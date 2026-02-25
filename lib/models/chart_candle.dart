/// 캔들스틱 차트 데이터 모델
/// API 응답의 stk_dt_pole_chart_qry 배열 항목을 매핑
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

  /// API JSON 응답에서 ChartCandle 객체 생성
  factory ChartCandle.fromJson(Map<String, dynamic> json) {
    // dt 형식: "20260225" → DateTime 변환
    final dtStr = json['dt'] as String;
    final date = DateTime(
      int.parse(dtStr.substring(0, 4)),
      int.parse(dtStr.substring(4, 6)),
      int.parse(dtStr.substring(6, 8)),
    );

    return ChartCandle(
      date: date,
      open: double.parse(json['open_pric'] as String),
      high: double.parse(json['high_pric'] as String),
      low: double.parse(json['low_pric'] as String),
      close: double.parse(json['cur_prc'] as String),
      volume: double.parse(json['trde_qty'] as String),
    );
  }

  /// 양봉 여부 (종가 >= 시가)
  bool get isBullish => close >= open;

  @override
  String toString() =>
      'ChartCandle(date: $date, O: $open, H: $high, L: $low, C: $close, V: $volume)';
}
