import 'package:flutter/material.dart';

import '../../entities/quote/quote.dart';
import '../../shared/utils/number_formatter.dart';
import '../../shared/utils/price_change_formatter.dart';
import '../../theme/theme.dart';

const double _priceFontSize = 30;
const double _priceLineHeight = 36;
const double _priceLetterSpacing = -0.4;
const double _changeFontSize = 15;
const double _changeLineHeight = 20;
const double _changeLetterSpacing = -0.1;

/// 현재가 + 등락(방향 아이콘 + formatPriceChange 텍스트/색상)을 같은 줄, 하단 기준으로 표시한다.
class StockDetailPriceSection extends StatelessWidget {
  const StockDetailPriceSection({super.key, required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final change = formatPriceChange(quote, colors);
    final directionIcon = switch (quote.changeAmount) {
      > 0 => Icons.arrow_drop_up,
      < 0 => Icons.arrow_drop_down,
      _ => null,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          NumberFormatter.comma(quote.currentPrice),
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontWeight: AppTypography.bold,
            fontSize: _priceFontSize,
            height: _priceLineHeight / _priceFontSize,
            letterSpacing: _priceLetterSpacing,
            color: colors.textPrimary,
          ),
        ),
        Text.rich(
          TextSpan(
            children: [
              if (directionIcon != null)
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Icon(
                    directionIcon,
                    color: change.color,
                    size: _changeFontSize,
                  ),
                ),
              TextSpan(text: change.text),
            ],
          ),
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontWeight: AppTypography.medium,
            fontSize: _changeFontSize,
            height: _changeLineHeight / _changeFontSize,
            letterSpacing: _changeLetterSpacing,
            color: change.color,
          ),
        ),
      ],
    );
  }
}
