import 'package:edencrew_assignment_starter/entities/daily_quote/daily_quote.dart';
import 'package:edencrew_assignment_starter/features/stock-detail/stock_detail_daily_quote_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _quotes = [
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

Future<void> _pumpTable(WidgetTester tester, {List<DailyQuote> quotes = _quotes}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StockDetailDailyQuoteTable(quotes: quotes),
      ),
    ),
  );
}

void main() {
  group('StockDetailDailyQuoteTable', () {
    testWidgets('날짜가 MM.dd 형식으로 표시된다', (tester) async {
      await _pumpTable(tester);

      expect(find.text('09.11'), findsOneWidget);
      expect(find.text('09.10'), findsOneWidget);
    });

    testWidgets('각 행의 등락이 formatDailyQuoteChange 결과(부호+색상)로 표시된다', (
      tester,
    ) async {
      await _pumpTable(tester);

      // 70000 - 69000 = +1,000
      expect(find.textContaining('+1,000'), findsOneWidget);
    });

    testWidgets('목록의 마지막 행(그 기간의 가장 오래된 데이터)은 등락이 0으로 표시된다', (
      tester,
    ) async {
      await _pumpTable(tester);

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('거래량은 축약 없이 콤마 포맷 원본 숫자로 표시된다', (tester) async {
      await _pumpTable(tester);

      expect(find.text('12,345,678'), findsOneWidget);
      expect(find.textContaining('천'), findsNothing);
    });
  });
}
