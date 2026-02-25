import 'dart:async';

import 'package:flutter/material.dart';

import '../models/chart_candle.dart';
import '../services/chart_service.dart';
import '../widgets/candlestick_chart.dart';

/// 차트 탭 화면
/// 종목 코드를 입력하여 일반 조회 또는 스트리밍으로 캔들스틱 차트를 표시
class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  final _codeController = TextEditingController(text: '005930');
  final _chartService = ChartService();

  List<ChartCandle> _candles = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  bool _isStreaming = false;
  int _totalReceived = 0;
  StreamSubscription? _streamSubscription;

  // Pagination 상태
  String? _contYn;
  String? _nextKey;
  String? _loadedCode; // 현재 로드된 종목 코드

  bool get _hasMore => _contYn == 'Y';

  @override
  void dispose() {
    _codeController.dispose();
    _streamSubscription?.cancel();
    super.dispose();
  }

  /// [방식 A] 일반 조회 — 첫 페이지 가져오기
  Future<void> _fetchData() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    // 같은 종목이 이미 로드되어 있으면 무시
    if (code == _loadedCode && _candles.isNotEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _candles = [];
      _totalReceived = 0;
      _contYn = null;
      _nextKey = null;
      _loadedCode = code;
    });

    try {
      final result = await _chartService.fetchChartPage(code);
      final candles = result.candles;
      // 날짜 오름차순 정렬
      candles.sort((a, b) => a.date.compareTo(b.date));

      setState(() {
        _candles = candles;
        _totalReceived = candles.length;
        _contYn = result.contYn;
        _nextKey = result.nextKey;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// 추가 데이터 로드 (Pagination)
  Future<void> _loadMoreData() async {
    if (!_hasMore || _isLoadingMore) return;

    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isLoadingMore = true;
    });

    // API 요청 간 최소 1초 간격 유지
    await Future.delayed(const Duration(seconds: 1));

    try {
      final result = await _chartService.fetchChartPage(
        code,
        contYn: _contYn,
        nextKey: _nextKey,
      );

      final newCandles = result.candles;
      final allCandles = [..._candles, ...newCandles];
      // 날짜 오름차순 정렬
      allCandles.sort((a, b) => a.date.compareTo(b.date));

      setState(() {
        _candles = allCandles;
        _totalReceived = allCandles.length;
        _contYn = result.contYn;
        _nextKey = result.nextKey;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoadingMore = false;
      });
    }
  }

  /// [방식 B] 스트리밍 조회 — NDJSON 스트림으로 점진적 수신
  void _startStream() {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    // 같은 종목이 이미 로드되어 있으면 무시
    if (code == _loadedCode && _candles.isNotEmpty) return;

    _streamSubscription?.cancel();

    setState(() {
      _isStreaming = true;
      _isLoading = true;
      _errorMessage = null;
      _candles = [];
      _totalReceived = 0;
      _contYn = null;
      _nextKey = null;
    });

    final allCandles = <ChartCandle>[];

    _streamSubscription = _chartService
        .streamChartData(code)
        .listen(
          (pageCandles) {
            allCandles.addAll(pageCandles);
            allCandles.sort((a, b) => a.date.compareTo(b.date));

            setState(() {
              _candles = List.from(allCandles);
              _totalReceived = allCandles.length;
            });
          },
          onError: (e) {
            setState(() {
              _errorMessage = e.toString();
              _isLoading = false;
              _isStreaming = false;
            });
          },
          onDone: () {
            setState(() {
              _isLoading = false;
              _isStreaming = false;
            });
          },
        );
  }

  void _stopStream() {
    _streamSubscription?.cancel();
    setState(() {
      _isStreaming = false;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildControls(),
        _buildStatusBar(),
        Expanded(child: _buildChart()),
      ],
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        border: Border(
          bottom: BorderSide(color: Colors.grey[850]!, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF0F3460), width: 1),
              ),
              child: TextField(
                controller: _codeController,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: const InputDecoration(
                  hintText: '종목 코드 (예: 005930)',
                  hintStyle: TextStyle(color: Color(0xFF506680), fontSize: 13),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: InputBorder.none,
                  prefixIcon: Icon(
                    Icons.search,
                    color: Color(0xFF506680),
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            label: '조회',
            icon: Icons.download,
            onPressed: _isLoading ? null : _fetchData,
            color: const Color(0xFF0F3460),
          ),
          const SizedBox(width: 6),
          _buildActionButton(
            label: _isStreaming ? '중지' : '스트림',
            icon: _isStreaming ? Icons.stop : Icons.stream,
            onPressed: _isStreaming
                ? _stopStream
                : (_isLoading ? null : _startStream),
            color: _isStreaming
                ? const Color(0xFFB71C1C)
                : const Color(0xFF1B5E20),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return SizedBox(
      height: 40,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: const Color(0xFF0D1117),
      child: Row(
        children: [
          if (_isLoading || _isLoadingMore)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF4FC3F7),
              ),
            ),
          if (_isLoading || _isLoadingMore) const SizedBox(width: 8),
          Text(
            _isStreaming
                ? '스트리밍 수신 중...'
                : _isLoadingMore
                ? '추가 데이터 로딩 중...'
                : _isLoading
                ? '데이터 로딩 중...'
                : _hasMore
                ? '대기 중'
                : _candles.isNotEmpty
                ? '전체 로드 완료'
                : '',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
          const Spacer(),
          if (_hasMore)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '추가 데이터 있음',
                style: TextStyle(
                  color: Color(0xFF66BB6A),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$_totalReceived건',
              style: const TextStyle(
                color: Color(0xFF4FC3F7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(width: 8),
            Icon(Icons.error_outline, color: Colors.red[400], size: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (_errorMessage != null && _candles.isEmpty) {
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
                _errorMessage!,
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_candles.isEmpty && !_isLoading) {
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
              '일반 조회 또는 스트리밍 방식을 선택할 수 있습니다',
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Container(
      color: const Color(0xFF0D1117),
      child: CandlestickChart(
        candles: _candles,
        hasMore: _hasMore,
        isLoadingMore: _isLoadingMore,
        onLoadMore: _loadMoreData,
      ),
    );
  }
}
