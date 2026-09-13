import 'package:edencrew_assignment_starter/entities/quote/mock_quote_repository.dart';
import 'package:edencrew_assignment_starter/entities/quote/network_quote_repository.dart';
import 'package:edencrew_assignment_starter/entities/quote/quote_providers.dart';
import 'package:edencrew_assignment_starter/entities/quote/quote_repository.dart';
import 'package:edencrew_assignment_starter/entities/quote/quote.dart';
import 'package:edencrew_assignment_starter/shared/config/data_source_mode.dart';
import 'package:edencrew_assignment_starter/shared/error/failure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeQuoteRepository implements QuoteRepository {
  _FakeQuoteRepository({Map<String, Quote>? quotes, Object? errorToThrow})
    : _quotes = quotes ?? const {},
      _errorToThrow = errorToThrow;

  final Map<String, Quote> _quotes;
  final Object? _errorToThrow;
  List<String>? lastRequestedSymbols;

  @override
  Future<Map<String, Quote>> fetchQuotes(List<String> symbols) async {
    lastRequestedSymbols = symbols;
    if (_errorToThrow != null) throw _errorToThrow;
    return _quotes;
  }
}

const _sampleQuote = Quote(
  symbol: '005930',
  currentPrice: 70000,
  previousClose: 69000,
  open: 69500,
  high: 70500,
  low: 69000,
  volume: 1000000,
  countOfListedStock: 5969782550,
);

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

  group('quoteProvider', () {
    test('symbol을 조회하면 fetchQuotes([symbol])을 호출해 해당 Quote를 반환한다', () async {
      final fake = _FakeQuoteRepository(quotes: {'005930': _sampleQuote});
      final container = ProviderContainer(
        overrides: [quoteRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      final quote = await container.read(quoteProvider('005930').future);

      expect(quote, _sampleQuote);
      expect(fake.lastRequestedSymbols, ['005930']);
    });

    test('응답 Map에 symbol이 없으면 EmptyResultFailure를 던진다', () async {
      final fake = _FakeQuoteRepository(quotes: const {});
      final container = ProviderContainer(
        overrides: [quoteRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(quoteProvider('005930').future),
        throwsA(isA<EmptyResultFailure>()),
      );
    });

    test('fetchQuotes가 NetworkFailure를 던지면 그대로 전파한다', () async {
      final fake = _FakeQuoteRepository(errorToThrow: const NetworkFailure());
      final container = ProviderContainer(
        overrides: [quoteRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(quoteProvider('005930').future),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });
}
