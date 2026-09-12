import 'package:edencrew_assignment_starter/entities/quote/quote.dart';
import 'package:edencrew_assignment_starter/entities/stock_meta/stock_meta.dart';
import 'package:edencrew_assignment_starter/entities/watchlist/watchlist_item.dart';
import 'package:edencrew_assignment_starter/features/watchlist-sort/sort_criteria.dart';
import 'package:edencrew_assignment_starter/features/watchlist-sort/watchlist_comparator.dart';
import 'package:flutter_test/flutter_test.dart';

StockMeta _stockMetaFor(String symbol, {String? name}) =>
    StockMeta(symbol: symbol, name: name ?? '종목-$symbol', marketName: '코스피');

Quote _quoteFor(
  String symbol, {
  required int currentPrice,
  required int previousClose,
}) => Quote(
  symbol: symbol,
  currentPrice: currentPrice,
  previousClose: previousClose,
  open: previousClose,
  high: currentPrice,
  low: previousClose,
  volume: 1000000,
  countOfListedStock: 100,
);

WatchlistItem _itemFor(
  String symbol, {
  String? name,
  Quote? quote,
}) => WatchlistItem(
  symbol: symbol,
  stockMeta: _stockMetaFor(symbol, name: name),
  quote: quote,
);

void main() {
  group('sortWatchlistItems', () {
    test(
      'should sort by current price descending when given a list of WatchlistItem all with quotes and SortCriteria.priceDesc',
      () {
        final items = [
          _itemFor(
            '005930',
            quote: _quoteFor('005930', currentPrice: 70000, previousClose: 69000),
          ),
          _itemFor(
            '000660',
            quote: _quoteFor('000660', currentPrice: 120000, previousClose: 119000),
          ),
          _itemFor(
            '035420',
            quote: _quoteFor('035420', currentPrice: 90000, previousClose: 91000),
          ),
        ];

        final sorted = sortWatchlistItems(items, SortCriteria.priceDesc);

        expect(sorted.map((item) => item.symbol).toList(), [
          '000660',
          '035420',
          '005930',
        ]);
      },
    );

    test(
      'should sort by change rate descending when given a list of WatchlistItem all with quotes and SortCriteria.changeRateDesc',
      () {
        final items = [
          // changeRate = (70000-69000)/69000 ≈ 0.0145
          _itemFor(
            '005930',
            quote: _quoteFor('005930', currentPrice: 70000, previousClose: 69000),
          ),
          // changeRate = (119000-120000)/120000 ≈ -0.0083
          _itemFor(
            '000660',
            quote: _quoteFor('000660', currentPrice: 119000, previousClose: 120000),
          ),
          // changeRate = (99000-90000)/90000 ≈ 0.1
          _itemFor(
            '035420',
            quote: _quoteFor('035420', currentPrice: 99000, previousClose: 90000),
          ),
        ];

        final sorted = sortWatchlistItems(items, SortCriteria.changeRateDesc);

        expect(sorted.map((item) => item.symbol).toList(), [
          '035420',
          '005930',
          '000660',
        ]);
      },
    );

    test(
      'should sort alphabetically (가나다순) when given a list of WatchlistItem with different names and SortCriteria.nameAsc',
      () {
        final items = [
          _itemFor('005930', name: '삼성전자'),
          _itemFor('035420', name: '나이키'),
          _itemFor('000660', name: '다음카카오'),
          _itemFor('005380', name: '가나다전자'),
        ];

        final sorted = sortWatchlistItems(items, SortCriteria.nameAsc);

        expect(
          sorted.map((item) => item.stockMeta.name).toList(),
          ['가나다전자', '나이키', '다음카카오', '삼성전자'],
        );
      },
    );

    test(
      'should place all quote == null items at the end of the result when sorting a mixed list with SortCriteria.priceDesc',
      () {
        final items = [
          _itemFor('005930', quote: null),
          _itemFor(
            '000660',
            quote: _quoteFor('000660', currentPrice: 120000, previousClose: 119000),
          ),
          _itemFor('035420', quote: null),
          _itemFor(
            '005380',
            quote: _quoteFor('005380', currentPrice: 90000, previousClose: 91000),
          ),
        ];

        final sorted = sortWatchlistItems(items, SortCriteria.priceDesc);

        final lastTwoSymbols = sorted
            .sublist(sorted.length - 2)
            .map((item) => item.symbol)
            .toSet();
        expect(lastTwoSymbols, {'005930', '035420'});
        expect(sorted[0].quote, isNotNull);
        expect(sorted[1].quote, isNotNull);
      },
    );

    test(
      'should place all quote == null items at the end of the result when sorting a mixed list with SortCriteria.changeRateDesc',
      () {
        final items = [
          _itemFor('005930', quote: null),
          _itemFor(
            '000660',
            quote: _quoteFor('000660', currentPrice: 120000, previousClose: 119000),
          ),
          _itemFor('035420', quote: null),
          _itemFor(
            '005380',
            quote: _quoteFor('005380', currentPrice: 99000, previousClose: 90000),
          ),
        ];

        final sorted = sortWatchlistItems(items, SortCriteria.changeRateDesc);

        final lastTwoSymbols = sorted
            .sublist(sorted.length - 2)
            .map((item) => item.symbol)
            .toSet();
        expect(lastTwoSymbols, {'005930', '035420'});
        expect(sorted[0].quote, isNotNull);
        expect(sorted[1].quote, isNotNull);
      },
    );

    test(
      'should return the original order without throwing when every item has quote == null and sorted with SortCriteria.priceDesc',
      () {
        final items = [
          _itemFor('005930', quote: null),
          _itemFor('000660', quote: null),
          _itemFor('035420', quote: null),
        ];

        final sorted = sortWatchlistItems(items, SortCriteria.priceDesc);

        expect(
          sorted.map((item) => item.symbol).toList(),
          ['005930', '000660', '035420'],
        );
      },
    );

    test(
      'should return an empty list when sorting an empty list with any SortCriteria',
      () {
        for (final criteria in SortCriteria.values) {
          final sorted = sortWatchlistItems(<WatchlistItem>[], criteria);
          expect(sorted, isEmpty);
        }
      },
    );

    test(
      'should return a list containing only that one item when sorting a single-item list',
      () {
        final items = [
          _itemFor(
            '005930',
            quote: _quoteFor('005930', currentPrice: 70000, previousClose: 69000),
          ),
        ];

        final sorted = sortWatchlistItems(items, SortCriteria.priceDesc);

        expect(sorted, hasLength(1));
        expect(sorted.single.symbol, '005930');
      },
    );

    test(
      'should not change the order of the original input list passed as an argument after calling sortWatchlistItems',
      () {
        final items = [
          _itemFor(
            '005930',
            quote: _quoteFor('005930', currentPrice: 70000, previousClose: 69000),
          ),
          _itemFor(
            '000660',
            quote: _quoteFor('000660', currentPrice: 120000, previousClose: 119000),
          ),
          _itemFor(
            '035420',
            quote: _quoteFor('035420', currentPrice: 90000, previousClose: 91000),
          ),
        ];
        final originalOrder = items.map((item) => item.symbol).toList();

        sortWatchlistItems(items, SortCriteria.priceDesc);

        expect(items.map((item) => item.symbol).toList(), originalOrder);
      },
    );
  });
}
