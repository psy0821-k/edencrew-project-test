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

    test('symbols 2개로 호출하면 한 번의 HTTP 요청으로 두 종목 모두 포함된 Map을 반환한다', () async {
      var requestCount = 0;
      final apiClient = ApiClient(
        client: MockClient((request) async {
          requestCount++;
          return http.Response(
            '{"result":{"areas":[{"datas":['
            '{"cd":"005930","nv":70000,"pcv":70400,"ov":70000,"hv":71000,"lv":69500,"aq":1000000,"countOfListedStock":100000000},'
            '{"cd":"000660","nv":150000,"pcv":149000,"ov":149500,"hv":151000,"lv":148000,"aq":500000,"countOfListedStock":50000000}'
            ']}]}}',
            200,
          );
        }),
      );
      final repository = NetworkQuoteRepository(apiClient);

      final result = await repository.fetchQuotes(['005930', '000660']);

      expect(requestCount, 1);
      expect(result.keys, containsAll(['005930', '000660']));
    });

    test('응답 항목의 필드가 각각 Quote의 대응 필드로 매핑된다', () async {
      final apiClient = ApiClient(
        client: MockClient(
          (request) async => http.Response(
            '{"result":{"areas":[{"datas":['
            '{"cd":"005930","nv":70000,"pcv":70400,"ov":69800,"hv":71000,"lv":69500,"aq":1000000,"countOfListedStock":100000000}'
            ']}]}}',
            200,
          ),
        ),
      );
      final repository = NetworkQuoteRepository(apiClient);

      final result = await repository.fetchQuotes(['005930']);
      final quote = result['005930']!;

      expect(quote.symbol, '005930');
      expect(quote.currentPrice, 70000);
      expect(quote.previousClose, 70400);
      expect(quote.open, 69800);
      expect(quote.high, 71000);
      expect(quote.low, 69500);
      expect(quote.volume, 1000000);
      expect(quote.countOfListedStock, 100000000);
    });

    test('datas 배열이 비어있으면 EmptyResultFailure를 던진다', () async {
      final apiClient = ApiClient(
        client: MockClient(
          (request) async =>
              http.Response('{"result":{"areas":[{"datas":[]}]}}', 200),
        ),
        maxRetries: 0,
      );
      final repository = NetworkQuoteRepository(apiClient);

      await expectLater(
        repository.fetchQuotes(['005930']),
        throwsA(isA<EmptyResultFailure>()),
      );
    });

    test('응답 항목에 필수 필드(cd)가 없으면 ParsingFailure를 던진다', () async {
      final apiClient = ApiClient(
        client: MockClient(
          (request) async => http.Response(
            '{"result":{"areas":[{"datas":['
            '{"nv":70000,"pcv":70400,"ov":69800,"hv":71000,"lv":69500,"aq":1000000,"countOfListedStock":100000000}'
            ']}]}}',
            200,
          ),
        ),
      );
      final repository = NetworkQuoteRepository(apiClient);

      await expectLater(
        repository.fetchQuotes(['005930']),
        throwsA(isA<ParsingFailure>()),
      );
    });

    test('응답 body가 유효한 JSON이 아니면 ParsingFailure를 던진다', () async {
      final apiClient = ApiClient(
        client: MockClient((request) async => http.Response('not a json', 200)),
      );
      final repository = NetworkQuoteRepository(apiClient);

      await expectLater(
        repository.fetchQuotes(['005930']),
        throwsA(isA<ParsingFailure>()),
      );
    });
  });
}
