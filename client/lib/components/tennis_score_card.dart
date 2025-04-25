import 'package:flutter/material.dart';

class TennisScoreCard extends StatelessWidget {
  final String player1;
  final String player2;
  final String player1Rank;
  final String player2Rank;
  final String player1Country;
  final String player2Country;
  final bool serving1;
  final bool serving2;
  final bool isLive;
  final String roundInfo;
  final List<int> set1Scores; // 第一位球员在每盘的得分
  final List<int> set2Scores; // 第二位球员在每盘的得分
  final List<int> tiebreak1; // 第一位球员在抢七中的小分
  final List<int> tiebreak2; // 第二位球员在抢七中的小分
  final String currentGameScore1; // 当前局的得分 (0, 15, 30, 40, Ad)
  final String currentGameScore2;
  final String? matchDuration; // 比赛时长，仅用于已完成的比赛
  final VoidCallback? onWatchPressed;
  final VoidCallback? onDetailPressed;
  final bool isPlayer1Winner; // 新增：标识球员1是否为获胜者
  final bool isPlayer2Winner; // 新增：标识球员2是否为获胜者
  final String? matchType;

  const TennisScoreCard(
      {super.key,
      required this.player1,
      required this.player2,
      this.player1Rank = '',
      this.player2Rank = '',
      required this.player1Country,
      required this.player2Country,
      this.serving1 = false,
      this.serving2 = false,
      this.isLive = true,
      required this.roundInfo,
      required this.set1Scores,
      required this.set2Scores,
      this.tiebreak1 = const [],
      this.tiebreak2 = const [],
      this.currentGameScore1 = '0',
      this.currentGameScore2 = '0',
      this.matchDuration,
      this.onWatchPressed,
      this.onDetailPressed,
      this.isPlayer1Winner = false, // 默认为false
      this.isPlayer2Winner = false, // 默认为false
      this.matchType});

  @override
  Widget build(BuildContext context) {
    // 获取国旗图片URL
    final player1FlagUrl = _getFlagImageUrl(player1Country);
    final player2FlagUrl = _getFlagImageUrl(player2Country);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    const backgroundColor = Color(0xFF0C0D0C); // 使用深灰色背景
    final borderColor = Colors.white.withOpacity(0.04); // 减小边框透明度，使其更加微妙
    debugPrint('player1: $player1');
    debugPrint('player2: $player2');
    debugPrint('set1Scores: $set1Scores');
    debugPrint('set2Scores: $set2Scores');
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.5), // 减小边框宽度
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 显示比赛状态和回合信息
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 10.0, 12.0, 4.0),
            child: Row(
              children: [
                // 直播或已完成状态指示器
                if (isLive)
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF94E831),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Color(0xFF94E831),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Text(
                        matchType == 'completed' ? 'Completed' : 'Unmatch',
                        style: TextStyle(
                          color: Color(0xFFAC49FF),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (matchDuration != null)
                        Row(
                          children: [
                            const SizedBox(width: 6),
                            Text(
                              '$matchDuration',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                const SizedBox(width: 8),
                Text(
                  roundInfo,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // 分隔线
          Divider(
            height: 1,
            thickness: 1,
            color: borderColor,
          ),

          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // 比分表格
                LayoutBuilder(builder: (context, constraints) {
                  // 计算每列的宽度
                  final availableWidth = constraints.maxWidth;
                  final playerColumnWidth = availableWidth * 0.65; // 球员名列宽度
                  // 确保所有行有相同数量的列
                  const totalColumns = 4; // +1 是球员列
                  final scoreColumnWidth =
                      (availableWidth - playerColumnWidth) / totalColumns - 1;

                  // 创建列宽映射
                  final Map<int, TableColumnWidth> columnWidths = {
                    0: FixedColumnWidth(playerColumnWidth), // 球员名字列
                  };

                  // 为所有比分列设置相同宽度
                  for (int i = 1; i < totalColumns; i++) {
                    columnWidths[i] = FixedColumnWidth(scoreColumnWidth);
                  }
                  return Table(
                    defaultColumnWidth: FixedColumnWidth(scoreColumnWidth),
                    columnWidths: {
                      0: FixedColumnWidth(playerColumnWidth), // 球员名字
                      1: FixedColumnWidth(scoreColumnWidth), // 第一局
                      2: FixedColumnWidth(scoreColumnWidth), // 第二局
                      3: FixedColumnWidth(scoreColumnWidth), // 第三局
                      // 当前局分列（仅直播时显示）
                    },
                    children: [
                      TableRow(
                        children: [
                          // 球员1名称
                          // 在TableRow中显示球员1名称的部分
                          TableCell(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  player1Country,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Text(
                                        '${player1.replaceAll(RegExp(r'[\r\n]+'), '')} ${player1Rank.replaceAll(RegExp(r'[\r\n]+'), '')}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14.0,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (!isLive && isPlayer1Winner)
                                        const Padding(
                                          padding: EdgeInsets.only(left: 4.0),
                                          child: Icon(
                                            Icons.check_circle,
                                            color: Color(0xFF94E831),
                                            size: 14.0,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TableCell(
                            child: Container(
                              alignment: Alignment.centerRight,
                              child: _buildSetScoreWidget(
                                set1Scores.length > 0 ? set1Scores[0] : 0,
                                set2Scores.length > 0 ? set2Scores[0] : 0,
                                tiebreak1.length > 0 ? tiebreak1[0] : 0,
                                tiebreak2.length > 0 ? tiebreak2[0] : 0,
                                isPlayer1: true,
                              ),
                            ),
                          ),
                          TableCell(
                            child: Container(
                              alignment: Alignment.centerRight,
                              child: _buildSetScoreWidget(
                                set1Scores.length > 1 ? set1Scores[1] : 0,
                                set2Scores.length > 1 ? set2Scores[1] : 0,
                                tiebreak1.length > 1 ? tiebreak1[1] : 0,
                                tiebreak2.length > 1 ? tiebreak2[1] : 0,
                                isPlayer1: true,
                              ),
                            ),
                          ),
                          TableCell(
                            child: Container(
                              alignment: Alignment.centerRight,
                              child: _buildSetScoreWidget(
                                set1Scores.length > 2 ? set1Scores[2] : 0,
                                set2Scores.length > 2 ? set2Scores[2] : 0,
                                tiebreak1.length > 2 ? tiebreak1[2] : 0,
                                tiebreak2.length > 2 ? tiebreak2[2] : 0,
                                isPlayer1: true,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // 球员2信息
                      TableRow(
                        children: [
                          // 球员2名称
                          TableCell(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  player2Country,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Text(
                                        '${player2.replaceAll(RegExp(r'[\r\n]+'), '')} ${player2Rank.replaceAll(RegExp(r'[\r\n]+'), '')}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14.0,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (!isLive && isPlayer2Winner)
                                        const Padding(
                                          padding: EdgeInsets.only(left: 4.0),
                                          child: Icon(
                                            Icons.check_circle,
                                            color: Color(0xFF94E831),
                                            size: 14.0,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TableCell(
                            child: Container(
                              alignment: Alignment.centerRight,
                              child: _buildSetScoreWidget(
                                set2Scores.length > 0 ? set2Scores[0] : 0,
                                set1Scores.length > 0 ? set1Scores[0] : 0,
                                tiebreak2.length > 0 ? tiebreak2[0] : 0,
                                tiebreak1.length > 0 ? tiebreak1[0] : 0,
                                isPlayer1: false,
                              ),
                            ),
                          ),
                          TableCell(
                            child: Container(
                              alignment: Alignment.centerRight,
                              child: _buildSetScoreWidget(
                                set2Scores.length > 1 ? set2Scores[1] : 0,
                                set1Scores.length > 1 ? set1Scores[1] : 0,
                                tiebreak2.length > 1 ? tiebreak2[1] : 0,
                                tiebreak1.length > 1 ? tiebreak1[1] : 0,
                                isPlayer1: false,
                              ),
                            ),
                          ),
                          TableCell(
                            child: Container(
                              alignment: Alignment.centerRight,
                              child: _buildSetScoreWidget(
                                set2Scores.length > 2 ? set2Scores[2] : 0,
                                set1Scores.length > 2 ? set1Scores[2] : 0,
                                tiebreak2.length > 2 ? tiebreak2[2] : 0,
                                tiebreak1.length > 2 ? tiebreak1[2] : 0,
                                isPlayer1: false,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }),

                const SizedBox(height: 16.0),

                // 按钮区域
                Row(
                  children: [
                    // 查看详情按钮
                    Expanded(
                      child: TextButton(
                        onPressed: onDetailPressed,
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFF0C0D0C), // 使用深灰色背景
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          foregroundColor: Colors.white.withOpacity(0.7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                                color: Colors.white.withOpacity(0.1)),
                          ),
                        ),
                        child: const Text(
                          'Match detail',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 观看按钮
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onWatchPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF94E831),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(
                          Icons.play_arrow,
                          size: 16,
                        ),
                        label: const Text(
                          'Watch',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 根据国家代码获取国旗图片URL
  String _getFlagImageUrl(String countryCode) {
    // 使用Unsplash上的国旗图片
    final Map<String, String> flagUrls = {
      'ESP':
          'https://images.unsplash.com/photo-1464790719320-516ecd75af6c?w=32&h=24&fit=crop&auto=format',
      'ITA':
          'https://images.unsplash.com/photo-1518730518541-d0843268c287?w=32&h=24&fit=crop&auto=format',
      'AUS':
          'https://images.unsplash.com/photo-1624138115358-32823ec13672?w=32&h=24&fit=crop&auto=format',
      'USA':
          'https://images.unsplash.com/photo-1520106212299-d99c443e4568?w=32&h=24&fit=crop&auto=format',
      'GBR':
          'https://images.unsplash.com/photo-1526659666036-c3baaa2fc3b5?w=32&h=24&fit=crop&auto=format',
      'FRA':
          'https://images.unsplash.com/photo-1560363199-a1264d4ea5fc?w=32&h=24&fit=crop&auto=format',
      'DEU':
          'https://images.unsplash.com/photo-1527866512907-a35a62a0f6c5?w=32&h=24&fit=crop&auto=format',
    };

    return flagUrls[countryCode] ??
        'https://images.unsplash.com/photo-1516906561371-53f48df9fe4c?w=32&h=24&fit=crop&auto=format';
  }

  Widget _buildPlayerRow(
    BuildContext context,
    String name,
    String country,
    String rank,
    bool isServing,
    String currentScore,
    List<int> playerScores,
    List<int> opponentScores,
    bool isFirstPlayer,
  ) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Row(
      children: [
        // 发球指示器
        if (isServing)
          Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF94E831),
                width: 1,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.circle,
                color: Color(0xFF94E831),
                size: 6,
              ),
            ),
          )
        else
          const SizedBox(width: 24),

        // 国旗与球员名称
        Row(
          children: [
            // 国旗
            Container(
              width: 24,
              height: 16,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.2)
                      : Colors.black.withOpacity(0.1),
                  width: 0.5,
                ),
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image:
                      AssetImage('assets/flags/${country.toLowerCase()}.png'),
                  onError: (exception, stackTrace) =>
                      const AssetImage('assets/flags/placeholder.png'),
                ),
              ),
            ),

            // 球员名称和排名
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (rank.isNotEmpty)
                      Text(
                        ' $rank',
                        style: TextStyle(
                          color: textColor.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),

        const Spacer(),

        // 比分
        Row(
          children: [
            // 当前局比分
            Container(
              width: 30,
              alignment: Alignment.center,
              child: Text(
                currentScore,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // 横线或破折号 (仅展示一个)
            if (playerScores.isNotEmpty)
              Container(
                width: 15,
                alignment: Alignment.center,
                child: Text(
                  '-',
                  style: TextStyle(
                    color: textColor.withOpacity(0.5),
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),

            // 第一盘得分
            if (playerScores.isNotEmpty)
              Container(
                width: 25,
                alignment: Alignment.center,
                child: Text(
                  playerScores[0].toString(),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            // 绿色得分指示器 (如果该球员正在发球)
            if (isServing)
              Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(left: 8),
                alignment: Alignment.center,
                child: const Text(
                  'SERVICE',
                  style: TextStyle(
                    color: Color(0xFF94E831),
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // 根据网球规则格式化盘分数
  String _formatSetScore(int playerScore, int opponentScore) {
    // 如果是抢七
    if (playerScore >= 6 && opponentScore >= 6) {
      return playerScore.toString();
    }
    // 常规得分
    return playerScore.toString();
  }

  String formatGameScore(int points) {
    switch (points) {
      case 0:
        return '0';
      case 1:
        return '15';
      case 2:
        return '30';
      case 3:
        return '40';
      case 4:
        return 'Ad';
      default:
        return '';
    }
  }

  bool isDeuce(int player1Points, int player2Points) {
    return player1Points >= 3 &&
        player2Points >= 3 &&
        player1Points == player2Points;
  }

  String getCurrentGameScore(int player1Points, int player2Points) {
    if (isDeuce(player1Points, player2Points)) {
      return '40';
    }

    if (player1Points >= 3 && player2Points >= 3) {
      if (player1Points > player2Points) {
        return 'Ad';
      } else if (player2Points > player1Points) {
        return '40';
      }
    }

    return formatGameScore(player1Points);
  }

  Widget _buildSetScoreWidget(
      int playerScore, int opponentScore, int playerTie, int opponentTie,
      {bool isPlayer1 = true}) {
    // 直接查找此列的索引
    debugPrint(
        'playerScore: $playerScore, opponentScore: $opponentScore,playerTie: $playerTie, opponentTie: $opponentTie');
    // int setIndex = -1;
    // for (int i = 0; i < set1Scores.length; i++) {
    //   if (isPlayer1 &&
    //           set1Scores[i] == playerScore &&
    //           set2Scores[i] == opponentScore ||
    //       !isPlayer1 &&
    //           set2Scores[i] == playerScore &&
    //           set1Scores[i] == opponentScore) {
    //     setIndex = i;
    //     break;
    //   }
    // }

    // 获取对应的抢七小分
    // int tiebreakPoint = 0;
    // if (setIndex >= 0) {
    //   tiebreakPoint = isPlayer1
    //       ? (tiebreak1.length > setIndex ? tiebreak1[setIndex] : 0)
    //       : (tiebreak2.length > setIndex ? tiebreak2[setIndex] : 0);
    // }

    // 抢七情况的处理
    bool isStandardTiebreak = (playerTie != 0 || opponentTie != 0);
    bool isExtendedTiebreak = (playerTie > 7 || opponentTie > 7);

    // 判断是否显示小分
    debugPrint('isStandardTiebreak: $isStandardTiebreak');
    // 标准抢七(7-6)：小分显示在输的一方
    if (isStandardTiebreak) {
      bool isLosingPlayer = playerScore < opponentScore;

      if (isLosingPlayer) {
        return _buildTiebreakScore(playerScore, playerTie);
      }
    }
    // 延长抢七(>7分)：双方都显示小分
    else if (isExtendedTiebreak) {
      return _buildTiebreakScore(playerScore, opponentTie);
    }

    // 常规情况，直接显示分数
    return Text(
      playerScore.toString(),
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 15.0,
      ),
    );
  }

  // 创建显示抢七小分的Widget
  Widget _buildTiebreakScore(int score, int tiebreakPoint) {
    return Stack(
      clipBehavior: Clip.none, // 允许超出父容器
      alignment: Alignment.center,
      children: [
        Text(
          score.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15.0,
          ),
        ),
        Positioned(
          top: -5,
          right: -12,
          child: Text(
            '($tiebreakPoint)',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 9.0,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
