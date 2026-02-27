import 'package:flutter/material.dart';
import '../../controllers/chart_controller.dart';

class ChartControls extends StatelessWidget {
  final ChartController controller;

  const ChartControls({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            border: Border(
              bottom: BorderSide(color: Colors.grey[850]!, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF0F3460),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: controller.codeController,
                    onChanged: controller.searchStocks,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      hintText: '종목명 또는 코드 검색',
                      hintStyle: TextStyle(
                        color: Color(0xFF506680),
                        fontSize: 13,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: InputBorder.none,
                      prefixIcon: Icon(
                        Icons.search,
                        color: Color(0xFF506680),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                label: '조회',
                icon: Icons.download,
                onPressed: controller.isLoading
                    ? null
                    : controller.resetAndFetch,
                color: const Color(0xFF0F3460),
              ),
            ],
          ),
        ),
        if (controller.isSearching || controller.searchResults.isNotEmpty)
          _buildSearchResults(context),
      ],
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        border: Border(
          bottom: BorderSide(color: Colors.grey[850]!, width: 0.5),
        ),
      ),
      child: controller.isSearching
          ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF4FC3F7),
                  ),
                ),
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              itemCount: controller.searchResults.length,
              itemBuilder: (context, index) {
                final stock = controller.searchResults[index];
                return ListTile(
                  dense: true,
                  title: Text(
                    stock.name,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  subtitle: Text(
                    '${stock.code} | ${stock.marketLabel}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                  onTap: () => controller.selectStock(stock),
                );
              },
            ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return SizedBox(
      height: 40,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
      ),
    );
  }
}
