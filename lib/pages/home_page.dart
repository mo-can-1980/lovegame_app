import 'package:flutter/material.dart';
import '../components/tennis_calendar.dart';
import '../components/glass_icon_button.dart';
import '../components/tennis_score_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime selectedDate = DateTime.now();
  late List<DateTime> calendarDates;

  @override
  void initState() {
    super.initState();
    calendarDates = _generateWeekDates(selectedDate);
  }

  List<DateTime> _generateWeekDates(DateTime date) {
    final firstDate = date.subtract(Duration(days: date.weekday - 1));
    return List.generate(7, (index) => firstDate.add(Duration(days: index)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景图片
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 280, // 调整高度以覆盖日历和地点组件
            child: Image.network(
              'https://images.unsplash.com/photo-1595435934249-5df7ed86e1c0?q=80&w=1920&auto=format&fit=crop',
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.black,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.black,
                  child: const Center(
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                );
              },
            ),
          ),
          // 渐变遮罩
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 280,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.4),
                  ],
                ),
              ),
            ),
          ),

          // 主要内容
          SafeArea(
            child: Column(
              children: [
                // 顶部栏
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GlassIconButton(
                        icon: Icons.search,
                        onPressed: () {
                          // TODO: 实现搜索功能
                        },
                      ),
                      const Text(
                        'Tennis',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          GlassIconButton(
                            icon: Icons.calendar_today,
                            onPressed: () {
                              // TODO: 实现日历功能
                            },
                          ),
                          const SizedBox(width: 8),
                          GlassIconButton(
                            icon: Icons.person,
                            onPressed: () {
                              // TODO: 实现个人中心功能
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 日历组件
                TennisCalendar(
                  selectedDate: selectedDate,
                  dates: calendarDates,
                  onDateSelected: (date) {
                    setState(() {
                      selectedDate = date;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // 地点信息
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Madrid, Spain',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 比赛列表
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                    ),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        TennisScoreCard(
                          player1: 'R. Nadal',
                          player2: 'C. Alcaraz',
                          player1Rank: '(1)',
                          player2Rank: '',
                          player1Country: 'ESP',
                          player2Country: 'ESP',
                          serving1: true,
                          serving2: false,
                          roundInfo: 'round of 32',
                          set1Scores: [5, 0, 0],
                          set2Scores: [1, 0, 0],
                          currentGameScore1: '30',
                          currentGameScore2: '0',
                          onWatchPressed: () {
                            // TODO: 实现观看功能
                          },
                          onDetailPressed: () {
                            // TODO: 实现查看详情功能
                          },
                        ),
                        TennisScoreCard(
                          player1: 'A. Popyrin',
                          player2: 'J. Sinner',
                          player1Rank: '',
                          player2Rank: '(14)',
                          player1Country: 'AUS',
                          player2Country: 'ITA',
                          serving1: false,
                          serving2: true,
                          roundInfo: 'round of 32',
                          set1Scores: [0, 0, 2],
                          set2Scores: [0, 0, 3],
                          currentGameScore1: '0',
                          currentGameScore2: '0',
                          onWatchPressed: () {
                            // TODO: 实现观看功能
                          },
                          onDetailPressed: () {
                            // TODO: 实现查看详情功能
                          },
                        ),
                        TennisScoreCard(
                          player1: 'N. Djokovic',
                          player2: 'D. Medvedev',
                          player1Rank: '(2)',
                          player2Rank: '(4)',
                          player1Country: 'SRB',
                          player2Country: 'RUS',
                          serving1: true,
                          serving2: false,
                          roundInfo: 'round of 16',
                          set1Scores: [6, 3, 1],
                          set2Scores: [4, 6, 0],
                          currentGameScore1: '40',
                          currentGameScore2: '15',
                          onWatchPressed: () {
                            // TODO: 实现观看功能
                          },
                          onDetailPressed: () {
                            // TODO: 实现查看详情功能
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
