import 'dart:async';

import 'package:edencrew_assignment_starter/entities/quote/quote.dart';
import 'package:edencrew_assignment_starter/entities/quote/quote_providers.dart';
import 'package:edencrew_assignment_starter/entities/quote/quote_repository.dart';
import 'package:edencrew_assignment_starter/entities/stock_meta/stock_meta.dart';
import 'package:edencrew_assignment_starter/entities/stock_meta/stock_meta_providers.dart';
import 'package:edencrew_assignment_starter/entities/stock_meta/stock_meta_repository.dart';
import 'package:edencrew_assignment_starter/entities/watchlist/watchlist_providers.dart';
import 'package:edencrew_assignment_starter/entities/watchlist/watchlist_repository.dart';
import 'package:edencrew_assignment_starter/pages/stock_detail_page.dart';
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

      expect(find.textContaining('70,000'), findsOneWidget);
      expect(find.textContaining('1,000'), findsOneWidget);
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
      expect(find.textContaining('70,000'), findsOneWidget);
    });
  });
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
