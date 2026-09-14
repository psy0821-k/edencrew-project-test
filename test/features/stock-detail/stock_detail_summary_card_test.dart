import 'package:edencrew_assignment_starter/entities/daily_quote/daily_quote.dart';
import 'package:edencrew_assignment_starter/features/stock-detail/stock_detail_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _sampleDailyQuote = DailyQuote(
  date: '20260911',
  closePrice: 70000,
  openPrice: 70200,
  highPrice: 70800,
  lowPrice: 69900,
  volume: 29113000,
);

Future<void> _pumpSummaryCard(WidgetTester tester, {int marketCap = 1063000000000000}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StockDetailSummaryCard(
          latestDailyQuote: _sampleDailyQuote,
          marketCap: marketCap,
        ),
      ),
    ),
  );
}

void main() {
  group('StockDetailSummaryCard', () {
    testWidgets('시가/고가/저가가 DailyQuote의 값 그대로 표시된다', (tester) async {
      await _pumpSummaryCard(tester);

      expect(find.textContaining('70,200'), findsOneWidget); // 시가
      expect(find.textContaining('70,800'), findsOneWidget); // 고가
      expect(find.textContaining('69,900'), findsOneWidget); // 저가
    });

    testWidgets('거래량이 NumberFormatter.compactKorean으로 축약되어 표시된다', (
      tester,
    ) async {
      await _pumpSummaryCard(tester);

      expect(find.textContaining('29,113천'), findsOneWidget);
    });

    testWidgets('시가총액이 NumberFormatter.compactKorean으로 축약되어 표시된다', (
      tester,
    ) async {
      await _pumpSummaryCard(tester, marketCap: 1063000000000000);

      expect(find.textContaining('1,063조'), findsOneWidget);
    });

    testWidgets('각 항목(시가/고가/저가/거래량/시가총액) 컨테이너 높이는 55px로 고정된다', (
      tester,
    ) async {
      await _pumpSummaryCard(tester);

      final containers = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) => c.constraints?.maxHeight == 55)
          .toList();

      expect(containers.length, 5);
    });
  });
}
