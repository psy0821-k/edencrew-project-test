# Issue #37 — widget_test.dart의 Phase 0 더미 화면 기준 테스트를 실제 UI 기준으로 재작성

## 시그니처

```dart
// test/widget_test.dart

/// 테스트 대상 위젯 트리 진입점. main.dart와 동일하게 EdencrewAssignmentApp을
/// ProviderScope로 감싸되, 네트워크/영속성 의존성은 페이크로 override한다.
/// (watchlist_page_test.dart / search_page_test.dart와 동일한 override 패턴)
Future<void> _pumpApp(
  WidgetTester tester, {
  WatchlistRepository? watchlistRepository,
  SearchRepository? searchRepository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        watchlistRepositoryProvider.overrideWithValue(
          watchlistRepository ?? _FakeWatchlistRepository(),
        ),
        searchRepositoryProvider.overrideWithValue(
          searchRepository ?? _FakeSearchRepository(),
        ),
      ],
      child: const EdencrewAssignmentApp(),
    ),
  );
}

// _FakeWatchlistRepository, _FakeSearchRepository는 watchlist_page_test.dart /
// search_page_test.dart의 동일 클래스와 같은 형태로 이 파일 안에 로컬 정의한다.
// (기존 관행 — 파일 간 공유 test helper로 추출하는 것은 이번 이슈 범위 밖)
```

## 배경

기존 `test/widget_test.dart`는 Phase 0 더미 화면 문구(`관심 화면 (더미) — 탭하면 상세로 이동`,
`검색 화면 (더미) — 탭하면 상세로 이동`)를 찾도록 작성되어 있었다. 관심 화면(`WatchlistPage`),
검색 화면(`SearchPage`)이 모두 실제 UI로 교체되면서 이 문구들이 사라져 2개 테스트가 실패한다.

세 번째 기존 테스트("관심 화면의 더미 항목을 탭하면 상세 화면으로 push된다")가 검증하던
"항목 탭 → 상세 이동" 기능 자체가 현재 관심 화면에는 구현되어 있지 않다(검색 결과 행 탭→상세
이동은 이슈 #35 소관, 관심 행 탭→상세 이동 기능은 존재하지 않음). 존재하지 않는 기능을 재현할
수 없으므로 이 시나리오는 삭제하고, 같은 셸 구조(`RootShell`의 `IndexedStack`)가 보장해야 하는
"탭 전환 시 화면 상태 유지" 시나리오로 대체한다.

## 테스트 시나리오

### RootShell (widget_test.dart)

- [정상] 앱을 처음 렌더링하면 다크 테마이고 관심 화면이 기본 탭으로 보여야 한다
- [정상] 하단 탭에서 "검색"을 누르면 검색 화면(초기 안내 문구 "종목을 검색해 보세요")으로
      전환되어야 한다
- [정상] 검색 탭에서 검색어를 입력한 뒤 관심 탭으로 이동했다가 다시 검색 탭으로 돌아오면
      입력했던 검색어가 그대로 유지되어야 한다 (`IndexedStack`이 화면 상태를 보존함을 검증)

## AC 커버리지

| AC | 커버 시나리오 |
|---|---|
| 실제 화면 기준으로 하단 탭 전환·화면 간 이동 시나리오 유지 | 위 3개 시나리오 전체 |
| 재작성된 테스트가 통과한다 | tdd-green 단계에서 실행 확인 |
