/*
 * @Descripttion: 
 * @Author: ouchao
 * @Email: ouchao@sendpalm.com
 * @version: 1.0
 * @Date: 2025-04-21 17:22:17
 * @LastEditors: ouchao
 * @LastEditTime: 2025-04-25 14:51:06
 */
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:html/dom.dart' as dom;

class ApiService {
  static const String _baseUrl = 'https://www.atptour.com';
  static const List<String> _proxyUrls = [
    // 'https://api.allorigins.win/raw?url=',
    // 'https://cors-anywhere.herokuapp.com/',
    // 'https://cors.sh/',
    'https://thingproxy.freeboard.io/fetch/',
    // 'https://cors.io/?'
  ];
  static int _currentProxyIndex = 0;

  static String get _currentProxyUrl {
    return _proxyUrls[_currentProxyIndex];
  }

  static void _rotateProxy() {
    _currentProxyIndex = (_currentProxyIndex + 1) % _proxyUrls.length;
  }

  // 构建URI，根据平台决定是否使用代理
  static Uri _buildUri(String endpoint) {
    if (kIsWeb) {
      // Web平台使用CORS代理
      final String fullUrl = _baseUrl + endpoint;
      try {
        return Uri.parse(_currentProxyUrl + Uri.encodeComponent(fullUrl));
      } catch (e) {
        _rotateProxy(); // 如果当前代理有问题，轮换到下一个
        return Uri.parse(_currentProxyUrl + Uri.encodeComponent(fullUrl));
      }
    } else {
      // 移动平台直接请求
      return Uri.parse(_baseUrl + endpoint);
    }
  }

  // 获取ATP赛事日历数据
  static Future<Map<String, dynamic>> getTournamentCalendar() async {
    try {
      final String endpoint = '/en/-/tournaments/calendar/tour';
      final Uri uri = _buildUri(endpoint);

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('API request failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to get tournament calendar data: $e');
      rethrow;
    }
  }

  // 加载本地比赛数据
  static Future<Map<String, dynamic>> loadLocalTournamentData() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/2025_atp_tournament.json');
      return json.decode(jsonString);
    } catch (e) {
      print('Failed to load local tournament data: $e');
      return {};
    }
  }

  // 根据当前日期查找正在进行的比赛
  static Future<List<Map<String, dynamic>>> findCurrentTournaments() async {
    final tournamentData = await loadLocalTournamentData();
    final DateTime now = DateTime.now();

    List<Map<String, dynamic>> currentTournaments = [];

    if (tournamentData.containsKey('TournamentDates')) {
      for (var dateGroup in tournamentData['TournamentDates']) {
        for (var tournament in dateGroup['Tournaments']) {
          // 解析比赛的开始和结束日期
          final startDate = DateTime.parse(tournament['startDate']);
          final endDate = DateTime.parse(tournament['endDate']);
          print("$startDate ==== $endDate");
          // 检查当前日期是否在比赛日期范围内
          if (now.isAfter(startDate) &&
              now.isBefore(endDate.add(Duration(days: 1)))) {
            currentTournaments.add(tournament);
          }
        }
      }
    }
    return currentTournaments;
  }

  // 获取当日巡回赛比赛数据
  static Future<Map<String, List<Map<String, dynamic>>>>
      getScheduelTournamentMatches(DateTime date) async {
    Map<String, List<Map<String, dynamic>>> matchesByDate = {};
    try {
      // 1. 从本地加载巡回赛数据
      final tournamentData = await loadLocalTournamentData();
      final DateTime now = date;
      final List<Map<String, dynamic>> todayTournaments = [];

      // 2. 查找当日进行的巡回赛
      if (tournamentData.containsKey('TournamentDates')) {
        for (var dateGroup in tournamentData['TournamentDates']) {
          for (var tournament in dateGroup['Tournaments']) {
            // 解析比赛的开始和结束日期
            final startDate = DateTime.parse(tournament['startDate']);
            final endDate = DateTime.parse(tournament['endDate']);

            // 检查当前日期是否在比赛日期范围内
            if (now.isAfter(startDate.subtract(const Duration(days: 1))) &&
                now.isBefore(endDate.add(const Duration(days: 1)))) {
              if (tournament.containsKey('ScheduleUrl')) {
                todayTournaments.add(tournament);
              }
            }
          }
        }
      }

      // 3. 如果没有找到当日比赛，返回空结果
      if (todayTournaments.isEmpty) {
        return matchesByDate;
      }

      // 4. 获取每个巡回赛的比赛数据
      for (var tournament in todayTournaments) {
        final String scheduleUrl = tournament['ScheduleUrl'];
        final Uri uri = _buildUri(scheduleUrl);

        final response = await http.get(
          uri,
          headers: {
            'Accept': 'text/html',
            'User-Agent':
                'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          },
        );
        debugPrint('schedule!!!!!${response.statusCode}');
        if (response.statusCode == 200) {
          final document = parse(response.body);

          // 5. 解析比赛日期
          final tournamentDays =
              document.getElementsByClassName('tournament-day');
          final dateHeader = tournamentDays[0].getElementsByTagName('h4');
          String dateStr = '';
          // 直接获取h4的文本内容，但排除其中的span标签内容
          for (var node in dateHeader.first.nodes) {
            if (node is dom.Text) {
              dateStr += node.text.trim();
            }
          }
          // 清理日期字符串，移除多余空格
          dateStr = dateStr.trim();
          if (!matchesByDate.containsKey(dateStr)) {
            matchesByDate[dateStr] = [];
          }
          final schedules = document.getElementsByClassName('schedule');
          debugPrint('解析schedules: ${schedules.length}, 解析日期: $dateStr');
          for (var scheduleItem in schedules) {
            // 为该日期创建一个空列表
            if (!matchesByDate.containsKey(dateStr)) {
              matchesByDate[dateStr] = [];
            }
            final matchType = scheduleItem.getElementsByClassName('match-type');
            if (matchType.isNotEmpty) {
              continue;
            }
            // 获取比赛时间
            final locationTimestamp = scheduleItem
                .getElementsByClassName('schedule-location-timestamp');
            String matchTime = '';
            String courtInfo = '';
            if (locationTimestamp.isNotEmpty) {
              final spans =
                  locationTimestamp.first.getElementsByTagName('span');
              // 第一个span是球场信息
              if (spans.length > 0) {
                courtInfo = spans[0].text.trim();
              }
              final timestamp =
                  locationTimestamp.first.getElementsByClassName('timestamp');
              if (timestamp.isNotEmpty) {
                matchTime = timestamp.first.text.trim();
              }
            }

            // 获取比赛轮次
            final scheduleContent =
                scheduleItem.getElementsByClassName('schedule-content');
            String round = '';
            if (scheduleContent.isNotEmpty) {
              final scheduleType =
                  scheduleContent.first.getElementsByClassName('schedule-type');
              if (scheduleType.isNotEmpty) {
                round = scheduleType.first.text.trim();
              }
            }

            // 获取球员信息
            final schedulePlayers =
                scheduleItem.getElementsByClassName('schedule-players');
            if (schedulePlayers.isEmpty) continue;

            final players =
                schedulePlayers.first.getElementsByClassName('player');
            final opponents =
                schedulePlayers.first.getElementsByClassName('opponent');

            if (players.isEmpty || opponents.isEmpty) continue;

            // 获取球员1信息
            final player1Element = players.first;
            String player1Name = '';
            String player1Rank = '';

            // 获取名字 (a标签内容)
            final player1NameLinks = player1Element.getElementsByTagName('a');
            if (player1NameLinks.isNotEmpty) {
              player1Name = player1NameLinks.first.text
                  .trim()
                  .replaceAll(RegExp(r'[\r\n]+'), '');
            }
            // 获取排名 (rank class内容)
            final player1RankElements = player1Element
                .getElementsByClassName('rank')
                .first
                .getElementsByTagName('span');
           
            if (player1RankElements.isNotEmpty) {
              player1Rank = player1RankElements.first.text
                  .trim()
                  .replaceAll(RegExp(r'[\r\n]+'), '');
            }
            final player1Country =
                player1Element.getElementsByClassName('atp-flag').isNotEmpty
                    ? player1Element
                        .getElementsByClassName('atp-flag')
                        .first
                        .text
                        .trim()
                        .replaceAll(RegExp(r'[\r\n]+'), '')
                    : '';

            // 获取球员2信息
            final player2Element = opponents.first;
            String player2Name = '';
            String player2Rank = '';

            // 获取名字 (a标签内容)
            final player2NameLinks = player2Element.getElementsByTagName('a');
            if (player2NameLinks.isNotEmpty) {
              player2Name = player2NameLinks.first.text
                  .trim()
                  .replaceAll(RegExp(r'[\r\n]+'), '');
            }

            // 获取排名 (rank class内容)
            final player2RankElements =
                player2Element.getElementsByClassName('rank');
            if (player2RankElements.isNotEmpty) {
              player2Rank = player2RankElements.first.text
                  .trim()
                  .replaceAll(RegExp(r'[\r\n]+'), '');
            }
            final player2Country =
                player2Element.getElementsByClassName('atp-flag').isNotEmpty
                    ? player2Element
                        .getElementsByClassName('atp-flag')
                        .first
                        .text
                        .trim()
                    : '';

            // 7. 构建比赛数据，与现有格式保持一致
            final matchData = {
              'roundInfo': round.toString() +
                  ' ' +
                  courtInfo.toString() +
                  ' ' +
                  matchTime.toString(),
              'matchTime': matchTime,
              'player1': player1Name,
              'player2': player2Name,
              'player1Rank': player1Rank,
              'player2Rank': player2Rank,
              'player1Country': player1Country,
              'player2Country': player2Country,
              // 使用新的存储格式，对于未开始的比赛，设置默认值
              'player1SetScores': [0, 0, 0],
              'player2SetScores': [0, 0, 0],
              'player1TiebreakScores': [0, 0, 0],
              'player2TiebreakScores': [0, 0, 0],
              'isCompleted': false, // 标记为未完成的
              'matchDuration': matchTime,
              'isPlayer1Winner': false, // 添加获胜者标识
              'isPlayer2Winner': false,
              'courtInfo': courtInfo, // 添加获胜者标识
              'matchType': "unmatch"
            };
            // 添加到对应日期的比赛列表
            matchesByDate[dateStr]!.add(matchData);
          }
        } else {
          debugPrint('获取比赛数据失败: ${response.statusCode}');
        }
      }

      return matchesByDate;
    } catch (e) {
      debugPrint('解析比赛数据异常: $e');
      return matchesByDate;
    }
  }

  // 获取特定比赛的实时数据
  static Future<Map<String, dynamic>> getLiveTournamentData(
      String tournamentId) async {
    try {
      final String endpoint = '/en/-/www/LiveMatches/2025/$tournamentId';
      final Uri uri = _buildUri(endpoint);

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        },
      ).timeout(const Duration(seconds: 10));
      debugPrint('getLiveTournamentData!!!!!!!!!!!${response.statusCode}');
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('API request failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to get live tournament data: $e');
      rethrow;
    }
  }

  // 解析比赛数据为应用内部格式
  static List<Map<String, dynamic>> parseMatchesData(
      Map<String, dynamic> apiData) {
    List<Map<String, dynamic>> matches = [];

    try {
      if (apiData.containsKey('LiveMatches') &&
          apiData['LiveMatches'] is List) {
        final liveMatches = apiData['LiveMatches'];
        final tournamentName = apiData['EventTitle'] ?? '';
        final location =
            '${apiData['EventCity'] ?? ''}, ${apiData['EventCountry'] ?? ''}';

        for (var match in liveMatches) {
          if (match['Type'] == 'singles') {
            // 只处理单打比赛
            final playerTeam = match['PlayerTeam'];
            final opponentTeam = match['OpponentTeam'];

            // 构建比赛数据
            Map<String, dynamic> matchData = {
              'player1':
                  '${playerTeam['Player']['PlayerFirstName']} ${playerTeam['Player']['PlayerLastName']}',
              'player2':
                  '${opponentTeam['Player']['PlayerFirstName']} ${opponentTeam['Player']['PlayerLastName']}',
              'player1Rank':
                  playerTeam['Seed'] != null ? '(${playerTeam['Seed']})' : '',
              'player2Rank': opponentTeam['Seed'] != null
                  ? '(${opponentTeam['Seed']})'
                  : '',
              'player1Country': playerTeam['Player']['PlayerCountry'] ?? '',
              'player2Country': opponentTeam['Player']['PlayerCountry'] ?? '',
              'serving1': match['ServerTeam'] == 0,
              'serving2': match['ServerTeam'] == 1,
              'roundInfo': match['RoundName'] ?? '',
              'tournamentName': tournamentName,
              'location': location,
              'matchStatus': match['MatchStatus'] ?? '',
              'player1SetScores': _extractSetScores(playerTeam['SetScores']),
              'player2SetScores': _extractSetScores(opponentTeam['SetScores']),
              'currentGameScore1':
                  _getCurrentGameScore(playerTeam['GameScore']),
              'currentGameScore2':
                  _getCurrentGameScore(opponentTeam['GameScore']),
              'player1TiebreakScores':
                  _extractTiebreakScores(playerTeam['SetScores']),
              'player2TiebreakScores':
                  _extractTiebreakScores(opponentTeam['SetScores']),
              'isPlayer1Winner': false, // 添加获胜者标识
              'isPlayer2Winner': false,
              'matchType': 'live'
            };

            matches.add(matchData);
          }
        }
      }
    } catch (e) {
      print('Failed to parse match data: $e');
    }

    return matches;
  }

  // 提取局分
  static List<int> _extractSetScores(List<dynamic>? setScores) {
    List<int> scores = [];
    if (setScores != null) {
      for (var set in setScores) {
        if (set['SetScore'] != null) {
          scores.add(set['SetScore']);
        } else {
          scores.add(0);
        }
      }
    }
    // 确保至少有3个元素
    while (scores.length < 3) {
      scores.add(0);
    }
    return scores;
  }

  // 提取抢七分数
  static List<int> _extractTiebreakScores(List<dynamic>? setScores) {
    List<int> tiebreakScores = [];
    if (setScores != null) {
      for (var set in setScores) {
        if (set['TieBreakScore'] != null) {
          tiebreakScores.add(set['TieBreakScore']);
        } else {
          tiebreakScores.add(0);
        }
      }
    }
    // 确保至少有3个元素
    while (tiebreakScores.length < 3) {
      tiebreakScores.add(0);
    }
    return tiebreakScores;
  }

  // 获取当前局比分
  static String _getCurrentGameScore(dynamic gameScore) {
    if (gameScore == null) return '0';

    switch (gameScore.toString()) {
      case '0':
        return '0';
      case '1':
        return '15';
      case '2':
        return '30';
      case '3':
        return '40';
      case '4':
        return 'A';
      default:
        return '0';
    }
  }

  // 获取ATP球员排名
  Future<List<dynamic>> getPlayerRankings() async {
    try {
      const String endpoint = '/en/-/www/rank/sglroll/100?v=1';
      final Uri uri = _buildUri(endpoint);

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        print('获取排名失败: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('获取排名异常: $e');
      // 如果API调用失败，返回空列表
      return [];
    }
  }

  // 根据关键词搜索球员
  Future<List<dynamic>> searchPlayers(String keyword) async {
    try {
      // 实际项目中，可能会有专门的搜索API
      // 这里我们简化处理，获取所有排名然后在客户端过滤
      final allPlayers = await getPlayerRankings();

      if (keyword.isEmpty) {
        return allPlayers;
      }

      // 过滤包含关键词的球员
      return allPlayers.where((player) {
        final String fullName =
            '${player['PlayerFirstName']} ${player['PlayerLastName']}'
                .toLowerCase();
        return fullName.contains(keyword.toLowerCase());
      }).toList();
    } catch (e) {
      print('搜索球员异常: $e');
      return [];
    }
  }

  static Future<Map<String, List<Map<String, dynamic>>>>
      getATPMatchesResultData(String? scoresUrl) async {
    Map<String, List<Map<String, dynamic>>> matchesByDate = {};
    try {
      final String? endpoint = scoresUrl;
      final Uri uri = _buildUri(endpoint!);
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        },
      );
      debugPrint('getATPMatchesResultData!!!!!!!!!!!${response.statusCode}');
      if (response.statusCode == 200) {
        final document = parse(response.body);
        final accordionItems =
            document.getElementsByClassName('atp_accordion-item');

        for (var accordionItem in accordionItems) {
          // 查找日期元素
          final tournamentDays =
              accordionItem.getElementsByClassName('tournament-day');
          if (tournamentDays.isEmpty) continue;

          // 获取日期文本
          final dateHeader = tournamentDays.first.getElementsByTagName('h4');
          if (dateHeader.isEmpty) continue;
          String dateStr = '';
          // 直接获取h4的文本内容，但排除其中的span标签内容
          for (var node in dateHeader.first.nodes) {
            if (node is dom.Text) {
              dateStr += node.text.trim();
            }
          }
          // 清理日期字符串，移除多余空格
          dateStr = dateStr.trim();
          debugPrint('解析日期: $dateStr');

          // 为该日期创建一个空列表
          matchesByDate[dateStr] = [];

          // 获取所有比赛元素
          final matchElements = accordionItem.getElementsByClassName('match');
          for (var matchElement in matchElements) {
            // 获取轮次和时间信息
            final matchHeader =
                matchElement.getElementsByClassName('match-header').first;
            final headerSpans = matchHeader.getElementsByTagName('span');
            final String round =
                headerSpans.isNotEmpty ? headerSpans[0].text.trim() : '';
            final String matchTime =
                headerSpans.length > 1 ? headerSpans[1].text.trim() : '';

            // 在获取比赛内容的部分
            final matchContent =
                matchElement.getElementsByClassName('match-content').first;
            final statsItems =
                matchContent.getElementsByClassName('stats-item');
            if (statsItems.length >= 2) {
              // 检查哪位球员是获胜者
              final win1 = statsItems[0].getElementsByClassName('win');
              final win2 = statsItems[1].getElementsByClassName('win');

              final isPlayer1Winner = win1.isNotEmpty;
              final isPlayer2Winner = win2.isNotEmpty;

              // 获取第一个选手信息
              final player1Info =
                  statsItems[0].getElementsByClassName('player-info').first;
              final player1Name =
                  player1Info.getElementsByClassName('name').first.text.trim();
              final player1Country =
                  player1Info.getElementsByClassName('atp-flag').isNotEmpty
                      ? player1Info
                              .getElementsByClassName('atp-flag')
                              .first
                              .attributes['data-country'] ??
                          ''
                      : '';

              // 获取第二个选手信息
              final player2Info =
                  statsItems[1].getElementsByClassName('player-info').first;
              final player2Name =
                  player2Info.getElementsByClassName('name').first.text.trim();
              final player2Country =
                  player2Info.getElementsByClassName('atp-flag').isNotEmpty
                      ? player2Info
                              .getElementsByClassName('atp-flag')
                              .first
                              .attributes['data-country'] ??
                          ''
                      : '';

              // 获取比分信息
              final scores1 = statsItems[0].getElementsByClassName('scores');
              final scores2 = statsItems[1].getElementsByClassName('scores');

              // 改为按球员分别存储比分
              List<int> player1SetScores = [];
              List<int> player2SetScores = [];
              List<int> player1TiebreakScores = [];
              List<int> player2TiebreakScores = [];

              if (scores1.isNotEmpty && scores2.isNotEmpty) {
                // 获取每个选手的得分元素
                final scoreItems1 =
                    scores1.first.getElementsByClassName('score-item');
                final scoreItems2 =
                    scores2.first.getElementsByClassName('score-item');

                // 确保两个选手的得分项数量相同
                final minItems = scoreItems1.length < scoreItems2.length
                    ? scoreItems1.length
                    : scoreItems2.length;

                for (int i = 1; i < minItems; i++) {
                  // 获取当前盘的得分元素
                  final item1 = scoreItems1[i];
                  final item2 = scoreItems2[i];

                  // 获取每个得分项中的所有span元素
                  final spans1 = item1.getElementsByTagName('span');
                  final spans2 = item2.getElementsByTagName('span');

                  // 获取主要得分（第一个span）
                  final s1 = int.tryParse(
                          spans1.isNotEmpty ? spans1[0].text.trim() : '0') ??
                      0;
                  final s2 = int.tryParse(
                          spans2.isNotEmpty ? spans2[0].text.trim() : '0') ??
                      0;

                  // 添加到各自的盘分数组
                  player1SetScores.add(s1);
                  player2SetScores.add(s2);

                  // 检查是否有抢七小分（第二个span）
                  int tb1 = 0;
                  int tb2 = 0;

                  // 检查player1的抢七小分
                  if (spans1.length > 1) {
                    final tiebreakText = spans1[1].text.trim();

                    tb1 = int.tryParse(tiebreakText) ?? 0;
                  }

                  // 检查player2的抢七小分
                  if (spans2.length > 1) {
                    final tiebreakText = spans2[1].text.trim();
                    tb2 = int.tryParse(tiebreakText) ?? 0;
                  }

                  // 添加到各自的抢七分数组
                  player1TiebreakScores.add(tb1);
                  player2TiebreakScores.add(tb2);
                }
              }

              // 创建比赛数据对象时添加获胜者信息
              final matchData = {
                'roundInfo': round,
                'matchTime': matchTime,
                'player1': player1Name,
                'player2': player2Name,
                'player1Country': player1Country,
                'player2Country': player2Country,
                // 使用新的存储格式
                'player1SetScores': player1SetScores,
                'player2SetScores': player2SetScores,
                'player1TiebreakScores': player1TiebreakScores,
                'player2TiebreakScores': player2TiebreakScores,
                'isCompleted': true, // 标记为已完成的
                'matchDuration': matchTime,
                'isPlayer1Winner': isPlayer1Winner, // 添加获胜者标识
                'isPlayer2Winner': isPlayer2Winner, // 添加获胜者标识
              };
              matchesByDate[dateStr]!.add(matchData);
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching ATP matches============: $e');
    }

    return matchesByDate;
  }
}
