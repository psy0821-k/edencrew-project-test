import 'package:edencrew_assignment_starter/entities/daily_quote/network_daily_quote_repository.dart';
import 'package:edencrew_assignment_starter/entities/daily_quote/period.dart';
import 'package:edencrew_assignment_starter/shared/api/api_client.dart';
import 'package:edencrew_assignment_starter/shared/error/failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// [eucKr]이 디코딩할 EUC-KR 바이트로 응답을 만든다. "맨뒤"는 매핑 테이블에
/// 있는 4글자(맨,뒤)라 [eucKr]로 직접 인코딩할 수 없으므로(디코딩만 지원),
/// 실측한 바이트(0xB8FBC1BE = 맨, 0xB5D2 = 뒤)를 그대로 사용한다.
final List<int> _maenDwiBytes = [0xB8, 0xC7, 0xB5, 0xDA]; // '맨뒤'

/// 요청받은 page 번호에 맞춰 한 행짜리 페이지 HTML을 만들어주는 fake 서버.
/// lastPage는 기본 30으로 고정한다(대부분의 Period 요청을 다 채울 만큼 큼).
/// 한글이 필요한 자리("맨뒤")만 실측 EUC-KR 바이트를 삽입하고, 나머지는
/// ASCII라 그대로 UTF-8/EUC-KR 양쪽에서 동일하다.
http.Response _pageResponse(int page, {int lastPage = 30}) {
  final day = (99 - page).toString().padLeft(2, '0'); // 페이지마다 날짜가 달라지도록
  final before =
      '''
<html><body><table>
<tr onMouseOver="mouseOver(this)">
<td align="center"><span>2026.01.$day</span></td>
<td class="num"><span>100,000</span></td>
<td class="num"><em></em><span>0</span></td>
<td class="num"><span>100,000</span></td>
<td class="num"><span>101,000</span></td>
<td class="num"><span>99,000</span></td>
<td class="num"><span>1,000,000</span></td>
</tr>
<tr><td class="pgRR"><a href="/item/sise_day.naver?code=005930&page=$lastPage">''';
  const after = '''</a></td></tr>
</table></body></html>
''';
  final bytes = [...before.codeUnits, ..._maenDwiBytes, ...after.codeUnits];
  return http.Response.bytes(bytes, 200);
}

void main() {
  group('NetworkDailyQuoteRepository', () {
    test('Period.oneMonth를 요청하면 2페이지치 DailyQuote가 반환된다', () async {
      final apiClient = ApiClient(
        client: MockClient((request) async {
          final page = int.parse(request.url.queryParameters['page']!);
          return _pageResponse(page);
        }),
      );
      final repository = NetworkDailyQuoteRepository(apiClient);

      final quotes = await repository.fetchQuotes('005930', Period.oneMonth);

      expect(quotes, hasLength(2));
    });

    test(
      '이미 oneMonth(2페이지)를 조회한 상태에서 threeMonths(6페이지)를 요청하면 '
      '캐시된 1~2페이지는 재요청하지 않고 3~6페이지만 추가로 요청한다',
      () async {
        final requestedPages = <int>[];
        final apiClient = ApiClient(
          client: MockClient((request) async {
            final page = int.parse(request.url.queryParameters['page']!);
            requestedPages.add(page);
            return _pageResponse(page);
          }),
        );
        final repository = NetworkDailyQuoteRepository(apiClient);

        await repository.fetchQuotes('005930', Period.oneMonth);
        requestedPages.clear();
        final quotes = await repository.fetchQuotes(
          '005930',
          Period.threeMonths,
        );

        expect(requestedPages, [3, 4, 5, 6]);
        expect(quotes, hasLength(6));
      },
    );

    test(
      'lastPage=1인 종목에서 oneMonth(2페이지 필요)를 요청하면 '
      '2페이지는 요청하지 않고 1페이지치 데이터만 반환한다',
      () async {
        var requestCount = 0;
        final apiClient = ApiClient(
          client: MockClient((request) async {
            requestCount++;
            final page = int.parse(request.url.queryParameters['page']!);
            return _pageResponse(page, lastPage: 1);
          }),
        );
        final repository = NetworkDailyQuoteRepository(apiClient);

        final quotes = await repository.fetchQuotes('005930', Period.oneMonth);

        expect(quotes, hasLength(1));
        expect(requestCount, 1);
      },
    );

    test('동일한 (symbol, Period)로 두 번 연속 조회하면 두 번째는 네트워크 재요청하지 않는다', () async {
      var requestCount = 0;
      final apiClient = ApiClient(
        client: MockClient((request) async {
          requestCount++;
          final page = int.parse(request.url.queryParameters['page']!);
          return _pageResponse(page);
        }),
      );
      final repository = NetworkDailyQuoteRepository(apiClient);

      await repository.fetchQuotes('005930', Period.oneMonth);
      final countAfterFirst = requestCount;
      await repository.fetchQuotes('005930', Period.oneMonth);

      expect(countAfterFirst, 2);
      expect(requestCount, countAfterFirst);
    });

    test('요청이 계속 실패하면 NetworkFailure를 던진다', () async {
      final apiClient = ApiClient(
        client: MockClient((request) async => http.Response('error', 500)),
        maxRetries: 0,
      );
      final repository = NetworkDailyQuoteRepository(apiClient);

      await expectLater(
        repository.fetchQuotes('005930', Period.oneMonth),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('응답 body가 비어있으면 EmptyResultFailure를 던진다', () async {
      final apiClient = ApiClient(
        client: MockClient((request) async => http.Response('', 200)),
        maxRetries: 0,
      );
      final repository = NetworkDailyQuoteRepository(apiClient);

      await expectLater(
        repository.fetchQuotes('005930', Period.oneMonth),
        throwsA(isA<EmptyResultFailure>()),
      );
    });
  });
}
