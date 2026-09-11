# project-foundation PRD

## 개요

이든크루 Flutter 과제(관심종목 앱) 구현을 시작하기 전, 화면 3개가 공통으로 딛고 설 **아키텍처 뼈대**를 만든다. `flutter create` 직후 템플릿에 디자인 토큰만 준비된 현재 상태에서, 상태관리·폴더 구조·라우팅·네트워킹·데이터 소스 전환 구조까지 갖춰 이후 각 화면 feature가 바로 붙을 수 있게 하는 것이 목적이다. ROADMAP.md의 Phase 0에 해당한다.

**시간 상한: 4시간.** ROADMAP 1일차(Figma 파악 + Naver API 4개 호출 + DTO/파싱)와 겹치므로, 이 Phase가 4시간을 넘기면 즉시 스코프를 축소한다 — 축소 1순위는 Repository/Mock 스텁 범위(이미 Quote 1개 도메인으로 한정, 필요시 인터페이스 정의만 남기고 구현은 Phase 1로 이월).

## 사용자 스토리

이 Phase 자체는 사용자에게 보이는 기능이 없다(순수 아키텍처). 대신 "다음 개발자(이 프로젝트를 이어받는 사람 또는 평가자)"가 다음을 할 수 있어야 한다:

- 저장소를 클론하고 `flutter pub get; flutter run`을 하면 관심/검색 탭이 전환되고 상세 화면으로 push되는 최소 스켈레톤이 뜬다.
- `lib/` 폴더만 봐도 어디에 무엇을 추가해야 할지(새 화면=`pages`, 새 도메인=`entities`, 새 액션=`features`) 유추할 수 있다.
- Naver 서버가 막혀도 코드 한 줄(`dataSourceModeProvider` 기본값)만 바꾸면 mock 데이터로 개발을 이어갈 수 있다.
- `flutter analyze`가 경고 없이 통과한다.

## 기술 결정

### ADR 1 — 상태관리: Riverpod (수동 provider)

**Context** — 관심 상태를 관심/검색/상세 3화면이 공유해야 하고, 시세·일별시세 조회는 로딩/에러/데이터 3상태를 가지며, 일별 시세는 종목×기간별로 페이지를 캐시·재사용해야 한다. 이 세 가지가 이 과제의 핵심 난이도이자 평가 비중이 높다고 명시된 지점이다.

**Decision** — Riverpod을 채택한다. `ref.watch`의 자동 의존성 추적으로 3화면 동기화를, `AsyncValue`로 로딩/에러/데이터 3상태를, `FutureProvider.family`로 종목×기간별 캐시를 구현한다. 코드 생성(`riverpod_generator`)은 쓰지 않고 수동으로 provider를 선언한다.

**Alternatives**
- *Provider*: 3화면 동기화까지는 가능하나 비동기 3상태·캐싱·파생상태를 전부 수동 구현해야 해 평가 비중이 높은 부분의 코드가 늘어난다.
- *Bloc(full)*: 테스트·구조 강제는 최고지만 이벤트/상태 클래스 계층이 4일·3화면 규모엔 보일러플레이트 과다.
- *GetX*: 서비스 로케이터(`Get.find()`) 기반의 암묵적 동작이 많아 "다른 사람이 이어받을 수 있는 수준"이라는 평가 기준과 상충.
- *코드 생성(riverpod_generator)*: provider 10~15개 규모에서 `build_runner` 상시 실행·생성 파일 리뷰 노이즈 비용이 이점(파라미터 자유도)을 넘어섬. 다중 파라미터는 Dart 3 record로 해결 가능해 이점 자체가 상쇄됨.

**Consequences**
- 장점: 요구사항 대비 코드량이 가장 적고, 평가 문서가 강조하는 지점(비동기 상태, 캐싱)에 라이브러리 기능이 정확히 대응.
- 단점: Provider 생태계 3종(Provider/Notifier/FutureProvider) 개념을 각각 이해해야 하는 러닝커브. 실제 트레이딩(주문·체결) 앱이었다면 감사 추적 관점에서 Bloc이 더 적합했을 것이나, 이 과제는 읽기 전용이라 해당 없음.

---

### ADR 2 — 폴더 구조: FSD(Feature-Sliced Design) 변형

**Context** — 저장소에는 `lib/theme/`만 있고 나머지 구조가 없다. 화면 3개, 도메인 모델 3~4개(Stock/Quote/DailyQuote), 사용자 액션 여러 개(정렬/검색/토글)가 얽히므로 "어디에 무엇을 두는가"가 코드 일관성을 좌우한다.

**Decision** — FSD를 이 프로젝트 규모에 맞게 축약해 적용한다.

```
lib/
  app/        # 진입점, 전역 설정 (main.dart, ProviderScope, go_router 설정)
  pages/      # 라우트 단위 화면 조립
  widgets/    # 여러 feature가 공유하는 복합 UI 블록
  features/   # 사용자 액션 단위
  entities/   # 도메인 모델 + 최소 UI
  shared/     # 도메인 무관 (api, theme 연동, utils, 상수)
```

의존 방향은 상위 → 하위만 허용(`pages`→`widgets/features/entities/shared`, `features`→`entities/shared`, `entities`→`shared`). 역방향 금지.

Util 배치는 "이 함수가 특정 도메인 타입을 알아야 하는가"로 판단한다: 도메인 무관(숫자·날짜 포맷, Debouncer, HTML 디코더)은 `shared/utils/`, 도메인 전용 계산(등락률·시가총액)은 `entities/{도메인}/`, feature 전용 헬퍼(정렬 comparator)는 `features/{기능}/`.

**Alternatives**
- *레이어드 아키텍처(controller/service/repository 수평 분리)*: 파일이 레이어별로 흩어져 "이 화면 하나를 이해하려면 4개 폴더를 오가야" 하는 구조가 됨. FSD는 도메인 중심이라 이 문제를 피함.
- *FSD 원안 그대로(processes 레이어 포함)*: 화면 3개짜리 과제에 과한 세분화.
- *shared/utils에 모든 유틸 집중*: "utils 쓰레기통" 패턴이 되어 도메인 규칙(등락률 계산 등)이 도메인 폴더 밖에 위치하게 됨.

**Consequences**
- 장점: 새 화면/도메인/액션을 추가할 때 어느 레이어에 넣을지 규칙이 명확. 관심 상태 동기화가 `entities/watchlist`라는 단일 지점으로 자연스럽게 귀결.
- 단점: FSD가 원래 프론트엔드(React) 방법론이라 레이어 이름(`entities`, `features`)을 Flutter 관용어(`models`, `providers`)와 다르게 쓰는 데 대한 설명이 필요함(면접에서 대응 가능).

---

### ADR 3 — 라우팅: Navigator 1.0 (순정)

**Context** — 화면은 관심/검색(탭 전환) + 상세(push) 총 3개, 파라미터는 `symbol` 하나, 딥링크·웹 URL 동기화는 요구되지 않는다.

**Decision** — Flutter 순정 Navigator 1.0을 채택한다. 탭 전환은 `IndexedStack` + `BottomNavigationBar`(또는 그 상태를 Riverpod provider로 관리), 상세 화면 이동은 `Navigator.push(MaterialPageRoute(builder: ...))`로 구성한다.

**Alternatives**
- *go_router*: 최초 검토 시 "채용 대상이 프론트엔드 개발자이므로 실무 확장성을 보여준다"는 근거로 채택을 고려했으나, Flutter 전문가·평가자 관점 교차 검증(아래 참고)에서 철회했다. `ShellRoute`+`GoRoute` 2개 구성이 `IndexedStack`+`Navigator.push`보다 코드가 짧지도 안전하지도 않아 이 과제 범위 안에서 실질적 우위가 없고, "실무에서 표준이니까"라는 근거는 이 과제의 실제 요구와 무관한 사후 정당화에 가깝다고 판단했다.

**Consequences**
- 장점: 의존성 0, 학습·설정 비용 없음. "화면 3개, 딥링크 없음, 파라미터 1개 — 이 규모에 맞는 최소 구성을 선택했다"는 설명이 그 자체로 판단력을 보여주는 답이 된다. Phase 0 소요시간을 1.5~2시간 단축.
- 단점: 향후 실제로 딥링크·중첩 라우팅이 필요해지면(이 과제 범위 밖) go_router로 마이그레이션이 필요하다 — 다만 화면 3개 규모에서 그 마이그레이션 비용은 낮다.

> **교차 검증 메모**: 이 ADR은 최초 인터뷰에서 go_router로 확정됐으나, PRD 완성 후 Flutter 전문가 관점과 CEO/평가자 관점 서브에이전트를 실제로 토론시킨 결과 두 관점이 독립적으로 동일한 리스크(오버엔지니어링, 사후 정당화 소지)를 지적하며 수렴해 Navigator 1.0으로 번복했다. 상세 토론 기록은 `interview-notes.md` 참고.

---

### ADR 4 — HTTP 클라이언트: http (Dart 공식 패키지)

**Context** — Naver 4개 endpoint 호출 시 인증·업로드·스트리밍이 없고, 일별 시세는 비UTF-8 HTML을 바이트로 받아 직접 디코딩해야 한다. 새로고침 버튼은 사용자가 누르는 단발 재호출이라 HTTP 레벨 재시도와 무관하며, 페이지네이션(최대 25페이지) 중 일부 실패에 대한 재시도만 실질적으로 유의미하다.

**Decision** — `http` 패키지를 채택한다. 모든 Naver 호출을 `shared/api/ApiClient`로 감싸고, 일별 시세 페이지네이션 재시도(3회, 고정 딜레이)는 `ApiClient` 내부에 직접 구현한다.

**Alternatives**
- *dio*: interceptor·재시도·취소 토큰 등을 내장하지만, 이 4개 endpoint의 실제 요구(인증 없음, 스트림 없음)엔 해당 기능이 발동할 지점이 없음. 페이지네이션 재시도 정도는 `http` 위에 짧은 헬퍼로 대체 가능.

**Consequences**
- 장점: 의존성이 가볍고, `ApiClient`로 감싸두면 추후 요구가 커져 dio로 교체해도 호출부(`entities`/`features`)는 무영향.
- 단점: interceptor 같은 표준화된 부가기능이 없어 로깅·공통 헤더 처리를 `ApiClient` 내부에서 직접 관리해야 함(이 규모에선 문제되지 않음).
- **판단 원칙**: "이 4개 endpoint의 실제 요구가 무엇을 필요로 하는가"로 판단했다. ADR 3(라우팅)도 교차 검증 이후 같은 원칙(이 과제 규모의 실제 요구 기준)으로 재정렬되어, 이제 두 ADR이 서로 다른 기준을 쓰는 문제는 해소됐다.

---

### ADR 5 — mock ↔ network 데이터 소스 전환: 전역 스위치 + Repository override 병행

**Context** — `NAVER_API.md`는 "네트워크가 막힐 때 mock으로 개발을 이어가라"고 명시하며, `assets/mock/`에 응답을 저장해두는 것을 권장한다. 개발 중 이 전환이 빈번할 것으로 예상된다.

**Decision** — `shared/config/`에 `dataSourceModeProvider`(enum `mock`/`network`, 기본값 `network`)를 두고, 모든 도메인 Repository provider가 이 값을 `switch`로 참조해 구현체(`Mock*Repository`/`Network*Repository`)를 스스로 선택한다. 테스트 코드에서는 필요 시 개별 Repository provider를 `overrideWithValue`로 직접 교체하는 것을 병행 허용한다(Riverpod override의 기본 동작이라 별도 설계 불필요).

**Alternatives**
- *안 A(직결형)*: 도메인별 Repository provider를 개별 override. 테스트 시 정밀 제어는 쉬우나, 앱 전체를 mock으로 돌리려면 도메인 수만큼(4개+) override를 나열해야 해 "네트워크 차단 시 즉시 mock 전환" 요구에 불리.
- *안 C(수동 주입형)*: Repository를 `main.dart`에서 만들어 라우트 `builder`로 Page에 직접 전달. FSD가 정한 "Page는 조립만 담당" 원칙과 충돌하고, 라우팅·Riverpod 두 DI 축이 공존해 일관성 저하(이 안은 라우팅을 go_router로 검토하던 시점의 비교이나, Navigator 1.0으로 확정된 이후에도 "Page가 Repository를 직접 안다"는 결함 자체는 동일하게 유효).

**Consequences**
- 장점: "지금 이 빌드가 mock인지 network인지"를 코드 한 줄(`dataSourceModeProvider` 기본값)만 보면 파악 가능. 전체 전환이 1줄 변경. 개별 override도 Riverpod 문법상 자연히 가능해 두 방식이 상충하지 않음.
- 단점: 도메인별 Repository provider마다 `switch` 문이 반복되어 안 A보다 provider 파일이 몇 줄 더 길어짐(새 도메인 추가 시의 자연스러운 비용으로 간주).

### ADR 6 — 공통 에러 타입: `Failure` 3종 최소 정의

**Context** — `AsyncValue.when`의 `error` 콜백에서 무엇을 보여줄지는 화면마다(Phase 3~5) 다를 수 있지만, "에러를 어떻게 분류할지" 자체를 화면마다 각자 정의하면 관심/검색/상세 3화면이 서로 다른 방식으로 네트워크 실패·파싱 실패·빈 응답을 다루게 된다. 이는 Flutter 전문가 교차 검증에서 지적된 갭이다.

**Decision** — `shared/error/failure.dart`에 최소 3종의 공통 에러 타입을 정의한다: `NetworkFailure`(연결 실패/타임아웃), `ParsingFailure`(Naver 응답 파싱 실패 — 특히 일별 시세 HTML), `EmptyResultFailure`(정상 응답이나 빈 데이터). 각 Repository 구현체는 예외를 이 3종 중 하나로 변환해 던지고, Provider의 `AsyncValue.error`가 이를 받아 화면별로 다르게 렌더링한다.

**Alternatives**
- *에러 타입 없이 `Object`/`Exception` 그대로 전파*: 각 feature가 `error is SocketException` 같은 타입 체크를 반복하게 되어 일관성이 깨짐.
- *화면마다 자체 에러 enum 정의*: 관심/검색/상세가 각자 다른 이름·분류 체계를 가지게 되어 "이어받는 사람"이 매번 새로 학습해야 함.

**Consequences**
- 장점: 15분 내외의 낮은 비용으로 Phase 1~5 전체(화면 3개)의 에러 처리 로직 중복을 방지. 코드 리뷰어가 어떤 화면을 보든 같은 에러 분류를 기대할 수 있음.
- 단점: 3종 분류가 이 과제의 모든 실패 케이스를 완벽히 포괄하진 않음 — 필요 시 화면 구현 단계(Phase 3~5)에서 세분화 가능하도록 `Failure`를 sealed class로 열어둔다.

## Out of Scope

- 실제 화면 UI 구현 (관심/검색/상세의 실제 레이아웃·인터랙션) — Phase 3~5에서 별도 feature로 기획.
- Naver 4개 endpoint의 실제 파싱 로직(DTO, HTML 파싱, 인코딩 처리) — Phase 1, 별도 feature.
- 관심 상태 동기화 로직 자체(토글·정렬 등 실제 비즈니스 로직) — Phase 2, 별도 feature. 이 Phase는 Repository 인터페이스와 provider 골격만 준비한다.
- **Repository/Mock 구현체를 4개 도메인(검색/시세/메타데이터/일별시세) 전부 만드는 것** — Quote 도메인 1개만 스켈레톤으로 만들어 패턴을 검증하고, 나머지 도메인은 Phase 1에서 그때그때 동일 패턴으로 추가한다(Phase 0가 Phase 1을 선점하지 않도록 하는 경계).
- `go_router` 등 선언적 라우팅 패키지 도입 — Navigator 1.0으로 충분한 규모라 판단(교차 검증 결과, `interview-notes.md` 참고).
- `riverpod_generator` 등 코드 생성 도구 도입.
- 다크/라이트 테마 전환 — 다크 단일 모드 고정(과제 요구사항).
- 관심 목록 로컬 영속화(재실행 후 유지) — 과제상 선택 항목이며 이 Phase의 범위가 아님.
- CI/CD, 배포 파이프라인 구성.

## 용어 정의

`docs/features/project-foundation/spec-fixed.md`의 "용어 정의" 섹션과 동기화됨: Entity, Feature, Page, ApiClient, Repository, Watchlist.
