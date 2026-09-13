# stock-detail-screen — 이슈 분해

PRD(`prd.md`) 기준. 의존성 순서: A → B → C → D.

---

## 이슈 A — 일별 시세 Repository를 기간(Period) 기준 조회로 재설계

### 설명

`DailyQuoteRepository.fetchNextPage(symbol)`(무한 스크롤 전용)을 `fetchQuotes(symbol, Period)`로 교체한다.
캐시는 기존 `_SymbolCacheState`(다음 페이지 번호만 저장)를 페이지 데이터 자체를 저장하는 구조로
새로 설계한다(Flutter 전문가 검증에서 기존 구조가 페이지 데이터를 캐시하지 않음을 확인).

### 작업 범위

- `Period` enum 신설(`oneMonth`/`threeMonths`/`sixMonths`/`oneYear`), 각 값에 필요 페이지 수(2/6/12/25) 매핑 getter
- `DailyQuoteRepository` 인터페이스: `fetchNextPage` → `fetchQuotes(String symbol, Period period)`로 교체
- `NetworkDailyQuoteRepository`: `_SymbolPageCache`(symbol별 `Map<int, List<DailyQuote>>` + `int? lastPage`)로 캐시 재설계. 필요한 페이지 중 캐시에 없는 것만 순차 요청(병렬 아님 — NAVER_API.md의 페이지 재사용 요구), 병합해 반환
- `MockDailyQuoteRepository`도 새 시그니처에 맞춰 수정
- `daily_quote_providers.dart`: 기존 `dailyQuoteRepositoryProvider`는 유지(반환 타입 그대로)

### Acceptance Criteria

- [ ] Given `1개월` 기간을 요청하면, When `fetchQuotes(symbol, Period.oneMonth)`를 호출하면, Then 2페이지(약 20거래일)만큼의 `DailyQuote` 목록이 반환된다
- [ ] Given 이미 `1개월`(2페이지)을 조회해 캐시된 상태에서, When 같은 symbol로 `3개월`(6페이지)을 요청하면, Then 캐시된 2페이지는 재요청하지 않고 3~6페이지만 추가로 요청한다
- [ ] Given `lastPage=15`인 종목에서, When `1년`(25페이지 필요)을 요청하면, Then 16페이지 이상은 요청하지 않고 있는 데이터(15페이지치)만 반환한다
- [ ] Given 동일한 `(symbol, Period)`로 두 번 연속 조회하면, When 두 번째 호출 시, Then 네트워크 재요청 없이 캐시된 페이지만으로 응답한다

### 의존성

없음(Phase 1 산출물 위에서 바로 작업).

---

## 이슈 B — 상세 화면 헤더 + 현재가/등락 + 관심 버튼

### 설명

더미 `StockDetailPage`를 실제 화면으로 교체하는 첫 단계. 뒤로가기/종목명/종목코드·시장/관심 버튼과
현재가·등락을 표시한다. 기간 탭/차트/표는 이 이슈 범위 밖(이슈 C, D에서 추가).

### 작업 범위

- `quoteProvider(symbol)`, `stockMetaProvider(symbol)` 신설(`FutureProvider.family`, 각각 기존 `quoteRepositoryProvider.fetchQuotes([symbol])`/`stockMetaRepositoryProvider.fetchStockMeta(symbol)` 감싸기)
- `StockDetailPage` 헤더: 뒤로가기 + 종목명 + `종목코드 · 시장` + 관심 버튼(`isFavoriteProvider`/`toggleFavorite` 재사용, `PendingSymbolsNotifier`로 연속 클릭 방지, 토스트 없음)
- 현재가 + 등락(방향 아이콘 ▲/▼, `formatPriceChange` 재사용)
- 최초 로딩: `SkeletonBox`로 헤더 아래 영역 표시
- 최초 조회 실패: 헤더는 유지, 그 아래 영역을 상세 화면 전용 에러 뷰(아이콘+메시지+다시 시도)로 대체

### Acceptance Criteria

- [ ] Given 검색 화면에서 종목 행을 탭하면, When 상세 화면에 진입하면, Then 뒤로가기/종목명/종목코드·시장/관심 버튼이 있는 헤더가 보인다
- [ ] Given 시세·메타 조회가 완료되면, When 화면을 보면, Then 현재가와 등락(부호+색상+방향 아이콘)이 표시된다
- [ ] Given 아직 관심등록 안 된 종목의 상세 화면에서, When 관심 버튼을 탭하면, Then 별 아이콘이 즉시 채워지고(토스트 없음) 관심 화면 목록에도 반영된다
- [ ] Given 데이터가 아직 도착하지 않은 상태에서, When 화면을 보면, Then 헤더 아래 영역에 스켈레톤이 표시된다
- [ ] Given 최초 조회가 실패하면, When 화면을 보면, Then 헤더는 유지된 채 그 아래가 에러 뷰(다시 시도 버튼 포함)로 대체된다

### 의존성

이슈 A 불필요(quote/stockMeta는 기존 산출물 재사용) — A와 병렬 가능하나, 문서 순서상 A 이후 진행 권장(팀 리뷰 편의).

---

## 이슈 C — 기간 탭 + 요약 카드 + 일별 시세 표

### 설명

기간 탭 4개를 동작시키고, 요약 카드와 일별 시세 표를 표시한다. 이슈 A의 `fetchQuotes(symbol, Period)`를
사용하는 첫 UI 이슈.

### 작업 범위

- `selectedPeriodProvider`(`StateProvider<Period>`, 기본값 `oneMonth`)
- `dailyQuoteProvider((symbol, period))`(`FutureProvider.family`) + race condition 방어(요청 세대 검증, `SearchDebouncerNotifier`와 동일 패턴)
- 기간 탭 UI: 선택된 탭 `accentDefault`/`accentBg` 스타일, 탭 전환 시 기존 차트/표 유지한 채 새 데이터로 교체(화면 비우지 않음)
- 요약 카드: 시가/고가/저가(그대로), 거래량("천" 축약), 시가총액("조" 축약, 1조 미만도 소수)
- 일별 시세 표: 날짜(`MM.DD`)/종가/등락(인접 거래일 종가 비교, 부호+색)/거래량
- 탭 전환 중 실패: 기존 표/카드 유지, 상단 얇은 에러 배너 + 다시 시도

### Acceptance Criteria

- [ ] Given 상세 화면에 진입하면, When 데이터가 도착하면, Then `1개월` 탭이 선택된 상태로 요약 카드와 일별 시세 표가 표시된다
- [ ] Given `1개월` 탭이 선택된 상태에서, When `3개월` 탭을 누르면, Then `accentDefault`/`accentBg` 스타일이 `3개월` 탭으로 옮겨가고 표/카드가 3개월치 데이터로 바뀐다
- [ ] Given 탭 전환 요청이 진행 중인 상태에서, When 새 데이터가 도착하기 전까지, Then 기존 표/카드가 화면에서 사라지지 않고 그대로 남아있다
- [ ] Given `1개월`을 누른 직후 바로 `1년`을 눌러 두 요청이 겹치면, When 두 응답이 모두 도착하면, Then 최종 화면에는 `1년`(마지막으로 누른 탭)의 데이터만 반영된다
- [ ] Given 일별 시세 표에서, When 특정 행의 등락을 확인하면, Then 그 행 종가와 하루 전 행 종가의 차이로 계산된 값이 부호·색상과 함께 표시된다
- [ ] Given 거래량이 29113000이면 `29,113천`으로, 시가총액이 1063000000000000이면 `1,063조`로 표시된다
- [ ] Given 기간 탭 전환 중 조회가 실패하면, When 화면을 보면, Then 기존 표/카드는 유지된 채 상단에 에러 배너와 다시 시도 버튼이 보인다

### 의존성

이슈 A(Repository), 이슈 B(헤더 레이아웃 위에 이어 붙임) 완료 후 진행.

---

## 이슈 D — 캔들 차트

### 설명

`CustomPainter`로 캔들 차트를 그린다. 선택된 기간 탭의 `dailyQuoteProvider` 데이터를 그대로 사용(이슈 C에서 이미 구축).

### 작업 범위

- 캔들 차트 위젯(`CustomPainter` 기반), 상승 `chartLineUp`/하락 `chartLineDown` 색상
- 기간 탭 전환 시 차트도 표/카드와 동일하게 끊김 없이 데이터 교체
- 렌더링 디테일(캔들 두께/간격/스크롤)은 최소 기준만 충족(감점 없는 항목)

### Acceptance Criteria

- [ ] Given `1개월` 데이터가 로드되면, When 화면을 보면, Then 그 기간의 거래일 수만큼 캔들이 그려진다
- [ ] Given 특정 거래일의 종가가 시가보다 높으면, When 캔들을 확인하면, Then `chartLineUp` 색상으로 그려진다
- [ ] Given 특정 거래일의 종가가 시가보다 낮으면, When 캔들을 확인하면, Then `chartLineDown` 색상으로 그려진다
- [ ] Given 기간 탭을 전환하면, When 새 데이터가 도착하면, Then 캔들 차트도 표/카드와 함께 새 기간 데이터로 교체된다

### 의존성

이슈 C(`dailyQuoteProvider`, 기간 탭 UI) 완료 후 진행.
