import '../../shared/api/api_client.dart';
import '../../shared/error/failure.dart';
import '../../shared/utils/euc_kr_decoder.dart';
import 'daily_quote.dart';
import 'daily_quote_page_parser.dart';
import 'daily_quote_repository.dart';
import 'period.dart';

/// symbol 하나에 대한 캐시 상태입니다. 페이지 번호별로 실제 조회 결과
/// (`DailyQuote` 목록)와, 알고 있는 `lastPage`를 함께 관리합니다.
class _SymbolPageCache {
  final Map<int, List<DailyQuote>> pages = {};
  int? lastPage;
}

/// Naver 일별 시세 HTML(`finance.naver.com/item/sise_day.naver`)을 호출하는
/// 구현체입니다.
///
/// symbol별로 이미 받은 페이지를 캐시해두고, `Period`가 요구하는 페이지 중
/// 캐시에 없는 것만 순차로 요청합니다(동시에 여러 페이지를 요청하지 않음 —
/// `docs/NAVER_API.md`가 "페이지를 이어서 받고 재사용"을 요구하기 때문).
class NetworkDailyQuoteRepository implements DailyQuoteRepository {
  NetworkDailyQuoteRepository(this._apiClient);

  final ApiClient _apiClient;
  final Map<String, _SymbolPageCache> _cache = {};

  static final _baseUri = Uri.parse(
    'https://finance.naver.com/item/sise_day.naver',
  );

  @override
  Future<List<DailyQuote>> fetchQuotes(String symbol, Period period) async {
    final cache = _cache.putIfAbsent(symbol, () => _SymbolPageCache());

    for (var page = 1; page <= period.requiredPageCount; page++) {
      if (cache.lastPage != null && page > cache.lastPage!) break;
      if (cache.pages.containsKey(page)) continue;

      final parsedPage = await _fetchPage(symbol, page);
      cache.lastPage = parsedPage.lastPage;
      cache.pages[page] = parsedPage.quotes;

      if (page >= parsedPage.lastPage) break;
    }

    final targetPageCount = cache.lastPage == null
        ? period.requiredPageCount
        : period.requiredPageCount.clamp(0, cache.lastPage!);

    final result = <DailyQuote>[];
    for (var page = 1; page <= targetPageCount; page++) {
      final pageQuotes = cache.pages[page];
      if (pageQuotes == null) break;
      result.addAll(pageQuotes);
    }
    return result;
  }

  Future<({List<DailyQuote> quotes, int lastPage})> _fetchPage(
    String symbol,
    int page,
  ) async {
    final uri = _baseUri.replace(
      queryParameters: {'code': symbol, 'page': '$page'},
    );

    try {
      final response = await _apiClient.get(uri);
      if (response.bodyBytes.isEmpty) {
        throw const EmptyResultFailure();
      }

      final html = eucKr.decode(response.bodyBytes);
      final parsed = parseDailyQuotePage(html);
      return (quotes: parsed.quotes, lastPage: parsed.lastPage);
    } on Failure {
      rethrow;
    } catch (e) {
      throw NetworkFailure('$e');
    }
  }
}
