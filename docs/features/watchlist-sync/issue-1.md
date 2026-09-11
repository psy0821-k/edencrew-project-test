# 이슈 1: Watchlist 도메인 + LocalWatchlistRepository (SharedPreferences 영속화)

## 목적

관심등록된 종목코드(symbol) 집합을 저장·토글·조회하는 도메인 계층을 만든다. PRD ADR 1 참고.

## 구현 범위

`lib/entities/watchlist/`:

- `watchlist_repository.dart` — `abstract interface class WatchlistRepository`
  - `Set<String> getSymbols()` — 현재 관심등록된 symbol 전체 조회 (동기)
  - `Future<bool> toggleFavorite(String symbol)` — 등록↔해제 토글, 결과(`true`=등록됨/`false`=해제됨) 반환
  - `bool isFavorite(String symbol)` — 단일 symbol 조회 (동기)
- `local_watchlist_repository.dart` — `LocalWatchlistRepository implements WatchlistRepository`
  - 생성자에서 `SharedPreferences` 인스턴스를 주입받음 (사전 로드된 것을 받는 구조, PRD ADR 1)
  - key: `'watchlist_symbols'`, 값: `List<String>` (`getStringList`/`setStringList`)
- `watchlist_providers.dart`
  - `sharedPreferencesProvider` — `main()`에서 `overrideWithValue`로 주입되는 것을 전제 (기본 구현 없이 `UnimplementedError` throw)
  - `watchlistRepositoryProvider` — `Provider<WatchlistRepository>`, `LocalWatchlistRepository` 반환
  - `watchlistProvider` — `StateNotifierProvider<WatchlistNotifier, Set<String>>`
- `watchlist_notifier.dart` — `WatchlistNotifier extends StateNotifier<Set<String>>`
  - 생성 시 Repository의 `getSymbols()`로 초기 state 설정
  - `Future<bool> toggleFavorite(String symbol)` — Repository에 위임 후 state 갱신, 결과 반환

`pubspec.yaml`에 `shared_preferences` 패키지 추가.

## 참고

- `entities/quote/quote_repository.dart`, `entities/quote/quote_providers.dart`의 인터페이스+provider 패턴을 그대로 따른다.
- `dataSourceModeProvider`(mock/network)는 사용하지 않는다 — 이 도메인은 Local 구현체 하나뿐 (PRD Out of Scope).

## Acceptance Criteria

- [ ] Given SharedPreferences에 저장된 관심종목이 없을 때, When `LocalWatchlistRepository.getSymbols()`를 호출하면, Then 빈 Set이 반환된다.
- [ ] Given symbol `"005930"`이 관심등록되어 있지 않을 때, When `toggleFavorite("005930")`을 호출하면, Then `true`가 반환되고 이후 `isFavorite("005930")`은 `true`를 반환한다.
- [ ] Given symbol `"005930"`이 이미 관심등록되어 있을 때, When `toggleFavorite("005930")`을 호출하면, Then `false`가 반환되고 이후 `isFavorite("005930")`은 `false`를 반환한다.
- [ ] Given `toggleFavorite`으로 symbol을 등록한 뒤, When 같은 SharedPreferences 인스턴스로 새 `LocalWatchlistRepository`를 생성해 `getSymbols()`를 호출하면, Then 등록한 symbol이 포함되어 있다 (영속화 검증).
- [ ] Given `WatchlistNotifier`가 초기화된 상태에서, When `toggleFavorite(symbol)`을 호출하면, Then `state`(Set)가 즉시 갱신되고 반환값이 Repository의 토글 결과와 일치한다.
