/// 정규화된 [query] 기준으로 [name] 안에서 첫 매치의 시작(포함)/끝(제외) 인덱스를 찾습니다.
///
/// 매치가 없거나 [query]가 빈 문자열이면 `null`을 반환합니다. 호출 측이
/// `normalizeQuery`로 정규화한 검색어를 넘겨준다고 가정합니다(이 함수 자체는
/// 순수 문자열 매칭만 수행).
({int start, int end})? findHighlightRange(String name, String query) {
  if (query.isEmpty) return null;

  final start = name.indexOf(query);
  if (start == -1) return null;

  return (start: start, end: start + query.length);
}
