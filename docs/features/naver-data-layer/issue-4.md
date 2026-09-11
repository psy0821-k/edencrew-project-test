# 이슈 4 — 일별 시세 HTML 파싱 + EUC-KR 디코딩 + 페이지 캐시 (DailyQuote)

## 설명

`finance.naver.com/item/sise_day.naver`의 HTML 응답을 `html` 패키지로 파싱하고, EUC-KR 인코딩을 직접 디코딩하며, 페이지네이션(최대 25페이지)을 Repository 단일 레이어 캐시로 재사용 가능하게 구현한다. 이 Phase에서 가장 복잡한 이슈이며 시간 상한을 반드시 지킨다.

## 작업 범위

- `pubspec.yaml`에 `html` 패키지 추가
- `shared/utils/euc_kr_decoder.dart`: `dart:convert`의 `Encoding` 서브클래스로 EUC-KR 디코더 직접 구현 (신규 외부 의존성 없이, 완성형 한글 매핑 테이블 기반)
- `entities/daily_quote/daily_quote.dart`: `DailyQuote` 모델 (`date`, `closePrice`, `openPrice`, `highPrice`, `lowPrice`, `volume`)
- `entities/daily_quote/daily_quote_page.dart`: `DailyQuotePage` (한 페이지 파싱 결과 + `lastPage` 정보)
- `entities/daily_quote/daily_quote_repository.dart`: 추상 인터페이스 (`Future<List<DailyQuote>> fetchDailyQuotes(String symbol, int requiredDays)`)
- `entities/daily_quote/mock_daily_quote_repository.dart`, `network_daily_quote_repository.dart`
  - Network 구현체: `Map<String, Map<int, DailyQuotePage>>` 캐시 전담, 캐시된 페이지 수 확인 → 부족분만 순차 요청 → 병합 반환. `lastPage` 초과 요청 금지
  - HTML 파싱: `html` 패키지로 `<table>` 행 순회, 숫자 순서(`종가, 전일비, 시가, 고가, 저가, 거래량`) 매핑, 날짜는 `DateFormatter.parseInternal` 재사용
- `entities/daily_quote/daily_quote_providers.dart`: `FutureProvider.family<List<DailyQuote>, (String symbol, Period period)>` — Repository 결과를 감싸기만 함(캐시 로직 없음)
- `assets/mock/daily_quote_005930_page1.html`, `daily_quote_005930_page2.html` 저장

## Acceptance Criteria

- [ ] Given EUC-KR로 인코딩된 응답 바이트를, When `euc_kr_decoder`로 디코딩하면, Then 한글이 깨지지 않고 정상 문자열로 변환된다
- [ ] Given 일별 시세 HTML 1페이지를, When `html` 패키지로 파싱하면, Then 10개의 `DailyQuote`가 날짜 역순(최신순)으로 추출된다
- [ ] Given 종목 `005930`에 대해 이미 2페이지(20거래일)가 캐시된 상태에서, When `requiredDays=60`(3개월, 6페이지 필요)으로 다시 요청하면, Then 캐시된 2페이지는 재요청하지 않고 3~6페이지만 추가로 요청한다
- [ ] Given `lastPage=15`인 종목에 대해, When `requiredDays`가 `lastPage`를 초과하는 페이지를 요구하면, Then 16페이지 이상은 요청하지 않고 있는 데이터만 반환한다
- [ ] Given 동일한 `(symbol, period)` 조합으로 `dailyQuoteProvider`를 두 번 연속 watch하면, When 두 번째 호출 시, Then 네트워크 재요청 없이 캐시된 결과를 즉시 반환한다 (Riverpod family 캐시 확인)

## 의존성

이슈 1 (패턴 재사용), 이슈 2의 `shared/utils/date_formatter.dart` 재사용 (Phase 0에서 이미 구현됨)

## 시간 상한

3시간 (EUC-KR 실측 확인 완료로 기존 견적 3~5시간에서 하향). **초과 시 대응**: 캔들차트/일별시세 표는 `MockDailyQuoteRepository`로 유지한 채 즉시 Phase 2로 진행한다.
