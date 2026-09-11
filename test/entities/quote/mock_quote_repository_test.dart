import 'package:edencrew_assignment_starter/entities/quote/mock_quote_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MockQuoteRepository', () {
    test(
      '확장된 필드(open/high/low/volume/countOfListedStock)를 포함한 고정 Quote를 반환한다',
      () async {
        final repository = MockQuoteRepository();

        final result = await repository.fetchQuotes(['005930']);
        final quote = result['005930']!;

        expect(quote.open, isNonNegative);
        expect(quote.high, isNonNegative);
        expect(quote.low, isNonNegative);
        expect(quote.volume, isNonNegative);
        expect(quote.countOfListedStock, isNonNegative);
      },
    );
  });
}
