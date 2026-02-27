import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../models/stock_master.dart';
import '../models/stock_price_detail.dart';
import '../models/favorite_stock_batch.dart';

/// 관심종목 및 폴더 정보를 관리하는 서비스 클래스입니다.
/// 로컬 저장소(SharedPreferences)와 서버 API를 연동하여 데이터를 처리합니다.
class WatchlistService {
  // 로컬 저장소에 저장될 키 이름
  static const String _storageKey = 'watchlist_folders';

  // 비즈니스 로직 상의 제한 사항
  static const int maxFolders = 20; // 생성 가능한 최대 폴더 수
  static const int maxStocksPerFolder = 50; // 폴더당 담을 수 있는 최대 종목 수

  // API 서버 기본 주소
  static const String _baseUrl = ApiConstants.baseUrl;

  /// 사용자가 입력한 검색어(query)를 기반으로 종목 리스트를 검색합니다.
  /// [query]: 종목명 또는 종목 코드의 일부
  /// 리턴값: 검색 결과에 부합하는 [StockMaster] 리스트
  Future<List<StockMaster>> searchStocks(String query) async {
    final uri = Uri.parse(
      '$_baseUrl/api/market/search',
    ).replace(queryParameters: {'q': query});

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('종목 검색 실패: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    // 서버 응답의 'list' 필드에서 데이터를 추출하여 StockMaster 모델로 변환
    final list =
        (json['list'] as List?)?.map((e) => StockMaster.fromJson(e)).toList() ??
        [];
    return list;
  }

  /// 특정 종목의 상세 시세 정보를 서버로부터 조회합니다.
  /// [code]: 조회할 종목 코드 (예: '005930')
  Future<StockPriceDetail> fetchStockPriceDetail(String code) async {
    final uri = Uri.parse('$_baseUrl/api/market/price/$code');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('상세 시세 조회 실패: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('상세 시세 데이터가 응답에 포함되지 않았습니다.');
    }

    return StockPriceDetail.fromJson(data);
  }

  /// 여러 종목의 시세를 한 번의 API 호출로 대량(Bulk) 조회합니다.
  /// [codes]: 조회할 종목 코드 리스트
  /// 주로 관심종목 화면에서 여러 종목의 현재가를 실시간으로 업데이트할 때 사용합니다.
  Future<List<FavoriteStockDetail>> fetchFavoriteStocks(
    List<String> codes,
  ) async {
    if (codes.isEmpty) return [];

    // 종목 코드들을 '|' 구분자로 합쳐서 파라미터로 전달 (예: '005930|000660')
    final codesParam = codes.join('|');
    final uri = Uri.parse(
      '$_baseUrl/api/market/favorite',
    ).replace(queryParameters: {'codes': codesParam});

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('벌크 시세 조회 실패: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    // 응답 데이터를 FavoriteStockBatchResponse로 파싱하여 리턴
    return FavoriteStockBatchResponse.fromJson(json).stocks;
  }

  /// 현재 구성된 모든 폴더와 종목 정보를 로컬 저장소(SharedPreferences)에 저장합니다.
  /// [folders]: 저장할 [WatchlistFolder] 리스트
  Future<void> saveFolders(List<WatchlistFolder> folders) async {
    final prefs = await SharedPreferences.getInstance();
    // 모델 리스트를 JSON 문자열로 인코딩하여 저장
    final String encoded = jsonEncode(folders.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  /// 로컬 저장소에 저장되어 있는 폴더 및 종목 데이터를 불러옵니다.
  /// 리턴값: 저장된 [WatchlistFolder] 리스트. 데이터가 없으면 '기본 그룹' 폴더를 생성하여 반환합니다.
  Future<List<WatchlistFolder>> loadFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString(_storageKey);

    if (encoded == null || encoded.isEmpty) {
      // 저장된 데이터가 없는 경우 초기 상태 설정
      return [WatchlistFolder(id: 'default', name: '기본 그룹', stocks: [])];
    }

    final List decoded = jsonDecode(encoded);
    // JSON 리스트를 WatchlistFolder 모델 리스트로 변환
    return decoded.map((e) => WatchlistFolder.fromJson(e)).toList();
  }

  /// 새로운 관심종목 폴더를 추가합니다.
  /// [currentFolders]: 현재 유지 중인 폴더 리스트
  /// [name]: 새 폴더 이름
  Future<List<WatchlistFolder>> addFolder(
    List<WatchlistFolder> currentFolders,
    String name,
  ) async {
    // 1. 최대 폴더 개수 제한 확인
    if (currentFolders.length >= maxFolders) {
      throw Exception('최대 폴더 개수($maxFolders개)를 초과할 수 없습니다.');
    }

    // 2. 새 폴더 객체 생성 (ID는 타임스탬프 기반으로 유니크하게 생성)
    final newFolder = WatchlistFolder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      stocks: [],
    );

    // 3. 리스트 업데이트 후 로컬에 자동 저장
    final updated = List<WatchlistFolder>.from(currentFolders)..add(newFolder);
    await saveFolders(updated);
    return updated;
  }

  /// 특정 폴더에 새로운 종목을 추가합니다.
  /// [currentFolders]: 전체 폴더 리스트
  /// [folderId]: 종목을 추가할 대상 폴더의 고유 ID
  /// [stock]: 추가할 종목 정보 ([StockMaster])
  Future<List<WatchlistFolder>> addStockToFolder(
    List<WatchlistFolder> currentFolders,
    String folderId,
    StockMaster stock,
  ) async {
    final updated = currentFolders.map((f) {
      if (f.id == folderId) {
        // 1. 폴더당 종목 개수 제한 확인
        if (f.stocks.length >= maxStocksPerFolder) {
          throw Exception('폴더당 최대 종목 개수($maxStocksPerFolder개)를 초과할 수 없습니다.');
        }
        // 2. 이미 등록된 종목인지 중복 확인
        if (f.stocks.any((s) => s.code == stock.code)) {
          throw Exception('이미 등록된 종목입니다.');
        }
        // 3. 해당 폴더의 종목 리스트에 추가
        return WatchlistFolder(
          id: f.id,
          name: f.name,
          stocks: List<StockMaster>.from(f.stocks)..add(stock),
        );
      }
      return f;
    }).toList();

    // 업데이트된 전체 구조를 로컬에 저장
    await saveFolders(updated);
    return updated;
  }
}
