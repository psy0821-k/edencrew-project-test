# Phase 2: 관심 상태 공유 계층 (watchlist-sync) — 확정 요구사항

## 배경

`spec-original.md` 참고. ASSIGNMENT.md "4. 상태 동기화 (전체 필수)" 요구사항을 충족하는 상태 계층을 만든다.

## 확정된 범위

### 1. 저장 범위 — 로컬 영속화 포함

- 이번 Phase에서 관심종목 등록/해제 상태를 **SharedPreferences로 영속화**까지 구현한다.
- ASSIGNMENT.md상 "관심 목록 재실행 후 유지"는 선택 항목이지만, 이번 Phase에서 함께 처리하기로 확정.

**선택 사유(SharedPreferences)**:
- 저장 데이터가 "관심등록된 종목코드 문자열 집합" 하나뿐 — 관계형 구조·복잡한 쿼리 불필요.
- Flutter 공식 플러그인이며 `getStringList`/`setStringList`로 별도 직렬화 코드 없이 처리 가능.
- Hive/Isar 등은 스키마·어댑터·코드 생성 등 초기 설정 비용이 있으나 이 규모(symbol 목록 하나)에는 이점이 없음 — project-foundation ADR 1이 `riverpod_generator`를 배제한 것과 같은 판단 기준(YAGNI).

### 2. 관심종목 ↔ 시세/메타데이터 결합 — 이번 Phase에 포함

- `entities/watchlist/`에 다음을 만든다:
  - `watchlist_item.dart` — symbol + StockMeta + Quote를 조합한 `WatchlistItem` 모델
  - `watchlist_repository.dart` — symbol Set 저장/토글 (SharedPreferences 기반 영속화)
  - `watchlist_providers.dart`:
    - `watchlistItemsProvider` — 관심 화면용. 등록된 symbol 목록에 Quote/StockMeta를 결합해 `WatchlistItem` 목록 생성 (비동기, `AsyncValue`)
    - `isFavoriteProvider(symbol)` — 단일 symbol의 관심등록 여부. 검색/상세 화면이 개별 구독.
- 다음 Phase(화면 구현)는 이 provider들을 그대로 가져다 쓰기만 하면 된다.

### 3. 정렬 로직 — 이번 Phase에 포함

- `features/watchlist-sort/`에 다음을 만든다:
  - `sort_criteria.dart` — enum(`priceDesc`, `changeRateDesc`, `nameAsc` 등 3가지 기준)
  - `watchlist_sort_provider.dart` — 현재 선택된 정렬 기준 state
  - `watchlist_comparator.dart` — `List<WatchlistItem>` 정렬 로직
- 다음 Phase(화면 구현)는 정렬 바텀시트 UI만 이 provider/comparator에 연결하면 된다.

### 4. 시세 미수신 행의 정렬 위치 — 확정

- **현재가순 / 등락률순** 정렬 시, 시세를 아직 받지 못한(로딩/실패) 행은 **정렬 기준과 무관하게 항상 리스트 최하단**에 모아둔다.
- comparator에서 null-safe 비교로 처리 (시세 있는 항목 우선 정렬 → 없는 항목은 뒤에 원래 순서 유지).
- **가나다순**은 종목명이 항상 존재하므로 이 문제가 발생하지 않는다 (전체를 이름 기준으로 정렬).

### 5. 토스트/UI 연동 — 결과값 반환 방식

- 관심 토글은 `Future<bool> toggleFavorite(String symbol)` 형태로, 토글 후 상태(`true`=등록됨, `false`=해제됨)를 반환한다.
- 토스트 UI 자체는 다음 Phase(화면 구현)의 책임. 이번 Phase는 상태 변경과 반환값 제공까지만 담당 — UI와 완전히 분리된 순수 상태 계층 유지.

### 6. SharedPreferences 초기화 시점 — 하이브리드

- **symbol 목록 읽기**: `main()`에서 `await SharedPreferences.getInstance()`로 사전 로드 후 `sharedPreferencesProvider`를 `overrideWithValue`로 주입. 관심등록 여부는 앱 시작 즉시 동기 데이터처럼 확정된 상태로 존재.
- **WatchlistItem 목록(`watchlistItemsProvider`)**: 어차피 Quote 네트워크 조회가 필요해 원래도 비동기이므로, 그대로 `AsyncValue` 기반 유지. symbol 목록만 동기화하고 시세 결합은 기존 비동기 패턴을 그대로 따른다.
- 즉 "SharedPreferences 로딩"과 "시세 로딩"은 별개의 두 비동기 작업이며, 전자만 사전 로드로 지연을 제거하고 후자는 기존 방식(AsyncValue)을 유지한다.

## 이번 Phase가 다루지 않는 것

- 화면 UI(레이아웃, 정렬 바텀시트, 빈 상태, 토스트 표시) — 다음 Phase(화면 구현)
- 캔들 차트, 일별 시세 표 UI — naver-data-layer는 완료됐으나 화면 렌더링은 별도 Phase

## 용어 정의

- **WatchlistItem**: symbol + StockMeta + Quote를 결합한, 관심 화면이 바로 렌더링할 수 있는 조합 모델.
- **관심 토글(toggleFavorite)**: 특정 symbol의 관심등록 상태를 반전시키고 결과를 반환하는 동작.
- **정렬 기준(SortCriteria)**: 현재가순 / 등락률순 / 가나다순 3가지.
- 그 외 Entity/Feature/Page/ApiClient/Repository는 `project-foundation/spec-fixed.md`와 동일.
