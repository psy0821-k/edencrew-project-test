import 'package:edencrew_assignment_starter/features/search-query/query_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeQuery', () {
    test("'삼성 전자'(중간 공백 1개)를 넣으면 '삼성전자'를 반환한다", () {
      expect(normalizeQuery('삼성 전자'), '삼성전자');
    });

    test("'  삼성전자  '(앞뒤 공백)를 넣으면 '삼성전자'를 반환한다", () {
      expect(normalizeQuery('  삼성전자  '), '삼성전자');
    });

    test("'삼   성   전   자'(여러 공백)를 넣으면 '삼성전자'를 반환한다", () {
      expect(normalizeQuery('삼   성   전   자'), '삼성전자');
    });

    test('빈 문자열을 넣으면 빈 문자열을 반환한다', () {
      expect(normalizeQuery(''), '');
    });
  });
}
