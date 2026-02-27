import '../utils/format_utils.dart';

class ApiResponse {
  final AccountData? data;
  final String? nextKey;
  final String? contYn;

  ApiResponse({this.data, this.nextKey, this.contYn});

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      data: json['data'] != null ? AccountData.fromJson(json['data']) : null,
      nextKey: json['nextKey'],
      contYn: json['contYn'],
    );
  }
}

class AccountData {
  final String? acntNm;
  final String? brchNm;
  final String? entr; // 예수금
  final String? d2Entra; // D+2추정예수금
  final String? totEstAmt; // 유가잔고평가액
  final String? asetEvltAmt; // 예탁자산평가액
  final String? totPurAmt; // 총매입금액
  final String? prsmDpstAsetAmt; // 추정예탁자산
  final String? totGrntSella; // 매도담보대출금
  final String? tdyLspftAmt; // 당일투자원금
  final String? invtBsamt; // 당월투자원금
  final String? lspftAmt; // 누적투자원금
  final String? tdyLspft; // 당일투자손익
  final String? lspft2; // 당월투자손익
  final String? lspft; // 누적투자손익
  final String? tdyLspftRt; // 당일손익율
  final String? lspftRatio; // 당월손익율
  final String? lspftRt; // 누적손익율
  final List<StockItem> stockList;
  final int? returnCode;
  final String? returnMsg;

  AccountData({
    this.acntNm,
    this.brchNm,
    this.entr,
    this.d2Entra,
    this.totEstAmt,
    this.asetEvltAmt,
    this.totPurAmt,
    this.prsmDpstAsetAmt,
    this.totGrntSella,
    this.tdyLspftAmt,
    this.invtBsamt,
    this.lspftAmt,
    this.tdyLspft,
    this.lspft2,
    this.lspft,
    this.tdyLspftRt,
    this.lspftRatio,
    this.lspftRt,
    this.stockList = const [],
    this.returnCode,
    this.returnMsg,
  });

  factory AccountData.fromJson(Map<String, dynamic> json) {
    return AccountData(
      acntNm: json['acnt_nm'],
      brchNm: json['brch_nm'],
      entr: FormatUtils.formatAmount(json['entr']),
      d2Entra: FormatUtils.formatAmount(json['d2_entra']),
      totEstAmt: FormatUtils.formatAmount(json['tot_est_amt']),
      asetEvltAmt: FormatUtils.formatAmount(json['aset_evlt_amt']),
      totPurAmt: FormatUtils.formatAmount(json['tot_pur_amt']),
      prsmDpstAsetAmt: FormatUtils.formatAmount(json['prsm_dpst_aset_amt']),
      totGrntSella: FormatUtils.formatAmount(json['tot_grnt_sella']),
      tdyLspftAmt: FormatUtils.formatAmount(json['tdy_lspft_amt']),
      invtBsamt: FormatUtils.formatAmount(json['invt_bsamt']),
      lspftAmt: FormatUtils.formatAmount(json['lspft_amt']),
      tdyLspft: FormatUtils.formatAmount(json['tdy_lspft']),
      lspft2: FormatUtils.formatAmount(json['lspft2']),
      lspft: FormatUtils.formatAmount(json['lspft']),
      tdyLspftRt: json['tdy_lspft_rt'],
      lspftRatio: json['lspft_ratio'],
      lspftRt: json['lspft_rt'],
      returnCode: json['return_code'],
      returnMsg: json['return_msg'],
      stockList:
          (json['stk_acnt_evlt_prst'] as List?)
              ?.map((e) => StockItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class StockItem {
  final String? stkCd; // 종목코드
  final String? stkNm; // 종목명
  final String? rmndQty; // 보유수량
  final String? avgPrc; // 평균단가
  final String? curPrc; // 현재가
  final String? evltAmt; // 평가금액
  final String? plAmt; // 손익금액
  final String? plRt; // 손익율
  final String? loanDt; // 대출일
  final String? purAmt; // 매입금액
  final String? setlRemn; // 결제잔고
  final String? predBuyq; // 전일매수수량
  final String? predSellq; // 전일매도수량
  final String? tdyBuyq; // 금일매수수량
  final String? tdySellq; // 금일매도수량

  StockItem({
    this.stkCd,
    this.stkNm,
    this.rmndQty,
    this.avgPrc,
    this.curPrc,
    this.evltAmt,
    this.plAmt,
    this.plRt,
    this.loanDt,
    this.purAmt,
    this.setlRemn,
    this.predBuyq,
    this.predSellq,
    this.tdyBuyq,
    this.tdySellq,
  });

  factory StockItem.fromJson(Map<String, dynamic> json) {
    return StockItem(
      stkCd: json['stk_cd'],
      stkNm: json['stk_nm'],
      rmndQty: FormatUtils.formatAmount(json['rmnd_qty']),
      avgPrc: FormatUtils.formatAmount(json['avg_prc']),
      curPrc: FormatUtils.formatAmount(json['cur_prc']),
      evltAmt: FormatUtils.formatAmount(json['evlt_amt']),
      plAmt: FormatUtils.formatAmount(json['pl_amt']),
      plRt: FormatUtils.formatRate(json['pl_rt']),
      loanDt: json['loan_dt'],
      purAmt: FormatUtils.formatAmount(json['pur_amt']),
      setlRemn: FormatUtils.formatAmount(json['setl_remn']),
      predBuyq: FormatUtils.formatAmount(json['pred_buyq']),
      predSellq: FormatUtils.formatAmount(json['pred_sellq']),
      tdyBuyq: FormatUtils.formatAmount(json['tdy_buyq']),
      tdySellq: FormatUtils.formatAmount(json['tdy_sellq']),
    );
  }
}
