import 'package:edencrew_assignment_starter/entities/quote/quote.dart';
import 'package:edencrew_assignment_starter/entities/stock_meta/stock_meta.dart';
import 'package:edencrew_assignment_starter/entities/watchlist/watchlist_item.dart';
import 'package:edencrew_assignment_starter/features/watchlist-list/watchlist_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

const _sampleItem = WatchlistItem(
  symbol: '005930',
  stockMeta: StockMeta(symbol: '005930', name: '삼성전자', marketName: '코스피'),
  quote: Quote(
    symbol: '005930',
    currentPrice: 70000,
    previousClose: 69000,
    open: 69500,
    high: 70500,
    low: 69000,
    volume: 1000000,
    countOfListedStock: 5969782550,
  ),
);

Finder _closeIconFinder() {
  return find.byWidgetPredicate(
    (widget) =>
        widget is SvgPicture &&
        (widget.bytesLoader as SvgAssetLoader).assetName ==
            'assets/icons/ico_close.svg',
  );
}

Future<void> _pumpWatchlistRow(
  WidgetTester tester, {
  void Function(String symbol)? onTap,
  void Function(String symbol)? onRemoveTap,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: WatchlistRow(
          item: _sampleItem,
          onTap: onTap ?? (_) {},
          onRemoveTap: onRemoveTap ?? (_) {},
        ),
      ),
    ),
  );
}

void main() {
  group('WatchlistRow', () {
    testWidgets('close 아이콘이 표시된다', (tester) async {
      await _pumpWatchlistRow(tester);

      expect(_closeIconFinder(), findsOneWidget);
    });

    testWidgets('행(close 아이콘 영역 제외)을 탭하면 onTap이 symbol과 함께 호출된다', (
      tester,
    ) async {
      String? tappedSymbol;
      await _pumpWatchlistRow(tester, onTap: (symbol) => tappedSymbol = symbol);

      await tester.tap(find.text('삼성전자'));
      await tester.pump();

      expect(tappedSymbol, '005930');
    });

    testWidgets('close 아이콘을 탭하면 onRemoveTap이 symbol과 함께 호출된다', (
      tester,
    ) async {
      String? removedSymbol;
      await _pumpWatchlistRow(
        tester,
        onRemoveTap: (symbol) => removedSymbol = symbol,
      );

      await tester.tap(_closeIconFinder());
      await tester.pump();

      expect(removedSymbol, '005930');
    });

    testWidgets('close 아이콘을 탭해도 onTap은 호출되지 않는다', (tester) async {
      String? tappedSymbol;
      await _pumpWatchlistRow(tester, onTap: (symbol) => tappedSymbol = symbol);

      await tester.tap(_closeIconFinder());
      await tester.pump();

      expect(tappedSymbol, isNull);
    });
  });
}
