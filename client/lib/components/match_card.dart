import 'package:flutter/material.dart';

class MatchCard extends StatelessWidget {
  final bool isLive;
  final String roundInfo;
  final String player1;
  final String player2;
  final String player1Rank;
  final String player2Rank;
  final String score1;
  final String score2;
  final bool serving1;
  final bool serving2;
  final String set1;
  final String set2;

  const MatchCard({
    super.key,
    required this.isLive,
    required this.roundInfo,
    required this.player1,
    required this.player2,
    required this.player1Rank,
    required this.player2Rank,
    required this.score1,
    required this.score2,
    required this.serving1,
    required this.serving2,
    required this.set1,
    required this.set2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header with LIVE and round info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
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
                      const SizedBox(width: 8),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(width: 8),
                Text(
                  roundInfo,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Player 1 info
          _buildPlayerRow(player1, player1Rank, score1, serving1),
          
          // Player 2 info
          _buildPlayerRow(player2, player2Rank, score2, serving2),
          
          // Set scores
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 180,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        set1,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '-',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        set2,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Watch button
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.play_arrow,
                    color: Colors.black,
                  ),
                  label: const Text(
                    'Watch',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF94E831),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
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

  Widget _buildPlayerRow(
    String playerName,
    String playerRank,
    String score,
    bool isServing,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                playerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (playerRank.isNotEmpty)
                Text(
                  ' $playerRank',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 16,
                  ),
                ),
            ],
          ),
          Row(
            children: [
              Text(
                score,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isServing)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF94E831),
                        width: 1,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.sports_tennis,
                        color: Color(0xFF94E831),
                        size: 12,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                'SERVICE',
                style: TextStyle(
                  color: isServing
                      ? const Color(0xFF94E831)
                      : Colors.transparent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 