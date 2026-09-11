import 'dart:convert';

import '../../shared/api/api_client.dart';
import '../../shared/error/failure.dart';
import 'stock_meta.dart';
import 'stock_meta_repository.dart';

/// Naver 종목 메타데이터 API
/// (`stock.naver.com/api/securityFe/api/fchart/domestic/stock/{symbol}`)를
/// 호출하는 구현체입니다.
class NetworkStockMetaRepository implements StockMetaRepository {
  NetworkStockMetaRepository(this._apiClient);

  final ApiClient _apiClient;

  static Uri _uriFor(String symbol) => Uri.parse(
    'https://stock.naver.com/api/securityFe/api/fchart/domestic/stock/$symbol',
  );

  @override
  Future<StockMeta> fetchStockMeta(String symbol) async {
    try {
      final response = await _apiClient.get(_uriFor(symbol));
      if (response.body.isEmpty) {
        throw const EmptyResultFailure();
      }

      final Map<String, dynamic> json;
      try {
        json = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        throw const ParsingFailure();
      }

      final symbolCode = json['symbolCode'];
      final stockName = json['stockName'];
      final marketName = json['stockExchangeNameKor'];
      if (symbolCode is! String ||
          stockName is! String ||
          marketName is! String) {
        throw const ParsingFailure();
      }

      return StockMeta(
        symbol: symbolCode,
        name: stockName,
        marketName: marketName,
      );
    } on Failure {
      rethrow;
    } catch (e) {
      throw NetworkFailure('$e');
    }
  }
}
