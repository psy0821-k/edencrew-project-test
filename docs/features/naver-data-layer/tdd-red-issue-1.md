# TDD Red 계획 — 이슈 1 (StockMeta 도메인)

이 문서는 `docs/features/naver-data-layer/issue-1.md`에 확정된 시나리오를 실제 **테스트 파일**로 어떻게 옮길지 미리 정리한 계획서입니다. 아래 내용을 확인해주시면 그에 맞춰 테스트 코드(.dart)를 작성합니다. (아직 테스트 코드는 작성하지 않았습니다.)

## 원칙

- 이 단계에서는 **테스트 코드만** 작성합니다. `lib/` 아래 실제 구현 코드는 절대 만들지 않습니다.
- 따라서 아래 테스트들은 실행하면 전부 "구현이 없어서" 실패(컴파일 에러)하는 게 **정상**입니다. 이걸 Red 상태라고 부릅니다.
- 기존 `entities/quote/` 도메인의 테스트 파일(`test/entities/quote/network_quote_repository_test.dart`, `quote_providers_test.dart`) 스타일을 그대로 따릅니다.

## 작성할 파일 4개와 각 파일의 테스트 목록

### 1. `test/entities/stock_meta/stock_meta_test.dart`
`StockMeta` 모델이 생성자로 받은 값을 그대로 저장하는지 확인.
- symbol, name, marketName을 넣어 생성하면 각 필드에 그대로 저장된다

### 2. `test/entities/stock_meta/network_stock_meta_repository_test.dart`
실제 네트워크 응답을 가정한 가짜(Mock) HTTP 응답으로 `NetworkStockMetaRepository`를 검증. (`http/testing.dart`의 `MockClient`로 실제 서버 호출 없이 테스트)
- 응답 JSON에 3개 필드(`symbolCode`/`stockName`/`stockExchangeNameKor`)가 모두 있으면 `StockMeta`로 정확히 매핑됨
- 응답 본문이 비어있으면 `EmptyResultFailure`
- 서버가 계속 실패(500)하면 재시도 후 `NetworkFailure`
- `symbolCode` 누락 → `ParsingFailure`
- `stockName` 누락 → `ParsingFailure`
- `stockExchangeNameKor` 누락 → `ParsingFailure`
- 응답이 JSON 형식이 아님 → `ParsingFailure`

### 3. `test/entities/stock_meta/mock_stock_meta_repository_test.dart`
개발/테스트용 가짜 구현체 `MockStockMetaRepository` 검증.
- 아무 symbol로 호출해도 고정된 `StockMeta`(넣은 symbol 포함)를 반환

### 4. `test/entities/stock_meta/stock_meta_providers_test.dart`
Riverpod provider `stockMetaRepositoryProvider`가 설정에 따라 올바른 구현체를 고르는지 검증.
- 기본값(`network`)일 때 `NetworkStockMetaRepository` 반환
- `mock`으로 바꾸면 `MockStockMetaRepository` 반환
- provider 자체를 직접 override하면 그 값이 우선

## AC 대조 (issue-1.md 4개 AC 모두 커버)

| issue-1.md AC | 커버하는 테스트 |
|---|---|
| 필드 매핑 정확성 | 2번 파일 - 정상 케이스 |
| mock 모드일 때 MockRepository 반환 | 4번 파일 - mock override 케이스 |
| API 실패 시 NetworkFailure | 2번 파일 - 서버 500 케이스 |
| 필드 누락 시 ParsingFailure | 2번 파일 - 필드 누락 3케이스 |

---

## 실행 결과 (승인 후 작성 완료)

`flutter test test/entities/stock_meta/` 실행 결과: **4개 파일 모두 실패(Red) 확인됨.**

모든 실패는 `lib/entities/stock_meta/` 구현 파일이 아직 없어서 나는 컴파일 에러(`Error when reading '...': 지정된 경로를 찾을 수 없습니다`, `Method not found`)이며, 테스트 코드 자체의 오타나 실수로 인한 실패가 아님을 확인했다.

기존 테스트(21개, `test/entities/quote/` 등)는 영향받지 않고 그대로 통과 중.

다음 단계: TDD Green — `lib/entities/stock_meta/` 아래 실제 구현 코드 작성.
