# 이슈 4 — 일별 시세 HTML 파싱 + EUC-KR 디코딩 + 페이지 캐시 (DailyQuote)

## 설계 변경 메모

원래 issue-4.md는 "기간 탭(1개월/3개월/6개월/1년)이 요구하는 페이지 수만큼 한 번에 요청"하는 `requiredDays` 방식을 전제로 작성되었으나, **실제 UI는 무한 스크롤로 진행하기로 결정**되어 아래처럼 시그니처를 변경했다.

- `fetchDailyQuotes(symbol, requiredDays)` (한 번에 N일치 요청) → `fetchNextPage(symbol)` (스크롤 시마다 다음 페이지 1개만 요청)
- 캐시는 "이미 받은 페이지"뿐 아니라 "이 symbol을 몇 페이지까지 읽었는지(다음에 가져올 페이지 번호)"까지 함께 관리해야 한다.
- 같은 페이지를 두 번 요청하는 일 자체가 구조상 없으므로("항상 다음 페이지"만 요청), 원래 AC의 "캐시된 페이지는 재요청 안 함" 요구사항은 "같은 symbol로 fetchNextPage를 연속 호출하면 페이지 번호가 순서대로 증가하며 겹치지 않는다"로 재해석했다.
- `lastPage` 초과 방지 로직은 동일하게 유지 — 마지막 페이지를 넘으면 빈 리스트 반환.
- 날짜는 화면에 `MM.dd`(연도 없이)로 표시하지만, **DailyQuote.date 필드 자체는 기존 `DateFormatter`와 호환되는 `yyyyMMdd`(연도 포함)로 내부 저장**한다 — 연도를 지우면 연말/연초 경계에서 정렬이 꼬이고 여러 해에 걸친 데이터에서 날짜가 중복될 수 있어, 저장은 연도 포함 + 표시만 `DateFormatter.internalToDisplay`로 변환하는 기존 패턴을 그대로 따른다.

## 시그니처

```dart
// lib/entities/daily_quote/daily_quote.dart
class DailyQuote {
  const DailyQuote({
    required this.date,        // yyyyMMdd (연도 포함, 내부 저장용)
    required this.closePrice,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.volume,
  });

  final String date;
  final int closePrice;
  final int openPrice;
  final int highPrice;
  final int lowPrice;
  final int volume;
}

// lib/entities/daily_quote/daily_quote_page.dart
class DailyQuotePage {
  const DailyQuotePage({required this.quotes, required this.lastPage});
  final List<DailyQuote> quotes; // 한 페이지(최대 10개), 날짜 역순(최신순)
  final int lastPage;            // 응답에서 추출한 마지막 페이지 번호
}

// lib/entities/daily_quote/daily_quote_repository.dart
abstract interface class DailyQuoteRepository {
  /// symbol의 "다음 페이지"(10거래일)를 가져온다. 이 symbol을 처음 요청하면
  /// 1페이지부터, 이전에 N페이지까지 가져왔다면 N+1페이지를 반환한다.
  /// 이미 lastPage까지 다 가져왔다면 빈 리스트를 반환한다(더 가져올 데이터 없음).
  Future<List<DailyQuote>> fetchNextPage(String symbol);
}

// lib/entities/daily_quote/network_daily_quote_repository.dart
class NetworkDailyQuoteRepository implements DailyQuoteRepository {
  NetworkDailyQuoteRepository(this._apiClient);
  final ApiClient _apiClient;
  // symbol별 캐시 상태(_SymbolCacheState): 받은 페이지들 + 다음에 가져올 페이지 번호 + lastPage
}
```

### HTML 파싱 규칙

- `html` 패키지로 `<tr onMouseOver="mouseOver(this)">` 행만 순회 (구분선/헤더 행 제외)
- 각 행의 `td.num` 6개 중 전일비(2번째)는 스킵하고 종가(1번째)/시가(3번째)/고가(4번째)/저가(5번째)/거래량(6번째) 사용 (`docs/NAVER_API.md` 숫자 순서: 종가, 전일비, 시가, 고가, 저가, 거래량)
- 날짜는 `align="center"` td 안의 `2026.09.11` 형식 → `.` 제거해 `yyyyMMdd`로 정규화
- `lastPage`는 `class="pgRR"` 안의 `<a href=".../sise_day.naver?code=...&page=756">` 에서 `page=(\d+)` 정규식으로 추출 (실측 확인 완료)
- 쉼표 포함 숫자(`259,500`)는 콤마 제거 후 `int.parse`

### 에러 케이스

- 요청 실패 → `NetworkFailure`
- 응답 body 비어있음 → `EmptyResultFailure`
- `<tr>` 행이 0개(파싱 결과 없음) → `EmptyResultFailure`
- `lastPage`를 찾을 수 없음 또는 숫자 파싱 실패 → `ParsingFailure`
- 개별 행의 필드(날짜/가격/거래량) 파싱 실패 → `ParsingFailure`

## 설명

`finance.naver.com/item/sise_day.naver`의 HTML 응답을 `html` 패키지로 파싱하고, EUC-KR 인코딩을 직접 디코딩하며, 페이지네이션(최대 25페이지)을 Repository 단일 레이어 캐시로 재사용 가능하게 구현한다. 이 Phase에서 가장 복잡한 이슈이며 시간 상한을 반드시 지킨다.

## 작업 범위

- `pubspec.yaml`에 `html` 패키지 추가
- `shared/utils/euc_kr_decoder.dart`: `dart:convert`의 `Encoding` 서브클래스로 EUC-KR 디코더 직접 구현 (신규 외부 의존성 없이, 완성형 한글 매핑 테이블 기반)
- `entities/daily_quote/daily_quote.dart`: `DailyQuote` 모델 (`date`, `closePrice`, `openPrice`, `highPrice`, `lowPrice`, `volume`)
- `entities/daily_quote/daily_quote_page.dart`: `DailyQuotePage` (한 페이지 파싱 결과 + `lastPage` 정보)
- `entities/daily_quote/daily_quote_repository.dart`: 추상 인터페이스 (`Future<List<DailyQuote>> fetchDailyQuotes(String symbol, int requiredDays)`)
- `entities/daily_quote/mock_daily_quote_repository.dart`, `network_daily_quote_repository.dart`
  - Network 구현체: `Map<String, Map<int, DailyQuotePage>>` 캐시 전담, 캐시된 페이지 수 확인 → 부족분만 순차 요청 → 병합 반환. `lastPage` 초과 요청 금지
  - HTML 파싱: `html` 패키지로 `<table>` 행 순회, 숫자 순서(`종가, 전일비, 시가, 고가, 저가, 거래량`) 매핑, 날짜는 `DateFormatter.parseInternal` 재사용
- `entities/daily_quote/daily_quote_providers.dart`: `FutureProvider.family<List<DailyQuote>, (String symbol, Period period)>` — Repository 결과를 감싸기만 함(캐시 로직 없음)
- `assets/mock/daily_quote_005930_page1.html`, `daily_quote_005930_page2.html` 저장

## Acceptance Criteria

- [ ] Given EUC-KR로 인코딩된 응답 바이트를, When `euc_kr_decoder`로 디코딩하면, Then 한글이 깨지지 않고 정상 문자열로 변환된다
- [ ] Given 일별 시세 HTML 1페이지를, When `html` 패키지로 파싱하면, Then 10개의 `DailyQuote`가 날짜 역순(최신순)으로 추출된다
- [ ] Given 종목 `005930`에 대해 이미 2페이지(20거래일)가 캐시된 상태에서, When `requiredDays=60`(3개월, 6페이지 필요)으로 다시 요청하면, Then 캐시된 2페이지는 재요청하지 않고 3~6페이지만 추가로 요청한다
- [ ] Given `lastPage=15`인 종목에 대해, When `requiredDays`가 `lastPage`를 초과하는 페이지를 요구하면, Then 16페이지 이상은 요청하지 않고 있는 데이터만 반환한다
- [ ] Given 동일한 `(symbol, period)` 조합으로 `dailyQuoteProvider`를 두 번 연속 watch하면, When 두 번째 호출 시, Then 네트워크 재요청 없이 캐시된 결과를 즉시 반환한다 (Riverpod family 캐시 확인)

## 의존성

이슈 1 (패턴 재사용), 이슈 2의 `shared/utils/date_formatter.dart` 재사용 (Phase 0에서 이미 구현됨)

## 시간 상한

3시간 (EUC-KR 실측 확인 완료로 기존 견적 3~5시간에서 하향). **초과 시 대응**: 캔들차트/일별시세 표는 `MockDailyQuoteRepository`로 유지한 채 즉시 Phase 2로 진행한다.
