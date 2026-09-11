# 이슈 3: 관심목록 정렬 (SortCriteria + comparator)

## 목적

관심 화면의 정렬 기능(현재가순/등락률순/가나다순)을 위한 순수 정렬 로직과 선택 상태를 만든다. PRD ADR 3, spec-fixed.md 4번(시세 미수신 행 최하단 배치) 참고.

## 구현 범위

`lib/features/watchlist-sort/`:

- `sort_criteria.dart` — `enum SortCriteria { priceDesc, changeRateDesc, nameAsc }`
- `watchlist_comparator.dart` — `List<WatchlistItem> sortWatchlistItems(List<WatchlistItem> items, SortCriteria criteria)`
  - `priceDesc`(현재가순): `quote.currentPrice` 내림차순, `quote == null`인 항목은 항상 최하단
  - `changeRateDesc`(등락률순): `quote`의 등락률 내림차순, `quote == null`인 항목은 항상 최하단
  - `nameAsc`(가나다순): `stockMeta.name` 오름차순 (항상 값 존재, null 처리 불필요)
- `watchlist_sort_provider.dart` — `watchlistSortCriteriaProvider` = `StateProvider<SortCriteria>(initialValue: SortCriteria.priceDesc)` (기본값은 PRD/스펙에 명시 없어 관심 화면 첫 진입 시 자연스러운 기준으로 판단)

## 참고

- 순수 함수로 구현 — `WatchlistRepository`나 Riverpod에 의존하지 않는다 (이슈 2의 `WatchlistItem`만 입력받음).
- null-safe 비교는 `Comparator`에서 `if (a.quote == null && b.quote == null) return 0; if (a.quote == null) return 1; if (b.quote == null) return -1;`처럼 명시적으로 처리한다.

## Acceptance Criteria

- [ ] Given 시세가 모두 있는 `WatchlistItem` 목록일 때, When `sortWatchlistItems(items, SortCriteria.priceDesc)`를 호출하면, Then 현재가 내림차순으로 정렬된다.
- [ ] Given 시세가 모두 있는 `WatchlistItem` 목록일 때, When `sortWatchlistItems(items, SortCriteria.changeRateDesc)`를 호출하면, Then 등락률 내림차순으로 정렬된다.
- [ ] Given 종목명이 다른 `WatchlistItem` 목록일 때, When `sortWatchlistItems(items, SortCriteria.nameAsc)`를 호출하면, Then 가나다순으로 정렬된다.
- [ ] Given 일부 항목은 `quote`가 있고 일부는 `null`일 때, When `SortCriteria.priceDesc` 또는 `changeRateDesc`로 정렬하면, Then `quote == null`인 항목이 정렬 결과의 맨 뒤에 모두 위치한다.
- [ ] Given `watchlistSortCriteriaProvider`가 기본값으로 초기화되어 있을 때, When 기준을 `SortCriteria.nameAsc`로 변경하면, Then provider의 상태가 즉시 갱신된다.
