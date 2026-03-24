import 'package:flutter/material.dart';
import '../models/activity.dart';
import 'timeline_activity_block.dart';

class TimelineView extends StatefulWidget {
  final List<Activity> activities;

  const TimelineView({super.key, required this.activities});

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  late PageController _pageController;
  late ScrollController _weekScrollController;
  int _currentIndex = 0;
  List<DateTime> _availableWeeks = [];

  @override
  void initState() {
    super.initState();
    _availableWeeks = _getAvailableWeeks();
    final thisWeek = _getStartOfWeek(_normalizeDate(DateTime.now()));
    _currentIndex = _availableWeeks.indexOf(thisWeek);
    if (_currentIndex == -1) _currentIndex = 0;
    
    _pageController = PageController(initialPage: _currentIndex);
    _weekScrollController = ScrollController();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_weekScrollController.hasClients) {
        _weekScrollController.jumpTo(_weekScrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void didUpdateWidget(covariant TimelineView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newWeeks = _getAvailableWeeks();
    if (newWeeks.length != _availableWeeks.length || 
        (_availableWeeks.isNotEmpty && newWeeks.first != _availableWeeks.first)) {
        
      DateTime selectedWeek = _availableWeeks.isNotEmpty && _currentIndex < _availableWeeks.length 
          ? _availableWeeks[_currentIndex] 
          : _getStartOfWeek(_normalizeDate(DateTime.now()));
          
      setState(() {
        _availableWeeks = newWeeks;
        _currentIndex = _availableWeeks.indexOf(selectedWeek);
        if (_currentIndex == -1) {
          _currentIndex = _availableWeeks.indexOf(_getStartOfWeek(_normalizeDate(DateTime.now())));
        }
        if (_currentIndex == -1) _currentIndex = 0;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _weekScrollController.dispose();
    super.dispose();
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _getStartOfWeek(DateTime date) {
    final diff = date.weekday - DateTime.monday;
    return date.subtract(Duration(days: diff));
  }

  List<DateTime> _getAvailableWeeks() {
    final Set<DateTime> weeks = {};
    weeks.add(_getStartOfWeek(_normalizeDate(DateTime.now())));
    for (var a in widget.activities) {
      weeks.add(_getStartOfWeek(_normalizeDate(a.starttime.toLocal())));
      weeks.add(_getStartOfWeek(_normalizeDate(a.endtime.toLocal())));
    }
    return weeks.toList()..sort();
  }

  String _formatWeek(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (weekStart.month == weekEnd.month) {
      return '${months[weekStart.month - 1]} ${weekStart.day} - ${weekEnd.day}';
    } else {
      return '${months[weekStart.month - 1]} ${weekStart.day} - ${months[weekEnd.month - 1]} ${weekEnd.day}';
    }
  }

  String _formatHour(int hour) {
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final ampm = hour < 12 ? 'AM' : 'PM';
    return '$h:00 $ampm';
  }

  String _formatDayHeader(DateTime date) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[date.weekday - 1]}\n${date.day}';
  }

  Widget _buildDayGrid(DateTime date, double hourHeight) {
    final activitiesForDate = widget.activities.where((a) {
      final start = _normalizeDate(a.starttime.toLocal());
      final end = _normalizeDate(a.endtime.toLocal());
      return start.isAtSameMomentAs(date) || end.isAtSameMomentAs(date);
    }).toList();

    return Stack(
      fit: StackFit.expand,
      children: [
        // Horizontal hour lines for this day
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(24, (index) {
            return Container(
              height: hourHeight,
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.black12, width: 1),
                ),
              ),
            );
          }).toList(),
        ),
        
        // Activity Blocks
        ...activitiesForDate.map((activity) {
          final start = activity.starttime.toLocal();
          final end = activity.endtime.toLocal();
          
          DateTime dayStart = date;
          DateTime dayEnd = dayStart.add(const Duration(days: 1));
          
          DateTime effectiveStart = start.isBefore(dayStart) ? dayStart : start;
          DateTime effectiveEnd = end.isAfter(dayEnd) ? dayEnd : end;
          
          final startMinutes = effectiveStart.hour * 60 + effectiveStart.minute;
          final endMinutes = effectiveEnd.hour * 60 + effectiveEnd.minute;
          final durationMinutes = endMinutes - startMinutes;
          
          if (durationMinutes <= 0) return const SizedBox.shrink();
          
          final topOffset = (startMinutes / 60.0) * hourHeight;
          final height = (durationMinutes / 60.0) * hourHeight;
          
          return TimelineActivityBlock(
            activity: activity,
            height: height,
            topOffset: topOffset,
          );
        }),
      ],
    );
  }

  Widget _buildWeekGrid(DateTime weekStart, double hourHeight) {
    return Row(
      children: List.generate(7, (index) {
        final date = weekStart.add(Duration(days: index));
        return Expanded(
          child: Container(
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: Colors.black12, width: 0.5)),
            ),
            child: _buildDayGrid(date, hourHeight),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_availableWeeks.isEmpty) {
      return const Center(child: Text("No weeks available"));
    }

    final currentWeekStart = _availableWeeks[_currentIndex];

    return Column(
      children: [
        // Horizontal Week Selector
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.builder(
            controller: _weekScrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _availableWeeks.length,
            itemBuilder: (context, index) {
              final weekStart = _availableWeeks[index];
              final isSelected = _currentIndex == index;
              return Padding(
                padding: const EdgeInsets.only(right: 8, top: 10, bottom: 10),
                child: ChoiceChip(
                  label: Text(_formatWeek(weekStart)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                ),
              );
            },
          ),
        ),
        
        // Sticky Day Headers
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.black12, width: 1)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 50), // Matches hour demarcation width
              Expanded(
                child: Row(
                  children: List.generate(7, (index) {
                    final date = currentWeekStart.add(Duration(days: index));
                    final isToday = date.isAtSameMomentAs(_normalizeDate(DateTime.now()));
                    return Expanded(
                      child: Text(
                        _formatDayHeader(date),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                          color: isToday ? Theme.of(context).colorScheme.primary : Colors.black87,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),

        // Timeline View
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double hourHeight = constraints.maxHeight / 24;
              
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fixed Hour Demarcations on the left
                  SizedBox(
                    width: 50,
                    child: Column(
                      children: List.generate(24, (index) {
                        return SizedBox(
                          height: hourHeight,
                          child: Text(
                            _formatHour(index),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  
                  // Swipeable Weeks
                  Expanded(
                    child: SizedBox(
                      height: constraints.maxHeight, 
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _availableWeeks.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          final weekStart = _availableWeeks[index];
                          return _buildWeekGrid(weekStart, hourHeight);
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
