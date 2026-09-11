# 이슈 2 — 실시간 시세 파싱 완성 (Quote)

## 시그니처

```dart
// lib/entities/quote/quote.dart
class Quote {
  const Quote({
    required this.symbol,
    required this.currentPrice,
    required this.previousClose,
    required this.open,
    required this.high,
    required this.low,
    required this.volume,
    required this.countOfListedStock,
  });

  final String symbol;
  final int currentPrice;
  final int previousClose;
  final int open;
  final int high;
  final int low;
  final int volume;
  final int countOfListedStock;

  int get changeAmount => currentPrice - previousClose;
  double get changeRate => (currentPrice - previousClose) / previousClose;
  int get marketCap => currentPrice * countOfListedStock;
}
```

### NetworkQuoteRepository.fetchQuotes 파싱 로직

- 응답 JSON: `result.areas[0].datas` 배열을 순회한다고 가정 (실제 Naver realtime API의 알려진 응답 구조)
- 각 항목의 `cd`/`nv`/`pcv`/`ov`/`hv`/`lv`/`aq`/`countOfListedStock`을 `Quote`로 매핑
- 반환값: `Map<String, Quote>` (symbol 기준 키)

### 에러 케이스

- 요청 실패(재시도 후) → `NetworkFailure`
- 응답 body 비어있음 → `EmptyResultFailure`
- `datas` 배열이 비어있음 → `EmptyResultFailure`
- JSON 파싱 실패 또는 개별 항목 필드 누락/타입 불일치 → `ParsingFailure`

## 설명

Phase 0에서 만든 `NetworkQuoteRepository`의 TODO 파싱을 실제 `polling.finance.naver.com/api/realtime` 응답 구조로 채운다. Repository/provider 뼈대는 이미 존재하므로 파싱 로직과 모델 필드 확장만 진행한다.

## 작업 범위

- `entities/quote/quote.dart`: 필드 확장 — `open`, `high`, `low`, `volume`, `countOfListedStock` 추가
- `entities/quote/network_quote_repository.dart`: TODO 파싱 구현
  - 응답 필드 매핑: `cd`→`symbol`, `nv`→`currentPrice`, `pcv`→`previousClose`, `ov`→`open`, `hv`→`high`, `lv`→`low`, `aq`→`volume`, `countOfListedStock`→`countOfListedStock`
  - 등락액 `nv - pcv`, 등락률 `(nv - pcv) / pcv`, 시가총액 `nv × countOfListedStock` 계산 프로퍼티 추가
- `entities/quote/mock_quote_repository.dart`: 확장된 필드에 맞춰 mock 데이터 갱신
- `assets/mock/quote_realtime.json` 저장 (여러 종목 배치 응답)

## Acceptance Criteria

- [ ] Given 관심종목 심볼 리스트(`['005930', '000660']`)로, When `fetchQuotes`를 호출하면, Then **한 번의 HTTP 요청**으로 두 종목의 시세를 모두 조회한다 (개별 호출 금지)
- [ ] Given 응답의 `nv=70000, pcv=70400`일 때, When `Quote.changeAmount`/`changeRate`를 읽으면, Then 각각 `-400`, `약 -0.0057`(퍼센트 변환 전 비율)을 반환한다
- [ ] Given `nv=70000, countOfListedStock=100000000`일 때, When 시가총액을 계산하면, Then `7000000000000`을 반환한다
- [ ] Given 응답 본문이 비어있으면, When `fetchQuotes`를 호출하면, Then `EmptyResultFailure`를 던진다

## 의존성

없음 (Phase 0에서 뼈대 완성, 병렬 진행 가능하나 순서상 이슈 1 다음)

## 시간 상한

1시간

## 테스트 시나리오

### Quote (계산 프로퍼티)

- [정상] `currentPrice=70000, previousClose=70400`일 때 `changeAmount`는 `-400`을 반환해야 한다
- [정상] `currentPrice=70000, previousClose=70400`일 때 `changeRate`는 `약 -0.0057`을 반환해야 한다
- [정상] `currentPrice=70000, countOfListedStock=100000000`일 때 `marketCap`은 `7000000000000`을 반환해야 한다

### NetworkQuoteRepository.fetchQuotes

- [정상] symbols 2개(`['005930','000660']`)로 호출하면 **한 번의 HTTP 요청**으로 두 종목 모두 포함된 `Map<String, Quote>`를 반환해야 한다 (요청 횟수 검증)
- [정상] 응답 항목의 `cd`/`nv`/`pcv`/`ov`/`hv`/`lv`/`aq`/`countOfListedStock`이 각각 `symbol`/`currentPrice`/`previousClose`/`open`/`high`/`low`/`volume`/`countOfListedStock`으로 매핑되어야 한다
- [경계] symbols가 비어있으면 요청 없이 빈 맵을 즉시 반환해야 한다 (기존 동작 유지)
- [경계] 응답 body가 비어있으면 `EmptyResultFailure`를 던져야 한다
- [경계] `datas` 배열이 비어있으면 `EmptyResultFailure`를 던져야 한다
- [예외] 요청이 계속 실패(5xx)하면 재시도 후 `NetworkFailure`를 던져야 한다
- [예외] 응답 항목에 필수 필드(`cd` 등)가 없으면 `ParsingFailure`를 던져야 한다
- [예외] 응답 body가 유효한 JSON이 아니면 `ParsingFailure`를 던져야 한다

### MockQuoteRepository.fetchQuotes

- [정상] 확장된 필드(open/high/low/volume/countOfListedStock)를 포함한 고정 `Quote`를 반환해야 한다

## AC 커버리지 대조

| AC | 커버 시나리오 |
|---|---|
| 관심종목 2개를 한 번의 요청으로 조회 | `NetworkQuoteRepository.fetchQuotes` [정상] (요청 횟수 검증) |
| `changeAmount`/`changeRate` 계산 | `Quote` [정상] 2건 |
| 시가총액 계산 | `Quote` [정상] 1건 |
| 응답 본문 비어있으면 `EmptyResultFailure` | `NetworkQuoteRepository.fetchQuotes` [경계] |

모든 AC가 시나리오로 커버됨을 확인했다.

## 진행 결과 (Red → Green → Format 완료)

- `test/entities/quote/quote_test.dart`(신규), `network_quote_repository_test.dart`(8개로 확장), `mock_quote_repository_test.dart`(신규) 작성 → 전부 Red 확인 → `lib/entities/quote/quote.dart`, `network_quote_repository.dart`, `mock_quote_repository.dart` 구현 → 전부 Green.
- `assets/mock/quote_realtime.json` 추가 (실제 Naver realtime 응답 구조 `result.areas[0].datas[]`를 가정).
- `dart format` 적용.
- 최종 확인: `flutter test` 47개 전체 통과, `flutter analyze` 경고 0건.
- 커밋은 아직 하지 않음 (사용자 요청으로 issue-2~5 전체 완료 후 대기).
