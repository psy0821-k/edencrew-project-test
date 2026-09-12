import 'package:flutter/material.dart';

import '../../entities/quote/quote.dart';
import '../../theme/theme.dart';
import 'number_formatter.dart';

/// 등락액/등락률 문자열과 상승/하락/보합에 맞는 색상을 함께 반환합니다.
///
/// 예: `-400 (-0.22%)` + `colors.priceDownText`
class PriceChangeDisplay {
  const PriceChangeDisplay({required this.text, required this.color});

  final String text;
  final Color color;
}

/// 국내 시장 관행(상승=빨강, 하락=파랑, 보합=중립색)에 맞춰
/// [Quote]의 등락액/등락률을 화면 표시용 문자열과 색상으로 변환합니다.
PriceChangeDisplay formatPriceChange(Quote quote, AppColors colors) {
  final amount = quote.changeAmount;
  final rate = quote.changeRate * 100;
  final sign = amount > 0 ? '+' : '';
  final text =
      '$sign${NumberFormatter.comma(amount)} ($sign${rate.toStringAsFixed(2)}%)';

  final color = switch (amount) {
    > 0 => colors.priceUpText,
    < 0 => colors.priceDownText,
    _ => colors.priceFlatText,
  };

  return PriceChangeDisplay(text: text, color: color);
}
