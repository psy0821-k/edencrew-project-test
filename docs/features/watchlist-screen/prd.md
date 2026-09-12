# watchlist-screen PRD

> feature-planner 단계2 산출물. 이 기능에 대해 궁금하면 여기만 보면 되는 단일 기준 문서.
> 요구사항·디자인·기술 결정·범위를 하나로 통합한다.

## 개요

이든크루 Flutter 과제 `01 · 관심` 화면을 실제 UI로 구현한다. Phase 0~2에서 이미 완성된 데이터 계층
(`watchlistItemsProvider`, `sortWatchlistItems`, `isFavoriteProvider` 등)을 그대로 구독해, 목록 표시·
새로고침·정렬 바텀시트·빈 상태·에러 상태를 갖춘 화면으로 조립하는 것이 이번 Phase의 범위다.
`lib/pages/watchlist_page.dart`(Phase 0 더미)를 교체한다.

## 사용자 스토리

- 관심종목을 등록해 둔 사용자로서, 앱을 열면 관심 화면에서 각 종목의 현재가와 등락을 한눈에 보고 싶다.
- 사용자로서, 시세가 오래됐을 수 있으니 새로고침 버튼으로 최신 시세를 다시 받고 싶다.
- 사용자로서, 관심종목이 많아지면 현재가순/등락률순/가나다순으로 원하는 기준에 맞춰 목록을 보고 싶다.
- 사용자로서, 관심종목이 아직 없으면 무엇을 해야 하는지 안내를 보고 싶다.
- 사용자로서, 관심 화면에서 바로 별 아이콘으로 관심을 해제하고 싶다(검색 화면까지 가지 않고).

## 기술 결정

> 아키텍처 3안을 7가지 고정 기준(데이터 구조 / API 레이어 변경지점 / 상태관리 변경지점 /
> 핵심 동작 / 컴포넌트 구조 / 기존 패턴과의 일관성 / 테스트 용이성)으로 비교한 뒤,
> 선택한 안을 아래 ADR 4요소로 기록한다.

### 관심 화면 위젯 구조

**Context** — `lib/pages/watchlist_page.dart`(Phase 0 더미)를 실제 UI로 교체해야 한다. 화면은 헤더(정렬 칩),
목록(행+별아이콘+스켈레톤), 빈 상태, 에러 상태, 정렬 바텀시트로 구성된다. 프로젝트는 FSD 변형 구조를 쓰며
`lib/pages/README.md`는 "Page는 widgets/features/entities/shared를 조립만 한다"고 못박아 두었다 — 어떤 조각을
어느 레이어에 둘지 결정해야 한다. 3가지 안을 비교했다.

| # | 기준 | A: page에 다 넣기 | B: feature 단위로만 분리 | C: 공용 UI만 widgets, 도메인 로직은 features |
|---|---|---|---|---|
| 1 | 데이터 구조 | 동일 (`WatchlistItem` 리스트 그대로 렌더) | 동일 | 동일 |
| 2 | API 레이어 변경지점 | 없음 | 없음 | 없음 |
| 3 | 상태관리 변경지점 | 없음(기존 provider 구독만) | 없음 | 없음 |
| 4 | 핵심 동작 | AsyncValue.when 분기 전부 page 안에 inline | 동일 로직이지만 위젯 단위로 분리돼 각 파일이 단일 책임 | B와 동일하되 스켈레톤만 별도 레이어 |
| 5 | 컴포넌트 구조 | 단일 파일 300+줄 | `features/watchlist-list/`에 5개 파일 | 스켈레톤은 `widgets/skeleton_box.dart`, 나머지는 `features/watchlist-list/` |
| 6 | 기존 패턴과의 일관성 | `lib/pages/README.md` 규칙(조립만) 위반 | Phase 1 `search-query`, Phase 2 `watchlist-sort`와 동일한 패턴 | B와 동일 + `lib/widgets/README.md`가 정의한 "여러 화면이 공유하는 도메인 비종속 UI" 조건을 스켈레톤이 충족 |
| 7 | 테스트 용이성 | 위젯 테스트 시 화면 전체를 pump해야 함 | 위젯 단위 개별 테스트 가능 | 동일 (B와 차이 없음) |

**Decision** — **C안**: 시세 미수신 행의 스켈레톤(네모박스 + 밝기 pulse 애니메이션)은 `lib/widgets/skeleton_box.dart`로
분리한다. 검색(Phase 4)·상세(Phase 5) 화면에서도 로딩 중인 값에 동일한 스켈레톤을 쓸 계획이 이미 확정되어 있어
(사용자 확인), 처음부터 도메인 비종속 공용 위젯으로 만드는 것이 Phase 4/5에서 다시 꺼내는 리팩토링 비용을 없앤다.
그 외 행(`watchlist_row.dart`), 정렬 칩/바텀시트, 빈 상태, 에러 배너/에러 뷰는 `lib/features/watchlist-list/`에 둔다
(`WatchlistItem`·`SortCriteria` 등 관심 도메인 모델에 직접 의존하므로 B안과 동일하게 feature 레이어).
`watchlist_page.dart`는 이 조각들을 `Scaffold`로 조립만 한다.

**Alternatives**
- A안(page에 다 넣기) — 가장 빠르지만 `lib/pages/README.md`가 명시한 "Page는 조립만" 규칙을 정면으로 어기고,
  파일이 300줄 이상으로 커져 리뷰어가 "이 파일이 뭘 하는지" 한눈에 파악하기 어려워진다. 기각.
- B안(전부 feature로) — 에러 배너까지 공용화하려 했으나, 에러 배너는 ASSIGNMENT.md가 "Figma에 정의되지 않은 상태"로
  명시한 항목이라 화면마다 문구·배치가 달라질 수 있다. 반면 스켈레톤은 세 화면 모두 동일하게 쓸 것이 이미 확정됐으므로,
  에러 배너까지 미리 공용화하는 것(B안이 아니라 오히려 C안을 에러 배너에도 적용하는 것)은 YAGNI 위반으로 기각하고,
  스켈레톤만 공용화하는 C안을 최종 채택했다.

**Consequences**
- 장점: Phase 4(검색)·Phase 5(상세) 작업 시 스켈레톤을 새로 만들지 않고 import만 하면 된다. 관심 화면 테스트도
  위젯 단위로 쪼개져 있어 회귀 파악이 쉽다.
- 단점: 파일 수가 A안보다 많아져(6개) 처음 코드베이스를 보는 사람은 어디서 무엇을 찾아야 할지 README를 먼저
  읽어야 한다. 에러 배너/뷰는 지금 판단으로는 feature 안에 두지만, 검색·상세 화면 작업 중 실제로 모양이 같다고
  확인되면 그때 다시 `widgets/`로 옮기는 추가 작업이 생길 수 있다(경미한 비용으로 판단).

## Out of Scope

> 관련은 있지만 이번엔 하지 않을 것을 구체적으로 나열한다. 명시하지 않으면 이후 구현 세션이
> 맥락을 확장 해석해 요청받지 않은 것까지 만든다.

- **별 아이콘 연속 클릭 방지의 구체적 구현**(로컬 Set 추적 등) — 요구사항만 확정, 실제 방식은 이슈 구현 시 결정 (spec-fixed.md 참고)
- **하단 탭 재선택 시 무동작의 구체적 구현** — 동일하게 이슈 구현 시 결정
- **Pull to refresh** — 선택 항목, 이번 Phase에서 다루지 않음
- **관심종목 스와이프 삭제** — 선택 항목
- **정렬 기준 영속화**(앱 재실행 후 유지) — 선택 항목
- **검색/상세 화면 자체 구현** — Phase 4/5에서 별도 진행. 이번 Phase는 이 두 화면이 재사용할 `skeleton_box.dart`
  위젯의 "자리"만 만들어 둘 뿐, 검색/상세 화면 코드는 건드리지 않는다.
- **에러 배너/에러 뷰의 widgets 레이어 승격** — 지금은 `features/watchlist-list/`에 둔다. 검색·상세 화면에서
  실제로 동일한 모양이 필요하다고 확인되기 전까지는 옮기지 않는다.
- **등락 포맷팅 공용 유틸의 실제 사용처 확장** — 이번 Phase에서 `lib/shared/utils/`에 만들지만, 상세 화면(Phase 5)에
  가져다 쓰는 작업은 Phase 5 몫이다.

## Definition of Done

- [ ] `flutter analyze` 0 경고 유지
- [ ] 관심 화면 필수 항목 전부 동작: 행 표시(종목명/코드·시장/현재가/등락) / 등락 3색 / 새로고침 /
      하단 탭바 / 스켈레톤 / 빈 상태 / 정렬 바텀시트
- [ ] 등락 색상: 상승=`priceUpText`(빨강) / 하락=`priceDownText`(파랑) / 보합=`priceFlatText`·`priceFlatBg` — 반대 아님
- [ ] 화면 코드에서 `AppPalette` 직접 참조 없음(전부 `context.colors.*` 시맨틱 토큰)
- [ ] 새 위젯/함수에 Dart 타입 명시, `dynamic`/암묵적 `any` 없음
- [ ] 관심 화면 위젯 테스트 최소 1개 이상 (빈 상태 렌더링 등 핵심 시나리오)

## 용어 정의

> spec-fixed.md의 Ubiquitous Language와 동기화한다.

| 용어 | 정의 |
|---|---|
| 관심 화면 | `01 · 관심` 프레임. 관심종목 목록을 보여주는 화면(`lib/pages/watchlist_page.dart`) |
| 관심 항목(WatchlistItem) | 관심등록된 종목 하나 + 결합된 StockMeta/Quote (기존 모델, 변경 없음) |
| 정렬 기준(SortCriteria) | `현재가순`(priceDesc) / `등락률순`(changeRateDesc) / `가나다순`(nameAsc) — 기존 enum, 변경 없음 |
| 정렬 바텀시트 | 정렬 칩을 눌렀을 때 열리는, 3가지 정렬 기준을 고르는 하단 슬라이드 패널 |
| 시세 미수신 행 | `WatchlistItem.quote == null`인 행. 스켈레톤으로 표시되며 정렬 시 항상 맨 뒤 |
| 관심 해제 | 별 아이콘을 눌러 해당 종목을 관심 목록에서 제거하는 동작 (기존 `toggleFavorite` 재사용) |
| SkeletonBox | 세 화면(관심/검색/상세) 공용, 네모박스 + 밝기 pulse 애니메이션의 로딩 placeholder 위젯 (`lib/widgets/skeleton_box.dart`) |
