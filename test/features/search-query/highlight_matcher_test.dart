import 'package:edencrew_assignment_starter/features/search-query/highlight_matcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('findHighlightRange', () {
    test("name='삼성전자', query='삼성전자'일 때 start=0, end=4를 반환한다", () {
      final range = findHighlightRange('삼성전자', '삼성전자');

      expect(range, isNotNull);
      expect(range!.start, 0);
      expect(range.end, 4);
    });

    test("name='삼성전자', query='전자'일 때 start=2, end=4를 반환한다", () {
      final range = findHighlightRange('삼성전자', '전자');

      expect(range, isNotNull);
      expect(range!.start, 2);
      expect(range.end, 4);
    });

    test('query가 name에 없으면 null을 반환한다', () {
      expect(findHighlightRange('삼성전자', '카카오'), isNull);
    });

    test('query가 빈 문자열이면 null을 반환한다', () {
      expect(findHighlightRange('삼성전자', ''), isNull);
    });
  });
}
