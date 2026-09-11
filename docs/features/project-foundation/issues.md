# project-foundation — 이슈 분해

PRD(`prd.md`) 기준. 이 Phase는 사용자 기능이 없는 아키텍처 뼈대라 "사용자 관찰 가능 결과"를 "다음 이슈가 실제로 검증 가능한 상태" 및 "`flutter run`으로 확인 가능한 최소 동작"으로 대체 적용한다. 전체 시간 상한 4시간(스코프 초과 시 이슈 4의 도메인 범위를 Quote 1개로 이미 한정해둔 상태 유지, 필요 시 이슈 4를 인터페이스 정의까지만 남기고 Phase 1로 이월).

의존 순서: 1 → 2 → 3 → 4 (2, 3은 1 완료 후 병행 가능).

---

## 이슈 1 — 패키지 추가 및 FSD 폴더 구조 생성

### 설명
`pubspec.yaml`에 필요 패키지를 추가하고, `lib/` 하위에 FSD 6개 레이어 폴더를 생성한다. `StartHereScreen`은 이 이슈에서 제거하지 않는다(라우팅 스켈레톤이 실제로 대체할 때 제거 — 이슈 3).

### 작업 범위
- `pubspec.yaml`에 `flutter_riverpod`, `http`, `intl` 추가
- `lib/app/`, `lib/pages/`, `lib/widgets/`, `lib/features/`, `lib/entities/`, `lib/shared/` 폴더 생성 (각 폴더에 `.gitkeep` 또는 최소 placeholder)
- `app/main.dart`로 기존 `main.dart` 로직 이동 준비(단, 실제 이동은 이슈 3에서 라우팅과 함께 — 이 이슈에서는 폴더만)

### Acceptance Criteria
- [ ] Given `pubspec.yaml`을 열었을 때, When 의존성 목록을 확인하면, Then `flutter_riverpod`, `http`, `intl`이 포함되어 있다
- [ ] Given 프로젝트 루트에서, When `flutter pub get`을 실행하면, Then 에러 없이 성공한다
- [ ] Given `lib/` 디렉토리를, When 탐색하면, Then `app/pages/widgets/features/entities/shared` 6개 폴더가 존재한다
- [ ] Given 프로젝트 루트에서, When `flutter analyze`를 실행하면, Then 경고 0으로 통과한다

### 의존성
없음 (최초 이슈)

---

## 이슈 2 — 공통 에러 타입 + Debouncer + 포맷 유틸

### 설명
여러 화면이 재사용할 도메인 무관 유틸과 공통 에러 타입을 `shared/`에 구현한다.

### 작업 범위
- `shared/error/failure.dart`: `Failure` sealed class + `NetworkFailure`/`ParsingFailure`/`EmptyResultFailure` 3종
- `shared/utils/debouncer.dart`: `Debouncer` 클래스 (`Timer` 기반)
- `shared/utils/number_formatter.dart`: 천 단위 콤마, 한국식 억/조 축약 표기 함수
- `shared/utils/date_formatter.dart`: `yyyyMMdd` ↔ `MM.dd` 변환 (intl 기반)

### Acceptance Criteria
- [ ] Given `Failure` 타입을, When `NetworkFailure()`/`ParsingFailure()`/`EmptyResultFailure()`로 각각 생성하면, Then 모두 `Failure`의 하위 타입으로 타입 검사를 통과한다
- [ ] Given `Debouncer(Duration(milliseconds: 300))`를, When `run()`을 짧은 간격으로 3번 연속 호출하면, Then 마지막 호출의 콜백만 실행된다
- [ ] Given 숫자 `1063000000000`을, When `formatCompactKorean()`(가칭)에 넣으면, Then `1,063조` 형태 문자열을 반환한다
- [ ] Given 숫자 `200000`을, When 천단위 포맷 함수에 넣으면, Then `200,000` 문자열을 반환한다
- [ ] Given 날짜 문자열 `20260911`을, When `yyyyMMdd → MM.dd` 변환 함수에 넣으면, Then `09.11`을 반환한다

### 의존성
이슈 1 (폴더 구조 존재)

---

## 이슈 3 — Navigator 1.0 라우팅 스켈레톤

### 설명
`StartHereScreen`을 제거하고, 관심/검색 탭 전환 + 상세 화면 push가 실제로 동작하는 최소 스켈레톤을 구성한다. 화면 내용은 더미 텍스트로 충분하다(실제 UI는 Phase 3~5).

### 작업 범위
- `pages/watchlist_page.dart`, `pages/search_page.dart`, `pages/stock_detail_page.dart` (더미 콘텐츠)
- `app/root_shell.dart`: `IndexedStack` + `BottomNavigationBar`로 탭 전환 (Riverpod provider로 현재 탭 인덱스 관리)
- `app/main.dart`: `ProviderScope` + `MaterialApp`에서 `RootShell`을 홈으로 연결
- 검색 화면 등에서 종목 탭 시 `Navigator.push(MaterialPageRoute(builder: (_) => StockDetailPage(symbol: ...)))`로 상세 이동

### Acceptance Criteria
- [ ] Given 앱을 처음 실행했을 때, When 화면이 뜨면, Then `StartHereScreen`이 아니라 관심 화면(더미)이 보인다
- [ ] Given 관심 화면이 보이는 상태에서, When 하단 탭의 검색을 누르면, Then 검색 화면(더미)으로 전환된다 (스택이 쌓이지 않고 교체됨)
- [ ] Given 검색 화면에서, When 더미 항목을 탭하면, Then 상세 화면이 push되고 뒤로가기로 검색 화면에 복귀한다
- [ ] Given 상세 화면이 push된 상태에서, When 기기 뒤로가기를 누르면, Then 이전 화면(검색)으로 pop된다

### 의존성
이슈 1 (폴더 구조 존재)

---

## 이슈 4 — ApiClient + Quote Repository(Mock/Network) + 전역 데이터소스 스위치

### 설명
Naver API 호출을 감싸는 `ApiClient`와, Quote 도메인 1개에 대한 Repository 인터페이스·Mock/Network 구현체·전역 스위치를 구성한다. **4개 도메인 전부가 아니라 Quote 1개만** 구현한다(Out of Scope 참고, Phase 1 선점 방지).

### 작업 범위
- `shared/api/api_client.dart`: `http` 기반, 재시도 헬퍼(3회 고정 딜레이) 포함
- `shared/config/data_source_mode.dart`: `DataSourceMode` enum + `dataSourceModeProvider` (기본값 `network`)
- `entities/quote/quote.dart`: `Quote` 모델 (필드는 최소, 실제 파싱은 Phase 1)
- `entities/quote/quote_repository.dart`: 추상 `QuoteRepository` 인터페이스
- `entities/quote/mock_quote_repository.dart`, `network_quote_repository.dart`: 두 구현체 (Network는 실제 파싱 없이 스텁 응답 가능 — 실제 파싱은 Phase 1)
- `entities/quote/quote_providers.dart`: `quoteRepositoryProvider`가 `dataSourceModeProvider`를 `switch`로 참조

### Acceptance Criteria
- [ ] Given `dataSourceModeProvider`가 기본값(`network`)일 때, When `quoteRepositoryProvider`를 읽으면, Then `NetworkQuoteRepository` 인스턴스를 반환한다
- [ ] Given `ProviderScope(overrides: [dataSourceModeProvider.overrideWithValue(DataSourceMode.mock)])`로 실행했을 때, When `quoteRepositoryProvider`를 읽으면, Then `MockQuoteRepository` 인스턴스를 반환한다
- [ ] Given 테스트 코드에서 `quoteRepositoryProvider`만 개별 `overrideWithValue`로 교체했을 때, When 전역 모드가 `network`로 남아있어도, Then 해당 테스트에서는 override한 구현체가 사용된다 (개별 override 우선)
- [ ] Given `ApiClient`로 존재하지 않는 경로에 요청했을 때, When 응답이 실패하면, Then `NetworkFailure`로 변환되어 던져진다

### 의존성
이슈 1, 이슈 2 (`Failure` 타입 필요)

---

## 완료 후 다음 단계

이 4개 이슈가 완료되면 ROADMAP Phase 1(Naver 데이터 계층)로 진입 — Quote 외 3개 도메인(Search/StockMeta/DailyQuote)을 이슈 4와 동일 패턴으로 추가하며 실제 파싱 로직을 구현한다.
