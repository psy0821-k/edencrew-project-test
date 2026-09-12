# watchlist-sync — 이슈 분해

PRD(`prd.md`) 기준. 각 이슈는 `issue-{N}.md`로 개별 저장.

## 이슈 목록

| # | 제목 | 파일 | 의존성 |
|---|---|---|---|
| 1 | Watchlist 도메인 + LocalWatchlistRepository (SharedPreferences 영속화) | [issue-1.md](issue-1.md) | 없음 |
| 2 | WatchlistItem 조합 provider (Quote/StockMeta 결합) | [issue-2.md](issue-2.md) | #1 |
| 3 | 관심목록 정렬 (SortCriteria + comparator) | [issue-3.md](issue-3.md) | #2 |
| 4 | main() 초기화 배선 + 전체 검증 | [issue-4.md](issue-4.md) | #1, #2, #3 |

## 의존성 순서

```
#1 (Watchlist Repository) ─→ #2 (WatchlistItem 조합) ─→ #3 (정렬)
#1, #2, #3 완료 ─→ #4 (main() 배선 + 검증)
```

## 수직 슬라이스 확인

- **#1**: `toggleFavorite`/`isRegistered` 등 Repository 동작을 단위 테스트로 즉시 확인 가능. 앱을 재시작해도(SharedPreferences 목킹으로) 상태가 유지되는지 검증 가능한 완결 단위.
- **#2**: `watchlistItemsProvider`가 실제로 Quote/StockMeta를 결합해 `WatchlistItem` 목록을 만드는지, `isFavoriteProvider(symbol)`가 토글에 반응해 갱신되는지 테스트로 확인 가능한 완결 단위.
- **#3**: `sortWatchlistItems`가 3가지 기준으로 올바르게 정렬하고 시세 미수신 항목을 최하단으로 보내는지 순수 함수 테스트로 확인 가능한 완결 단위.
- **#4**: 앱을 `flutter run`으로 띄웠을 때 SharedPreferences 사전 로드가 실제로 동작하는지, `flutter analyze`/`flutter test` 전체가 통과하는지 확인하는 마무리 단위.

수평 슬라이싱(모델만 먼저, provider만 전부, UI만 전부) 대신 도메인 단위 수직 완결로 나눴다 — naver-data-layer와 동일한 방식.

## 시간 상한

PRD에 별도 ADR로 시간 상한을 정의하지 않았으나, naver-data-layer 규모(도메인당 1~3시간)를 참고해 이슈당 1~1.5시간 내외로 예상한다. 초과 시 우선순위: #1, #2(필수 동작) 먼저 완료 → #3(정렬)은 화면 Phase로 이월 가능 → #4는 항상 마지막에 짧게 마무리.
