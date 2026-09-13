import 'package:edencrew_assignment_starter/entities/daily_quote/daily_quote.dart';
import 'package:edencrew_assignment_starter/entities/daily_quote/daily_quote_providers.dart';
import 'package:edencrew_assignment_starter/entities/daily_quote/daily_quote_repository.dart';
import 'package:edencrew_assignment_starter/entities/daily_quote/mock_daily_quote_repository.dart';
import 'package:edencrew_assignment_starter/entities/daily_quote/network_daily_quote_repository.dart';
import 'package:edencrew_assignment_starter/entities/daily_quote/period.dart';
import 'package:edencrew_assignment_starter/shared/config/data_source_mode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDailyQuoteRepository implements DailyQuoteRepository {
  _FakeDailyQuoteRepository({List<DailyQuote>? quotes})
    : _quotes = quotes ?? const [];

  final List<DailyQuote> _quotes;
  String? lastSymbol;
  Period? lastPeriod;

  @override
  Future<List<DailyQuote>> fetchQuotes(String symbol, Period period) async {
    lastSymbol = symbol;
    lastPeriod = period;
    return _quotes;
  }
}

const _sampleDailyQuote = DailyQuote(
  date: '20260911',
  closePrice: 70000,
  openPrice: 70200,
  highPrice: 70800,
  lowPrice: 69900,
  volume: 12345678,
);

void main() {
  group('dailyQuoteRepositoryProvider', () {
    test(
      'dataSourceMode 기본값(network)일 때 NetworkDailyQuoteRepository를 반환한다',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final repository = container.read(dailyQuoteRepositoryProvider);

        expect(repository, isA<NetworkDailyQuoteRepository>());
      },
    );

    test(
      'dataSourceMode를 mock으로 override하면 MockDailyQuoteRepository를 반환한다',
      () {
        final container = ProviderContainer(
          overrides: [
            dataSourceModeProvider.overrideWithValue(DataSourceMode.mock),
          ],
        );
        addTearDown(container.dispose);

        final repository = container.read(dailyQuoteRepositoryProvider);

        expect(repository, isA<MockDailyQuoteRepository>());
      },
    );
  });

  group('selectedPeriodProvider', () {
    test('기본값은 Period.oneMonth다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedPeriodProvider), Period.oneMonth);
    });
  });

  group('dailyQuoteProvider', () {
    test(
      '(symbol, period)로 조회하면 dailyQuoteRepositoryProvider.fetchQuotes(symbol, period)를 '
      '호출해 결과를 반환한다',
      () async {
        final fake = _FakeDailyQuoteRepository(quotes: [_sampleDailyQuote]);
        final container = ProviderContainer(
          overrides: [dailyQuoteRepositoryProvider.overrideWithValue(fake)],
        );
        addTearDown(container.dispose);

        final result = await container.read(
          dailyQuoteProvider(('005930', Period.oneMonth)).future,
        );

        expect(result, [_sampleDailyQuote]);
        expect(fake.lastSymbol, '005930');
        expect(fake.lastPeriod, Period.oneMonth);
      },
    );
  });
}
