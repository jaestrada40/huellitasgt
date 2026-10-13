import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import '../domain/enums.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Pets, WeightEntries, Treatments, HealthEvents, Attachments])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.memory() : super(NativeDatabase.memory());

  AppDatabase.file(File file) : super(NativeDatabase.createInBackground(file));

  @override
  int get schemaVersion => 3;

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
        },
      );
}
