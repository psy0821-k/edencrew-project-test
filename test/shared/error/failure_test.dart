import 'package:edencrew_assignment_starter/shared/error/failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Failure', () {
    test('NetworkFailure는 Failure의 하위 타입이다', () {
      const failure = NetworkFailure();
      expect(failure, isA<Failure>());
    });

    test('ParsingFailure는 Failure의 하위 타입이다', () {
      const failure = ParsingFailure();
      expect(failure, isA<Failure>());
    });

    test('EmptyResultFailure는 Failure의 하위 타입이다', () {
      const failure = EmptyResultFailure();
      expect(failure, isA<Failure>());
    });

    test('커스텀 메시지를 지정할 수 있다', () {
      const failure = NetworkFailure('연결 시간이 초과되었습니다.');
      expect(failure.message, '연결 시간이 초과되었습니다.');
    });
  });
}
