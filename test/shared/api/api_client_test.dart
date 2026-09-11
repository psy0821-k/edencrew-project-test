import 'package:edencrew_assignment_starter/shared/api/api_client.dart';
import 'package:edencrew_assignment_starter/shared/error/failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ApiClient', () {
    test('2xx 응답이면 성공적으로 반환한다', () async {
      final mockClient = MockClient(
        (request) async => http.Response('ok', 200),
      );
      final apiClient = ApiClient(client: mockClient, maxRetries: 0);

      final response = await apiClient.get(Uri.parse('https://example.com'));

      expect(response.body, 'ok');
    });

    test('실패 응답이 재시도 후에도 계속되면 NetworkFailure를 던진다', () async {
      var callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        return http.Response('error', 500);
      });
      final apiClient = ApiClient(
        client: mockClient,
        maxRetries: 2,
        retryDelay: Duration.zero,
      );

      await expectLater(
        apiClient.get(Uri.parse('https://example.com')),
        throwsA(isA<NetworkFailure>()),
      );
      // 최초 시도 1회 + 재시도 2회 = 3회 호출
      expect(callCount, 3);
    });

    test('예외가 발생해도 재시도 후 NetworkFailure로 변환한다', () async {
      final mockClient = MockClient((request) async {
        throw Exception('connection refused');
      });
      final apiClient = ApiClient(
        client: mockClient,
        maxRetries: 1,
        retryDelay: Duration.zero,
      );

      await expectLater(
        apiClient.get(Uri.parse('https://example.com')),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });
}
