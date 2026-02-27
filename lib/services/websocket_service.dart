import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants.dart';
import '../models/stock_master.dart';
import '../models/market_status.dart';

/// 실시간 주식 시세 및 시장 상태를 처리하는 웹소켓 서비스 클래스입니다.
/// Socket.IO를 사용하여 서버와 양방향 통신을 수행합니다.
class WebSocketService {
  // 싱글톤 패턴 적용: 앱 전체에서 단 하나의 서비스 인스턴스만 유지
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  io.Socket? _socket;

  // 브로드캐스트 스트림 컨트롤러: 여러 화면(리스너)에서 동시에 실시간 데이터를 구독할 수 있게 함
  final _priceStreamController = StreamController<RealtimePrice>.broadcast();
  final _marketStreamController = StreamController<MarketStatus>.broadcast();

  // 종목코드별 참조 카운트 관리 (Reference Counting)
  // 여러 화면에서 동일 종목을 구독할 때, 실제 서버에는 한 번만 구독 요청을 보내고
  // 모든 화면이 나갔을 때만 서버에 구독 해제 요청을 보냄
  final Map<String, int> _subscriptionCounts = {};

  // 현재 시장 상태 (개장여부 등) 저장
  MarketStatus? _currentMarketStatus;

  /// 실시간 가격 업데이트를 수신할 수 있는 스트림
  Stream<RealtimePrice> get priceStream => _priceStreamController.stream;

  /// 시장 상태 업데이트를 수신할 수 있는 스트림 (개장/폐장 등)
  Stream<MarketStatus> get marketStream => _marketStreamController.stream;

  /// 현재 장이 시작되었는지 확인 (서버에서 받은 status 기준)
  bool get isMarketOpen => _currentMarketStatus?.isMarketOpen ?? false;

  /// 서버와의 소켓 연결 상태를 반환
  bool get isConnected => _socket?.connected ?? false;

  /// 소켓을 초기화하고 서버에 연결합니다.
  void connect() {
    // 이미 연결되어 있으면 중복 연결 차단
    if (_socket != null && _socket!.connected) return;

    _socket = io.io(
      ApiConstants.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket']) // 폴링 없이 즉시 웹소켓 프로토콜 사용
          .setReconnectionAttempts(5) // 연결 끊김 시 최대 5회 재시도
          .setReconnectionDelay(2000) // 재연결 시도 간격 2초
          .enableForceNew() // 새 인스턴스 연결 강제
          .build(),
    );

    // 연결 성공 이벤트 핸들러
    _socket!.onConnect((_) {
      debugPrint('WebSocket 연결 성공: ${ApiConstants.baseUrl}');

      // 1. 시장 전체 상태 구독 요청 (서버에서 주기적으로 'market_update' 전달 시작)
      _socket!.emit('subscribe_market');

      // 2. 재연결된 경우, 참조 카운트가 있는 종목들을 다시 서버에 구독 요청 (장중일 때만)
      if (isMarketOpen) {
        _resubscribeAllOpenStocks();
      }
    });

    _socket!.onDisconnect((_) {
      debugPrint('WebSocket 연결 종료');
    });

    _socket!.onConnectError((data) {
      debugPrint('WebSocket 연결 에러: $data');
    });

    // 시장 상태 업데이트 수신 ('market_update' 채널)
    _socket!.on('market_update', (data) {
      try {
        final status = MarketStatus.fromSocket(data);
        final wasOpen = isMarketOpen;
        _currentMarketStatus = status;
        _marketStreamController.add(status); // 스트림에 흘려보내 UI 반영

        debugPrint('시장 상태 업데이트: ${status.statusLabel} (${status.status})');

        // 장이 시작되는 순간 처리
        if (!wasOpen && status.isMarketOpen) {
          debugPrint('장이 시작됨: 대기 중인 모든 종목 구독 실행');
          _resubscribeAllOpenStocks();
        }
        // 장이 닫히는 순간 처리 (서버 리소스 절약을 위해 구독 일시 중단)
        else if (wasOpen && !status.isMarketOpen) {
          debugPrint('장이 종료됨: 모든 서버 구독 해제');
          _unsubscribeAllFromStockServer();
        }
      } catch (e) {
        debugPrint('시장 상태 파싱 에러: $e');
      }
    });

    // 종목별 실시간 시세 데이터 수신 ('stock_update' 채널)
    _socket!.on('stock_update', (data) {
      try {
        final update = RealtimePrice.fromSocket(data);
        _priceStreamController.add(update); // 스트림으로 전달
      } catch (e) {
        debugPrint('시세 데이터 파싱 에러: $e');
      }
    });

    _socket!.connect();
  }

  /// 특정 종목의 실시간 시세를 구독합니다.
  /// [code]: 구독할 종목 코드 (A 접두사 제외된 경우 권장)
  void subscribe(String code) {
    final currentCount = _subscriptionCounts[code] ?? 0;
    _subscriptionCounts[code] = currentCount + 1;

    // 해당 종목을 앱 내에서 처음으로 구독하는 경우에만 실제 서버에 신호 전송
    if (currentCount == 0) {
      if (_socket != null && isConnected && isMarketOpen) {
        _socket!.emit('subscribe_stock', code);
        debugPrint('종목 구독 요청 (장중 최초 서버 전송): $code');
      } else {
        // 장외 시간일 경우 카운트만 유지하고 서버 전송은 장 시작 시점으로 예약됨
        String reason = !isConnected ? "연결대기" : "장종료";
        debugPrint('종목 구독 예약 (대기 - $reason): $code');
      }
    } else {
      debugPrint(
        '종목 구독 추가 (참조 카운트 증가): $code (현재 구독자: ${_subscriptionCounts[code]})',
      );
    }
  }

  /// 특정 종목의 구독을 해지합니다.
  void unsubscribe(String code) {
    final currentCount = _subscriptionCounts[code] ?? 0;
    if (currentCount <= 0) return;

    final newCount = currentCount - 1;
    if (newCount == 0) {
      // 앱 내의 모든 화면에서 해당 종목을 보지 않을 때 실제 서버에 해지 요청
      _subscriptionCounts.remove(code);
      if (_socket != null && isConnected) {
        _socket!.emit('unsubscribe_stock', code);
        debugPrint('종목 구독 해지 (최종 서버 전송): $code');
      }
    } else {
      _subscriptionCounts[code] = newCount;
      debugPrint('종목 구독 유지 (참조 카운트 감소): $code (남은 구독자: $newCount)');
    }
  }

  /// 현재 대기 중인(참조 카운트가 1 이상인) 모든 종목을 서버에 즉시 구독 신청합니다.
  /// 주로 장 시작 직후 혹은 재연결 시 호출됩니다.
  void _resubscribeAllOpenStocks() {
    if (_socket == null || !isConnected) return;
    _subscriptionCounts.forEach((code, count) {
      if (count > 0) {
        _socket!.emit('subscribe_stock', code);
        debugPrint('서버 구독 활성화: $code (카운트: $count)');
      }
    });
  }

  /// 모든 서버 구독을 명시적으로 취소합니다.
  /// 장 마감 시 불필요한 네트워크 트래픽 및 서버 부하를 방지하기 위해 사용합니다.
  void _unsubscribeAllFromStockServer() {
    if (_socket == null || !isConnected) return;
    for (var code in _subscriptionCounts.keys) {
      _socket!.emit('unsubscribe_stock', code);
    }
    debugPrint('모든 서버 시세 배달 중단 (시장 마감)');
  }

  /// 소켓 연결을 완전히 종료하고 모든 상태를 초기화합니다.
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _subscriptionCounts.clear();
    _currentMarketStatus = null;
    debugPrint('WebSocket 서비스 종료 및 구독 초기화');
  }
}
