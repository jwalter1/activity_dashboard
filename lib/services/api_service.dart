import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/activity.dart';

class ApiService {
  static const String _url = 'https://ovl6c4vyhkevvd5fyn2g7hx6u40rnxda.lambda-url.us-east-1.on.aws/';

  Future<List<Activity>> fetchActivities() async {
    final response = await http.get(Uri.parse(_url));
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List<dynamic> items = decoded['Items'];
      
      // Map to Activity items and sort by starttime descending
      final activities = items.map((json) => Activity.fromJson(json)).toList();
      activities.sort((a, b) => b.starttime.compareTo(a.starttime));
      return activities;
    } else {
      throw Exception('Failed to load activities: ${response.statusCode}');
    }
  }
}
