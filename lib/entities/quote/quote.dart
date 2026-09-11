/// 종목의 실시간 시세입니다.
class Quote {
  const Quote({
    required this.symbol,
    required this.currentPrice,
    required this.previousClose,
    required this.open,
    required this.high,
    required this.low,
    required this.volume,
    required this.countOfListedStock,
  });

  /// 6자리 종목코드. 예: `005930`
  final String symbol;

  /// 현재가
  final int currentPrice;

  /// 전일 종가
  final int previousClose;

  /// 시가
  final int open;

  /// 고가
  final int high;

  /// 저가
  final int low;

  /// 누적 거래량
  final int volume;

  /// 상장 주식 수
  final int countOfListedStock;

  /// 전일 대비 등락액. `현재가 - 전일종가`
  int get changeAmount => currentPrice - previousClose;

  /// 전일 대비 등락률(비율, 퍼센트 변환 전). `(현재가 - 전일종가) / 전일종가`
  double get changeRate => (currentPrice - previousClose) / previousClose;

  /// 시가총액. `현재가 × 상장주식수`
  int get marketCap => currentPrice * countOfListedStock;
}
