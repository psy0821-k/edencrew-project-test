import 'dart:async';

import 'package:edencrew_assignment_starter/entities/search/search_providers.dart';
import 'package:edencrew_assignment_starter/entities/search/search_repository.dart';
import 'package:edencrew_assignment_starter/entities/search/search_result.dart';
import 'package:edencrew_assignment_starter/entities/watchlist/watchlist_providers.dart';
import 'package:edencrew_assignment_starter/entities/watchlist/watchlist_repository.dart';
import 'package:edencrew_assignment_starter/features/search-list/search_result_row.dart';
import 'package:edencrew_assignment_starter/pages/search_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  _FakeWatchlistRepository({Set<String>? initialSymbols, this.toggleDelay})
    : _symbols = initialSymbols ?? {};

  final Set<String> _symbols;

  /// 지정하면 toggleFavorite이 이 Future가 완료될 때까지 기다린다.
  /// (동일 symbol의 진행 중 상태를 테스트에서 붙잡아 두기 위해 사용)
  final Future<void>? toggleDelay;

  @override
  Set<String> getSymbols() => _symbols;

  @override
  bool isFavorite(String symbol) => _symbols.contains(symbol);

  @override
  Future<bool> toggleFavorite(String symbol) async {
    if (toggleDelay != null) {
      await toggleDelay;
    }
    final nowFavorite = !_symbols.contains(symbol);
    if (nowFavorite) {
      _symbols.add(symbol);
    } else {
      _symbols.remove(symbol);
    }
    return nowFavorite;
  }
}

Future<void> _pumpSearchPage(
  WidgetTester tester, {
  required SearchRepository searchRepository,
  Set<String>? initialFavoriteSymbols,
  Future<void>? toggleDelay,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        searchRepositoryProvider.overrideWithValue(searchRepository),
        watchlistRepositoryProvider.overrideWithValue(
          _FakeWatchlistRepository(
            initialSymbols: initialFavoriteSymbols,
            toggleDelay: toggleDelay,
          ),
        ),
      ],
      child: const MaterialApp(home: SearchPage()),
    ),
  );
}

Future<void> _enterQueryAndAwaitResults(
  WidgetTester tester,
  String query,
) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump();
}

/// 검색 결과 행(SearchResultRow) 안의 별 아이콘만 찾는다.
/// find.byType(SvgPicture)는 검색 입력창의 돋보기 아이콘도 함께 잡히므로 범위를 좁힌다.
final Finder _starIcons = find.descendant(
  of: find.byType(SearchResultRow),
  matching: find.byType(SvgPicture),
);

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
          find.text("'없는종목'와\n일치하는 검색 결과를 찾지 못했습니다."),
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

    testWidgets(
      'should immediately fill the star icon and show the "관심이 등록되었습니다" toast when tapping the star of a stock not yet favorited',
      (WidgetTester tester) async {
        const result = SearchResult(
          symbol: '005930',
          name: '삼성전자',
          marketName: '코스피',
        );
        final repository = _FakeSearchRepository(results: const [result]);

        await _pumpSearchPage(tester, searchRepository: repository);
        await _enterQueryAndAwaitResults(tester, '삼성');

        await tester.tap(_starIcons);
        await tester.pump();

        expect(find.text('관심이 등록되었습니다'), findsOneWidget);
      },
    );

    testWidgets(
      'should immediately empty the star icon and show the "관심이 해제되었습니다" toast when tapping the star of an already favorited stock',
      (WidgetTester tester) async {
        const result = SearchResult(
          symbol: '005930',
          name: '삼성전자',
          marketName: '코스피',
        );
        final repository = _FakeSearchRepository(results: const [result]);

        await _pumpSearchPage(
          tester,
          searchRepository: repository,
          initialFavoriteSymbols: {'005930'},
        );
        await _enterQueryAndAwaitResults(tester, '삼성');

        await tester.tap(_starIcons);
        await tester.pump();

        expect(find.text('관심이 해제되었습니다'), findsOneWidget);
      },
    );

    testWidgets(
      'should hide the toast after 2 seconds have passed',
      (WidgetTester tester) async {
        const result = SearchResult(
          symbol: '005930',
          name: '삼성전자',
          marketName: '코스피',
        );
        final repository = _FakeSearchRepository(results: const [result]);

        await _pumpSearchPage(tester, searchRepository: repository);
        await _enterQueryAndAwaitResults(tester, '삼성');

        await tester.tap(_starIcons);
        await tester.pump();
        expect(find.text('관심이 등록되었습니다'), findsOneWidget);

        // SnackBar는 등장 애니메이션(약 750ms)이 끝난 뒤부터 duration 타이머가 시작되므로
        // 등장 애니메이션 + duration + 퇴장 애니메이션 시간을 모두 흘려보내야 한다.
        await tester.pump(const Duration(milliseconds: 750));
        await tester.pump(const Duration(seconds: 2));
        await tester.pump(const Duration(milliseconds: 750));

        expect(find.text('관심이 등록되었습니다'), findsNothing);
      },
    );

    testWidgets(
      'should not trigger a duplicate toggle when the star icon is tapped again while a toggle is already pending',
      (WidgetTester tester) async {
        const result = SearchResult(
          symbol: '005930',
          name: '삼성전자',
          marketName: '코스피',
        );
        final repository = _FakeSearchRepository(results: const [result]);
        final toggleGate = Completer<void>();

        await _pumpSearchPage(
          tester,
          searchRepository: repository,
          toggleDelay: toggleGate.future,
        );
        await _enterQueryAndAwaitResults(tester, '삼성');

        // 첫 탭으로 토글이 진행 중(pending)인 상태를 만든다. toggleDelay가 아직
        // 완료되지 않아 toggleFavorite은 await 상태로 멈춰 있다.
        await tester.tap(_starIcons);
        await tester.pump();

        // 진행 중인 동안 같은 별 아이콘을 다시 탭한다 — 무시되어야 한다.
        await tester.tap(_starIcons);
        await tester.pump();

        toggleGate.complete();
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byType(SearchResultRow),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is SvgPicture &&
                  (widget.bytesLoader as SvgAssetLoader).assetName ==
                      'assets/icons/ico_star_filled.svg',
            ),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'should immediately replace an existing toast with a new one when toggling a different stock while a toast is shown',
      (WidgetTester tester) async {
        const resultA = SearchResult(
          symbol: '005930',
          name: '삼성전자',
          marketName: '코스피',
        );
        const resultB = SearchResult(
          symbol: '000660',
          name: 'SK하이닉스',
          marketName: '코스피',
        );
        final repository = _FakeSearchRepository(
          results: const [resultA, resultB],
        );

        await _pumpSearchPage(
          tester,
          searchRepository: repository,
          initialFavoriteSymbols: {'000660'},
        );
        await _enterQueryAndAwaitResults(tester, '전자하이닉스');

        await tester.tap(_starIcons.first);
        await tester.pump();
        expect(find.text('관심이 등록되었습니다'), findsOneWidget);

        await tester.tap(_starIcons.last);
        await tester.pump();

        expect(find.text('관심이 등록되었습니다'), findsNothing);
        expect(find.text('관심이 해제되었습니다'), findsOneWidget);
      },
    );
  });
}
