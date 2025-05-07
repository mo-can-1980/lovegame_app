/*
 * @Descripttion: 
 * @Author: ouchao
 * @Email: ouchao@sendpalm.com
 * @version: 1.0
 * @Date: 2025-04-15 14:20:32
 * @LastEditors: ouchao
 * @LastEditTime: 2025-04-30 19:34:18
 */
import 'package:LoveGame/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'utils/constants.dart';
import 'package:provider/provider.dart';
import 'pages/home_page.dart';
import 'pages/tournament_calendar_page.dart';
import 'pages/player_rankings_page.dart'; // 添加排名页面导入
import 'utils/theme_provider.dart';
import 'services/platform_channel_service.dart';

void main() {
  // 确保Flutter绑定已初始化
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Tennis App',
          debugShowCheckedModeBanner: false,
          theme: ThemeProvider.lightTheme(),
          darkTheme: ThemeProvider.darkTheme(),
          themeMode: themeProvider.themeMode,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('es'),
          ],
          home: const MainNavigationScreen(),
        );
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    HomePage(),
    TournamentCalendarPage(),
    PlayerRankingsPage(), // 添加排名页面
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    Color primaryColor = AppColors.primaryGreen;
    Color secondaryColor = const Color(0xFF121212);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens, // 包含 PlayerRankingsPage 的页面列表
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: secondaryColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 10,
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.sports_tennis),
              label: 'Matches',
              activeIcon: Icon(Icons.sports_tennis),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Schedule',
              activeIcon: Icon(Icons.calendar_month),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.leaderboard),
              label: 'Rankings',
              activeIcon: Icon(Icons.leaderboard),
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey,
          backgroundColor: secondaryColor,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
