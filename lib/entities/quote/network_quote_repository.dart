import 'dart:convert';

import '../../shared/api/api_client.dart';
import '../../shared/error/failure.dart';
import 'quote.dart';
import 'quote_repository.dart';

/// Naver 실시간 시세 API(`polling.finance.naver.com/api/realtime`)를 호출하는
/// 구현체입니다.
class NetworkQuoteRepository implements QuoteRepository {
  NetworkQuoteRepository(this._apiClient);

  final ApiClient _apiClient;

  static final _baseUri = Uri.parse(
    'https://polling.finance.naver.com/api/realtime',
  );

  @override
  Future<Map<String, Quote>> fetchQuotes(List<String> symbols) async {
    if (symbols.isEmpty) return {};

    // 관심종목을 한 번의 요청으로 조회한다 (NAVER_API.md 요구사항).
    final uri = _baseUri.replace(
      queryParameters: {'query': 'SERVICE_ITEM:${symbols.join(',')}'},
    );

    try {
      final response = await _apiClient.get(uri);
      if (response.body.isEmpty) {
        throw const EmptyResultFailure();
      }

      final Map<String, dynamic> json;
      try {
        json = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        throw const ParsingFailure();
      }

      final areas =
          (json['result'] as Map<String, dynamic>?)?['areas'] as List?;
      final datas = areas?.isNotEmpty == true
          ? (areas!.first as Map<String, dynamic>)['datas'] as List?
          : null;
      if (datas == null) {
        throw const ParsingFailure();
      }
      if (datas.isEmpty) {
        throw const EmptyResultFailure();
      }

      return {
        for (final item in datas)
          ...() {
            final quote = _parseQuote(item as Map<String, dynamic>);
            return {quote.symbol: quote};
          }(),
      };
    } on Failure {
      rethrow;
    } catch (e) {
      throw NetworkFailure('$e');
    }
  }

  Quote _parseQuote(Map<String, dynamic> item) {
    final symbol = item['cd'];
    final currentPrice = item['nv'];
    final previousClose = item['pcv'];
    final open = item['ov'];
    final high = item['hv'];
    final low = item['lv'];
    final volume = item['aq'];
    final countOfListedStock = item['countOfListedStock'];

    if (symbol is! String ||
        currentPrice is! int ||
        previousClose is! int ||
        open is! int ||
        high is! int ||
        low is! int ||
        volume is! int ||
        countOfListedStock is! int) {
      throw const ParsingFailure();
    }

    return Quote(
      symbol: symbol,
      currentPrice: currentPrice,
      previousClose: previousClose,
      open: open,
      high: high,
      low: low,
      volume: volume,
      countOfListedStock: countOfListedStock,
    );
  }
}
