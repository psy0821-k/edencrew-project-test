import 'package:edencrew_assignment_starter/entities/stock_meta/stock_meta.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StockMeta', () {
    test('symbol, name, marketName을 전달해 생성하면 각 필드에 전달한 값이 그대로 저장된다', () {
      const meta = StockMeta(symbol: '005930', name: '삼성전자', marketName: '코스피');

      expect(meta.symbol, '005930');
      expect(meta.name, '삼성전자');
      expect(meta.marketName, '코스피');
    });
  });
}
