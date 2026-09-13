import 'package:edencrew_assignment_starter/entities/quote/quote.dart';
import 'package:edencrew_assignment_starter/features/stock-detail/stock_detail_price_section.dart';
import 'package:edencrew_assignment_starter/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpPriceSection(WidgetTester tester, Quote quote) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: StockDetailPriceSection(quote: quote)),
    ),
  );
}

const _upQuote = Quote(
  symbol: '005930',
  currentPrice: 70000,
  previousClose: 69000,
  open: 69500,
  high: 70500,
  low: 69000,
  volume: 1000000,
  countOfListedStock: 5969782550,
);

const _downQuote = Quote(
  symbol: '005930',
  currentPrice: 68000,
  previousClose: 69000,
  open: 69500,
  high: 69800,
  low: 67900,
  volume: 1000000,
  countOfListedStock: 5969782550,
);

const _flatQuote = Quote(
  symbol: '005930',
  currentPrice: 69000,
  previousClose: 69000,
  open: 69000,
  high: 69200,
  low: 68900,
  volume: 1000000,
  countOfListedStock: 5969782550,
);

void main() {
  group('StockDetailPriceSection', () {
    testWidgets('현재가가 콤마 포맷으로 표시된다', (tester) async {
      await _pumpPriceSection(tester, _upQuote);

      expect(find.textContaining('70,000'), findsOneWidget);
    });

    testWidgets('changeAmount가 양수면 상승 아이콘과 priceUpText 색상으로 표시된다', (
      tester,
    ) async {
      await _pumpPriceSection(tester, _upQuote);

      final context = tester.element(find.byType(StockDetailPriceSection));
      final colors = context.colors;

      expect(find.byIcon(Icons.arrow_drop_up), findsOneWidget);

      final changeText = tester.widget<Text>(
        find.textContaining('1,000').first,
      );
      expect(changeText.style?.color, colors.priceUpText);
    });

    testWidgets('changeAmount가 음수면 하락 아이콘과 priceDownText 색상으로 표시된다', (
      tester,
    ) async {
      await _pumpPriceSection(tester, _downQuote);

      final context = tester.element(find.byType(StockDetailPriceSection));
      final colors = context.colors;

      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);

      final changeText = tester.widget<Text>(
        find.textContaining('1,000').first,
      );
      expect(changeText.style?.color, colors.priceDownText);
    });

    testWidgets('changeAmount가 0이면 보합 상태(priceFlatText 색상, 방향 아이콘 없음)로 표시된다', (
      tester,
    ) async {
      await _pumpPriceSection(tester, _flatQuote);

      final context = tester.element(find.byType(StockDetailPriceSection));
      final colors = context.colors;

      expect(find.byIcon(Icons.arrow_drop_up), findsNothing);
      expect(find.byIcon(Icons.arrow_drop_down), findsNothing);

      final changeText = tester.widget<Text>(find.text('0 (0.00%)'));
      expect(changeText.style?.color, colors.priceFlatText);
    });
  });
}
