import 'package:edencrew_assignment_starter/shared/utils/date_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DateFormatter', () {
    test('yyyyMMdd 문자열을 MM.dd로 변환한다', () {
      expect(DateFormatter.internalToDisplay('20260911'), '09.11');
    });

    test('yyyyMMdd 문자열을 DateTime으로 파싱한다', () {
      final parsed = DateFormatter.parseInternal('20260911');
      expect(parsed, DateTime(2026, 9, 11));
    });

    test('DateTime을 MM.dd 문자열로 변환한다', () {
      expect(DateFormatter.toDisplay(DateTime(2026, 1, 5)), '01.05');
    });

    test('8자리가 아니면 FormatException을 던진다', () {
      expect(
        () => DateFormatter.parseInternal('202609'),
        throwsFormatException,
      );
    });
  });
}
