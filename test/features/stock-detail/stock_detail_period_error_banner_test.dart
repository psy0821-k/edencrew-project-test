import 'package:edencrew_assignment_starter/features/stock-detail/stock_detail_period_error_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StockDetailPeriodErrorBanner', () {
    testWidgets('다시 시도 버튼을 탭하면 onRetryTap이 호출된다', (tester) async {
      var retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StockDetailPeriodErrorBanner(
              onRetryTap: () => retried = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('다시 시도'));
      await tester.pump();

      expect(retried, isTrue);
    });
  });
}
