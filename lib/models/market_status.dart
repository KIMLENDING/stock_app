/// 시장 운영 상태 모델
class MarketStatus {
  final String status; // 장운영구분 (215)
  final String time; // 체결시간 (20) - HHMMSS
  final String remainTime; // 잔여시간 (214)

  MarketStatus({
    required this.status,
    required this.time,
    required this.remainTime,
  });

  factory MarketStatus.fromSocket(Map<String, dynamic> data) {
    final values = data['values'] as Map<String, dynamic>;
    return MarketStatus(
      status: values['215'] ?? "",
      time: values['20'] ?? "",
      remainTime: values['214'] ?? "",
    );
  }

  /// 현재 장이 열려있는 상태인지 여부
  /// 0: 장시작전, 3: 정규장, 2: 장마감전알림
  bool get isMarketOpen {
    // 실시간 시세가 유의미하게 변하는 시점 기준
    return status == '0' || status == '3' || status == '2';
  }

  /// 장 상태에 대한 한국어 대칭 레이블
  String get statusLabel {
    switch (status) {
      case '0':
        return '장 시작 전';
      case '3':
        return '장 진행 중';
      case '2':
        return '장 마감 임박';
      case '4':
        return '장 마감';
      case 'c':
        return '시간외 단일가 시작';
      case 'd':
        return '시간외 단일가 마감';
      default:
        return '장 종료';
    }
  }
}
