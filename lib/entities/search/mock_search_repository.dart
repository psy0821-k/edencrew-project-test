import 'search_repository.dart';
import 'search_result.dart';

/// 네트워크 호출 없이 고정된 검색 결과를 반환하는 테스트/개발용 구현체입니다.
class MockSearchRepository implements SearchRepository {
  @override
  Future<List<SearchResult>> search(String query) async {
    return const [
      SearchResult(symbol: '005930', name: '삼성전자', marketName: '코스피'),
    ];
  }
}
