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
  final String currentGameScore1; // 当前局的得分 (0, 15, 30, 40, Ad)
  final String currentGameScore2;
  final VoidCallback? onWatchPressed;
  final VoidCallback? onDetailPressed;

  const TennisScoreCard({
    super.key,
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
    this.currentGameScore1 = '0',
    this.currentGameScore2 = '0',
    this.onWatchPressed,
    this.onDetailPressed,
  });

  @override
  Widget build(BuildContext context) {
    // 获取国旗图片URL
    final player1FlagUrl = _getFlagImageUrl(player1Country);
    final player2FlagUrl = _getFlagImageUrl(player2Country);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Table(
                    defaultColumnWidth: const IntrinsicColumnWidth(),
                    columnWidths: const {
                      0: FlexColumnWidth(2.0), // 球员名字列
                    },
                    children: [
                      TableRow(
                        children: [
                          TableCell(
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: Image.network(
                                    player1FlagUrl,
                                    width: 16,
                                    height: 12,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => 
                                      Container(
                                        width: 16,
                                        height: 12,
                                        color: Colors.grey[300],
                                      ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '$player1 $player1Rank',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13.0,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...List.generate(
                            set1Scores.length,
                            (index) => TableCell(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                child: Text(
                                  set1Scores[index].toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14.0,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          TableCell(
                            child: Container(
                              constraints: const BoxConstraints(minWidth: 30),
                              margin: const EdgeInsets.only(left: 2.0),
                              padding: const EdgeInsets.only(left: 2.0),
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: Colors.grey[300]!,
                                    width: 1.0,
                                  ),
                                ),
                              ),
                              child: Center(
                                child: serving1
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          margin: const EdgeInsets.only(right: 2),
                                          decoration: const BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        Text(
                                          currentGameScore1,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14.0,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      currentGameScore1,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14.0,
                                      ),
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          TableCell(
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: Image.network(
                                    player2FlagUrl,
                                    width: 16,
                                    height: 12,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => 
                                      Container(
                                        width: 16,
                                        height: 12,
                                        color: Colors.grey[300],
                                      ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '$player2 $player2Rank',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13.0,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...List.generate(
                            set2Scores.length,
                            (index) => TableCell(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                child: Text(
                                  set2Scores[index].toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14.0,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          TableCell(
                            child: Container(
                              constraints: const BoxConstraints(minWidth: 30),
                              margin: const EdgeInsets.only(left: 2.0),
                              padding: const EdgeInsets.only(left: 2.0),
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: Colors.grey[300]!,
                                    width: 1.0,
                                  ),
                                ),
                              ),
                              child: Center(
                                child: serving2
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          margin: const EdgeInsets.only(right: 2),
                                          decoration: const BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        Text(
                                          currentGameScore2,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14.0,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      currentGameScore2,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14.0,
                                      ),
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
            const SizedBox(height: 12.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: onDetailPressed,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  ),
                  child: const Text('查看详情'),
                ),
                ElevatedButton(
                  onPressed: onWatchPressed,
                  style: ElevatedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  ),
                  child: const Text('观看直播'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 根据国家代码获取国旗图片URL
  String _getFlagImageUrl(String countryCode) {
    // 使用Unsplash上的国旗图片
    final Map<String, String> flagUrls = {
      'ESP': 'https://images.unsplash.com/photo-1464790719320-516ecd75af6c?w=32&h=24&fit=crop&auto=format',
      'ITA': 'https://images.unsplash.com/photo-1518730518541-d0843268c287?w=32&h=24&fit=crop&auto=format',
      'AUS': 'https://images.unsplash.com/photo-1624138115358-32823ec13672?w=32&h=24&fit=crop&auto=format',
      'USA': 'https://images.unsplash.com/photo-1520106212299-d99c443e4568?w=32&h=24&fit=crop&auto=format',
      'GBR': 'https://images.unsplash.com/photo-1526659666036-c3baaa2fc3b5?w=32&h=24&fit=crop&auto=format',
      'FRA': 'https://images.unsplash.com/photo-1560363199-a1264d4ea5fc?w=32&h=24&fit=crop&auto=format',
      'DEU': 'https://images.unsplash.com/photo-1527866512907-a35a62a0f6c5?w=32&h=24&fit=crop&auto=format',
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
                  "-",
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
                  "SERVICE",
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
}
