import 'package:edencrew_assignment_starter/entities/stock_meta/network_stock_meta_repository.dart';
import 'package:edencrew_assignment_starter/shared/api/api_client.dart';
import 'package:edencrew_assignment_starter/shared/error/failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('NetworkStockMetaRepository', () {
    test('응답 JSON에 symbolCode/stockName/stockExchangeNameKor가 모두 있으면 '
        '각각 symbol/name/marketName으로 매핑된 StockMeta를 반환한다', () async {
      final apiClient = ApiClient(
        client: MockClient(
          (request) async => http.Response(
            '{"symbolCode":"005930","stockName":"삼성전자","stockExchangeNameKor":"코스피"}',
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );
      final repository = NetworkStockMetaRepository(apiClient);

      final result = await repository.fetchStockMeta('005930');

      expect(result.symbol, '005930');
      expect(result.name, '삼성전자');
      expect(result.marketName, '코스피');
    });

    test('응답 본문이 비어있으면 EmptyResultFailure를 던진다', () async {
      final apiClient = ApiClient(
        client: MockClient((request) async => http.Response('', 200)),
        maxRetries: 0,
      );
      final repository = NetworkStockMetaRepository(apiClient);

      await expectLater(
        repository.fetchStockMeta('005930'),
        throwsA(isA<EmptyResultFailure>()),
      );
    });

    test('요청이 계속 실패하면 NetworkFailure를 던진다', () async {
      final apiClient = ApiClient(
        client: MockClient((request) async => http.Response('error', 500)),
        maxRetries: 0,
      );
      final repository = NetworkStockMetaRepository(apiClient);

      await expectLater(
        repository.fetchStockMeta('005930'),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('응답 JSON에 symbolCode가 없으면 ParsingFailure를 던진다', () async {
      final apiClient = ApiClient(
        client: MockClient(
          (request) async => http.Response(
            '{"stockName":"삼성전자","stockExchangeNameKor":"코스피"}',
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );
      final repository = NetworkStockMetaRepository(apiClient);

      await expectLater(
        repository.fetchStockMeta('005930'),
        throwsA(isA<ParsingFailure>()),
      );
    });

    test('응답 JSON에 stockName이 없으면 ParsingFailure를 던진다', () async {
      final apiClient = ApiClient(
        client: MockClient(
          (request) async => http.Response(
            '{"symbolCode":"005930","stockExchangeNameKor":"코스피"}',
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );
      final repository = NetworkStockMetaRepository(apiClient);

      await expectLater(
        repository.fetchStockMeta('005930'),
        throwsA(isA<ParsingFailure>()),
      );
    });

    test('응답 JSON에 stockExchangeNameKor가 없으면 ParsingFailure를 던진다', () async {
      final apiClient = ApiClient(
        client: MockClient(
          (request) async => http.Response(
            '{"symbolCode":"005930","stockName":"삼성전자"}',
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );
      final repository = NetworkStockMetaRepository(apiClient);

      await expectLater(
        repository.fetchStockMeta('005930'),
        throwsA(isA<ParsingFailure>()),
      );
    });

    test('응답 body가 유효한 JSON이 아니면 ParsingFailure를 던진다', () async {
      final apiClient = ApiClient(
        client: MockClient((request) async => http.Response('not a json', 200)),
      );
      final repository = NetworkStockMetaRepository(apiClient);

      await expectLater(
        repository.fetchStockMeta('005930'),
        throwsA(isA<ParsingFailure>()),
      );
    });
  });
}
