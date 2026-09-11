import 'package:edencrew_assignment_starter/entities/daily_quote/mock_daily_quote_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MockDailyQuoteRepository', () {
    test('symbol별로 호출할 때마다 다음 페이지의 고정 데이터를 순서대로 반환한다', () async {
      final repository = MockDailyQuoteRepository();

      final first = await repository.fetchNextPage('005930');
      final second = await repository.fetchNextPage('005930');

      expect(first, isNotEmpty);
      expect(second, isNotEmpty);
      expect(first.first.date, isNot(second.first.date));
    });
  });
}
