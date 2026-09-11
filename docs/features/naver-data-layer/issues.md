# naver-data-layer — 이슈 분해

PRD(`prd.md`) 기준. 각 이슈는 `issue-{N}.md`로 개별 저장. 도메인별 시간 상한 합계 7.5시간(ADR 6).

## 이슈 목록

| # | 제목 | 파일 | 시간 상한 | 의존성 |
|---|---|---|---|---|
| 1 | 종목 메타데이터 도메인 (StockMeta) | [issue-1.md](issue-1.md) | 1시간 | 없음 |
| 2 | 실시간 시세 파싱 완성 (Quote) | [issue-2.md](issue-2.md) | 1시간 | 없음 (Phase 0 뼈대 재사용) |
| 3 | 검색 자동완성 + 실시간 디바운스 검색 (Search) | [issue-3.md](issue-3.md) | 1.5시간 | #1 |
| 4 | 일별 시세 HTML 파싱 + EUC-KR + 페이지 캐시 (DailyQuote) | [issue-4.md](issue-4.md) | 3시간 | #1, #2 |
| 5 | mock 자산 정리 + 전체 검증 | [issue-5.md](issue-5.md) | 1시간 | #1, #2, #3, #4 |

## 의존성 순서

```
#1 (StockMeta) ─┬─→ #3 (Search)
                └─→ #4 (DailyQuote, #2와 함께)
#2 (Quote)      ───→ #4 (date_formatter 재사용)

#1, #2, #3, #4 완료 ─→ #5 (검증)
```

`#1`과 `#2`는 서로 독립적이라 병렬 진행 가능하나, PRD ADR 1(구현 순서)에 따라 순차 진행을 기본으로 한다.

## 수직 슬라이스 확인

이 Phase는 화면 UI가 없는 데이터 계층이라 "사용자 관찰 가능 결과" 대신 project-foundation과 동일하게 "다음 이슈가 검증 가능한 상태" + "단위 테스트로 즉시 확인 가능한 동작"을 기준으로 삼았다. 각 이슈는:
- 독립적으로 `flutter test`를 돌려 통과 여부를 확인할 수 있고
- Mock/Network 구현체가 완결된 상태로 다음 이슈가 그 결과(StockMeta, Quote)를 재사용할 수 있다.

수평 슬라이싱(예: "4개 도메인의 모델만 먼저, 그다음 Repository만 전부") 대신 도메인별 수직 완결(모델+Repository+Mock+Network+provider+테스트)로 나눴다.

## 시간 상한 초과 시 대응

PRD ADR 6 참고. 이슈 4(일별 시세)에서 초과 시 `MockDailyQuoteRepository`로 유지한 채 이슈 5로 건너뛰고, Phase 2(관심 상태 공유 계층)로 진행한다.
