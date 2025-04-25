import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class LoadingIndicator extends StatelessWidget {
  final bool isLoading;
  final bool noMoreData;
  final String loadingText;
  final String noMoreDataText;

  const LoadingIndicator({
    super.key,
    this.isLoading = false,
    this.noMoreData = false,
    this.loadingText = 'Loading more matches...',
    this.noMoreDataText = 'No more matches',
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            const CupertinoActivityIndicator(
              radius: 14,
              color: Color(0xFF94E831),
            ),
            const SizedBox(height: 10),
            Text(
              loadingText,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      );
    } else if (noMoreData) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 0.5,
              color: Colors.white.withOpacity(0.2),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Text(
                noMoreDataText,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              width: 50,
              height: 0.5,
              color: Colors.white.withOpacity(0.2),
            ),
          ],
        ),
      );
    }
    return const SizedBox(height: 20);
  }
} 