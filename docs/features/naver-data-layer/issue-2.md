# 이슈 2 — 실시간 시세 파싱 완성 (Quote)

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
