import 'dates.dart';
import 'enums.dart';
import 'models.dart';
import 'reminder_plan.dart';

// ---- Rutinas ----

/// Días desde la última vez, o `null` si nunca se ha hecho.
int? daysSinceDone(Routine r, DateTime now) =>
    r.lastDoneAt == null ? null : daysUntil(now, r.lastDoneAt!);

/// Toca si nunca se hizo o ya pasaron [Routine.everyDays] días.
bool routineIsDue(Routine r, DateTime now) {
  final d = daysSinceDone(r, now);
  return d == null || d >= r.everyDays;
}

// ---- Comida ----

/// Día en que se acaba la bolsa si se sirve [FoodStock.gramsPerDay] cada día.
DateTime foodRunsOutOn(FoodStock f) =>
    addInterval(f.openedOn, (f.bagKg * 1000 / f.gramsPerDay).floor(), IntervalUnit.days);

int foodDaysLeft(FoodStock f, DateTime today) => daysUntil(foodRunsOutOn(f), today);

const int foodReminderDaysBefore = 5;

// ---- Gastos ----

double monthTotal(Iterable<Expense> expenses, int year, int month) => expenses
    .where((e) => e.date.year == year && e.date.month == month)
    .fold(0.0, (a, e) => a + e.amount);

Map<ExpenseCategory, double> totalsByCategory(Iterable<Expense> expenses) {
  final out = <ExpenseCategory, double>{};
  for (final e in expenses) {
    out[e.category] = (out[e.category] ?? 0) + e.amount;
  }
  return out;
}

/// Moneda fija: la app se usa en Guatemala. Pasar a una preferencia si se publica fuera.
String money(double v) => 'Q ${v.toStringAsFixed(2)}';

// ---- Avisos de fechas (cumpleaños, llegada a casa, comida) ----

DateTime _anniversary(DateTime base, int year) {
  final lastDay = DateTime.utc(year, base.month + 1, 0).day;
  return DateTime(year, base.month, base.day > lastDay ? lastDay : base.day);
}

/// Próximo aniversario de [base] a la hora dada, estrictamente después de [now],
/// con los años cumplidos. `null` si [base] es futura.
({DateTime at, int years})? nextAnniversary(DateTime base, DateTime now, int hour, int minute) {
  for (var y = now.year; y <= now.year + 1; y++) {
    final d = _anniversary(base, y);
    final at = DateTime(d.year, d.month, d.day, hour, minute);
    if (y - base.year >= 1 && at.isAfter(now)) return (at: at, years: y - base.year);
  }
  return null;
}

String _years(int n) => '$n ${n == 1 ? 'año' : 'años'}';

List<PlannedReminder> planDateReminders({
  required Iterable<Pet> pets,
  required Iterable<FoodStock> foods,
  required DateTime now,
  int hour = 9,
  int minute = 0,
}) {
  final out = <PlannedReminder>[];
  final live = {for (final p in pets) if (!p.archived && !p.inMemoriam) p.id: p};

  for (final p in live.values) {
    final b = p.birthDate == null ? null : nextAnniversary(p.birthDate!, now, hour, minute);
    if (b != null) {
      out.add(PlannedReminder(
        id: stableId('birth:${p.id}'),
        treatmentId: p.id,
        fireAt: b.at,
        title: '¡Cumpleaños de ${p.name}!',
        body: 'Hoy cumple ${_years(b.years)}',
      ));
    }
    final a = p.adoptionDate == null ? null : nextAnniversary(p.adoptionDate!, now, hour, minute);
    if (a != null) {
      out.add(PlannedReminder(
        id: stableId('adopt:${p.id}'),
        treatmentId: p.id,
        fireAt: a.at,
        title: '${p.name} llegó a casa',
        body: 'Hoy hace ${_years(a.years)} que llegó a tu vida',
      ));
    }
  }

  for (final f in foods) {
    final pet = live[f.petId];
    if (pet == null) continue;
    final runsOut = foodRunsOutOn(f);
    DateTime at(DateTime d) => DateTime(d.year, d.month, d.day, hour, minute);
    final early = at(DateTime.utc(runsOut.year, runsOut.month, runsOut.day - foodReminderDaysBefore));
    final fireAt = early.isAfter(now) ? early : at(runsOut);
    if (!fireAt.isAfter(now)) continue;
    final left = daysUntil(runsOut, fireAt);
    out.add(PlannedReminder(
      id: stableId('food:${f.id}'),
      treatmentId: f.id,
      fireAt: fireAt,
      title: 'Comida de ${pet.name}',
      body: left <= 0
          ? 'Hoy se acaba la bolsa de ${f.brand}'
          : 'La bolsa de ${f.brand} se acaba en $left ${left == 1 ? 'día' : 'días'}',
    ));
  }
  return out;
}
