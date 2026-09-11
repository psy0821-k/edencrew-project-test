# 이슈 4: main() 초기화 배선 + 전체 검증

## 목적

SharedPreferences 사전 로드를 `main()`에 실제로 배선하고, watchlist-sync 전체(이슈 1~3)가 앱 부트스트랩 과정에서 정상 동작하는지 검증한다. PRD ADR 1(하이브리드 초기화) 참고.

## 구현 범위

- `lib/main.dart` 수정:
  - `main()`을 `async`로 변경 (이미 그렇다면 유지), `WidgetsFlutterBinding.ensureInitialized()` 호출 확인
  - `await SharedPreferences.getInstance()`로 사전 로드
  - `ProviderScope(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)], ...)`로 주입
- `assets/mock/`에 watchlist 관련 mock이 필요하면 추가 (이 도메인은 로컬 전용이라 별도 mock 응답은 불필요할 가능성 높음 — 필요 여부 확인 후 생략 가능)
- 전체 검증:
  - `flutter analyze` 경고 없이 통과
  - `flutter test` 전체 통과 (이슈 1~3에서 작성한 테스트 포함)
  - `flutter run`으로 앱을 띄워 초기화가 예외 없이 완료되는지 수동 확인

## 참고

- `project-foundation`의 `main.dart`가 이미 `ProviderScope`를 조립하는 구조이므로, 그 위에 `overrides`만 추가하는 최소 변경이어야 한다 (project-foundation ADR 5의 "Repository provider override" 관행과 동일 방식).
- 이 이슈는 새 기능을 추가하지 않는다 — 이슈 1~3의 배선과 검증만 담당한다.

## Acceptance Criteria

- [ ] Given 앱을 처음 실행할 때, When `main()`이 실행되면, Then `SharedPreferences.getInstance()` 완료 후에 `runApp()`이 호출된다 (초기화 순서 보장).
- [ ] Given 이전 실행에서 관심등록된 symbol이 SharedPreferences에 저장되어 있을 때, When 앱을 재실행하면, Then `watchlistProvider`의 초기 state에 해당 symbol이 이미 포함되어 있다 (로딩 스피너 없이 즉시).
- [ ] Given 프로젝트 전체 코드에서, When `flutter analyze`를 실행하면, Then 경고 없이 통과한다.
- [ ] Given 이슈 1~3에서 작성한 테스트를 포함한 전체 테스트 스위트에서, When `flutter test`를 실행하면, Then 모두 통과한다.
