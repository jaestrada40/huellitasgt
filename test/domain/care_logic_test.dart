import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/domain/care_logic.dart';
import 'package:huellitas/domain/enums.dart';
import 'package:huellitas/domain/models.dart';

Pet pet({DateTime? birth, DateTime? adopted, DateTime? memorial, bool archived = false}) => Pet(
      id: 'p1',
      name: 'Koko',
      species: PetSpecies.dog,
      createdAt: DateTime(2024),
      birthDate: birth,
      adoptionDate: adopted,
      memorialDate: memorial,
      archived: archived,
    );

void main() {
  final now = DateTime(2026, 10, 20, 8);

  test('rutina: nunca hecha o vencida toca; reciente no', () {
    Routine r(DateTime? last) => Routine(id: 'r', petId: 'p1', name: 'Baño', everyDays: 15, lastDoneAt: last);
    expect(routineIsDue(r(null), now), true);
    expect(routineIsDue(r(DateTime(2026, 10, 10)), now), false);
    expect(routineIsDue(r(DateTime(2026, 10, 5)), now), true);
    expect(daysSinceDone(r(DateTime(2026, 10, 10, 23)), now), 10);
  });

  test('comida: 15 kg a 300 g/día dura 50 días', () {
    final f = FoodStock(id: 'f', petId: 'p1', brand: 'X', bagKg: 15, gramsPerDay: 300, openedOn: DateTime.utc(2026, 10, 1));
    expect(foodRunsOutOn(f), DateTime.utc(2026, 11, 20));
    expect(foodDaysLeft(f, now), 31);
  });

  test('gastos: total del mes y por categoría', () {
    final es = [
      Expense(id: '1', petId: 'p', date: DateTime.utc(2026, 10, 3), amount: 150, category: ExpenseCategory.vet),
      Expense(id: '2', petId: 'p', date: DateTime.utc(2026, 10, 9), amount: 50.5, category: ExpenseCategory.food),
      Expense(id: '3', petId: 'p', date: DateTime.utc(2026, 9, 30), amount: 99, category: ExpenseCategory.vet),
    ];
    expect(monthTotal(es, 2026, 10), 200.5);
    expect(totalsByCategory(es)[ExpenseCategory.vet], 249);
    expect(money(200.5), 'Q 200.50');
  });

  test('cumpleaños: próximo aniversario con los años cumplidos', () {
    final a = nextAnniversary(DateTime.utc(2020, 11, 5), now, 9, 0)!;
    expect((a.at, a.years), (DateTime(2026, 11, 5, 9), 6));
    final b = nextAnniversary(DateTime.utc(2020, 10, 20), now, 9, 0)!; // hoy a las 9, aún no pasa
    expect((b.at, b.years), (DateTime(2026, 10, 20, 9), 6));
    final c = nextAnniversary(DateTime.utc(2020, 10, 20), DateTime(2026, 10, 20, 10), 9, 0)!;
    expect(c.at, DateTime(2027, 10, 20, 9));
  });

  test('29 de febrero cae el 28 en año no bisiesto; fecha de este año no avisa', () {
    final a = nextAnniversary(DateTime.utc(2020, 2, 29), now, 9, 0)!;
    expect(a.at, DateTime(2027, 2, 28, 9));
    expect(nextAnniversary(DateTime.utc(2026, 12, 1), now, 9, 0)!.years, 1); // cumple 1 año el 2027
  });

  test('avisos de fechas: cumpleaños y llegada a casa; no para en memoria ni archivadas', () {
    final p = pet(birth: DateTime.utc(2020, 11, 5), adopted: DateTime.utc(2021, 12, 1));
    final plan = planDateReminders(pets: [p], foods: const [], now: now);
    expect(plan.map((r) => r.title), ['¡Cumpleaños de Koko!', 'Koko llegó a casa']);
    expect(plan.first.body, 'Hoy cumple 6 años');
    expect(planDateReminders(pets: [pet(birth: DateTime.utc(2020, 11, 5), memorial: DateTime.utc(2026, 1, 1))], foods: const [], now: now), isEmpty);
    expect(planDateReminders(pets: [pet(birth: DateTime.utc(2020, 11, 5), archived: true)], foods: const [], now: now), isEmpty);
  });

  test('aviso de comida 5 días antes de que se acabe', () {
    final f = FoodStock(id: 'f', petId: 'p1', brand: 'Pro Plan', bagKg: 15, gramsPerDay: 300, openedOn: DateTime.utc(2026, 10, 1));
    final plan = planDateReminders(pets: [pet()], foods: [f], now: now);
    expect(plan.single.fireAt, DateTime(2026, 11, 15, 9));
    expect(plan.single.body, 'La bolsa de Pro Plan se acaba en 5 días');
  });
}
