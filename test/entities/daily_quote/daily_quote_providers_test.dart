import 'package:edencrew_assignment_starter/entities/daily_quote/daily_quote_providers.dart';
import 'package:edencrew_assignment_starter/entities/daily_quote/mock_daily_quote_repository.dart';
import 'package:edencrew_assignment_starter/entities/daily_quote/network_daily_quote_repository.dart';
import 'package:edencrew_assignment_starter/shared/config/data_source_mode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
