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

- [ ] Given `flutter pub get` 이후, When 앱을 mock 모드로 실행하면, Then 4개 도메인 모두 `assets/mock/`의 데이터가 정상 로드된다
- [ ] Given 전체 테스트 스위트를, When `flutter test`로 실행하면, Then 이슈 1~4에서 추가된 테스트를 포함해 전부 통과한다
- [ ] Given 프로젝트 전체를, When `flutter analyze`를 실행하면, Then 경고 0으로 통과한다

## 의존성

이슈 1, 2, 3, 4 (전체 완료 후 마무리)

## 시간 상한

1시간
