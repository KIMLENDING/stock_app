import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/chart_candle.dart';

/// 차트 데이터 API 서비스
/// - 방식 A: 일반 조회 (한 페이지 또는 Pagination)
/// - 방식 B: NDJSON 스트리밍 전량 조회
class ChartService {
  static const String _baseUrl = ApiConstants.baseUrl;

  /// [방식 A] 일반 조회 — 한 페이지 데이터 가져오기
  /// contYn이 "Y"면 nextKey를 사용해 추가 조회 가능
  Future<ChartPageResult> fetchChartPage(
    String code, {
    String? contYn,
    String? nextKey,
  }) async {
    final Map<String, String> params = {};
    if (contYn != null) params['cont_yn'] = contYn;
    if (nextKey != null) params['next_key'] = nextKey;

    final uri = Uri.parse(
      '$_baseUrl/api/chart/daily/$code',
    ).replace(queryParameters: params.isEmpty ? null : params);

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

  /// 분봉 차트 조회 — 한 페이지 가져오기
  /// ticScope: 1, 3, 5, 10, 15, 30, 45, 60 (분)
  Future<ChartPageResult> fetchMinuteChartPage(
    String code, {
    int ticScope = 1,
    String? contYn,
    String? nextKey,
  }) async {
    final Map<String, String> params = {'tic_scope': ticScope.toString()};
    if (contYn != null) params['cont_yn'] = contYn;
    if (nextKey != null) params['next_key'] = nextKey;

    final uri = Uri.parse(
      '$_baseUrl/api/chart/minute/$code',
    ).replace(queryParameters: params);

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('분봉 차트 데이터 조회 실패: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>;
    final chartList = (data['stk_min_pole_chart_qry'] as List<dynamic>?) ?? [];

    final candles = chartList
        .map((e) => ChartCandle.fromMinuteJson(e as Map<String, dynamic>))
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
