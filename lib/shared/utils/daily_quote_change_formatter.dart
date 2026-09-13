import '../../entities/daily_quote/daily_quote.dart';
import '../../theme/theme.dart';
import 'number_formatter.dart';
import 'price_change_formatter.dart';

/// 인접한 두 거래일 [DailyQuote]의 종가를 비교해 등락을 계산합니다.
///
/// [current]가 그 행, [previous]가 하루 전 행(배열상 다음 인덱스, 최신순 정렬 기준)입니다.
/// [previous]가 null이면(그 기간의 마지막 행) 비교할 이전 데이터가 없으므로 null을 반환합니다.
PriceChangeDisplay? formatDailyQuoteChange(
  DailyQuote current,
  DailyQuote? previous,
  AppColors colors,
) {
  if (previous == null) return null;

  final amount = current.closePrice - previous.closePrice;
  final sign = amount > 0 ? '+' : '';
  final text = '$sign${NumberFormatter.comma(amount)}';

  final color = switch (amount) {
    > 0 => colors.priceUpText,
    < 0 => colors.priceDownText,
    _ => colors.priceFlatText,
  };

  return PriceChangeDisplay(text: text, color: color);
}
