import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chart_candle.dart';
import '../models/chart_types.dart';
import '../models/stock_master.dart';
import '../services/chart_service.dart';
import '../services/watchlist_service.dart';

class ChartController extends ChangeNotifier {
  final ChartService _chartService = ChartService();
  final WatchlistService _watchlistService = WatchlistService();
  final TextEditingController codeController = TextEditingController(
    text: '005930',
  );

  List<ChartCandle> _candles = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _totalReceived = 0;

  // Pagination 상태
  String? _contYn;
  String? _nextKey;
  String? _loadedCode;
  String? _loadedStockName;

  // 차트 타입 상태
  ChartType _chartType = ChartType.daily;
  int _minuteScope = 1; // 1, 3, 5, 10, 15, 30, 45, 60
  ChartType? _loadedChartType; // 현재 로드된 차트 타입
  int? _loadedMinuteScope; // 현재 로드된 분봉 스코프

  // 선택된 캔들 정보
  ChartCandle? _selectedCandle;

  // 검색 관련 상태
  List<StockMaster> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounceTimer;

  // Getters
  List<ChartCandle> get candles => _candles;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  int get totalReceived => _totalReceived;
  ChartType get chartType => _chartType;
  int get minuteScope => _minuteScope;
  ChartType? get loadedChartType => _loadedChartType;
  int? get loadedMinuteScope => _loadedMinuteScope;
  ChartCandle? get selectedCandle => _selectedCandle;
  bool get hasMore => _contYn == 'Y';
  List<StockMaster> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  String? get loadedStockName => _loadedStockName;

  void setChartType(ChartType type) {
    if (_chartType != type) {
      _chartType = type;
      notifyListeners();
      resetAndFetch();
    }
  }

  void setMinuteScope(int scope) {
    if (_minuteScope != scope) {
      _minuteScope = scope;
      notifyListeners();
      resetAndFetch();
    }
  }

  void selectCandle(ChartCandle? candle) {
    _selectedCandle = candle;
    notifyListeners();
  }

  /// 데이터 초기화 및 새로 조회
  void resetAndFetch() {
    _candles = [];
    _totalReceived = 0;
    _contYn = null;
    _nextKey = null;
    _loadedCode = null;
    _loadedStockName = null;
    _loadedChartType = null;
    _loadedMinuteScope = null;
    _errorMessage = null;
    _selectedCandle = null;
    notifyListeners();
    fetchData();
  }

  /// 조회 — 첫 페이지 가져오기 (일봉/분봉 공통)
  Future<void> fetchData() async {
    final code = codeController.text.trim();
    if (code.isEmpty) return;

    // 같은 종목+같은 타입+같은 스코프가 이미 로드되어 있으면 무시
    if (code == _loadedCode &&
        _chartType == _loadedChartType &&
        (_chartType == ChartType.daily || _minuteScope == _loadedMinuteScope) &&
        _candles.isNotEmpty) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _candles = [];
    _totalReceived = 0;
    _contYn = null;
    _nextKey = null;
    _loadedCode = code;
    _loadedChartType = _chartType;
    _loadedMinuteScope = _minuteScope;
    // 종목명이 없을 경우(직접 코드 입력) fetch 시점에 업데이트 예정
    _selectedCandle = null;
    notifyListeners();

    try {
      final result = _chartType == ChartType.daily
          ? await _chartService.fetchChartPage(code)
          : await _chartService.fetchMinuteChartPage(
              code,
              ticScope: _minuteScope,
            );
      final fetchedCandles = result.candles;
      fetchedCandles.sort((a, b) => a.date.compareTo(b.date));

      _candles = fetchedCandles;
      _totalReceived = fetchedCandles.length;
      _contYn = result.contYn;
      _nextKey = result.nextKey;

      // 종목 정보 조회하여 이름 업데이트 (코드가 있는데 이름이 없거나 다를 때)
      if (_loadedStockName == null) {
        try {
          final detail = await _watchlistService.fetchStockPriceDetail(code);
          _loadedStockName = detail.stkNm;
        } catch (_) {
          // 이름 가져오기 실패 시 코드로 대체하거나 유지
          _loadedStockName = code;
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 추가 데이터 로드 (Pagination)
  Future<void> loadMoreData() async {
    if (!hasMore || _isLoadingMore) return;

    final code = codeController.text.trim();
    if (code.isEmpty) return;

    _isLoadingMore = true;
    notifyListeners();

    // UI 경험을 위해 약간의 지연 (선택 사항)
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final result = _chartType == ChartType.daily
          ? await _chartService.fetchChartPage(
              code,
              contYn: _contYn,
              nextKey: _nextKey,
            )
          : await _chartService.fetchMinuteChartPage(
              code,
              ticScope: _minuteScope,
              contYn: _contYn,
              nextKey: _nextKey,
            );

      final newCandles = result.candles;
      final allCandles = [..._candles, ...newCandles];
      allCandles.sort((a, b) => a.date.compareTo(b.date));

      _candles = allCandles;
      _totalReceived = allCandles.length;
      _contYn = result.contYn;
      _nextKey = result.nextKey;
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    codeController.dispose();
    super.dispose();
  }

  /// 종목명 또는 코드로 검색
  void searchStocks(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();

    if (query.isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      _isSearching = true;
      notifyListeners();

      try {
        _searchResults = await _watchlistService.searchStocks(query);
      } catch (e) {
        _searchResults = [];
      } finally {
        _isSearching = false;
        notifyListeners();
      }
    });
  }

  /// 검색 결과에서 종목 선택
  void selectStock(StockMaster stock) {
    codeController.text = stock.code;
    _loadedStockName = stock.name;
    _searchResults = [];
    _isSearching = false;
    notifyListeners();
    resetAndFetch();
  }
}
