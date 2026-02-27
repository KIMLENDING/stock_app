import 'package:flutter/material.dart';
import '../../controllers/chart_controller.dart';
import '../../models/chart_types.dart';

class ChartStatusBar extends StatelessWidget {
  final ChartController controller;

  const ChartStatusBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF0D1117),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: 종목 정보 및 상태 메시지
          Row(
            children: [
              if (controller.loadedStockName != null)
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          controller.loadedStockName!,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${controller.codeController.text})',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 8),
              if (controller.isLoading || controller.isLoadingMore)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF4FC3F7),
                  ),
                ),
              if (controller.isLoading || controller.isLoadingMore)
                const SizedBox(width: 6),
              Text(
                controller.isLoadingMore
                    ? '로딩 중'
                    : controller.isLoading
                    ? '데이터 로딩 중...'
                    : controller.hasMore
                    ? '대기 중'
                    : controller.candles.isNotEmpty
                    ? '완료'
                    : '',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Row 2: 뱃지 정보 (차트타입, 추가데이터 여부, 총 데이터 건수)
          Row(
            children: [
              if (controller.candles.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F3460).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    controller.loadedChartType == ChartType.minute
                        ? '${controller.loadedMinuteScope}분봉'
                        : '일봉',
                    style: const TextStyle(
                      color: Color(0xFF4FC3F7),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (controller.hasMore) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '추가데이터 있음',
                    style: TextStyle(
                      color: Color(0xFF66BB6A),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${controller.totalReceived}건',
                  style: const TextStyle(
                    color: Color(0xFF4FC3F7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (controller.errorMessage != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.error_outline, color: Colors.red[400], size: 16),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
