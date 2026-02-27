import 'package:flutter/material.dart';
import '../../models/account_evaluation.dart';
import '../../models/market_status.dart';
import '../../models/stock_master.dart';
import '../../utils/format_utils.dart';

/// 계좌 화면 최상단에서 총 평가 금액, 총 손익, 예수금 등 주요 자산 현황을 요약해서 보여주는 카드 위젯입니다.
/// 모든 보유 종목의 실시간 변동분을 합산하여 전체 계좌의 실시간 원장을 산출합니다.
class AccountSummaryCard extends StatelessWidget {
  final AccountData data; // 서버에서 받은 계좌 원장 데이터
  final Map<String, RealtimePrice> realtimePrices; // 웹소켓 실시간 가격 맵
  final MarketStatus? marketStatus; // 현재 시장 상태

  const AccountSummaryCard({
    super.key,
    required this.data,
    required this.realtimePrices,
    this.marketStatus,
  });

  @override
  Widget build(BuildContext context) {
    // 실시간 데이터를 반영한 전체 평가 금액 및 손익 합계 초기화
    int totalPl = 0;
    int totalEvltAmt = 0;

    // 모든 보유 종목을 순회하며 실시간 가치를 합산
    for (var stock in data.stockList) {
      final stockCode = stock.stkCd?.startsWith('A') == true
          ? stock.stkCd!.substring(1)
          : stock.stkCd;
      final realtime = realtimePrices[stockCode];

      final int initialPrice = FormatUtils.parseAmount(
        stock.curPrc,
      ); // 조회 시점 가격
      final int currentPrice = realtime?.price ?? initialPrice; // 실시간 현재가
      final int qty = FormatUtils.parseAmount(stock.rmndQty); // 보유 수량
      final int purAmt = FormatUtils.parseAmount(stock.purAmt); // 매입 금액
      final int initialPlAmt = FormatUtils.parseAmount(stock.plAmt); // 조회 시점 손익

      // [종목별 실시간 손익/평가액 계산]
      // 정확한 실시간 손익 = (조회 시점 손익) + (현재가 변동분 * 수량)
      final int currentPlAmt =
          initialPlAmt + (currentPrice - initialPrice) * qty;
      final int currentEvltAmt = purAmt + currentPlAmt;

      // 전체 합계에 누적
      totalEvltAmt += currentEvltAmt;
      totalPl += currentPlAmt;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 총 평가 금액 및 시장 상태 라벨
          _buildHeader(totalEvltAmt),
          const SizedBox(height: 12),
          // 2. 계좌 전체 실시간 손익 금액
          _buildTotalPlRow(totalPl),
          const SizedBox(height: 16),
          // 3. 기타 자산 정보 (예수금, 총 매입금액 등)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('매입가능금액', '${data.asetEvltAmt ?? "0"}원'),
              _buildSummaryItem('매입금액', '${data.totPurAmt ?? "0"}원'),
            ],
          ),
        ],
      ),
    );
  }

  /// 총 평가 금액과 현재 시장의 운영 상태(장중/장외 등)를 표시하는 영역을 생성합니다.
  Widget _buildHeader(int totalEvltAmt) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            '총 평가 금액: ${FormatUtils.formatPrice(totalEvltAmt)}원',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (marketStatus != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: marketStatus!.isMarketOpen
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              marketStatus!.statusLabel,
              style: TextStyle(
                color: marketStatus!.isMarketOpen ? Colors.green : Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  /// 계좌 전체의 총 손익 금액을 빨강/파랑 색상으로 강조하여 표시합니다.
  Widget _buildTotalPlRow(int totalPl) {
    return Row(
      children: [
        Text('총 손익: ', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
        Text(
          '${FormatUtils.formatSignedAmount(totalPl)}원',
          style: TextStyle(
            color: totalPl > 0
                ? Colors.red
                : (totalPl < 0 ? Colors.blue : Colors.white),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// 라벨과 값을 정렬하여 보여주는 요약 항목 위젯입니다.
  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ],
    );
  }
}
