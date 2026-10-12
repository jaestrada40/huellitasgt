import 'dates.dart';
import 'models.dart';

class WeightTrend {
  const WeightTrend(this.current, this.deltaVsMonthAgo);
  final double current;
  final double? deltaVsMonthAgo;
}

WeightTrend? weightTrend(List<WeightEntry> entries, DateTime today) {
  if (entries.isEmpty) return null;
  final sorted = [...entries]..sort((a, b) => b.date.compareTo(a.date));
  final latest = sorted.first;
  final cutoff = dateOnly(today).subtract(const Duration(days: 30));
  WeightEntry? reference;
  for (final e in sorted.skip(1)) {
    if (!e.date.isAfter(cutoff)) {
      reference = e;
      break;
    }
  }
  final delta =
      reference == null ? null : double.parse((latest.kg - reference.kg).toStringAsFixed(1));
  return WeightTrend(latest.kg, delta);
}
