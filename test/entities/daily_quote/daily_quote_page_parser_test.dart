import 'dart:io';

import 'package:edencrew_assignment_starter/entities/daily_quote/daily_quote_page_parser.dart';
import 'package:edencrew_assignment_starter/shared/error/failure.dart';
import 'package:edencrew_assignment_starter/shared/utils/euc_kr_decoder.dart';
import 'package:flutter_test/flutter_test.dart';

/// assets/mock/의 실측 EUC-KR HTML 샘플을 읽어 UTF-8 문자열로 디코딩한다.
String _loadMockHtml(String fileName) {
  final bytes = File('assets/mock/$fileName').readAsBytesSync();
  return eucKr.decode(bytes);
}

void main() {
  group('parseDailyQuotePage', () {
    test('실측 응답 1페이지를 파싱하면 10개의 DailyQuote가 날짜 역순(최신순)으로 추출된다', () {
      final html = _loadMockHtml('daily_quote_005930_page1.html');

      final page = parseDailyQuotePage(html);

      expect(page.quotes, hasLength(10));
      final dates = page.quotes.map((q) => q.date).toList();
      final sortedDesc = [...dates]..sort((a, b) => b.compareTo(a));
      expect(dates, sortedDesc);
    });

    test('td.num 6개 중 전일비를 제외한 종가/시가/고가/저가/거래량이 각 필드로 정확히 매핑된다', () {
      final html = _loadMockHtml('daily_quote_005930_page1.html');

      final page = parseDailyQuotePage(html);
      final first = page.quotes.first;

      expect(first.closePrice, 259500);
      expect(first.openPrice, 258000);
      expect(first.highPrice, 261500);
      expect(first.lowPrice, 256500);
      expect(first.volume, 13938673);
    });

    test('콤마 포함 숫자(259,500)가 정수로 올바르게 파싱된다', () {
      final html = _loadMockHtml('daily_quote_005930_page1.html');

      final page = parseDailyQuotePage(html);

      expect(page.quotes.first.closePrice, isA<int>());
      expect(page.quotes.first.closePrice, 259500);
    });

    test('2026.09.11 형식 날짜가 20260911(yyyyMMdd)로 정규화된다', () {
      final html = _loadMockHtml('daily_quote_005930_page1.html');

      final page = parseDailyQuotePage(html);

      expect(page.quotes.first.date, '20260911');
    });

    test('pgRR 링크에서 lastPage가 정확히 추출된다', () {
      final html = _loadMockHtml('daily_quote_005930_page1.html');

      final page = parseDailyQuotePage(html);

      expect(page.lastPage, 756);
    });

    test('데이터 행이 0개인 HTML을 파싱하면 빈 리스트를 반환한다', () {
      const html = '''
<html><body><table>
<tr><td colspan="7" height="8"></td></tr>
<tr><td class="pgRR"><a href="/item/sise_day.naver?code=005930&page=756">맨뒤</a></td></tr>
</table></body></html>
''';

      final page = parseDailyQuotePage(html);

      expect(page.quotes, isEmpty);
    });

    test('pgRR 링크를 찾을 수 없으면 ParsingFailure를 던진다', () {
      const html = '''
<html><body><table>
<tr onMouseOver="mouseOver(this)"><td align="center"><span>2026.09.11</span></td></tr>
</table></body></html>
''';

      expect(() => parseDailyQuotePage(html), throwsA(isA<ParsingFailure>()));
    });
  });
}
