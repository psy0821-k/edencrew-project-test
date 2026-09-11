import 'package:edencrew_assignment_starter/shared/utils/debouncer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Debouncer', () {
    test('짧은 간격으로 연속 호출하면 마지막 호출의 콜백만 실행된다', () async {
      final debouncer = Debouncer(const Duration(milliseconds: 50));
      final calls = <int>[];

      debouncer.run(() => calls.add(1));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      debouncer.run(() => calls.add(2));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      debouncer.run(() => calls.add(3));
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(calls, [3]);
    });

    test('dispose 이후에는 예약된 콜백이 실행되지 않는다', () async {
      final debouncer = Debouncer(const Duration(milliseconds: 50));
      var called = false;

      debouncer.run(() => called = true);
      debouncer.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(called, isFalse);
    });
  });
}
