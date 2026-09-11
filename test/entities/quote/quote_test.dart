import 'package:edencrew_assignment_starter/entities/quote/quote.dart';
import 'package:flutter_test/flutter_test.dart';

Quote _quote({
  int currentPrice = 70000,
  int previousClose = 70400,
  int countOfListedStock = 100000000,
}) {
  return Quote(
    symbol: '005930',
    currentPrice: currentPrice,
    previousClose: previousClose,
    open: 70000,
    high: 71000,
    low: 69500,
    volume: 1000000,
    countOfListedStock: countOfListedStock,
  );
}

void main() {
  group('Quote', () {
    test(
      'currentPrice=70000, previousClose=70400일 때 changeAmount는 -400을 반환한다',
      () {
        final quote = _quote(currentPrice: 70000, previousClose: 70400);

        expect(quote.changeAmount, -400);
      },
    );

    test(
      'currentPrice=70000, previousClose=70400일 때 changeRate는 약 -0.0057을 반환한다',
      () {
        final quote = _quote(currentPrice: 70000, previousClose: 70400);

        expect(quote.changeRate, closeTo(-0.0057, 0.0001));
      },
    );

    test(
      'currentPrice=70000, countOfListedStock=100000000일 때 marketCap은 7000000000000을 반환한다',
      () {
        final quote = _quote(
          currentPrice: 70000,
          countOfListedStock: 100000000,
        );

        expect(quote.marketCap, 7000000000000);
      },
    );
  });
}
