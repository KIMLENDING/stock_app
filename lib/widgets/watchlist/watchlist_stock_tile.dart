import 'package:flutter/material.dart';
import '../../models/stock_master.dart';
import '../../models/stock_price_detail.dart';
import '../../models/market_status.dart';
import '../../utils/format_utils.dart';

/// 관심종목 리스트에서 개별 종목의 정보를 표시하는 타일 위젯입니다.
/// 실시간 소켓 데이터, API 상세 시세, 기본 종목 정보를 조합하여 상황에 맞는 가격을 결정하는 로직이 포함되어 있습니다.
class WatchlistStockTile extends StatelessWidget {
  final StockMaster stock; // 종목 기본 정보 (이름, 코드, 전일종가 등)
  final StockPriceDetail? detail; // API로 조회된 상세 시세 (현재가, 예상가 등)
  final RealtimePrice? realtime; // 웹소켓을 통해 수신된 실시간 가격 업데이트
  final MarketStatus? marketStatus; // 현재 시장의 상태 (장전/장중/장후)
  final Function(String) onDismissed; // 스와이프하여 삭제 시 호출될 콜백

  const WatchlistStockTile({
    super.key,
    required this.stock,
    required this.onDismissed,
    this.detail,
    this.realtime,
    this.marketStatus,
  });

  @override
  Widget build(BuildContext context) {
    final status = marketStatus?.status ?? "4"; // 기본값: 장마감("4")
    final isMarketOpen = marketStatus?.isMarketOpen ?? false;

    // 화면에 최종적으로 표시할 데이터들
    int displayPrice;
    double displayRate;
    int displayChange;
    String? priceLabel;

    // [Hybrid 가격 결정 로직]
    // 시장 상황에 따라 어떤 데이터(실시간 소켓 vs 상세 시세 vs 마스터 데이터)를 우선할지 결정합니다.

    if (status == "0") {
      // 1. 장 시작 전: 주로 예상체결가 정보를 우선적으로 보여줍니다.
      displayPrice = detail?.validExpectedPrice ?? stock.lastPrice;
      displayRate = detail?.fluRt ?? 0.0;
      displayChange = detail?.predPre ?? 0;
      priceLabel = "예상";
    } else if (isMarketOpen) {
      // 2. 장 중: 웹소켓을 통해 들어오는 '실시간 가격'을 최우선으로 합니다.
      displayPrice =
          realtime?.price ??
          (detail != null && detail!.validPrice > 0
              ? detail!.validPrice
              : stock.lastPrice);
      displayRate = realtime?.changeRate ?? detail?.fluRt ?? 0.0;
      displayChange = realtime?.changeValue ?? detail?.predPre ?? 0;
    } else {
      // 3. 장 마감 이후: 확정된 상세 시세의 '현재가'를 우선으로 보여줍니다.
      displayPrice = (detail != null && detail!.validPrice > 0
          ? detail!.validPrice
          : stock.lastPrice);
      displayRate = detail?.fluRt ?? 0.0;
      displayChange = detail?.predPre ?? 0;
    }

    // 등락에 따른 텍스트 컬러 결정 (상승: 빨강, 하락: 파랑, 보합: 흰색)
    final Color priceColor = displayRate > 0
        ? Colors.red
        : displayRate < 0
        ? Colors.blue
        : Colors.white;

    return Dismissible(
      key: ValueKey('dismiss_${stock.code}'),
      direction: DismissDirection.endToStart, // 오른쪽에서 왼쪽으로 스와이프 시 삭제
      background: Container(color: Colors.transparent),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.redAccent,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDismissed(stock.code),
      child: ListTile(
        key: ValueKey(stock.code),
        // 왼쪽 끝에 정렬(Reorder)용 아이콘 표시
        leading: const Icon(Icons.reorder, color: Colors.grey),
        title: Row(
          children: [
            // 종목명 영역
            Expanded(
              child: Text(
                stock.name,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            // 가격 정보 영역 (우측 정렬)
            _buildPriceInfo(
              displayPrice,
              displayRate,
              displayChange,
              priceColor,
              priceLabel,
            ),
          ],
        ),
        subtitle: _buildSubtitle(),
      ),
    );
  }

  /// 가격과 등락률 정보를 수직으로 배치하여 생성합니다.
  Widget _buildPriceInfo(
    int price,
    double rate,
    int change,
    Color color,
    String? label,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // '예상' 등의 라벨이 있는 경우 표시
            if (label != null)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  label,
                  style: TextStyle(color: Colors.grey[500], fontSize: 10),
                ),
              ),
            Text(
              '${FormatUtils.formatPrice(price)}원',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        // 등락률 및 등락폭 표시 (예: +2.50% (5,000))
        Text(
          '${rate > 0 ? "+" : ""}${rate.toStringAsFixed(2)}% (${FormatUtils.formatSignedAmount(change)})',
          style: TextStyle(color: color, fontSize: 12),
        ),
      ],
    );
  }

  /// 종목 코드, 시장 구분(KOSPI/KOSDAQ), 투자주의 라벨 등을 포함한 서브타이틀 위젯입니다.
  Widget _buildSubtitle() {
    return Row(
      children: [
        Text(stock.code, style: TextStyle(color: Colors.grey[500])),
        const SizedBox(width: 8),
        // 시장 구분 뱃지 (예: 거래소, 코스닥)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            stock.marketLabel,
            style: const TextStyle(fontSize: 10, color: Colors.white),
          ),
        ),
        const SizedBox(width: 4),
        // 투자주의, 경고 등 특이사항이 있는 경우 노란색 텍스트로 표시
        if (stock.orderWarning != '0')
          Text(
            stock.warningLabel,
            style: const TextStyle(fontSize: 10, color: Colors.yellow),
          ),
      ],
    );
  }
}
