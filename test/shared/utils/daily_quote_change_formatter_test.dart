import 'package:edencrew_assignment_starter/entities/daily_quote/daily_quote.dart';
import 'package:edencrew_assignment_starter/shared/utils/daily_quote_change_formatter.dart';
import 'package:edencrew_assignment_starter/theme/theme.dart';
import 'package:flutter_test/flutter_test.dart';

const _colors = AppColors.dark();

DailyQuote _quoteWithClose(int closePrice) => DailyQuote(
  date: '20260911',
  closePrice: closePrice,
  openPrice: closePrice,
  highPrice: closePrice,
  lowPrice: closePrice,
  volume: 1000,
);

void main() {
  group('formatDailyQuoteChange', () {
    test('current 종가가 previous보다 크면 양수 등락 + priceUpText 색상을 반환한다', () {
      final result = formatDailyQuoteChange(
        _quoteWithClose(70000),
        _quoteWithClose(69000),
        _colors,
      );

      expect(result, isNotNull);
      expect(result!.color, _colors.priceUpText);
      expect(result.text, contains('+1,000'));
    });

    test('current 종가가 previous보다 작으면 음수 등락 + priceDownText 색상을 반환한다', () {
      final result = formatDailyQuoteChange(
        _quoteWithClose(68000),
        _quoteWithClose(69000),
        _colors,
      );

      expect(result, isNotNull);
      expect(result!.color, _colors.priceDownText);
      expect(result.text, contains('-1,000'));
    });

    test('두 종가가 같으면 등락 0 + priceFlatText 색상을 반환한다', () {
      final result = formatDailyQuoteChange(
        _quoteWithClose(69000),
        _quoteWithClose(69000),
        _colors,
      );

      expect(result, isNotNull);
      expect(result!.color, _colors.priceFlatText);
    });

    test('previous가 null이면 등락을 표시하지 않는다(null 반환)', () {
      final result = formatDailyQuoteChange(
        _quoteWithClose(69000),
        null,
        _colors,
      );

      expect(result, isNull);
    });
  });
}
