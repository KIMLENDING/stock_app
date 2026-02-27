import 'package:flutter/material.dart';

import '../controllers/chart_controller.dart';
import '../widgets/chart/candlestick_chart.dart';
import '../widgets/chart/chart_controls.dart';
import '../widgets/chart/chart_status_bar.dart';
import '../widgets/chart/chart_candle_info.dart';
import '../widgets/chart/chart_type_bar.dart';

/// 차트 탭 화면
class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  late final ChartController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ChartController();
    // 화면 진입 시 초기 데이터 자동 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fetchData();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Column(
          children: [
            ChartControls(controller: _controller),
            ChartStatusBar(controller: _controller),
            ChartCandleInfo(controller: _controller),
            ChartTypeBar(controller: _controller),
            Expanded(child: _buildChart()),
          ],
        );
      },
    );
  }

  Widget _buildChart() {
    if (_controller.errorMessage != null && _controller.candles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                '오류 발생',
                style: TextStyle(
                  color: Colors.red[400],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _controller.errorMessage!,
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_controller.candles.isEmpty && !_controller.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.candlestick_chart, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text(
              '종목 코드를 입력하고 조회하세요',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              '일봉 / 분봉 차트를 선택할 수 있습니다',
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Container(
      color: const Color(0xFF0D1117),
      child: CandlestickChart(
        candles: _controller.candles,
        hasMore: _controller.hasMore,
        isLoadingMore: _controller.isLoadingMore,
        onLoadMore: _controller.loadMoreData,
        onSelectCandle: _controller.selectCandle,
      ),
    );
  }
}
