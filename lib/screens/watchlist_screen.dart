import 'package:flutter/material.dart';
import '../controllers/watchlist_controller.dart';
import '../widgets/watchlist/watchlist_folder_bar.dart';
import '../widgets/watchlist/watchlist_stock_tile.dart';
import '../widgets/watchlist/watchlist_search_bar.dart';

/// 관심종목 화면
class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final WatchlistController _controller = WatchlistController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final isSearchingView =
            _controller.isSearching || _controller.searchResults.isNotEmpty;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              if (isSearchingView)
                Expanded(
                  child: WatchlistSearchBar(
                    controller: _searchController,
                    searchResults: _controller.searchResults,
                    isSearching: _controller.isSearching,
                    onChanged: _controller.handleSearch,
                    onStockAdded: (stock) async {
                      try {
                        await _controller.addStock(stock);
                        _searchController.clear();
                      } catch (e) {
                        _showError(e.toString());
                      }
                    },
                  ),
                )
              else
                WatchlistSearchBar(
                  controller: _searchController,
                  searchResults: _controller.searchResults,
                  isSearching: _controller.isSearching,
                  onChanged: _controller.handleSearch,
                  onStockAdded: (stock) async {
                    try {
                      await _controller.addStock(stock);
                      _searchController.clear();
                    } catch (e) {
                      _showError(e.toString());
                    }
                  },
                ),
              if (!isSearchingView) ...[
                WatchlistFolderBar(
                  folders: _controller.folders,
                  selectedFolderIndex: _controller.selectedFolderIndex,
                  marketStatus: _controller.marketStatus,
                  onFolderSelected: _controller.switchFolder,
                  onAddFolder: _showAddFolderDialog,
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _controller.currentFolder?.stocks.length ?? 0,
                    onReorder: _controller.reorderStocks,
                    itemBuilder: (context, index) {
                      final folder = _controller.currentFolder;
                      if (folder == null || index >= folder.stocks.length) {
                        return SizedBox(key: ValueKey('empty_$index'));
                      }
                      final stock = folder.stocks[index];
                      final code = stock.code.startsWith('A')
                          ? stock.code.substring(1)
                          : stock.code;
                      return WatchlistStockTile(
                        key: ValueKey('stock_$code'),
                        stock: stock,
                        detail: _controller.stockDetails[code],
                        realtime: _controller.realtimePrices[code],
                        marketStatus: _controller.marketStatus,
                        onDismissed: (code) =>
                            _controller.removeStock(index, code),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showAddFolderDialog() {
    final folderController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('새 폴더 생성'),
        content: TextField(
          controller: folderController,
          decoration: const InputDecoration(hintText: '폴더 이름을 입력하세요'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              if (folderController.text.isNotEmpty) {
                final navigator = Navigator.of(context);
                try {
                  await _controller.addFolder(folderController.text);
                  navigator.pop();
                } catch (e) {
                  _showError(e.toString());
                }
              }
            },
            child: const Text('생성'),
          ),
        ],
      ),
    );
  }
}
