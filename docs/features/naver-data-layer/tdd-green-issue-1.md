# TDD Green 계획 — 이슈 1 (StockMeta 도메인)

`test/entities/stock_meta/` 아래 Red 상태인 테스트 4개를 통과시키기 위해 만들 **구현 파일 5개** 계획입니다. 아직 구현 코드는 작성하지 않았습니다. 각 파일의 역할과 핵심 로직만 정리했습니다.

## 만들 파일

### 1. `lib/entities/stock_meta/stock_meta.dart`
issue-1.md에 확정된 시그니처 그대로. `symbol`/`name`/`marketName` 3개 필드를 갖는 불변(`const`) 클래스.

### 2. `lib/entities/stock_meta/stock_meta_repository.dart`
`Future<StockMeta> fetchStockMeta(String symbol)` 한 개 메서드를 가진 추상 인터페이스. `entities/quote/quote_repository.dart`와 동일한 형태(구현 없는 규칙만 정의).

### 3. `lib/entities/stock_meta/mock_stock_meta_repository.dart`
네트워크 호출 없이 고정값(`삼성전자`, `코스피`)을 반환. `mock_quote_repository.dart`와 동일 패턴.

### 4. `lib/entities/stock_meta/network_stock_meta_repository.dart`
실제 구현이 들어가는 핵심 파일. `ApiClient.get()`으로 요청을 보낸 뒤:

1. **응답 body가 비어있으면** → `EmptyResultFailure` 던짐
2. **`jsonDecode`로 JSON 파싱 시도** → 실패(형식이 깨짐)하면 `ParsingFailure`로 변환해 던짐
3. **파싱된 Map에서 `symbolCode`/`stockName`/`stockExchangeNameKor` 3개 키를 꺼냄** → 하나라도 없으면(`null`이면) `ParsingFailure` 던짐
4. **셋 다 있으면** `StockMeta(symbol: ..., name: ..., marketName: ...)`로 변환해 반환

네트워크 요청 자체의 실패(타임아웃, 5xx 등)는 이미 `ApiClient.get()` 안에서 재시도 후 `NetworkFailure`로 던지므로, 이 파일에서 별도로 처리하지 않고 그대로 전파되게 둡니다 (`quote`의 `network_quote_repository.dart`와 동일한 방식 — `on Failure { rethrow; }`).

### 5. `lib/entities/stock_meta/stock_meta_providers.dart`
Riverpod provider 하나. `dataSourceModeProvider` 값에 따라 Mock/Network 구현체를 골라줍니다. `apiClientProvider`는 새로 만들지 않고 `entities/quote/quote_providers.dart`에 이미 있는 것을 그대로 import해서 재사용합니다 (issue-1.md 비고란에 명시된 대로, 중복 정의 방지).

## 진행 방식

시나리오 하나를 통과시킬 때마다 바로 `flutter test`를 돌려서, 의도한 이유로 통과하는지 확인하며 하나씩 진행합니다 (한 번에 5개 파일을 몰아 쓰고 마지막에 한 번만 테스트하지 않습니다).

## 참고 — mock 응답 파일

issue-1.md 작업 범위에 있는 `assets/mock/stock_meta_005930.json`도 함께 생성합니다 (실제 Naver 응답 구조를 가정한 샘플: `symbolCode`, `stockName`, `stockExchangeNameKor` 포함). 이 파일은 지금 당장 테스트 통과에 필수는 아니지만, 이후 개발 중 mock 데이터로 재사용하기 위해 이슈 범위에 포함되어 있으므로 같이 만듭니다.

---

## 실행 결과 (승인 후 구현 완료)

계획대로 파일 5개 + mock JSON 1개를 생성했고, 시나리오 하나씩 만들 때마다 테스트를 돌려 통과를 확인했다.

- `NetworkStockMetaRepository` 구현 중, 테스트 코드의 `http.Response(...)`가 기본적으로 body를 latin1로 인코딩해 한글(`삼성전자`, `코스피`)이 깨지는 문제 발견 → 테스트 코드에 `headers: {'content-type': 'application/json; charset=utf-8'}` 추가로 수정 (구현 버그가 아니라 테스트 코드의 실수였음).

최종 확인:
- `flutter test`: 38개 전체 통과 (기존 21개 + 이번 이슈 12개 + 기존 5개 구성 반영)
- `flutter analyze`: 경고 0건

다음 단계: 커밋 (작업 단위로 분리해서 진행 예정).
