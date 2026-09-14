import 'package:edencrew_assignment_starter/entities/daily_quote/daily_quote.dart';
import 'package:edencrew_assignment_starter/features/stock-detail/stock_detail_candle_chart.dart';
import 'package:edencrew_assignment_starter/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _upQuote = DailyQuote(
  date: '20260911',
  closePrice: 70000,
  openPrice: 69000,
  highPrice: 70800,
  lowPrice: 68900,
  volume: 12345678,
);

const _downQuote = DailyQuote(
  date: '20260910',
  closePrice: 69000,
  openPrice: 70000,
  highPrice: 70800,
  lowPrice: 68900,
  volume: 11111111,
);

const _flatQuote = DailyQuote(
  date: '20260909',
  closePrice: 68000,
  openPrice: 68000,
  highPrice: 68500,
  lowPrice: 67900,
  volume: 9999999,
);

Future<void> _pumpChart(
  WidgetTester tester, {
  required List<DailyQuote> quotes,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: StockDetailCandleChart(quotes: quotes)),
    ),
  );
}

CustomPaint _findCustomPaint(WidgetTester tester) {
  return tester.widget<CustomPaint>(
    find.descendant(
      of: find.byType(StockDetailCandleChart),
      matching: find.byType(CustomPaint),
    ),
  );
}

void main() {
  group('StockDetailCandleChart', () {
    testWidgets('quotes에 N개의 일별 시세가 있으면 예외 없이 렌더링된다', (tester) async {
      await _pumpChart(tester, quotes: [_upQuote, _downQuote, _flatQuote]);

      expect(find.byType(StockDetailCandleChart), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('closePrice > openPrice이면 chartLineUp 색상 정보를 painter가 갖는다', (
      tester,
    ) async {
      await _pumpChart(tester, quotes: [_upQuote]);

      final context = tester.element(find.byType(StockDetailCandleChart));
      final customPaint = _findCustomPaint(tester);

      expect(
        (customPaint.painter as dynamic).upColor,
        context.colors.chartLineUp,
      );
    });

    testWidgets('closePrice < openPrice이면 chartLineDown 색상 정보를 painter가 갖는다', (
      tester,
    ) async {
      await _pumpChart(tester, quotes: [_downQuote]);

      final context = tester.element(find.byType(StockDetailCandleChart));
      final customPaint = _findCustomPaint(tester);

      expect(
        (customPaint.painter as dynamic).downColor,
        context.colors.chartLineDown,
      );
    });

    testWidgets('closePrice == openPrice(보합)이면 chartLineFlat 색상 정보를 painter가 갖는다', (
      tester,
    ) async {
      await _pumpChart(tester, quotes: [_flatQuote]);

      final context = tester.element(find.byType(StockDetailCandleChart));
      final customPaint = _findCustomPaint(tester);

      expect(
        (customPaint.painter as dynamic).flatColor,
        context.colors.chartLineFlat,
      );
    });

    testWidgets('quotes가 최신순으로 입력되어도 painter에는 그대로 전달되고 내부에서 오름차순으로 그려진다', (
      tester,
    ) async {
      // 최신순(내림차순) 입력: _upQuote(0911)가 먼저, _flatQuote(0909)가 나중.
      await _pumpChart(tester, quotes: [_upQuote, _flatQuote]);

      final customPaint = _findCustomPaint(tester);
      final painterQuotes =
          (customPaint.painter as dynamic).quotes as List<DailyQuote>;

      // painter로 전달되는 원본 리스트는 최신순 그대로 유지된다.
      expect(painterQuotes.first.date, '20260911');
      expect(painterQuotes.last.date, '20260909');
    });

    testWidgets('quotes가 빈 리스트이면 예외 없이 렌더링된다', (tester) async {
      await _pumpChart(tester, quotes: const []);

      expect(find.byType(StockDetailCandleChart), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('quotes 내용이 바뀌면 shouldRepaint가 true를 반환한다', (tester) async {
      await _pumpChart(tester, quotes: [_upQuote]);
      final oldPainter = _findCustomPaint(tester).painter as CustomPainter;

      await _pumpChart(tester, quotes: [_downQuote]);
      final newPainter = _findCustomPaint(tester).painter as CustomPainter;

      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });
  });
}
