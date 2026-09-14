import 'stock_meta.dart';
import 'stock_meta_repository.dart';

/// 인메모리 캐시가 가질 수 있는 최대 symbol 수의 기본값입니다.
/// 국내 상장 종목 수(코스피·코스닥·코넥스 합쳐 약 2,700개 수준)를 다 담을
/// 필요는 없다 — 한 세션에서 사용자가 검색으로 실제 접근하는 종목은 그 일부
/// (자주 찾는 몇십~몇백 개 수준)이므로, 그 정도만 커버해도 재검색 시 재호출을
/// 막는 효과는 충분하다. 메모리 사용량을 작게 유지하기 위해 넉넉히 200으로 둔다.
const int _defaultMaxCacheSize = 200;

/// [StockMetaRepository]를 감싸 symbol별 조회 결과를 인메모리에 캐싱하는 데코레이터입니다.
///
/// ## 캐시 무효화 정책
/// - **TTL(시간 기반 만료) 없음** — 거래소명 등 메타데이터는 거래소 이전처럼 극히 드문
///   경우가 아니면 바뀌지 않으므로, 시간 기반 재조회는 실익이 없다고 판단해 의도적으로
///   두지 않는다.
/// - **세션(앱 실행) 수명 동안 유지** — 이 캐시는 인메모리 [Map]이라 앱을 종료하면
///   자연히 비워진다. 별도의 수동 무효화 API를 두지 않는다.
/// - **LRU 크기 제한([maxCacheSize], 기본 200개)** — 무한정 커지는 것만 방지한다.
///   오래된 항목이 틀렸다고 판단해서가 아니라, 메모리 사용량을 억제하기 위한 목적이다.
/// - 실패한 조회는 캐시에 남기지 않아 다음 호출에서 재시도할 수 있게 한다.
///
/// 검색 화면은 여러 종목의 메타데이터를 `Future.wait`로 동시에 조회하므로, 같은 symbol이
/// 캐시 미스 상태에서 동시에 여러 번 요청되면 완료된 값이 아닌 진행 중인 [Future] 자체를
/// symbol별로 공유해, delegate가 중복 호출되지 않도록 한다.
class CachingStockMetaRepository implements StockMetaRepository {
  CachingStockMetaRepository(
    this._delegate, {
    int maxCacheSize = _defaultMaxCacheSize,
  }) : _maxCacheSize = maxCacheSize;

  final StockMetaRepository _delegate;
  final int _maxCacheSize;

  /// Dart의 [Map]은 삽입 순서를 유지하므로, 접근할 때마다 항목을 제거 후
  /// 재삽입해 "가장 최근에 접근한 항목이 맨 뒤"가 되게 하면 맨 앞 항목이
  /// 곧 가장 오래전에 접근한(LRU) 항목이 된다.
  final Map<String, Future<StockMeta>> _inFlight = {};

  @override
  Future<StockMeta> fetchStockMeta(String symbol) async {
    final cached = _inFlight.remove(symbol);
    if (cached != null) {
      _inFlight[symbol] = cached;
      return cached;
    }

    final future = _delegate.fetchStockMeta(symbol);
    _inFlight[symbol] = future;
    _evictLeastRecentlyUsedIfNeeded();
    try {
      return await future;
    } catch (_) {
      // 실패한 조회는 캐시에 남기지 않아 다음 호출에서 재시도할 수 있게 한다.
      _inFlight.remove(symbol);
      rethrow;
    }
  }

  void _evictLeastRecentlyUsedIfNeeded() {
    if (_inFlight.length <= _maxCacheSize) return;
    _inFlight.remove(_inFlight.keys.first);
  }
}
