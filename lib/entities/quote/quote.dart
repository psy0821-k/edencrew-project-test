/// 종목의 실시간 시세입니다.
///
/// Phase 0에서는 라우팅·데이터소스 스위치 구조를 검증하기 위한 최소 필드만
/// 정의합니다. 실제 Naver 응답 파싱(등락액/등락률/시가총액 계산 등)은
/// Phase 1에서 구현합니다.
class Quote {
  const Quote({
    required this.symbol,
    required this.currentPrice,
    required this.previousClose,
  });

  /// 6자리 종목코드. 예: `005930`
  final String symbol;

  /// 현재가
  final int currentPrice;

  /// 전일 종가
  final int previousClose;

  /// 전일 대비 등락액. `현재가 - 전일종가`
  int get changeAmount => currentPrice - previousClose;
}
