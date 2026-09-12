import 'package:edencrew_assignment_starter/entities/quote/quote.dart';
import 'package:edencrew_assignment_starter/entities/stock_meta/stock_meta.dart';
import 'package:edencrew_assignment_starter/entities/watchlist/watchlist_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WatchlistItem', () {
    test(
      'should retain all fields as-is when created with symbol, stockMeta, and non-null quote',
      () {
        const stockMeta = StockMeta(
          symbol: '005930',
          name: '삼성전자',
          marketName: '코스피',
        );
        const quote = Quote(
          symbol: '005930',
          currentPrice: 70000,
          previousClose: 69000,
          open: 69500,
          high: 70500,
          low: 69000,
          volume: 1000000,
          countOfListedStock: 100,
        );

        const item = WatchlistItem(
          symbol: '005930',
          stockMeta: stockMeta,
          quote: quote,
        );

        expect(item.symbol, '005930');
        expect(item.stockMeta, stockMeta);
        expect(item.quote, quote);
      },
    );

    test('should have a null quote field when created with quote: null', () {
      const stockMeta = StockMeta(
        symbol: '005930',
        name: '삼성전자',
        marketName: '코스피',
      );

      const item = WatchlistItem(
        symbol: '005930',
        stockMeta: stockMeta,
        quote: null,
      );

      expect(item.quote, isNull);
    });
  });
}
