import 'package:edencrew_assignment_starter/entities/daily_quote/daily_quote_providers.dart';
import 'package:edencrew_assignment_starter/entities/daily_quote/period.dart';
import 'package:edencrew_assignment_starter/features/stock-detail/stock_detail_period_tabs.dart';
import 'package:edencrew_assignment_starter/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpPeriodTabs(WidgetTester tester) async {
  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: StockDetailPeriodTabs()),
      ),
    ),
  );
}

void main() {
  group('StockDetailPeriodTabs', () {
    testWidgets('selectedPeriodProvider가 oneMonth면 1개월 탭이 accentDefault/accentBg 스타일로 표시된다', (
      tester,
    ) async {
      await _pumpPeriodTabs(tester);

      final context = tester.element(find.byType(StockDetailPeriodTabs));
      final colors = context.colors;

      final text = tester.widget<Text>(find.text('1개월'));
      expect(text.style?.color, colors.accentDefault);
    });

    testWidgets('3개월 탭을 탭하면 selectedPeriodProvider가 threeMonths로 바뀐다', (
      tester,
    ) async {
      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              return const MaterialApp(
                home: Scaffold(body: StockDetailPeriodTabs()),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('3개월'));
      await tester.pump();

      expect(container.read(selectedPeriodProvider), Period.threeMonths);
    });

    testWidgets('탭을 전환하면 이전에 선택됐던 탭은 스타일이 원래대로 돌아간다', (tester) async {
      await _pumpPeriodTabs(tester);
      final context = tester.element(find.byType(StockDetailPeriodTabs));
      final colors = context.colors;

      await tester.tap(find.text('3개월'));
      await tester.pump();

      final oneMonthText = tester.widget<Text>(find.text('1개월'));
      final threeMonthsText = tester.widget<Text>(find.text('3개월'));
      expect(oneMonthText.style?.color, isNot(colors.accentDefault));
      expect(threeMonthsText.style?.color, colors.accentDefault);
    });
  });
}
