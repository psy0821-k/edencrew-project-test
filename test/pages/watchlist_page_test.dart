import 'dart:async';

import 'package:edencrew_assignment_starter/entities/quote/quote.dart';
import 'package:edencrew_assignment_starter/entities/quote/quote_providers.dart';
import 'package:edencrew_assignment_starter/entities/quote/quote_repository.dart';
import 'package:edencrew_assignment_starter/entities/stock_meta/stock_meta.dart';
import 'package:edencrew_assignment_starter/entities/stock_meta/stock_meta_providers.dart';
import 'package:edencrew_assignment_starter/entities/stock_meta/stock_meta_repository.dart';
import 'package:edencrew_assignment_starter/entities/watchlist/watchlist_providers.dart';
import 'package:edencrew_assignment_starter/entities/watchlist/watchlist_repository.dart';
import 'package:edencrew_assignment_starter/pages/watchlist_page.dart';
import 'package:edencrew_assignment_starter/widgets/skeleton_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeWatchlistRepository implements WatchlistRepository {
  _FakeWatchlistRepository({Set<String>? initialSymbols})
    : _symbols = initialSymbols ?? {};

  final Set<String> _symbols;

  @override
  Set<String> getSymbols() => _symbols;

  @override
  bool isFavorite(String symbol) => _symbols.contains(symbol);

  @override
  Future<bool> toggleFavorite(String symbol) async => false;
}

/// fetchQuotes 호출 횟수를 기록하는 fake. [delayFrom]번째 호출부터는 즉시
/// 완료되지 않고 대기시켜, 재조회가 진행 중인 동안 연속 탭이 무시되는지
/// 검증하는 데 사용한다(초기 로드는 지연 없이 끝나야 위젯 트리가 안정된다).
class _RecordingQuoteRepository implements QuoteRepository {
  _RecordingQuoteRepository({this.delayFrom, this.delay});

  int callCount = 0;
  final int? delayFrom;
  final Future<void>? delay;

  @override
  Future<Map<String, Quote>> fetchQuotes(List<String> symbols) async {
    callCount++;
    if (delayFrom != null && callCount >= delayFrom! && delay != null) {
      await delay;
    }
    return {
      for (final symbol in symbols)
        symbol: Quote(
          symbol: symbol,
          currentPrice: 1000,
          previousClose: 1000,
          open: 1000,
          high: 1000,
          low: 1000,
          volume: 0,
          countOfListedStock: 0,
        ),
    };
  }
}

class _FakeStockMetaRepository implements StockMetaRepository {
  @override
  Future<StockMeta> fetchStockMeta(String symbol) async =>
      StockMeta(symbol: symbol, name: symbol, marketName: '코스피');
}

void main() {
  group('WatchlistPage', () {
    testWidgets(
      'should show the empty state screen when there are zero watchlist items',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              watchlistRepositoryProvider.overrideWithValue(
                _FakeWatchlistRepository(),
              ),
            ],
            child: const MaterialApp(home: WatchlistPage()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('관심 종목이 없습니다'), findsOneWidget);
      },
    );

    testWidgets(
      'should trigger only one refetch when the refresh button is tapped '
      'repeatedly while a refetch is already in progress',
      (WidgetTester tester) async {
        final completer = Completer<void>();
        final quoteRepository = _RecordingQuoteRepository(
          delayFrom: 2,
          delay: completer.future,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              watchlistRepositoryProvider.overrideWithValue(
                _FakeWatchlistRepository(initialSymbols: {'005930'}),
              ),
              quoteRepositoryProvider.overrideWithValue(quoteRepository),
              stockMetaRepositoryProvider.overrideWithValue(
                _FakeStockMetaRepository(),
              ),
            ],
            child: const MaterialApp(home: WatchlistPage()),
          ),
        );
        await tester.pumpAndSettle();

        final callCountAfterInitialLoad = quoteRepository.callCount;
        final refreshButton = find.byType(IconButton);

        await tester.tap(refreshButton);
        await tester.pump();
        await tester.tap(refreshButton);
        await tester.pump();
        await tester.tap(refreshButton);
        await tester.pump();

        expect(quoteRepository.callCount, callCountAfterInitialLoad + 1);

        completer.complete();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'should show skeleton boxes for existing rows while a refresh is in '
      'progress, then show real values again once it completes',
      (WidgetTester tester) async {
        final completer = Completer<void>();
        final quoteRepository = _RecordingQuoteRepository(
          delayFrom: 2,
          delay: completer.future,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              watchlistRepositoryProvider.overrideWithValue(
                _FakeWatchlistRepository(initialSymbols: {'005930'}),
              ),
              quoteRepositoryProvider.overrideWithValue(quoteRepository),
              stockMetaRepositoryProvider.overrideWithValue(
                _FakeStockMetaRepository(),
              ),
            ],
            child: const MaterialApp(home: WatchlistPage()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('1,000'), findsOneWidget);
        expect(find.byType(SkeletonBox), findsNothing);

        await tester.tap(find.byType(IconButton));
        await tester.pump();

        expect(find.textContaining('1,000'), findsNothing);
        expect(find.byType(SkeletonBox), findsWidgets);

        completer.complete();
        await tester.pumpAndSettle();

        expect(find.textContaining('1,000'), findsOneWidget);
        expect(find.byType(SkeletonBox), findsNothing);
      },
    );
  });
}
