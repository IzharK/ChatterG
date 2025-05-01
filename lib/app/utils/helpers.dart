import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Helpers {
  // Formats Timestamp to a readable string (e.g., "10:30 AM" or "Yesterday" or "Mar 15")
  static String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final DateTime messageTime = timestamp.toDate();
    final DateTime now = DateTime.now();
    final DateTime startOfToday = DateTime(now.year, now.month, now.day);
    final DateTime startOfYesterday = DateTime(
      now.year,
      now.month,
      now.day - 1,
    );

    if (messageTime.isAfter(startOfToday)) {
      // Today: Show time
      return DateFormat.jm().format(messageTime); // e.g., 10:30 AM
    } else if (messageTime.isAfter(startOfYesterday)) {
      // Yesterday: Show "Yesterday"
      return 'Yesterday';
    } else {
      // Older: Show date (e.g., Mar 15)
      return DateFormat('MMM d').format(messageTime);
    }
  }
}
