import 'package:intl/intl.dart';

/// 데이터 포맷팅 유틸리티 클래스
class FormatUtils {
  static final _numberFormat = NumberFormat('#,###');

  /// 숫자를 천 단위 콤마가 포함된 문자열로 포맷팅합니다.
  static String formatPrice(num? value) {
    if (value == null) return '0';
    return _numberFormat.format(value);
  }

  /// 숫자 문자열의 앞자리 0을 제거하고 천 단위 콤마를 추가합니다.
  /// 비숫자이거나 null인 경우 기본값을 반환합니다.
  static String formatAmount(String? value, {String defaultValue = '0'}) {
    if (value == null || value.trim().isEmpty) return defaultValue;

    // 앞자리 0 제거
    String cleaned = value.replaceAll(RegExp(r'^0+'), '');
    if (cleaned.isEmpty) return '0';

    try {
      // 숫자로 변환 후 포맷팅
      final number = int.parse(cleaned);
      return _numberFormat.format(number);
    } catch (e) {
      // 변환 실패 시 (소수점 등) 원본 또는 기본 처리
      return cleaned;
    }
  }

  /// 수익률 등 소수점이 포함된 숫자를 소수점 2자리 고정 및 반올림하여 포맷팅합니다.
  /// 부호는 표시하지 않습니다.
  static String formatRate(String? value, {String defaultValue = '0.00'}) {
    if (value == null || value.trim().isEmpty) return defaultValue;

    try {
      final number = double.parse(value);
      return number.toStringAsFixed(2);
    } catch (e) {
      return defaultValue;
    }
  }

  /// 부호, 콤마, 소수점이 포함된 숫자 문자열을 int로 변환합니다.
  static int parseAmount(String? value) {
    if (value == null || value.isEmpty || value == '-') return 0;
    try {
      // 콤마 제거 및 + 기호 제거
      String cleaned = value.replaceAll(',', '').replaceAll('+', '');

      // 소수점이 포함된 경우 double로 먼저 파싱 후 반올림
      if (cleaned.contains('.')) {
        return double.parse(cleaned).round();
      }

      return int.parse(cleaned);
    } catch (e) {
      return 0;
    }
  }

  /// 부호를 포함하여 금액을 포맷팅합니다.
  static String formatSignedAmount(int amount) {
    String formatted = _numberFormat.format(amount.abs());
    if (amount > 0) return '+$formatted';
    if (amount < 0) return '-$formatted';
    return '0';
  }
}
