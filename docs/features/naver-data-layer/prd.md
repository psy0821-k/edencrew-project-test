# naver-data-layer PRD

## 개요

ROADMAP Phase 1. Naver 4개 endpoint(종목 메타데이터, 실시간 시세, 검색 자동완성, 일별 시세 HTML)에 대해 요청·파싱·DTO·모델 연결을 구현한다. Phase 0에서 확정된 아키텍처(Riverpod, FSD, `ApiClient`, `Failure` 3종, `dataSourceModeProvider`)를 따르며, Quote 도메인의 뼈대(Phase 0에서 이미 구현)를 기준 패턴 삼아 나머지 3개 도메인(StockMeta, Search, DailyQuote)에 동일하게 복제한다.

## 사용자 스토리

- 관심 화면을 열면 등록된 종목의 현재가·전일대비·종목명·거래소가 표시된다 (Quote+StockMeta 조합).
- 검색창에 종목명을 입력하면(2글자 이상, 입력 멈춘 뒤 300ms) 실시간으로 결과가 뜨고, 검색어와 일치하는 부분이 하이라이트된다. 공백을 넣거나 빼도(`"삼성 전자"`/`"삼성전자"`) 같은 결과가 나온다.
- 상세 화면에서 기간 탭(1개월~1년)을 눌러도, 이미 불러온 기간과 겹치는 부분은 재요청 없이 즉시 표시된다.

## 기술 결정

### ADR 1 — 구현 순서: 메타데이터 → 시세 → 검색 → 일별시세

**Context** — `NAVER_API.md`는 검색→시세→메타데이터→일별시세 순으로 나열하지만, 실제 화면 의존 관계를 보면 메타데이터(`종목명 · 거래소`)가 검색·관심·상세 3화면 모두의 공통 표시 요소다.

**Decision** — 메타데이터를 가장 먼저 구현해 이후 도메인이 이를 재사용하게 한다. Quote는 Phase 0에서 이미 Repository/provider 뼈대가 존재하므로 그다음, 검색은 StockMeta와 결합이 필요해 그다음, 일별시세는 가장 복잡하므로 마지막.

**Alternatives** — `NAVER_API.md` 나열 순서 그대로(검색 먼저): 검색 결과에 종목명을 표시하려면 결국 메타데이터가 먼저 필요해, 순서를 그대로 따르면 검색 도메인 안에서 메타데이터 의존을 임시로 처리했다가 나중에 다시 연결해야 하는 재작업이 생긴다.

**Consequences** — 장점: 재작업 없음. 단점: `NAVER_API.md` 표와 실제 구현 순서가 달라 문서 대조 시 혼동 가능 — 이 PRD에 명시해 완화.

---

### ADR 2 — 검색: 실시간 + 필수 디바운스 + 정규화

**Context** — 검색을 실시간으로 구현하면 키 입력마다 API를 호출할 위험이 있고, `NAVER_API.md`는 "호출이 잦으면 응답이 느려지거나 차단될 수 있다"고 명시 경고한다. 또한 검색어에 공백이 섞여도(`"삼성 전자"`) 결과와 하이라이트가 정확히 동작해야 한다.

**Decision**
- 디바운스 300ms, 최소 2글자부터 요청 (기존 `Debouncer` 재사용)
- 검색어 정규화(`trim` + 중간 공백 전부 제거)를 요청 전처리와 하이라이트 매칭 두 지점에 동일하게 적용
- 최근 검색어 기능은 구현하지 않음 (ASSIGNMENT.md 선택 항목)

**Alternatives**
- *디바운스를 선택 항목으로 유지*: 초기 인터뷰안이었으나, 실시간 검색을 기본 채택한 이상 디바운스 없이는 스스로 API 차단 리스크를 만드는 것과 같아 필수로 격상.
- *정규화를 요청 전처리에만 적용*: 응답 결과(원문 종목명)와 검색어(공백 포함) 사이에 하이라이트 매칭이 깨질 수 있어 두 지점 모두 적용하기로 함.

**Consequences** — 장점: API 호출 폭증 방지, 공백 입력에도 일관된 UX. 단점: 최소 2글자 제약으로 1글자 검색(예: 특정 단일 문자 코드)이 안 되지만, 국내 종목명 특성상 실질적 제약은 미미함.

---

### ADR 3 — HTML 파싱: `html` 패키지

**Context** — 일별 시세(`finance.naver.com/item/sise_day.naver`)는 HTML 테이블로 응답하며, 최대 25페이지까지 반복 파싱해야 한다.

**Decision** — Dart 공식 `html` 패키지로 DOM 파싱한다 (`document.querySelectorAll('table tr')` 방식).

**Alternatives** — 정규식 직접 매칭: 마크업의 공백·속성 순서 변화에 취약해 25페이지 반복 파싱에서 취약점이 누적될 위험. `ASSIGNMENT.md`의 "Naver 데이터를 안정적으로 파싱"이라는 평가 기준에 정규식보다 불리.

**Consequences** — 장점: 파싱 안정성. 단점: 신규 의존성 1개 추가 — 다만 이 작업(HTML 파싱)에 직접 필요한 도구라 Phase 0의 "불필요한 라이브러리 지양" 원칙에 저촉되지 않는다고 판단.

---

### ADR 4 — 인코딩: EUC-KR 단일 디코더 직접 구현 (범용 패키지 도입 철회)

**Context** — `NAVER_API.md`는 "응답 HTML 인코딩이 UTF-8이 아니다"라고만 명시한다. 최초 인터뷰에서는 "EUC-KR인지 CP949인지 확신 없다"는 이유로 범용 `charset` 패키지를 채택했으나, Flutter 전문가·CEO 교차 검증에서 "확신이 없다고 범용 도구를 쓰는 것은 판단을 미루는 것"이라는 지적을 받았다(Phase 0의 go_router 사례와 동일 패턴).

**Decision** — 실제로 `curl -I https://finance.naver.com/item/sise_day.naver?code=005930&page=1`로 응답 헤더를 확인한 결과 `content-type: text/html;charset=EUC-KR`이 명시됨을 확보했다. 이에 따라 범용 `charset` 패키지 도입을 철회하고, EUC-KR 단일 인코딩을 `dart:convert`의 `Encoding` 서브클래스로 직접 구현한다(약 20~30줄).

**Alternatives**
- *`charset` 패키지(다국어 지원)*: 실측 결과 불필요한 범용성 — 철회.
- *`cp949_codec` 패키지(단일 인코딩 전용)*: 실측으로 EUC-KR이 명확히 확인된 이상, 이마저도 불필요한 의존성 추가.

**Consequences** — 장점: 신규 의존성 0개, 실측 근거로 확신 있는 선택. 단점: EUC-KR 인코딩 테이블을 직접 구현/검증하는 초기 비용이 있으나, EUC-KR은 표준 규격이라 완성형 한글 2,350자 매핑 테이블만 필요해 범위가 명확하다.

---

### ADR 5 — 일별 시세 캐시: Repository 단일 레이어

**Context** — 일별 시세는 종목×기간별로 최대 25페이지까지 이어받고, 이미 받은 페이지는 재사용해야 한다(`NAVER_API.md`가 "비중 있게 본다"고 명시). 최초 인터뷰안은 "Repository 내부 캐시 + Riverpod `family` 캐시"의 이중 레이어 결합이었으나, 교차 검증에서 "설명이 정교해질수록 스코프가 커지는 패턴"으로 지적받았다.

**Decision** — 캐시를 Repository 한 곳에만 둔다. `NetworkDailyQuoteRepository`가 `Map<String, Map<int, DailyQuotePage>>`(종목별·페이지별)로 캐시를 관리하고, `fetchDailyQuotes(symbol, requiredDays)` 단일 메서드가 "캐시 확인 → 부족분만 요청 → 병합 반환"을 전담한다. Riverpod `FutureProvider.family`는 이 메서드를 감싸기만 하며 캐시 로직을 갖지 않는다.

**Alternatives** — 이중 레이어(Repository+Riverpod family) 결합: 캐시가 두 곳에 존재해 "새로고침 시 어느 캐시를 지워야 하는가" 같은 질문이 새로 생기고, 이 4일 과제에서 캐시 재사용의 실제 평가 기여("탭 전환 시 재요청 안 함" 체감 수준)에 비해 설계 비용이 과함.

**Consequences** — 장점: 캐시 소유권이 명확(Repository 하나), 무효화 시점 질문이 발생하지 않음. 단점: Repository가 상태(mutable Map)를 가지게 되어 순수 함수형 스타일에서는 벗어나지만, Repository는 원래 부수효과(네트워크 I/O)를 다루는 계층이라 상태를 갖는 것이 자연스럽다.

---

### ADR 6 — 도메인별 시간 상한 (Phase 0 교훈 재적용)

**Context** — 최초 인터뷰안("도메인당 순차 진행, 막히면 스킵")은 "막히면"의 판단 기준이 없어 무한정 시도로 이어질 위험이 있다고 CEO·Flutter 전문가 양측에서 지적받았다. Phase 0에서 이미 "시간 상한 부재 = 첫 감점 포인트"라는 교훈을 얻은 바 있다.

**Decision** — 도메인별 구체적 시간 상한을 설정한다: 메타데이터 1시간, 시세 1시간, 검색 1.5시간, 일별시세 3시간(EUC-KR 실측 확인으로 리스크 축소되어 기존 견적 3~5시간에서 하향), mock+테스트 1시간 = 합계 7.5시간. 일별 시세에서 초과 시 캔들차트는 mock 데이터로 유지하고 즉시 Phase 2로 진행한다.

**Alternatives** — Phase 0처럼 전체 단일 상한(예: 8시간): 이 Phase는 도메인마다 성격이 달라(단순 JSON vs 복잡한 HTML 파싱) 단일 상한보다 도메인별 배분이 병목 지점을 더 명확히 드러낸다.

**Consequences** — 장점: ASSIGNMENT.md의 "시간 부족하면 단순화하고 필수만 완성"이라는 명시적 조언과 정확히 일치하는 대응 규칙. 단점: 각 도메인 상한이 견적이라 실제로는 ±30분 정도 오차 가능 — 초과 시 즉시 판단하되 아주 근소한 초과는 유연하게 허용.

## Out of Scope

- 최근 검색어 기능 (ASSIGNMENT.md 선택 항목)
- 범용 다국어 인코딩 지원 — EUC-KR 단일 인코딩만
- Riverpod provider 레벨 캐시 로직 — 캐시는 Repository에만 존재
- 관심 화면·검색 화면·상세 화면의 실제 UI (Phase 3~5, 별도 feature)
- 관심 상태 동기화 로직 자체 (Phase 2, 별도 feature) — 이 Phase는 데이터 계층만
- 입력값 검증 UI(에러 메시지 등) — 이 Phase는 `Failure` 타입 변환까지, 화면 표시는 Phase 3~5

## 용어 정의

`spec-fixed.md`의 "용어 정의" 섹션과 동기화됨: StockMeta, SearchResult, DailyQuote, DailyQuotePage, canonical id.
