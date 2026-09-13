import 'package:edencrew_assignment_starter/app/app.dart';
import 'package:edencrew_assignment_starter/entities/search/search_providers.dart';
import 'package:edencrew_assignment_starter/entities/search/search_repository.dart';
import 'package:edencrew_assignment_starter/entities/search/search_result.dart';
import 'package:edencrew_assignment_starter/entities/watchlist/watchlist_providers.dart';
import 'package:edencrew_assignment_starter/entities/watchlist/watchlist_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeWatchlistRepository implements WatchlistRepository {
  final Set<String> _symbols = {};

  @override
  Set<String> getSymbols() => _symbols;

  @override
  bool isFavorite(String symbol) => _symbols.contains(symbol);

  @override
  Future<bool> toggleFavorite(String symbol) async => false;
}

class _FakeSearchRepository implements SearchRepository {
  @override
  Future<List<SearchResult>> search(String query) async => const [];
}

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        watchlistRepositoryProvider.overrideWithValue(
          _FakeWatchlistRepository(),
        ),
        searchRepositoryProvider.overrideWithValue(_FakeSearchRepository()),
      ],
      child: const EdencrewAssignmentApp(),
    ),
  );
}

void main() {
  testWidgets('앱을 처음 렌더링하면 다크 테마이고 관심 화면이 기본 탭으로 보여야 한다', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await tester.pumpAndSettle();

    expect(find.text('관심 종목이 없습니다'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.dark,
    );
  });

  testWidgets('하단 탭에서 검색을 누르면 검색 화면(초기 안내 문구)으로 전환되어야 한다', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('검색').last);
    await tester.pumpAndSettle();

    expect(find.text('종목을 검색해 보세요'), findsOneWidget);
  });

  testWidgets('검색 탭에서 입력한 검색어는 관심 탭을 오간 뒤에도 유지되어야 한다', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('검색').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '삼성전자');
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('관심').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('검색').last);
    await tester.pumpAndSettle();

    expect(find.text('삼성전자'), findsOneWidget);
  });
}
