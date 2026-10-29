import 'dart:ui';

import 'holidays_sg.dart';

abstract interface class HolidayProvider {
  bool isPublicHoliday(DateTime localDate);
}

class NoHolidays implements HolidayProvider {
  const NoHolidays();

  @override
  bool isPublicHoliday(DateTime localDate) => false;
}

class DateListHolidays implements HolidayProvider {
  DateListHolidays(Iterable<String> isoDates) : _dates = isoDates.toSet();

  final Set<String> _dates;

  @override
  bool isPublicHoliday(DateTime localDate) => _dates.contains(isoDate(localDate));
}

String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

final HolidayProvider singapore = DateListHolidays([
  for (final (date, _) in singaporeHolidays) date,
]);

HolidayProvider holidaysForRegion(String? countryCode) =>
    countryCode?.toUpperCase() == 'SG' ? singapore : const NoHolidays();

HolidayProvider holidaysForPhone() =>
    holidaysForRegion(PlatformDispatcher.instance.locale.countryCode);
