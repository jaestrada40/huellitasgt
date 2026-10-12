import 'dates.dart';

String ageLabel(DateTime birth, DateTime today) {
  final b = dateOnly(birth);
  final t = dateOnly(today);
  var months = (t.year - b.year) * 12 + (t.month - b.month);
  if (t.day < b.day) months -= 1;
  if (months < 0) months = 0;
  final y = months ~/ 12;
  final m = months % 12;
  if (y == 0) return '${m}m';
  if (m == 0) return '${y}a';
  return '${y}a ${m}m';
}
