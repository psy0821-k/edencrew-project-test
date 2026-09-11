import 'package:edencrew_assignment_starter/entities/daily_quote/network_daily_quote_repository.dart';
import 'package:edencrew_assignment_starter/shared/api/api_client.dart';
import 'package:edencrew_assignment_starter/shared/error/failure.dart';
import 'package:edencrew_assignment_starter/shared/utils/euc_kr_decoder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// [eucKr]이 디코딩할 EUC-KR 바이트로 응답을 만든다. "맨뒤"는 매핑 테이블에
/// 있는 4글자(맨,뒤)라 [eucKr]로 직접 인코딩할 수 없으므로(디코딩만 지원),
/// 실측한 바이트(0xB8FBC1BE = 맨, 0xB5D2 = 뒤)를 그대로 사용한다.
final List<int> _maenDwiBytes = [0xB8, 0xC7, 0xB5, 0xDA]; // '맨뒤'

/// 요청받은 page 번호에 맞춰 한 행짜리 페이지 HTML을 만들어주는 fake 서버.
/// lastPage는 3으로 고정한다. 한글이 필요한 자리("맨뒤")만 실측 EUC-KR
/// 바이트를 삽입하고, 나머지는 ASCII라 그대로 UTF-8/EUC-KR 양쪽에서 동일하다.
http.Response _pageResponse(int page, {int lastPage = 3}) {
  final day = (10 - page).toString().padLeft(2, '0'); // 페이지마다 날짜가 달라지도록
  final before =
      '''
<html><body><table>
<tr onMouseOver="mouseOver(this)">
<td align="center"><span>2026.09.$day</span></td>
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
    test('symbol을 처음 요청하면 1페이지를 반환한다', () async {
      final apiClient = ApiClient(
        client: MockClient((request) async => _pageResponse(1)),
      );
      final repository = NetworkDailyQuoteRepository(apiClient);

      final quotes = await repository.fetchNextPage('005930');

      expect(quotes, hasLength(1));
      expect(quotes.first.date, '20260909');
    });

    test('같은 symbol로 연속 호출하면 페이지 번호가 순서대로 증가하며 겹치지 않는다', () async {
      final requestedPages = <int>[];
      final apiClient = ApiClient(
        client: MockClient((request) async {
          final page = int.parse(request.url.queryParameters['page']!);
          requestedPages.add(page);
          return _pageResponse(page);
        }),
      );
      final repository = NetworkDailyQuoteRepository(apiClient);

      await repository.fetchNextPage('005930');
      await repository.fetchNextPage('005930');
      await repository.fetchNextPage('005930');

      expect(requestedPages, [1, 2, 3]);
    });

    test('이미 가져온 페이지는 재요청하지 않는다 (요청 횟수로 검증)', () async {
      var requestCount = 0;
      final apiClient = ApiClient(
        client: MockClient((request) async {
          requestCount++;
          final page = int.parse(request.url.queryParameters['page']!);
          return _pageResponse(page);
        }),
      );
      final repository = NetworkDailyQuoteRepository(apiClient);

      await repository.fetchNextPage('005930');
      await repository.fetchNextPage('005930');

      expect(requestCount, 2); // 페이지 1, 2 — 각각 1번씩만 요청됨
    });

    test('lastPage에 도달한 뒤 추가로 호출하면 네트워크 요청 없이 빈 리스트를 반환한다', () async {
      var requestCount = 0;
      final apiClient = ApiClient(
        client: MockClient((request) async {
          requestCount++;
          final page = int.parse(request.url.queryParameters['page']!);
          return _pageResponse(page, lastPage: 1);
        }),
      );
      final repository = NetworkDailyQuoteRepository(apiClient);

      await repository.fetchNextPage('005930'); // 1페이지 = lastPage
      final result = await repository.fetchNextPage('005930'); // 더 없음

      expect(result, isEmpty);
      expect(requestCount, 1); // 두 번째 호출은 네트워크 요청 안 함
    });

    test('요청이 계속 실패하면 NetworkFailure를 던진다', () async {
      final apiClient = ApiClient(
        client: MockClient((request) async => http.Response('error', 500)),
        maxRetries: 0,
      );
      final repository = NetworkDailyQuoteRepository(apiClient);

      await expectLater(
        repository.fetchNextPage('005930'),
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
        repository.fetchNextPage('005930'),
        throwsA(isA<EmptyResultFailure>()),
      );
    });
  });
}
