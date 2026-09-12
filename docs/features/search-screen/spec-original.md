# search-screen — 초기 아이디어 (spec-original)

## 배경

`docs/ASSIGNMENT.md`의 `02 · 검색` 화면(및 하위 상태 `02 · 검색_empty`, `02 · 검색결과_empty`, `04 · 검색 · 관심 등록 토스트`, `05 · 검색 · 관심 해제 토스트`)을 구현한다.

## 이미 준비된 것

- `lib/features/search-query/`: `query_normalizer.dart`(공백 제거 정규화), `highlight_matcher.dart`(하이라이트 range 계산), `search_debouncer_notifier.dart`(300ms 디바운스 + 2글자 미만 미조회 + `searchRepositoryProvider` 호출, `searchDebouncerNotifierProvider`로 노출)
- `lib/entities/search/`: `search_result.dart`, `search_repository.dart` / `network_search_repository.dart` / `mock_search_repository.dart`, `search_providers.dart`
- `lib/entities/stock_meta/`: 종목명/거래소명 메타데이터 레이어
- `lib/entities/watchlist/`: `watchlist_notifier.dart`(`toggleFavorite`), `watchlist_providers.dart`
- `lib/pages/search_page.dart`: 현재 Phase 0 더미(버튼 하나 + 상세 이동 테스트용)

## 이번 Phase 범위 (가설)

`search_page.dart`를 실제 UI로 교체:

- 검색 입력창 + 지우기 버튼
- 검색 결과 리스트: 종목명(하이라이트) + `종목코드 · 시장` + 관심 등록 별 아이콘
- 별 아이콘 탭 → 관심 등록/해제 즉시 반영 + 하단 토스트
- 행 탭 → 상세 화면 이동
- 초기 상태(검색 전) / 결과 없음 상태 각각 시안대로
- watchlist-screen에서 이미 나온 "연속 클릭 방지" 패턴을 검색 화면 별 아이콘에도 적용해야 한다는 이슈가 남아있음

## 확인이 필요한 부분

- 정확한 화면 조립 방식과 상태 전이, 토스트 처리, 에러 처리, 재사용 범위는 인터뷰로 확정한다.
