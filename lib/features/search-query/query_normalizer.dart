/// 검색어를 정규화합니다. `trim()` 후 문자열 내부의 모든 공백을 제거합니다.
///
/// 예: `"삼성 전자"` → `"삼성전자"`. 요청 전처리와 하이라이트 매칭 양쪽에서
/// 공용으로 사용합니다.
String normalizeQuery(String raw) => raw.trim().replaceAll(RegExp(r'\s+'), '');
