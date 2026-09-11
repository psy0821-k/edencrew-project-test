/// 검색 자동완성 결과 하나를 나타내는 모델입니다.
class SearchResult {
  const SearchResult({
    required this.symbol,
    required this.name,
    required this.marketName,
  });

  /// 6자리 종목코드. 예: `005930`
  final String symbol;

  /// 종목명. 예: `삼성전자`
  final String name;

  /// 거래소명. 예: `코스피` (StockMetaRepository로 보강됨)
  final String marketName;

  /// 관심/상세 화면과 공유하는 canonical id. `domestic:{symbol}` 형태.
  String get canonicalId => 'domestic:$symbol';
}
