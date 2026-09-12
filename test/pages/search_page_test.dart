import 'dart:async';

import 'package:edencrew_assignment_starter/entities/search/search_providers.dart';
import 'package:edencrew_assignment_starter/entities/search/search_repository.dart';
import 'package:edencrew_assignment_starter/entities/search/search_result.dart';
import 'package:edencrew_assignment_starter/entities/watchlist/watchlist_providers.dart';
import 'package:edencrew_assignment_starter/entities/watchlist/watchlist_repository.dart';
import 'package:edencrew_assignment_starter/pages/search_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSearchRepository implements SearchRepository {
  _FakeSearchRepository({
    List<SearchResult>? results,
    Object? errorToThrow,
  }) : _results = results ?? const [],
       _errorToThrow = errorToThrow;

  final List<SearchResult> _results;
  final Object? _errorToThrow;
  int callCount = 0;

  @override
  Future<List<SearchResult>> search(String query) async {
    callCount++;
    if (_errorToThrow != null) {
      throw _errorToThrow;
    }
    return _results;
  }
}

class _FakeWatchlistRepository implements WatchlistRepository {
  final Set<String> _symbols = {};

  @override
  Set<String> getSymbols() => _symbols;

  @override
  bool isFavorite(String symbol) => _symbols.contains(symbol);

  @override
  Future<bool> toggleFavorite(String symbol) async => false;
}

Future<void> _pumpSearchPage(
  WidgetTester tester, {
  required SearchRepository searchRepository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        searchRepositoryProvider.overrideWithValue(searchRepository),
        watchlistRepositoryProvider.overrideWithValue(
          _FakeWatchlistRepository(),
        ),
      ],
      child: const MaterialApp(home: SearchPage()),
    ),
  );
}

void main() {
  group('SearchPage', () {
    testWidgets(
      'should show the initial state (magnifier icon + guidance text) on first entry with no query',
      (WidgetTester tester) async {
        await _pumpSearchPage(
          tester,
          searchRepository: _FakeSearchRepository(),
        );

        expect(find.text('종목을 검색해 보세요'), findsOneWidget);
      },
    );

    testWidgets(
      'should not trigger a request and should keep the initial state after 300ms when only one character is entered',
      (WidgetTester tester) async {
        final repository = _FakeSearchRepository();

        await _pumpSearchPage(tester, searchRepository: repository);

        await tester.enterText(find.byType(TextField), '삼');
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.text('종목을 검색해 보세요'), findsOneWidget);
        expect(repository.callCount, 0);
      },
    );

    testWidgets(
      'should keep the initial state after 300ms when only whitespace is entered',
      (WidgetTester tester) async {
        await _pumpSearchPage(
          tester,
          searchRepository: _FakeSearchRepository(),
        );

        await tester.enterText(find.byType(TextField), '   ');
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.text('종목을 검색해 보세요'), findsOneWidget);
      },
    );

    testWidgets(
      'should show the result list with highlighted name and "symbol · marketName" when a valid stock name of 2+ characters is entered and results arrive after 300ms',
      (WidgetTester tester) async {
        const result = SearchResult(
          symbol: '005930',
          name: '삼성전자',
          marketName: '코스피',
        );
        final repository = _FakeSearchRepository(results: const [result]);

        await _pumpSearchPage(tester, searchRepository: repository);

        await tester.enterText(find.byType(TextField), '삼성');
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump();

        expect(find.textContaining('삼성전자'), findsOneWidget);
        expect(find.textContaining('005930'), findsOneWidget);
        expect(find.textContaining('코스피'), findsOneWidget);
      },
    );

    testWidgets(
      'should show "\'{query}\'와 일치하는 검색 결과를 찾지 못했습니다" with the original input string when the search term has no results',
      (WidgetTester tester) async {
        final repository = _FakeSearchRepository(results: const []);

        await _pumpSearchPage(tester, searchRepository: repository);

        await tester.enterText(find.byType(TextField), '없는종목');
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump();

        expect(
          find.text("'없는종목'와 일치하는 검색 결과를 찾지 못했습니다."),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'should show the error message "검색 중 문제가 발생했습니다" in a layout similar to the empty-result state when the search request fails',
      (WidgetTester tester) async {
        final repository = _FakeSearchRepository(
          errorToThrow: Exception('network error'),
        );

        await _pumpSearchPage(tester, searchRepository: repository);

        await tester.enterText(find.byType(TextField), '삼성전자');
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump();

        expect(find.text('검색 중 문제가 발생했습니다'), findsOneWidget);
      },
    );

    testWidgets(
      'should clear both the query and the results and return to the initial state when the clear (X) button is tapped while results are shown',
      (WidgetTester tester) async {
        const result = SearchResult(
          symbol: '005930',
          name: '삼성전자',
          marketName: '코스피',
        );
        final repository = _FakeSearchRepository(results: const [result]);

        await _pumpSearchPage(tester, searchRepository: repository);

        await tester.enterText(find.byType(TextField), '삼성');
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump();

        expect(find.textContaining('삼성전자'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.clear));
        await tester.pump();

        expect(find.text('종목을 검색해 보세요'), findsOneWidget);
      },
    );
  });
}
