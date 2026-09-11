import 'package:edencrew_assignment_starter/entities/search/search_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SearchResult', () {
    test('symbol, name, marketName을 전달해 생성하면 각 필드에 전달한 값이 그대로 저장된다', () {
      const result = SearchResult(
        symbol: '005930',
        name: '삼성전자',
        marketName: '코스피',
      );

      expect(result.symbol, '005930');
      expect(result.name, '삼성전자');
      expect(result.marketName, '코스피');
    });

    test("symbol이 '005930'일 때 canonicalId는 'domestic:005930'을 반환한다", () {
      const result = SearchResult(
        symbol: '005930',
        name: '삼성전자',
        marketName: '코스피',
      );

      expect(result.canonicalId, 'domestic:005930');
    });
  });
}
