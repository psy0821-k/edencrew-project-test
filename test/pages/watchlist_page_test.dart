import 'dart:async';

import 'package:edencrew_assignment_starter/entities/daily_quote/daily_quote_providers.dart';
import 'package:edencrew_assignment_starter/entities/daily_quote/mock_daily_quote_repository.dart';
import 'package:edencrew_assignment_starter/entities/quote/quote.dart';
import 'package:edencrew_assignment_starter/entities/quote/quote_providers.dart';
import 'package:edencrew_assignment_starter/entities/quote/quote_repository.dart';
import 'package:edencrew_assignment_starter/entities/stock_meta/stock_meta.dart';
import 'package:edencrew_assignment_starter/entities/stock_meta/stock_meta_providers.dart';
import 'package:edencrew_assignment_starter/entities/stock_meta/stock_meta_repository.dart';
import 'package:edencrew_assignment_starter/entities/watchlist/watchlist_providers.dart';
import 'package:edencrew_assignment_starter/entities/watchlist/watchlist_repository.dart';
import 'package:edencrew_assignment_starter/pages/stock_detail_page.dart';
import 'package:edencrew_assignment_starter/pages/watchlist_page.dart';
import 'package:edencrew_assignment_starter/widgets/skeleton_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeWatchlistRepository implements WatchlistRepository {
  _FakeWatchlistRepository({Set<String>? initialSymbols, this.toggleDelay})
    : _symbols = initialSymbols ?? {};

  final Set<String> _symbols;

  /// 지정하면 toggleFavorite이 이 Future가 완료될 때까지 기다린다.
  final Future<void>? toggleDelay;
  int toggleCallCount = 0;

  @override
  Set<String> getSymbols() => _symbols;

  @override
  bool isFavorite(String symbol) => _symbols.contains(symbol);

  @override
  Future<bool> toggleFavorite(String symbol) async {
    toggleCallCount++;
    if (toggleDelay != null) await toggleDelay;
    final nowFavorite = !_symbols.contains(symbol);
    if (nowFavorite) {
      _symbols.add(symbol);
    } else {
      _symbols.remove(symbol);
    }
    return nowFavorite;
  }
}

Finder _closeIconFinder() {
  return find.byWidgetPredicate(
    (widget) =>
        widget is SvgPicture &&
        (widget.bytesLoader as SvgAssetLoader).assetName ==
            'assets/icons/ico_close.svg',
  );
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

/// [failFrom]번째 호출부터 예외를 던지는 fake. 첫 로드 실패와, 이전 데이터가
/// 있는 상태에서의 재조회 실패를 각각 재현하는 데 사용한다.
class _FailingQuoteRepository implements QuoteRepository {
  _FailingQuoteRepository({this.failFrom = 1});

  int callCount = 0;
  final int failFrom;

  @override
  Future<Map<String, Quote>> fetchQuotes(List<String> symbols) async {
    callCount++;
    if (callCount >= failFrom) {
      throw Exception('network error');
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

    testWidgets(
      'should replace the entire list area with an error view (keeping the '
      'header) when the very first load fails',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              watchlistRepositoryProvider.overrideWithValue(
                _FakeWatchlistRepository(initialSymbols: {'005930'}),
              ),
              quoteRepositoryProvider.overrideWithValue(
                _FailingQuoteRepository(),
              ),
              stockMetaRepositoryProvider.overrideWithValue(
                _FakeStockMetaRepository(),
              ),
            ],
            child: const MaterialApp(home: WatchlistPage()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('관심'), findsOneWidget);
        expect(find.text('목록을 불러오지 못했습니다'), findsOneWidget);
        expect(find.text('다시 시도'), findsOneWidget);
      },
    );

    testWidgets(
      'should keep the existing list and show an error banner on top when a '
      'refresh fails after a previous successful load',
      (WidgetTester tester) async {
        final quoteRepository = _FailingQuoteRepository(failFrom: 2);

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

        await tester.tap(find.byType(IconButton));
        await tester.pumpAndSettle();

        expect(find.textContaining('1,000'), findsOneWidget);
        expect(find.text('목록을 불러오지 못했습니다'), findsOneWidget);
      },
    );

    testWidgets(
      '상세 화면 진입 후 뒤로가기를 누르면 관심 화면으로 돌아오고 목록 상태가 유지된다',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              watchlistRepositoryProvider.overrideWithValue(
                _FakeWatchlistRepository(initialSymbols: {'005930'}),
              ),
              quoteRepositoryProvider.overrideWithValue(
                _RecordingQuoteRepository(),
              ),
              stockMetaRepositoryProvider.overrideWithValue(
                _FakeStockMetaRepository(),
              ),
              dailyQuoteRepositoryProvider.overrideWithValue(
                MockDailyQuoteRepository(),
              ),
            ],
            child: const MaterialApp(home: WatchlistPage()),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('005930'));
        await tester.pumpAndSettle();
        expect(find.byType(StockDetailPage), findsOneWidget);

        final backButtonFinder = find.byWidgetPredicate(
          (widget) =>
              widget is SvgPicture &&
              (widget.bytesLoader as SvgAssetLoader).assetName ==
                  'assets/icons/ico_back.svg',
        );
        await tester.tap(backButtonFinder);
        await tester.pumpAndSettle();

        expect(find.byType(WatchlistPage), findsOneWidget);
        expect(find.text('005930'), findsOneWidget);
      },
    );

    testWidgets(
      '종목 행을 탭하면 StockDetailPage(symbol: ...)로 이동한다',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              watchlistRepositoryProvider.overrideWithValue(
                _FakeWatchlistRepository(initialSymbols: {'005930'}),
              ),
              quoteRepositoryProvider.overrideWithValue(
                _RecordingQuoteRepository(),
              ),
              stockMetaRepositoryProvider.overrideWithValue(
                _FakeStockMetaRepository(),
              ),
              dailyQuoteRepositoryProvider.overrideWithValue(
                MockDailyQuoteRepository(),
              ),
            ],
            child: const MaterialApp(home: WatchlistPage()),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('005930'));
        await tester.pumpAndSettle();

        final detailPage = tester.widget<StockDetailPage>(
          find.byType(StockDetailPage),
        );
        expect(detailPage.symbol, '005930');
      },
    );

    testWidgets(
      'close 아이콘을 탭하면 확인 절차 없이 즉시 관심이 해제되고 목록에서 사라지며 토스트가 표시된다',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              watchlistRepositoryProvider.overrideWithValue(
                _FakeWatchlistRepository(initialSymbols: {'005930'}),
              ),
              quoteRepositoryProvider.overrideWithValue(
                _RecordingQuoteRepository(),
              ),
              stockMetaRepositoryProvider.overrideWithValue(
                _FakeStockMetaRepository(),
              ),
            ],
            child: const MaterialApp(home: WatchlistPage()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('005930'), findsOneWidget);

        await tester.tap(_closeIconFinder());
        await tester.pumpAndSettle();

        expect(find.text('005930'), findsNothing);
        expect(find.text('관심이 해제되었습니다'), findsOneWidget);
      },
    );

    testWidgets(
      'close 아이콘을 연속으로 빠르게 탭하면 두 번째 탭은 무시된다',
      (WidgetTester tester) async {
        final delayCompleter = Completer<void>();
        final watchlistRepository = _FakeWatchlistRepository(
          initialSymbols: {'005930'},
          toggleDelay: delayCompleter.future,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              watchlistRepositoryProvider.overrideWithValue(
                watchlistRepository,
              ),
              quoteRepositoryProvider.overrideWithValue(
                _RecordingQuoteRepository(),
              ),
              stockMetaRepositoryProvider.overrideWithValue(
                _FakeStockMetaRepository(),
              ),
            ],
            child: const MaterialApp(home: WatchlistPage()),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(_closeIconFinder());
        await tester.pump();
        await tester.tap(_closeIconFinder());
        await tester.pump();

        delayCompleter.complete();
        await tester.pumpAndSettle();

        expect(watchlistRepository.toggleCallCount, 1);
      },
    );
  });
}
