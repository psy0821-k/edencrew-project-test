import 'package:edencrew_assignment_starter/entities/quote/mock_quote_repository.dart';
import 'package:edencrew_assignment_starter/entities/quote/network_quote_repository.dart';
import 'package:edencrew_assignment_starter/entities/quote/quote_providers.dart';
import 'package:edencrew_assignment_starter/entities/quote/quote_repository.dart';
import 'package:edencrew_assignment_starter/entities/quote/quote.dart';
import 'package:edencrew_assignment_starter/shared/config/data_source_mode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeQuoteRepository implements QuoteRepository {
  @override
  Future<Map<String, Quote>> fetchQuotes(List<String> symbols) async => {};
}

void main() {
  group('quoteRepositoryProvider', () {
    test('dataSourceMode 기본값(network)일 때 NetworkQuoteRepository를 반환한다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repository = container.read(quoteRepositoryProvider);

      expect(repository, isA<NetworkQuoteRepository>());
    });

    test('dataSourceMode를 mock으로 override하면 MockQuoteRepository를 반환한다', () {
      final container = ProviderContainer(
        overrides: [
          dataSourceModeProvider.overrideWithValue(DataSourceMode.mock),
        ],
      );
      addTearDown(container.dispose);

      final repository = container.read(quoteRepositoryProvider);

      expect(repository, isA<MockQuoteRepository>());
    });

    test(
      '전역 모드가 network여도 quoteRepositoryProvider를 개별 override하면 그 값이 우선한다',
      () {
        final fake = _FakeQuoteRepository();
        final container = ProviderContainer(
          overrides: [quoteRepositoryProvider.overrideWithValue(fake)],
        );
        addTearDown(container.dispose);

        final repository = container.read(quoteRepositoryProvider);

        expect(repository, same(fake));
      },
    );
  });
}
