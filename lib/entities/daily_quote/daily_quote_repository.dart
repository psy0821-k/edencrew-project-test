import 'daily_quote.dart';
import 'period.dart';

/// 일별 시세를 기간(Period) 단위로 조회하는 방법을 추상화합니다.
///
/// 구현체는 [MockDailyQuoteRepository](고정 데이터 반환)와
/// [NetworkDailyQuoteRepository](Naver 일별 시세 HTML을 페이지 단위로 캐싱하며
/// 호출) 두 가지가 있으며, `dataSourceModeProvider`가 어떤 구현체를 쓸지
/// 결정합니다.
abstract interface class DailyQuoteRepository {
  /// [symbol]의 [period]가 요구하는 만큼의 일별 시세를 최신순으로 반환합니다.
  ///
  /// 이미 캐시된 페이지는 재사용하고, 부족한 페이지만 추가로 요청합니다.
  /// lastPage보다 큰 페이지는 요청하지 않고, 있는 데이터만 반환합니다.
  Future<List<DailyQuote>> fetchQuotes(String symbol, Period period);
}
