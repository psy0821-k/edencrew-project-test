# 이슈 3 — 검색 자동완성 도메인 (Search) + 실시간 디바운스 검색

## 설명

`ac.stock.naver.com/ac`를 호출해 종목 후보를 조회하는 도메인을 구현하고, 국내 주식 필터링·canonical id 생성·StockMeta 결합까지 완성한다. 검색 입력을 실시간+디바운스로 처리하는 로직도 함께 구현한다(화면 UI 자체는 Phase 4에서, 이 이슈는 검색 실행 로직까지).

## 작업 범위

- `entities/search/search_result.dart`: `SearchResult` 모델 (`symbol`, `name`, `marketName`)
- `entities/search/search_repository.dart`: 추상 인터페이스 (`Future<List<SearchResult>> search(String query)`)
- `entities/search/mock_search_repository.dart`, `network_search_repository.dart`
  - Network 구현체: 국내 주식만 필터링(`nationCode`/`category` 확인), 6자리 종목코드만 통과, canonical id `domestic:{symbol}` 생성, `StockMetaRepository`와 결합해 거래소명 보강
- `entities/search/search_providers.dart`
- `features/search-query/query_normalizer.dart`: `trim()` + 중간 공백 제거 정규화 함수 (요청 전처리와 하이라이트 매칭 양쪽에서 공용으로 재사용)
- `features/search-query/search_debouncer_notifier.dart` (가칭): `Debouncer`(300ms) + 최소 2글자 조건을 적용해 `searchResultsProvider`를 트리거하는 Notifier
- `assets/mock/search_samsung.json` 저장

## Acceptance Criteria

- [ ] Given 검색어 `"삼성 전자"`(중간 공백 포함)로, When 정규화 함수를 거치면, Then `"삼성전자"`로 변환된다
- [ ] Given API 응답에 해외 주식(`nationCode != 'KOR'`) 또는 5자리 이하 코드가 섞여 있으면, When 필터링하면, Then 국내 6자리 종목코드만 남는다
- [ ] Given 종목코드 `005930`이 검색 결과에 있을 때, When canonical id를 생성하면, Then `domestic:005930`을 반환한다
- [ ] Given 검색창에 1글자만 입력했을 때, When 300ms가 지나도, Then API 요청이 발생하지 않는다
- [ ] Given 검색창에 2글자 이상 입력 후 300ms 이내에 추가로 입력했을 때, When 타이핑이 멈추고 300ms가 지나면, Then 마지막 입력값으로만 1회 요청한다
- [ ] Given 검색 결과 종목명이 `"삼성전자"`이고 검색어가 `"삼성 전자"`일 때, When 하이라이트 매칭을 수행하면, Then 정규화된 검색어 기준으로 하이라이트 위치를 정확히 찾는다

## 의존성

이슈 1 (StockMeta — 거래소명 결합에 필요)

## 시간 상한

1.5시간
