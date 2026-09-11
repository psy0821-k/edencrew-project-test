# 이슈 3 — 검색 자동완성 도메인 (Search) + 실시간 디바운스 검색

## 시그니처

```dart
// lib/entities/search/search_result.dart
class SearchResult {
  const SearchResult({
    required this.symbol,
    required this.name,
    required this.marketName,
  });

  /// 6자리 종목코드. 예: `005930`
  final String symbol;

  /// 종목명. 예: `삼성전자`
  final String name;

  /// 거래소명. 예: `코스피` (StockMetaRepository로 보강됨)
  final String marketName;

  /// canonical id. `domestic:{symbol}` 형태.
  String get canonicalId => 'domestic:$symbol';
}

// lib/entities/search/search_repository.dart
abstract interface class SearchRepository {
  Future<List<SearchResult>> search(String query);
}

// lib/entities/search/mock_search_repository.dart
class MockSearchRepository implements SearchRepository {
  @override
  Future<List<SearchResult>> search(String query) async {
    return const [
      SearchResult(symbol: '005930', name: '삼성전자', marketName: '코스피'),
    ];
  }
}

// lib/entities/search/network_search_repository.dart
class NetworkSearchRepository implements SearchRepository {
  NetworkSearchRepository(this._apiClient, this._stockMetaRepository);
  final ApiClient _apiClient;
  final StockMetaRepository _stockMetaRepository;

  @override
  Future<List<SearchResult>> search(String query) async {
    // GET https://ac.stock.naver.com/ac?q={query}&target=stock
    // 응답 JSON: { "query": ..., "items": [{ code, name, typeCode, typeName,
    //   url, reutersCode, nationCode, nationName, category, hasDiscussion }] }
    // 1) nationCode == 'KOR' && code가 6자리 숫자인 항목만 남김
    // 2) 남은 각 항목에 대해 StockMetaRepository.fetchStockMeta(code) 호출해 marketName 보강
    // 3) SearchResult(symbol: code, name: name, marketName: <보강된 값>) 로 매핑
  }
}

// lib/entities/search/search_providers.dart
final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return switch (ref.watch(dataSourceModeProvider)) {
    DataSourceMode.mock => MockSearchRepository(),
    DataSourceMode.network => NetworkSearchRepository(
      ref.watch(apiClientProvider),
      ref.watch(stockMetaRepositoryProvider),
    ),
  };
});

// lib/features/search-query/query_normalizer.dart
/// trim() 후 문자열 내부의 모든 공백을 제거한다. 예: "삼성 전자" → "삼성전자"
String normalizeQuery(String raw) => raw.trim().replaceAll(RegExp(r'\s+'), '');

// lib/features/search-query/highlight_matcher.dart
/// 정규화된 [query] 기준으로 [name] 안에서 첫 매치의 시작/끝 인덱스(끝은 exclusive)를 찾는다.
/// 매치가 없으면 null.
({int start, int end})? findHighlightRange(String name, String query) { ... }

// lib/features/search-query/search_debouncer_notifier.dart
/// 원본 입력 문자열을 받아 Debouncer(300ms)로 지연시킨 뒤,
/// normalizeQuery 적용 결과 길이가 2 미만이면 검색하지 않고 빈 목록으로 상태를 갱신하며,
/// 2 이상이면 searchRepositoryProvider.search(...)를 호출해 상태를 갱신한다.
class SearchDebouncerNotifier extends AsyncNotifier<List<SearchResult>> {
  @override
  Future<List<SearchResult>> build() async => [];

  /// 사용자가 타이핑할 때마다 호출. 원본(정규화 전) 문자열을 그대로 전달한다.
  void onQueryChanged(String raw) { ... }
}

final searchDebouncerNotifierProvider =
    AsyncNotifierProvider<SearchDebouncerNotifier, List<SearchResult>>(
  SearchDebouncerNotifier.new,
);
```

### 설계 메모 (가정 및 근거)

- **`items` 배열 구조**: 실제 `ac.stock.naver.com/ac?q=삼성전자&target=stock`을 직접 호출해 응답을 확인한 결과, `items`는 **단순 배열**(배열의 배열 아님)이었다. 각 원소는 `code`, `name`, `typeCode`, `typeName`, `url`, `reutersCode`, `nationCode`, `nationName`, `category`, `hasDiscussion` 필드를 가진다. 이 실측 구조를 그대로 채택한다.
- **6자리 코드 필터링이 실제로 필요함을 확인**: 같은 응답에 `005930`(삼성전자, 6자리)뿐 아니라 `0162Z0`, `448330` 같은 ETF/ETN 코드(6자리 숫자가 아니거나 숫자+영문 혼합)도 `category: "stock"`으로 섞여 나왔다. `RegExp(r'^\d{6}$')`로 순수 6자리 숫자만 통과시킨다.
- **`nationCode`**: 실측 결과 국내 종목은 `"KOR"`이었다. `nationCode == 'KOR'`로 필터링한다.
- **StockMeta 보강 방식**: `network_search_repository.dart`는 필터링 후 남은 각 종목에 대해 `StockMetaRepository.fetchStockMeta(symbol)`을 호출해 `marketName`을 얻는다. 자동완성 응답의 `typeName`(예: "코스피")과 값이 겹칠 수 있으나, issue-3 작업 범위에 "StockMeta 결합"이 명시되어 있으므로 `typeName`을 그대로 쓰지 않고 `StockMetaRepository`를 경유한다.
- **`SearchDebouncerNotifier`의 Riverpod API 선택**: `pubspec.yaml`에서 `flutter_riverpod: ^2.6.1` 확인. 2.x에서 비동기 상태를 다루는 관용적 방식은 `AsyncNotifier`(제네레이터 방식, `StateNotifier`보다 권장)이므로 이를 채택했다.

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

## 테스트 시나리오

### SearchResult

- [정상] `symbol`, `name`, `marketName`을 전달해 생성하면 각 필드에 전달한 값이 그대로 저장되어야 한다
- [정상] `symbol='005930'`일 때 `canonicalId`는 `'domestic:005930'`을 반환해야 한다

### normalizeQuery

- [정상] `"삼성 전자"`(중간 공백 1개)를 넣으면 `"삼성전자"`를 반환해야 한다
- [정상] `"  삼성전자  "`(앞뒤 공백)를 넣으면 `"삼성전자"`를 반환해야 한다
- [경계] `"삼   성   전   자"`(여러 공백)를 넣으면 `"삼성전자"`를 반환해야 한다
- [경계] 빈 문자열을 넣으면 빈 문자열을 반환해야 한다

### findHighlightRange

- [정상] `name="삼성전자"`, `query="삼성전자"`(정규화 후)일 때 `start=0, end=4`를 반환해야 한다
- [정상] `name="삼성전자"`, `query="전자"`일 때 `start=2, end=4`를 반환해야 한다
- [경계] `query`가 `name`에 없으면 `null`을 반환해야 한다
- [경계] `query`가 빈 문자열이면 `null`을 반환해야 한다

### NetworkSearchRepository.search

- [정상] 응답 `items`에 국내 6자리 종목(`005930`)만 있으면 `StockMetaRepository.fetchStockMeta`로 보강된 `marketName`을 포함한 `SearchResult` 목록을 반환해야 한다
- [정상] `symbol='005930'`인 결과의 `canonicalId`는 `'domestic:005930'`이어야 한다
- [경계] 응답에 해외 주식(`nationCode != 'KOR'`)이 섞여 있으면 결과에서 제외되어야 한다
- [경계] 응답에 6자리가 아닌 코드(`0162Z0`, `448330` 등)가 섞여 있으면 결과에서 제외되어야 한다
- [경계] 필터링 후 남은 종목이 없으면 빈 리스트를 반환해야 한다 (요청은 보내되 `EmptyResultFailure`를 던지지 않음 — 검색 결과 없음은 정상 흐름)
- [경계] 응답 body가 비어있으면 `EmptyResultFailure`를 던져야 한다
- [예외] 요청이 계속 실패(5xx)하면 재시도 후 `NetworkFailure`를 던져야 한다
- [예외] 응답 body가 유효한 JSON이 아니면 `ParsingFailure`를 던져야 한다
- [예외] 응답 항목에 `code`/`name` 등 필수 필드가 없으면 `ParsingFailure`를 던져야 한다

### MockSearchRepository.search

- [정상] 임의의 query로 호출하면 고정된 `SearchResult` 목록을 반환해야 한다

### searchRepositoryProvider

- [정상] `dataSourceModeProvider`가 기본값(`network`)일 때 `NetworkSearchRepository`를 반환해야 한다
- [정상] `dataSourceModeProvider`를 `mock`으로 override하면 `MockSearchRepository`를 반환해야 한다
- [경계] `searchRepositoryProvider` 자체를 개별 override하면 전역 모드와 무관하게 그 값이 우선해야 한다

### SearchDebouncerNotifier

- [정상] 2글자 이상 입력 후 300ms가 지나면 정규화된 값으로 `searchRepositoryProvider.search`를 1회 호출하고 결과로 상태가 갱신되어야 한다
- [경계] 1글자만 입력하면 300ms가 지나도 `search`가 호출되지 않아야 한다
- [경계] 2글자 이상을 연속으로 여러 번 입력(각 300ms 이내 간격)하면, 타이핑이 멈추고 300ms 후 마지막 입력값으로만 1회 호출되어야 한다
- [경계] 정규화 후 길이가 2 미만이 되면(예: 공백만 입력) `search`가 호출되지 않고 빈 목록으로 상태가 갱신되어야 한다

## AC 커버리지 대조

| AC | 커버 시나리오 |
|---|---|
| `"삼성 전자"` → `"삼성전자"` 정규화 | `normalizeQuery` [정상] (중간 공백 1개) |
| 해외 주식/5자리 이하 코드 필터링 → 국내 6자리만 남음 | `NetworkSearchRepository.search` [경계] (해외 주식 제외, 6자리 아닌 코드 제외) |
| `005930` → canonical id `domestic:005930` | `SearchResult` [정상] (canonicalId), `NetworkSearchRepository.search` [정상] (canonicalId) |
| 1글자 입력 시 300ms 지나도 요청 없음 | `SearchDebouncerNotifier` [경계] (1글자) |
| 2글자 이상 연속 입력 시 마지막 값으로만 1회 요청 | `SearchDebouncerNotifier` [경계] (연속 입력) |
| `"삼성전자"` + 검색어 `"삼성 전자"` → 하이라이트 위치 정확히 찾음 | `findHighlightRange` [정상] (전체 일치), `normalizeQuery`와 조합 |

모든 AC가 시나리오로 커버됨을 확인했다.
