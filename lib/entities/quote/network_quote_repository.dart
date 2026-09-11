import '../../shared/api/api_client.dart';
import '../../shared/error/failure.dart';
import 'quote.dart';
import 'quote_repository.dart';

/// Naver 실시간 시세 API(`polling.finance.naver.com/api/realtime`)를 호출하는
/// 구현체입니다.
///
/// Phase 0에서는 [ApiClient]를 통한 요청·에러 변환 구조만 검증하고, 실제
/// 응답 필드 파싱(`nv`, `pcv` 등)은 Phase 1에서 구현합니다.
class NetworkQuoteRepository implements QuoteRepository {
  NetworkQuoteRepository(this._apiClient);

  final ApiClient _apiClient;

  static final _baseUri = Uri.parse(
    'https://polling.finance.naver.com/api/realtime',
  );

  @override
  Future<Map<String, Quote>> fetchQuotes(List<String> symbols) async {
    if (symbols.isEmpty) return {};

    // 관심종목을 한 번의 요청으로 조회한다 (NAVER_API.md 요구사항).
    final uri = _baseUri.replace(
      queryParameters: {'query': 'SERVICE_ITEM:${symbols.join(',')}'},
    );

    try {
      final response = await _apiClient.get(uri);
      // TODO(Phase 1): 응답 JSON의 cd/nv/pcv 필드를 파싱해 Quote로 변환한다.
      // 지금은 Phase 0 스켈레톤이므로 파싱하지 않고 빈 맵을 반환한다.
      if (response.body.isEmpty) {
        throw const EmptyResultFailure();
      }
      return {};
    } on Failure {
      rethrow;
    } catch (e) {
      throw NetworkFailure('$e');
    }
  }
}
