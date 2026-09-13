import 'package:flutter/material.dart';

import '../../entities/daily_quote/daily_quote.dart';
import '../../shared/utils/number_formatter.dart';
import '../../theme/theme.dart';

const double _labelFontSize = 11;
const double _labelLineHeight = 14;
const double _valueFontSize = 13;
const double _valueLineHeight = 18;

/// 시가/고가/저가(그대로) + 거래량/시가총액(NumberFormatter.compactKorean 축약) 카드.
class StockDetailSummaryCard extends StatelessWidget {
  const StockDetailSummaryCard({
    super.key,
    required this.latestDailyQuote,
    required this.marketCap,
  });

  final DailyQuote latestDailyQuote;
  final int marketCap;

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;

    return Wrap(
      spacing: dimens.space4,
      runSpacing: dimens.space2,
      children: [
        _SummaryItem(
          label: '시가',
          value: NumberFormatter.comma(latestDailyQuote.openPrice),
        ),
        _SummaryItem(
          label: '고가',
          value: NumberFormatter.comma(latestDailyQuote.highPrice),
        ),
        _SummaryItem(
          label: '저가',
          value: NumberFormatter.comma(latestDailyQuote.lowPrice),
        ),
        _SummaryItem(
          label: '거래량',
          value: NumberFormatter.compactKorean(latestDailyQuote.volume),
        ),
        _SummaryItem(
          label: '시가총액',
          value: NumberFormatter.compactKorean(marketCap),
        ),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontWeight: AppTypography.regular,
            fontSize: _labelFontSize,
            height: _labelLineHeight / _labelFontSize,
            color: colors.textTertiary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontWeight: AppTypography.medium,
            fontSize: _valueFontSize,
            height: _valueLineHeight / _valueFontSize,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
