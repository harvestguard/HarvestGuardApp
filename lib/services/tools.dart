


import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

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

Future<Map<String, Object?>> getAddress(int region, int province, int city, int barangay) async {
    Database db = await openDatabase('address.db', readOnly: true);

    print('region: $region, province: $province, city: $city, barangay: $barangay');
    

    var regionData = await db.query('refRegion',
        where: '(regCode = ?)', whereArgs: [region]);
    var provinceData = await db.query('refProvince',
        where: '(provCode = ?)', whereArgs: [province]);
    var cityData = await db.query('refCitymun',
        where: '(citymunCode = ?)', whereArgs: [city]);
    var barangayData = await db.query('refBarangay',
        where: '(brgyCode = ?)', whereArgs: [barangay]);

    return {
      'region': regionData[0]['regDesc'],
      'province': provinceData[0]['provDesc'],
      'city': cityData[0]['citymunDesc'],
      'barangay': barangayData[0]['brgyDesc']
    };
  }


