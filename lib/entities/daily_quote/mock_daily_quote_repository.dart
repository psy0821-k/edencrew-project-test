import 'daily_quote.dart';
import 'daily_quote_repository.dart';

/// 네트워크 호출 없이 고정된 일별 시세를 반환하는 테스트/개발용 구현체입니다.
///
/// symbol별로 호출 횟수를 세어, 호출할 때마다 하루씩 과거로 이동한
/// 고정 데이터를 반환합니다(무한 스크롤 동작을 mock에서도 재현하기 위함).
class MockDailyQuoteRepository implements DailyQuoteRepository {
  final Map<String, int> _callCount = {};

  @override
  Future<List<DailyQuote>> fetchNextPage(String symbol) async {
    final page = (_callCount[symbol] ?? 0) + 1;
    _callCount[symbol] = page;

    return List.generate(10, (i) {
      final dayOffset = (page - 1) * 10 + i;
      final date = DateTime(2026, 9, 11).subtract(Duration(days: dayOffset));
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
