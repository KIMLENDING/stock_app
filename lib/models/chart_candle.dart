/// 캔들스틱 차트 데이터 모델
/// 일봉/분봉 API 응답을 모두 지원
class ChartCandle {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  const ChartCandle({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  /// 일봉 API 응답에서 생성 (stk_dt_pole_chart_qry)
  /// dt 형식: "20260225"
  factory ChartCandle.fromDailyJson(Map<String, dynamic> json) {
    final dtStr = json['dt'] as String;
    final date = DateTime(
      int.parse(dtStr.substring(0, 4)),
      int.parse(dtStr.substring(4, 6)),
      int.parse(dtStr.substring(6, 8)),
    );

    return ChartCandle(
      date: date,
      open: double.parse(json['open_pric'] as String).abs(),
      high: double.parse(json['high_pric'] as String).abs(),
      low: double.parse(json['low_pric'] as String).abs(),
      close: double.parse(json['cur_prc'] as String).abs(),
      volume: double.parse(json['trde_qty'] as String).abs(),
    );
  }

  /// 분봉 API 응답에서 생성 (stk_min_pole_chart_qry)
  /// cntr_tm 형식: "20250917132000" (YYYYMMDDHHmmss)
  factory ChartCandle.fromMinuteJson(Map<String, dynamic> json) {
    final tmStr = json['cntr_tm'] as String;
    final date = DateTime(
      int.parse(tmStr.substring(0, 4)),
      int.parse(tmStr.substring(4, 6)),
      int.parse(tmStr.substring(6, 8)),
      int.parse(tmStr.substring(8, 10)),
      int.parse(tmStr.substring(10, 12)),
    );

    return ChartCandle(
      date: date,
      open: double.parse(json['open_pric'] as String).abs(),
      high: double.parse(json['high_pric'] as String).abs(),
      low: double.parse(json['low_pric'] as String).abs(),
      close: double.parse(json['cur_prc'] as String).abs(),
      volume: double.parse(json['trde_qty'] as String).abs(),
    );
  }

  /// 하위 호환: 기존 fromJson은 일봉으로 동작
  factory ChartCandle.fromJson(Map<String, dynamic> json) =>
      ChartCandle.fromDailyJson(json);

  /// 양봉 여부 (종가 >= 시가)
  bool get isBullish => close >= open;

  @override
  String toString() =>
      'ChartCandle(date: $date, O: $open, H: $high, L: $low, C: $close, V: $volume)';
}
