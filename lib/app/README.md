# app

앱 진입점과 전역 설정을 담는 레이어입니다.

- `main.dart` — 앱 진입점 (`ProviderScope` + `MaterialApp` 조립)
- `root_shell.dart` — 관심/검색 탭 전환 셸 (`IndexedStack` + `BottomNavigationBar`)

다른 레이어를 전부 참조할 수 있는 최상위 레이어입니다.
