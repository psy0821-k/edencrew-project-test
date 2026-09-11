/// 앱 전역에서 사용하는 공통 실패(에러) 타입입니다.
///
/// 각 Repository 구현체는 발생한 예외를 아래 3종 중 하나로 변환해 던지고,
/// 화면(Provider)의 `AsyncValue.error`가 이를 받아 화면별로 다르게 렌더링합니다.
///
/// 화면마다 에러 분류를 각자 정의하지 않도록, 최소한의 공통 분류만 여기서 정의합니다.
/// 필요하면 하위 타입을 추가해 세분화할 수 있습니다(sealed class라 컴파일러가 강제).
sealed class Failure {
  const Failure(this.message);

  /// 사용자에게 보여줄 수 있는 기본 메시지입니다.
  final String message;

  @override
  String toString() => '$runtimeType($message)';
}

/// 네트워크 연결 실패, 타임아웃 등 요청 자체가 실패한 경우입니다.
final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = '네트워크 연결을 확인해주세요.']);
}

/// 응답은 받았으나 파싱에 실패한 경우입니다. (예: 일별 시세 HTML 구조 변경, 인코딩 오류)
final class ParsingFailure extends Failure {
  const ParsingFailure([super.message = '데이터를 처리하는 중 문제가 발생했습니다.']);
}

/// 정상 응답이지만 결과가 비어있는 경우입니다. (예: 검색 결과 없음)
final class EmptyResultFailure extends Failure {
  const EmptyResultFailure([super.message = '표시할 데이터가 없습니다.']);
}
