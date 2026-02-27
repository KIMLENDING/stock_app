import 'dart:async';
import 'package:flutter/material.dart';
import '../services/account_service.dart';
import '../models/account_evaluation.dart';
import '../services/websocket_service.dart';
import '../models/stock_master.dart';
import '../models/market_status.dart';

import '../widgets/account/account_summary_card.dart';
import '../widgets/account/account_stock_tile.dart';

/// 사용자의 보유 자산 현황과 주식 평가 내역을 종합적으로 보여주는 '계좌' 탭 화면입니다.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final AccountService _accountService = AccountService();
  final WebSocketService _webSocketService = WebSocketService();

  AccountData? _accountData; // 서버에서 불러온 계좌 원장 데이터
  bool _isLoading = true; // 로딩 상태 플래그
  String? _errorMessage; // 에러 메시지 데이터

  // 실시간 가격 정보 저장소 (종목코드 -> 실시간 가격 모델)
  final Map<String, RealtimePrice> _realtimePrices = {};

  // 스트림 구독 관리
  StreamSubscription? _priceSubscription; // 주시 종목 가격 스트림
  StreamSubscription? _marketSubscription; // 시장 개장 현황 스트림
  MarketStatus? _marketStatus; // 현재 전송받은 시장 상태

  @override
  void initState() {
    super.initState();
    _initWebSocket(); // 1. 웹소켓 시스템 연결
    _fetchData(); // 2. 계좌 기본 데이터 불러오기
  }

  /// 웹소켓을 초기화하고 서버로부터 실시간 데이터(가격, 시장상태)를 리스닝합니다.
  void _initWebSocket() {
    _webSocketService.connect();

    // 개별 종목의 가격 업데이트 수신
    _priceSubscription = _webSocketService.priceStream.listen((priceUpdate) {
      if (mounted) {
        setState(() {
          _realtimePrices[priceUpdate.code] = priceUpdate;
        });
      }
    });

    // 시장 전체 상태(정규장, 장외 등) 업데이트 수신
    _marketSubscription = _webSocketService.marketStream.listen((status) {
      if (mounted) {
        setState(() {
          _marketStatus = status;
        });
      }
    });
  }

  /// API를 통해 최신 계좌 자산 현황을 불러옵니다.
  /// 데이터를 성공적으로 가져오면 보유 종목 리스트를 웹소켓에 구독 신청합니다.
  Future<void> _fetchData() async {
    try {
      final response = await _accountService.fetchAccountEvaluation();
      if (mounted) {
        setState(() {
          _accountData = response.data;
          _isLoading = false;
        });
        // 현재 보유 중인 종목들에 대해 실시간 가격 수신 신청
        _subscribeToStocks();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// 현재 보유 중인 모든 종목 리스트를 순회하며 실시간 시세 서버(WebSocket)에 구독 신청합니다.
  void _subscribeToStocks() {
    if (_accountData == null) return;
    for (var stock in _accountData!.stockList) {
      if (stock.stkCd != null) {
        // 서버 전송 규격에 맞춰 'A' 접두사가 있을 경우 제거 (예: A005930 -> 005930)
        final code = stock.stkCd!.startsWith('A')
            ? stock.stkCd!.substring(1)
            : stock.stkCd!;
        _webSocketService.subscribe(code);
      }
    }
  }

  /// 화면이 닫힐 때 혹은 데이터가 갱신될 때 기존 종목들에 대한 소켓 구독을 모두 해지합니다.
  void _unsubscribeAll() {
    if (_accountData == null) return;
    for (var stock in _accountData!.stockList) {
      if (stock.stkCd != null) {
        final code = stock.stkCd!.startsWith('A')
            ? stock.stkCd!.substring(1)
            : stock.stkCd!;
        _webSocketService.unsubscribe(code);
      }
    }
  }

  @override
  void dispose() {
    _unsubscribeAll(); // 종목 구독 해지
    _priceSubscription?.cancel(); // 스트림 리스너 차단
    _marketSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text('에러 발생: $_errorMessage'));
    }

    if (_accountData == null) {
      return const Center(child: Text('데이터가 없습니다.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 최상단 요약 카드: 총 평가금액, 수익률, 시장 상태 등 표시
          AccountSummaryCard(
            data: _accountData!,
            realtimePrices: _realtimePrices,
            marketStatus: _marketStatus,
          ),
          const SizedBox(height: 24),
          const Text(
            '보유 주식',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          // 2. 보유 종목 리스트: 각 종목별로 개별 타일(Tile)을 생성
          ..._accountData!.stockList.map((stock) {
            // 소켓 코드 매칭 (A 접두사 제외된 버전을 키로 사용)
            final stockCode = stock.stkCd?.startsWith('A') == true
                ? stock.stkCd!.substring(1)
                : stock.stkCd;
            return AccountStockTile(
              stock: stock,
              realtime: _realtimePrices[stockCode],
            );
          }),
        ],
      ),
    );
  }
}
