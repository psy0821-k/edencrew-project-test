# TDD Red 계획 — 이슈 3 (Search 도메인 + 실시간 디바운스 검색)

`docs/features/naver-data-layer/issue-3.md`에 확정된 시그니처/시나리오를 실제 **테스트 파일**로 옮기는 계획입니다. 아래 계획대로 테스트 코드(.dart)만 작성하고 `lib/` 구현은 만들지 않습니다. 따라서 전부 컴파일 에러로 실패(Red)하는 것이 정상입니다.

기존 `entities/stock_meta/`, `entities/quote/` 테스트 스타일(`http/testing.dart`의 `MockClient`, `ProviderContainer` + override)을 그대로 따릅니다.

## 작성할 파일 6개와 각 파일의 테스트 목록

### 1. `test/entities/search/search_result_test.dart`
- symbol/name/marketName을 넣어 생성하면 각 필드에 그대로 저장된다
- `symbol='005930'`일 때 `canonicalId`는 `'domestic:005930'`을 반환한다

### 2. `test/entities/search/network_search_repository_test.dart`
`NetworkSearchRepository`는 `ApiClient`와 (fake) `StockMetaRepository`를 함께 주입받는다. `StockMetaRepository`는 실제 네트워크 호출 없이 고정값을 돌려주는 fake 클래스를 테스트 파일 안에 정의해 사용한다 (`stock_meta_providers_test.dart`의 `_FakeStockMetaRepository` 패턴 참고).

- [정상] 응답 `items`에 국내 6자리 종목만 있으면 `StockMetaRepository.fetchStockMeta`로 보강된 `marketName`을 포함한 `SearchResult` 목록을 반환한다
- [정상] 반환된 `SearchResult`의 `canonicalId`가 `'domestic:005930'`이다
- [경계] `nationCode != 'KOR'`인 해외 주식이 섞여 있으면 결과에서 제외된다
- [경계] 6자리 숫자가 아닌 코드(`0162Z0`, `448330`)가 섞여 있으면 결과에서 제외된다
- [경계] 필터링 후 남은 종목이 없으면 빈 리스트를 반환한다 (예외를 던지지 않음)
- [경계] 응답 body가 비어있으면 `EmptyResultFailure`를 던진다
- [예외] 요청이 계속 실패(500)하면 재시도 후 `NetworkFailure`를 던진다
- [예외] 응답 body가 유효한 JSON이 아니면 `ParsingFailure`를 던진다
- [예외] 응답 항목에 `code`가 없으면 `ParsingFailure`를 던진다

### 3. `test/entities/search/mock_search_repository_test.dart`
- 임의의 query로 호출하면 고정된 `SearchResult` 목록을 반환한다

### 4. `test/entities/search/search_providers_test.dart`
`stockMetaRepositoryProvider`/`apiClientProvider`는 재정의하지 않고 기존 provider를 그대로 사용한다.

- [정상] `dataSourceModeProvider` 기본값(`network`)일 때 `NetworkSearchRepository`를 반환한다
- [정상] `dataSourceModeProvider`를 `mock`으로 override하면 `MockSearchRepository`를 반환한다
- [경계] `searchRepositoryProvider` 자체를 override하면 그 값이 우선한다

### 5. `test/features/search-query/query_normalizer_test.dart`
- [정상] `"삼성 전자"`(중간 공백 1개) → `"삼성전자"`
- [정상] `"  삼성전자  "`(앞뒤 공백) → `"삼성전자"`
- [경계] `"삼   성   전   자"`(여러 공백) → `"삼성전자"`
- [경계] 빈 문자열 → 빈 문자열

### 6. `test/features/search-query/highlight_matcher_test.dart`
- [정상] `name="삼성전자"`, `query="삼성전자"` → `start=0, end=4`
- [정상] `name="삼성전자"`, `query="전자"` → `start=2, end=4`
- [경계] `query`가 `name`에 없으면 `null`
- [경계] `query`가 빈 문자열이면 `null`

### 7. `test/features/search-query/search_debouncer_notifier_test.dart`
기존 `test/shared/utils/debouncer_test.dart`와 동일하게 실제 시간 대기(`await Future<void>.delayed(...)`) 방식을 사용한다. `fake_async` 패키지는 `pubspec.lock`에 transitive dependency로는 존재하지만, `Debouncer`가 내부적으로 `Timer`를 쓰고 `AsyncNotifier`가 비동기 체인을 타므로 `fakeAsync`와 섞으면 pending microtask/타이머 정리 문제가 생길 리스크가 있어, 기존 프로젝트 관례(실시간 대기)를 그대로 따르기로 했다. `searchRepositoryProvider`는 호출 횟수/인자를 기록하는 fake로 override한다.

- [정상] 2글자 이상 입력 후 300ms 초과 대기하면 정규화된 값으로 `search`가 1회 호출되고 상태가 결과로 갱신된다
- [경계] 1글자만 입력하고 300ms 초과 대기해도 `search`가 호출되지 않는다
- [경계] 2글자 이상을 연속 입력(짧은 간격)하면 마지막 입력값으로만 1회 호출된다
- [경계] 공백만 입력(정규화 후 길이 0)하면 `search`가 호출되지 않고 빈 목록으로 상태가 갱신된다

## AC 대조 (issue-3.md 6개 AC 모두 커버)

| issue-3.md AC | 커버하는 테스트 |
|---|---|
| `"삼성 전자"` → `"삼성전자"` 정규화 | 5번 파일 - 중간 공백 1개 케이스 |
| 해외 주식/6자리 아닌 코드 필터링 | 2번 파일 - 경계 케이스 2건 |
| `005930` → `domestic:005930` | 1번 파일 - canonicalId, 2번 파일 - canonicalId |
| 1글자 입력 시 요청 없음 | 7번 파일 - 1글자 케이스 |
| 연속 입력 시 마지막 값만 1회 요청 | 7번 파일 - 연속 입력 케이스 |
| 하이라이트 위치 정확히 찾음 | 6번 파일 - 전체/부분 일치 케이스 |

---

## 실행 결과 (작성 완료 후 기록)

`flutter test test/entities/search/ test/features/search-query/` 실행 결과: **7개 파일 모두 실패(Red) 확인됨.**

모든 실패는 `lib/entities/search/`, `lib/features/search-query/` 구현 파일이 아직 없어서 나는 컴파일 에러(`Error when reading '...': 지정된 경로를 찾을 수 없습니다`, `Undefined name`, `Type ... not found`)이며, 테스트 코드 자체의 오타나 실수로 인한 실패가 아님을 확인했다.

`flutter test` 전체 실행 결과, 기존 47개 테스트는 영향받지 않고 그대로 통과 중이다.

계획 대비 변경 사항: `search_debouncer_notifier_test.dart`는 애초 `fake_async`의 `fakeAsync()`로 가상 시간을 쓰려 했으나, 기존 `test/shared/utils/debouncer_test.dart`가 실시간 대기 방식을 쓰고 있고 `AsyncNotifier` + `Timer` 조합에서 `fakeAsync`가 pending microtask 문제를 일으킬 리스크가 있어 실시간 대기(`await Future<void>.delayed(...)`) 방식으로 최종 작성했다 (프로젝트 기존 관례와의 일관성 우선).

다음 단계: TDD Green — `lib/entities/search/`, `lib/features/search-query/` 아래 실제 구현 코드 작성.
