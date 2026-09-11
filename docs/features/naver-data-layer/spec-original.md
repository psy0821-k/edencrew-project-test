# naver-data-layer — 초기 아이디어

## 무엇을

ROADMAP.md Phase 1. Naver 4개 endpoint(검색 자동완성, 실시간 시세, 종목 메타데이터, 일별 시세 HTML)에 대해 **요청 → 파싱 → DTO → 앱 모델 연결**을 구현한다. `NAVER_API.md`가 규정하는 4개 endpoint 모두 필수다.

## 포함 범위 (ROADMAP Phase 1)

- endpoint 1 · 검색 자동완성 (`ac.stock.naver.com/ac`) — 국내 주식만, 6자리 코드만, canonical id `domestic:{symbol}`
- endpoint 2 · 실시간 시세 (`polling.finance.naver.com/api/realtime`) — 관심종목 1회 일괄 조회, 등락액/등락률/시가총액 계산. **Quote 도메인 뼈대는 Phase 0에서 이미 구현됨** (`NetworkQuoteRepository`의 TODO 파싱만 채우면 됨)
- endpoint 3 · 종목 메타데이터 (`stock.naver.com/api/securityFe/api/fchart/domestic/stock/{symbol}`) — 종목명, 거래소명
- endpoint 4 · 일별 시세 HTML (`finance.naver.com/item/sise_day.naver`) — 비UTF-8 디코딩, HTML 파싱, 페이지네이션(최대 25페이지) 캐시 재사용
- 응답 mock을 `assets/mock/`에 저장

## 제약 / 전제

- Phase 0에서 확정된 아키텍처를 따른다: FSD 폴더 구조, `entities/{도메인}/`에 모델+Repository+Mock/Network 구현체+provider, `ApiClient`(http 기반, 재시도 포함), `Failure` 3종, `dataSourceModeProvider` 전역 스위치
- Quote 도메인은 이미 존재 — 나머지 3도메인(Search, StockMeta, DailyQuote)을 동일 패턴으로 신규 생성
- "요청, 파싱, DTO 작성, 모델 연결은 직접 구현" — 4가지 모두 필수 (`NAVER_API.md` 명시)
- 페이지 요청은 필요한 만큼만 하고 캐시 재사용 (평가 비중 높음 — `NAVER_API.md`, `docs/ASSIGNMENT.md` 공통 강조)
- 네트워크가 잦은 호출로 차단될 수 있음 → mock 저장 권장
- 4일 중 1일차 분량으로 예정되어 있었음 (ROADMAP 원안) — Phase 0에 예상보다 시간을 더 썼으므로 일정 재확인 필요

## 확정 필요 (인터뷰 대상)

- 4개 endpoint 구현 순서 (의존성 있는지, 병렬 가능한지)
- 각 도메인의 모델 필드를 어디까지 최소화할지 (Phase 3~5 UI 요구사항 역산 필요한지)
- HTML 파싱 방식 (정규식 vs HTML 파서 패키지)
- 비UTF-8 인코딩을 구체적으로 어떻게 처리할지 (어떤 인코딩인지 확인 필요)
- 페이지 캐시를 어느 레이어에 둘지 (Repository 내부 메모리 캐시 vs Riverpod provider 캐시)
- mock 파일을 어떤 형식/이름으로 `assets/mock/`에 저장할지
- 이 Phase의 "완료" 판정 기준과 시간 상한
