# search-screen PRD

> feature-planner 단계2 산출물. 이 기능에 대해 궁금하면 여기만 보면 되는 단일 기준 문서.
> 요구사항·디자인·기술 결정·범위를 하나로 통합한다.

## 개요

이든크루 Flutter 과제 `02 · 검색` 화면을 실제 UI로 구현한다. 이미 완성된 검색 데이터/로직 계층
(`searchDebouncerNotifierProvider`, `normalizeQuery`, `findHighlightRange`, `searchRepositoryProvider`)과
관심 데이터 계층(`isFavoriteProvider`, `watchlistProvider.toggleFavorite`)을 그대로 구독해, 입력창·결과
목록·초기/결과없음 상태·토스트·상세 이동을 갖춘 화면으로 조립하는 것이 이번 Phase의 범위다.
`lib/pages/search_page.dart`(Phase 0 더미)를 교체한다. 부수적으로 관심 화면의 `WatchlistEmptyView`를
공용 `EmptyStateView` 위에서 재구성하고, 별 아이콘/새로고침 버튼에 적용할 연속 클릭 방지 공용 로직을 만든다.

## 사용자 스토리

- 사용자로서, 검색 탭에 처음 들어가면 무엇을 입력해야 하는지 안내를 보고 싶다.
- 사용자로서, 종목명이나 6자리 종목코드로 검색해서 원하는 종목을 빠르게 찾고 싶다.
- 사용자로서, 검색 결과에서 검색어와 일치하는 부분이 강조되어 결과를 빠르게 훑어보고 싶다.
- 사용자로서, 검색 결과에서 바로 별 아이콘을 눌러 관심 등록/해제하고, 방금 무엇이 바뀌었는지 토스트로 확인하고 싶다.
- 사용자로서, 검색어에 맞는 결과가 없으면 무엇이 잘못됐는지(오타 등) 알 수 있는 안내를 보고 싶다.
- 사용자로서, 검색 결과를 탭해서 바로 종목 상세 화면으로 이동하고 싶다.

## 기술 결정

> 아키텍처 3안을 7가지 고정 기준(데이터 구조 / API 레이어 변경지점 / 상태관리 변경지점 /
> 핵심 동작 / 컴포넌트 구조 / 기존 패턴과의 일관성 / 테스트 용이성)으로 비교한 뒤,
> 선택한 안을 아래 ADR 4요소로 기록한다.

### 결정 1 — 검색 화면 위젯 구조 & 빈 상태 공용화

**Context** — `lib/pages/search_page.dart`(Phase 0 더미)를 실제 UI로 교체해야 한다. 화면은 입력창(+X버튼),
결과 목록(행+하이라이트+별아이콘), 초기 상태, 결과없음/에러 상태, 토스트로 구성된다. `lib/pages/README.md`는
"Page는 조립만" 규칙을 두고 있고, watchlist-screen에서 이미 "아이콘+타이틀+캡션" 빈 상태 구조가 `WatchlistEmptyView`로
존재한다 — 이 구조를 검색 화면의 초기/결과없음 상태와 어떻게 공유할지 결정해야 한다.

| # | 기준 | A: search_page에 다 넣기 | B: feature 단위로만 분리 (빈 상태는 각자 구현) | C: 공용 EmptyStateView(widgets) + 도메인 로직은 features |
|---|---|---|---|---|
| 1 | 데이터 구조 | 동일 (`SearchResult` 리스트 그대로 렌더) | 동일 | 동일 |
| 2 | API 레이어 변경지점 | 없음 | 없음 | 없음 |
| 3 | 상태관리 변경지점 | 없음(기존 provider 구독만) | 없음 | 없음(연속 클릭 방지 Provider는 결정 2에서 별도 다룸) |
| 4 | 핵심 동작 | AsyncValue.when 분기 + 하이라이트 렌더링 전부 page 안에 inline | 동일 로직이지만 위젯 단위로 분리돼 각 파일이 단일 책임 | B와 동일하되 빈 상태(아이콘+타이틀+캡션)만 공용 위젯으로 추출 |
| 5 | 컴포넌트 구조 | 단일 파일 300+줄 | `features/search-list/`에 여러 파일, `WatchlistEmptyView`는 그대로 별도 유지(중복) | `widgets/empty_state_view.dart` 하나 + `features/search-list/`에 검색 전용 조각들, `WatchlistEmptyView`는 `EmptyStateView` 호출로 축소 |
| 6 | 기존 패턴과의 일관성 | `lib/pages/README.md` 규칙(조립만) 위반 | `search-query`, `watchlist-sort`와 동일한 feature 분리 패턴은 따르지만 빈 상태 중복 발생 | B와 동일 + `lib/widgets/README.md`가 정의한 "여러 화면이 공유하는 도메인 비종속 UI" 조건을 빈 상태 레이아웃이 충족 |
| 7 | 테스트 용이성 | 위젯 테스트 시 화면 전체를 pump해야 함 | 위젯 단위 개별 테스트 가능 | 동일 + `EmptyStateView` 자체도 독립 테스트 가능, `WatchlistEmptyView`/검색 빈 상태 테스트가 얇아짐 |

**Decision** — **C안**: 아이콘(SVG) + 타이틀 + 캡션 구조를 `lib/widgets/empty_state_view.dart`의 `EmptyStateView`로
추출한다(아이콘 asset 경로, 타이틀, 캡션을 파라미터로 받음). `WatchlistEmptyView`는 이 위젯을 호출하는 얇은 래퍼로
남기거나 직접 `EmptyStateView`를 사용하도록 교체한다. 검색 화면은 초기 상태(`돋보기 아이콘` + `종목을 검색해 보세요`)와
결과없음/에러 상태(`아이콘` + 동적 메시지) 모두 `EmptyStateView`로 구성한다. 검색 결과 행(하이라이트 포함), 입력창은
`SearchResult`/`normalizeQuery`/`findHighlightRange`에 직접 의존하므로 B안과 동일하게 `lib/features/search-list/`에 둔다.
`search_page.dart`는 이 조각들을 `Scaffold`로 조립만 한다.

**Alternatives**
- A안(page에 다 넣기) — `lib/pages/README.md` 규칙 위반, 파일이 커져 리뷰 어려움. 기각.
- B안(빈 상태도 각자 구현) — watchlist-screen PRD에서 이미 "검색 화면에서 실제로 동일한 모양이 필요하다고 확인되면
  그때 widgets로 옮긴다"고 명시해 두었는데, 지금이 바로 그 시점이다(사용자가 이번 인터뷰에서 재사용성을 직접 요청).
  지금 안 옮기면 거의 동일한 레이아웃 코드가 두 곳에 중복되고, 다음 상세 화면 작업 때 또 판단을 미루게 된다. 기각.

**Consequences**
- 장점: 이후 상세 화면 등에서 빈/에러 상태가 필요할 때 `EmptyStateView` import만 하면 됨. `WatchlistEmptyView` 코드도
  줄어듦.
- 단점: `WatchlistEmptyView` 기존 코드를 함께 수정해야 하므로 이번 PR의 diff가 검색 화면 범위를 살짝 넘어선다
  (리뷰 시 "왜 관심 화면 파일도 바뀌었는지" 설명이 필요 — PR 설명에 명시).

### 결정 2 — 연속 클릭 방지 공용 로직 설계

**Context** — 별 아이콘 토글(symbol 단위, 검색+관심 화면 공통)과 새로고침 버튼(관심 화면, bool 단위) 모두
"진행 중이면 재입력 무시"가 필요하다. 두 액션의 상태 모양(symbol 집합 vs 단일 bool)이 다르다는 점을 반영해야 한다.

| # | 기준 | A: 화면마다 로컬 State로 각자 구현 | B: 범용 "진행 중 작업 추적" Provider 하나 | C: 액션별 전용 Notifier 2개(별 아이콘용, 새로고침용) |
|---|---|---|---|---|
| 1 | 데이터 구조 | 화면별 `bool`/`Set<String>` state 각각 | `Set<Object>`(대상 id) 범용 컨테이너 | `Set<String>`(symbol), `bool` 각각의 전용 Notifier |
| 2 | API 레이어 변경지점 | 없음 | 없음 | 없음 |
| 3 | 상태관리 변경지점 | 각 위젯에 `StatefulWidget` 추가 | `lib/shared/`에 Provider 1개 추가 | `lib/shared/`에 Provider 2개 추가 |
| 4 | 핵심 동작 | 위젯 로컬 상태라 화면 간 공유 불가(같은 종목을 관심 화면과 검색 화면에서 동시에 조작하는 극단적 케이스는 애초에 화면 전환 중이라 실질 충돌 없음) | 하나의 Notifier가 "무엇이 진행 중인지"를 범용 키로 관리, 화면은 `contains(key)`만 확인 | 별 아이콘/새로고침 각각 명확한 타입으로 관리, 범용 키 타입 캐스팅 불필요 |
| 5 | 컴포넌트 구조 | 없음(위젯에 흡수) | `lib/shared/state/pending_action_notifier.dart` 1개 | `lib/shared/state/`에 2개 파일 |
| 6 | 기존 패턴과의 일관성 | `watchlistProvider`처럼 Riverpod으로 상태를 올리는 기존 패턴과 어긋남(이 프로젝트는 로컬 State를 지양하고 Provider로 상태를 끌어올리는 편) | Riverpod 패턴 일치, 다만 범용 컨테이너는 이 프로젝트에 아직 없던 새 추상화 | Riverpod 패턴 일치, 기존 `isFavoriteProvider.family` 같은 `.family` 사용 관례와 자연스럽게 이어짐 |
| 7 | 테스트 용이성 | 위젯 pump 필요, 로직만 단위 테스트하기 어려움 | Notifier 단위 테스트 가능하나 "범용 키"라 테스트 케이스가 별 아이콘/새로고침 의미를 직접 드러내지 못함 | Notifier 단위 테스트 가능 + 테스트 이름 자체가 "별 아이콘 연속 클릭", "새로고침 연속 클릭"으로 의미가 분명 |

**Decision** — **C안**: `lib/shared/state/pending_symbols_notifier.dart`(별 아이콘용, `StateNotifier<Set<String>>`,
`isPending(symbol)`/`run(symbol, action)`)와 `lib/shared/state/pending_flag_notifier.dart`(새로고침 버튼용,
`StateNotifier<bool>`, `isPending`/`run(action)`) 두 개로 나눈다. 둘 다 "요청 시작 시 진행 중 표시 → 완료(성공/실패
무관) 시 해제, 진행 중이면 재호출 무시"라는 동일한 뼈대를 공유하지만, 새로고침 쪽은 원래 상태가 스칼라(`bool`)라서
symbol 기반 Set과 억지로 같은 타입을 씌우면 오히려 호출부에서 `isPending('refresh')`처럼 의미 없는 문자열 키를
만들어야 한다 — 이게 B안을 기각한 이유다.

**Alternatives**
- A안(화면마다 로컬 State) — 이 프로젝트는 `watchlistProvider`/`watchlistSortCriteriaProvider` 등 상태를 Riverpod으로
  올리는 것이 기존 관례이고, 로컬 State로 되돌리면 다음에 상세 화면에서 같은 패턴이 필요할 때 재사용이 안 된다. 기각.
- B안(범용 Set<Object> 하나) — 재사용성은 가장 높아 보이지만, 지금 시점에 필요한 액션은 딱 2종류(symbol 단위,
  단일 flag)뿐이라 범용 키 타입을 미리 설계하는 것은 YAGNI 위반이다. 새 액션이 3번째로 생기는 시점에 다시 판단한다. 기각.

**Consequences**
- 장점: 각 Notifier가 호출부 의도를 이름으로 드러내고, 테스트 케이스 이름도 명확해진다. 두 Notifier 모두
  `run()` 메서드의 뼈대(진행 중 체크 → 상태 갱신 → 실행 → 해제)가 거의 같아 코드 중복이 약간 있다.
- 단점: 파일이 2개로 늘어나고, "왜 하나로 합치지 않았는지" 설명이 README나 커밋 메시지에 필요하다(이 PRD가 그 근거).
  세 번째 유사 액션이 생기면 그때 공통 뼈대를 추출하는 리팩토링이 필요할 수 있다(현재는 과도한 추상화로 판단해 보류).

## Out of Scope

- **6자리 종목코드 검색의 실제 API 동작 검증 및 대응 로직** — spec-fixed.md에 따라 이슈 구현 단계에서 실기기로
  확인하고 필요 시 그 이슈 안에서 대응한다.
- **디바운스/응답 대기 중 로딩 인디케이터** — 선택 항목, 이번 Phase에서 다루지 않음.
- **최근 검색어, 토스트 애니메이션** — 선택 항목.
- **연속 클릭 방지 로직을 상세 화면 등 세 번째 사용처로 확장** — 지금은 별 아이콘/새로고침 두 곳만 대응한다.
- **에러 재시도 버튼** — 별도 UI 없이 디바운스 재입력으로 자연 재시도되도록 한다(spec-fixed.md 확정 사항).
- **관심 화면 새로고침 버튼 자체의 다른 리팩토링** — `pending_flag_notifier` 적용만 하고, `WatchlistHeader`/`WatchlistPage`의
  다른 로직은 건드리지 않는다.
- **`WatchlistEmptyView`를 완전히 삭제하고 `EmptyStateView`를 직접 호출하도록 모든 호출부 변경** — 이슈 구현 시
  `WatchlistEmptyView`를 얇은 래퍼로 남길지, 호출부를 다 바꿀지는 이슈 단계에서 실제 diff 크기를 보고 결정한다.

## Definition of Done

- [ ] `flutter analyze` 0 경고 유지
- [ ] 검색 화면 필수 항목 전부 동작: 입력창+X버튼 / 결과 행(하이라이트+코드·시장+별아이콘) / 관심 등록·해제 즉시 반영 +
      토스트(2초 자동 소멸) / 행 탭 시 상세 이동 / 초기 상태 / 결과없음 상태(입력 검색어 포함 문구)
- [ ] 종목명 검색과 6자리 종목코드 검색 모두 동작 확인(실기기, network 모드)
- [ ] 별 아이콘·새로고침 버튼 연속 클릭 방지 동작 확인
- [ ] 화면 코드에서 `AppPalette` 직접 참조 없음(전부 `context.colors.*` 시맨틱 토큰)
- [ ] 새 위젯/함수에 Dart 타입 명시, `dynamic`/암묵적 `any` 없음
- [ ] 검색 화면 위젯 테스트 최소 1개 이상 (초기 상태 또는 결과없음 상태 렌더링 등 핵심 시나리오)

## 용어 정의

> spec-fixed.md의 Ubiquitous Language와 동기화한다.

| 용어 | 정의 |
|---|---|
| 검색 화면 | `02 · 검색` 프레임. 종목 검색 및 관심 등록을 하는 화면(`lib/pages/search_page.dart`) |
| 검색 결과 행 | `SearchResult` 하나를 표시하는 행. 종목명(하이라이트) + `종목코드 · 시장` + 별 아이콘 |
| 초기 상태 | 검색어가 비어 있을 때(`02 · 검색_empty`)의 화면 상태 |
| 결과 없음 상태 | 유효한 검색(2글자 이상)을 했지만 결과가 0건이거나 요청이 실패했을 때(`02 · 검색결과_empty`)의 화면 상태 |
| 하이라이트 | 종목명 중 정규화된 검색어와 일치하는 구간을 `searchHighlight` 토큰으로 강조하는 것 |
| 관심 등록 토스트 / 관심 해제 토스트 | 별 아이콘 토글 시 화면 하단에 2초간 노출되는 안내 메시지 (`04`/`05` 프레임) |
| 진행 중 상태(연속 클릭 방지) | 별 아이콘 토글 또는 새로고침 요청이 아직 완료되지 않은 상태. 이 동안 같은 액션의 재입력은 무시된다 |
| EmptyStateView | 아이콘 + 타이틀 + 캡션 구조를 공유하는 공용 빈 상태 위젯(`lib/widgets/empty_state_view.dart`). `WatchlistEmptyView`와 검색 화면 초기/결과없음 상태가 이 위에서 구성된다 |
| PendingSymbolsNotifier | 별 아이콘 등 symbol 단위 진행 중 상태를 관리하는 공용 Notifier |
| PendingFlagNotifier | 새로고침 버튼 등 단일 플래그 진행 중 상태를 관리하는 공용 Notifier |
