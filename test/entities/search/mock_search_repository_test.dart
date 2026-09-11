import 'package:edencrew_assignment_starter/entities/search/mock_search_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MockSearchRepository', () {
    test('임의의 query로 호출하면 고정된 SearchResult 목록을 반환한다', () async {
      final repository = MockSearchRepository();

      final results = await repository.search('삼성전자');

      expect(results, isNotEmpty);
      expect(results.first.symbol, isNotEmpty);
      expect(results.first.name, isNotEmpty);
      expect(results.first.marketName, isNotEmpty);
    });
  });
}
