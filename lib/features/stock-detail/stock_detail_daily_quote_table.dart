import 'package:flutter/material.dart';

import '../../entities/daily_quote/daily_quote.dart';
import '../../shared/utils/daily_quote_change_formatter.dart';
import '../../shared/utils/date_formatter.dart';
import '../../shared/utils/number_formatter.dart';
import '../../theme/theme.dart';

const double _cellFontSize = 12;
const double _cellLineHeight = 16;

/// 날짜(MM.dd)/종가/등락/거래량 컬럼의 표. quotes를 최신순 그대로 렌더링한다.
class StockDetailDailyQuoteTable extends StatelessWidget {
  const StockDetailDailyQuoteTable({super.key, required this.quotes});

  final List<DailyQuote> quotes;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    return Column(
      children: [
        for (var i = 0; i < quotes.length; i++)
          Padding(
            padding: EdgeInsets.symmetric(vertical: dimens.space1),
            child: _DailyQuoteRow(
              quote: quotes[i],
              previous: i + 1 < quotes.length ? quotes[i + 1] : null,
              colors: colors,
            ),
          ),
      ],
    );
  }
}

class _DailyQuoteRow extends StatelessWidget {
  const _DailyQuoteRow({
    required this.quote,
    required this.previous,
    required this.colors,
  });

  final DailyQuote quote;
  final DailyQuote? previous;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final change = formatDailyQuoteChange(quote, previous, colors);

    TextStyle style({Color? color}) => TextStyle(
      fontFamily: AppTypography.fontFamily,
      fontWeight: AppTypography.regular,
      fontSize: _cellFontSize,
      height: _cellLineHeight / _cellFontSize,
      color: color ?? colors.textPrimary,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(DateFormatter.internalToDisplay(quote.date), style: style()),
        Text(NumberFormatter.comma(quote.closePrice), style: style()),
        Text(
          change?.text ?? '-',
          style: style(color: change?.color ?? colors.textTertiary),
        ),
        Text(
          NumberFormatter.compactKorean(quote.volume),
          style: style(color: colors.textSecondary),
        ),
      ],
    );
  }
}
