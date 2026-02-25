# AI 전용 API 연동 사양서 v2 (Pagination & Real Data)

이 문서는 플러터 앱 내 AI 어시스턴트가 서버 API의 **실제 데이터 구조**와 **연속 조회(Pagination)** 로직을 완벽하게 이해하고 코드를 생성할 수 있도록 작성되었습니다.

## 1. 공통 사항

- **Base URL**: `http://localhost:3000`
- **Pagination**: 응답의 `contYn`이 `"Y"`인 경우, 함께 전달된 `nextKey`를 다음 요청의 쿼리 파라미터로 보내면 다음 데이터를 가져올 수 있습니다.

---

## 2. API 상세 명세 및 Dart 모델

### 2.1 계좌 번호 조회 (ka00001) - PDF 10p

- **Endpoint**: `GET /api/account`
- **응답 샘플**:

```json
{
  "data": {
    "acctNo": "1234567810",
    "return_code": 0,
    "return_msg": "정상적으로 처리되었습니다"
  }
}
```

---

### 2.2 주식 기본 정보 요청 (ka10001) - PDF 15, 16p

- **Endpoint**: `GET /api/market/price/:code`
- **Request Parameters**: `code` (예: `005930`)
- **응답 샘플 (리얼 데이터)**:

```json
{
  "data": {
    "stk_cd": "005930",
    "stk_nm": "삼성전자",
    "setl_mm": "12",
    "fav": "5000",
    "cap": "1311",
    "flo_stk": "25527",
    "crd_rt": "+0.08",
    "oyr_hgst": "+181400",
    "oyr_lwst": "-91200",
    "mac": "24352",
    "repl_pric": "66780",
    "bps": "-75300",
    "high_pric": "95400",
    "open_pric": "-0",
    "low_pric": "0",
    "cur_prc": "0.00",
    "flu_rt": "0",
    "return_code": 0,
    "return_msg": "정상적으로 처리되었습니다"
  }
}
```

### 2.3 주식 일봉 차트 조회 (ka10081) - PDF 201, 202p

종목의 일봉 차트 리스트를 가져옵니다. 일반 조회와 스트리밍 조회의 두 가지 방식이 있습니다.

#### [방식 A] 일반 조회 (Pagination)

- **Endpoint**: `GET /api/market/chart/:code`
- **Query Params**: `cont_yn`, `next_key` (수동 Pagination용)
- **응답 샘플**:

```json
{
  "data": {
    "stk_cd": "005930",
    "stk_dt_pole_chart_qry": [
      {
        "cur_prc": "203500",
        "trde_qty": "26987996",
        "trde_prica": "5474225",
        "dt": "20260225",
        "open_pric": "202500",
        "high_pric": "206000",
        "low_pric": "201000",
        "pred_pre": "+3500",
        "pred_pre_sig": "2",
        "trde_tern_rt": "+0.46"
      },
      {
        "cur_prc": "200000",
        "trde_qty": "28060617",
        "trde_prica": "5538098",
        "dt": "20260224",
        "open_pric": "193000",
        "high_pric": "200000",
        "low_pric": "192000",
        "pred_pre": "+7000",
        "pred_pre_sig": "2",
        "trde_tern_rt": "+0.47"
      }
    ],
    "return_code": 0,
    "return_msg": "정상적으로 처리되었습니다"
  },
  "nextKey": "A0059302023090100010000", // 추가 요청시 쿼리에 넣어서 추가 요청 하면됨
  "contYn": "Y" // Y이면 추가 데이터 있음 // 응답이 N이면 마지막 데이터임
}
```

#### [방식 B] 스트리밍 전량 조회

서버가 내부적으로 재귀 호출을 수행하여 모든 페이지를 즉시 전송합니다. 클라이언트는 데이터를 받는 대로 즉시 UI를 갱신할 수 있습니다.

- **Endpoint**: `GET /api/market/chart/stream/:code`
- **Response Format**: `text/plain`

---

## 4. AI 개발 가이드 (Tips)

1. **NDJSON 처리**: 스트리밍 API(`.../stream/:code`)는 'NDJSON' 형식을 사용하므로 `jsonDecode`를 전체 응답이 아닌 **매 라인마다** 수행해야 합니다.
2. **비동기 재귀**: 서버가 이미 재귀Pagination을 처리하므로, 플러터 앱은 `yield` 되는 데이터를 리스트에 추가만 하면 됩니다.
3. **에러 처리**: 스트림 도중 `{"error": "..."}` 메시지가 한 줄로 올 수 있으므로 이에 대한 방어 코드를 작성하십시오.
