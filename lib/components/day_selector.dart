import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

class DaySelector extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  
  const DaySelector({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    // 获取一周的日期，从selectedDate往前3天到往后3天
    final dates = List.generate(
      7,
      (index) => selectedDate.subtract(Duration(days: 3 - index)),
    );

    // 使用ClipRRect进行圆角裁剪
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // 毛玻璃效果
        child: Container(
          height: 85,
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15), // 半透明背景
            borderRadius: BorderRadius.circular(24),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            itemCount: dates.length,
            itemBuilder: (context, index) {
              final date = dates[index];
              final isSelected = date.day == selectedDate.day &&
                  date.month == selectedDate.month &&
                  date.year == selectedDate.year;
              
              final dayOfWeek = DateFormat('EEE').format(date);
              final dayNumber = date.day.toString();
              
              return GestureDetector(
                onTap: () => onDateSelected(date),
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 日期数字
                      Text(
                        dayNumber,
                        style: TextStyle(
                          color: isSelected 
                              ? Colors.black 
                              : Colors.white,
                          fontSize: 22,
                          fontWeight: isSelected 
                              ? FontWeight.w600 
                              : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      
                      // 星期几
                      Text(
                        dayOfWeek.substring(0, 3),
                        style: TextStyle(
                          color: isSelected 
                              ? Colors.black.withOpacity(0.7) 
                              : Colors.white.withOpacity(0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
} 