# stock-detail-screen — 확정 요구사항 (spec-fixed)

> feature-planner 단계1 산출물. 인터뷰로 모호성을 제거하고 결정 사항을 고정한 문서.
> 이 문서가 확정되어야 단계2(PRD)로 넘어간다.

## Primary User

이든크루 과제 평가자 — Flutter 코드로 화면을 직접 실행해 필수 요건 충족 여부와 직접 판단한 부분의 타당성을 확인하는 사람.

## 최소 동작 시나리오

1. 검색/관심 화면에서 종목 행을 탭해 상세 화면에 진입하면, 헤더(뒤로가기/종목명/종목코드·시장/관심 버튼)가 즉시 보이고 나머지 영역(현재가, 기간 탭, 차트, 요약 카드, 일별 시세 표)은 스켈레톤으로 표시되다가 데이터가 도착하면 실제 값으로 채워진다.
2. 기본 선택된 기간 탭(`1개월`)의 캔들 차트와 일별 시세 표가 보인다. 다른 기간 탭(`3개월`/`6개월`/`1년`)을 누르면 그 기간에 맞는 데이터로 차트·표가 바뀐다. 전환 중에도 기존 차트/표는 화면에 남아있다가 새 데이터가 오면 그 자리에서 교체된다(화면을 비우지 않음).
3. 헤더의 별 아이콘을 누르면 관심 등록/해제가 즉시 반영된다(토스트 없음). 뒤로 가서 관심 화면을 보면 반영된 상태가 그대로 보인다.

## 데이터 저장 방식

새로 추가되는 저장소는 없다. 기존 도메인을 조합해서 쓴다.

- `lib/entities/quote/quote_providers.dart`의 `quoteRepositoryProvider` — 현재가/등락 표시용. 단일 symbol 조회(`fetchQuotes([symbol])`)로 재사용
- `lib/entities/stock_meta/stock_meta_providers.dart`의 `stockMetaRepositoryProvider`(`CachingStockMetaRepository`로 이미 캐싱됨) — 헤더의 종목명/시장 표시용
- `lib/entities/watchlist/watchlist_providers.dart`의 `isFavoriteProvider(symbol)`, `watchlistProvider.toggleFavorite` — 관심 버튼
- `lib/entities/daily_quote/`(**이번 이슈에서 시그니처 변경**) — 차트·일별 시세 표용

새로 추가하는 것: 위 셋을 조합하는 `stockDetailProvider(symbol)`류 provider, `Period` enum, 재설계된 `DailyQuoteRepository`, 캔들 차트 `CustomPainter`, 요약 카드/일별 시세 표 위젯들.

## 경계 조건

- **일별 시세 표의 "등락" 계산**: 인접한 두 거래일 종가 비교(그 행 종가 − 하루 전 행 종가). `DailyQuotePage`가 날짜 역순(최신순)으로 오므로, 표의 각 행은 배열상 바로 다음 인덱스(하루 전) 종가와 비교한다. 가장 오래된 행(그 기간의 마지막 행)은 비교할 이전 데이터가 없으면 등락을 표시하지 않거나(`-`), 다음 페이지 첫 항목과 비교한다 — **이슈 구현 단계에서 실제 데이터 경계 처리 방식을 다시 확인**.
- **기간 탭 → 필요 거래일수 매핑**(`docs/NAVER_API.md` 기준, 대략치):
  | Period | 거래일수 | 페이지 |
  |---|---|---|
  | oneMonth | 약 20 | 2 |
  | threeMonths | 약 60 | 6 |
  | sixMonths | 약 120 | 12 |
  | oneYear | 약 245 | 25 |
  - `lastPage`보다 큰 페이지는 요청하지 않는다(기존 Phase 1 규칙 유지).
  - **[Flutter 전문가 검증 정정]** 기존 `_SymbolCacheState`(`network_daily_quote_repository.dart`)는 `nextPageToFetch`/`lastPage`만 들고 있고, 받아온 페이지의 `List<DailyQuote>` 자체는 캐시하지 않는다(매 호출 반환 후 버림) — "기존 캐시 구조를 그대로 살린다"는 전제는 틀렸다. `fetchQuotes(symbol, Period)`가 실제로 페이지 재사용을 하려면 `Map<int, List<DailyQuote>>`(페이지 번호 → 해당 페이지 quotes) 형태로 캐시를 **새로 설계**해야 한다. PRD 단계에서 이 캐시 자료구조를 명시적으로 정의한다.
  - **[Flutter 전문가 검증 추가]** 기간 탭을 빠르게 연속 전환하면(예: 1개월→1년) 여러 `fetchQuotes` 호출이 겹쳐 단일 커서(`nextPageToFetch`)를 동시에 읽거나, 응답이 역순 도착해 오래된 탭의 데이터가 최신 화면을 덮어쓸 수 있다(검색 화면 `SearchDebouncerNotifier`에서 이미 겪은 것과 같은 유형의 race condition). PRD에서 요청 세대(generation) 검증 등 대응 방식을 명시한다.
- **거래량 축약**: 항상 "천" 단위로 나눠 콤마 포맷 + `천` 접미사 (예: `29,113천`).
- **시가총액 축약**: 항상 "조" 단위로 나눠 콤마 포맷 + `조` 접미사, 1조 미만도 소수로 표시 (예: `0.5조`). 소수 자릿수는 구현 단계에서 Figma 예시(`1,063조`, 정수처럼 보임)를 참고해 결정 — 정수 반올림 vs 소수 첫째 자리까지 표시 여부 확인 필요.
- **캔들 차트**: `CustomPainter`로 직접 구현. 상승 `chartLineUp`, 하락 `chartLineDown`, 보합은 별도 색상 필요 시 기존 `priceFlatText`류 참고. 내부 렌더링 디테일(캔들 두께, 간격, 스크롤 등)은 감점 없는 항목이므로 "기간에 맞는 캔들이 그려짐"을 최소 기준으로 삼는다.
- **관심 버튼**: 토스트 없이 별 아이콘만 즉시 토글. 검색 화면의 `PendingSymbolsNotifier`(연속 클릭 방지)도 동일하게 재사용해 중복 탭을 방지한다.

## 로딩 상태

- **최초 진입**(아직 아무 데이터도 없음): 헤더는 즉시 표시. 현재가/등락, 기간 탭 아래 차트·요약 카드·일별 시세 표 영역은 `SkeletonBox`(검색/관심 화면과 공유하는 기존 위젯)로 표시.
- **기간 탭 전환**: 기존 차트·요약 카드·일별 시세 표를 그대로 유지한 채 새 데이터를 요청하고, 도착하면 그 자리에서 교체한다(화면을 비우지 않음 — stale-while-revalidate 패턴, 업계 표준 리서치 근거로 채택). 탭 전환 중임을 알리는 최소한의 로딩 신호(예: 선택된 탭 옆 작은 스피너)는 넣을 수 있으나 화면 전체를 가리지 않는다.

## 에러 처리

관심 화면(PR #54)에서 확립한 배너/전체뷰 패턴을 그대로 적용한다.

- **최초 진입 시 실패**(표시할 데이터 자체가 없음): 헤더(뒤로가기/종목명)는 유지하고, 그 아래 영역 전체를 에러 뷰(아이콘 + 메시지 + 다시 시도 버튼)로 대체한다. `WatchlistErrorView`와 유사한 패턴이나 상세 화면 전용 위젯으로 분리(관심 목록 특화 문구와 다르므로).
- **기간 탭 전환 중 실패**: 기존 차트·표는 유지한 채 상단에 얇은 에러 배너(`WatchlistErrorBanner`류) + 다시 시도 버튼만 노출.
- 시세(`Quote`)와 종목 메타(`StockMeta`)는 최초 진입 실패에 포함해서 같이 처리한다(기간별로 갈리지 않는 값이므로).

## 상태 동기화

- 관심 버튼은 `isFavoriteProvider(symbol)`을 `ref.watch`하므로 다른 화면에서 관심 상태가 바뀌어도(예: 검색 화면에서 등록) 상세 화면이 열려있는 동안 자동으로 별 아이콘이 갱신된다. 별도 처리 불필요 — 기존 provider 재사용만으로 충족됨을 명시적으로 확인한다.

## 재사용할 기존 UI 패턴 / 컴포넌트

- `lib/widgets/skeleton_box.dart`의 `SkeletonBox` — 최초 로딩 상태
- `lib/shared/state/pending_symbols_notifier.dart`의 `PendingSymbolsNotifier` — 관심 버튼 연속 클릭 방지
- `lib/shared/utils/number_formatter.dart`의 `NumberFormatter.comma` — 콤마 포맷 기반 (축약 포맷터가 내부에서 재사용)
- `lib/features/watchlist-list/watchlist_error_banner.dart`, `watchlist_error_view.dart` — 배너/전체뷰 패턴 참고(직접 재사용은 문구가 다르므로 상세 화면 전용 위젯 신설)
- `lib/theme/`의 `chartLineUp`/`chartLineDown`/`chartBaseline`/`chartAxisLabel`/`chartVolumeBar`/`accentDefault`/`accentBg`/`priceUpText`/`priceDownText`/`priceFlatText`
- `formatPriceChange`(`Quote` 전용)는 현재가 등락 표시에 그대로 재사용. 일별 시세 표의 등락은 `DailyQuote` 두 개를 받는 새 함수 필요(경계 조건 참고)

## 성능 제약

- **허용 응답 시간**: 없음(Naver API 응답 속도에 의존).
- **데이터 크기 제한**: 없음. `1년`(25페이지)까지 순차 요청하되, 이미 받은 페이지는 재사용(캐시).

## 향후 확장 가능성

- 일별 시세 표 무한 스크롤(선택 항목)을 나중에 추가한다면, 이번에 재설계하는 `fetchQuotes(symbol, Period)` 위에 페이지 단위 조회를 얹는 방식으로 확장 가능하도록 Repository 내부 캐시 구조를 설계한다.
- 상세 화면 전용 에러 뷰/배너는 이후 다른 화면에도 일반화될 수 있는 여지를 남긴다(지금은 문구만 다르게 신설).

## Out of Scope (인터뷰에서 배제 확정)

- 일별 시세 표 무한 스크롤(선택 항목, 이번 Phase에서 하지 않음)
- 차트 축 라벨, 거래량 바, 영역 채우기, 크로스헤어/툴팁, 전환 애니메이션(전부 선택 항목)
- 검색 화면과 동일한 토스트(관심 등록/해제 시)

## 용어 정의 (Ubiquitous Language)

| 용어 | 정의 |
|---|---|
| 상세 화면 | `03 · 종목상세` 프레임. 종목 하나의 현재가·차트·일별 시세를 보여주는 화면(`lib/pages/stock_detail_page.dart`) |
| 기간 탭 | `1개월`/`3개월`/`6개월`/`1년` 중 하나를 선택하는 UI. 선택된 탭이 차트·일별 시세 표의 대상 기간을 결정 |
| Period | 기간 탭 4종을 나타내는 enum. 각 값은 필요 거래일수/페이지 수와 매핑된다 |
| 일별 시세 표 | 날짜/종가/등락/거래량 컬럼을 가진 표. `DailyQuote` 목록을 최신순으로 표시 |
| 등락(일별 시세 표) | 그 행의 종가와 하루 전 행의 종가를 비교한 값(경계 조건 참고). 실시간 시세의 등락(`Quote.changeAmount`)과는 별개 계산 |
| 끊김 없는 전환 | 기간 탭을 바꿔도 기존 차트/표를 화면에서 지우지 않고, 새 데이터가 도착하면 그 자리에서 교체하는 방식(stale-while-revalidate) |
