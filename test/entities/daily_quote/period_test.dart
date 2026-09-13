import 'package:edencrew_assignment_starter/entities/daily_quote/period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Period', () {
    test('oneMonth의 requiredPageCount는 2다', () {
      expect(Period.oneMonth.requiredPageCount, 2);
    });

    test('threeMonths의 requiredPageCount는 6이다', () {
      expect(Period.threeMonths.requiredPageCount, 6);
    });

    test('sixMonths의 requiredPageCount는 12다', () {
      expect(Period.sixMonths.requiredPageCount, 12);
    });

    test('oneYear의 requiredPageCount는 25다', () {
      expect(Period.oneYear.requiredPageCount, 25);
    });
  });
}
