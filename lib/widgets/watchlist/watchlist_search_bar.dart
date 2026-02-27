import 'package:flutter/material.dart';
import '../../models/stock_master.dart';

/// 관심종목 화면 내에서 종목을 검색하고 결과를 리스트로 보여주는 위젯입니다.
class WatchlistSearchBar extends StatelessWidget {
  final TextEditingController controller; // 검색 입력 필드 제어용 컨트롤러
  final List<StockMaster> searchResults; // 검색 API 결과 리스트
  final bool isSearching; // 현재 검색 API 호출 중인지 여부 (로딩 표시용)
  final Function(String) onChanged; // 텍스트 입력 시 실시간으로 호출될 콜백
  final Function(StockMaster) onStockAdded; // 검색 결과에서 '추가' 버튼 클릭 시 호출될 콜백

  const WatchlistSearchBar({
    super.key,
    required this.controller,
    required this.searchResults,
    required this.isSearching,
    required this.onChanged,
    required this.onStockAdded,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. 상단 검색어 입력 필드
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: '종목명 또는 코드 검색',
              hintStyle: TextStyle(color: Colors.grey[600]),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              // 검색어가 있을 때만 'X' (Clear) 버튼 표시
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        controller.clear();
                        onChanged(''); // 상태 초기화
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: onChanged, // 입력을 감시하여 검색 실행
          ),
        ),

        // 2. 검색 결과 또는 로딩 상태 표시 영역
        if (searchResults.isNotEmpty || isSearching)
          Expanded(child: _buildResults()),
      ],
    );
  }

  /// 검색 결과 리스트 또는 로딩 인디케이터를 생성합니다.
  Widget _buildResults() {
    // 검색 중인 경우 중앙에 회전하는 로딩바 표시
    if (isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    // 결과 데이터가 있을 경우 리스트 뷰로 렌더링
    return ListView.builder(
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final stock = searchResults[index];
        return ListTile(
          title: Text(stock.name, style: const TextStyle(color: Colors.white)),
          subtitle: Text(
            '${stock.code} | ${stock.marketLabel}',
            style: TextStyle(color: Colors.grey[500]),
          ),
          trailing: TextButton(
            onPressed: () => onStockAdded(stock), // 클릭 시 상위 컨트롤러로 종목 전달
            child: const Text('추가', style: TextStyle(color: Colors.red)),
          ),
        );
      },
    );
  }
}
