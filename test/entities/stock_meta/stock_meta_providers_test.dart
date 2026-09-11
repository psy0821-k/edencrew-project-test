import 'package:edencrew_assignment_starter/entities/stock_meta/mock_stock_meta_repository.dart';
import 'package:edencrew_assignment_starter/entities/stock_meta/network_stock_meta_repository.dart';
import 'package:edencrew_assignment_starter/entities/stock_meta/stock_meta.dart';
import 'package:edencrew_assignment_starter/entities/stock_meta/stock_meta_providers.dart';
import 'package:edencrew_assignment_starter/entities/stock_meta/stock_meta_repository.dart';
import 'package:edencrew_assignment_starter/shared/config/data_source_mode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStockMetaRepository implements StockMetaRepository {
  @override
  Future<StockMeta> fetchStockMeta(String symbol) async =>
      const StockMeta(symbol: '005930', name: '삼성전자', marketName: '코스피');
}

void main() {
  group('stockMetaRepositoryProvider', () {
    test('dataSourceMode 기본값(network)일 때 NetworkStockMetaRepository를 반환한다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repository = container.read(stockMetaRepositoryProvider);

      expect(repository, isA<NetworkStockMetaRepository>());
    });

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
}
