# watchlist-sync PRD

## 개요

관심/검색/상세 3화면이 공유하는 "관심종목 상태 계층"을 만든다. 어떤 종목이 관심등록되어 있는지(symbol Set, SharedPreferences로 영속화), 그 symbol들에 실시간 시세(Quote)·메타데이터(StockMeta)를 결합한 `WatchlistItem` 목록, 그리고 목록 정렬(현재가순/등락률순/가나다순) 로직까지가 이번 Phase의 범위다. ROADMAP Phase 2에 해당하며, 화면 UI(레이아웃·바텀시트·토스트)는 다루지 않는다.

## 사용자 스토리

- 검색 화면에서 별 아이콘을 눌러 종목을 관심등록하면, 관심 화면 목록에 즉시 나타난다.
- 상세 화면에서 관심을 해제하고 관심 화면으로 돌아오면, 목록에서 해당 종목이 사라져 있다.
- 앱을 재실행해도 이전에 등록한 관심종목이 그대로 남아 있다.
- 관심 화면에서 정렬 기준(현재가순/등락률순/가나다순)을 바꾸면 목록 순서가 즉시 바뀐다.
- 시세를 아직 받아오지 못한 종목은 정렬 결과의 맨 아래에 위치한다.

## 기술 결정

### ADR 1 — 상태 저장: Repository 패턴 + `StateNotifier<Set<String>>`

**Context** — 관심종목 symbol 집합을 저장·토글·영속화해야 하고, 이 상태는 관심/검색/상세 3화면이 동시에 구독한다. project-foundation ADR 2(FSD)·ADR 5(Repository+전역 스위치)가 이미 Quote/Search/StockMeta 3개 도메인에 "인터페이스 + Mock/Network 구현체 + provider" 패턴을 확립해 두었다. Watchlist는 네트워크가 아닌 로컬 저장소(SharedPreferences)를 다루지만, "저장 방식을 추상화해 도메인 로직이 구체 구현을 모르게 한다"는 동일한 목적이 적용된다.

**Decision** — `WatchlistRepository` 추상 인터페이스를 정의하고, `LocalWatchlistRepository`(SharedPreferences 기반) 구현체 하나만 둔다(Mock/Network 이분법 대신 Local 하나 — 이 도메인엔 "네트워크 차단 시 대체할 mock"이라는 개념 자체가 없음). `StateNotifier<Set<String>>`가 이 Repository를 감싸 메모리 상태를 들고, `toggleFavorite`가 Repository에 위임 후 결과를 반환한다. `main()`에서 `SharedPreferences.getInstance()`를 사전 로드해 `sharedPreferencesProvider`를 `overrideWithValue`로 주입하므로, Repository와 StateNotifier는 완전히 동기 인터페이스로 유지된다.

**Alternatives**
- *안 B(Notifier + SharedPreferences 직결)*: Repository 계층을 생략해 코드가 짧아지지만, "새 도메인을 추가할 때 Repository를 만든다"는 project-foundation ADR 2/5의 기존 규칙을 이 도메인만 깨게 되어 일관성이 떨어지고, 테스트 시 SharedPreferences와 상태 로직을 분리해서 검증하기 어려움.
- *안 C(AsyncNotifier로 전체 비동기 통일)*: spec-fixed.md에서 이미 "symbol 목록은 사전 로드로 동기화, 시세 결합만 비동기 유지"로 확정했는데, 상태 자체를 `AsyncValue`로 감싸면 이 결정과 방향이 어긋나고 불필요한 로딩 상태 처리가 화면에 전파됨.

**Consequences**
- 장점: 기존 4개 도메인과 동일한 "인터페이스 + 구현체 + provider" 구조를 유지해 코드 읽는 사람이 새 도메인 이름만 학습하면 됨. Repository를 가짜 구현체로 override해 StateNotifier 로직만 독립적으로 테스트 가능.
- 단점: Mock/Network 이분법이 없는 도메인에 동일한 "Repository 인터페이스" 틀을 씌우는 것이 약간의 형식적 오버헤드로 보일 수 있음 — 다만 "저장 방식이 나중에 바뀌어도(예: 클라우드 동기화) 호출부가 무영향"이라는 이점이 이 오버헤드를 상쇄한다고 판단.

### ADR 2 — 시세/메타데이터 결합: 화면별 파생 provider

**Context** — 관심 화면은 `WatchlistItem`(symbol+StockMeta+Quote 결합) 목록이 필요하고, 검색/상세 화면은 단일 symbol의 관심등록 여부(`bool`)만 필요하다. 두 요구가 다른 형태의 데이터를 원한다.

**Decision** — `watchlistItemsProvider`(전체 목록용, `FutureProvider` — Quote 네트워크 조회를 `ref.watch(quoteRepositoryProvider)`로 결합)와 `isFavoriteProvider(symbol)`(단일 조회용, `Provider.family` — StateNotifier의 Set에서 `contains` 확인) 두 개를 분리해 제공한다. 두 provider 모두 같은 `watchlistProvider`(StateNotifier)를 `ref.watch`해 자동으로 동기화된다.

**Alternatives**
- *단일 provider로 통합*: 검색 화면처럼 단일 symbol만 필요한 곳에서도 전체 `WatchlistItem` 목록(및 그에 딸린 Quote 네트워크 조회)을 구독하게 되어 불필요한 재계산이 발생.

**Consequences**
- 장점: 각 화면이 필요한 만큼만 구독해 리렌더링 범위가 최소화됨. `ref.watch`의 자동 의존성 추적으로 관심 상태가 바뀌면 두 provider 모두 자동 갱신 — 별도 이벤트 브로드캐스팅 불필요.
- 단점: provider가 2개로 늘어나 처음 보는 사람은 "왜 두 개로 나눴는지" 문서(ADR)를 봐야 함.

### ADR 3 — 정렬: `features/watchlist-sort/`의 순수 함수 comparator

**Context** — 정렬 기준 3가지(현재가순/등락률순/가나다순)와 "시세 미수신 행은 항상 최하단" 규칙(spec-fixed.md 4번)을 적용해야 한다.

**Decision** — `features/watchlist-sort/watchlist_comparator.dart`에 `List<WatchlistItem> sortWatchlistItems(List<WatchlistItem> items, SortCriteria criteria)` 순수 함수로 구현한다. 현재가순/등락률순은 Quote가 `null`인 항목을 `Comparator`에서 항상 뒤로 보내는 null-safe 비교를 쓰고, 가나다순은 StockMeta의 종목명으로 정렬(항상 값이 존재하므로 이 문제 없음). 정렬 기준 선택 상태는 `watchlist_sort_provider.dart`의 별도 `StateProvider<SortCriteria>`로 분리한다.

**Alternatives**
- *`watchlistItemsProvider` 안에서 정렬까지 처리*: provider 하나가 "조합 + 정렬" 두 책임을 가지게 되어 단일 책임 원칙에 어긋나고, 정렬 기준만 바꿔도 Quote 재조합 로직 전체가 재실행될 위험.

**Consequences**
- 장점: 정렬 로직이 순수 함수라 유닛 테스트가 입출력만으로 간단. 정렬 기준 변경이 네트워크 재조회를 유발하지 않음(화면에서 `sortWatchlistItems(items, criteria)`로 조합만 하면 됨).
- 단점: 화면 Phase에서 "조합 결과 + 정렬 함수"를 두 곳에서 가져와 합쳐야 하는 한 단계가 늘어남(사소한 비용).

## Out of Scope

- 화면 UI(레이아웃, 정렬 바텀시트, 빈 상태, 토스트 표시) — 다음 Phase(화면 구현)에서 별도 feature로 기획.
- 관심종목 삭제 스와이프 등 화면 인터랙션 — 다음 Phase.
- Mock 데이터 소스 이분법 — Watchlist는 로컬 전용 도메인이라 `LocalWatchlistRepository` 하나만 두고 `dataSourceModeProvider`(mock/network)와 무관하게 항상 동일하게 동작한다.
- 클라우드/서버 동기화(여러 기기 간 관심목록 공유) — 과제 범위 밖.
- 정렬 기준 자체의 영속화(재실행 후 정렬 기준 유지) — ASSIGNMENT.md상 선택 항목이며 이번 Phase는 관심목록 symbol만 영속화한다.
- 캔들 차트, 일별 시세 표 등 상세 화면의 나머지 UI — naver-data-layer(Phase 1)에서 데이터 계층은 이미 완료, 렌더링은 화면 Phase.

## 용어 정의

`spec-fixed.md`의 "용어 정의" 섹션과 동기화됨: WatchlistItem, 관심 토글(toggleFavorite), 정렬 기준(SortCriteria).
