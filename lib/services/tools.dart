


import 'package:intl/intl.dart';

String parseDate(dynamic timestamp){
   var dateTime = DateTime.fromMillisecondsSinceEpoch(int.tryParse(timestamp) ?? DateTime.timestamp().millisecond);

  // check if 1 day or less
  if (DateTime.now().difference(dateTime).inDays < 1) {
    return DateFormat.jm().format(dateTime);
    // check if within the last 7 days
  } else if (DateTime.now().difference(dateTime).inDays < 7) {
    // format thu 12:00 PM
    return DateFormat('E, h:mm a').format(dateTime);
    // check if within this year
  } else if (DateTime.now().year == dateTime.year) {
    return DateFormat('MMM d').format(dateTime);
  } else {
    return DateFormat('MMM d, y').format(dateTime);
  }

}