import 'package:flutter/material.dart';
import '../models/activity.dart';
import 'pie_chart_view.dart';

class AnalyzeView extends StatefulWidget {
  final List<Activity> activities;

  const AnalyzeView({super.key, required this.activities});

  @override
  State<AnalyzeView> createState() => _AnalyzeViewState();
}

class _AnalyzeViewState extends State<AnalyzeView> {
  // Weekly selection state
  late PageController _pageController;
  late ScrollController _weekScrollController;
  int _currentIndex = 0;
  List<DateTime> _availableWeeks = [];

  // Data state
  List<DateTime> _dates = [];
  Map<DateTime, int> _dayTotals = {};
  Map<DateTime, Map<String, int>> _dayActivities = {};
  Map<String, String> _activityColors = {};
  int _maxDayTotal = 0;
  
  Map<String, int> _weeklyActivityTotals = {};

  @override
  void initState() {
    super.initState();
    _availableWeeks = _getAvailableWeeks();
    final thisWeek = _getStartOfWeek(_normalizeDate(DateTime.now()));
    _currentIndex = _availableWeeks.indexOf(thisWeek);
    if (_currentIndex == -1) _currentIndex = 0;

    _pageController = PageController(initialPage: _currentIndex);
    _weekScrollController = ScrollController();
    
    _processDataForCurrentWeek();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_weekScrollController.hasClients) {
        _weekScrollController.jumpTo(_weekScrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void didUpdateWidget(covariant AnalyzeView oldWidget) {
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
        _processDataForCurrentWeek();
      });
    } else {
      _processDataForCurrentWeek();
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

  void _processDataForCurrentWeek() {
    if (_availableWeeks.isEmpty) return;
    
    final currentWeekStart = _availableWeeks[_currentIndex];
    
    // Create exactly 7 days for the selected week
    _dates = List.generate(7, (index) => currentWeekStart.add(Duration(days: index)));
    
    _dayTotals = {};
    _dayActivities = {};
    _activityColors = {};
    _weeklyActivityTotals = {};
    _maxDayTotal = 0;

    for (var date in _dates) {
      int dailyTotal = 0;
      Map<String, int> dailyActs = {};

      for (var activity in widget.activities) {
        final start = activity.starttime.toLocal();
        final end = activity.endtime.toLocal();

        DateTime dayStart = date;
        DateTime dayEnd = dayStart.add(const Duration(days: 1));

        if (end.isBefore(dayStart) || start.isAfter(dayEnd) || start.isAtSameMomentAs(dayEnd)) {
          continue;
        }

        DateTime effectiveStart = start.isBefore(dayStart) ? dayStart : start;
        DateTime effectiveEnd = end.isAfter(dayEnd) ? dayEnd : end;

        final durationSeconds = effectiveEnd.difference(effectiveStart).inSeconds;
        if (durationSeconds > 0) {
          dailyTotal += durationSeconds;
          dailyActs[activity.activity] = (dailyActs[activity.activity] ?? 0) + durationSeconds;
          _activityColors[activity.activity] = activity.color;
          _weeklyActivityTotals[activity.activity] = (_weeklyActivityTotals[activity.activity] ?? 0) + durationSeconds;
        }
      }

      _dayTotals[date] = dailyTotal;
      _dayActivities[date] = dailyActs;
      if (dailyTotal > _maxDayTotal) {
        _maxDayTotal = dailyTotal;
      }
    }
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

  Color _colorFromHex(String hexColor) {
    String formatted = hexColor.replaceAll('#', '').toUpperCase();
    if (formatted.length == 6) {
      formatted = 'FF$formatted';
    }
    return Color(int.parse(formatted, radix: 16));
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String _formatDateShort(DateTime date) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[date.weekday - 1]}\n${date.day}';
  }

  Widget _buildLegend() {
    if (_activityColors.isEmpty) return const SizedBox.shrink();
    
    final int totalWeeklySeconds = _weeklyActivityTotals.values.fold(0, (sum, val) => sum + val);

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: _activityColors.entries.map((entry) {
        final activityTotal = _weeklyActivityTotals[entry.key] ?? 0;
        final double percent = totalWeeklySeconds > 0 ? (activityTotal / totalWeeklySeconds) * 100 : 0;
        final percentString = '${percent.toStringAsFixed(1)}%';

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _colorFromHex(entry.value),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${entry.key} ($percentString)',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_availableWeeks.isEmpty) {
      return const Center(child: Text("No data to analyze."));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      setState(() {
                        _currentIndex = index;
                        _processDataForCurrentWeek();
                      });
                    }
                  },
                ),
              );
            },
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Pie Chart
                  Text(
                    'Weekly Breakdown',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  if (_weeklyActivityTotals.isNotEmpty)
                    PieChartView(
                      data: _weeklyActivityTotals,
                      colors: _activityColors,
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: Text("No activities for this week"),
                    ),
                    
                  const SizedBox(height: 24),
                  
                  // Legend
                  _buildLegend(),
                  
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Stacked Bar Chart Title
                  Text(
                    'Daily Volume',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Stacked Bar Chart
                  SizedBox(
                    height: 220, // specific height for the chart to ensure layout fits correctly
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _dates.length,
                      itemBuilder: (context, index) {
                        final date = _dates[index];
                        final totalSeconds = _dayTotals[date] ?? 0;
                        final acts = _dayActivities[date] ?? {};

                        // Calculate bar height relative to max day
                        double barHeight = 0;
                        if (_maxDayTotal > 0) {
                          barHeight = (totalSeconds / _maxDayTotal) * 150; // max 150px
                        }

                        // Sort activities within the bar (largest at bottom)
                        final sortedActEntries = acts.entries.toList()
                          ..sort((a, b) => b.value.compareTo(a.value));

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Total time above bar
                              if (totalSeconds > 0)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Text(
                                    _formatDuration(totalSeconds),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),

                              // The stacked bar
                              Container(
                                width: 36,
                                height: barHeight == 0 ? 1 : barHeight, // show a tiny line if 0? No, just space
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: Colors.grey.withValues(alpha: 0.1),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: totalSeconds == 0
                                    ? const SizedBox.shrink()
                                    : Column(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: sortedActEntries.map((entry) {
                                          final flex = entry.value;
                                          final colorHex = _activityColors[entry.key] ?? '000000';
                                          return Flexible(
                                            flex: flex,
                                            child: Tooltip(
                                              message: '${entry.key}: ${_formatDuration(entry.value)}',
                                              child: Container(
                                                color: _colorFromHex(colorHex),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                              ),

                              // X-axis label
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 32,
                                child: Text(
                                  _formatDateShort(date),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
