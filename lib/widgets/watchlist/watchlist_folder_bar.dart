import 'package:flutter/material.dart';
import '../../models/stock_master.dart';
import '../../models/market_status.dart';

/// 관심종목 화면 상단에서 폴더(그룹) 탭과 시장 상태(개장/폐장)를 표시하는 바 위젯입니다.
class WatchlistFolderBar extends StatelessWidget {
  final List<WatchlistFolder> folders; // 표시할 폴더 리스트
  final int selectedFolderIndex; // 현재 선택된 폴더의 인덱스
  final MarketStatus? marketStatus; // 서버에서 받은 실시간 시장 상태
  final Function(int) onFolderSelected; // 폴더 탭 클릭 시 실행될 콜백
  final VoidCallback onAddFolder; // '+' 버튼 클릭 시 폴더 추가 팝업을 띄우는 콜백

  const WatchlistFolderBar({
    super.key,
    required this.folders,
    required this.selectedFolderIndex,
    required this.onFolderSelected,
    required this.onAddFolder,
    this.marketStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50, // 상단 바 고정 높이
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 1. 왼쪽 영역: 수평으로 스크롤 가능한 폴더 탭 리스트
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: folders.length + 1, // 폴더들 + 마지막 추가(+) 버튼
              itemBuilder: (context, index) {
                // 리스트의 마지막 아이템인 경우 '+' 버튼 표시
                if (index == folders.length) {
                  return IconButton(
                    icon: const Icon(Icons.add, color: Colors.grey),
                    onPressed: onAddFolder,
                  );
                }

                final isSelected = index == selectedFolderIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(folders[index].name),
                    selected: isSelected,
                    showCheckmark: false, // 선택 시 체크 표시 숨김 (깔끔한 탭 스타일)
                    onSelected: (selected) {
                      if (selected) {
                        onFolderSelected(index);
                      }
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.transparent),
                    ),
                    selectedColor: Colors.green, // 선택 시 포인트 컬러
                    backgroundColor: const Color(0xFF1E1E1E), // 비선택시 배경색
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[400],
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. 오른쪽 영역: 실시간 시장 상태 표시 뱃지
          if (marketStatus != null) _buildMarketStatus(marketStatus!),
        ],
      ),
    );
  }

  /// 시장 상태(개장/폐장/장외 등)를 나타내는 작은 뱃지 위젯을 생성합니다.
  Widget _buildMarketStatus(MarketStatus status) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        // 상태에 따라 배경색 투명도 조절
        color: status.isMarketOpen
            ? Colors.green.withValues(alpha: 0.2)
            : Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.statusLabel, // '장중', '장외', '정규장종료' 등
        style: TextStyle(
          color: status.isMarketOpen ? Colors.green : Colors.grey,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
