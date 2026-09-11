import 'search_result.dart';

/// 검색어로 종목 후보를 조회하는 방법을 추상화합니다.
///
/// 구현체는 [MockSearchRepository](실제 네트워크 없이 고정 데이터 반환)와
/// [NetworkSearchRepository](Naver 검색 자동완성 API 호출) 두 가지가 있으며,
/// `dataSourceModeProvider`가 어떤 구현체를 쓸지 결정합니다.
abstract interface class SearchRepository {
  Future<List<SearchResult>> search(String query);
}
