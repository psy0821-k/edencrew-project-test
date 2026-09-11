# Phase 2: 관심 상태 공유 계층 (watchlist-sync) — 초기 아이디어

## 배경

이든크루 Flutter 과제 ROADMAP 상 Phase 2. Phase 0(project-foundation)에서 Riverpod/FSD 아키텍처 뼈대와 Repository 인터페이스·provider 골격을 준비했고, Phase 1(naver-data-layer)에서 StockMeta/Quote/Search/DailyQuote 4개 도메인의 실제 데이터 계층(파싱·DTO·Mock/Network Repository)을 완성했다.

과제 요구사항(ASSIGNMENT.md "4. 상태 동기화 (전체 필수)")은 다음을 명시한다:

- 관심 상태가 바뀌면 관심 화면, 검색 화면, 상세 화면의 별 아이콘이 모두 함께 바뀐다.
- 검색 직후에도 현재 관심 상태가 결과에 반영된다.
- 검색 화면에서 관심 등록한 종목이 관심 화면 목록에 반영된다.
- 상세 화면에서 관심을 해제하고 돌아오면 목록에도 반영된다.
- (선택) 관심 목록을 앱 재실행 후에도 유지 — 로컬 저장은 이번 Phase 범위가 아닐 수 있음, 인터뷰에서 확정 필요.

## 이번 Phase가 다루는 것

- 관심종목 도메인 모델 (`entities/watchlist`로 귀결 예정 — project-foundation ADR 2 참고)
- 관심종목 등록/해제 Repository (Mock/Network 여부는 인터뷰에서 확정 — 이 데이터는 Naver가 제공하지 않고 클라이언트가 직접 관리하는 상태이므로 project-foundation의 다른 도메인과 다를 수 있음)
- 3화면(관심/검색/상세)이 이 상태를 함께 구독해 동기화되는 provider 구조
- 관심종목 목록에 실제 시세(Quote)·메타데이터(StockMeta)를 붙이기 위한 조합 로직 (화면이 쓸 수 있는 형태로)

## 이번 Phase가 다루지 않는 것 (인터뷰에서 확정)

- 화면 UI(레이아웃, 정렬 바텀시트, 빈 상태, 토스트 등 시각적 요소) — 다음 Phase(화면 구현)
- 정렬 로직 자체(현재가순/등락률순/가나다순)는 화면 Phase에서 다룰지, 이번 Phase에서 도메인 로직으로 준비해둘지 인터뷰 필요
- 로컬 영속화(재실행 후 유지) — 과제상 선택 항목, 이번 Phase 범위 여부 인터뷰 필요

## 참고 문서

- `docs/ASSIGNMENT.md` — 4번 섹션 "상태 동기화"
- `docs/features/project-foundation/prd.md` — ADR 1(Riverpod), ADR 2(FSD), ADR 6(Failure)
- `docs/features/naver-data-layer/prd.md` — Quote/StockMeta/Search 도메인 구조
- `lib/entities/quote/`, `lib/entities/stock_meta/`, `lib/entities/search/` — 기존 도메인 패턴
