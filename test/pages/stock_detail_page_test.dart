import 'dart:async';

import 'package:edencrew_assignment_starter/entities/daily_quote/daily_quote.dart';
import 'package:edencrew_assignment_starter/entities/daily_quote/daily_quote_providers.dart';
import 'package:edencrew_assignment_starter/entities/daily_quote/daily_quote_repository.dart';
import 'package:edencrew_assignment_starter/entities/daily_quote/period.dart';
import 'package:edencrew_assignment_starter/entities/quote/quote.dart';
import 'package:edencrew_assignment_starter/entities/quote/quote_providers.dart';
import 'package:edencrew_assignment_starter/entities/quote/quote_repository.dart';
import 'package:edencrew_assignment_starter/entities/stock_meta/stock_meta.dart';
import 'package:edencrew_assignment_starter/entities/stock_meta/stock_meta_providers.dart';
import 'package:edencrew_assignment_starter/entities/stock_meta/stock_meta_repository.dart';
import 'package:edencrew_assignment_starter/entities/watchlist/watchlist_providers.dart';
import 'package:edencrew_assignment_starter/entities/watchlist/watchlist_repository.dart';
import 'package:edencrew_assignment_starter/features/stock-detail/stock_detail_price_section.dart';
import 'package:edencrew_assignment_starter/pages/stock_detail_page.dart';
import 'package:edencrew_assignment_starter/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeQuoteRepository implements QuoteRepository {
  _FakeQuoteRepository({
    Map<String, Quote>? quotes,
    Object? errorToThrow,
    this.delay,
  }) : _quotes = quotes ?? const {},
       _errorToThrow = errorToThrow;

  final Map<String, Quote> _quotes;
  final Object? _errorToThrow;
  final Future<void>? delay;

  @override
  Future<Map<String, Quote>> fetchQuotes(List<String> symbols) async {
    if (delay != null) await delay;
    if (_errorToThrow != null) throw _errorToThrow;
    return _quotes;
  }
}

class _FakeStockMetaRepository implements StockMetaRepository {
  _FakeStockMetaRepository({StockMeta? stockMeta, Object? errorToThrow})
    : _stockMeta =
          stockMeta ??
          const StockMeta(symbol: '005930', name: '삼성전자', marketName: '코스피'),
      _errorToThrow = errorToThrow;

  final StockMeta _stockMeta;
  final Object? _errorToThrow;

  @override
  Future<StockMeta> fetchStockMeta(String symbol) async {
    if (_errorToThrow != null) throw _errorToThrow;
    return _stockMeta;
  }
}

class _FakeWatchlistRepository implements WatchlistRepository {
  _FakeWatchlistRepository({Set<String>? initialSymbols})
    : _symbols = initialSymbols ?? {};

  final Set<String> _symbols;

  @override
  Set<String> getSymbols() => _symbols;

  @override
  bool isFavorite(String symbol) => _symbols.contains(symbol);

  @override
  Future<bool> toggleFavorite(String symbol) async {
    final nowFavorite = !_symbols.contains(symbol);
    if (nowFavorite) {
      _symbols.add(symbol);
    } else {
      _symbols.remove(symbol);
    }
    return nowFavorite;
  }
}

class _FakeDailyQuoteRepository implements DailyQuoteRepository {
  _FakeDailyQuoteRepository({
    Map<Period, List<DailyQuote>>? quotesByPeriod,
    Object? errorToThrow,
  }) : _quotesByPeriod = quotesByPeriod ?? const {},
       _errorToThrow = errorToThrow;

  final Map<Period, List<DailyQuote>> _quotesByPeriod;
  final Object? _errorToThrow;

  @override
  Future<List<DailyQuote>> fetchQuotes(String symbol, Period period) async {
    if (_errorToThrow != null) throw _errorToThrow;
    return _quotesByPeriod[period] ?? _defaultQuotesFor(period);
  }
}

List<DailyQuote> _defaultQuotesFor(Period period) => [
  DailyQuote(
    date: '20260911',
    closePrice: 70000,
    openPrice: 70200,
    highPrice: 70800,
    lowPrice: 69900,
    volume: 12345678,
  ),
  DailyQuote(
    date: '20260910',
    closePrice: 69000,
    openPrice: 69200,
    highPrice: 69800,
    lowPrice: 68900,
    volume: 11111111,
  ),
];

const _oneYearQuote = DailyQuote(
  date: '20250912',
  closePrice: 50000,
  openPrice: 50200,
  highPrice: 50800,
  lowPrice: 49900,
  volume: 33333333,
);

const _threeMonthsQuote = DailyQuote(
  date: '20260801',
  closePrice: 65000,
  openPrice: 65200,
  highPrice: 65800,
  lowPrice: 64900,
  volume: 22222222,
);

const _sampleQuote = Quote(
  symbol: '005930',
  currentPrice: 70000,
  previousClose: 69000,
  open: 69500,
  high: 70500,
  low: 69000,
  volume: 1000000,
  countOfListedStock: 5969782550,
);

const _sampleStockMeta = StockMeta(
  symbol: '005930',
  name: '삼성전자',
  marketName: '코스피',
);

Future<void> _pumpStockDetailPage(
  WidgetTester tester, {
  QuoteRepository? quoteRepository,
  StockMetaRepository? stockMetaRepository,
  DailyQuoteRepository? dailyQuoteRepository,
  Set<String>? initialFavoriteSymbols,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        quoteRepositoryProvider.overrideWithValue(
          quoteRepository ??
              _FakeQuoteRepository(quotes: {'005930': _sampleQuote}),
        ),
        stockMetaRepositoryProvider.overrideWithValue(
          stockMetaRepository ??
              _FakeStockMetaRepository(stockMeta: _sampleStockMeta),
        ),
        dailyQuoteRepositoryProvider.overrideWithValue(
          dailyQuoteRepository ?? _FakeDailyQuoteRepository(),
        ),
        watchlistRepositoryProvider.overrideWithValue(
          _FakeWatchlistRepository(initialSymbols: initialFavoriteSymbols),
        ),
      ],
      child: const MaterialApp(home: StockDetailPage(symbol: '005930')),
    ),
  );
}

Finder _backButtonFinder() {
  return find.byWidgetPredicate(
    (widget) =>
        widget is SvgPicture &&
        (widget.bytesLoader as SvgAssetLoader).assetName ==
            'assets/icons/ico_back.svg',
  );
}

void main() {
  group('StockDetailPage', () {
    testWidgets('진입하면 뒤로가기/종목명/종목코드·시장/관심 버튼이 있는 헤더가 보인다', (tester) async {
      await _pumpStockDetailPage(tester);
      await tester.pumpAndSettle();

      expect(_backButtonFinder(), findsOneWidget);
      expect(find.text('삼성전자'), findsOneWidget);
      expect(find.textContaining('005930'), findsOneWidget);
      expect(find.textContaining('코스피'), findsOneWidget);
      expect(find.byType(SvgPicture), findsWidgets);
    });

    testWidgets('조회가 완료되면 현재가와 등락이 표시된다', (tester) async {
      await _pumpStockDetailPage(tester);
      await tester.pumpAndSettle();

      final priceSectionFinder = find.descendant(
        of: find.byType(StockDetailPriceSection),
        matching: find.textContaining('70,000'),
      );
      expect(priceSectionFinder, findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(StockDetailPriceSection),
          matching: find.textContaining('1,000'),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      '관심등록 안 된 종목에서 관심 버튼을 탭하면 별 아이콘이 즉시 채워지고 watchlistProvider에도 반영된다',
      (tester) async {
        await _pumpStockDetailPage(tester);
        await tester.pumpAndSettle();

        final starIconFinder = find.byWidgetPredicate(
          (widget) =>
              widget is SvgPicture &&
              (widget.bytesLoader as SvgAssetLoader).assetName ==
                  'assets/icons/ico_star.svg',
        );
        expect(starIconFinder, findsOneWidget);

        await tester.tap(starIconFinder);
        await tester.pumpAndSettle();

        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is SvgPicture &&
                (widget.bytesLoader as SvgAssetLoader).assetName ==
                    'assets/icons/ico_star_filled.svg',
          ),
          findsWidgets,
        );
      },
    );

    testWidgets('데이터가 아직 도착하지 않으면 헤더 아래 영역에 스켈레톤이 표시된다', (tester) async {
      final quoteDelay = Completer<void>();
      await _pumpStockDetailPage(
        tester,
        quoteRepository: _FakeQuoteRepository(
          quotes: {'005930': _sampleQuote},
          delay: quoteDelay.future,
        ),
      );
      await tester.pump();

      final skeletonFinder = find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == 'SkeletonBox',
      );
      expect(skeletonFinder, findsWidgets);

      quoteDelay.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('최초 조회가 실패하면 헤더는 유지된 채 그 아래가 에러 뷰로 대체된다', (tester) async {
      await _pumpStockDetailPage(
        tester,
        quoteRepository: _FakeQuoteRepository(
          errorToThrow: Exception('network error'),
        ),
      );
      await tester.pumpAndSettle();

      expect(_backButtonFinder(), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);
    });

    testWidgets('에러 뷰의 다시 시도 버튼을 탭하면 재조회된다', (tester) async {
      var callCount = 0;
      final repository = _CountingQuoteRepository(
        onCall: () => callCount++,
        failFirstCall: true,
      );

      await _pumpStockDetailPage(tester, quoteRepository: repository);
      await tester.pumpAndSettle();

      expect(find.text('다시 시도'), findsOneWidget);
      expect(callCount, 1);

      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();

      expect(callCount, 2);
      expect(
        find.descendant(
          of: find.byType(StockDetailPriceSection),
          matching: find.textContaining('70,000'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('상세 화면에 진입해 데이터가 도착하면 1개월 탭이 선택된 상태로 요약 카드와 일별 시세 표가 표시된다', (
      tester,
    ) async {
      await _pumpStockDetailPage(tester);
      await tester.pumpAndSettle();

      final oneMonthText = tester.widget<Text>(find.text('1개월'));
      final context = tester.element(find.byType(StockDetailPage));
      expect(oneMonthText.style?.color, context.colors.accentDefault);
      expect(find.textContaining('70,200'), findsOneWidget); // 시가
      expect(find.text('09.11'), findsOneWidget); // 표의 날짜
    });

    testWidgets('1개월 탭에서 3개월 탭을 누르면 표/카드가 3개월치 데이터로 바뀐다', (tester) async {
      final threeMonthsQuote = DailyQuote(
        date: '20260801',
        closePrice: 65000,
        openPrice: 65200,
        highPrice: 65800,
        lowPrice: 64900,
        volume: 22222222,
      );
      await _pumpStockDetailPage(
        tester,
        dailyQuoteRepository: _FakeDailyQuoteRepository(
          quotesByPeriod: {
            Period.threeMonths: [threeMonthsQuote],
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('3개월'));
      await tester.pumpAndSettle();

      expect(find.text('08.01'), findsOneWidget);
    });

    testWidgets('탭 전환 요청이 진행 중인 동안에는 기존 표/카드가 화면에서 사라지지 않는다', (
      tester,
    ) async {
      final delayCompleter = Completer<List<DailyQuote>>();
      var callCount = 0;
      final repository = _DelayedDailyQuoteRepository(
        onCall: (period) => callCount++,
        delayFor: Period.threeMonths,
        delayCompleter: delayCompleter,
      );

      await _pumpStockDetailPage(tester, dailyQuoteRepository: repository);
      await tester.pumpAndSettle();
      expect(find.text('09.11'), findsOneWidget);

      await tester.tap(find.text('3개월'));
      await tester.pump();

      // 새 데이터가 아직 도착하지 않았으므로 기존 표는 화면에 남아있어야 한다.
      expect(find.text('09.11'), findsOneWidget);

      delayCompleter.complete(_defaultQuotesFor(Period.threeMonths));
      await tester.pumpAndSettle();
    });

    testWidgets(
      '3개월을 누른 직후 바로 1년을 눌러 두 요청이 겹치면, 최종 화면에는 1년(마지막으로 누른 탭)의 데이터만 반영된다',
      (tester) async {
        final repository = _RaceDailyQuoteRepository();

        await _pumpStockDetailPage(tester, dailyQuoteRepository: repository);
        await tester.pumpAndSettle();
        expect(find.text('09.11'), findsOneWidget); // 최초 oneMonth 데이터

        await tester.tap(find.text('3개월'));
        await tester.pump();
        await tester.tap(find.text('1년'));
        await tester.pump();

        // 늦게 요청한 1년이 먼저 응답하고, 먼저 요청한 3개월이 나중에 응답한다.
        repository.completeWith(Period.oneYear, [_oneYearQuote]);
        await tester.pump();
        repository.completeWith(Period.threeMonths, [_threeMonthsQuote]);
        await tester.pumpAndSettle();

        expect(find.text('09.12'), findsOneWidget); // 1년 데이터
        expect(find.text('08.01'), findsNothing); // 3개월 데이터는 반영되지 않음
      },
    );

    testWidgets('기간 탭 전환 중 조회가 실패하면 기존 표/카드는 유지된 채 상단에 에러 배너와 다시 시도 버튼이 표시된다', (
      tester,
    ) async {
      final repository = _FailingOnSwitchDailyQuoteRepository();

      await _pumpStockDetailPage(tester, dailyQuoteRepository: repository);
      await tester.pumpAndSettle();
      expect(find.text('09.11'), findsOneWidget);

      await tester.tap(find.text('3개월'));
      await tester.pumpAndSettle();

      expect(find.text('09.11'), findsOneWidget); // 기존 표 유지
      expect(find.text('다시 시도'), findsWidgets); // 헤더 에러 뷰가 없으므로 배너의 것
    });
  });
}

class _DelayedDailyQuoteRepository implements DailyQuoteRepository {
  _DelayedDailyQuoteRepository({
    required this.onCall,
    required this.delayFor,
    required this.delayCompleter,
  });

  final void Function(Period period) onCall;
  final Period delayFor;
  final Completer<List<DailyQuote>> delayCompleter;

  @override
  Future<List<DailyQuote>> fetchQuotes(String symbol, Period period) async {
    onCall(period);
    if (period == delayFor) return delayCompleter.future;
    return _defaultQuotesFor(period);
  }
}

/// 최초 oneMonth 로드는 즉시 성공하고, 이후 요청된 기간은 [completeWith]로
/// 응답 순서를 자유롭게 제어할 수 있는 fake. 응답 역전(늦게 요청한 기간이
/// 먼저 응답) 시나리오를 재현하는 데 사용한다.
class _RaceDailyQuoteRepository implements DailyQuoteRepository {
  final Map<Period, Completer<List<DailyQuote>>> _completers = {};
  bool _isFirstCall = true;

  Completer<List<DailyQuote>> _completerFor(Period period) =>
      _completers.putIfAbsent(period, () => Completer());

  void completeWith(Period period, List<DailyQuote> quotes) {
    _completerFor(period).complete(quotes);
  }

  @override
  Future<List<DailyQuote>> fetchQuotes(String symbol, Period period) async {
    if (_isFirstCall) {
      _isFirstCall = false;
      return _defaultQuotesFor(period);
    }
    return _completerFor(period).future;
  }
}

class _FailingOnSwitchDailyQuoteRepository implements DailyQuoteRepository {
  int _calls = 0;

  @override
  Future<List<DailyQuote>> fetchQuotes(String symbol, Period period) async {
    _calls++;
    if (_calls == 1) return _defaultQuotesFor(period);
    throw Exception('network error');
  }
}

class _CountingQuoteRepository implements QuoteRepository {
  _CountingQuoteRepository({required this.onCall, required this.failFirstCall});

  final VoidCallback onCall;
  final bool failFirstCall;
  int _calls = 0;

  @override
  Future<Map<String, Quote>> fetchQuotes(List<String> symbols) async {
    _calls++;
    onCall();
    if (failFirstCall && _calls == 1) {
      throw Exception('network error');
    }
    return {'005930': _sampleQuote};
  }
}
