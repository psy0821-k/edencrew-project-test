# TDD Red 계획 — 이슈 4 (DailyQuote: EUC-KR 디코딩 + HTML 파싱 + 페이지 캐시)

issue-4.md에 확정된 시그니처(무한 스크롤 기준으로 재설계됨)를 테스트 파일로 옮기는 계획. 아직 구현 코드는 작성하지 않음.

## 작성할 파일과 테스트 목록

### 1. `test/shared/utils/euc_kr_decoder_test.dart`
- [정상] `가` 등 실측 확인된 EUC-KR 바이트(`0xB0 0xA1`)를 디코딩하면 `'가'`를 반환한다
- [정상] "날짜, 종가, 거래량" 등 실제 응답에 등장하는 여러 글자를 포함한 바이트 시퀀스를 디코딩하면 원문과 일치한다
- [경계] ASCII 문자(영문/숫자/기호)가 섞인 바이트를 디코딩하면 그대로 유지된다 (한글 아닌 바이트는 1바이트로 통과)
- [예외] 매핑 테이블에 없는 EUC-KR 바이트 조합을 디코딩하면 `FormatException`을 던진다 (알 수 없는 문자를 조용히 무시하지 않음)

### 2. `test/entities/daily_quote/daily_quote_page_parser_test.dart` (HTML 파싱 로직 — 순수 함수로 분리 예정)
- [정상] 실제 응답 형태의 HTML(실측 샘플 기반)을 파싱하면 10개의 `DailyQuote`가 날짜 역순(최신순)으로 추출된다
- [정상] `td.num` 6개 중 전일비를 제외한 종가/시가/고가/저가/거래량이 각 필드로 정확히 매핑된다
- [정상] 콤마 포함 숫자(`259,500`)가 정수로 올바르게 파싱된다
- [정상] `2026.09.11` 형식 날짜가 `20260911`(yyyyMMdd)로 정규화된다
- [정상] `pgRR` 링크에서 `lastPage`(예: 756)가 정확히 추출된다
- [경계] 데이터 행이 0개인 HTML을 파싱하면 빈 리스트를 반환한다 (EmptyResultFailure는 Repository 레이어에서 던짐 — 파서 자체는 빈 결과만 반환)
- [예외] `pgRR` 링크를 찾을 수 없으면 `ParsingFailure`를 던진다

### 3. `test/entities/daily_quote/network_daily_quote_repository_test.dart`
- [정상] symbol을 처음 요청하면 1페이지를 반환한다
- [정상] 같은 symbol로 연속 `fetchNextPage`를 호출하면 페이지 번호가 순서대로 증가하며 겹치지 않는다 (1페이지 → 2페이지 → 3페이지)
- [정상] 이미 가져온 페이지는 재요청하지 않는다 (HTTP 요청 횟수로 검증 — 같은 symbol에 N번 호출 시 정확히 N번만 요청)
- [경계] `lastPage`에 도달한 뒤 추가로 호출하면 네트워크 요청 없이 빈 리스트를 반환한다
- [예외] 요청이 계속 실패하면 `NetworkFailure`를 던진다
- [예외] 응답 body가 비어있으면 `EmptyResultFailure`를 던진다

### 4. `test/entities/daily_quote/mock_daily_quote_repository_test.dart`
- [정상] symbol별로 호출할 때마다 다음 페이지의 고정 데이터를 순서대로 반환한다

### 5. `test/entities/daily_quote/daily_quote_providers_test.dart`
- [정상] `dataSourceMode` 기본값(network)일 때 `NetworkDailyQuoteRepository`를 반환한다
- [정상] `dataSourceMode`를 mock으로 override하면 `MockDailyQuoteRepository`를 반환한다

## AC 커버리지 대조 (재해석된 AC 기준)

| 원 AC | 재해석 | 커버 시나리오 |
|---|---|---|
| EUC-KR 디코딩 시 한글 안 깨짐 | 동일 | euc_kr_decoder_test [정상] 2건 |
| HTML 1페이지 파싱 → 10개 DailyQuote, 날짜 역순 | 동일 | daily_quote_page_parser_test [정상] |
| 캐시된 페이지 재요청 안 함 | "연속 호출 시 페이지 순서 증가 + 겹치지 않음 + 실제 요청 횟수로 검증" | network_daily_quote_repository_test [정상] 2건 |
| lastPage 초과 요청 금지 | "lastPage 도달 후 추가 호출 시 네트워크 요청 없이 빈 리스트" | network_daily_quote_repository_test [경계] |
| Riverpod family 캐시 확인(동일 조합 재watch 시 재요청 없음) | Provider 자체는 Repository 결과를 감싸기만 하므로, Repository의 내부 캐시 검증으로 대체(위 항목과 동일 시나리오) | network_daily_quote_repository_test [정상] |

모든 AC가(재해석 형태로) 시나리오로 커버됨을 확인했다.

---

## 실행 결과

`euc_kr_decoder_test.dart`, `daily_quote_page_parser_test.dart`, `network_daily_quote_repository_test.dart`, `mock_daily_quote_repository_test.dart`, `daily_quote_providers_test.dart` 5개 파일 모두 구현 파일이 없어 컴파일 실패(Red) 확인. 오타나 테스트 코드 실수가 아니라 "구현이 없어서" 나는 예상된 실패임을 각 에러 메시지로 확인했다.

파싱 테스트는 실제 Naver 서버에서 실측한 EUC-KR HTML 응답(`assets/mock/daily_quote_005930_page1.html`, `daily_quote_005930_page2.html`)을 기반으로 작성했다.
