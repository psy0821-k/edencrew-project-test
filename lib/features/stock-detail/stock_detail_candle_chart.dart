import 'package:flutter/material.dart';

import '../../entities/daily_quote/daily_quote.dart';
import '../../theme/theme.dart';

// 임시 값. 세부 디자인은 다음 세션에서 시안에 맞춰 조정 예정.
const double _chartHeight = 200;
const double _slotWidth = 12;
const double _candleWidthRatio = 0.6;

/// 캔들 차트. `quotes`는 [StockDetailDailyQuoteTable]과 동일하게 최신순으로
/// 들어오므로, 내부에서 날짜 오름차순으로 반전해 왼쪽부터 과거 → 오른쪽 최신
/// 순으로 그린다. 기간 탭 전환으로 `quotes`가 바뀌면 자동으로 다시 그려진다.
///
/// 캔들 하나당 너비를 고정하고 전체를 가로 스크롤 가능한 영역에 그려서,
/// 기간이 길어져도(1년 등) 캔들이 찌그러지지 않고 스크롤로 확대해 볼 수
/// 있게 한다.
class StockDetailCandleChart extends StatelessWidget {
  const StockDetailCandleChart({super.key, required this.quotes});

  final List<DailyQuote> quotes;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final contentWidth = quotes.length * _slotWidth;

    return SizedBox(
      height: _chartHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: SizedBox(
          width: contentWidth,
          height: _chartHeight,
          child: CustomPaint(
            painter: _CandleChartPainter(
              quotes: quotes,
              upColor: colors.chartLineUp,
              downColor: colors.chartLineDown,
              flatColor: colors.chartLineFlat,
            ),
          ),
        ),
      ),
    );
  }
}

class _CandleChartPainter extends CustomPainter {
  const _CandleChartPainter({
    required this.quotes,
    required this.upColor,
    required this.downColor,
    required this.flatColor,
  });

  final List<DailyQuote> quotes;
  final Color upColor;
  final Color downColor;
  final Color flatColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (quotes.isEmpty) return;

    final ascending = quotes.reversed.toList();
    final highest = ascending.map((q) => q.highPrice).reduce(
      (a, b) => a > b ? a : b,
    );
    final lowest = ascending.map((q) => q.lowPrice).reduce(
      (a, b) => a < b ? a : b,
    );
    final range = (highest - lowest).toDouble();

    const slotWidth = _slotWidth;
    const candleWidth = slotWidth * _candleWidthRatio;

    double yFor(int price) {
      if (range == 0) return size.height / 2;
      return size.height - ((price - lowest) / range) * size.height;
    }

    for (var i = 0; i < ascending.length; i++) {
      final quote = ascending[i];
      final color = quote.closePrice > quote.openPrice
          ? upColor
          : quote.closePrice < quote.openPrice
          ? downColor
          : flatColor;
      final paint = Paint()..color = color;

      final centerX = slotWidth * i + slotWidth / 2;

      canvas.drawLine(
        Offset(centerX, yFor(quote.highPrice)),
        Offset(centerX, yFor(quote.lowPrice)),
        paint,
      );

      final bodyTop = yFor(
        quote.openPrice > quote.closePrice
            ? quote.openPrice
            : quote.closePrice,
      );
      final bodyBottom = yFor(
        quote.openPrice > quote.closePrice
            ? quote.closePrice
            : quote.openPrice,
      );
      canvas.drawRect(
        Rect.fromLTRB(
          centerX - candleWidth / 2,
          bodyTop,
          centerX + candleWidth / 2,
          bodyBottom,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CandleChartPainter oldDelegate) {
    return quotes != oldDelegate.quotes ||
        upColor != oldDelegate.upColor ||
        downColor != oldDelegate.downColor ||
        flatColor != oldDelegate.flatColor;
  }
}
