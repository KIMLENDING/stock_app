import 'package:flutter/material.dart';
import '../../models/account_evaluation.dart';
import '../../models/stock_master.dart';
import '../../utils/format_utils.dart';

/// 계좌 탭에서 내가 보유한 개별 종목의 평가 현황을 보여주는 카드형 타일 위젯입니다.
/// API로 받은 원장 시세와 웹소켓 실시간 시세를 조합하여 실시간 수익률을 계산합니다.
class AccountStockTile extends StatelessWidget {
  final StockItem stock; // 원장 데이터(매입가, 보유수량, 조회시점 현재가 등)
  final RealtimePrice? realtime; // 웹소켓 실시간 가격

  const AccountStockTile({super.key, required this.stock, this.realtime});

  @override
  Widget build(BuildContext context) {
    // 1. 기본 데이터 파싱 (API 데이터는 문자열로 올 수 있어 정수형으로 변환)
    final int initialPrice = FormatUtils.parseAmount(
      stock.curPrc,
    ); // 조회 시점의 현재가
    final int currentPrice =
        realtime?.price ?? initialPrice; // 실시간 현재가 (없으면 조회시점 가격 사용)
    final int qty = FormatUtils.parseAmount(stock.rmndQty); // 보유 수량
    final int purAmt = FormatUtils.parseAmount(stock.purAmt); // 총 매입 금액
    final int initialPlAmt = FormatUtils.parseAmount(
      stock.plAmt,
    ); // API가 계산해준 조회시점 손익금액

    // 2. [실시간 수익 계산 핵심 로직]
    // 실시간 손익 = (조시점 손익금액) + (실시간 현재가 - 조회시점 현재가) * 보유수량
    // 이렇게 계산해야 API가 제공하는 정확한 평단가/수익금 기반 위에서 실시간 변동분을 미세하게 반영할 수 있습니다.
    final int plAmt =
        initialPlAmt + (currentPrice - initialPrice) * qty; // 최종 실시간 손익금액
    final int evltAmt = purAmt + plAmt; // 최종 실시간 평가금액
    final double plRt = purAmt > 0 ? (plAmt / purAmt) * 100 : 0.0; // 실시간 수익률(%)

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 왼쪽: 종목명 및 수량/평단가 정보
          _buildStockInfo(),
          // 오른쪽: 실시간 손익 금액 및 수익률 정보
          _buildPriceInfo(plAmt, evltAmt, plRt),
        ],
      ),
    );
  }

  /// 종목 이름과 보유 정보를 구성합니다.
  Widget _buildStockInfo() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stock.stkNm ?? '알 수 없는 종목',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '수량: ${stock.rmndQty ?? "0"}주 | 매입단가: ${stock.avgPrc ?? "0"}원',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// 실시간 손익 금액, 평가 금액, 수익률 텍스트를 구성합니다.
  Widget _buildPriceInfo(int plAmt, int evltAmt, double plRt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 손익 금액 (예: +150,000원)
        Text(
          '${FormatUtils.formatSignedAmount(plAmt)}원',
          style: TextStyle(
            color: plAmt > 0
                ? Colors.red
                : (plAmt < 0 ? Colors.blue : Colors.white),
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            // 총 평가 금액 (예: 1,250,000원)
            Text(
              '${FormatUtils.formatPrice(evltAmt)}원',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
            const SizedBox(width: 8),
            // 수익률 (예: +12.50%)
            Text(
              '${plRt > 0 ? "+" : ""}${plRt.toStringAsFixed(2)}%',
              style: TextStyle(
                color: plRt > 0
                    ? Colors.red
                    : (plRt < 0 ? Colors.blue : Colors.white),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
