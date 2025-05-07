import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_svg/flutter_svg.dart';
import '../models/tournament_model.dart';
import '../services/tournament_service.dart';
import '../services/api_service.dart';

class TournamentCalendarPage extends StatefulWidget {
  const TournamentCalendarPage({super.key});

  @override
  _TournamentCalendarPageState createState() => _TournamentCalendarPageState();
}

class _TournamentCalendarPageState extends State<TournamentCalendarPage>
    with SingleTickerProviderStateMixin {
  final TournamentService _tournamentService = TournamentService();
  List<dynamic> _tournaments = [];
  List<dynamic> _tournamentDates = [];
  late DateTime _currentMonth;
  late int _daysInMonth;
  late int _firstDayOfWeek;
  bool _isLoading = true;
  bool _showCalendar =
      false; // Control whether to display calendar or list view

  // Add year and month lists
  List<int> _years = [];
  final List<int> _months = List.generate(12, (index) => index + 1);

  // Define theme colors
  final Color _primaryColor = const Color(0xFF94E831); // Primary green color
  final Color _secondaryColor = Colors.black; // Black background
  final Color _accentColor = const Color(0xFFF67F21); // Orange accent color

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _updateCalendarData();
    _loadTournamentsFromAsset();

    // Initialize year list (2 years before and after current year)
    final currentYear = DateTime.now().year;
    _years = List.generate(5, (index) => currentYear - 2 + index);
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Test CORS issues
  Future<void> _testCORS() async {
    print('Starting CORS test...');
    try {
      // Use ApiService to handle CORS issues
      final data = await ApiService.getTournamentCalendar();

      print('API request successful - Can access ATP API');
      // Process returned data
      // ...
    } catch (e) {
      print('CORS test exception: $e');
      print('Exception type: ${e.runtimeType}');

      // Identify different types of errors
      if (e.toString().contains('XMLHttpRequest')) {
        print('Confirmed CORS issue - Browser blocked cross-origin request');
      } else if (e.toString().contains('Connection refused') ||
          e.toString().contains('Connection reset')) {
        print('Network connection issue - Server refused or reset connection');
      } else if (e.toString().contains('timed out')) {
        print('Connection timeout - Server did not respond');
      } else if (e.toString().contains('403')) {
        print('Access denied - Server rejected the request');
      } else if (e.toString().contains('404')) {
        print('Resource not found - Requested resource does not exist');
      } else if (e.toString().contains('500')) {
        print('Server error - Internal server error');
      }
    }
  }

  // Attempt to fetch data from backend API
  Future<Map<String, dynamic>?> _fetchFromBackendAPI() async {
    try {
      // Try to get data from our own backend service
      // Note: Please replace with your actual backend API URL
      final backendResponse = await http
          .get(
            Uri.parse('https://your-backend-api.com/tournaments'),
          )
          .timeout(const Duration(seconds: 5));

      if (backendResponse.statusCode == 200) {
        print('Successfully retrieved data from backend API');
        return json.decode(backendResponse.body);
      }
    } catch (e) {
      print('Failed to retrieve data from backend API: $e');
    }
    return null;
  }

  // Keep original method unchanged
  void _updateCalendarData() {
    final firstDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    _firstDayOfWeek = firstDayOfMonth.weekday;

    final lastDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    _daysInMonth = lastDayOfMonth.day;
  }

  // Load tournament data from ATP official website
  Future<void> _loadTournamentsFromAsset() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> data;

      // Try to get the latest data from API
      try {
        // Note: In a production environment, you should use your own backend service to proxy requests to avoid CORS issues
        // Here we try a different URL format, or consider using a proxy service
        print('Starting ATP tournament data request...');
        data = await _loadFromAsset();
      } catch (e) {
        print('Failed to retrieve data from API: $e');
        print('Error type: ${e.runtimeType}');

        // Due to potential CORS issues with API request, use built-in resource file
        data = await _loadFromAsset();
      }

      // Keep data processing logic unchanged
      setState(() {
        _tournamentDates = data['TournamentDates'] ?? [];
        _tournaments = [];

        final currentMonthData = _tournamentDates
            .where((item) =>
                item['month'] == _currentMonth.month &&
                (item['year'] == _currentMonth.year || item['year'] == null))
            .toList();

        // Process tournaments in current month
        for (var monthData in currentMonthData) {
          if (monthData.containsKey('Tournaments')) {
            final List<dynamic> tournamentsInMonth = monthData['Tournaments'];

            for (var tournament in tournamentsInMonth) {
              Map<String, dynamic> processedTournament =
                  Map<String, dynamic>.from(tournament);

              // 解析开始日期
              if (tournament['startDate'] != null) {
                try {
                  final DateTime startDate =
                      DateTime.parse(tournament['startDate']);

                  // Modified: No longer restrict to only add when start date is in current month
                  // If start date is in current month
                  if (startDate.month == _currentMonth.month &&
                      startDate.year == _currentMonth.year) {
                    processedTournament['startDay'] = startDate.day;
                    processedTournament['startDateFull'] = startDate;
                  } else if (startDate.month < _currentMonth.month ||
                      (startDate.year < _currentMonth.year &&
                          startDate.month > _currentMonth.month)) {
                    // If start date is in previous month, set to 1st day of current month
                    processedTournament['startDay'] = 1;
                    processedTournament['startDateFull'] =
                        DateTime(_currentMonth.year, _currentMonth.month, 1);
                    processedTournament['isCrossMonth'] = true;
                  } else {
                    // If start date is in next month, keep original date
                    processedTournament['startDay'] = startDate.day;
                    processedTournament['startDateFull'] = startDate;
                  }
                } catch (e) {
                  print(
                      'Error parsing start date: ${tournament['startDate']} - $e');
                  processedTournament['startDay'] =
                      _extractDayFromString(tournament['startDate']);
                }
              }

              // 解析结束日期
              if (tournament['endDate'] != null) {
                try {
                  final DateTime endDate =
                      DateTime.parse(tournament['endDate']);

                  // Check if end date is in current month
                  if (endDate.month == _currentMonth.month &&
                      endDate.year == _currentMonth.year) {
                    processedTournament['endDay'] = endDate.day;
                    processedTournament['endDateFull'] = endDate;
                  } else if (endDate.month > _currentMonth.month ||
                      (endDate.year > _currentMonth.year &&
                          endDate.month < _currentMonth.month)) {
                    // If end date is in next month, set to last day of current month
                    processedTournament['endDay'] = _daysInMonth;
                    processedTournament['endDateFull'] = DateTime(
                        _currentMonth.year, _currentMonth.month, _daysInMonth);
                    processedTournament['isCrossNextMonth'] = true;
                  } else {
                    // Modified: If end date is in previous month, but start date is also in previous month, don't display
                    // If start date is in current month or earlier, it should be displayed
                    if (processedTournament['startDateFull'] != null) {
                      final startDateFull =
                          processedTournament['startDateFull'] as DateTime;
                      if (startDateFull.month == _currentMonth.month &&
                          startDateFull.year == _currentMonth.year) {
                        // If start date is in current month, keep this tournament
                        processedTournament['endDay'] =
                            1; // Set to first day of current month
                        processedTournament['endDateFull'] = DateTime(
                            _currentMonth.year, _currentMonth.month, 1);
                      } else {
                        // If both start and end are not in current month, skip
                        continue;
                      }
                    } else {
                      continue;
                    }
                  }
                } catch (e) {
                  print(
                      'Error parsing end date: ${tournament['endDate']} - $e');
                  processedTournament['endDay'] =
                      _extractDayFromString(tournament['endDate']);
                }
              }

              // 添加到比赛列表
              _tournaments.add(processedTournament);
            }
          }
        }

        // Process cross-month tournaments - Check if tournaments from previous and next month extend into current month
        _processCrossMonthTournaments();

        _isLoading = false;
      });
    } catch (e) {
      print('Error loading tournament data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Load data from built-in resource file
  Future<Map<String, dynamic>> _loadFromAsset() async {
    print('Loading data from built-in resource file');
    try {
      final String jsonData =
          await rootBundle.loadString('assets/2025_atp_tournament.json');
      return json.decode(jsonData);
    } catch (e) {
      print('Failed to read built-in resource file: $e');
      // Return an empty data structure to avoid null errors
      return {'TournamentDates': []};
    }
  }

  // 从字符串中提取日期数字
  int _extractDayFromString(String dateStr) {
    // 如果是格式为 "2025-01-05" 的日期字符串
    if (dateStr.contains('-')) {
      final parts = dateStr.split('-');
      if (parts.length >= 3) {
        return int.tryParse(parts[2]) ?? 1;
      }
    }
    return 1; // 默认值
  }

  // 处理跨月的比赛
  void _processCrossMonthTournaments() {
    // Get year and month of previous month
    int prevYear = _currentMonth.year;
    int prevMonth = _currentMonth.month - 1;
    if (prevMonth == 0) {
      prevMonth = 12;
      prevYear--;
    }

    // Get year and month of next month
    int nextYear = _currentMonth.year;
    int nextMonth = _currentMonth.month + 1;
    if (nextMonth == 13) {
      nextMonth = 1;
      nextYear++;
    }

    // Find data for previous month
    final prevMonthData = _tournamentDates
        .where((item) =>
            item['month'] == prevMonth &&
            (item['year'] == prevYear || item['year'] == null))
        .toList();

    // Process tournaments that start in previous month and end in current month
    for (var monthData in prevMonthData) {
      if (monthData.containsKey('Tournaments')) {
        final List<dynamic> tournamentsInMonth = monthData['Tournaments'];

        for (var tournament in tournamentsInMonth) {
          // Only process tournaments not yet added
          bool alreadyAdded = false;
          String tournamentId = tournament['Id'] ?? '';

          // Check if this tournament is already in current month list
          for (var existingTournament in _tournaments) {
            if (existingTournament['Id'] == tournamentId) {
              alreadyAdded = true;
              break;
            }
          }

          if (!alreadyAdded) {
            // Try to parse start and end dates
            if (tournament['startDate'] != null &&
                tournament['endDate'] != null) {
              try {
                final DateTime startDate =
                    DateTime.parse(tournament['startDate']);
                final DateTime endDate = DateTime.parse(tournament['endDate']);

                // Determine if tournament crosses into current month
                // Condition: start date in previous month, end date in current month or later
                if (startDate.month == prevMonth &&
                    startDate.year == prevYear &&
                    ((endDate.month == _currentMonth.month &&
                            endDate.year == _currentMonth.year) ||
                        (endDate.month > _currentMonth.month ||
                            endDate.year > _currentMonth.year))) {
                  // Create a new tournament record
                  Map<String, dynamic> crossMonthTournament =
                      Map<String, dynamic>.from(tournament);

                  // Set start date in current month to 1st day
                  crossMonthTournament['startDay'] = 1;
                  crossMonthTournament['startDateFull'] =
                      DateTime(_currentMonth.year, _currentMonth.month, 1);

                  // Set end date
                  if (endDate.month == _currentMonth.month &&
                      endDate.year == _currentMonth.year) {
                    crossMonthTournament['endDay'] = endDate.day;
                    crossMonthTournament['endDateFull'] = endDate;
                  } else {
                    // If end date is in a later month, set to last day of current month
                    crossMonthTournament['endDay'] = _daysInMonth;
                    crossMonthTournament['endDateFull'] = DateTime(
                        _currentMonth.year, _currentMonth.month, _daysInMonth);
                  }

                  crossMonthTournament['isCrossMonth'] = true;
                  _tournaments.add(crossMonthTournament);

                  print(
                      'Adding cross-month tournament: ${crossMonthTournament['Name']} from ${startDate.toString()} to ${endDate.toString()}');
                }
              } catch (e) {
                print(
                    'Error parsing date when processing cross-month tournament: ${tournament['startDate']} - ${tournament['endDate']} - $e');
              }
            }
          }
        }
      }
    }

    // Find data for next month, process tournaments that start in current month and end in next month
    final nextMonthData = _tournamentDates
        .where((item) =>
            item['month'] == nextMonth &&
            (item['year'] == nextYear || item['year'] == null))
        .toList();

    // Check if any tournaments in current month extend into next month
    for (var tournament in List.from(_tournaments)) {
      if (tournament['endDate'] != null) {
        try {
          final DateTime endDate = DateTime.parse(tournament['endDate']);
          if (endDate.month == nextMonth && endDate.year == nextYear) {
            // This tournament extends into next month, mark as crossing to next month
            tournament['isCrossNextMonth'] = true;
            print(
                'Marking tournament extending to next month: ${tournament['Name']}');
          }
        } catch (e) {
          print('Error checking tournament extending to next month: $e');
        }
      }
    }
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
      _updateCalendarData();
    });
    _loadTournamentsFromAsset();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
      _updateCalendarData();
    });
    _loadTournamentsFromAsset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: _secondaryColor,
        // appBar: AppBar(
        //   backgroundColor: Colors.transparent,
        //   elevation: 0,
        //   title: const Text(
        //     '',
        //     style: TextStyle(
        //       color: Colors.white,
        //       fontSize: 18,
        //       fontWeight: FontWeight.bold,
        //     ),
        //   ),
        //   centerTitle: false,
        // ),
        body: SafeArea(
            child: Container(
          decoration: BoxDecoration(
            color: _secondaryColor,
          ),
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: _primaryColor))
              : _showCalendar
                  ? _buildCalendarView()
                  : _buildPlayListView(),
        )));
  }

  // Calendar view
  Widget _buildCalendarView() {
    return Column(
      children: [
        _buildHeader(),
        _buildWeekdayHeader(),
        Expanded(
          child: _buildCalendarGrid(),
        ),
        _buildFooter(),
      ],
    );
  }

  // Tournament list view
  Widget _buildPlayListView() {
    // Filter tournaments for current month
    final monthlyTournaments = _tournaments
        .where((tournament) =>
            tournament['startDateFull'] != null ||
            tournament['endDateFull'] != null)
        .toList();

    // Sort by start date
    monthlyTournaments.sort((a, b) {
      final aStartDate = a['startDateFull'] as DateTime? ??
          (a['startDay'] != null
              ? DateTime(_currentMonth.year, _currentMonth.month, a['startDay'])
              : DateTime(_currentMonth.year, _currentMonth.month, 1));

      final bStartDate = b['startDateFull'] as DateTime? ??
          (b['startDay'] != null
              ? DateTime(_currentMonth.year, _currentMonth.month, b['startDay'])
              : DateTime(_currentMonth.year, _currentMonth.month, 1));

      return aStartDate.compareTo(bStartDate);
    });

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: monthlyTournaments.isEmpty
              ? Center(
                  child: Text(
                    'No tournaments this month',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 16,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  itemCount: monthlyTournaments.length,
                  itemBuilder: (context, index) {
                    final tournament = monthlyTournaments[index];
                    return _buildTournamentCard(tournament);
                  },
                ),
        ),
      ],
    );
  }

  // Bottom navigation bar

  // Create a tournament card (optimize text alignment and visual effects)
  Widget _buildTournamentCard(dynamic tournament) {
    final String name = tournament['Name'] ?? '';
    final String location = tournament['Location'] ?? '';
    final String surface = tournament['Surface'] ?? '';
    final String type = tournament['Type'] ?? '';
    final String prize = tournament['PrizeMoneyDetails'] ?? '';
    final String formattedDate = tournament['FormattedDate'] ?? '';

    // Date processing
    String dateRange = formattedDate.isNotEmpty ? formattedDate : '';

    if (dateRange.isEmpty &&
        tournament['startDate'] != null &&
        tournament['endDate'] != null) {
      try {
        final startDate = DateTime.parse(tournament['startDate']);
        final endDate = DateTime.parse(tournament['endDate']);
        dateRange =
            '${startDate.day} ${_getMonthShortName(startDate.month)} - ${endDate.day} ${_getMonthShortName(endDate.month)}';
      } catch (e) {
        int? startDay = tournament['startDay'];
        int? endDay = tournament['endDay'];
        if (startDay != null && endDay != null) {
          dateRange =
              '$startDay - $endDay ${_getMonthName(_currentMonth.month)}';
        }
      }
    }

    // Get color for surface type
    Color surfaceColor;
    IconData surfaceIcon;
    switch (surface.toString().toLowerCase()) {
      case 'clay':
        surfaceColor = const Color(0xFFE26B10); // 红土场标准橙红色
        surfaceIcon = Icons.circle;
        break;
      case 'hard':
        surfaceColor = const Color(0xFF0078C8); // 硬地场标准蓝色
        surfaceIcon = Icons.square;
        break;
      case 'grass':
        surfaceColor = const Color(0xFF4CAF50); // 草地场标准绿色
        surfaceIcon = Icons.grass;
        break;
      case 'indoor':
        surfaceColor = const Color(0xFF673AB7); // 室内场紫色
        surfaceIcon = Icons.home;
        break;
      default:
        surfaceColor = const Color(0xFF0078C8);
        surfaceIcon = Icons.question_mark;
    }

    // Use high-quality tournament images and SVG resources consistently
    final String tournamentImage = tournament['TournamentImage'] ??
        'https://images.unsplash.com/photo-1595435934249-5df7ed86e1c0?q=80&w=1920&auto=format&fit=crop';
    const String atp250Svg = 'assets/images/categorystamps_250.png';
    const String atp500Svg = 'assets/images/categorystamps_500.png';
    const String atpMasterSvg = 'assets/images/categorystamps_1000.png';

    // Create badge based on tournament type - using SVG images
    Widget typeBadge;
    switch (type) {
      case '1000':
        typeBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          // decoration: BoxDecoration(
          //   color: Colors.black54,
          //   borderRadius: BorderRadius.circular(4),
          //   border: Border.all(color: Colors.white24, width: 0.5),
          // ),
          child: Image.asset(
            atpMasterSvg,
            width: 80,
            height: 44,
            color: Colors.white,
          ),
        );
        break;
      case '500':
        typeBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          // decoration: BoxDecoration(
          //   color: Colors.black54,
          //   borderRadius: BorderRadius.circular(4),
          //   border: Border.all(color: Colors.white24, width: 0.5),
          // ),
          child: Image.asset(
            atp500Svg,
            width: 120,
            height: 44,
            color: Colors.white,
          ),
        );
        break;
      case '250':
        typeBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          // decoration: BoxDecoration(
          //     // color: Colors.black54,
          //     // borderRadius: BorderRadius.circular(4),
          //     // border: Border.all(color: Colors.white24, width: 0.5),
          //     ),
          child: Image.asset(
            atp250Svg,
            width: 120,
            height: 44,
            color: Colors.white,
          ),
        );
        break;
      default:
        typeBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white24, width: 0.5),
          ),
          child: Text(
            type,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'Serif',
              letterSpacing: 0.5,
            ),
          ),
        );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: _secondaryColor,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showTournamentDetails(tournament),
        child: Stack(
          children: [
            // Background image
            Image.network(
              tournamentImage,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                // 加载中显示黑色背景
                return Container(
                  color: const Color.fromARGB(255, 75, 75, 75),
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                // 图片加载失败时显示黑色背景
                return Container(
                  color: Colors.black,
                  child: Center(
                    child: Icon(
                      Icons.sports_tennis,
                      color: Colors.white.withOpacity(0.3),
                      size: 48,
                    ),
                  ),
                );
              },
            ),
            // Gradient overlay
            Container(
              height: 240,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.2, 0.6, 0.9],
                ),
              ),
            ),
            // Content layout - optimize spacing and font size
            // Content layout - optimize spacing and font size
            Positioned.fill(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min, // 修改为 min 以避免溢出
                  children: [
                    // Tournament level badge
                    Center(child: typeBadge),
                    const SizedBox(height: 16),

                    // Tournament name - main title
                    Flexible(
                      // 添加 Flexible 包装
                      child: Text(
                        name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18, // 减小字号
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Serif',
                          letterSpacing: 0.5,
                          height: 1.2,
                          shadows: [
                            Shadow(
                              blurRadius: 4,
                              color: Color.fromARGB(255, 27, 27, 27),
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Location - subtitle
                    Text(
                      location,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15, // 减小字号
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Serif',
                        letterSpacing: 0.3,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16), // 减小间距

                    // Date and venue information - secondary information area
                    Flexible(
                      // 添加 Flexible 包装
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min, // 设置为 min
                        children: [
                          // Date information
                          Icon(
                            Icons.calendar_today,
                            color: Colors.white60,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            // 添加 Flexible 包装
                            child: Text(
                              dateRange,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                height: 1.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Separator
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8), // 减小间距
                            child: Text(
                              "•",
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 14,
                              ),
                            ),
                          ),

                          // // 场地类型
                          // Icon(
                          //   surfaceIcon,
                          //   color: surfaceColor,
                          //   size: 14,
                          // ),
                          // const SizedBox(width: 6),
                          Text(
                            surface,
                            style: TextStyle(
                              color: surfaceColor,
                              fontWeight: FontWeight.normal,
                              fontStyle: FontStyle.italic,
                              fontSize: 14,
                              height: 1.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Prize money information - bottom emphasis area
                    if (prize.isNotEmpty && name.length < 20) // 添加条件限制
                      Padding(
                        padding: const EdgeInsets.only(top: 12), // 减小间距
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 3), // 减小内边距
                          // decoration: BoxDecoration(
                          //   border: Border.all(
                          //     color: _primaryColor.withOpacity(0.4),
                          //     width: 1,
                          //   ),
                          //   borderRadius: BorderRadius.circular(12),
                          // ),
                          child: Text(
                            'Prize: $prize',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _primaryColor,
                              fontSize: 12, // 减小字号
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Create elegant month and year selector
  Widget _buildMonthYearPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        // 将 Row 改为 Column，解决水平空间不足问题
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First row: Order of Play and Tournament Calendar tabs
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showCalendar = false;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: Text(
                    'Schedule List',
                    style: TextStyle(
                      color: !_showCalendar ? Colors.white : Colors.grey,
                      fontSize: 16,
                      fontWeight:
                          !_showCalendar ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showCalendar = true;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calendar',
                        style: TextStyle(
                          color: _showCalendar ? Colors.white : Colors.grey,
                          fontSize: 16,
                          fontWeight: _showCalendar
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Second row: Month, year selector and download button
          const SizedBox(height: 12), // 添加垂直间距
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side: Month and year selector
              Wrap(
                // 使用 Wrap 代替 Row，允许在空间不足时自动换行
                spacing: 8, // 水平间距
                runSpacing: 8, // 垂直间距
                children: [
                  // Month selector
                  GestureDetector(
                    onTap: () {
                      _showMonthPicker(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min, // 设置为最小尺寸
                        children: [
                          Text(
                            _getMonthName(_currentMonth.month),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_drop_down,
                            color: _primaryColor,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Year selector
                  GestureDetector(
                    onTap: () {
                      _showYearPicker(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min, // 设置为最小尺寸
                        children: [
                          Text(
                            _currentMonth.year.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_drop_down,
                            color: _primaryColor,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 替换原有的Header方法
  Widget _buildHeader() {
    return _buildMonthYearPicker();
  }

  Widget _buildWeekdayHeader() {
    const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: _secondaryColor,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.3),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: weekdays.map((day) {
          final isWeekend = day == 'Sat' || day == 'Sun';
          return SizedBox(
            width: 40,
            child: Center(
              child: Text(
                day,
                style: TextStyle(
                  color: isWeekend ? _accentColor : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 显示月份选择器
  void _showMonthPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _secondaryColor,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Month',
                style: TextStyle(
                  color: _primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final month = index + 1;
                    final isSelected = month == _currentMonth.month;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentMonth =
                              DateTime(_currentMonth.year, month, 1);
                          _updateCalendarData();
                        });
                        _loadTournamentsFromAsset();
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? _primaryColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isSelected
                                ? _primaryColor
                                : Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _getMonthName(month),
                          style: TextStyle(
                            color: isSelected ? _secondaryColor : Colors.white,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 显示年份选择器
  void _showYearPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _secondaryColor,
      builder: (BuildContext context) {
        return Container(
          height: 250,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Year',
                style: TextStyle(
                  color: _primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _years.length,
                  itemBuilder: (context, index) {
                    final year = _years[index];
                    final isSelected = year == _currentMonth.year;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentMonth =
                              DateTime(year, _currentMonth.month, 1);
                          _updateCalendarData();
                        });
                        _loadTournamentsFromAsset();
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? _primaryColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isSelected
                                ? _primaryColor
                                : Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          year.toString(),
                          style: TextStyle(
                            color: isSelected ? _secondaryColor : Colors.white,
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCalendarGrid() {
    // 计算总格子数
    final totalCells =
        (_firstDayOfWeek == 7 ? 0 : _firstDayOfWeek) + _daysInMonth;
    final totalRows = (totalCells / 7).ceil();

    // 为每一天创建日历格子
    List<Widget> cells = [];

    // 添加空白格子填充第一行
    int firstDayAdjusted =
        _firstDayOfWeek == 7 ? 0 : _firstDayOfWeek; // Adjust Sunday to 0
    for (int i = 0; i < firstDayAdjusted; i++) {
      cells.add(Container());
    }

    // 添加当月的所有天
    for (int day = 1; day <= _daysInMonth; day++) {
      cells.add(_buildDayCell(day));
    }

    // 添加额外的空白格子填充最后一行
    final remainingCells = totalRows * 7 - cells.length;
    for (int i = 0; i < remainingCells; i++) {
      cells.add(Container());
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      padding: const EdgeInsets.all(8.0),
      child: GridView.count(
        crossAxisCount: 7,
        childAspectRatio: 0.75,
        children: cells,
      ),
    );
  }

  Widget _buildDayCell(int day) {
    final date = DateTime(_currentMonth.year, _currentMonth.month, day);
    final isToday = _isToday(date);
    final tournamentsOnDay = _getTournamentsOnDay(day);
    final hasTournament = tournamentsOnDay.isNotEmpty;

    // 检查日期是否为周末
    final isWeekend = date.weekday == 6 || date.weekday == 7;

    return Container(
      margin: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        color: isToday ? _primaryColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isToday ? _primaryColor : Colors.grey.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          // 日期
          Container(
            padding: const EdgeInsets.all(4.0),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isWeekend
                  ? _accentColor.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: Text(
              day.toString(),
              style: TextStyle(
                color: isToday ? _primaryColor : Colors.white,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
          ),
          // 赛事列表
          Expanded(
            child: hasTournament
                ? ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 2.0, vertical: 2.0),
                    itemCount: tournamentsOnDay.length,
                    itemBuilder: (context, index) {
                      final tournament = tournamentsOnDay[index];
                      return _buildTournamentIndicator(tournament, day);
                    },
                  )
                : Container(),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentIndicator(dynamic tournament, int day) {
    // 获取日期范围
    int? startDay = tournament['startDay'];
    int? endDay = tournament['endDay'];

    // 如果没有有效的日期数据，返回空容器
    if (startDay == null || endDay == null) return Container();

    final isStartDay = day == startDay;
    final isEndDay = day == endDay;
    final isMiddleDay = day > startDay && day < endDay;

    // 根据赛事类别设置颜色和图标
    Color tournamentColor;
    String? tournamentEmoji;

    // 使用正确的字段名称
    final surface = tournament['Surface'] ?? '';
    final type = tournament['Type'] ?? '';

    // 根据赛事表面类型和级别分配颜色
    switch (surface.toString().toLowerCase()) {
      case 'clay':
        tournamentColor = Colors.red;
        tournamentEmoji = '🧱';
        break;
      case 'hard':
        tournamentColor = Colors.blue;
        tournamentEmoji = '🔷';
        break;
      case 'grass':
        tournamentColor = Colors.green;
        tournamentEmoji = '🌱';
        break;
      case 'indoor':
        tournamentColor = Colors.purple;
        tournamentEmoji = '🏠';
        break;
      default:
        // 如果没有表面信息，根据类型设置
        if (type == '1000') {
          tournamentColor = Colors.pink;
          tournamentEmoji = '💫';
        } else if (type == '500') {
          tournamentColor = _primaryColor;
          tournamentEmoji = '🎾';
        } else if (type == '250') {
          tournamentColor = Colors.amber;
          tournamentEmoji = '🎯';
        } else {
          tournamentColor = Colors.blueGrey;
          tournamentEmoji = '🌍';
        }
    }

    return GestureDetector(
      onTap: () {
        _showTournamentDetails(tournament);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 2.0),
        padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 1.0),
        decoration: BoxDecoration(
          color: _secondaryColor,
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(
            color: tournamentColor,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            if (isStartDay) ...[
              Text(
                tournamentEmoji,
                style: const TextStyle(fontSize: 10),
              ),
              const SizedBox(width: 2),
            ],
            if (isMiddleDay) ...[
              Container(
                width: 3,
                height: 12,
                decoration: BoxDecoration(
                  color: tournamentColor,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
              const SizedBox(width: 2),
            ],
            Expanded(
              child: Text(
                isStartDay
                    ? (tournament['Name'] ?? '')
                    : isMiddleDay
                        ? (_getShortTournamentName(tournament['Name'] ?? ''))
                        : (isEndDay ? 'Finals' : ''),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tournamentColor,
                  fontSize: 8.0,
                  fontWeight: isStartDay || isEndDay
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
            if (isEndDay) ...[
              Icon(
                Icons.emoji_events_outlined,
                color: tournamentColor,
                size: 8,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getShortTournamentName(String name) {
    // 缩短比赛名称
    if (name.length <= 8) return name;

    final nameParts = name.split(' ');
    if (nameParts.length > 1) {
      // 取第一个单词的首字母
      return nameParts.map((word) => word[0]).join('').toUpperCase();
    }

    return '${name.substring(0, 6)}...';
  }

  void _showTournamentDetails(dynamic tournament) {
    // 使用正确的字段名称
    final String name = tournament['Name'] ?? '';
    final String location = tournament['Location'] ?? '';
    final String surface = tournament['Surface'] ?? 'Unknown';
    final String type = tournament['Type'] ?? 'Unknown';

    // 格式化日期范围显示
    String dateRange = '';
    if (tournament['startDate'] != null && tournament['endDate'] != null) {
      try {
        final DateTime startDate = DateTime.parse(tournament['startDate']);
        final DateTime endDate = DateTime.parse(tournament['endDate']);

        dateRange =
            '${startDate.year}-${startDate.month}-${startDate.day} to ${endDate.year}-${endDate.month}-${endDate.day}';
      } catch (e) {
        // 如果解析失败，使用简单的开始和结束日
        int? startDay = tournament['startDay'];
        int? endDay = tournament['endDay'];

        if (startDay != null && endDay != null) {
          if (tournament['isCrossMonth'] == true ||
              tournament['isCrossNextMonth'] == true) {
            dateRange = 'Crosses month boundary';
          } else {
            dateRange =
                '$startDay-$endDay ${_getMonthName(_currentMonth.month)}';
          }
        } else {
          dateRange = 'Date information unavailable';
        }
      }
    } else {
      // Fallback
      int? startDay = tournament['startDay'];
      int? endDay = tournament['endDay'];

      if (startDay != null && endDay != null) {
        dateRange = '$startDay-$endDay ${_getMonthName(_currentMonth.month)}';
      } else {
        dateRange = 'Date information unavailable';
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _secondaryColor,
        title: Text(
          name,
          style: TextStyle(
            color: _primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow(Icons.location_on, location),
            const SizedBox(height: 8),
            _infoRow(Icons.grass, 'Surface: $surface'),
            const SizedBox(height: 8),
            _infoRow(Icons.emoji_events, 'Type: $type'),
            const SizedBox(height: 8),
            _infoRow(
              Icons.calendar_today,
              'Date: $dateRange',
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text(
              'Close',
              style: TextStyle(color: _primaryColor),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Clay', Colors.red),
              const SizedBox(width: 12),
              _buildLegendItem('Hard', Colors.blue),
              const SizedBox(width: 12),
              _buildLegendItem('Grass', Colors.green),
              const SizedBox(width: 12),
              _buildLegendItem('Indoor', Colors.purple),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tap on event for details',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // 获取特定日期上的赛事
  List<dynamic> _getTournamentsOnDay(int day) {
    return _tournaments.where((tournament) {
      int? startDay = tournament['startDay'];
      int? endDay = tournament['endDay'];

      // 如果没有有效的日期数据，返回false
      if (startDay == null || endDay == null) return false;

      // 检查当天是否在赛事日期范围内
      return day >= startDay && day <= endDay;
    }).toList();
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.day == now.day &&
        date.month == now.month &&
        date.year == now.year;
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  String _getMonthShortName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}
