import 'package:edencrew_assignment_starter/entities/quote/network_quote_repository.dart';
import 'package:edencrew_assignment_starter/shared/api/api_client.dart';
import 'package:edencrew_assignment_starter/shared/error/failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('NetworkQuoteRepository', () {
    test('symbols가 비어있으면 빈 맵을 즉시 반환한다', () async {
      final apiClient = ApiClient(
        client: MockClient((request) async => http.Response('', 200)),
      );
      final repository = NetworkQuoteRepository(apiClient);

      final result = await repository.fetchQuotes([]);

      expect(result, isEmpty);
    });

    test('응답 본문이 비어있으면 EmptyResultFailure를 던진다', () async {
      final apiClient = ApiClient(
        client: MockClient((request) async => http.Response('', 200)),
        maxRetries: 0,
      );
      final repository = NetworkQuoteRepository(apiClient);

      await expectLater(
        repository.fetchQuotes(['005930']),
        throwsA(isA<EmptyResultFailure>()),
      );
    });

    test('요청이 계속 실패하면 NetworkFailure를 던진다', () async {
      final apiClient = ApiClient(
        client: MockClient((request) async => http.Response('error', 500)),
        maxRetries: 0,
      );
      final repository = NetworkQuoteRepository(apiClient);

      await expectLater(
        repository.fetchQuotes(['005930']),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });
}
