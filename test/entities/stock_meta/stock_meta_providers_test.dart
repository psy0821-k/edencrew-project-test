import 'package:edencrew_assignment_starter/entities/stock_meta/caching_stock_meta_repository.dart';
import 'package:edencrew_assignment_starter/entities/stock_meta/mock_stock_meta_repository.dart';
import 'package:edencrew_assignment_starter/entities/stock_meta/stock_meta.dart';
import 'package:edencrew_assignment_starter/entities/stock_meta/stock_meta_providers.dart';
import 'package:edencrew_assignment_starter/entities/stock_meta/stock_meta_repository.dart';
import 'package:edencrew_assignment_starter/shared/config/data_source_mode.dart';
import 'package:edencrew_assignment_starter/shared/error/failure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStockMetaRepository implements StockMetaRepository {
  _FakeStockMetaRepository({StockMeta? stockMeta, Object? errorToThrow})
    : _stockMeta =
          stockMeta ??
          const StockMeta(symbol: '005930', name: '삼성전자', marketName: '코스피'),
      _errorToThrow = errorToThrow;

  final StockMeta _stockMeta;
  final Object? _errorToThrow;

  @override
  Future<StockMeta> fetchStockMeta(String symbol) async {
    if (_errorToThrow != null) throw _errorToThrow;
    return _stockMeta;
  }
}

void main() {
  group('stockMetaRepositoryProvider', () {
    test(
      'dataSourceMode 기본값(network)일 때 캐싱이 적용된 '
      'CachingStockMetaRepository를 반환한다',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final repository = container.read(stockMetaRepositoryProvider);

        expect(repository, isA<CachingStockMetaRepository>());
      },
    );

    test('dataSourceMode를 mock으로 override하면 MockStockMetaRepository를 반환한다', () {
      final container = ProviderContainer(
        overrides: [
          dataSourceModeProvider.overrideWithValue(DataSourceMode.mock),
        ],
      );
      addTearDown(container.dispose);

      final repository = container.read(stockMetaRepositoryProvider);

      expect(repository, isA<MockStockMetaRepository>());
    });

    test(
      '전역 모드가 network여도 stockMetaRepositoryProvider를 개별 override하면 그 값이 우선한다',
      () {
        final fake = _FakeStockMetaRepository();
        final container = ProviderContainer(
          overrides: [stockMetaRepositoryProvider.overrideWithValue(fake)],
        );
        addTearDown(container.dispose);

        final repository = container.read(stockMetaRepositoryProvider);

        expect(repository, same(fake));
      },
    );
  });

  group('stockMetaProvider', () {
    test('symbol을 조회하면 fetchStockMeta(symbol)을 호출해 StockMeta를 반환한다', () async {
      const expected = StockMeta(
        symbol: '005930',
        name: '삼성전자',
        marketName: '코스피',
      );
      final fake = _FakeStockMetaRepository(stockMeta: expected);
      final container = ProviderContainer(
        overrides: [stockMetaRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      final stockMeta = await container.read(
        stockMetaProvider('005930').future,
      );

      expect(stockMeta, expected);
    });

    test('fetchStockMeta가 NetworkFailure를 던지면 그대로 전파한다', () async {
      final fake = _FakeStockMetaRepository(
        errorToThrow: const NetworkFailure(),
      );
      final container = ProviderContainer(
        overrides: [stockMetaRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(stockMetaProvider('005930').future),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });
}
