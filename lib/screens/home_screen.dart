import 'package:flutter/material.dart';

import 'watchlist_screen.dart';
import 'chart_screen.dart';
import 'account_screen.dart';
import 'trade_screen.dart';

/// 메인 앱 — 4탭 네비게이션 쉘
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 1; // 차트 탭을 기본으로 시작

  final _screens = const [
    WatchlistScreen(),
    ChartScreen(),
    AccountScreen(),
    TradeScreen(),
  ];

  final _titles = const ['관심종목', '차트', '계좌', '매매'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
        backgroundColor: const Color(0xFF0D1117),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey[850]!, width: 0.5)),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: const Color(0xFF0D1117),
            selectedItemColor: const Color(0xFF4FC3F7),
            unselectedItemColor: Colors.grey[600],
            selectedFontSize: 11,
            unselectedFontSize: 11,
            enableFeedback: false,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.star_outline),
                activeIcon: Icon(Icons.star),
                label: '관심종목',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.candlestick_chart_outlined),
                activeIcon: Icon(Icons.candlestick_chart),
                label: '차트',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_outlined),
                activeIcon: Icon(Icons.account_balance_wallet),
                label: '계좌',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.swap_horiz),
                activeIcon: Icon(Icons.swap_horiz),
                label: '매매',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
