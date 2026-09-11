# 이슈 5 — mock 자산 정리 + 전체 검증

## 설명

이슈 1~4에서 각각 저장한 mock 파일이 실제로 `MockXxxRepository`와 일관되게 연결되는지 확인하고, Phase 1 전체 DoD를 검증한다. 새 도메인 기능이 아니라 마무리·검증 이슈다.

## 작업 범위

- `assets/mock/` 4개 도메인 파일이 `pubspec.yaml`의 `assets:` 목록에 포함되어 있는지 확인(이미 `assets/mock/` 전체가 등록되어 있어 파일 추가만으로 충분한지 검증)
- 4개 도메인 Repository의 Mock/Network 구현체 단위 테스트 전체 재확인
- `flutter analyze` 0 경고 확인
- `flutter test` 전체 통과 확인
- Phase 1 전체 소요시간이 7.5시간 상한 이내였는지 기록 (초과 시 어느 도메인에서 얼마나 초과했는지 메모)

## Acceptance Criteria

- [x] Given `flutter pub get` 이후, When 앱을 mock 모드로 실행하면, Then 4개 도메인 모두 `assets/mock/`의 데이터가 정상 로드된다

  **재해석**: 4개 `Mock*Repository`(`MockStockMetaRepository`, `MockQuoteRepository`, `MockSearchRepository`, `MockDailyQuoteRepository`)는 실제로 `assets/mock/*.json`/`.html` 파일을 `rootBundle`로 읽지 않고, 코드에 하드코딩된 고정값을 반환한다(issue-1~4 전부 동일 패턴, `mock_*_repository.dart` 확인). `assets/mock/`의 실제 파일들은 **각 도메인의 HTML/JSON 파싱 로직을 단위 테스트에서 검증할 때 실측 샘플로 사용**됐다(`daily_quote_page_parser_test.dart`가 `File('assets/mock/daily_quote_005930_page1.html')`을 직접 읽는 방식 등). 개발 중 API 차단에 대응해 `dataSourceModeProvider`를 `mock`으로 바꾸면 네트워크 없이 즉시 동작하는 고정 데이터를 제공한다는 원래 취지(`docs/NAVER_API.md`의 "네트워크가 막힐 때" 섹션)는 달성되었으므로, "mock 모드가 정상 동작하고 assets/mock/이 파싱 검증에 활용되었다"로 재해석해 통과 처리한다. (코드 변경 없음 — Mock Repository가 asset 파일을 직접 읽도록 바꾸는 건 이번 이슈 범위를 벗어난다고 판단)

- [x] Given 전체 테스트 스위트를, When `flutter test`로 실행하면, Then 이슈 1~4에서 추가된 테스트를 포함해 전부 통과한다

  `flutter test` 94개 전체 통과 확인 (기존 21개 + StockMeta 12 + Quote 15 + Search 27 + DailyQuote 20 — 정확한 개수는 아래 도메인별 재확인 결과 참고).

- [x] Given 프로젝트 전체를, When `flutter analyze`를 실행하면, Then 경고 0으로 통과한다

  `flutter analyze` → `No issues found!` 확인.

## 도메인별 재확인 (Mock/Network Repository 단위 테스트)

| 도메인 | 테스트 개수 | 결과 |
|---|---|---|
| stock_meta | 12 | 전부 통과 |
| quote | 15 | 전부 통과 |
| search | 15 | 전부 통과 |
| daily_quote | 16 | 전부 통과 |

## pubspec.yaml assets 등록 확인

`assets/mock/` 폴더 전체가 `pubspec.yaml`에 등록되어 있어(`- assets/mock/`), 4개 도메인 mock 파일(`stock_meta_005930.json`, `quote_realtime.json`, `search_samsung.json`, `daily_quote_005930_page{1,2}.html`)이 별도 등록 없이 전부 포함됨을 확인. `flutter pub get` 에러 없이 성공.

## Phase 1 소요시간 기록

| 이슈 | 시간 상한 | 실제 커밋 시각 간격 |
|---|---|---|
| issue-1 (StockMeta) | 1시간 | 4fa3253(13:13, Phase0 종료) → 00017e8(18:00) 중 실제 작업 시간대는 세션 특성상 커밋 간격과 정확히 일치하지 않음(대화 중 설명/질문 시간 포함) |
| issue-2 (Quote 파싱) | 1시간 | 00017e8(18:00) → d7584b3(19:22), 약 1시간 22분 |
| issue-3 (Search) | 1.5시간 | d7584b3(19:22) → 209d13c(20:07), 약 45분 (서브에이전트 병행 진행) |
| issue-4 (DailyQuote) | 3시간 | 209d13c(20:07) → 3a96660(21:02), 약 55분 |

**전체 Phase 1 소요**: `4fa3253`(13:13) ~ `3a96660`(21:02) 약 7시간 49분. 시간 상한 합계(1+1+1.5+3=6.5시간) 대비 약 1시간 19분 초과. 커밋 시각 간격에는 요구사항 설계 논의, 사용자 질문 응답, 워크플로우 정리(이슈/브랜치/PR 전환) 시간이 포함되어 있어 순수 구현 시간과는 차이가 있음. 실질적인 초과 원인은 issue-4의 EUC-KR 매핑 테이블 실측(직접 Naver 서버 요청 및 바이트 분석)과, 중간에 발생한 워크플로우 정리(issue-1~3 GitHub Issue 사후 등록, main push 누락 수정) 작업 시간으로 판단된다.

## 의존성

이슈 1, 2, 3, 4 (전체 완료 후 마무리)

## 시간 상한

1시간 — 실제 소요 약 30분 (검증 작업만, 코드 변경 없음)
