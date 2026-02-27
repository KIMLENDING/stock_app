import '../utils/format_utils.dart';
import 'favorite_stock_batch.dart';

/// 종목 상세 시세 모델 (사용자 제공 전체 JSON 구조 및 기존 필드 통합)
class StockPriceDetail {
  // 기본 정보
  final String stkCd; // 종목코드
  final String stkNm; // 종목명
  final String setlMm; // 결산월
  final String fav; // 액면가
  final String favUnit; // 액면가단위

  // 자본 및 주식수
  final String cap; // 자본금
  final String floStk; // 상장주식
  final String dstrStk; // 유통주식
  final String dstrRt; // 유통비율

  // 투자 지표
  final String per; // PER
  final String eps; // EPS
  final String roe; // ROE
  final String pbr; // PBR
  final String ev; // EV
  final String bps; // BPS

  // 실적 정보
  final String saleAmt; // 매출액
  final String busPro; // 영업이익
  final String cupNga; // 당기순이익

  // 가격 정보 (정수형 파싱용)
  final int curPrc; // 현재가
  final int openPric; // 시가
  final int highPric; // 고가
  final int lowPric; // 저가
  final String basePric; // 기준가
  final int uplPric; // 상한가
  final int lstPric; // 하한가

  // 변동성 및 등락
  final String preSig; // 대비기호
  final int predPre; // 전일대비
  final double fluRt; // 등락율
  final int trdeQty; // 거래량
  final int trdePre; // 거래대비
  final String crdRt; // 신용비율

  // 기간별 최고/최저
  final String oyrHgst; // 연중최고
  final String oyrLwst; // 연중최저
  final String hgst250; // 250최고 (250hgst)
  final String lwst250; // 250최저 (250lwst)
  final String hgst250PricDt; // 250최고가일
  final String hgst250PricPreRt; // 250최고가대비율
  final String lwst250PricDt; // 250최저가일
  final String lwst250PricPreRt; // 250최저가대비율

  // 기타 시장 정보
  final String mac; // 시가총액
  final String macWght; // 시가총액비중
  final String forExhRt; // 외인소진률
  final String replPric; // 대용가
  final int expCntrPric; // 예상체결가
  final int expCntrQty; // 예상체결수량

  // API 응답 상태
  final int returnCode; // 결과코드
  final String returnMsg; // 결과메시지

  StockPriceDetail({
    required this.stkCd,
    required this.stkNm,
    required this.setlMm,
    required this.fav,
    required this.favUnit,
    required this.cap,
    required this.floStk,
    required this.dstrStk,
    required this.dstrRt,
    required this.per,
    required this.eps,
    required this.roe,
    required this.pbr,
    required this.ev,
    required this.bps,
    required this.saleAmt,
    required this.busPro,
    required this.cupNga,
    required this.curPrc,
    required this.openPric,
    required this.highPric,
    required this.lowPric,
    required this.basePric,
    required this.uplPric,
    required this.lstPric,
    required this.preSig,
    required this.predPre,
    required this.fluRt,
    required this.trdeQty,
    required this.trdePre,
    required this.crdRt,
    required this.oyrHgst,
    required this.oyrLwst,
    required this.hgst250,
    required this.lwst250,
    required this.hgst250PricDt,
    required this.hgst250PricPreRt,
    required this.lwst250PricDt,
    required this.lwst250PricPreRt,
    required this.mac,
    required this.macWght,
    required this.forExhRt,
    required this.replPric,
    required this.expCntrPric,
    required this.expCntrQty,
    required this.returnCode,
    required this.returnMsg,
  });

  /// 유효한 현재가 반환 (0일 경우 예상체결가 등을 확인)
  int get validPrice {
    // 가격 데이터이므로 절대값을 취함
    final int absCurPrc = curPrc.abs();
    final int absExpQty = expCntrQty.abs();
    final int absExpPric = expCntrPric.abs();

    if (absCurPrc > 0) return absCurPrc;
    if (absExpQty > 0) return absExpQty;
    if (absExpPric > 100) return absExpPric;
    return 0;
  }

  /// 유효한 예상체결가 반환 (장전용)
  int get validExpectedPrice {
    final int absExpQty = expCntrQty.abs();
    final int absExpPric = expCntrPric.abs();
    final int absCurPrc = curPrc.abs();

    if (absExpQty > 0) return absExpQty;
    if (absExpPric > 100) return absExpPric;
    return absCurPrc > 0 ? absCurPrc : 0;
  }

  /// 유효한 등락율 반환
  double get validRate {
    if (fluRt != 0) return fluRt;
    // 예상체결가 필드가 비율(+26.69 등)로 사용되는 경우를 위한 처리
    // parseAmount는 정수로 반환하므로 주의 필요 (실제론 fluRt 필드가 우선됨)
    return fluRt;
  }

  factory StockPriceDetail.fromJson(Map<String, dynamic> json) {
    return StockPriceDetail(
      stkCd: json['stk_cd']?.toString() ?? "",
      stkNm: json['stk_nm']?.toString() ?? "",
      setlMm: json['setl_mm']?.toString() ?? "",
      fav: json['fav']?.toString() ?? "",
      favUnit: json['fav_unit']?.toString() ?? "",
      cap: json['cap']?.toString() ?? "",
      floStk: json['flo_stk']?.toString() ?? "",
      dstrStk: json['dstr_stk']?.toString() ?? "",
      dstrRt: json['dstr_rt']?.toString() ?? "",
      per: json['per']?.toString() ?? "",
      eps: json['eps']?.toString() ?? "",
      roe: json['roe']?.toString() ?? "",
      pbr: json['pbr']?.toString() ?? "",
      ev: json['ev']?.toString() ?? "",
      bps: json['bps']?.toString() ?? "",
      saleAmt: json['sale_amt']?.toString() ?? "",
      busPro: json['bus_pro']?.toString() ?? "",
      cupNga: json['cup_nga']?.toString() ?? "",
      curPrc: FormatUtils.parseAmount(json['cur_prc']?.toString()),
      openPric: FormatUtils.parseAmount(json['open_pric']?.toString()),
      highPric: FormatUtils.parseAmount(json['high_pric']?.toString()),
      lowPric: FormatUtils.parseAmount(json['low_pric']?.toString()),
      basePric: json['base_pric']?.toString() ?? "",
      uplPric: FormatUtils.parseAmount(json['upl_pric']?.toString()),
      lstPric: FormatUtils.parseAmount(json['lst_pric']?.toString()),
      preSig: json['pre_sig']?.toString() ?? "",
      predPre: FormatUtils.parseAmount(json['pred_pre']?.toString()),
      fluRt: double.tryParse(json['flu_rt']?.toString() ?? "0") ?? 0.0,
      trdeQty: FormatUtils.parseAmount(json['trde_qty']?.toString()),
      trdePre: FormatUtils.parseAmount(json['trde_pre']?.toString()),
      crdRt: json['crd_rt']?.toString() ?? "",
      oyrHgst: json['oyr_hgst']?.toString() ?? "",
      oyrLwst: json['oyr_lwst']?.toString() ?? "",
      hgst250: json['250hgst']?.toString() ?? "",
      lwst250: json['250lwst']?.toString() ?? "",
      hgst250PricDt: json['250hgst_pric_dt']?.toString() ?? "",
      hgst250PricPreRt: json['250hgst_pric_pre_rt']?.toString() ?? "",
      lwst250PricDt: json['250lwst_pric_dt']?.toString() ?? "",
      lwst250PricPreRt: json['250lwst_pric_pre_rt']?.toString() ?? "",
      mac: json['mac']?.toString() ?? "",
      macWght: json['mac_wght']?.toString() ?? "",
      forExhRt: json['for_exh_rt']?.toString() ?? "",
      replPric: json['repl_pric']?.toString() ?? "",
      expCntrPric: FormatUtils.parseAmount(json['exp_cntr_pric']?.toString()),
      expCntrQty: FormatUtils.parseAmount(json['exp_cntr_qty']?.toString()),
      returnCode: int.tryParse(json['return_code']?.toString() ?? "0") ?? 0,
      returnMsg: json['return_msg']?.toString() ?? "",
    );
  }

  /// 벌크 조회 모델(FavoriteStockDetail)을 상세 모델(StockPriceDetail)로 변환
  factory StockPriceDetail.fromFavoriteBatch(FavoriteStockDetail src) {
    return StockPriceDetail(
      stkCd: src.stkCd,
      stkNm: src.stkNm,
      setlMm: "", // 벌크에는 없는 필드들
      fav: src.fav,
      favUnit: "원",
      cap: src.cap,
      floStk: src.stkcnt,
      dstrStk: "",
      dstrRt: "",
      per: "",
      eps: "",
      roe: "",
      pbr: "",
      ev: "",
      bps: "",
      saleAmt: "",
      busPro: "",
      cupNga: "",
      curPrc: src.curPrc,
      openPric: src.openPric,
      highPric: src.highPric,
      lowPric: src.lowPric,
      basePric: src.basePric.toString(),
      uplPric: src.uplPric,
      lstPric: src.lstPric,
      preSig: src.predPreSig,
      predPre: src.predPre,
      fluRt: src.fluRt,
      trdeQty: src.trdeQty,
      trdePre: src.trdePrica,
      crdRt: "",
      oyrHgst: "",
      oyrLwst: "",
      hgst250: "",
      lwst250: "",
      hgst250PricDt: "",
      hgst250PricPreRt: "",
      lwst250PricDt: "",
      lwst250PricPreRt: "",
      mac: src.mac,
      macWght: "",
      forExhRt: "",
      replPric: "",
      expCntrPric: src.expCntrPric,
      expCntrQty: src.expCntrQty,
      returnCode: 0,
      returnMsg: "Bulk Success",
    );
  }
}
