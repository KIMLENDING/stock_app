import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/chart_candle.dart';

/// 차트 데이터 API 서비스
/// - 방식 A: 일반 조회 (한 페이지 또는 Pagination)
/// - 방식 B: NDJSON 스트리밍 전량 조회
class ChartService {
  // Android 에뮬레이터에서 호스트 PC 접근: 10.0.2.2
  // Windows/웹 실행 시에는 localhost로 변경
  static const String _baseUrl = 'http://10.0.2.2:3000';

  /// [방식 A] 일반 조회 — 한 페이지 데이터 가져오기
  /// contYn이 "Y"면 nextKey를 사용해 추가 조회 가능
  Future<ChartPageResult> fetchChartPage(
    String code, {
    String? contYn,
    String? nextKey,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/market/chart/$code').replace(
      queryParameters: {
        if (contYn != null) 'cont_yn': contYn,
        if (nextKey != null) 'next_key': nextKey,
      },
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('차트 데이터 조회 실패: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>;
    final chartList = (data['stk_dt_pole_chart_qry'] as List<dynamic>?) ?? [];

    final candles = chartList
        .map((e) => ChartCandle.fromJson(e as Map<String, dynamic>))
        .toList();

    return ChartPageResult(
      candles: candles,
      contYn: json['contYn'] as String? ?? 'N',
      nextKey: json['nextKey'] as String?,
    );
  }

  /// [방식 A] 전체 페이지 순회 — 모든 데이터를 가져올 때까지 반복
  Future<List<ChartCandle>> fetchAllChartData(String code) async {
    final allCandles = <ChartCandle>[];
    String? contYn;
    String? nextKey;

    do {
      final result = await fetchChartPage(
        code,
        contYn: contYn,
        nextKey: nextKey,
      );
      allCandles.addAll(result.candles);
      contYn = result.contYn;
      nextKey = result.nextKey;
    } while (contYn == 'Y');

    // 날짜 오름차순 정렬 (API는 최신→과거 순서)
    allCandles.sort((a, b) => a.date.compareTo(b.date));
    return allCandles;
  }

  /// [방식 B] NDJSON 스트리밍 조회 — 서버가 전량 스트림으로 전송
  /// 각 라인이 하나의 JSON 페이지이므로, 라인별로 파싱 후 yield
  Stream<List<ChartCandle>> streamChartData(String code) async* {
    final uri = Uri.parse('$_baseUrl/api/market/chart/stream/$code');
    final request = http.Request('GET', uri);
    final streamedResponse = await http.Client().send(request);

    if (streamedResponse.statusCode != 200) {
      throw Exception('스트리밍 차트 데이터 조회 실패: ${streamedResponse.statusCode}');
    }

    // NDJSON: 각 라인이 하나의 JSON 객체
    await for (final chunk
        in streamedResponse.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
      if (chunk.trim().isEmpty) continue;

      try {
        final json = jsonDecode(chunk) as Map<String, dynamic>;

        // 에러 메시지 방어
        if (json.containsKey('error')) {
          throw Exception('서버 에러: ${json['error']}');
        }

        final data = json['data'] as Map<String, dynamic>;
        final chartList = data['stk_dt_pole_chart_qry'] as List<dynamic>;

        final candles = chartList
            .map((e) => ChartCandle.fromJson(e as Map<String, dynamic>))
            .toList();

        yield candles;
      } catch (e) {
        if (e is Exception && e.toString().contains('서버 에러')) {
          rethrow;
        }
        // JSON 파싱 실패 시 해당 라인 스킵
        continue;
      }
    }
  }
}

/// 일반 조회 결과 (한 페이지 + Pagination 정보)
class ChartPageResult {
  final List<ChartCandle> candles;
  final String contYn;
  final String? nextKey;

  const ChartPageResult({
    required this.candles,
    required this.contYn,
    this.nextKey,
  });

  bool get hasMore => contYn == 'Y';
}
