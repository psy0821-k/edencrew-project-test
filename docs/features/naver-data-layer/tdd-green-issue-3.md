# TDD Green 계획 — 이슈 3 (Search 도메인 + 실시간 디바운스 검색)

`test/entities/search/`, `test/features/search-query/` 아래 Red 상태인 테스트 7개 파일을 통과시키기 위해 만들 **구현 파일 8개 + mock JSON 1개** 계획입니다. 아직 구현 코드는 작성하지 않았습니다.

## 만들 파일

### 1. `lib/entities/search/search_result.dart`
issue-3.md에 확정된 시그니처 그대로. `symbol`/`name`/`marketName` 3개 필드 + `canonicalId` getter(`'domestic:$symbol'`)를 갖는 불변 클래스.

### 2. `lib/entities/search/search_repository.dart`
`Future<List<SearchResult>> search(String query)` 한 개 메서드를 가진 추상 인터페이스. `entities/stock_meta/stock_meta_repository.dart`와 동일한 형태.

### 3. `lib/entities/search/mock_search_repository.dart`
네트워크 호출 없이 고정된 `SearchResult` 목록(삼성전자 1건)을 반환. `mock_stock_meta_repository.dart`와 동일 패턴.

### 4. `lib/entities/search/network_search_repository.dart`
실제 구현이 들어가는 핵심 파일. `ApiClient`와 `StockMetaRepository`를 생성자로 주입받는다.

1. **응답 body가 비어있으면** → `EmptyResultFailure`
2. **`jsonDecode`로 JSON 파싱 시도** → 실패하면 `ParsingFailure`
3. **`items` 배열을 순회**하며 각 항목에서 `code`/`name`/`nationCode` 3개 키를 꺼냄 → `code`나 `name`이 없으면(타입 불일치 포함) `ParsingFailure`
4. **필터링**: `nationCode == 'KOR'` && `code`가 `RegExp(r'^\d{6}$')`에 매치하는 항목만 통과
5. **필터링 후 남은 각 항목**에 대해 `StockMetaRepository.fetchStockMeta(code)`를 호출해 `marketName`을 얻음 (실제 국내 필드 검증 요구사항 — issue-3.md 작업범위)
6. `SearchResult(symbol: code, name: name, marketName: <StockMeta.marketName>)`로 매핑해 리스트 반환. 필터링 후 결과가 0건이어도 예외 없이 빈 리스트 반환 (검색 결과 없음은 정상 흐름).

네트워크 요청 자체의 실패(타임아웃, 5xx 등)는 `ApiClient.get()` 안에서 이미 처리되므로 `on Failure { rethrow; }` 패턴을 그대로 따른다 (`network_stock_meta_repository.dart`와 동일).

### 5. `lib/entities/search/search_providers.dart`
Riverpod provider 하나. `dataSourceModeProvider`에 따라 Mock/Network 구현체를 고른다. `apiClientProvider`(entities/quote/quote_providers.dart)와 `stockMetaRepositoryProvider`(entities/stock_meta/stock_meta_providers.dart)는 재사용하고 새로 정의하지 않는다.

### 6. `lib/features/search-query/query_normalizer.dart`
`String normalizeQuery(String raw) => raw.trim().replaceAll(RegExp(r'\s+'), '');`

### 7. `lib/features/search-query/highlight_matcher.dart`
`normalizeQuery`로 `query`를 정규화한 뒤(호출 측 책임 — 함수 자체는 순수 문자열 매칭만) `name.indexOf(query)`로 첫 매치 위치를 찾아 `(start, end)` 레코드 반환, 없으면 `null`. `query`가 빈 문자열이면 무조건 `null` (issue-3.md 시나리오).

### 8. `lib/features/search-query/search_debouncer_notifier.dart`
`AsyncNotifier<List<SearchResult>>` 기반. 내부에 `Debouncer(300ms)`를 갖고(`ref.onDispose`로 정리), `onQueryChanged(String raw)`가 호출되면:

1. `Debouncer.run(...)`으로 지연
2. 지연 콜백 안에서 `normalizeQuery(raw)` 적용
3. 정규화 결과 길이가 2 미만이면 `state = const AsyncData([])`
4. 2 이상이면 `state = const AsyncLoading()` 후 `searchRepositoryProvider.search(...)` 호출 결과로 `state` 갱신 (`AsyncValue.guard` 활용)

`ref.watch(searchRepositoryProvider)`로 Repository를 얻는다(테스트의 override가 반영되도록).

### 9. `assets/mock/search_samsung.json`
issue-3.md에서 확인한 **실제 Naver 자동완성 API 응답 구조**(직접 호출로 확보)를 그대로 반영. 6자리 종목(005930)과 6자리가 아닌 ETF 코드(0162Z0 등)를 섞어 필터링 로직 검증용 샘플로 구성.

## 진행 방식

시나리오 하나를 통과시킬 때마다 바로 `flutter test`를 돌려서, 의도한 이유로 통과하는지 확인하며 하나씩 진행한다 (파일 단위: 1→2→3→4→5→6→7→8 순서로 구현하며, 의존관계상 `search_result.dart`/`search_repository.dart`를 먼저 만들어야 나머지가 컴파일된다).

## 설계 메모

- `network_search_repository.dart`의 `StockMetaRepository` 호출은 종목 개수만큼 개별 HTTP 호출이 발생한다 (검색 결과는 보통 소수이므로 Quote처럼 배치 API가 없는 한 이 방식이 유일한 선택 — NAVER_API.md 3번 섹션에도 배치 조회 언급이 없음).
- `highlight_matcher.dart`는 정규화된 검색어를 넘겨받는다고 가정한다(함수 시그니처상 정규화를 안쪽에서 강제하지 않음) — 실제 사용 시 UI 레이어가 `normalizeQuery`를 먼저 적용해서 넘기는 책임 분리 구조. issue-3.md AC의 "정규화된 검색어 기준"이라는 표현과 일치.

---

## 실행 결과 (구현 완료 후 기록)

계획대로 파일 8개(`search_result.dart`, `search_repository.dart`, `mock_search_repository.dart`, `network_search_repository.dart`, `search_providers.dart`, `query_normalizer.dart`, `highlight_matcher.dart`, `search_debouncer_notifier.dart`) + mock JSON 1개(`search_samsung.json`)를 순서대로 생성했고, 파일 하나를 만들 때마다 대응하는 테스트를 즉시 실행해 통과를 확인했다.

- `search_result.dart` → `search_result_test.dart` 2개 통과
- `mock_search_repository.dart` → `mock_search_repository_test.dart` 1개 통과
- `network_search_repository.dart` → `network_search_repository_test.dart` 9개 통과 (한 번에 통과, 추가 수정 없음)
- `search_providers.dart` → `search_providers_test.dart` 3개 통과
- `query_normalizer.dart`/`highlight_matcher.dart` → 각 테스트 4개씩 통과
- `search_debouncer_notifier.dart` → `search_debouncer_notifier_test.dart` 4개 통과 (한 번에 통과, 추가 수정 없음)

### 설계 메모 보강

- `NetworkSearchRepository`는 검색 결과 종목 수만큼 `StockMetaRepository.fetchStockMeta`를 순차 호출한다(배치 API가 없으므로). 검색 결과는 보통 소수(자동완성 특성상)라 실사용에 문제 없다고 판단했다.
- `assets/mock/search_samsung.json`은 `ac.stock.naver.com/ac?q=삼성전자&target=stock`을 직접 호출해 확보한 **실제 응답 구조**를 기반으로 작성했다(이슈-3.md 설계 메모에 근거 기록). `items`는 단순 배열이며, 6자리 종목(`005930`)과 6자리가 아닌 ETF 코드(`0162Z0`, `448330`)를 함께 포함시켜 필터링 로직을 mock으로도 검증할 수 있도록 구성했다.

### 최종 확인

- `dart format lib/entities/search/ lib/features/search-query/ test/entities/search/ test/features/search-query/` 적용 (기존 스타일 유지, 2개 테스트 파일만 줄바꿈 조정됨).
- `flutter test`: **전체 74개 통과** (기존 47개 + 이번 이슈 27개: search_result 2 + mock_search 1 + network_search 9 + search_providers 3 + query_normalizer 4 + highlight_matcher 4 + search_debouncer_notifier 4).
- `flutter analyze`: **No issues found!**

다음 단계: 커밋 (작업 단위로 분리 예정, 사용자가 직접 검토 후 진행).
