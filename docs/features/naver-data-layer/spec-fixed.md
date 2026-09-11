# naver-data-layer — 확정 요구사항

인터뷰 + Flutter 전문가/CEO 교차 검증을 통해 확정된 Naver 데이터 계층(ROADMAP Phase 1) 요구사항.
Phase 0 산출물(`docs/features/project-foundation/`)의 아키텍처를 그대로 따른다.

## 용어 정의 (Ubiquitous Language)

`project-foundation/spec-fixed.md`의 용어(Entity, Feature, Page, ApiClient, Repository, Watchlist)에 추가:

| 용어 | 의미 |
|---|---|
| StockMeta | 종목명·거래소명 등 기본 정보 (endpoint 3) |
| SearchResult | 검색 결과 1건 (검색 API 필드 + StockMeta 결합) |
| DailyQuote | 하루치 시세(종가/시가/고가/저가/거래량) — 일별 시세 표·캔들차트의 최소 단위 |
| DailyQuotePage | 일별 시세 HTML 응답 1페이지(10거래일) 단위의 원시 파싱 결과 |
| canonical id | 국내 주식 종목을 앱 내부에서 유일하게 식별하는 문자열, `domestic:{symbol}` 형태 |

## 확정된 결정

### 1. 구현 순서

**종목 메타데이터 → 실시간 시세(Quote) → 검색 자동완성 → 일별 시세 HTML**

`NAVER_API.md`가 나열한 순서(검색→시세→메타데이터→일별시세)와 다르다. 메타데이터가 검색·관심·상세 3화면 공통 의존이라 먼저 구현하면 이후 도메인 개발에서 재작업이 없다. Quote는 Phase 0에서 이미 Repository/provider 뼈대가 있어 TODO 파싱만 채우면 된다.

### 2. 검색: 실시간 + 디바운스(필수) + 정규화

- **최근 검색어 기능은 제외** (ASSIGNMENT.md 선택 항목, 미구현)
- **디바운스는 필수로 격상**: 최초 인터뷰에서 선택 항목으로 뒀으나, 실시간 검색 자체가 키 입력마다 API를 호출할 위험이 있고 `NAVER_API.md`가 "호출이 잦으면 차단될 수 있다"고 명시 경고했으므로 필수로 승격.
  - **파라미터**: 300ms 디바운스, **최소 2글자부터** 요청 전송 (1글자는 한글 자모 조합 도중일 가능성이 높아 제외)
  - 기존 `shared/utils/debouncer.dart`의 `Debouncer` 재사용
- **검색어 정규화**: `trim()` + 중간 공백 전부 제거(`RegExp(r'\s+')`)를 아래 두 지점 모두에 동일하게 적용
  - **A. 요청 전처리**: Naver API에 보내기 전 정규화 (`"삼성 전자"` → `"삼성전자"`)
  - **B. 하이라이트 매칭**: `searchHighlight` 렌더링 시 종목명과 정규화된 검색어를 매칭 (검색어에 공백이 섞여도 하이라이트가 정확히 걸리도록)

### 3. 모델 필드 범위 (Phase 3~5 UI 요구사항 역산)

| 모델 | 필드 |
|---|---|
| `StockMeta` | `symbol`, `name`(종목명), `marketName`(거래소명, `stockExchangeNameKor`) |
| `Quote` (Phase 0 기존 필드 확장) | `symbol`, `currentPrice`, `previousClose` + **추가**: `open`, `high`, `low`, `volume`, `countOfListedStock`(시가총액 계산용) |
| `SearchResult` | `symbol`, `name`, `marketName` — 검색 API 응답 + `StockMeta` 결합 |
| `DailyQuote` | `date`, `closePrice`, `openPrice`, `highPrice`, `lowPrice`, `volume` |

### 4. HTML 파싱: `html` 패키지 채택

정규식 대신 Dart 공식 `html` 패키지로 DOM 파싱. 정규식은 마크업의 공백·속성 순서 변화에 취약해 "안정적으로 파싱"이라는 평가 기준(`ASSIGNMENT.md` 중점 확인 포인트)에 불리하다는 데 Flutter 전문가·CEO 양측 이견 없이 승인.

### 5. 인코딩 처리: 실측 확인 결과 EUC-KR 단일 인코딩, 범용 패키지 불필요

최초 인터뷰에서 "EUC-KR인지 CP949인지 확신 없어 범용 `charset` 패키지 채택"으로 결정했으나, 교차 검증 과정에서 **실제로 curl 요청**하여 응답 헤더를 확인:

```
content-type: text/html;charset=EUC-KR
```

**변경**: 범용 `charset` 패키지 도입을 철회하고, **EUC-KR 단일 인코딩 디코더를 `dart:convert`의 `Encoding` 서브클래스로 직접 구현**(20~30줄 규모, 신규 의존성 0개)한다.

> 교훈: "확신이 없으니 범용 도구를 쓴다"는 판단을 미루는 것과 같다는 지적(Phase 0의 go_router 사례와 동일 패턴)을 받아, 결정 전에 반드시 실측 확인을 거쳤다.

### 6. 일별 시세 페이지 캐시: Repository 단일 레이어로 단순화

최초 인터뷰안(Repository 캐시 + Riverpod `family` 캐시의 이중 레이어 결합)은 교차 검증에서 "설명이 정교해질수록 스코프가 커지는 패턴"으로 지적받아 단순화했다.

**확정 구조**:
- `NetworkDailyQuoteRepository`가 종목별·페이지별 캐시를 전담: `Map<String, Map<int, DailyQuotePage>>`
- `fetchDailyQuotes(String symbol, int requiredDays)` 단일 메서드가 "이미 캐시된 페이지 수 확인 → 부족한 페이지만 추가 요청 → 합쳐서 반환"까지 전부 담당
- Riverpod `FutureProvider.family<List<DailyQuote>, (String symbol, Period period)>`는 이 메서드를 호출해 결과를 감싸기만 함 — **캐시 로직을 갖지 않는다**
- `lastPage`보다 큰 페이지 요청 금지, 페이지당 10거래일 가정

이렇게 하면 캐시가 Repository 한 곳에만 존재해 "언제 무효화하는가"(예: 새로고침 시 캐시를 지워야 하는지) 같은 이중 레이어 특유의 질문이 사라진다.

### 7. mock 파일 명명 규칙

```
assets/mock/{도메인}_{설명/종목코드}.{원본 확장자}
```
예: `stock_meta_005930.json`, `quote_realtime.json`, `search_samsung.json`, `daily_quote_005930_page1.html`

### 8. 도메인별 시간 상한 (Phase 0의 "상한 없음 실수" 재발 방지)

최초 인터뷰안("도메인당 순차 진행, 막히면 스킵")은 트리거 없는 모호한 기준이라는 지적을 받아 구체적 상한으로 교체.

| 도메인 | 상한 |
|---|---|
| 종목 메타데이터 | 1시간 |
| 실시간 시세 (Quote TODO 채우기) | 1시간 |
| 검색 자동완성 | 1.5시간 |
| 일별 시세 HTML (인코딩 확인 완료로 단축됨) | 3시간 |
| mock 저장 + 단위 테스트 전체 | 1시간 |
| **합계 상한** | **7.5시간** |

**초과 시 대응**: 일별 시세에서 상한을 넘기면 캔들차트는 임시로 mock 데이터를 반환하는 Repository로 유지하고, 즉시 Phase 2(관심 상태 공유 계층)로 넘어간다 — ASSIGNMENT.md의 "시간이 부족하면 차트를 단순화하고 나머지 필수 항목을 완성하는 편이 낫다"는 명시적 조언과 일치.

## 범위 (ROADMAP Phase 1)

- StockMeta, Quote(파싱 완성), SearchResult, DailyQuote 4개 도메인의 요청·파싱·DTO·모델 연결
- 검색: 실시간 + 디바운스(300ms/2글자) + trim/공백 정규화(요청+하이라이트)
- 일별 시세: EUC-KR 디코딩 + `html` 파싱 + 페이지 캐시(Repository 단일 레이어)
- `assets/mock/`에 4개 도메인 응답 저장
- `flutter analyze` 클린 유지

## 완료(Definition of Done) 기준

- [ ] `entities/stock_meta/`, `entities/search/`, `entities/daily_quote/`에 Phase 0의 Quote와 동일 패턴(모델+Repository 인터페이스+Mock/Network 구현체+provider) 존재
- [ ] `NetworkQuoteRepository`의 TODO 파싱이 실제 `polling.finance.naver.com/api/realtime` 응답 구조로 채워짐 (`nv`/`pcv`/`ov`/`hv`/`lv`/`aq`/`countOfListedStock` 필드 매핑)
- [ ] 검색: 6자리 종목코드만 통과, canonical id `domestic:{symbol}` 생성, trim+공백제거 정규화(요청 전+하이라이트 매칭 양쪽)
- [ ] 일별 시세: EUC-KR 디코더로 한글 정상 표시, `html` 패키지로 표 파싱, `lastPage` 초과 요청 금지, 페이지 캐시로 재요청 방지 확인
- [ ] `assets/mock/`에 4개 도메인 최소 1개씩 응답 저장 및 커밋
- [ ] 각 Repository의 Mock/Network 구현체 단위 테스트
- [ ] `flutter analyze` 통과 (경고 0)
- [ ] 전체 소요시간 7.5시간 이내 (초과 시 위 8번 대응 규칙 적용)

## Out of Scope

- 최근 검색어 기능 (ASSIGNMENT.md 선택 항목)
- 범용 다국어 인코딩 지원 (`charset` 패키지) — EUC-KR 단일 인코딩만 지원
- Riverpod provider 레벨의 캐시 로직 — 캐시는 Repository에만 존재
- 화면 UI 자체 (Phase 3~5, 별도 feature)
- 관심 상태 동기화 로직 (Phase 2, 별도 feature)
