import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/account_evaluation.dart';

/// 사용자의 계좌 정보 및 보유 주식 평가 현황을 관리하는 서비스 클래스입니다.
class AccountService {
  // API 서버 기본 주소
  static const String _baseUrl = ApiConstants.baseUrl;

  /// 서버로부터 사용자의 전체 계좌 평가 현황(예수금, 총 매입금액, 보유 종목 리스트 등)을 조회합니다.
  /// 리턴값: [ApiResponse] (내부에 [AccountData] 포함)
  Future<ApiResponse> fetchAccountEvaluation() async {
    final uri = Uri.parse('$_baseUrl/api/account/evaluation');

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('계좌 평가 조회 실패: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    // JSON 데이터를 ApiResponse 모델로 변환하여 반환
    return ApiResponse.fromJson(json);
  }
}
