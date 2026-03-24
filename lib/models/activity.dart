class Activity {
  final int seconds;
  final String activity;
  final String username;
  final DateTime starttime;
  final DateTime endtime;
  final String color;

  Activity({
    required this.seconds,
    required this.activity,
    required this.username,
    required this.starttime,
    required this.endtime,
    required this.color,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      seconds: json['seconds'] as int,
      activity: json['activity'] as String,
      username: json['username'] as String,
      starttime: DateTime.parse(json['starttime'] as String),
      endtime: DateTime.parse(json['endtime'] as String),
      color: json['color'] as String,
    );
  }
}
