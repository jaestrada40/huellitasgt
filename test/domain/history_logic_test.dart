import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/domain/enums.dart';
import 'package:huellitas/domain/history_logic.dart';

import '../helpers/samples.dart';

void main() {
  final a = sampleEvent(id: 'a', title: 'Antirrábica', occurredAt: DateTime(2024, 10, 15));
  final b = sampleEvent(id: 'b', type: EventType.deworming, title: 'Desparasitación interna', occurredAt: DateTime(2024, 8, 10));
  final c = sampleEvent(id: 'c', type: EventType.checkup, title: 'Consulta dental', occurredAt: DateTime(2024, 8, 2), notes: 'Sarro leve');
  final all = [a, b, c];

  group('filterEvents', () {
    test('sin filtros devuelve todo', () {
      expect(filterEvents(all).length, 3);
    });
    test('por tipo', () {
      expect(filterEvents(all, type: EventType.deworming).map((e) => e.id), ['b']);
    });
    test('búsqueda sin acentos ni mayúsculas', () {
      expect(filterEvents(all, query: 'DESPARASITACION').map((e) => e.id), ['b']);
      expect(filterEvents(all, query: 'sarro').map((e) => e.id), ['c']);
    });
    test('busca también en veterinario y clínica', () {
      expect(filterEvents(all, query: 'narvarte').length, 3); // sampleEvent usa Vet Narvarte
    });
    test('combina tipo y búsqueda; sin coincidencias devuelve vacío', () {
      expect(filterEvents(all, type: EventType.vaccine, query: 'dental'), isEmpty);
    });
  });

  test('groupByMonth agrupa y ordena del más reciente al más antiguo', () {
    final groups = groupByMonth([c, a, b]);
    expect(groups.map((g) => (g.year, g.month)), [(2024, 10), (2024, 8)]);
    expect(groups.last.events.map((e) => e.id), ['b', 'c']);
  });

  test('groupByMonth separa el mismo mes de años distintos', () {
    final old = sampleEvent(id: 'o', occurredAt: DateTime(2023, 10, 15));
    expect(groupByMonth([a, old]).length, 2);
  });
}
