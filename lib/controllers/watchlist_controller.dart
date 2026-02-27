import 'dart:async';
import 'package:flutter/material.dart';
import '../models/stock_master.dart';
import '../models/stock_price_detail.dart';
import '../models/market_status.dart';
import '../services/watchlist_service.dart';
import '../services/websocket_service.dart';

/// 관심종목 화면의 비즈니스 로직 및 상태를 관리하는 컨트롤러입니다.
/// ChangeNotifier를 확장하여 상태 변경 시 UI에 알림을 보냅니다.
class WatchlistController extends ChangeNotifier {
  final WatchlistService _watchlistService = WatchlistService();
  final WebSocketService _webSocketService = WebSocketService();

  // 상태 변수들
  List<WatchlistFolder> _folders = []; // 전체 폴더 및 종목 리스트
  int _selectedFolderIndex = 0; // 현재 선택된 폴더의 인덱스
  bool _isLoading = true; // 초기 데이터 로딩 여부

  // 시세 및 상세 데이터 저장소
  final Map<String, RealtimePrice> _realtimePrices = {}; // 웹소켓 실시간 가격 수신용
  final Map<String, StockPriceDetail> _stockDetails = {}; // API 상세 시세 저장용

  // 스트림 구독 및 시장 상태
  StreamSubscription? _priceSubscription; // 실시간 가격 스트림 구독 처리
  StreamSubscription? _marketSubscription; // 시장 상태(개장/폐장 등) 스트림 구독 처리
  MarketStatus? _marketStatus; // 현재 전송받은 시장 상태

  // 검색 관련 상태
  List<StockMaster> _searchResults = []; // 검색 결과 리스트
  bool _isSearching = false; // 검색 진행 중 여부
  Timer? _debounce; // API 호출 부하를 줄이기 위한 디바운스 타이머

  // 리소스 해제 확인용 플래그
  bool _isDisposed = false;

  // UI에서 접근하기 위한 Getters
  List<WatchlistFolder> get folders => _folders;
  int get selectedFolderIndex => _selectedFolderIndex;
  bool get isLoading => _isLoading;
  Map<String, RealtimePrice> get realtimePrices => _realtimePrices;
  Map<String, StockPriceDetail> get stockDetails => _stockDetails;
  MarketStatus? get marketStatus => _marketStatus;
  List<StockMaster> get searchResults => _searchResults;
  bool get isSearching => _isSearching;

  /// 현재 선택된 폴더 정보를 반환합니다.
  WatchlistFolder? get currentFolder =>
      _folders.isNotEmpty ? _folders[_selectedFolderIndex] : null;

  /// 컨트롤러 초기화 시 호출됩니다. 웹소켓 연결 및 초기 데이터를 로드합니다.
  void init() {
    _initWebSocket();
    _loadData();
  }

  /// 웹소켓을 연결하고 가격/시장 상태 스트림을 리스닝합니다.
  void _initWebSocket() {
    _webSocketService.connect();

    // 실시간 가격 업데이트 리스너
    _priceSubscription = _webSocketService.priceStream.listen((priceUpdate) {
      _realtimePrices[priceUpdate.code] = priceUpdate;
      notifyListeners(); // UI 갱신 일괄 요청
    });

    // 시장 상태 업데이트 리스너
    _marketSubscription = _webSocketService.marketStream.listen((status) {
      _marketStatus = status;
      notifyListeners();
    });
  }

  /// 로컬 저장소에서 폴더 정보를 로드하고 초기 구독을 시작합니다.
  Future<void> _loadData() async {
    try {
      final data = await _watchlistService.loadFolders();
      _folders = data;
      _isLoading = false;
      notifyListeners();

      // 상세 시세 조회 및 실시간 웹소켓 구독 시작
      _loadDetailedPrices();
      _subscribeToCurrentFolder();
    } catch (e) {
      debugPrint('WatchlistController _loadData error: $e');
    }
  }

  /// 현재 선택된 폴더에 포함된 모든 종목들에 대해 실시간 시세 구독을 신청합니다.
  void _subscribeToCurrentFolder() {
    final folder = currentFolder;
    if (folder == null) return;
    for (var stock in folder.stocks) {
      // 'A' 접두사가 붙은 경우 제거 후 신청 (서버 규격)
      final code = stock.code.startsWith('A')
          ? stock.code.substring(1)
          : stock.code;
      _webSocketService.subscribe(code);
    }
  }

  /// 현재 선택된 폴더의 종목들에 대한 실시간 시세 구독을 해지합니다.
  void _unsubscribeFromCurrentFolder() {
    final folder = currentFolder;
    if (folder == null) return;
    for (var stock in folder.stocks) {
      final code = stock.code.startsWith('A')
          ? stock.code.substring(1)
          : stock.code;
      _webSocketService.unsubscribe(code);
    }
  }

  /// 서버에서 현재 폴더 내 종목들의 상세 시세(벌크 조회)를 가져옵니다.
  /// 초기 화면 진입 시 또는 폴더 전환 시 호출됩니다.
  Future<void> _loadDetailedPrices() async {
    final folder = currentFolder;
    if (folder == null || folder.stocks.isEmpty) return;

    final List<String> codes = folder.stocks.map((s) => s.code).toList();

    try {
      // API를 통해 여러 종목 시세를 한 번에 조회
      final batchDetails = await _watchlistService.fetchFavoriteStocks(codes);

      for (var detail in batchDetails) {
        String codeKey = detail.stkCd;
        // 서버에서 오는 코드는 'A'가 없을 수 있으므로 로컬 코드 키와 매칭 보정
        if (!codeKey.startsWith('A')) {
          final matchedCode = codes.firstWhere(
            (c) => c == 'A$codeKey' || c == codeKey,
            orElse: () => codeKey,
          );
          codeKey = matchedCode;
        }

        _stockDetails[codeKey] = StockPriceDetail.fromFavoriteBatch(detail);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('벌크 시세 로드 실패: $e');
    }
  }

  /// 상단 탭 등에서 다른 폴더를 선택했을 때 처리합니다.
  /// 기존 폴더 구독 해지 -> 인덱스 변경 -> 새 폴더 데이터 조회 및 구독
  void switchFolder(int index) {
    if (_selectedFolderIndex == index) return;

    _unsubscribeFromCurrentFolder();
    _selectedFolderIndex = index;
    notifyListeners();

    _loadDetailedPrices();
    _subscribeToCurrentFolder();
  }

  /// 종목 검색 필드의 입력값에 따라 주식 종목을 검색합니다.
  /// 불필요한 API 호출을 막기 위해 500ms 디바운싱이 적용되어 있습니다.
  Future<void> handleSearch(String query) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      _isSearching = true;
      notifyListeners();
      try {
        _searchResults = await _watchlistService.searchStocks(query);
      } catch (e) {
        debugPrint('Search error: $e');
      } finally {
        _isSearching = false;
        notifyListeners();
      }
    });
  }

  /// 선택된 종목을 현재 활성화된 폴더에 추가합니다.
  /// 저장소 업데이트 후 해당 종목의 시세를 즉시 구독합니다.
  Future<void> addStock(StockMaster stock) async {
    final folder = currentFolder;
    if (folder == null) return;

    try {
      // 1. 서비스 클래스를 통해 로컬/서버에 종목 저장
      final updated = await _watchlistService.addStockToFolder(
        _folders,
        folder.id,
        stock,
      );
      _folders = updated;
      _searchResults = []; // 검색창 비우기
      notifyListeners();

      // 2. 추가된 개별 종목의 상세 시세를 즉시 한 번 페칭
      try {
        final detail = await _watchlistService.fetchStockPriceDetail(
          stock.code,
        );
        _stockDetails[detail.stkCd] = detail;
        notifyListeners();
      } catch (_) {}

      // 3. 웹소켓 실시간 시세 구독 추가
      final code = stock.code.startsWith('A')
          ? stock.code.substring(1)
          : stock.code;
      _webSocketService.subscribe(code);
    } catch (e) {
      // 중복 등록이나 개수 초과 등의 에러 발생 시 UI로 전파
      rethrow;
    }
  }

  /// 특정 종목을 해당 폴더에서 제거하고 웹소켓 구독을 끊습니다.
  Future<void> removeStock(int index, String code) async {
    final folder = currentFolder;
    if (folder == null) return;

    // 구독 해지
    final normalizedCode = code.startsWith('A') ? code.substring(1) : code;
    _webSocketService.unsubscribe(normalizedCode);

    // 리스트에서 삭제 및 저장
    folder.stocks.removeAt(index);
    notifyListeners();
    await _watchlistService.saveFolders(_folders);
  }

  /// 폴더 내의 종목 순서를 변경합니다. (ReorderableListView 등에서 사용)
  Future<void> reorderStocks(int oldIndex, int newIndex) async {
    final folder = currentFolder;
    if (folder == null) return;

    if (newIndex > oldIndex) newIndex -= 1;
    final item = folder.stocks.removeAt(oldIndex);
    folder.stocks.insert(newIndex, item);

    notifyListeners();
    await _watchlistService.saveFolders(_folders);
  }

  /// 폴더 리스트에 새로운 그룹 폴더를 추가합니다.
  Future<void> addFolder(String name) async {
    try {
      final updated = await _watchlistService.addFolder(_folders, name);
      _folders = updated;
      // 생성된 새 폴더로 자동 포커스 이동
      _selectedFolderIndex = _folders.length - 1;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// 위젯이 살아있는 상태일 때만 알림을 보내 비정상 종료를 방지합니다.
  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  /// 컨트롤러 종료 시 리소스를 정리합니다. (구독 취소, 웹소켓 차단 등)
  @override
  void dispose() {
    _isDisposed = true;
    _priceSubscription?.cancel();
    _marketSubscription?.cancel();
    _webSocketService.disconnect();
    _debounce?.cancel();
    super.dispose();
  }
}
