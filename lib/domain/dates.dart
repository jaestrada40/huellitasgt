import 'enums.dart';

/// Día calendario sin hora ni zona: medianoche UTC con el año/mes/día
/// recibidos. Si la fecha viene de la base de datos, convertirla antes con
/// `.toUtc()` (ver data/mappers.dart).
DateTime dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);

DateTime addInterval(DateTime from, int value, IntervalUnit unit) {
  final d = dateOnly(from);
  return switch (unit) {
    IntervalUnit.days => DateTime.utc(d.year, d.month, d.day + value),
    IntervalUnit.weeks => DateTime.utc(d.year, d.month, d.day + 7 * value),
    IntervalUnit.months => _addMonths(d, value),
    IntervalUnit.years => _addMonths(d, 12 * value),
  };
}

DateTime _addMonths(DateTime d, int months) {
  final index = d.year * 12 + (d.month - 1) + months;
  final year = index ~/ 12;
  final month = index % 12 + 1;
  final lastDay = DateTime.utc(year, month + 1, 0).day;
  return DateTime.utc(year, month, d.day > lastDay ? lastDay : d.day);
}

/// Días desde [today] hasta [due]; negativo si ya pasó.
int daysUntil(DateTime due, DateTime today) =>
    dateOnly(due).difference(dateOnly(today)).inDays;
