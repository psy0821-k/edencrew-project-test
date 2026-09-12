# watchlist-screen — 확정 요구사항 (spec-fixed)

> feature-planner 단계1 산출물. 인터뷰로 모호성을 제거하고 결정 사항을 고정한 문서.
> 이 문서가 확정되어야 단계2(PRD)로 넘어간다.

## Primary User

이든크루 과제 평가자 — Flutter 코드로 화면을 직접 실행해 필수 요건 충족 여부와 직접 판단한 부분의 타당성을 확인하는 사람.

## 최소 동작 시나리오

1. 관심종목이 1개 이상 있는 상태로 앱을 켜면 관심 화면(기본 탭)에 목록이 뜬다. 시세가 아직 안 온 행은 스켈레톤으로 보이다가 도착하면 실제 값으로 바뀐다.
2. 헤더 우측 정렬 칩을 눌러 `등락률순`을 선택하면 바텀시트가 즉시 닫히고 목록이 등락률 내림차순으로 재정렬되며 칩 문구도 `등락률순`으로 바뀐다.
3. 관심종목이 하나도 없는 상태로 진입하면 헤더·탭바는 유지된 채 별 아이콘 + 안내 문구의 빈 상태가 보인다.

## 데이터 저장 방식

새로 추가되는 저장소는 없다. Phase 2에서 완성된 `lib/entities/watchlist/`(`watchlistProvider`, `watchlistItemsProvider`, `isFavoriteProvider`)와 `lib/features/watchlist-sort/`(`watchlistSortCriteriaProvider`, `sortWatchlistItems`)를 그대로 구독해서 화면만 그린다. `lib/pages/watchlist_page.dart`(현재 Phase 0 더미)를 실제 UI로 교체하는 것이 이번 Phase의 범위다.

## 경계 조건

- **최대값 / 개수 제한**: 없음. 과제 범위상 관심종목 수는 수십 개 이하로 가정, `ListView.builder`로 충분 (별도 페이지네이션/가상화 불필요).
- **빈 값**: 관심종목 0개 → 빈 상태 화면(`01 · 관심_empty`).
- **중복**: 같은 종목을 두 번 등록하는 경로 자체가 없음(토글 방식) — 관심 화면 범위 밖(Phase 2에서 이미 Set 기반으로 처리됨).
- **동시성**: 별 아이콘(관심 해제) 연속 탭 — `toggleFavorite`이 `Future<bool>`(SharedPreferences I/O 대기)이라 완료 전 재탭 시 상태가 꼬일 수 있다. **연속 클릭 방지가 필요하다는 요구사항만 확정**하고, 구체적 구현 방식(로컬 Set 추적 등)은 실제 UI 구현 이슈에서 결정한다. (관심 화면 + 검색 화면 공통 적용 — Figma에 없는 처리, README 메모 대상)
- **하단 탭 재선택**: 이미 선택된 탭(관심/검색)을 다시 눌렀을 때 무동작이어야 한다는 요구사항만 확정하고, 구체적 구현 방식은 UI 구현 이슈에서 결정한다.

## 에러 처리

`watchlistItemsProvider`(`FutureProvider`)가 실패했을 때:

- **이전에 성공적으로 표시한 목록이 있는 경우**: 목록은 그대로 유지하고, 상단에 `feedbackWarning` 토큰 기반의 얇은 에러 배너(메시지 + 다시 시도 버튼)만 노출한다.
- **첫 로드부터 실패한 경우**(표시할 이전 데이터 자체가 없음): 목록 영역 전체를 에러 상태(아이콘 + 메시지 + 다시 시도 버튼)로 대체한다. 헤더·탭바는 그대로 유지.

새로고침 버튼을 눌렀을 때는 전체 화면을 로딩으로 바꾸지 않고, 각 행의 시세 표시 부분만 `feedbackSkeleton` 상태로 되돌린 뒤 재조회한다(기존 종목명/코드는 유지).

이상은 Figma에 정의되지 않은 상태이므로 README "직접 판단한 부분"에 근거와 함께 남긴다.

## 재사용할 기존 UI 패턴 / 컴포넌트

- `lib/theme/`의 시맨틱 토큰 전부 (`priceUpText`/`priceDownText`/`priceFlatText`/`priceFlatBg`, `feedbackSkeleton`, `navActive`/`navInactive`, `favoriteActive`/`favoriteInactive`, `accentDefault`/`accentBg`)
- `lib/entities/watchlist/watchlist_providers.dart`의 `watchlistItemsProvider`, `isFavoriteProvider`, `watchlistProvider`
- `lib/features/watchlist-sort/`의 `SortCriteria`, `sortWatchlistItems`, `watchlistSortCriteriaProvider`
- `lib/shared/utils/number_formatter.dart`의 `NumberFormatter.comma`
- `lib/app/root_shell.dart`의 하단 탭 바(이미 구현됨 — 관심 화면 자체는 이 셸 안에 그려짐)
- `lib/pages/stock_detail_page.dart` (행 탭 시 이동할 기존 상세 화면 경로)

## 성능 제약

- **허용 응답 시간**: 없음(Naver API 응답 속도에 의존, 앱 자체의 인위적 제한 없음).
- **데이터 크기 제한**: 없음. 과제 범위상 관심종목 수십 개 이하 가정, `ListView.builder` 기본 동작으로 충분.

## 향후 확장 가능성

- 이번 Phase에서 만드는 등락 포맷팅 공용 유틸(`lib/shared/utils/`)은 Phase 5(상세 화면)에서 등락 표시에 동일하게 재사용될 예정 — 여기서 인터페이스를 잘 잡아두면 상세 화면 작업이 가벼워진다.
- 연속 클릭 방지 패턴(구현 방식은 UI 작업 시 결정)은 검색 화면(Phase 4)의 별 아이콘에도 동일하게 적용해야 한다 — 이번 Phase에서 공용 위치에 만들어 재사용할지 여부도 그때 함께 판단.

## 용어 정의 (Ubiquitous Language)

| 용어 | 정의 |
|---|---|
| 관심 화면 | `01 · 관심` 프레임. 관심종목 목록을 보여주는 화면(`lib/pages/watchlist_page.dart`) |
| 관심 항목(WatchlistItem) | 관심등록된 종목 하나 + 결합된 StockMeta/Quote (기존 모델, 변경 없음) |
| 정렬 기준(SortCriteria) | `현재가순`(priceDesc) / `등락률순`(changeRateDesc) / `가나다순`(nameAsc) — 기존 enum, 변경 없음 |
| 정렬 바텀시트 | 정렬 칩을 눌렀을 때 열리는, 3가지 정렬 기준을 고르는 하단 슬라이드 패널 |
| 시세 미수신 행 | `WatchlistItem.quote == null`인 행. 스켈레톤으로 표시되며 정렬 시 항상 맨 뒤 |
| 관심 해제 | 별 아이콘을 눌러 해당 종목을 관심 목록에서 제거하는 동작 (기존 `toggleFavorite` 재사용) |
| 진행 중 symbol | 별 아이콘 토글 요청이 아직 완료되지 않은 종목의 symbol 집합. 이 안에 있으면 재탭 무시 |
