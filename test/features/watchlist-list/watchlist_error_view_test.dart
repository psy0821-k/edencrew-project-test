import 'package:edencrew_assignment_starter/features/watchlist-list/watchlist_error_view.dart';
import 'package:edencrew_assignment_starter/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WatchlistErrorView', () {
    testWidgets(
      'should call onRetryTap when the retry button is tapped',
      (WidgetTester tester) async {
        var retryTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: WatchlistErrorView(
                onRetryTap: () => retryTapped = true,
              ),
            ),
          ),
        );

        await tester.tap(find.text('다시 시도'));
        await tester.pump();

        expect(retryTapped, isTrue);
      },
    );
  });
}
