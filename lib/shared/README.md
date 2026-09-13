# shared

도메인에 종속되지 않는 공통 레이어입니다. 다른 모든 레이어가 참조할 수 있는 최하위 레이어입니다.

- `api/` — `ApiClient` (Naver API 4종 호출 게이트웨이)
- `config/` — `dataSourceModeProvider` (mock/network 전역 스위치)
- `error/` — `Failure` 공통 에러 타입 3종
- `state/` — 화면에 종속되지 않는 공용 상태 관리 Notifier (`PendingSymbolsNotifier` 등 연속 클릭 방지류)
- `utils/` — 도메인 무관 순수 함수 (숫자·날짜 포맷, Debouncer, HTML 인코딩 디코더)

배치 기준: "이 함수/타입이 특정 도메인을 알아야 하는가?" — 알아야 하면 `entities`나 `features`로, 몰라도 되면 여기로.
