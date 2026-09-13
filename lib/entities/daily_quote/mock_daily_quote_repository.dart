import 'daily_quote.dart';
import 'daily_quote_repository.dart';
import 'period.dart';

/// 네트워크 호출 없이 고정된 일별 시세를 반환하는 테스트/개발용 구현체입니다.
///
/// [period]가 요구하는 페이지 수(10거래일 단위)만큼 고정 데이터를 생성해
/// 반환합니다.
class MockDailyQuoteRepository implements DailyQuoteRepository {
  @override
  Future<List<DailyQuote>> fetchQuotes(String symbol, Period period) async {
    final dayCount = period.requiredPageCount * 10;

    return List.generate(dayCount, (i) {
      final date = DateTime(2026, 9, 11).subtract(Duration(days: i));
      final dateStr =
          '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
      return DailyQuote(
        date: dateStr,
        closePrice: 70000,
        openPrice: 70200,
        highPrice: 70800,
        lowPrice: 69900,
        volume: 12345678,
      );
    });
  }
}
