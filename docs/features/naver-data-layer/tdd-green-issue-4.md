# TDD Green 계획 — 이슈 4 (DailyQuote)

`test/entities/daily_quote/`, `test/shared/utils/euc_kr_decoder_test.dart`의 Red 테스트를 통과시키기 위한 구현 파일 계획.

## 만들 파일

1. **`lib/shared/utils/euc_kr_decoder.dart`** — `dart:convert`의 `Encoding` 서브클래스. 실제 응답에서 실측한 39개 한글 문자(가거게고권끝날네다뒤락래량리맨별보비상세션스승시음이일작저전종증지짜트페하합) + ASCII 전체를 담은 매핑 테이블. 테이블에 없는 바이트 조합은 `FormatException`.
2. **`lib/entities/daily_quote/daily_quote.dart`** — 모델.
3. **`lib/entities/daily_quote/daily_quote_page.dart`** — 한 페이지 파싱 결과 + lastPage.
4. **`lib/entities/daily_quote/daily_quote_page_parser.dart`** — `parseDailyQuotePage(String html) -> DailyQuotePage` 순수 함수. `html` 패키지로 `tr[onMouseOver]` 행 순회, `pgRR` 링크에서 lastPage 정규식 추출.
5. **`lib/entities/daily_quote/daily_quote_repository.dart`** — 인터페이스.
6. **`lib/entities/daily_quote/mock_daily_quote_repository.dart`** — symbol별 호출 횟수를 세어 다른 고정 데이터를 순서대로 반환.
7. **`lib/entities/daily_quote/network_daily_quote_repository.dart`** — symbol별 캐시 상태(다음 페이지 번호, lastPage) 관리 + `ApiClient.get` + `eucKr.decode` + `parseDailyQuotePage` 결합.
8. **`lib/entities/daily_quote/daily_quote_providers.dart`** — `dailyQuoteRepositoryProvider` (기존 `apiClientProvider` 재사용).
9. **`pubspec.yaml`**에 `html` 패키지 추가.

시나리오 하나 만들 때마다 바로 `flutter test`로 확인하며 진행.

## 실행 결과

계획대로 9개 파일(`html` 패키지 추가 포함)을 만들었고, 시나리오 하나씩 만들 때마다 `flutter test`로 확인하며 진행했다.

- `euc_kr_decoder.dart`: 실측한 39개 한글 + ASCII 매핑으로 구현, 4개 테스트 전부 통과.
- `daily_quote_page_parser.dart`: 실측 EUC-KR HTML(`assets/mock/daily_quote_005930_page1.html`)을 `eucKr.decode`로 디코딩한 뒤 파싱 — 실제 응답으로 검증했기 때문에 필드 매핑(종가/시가/고가/저가/거래량 순서, lastPage 추출 정규식)의 신뢰도가 높음.
- `network_daily_quote_repository_test.dart` 작성 중 테스트 데이터 버그 발견: 한 자리 날짜(`2026.09.9`)를 넣었더니 `.replaceAll('.', '')` 결과가 7자리(`2026099`)가 되어 실패 → `padLeft(2, '0')`으로 수정 (구현 버그 아님, 테스트 데이터 실수).
- 테스트 응답에 "맨뒤" 문자열이 필요했는데, `EucKrCodec`이 디코딩만 지원(인코딩 미지원)이라 실측한 바이트(`[0xB8, 0xC7, 0xB5, 0xDA]`)를 직접 삽입하는 방식으로 작성.

최종 확인:
- `flutter test`: 94개 전체 통과 (기존 74개 + 이번 이슈 20개)
- `flutter analyze`: 경고 0건
- `dart format` 적용
- 민감정보(API 키 등) 노출 없음 확인

다음 단계: 리팩토링 검토 후 커밋.
