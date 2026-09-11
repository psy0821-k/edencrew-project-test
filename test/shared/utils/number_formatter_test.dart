import 'package:edencrew_assignment_starter/shared/utils/number_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NumberFormatter.comma', () {
    test('천 단위 콤마를 넣는다', () {
      expect(NumberFormatter.comma(200000), '200,000');
    });
  });

  group('NumberFormatter.compactKorean', () {
    test('조 단위로 축약한다', () {
      // 1,063조 = 1,063,000,000,000,000 (1조 = 10^12)
      expect(NumberFormatter.compactKorean(1063000000000000), '1,063조');
    });

    test('천 단위로 축약한다', () {
      // 29,113천 = 29,113,000
      expect(NumberFormatter.compactKorean(29113000), '29,113천');
    });

    test('1000 미만은 그대로 콤마만 적용한다', () {
      expect(NumberFormatter.compactKorean(999), '999');
    });
  });
}
