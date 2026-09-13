# stock-detail-screen — 초기 정의서 (spec-original)

## 배경

과제 1의 세 번째 화면(`03 · 종목상세`). ASSIGNMENT.md와 Figma 시안(사용자 제공 스크린샷) 기준.

현재 `lib/pages/stock_detail_page.dart`는 Phase 0에서 만든 라우팅 검증용 더미 화면이다
(뒤로가기 + `종목상세 · {symbol}` 타이틀 + 심볼 텍스트만 표시).

## Figma 시안 (사용자 제공 이미지 기준)

- 헤더: 뒤로가기(`←`) / 종목명(`삼성전자`) 위 + `종목코드 · 시장`(`005930 · 코스피`) 아래 / 우측 별 아이콘(관심 등록)
- 현재가 크게(`179,700`) + 등락 방향 아이콘(▼) + 등락액/등락률(`400 (-0.22%)`, 파랑=하락)
- 기간 탭 4개: `1개월`(선택 상태, 보라 배경 pill) / `3개월` / `6개월` / `1년`
- 캔들 차트 (빨강=상승, 파랑=하락, 세로 막대형 캔들)
- 요약 카드 2행 3열/2열: `시가`/`고가`/`저가`, `거래량`/`시가총액`
- `일별 시세` 표: 컬럼 `날짜`(MM.DD) / `종가` / `등락`(부호+색) / `거래량`, 5행 정도 노출

## ASSIGNMENT.md 요구사항 (필수)

- 상단에 뒤로 가기, 종목명, `종목코드 · 시장`, 관심 등록 버튼
- 현재가와 전일 대비 등락을 크게 표시, 등락 방향 아이콘(▲/▼)
- 기간 탭 `1개월`/`3개월`/`6개월`/`1년`이 **모두 동작**해야 함. 선택 탭은 `accentDefault`/`accentBg` 스타일. 탭 전환 시 차트·표 기간 변경
- 캔들 차트 (상승/하락 `chartLineUp`/`chartLineDown`). 기간에 맞는 캔들이 그려지면 필수 충족(내부 렌더링 디테일은 감점 없음)
- 요약 카드: `시가`/`고가`/`저가`/`거래량`/`시가총액` (거래량·시총 축약 표기: `29,113천`, `1,063조`)
- 일별 시세 표: 컬럼 `날짜`(MM.DD)/`종가`/`등락`(부호+색)/`거래량`

## ASSIGNMENT.md 요구사항 (선택)

- 차트 축 라벨, 거래량 바 (`chartAxisLabel`, `chartVolumeBar`)
- 차트 영역 채우기 (`chartAreaUp`, `chartAreaDown`)
- 차트 터치 시 크로스헤어/툴팁
- **일별 시세 표의 무한 스크롤**
- 차트 전환 애니메이션

## 상태 동기화 (전체 필수, 이 화면 관련 부분)

- 상세 화면에서 관심을 해제하고 돌아오면 관심 목록에도 반영되어야 한다
- 관심 상태가 바뀌면 관심/검색/상세 화면의 별 아이콘이 모두 함께 바뀐다

## 기존 코드 자산 (재사용 대상)

이미 Phase 1에서 데이터 계층이 구현되어 있다.

- `lib/entities/daily_quote/`: `DailyQuote`(날짜·종가·시가·고가·저가·거래량), `DailyQuoteRepository`(Mock/Network), `daily_quote_providers.dart`
- `lib/entities/quote/`: `Quote`(현재가·전일종가·시가/고가/저가·거래량·상장주식수), `changeAmount`/`changeRate`/`marketCap` getter
- `lib/entities/stock_meta/`: `StockMeta`(종목명·거래소명), `CachingStockMetaRepository`(symbol별 캐싱)
- `lib/entities/watchlist/watchlist_providers.dart`: `isFavoriteProvider(symbol)`, `watchlistProvider.toggleFavorite`
- `lib/shared/utils/price_change_formatter.dart`: 등락 색상/부호 포맷 (관심 화면과 공유 예정, ROADMAP에 명시됨)
- `lib/shared/utils/number_formatter.dart`: 숫자 콤마 포맷
- `lib/theme/`: `chartLineUp`/`chartLineDown`/`chartAreaUp`/`chartAreaDown`/`chartBaseline`/`chartAxisLabel`/`chartVolumeBar`/`accentDefault`/`accentBg` 등 차트·탭 전용 토큰 이미 준비됨

## ⚠️ 알려진 설계 불일치 — 인터뷰에서 반드시 다룰 것

`DailyQuoteRepository.fetchNextPage(symbol)`은 Phase 1에서 "무한 스크롤" 전제로 설계되어
**"다음 페이지 1개만" 순차적으로 가져오는 시그니처**다(`requiredDays`나 `period` 파라미터가 없음).

그런데 ASSIGNMENT.md는 **기간 탭 전환이 필수**이고 **무한 스크롤은 선택**이다. 즉 지금 있는
Repository 시그니처만으로는 필수 요건(기간 탭)을 자연스럽게 구현하기 어렵다.

→ 사용자와 상의 결과: **Repository 시그니처를 기간 탭 기준으로 다시 설계**하기로 결정.
(무한 스크롤 전용 `fetchNextPage`는 폐기하거나, 기간 조회 위에 선택적으로 얹는 방식 중 인터뷰에서 결정)

## 아직 정해지지 않은 것 (인터뷰에서 확정)

- Repository 시그니처를 어떻게 바꿀지 (기간→거래일수 매핑, 페이지 캐시를 그대로 살릴지)
- 캔들 차트를 패키지로 그릴지 `CustomPainter`로 직접 그릴지
- 요약 카드 축약 표기(`29,113천`, `1,063조`) 규칙을 어디에 둘지(포맷터 유틸)
- 등락 아이콘/색상을 관심 화면과 얼마나 공유할지
