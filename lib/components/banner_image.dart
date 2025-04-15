import 'package:flutter/material.dart';

class BannerImage extends StatelessWidget {
  final String imageUrl;
  final double height;
  final Widget? child;
  final double overlayOpacity;
  final bool hasForeground;

  const BannerImage({
    super.key,
    required this.imageUrl,
    this.height = 300.0,
    this.child,
    this.overlayOpacity = 0.35,
    this.hasForeground = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 图片
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Icon(
                  Icons.broken_image,
                  color: Colors.white.withOpacity(0.3),
                  size: 64,
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  color: const Color(0xFF94E831),
                ),
              );
            },
          ),

          // 半透明黑色遮罩
          Container(
            color: Colors.black.withOpacity(overlayOpacity),
          ),

          // 前景子组件（如文字内容）
          if (hasForeground && child != null) child!,
        ],
      ),
    );
  }
}
