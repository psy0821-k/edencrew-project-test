/// 종목의 메타데이터입니다. (종목명, 거래소명 등 자주 바뀌지 않는 정보)
class StockMeta {
  const StockMeta({
    required this.symbol,
    required this.name,
    required this.marketName,
  });

  /// 6자리 종목코드. 예: `005930`
  final String symbol;

  /// 종목명. 예: `삼성전자`
  final String name;

  /// 거래소명. 예: `코스피`
  final String marketName;
}
