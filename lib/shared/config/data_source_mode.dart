import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 앱이 실제 Naver API(network)를 쓸지, 저장된 mock 응답(mock)을 쓸지 결정합니다.
///
/// 모든 도메인 Repository provider는 이 값을 `switch`로 참조해 구현체를
/// 스스로 선택합니다. 개발 중 Naver가 차단되면 이 provider 하나만
/// override하면 앱 전체가 mock으로 전환됩니다 (컴파일 타임 전환 — 코드
/// 수정 후 재실행 필요, 런타임 UI 토글이 아닙니다).
///
/// 테스트에서 특정 도메인 하나만 mock으로 바꾸고 싶다면, 이 provider는
/// 그대로 두고 해당 도메인의 Repository provider를 개별 `overrideWithValue`
/// 하면 됩니다 (Riverpod override의 기본 동작 — "더 안쪽 override가 우선").
enum DataSourceMode { mock, network }

final dataSourceModeProvider = Provider<DataSourceMode>(
  (ref) => DataSourceMode.network,
);
