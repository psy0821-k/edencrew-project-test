# project-foundation — 확정 요구사항

인터뷰를 통해 확정된 프로젝트 아키텍처 뼈대(ROADMAP Phase 0)의 요구사항 정리.
각 결정의 상세 근거·비교·반론 대비는 `interview-notes.md` 참고 (커밋 대상 아님, 면접 준비용).

## 용어 정의 (Ubiquitous Language)

| 용어 | 의미 |
|---|---|
| Entity | 여러 화면이 공유하는 도메인 모델과 그 최소 표현 UI (예: Stock, Quote, DailyQuote) |
| Feature | 사용자가 취하는 액션 단위 (관심 등록/해제, 정렬 변경, 검색어 입력) |
| Page | 라우트에 대응하는 화면 조립 단위 (관심/검색/상세) |
| ApiClient | Naver 4개 endpoint 호출을 감싸는 단일 HTTP 게이트웨이 (`shared/api/`) |
| Repository | 도메인별 데이터 접근 인터페이스. Mock/Network 두 구현체를 가짐 |
| Watchlist | 사용자가 등록한 관심 종목 집합. 관심/검색/상세 3화면이 공유하는 단일 소스 |

## 확정된 기술 결정

### 1. 상태관리: Riverpod (수동 provider, 코드생성 미사용)

- 관심 상태 3화면 동기화, 로딩/에러/데이터 3상태(`AsyncValue`), 일별 시세 페이지 캐시(`family`)가 과제의 3대 난이도이며 Riverpod 기능과 1:1 대응.
- `riverpod_generator`/`build_runner`는 이 규모(provider 10~15개)에 이점 대비 비용(빌드 워크플로우, 리뷰 노이즈, 의존성 3개)이 크므로 미채택. 다중 파라미터 `family`는 Dart 3 record 타입으로 해결.

### 2. 폴더 구조: FSD (Feature-Sliced Design) 변형

```
lib/
  app/        # 진입점, 전역 설정 (main.dart, ProviderScope, go_router 설정)
  pages/      # 라우트 단위 화면 조립 (watchlist_page, search_page, stock_detail_page)
  widgets/    # 여러 feature가 공유하는 복합 UI 블록 (토스트, 바텀시트, 스켈레톤)
  features/   # 사용자 액션 단위 (관심 토글, 정렬 변경, 검색어 입력)
  entities/   # 도메인 모델 + 최소 UI (Stock, Quote, DailyQuote + 카드/행)
  shared/     # 도메인 무관 (api 클라이언트, theme 연동, 공용 유틸, 상수)
```

- 의존 방향: 상위 → 하위만 참조 (`pages`→`widgets/features/entities/shared`, `features`→`entities/shared`, `entities`→`shared`). 역방향 금지.
- 화면 3개 규모에 맞춰 FSD 원안의 `processes` 등 세분화 레이어는 축약.

### 3. Util 배치 기준

판단 기준: **"이 함수가 특정 도메인 타입을 알아야 하는가?"**

| 유틸 성격 | 위치 | 예 |
|---|---|---|
| 도메인 무관 순수 함수 | `shared/utils/` | 숫자·날짜 포맷, HTML 인코딩 디코더, Debouncer |
| 특정 도메인 모델 전용 계산 | `entities/{도메인}/` | 등락률·시가총액 계산 |
| 특정 feature 전용 헬퍼 | `features/{기능}/` | 정렬 comparator 3종 |

### 4. 날짜/숫자 포맷: `intl` 패키지

- 천 단위 콤마, `MM.dd`/`yyyyMMdd` 파싱·포맷에 사용. `main()`에서 `initializeDateFormatting('ko_KR')` 초기화.
- 한국식 억/조 축약 표기(`29,113천`, `1,063조`)는 `intl`에 없어 `shared/utils/number_formatter.dart`에 직접 구현.

### 5. Debounce: `Timer` 직접 구현 (패키지 미사용)

- `shared/utils/debouncer.dart`에 `Debouncer` 클래스로 구현. `rxdart`/`easy_debounce` 등 패키지 도입은 불필요.

### 6. 라우팅: `Navigator 1.0` (순정)

- 이 과제 요구사항(탭 2개 + 상세 1단계 push, 딥링크 불필요)에 정확히 맞는 최소 구성. `IndexedStack` + `BottomNavigationBar`로 탭 전환, `Navigator.push(MaterialPageRoute(...))`로 상세 이동.
- **변경 이력**: 최초 인터뷰에서는 "실무 확장성"을 근거로 `go_router`를 채택했으나, PRD 완성 후 Flutter 전문가·CEO 관점 교차 검증에서 두 관점이 독립적으로 "이 과제 범위에서 실질적 우위 없음 + 사후 정당화 소지"를 지적하며 수렴, Navigator 1.0으로 번복 확정. 상세 토론은 `interview-notes.md` 참고.

### 7. HTTP 클라이언트: `http` (Dart 공식 패키지)

- 이 4개 endpoint(인증 없음, 스트림/업로드 없음)엔 `dio`의 핵심 기능(interceptor 체인, FormData, 취소 토큰)이 발동할 지점이 없음.
- 모든 Naver 호출을 `shared/api/ApiClient`로 감싸 추후 `dio` 교체 시 호출부(`entities`/`features`) 무영향 구조로 구성.
- 일별 시세 페이지네이션 재시도는 `ApiClient` 내부에 짧은 헬퍼(3회, 고정 딜레이)로 직접 구현.
- 판단 기준: "이 4개 endpoint의 실제 요구가 무엇을 필요로 하는가" — 라우팅도 교차 검증 이후 같은 기준으로 재정렬되어 두 ADR이 이제 동일한 원칙을 공유.

### 8. mock ↔ network 데이터 소스 전환: 전역 스위치 + Repository override 병행

- `shared/config/`에 `dataSourceModeProvider`(enum `mock`/`network`, 기본값 `network`)를 두고, 모든 도메인 Repository provider가 이 값을 `switch`로 참조.
- 테스트 코드에서는 필요 시 개별 Repository provider를 `overrideWithValue`로 직접 교체하는 것을 병행 허용(Riverpod override의 기본 동작).
- 실제 앱은 Network 기본, 위젯 테스트는 개별 override, 개발 중 Naver 차단 시 `dataSourceModeProvider` 기본값을 `mock`으로 바꿔 즉시 전환 (코드 수정 + 재실행 필요 — 런타임 UI 토글 아님, 컴파일 타임 전환).

### 9. 공통 에러 타입: `Failure` 3종 최소 정의

- `shared/error/failure.dart`에 `NetworkFailure`/`ParsingFailure`/`EmptyResultFailure` 3종을 sealed class로 정의.
- 각 Repository 구현체가 예외를 이 3종으로 변환해 던지고, `AsyncValue.error`가 이를 받아 화면별로 다르게 렌더링.
- 교차 검증에서 지적된 갭 보완 — 화면마다 에러 분류를 각자 정의하는 것을 방지.

## 범위 (ROADMAP Phase 0, 교차 검증 반영)

- 상태관리 도입 (Riverpod)
- FSD 폴더 구조 생성
- `StartHereScreen` 제거, Navigator 1.0 기반 라우팅 뼈대 (관심↔검색 탭, 상세 push)
- `http` 기반 `ApiClient` 준비
- mock/network 전환 구조 (전역 스위치 + Repository override)
- 공통 에러 타입(`Failure` 3종) 정의
- `flutter analyze` 클린 유지

**시간 상한: 4시간.** 초과 시 Repository/Mock 스텁 범위(이미 Quote 1개 도메인 한정)를 인터페이스 정의만 남기고 구현은 Phase 1로 이월.

## 완료(Definition of Done) 기준

- [ ] `pubspec.yaml`에 `flutter_riverpod`, `http`, `intl` 추가 후 `flutter pub get` 성공 (`go_router` 불필요)
- [ ] `lib/` 하위에 `app/pages/widgets/features/entities/shared` 폴더 구조 생성 (최소 placeholder 포함)
- [ ] `StartHereScreen` 제거, `IndexedStack`+`Navigator.push`로 관심↔검색 탭 전환 + 상세 화면 push 스켈레톤 동작 (더미 콘텐츠 허용)
- [ ] `shared/api/ApiClient`(http 기반) 존재, **Quote 도메인 1개만** Repository 인터페이스 + Mock/Network 구현체 스텁 존재
- [ ] `shared/error/failure.dart`에 `Failure` 3종 정의 존재
- [ ] `dataSourceModeProvider` 전환으로 Mock ↔ Network 전환이 실제로 동작함을 확인
- [ ] `flutter analyze` 통과 (경고 0)
- [ ] 전체 소요시간 4시간 이내 (초과 시 위 범위 축소 규칙 적용)

## Out of Scope (이 Phase에서 하지 않음)

- 실제 화면 UI 구현 (Phase 3~5, 개별 feature로 별도 기획)
- Naver 4개 endpoint의 실제 파싱 로직 (Phase 1, 별도 feature)
- 관심 상태 동기화 로직 자체 (Phase 2, 별도 feature — 이 Phase는 구조만 준비)
- **Repository/Mock 구현체를 4개 도메인 전부 만드는 것** — Quote 1개만 스켈레톤, 나머지는 Phase 1에서 동일 패턴으로 추가
- `go_router` 등 선언적 라우팅 패키지 도입 (교차 검증 결과 철회)
- 코드 생성(`riverpod_generator`) 도입
- 다크/라이트 테마 전환 (다크 단일 모드 고정)
