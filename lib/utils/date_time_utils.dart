import 'package:intl/intl.dart';

  DateTime parseDate(DateTime dt) {
    if(dt==null){
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    else{
      return dt.toUtc();
    }
  }

  int getDayDifference(DateTime dt){
    DateTime today = DateTime.now();
    return today.difference(dt).inDays;
  }