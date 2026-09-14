import 'package:edencrew_assignment_starter/entities/search/network_search_repository.dart';
import 'package:edencrew_assignment_starter/entities/stock_meta/stock_meta.dart';
import 'package:edencrew_assignment_starter/entities/stock_meta/stock_meta_repository.dart';
import 'package:edencrew_assignment_starter/shared/api/api_client.dart';
import 'package:edencrew_assignment_starter/shared/error/failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// 실제 네트워크 호출 없이 symbol을 그대로 되돌려주는 fake.
/// (stock_meta_providers_test.dart의 `_FakeStockMetaRepository` 패턴 참고)
class _FakeStockMetaRepository implements StockMetaRepository {
  @override
  Future<StockMeta> fetchStockMeta(String symbol) async =>
      StockMeta(symbol: symbol, name: '이름-$symbol', marketName: '코스피');
}

void main() {
  group('NetworkSearchRepository', () {
    test('응답 items에 국내 6자리 종목만 있으면 StockMetaRepository로 보강된 marketName을 '
        '포함한 SearchResult 목록을 반환한다', () async {
      final apiClient = ApiClient(
        client: MockClient(
          (request) async => http.Response(
            '{"query":"삼성전자","items":['
            '{"code":"005930","name":"삼성전자","typeCode":"KOSPI","typeName":"코스피",'
            '"url":"/domestic/stock/005930/total","nationCode":"KOR","category":"stock"}'
            ']}',
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );
      final repository = NetworkSearchRepository(
        apiClient,
        _FakeStockMetaRepository(),
      );

      final results = await repository.search('삼성전자');

      expect(results, hasLength(1));
      expect(results.first.symbol, '005930');
      expect(results.first.name, '삼성전자');
      expect(results.first.marketName, '코스피');
    });

    test('nationCode가 KOR이 아닌 해외 주식이 섞여 있으면 결과에서 제외된다', () async {
      final apiClient = ApiClient(
        client: MockClient(
          (request) async => http.Response(
            '{"query":"apple","items":['
            '{"code":"005930","name":"삼성전자","typeCode":"KOSPI","typeName":"코스피",'
            '"url":"/domestic/stock/005930/total","nationCode":"KOR","category":"stock"},'
            '{"code":"AAPL","name":"Apple","typeCode":"NASDAQ","typeName":"나스닥",'
            '"url":"/worldstock/stock/AAPL.O","nationCode":"USA","category":"stock"}'
            ']}',
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );
      final repository = NetworkSearchRepository(
        apiClient,
        _FakeStockMetaRepository(),
      );

      final results = await repository.search('apple');

      expect(results, hasLength(1));
      expect(results.first.symbol, '005930');
    });

    test('6자리 숫자가 아닌 코드(ETF/ETN 등)가 섞여 있으면 결과에서 제외된다', () async {
      final apiClient = ApiClient(
        client: MockClient(
          (request) async => http.Response(
            '{"query":"삼성전자","items":['
            '{"code":"005930","name":"삼성전자","typeCode":"KOSPI","typeName":"코스피",'
            '"url":"/domestic/stock/005930/total","nationCode":"KOR","category":"stock"},'
            '{"code":"0162Z0","name":"RISE 삼성전자SK하이닉스채권혼합50","typeCode":"KOSPI",'
            '"typeName":"코스피","url":"/domestic/stock/0162Z0/total","nationCode":"KOR",'
            '"category":"stock"}'
            ']}',
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );
      final repository = NetworkSearchRepository(
        apiClient,
        _FakeStockMetaRepository(),
      );

      final results = await repository.search('삼성전자');

      expect(results, hasLength(1));
      expect(results.first.symbol, '005930');
    });

    test('필터링 후 남은 종목이 없으면 빈 리스트를 반환한다', () async {
      final apiClient = ApiClient(
        client: MockClient(
          (request) async => http.Response(
            '{"query":"apple","items":['
            '{"code":"AAPL","name":"Apple","typeCode":"NASDAQ","typeName":"나스닥",'
            '"url":"/worldstock/stock/AAPL.O","nationCode":"USA","category":"stock"}'
            ']}',
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );
      final repository = NetworkSearchRepository(
        apiClient,
        _FakeStockMetaRepository(),
      );

      final results = await repository.search('apple');

      expect(results, isEmpty);
    });

    test('응답 본문이 비어있으면 EmptyResultFailure를 던진다', () async {
      final apiClient = ApiClient(
        client: MockClient((request) async => http.Response('', 200)),
        maxRetries: 0,
      );
      final repository = NetworkSearchRepository(
        apiClient,
        _FakeStockMetaRepository(),
      );

      await expectLater(
        repository.search('삼성전자'),
        throwsA(isA<EmptyResultFailure>()),
      );
    });

    test('요청이 계속 실패하면 NetworkFailure를 던진다', () async {
      final apiClient = ApiClient(
        client: MockClient((request) async => http.Response('error', 500)),
        maxRetries: 0,
      );
      final repository = NetworkSearchRepository(
        apiClient,
        _FakeStockMetaRepository(),
      );

      await expectLater(
        repository.search('삼성전자'),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('응답 body가 유효한 JSON이 아니면 ParsingFailure를 던진다', () async {
      final apiClient = ApiClient(
        client: MockClient((request) async => http.Response('not a json', 200)),
      );
      final repository = NetworkSearchRepository(
        apiClient,
        _FakeStockMetaRepository(),
      );

      await expectLater(
        repository.search('삼성전자'),
        throwsA(isA<ParsingFailure>()),
      );
    });

    test('응답 항목에 code가 없으면 ParsingFailure를 던진다', () async {
      final apiClient = ApiClient(
        client: MockClient(
          (request) async => http.Response(
            '{"query":"삼성전자","items":['
            '{"name":"삼성전자","typeCode":"KOSPI","typeName":"코스피",'
            '"url":"/domestic/stock/005930/total","nationCode":"KOR","category":"stock"}'
            ']}',
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );
      final repository = NetworkSearchRepository(
        apiClient,
        _FakeStockMetaRepository(),
      );

      await expectLater(
        repository.search('삼성전자'),
        throwsA(isA<ParsingFailure>()),
      );
    });
  });
}
