/* Copyright (c) 2017 Miguel Castiblanco */
String twoDigits(int n) {
  if (n >= 10) return "${n}";
  return "0${n}";
}

String sxxepxx(int season, int episode) {
  return "S${twoDigits(season)}E${twoDigits(episode)}";
}

String capitalize(String text) {
  return text[0].toUpperCase() + text.substring(1);
}

String dayOfWeek(int day) {
  switch (day) {
    case DateTime.MONDAY:
      return "Monday";
    case DateTime.TUESDAY:
      return "Tuesday";
    case DateTime.WEDNESDAY:
      return "Wednesday";
    case DateTime.THURSDAY:
      return "Thursday";
    case DateTime.FRIDAY:
      return "Friday";
    case DateTime.SATURDAY:
      return "Saturday";
    case DateTime.SUNDAY:
      return "Sunday";
  }

  return "";
}

DateTime getTodayLocal() => new DateTime.now();

DateTime getTodayUtc() => getTodayLocal().toUtc();

DateTime getTomorrowLocal() {
  var tomorrow = getTodayLocal().add(new Duration(days: 1));
  return new DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
}

DateTime getTomorrowUtc() => getTomorrowLocal().toUtc();

bool isSameDay(DateTime a, DateTime b) {
  if (a == b) return true;
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
