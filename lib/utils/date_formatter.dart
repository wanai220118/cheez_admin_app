import 'package:intl/intl.dart';

class DateFormatter {
  // Format date as "dd MMM yyyy" (e.g., "15 Jan 2024")
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  // Format date as "dd/MM/yyyy" (e.g., "15/01/2024")
  static String formatDateShort(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Format date with time "dd MMM yyyy, HH:mm" (e.g., "15 Jan 2024, 14:30")
  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  // Format date as "EEEE, dd MMM yyyy" (e.g., "Monday, 15 Jan 2024")
  static String formatDateWithDay(DateTime date) {
    return DateFormat('EEEE, dd MMM yyyy').format(date);
  }

  // Format time only "HH:mm" (e.g., "14:30")
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  // Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  // Get relative date string (Today, Yesterday, or formatted date)
  static String getRelativeDate(DateTime date) {
    if (isToday(date)) {
      return 'Today';
    } else if (isYesterday(date)) {
      return 'Yesterday';
    } else {
      return formatDate(date);
    }
  }
}

