# 이슈 16 (feature: watchlist-sync #16): Watchlist 도메인 + LocalWatchlistRepository (SharedPreferences 영속화)

> GitHub 이슈 16 원문의 "이슈 1"과 동일 대상. PRD ADR 1 참고.

## 확정 시그니처

`lib/entities/watchlist/`:

```dart
// watchlist_repository.dart
/// 관심등록된 종목 symbol 집합을 저장·토글·조회하는 방법을 추상화합니다.
///
/// 구현체는 [LocalWatchlistRepository](SharedPreferences 기반) 하나뿐입니다.
/// Quote/Search/StockMeta 도메인과 달리 Mock/Network 이분법이 없습니다
/// (PRD ADR 1, Out of Scope).
abstract interface class WatchlistRepository {
  /// 현재 관심등록된 symbol 전체를 동기로 조회합니다.
  Set<String> getSymbols();

  /// symbol의 관심등록 상태를 토글합니다.
  ///
  /// 반환값은 토글 "이후" 상태입니다 — 등록되면 `true`, 해제되면 `false`.
  Future<bool> toggleFavorite(String symbol);

  /// 단일 symbol의 관심등록 여부를 동기로 조회합니다.
  bool isFavorite(String symbol);
}
```

```dart
// local_watchlist_repository.dart
/// SharedPreferences로 관심종목 symbol 집합을 영속화하는 구현체.
///
/// 생성자는 이미 로드가 끝난 [SharedPreferences] 인스턴스를 주입받습니다
/// (`main()`에서 `await SharedPreferences.getInstance()`로 사전 로드 —
/// PRD ADR 1의 "완전히 동기 인터페이스" 전제).
class LocalWatchlistRepository implements WatchlistRepository {
  LocalWatchlistRepository(this._preferences);

  final SharedPreferences _preferences;

  static const _watchlistSymbolsKey = 'watchlist_symbols';

  @override
  Set<String> getSymbols() {
    final stored = _preferences.getStringList(_watchlistSymbolsKey);
    return stored == null ? {} : stored.toSet();
  }

  @override
  Future<bool> toggleFavorite(String symbol) async {
    final symbols = getSymbols();
    final nowFavorite = !symbols.contains(symbol);

    if (nowFavorite) {
      symbols.add(symbol);
    } else {
      symbols.remove(symbol);
    }

    await _preferences.setStringList(_watchlistSymbolsKey, symbols.toList());
    return nowFavorite;
  }

  @override
  bool isFavorite(String symbol) => getSymbols().contains(symbol);
}
```

```dart
// watchlist_notifier.dart
/// 관심종목 symbol 집합의 메모리 상태를 들고 있는 StateNotifier.
///
/// 생성 시 Repository의 `getSymbols()`로 초기 state를 동기 설정합니다
/// (SharedPreferences가 이미 로드된 상태라는 전제 — main.dart 배선은 별도 이슈).
class WatchlistNotifier extends StateNotifier<Set<String>> {
  WatchlistNotifier(this._repository) : super(_repository.getSymbols());

  final WatchlistRepository _repository;

  /// Repository에 토글을 위임한 뒤 state를 갱신하고, 토글 결과를 그대로 반환합니다.
  Future<bool> toggleFavorite(String symbol) async {
    final result = await _repository.toggleFavorite(symbol);
    state = _repository.getSymbols();
    return result;
  }
}
```

```dart
// watchlist_providers.dart
/// main()에서 overrideWithValue로 주입되는 것을 전제합니다.
/// 기본 구현이 없으므로 override 없이 read하면 예외를 던집니다.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider는 main()에서 overrideWithValue로 주입되어야 합니다.',
  );
});

final watchlistRepositoryProvider = Provider<WatchlistRepository>((ref) {
  return LocalWatchlistRepository(ref.watch(sharedPreferencesProvider));
});

final watchlistProvider =
    StateNotifierProvider<WatchlistNotifier, Set<String>>((ref) {
  return WatchlistNotifier(ref.watch(watchlistRepositoryProvider));
});
```

### 확정 근거 (애매했던 부분)

- **파일 분리**: 이슈 본문 지시대로 4개 파일(`watchlist_repository.dart`, `local_watchlist_repository.dart`, `watchlist_providers.dart`, `watchlist_notifier.dart`)로 분리 — `entities/quote/`, `entities/search/`가 인터페이스/구현체/provider를 항상 별도 파일로 두는 기존 관행과 동일.
- **생성자 파라미터명**: `LocalWatchlistRepository(this._preferences)` — private 필드로 바로 받는 방식은 코드베이스에 선례가 없어(Quote/Search 구현체는 의존성이 없거나 `ApiClient`/Repository만 받음), Repository 계층에서 흔한 관례(필드명 = 역할명)를 따름. 공개 파라미터명이 필요 없으므로(위치 인자 1개) 별도 named parameter를 두지 않음.
- **`toggleFavorite`의 "해제됨" 반환값 의미**: PRD/이슈 문구가 "등록됨=true/해제됨=false"로 결과 상태를 반환한다고 명시 → `nowFavorite`(토글 후 상태)을 그대로 반환하는 것으로 확정. `WatchlistNotifier.toggleFavorite`도 동일하게 Repository의 반환값을 그대로 전달(가공하지 않음).
- **`WatchlistNotifier`의 state 갱신 방식**: `_repository.getSymbols()`로 다시 조회해 state를 교체 — Repository가 SharedPreferences라는 단일 진실 소스이므로 메모리에서 별도로 Set을 합성하지 않고 항상 재조회해 동기화 어긋남을 방지(`LocalWatchlistRepository.toggleFavorite` 내부와 별개로 이중 관리하지 않음).
- **`getSymbols()`가 매번 새 Set을 반환하는지**: `stored.toSet()`으로 매 호출 새 인스턴스를 생성 — 호출자가 반환된 Set을 변형해도 내부 상태(SharedPreferences 캐시)에 영향이 없도록 방어.
- **`dataSourceModeProvider` 미사용**: 이슈 본문과 PRD Out of Scope에 명시된 대로 이 도메인은 Local 구현체 하나뿐이므로 전역 모드 스위치를 참조하지 않음(Quote/Search의 `switch (dataSourceModeProvider)` 패턴을 따르지 않는 것이 의도적 확정 사항).

## pubspec.yaml

`shared_preferences` 패키지를 `dependencies`에 추가 (버전은 구현 단계에서 `flutter pub add shared_preferences`로 최신 안정 버전 사용).

## 테스트 도구

`pubspec.yaml` dev_dependencies에 `mockito`/`mocktail` 없음 — 코드베이스 전체가 `flutter_test`만으로 수동 Fake/Stub 클래스를 작성하는 관례(`test/entities/quote/quote_providers_test.dart`의 `_FakeQuoteRepository` 참고). Watchlist 테스트도 동일하게 수동 Fake 클래스 + `SharedPreferences.setMockInitialValues({})`를 사용한다.

---

## 테스트 시나리오

### `LocalWatchlistRepository`

1. **should return empty set when no watchlist stored** (정상 — AC1)
   - Given: `SharedPreferences.setMockInitialValues({})`로 초기화한 인스턴스
   - When: `LocalWatchlistRepository(prefs).getSymbols()` 호출
   - Then: 빈 `Set<String>` 반환

2. **should return true and persist symbol when toggling an unregistered symbol** (정상 — AC2)
   - Given: `"005930"`이 저장되어 있지 않은 상태
   - When: `toggleFavorite("005930")` 호출
   - Then: `true` 반환, 이후 `isFavorite("005930")`은 `true`

3. **should return false and remove symbol when toggling an already-registered symbol** (정상 — AC3)
   - Given: `"005930"`이 이미 저장된 상태(`setMockInitialValues({'watchlist_symbols': ['005930']})`)
   - When: `toggleFavorite("005930")` 호출
   - Then: `false` 반환, 이후 `isFavorite("005930")`은 `false`

4. **should keep symbol across repository instances backed by the same SharedPreferences** (정상 — AC4, 영속화 검증)
   - Given: 하나의 `SharedPreferences` 인스턴스로 `toggleFavorite("005930")`을 호출해 등록 완료
   - When: 같은 인스턴스로 새 `LocalWatchlistRepository`를 생성해 `getSymbols()` 호출
   - Then: 반환된 Set에 `"005930"` 포함

5. **should not affect stored symbols when mutating the returned set** (경계)
   - Given: `"005930"`이 등록된 상태
   - When: `getSymbols()`가 반환한 Set에 임의로 `"000000"`을 추가
   - Then: 다시 `getSymbols()`를 호출하면 `"000000"`이 포함되어 있지 않음 (반환 Set은 내부 상태와 독립적인 복사본)

6. **should toggle correctly when multiple symbols are already registered** (경계)
   - Given: `{"005930", "035720"}`이 저장된 상태
   - When: `toggleFavorite("035720")` 호출
   - Then: `false` 반환, `getSymbols()`는 `{"005930"}`만 포함(다른 symbol에 영향 없음)

### `WatchlistNotifier`

7. **should initialize state from repository's getSymbols on creation** (정상)
   - Given: Fake Repository의 `getSymbols()`가 `{"005930"}`을 반환하도록 설정
   - When: `WatchlistNotifier(fakeRepository)` 생성
   - Then: `notifier.state`가 즉시 `{"005930"}` (비동기 로딩 없이 동기 초기화)

8. **should update state and return repository's result when toggling** (정상 — AC5)
   - Given: 초기화된 `WatchlistNotifier`, Fake Repository의 `toggleFavorite`가 `true`를 반환하도록 설정
   - When: `notifier.toggleFavorite("005930")` 호출
   - Then: 반환값이 `true`이고, 호출 직후 `notifier.state`에 `"005930"`이 포함됨

9. **should reflect repository state after a toggle removes a symbol** (경계)
   - Given: 초기 state에 `"005930"` 포함, Fake Repository의 `toggleFavorite`가 `false`를 반환하고 `getSymbols()`가 `{}`를 반환하도록 설정
   - When: `notifier.toggleFavorite("005930")` 호출
   - Then: 반환값이 `false`이고, `notifier.state`는 빈 Set

### `watchlist_providers` (provider 배선)

10. **should throw when sharedPreferencesProvider is read without override** (예외)
    - Given: override 없는 `ProviderContainer`
    - When: `container.read(sharedPreferencesProvider)` 호출
    - Then: `UnimplementedError` 발생

11. **should build LocalWatchlistRepository from overridden SharedPreferences** (정상)
    - Given: `sharedPreferencesProvider.overrideWithValue(mockPrefs)`로 override한 `ProviderContainer`
    - When: `container.read(watchlistRepositoryProvider)` 호출
    - Then: `LocalWatchlistRepository` 인스턴스 반환

12. **should allow overriding watchlistRepositoryProvider directly with a fake** (정상, quote_providers_test 관례와 동일)
    - Given: `watchlistRepositoryProvider.overrideWithValue(fakeRepository)`로 override한 `ProviderContainer` (sharedPreferencesProvider override 불필요)
    - When: `container.read(watchlistRepositoryProvider)` 호출
    - Then: 주입한 fake 인스턴스와 동일(`same`)

13. **should expose watchlistProvider as a StateNotifierProvider synced with the repository** (정상)
    - Given: `watchlistRepositoryProvider`를 `getSymbols()`가 `{"005930"}`을 반환하는 fake로 override
    - When: `container.read(watchlistProvider)` 호출
    - Then: `{"005930"}` 반환 (Notifier가 Repository의 초기 상태를 그대로 노출)

## AC 커버리지

| AC | 커버 시나리오 |
|---|---|
| AC1 (빈 Set 반환) | 시나리오 1 |
| AC2 (미등록 → toggle → true, isFavorite true) | 시나리오 2 |
| AC3 (등록됨 → toggle → false, isFavorite false) | 시나리오 3 |
| AC4 (영속화 — 새 인스턴스에서도 유지) | 시나리오 4 |
| AC5 (Notifier state 즉시 갱신 + 반환값 일치) | 시나리오 8 |

5/5 AC 커버. 나머지 시나리오(5, 6, 7, 9~13)는 AC에 명시되지 않았지만 시그니처의 계약(불변성, 초기화 동기성, provider 배선 실수 방지)을 보강하기 위해 추가.
