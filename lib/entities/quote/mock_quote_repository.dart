import 'quote.dart';
import 'quote_repository.dart';

/// 네트워크 호출 없이 고정된 시세를 반환하는 테스트/개발용 구현체입니다.
class MockQuoteRepository implements QuoteRepository {
  @override
  Future<Map<String, Quote>> fetchQuotes(List<String> symbols) async {
    return {
      for (final symbol in symbols)
        symbol: Quote(
          symbol: symbol,
          currentPrice: 70000,
          previousClose: 70400,
          open: 70200,
          high: 70800,
          low: 69900,
          volume: 12345678,
          countOfListedStock: 5969782550,
        ),
    };
  }
}
