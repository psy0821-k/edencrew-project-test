import 'package:edencrew_assignment_starter/entities/stock_meta/mock_stock_meta_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MockStockMetaRepository', () {
    test('임의의 symbol로 호출하면 고정된 StockMeta(해당 symbol 포함)를 반환한다', () async {
      final repository = MockStockMetaRepository();

      final result = await repository.fetchStockMeta('005930');

      expect(result.symbol, '005930');
      expect(result.name, isNotEmpty);
      expect(result.marketName, isNotEmpty);
    });
  });
}
