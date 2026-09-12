# search-screen 이슈 분해

> feature-planner 단계3 산출물. prd.md 기준. 수직 슬라이스 원칙: 각 이슈 완료 시 사용자에게 보여줄 수 있는 동작이 있어야 한다.
> 의존성 순서대로 나열(앞 이슈가 뒤 이슈의 입력이 됨).

## 이슈 1 — 공용 EmptyStateView 추출 + WatchlistEmptyView 재구성

기존 `WatchlistEmptyView`의 아이콘+타이틀+캡션 구조를 `lib/widgets/empty_state_view.dart`의 `EmptyStateView`로
추출하고, `WatchlistEmptyView`를 그 위에서 재구성한다. 검색 화면 작업 전에 먼저 끝내 두 번째 이슈부터 바로
재사용할 수 있게 한다.

**Acceptance Criteria**
- [ ] Given 관심종목이 0개인 관심 화면, When 화면을 렌더링하면, Then 기존과 동일하게 별 아이콘 + `관심 종목이 없습니다` +
      안내 문구가 보인다 (시각적 회귀 없음).
- [ ] Given `EmptyStateView`에 아이콘 경로/타이틀/캡션을 다른 값으로 넘기면, When 렌더링하면, Then 넘긴 값 그대로
      표시된다 (범용성 검증).
- [ ] Given 기존 관심 화면 위젯 테스트, When 리팩토링 후 재실행하면, Then 그대로 통과한다(회귀 없음).

**의존성**: 없음 (선행 이슈)

---

## 이슈 2 — 검색 화면 뼈대: 입력창 + 초기 상태 + 결과 목록(하이라이트) + 결과없음 상태

`search_page.dart`를 실제 UI로 교체하는 첫 수직 슬라이스. `searchDebouncerNotifierProvider`를 구독해 입력에
따라 초기/결과/결과없음 상태를 전환한다. 이 이슈는 mock 데이터(`dataSourceModeProvider` 또는 provider override)로
검증하고, 관심 등록·상세 이동·연속 클릭 방지는 다루지 않는다(다음 이슈들에서 추가).

**Acceptance Criteria**
- [ ] Given 검색 화면에 처음 진입(검색어 없음), When 화면을 렌더링하면, Then 돋보기 아이콘 + `종목을 검색해 보세요` +
      안내 문구가 보인다.
- [ ] Given 검색 입력창에 1글자만 입력, When 300ms 경과하면, Then 요청이 발생하지 않고 초기 상태 화면이 그대로 유지된다.
- [ ] Given 검색 입력창에 공백만 연속 입력, When 300ms 경과하면, Then 초기 상태 화면이 그대로 유지된다.
- [ ] Given 검색 입력창에 2글자 이상 유효한 종목명 입력, When 300ms 경과하고 결과가 도착하면, Then 결과 목록이
      보이고 각 행에 종목명(검색어 일치 구간 하이라이트) + `종목코드 · 시장`이 표시된다.
- [ ] Given 결과가 없는 검색어 입력, When 응답이 도착하면, Then `'{입력한 검색어}'와 일치하는 검색 결과를 찾지
      못했습니다` 문구가 보인다 (입력한 원본 문자열 그대로).
- [ ] Given 검색 요청이 실패(`AsyncError`), When 에러 상태가 되면, Then 결과없음 상태와 유사한 레이아웃에 에러
      문구(`검색 중 문제가 발생했습니다`)가 보인다.
- [ ] Given 검색 결과가 보이는 상태, When 입력창 우측 X 버튼을 누르면, Then 검색어와 결과가 모두 지워지고 초기
      상태로 돌아간다.
- [ ] Given 종목명이 매우 긴 검색 결과 행, When 렌더링하면, Then 별 아이콘 영역과 겹치지 않고 말줄임표로 잘린다.

**의존성**: 이슈 1 (`EmptyStateView`를 초기/결과없음 상태에 사용)

---

## 이슈 3 — 실기기 network 모드 검증: 종목명/종목코드 검색 동작 확인

이슈 2로 화면이 눈에 보이는 상태가 됐으므로, `dataSourceModeProvider`를 `network`로 두고 실기기/에뮬레이터에서
실제 Naver 자동완성 API에 종목명과 6자리 종목코드 각각으로 검색해 정상 동작하는지 확인한다. 코드 검색이 기대대로
동작하지 않으면 이 이슈 안에서 최소한의 대응(예: 쿼리 전처리)을 추가한다. 인터랙션(별 아이콘, 상세 이동)을 붙이기
전에 검증해 파싱/표시 문제와 인터랙션 문제를 분리한다.

**Acceptance Criteria**
- [ ] Given network 모드로 실행한 실기기/에뮬레이터, When 종목명(예: `삼성전자`)을 입력하면, Then 실제 API 응답
      기반 결과 목록이 정상 표시된다.
- [ ] Given network 모드, When 6자리 종목코드(예: `005930`)를 입력하면, Then 해당 종목이 결과에 나타난다. 나타나지
      않으면 원인을 확인하고 최소 대응을 이 이슈에서 구현한다.
- [ ] Given 위 확인 결과, When README 메모를 작성하면, Then 코드 검색 동작 여부와 (필요 시) 적용한 대응 방식,
      그 이유가 기록되어 있다.

**의존성**: 이슈 2 (화면이 있어야 실제 응답을 눈으로 확인 가능)

---

## 이슈 4 — 관심 등록/해제: 별 아이콘 + 토스트 + 연속 클릭 방지(PendingSymbolsNotifier)

검색 결과 행의 별 아이콘이 `isFavoriteProvider`를 구독해 상태를 표시하고, 탭하면 `watchlistProvider.toggleFavorite`을
호출해 즉시 반영 + 토스트를 띄운다. 연속 클릭 방지용 `PendingSymbolsNotifier`를 `lib/shared/state/`에 새로 만들어
적용한다.

**Acceptance Criteria**
- [ ] Given 이미 관심등록된 종목이 검색 결과에 있는 경우, When 화면을 렌더링하면, Then 별 아이콘이 채워진 상태로
      보인다.
- [ ] Given 관심등록되지 않은 종목의 빈 별 아이콘, When 탭하면, Then 즉시 채워진 별 아이콘으로 바뀌고 하단에
      `관심이 등록되었습니다` 토스트가 뜬 뒤 2초 후 사라진다.
- [ ] Given 관심등록된 종목의 채워진 별 아이콘, When 탭하면, Then 즉시 빈 별 아이콘으로 바뀌고 `관심이 해제되었습니다`
      토스트가 뜬다.
- [ ] Given 별 아이콘 토글 요청이 진행 중인 상태(`PendingSymbolsNotifier`에 해당 symbol 포함), When 같은 별 아이콘을
      다시 탭하면, Then 요청이 중복 발생하지 않는다(무시됨).
- [ ] Given A 종목 등록 토스트가 떠 있는 상태, When 다른 B 종목의 별 아이콘을 탭해 해제 토스트가 발생하면, Then
      기존 토스트가 즉시 새 토스트로 교체된다.

**의존성**: 이슈 2 (결과 행 UI), 이슈 3 (실제 데이터 검증 완료 후 인터랙션 추가)

---

## 이슈 5 — 관심 화면 새로고침 버튼에 연속 클릭 방지(PendingFlagNotifier) 적용

`PendingFlagNotifier`를 새로 만들어 관심 화면의 새로고침 버튼(`WatchlistHeader.onRefreshTap`)에 적용한다.
검색 화면과 무관하지만 PRD 기술 결정 2에서 함께 설계한 공용 로직의 두 번째 사용처로, 이슈 4에서 만든
`PendingSymbolsNotifier`와 뼈대를 공유한다.

**Acceptance Criteria**
- [ ] Given 관심 화면 새로고침 버튼, When 탭하면, Then `watchlistItemsProvider`가 재조회를 시작하고 진행 중
      상태가 된다.
- [ ] Given 새로고침 요청이 진행 중인 상태, When 새로고침 버튼을 다시 탭하면, Then 재조회가 중복 발생하지 않는다.
- [ ] Given 새로고침 요청이 완료(성공 또는 실패)되면, When 상태를 확인하면, Then 진행 중 상태가 해제되어 다시
      탭할 수 있다.

**의존성**: 없음(이슈 4와 같은 뼈대를 공유하지만 병렬 진행 가능 — 단 코드 리뷰 편의상 이슈 4 이후 진행 권장)

---

## 이슈 6 — 검색 결과 행 탭 → 종목 상세 이동

검색 결과 행을 탭하면 기존 `StockDetailPage(symbol: ...)` 경로로 이동한다.

**Acceptance Criteria**
- [ ] Given 검색 결과 목록이 보이는 상태, When 한 행을 탭하면, Then 해당 종목의 `StockDetailPage`로 이동한다
      (symbol이 정확히 전달됨).
- [ ] Given 별 아이콘 영역을 탭한 경우, When 탭 이벤트가 발생하면, Then 상세 이동은 일어나지 않고 관심 등록/해제만
      동작한다 (탭 영역이 겹치지 않음).

**의존성**: 이슈 2 (결과 행 UI), 이슈 4 (별 아이콘 탭 영역과 행 탭 영역이 겹치지 않아야 하므로 별 아이콘 구현 이후)
