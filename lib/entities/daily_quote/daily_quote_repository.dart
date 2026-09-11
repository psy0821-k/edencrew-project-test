import 'daily_quote.dart';

/// 일별 시세를 무한 스크롤 방식으로 조회하는 방법을 추상화합니다.
///
/// 구현체는 [MockDailyQuoteRepository](고정 데이터 반환)와
/// [NetworkDailyQuoteRepository](Naver 일별 시세 HTML을 페이지 단위로 캐싱하며
/// 호출) 두 가지가 있으며, `dataSourceModeProvider`가 어떤 구현체를 쓸지
/// 결정합니다.
abstract interface class DailyQuoteRepository {
  /// [symbol]의 "다음 페이지"(최대 10거래일)를 가져옵니다.
  ///
  /// 이 [symbol]을 처음 요청하면 1페이지부터, 이전에 N페이지까지 가져온
  /// 적이 있다면 N+1페이지를 반환합니다. 이미 마지막 페이지까지 다 가져온
  /// 상태라면 빈 리스트를 반환합니다(더 가져올 데이터가 없음을 의미).
  Future<List<DailyQuote>> fetchNextPage(String symbol);
}
