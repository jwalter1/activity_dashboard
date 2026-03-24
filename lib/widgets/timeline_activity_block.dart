import 'package:flutter/material.dart';
import '../models/activity.dart';

class TimelineActivityBlock extends StatelessWidget {
  final Activity activity;
  final double height;
  final double topOffset;

  const TimelineActivityBlock({
    super.key,
    required this.activity,
    required this.height,
    required this.topOffset,
  });

  Color _colorFromHex(String hexColor) {
    String formatted = hexColor.replaceAll('#', '').toUpperCase();
    if (formatted.length == 6) {
      formatted = 'FF$formatted';
    }
    return Color(int.parse(formatted, radix: 16));
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
    final color = _colorFromHex(activity.color);
    
    return Positioned(
      top: topOffset,
      left: 1, // Tigher margin for weekly view
      right: 1,
      height: height,
      child: Tooltip(
        message: '${activity.activity}\n${_formatTime(activity.starttime)} - ${_formatTime(activity.endtime)}',
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.25),
            border: Border(
              left: BorderSide(color: color, width: 3),
            ),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(4),
              bottomRight: Radius.circular(4),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  activity.activity,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: color.withValues(alpha: 0.95),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (height > 30) // Only show time if the block is tall enough
                  Text(
                    _formatTime(activity.starttime),
                    style: TextStyle(
                      fontSize: 8,
                      color: color.withValues(alpha: 0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
