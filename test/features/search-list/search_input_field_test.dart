import 'package:edencrew_assignment_starter/features/search-list/search_input_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SearchInputField', () {
    testWidgets(
      'should call onChanged with the raw input string when text is typed',
      (WidgetTester tester) async {
        String? received;
        final controller = TextEditingController();

        await tester.pumpWidget(
          MaterialApp(
            home: SearchInputField(
              controller: controller,
              onChanged: (value) => received = value,
              onClear: () {},
            ),
          ),
        );

        await tester.enterText(find.byType(TextField), '삼성전자');

        expect(received, '삼성전자');
      },
    );

    testWidgets(
      'should call onClear when the clear (X) button is tapped',
      (WidgetTester tester) async {
        var cleared = false;
        final controller = TextEditingController(text: '삼성전자');

        await tester.pumpWidget(
          MaterialApp(
            home: SearchInputField(
              controller: controller,
              onChanged: (_) {},
              onClear: () => cleared = true,
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.clear));

        expect(cleared, isTrue);
      },
    );

    testWidgets(
      'should always show the clear (X) button even when the text field is empty',
      (WidgetTester tester) async {
        final controller = TextEditingController();

        await tester.pumpWidget(
          MaterialApp(
            home: SearchInputField(
              controller: controller,
              onChanged: (_) {},
              onClear: () {},
            ),
          ),
        );

        expect(find.byIcon(Icons.clear), findsOneWidget);
      },
    );
  });
}
