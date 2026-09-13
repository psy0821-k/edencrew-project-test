import 'package:flutter/material.dart';

import '../../entities/daily_quote/daily_quote.dart';
import '../../shared/utils/daily_quote_change_formatter.dart';
import '../../shared/utils/date_formatter.dart';
import '../../shared/utils/number_formatter.dart';
import '../../theme/theme.dart';

const double _titleFontSize = 15;
const double _titleLineHeight = 20;
const double _headerFontSize = 11;
const double _headerLineHeight = 14;
const double _cellFontSize = 11;
const double _cellLineHeight = 14;
const double _rowVerticalPadding = 10;
const double _borderWidth = 1;
const double _visibleRowCount = 5;
const double _rowHeight =
    _cellLineHeight + _rowVerticalPadding * 2 + _borderWidth;

/// "일별 시세" 타이틀 + 날짜/종가/등락/거래량 컬럼 헤더 + 표. quotes를 최신순
/// 그대로 렌더링한다.
class StockDetailDailyQuoteTable extends StatelessWidget {
  const StockDetailDailyQuoteTable({super.key, required this.quotes});

  final List<DailyQuote> quotes;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '일별 시세',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontWeight: AppTypography.bold,
            fontSize: _titleFontSize,
            height: _titleLineHeight / _titleFontSize,
            color: colors.textPrimary,
          ),
        ),
        SizedBox(height: dimens.space3),
        _HeaderRow(colors: colors),
        SizedBox(height: dimens.space2),
        SizedBox(
          height: _rowHeight * _visibleRowCount,
          child: ListView.builder(
            itemCount: quotes.length,
            itemBuilder: (context, i) => Container(
              height: _rowHeight,
              padding: EdgeInsets.symmetric(vertical: _rowVerticalPadding),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    width: _borderWidth,
                    color: colors.borderSubtle,
                  ),
                ),
              ),
              child: _DailyQuoteRow(
                quote: quotes[i],
                previous: i + 1 < quotes.length ? quotes[i + 1] : null,
                colors: colors,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: AppTypography.fontFamily,
      fontWeight: AppTypography.regular,
      fontSize: _headerFontSize,
      height: _headerLineHeight / _headerFontSize,
      color: colors.textSecondary,
    );

    return Row(
      children: [
        Expanded(child: Text('날짜', style: style)),
        Expanded(
          child: Text('종가', style: style, textAlign: TextAlign.right),
        ),
        Expanded(
          child: Text('등락', style: style, textAlign: TextAlign.right),
        ),
        Expanded(
          child: Text('거래량', style: style, textAlign: TextAlign.right),
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
      color: color ?? colors.textSecondary,
    );

    return Row(
      children: [
        Expanded(
          child: Text(
            DateFormatter.internalToDisplay(quote.date),
            style: style(),
          ),
        ),
        Expanded(
          child: Text(
            NumberFormatter.comma(quote.closePrice),
            style: style(),
            textAlign: TextAlign.right,
          ),
        ),
        Expanded(
          child: Text(
            change?.text ?? '0',
            style: style(color: change?.color ?? colors.priceFlatText),
            textAlign: TextAlign.right,
          ),
        ),
        Expanded(
          child: Text(
            NumberFormatter.comma(quote.volume),
            style: style(),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
