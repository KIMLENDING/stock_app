import '../utils/format_utils.dart';

/// 관심종목 벌크 조회 응답 모델
class FavoriteStockBatchResponse {
  final int returnCode;
  final String returnMsg;
  final List<FavoriteStockDetail> stocks;

  FavoriteStockBatchResponse({
    required this.returnCode,
    required this.returnMsg,
    required this.stocks,
  });

  factory FavoriteStockBatchResponse.fromJson(Map<String, dynamic> json) {
    return FavoriteStockBatchResponse(
      returnCode: int.tryParse(json['return_code']?.toString() ?? "0") ?? 0,
      returnMsg: json['return_msg']?.toString() ?? "",
      stocks:
          (json['atn_stk_infr'] as List?)
              ?.map((e) => FavoriteStockDetail.fromJson(e))
              .toList() ??
          [],
    );
  }
}

/// 관심종목 벌크 조회 개별 종목 상세 모델 (정확한 스펙 및 주석 반영)
class FavoriteStockDetail {
  // [기본 정보]
  final String stkCd; // 종목코드
  final String stkNm; // 종목명
  final String dt; // 일자
  final String cap; // 자본금
  final String fav; // 액면가
  final String mac; // 시가총액
  final String stkcnt; // 주식수

  // [가격 및 등락]
  final int curPrc; // 현재가
  final int basePric; // 기준가
  final int openPric; // 시가
  final int highPric; // 고가
  final int lowPric; // 저가
  final int closePric; // 종가
  final int uplPric; // 상한가
  final int lstPric; // 하한가
  final int predPre; // 전일대비
  final String predPreSig; // 전일대비기호
  final double fluRt; // 등락율

  // [거래 및 체결]
  final int trdeQty; // 거래량
  final int trdePrica; // 거래대금
  final int cntrQty; // 체결량
  final String cntrStr; // 체결강도
  final String cntrTm; // 체결시간
  final String predTrdeQtyPre; // 전일거래량대비
  final int expCntrPric; // 예상체결가
  final int expCntrQty; // 예상체결량

  // [호가 정보 - 매도]
  final int selBid; // 대표 매도호가
  final int sel1thBid; // 매도1차호가
  final int sel2thBid; // 매도2차호가
  final int sel3thBid; // 매도3차호가
  final int sel4thBid; // 매도4차호가
  final int sel5thBid; // 매도5차호가

  // [호가 정보 - 매수]
  final int buyBid; // 대표 매수호가
  final int buy1thBid; // 매수1차호가
  final int buy2thBid; // 매수2차호가
  final int buy3thBid; // 매수3차호가
  final int buy4thBid; // 매수4차호가
  final int buy5thBid; // 매수5차호가
  final String bidTm; // 호가시간

  // [잔량 및 건수]
  final String priSelReq; // 우선매도잔량
  final String priBuyReq; // 우선매수잔량
  final String priSelCnt; // 우선매도건수
  final String priBuyCnt; // 우선매수건수
  final String totSelReq; // 총매도잔량
  final String totBuyReq; // 총매수잔량
  final String totSelCnt; // 총매도건수
  final String totBuyCnt; // 총매수건수

  // [ELW 및 기술적 지표]
  final String prty; // 패리티
  final String gear; // 기어링
  final String plQutr; // 손익분기
  final String capSupport; // 자본지지
  final String elwexecPric; // ELW행사가
  final String cnvtRt; // 전환비율
  final String elwexprDt; // ELW만기일
  final String cntrEngg; // 미결제약정
  final String cntrPredPre; // 미결제전일대비
  final String theoryPric; // 이론가
  final String innrVltl; // 내재변동성
  final String delta; // 델타
  final String gam; // 감마
  final String theta; // 쎄타
  final String vega; // 베가
  final String law; // 로

  FavoriteStockDetail({
    required this.stkCd,
    required this.stkNm,
    required this.dt,
    required this.cap,
    required this.fav,
    required this.mac,
    required this.stkcnt,
    required this.curPrc,
    required this.basePric,
    required this.openPric,
    required this.highPric,
    required this.lowPric,
    required this.closePric,
    required this.uplPric,
    required this.lstPric,
    required this.predPre,
    required this.predPreSig,
    required this.fluRt,
    required this.trdeQty,
    required this.trdePrica,
    required this.cntrQty,
    required this.cntrStr,
    required this.cntrTm,
    required this.predTrdeQtyPre,
    required this.expCntrPric,
    required this.expCntrQty,
    required this.selBid,
    required this.sel1thBid,
    required this.sel2thBid,
    required this.sel3thBid,
    required this.sel4thBid,
    required this.sel5thBid,
    required this.buyBid,
    required this.buy1thBid,
    required this.buy2thBid,
    required this.buy3thBid,
    required this.buy4thBid,
    required this.buy5thBid,
    required this.bidTm,
    required this.priSelReq,
    required this.priBuyReq,
    required this.priSelCnt,
    required this.priBuyCnt,
    required this.totSelReq,
    required this.totBuyReq,
    required this.totSelCnt,
    required this.totBuyCnt,
    required this.prty,
    required this.gear,
    required this.plQutr,
    required this.capSupport,
    required this.elwexecPric,
    required this.cnvtRt,
    required this.elwexprDt,
    required this.cntrEngg,
    required this.cntrPredPre,
    required this.theoryPric,
    required this.innrVltl,
    required this.delta,
    required this.gam,
    required this.theta,
    required this.vega,
    required this.law,
  });

  factory FavoriteStockDetail.fromJson(Map<String, dynamic> json) {
    return FavoriteStockDetail(
      stkCd: json['stk_cd']?.toString() ?? "",
      stkNm: json['stk_nm']?.toString() ?? "",
      dt: json['dt']?.toString() ?? "",
      cap: json['cap']?.toString() ?? "",
      fav: json['fav']?.toString() ?? "",
      mac: json['mac']?.toString() ?? "",
      stkcnt: json['stkcnt']?.toString() ?? "",
      curPrc: FormatUtils.parseAmount(json['cur_prc']?.toString()),
      basePric: FormatUtils.parseAmount(json['base_pric']?.toString()),
      openPric: FormatUtils.parseAmount(json['open_pric']?.toString()),
      highPric: FormatUtils.parseAmount(json['high_pric']?.toString()),
      lowPric: FormatUtils.parseAmount(json['low_pric']?.toString()),
      closePric: FormatUtils.parseAmount(json['close_pric']?.toString()),
      uplPric: FormatUtils.parseAmount(json['upl_pric']?.toString()),
      lstPric: FormatUtils.parseAmount(json['lst_pric']?.toString()),
      predPre: FormatUtils.parseAmount(json['pred_pre']?.toString()),
      predPreSig: json['pred_pre_sig']?.toString() ?? "",
      fluRt: double.tryParse(json['flu_rt']?.toString() ?? "0") ?? 0.0,
      trdeQty: FormatUtils.parseAmount(json['trde_qty']?.toString()),
      trdePrica: FormatUtils.parseAmount(json['trde_prica']?.toString()),
      cntrQty: FormatUtils.parseAmount(json['cntr_qty']?.toString()),
      cntrStr: json['cntr_str']?.toString() ?? "",
      cntrTm: json['cntr_tm']?.toString() ?? "",
      predTrdeQtyPre: json['pred_trde_qty_pre']?.toString() ?? "",
      expCntrPric: FormatUtils.parseAmount(json['exp_cntr_pric']?.toString()),
      expCntrQty: FormatUtils.parseAmount(json['exp_cntr_qty']?.toString()),
      selBid: FormatUtils.parseAmount(json['sel_bid']?.toString()),
      sel1thBid: FormatUtils.parseAmount(json['sel_1th_bid']?.toString()),
      sel2thBid: FormatUtils.parseAmount(json['sel_2th_bid']?.toString()),
      sel3thBid: FormatUtils.parseAmount(json['sel_3th_bid']?.toString()),
      sel4thBid: FormatUtils.parseAmount(json['sel_4th_bid']?.toString()),
      sel5thBid: FormatUtils.parseAmount(json['sel_5th_bid']?.toString()),
      buyBid: FormatUtils.parseAmount(json['buy_bid']?.toString()),
      buy1thBid: FormatUtils.parseAmount(json['buy_1th_bid']?.toString()),
      buy2thBid: FormatUtils.parseAmount(json['buy_2th_bid']?.toString()),
      buy3thBid: FormatUtils.parseAmount(json['buy_3th_bid']?.toString()),
      buy4thBid: FormatUtils.parseAmount(json['buy_4th_bid']?.toString()),
      buy5thBid: FormatUtils.parseAmount(json['buy_5th_bid']?.toString()),
      bidTm: json['bid_tm']?.toString() ?? "",
      priSelReq: json['pri_sel_req']?.toString() ?? "",
      priBuyReq: json['pri_buy_req']?.toString() ?? "",
      priSelCnt: json['pri_sel_cnt']?.toString() ?? "",
      priBuyCnt: json['pri_buy_cnt']?.toString() ?? "",
      totSelReq: json['tot_sel_req']?.toString() ?? "",
      totBuyReq: json['tot_buy_req']?.toString() ?? "",
      totSelCnt: json['tot_sel_cnt']?.toString() ?? "",
      totBuyCnt: json['tot_buy_cnt']?.toString() ?? "",
      prty: json['prty']?.toString() ?? "",
      gear: json['gear']?.toString() ?? "",
      plQutr: json['pl_qutr']?.toString() ?? "",
      capSupport: json['cap_support']?.toString() ?? "",
      elwexecPric: json['elwexec_pric']?.toString() ?? "",
      cnvtRt: json['cnvt_rt']?.toString() ?? "",
      elwexprDt: json['elwexpr_dt']?.toString() ?? "",
      cntrEngg: json['cntr_engg']?.toString() ?? "",
      cntrPredPre: json['cntr_pred_pre']?.toString() ?? "",
      theoryPric: json['theory_pric']?.toString() ?? "",
      innrVltl: json['innr_vltl']?.toString() ?? "",
      delta: json['delta']?.toString() ?? "",
      gam: json['gam']?.toString() ?? "",
      theta: json['theta']?.toString() ?? "",
      vega: json['vega']?.toString() ?? "",
      law: json['law']?.toString() ?? "",
    );
  }
}
