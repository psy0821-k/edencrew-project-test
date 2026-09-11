# 이슈 1 — 종목 메타데이터 도메인 (StockMeta)

## 시그니처

```dart
// lib/entities/stock_meta/stock_meta.dart
class StockMeta {
  const StockMeta({
    required this.symbol,
    required this.name,
    required this.marketName,
  });

  /// 6자리 종목코드. 예: `005930`
  final String symbol;

  /// 종목명. 예: `삼성전자`
  final String name;

  /// 거래소명. 예: `코스피`
  final String marketName;
}

// lib/entities/stock_meta/stock_meta_repository.dart
abstract interface class StockMetaRepository {
  Future<StockMeta> fetchStockMeta(String symbol);
}

// lib/entities/stock_meta/mock_stock_meta_repository.dart
class MockStockMetaRepository implements StockMetaRepository {
  @override
  Future<StockMeta> fetchStockMeta(String symbol) async {
    return StockMeta(symbol: symbol, name: '삼성전자', marketName: '코스피');
  }
}

// lib/entities/stock_meta/network_stock_meta_repository.dart
class NetworkStockMetaRepository implements StockMetaRepository {
  NetworkStockMetaRepository(this._apiClient);
  final ApiClient _apiClient;

  @override
  Future<StockMeta> fetchStockMeta(String symbol) async {
    // GET https://stock.naver.com/api/securityFe/api/fchart/domestic/stock/{symbol}
    // 응답 JSON: symbolCode, stockName, stockExchangeNameKor
  }
}

// lib/entities/stock_meta/stock_meta_providers.dart
final stockMetaRepositoryProvider = Provider<StockMetaRepository>((ref) {
  return switch (ref.watch(dataSourceModeProvider)) {
    DataSourceMode.mock => MockStockMetaRepository(),
    DataSourceMode.network => NetworkStockMetaRepository(ref.watch(apiClientProvider)),
  };
});
```

### 에러 케이스

- HTTP 요청 자체가 실패(`ApiClient.get`이 재시도 후에도 실패) → `NetworkFailure`
- 응답 body가 비어있음 → `EmptyResultFailure`
- JSON 파싱은 되었으나 `symbolCode`/`stockName`/`stockExchangeNameKor` 중 하나라도 없음 → `ParsingFailure`
- JSON 형식 자체가 깨져 디코딩 실패 → `ParsingFailure`

### 비고

- `apiClientProvider`는 `entities/quote/quote_providers.dart`에 이미 정의되어 있으므로 재사용한다 (중복 정의 금지).

## 설명

`stock.naver.com/api/securityFe/api/fchart/domestic/stock/{symbol}`을 호출해 종목명·거래소명을 조회하는 도메인을 구현한다. Phase 0의 Quote 도메인과 동일 패턴(`entities/stock_meta/`: 모델+Repository 인터페이스+Mock/Network 구현체+provider)을 따른다.

## 작업 범위

- `entities/stock_meta/stock_meta.dart`: `StockMeta` 모델 (`symbol`, `name`, `marketName`)
- `entities/stock_meta/stock_meta_repository.dart`: 추상 인터페이스 (`Future<StockMeta> fetchStockMeta(String symbol)`)
- `entities/stock_meta/mock_stock_meta_repository.dart`, `network_stock_meta_repository.dart`
- `entities/stock_meta/stock_meta_providers.dart`: `dataSourceModeProvider` 참조
- 응답 필드 매핑: `symbolCode`→`symbol`, `stockName`→`name`, `stockExchangeNameKor`→`marketName`
- `assets/mock/stock_meta_005930.json` 저장

## Acceptance Criteria

- [ ] Given 종목코드 `005930`으로, When `NetworkStockMetaRepository.fetchStockMeta`를 호출하면, Then `symbolCode`/`stockName`/`stockExchangeNameKor` 필드가 각각 `symbol`/`name`/`marketName`으로 매핑된 `StockMeta`를 반환한다
- [ ] Given `dataSourceModeProvider`가 `mock`일 때, When `stockMetaRepositoryProvider`를 읽으면, Then `MockStockMetaRepository`를 반환한다
- [ ] Given API 응답이 실패하면, When `fetchStockMeta`를 호출하면, Then `NetworkFailure`로 변환되어 던져진다
- [ ] Given 응답 JSON에 필요한 필드가 없으면, When 파싱을 시도하면, Then `ParsingFailure`로 변환되어 던져진다

## 의존성

없음 (Phase 1 최초 이슈, Phase 0의 `ApiClient`/`Failure`/`dataSourceModeProvider` 재사용)

## 시간 상한

1시간

## 테스트 시나리오

### StockMeta

- [정상] `symbol`, `name`, `marketName`을 전달해 생성하면 각 필드에 전달한 값이 그대로 저장되어야 한다

### NetworkStockMetaRepository.fetchStockMeta

- [정상] 응답 JSON에 `symbolCode`/`stockName`/`stockExchangeNameKor`가 모두 있으면 각각 `symbol`/`name`/`marketName`으로 매핑된 `StockMeta`를 반환해야 한다
- [경계] 응답 body가 비어있으면 `EmptyResultFailure`를 던져야 한다
- [예외] 요청이 계속 실패(5xx 등)하면 재시도 후 `NetworkFailure`를 던져야 한다
- [예외] 응답 JSON에 `symbolCode`가 없으면 `ParsingFailure`를 던져야 한다
- [예외] 응답 JSON에 `stockName`이 없으면 `ParsingFailure`를 던져야 한다
- [예외] 응답 JSON에 `stockExchangeNameKor`가 없으면 `ParsingFailure`를 던져야 한다
- [예외] 응답 body가 유효한 JSON이 아니면 `ParsingFailure`를 던져야 한다

### MockStockMetaRepository.fetchStockMeta

- [정상] 임의의 `symbol`로 호출하면 고정된 `StockMeta`(해당 `symbol` 포함)를 반환해야 한다

### stockMetaRepositoryProvider

- [정상] `dataSourceModeProvider`가 기본값(`network`)일 때 `NetworkStockMetaRepository`를 반환해야 한다
- [정상] `dataSourceModeProvider`를 `mock`으로 override하면 `MockStockMetaRepository`를 반환해야 한다
- [경계] `stockMetaRepositoryProvider` 자체를 개별 override하면 전역 모드와 무관하게 그 값이 우선해야 한다

## AC 커버리지 대조

| AC | 커버 시나리오 |
|---|---|
| `symbolCode`/`stockName`/`stockExchangeNameKor` → `symbol`/`name`/`marketName` 매핑 | `NetworkStockMetaRepository.fetchStockMeta` [정상] |
| `dataSourceModeProvider`가 `mock`일 때 `MockStockMetaRepository` 반환 | `stockMetaRepositoryProvider` [정상] (mock override) |
| API 응답 실패 → `NetworkFailure` | `NetworkStockMetaRepository.fetchStockMeta` [예외] (요청 계속 실패) |
| 필요한 필드 없음 → `ParsingFailure` | `NetworkStockMetaRepository.fetchStockMeta` [예외] (symbolCode/stockName/stockExchangeNameKor 누락 3건) |

모든 AC가 시나리오로 커버됨을 확인했다.
