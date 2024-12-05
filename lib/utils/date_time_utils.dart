  DateTime parseDate(DateTime dt) {
    return dt.toUtc();
    }

  int getDayDifference(DateTime dt){
    DateTime today = DateTime.now();
    return today.difference(dt).inDays;
  }