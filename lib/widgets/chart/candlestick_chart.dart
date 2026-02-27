import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/chart_candle.dart';

/// 커스텀 캔들스틱 차트 위젯
/// CustomPainter를 사용하여 OHLC 캔들 + 거래량 바를 그립니다.
class CandlestickChart extends StatefulWidget {
  final List<ChartCandle> candles;
  final VoidCallback? onLoadMore;
  final bool hasMore;
  final bool isLoadingMore;
  final void Function(ChartCandle?)? onSelectCandle;

  const CandlestickChart({
    super.key,
    required this.candles,
    this.onLoadMore,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.onSelectCandle,
  });

  @override
  State<CandlestickChart> createState() => _CandlestickChartState();
}

class _CandlestickChartState extends State<CandlestickChart> {
  int? _selectedIndex;
  double _scale = 0.5; // 초기값을 작게 하여 더 많은 캔들 표시
  double _offset = 0.0; // x축 이동
  double _prevScale = 1.0; // 이전 스케일
  bool _initialized = false;
  double _chartWidth = 0;

  double get _candleWidth => 12.0 * _scale;
  double get _totalWidth =>
      (widget.candles.length + 5) * _candleWidth; // +5캔들 오른쪽 여백

  /// 최신 데이터가 오른쪽 끝에 오도록 초기 오프셋 설정
  void _initOffset(double viewWidth) {
    if (!_initialized || _chartWidth != viewWidth) {
      _chartWidth = viewWidth;
      if (_totalWidth > viewWidth) {
        _offset = -(_totalWidth - viewWidth);
      } else {
        _offset = 0;
      }
      _initialized = true;
    }
  }

  /// 오프셋을 유효 범위로 제한 + 추가 데이터 자동 로드
  void _clampOffset() {
    if (_totalWidth <= _chartWidth) {
      _offset = 0;
      // 모든 데이터가 화면에 보이므로 추가 로드 가능
      _tryLoadMore();
    } else {
      final minOffset = -(_totalWidth - _chartWidth);
      _offset = _offset.clamp(minOffset, 0.0);

      // 화면에 보이는 첫 번째 캔들 인덱스 계산
      final firstVisibleIdx = ((-_offset) / _candleWidth).floor();
      // 첫 5개 캔들이 보일 때만 추가 로드 트리거
      if (firstVisibleIdx <= 5) {
        _tryLoadMore();
      }
    }
  }

  bool _loadMoreTriggered = false;

  void _tryLoadMore() {
    if (widget.hasMore && !widget.isLoadingMore && !_loadMoreTriggered) {
      _loadMoreTriggered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onLoadMore?.call();
      });
    }
  }

  /// 오른쪽 끝 기준 줌: 줌 전후 오른쪽 끝에 보이는 캔들이 고정
  void _zoomFromRight(double newScale) {
    final oldScale = _scale;
    newScale = newScale.clamp(0.2, 5.0);
    // 현재 오른쪽 끝 위치 (데이터 공간)
    final rightEdge = (_chartWidth - _offset) / (12.0 * oldScale);
    _scale = newScale;
    // 같은 데이터 위치가 오른쪽 끝에 오도록 오프셋 재계산
    _offset = _chartWidth - rightEdge * 12.0 * _scale;
    _clampOffset();
  }

  @override
  void didUpdateWidget(covariant CandlestickChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.candles.length != widget.candles.length) {
      final addedCount = widget.candles.length - oldWidget.candles.length;
      if (oldWidget.candles.isEmpty) {
        // 첫 로드: 최신 데이터(오른쪽 끝)로 이동
        if (_chartWidth > 0 && _totalWidth > _chartWidth) {
          _offset = -(_totalWidth - _chartWidth);
        }
      } else if (addedCount > 0) {
        // 추가 로드 완료: 쿨다운 리셋
        _loadMoreTriggered = false;
        // 과거 데이터가 앞에 추가되므로, 현재 뷰 위치 유지
        _offset -= addedCount * _candleWidth;
        _clampOffset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.candles.isEmpty) {
      return Center(
        child: Text(
          '데이터 없음',
          style: TextStyle(color: Colors.grey[500], fontSize: 16),
        ),
      );
    }

    return Column(
      children: [
        // 줌 컨트롤 버튼
        _buildZoomControls(),
        // 캔들 차트 영역 (70%)
        Expanded(
          flex: 7,
          child: LayoutBuilder(
            builder: (context, constraints) {
              _initOffset(constraints.maxWidth);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: _onScaleStart,
                onScaleUpdate: _onScaleUpdate,
                onTapUp: (details) => _onTap(details, context),
                child: ClipRect(
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: _CandlePainter(
                      candles: widget.candles,
                      selectedIndex: _selectedIndex,
                      scale: _scale,
                      offset: _offset,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // 거래량 차트 영역 (30%)
        Expanded(
          flex: 3,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ClipRect(
                child: CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _VolumePainter(
                    candles: widget.candles,
                    selectedIndex: _selectedIndex,
                    scale: _scale,
                    offset: _offset,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildZoomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '${(_scale * 100).toInt()}%',
            style: TextStyle(color: Colors.grey[500], fontSize: 11),
          ),
          const SizedBox(width: 8),
          _zoomButton(Icons.remove, () {
            setState(() {
              _zoomFromRight(_scale - 0.15);
            });
          }),
          const SizedBox(width: 4),
          _zoomButton(Icons.add, () {
            setState(() {
              _zoomFromRight(_scale + 0.15);
            });
          }),
          const SizedBox(width: 4),
          _zoomButton(Icons.fit_screen, () {
            setState(() {
              // 전체 데이터를 화면에 맞추기
              if (_chartWidth > 0 && widget.candles.isNotEmpty) {
                _scale = (_chartWidth / (widget.candles.length * 12.0)).clamp(
                  0.2,
                  5.0,
                );
                _offset = 0;
                _clampOffset();
              }
            });
          }),
        ],
      ),
    );
  }

  Widget _zoomButton(IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 14),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xFF16213E),
          foregroundColor: const Color(0xFF4FC3F7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    _prevScale = _scale;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      if (details.scale != 1.0) {
        // 핀치 줌: 오른쪽 끝 기준으로 확대/축소
        _zoomFromRight(_prevScale * details.scale);
      }
      // 드래그: focalPointDelta는 이전 프레임 대비 증분값
      _offset += details.focalPointDelta.dx;
      _clampOffset();
    });
  }

  void _onTap(TapUpDetails details, BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox;
    final localPos = renderBox.globalToLocal(details.globalPosition);
    final idx = ((localPos.dx - _offset) / _candleWidth).floor();

    if (idx >= 0 && idx < widget.candles.length) {
      setState(() {
        _selectedIndex = idx;
      });
      widget.onSelectCandle?.call(widget.candles[idx]);
    }
  }
}

/// 캔들스틱 페인터
class _CandlePainter extends CustomPainter {
  final List<ChartCandle> candles;
  final int? selectedIndex;
  final double scale;
  final double offset;

  _CandlePainter({
    required this.candles,
    this.selectedIndex,
    required this.scale,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final candleWidth = 12.0 * scale;
    final bodyWidth = candleWidth * 0.6;

    // 현재 뷰에 보이는 캔들 범위 계산
    final startIdx = ((-offset) / candleWidth).floor().clamp(
      0,
      candles.length - 1,
    );
    final endIdx = ((size.width - offset) / candleWidth).ceil().clamp(
      0,
      candles.length,
    );

    // 보이는 범위의 min/max 가격 계산
    double minPrice = double.infinity;
    double maxPrice = double.negativeInfinity;
    for (int i = startIdx; i < endIdx; i++) {
      if (candles[i].low < minPrice) minPrice = candles[i].low;
      if (candles[i].high > maxPrice) maxPrice = candles[i].high;
    }

    final priceRange = maxPrice - minPrice;
    if (priceRange == 0) return;

    // 여백
    final padding = priceRange * 0.05;
    final adjustedMin = minPrice - padding;
    final adjustedRange = priceRange + padding * 2;

    // 가격 그리드 라인 (캔들 뒤)
    _drawGridLines(canvas, size, adjustedMin, adjustedRange);

    // 캔들 그리기
    for (int i = startIdx; i < endIdx; i++) {
      final candle = candles[i];
      final x = i * candleWidth + offset + candleWidth / 2;

      final isUp = candle.close >= candle.open;
      final color = isUp ? const Color(0xFFEF5350) : const Color(0xFF42A5F5);

      // 그림자 (위꼬리 ~ 아래꼬리)
      final highY =
          size.height -
          ((candle.high - adjustedMin) / adjustedRange) * size.height;
      final lowY =
          size.height -
          ((candle.low - adjustedMin) / adjustedRange) * size.height;

      canvas.drawLine(
        Offset(x, highY),
        Offset(x, lowY),
        Paint()
          ..color = color
          ..strokeWidth = 1.0,
      );

      // 몸통
      final openY =
          size.height -
          ((candle.open - adjustedMin) / adjustedRange) * size.height;
      final closeY =
          size.height -
          ((candle.close - adjustedMin) / adjustedRange) * size.height;

      final bodyTop = isUp ? closeY : openY;
      final bodyBottom = isUp ? openY : closeY;
      final bodyHeight = (bodyBottom - bodyTop).clamp(1.0, double.infinity);

      final bodyRect = Rect.fromLTWH(
        x - bodyWidth / 2,
        bodyTop,
        bodyWidth,
        bodyHeight,
      );

      canvas.drawRect(
        bodyRect,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );

      // 선택된 캔들 하이라이트
      if (selectedIndex == i) {
        canvas.drawLine(
          Offset(x, 0),
          Offset(x, size.height),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.3)
            ..strokeWidth = 1.0,
        );
      }
    }

    // 가격 텍스트 (캔들 위에 그려짐)
    _drawPriceLabels(canvas, size, adjustedMin, adjustedRange);
  }

  void _drawGridLines(Canvas canvas, Size size, double minPrice, double range) {
    const gridCount = 5;
    for (int i = 0; i <= gridCount; i++) {
      final y = size.height * i / gridCount;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = Colors.grey[850]!
          ..strokeWidth = 0.5,
      );
    }
  }

  void _drawPriceLabels(
    Canvas canvas,
    Size size,
    double minPrice,
    double range,
  ) {
    const gridCount = 5;
    final priceFormat = NumberFormat('#,###');
    final textStyle = TextStyle(color: Colors.grey[400], fontSize: 12);

    for (int i = 0; i <= gridCount; i++) {
      final y = size.height * i / gridCount;
      final price = minPrice + range * (1 - i / gridCount);

      final textSpan = TextSpan(
        text: priceFormat.format(price.round()),
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(size.width - textPainter.width - 4, y + 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CandlePainter oldDelegate) =>
      oldDelegate.candles != candles ||
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.scale != scale ||
      oldDelegate.offset != offset;
}

/// 거래량 바 페인터
class _VolumePainter extends CustomPainter {
  final List<ChartCandle> candles;
  final int? selectedIndex;
  final double scale;
  final double offset;

  _VolumePainter({
    required this.candles,
    this.selectedIndex,
    required this.scale,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final candleWidth = 12.0 * scale;
    final barWidth = candleWidth * 0.6;

    final startIdx = ((-offset) / candleWidth).floor().clamp(
      0,
      candles.length - 1,
    );
    final endIdx = ((size.width - offset) / candleWidth).ceil().clamp(
      0,
      candles.length,
    );

    // 최대 거래량
    double maxVolume = 0;
    for (int i = startIdx; i < endIdx; i++) {
      if (candles[i].volume > maxVolume) maxVolume = candles[i].volume;
    }
    if (maxVolume == 0) return;

    // 구분선
    canvas.drawLine(
      const Offset(0, 0),
      Offset(size.width, 0),
      Paint()
        ..color = Colors.grey[800]!
        ..strokeWidth = 0.5,
    );

    for (int i = startIdx; i < endIdx; i++) {
      final candle = candles[i];
      final x = i * candleWidth + offset + candleWidth / 2;
      final barHeight = (candle.volume / maxVolume) * size.height * 0.9;

      final isUp = candle.close >= candle.open;
      final color = isUp
          ? const Color(0xFFEF5350).withValues(alpha: 0.6)
          : const Color(0xFF42A5F5).withValues(alpha: 0.6);

      canvas.drawRect(
        Rect.fromLTWH(
          x - barWidth / 2,
          size.height - barHeight,
          barWidth,
          barHeight,
        ),
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );

      // 선택된 캔들 하이라이트
      if (selectedIndex == i) {
        canvas.drawLine(
          Offset(x, 0),
          Offset(x, size.height),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.3)
            ..strokeWidth = 1.0,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _VolumePainter oldDelegate) =>
      oldDelegate.candles != candles ||
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.scale != scale ||
      oldDelegate.offset != offset;
}
