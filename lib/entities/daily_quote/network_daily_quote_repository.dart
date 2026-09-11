import '../../shared/api/api_client.dart';
import '../../shared/error/failure.dart';
import '../../shared/utils/euc_kr_decoder.dart';
import 'daily_quote.dart';
import 'daily_quote_page_parser.dart';
import 'daily_quote_repository.dart';

/// symbol 하나에 대한 캐시 상태입니다. "다음에 가져올 페이지 번호"와
/// "이미 알고 있는 lastPage"를 함께 관리합니다.
class _SymbolCacheState {
  int nextPageToFetch = 1;
  int? lastPage;
}

/// Naver 일별 시세 HTML(`finance.naver.com/item/sise_day.naver`)을 호출하는
/// 구현체입니다.
///
/// symbol별로 "다음에 가져올 페이지 번호"를 기억해두고, 호출할 때마다 그
/// 다음 페이지 하나만 요청합니다 — 같은 페이지를 두 번 요청하는 일이 구조상
/// 없고, `lastPage`를 넘는 페이지도 요청하지 않습니다.
class NetworkDailyQuoteRepository implements DailyQuoteRepository {
  NetworkDailyQuoteRepository(this._apiClient);

  final ApiClient _apiClient;
  final Map<String, _SymbolCacheState> _cache = {};

  static final _baseUri = Uri.parse(
    'https://finance.naver.com/item/sise_day.naver',
  );

  @override
  Future<List<DailyQuote>> fetchNextPage(String symbol) async {
    final state = _cache.putIfAbsent(symbol, () => _SymbolCacheState());

    if (state.lastPage != null && state.nextPageToFetch > state.lastPage!) {
      return [];
    }

    final page = state.nextPageToFetch;
    final uri = _baseUri.replace(
      queryParameters: {'code': symbol, 'page': '$page'},
    );

    try {
      final response = await _apiClient.get(uri);
      if (response.bodyBytes.isEmpty) {
        throw const EmptyResultFailure();
      }

      final html = eucKr.decode(response.bodyBytes);
      final parsedPage = parseDailyQuotePage(html);

      state.lastPage = parsedPage.lastPage;
      state.nextPageToFetch = page + 1;

      return parsedPage.quotes;
    } on Failure {
      rethrow;
    } catch (e) {
      throw NetworkFailure('$e');
    }
  }
}
