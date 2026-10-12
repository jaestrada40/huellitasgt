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
  int get schemaVersion => 1;
}
