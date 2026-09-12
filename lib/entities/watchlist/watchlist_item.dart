import '../quote/quote.dart';
import '../stock_meta/stock_meta.dart';

/// 관심등록된 종목 하나를 화면이 바로 렌더링할 수 있는 형태로 결합한 모델입니다.
class WatchlistItem {
  const WatchlistItem({
    required this.symbol,
    required this.stockMeta,
    required this.quote,
  });

  /// 6자리 종목코드. 예: `005930`
  final String symbol;

  /// 종목 메타데이터 (종목명, 거래소명). 항상 값이 존재해야 한다.
  final StockMeta stockMeta;

  /// 실시간 시세. 아직 받아오지 못했거나 조회에 실패했으면 `null`.
  final Quote? quote;
}
