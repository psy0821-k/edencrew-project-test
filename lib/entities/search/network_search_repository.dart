import 'dart:convert';

import '../../shared/api/api_client.dart';
import '../../shared/error/failure.dart';
import '../stock_meta/stock_meta_repository.dart';
import 'search_repository.dart';
import 'search_result.dart';

/// 6자리 종목코드만 통과시키는 정규식입니다.
final _sixDigitSymbol = RegExp(r'^\d{6}$');

/// Naver 검색 자동완성 API(`ac.stock.naver.com/ac`)를 호출하는 구현체입니다.
///
/// 응답의 `items`는 국내 주식뿐 아니라 해외 주식, ETF/ETN 등이 섞여 오므로
/// 국내 6자리 종목코드만 남긴 뒤 [StockMetaRepository]로 거래소명을 보강합니다.
class NetworkSearchRepository implements SearchRepository {
  NetworkSearchRepository(this._apiClient, this._stockMetaRepository);

  final ApiClient _apiClient;
  final StockMetaRepository _stockMetaRepository;

  static final _baseUri = Uri.parse('https://ac.stock.naver.com/ac');

  @override
  Future<List<SearchResult>> search(String query) async {
    final uri = _baseUri.replace(
      queryParameters: {'q': query, 'target': 'stock'},
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

      final items = json['items'] as List?;
      if (items == null) {
        throw const ParsingFailure();
      }

      final domesticStocks = items
          .map((item) => _parseItem(item as Map<String, dynamic>))
          .where(
            (item) =>
                item.nationCode == 'KOR' && _sixDigitSymbol.hasMatch(item.code),
          );

      final results = <SearchResult>[];
      for (final item in domesticStocks) {
        final meta = await _stockMetaRepository.fetchStockMeta(item.code);
        results.add(
          SearchResult(
            symbol: item.code,
            name: item.name,
            marketName: meta.marketName,
          ),
        );
      }
      return results;
    } on Failure {
      rethrow;
    } catch (e) {
      throw NetworkFailure('$e');
    }
  }

  _AutocompleteItem _parseItem(Map<String, dynamic> item) {
    final code = item['code'];
    final name = item['name'];
    final nationCode = item['nationCode'];
    if (code is! String || name is! String) {
      throw const ParsingFailure();
    }
    return _AutocompleteItem(
      code: code,
      name: name,
      nationCode: nationCode is String ? nationCode : '',
    );
  }
}

class _AutocompleteItem {
  const _AutocompleteItem({
    required this.code,
    required this.name,
    required this.nationCode,
  });

  final String code;
  final String name;
  final String nationCode;
}
