import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../services/api_service.dart';
import '../widgets/timeline_view.dart';
import '../widgets/analyze_view.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<Activity>> _activitiesFuture;
  final ApiService _apiService = ApiService();
  bool _showTimeline = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _activitiesFuture = _apiService.fetchActivities();
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

  String _formatTime(DateTime time) {
    final localTime = time.toLocal();
    final hour = localTime.hour == 0 ? 12 : (localTime.hour > 12 ? localTime.hour - 12 : localTime.hour);
    final minute = localTime.minute.toString().padLeft(2, '0');
    final ampm = localTime.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Dashboard'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_selectedIndex == 0) // Only show timeline toggle on the dashboard tab
            IconButton(
              icon: Icon(_showTimeline ? Icons.list : Icons.calendar_today),
              onPressed: () {
                setState(() {
                  _showTimeline = !_showTimeline;
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _activitiesFuture = _apiService.fetchActivities();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Activity>>(
        future: _activitiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('Error: ${snapshot.error}', textAlign: TextAlign.center,),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No activities found.'));
          }

          final activities = snapshot.data!;
          
          if (_selectedIndex == 1) {
            return AnalyzeView(activities: activities);
          }

          if (_showTimeline) {
            return TimelineView(activities: activities);
          }
          
          final List<dynamic> listItems = [];
          String? currentDayString;

          for (var activity in activities) {
            final localStart = activity.starttime.toLocal();
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final yesterday = today.subtract(const Duration(days: 1));
            final activityDate = DateTime(localStart.year, localStart.month, localStart.day);

            String dayString;
            if (activityDate == today) {
              dayString = 'Today';
            } else if (activityDate == yesterday) {
              dayString = 'Yesterday';
            } else {
              final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
              dayString = '${months[localStart.month - 1]} ${localStart.day}, ${localStart.year}';
            }

            if (currentDayString != dayString) {
              listItems.add(dayString);
              currentDayString = dayString;
            }
            listItems.add(activity);
          }
          
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: listItems.length,
            itemBuilder: (context, index) {
              final item = listItems[index];
              
              if (item is String) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 4.0, left: 4.0),
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                );
              }
              
              final activity = item as Activity;
              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 2),
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Container(
                  height: 34,
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: _colorFromHex(activity.color),
                        width: 4,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          activity.activity,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_formatTime(activity.starttime)} - ${_formatTime(activity.endtime)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _colorFromHex(activity.color).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _formatDuration(activity.seconds),
                          style: TextStyle(
                            color: _colorFromHex(activity.color),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analyze',
          ),
        ],
      ),
    );
  }
}
