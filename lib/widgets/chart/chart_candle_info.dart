import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controllers/chart_controller.dart';

class ChartCandleInfo extends StatelessWidget {
  final ChartController controller;

  const ChartCandleInfo({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    // 선택된 캔들이 없으면 최신 캔들 표시
    final candle =
        controller.selectedCandle ??
        (controller.candles.isNotEmpty ? controller.candles.last : null);

    if (candle == null) return const SizedBox.shrink();

    final hasTime = candle.date.hour != 0 || candle.date.minute != 0;
    final dateFormat = hasTime
        ? DateFormat('yyyy.MM.dd HH:mm')
        : DateFormat('yyyy.MM.dd');
    final priceFormat = NumberFormat('#,###');
    final volumeFormat = NumberFormat('#,###');
    final isUp = candle.isBullish;
    final color = isUp ? const Color(0xFFEF5350) : const Color(0xFF42A5F5);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: const Color(0xFF0D1117), // 배경색 통일
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text(
              dateFormat.format(candle.date),
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            _infoChip('시', priceFormat.format(candle.open), color),
            _infoChip('고', priceFormat.format(candle.high), color),
            _infoChip('저', priceFormat.format(candle.low), color),
            _infoChip('종', priceFormat.format(candle.close), color),
            const SizedBox(width: 8),
            Text(
              '거래량 ${volumeFormat.format(candle.volume)}',
              style: TextStyle(color: Colors.grey[500], fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
