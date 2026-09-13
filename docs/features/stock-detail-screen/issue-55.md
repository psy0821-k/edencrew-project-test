# Issue #55 — 일별 시세 Repository를 기간(Period) 기준 조회로 재설계

## 시그니처

```dart
// lib/entities/daily_quote/period.dart (신규)
/// 종목 상세 화면의 기간 탭 4종.
enum Period {
  oneMonth,
  threeMonths,
  sixMonths,
  oneYear;

  /// 이 기간을 표시하는 데 필요한 페이지 수(한 페이지 = 최대 10거래일).
  /// docs/NAVER_API.md의 대략치를 그대로 사용한다.
  int get requiredPageCount => switch (this) {
    Period.oneMonth => 2,
    Period.threeMonths => 6,
    Period.sixMonths => 12,
    Period.oneYear => 25,
  };
}

// lib/entities/daily_quote/daily_quote_repository.dart (시그니처 교체)
abstract interface class DailyQuoteRepository {
  /// symbol의 [period]가 요구하는 만큼의 일별 시세를 최신순으로 반환한다.
  /// 이미 캐시된 페이지는 재사용하고, 부족한 페이지만 추가로 요청한다.
  /// lastPage보다 큰 페이지는 요청하지 않고, 있는 데이터만 반환한다.
  Future<List<DailyQuote>> fetchQuotes(String symbol, Period period);
}

// lib/entities/daily_quote/network_daily_quote_repository.dart (내부 캐시 재설계)
class _SymbolPageCache {
  final Map<int, List<DailyQuote>> pages = {};
  int? lastPage;
}

class NetworkDailyQuoteRepository implements DailyQuoteRepository {
  NetworkDailyQuoteRepository(this._apiClient);
  final ApiClient _apiClient;
  final Map<String, _SymbolPageCache> _cache = {};

  @override
  Future<List<DailyQuote>> fetchQuotes(String symbol, Period period) async {
    final cache = _cache.putIfAbsent(symbol, () => _SymbolPageCache());
    final maxPage = cache.lastPage ?? period.requiredPageCount;
    final targetPageCount = period.requiredPageCount > maxPage
        ? maxPage
        : period.requiredPageCount;

    for (var page = 1; page <= targetPageCount; page++) {
      if (cache.pages.containsKey(page)) continue;
      if (cache.lastPage != null && page > cache.lastPage!) break;
      final parsed = await _fetchPage(symbol, page);
      cache.lastPage = parsed.lastPage;
      cache.pages[page] = parsed.quotes;
      if (page > cache.lastPage!) break;
    }

    final result = <DailyQuote>[];
    for (var page = 1; page <= targetPageCount; page++) {
      final pageQuotes = cache.pages[page];
      if (pageQuotes == null) break;
      result.addAll(pageQuotes);
    }
    return result;
  }
}
```

- 순차 요청 유지(병렬 아님) — `docs/NAVER_API.md`의 "1년도 한 번에 받지 말고 페이지 재사용" 요구를 지킨다.
- `fetchNextPage`는 완전히 제거한다(무한 스크롤은 이번 Out of Scope).
- `MockDailyQuoteRepository`도 `fetchQuotes(symbol, period)`로 교체. 기존처럼 고정 데이터를 `period.requiredPageCount * 10`개만큼 생성해서 반환(네트워크 캐시 검증은 필요 없으므로 캐시 로직 없이 매번 새로 생성해도 무방).
- `daily_quote_page.dart`(`DailyQuotePage`), `daily_quote_page_parser.dart`(`parseDailyQuotePage`)는 변경 없음 — 여전히 "한 페이지 파싱 결과"를 반환하는 내부 헬퍼로 재사용.

## 테스트 시나리오

### Period

- [정상] `Period.oneMonth`의 `requiredPageCount`는 2다
- [정상] `Period.threeMonths`의 `requiredPageCount`는 6이다
- [정상] `Period.sixMonths`의 `requiredPageCount`는 12다
- [정상] `Period.oneYear`의 `requiredPageCount`는 25다

### NetworkDailyQuoteRepository.fetchQuotes

- [정상] `Period.oneMonth`를 요청하면 2페이지치(해당 목데이터 기준 페이지당 1행이므로 2건) `DailyQuote`가 반환된다
- [정상] 이미 `oneMonth`(2페이지)를 조회해 캐시된 상태에서 같은 symbol로 `threeMonths`(6페이지)를 요청하면, 캐시된 1~2페이지는 재요청하지 않고 3~6페이지만 추가로 요청한다
- [경계] `lastPage=1`인 종목에서 `oneMonth`(2페이지 필요)를 요청하면, 2페이지는 요청하지 않고 1페이지치 데이터만 반환한다
- [정상] 동일한 `(symbol, Period)`로 두 번 연속 조회하면, 두 번째 호출은 네트워크 재요청 없이 캐시된 페이지만으로 응답한다(요청 횟수로 검증)
- [예외] 요청이 계속 실패하면 `NetworkFailure`를 던진다
- [예외] 응답 body가 비어있으면 `EmptyResultFailure`를 던진다

### MockDailyQuoteRepository.fetchQuotes

- [정상] `Period.oneMonth`를 요청하면 고정된 `DailyQuote` 목록이 반환된다(길이 검증)
- [정상] `Period`가 다르면 반환되는 목록 길이도 다르다(`oneYear` > `oneMonth`)
