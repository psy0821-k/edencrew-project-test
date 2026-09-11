import 'quote.dart';

/// 종목 시세를 조회하는 방법을 추상화합니다.
///
/// 구현체는 [MockQuoteRepository](실제 네트워크 없이 고정 데이터 반환)와
/// [NetworkQuoteRepository](Naver 실시간 시세 API 호출) 두 가지가 있으며,
/// `dataSourceModeProvider`가 어떤 구현체를 쓸지 결정합니다.
abstract interface class QuoteRepository {
  /// 여러 종목의 시세를 한 번에 조회합니다.
  ///
  /// 종목마다 개별 호출하지 않고 한 번의 요청으로 조회해야 합니다
  /// (`NAVER_API.md` 요구사항).
  Future<Map<String, Quote>> fetchQuotes(List<String> symbols);
}
