/// 종목 마스터 정보 모델
class StockMaster {
  final String code; // 종목코드
  final String name; // 종목명
  final int listCount; // 상장주식수
  final int lastPrice; // 전일종가
  final String auditInfo; // 감리구분
  final String regDay; // 상장일
  final String state; // 종목상태
  final String marketCode; // 시장구분코드 (0:코스피, 10:코스닥)
  final String marketName; // 시장명
  final String upName; // 업종명
  final String upSizeName; // 회사크기분류
  final String companyClassName; // 회사분류
  final String orderWarning; // 투자유의종목여부 (0:정상, 1:주의 등)
  final String nxtEnable; // NXT가능여부 (Y/N)

  StockMaster({
    required this.code,
    required this.name,
    required this.listCount,
    required this.lastPrice,
    required this.auditInfo,
    required this.regDay,
    required this.state,
    required this.marketCode,
    required this.marketName,
    required this.upName,
    required this.upSizeName,
    required this.companyClassName,
    required this.orderWarning,
    required this.nxtEnable,
  });

  factory StockMaster.fromJson(Map<String, dynamic> json) {
    return StockMaster(
      code: (json['code'] ?? "").toString(),
      name: (json['name'] ?? "").toString(),
      listCount: json['listCount'] ?? 0,
      lastPrice: json['lastPrice'] ?? 0,
      auditInfo: json['auditInfo'] ?? "",
      regDay: json['regDay'] ?? "",
      state: json['state'] ?? "",
      marketCode: (json['marketCode'] ?? "").toString(),
      marketName: json['marketName'] ?? "",
      upName: json['upName'] ?? "",
      upSizeName: json['upSizeName'] ?? "",
      companyClassName: json['companyClassName'] ?? "",
      orderWarning: (json['orderWarning'] ?? "0").toString(),
      nxtEnable: json['nxtEnable'] ?? "N",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'listCount': listCount,
      'lastPrice': lastPrice,
      'auditInfo': auditInfo,
      'regDay': regDay,
      'state': state,
      'marketCode': marketCode,
      'marketName': marketName,
      'upName': upName,
      'upSizeName': upSizeName,
      'companyClassName': companyClassName,
      'orderWarning': orderWarning,
      'nxtEnable': nxtEnable,
    };
  }

  /// 시장 구분명 한글 변환
  String get marketLabel {
    if (marketCode == '0') return '코스피';
    if (marketCode == '10') return '코스닥';
    return marketName;
  }

  /// 투자 유의 상태 한글화
  String get warningLabel {
    const statusMap = {
      '0': '정상',
      '1': 'ETF투자주의',
      '2': '정리매매',
      '3': '단기과열',
      '4': '투자위험',
      '5': '투자경과',
    };
    return statusMap[orderWarning] ?? '해당없음';
  }
}

/// 관심종목 폴더 모델
class WatchlistFolder {
  final String id;
  String name;
  List<StockMaster> stocks;

  WatchlistFolder({
    required this.id,
    required this.name,
    this.stocks = const [],
  });

  factory WatchlistFolder.fromJson(Map<String, dynamic> json) {
    return WatchlistFolder(
      id: json['id'],
      name: json['name'],
      stocks:
          (json['stocks'] as List?)
              ?.map((e) => StockMaster.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'stocks': stocks.map((e) => e.toJson()).toList(),
    };
  }
}

/// 실시간 시세 정보 모델
class RealtimePrice {
  final String code; // 종목코드
  final int price; // 현재가
  final double changeRate; // 등락율
  final int changeValue; // 전일대비 변동액
  final String time; // 체결시간 (HHMMSS)

  RealtimePrice({
    required this.code,
    required this.price,
    required this.changeRate,
    required this.changeValue,
    required this.time,
  });

  factory RealtimePrice.fromSocket(Map<String, dynamic> data) {
    // 서버 응답 구조: { item: "005930", values: { "10": "75000", "11": "500", "12": "0.67", "20": "150130" } }
    final values = data['values'] as Map<String, dynamic>;

    int parseToInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString().replaceAll(',', '')) ?? 0;
    }

    double parseToDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    return RealtimePrice(
      code: data['item']?.toString() ?? "",
      price: parseToInt(values['10']),
      changeValue: parseToInt(values['11']),
      changeRate: parseToDouble(values['12']),
      time: values['20']?.toString() ?? "",
    );
  }
}
