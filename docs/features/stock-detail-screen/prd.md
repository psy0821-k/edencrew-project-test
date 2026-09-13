# stock-detail-screen PRD

## 개요

`03 · 종목상세` 화면. 검색/관심 화면에서 종목을 탭하면 진입하는 화면으로, 현재가·등락, 기간별 캔들 차트, 요약 카드(시가/고가/저가/거래량/시가총액), 일별 시세 표를 보여주고 관심 등록/해제를 지원한다.

## 사용자 스토리

- 사용자로서, 관심/검색 화면에서 종목을 탭하면 그 종목의 현재가와 등락을 한눈에 보고 싶다.
- 사용자로서, 기간 탭(1개월/3개월/6개월/1년)을 눌러 다른 기간의 차트와 일별 시세를 확인하고 싶다.
- 사용자로서, 상세 화면에서도 관심 등록/해제를 바로 할 수 있고, 그 상태가 다른 화면에도 반영되길 원한다.

## 기술 결정

### 화면 요소별 개별 Provider 분리 + Repository 내부 페이지 캐시 (B안)

**Context** — 종목 상세 화면은 quote(현재가)/stockMeta(종목명·시장)/dailyQuote(기간별 일별 시세)/watchlist(관심 여부) 네 도메인을 조합해야 한다. 헤더(종목명·현재가·관심 버튼)는 기간 탭과 무관하게 고정인데, 기간 탭을 전환할 때마다 일별 시세만 다시 조회된다. 이 둘을 어떻게 provider로 나눌지, 그리고 `DailyQuoteRepository`를 무한 스크롤 전용(`fetchNextPage`)에서 기간 조회(`fetchQuotes(symbol, Period)`)로 재설계하면서 캐시를 어디에 둘지 결정해야 한다.

**Decision** — 화면 요소별로 provider를 분리한다.
- `quoteProvider(symbol)`, `stockMetaProvider(symbol)` — 헤더/현재가 표시용, 화면 진입 시 1회 조회
- `selectedPeriodProvider` — 현재 선택된 기간 탭 상태(`StateProvider<Period>`, 기본값 `oneMonth`)
- `dailyQuoteProvider((symbol, period))` — `FutureProvider.family<List<DailyQuote>, (String, Period)>`, 차트·표 전용. Period가 바뀌면 이 provider만 재계산되고 헤더는 영향받지 않는다
- `isFavoriteProvider(symbol)`(기존 재사용) — 관심 버튼
- `DailyQuoteRepository`를 `fetchQuotes(symbol, period)`로 재설계하되, 캐시는 Repository 내부에 그대로 둔다. 자료구조는 `Map<String, _SymbolPageCache>`(symbol별), `_SymbolPageCache`는 `Map<int, List<DailyQuote>>`(페이지 번호 → quotes) + `int? lastPage`를 저장한다. `fetchQuotes`는 요청된 Period가 필요로 하는 페이지 번호 목록을 계산해, 캐시에 없는 페이지만 순차 요청(`docs/NAVER_API.md`가 "1년도 한 번에 받지 말고 페이지 재사용" 요구를 명시했으므로 병렬화하지 않는다) 후 병합해 반환한다
- 기간 탭 전환 race condition은 `dailyQuoteProvider`를 감싸는 `Notifier`(또는 `family` 재요청 시 세대 검증)에서, 검색 화면 `SearchDebouncerNotifier`와 동일한 요청 세대(generation) 카운터 패턴으로 방어한다

**Alternatives**
- A안(단일 조합 `FutureProvider`) 거부 — 관심 버튼만 토글해도(watchlist 상태 변경) 전체 provider가 재계산되어 캔들 차트까지 다시 그려지는 불필요한 rebuild가 발생한다. 검색 화면에서 `isFavoriteProvider`를 별도 분리해 이 문제를 이미 회피한 전례가 있는데 상세 화면만 역행할 이유가 없다.
- C안(Repository 무상태 + Notifier가 캐시 전담) 거부 — 이 프로젝트에 없던 새 패턴을 도입해야 하고, CEO 검증에서 지적된 "지금부터는 속도 우선" 원칙과 맞지 않는다. 페이지 캐시는 Repository 책임으로 두는 기존 Phase 1 설계(`NetworkStockMetaRepository`의 `CachingStockMetaRepository` 데코레이터 등)와도 더 일치한다.

**Consequences**
- 장점: 기간 탭 전환이 헤더/관심 버튼에 영향을 주지 않아 불필요한 rebuild가 없다. provider가 작게 쪼개져 있어 각각 독립적으로 테스트 가능(`dailyQuoteProvider`의 race condition만 집중적으로 테스트 가능). 기존 프로젝트 관례(가벼운 provider 분리)와 일치해 러닝커브가 낮다.
- 단점: provider 개수가 늘어나 `StockDetailPage`가 여러 `Consumer`/`ref.watch` 호출을 조합해야 한다(A안보다 위젯 코드가 약간 더 김). Repository의 캐시 자료구조를 새로 설계해야 하므로(Flutter 전문가 검증에서 확인된 대로 기존 `_SymbolCacheState`를 그대로 못 씀) 첫 이슈의 구현량이 예상보다 늘어난다.

## Definition of Done (이번 PRD 범위)

- [ ] `flutter analyze` 0 경고
- [ ] 기간 탭을 빠르게 연속 전환해도 최종적으로 마지막에 누른 탭의 데이터만 화면에 남는다(race condition 테스트로 검증)
- [ ] 관심 버튼 토글 시 차트/표 위젯이 재조회되지 않는다(rebuild 범위 확인)

## Out of Scope

- 일별 시세 표 무한 스크롤(선택 항목)
- 차트 축 라벨, 거래량 바, 영역 채우기, 크로스헤어/툴팁, 전환 애니메이션(전부 선택 항목)
- 검색 화면과 동일한 관심 등록/해제 토스트
- `Quote`(현재가) 실시간 폴링/자동 갱신 — 화면 진입 시 1회 조회로 그친다(과제 범위상 실시간 스트리밍 요구 없음, 필요하면 기존 새로고침 패턴처럼 수동 재조회를 후속 이슈로 분리)

## 용어 정의

`spec-fixed.md`의 Ubiquitous Language와 동일. 추가로:

| 용어 | 정의 |
|---|---|
| DailyQuotePageCache | symbol별로 "이미 받은 페이지의 실제 데이터"를 페이지 번호 기준으로 저장하는 새 캐시 자료구조(이번 PRD에서 신설) |
| 요청 세대(generation) | 기간 탭 전환 시 발급하는 순번. 응답 도착 시 가장 최근 발급된 세대인지 확인해 race condition을 막는다(검색 화면 `SearchDebouncerNotifier`와 동일 패턴) |
