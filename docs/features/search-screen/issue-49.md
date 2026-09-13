# Issue #49 — 검색 결과 종목 메타데이터 캐싱 적용

## 시그니처

```dart
/// StockMetaRepository를 감싸 symbol별 조회 결과를 인메모리에 캐싱하는 데코레이터.
/// 거래소명 등 메타데이터는 거의 바뀌지 않으므로 무효화 정책 없이 앱 생명주기 동안 유지한다.
class CachingStockMetaRepository implements StockMetaRepository {
  CachingStockMetaRepository(this._delegate);

  final StockMetaRepository _delegate;
  final Map<String, StockMeta> _cache = {};

  @override
  Future<StockMeta> fetchStockMeta(String symbol) async {
    final cached = _cache[symbol];
    if (cached != null) return cached;

    final meta = await _delegate.fetchStockMeta(symbol);
    _cache[symbol] = meta;
    return meta;
  }
}
```

- 위치: `lib/entities/stock_meta/caching_stock_meta_repository.dart`
- `stock_meta_providers.dart`의 `network` 분기에서 `NetworkStockMetaRepository`를 `CachingStockMetaRepository`로 감싸 반환한다. `mock` 분기는 감싸지 않는다(고정 데이터라 캐싱 이점 없음).

## 테스트 시나리오

### CachingStockMetaRepository

- [정상] 같은 symbol을 두 번 조회하면 delegate의 fetchStockMeta가 1회만 호출되고, 두 번째 호출도 첫 번째와 동일한 StockMeta를 반환해야 한다
- [정상] 서로 다른 symbol을 조회하면 각각 delegate가 호출되어야 한다
- [경계] 캐시에 없는 symbol을 조회하면 delegate 호출 후 결과가 캐시에 저장되어, 이어지는 동일 symbol 조회 시 delegate가 다시 호출되지 않아야 한다
- [예외] delegate가 예외를 던지면 그 예외가 그대로 전파되고, 실패한 조회는 캐시에 저장되지 않아야 한다(다음 호출에서 재시도 가능해야 함)

## AC 커버리지

- 동일 symbol 재조회 시 API 미재호출 → 시나리오 1, 3
- 새 symbol은 정상 조회 및 캐시 저장 → 시나리오 2, 3
- 기존 검색 기능 회귀 없음 → 기존 search_page_test.dart, network_search_repository_test.dart로 커버(변경 없음 확인용)
