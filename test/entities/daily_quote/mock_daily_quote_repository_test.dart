import 'package:edencrew_assignment_starter/entities/daily_quote/mock_daily_quote_repository.dart';
import 'package:edencrew_assignment_starter/entities/daily_quote/period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MockDailyQuoteRepository', () {
    test('Period.oneMonth를 요청하면 고정된 DailyQuote 목록이 반환된다', () async {
      final repository = MockDailyQuoteRepository();

      final quotes = await repository.fetchQuotes('005930', Period.oneMonth);

      expect(quotes, isNotEmpty);
    });

    test('Period가 다르면 반환되는 목록 길이도 다르다(oneYear > oneMonth)', () async {
      final repository = MockDailyQuoteRepository();

      final oneMonth = await repository.fetchQuotes('005930', Period.oneMonth);
      final oneYear = await repository.fetchQuotes('005930', Period.oneYear);

      expect(oneYear.length, greaterThan(oneMonth.length));
    });
  });
}
