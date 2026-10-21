import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import '../domain/enums.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  Pets,
  WeightEntries,
  Treatments,
  HealthEvents,
  Attachments,
  Medications,
  DoseLogs,
  Routines,
  FoodStocks,
  Expenses,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.memory() : super(NativeDatabase.memory());

  AppDatabase.file(File file) : super(NativeDatabase.createInBackground(file));

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(pets, pets.photoFocusX);
            await m.addColumn(pets, pets.photoFocusY);
          }
          if (from < 3) {
            await m.addColumn(pets, pets.photoZoom);
          }
          if (from < 4) {
            await m.addColumn(pets, pets.adoptionDate);
            await m.addColumn(pets, pets.memorialDate);
            await m.createTable(medications);
            await m.createTable(doseLogs);
            await m.createTable(routines);
            await m.createTable(foodStocks);
            await m.createTable(expenses);
          }
        },
      );
}
