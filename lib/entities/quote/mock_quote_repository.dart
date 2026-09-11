import 'quote.dart';
import 'quote_repository.dart';

/// 네트워크 호출 없이 고정된 시세를 반환하는 테스트/개발용 구현체입니다.
///
/// Naver 서버가 차단되었거나 위젯 테스트에서 네트워크 의존 없이 화면을
/// 확인하고 싶을 때 `dataSourceModeProvider`를 `mock`으로 바꾸면 이 구현체가
/// 자동으로 선택됩니다.
class MockQuoteRepository implements QuoteRepository {
  @override
  Future<Map<String, Quote>> fetchQuotes(List<String> symbols) async {
    return {
      for (final symbol in symbols)
        symbol: Quote(
          symbol: symbol,
          currentPrice: 70000,
          previousClose: 70400,
        ),
    };
  }
}
