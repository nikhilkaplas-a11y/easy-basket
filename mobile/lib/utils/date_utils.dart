import 'package:intl/intl.dart';

/// Converts a DateTime to IST (Indian Standard Time, UTC+5:30)
/// Assumes the input DateTime is in UTC (as stored in database)
DateTime toIST(DateTime dateTime) {
  // IST is UTC+5:30
  // If dateTime is already in UTC (which it should be from backend), add the offset
  // If dateTime is in local time, we need to convert to UTC first
  if (dateTime.isUtc) {
    return dateTime.add(const Duration(hours: 5, minutes: 30));
  } else {
    // Convert local time to UTC first, then add IST offset
    final utcTime = dateTime.toUtc();
    return utcTime.add(const Duration(hours: 5, minutes: 30));
  }
}

/// Formats a DateTime to IST timezone with the given format
String formatIST(DateTime dateTime, String format) {
  final istDateTime = toIST(dateTime);
  return DateFormat(format).format(istDateTime);
}

/// Formats a DateTime to IST with default format: 'MMM dd, yyyy hh:mm a'
String formatISTDefault(DateTime dateTime) {
  return formatIST(dateTime, 'MMM dd, yyyy hh:mm a');
}

/// Formats a DateTime to IST with short format: 'MMM dd, hh:mm a'
String formatISTShort(DateTime dateTime) {
  return formatIST(dateTime, 'MMM dd, hh:mm a');
}

