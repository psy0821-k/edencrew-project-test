# watchlist-screen — 초기 아이디어 (spec-original)

> feature-planner 단계1(요구사항 인터뷰)의 입력. 다듬어지지 않은 생각을 그대로 적는다.
> 이 파일은 인터뷰 후 `spec-fixed.md`로 확정된다. 여기서는 완결성보다 솔직함이 중요하다.

## 무엇을 만들고 싶은가

`01 · 관심` 화면(ROADMAP.md Phase 3). 관심종목 목록을 보여주는 화면으로, 현재 `lib/pages/watchlist_page.dart`는
Phase 0에서 만든 라우팅 검증용 더미 화면(버튼 하나)이다. 이걸 실제 UI로 교체한다.

Phase 2에서 이미 데이터 계층은 완성돼 있다: `watchlistItemsProvider`(symbol → StockMeta+Quote 결합 리스트),
`watchlistSortCriteriaProvider` + `sortWatchlistItems`(정렬 comparator). 이번 Phase는 그 위에 UI를 붙이는 작업이다.

## 왜 필요한가 / 어떤 문제를 푸는가

과제 1의 평가 대상 화면 3개 중 하나이며, `docs/ASSIGNMENT.md` 기준 필수 항목이 다음과 같이 명시돼 있다:

- 행 표시: 종목명 / `종목코드 · 시장` / 현재가 / `등락액 (등락률%)`
- 등락 색상 3상태(상승=빨강/하락=파랑/보합) 처리
- 상단 새로고침 버튼 → 시세 재조회
- 하단 탭 바 (관심/검색 전환, navActive/navInactive)
- 시세 미수신 행 스켈레톤 (feedbackSkeleton)
- 빈 상태 (관심종목 없음) — 헤더·탭바는 유지
- 정렬 기능 (현재가순/등락률순/가나다순) — 바텀시트, 체크 표시, 즉시 재정렬 + 칩 문구 변경

## 대략적인 사용 흐름

- 앱을 실행하면 관심 화면이 기본 탭으로 보인다.
- 관심종목이 있으면 목록이 뜨고, 각 행에 종목명/코드·시장/현재가/등락 정보가 보인다. 시세가 아직 안 왔으면 스켈레톤.
- 상단 새로고침 버튼을 누르면 시세를 다시 조회한다.
- 헤더 우측 정렬 칩을 누르면 바텀시트가 열리고, 정렬 기준(현재가순/등락률순/가나다순)을 고르면 목록이 즉시 재정렬되고 칩 문구가 바뀐다.
- 관심종목이 하나도 없으면 별 아이콘 + 안내 문구의 빈 상태를 보여준다(헤더/탭바는 그대로).
- 하단 탭 바로 검색 화면과 전환한다.

## 아직 모르겠는 것 / 결정 못 한 것

- 시세를 아직 못 받은(quote == null) 행을 현재가순/등락률순 정렬에서 어디에 둘지 — ASSIGNMENT.md에 "직접 판단" 항목으로 명시됨.
  (참고: `watchlist_comparator.dart`에 이미 null-safe 비교로 최하단 배치 로직이 구현돼 있음 — Phase 2 산출물 그대로 재사용 예정)
- 새로고침 버튼을 눌렀을 때 로딩 상태를 화면에 어떻게 보여줄지(전체 스피너 vs 각 행 스켈레톤 재사용) — Figma에 명시 없음.
- 네트워크 에러 시 화면 처리 방식 — Figma에 없는 상태, 직접 판단 필요(README 메모 대상, 평가 비중 높음).

## 참고 (유사 사례, 기존 화면, 링크 등)

- Figma 프레임: `01 · 관심`, `01 · 관심_empty`, `01 · 관심_sort` (안내 메일 전달, 393×852, 다크 테마 단일)
- 기존 산출물: `lib/entities/watchlist/`(watchlist_item.dart, watchlist_providers.dart), `lib/features/watchlist-sort/`
- 디자인 토큰: `lib/theme/README.md` Figma 변수 ↔ Dart 필드 대응표
- 유사 화면 구현 패턴 참고: Phase 1의 `entities/search`, `features/search-query` 폴더 구조
