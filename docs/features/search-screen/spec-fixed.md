# search-screen — 확정 요구사항 (spec-fixed)

> feature-planner 단계1 산출물. 인터뷰로 모호성을 제거하고 결정 사항을 고정한 문서.
> 이 문서가 확정되어야 단계2(PRD)로 넘어간다.

## Primary User

이든크루 과제 평가자 — Flutter 코드로 화면을 직접 실행해 필수 요건 충족 여부와 직접 판단한 부분의 타당성을 확인하는 사람.

## 최소 동작 시나리오

1. 검색 탭에 처음 진입하면(검색어 미입력) 초기 상태(돋보기 아이콘 + `종목을 검색해 보세요` + 안내 문구)가 보인다.
2. `삼성전자` 또는 `005930`을 입력하면 300ms 디바운스 후 결과 목록이 뜬다. 종목명 중 검색어와 일치하는 부분이 하이라이트되고, `종목코드 · 시장`이 함께 보인다. 별 아이콘을 눌러 관심 등록하면 즉시 채워진 별 + 하단 토스트(`관심이 등록되었습니다`)가 뜨고 2초 후 사라진다.
3. 결과가 없는 검색어를 입력하면 `'{입력한 검색어}'와 일치하는 검색 결과를 찾지 못했습니다` 문구가 보인다. 입력을 X 버튼으로 지우면 다시 초기 상태로 돌아간다.

## 데이터 저장 방식

새로 추가되는 저장소는 없다. 이미 완성된 다음을 그대로 구독/호출한다.

- `lib/features/search-query/search_debouncer_notifier.dart`의 `searchDebouncerNotifierProvider` (디바운스 + 최소 2글자 + `searchRepositoryProvider.search` 호출)
- `lib/features/search-query/query_normalizer.dart`, `highlight_matcher.dart`
- `lib/entities/search/search_result.dart` (`symbol`, `name`, `marketName` 모두 포함 — 이 화면에서 `stock_meta_providers`를 별도로 조회하지 않는다)
- `lib/entities/watchlist/watchlist_providers.dart`의 `isFavoriteProvider`(symbol 단위 구독), `watchlistProvider.toggleFavorite`
- `lib/pages/stock_detail_page.dart`(symbol) — 상세 이동은 기존 `Navigator.push(MaterialPageRoute(builder: (_) => StockDetailPage(symbol: ...)))` 패턴 재사용

새로 추가하는 것은 화면 조립 위젯들과, 아래 "연속 클릭 방지" 공용 로직뿐이다.

## 경계 조건

- **검색어 길이**: 2글자 미만(1글자 포함, 공백만 입력해 `normalizeQuery` 결과가 빈 문자열이 되는 경우 포함)이면 `searchDebouncerNotifierProvider`가 이미 요청 자체를 보내지 않는다(빈 목록 유지) — 화면은 이 경우 "결과 없음"이 아니라 그대로 초기 상태 UI(`종목을 검색해 보세요` 안내)를 유지한다. 별도의 "2글자 이상 입력해주세요" 같은 안내는 추가하지 않는다.
- **검색 대상**: 종목명 검색과 6자리 종목코드 검색 모두 지원해야 한다는 요구사항만 확정한다. `NetworkSearchRepository`는 현재 `q` 파라미터에 정규화된 문자열을 그대로 전달하는데, 코드 입력 시 Naver 자동완성 API가 실제로 매칭 결과를 주는지는 이슈 구현 단계에서 실기기로 검증하고, 필요 시 대응(예: 6자리 숫자 패턴이면 별도 처리)도 그 단계에서 결정한다. 이번 spec에서는 "코드로도 검색 가능해야 한다"는 요구사항만 고정한다.
  - **[이슈 #32 검증 결과]** `dataSourceModeProvider` 기본값이 이미 `network`이므로, 별도 전환 없이 실기기(에뮬레이터)에서 그대로 실제 Naver API로 확인했다. 종목명(`삼성전자`)과 6자리 종목코드(`005930`) 둘 다 정상적으로 결과가 표시된다 — 별도 전처리/대응 코드는 필요 없었다.
  - **[한계 발견]** Naver 자동완성 API(`ac.stock.naver.com/ac`)는 **접두어(prefix) 매칭만** 지원한다. 예를 들어 "삼성전자"에서 "삼성"으로 검색하면 정상적으로 나오지만, "전자"로 검색하면 결과가 나오지 않는다. 이는 앱 코드의 버그가 아니라 외부 API 자체의 특성이며, 클라이언트 코드로 보완하려면(전체 종목 목록을 별도로 확보해 로컬 `contains` 검색) 별도 데이터 소스가 필요해 이번 과제 범위에서는 대응하지 않기로 결정했다.
- **종목코드 검색 시 하이라이트 범위**: ASSIGNMENT.md 명세대로 하이라이트는 종목명에만 적용한다. 종목코드로 검색해도(예: `005930`) 종목코드 텍스트 자체에는 하이라이트를 적용하지 않는다(매칭되면 보통 종목명 쪽엔 하이라이트가 없을 수 있음 — 그 경우 종목명은 그냥 일반 텍스트로 표시).
- **결과 없음 문구의 검색어**: 사용자가 입력한 원본 문자열(정규화 전) 그대로 삽입한다.
- **이미 관심등록된 종목이 검색 결과에 노출**: 별 아이콘은 `isFavoriteProvider(symbol)`을 그대로 구독해 처음부터 채워진 상태(`favoriteActive`)로 표시한다. 별도 처리 불필요 — 기존 provider 재사용만으로 충족됨을 명시적으로 확인한다.
- **종목명 텍스트 오버플로**: 별 아이콘 등 다른 요소와 겹치지 않도록 1줄 + 말줄임표(`TextOverflow.ellipsis`)로 자른다. 관심 화면 행과 동일한 정책.
- **관심 등록/해제 연속 클릭**: 아래 "연속 클릭 방지" 절 참조.
- **입력 초기화(X 버튼)**: 검색어와 결과를 모두 비우고 초기 상태로 되돌린다.
- **디바운스 대기/응답 대기 중 로딩 표시**: 이번 Phase 범위에 포함하지 않는다(선택 항목, 시간이 남으면 별도 이슈로 진행).
- **토스트 겹침**: 서로 다른 종목에서 연속으로 별 아이콘을 눌러 토스트가 겹치는 경우, 새 토스트가 기존 토스트를 즉시 교체한다(`ScaffoldMessenger`의 기본 SnackBar 교체 동작 그대로 사용, 별도 큐잉 로직 불필요).
- **토스트 노출 시간(2초) 근거**: ASSIGNMENT.md가 Figma에 정의되지 않아 직접 판단하라고 명시한 항목이다. 별 아이콘이 탭 즉시 채워짐/빈 상태로 바뀌므로 토스트는 유일한 정보 전달 수단이 아니라 보조 확인용이라, 문장을 끝까지 읽게 만들 필요 없이 "스치듯 봐도 충분하다"고 판단했다. 다만 1초는 한글 문구(`관심이 등록되었습니다` 등)를 인지하기엔 너무 짧다고 보여 제외했고, Material `SnackBar` 기본값(4초)은 연속으로 여러 종목을 토글할 수 있는 화면 특성상 과하게 길다고 판단해 제외했다. 그 중간값으로 2초를 채택했다.

## 에러 처리

`searchDebouncerNotifierProvider`(`AsyncNotifier`)가 실패했을 때(`AsyncError`): "결과 없음" 화면과 시각적으로 유사한 레이아웃을 재사용하되 문구만 에러용으로 바꾼다(예: `검색 중 문제가 발생했습니다`). 별도의 에러 아이콘/배너나 재시도 버튼은 만들지 않는다 — 사용자가 타이핑을 계속하면 디바운스 후 자동으로 재시도되기 때문이다.

## 연속 클릭 방지 (공용 패턴)

**적용 범위**: 검색 화면의 관심 등록/해제 별 아이콘, 관심 화면의 새로고침 버튼. 둘 다 "탭 즉시 비동기 작업이 시작되고, 완료 전 재입력이 상태를 꼬이게 하거나 중복 요청을 유발"하는 액션이라는 공통점이 있다.

**동작 방식**: 요청 시작 시점에 진행 중 상태로 표시하고, 응답이 오면(성공/실패 무관) 해제한다. 진행 중인 동안 같은 액션의 재입력은 무시한다.

- 별 아이콘(symbol 단위): 진행 중 symbol 집합을 공용으로 관리 — 이미 등록/해제 요청이 진행 중인 symbol의 별 아이콘 재탭은 무시.
- 새로고침 버튼: 진행 중 여부를 bool로 관리 — 진행 중이면 버튼 재탭 무시(또는 비활성화 스타일).

**구현 범위**: 공용 유틸/Provider 하나로 만들어 이번 Phase에서 검색 화면 별 아이콘과 관심 화면 새로고침 버튼 둘 다에 적용한다.

## 재사용할 기존 UI 패턴 / 컴포넌트

- `lib/theme/`의 시맨틱 토큰 전부 (`favoriteActive`/`favoriteInactive`, `searchHighlight`, `textPrimary`/`textSecondary`/`textTertiary`)
- `lib/features/search-query/`의 `searchDebouncerNotifierProvider`, `normalizeQuery`, `findHighlightRange`
- `lib/entities/watchlist/watchlist_providers.dart`의 `isFavoriteProvider`, `watchlistProvider`
- `lib/pages/stock_detail_page.dart` 이동 경로
- `lib/features/watchlist-list/watchlist_empty_view.dart` — 아이콘 + 타이틀 + 캡션 구조를 공용 `EmptyStateView`로 일반화하고, `WatchlistEmptyView`와 검색 화면의 초기/결과없음 상태 모두 이 공용 위젯 위에서 재구성한다.

## 성능 제약

- **허용 응답 시간**: 없음(Naver API 응답 속도에 의존).
- **데이터 크기 제한**: 없음. 검색 결과는 자동완성 API 응답 개수 그대로 표시(`ListView.builder`).

## 향후 확장 가능성

- 연속 클릭 방지 공용 패턴은 이후 상세 화면의 관심 등록 버튼에도 동일하게 재사용될 수 있다.
- `EmptyStateView` 공용화는 이후 상세 화면 등 다른 빈/에러 상태 화면에도 재사용 가능한 기반이 된다.

## 용어 정의 (Ubiquitous Language)

| 용어 | 정의 |
|---|---|
| 검색 화면 | `02 · 검색` 프레임. 종목 검색 및 관심 등록을 하는 화면(`lib/pages/search_page.dart`) |
| 검색 결과 행 | `SearchResult` 하나를 표시하는 행. 종목명(하이라이트) + `종목코드 · 시장` + 별 아이콘 |
| 초기 상태 | 검색어가 비어 있을 때(`02 · 검색_empty`)의 화면 상태 |
| 결과 없음 상태 | 유효한 검색(2글자 이상)을 했지만 결과가 0건일 때(`02 · 검색결과_empty`)의 화면 상태 |
| 하이라이트 | 종목명 중 정규화된 검색어와 일치하는 구간을 `searchHighlight` 토큰으로 강조하는 것 |
| 관심 등록 토스트 / 관심 해제 토스트 | 별 아이콘 토글 시 화면 하단에 2초간 노출되는 안내 메시지 (`04`/`05` 프레임) |
| 진행 중 상태(연속 클릭 방지) | 별 아이콘 토글 또는 새로고침 요청이 아직 완료되지 않은 상태. 이 동안 같은 액션의 재입력은 무시된다 |
| EmptyStateView | 아이콘 + 타이틀 + 캡션 구조를 공유하는 공용 빈 상태 위젯. `WatchlistEmptyView`와 검색 화면 초기/결과없음 상태가 이 위에서 구성된다 |
