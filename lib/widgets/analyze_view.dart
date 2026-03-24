import 'package:flutter/material.dart';
import '../models/activity.dart';

class AnalyzeView extends StatefulWidget {
  final List<Activity> activities;

  const AnalyzeView({super.key, required this.activities});

  @override
  State<AnalyzeView> createState() => _AnalyzeViewState();
}

class _AnalyzeViewState extends State<AnalyzeView> {
  List<DateTime> _dates = [];
  Map<DateTime, int> _dayTotals = {};
  Map<DateTime, Map<String, int>> _dayActivities = {};
  Map<String, String> _activityColors = {};
  int _maxDayTotal = 0;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _processData();
    _scrollController = ScrollController();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AnalyzeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _processData();
  }

  void _processData() {
    final Set<DateTime> availableDates = {};
    for (var a in widget.activities) {
      availableDates.add(_normalizeDate(a.starttime.toLocal()));
      availableDates.add(_normalizeDate(a.endtime.toLocal()));
    }
    
    // If no data, ensure we at least have today
    if (availableDates.isEmpty) {
      availableDates.add(_normalizeDate(DateTime.now()));
    }

    _dates = availableDates.toList()..sort();
    
    _dayTotals = {};
    _dayActivities = {};
    _activityColors = {};
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
        }
      }

      _dayTotals[date] = dailyTotal;
      _dayActivities[date] = dailyActs;
      if (dailyTotal > _maxDayTotal) {
        _maxDayTotal = dailyTotal;
      }
    }
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
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
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]}\n${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    if (_dates.isEmpty) {
      return const Center(child: Text("No data to analyze."));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0, top: 8.0),
            child: Text(
              'Activity Volume',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Leave enough room for the top text label, bottom spacing, and X-axis labels
                final double chartHeight = constraints.maxHeight - 70; 

                return ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: _dates.length,
                  itemBuilder: (context, index) {
                    final date = _dates[index];
                    final totalSeconds = _dayTotals[date] ?? 0;
                    final acts = _dayActivities[date] ?? {};

                    // Calculate bar height relative to max day
                    double barHeight = 0;
                    if (_maxDayTotal > 0) {
                      barHeight = (totalSeconds / _maxDayTotal) * chartHeight;
                    }

                    // Sort activities within the bar (largest at bottom)
                    final sortedActEntries = acts.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value));

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Formatting the total time above the bar
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
                            width: 40,
                            height: barHeight,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.grey.withValues(alpha: 0.1),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
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
                );
              },
            ),
          ),
          
          // Legend
          if (_activityColors.isNotEmpty) ...[
            const Divider(height: 32),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _activityColors.entries.map((entry) {
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
                      entry.key,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                );
              }).toList(),
            ),
          ]
        ],
      ),
    );
  }
}
