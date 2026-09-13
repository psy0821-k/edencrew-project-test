import 'package:flutter/material.dart';

import '../../entities/daily_quote/daily_quote.dart';
import '../../shared/utils/number_formatter.dart';
import '../../theme/theme.dart';

const double _labelFontSize = 11;
const double _labelLineHeight = 14;
const double _valueFontSize = 13;
const double _valueLineHeight = 18;
const double _itemPaddingHorizontal = 10;
const double _itemPaddingVertical = 9;
const double _itemRadius = 8;
const double _gap = 8;

/// 시가/고가/저가(그대로) + 거래량/시가총액(NumberFormatter.compactKorean 축약) 카드.
/// 시가/고가/저가는 3열, 거래량/시가총액은 2열 그리드로 배치한다.
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryItem(
                label: '시가',
                value: NumberFormatter.comma(latestDailyQuote.openPrice),
              ),
            ),
            const SizedBox(width: _gap),
            Expanded(
              child: _SummaryItem(
                label: '고가',
                value: NumberFormatter.comma(latestDailyQuote.highPrice),
              ),
            ),
            const SizedBox(width: _gap),
            Expanded(
              child: _SummaryItem(
                label: '저가',
                value: NumberFormatter.comma(latestDailyQuote.lowPrice),
              ),
            ),
          ],
        ),
        const SizedBox(height: _gap),
        Row(
          children: [
            Expanded(
              child: _SummaryItem(
                label: '거래량',
                value: NumberFormatter.compactKorean(latestDailyQuote.volume),
              ),
            ),
            const SizedBox(width: _gap),
            Expanded(
              child: _SummaryItem(
                label: '시가총액',
                value: NumberFormatter.compactKorean(marketCap),
              ),
            ),
          ],
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

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _itemPaddingHorizontal,
        vertical: _itemPaddingVertical,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: BorderRadius.circular(_itemRadius),
      ),
      child: Column(
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
      ),
    );
  }
}
