import 'package:flutter/material.dart';
import 'dart:ui';

class TennisCalendar extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const TennisCalendar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<TennisCalendar> createState() => _TennisCalendarState();
}

class _TennisCalendarState extends State<TennisCalendar> {
  late List<DateTime> _calendarDates;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _calendarDates = _generateMonthDates(widget.selectedDate);

    // 在下一帧渲染完成后滚动到选中日期
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate();
    });
  }

  @override
  void didUpdateWidget(TennisCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _scrollToSelectedDate();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 滚动到选中的日期
  void _scrollToSelectedDate() {
    final selectedIndex = _calendarDates.indexWhere((date) =>
        date.day == widget.selectedDate.day &&
        date.month == widget.selectedDate.month &&
        date.year == widget.selectedDate.year);

    if (selectedIndex >= 0) {
      // 计算需要滚动的位置，使选中日期居中
      const itemWidth = 60.0; // 每个日期项的宽度
      final screenWidth = MediaQuery.of(context).size.width;
      final offset =
          (selectedIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2);

      _scrollController.animateTo(
        offset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // 生成整个月的日期
  List<DateTime> _generateMonthDates(DateTime selectedDate) {
    final DateTime firstDayOfMonth =
        DateTime(selectedDate.year, selectedDate.month, 1);
    final int daysInMonth =
        DateTime(selectedDate.year, selectedDate.month + 1, 0).day;

    return List.generate(
      daysInMonth,
      (index) => DateTime(selectedDate.year, selectedDate.month, index + 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
            child: Text(
              '${_getMonthName(widget.selectedDate.month)}, ${widget.selectedDate.year}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(
            height: 100,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              itemCount: _calendarDates.length,
              itemBuilder: (context, index) {
                final date = _calendarDates[index];
                final isSelected = date.day == widget.selectedDate.day &&
                    date.month == widget.selectedDate.month &&
                    date.year == widget.selectedDate.year;
                final isToday = _isToday(date);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: GestureDetector(
                    onTap: () => widget.onDateSelected(date),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: 52,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withOpacity(0.45)
                                : isToday
                                    ? Colors.white.withOpacity(0.25)
                                    : Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 0.5)
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _getDayName(date.weekday),
                                style: TextStyle(
                                  color: Colors.white
                                      .withOpacity(isSelected ? 1.0 : 0.7),
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                width: 36,
                                height: 36,
                                decoration: isSelected
                                    ? const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      )
                                    : null,
                                child: Center(
                                  child: Text(
                                    date.day.toString(),
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.black
                                          : Colors.white,
                                      fontSize: 18,
                                      fontWeight: isSelected || isToday
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}
