# Huellitas Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Construir Huellitas, una app Flutter (iPhone y Android) 100% local que recuerda vacunas, desparasitación y antipulgas de las mascotas y guarda su historial de salud.

**Architecture:** Capas: UI (Flutter + Riverpod + go_router) → dominio puro (fechas, estados, servicios) → repositorios (interfaces) → implementación local con Drift/SQLite y archivos. Recordatorios con notificaciones locales; respaldo manual en `.zip`. Sin servidor ni cuentas.

**Tech Stack:** Flutter, Dart, drift (SQLite), flutter_riverpod, go_router, flutter_local_notifications, image_picker + flutter_image_compress, archive, share_plus, file_picker, local_auth, flutter_secure_storage, pdf, intl, google_fonts.

**Spec:** `docs/superpowers/specs/2026-10-11-huellitas-design.md` (leerla antes de empezar). Diseño visual: proyecto de Stitch «Huellitas Pet Health Tracker» (id `15285772595589445161`), pantallas descartadas: «Iniciar Sesión» y «Compartir con Familia».

> **Advertencia de verificación:** este plan se escribió **sin Flutter instalado**, así que el código no se ejecutó. Las APIs de los paquetes cambian entre versiones (se marcan con **[API]** donde más suele pasar). Cada tarea termina con `flutter analyze` y pruebas: si el analizador reporta una diferencia de API, consulta el README del paquete instalado y ajusta **sin cambiar el comportamiento que la prueba exige**. Nunca fijes versiones de memoria: `flutter pub add` toma las vigentes.

## Global Constraints

- Plataformas: iPhone y Android desde una sola base de código Flutter. Textos de la app en español (México). Nombre: **Huellitas**.
- 100% local: sin servidor, sin nube, sin login ni cuentas, sin WhatsApp. Bloqueo opcional con Face ID/huella/PIN.
- Fuera de la primera versión: compartir en vivo, sincronizar, póliza de seguro, Apple Wallet, QR, sello/folio, y cualquier texto de validez «oficial» (SAGARPA/SENASICA, aerolíneas).
- Fechas de vencimiento y de nacimiento se guardan como **día calendario** (medianoche UTC con el año/mes/día del usuario); al leer de la base de datos se convierten con `.toUtc()`.
- Estados: atrasada si `nextDueDate < hoy`; «Vence en N días» si faltan 7 o menos; «Próxima» si faltan más. `% al día` = tratamientos activos no atrasados / tratamientos activos.
- Sumar meses/años ajusta fin de mes (31 ene + 1 mes = 28/29 feb). La frecuencia se cuenta desde la fecha de aplicación.
- iOS permite 64 notificaciones pendientes: se programa **solo el siguiente vencimiento** por tratamiento (máximo 60) y se reprograma al abrir la app y al cambiar datos. Por defecto 9:00 a. m. y 3 días antes.
- Respaldo: `huellitas-AAAA-MM-DD.zip` con `backup.json` (con `schemaVersion`) y carpeta `attachments/`. Importar **reemplaza todo** de forma atómica tras confirmar.
- Fotos comprimidas antes de guardarlas. Archivos en el teléfono; la base guarda rutas **relativas** (`attachments/<id>.jpg`).
- Paleta: canvas `#FBF9F5`, tarjetas `#FFFFFF`, primario `#2BA38B`, naranja `#FF9F5A`, coral `#FF5A5F`, texto `#1D2A29`, secundario `#6E7C7A`, divisor `#EAE6DE`. Fuente Plus Jakarta Sans. Pestañas: Inicio, Historial, Mascotas, Ajustes.
- Tipos de evento: `vaccine`, `deworming`, `fleaTick`, `illness`, `checkup`. Solo los tres primeros pueden tener tratamiento recurrente.

## Review Focus

Entradas que el spec implica pero no detalla, ordenadas por probabilidad de fallar. Cada una tiene su prueba en la tarea indicada.

1. **Teléfono en México (UTC-6) o en zona con horario de verano:** una fecha de vencimiento no debe moverse un día al guardarse y leerse, y el aviso debe salir a las 9:00 locales. → Task 3 (`TZ=America/Mexico_City`) y Task 5 (`TZ=America/New_York`).
2. **Mascota sin tratamientos o archivada:** `% al día` no divide entre cero (100 %) y una mascota archivada no genera avisos. → Task 2 y Task 5.
3. **Frecuencia 0 o negativa, o frecuencia en una enfermedad/consulta:** se rechaza o se ignora; nunca se crea un tratamiento fantasma. Registrar un evento viejo no atrasa la próxima fecha. → Task 4.
4. **Respaldo con foto faltante, de versión más nueva, corrupto o con rutas maliciosas (`../`):** se rechaza sin tocar los datos actuales. → Task 7.
5. **Nombre de producto con mayúsculas o espacios distintos** («Antirrábica» vs « antirrabica  »): cuenta como el mismo tratamiento. → Task 4.

## File Structure

```
lib/
  main.dart                       arranque: abre BD, prefs, notificaciones
  app/
    app.dart                      MaterialApp.router + LockGate
    providers.dart                todos los providers de Riverpod
    router.dart                   rutas y shell con pestañas
  domain/                         Dart puro, sin Flutter ni BD
    enums.dart  dates.dart  text.dart  age.dart
    models.dart  treatment_status.dart  repositories.dart  backup_data.dart
    health_service.dart  reminder_plan.dart
    home_logic.dart  history_logic.dart  weight_logic.dart
  data/                           Drift
    tables.dart  database.dart  mappers.dart
    drift_repositories.dart  drift_backup_store.dart
  services/
    app_prefs.dart  reminder_scheduler.dart  local_notifications_scheduler.dart
    reminder_coordinator.dart  attachment_store.dart
    backup_codec.dart  backup_service.dart
    pin_store.dart  pdf_exporter.dart  share_service.dart
  ui/
    theme.dart  widgets.dart  format.dart
    onboarding/  pets/  home/  events/  history/  profile/  carnet/  settings/
test/
  helpers/ (samples.dart, fakes.dart, pump_app.dart)
  domain/  data/  services/  ui/
docs/privacy-policy.md   docs/release-checklist.md
```

---

### Task 0: Entorno y proyecto base

**Files:**
- Create: proyecto Flutter en la raíz (`pubspec.yaml`, `lib/`, `ios/`, `android/`, `analysis_options.yaml`)
- Modify: `lib/main.dart`
- Delete: `test/widget_test.dart`

**Interfaces:**
- Produces: paquete `huellitas` (imports `package:huellitas/...`), todas las dependencias instaladas.

- [ ] **Step 1: Instalar herramientas (lo hace la persona, requiere cuenta/contraseña)**

1. Instalar **Xcode** desde la App Store (descarga grande). Después:
```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
sudo xcodebuild -license accept
```
2. Instalar Flutter, CocoaPods y Android Studio:
```bash
brew install --cask flutter
brew install cocoapods
brew install --cask android-studio
```
3. Abrir Android Studio una vez, instalar *Android SDK* y *Android SDK Command-line Tools* (SDK Manager), luego:
```bash
flutter doctor --android-licenses
flutter doctor -v
```
Expected: Flutter, Android toolchain y Xcode con ✓. (Chrome/web pueden salir con ✗: no se usan.)

Nota: las Tasks 1–8 solo necesitan el SDK de Flutter para `flutter test`; se puede avanzar mientras Xcode descarga.

- [ ] **Step 2: Crear el proyecto en la carpeta actual**

```bash
cd /Users/javierestrada/Documents/Proyecto/pet
flutter create --org com.huellitas --project-name huellitas --platforms ios,android .
```
El identificador queda `com.huellitas.huellitas`. **Es permanente una vez subida la app a las tiendas**: confirmarlo con la persona ahora; cambiarlo después es costoso.

- [ ] **Step 3: Instalar dependencias**

```bash
flutter pub add flutter_riverpod go_router drift sqlite3_flutter_libs path_provider path uuid intl google_fonts shared_preferences flutter_secure_storage crypto archive share_plus file_picker image_picker flutter_image_compress local_auth flutter_local_notifications timezone flutter_timezone pdf
flutter pub add flutter_localizations --sdk=flutter
flutter pub add --dev drift_dev build_runner
```

- [ ] **Step 4: Dejar un arranque mínimo y quitar la prueba de ejemplo**

```bash
rm test/widget_test.dart
```
Reemplazar `lib/main.dart` por:
```dart
import 'package:flutter/widgets.dart';

void main() => runApp(const SizedBox());
```

- [ ] **Step 5: Verificar**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git init
git add .
git commit -m "chore: scaffold Flutter project with spec and plan"
```

---

### Task 1: Enums y aritmética de fechas

**Files:**
- Create: `lib/domain/enums.dart`, `lib/domain/dates.dart`
- Test: `test/domain/dates_test.dart`

**Interfaces:**
- Produces:
  - `enum PetSpecies { dog, cat, other }`, `enum PetSex { male, female }`, `enum EventType { vaccine, deworming, fleaTick, illness, checkup }` (con `bool canRecur`, `String label`, `String pluralLabel`), `enum IntervalUnit { days, weeks, months, years }`, `enum AttachmentKind { image, pdf }`
  - `DateTime dateOnly(DateTime d)`, `DateTime addInterval(DateTime from, int value, IntervalUnit unit)`, `int daysUntil(DateTime due, DateTime today)`

- [ ] **Step 1: Escribir la prueba que falla**

`test/domain/dates_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/domain/dates.dart';
import 'package:huellitas/domain/enums.dart';

DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

void main() {
  group('addInterval', () {
    test('suma días y semanas', () {
      expect(addInterval(d(2024, 10, 24), 10, IntervalUnit.days), d(2024, 11, 3));
      expect(addInterval(d(2024, 10, 24), 2, IntervalUnit.weeks), d(2024, 11, 7));
    });
    test('suma meses', () {
      expect(addInterval(d(2024, 10, 24), 1, IntervalUnit.months), d(2024, 11, 24));
      expect(addInterval(d(2024, 11, 30), 3, IntervalUnit.months), d(2025, 2, 28));
    });
    test('ajusta fin de mes', () {
      expect(addInterval(d(2025, 1, 31), 1, IntervalUnit.months), d(2025, 2, 28));
      expect(addInterval(d(2024, 1, 31), 1, IntervalUnit.months), d(2024, 2, 29));
    });
    test('suma años y ajusta el 29 de febrero', () {
      expect(addInterval(d(2024, 10, 24), 1, IntervalUnit.years), d(2025, 10, 24));
      expect(addInterval(d(2024, 2, 29), 1, IntervalUnit.years), d(2025, 2, 28));
    });
    test('ignora la hora de la fecha de origen', () {
      expect(addInterval(DateTime(2024, 10, 24, 23, 59), 1, IntervalUnit.days), d(2024, 10, 25));
    });
  });

  group('daysUntil', () {
    test('mismo día, mañana y hace 3 días', () {
      expect(daysUntil(d(2024, 10, 24), d(2024, 10, 24)), 0);
      expect(daysUntil(d(2024, 10, 25), d(2024, 10, 24)), 1);
      expect(daysUntil(d(2024, 10, 21), d(2024, 10, 24)), -3);
    });
    test('ignora la hora de "hoy"', () {
      expect(daysUntil(d(2024, 10, 25), DateTime(2024, 10, 24, 23, 59)), 1);
    });
  });

  test('EventType.canRecur solo para vacuna, desparasitación y antipulgas', () {
    expect(EventType.vaccine.canRecur, isTrue);
    expect(EventType.deworming.canRecur, isTrue);
    expect(EventType.fleaTick.canRecur, isTrue);
    expect(EventType.illness.canRecur, isFalse);
    expect(EventType.checkup.canRecur, isFalse);
  });
}
```

- [ ] **Step 2: Ejecutar y ver que falla**

Run: `flutter test test/domain/dates_test.dart`
Expected: FAIL (`Target of URI doesn't exist: 'package:huellitas/domain/dates.dart'`)

- [ ] **Step 3: Implementar**

`lib/domain/enums.dart`:
```dart
enum PetSpecies { dog, cat, other }

enum PetSex { male, female }

enum EventType { vaccine, deworming, fleaTick, illness, checkup }

enum IntervalUnit { days, weeks, months, years }

enum AttachmentKind { image, pdf }

extension EventTypeInfo on EventType {
  bool get canRecur =>
      this == EventType.vaccine ||
      this == EventType.deworming ||
      this == EventType.fleaTick;

  String get label => switch (this) {
        EventType.vaccine => 'Vacuna',
        EventType.deworming => 'Desparasitación',
        EventType.fleaTick => 'Antipulgas y garrapatas',
        EventType.illness => 'Enfermedad',
        EventType.checkup => 'Consulta',
      };

  String get pluralLabel => switch (this) {
        EventType.vaccine => 'Vacunas',
        EventType.deworming => 'Desparasitación',
        EventType.fleaTick => 'Antipulgas',
        EventType.illness => 'Enfermedades',
        EventType.checkup => 'Consultas',
      };
}
```

`lib/domain/dates.dart`:
```dart
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
```

- [ ] **Step 4: Ejecutar y ver que pasa**

Run: `flutter test test/domain/dates_test.dart && TZ=America/Mexico_City flutter test test/domain/dates_test.dart`
Expected: PASS (ambas)

- [ ] **Step 5: Commit**

```bash
git add lib/domain test/domain
git commit -m "feat(domain): enums and calendar-day interval math"
```

---

### Task 2: Modelos, estado de vencimiento y edad

**Files:**
- Create: `lib/domain/models.dart`, `lib/domain/text.dart`, `lib/domain/age.dart`, `lib/domain/treatment_status.dart`
- Test: `test/domain/treatment_status_test.dart`, `test/domain/age_text_test.dart`

**Interfaces:**
- Consumes: `enums.dart`, `dates.dart` (Task 1).
- Produces:
  - `Pet`, `WeightEntry`, `Treatment` (con `copyWith({int? intervalValue, IntervalUnit? intervalUnit, DateTime? nextDueDate, int? reminderDaysBefore, bool? reminderEnabled, bool? active})`), `HealthEvent`, `Attachment` (campos abajo)
  - `enum DueStatus { overdue, dueSoon, upcoming }`, `DueStatus dueStatus(DateTime nextDue, DateTime today)`, `String dueLabel(DateTime nextDue, DateTime today)`, `int percentUpToDate(Iterable<Treatment>, DateTime today)`
  - `String ageLabel(DateTime birth, DateTime today)`, `String normalizeName(String)`, `String foldText(String)`

- [ ] **Step 1: Escribir las pruebas que fallan**

`test/domain/treatment_status_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/domain/enums.dart';
import 'package:huellitas/domain/models.dart';
import 'package:huellitas/domain/treatment_status.dart';

final today = DateTime.utc(2024, 10, 24);

Treatment tr(DateTime due, {bool active = true, String id = 't'}) => Treatment(
      id: id,
      petId: 'p1',
      type: EventType.vaccine,
      name: 'Antirrábica',
      intervalValue: 1,
      intervalUnit: IntervalUnit.years,
      nextDueDate: due,
      active: active,
    );

void main() {
  test('dueStatus', () {
    expect(dueStatus(DateTime.utc(2024, 10, 23), today), DueStatus.overdue);
    expect(dueStatus(DateTime.utc(2024, 10, 24), today), DueStatus.dueSoon);
    expect(dueStatus(DateTime.utc(2024, 10, 31), today), DueStatus.dueSoon);
    expect(dueStatus(DateTime.utc(2024, 11, 1), today), DueStatus.upcoming);
  });

  test('dueLabel', () {
    expect(dueLabel(DateTime.utc(2024, 10, 21), today), 'Atrasada · hace 3 días');
    expect(dueLabel(DateTime.utc(2024, 10, 23), today), 'Atrasada · hace 1 día');
    expect(dueLabel(DateTime.utc(2024, 10, 24), today), 'Hoy');
    expect(dueLabel(DateTime.utc(2024, 10, 25), today), 'Vence en 1 día');
    expect(dueLabel(DateTime.utc(2024, 10, 29), today), 'Vence en 5 días');
    expect(dueLabel(DateTime.utc(2024, 11, 5), today), 'En 12 días');
  });

  group('percentUpToDate', () {
    test('sin tratamientos es 100 (no divide entre cero)', () {
      expect(percentUpToDate(const [], today), 100);
    });
    test('un atrasado de tres es 67', () {
      final list = [
        tr(DateTime.utc(2024, 10, 1), id: 'a'),
        tr(DateTime.utc(2024, 11, 1), id: 'b'),
        tr(DateTime.utc(2025, 1, 1), id: 'c'),
      ];
      expect(percentUpToDate(list, today), 67);
    });
    test('ignora inactivos', () {
      final list = [tr(DateTime.utc(2024, 10, 1), active: false)];
      expect(percentUpToDate(list, today), 100);
    });
    test('todos atrasados es 0', () {
      expect(percentUpToDate([tr(DateTime.utc(2024, 10, 1))], today), 0);
    });
  });
}
```

`test/domain/age_text_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/domain/age.dart';
import 'package:huellitas/domain/text.dart';

void main() {
  final today = DateTime.utc(2024, 10, 24);
  test('ageLabel', () {
    expect(ageLabel(DateTime.utc(2021, 6, 12), today), '3a 4m');
    expect(ageLabel(DateTime.utc(2022, 10, 24), today), '2a');
    expect(ageLabel(DateTime.utc(2024, 8, 31), today), '1m');
    expect(ageLabel(DateTime.utc(2024, 10, 24), today), '0m');
    expect(ageLabel(DateTime.utc(2030, 1, 1), today), '0m');
  });
  test('normalizeName ignora mayúsculas y espacios', () {
    expect(normalizeName('  Antirrábica '), normalizeName('antirrábica'));
    expect(normalizeName('Drontal   Plus'), 'drontal plus');
  });
  test('foldText quita acentos', () {
    expect(foldText('Desparasitación Ñandú'), 'desparasitacion nandu');
  });
}
```

- [ ] **Step 2: Ejecutar y ver que fallan**

Run: `flutter test test/domain`
Expected: FAIL (archivos inexistentes)

- [ ] **Step 3: Implementar**

`lib/domain/models.dart`:
```dart
import 'enums.dart';

class Pet {
  const Pet({
    required this.id,
    required this.name,
    required this.species,
    required this.createdAt,
    this.breed,
    this.sex,
    this.neutered = false,
    this.birthDate,
    this.microchip,
    this.photoPath,
    this.allergiesNotes,
    this.vetName,
    this.vetClinic,
    this.vetPhone,
    this.archived = false,
  });

  final String id;
  final String name;
  final PetSpecies species;
  final DateTime createdAt;
  final String? breed;
  final PetSex? sex;
  final bool neutered;
  final DateTime? birthDate; // día calendario (UTC)
  final String? microchip;
  final String? photoPath; // ruta relativa
  final String? allergiesNotes;
  final String? vetName;
  final String? vetClinic;
  final String? vetPhone;
  final bool archived;
}

class WeightEntry {
  const WeightEntry({
    required this.id,
    required this.petId,
    required this.date,
    required this.kg,
    this.note,
  });

  final String id;
  final String petId;
  final DateTime date; // día calendario (UTC)
  final double kg;
  final String? note;
}

class Treatment {
  const Treatment({
    required this.id,
    required this.petId,
    required this.type,
    required this.name,
    required this.intervalValue,
    required this.intervalUnit,
    required this.nextDueDate,
    this.reminderDaysBefore = 3,
    this.reminderEnabled = true,
    this.active = true,
  });

  final String id;
  final String petId;
  final EventType type;
  final String name;
  final int intervalValue;
  final IntervalUnit intervalUnit;
  final DateTime nextDueDate; // día calendario (UTC)
  final int reminderDaysBefore;
  final bool reminderEnabled;
  final bool active;

  Treatment copyWith({
    int? intervalValue,
    IntervalUnit? intervalUnit,
    DateTime? nextDueDate,
    int? reminderDaysBefore,
    bool? reminderEnabled,
    bool? active,
  }) =>
      Treatment(
        id: id,
        petId: petId,
        type: type,
        name: name,
        intervalValue: intervalValue ?? this.intervalValue,
        intervalUnit: intervalUnit ?? this.intervalUnit,
        nextDueDate: nextDueDate ?? this.nextDueDate,
        reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
        reminderEnabled: reminderEnabled ?? this.reminderEnabled,
        active: active ?? this.active,
      );
}

class HealthEvent {
  const HealthEvent({
    required this.id,
    required this.petId,
    required this.type,
    required this.title,
    required this.occurredAt,
    required this.createdAt,
    this.treatmentId,
    this.product,
    this.lot,
    this.vetName,
    this.clinic,
    this.notes,
    this.weightKg,
  });

  final String id;
  final String petId;
  final EventType type;
  final String title;
  final DateTime occurredAt; // instante (hora local)
  final DateTime createdAt;
  final String? treatmentId;
  final String? product;
  final String? lot;
  final String? vetName;
  final String? clinic;
  final String? notes;
  final double? weightKg;
}

class Attachment {
  const Attachment({
    required this.id,
    required this.eventId,
    required this.relativePath,
    required this.kind,
    this.label,
  });

  final String id;
  final String eventId;
  final String relativePath;
  final AttachmentKind kind;
  final String? label;
}
```

`lib/domain/text.dart`:
```dart
/// Clave para comparar nombres de producto: sin mayúsculas ni espacios de más.
String normalizeName(String s) =>
    s.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

const _from = 'áàäâéèëêíìïîóòöôúùüûñÁÀÄÂÉÈËÊÍÌÏÎÓÒÖÔÚÙÜÛÑ';
const _to = 'aaaaeeeeiiiioooouuuunAAAAEEEEIIIIOOOOUUUUN';

/// Minúsculas y sin acentos, para búsquedas.
String foldText(String s) {
  final b = StringBuffer();
  for (final ch in s.split('')) {
    final i = _from.indexOf(ch);
    b.write(i >= 0 ? _to[i] : ch);
  }
  return b.toString().toLowerCase();
}
```

`lib/domain/age.dart`:
```dart
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
```

`lib/domain/treatment_status.dart`:
```dart
import 'dates.dart';
import 'models.dart';

enum DueStatus { overdue, dueSoon, upcoming }

DueStatus dueStatus(DateTime nextDue, DateTime today) {
  final days = daysUntil(nextDue, today);
  if (days < 0) return DueStatus.overdue;
  if (days <= 7) return DueStatus.dueSoon;
  return DueStatus.upcoming;
}

String _days(int n) => '$n ${n == 1 ? 'día' : 'días'}';

String dueLabel(DateTime nextDue, DateTime today) {
  final days = daysUntil(nextDue, today);
  if (days < 0) return 'Atrasada · hace ${_days(-days)}';
  if (days == 0) return 'Hoy';
  if (days <= 7) return 'Vence en ${_days(days)}';
  return 'En ${_days(days)}';
}

/// Porcentaje de tratamientos activos que no están atrasados.
/// Sin tratamientos activos devuelve 100.
int percentUpToDate(Iterable<Treatment> treatments, DateTime today) {
  final active = treatments.where((t) => t.active).toList();
  if (active.isEmpty) return 100;
  final ok = active.where((t) => daysUntil(t.nextDueDate, today) >= 0).length;
  return (ok * 100 / active.length).round();
}
```

- [ ] **Step 4: Ejecutar y ver que pasan**

Run: `flutter test test/domain`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/domain test/domain
git commit -m "feat(domain): models, due status, age and text helpers"
```

---

### Task 3: Interfaces de repositorio y base de datos local (Drift)

**Files:**
- Create: `lib/domain/repositories.dart`, `lib/domain/backup_data.dart`, `lib/data/tables.dart`, `lib/data/database.dart`, `lib/data/mappers.dart`, `lib/data/drift_repositories.dart`, `lib/data/drift_backup_store.dart`
- Test: `test/helpers/samples.dart`, `test/data/repositories_test.dart`

**Interfaces:**
- Consumes: modelos y enums (Tasks 1–2), `normalizeName`.
- Produces:
```dart
abstract class PetRepository {
  Stream<List<Pet>> watchAll();            // no archivadas, por createdAt
  Future<List<Pet>> all();                 // incluye archivadas, por id
  Future<Pet?> get(String id);
  Future<void> save(Pet pet);              // insert o update
  Future<void> archive(String id);
}
abstract class TreatmentRepository {
  Stream<List<Treatment>> watchActive();
  Future<List<Treatment>> active();
  Future<Treatment?> get(String id);
  Future<Treatment?> find(String petId, EventType type, String name); // incluye inactivos; compara con normalizeName
  Future<void> save(Treatment t);
}
abstract class EventRepository {
  Stream<List<HealthEvent>> watchForPet(String petId);   // más reciente primero
  Future<HealthEvent?> get(String id);
  Future<List<Attachment>> attachmentsFor(String eventId);
  Future<void> save(HealthEvent e, List<Attachment> attachments); // reemplaza los adjuntos del evento
  Future<List<String>> delete(String id);                // devuelve rutas relativas de adjuntos borrados
}
abstract class WeightRepository {
  Stream<List<WeightEntry>> watchForPet(String petId);   // más reciente primero
  Future<void> save(WeightEntry w);
  Future<void> delete(String id);
}
abstract class BackupStore {
  Future<BackupData> readAll();                          // ordenado por id
  Future<void> replaceAll(BackupData data);              // transaccional
}
class BackupData { final List<Pet> pets; final List<WeightEntry> weights; final List<Treatment> treatments; final List<HealthEvent> events; final List<Attachment> attachments; }
class AppDatabase  // AppDatabase(QueryExecutor), AppDatabase.memory(), AppDatabase.file(File)
class DriftPetRepository(AppDatabase), DriftTreatmentRepository, DriftEventRepository, DriftWeightRepository, DriftBackupStore
```

- [ ] **Step 1: Interfaces del dominio**

`lib/domain/backup_data.dart`:
```dart
import 'models.dart';

class BackupData {
  const BackupData({
    required this.pets,
    required this.weights,
    required this.treatments,
    required this.events,
    required this.attachments,
  });

  final List<Pet> pets;
  final List<WeightEntry> weights;
  final List<Treatment> treatments;
  final List<HealthEvent> events;
  final List<Attachment> attachments;
}
```

`lib/domain/repositories.dart`:
```dart
import 'backup_data.dart';
import 'enums.dart';
import 'models.dart';

abstract class PetRepository {
  Stream<List<Pet>> watchAll();
  Future<List<Pet>> all();
  Future<Pet?> get(String id);
  Future<void> save(Pet pet);
  Future<void> archive(String id);
}

abstract class TreatmentRepository {
  Stream<List<Treatment>> watchActive();
  Future<List<Treatment>> active();
  Future<Treatment?> get(String id);
  Future<Treatment?> find(String petId, EventType type, String name);
  Future<void> save(Treatment t);
}

abstract class EventRepository {
  Stream<List<HealthEvent>> watchForPet(String petId);
  Future<HealthEvent?> get(String id);
  Future<List<Attachment>> attachmentsFor(String eventId);
  Future<void> save(HealthEvent e, List<Attachment> attachments);
  Future<List<String>> delete(String id);
}

abstract class WeightRepository {
  Stream<List<WeightEntry>> watchForPet(String petId);
  Future<void> save(WeightEntry w);
  Future<void> delete(String id);
}

abstract class BackupStore {
  Future<BackupData> readAll();
  Future<void> replaceAll(BackupData data);
}
```

- [ ] **Step 2: Helpers de prueba y prueba que falla**

`test/helpers/samples.dart`:
```dart
import 'package:huellitas/domain/enums.dart';
import 'package:huellitas/domain/models.dart';

Pet samplePet({
  String id = 'p1',
  String name = 'Toby',
  String? photoPath,
  bool archived = false,
}) =>
    Pet(
      id: id,
      name: name,
      species: PetSpecies.dog,
      breed: 'Golden Retriever',
      sex: PetSex.male,
      neutered: true,
      birthDate: DateTime.utc(2021, 6, 12),
      microchip: '981098102938471',
      photoPath: photoPath,
      allergiesNotes: 'Ninguna',
      vetName: 'Dra. Carmen Morales',
      vetClinic: 'Vet Narvarte',
      vetPhone: '5555555555',
      createdAt: DateTime(2024, 1, 1, 8),
      archived: archived,
    );

Treatment sampleTreatment({
  String id = 't1',
  String petId = 'p1',
  EventType type = EventType.vaccine,
  String name = 'Antirrábica',
  DateTime? nextDue,
  bool active = true,
  bool reminderEnabled = true,
  int reminderDaysBefore = 3,
}) =>
    Treatment(
      id: id,
      petId: petId,
      type: type,
      name: name,
      intervalValue: 1,
      intervalUnit: IntervalUnit.years,
      nextDueDate: nextDue ?? DateTime.utc(2024, 10, 29),
      reminderEnabled: reminderEnabled,
      reminderDaysBefore: reminderDaysBefore,
      active: active,
    );

HealthEvent sampleEvent({
  String id = 'e1',
  String petId = 'p1',
  EventType type = EventType.vaccine,
  String title = 'Antirrábica',
  DateTime? occurredAt,
  String? treatmentId,
  String? notes,
}) =>
    HealthEvent(
      id: id,
      petId: petId,
      type: type,
      title: title,
      occurredAt: occurredAt ?? DateTime(2024, 10, 15, 11, 30),
      createdAt: DateTime(2024, 10, 15, 11, 31),
      treatmentId: treatmentId,
      product: title,
      lot: 'NX-9921',
      vetName: 'Dra. Carmen Morales',
      clinic: 'Vet Narvarte',
      notes: notes,
      weightKg: null,
    );

Attachment sampleAttachment({
  String id = 'a1',
  String eventId = 'e1',
  String path = 'attachments/a1.jpg',
}) =>
    Attachment(
      id: id,
      eventId: eventId,
      relativePath: path,
      kind: AttachmentKind.image,
      label: 'Carnet',
    );
```

`test/data/repositories_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/data/database.dart';
import 'package:huellitas/data/drift_backup_store.dart';
import 'package:huellitas/data/drift_repositories.dart';
import 'package:huellitas/domain/backup_data.dart';
import 'package:huellitas/domain/enums.dart';
import 'package:huellitas/domain/models.dart';

import '../helpers/samples.dart';

void main() {
  late AppDatabase db;
  late DriftPetRepository pets;
  late DriftTreatmentRepository treatments;
  late DriftEventRepository events;
  late DriftWeightRepository weights;

  setUp(() {
    db = AppDatabase.memory();
    pets = DriftPetRepository(db);
    treatments = DriftTreatmentRepository(db);
    events = DriftEventRepository(db);
    weights = DriftWeightRepository(db);
  });
  tearDown(() => db.close());

  test('mascota: guarda, lee y conserva la fecha de nacimiento como día UTC', () async {
    await pets.save(samplePet());
    final p = (await pets.get('p1'))!;
    expect(p.name, 'Toby');
    expect(p.species, PetSpecies.dog);
    expect(p.birthDate, DateTime.utc(2021, 6, 12)); // sin corrimiento por zona horaria
    expect(p.createdAt, DateTime(2024, 1, 1, 8));
  });

  test('archivar oculta de watchAll pero all() la conserva', () async {
    await pets.save(samplePet());
    await pets.save(samplePet(id: 'p2', name: 'Misi'));
    await pets.archive('p1');
    expect((await pets.watchAll().first).map((p) => p.id), ['p2']);
    expect((await pets.all()).map((p) => p.id), ['p1', 'p2']);
  });

  test('tratamiento: nextDueDate vuelve igual (día UTC)', () async {
    await treatments.save(sampleTreatment(nextDue: DateTime.utc(2024, 10, 24)));
    final t = (await treatments.get('t1'))!;
    expect(t.nextDueDate, DateTime.utc(2024, 10, 24));
  });

  test('find ignora mayúsculas/espacios y distingue tipo; active() excluye inactivos', () async {
    await treatments.save(sampleTreatment());
    await treatments.save(sampleTreatment(id: 't2', name: 'Otra', active: false));
    expect((await treatments.find('p1', EventType.vaccine, '  antirrábica '))?.id, 't1');
    expect(await treatments.find('p1', EventType.deworming, 'Antirrábica'), isNull);
    expect(await treatments.find('p1', EventType.vaccine, 'Otra'), isNotNull);
    expect((await treatments.active()).map((t) => t.id), ['t1']);
  });

  test('evento: guardar reemplaza adjuntos y delete devuelve las rutas', () async {
    await events.save(sampleEvent(), [
      sampleAttachment(),
      sampleAttachment(id: 'a2', path: 'attachments/a2.jpg'),
    ]);
    expect((await events.attachmentsFor('e1')).length, 2);

    await events.save(sampleEvent(), [sampleAttachment(id: 'a3', path: 'attachments/a3.jpg')]);
    expect((await events.attachmentsFor('e1')).map((a) => a.id), ['a3']);

    final removed = await events.delete('e1');
    expect(removed, ['attachments/a3.jpg']);
    expect(await events.get('e1'), isNull);
    expect(await events.attachmentsFor('e1'), isEmpty);
  });

  test('eventos por mascota salen del más reciente al más antiguo', () async {
    await events.save(sampleEvent(id: 'old', occurredAt: DateTime(2024, 1, 1)), []);
    await events.save(sampleEvent(id: 'new', occurredAt: DateTime(2024, 9, 1)), []);
    expect((await events.watchForPet('p1').first).map((e) => e.id), ['new', 'old']);
  });

  test('peso: guarda, ordena y borra', () async {
    await weights.save(WeightEntry(id: 'w1', petId: 'p1', date: DateTime.utc(2024, 8, 3), kg: 28.2));
    await weights.save(WeightEntry(id: 'w2', petId: 'p1', date: DateTime.utc(2024, 10, 1), kg: 28.5));
    final list = await weights.watchForPet('p1').first;
    expect(list.map((w) => w.id), ['w2', 'w1']);
    expect(list.first.date, DateTime.utc(2024, 10, 1));
    await weights.delete('w2');
    expect((await weights.watchForPet('p1').first).length, 1);
  });

  test('BackupStore: replaceAll borra lo anterior y readAll devuelve lo nuevo', () async {
    await pets.save(samplePet(id: 'viejo'));
    final store = DriftBackupStore(db);
    await store.replaceAll(BackupData(
      pets: [samplePet()],
      weights: const [],
      treatments: [sampleTreatment()],
      events: [sampleEvent()],
      attachments: [sampleAttachment()],
    ));
    final data = await store.readAll();
    expect(data.pets.map((p) => p.id), ['p1']);
    expect(data.treatments.single.nextDueDate, DateTime.utc(2024, 10, 29));
    expect(data.events.single.id, 'e1');
    expect(data.attachments.single.relativePath, 'attachments/a1.jpg');
  });
}
```

- [ ] **Step 3: Ejecutar y ver que falla**

Run: `flutter test test/data/repositories_test.dart`
Expected: FAIL (`database.dart` no existe)

- [ ] **Step 4: Tablas y base de datos**

`lib/data/tables.dart`:
```dart
import 'package:drift/drift.dart';

import '../domain/enums.dart';

@DataClassName('PetRow')
class Pets extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get species => textEnum<PetSpecies>()();
  TextColumn get breed => text().nullable()();
  TextColumn get sex => textEnum<PetSex>().nullable()();
  BoolColumn get neutered => boolean().withDefault(const Constant(false))();
  DateTimeColumn get birthDate => dateTime().nullable()();
  TextColumn get microchip => text().nullable()();
  TextColumn get photoPath => text().nullable()();
  TextColumn get allergiesNotes => text().nullable()();
  TextColumn get vetName => text().nullable()();
  TextColumn get vetClinic => text().nullable()();
  TextColumn get vetPhone => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('WeightRow')
class WeightEntries extends Table {
  TextColumn get id => text()();
  TextColumn get petId => text()();
  DateTimeColumn get date => dateTime()();
  RealColumn get kg => real()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TreatmentRow')
class Treatments extends Table {
  TextColumn get id => text()();
  TextColumn get petId => text()();
  TextColumn get type => textEnum<EventType>()();
  TextColumn get name => text()();
  IntColumn get intervalValue => integer()();
  TextColumn get intervalUnit => textEnum<IntervalUnit>()();
  DateTimeColumn get nextDueDate => dateTime()();
  IntColumn get reminderDaysBefore => integer().withDefault(const Constant(3))();
  BoolColumn get reminderEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('EventRow')
class HealthEvents extends Table {
  TextColumn get id => text()();
  TextColumn get petId => text()();
  TextColumn get treatmentId => text().nullable()();
  TextColumn get type => textEnum<EventType>()();
  TextColumn get title => text()();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get product => text().nullable()();
  TextColumn get lot => text().nullable()();
  TextColumn get vetName => text().nullable()();
  TextColumn get clinic => text().nullable()();
  TextColumn get notes => text().nullable()();
  RealColumn get weightKg => real().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AttachmentRow')
class Attachments extends Table {
  TextColumn get id => text()();
  TextColumn get eventId => text()();
  TextColumn get relativePath => text()();
  TextColumn get kind => textEnum<AttachmentKind>()();
  TextColumn get label => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
```

`lib/data/database.dart`:
```dart
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
```

Generar código:
```bash
dart run build_runner build --delete-conflicting-outputs
```
Expected: se crea `lib/data/database.g.dart` sin errores.

- [ ] **Step 5: Mapeos entre filas y modelos**

`lib/data/mappers.dart`:
```dart
import 'package:drift/drift.dart';

import '../domain/models.dart';
import 'database.dart';

// Fechas de día calendario: se leen con .toUtc() (la BD las devuelve en hora
// local y en UTC-6 el día se correría). Instantes: se leen con .toLocal().

Pet petFromRow(PetRow r) => Pet(
      id: r.id,
      name: r.name,
      species: r.species,
      breed: r.breed,
      sex: r.sex,
      neutered: r.neutered,
      birthDate: r.birthDate?.toUtc(),
      microchip: r.microchip,
      photoPath: r.photoPath,
      allergiesNotes: r.allergiesNotes,
      vetName: r.vetName,
      vetClinic: r.vetClinic,
      vetPhone: r.vetPhone,
      createdAt: r.createdAt.toLocal(),
      archived: r.archived,
    );

PetsCompanion petToCompanion(Pet p) => PetsCompanion.insert(
      id: p.id,
      name: p.name,
      species: p.species,
      createdAt: p.createdAt,
      breed: Value(p.breed),
      sex: Value(p.sex),
      neutered: Value(p.neutered),
      birthDate: Value(p.birthDate),
      microchip: Value(p.microchip),
      photoPath: Value(p.photoPath),
      allergiesNotes: Value(p.allergiesNotes),
      vetName: Value(p.vetName),
      vetClinic: Value(p.vetClinic),
      vetPhone: Value(p.vetPhone),
      archived: Value(p.archived),
    );

WeightEntry weightFromRow(WeightRow r) => WeightEntry(
      id: r.id,
      petId: r.petId,
      date: r.date.toUtc(),
      kg: r.kg,
      note: r.note,
    );

WeightEntriesCompanion weightToCompanion(WeightEntry w) => WeightEntriesCompanion.insert(
      id: w.id,
      petId: w.petId,
      date: w.date,
      kg: w.kg,
      note: Value(w.note),
    );

Treatment treatmentFromRow(TreatmentRow r) => Treatment(
      id: r.id,
      petId: r.petId,
      type: r.type,
      name: r.name,
      intervalValue: r.intervalValue,
      intervalUnit: r.intervalUnit,
      nextDueDate: r.nextDueDate.toUtc(),
      reminderDaysBefore: r.reminderDaysBefore,
      reminderEnabled: r.reminderEnabled,
      active: r.active,
    );

TreatmentsCompanion treatmentToCompanion(Treatment t) => TreatmentsCompanion.insert(
      id: t.id,
      petId: t.petId,
      type: t.type,
      name: t.name,
      intervalValue: t.intervalValue,
      intervalUnit: t.intervalUnit,
      nextDueDate: t.nextDueDate,
      reminderDaysBefore: Value(t.reminderDaysBefore),
      reminderEnabled: Value(t.reminderEnabled),
      active: Value(t.active),
    );

HealthEvent eventFromRow(EventRow r) => HealthEvent(
      id: r.id,
      petId: r.petId,
      treatmentId: r.treatmentId,
      type: r.type,
      title: r.title,
      occurredAt: r.occurredAt.toLocal(),
      product: r.product,
      lot: r.lot,
      vetName: r.vetName,
      clinic: r.clinic,
      notes: r.notes,
      weightKg: r.weightKg,
      createdAt: r.createdAt.toLocal(),
    );

HealthEventsCompanion eventToCompanion(HealthEvent e) => HealthEventsCompanion.insert(
      id: e.id,
      petId: e.petId,
      type: e.type,
      title: e.title,
      occurredAt: e.occurredAt,
      createdAt: e.createdAt,
      treatmentId: Value(e.treatmentId),
      product: Value(e.product),
      lot: Value(e.lot),
      vetName: Value(e.vetName),
      clinic: Value(e.clinic),
      notes: Value(e.notes),
      weightKg: Value(e.weightKg),
    );

Attachment attachmentFromRow(AttachmentRow r) => Attachment(
      id: r.id,
      eventId: r.eventId,
      relativePath: r.relativePath,
      kind: r.kind,
      label: r.label,
    );

AttachmentsCompanion attachmentToCompanion(Attachment a) => AttachmentsCompanion.insert(
      id: a.id,
      eventId: a.eventId,
      relativePath: a.relativePath,
      kind: a.kind,
      label: Value(a.label),
    );
```

- [ ] **Step 6: Repositorios y BackupStore**

`lib/data/drift_repositories.dart`:
```dart
import 'package:drift/drift.dart';

import '../domain/enums.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';
import '../domain/text.dart';
import 'database.dart';
import 'mappers.dart';

class DriftPetRepository implements PetRepository {
  DriftPetRepository(this._db);
  final AppDatabase _db;

  @override
  Stream<List<Pet>> watchAll() => (_db.select(_db.pets)
        ..where((t) => t.archived.equals(false))
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
      .watch()
      .map((rows) => rows.map(petFromRow).toList());

  @override
  Future<List<Pet>> all() async => (await (_db.select(_db.pets)
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get())
      .map(petFromRow)
      .toList();

  @override
  Future<Pet?> get(String id) async {
    final r = await (_db.select(_db.pets)..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null ? null : petFromRow(r);
  }

  @override
  Future<void> save(Pet pet) => _db.into(_db.pets).insertOnConflictUpdate(petToCompanion(pet));

  @override
  Future<void> archive(String id) => (_db.update(_db.pets)..where((t) => t.id.equals(id)))
      .write(const PetsCompanion(archived: Value(true)));
}

class DriftTreatmentRepository implements TreatmentRepository {
  DriftTreatmentRepository(this._db);
  final AppDatabase _db;

  SimpleSelectStatement<$TreatmentsTable, TreatmentRow> get _activeQuery =>
      _db.select(_db.treatments)
        ..where((t) => t.active.equals(true))
        ..orderBy([(t) => OrderingTerm.asc(t.nextDueDate)]);

  @override
  Stream<List<Treatment>> watchActive() =>
      _activeQuery.watch().map((rows) => rows.map(treatmentFromRow).toList());

  @override
  Future<List<Treatment>> active() async =>
      (await _activeQuery.get()).map(treatmentFromRow).toList();

  @override
  Future<Treatment?> get(String id) async {
    final r = await (_db.select(_db.treatments)..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null ? null : treatmentFromRow(r);
  }

  @override
  Future<Treatment?> find(String petId, EventType type, String name) async {
    final rows = await (_db.select(_db.treatments)
          ..where((t) => t.petId.equals(petId) & t.type.equalsValue(type)))
        .get();
    final key = normalizeName(name);
    for (final r in rows) {
      if (normalizeName(r.name) == key) return treatmentFromRow(r);
    }
    return null;
  }

  @override
  Future<void> save(Treatment t) =>
      _db.into(_db.treatments).insertOnConflictUpdate(treatmentToCompanion(t));
}

class DriftEventRepository implements EventRepository {
  DriftEventRepository(this._db);
  final AppDatabase _db;

  @override
  Stream<List<HealthEvent>> watchForPet(String petId) => (_db.select(_db.healthEvents)
        ..where((t) => t.petId.equals(petId))
        ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
      .watch()
      .map((rows) => rows.map(eventFromRow).toList());

  @override
  Future<HealthEvent?> get(String id) async {
    final r = await (_db.select(_db.healthEvents)..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null ? null : eventFromRow(r);
  }

  @override
  Future<List<Attachment>> attachmentsFor(String eventId) async =>
      (await (_db.select(_db.attachments)..where((t) => t.eventId.equals(eventId))).get())
          .map(attachmentFromRow)
          .toList();

  @override
  Future<void> save(HealthEvent e, List<Attachment> attachments) => _db.transaction(() async {
        await _db.into(_db.healthEvents).insertOnConflictUpdate(eventToCompanion(e));
        await (_db.delete(_db.attachments)..where((t) => t.eventId.equals(e.id))).go();
        for (final a in attachments) {
          await _db.into(_db.attachments).insert(attachmentToCompanion(a));
        }
      });

  @override
  Future<List<String>> delete(String id) => _db.transaction(() async {
        final rows = await (_db.select(_db.attachments)..where((t) => t.eventId.equals(id))).get();
        await (_db.delete(_db.attachments)..where((t) => t.eventId.equals(id))).go();
        await (_db.delete(_db.healthEvents)..where((t) => t.id.equals(id))).go();
        return rows.map((r) => r.relativePath).toList();
      });
}

class DriftWeightRepository implements WeightRepository {
  DriftWeightRepository(this._db);
  final AppDatabase _db;

  @override
  Stream<List<WeightEntry>> watchForPet(String petId) => (_db.select(_db.weightEntries)
        ..where((t) => t.petId.equals(petId))
        ..orderBy([(t) => OrderingTerm.desc(t.date)]))
      .watch()
      .map((rows) => rows.map(weightFromRow).toList());

  @override
  Future<void> save(WeightEntry w) =>
      _db.into(_db.weightEntries).insertOnConflictUpdate(weightToCompanion(w));

  @override
  Future<void> delete(String id) =>
      (_db.delete(_db.weightEntries)..where((t) => t.id.equals(id))).go();
}
```

`lib/data/drift_backup_store.dart`:
```dart
import 'package:drift/drift.dart';

import '../domain/backup_data.dart';
import '../domain/repositories.dart';
import 'database.dart';
import 'mappers.dart';

class DriftBackupStore implements BackupStore {
  DriftBackupStore(this._db);
  final AppDatabase _db;

  @override
  Future<BackupData> readAll() async {
    final pets = await (_db.select(_db.pets)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    final weights =
        await (_db.select(_db.weightEntries)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    final treatments =
        await (_db.select(_db.treatments)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    final events =
        await (_db.select(_db.healthEvents)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    final attachments =
        await (_db.select(_db.attachments)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    return BackupData(
      pets: pets.map(petFromRow).toList(),
      weights: weights.map(weightFromRow).toList(),
      treatments: treatments.map(treatmentFromRow).toList(),
      events: events.map(eventFromRow).toList(),
      attachments: attachments.map(attachmentFromRow).toList(),
    );
  }

  @override
  Future<void> replaceAll(BackupData data) => _db.transaction(() async {
        await _db.delete(_db.attachments).go();
        await _db.delete(_db.healthEvents).go();
        await _db.delete(_db.treatments).go();
        await _db.delete(_db.weightEntries).go();
        await _db.delete(_db.pets).go();
        await _db.batch((b) {
          b.insertAll(_db.pets, data.pets.map(petToCompanion));
          b.insertAll(_db.weightEntries, data.weights.map(weightToCompanion));
          b.insertAll(_db.treatments, data.treatments.map(treatmentToCompanion));
          b.insertAll(_db.healthEvents, data.events.map(eventToCompanion));
          b.insertAll(_db.attachments, data.attachments.map(attachmentToCompanion));
        });
      });
}
```
- [ ] **Step 7: Ejecutar y ver que pasa (en dos zonas horarias)**

Run: `flutter test test/data/repositories_test.dart && TZ=America/Mexico_City flutter test test/data/repositories_test.dart`
Expected: PASS (ambas). Si falla solo con `TZ=America/Mexico_City` en una comparación de fechas, falta un `.toUtc()`/`.toLocal()` en `mappers.dart`.

- [ ] **Step 8: Analizar y commit**

Run: `flutter analyze`  → Expected: `No issues found!`
```bash
git add lib test
git commit -m "feat(data): drift database, repositories and backup store"
```

---

### Task 4: HealthService (registrar evento, marcar como hecha)

**Files:**
- Create: `lib/domain/health_service.dart`
- Test: `test/domain/health_service_test.dart`

**Interfaces:**
- Consumes: repositorios (Task 3), `addInterval`, `dateOnly`, `normalizeName`, `EventType.canRecur`.
- Produces:
```dart
class NewAttachment { const NewAttachment({required String relativePath, required AttachmentKind kind, String? label}); }
class LogEventInput {
  const LogEventInput({
    required String petId, required EventType type, required String title, required DateTime occurredAt,
    String? product, String? lot, String? vetName, String? clinic, String? notes, double? weightKg,
    int? intervalValue, IntervalUnit? intervalUnit,
    bool reminderEnabled = true, int reminderDaysBefore = 3,
    List<NewAttachment> attachments = const [],
  });
}
class HealthService {
  HealthService({required EventRepository events, required TreatmentRepository treatments,
    required WeightRepository weights, required DateTime Function() now, required String Function() newId});
  Future<HealthEvent> logEvent(LogEventInput input);   // ArgumentError si título vacío o frecuencia inválida
  Future<HealthEvent> markDone(String treatmentId);    // StateError si no existe
}
```

- [ ] **Step 1: Escribir la prueba que falla**

`test/domain/health_service_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/data/database.dart';
import 'package:huellitas/data/drift_repositories.dart';
import 'package:huellitas/domain/enums.dart';
import 'package:huellitas/domain/health_service.dart';

void main() {
  late AppDatabase db;
  late DriftTreatmentRepository treatments;
  late DriftEventRepository events;
  late DriftWeightRepository weights;
  late HealthService service;
  var n = 0;
  final now = DateTime(2024, 10, 24, 10);

  LogEventInput vaccine({
    String title = 'Antirrábica',
    DateTime? at,
    int? value = 1,
    IntervalUnit? unit = IntervalUnit.years,
    EventType type = EventType.vaccine,
    double? weightKg,
    List<NewAttachment> attachments = const [],
  }) =>
      LogEventInput(
        petId: 'p1',
        type: type,
        title: title,
        occurredAt: at ?? now,
        intervalValue: value,
        intervalUnit: unit,
        weightKg: weightKg,
        attachments: attachments,
      );

  setUp(() {
    n = 0;
    db = AppDatabase.memory();
    treatments = DriftTreatmentRepository(db);
    events = DriftEventRepository(db);
    weights = DriftWeightRepository(db);
    service = HealthService(
      events: events,
      treatments: treatments,
      weights: weights,
      now: () => now,
      newId: () => 'id${n++}',
    );
  });
  tearDown(() => db.close());

  test('vacuna con 1 año crea tratamiento con próxima fecha y enlaza el evento', () async {
    final e = await service.logEvent(vaccine());
    final t = (await treatments.active()).single;
    expect(t.nextDueDate, DateTime.utc(2025, 10, 24));
    expect(t.name, 'Antirrábica');
    expect(e.treatmentId, t.id);
    expect((await events.get(e.id))!.title, 'Antirrábica');
  });

  test('mismo producto con otras mayúsculas/espacios actualiza el mismo tratamiento', () async {
    await service.logEvent(vaccine(title: 'Antirrábica'));
    await service.logEvent(vaccine(title: '  antirrábica  ', at: DateTime(2025, 1, 10)));
    final all = await treatments.active();
    expect(all.length, 1);
    expect(all.single.nextDueDate, DateTime.utc(2026, 1, 10));
  });

  test('enfermedad o consulta con frecuencia NO crea tratamiento', () async {
    final e = await service.logEvent(vaccine(type: EventType.illness, title: 'Gastritis'));
    await service.logEvent(vaccine(type: EventType.checkup, title: 'Rutina'));
    expect(await treatments.active(), isEmpty);
    expect(e.treatmentId, isNull);
  });

  test('frecuencia 0, negativa o sin unidad se rechaza', () {
    expect(() => service.logEvent(vaccine(value: 0)), throwsArgumentError);
    expect(() => service.logEvent(vaccine(value: -1)), throwsArgumentError);
    expect(() => service.logEvent(vaccine(value: 1, unit: null)), throwsArgumentError);
  });

  test('título vacío o solo espacios se rechaza', () {
    expect(() => service.logEvent(vaccine(title: '   ')), throwsArgumentError);
  });

  test('evento sin frecuencia solo guarda el evento', () async {
    final e = await service.logEvent(vaccine(value: null, unit: null));
    expect(await treatments.active(), isEmpty);
    expect(e.treatmentId, isNull);
  });

  test('registrar un evento más viejo no atrasa la próxima fecha', () async {
    await service.logEvent(vaccine(at: DateTime(2024, 10, 24)));
    await service.logEvent(vaccine(at: DateTime(2023, 10, 20)));
    expect((await treatments.active()).single.nextDueDate, DateTime.utc(2025, 10, 24));
  });

  test('markDone crea evento de hoy y mueve la fecha desde hoy', () async {
    await service.logEvent(vaccine(at: DateTime(2023, 10, 21))); // próxima 2024-10-21: atrasada
    final t = (await treatments.active()).single;
    expect(t.nextDueDate, DateTime.utc(2024, 10, 21));

    final done = await service.markDone(t.id);
    expect(done.occurredAt, now);
    expect(done.treatmentId, t.id);
    expect((await treatments.get(t.id))!.nextDueDate, DateTime.utc(2025, 10, 24));
    expect((await events.watchForPet('p1').first).length, 2);
  });

  test('markDone con id inexistente lanza StateError', () {
    expect(() => service.markDone('nope'), throwsStateError);
  });

  test('un peso en el evento también crea un registro de peso', () async {
    await service.logEvent(vaccine(value: null, unit: null, weightKg: 28.5));
    final w = (await weights.watchForPet('p1').first).single;
    expect(w.kg, 28.5);
    expect(w.date, DateTime.utc(2024, 10, 24));
  });

  test('guarda los adjuntos del evento', () async {
    final e = await service.logEvent(vaccine(
      value: null,
      unit: null,
      attachments: const [
        NewAttachment(relativePath: 'attachments/x.jpg', kind: AttachmentKind.image, label: 'Carnet'),
      ],
    ));
    final list = await events.attachmentsFor(e.id);
    expect(list.single.relativePath, 'attachments/x.jpg');
  });
}
```

- [ ] **Step 2: Ejecutar y ver que falla**

Run: `flutter test test/domain/health_service_test.dart`
Expected: FAIL (`health_service.dart` no existe)

- [ ] **Step 3: Implementar**

`lib/domain/health_service.dart`:
```dart
import 'dates.dart';
import 'enums.dart';
import 'models.dart';
import 'repositories.dart';

class NewAttachment {
  const NewAttachment({required this.relativePath, required this.kind, this.label});
  final String relativePath;
  final AttachmentKind kind;
  final String? label;
}

class LogEventInput {
  const LogEventInput({
    required this.petId,
    required this.type,
    required this.title,
    required this.occurredAt,
    this.product,
    this.lot,
    this.vetName,
    this.clinic,
    this.notes,
    this.weightKg,
    this.intervalValue,
    this.intervalUnit,
    this.reminderEnabled = true,
    this.reminderDaysBefore = 3,
    this.attachments = const [],
  });

  final String petId;
  final EventType type;
  final String title;
  final DateTime occurredAt;
  final String? product;
  final String? lot;
  final String? vetName;
  final String? clinic;
  final String? notes;
  final double? weightKg;
  final int? intervalValue;
  final IntervalUnit? intervalUnit;
  final bool reminderEnabled;
  final int reminderDaysBefore;
  final List<NewAttachment> attachments;
}

class HealthService {
  HealthService({
    required EventRepository events,
    required TreatmentRepository treatments,
    required WeightRepository weights,
    required DateTime Function() now,
    required String Function() newId,
  })  : _events = events,
        _treatments = treatments,
        _weights = weights,
        _now = now,
        _newId = newId;

  final EventRepository _events;
  final TreatmentRepository _treatments;
  final WeightRepository _weights;
  final DateTime Function() _now;
  final String Function() _newId;

  String? _clean(String? s) {
    final t = s?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  Future<HealthEvent> logEvent(LogEventInput i) async {
    final title = i.title.trim();
    if (title.isEmpty) {
      throw ArgumentError.value(i.title, 'title', 'no puede estar vacío');
    }
    final value = i.intervalValue;
    if (value != null && (value < 1 || i.intervalUnit == null)) {
      throw ArgumentError.value(value, 'intervalValue', 'frecuencia inválida');
    }

    String? treatmentId;
    if (value != null && i.type.canRecur) {
      final name = _clean(i.product) ?? title;
      final next = addInterval(i.occurredAt, value, i.intervalUnit!);
      final existing = await _treatments.find(i.petId, i.type, name);
      final Treatment t;
      if (existing == null) {
        t = Treatment(
          id: _newId(),
          petId: i.petId,
          type: i.type,
          name: name,
          intervalValue: value,
          intervalUnit: i.intervalUnit!,
          nextDueDate: next,
          reminderDaysBefore: i.reminderDaysBefore,
          reminderEnabled: i.reminderEnabled,
        );
      } else {
        // Un evento más viejo (captura retroactiva) no debe atrasar la fecha.
        final keep = existing.nextDueDate.isAfter(next) && existing.active;
        t = existing.copyWith(
          intervalValue: value,
          intervalUnit: i.intervalUnit,
          nextDueDate: keep ? existing.nextDueDate : next,
          reminderDaysBefore: i.reminderDaysBefore,
          reminderEnabled: i.reminderEnabled,
          active: true,
        );
      }
      await _treatments.save(t);
      treatmentId = t.id;
    }

    final event = HealthEvent(
      id: _newId(),
      petId: i.petId,
      treatmentId: treatmentId,
      type: i.type,
      title: title,
      occurredAt: i.occurredAt,
      product: _clean(i.product),
      lot: _clean(i.lot),
      vetName: _clean(i.vetName),
      clinic: _clean(i.clinic),
      notes: _clean(i.notes),
      weightKg: i.weightKg,
      createdAt: _now(),
    );
    final attachments = [
      for (final a in i.attachments)
        Attachment(
          id: _newId(),
          eventId: event.id,
          relativePath: a.relativePath,
          kind: a.kind,
          label: a.label,
        ),
    ];
    await _events.save(event, attachments);

    if (i.weightKg != null) {
      await _weights.save(WeightEntry(
        id: _newId(),
        petId: i.petId,
        date: dateOnly(i.occurredAt),
        kg: i.weightKg!,
        note: title,
      ));
    }
    return event;
  }

  Future<HealthEvent> markDone(String treatmentId) async {
    final t = await _treatments.get(treatmentId);
    if (t == null) throw StateError('Tratamiento no encontrado: $treatmentId');
    return logEvent(LogEventInput(
      petId: t.petId,
      type: t.type,
      title: t.name,
      product: t.name,
      occurredAt: _now(),
      intervalValue: t.intervalValue,
      intervalUnit: t.intervalUnit,
      reminderEnabled: t.reminderEnabled,
      reminderDaysBefore: t.reminderDaysBefore,
    ));
  }
}
```

- [ ] **Step 4: Ejecutar y ver que pasa**

Run: `flutter test test/domain/health_service_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/domain/health_service.dart test/domain/health_service_test.dart
git commit -m "feat(domain): HealthService with treatment upsert and markDone"
```

---

### Task 5: Plan de recordatorios, preferencias y programador

**Files:**
- Create: `lib/domain/reminder_plan.dart`, `lib/services/app_prefs.dart`, `lib/services/reminder_scheduler.dart`, `lib/services/reminder_coordinator.dart`, `lib/services/local_notifications_scheduler.dart`
- Test: `test/helpers/fakes.dart`, `test/domain/reminder_plan_test.dart`, `test/services/app_prefs_test.dart`, `test/services/reminder_coordinator_test.dart`

**Interfaces:**
- Consumes: `Treatment`, `daysUntil`, repositorios (Task 3).
- Produces:
```dart
class PlannedReminder { final int id; final String treatmentId; final DateTime fireAt; final String title; final String body; }
int stableId(String s);   // FNV-1a, no negativo
List<PlannedReminder> planReminders({required Iterable<Treatment> treatments, required Map<String,String> petNames,
  required DateTime now, int hour = 9, int minute = 0, int max = 60});
abstract class ReminderScheduler { Future<void> replaceAll(List<PlannedReminder>); Future<bool> hasPermission(); Future<bool> requestPermission(); }
class AppPrefs {
  static Future<AppPrefs> load(); AppPrefs(SharedPreferences p);
  bool get lockEnabled;           Future<void> setLockEnabled(bool v);
  int get reminderHour;           int get reminderMinute;   Future<void> setReminderTime(int hour, int minute);  // defaults 9:00
  int get reminderDaysBefore;     Future<void> setReminderDaysBefore(int d);                                     // default 3
  DateTime? get lastBackupAt;     Future<void> setLastBackupAt(DateTime d);
}
class ReminderCoordinator { ReminderCoordinator({required PetRepository pets, required TreatmentRepository treatments,
  required ReminderScheduler scheduler, required AppPrefs prefs, required DateTime Function() now}); Future<void> sync(); }
class LocalNotificationsScheduler implements ReminderScheduler { Future<void> init(); }
```

- [ ] **Step 1: Pruebas que fallan**

`test/helpers/fakes.dart`:
```dart
import 'package:huellitas/domain/reminder_plan.dart';
import 'package:huellitas/services/reminder_scheduler.dart';

class FakeScheduler implements ReminderScheduler {
  List<PlannedReminder> last = const [];
  int syncCount = 0;
  bool permission = true;

  @override
  Future<void> replaceAll(List<PlannedReminder> reminders) async {
    last = reminders;
    syncCount++;
  }

  @override
  Future<bool> hasPermission() async => permission;

  @override
  Future<bool> requestPermission() async {
    permission = true;
    return true;
  }
}
```

`test/domain/reminder_plan_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/domain/reminder_plan.dart';

import '../helpers/samples.dart';

void main() {
  final names = {'p1': 'Toby'};

  test('avisa a las 9:00 locales, 3 días antes', () {
    final plan = planReminders(
      treatments: [sampleTreatment(nextDue: DateTime.utc(2024, 10, 29))],
      petNames: names,
      now: DateTime(2024, 10, 20, 8),
    );
    expect(plan.single.fireAt, DateTime(2024, 10, 26, 9));
    expect(plan.single.title, 'Antirrábica · Toby');
    expect(plan.single.body, 'Vence en 3 días');
  });

  test('si el aviso anticipado ya pasó pero el vencimiento no, avisa el día de vencimiento', () {
    final plan = planReminders(
      treatments: [sampleTreatment(nextDue: DateTime.utc(2024, 10, 29))],
      petNames: names,
      now: DateTime(2024, 10, 27, 10),
    );
    expect(plan.single.fireAt, DateTime(2024, 10, 29, 9));
    expect(plan.single.body, 'Toca hoy');
  });

  test('atrasada o ya pasada la hora del día de vencimiento: no programa nada', () {
    final due = sampleTreatment(nextDue: DateTime.utc(2024, 10, 29));
    expect(planReminders(treatments: [due], petNames: names, now: DateTime(2024, 10, 29, 9, 30)), isEmpty);
    expect(planReminders(treatments: [due], petNames: names, now: DateTime(2024, 11, 5)), isEmpty);
  });

  test('omite inactivos, sin recordatorio y mascotas archivadas (ausentes del mapa)', () {
    final now = DateTime(2024, 10, 20);
    expect(planReminders(treatments: [sampleTreatment(active: false)], petNames: names, now: now), isEmpty);
    expect(planReminders(treatments: [sampleTreatment(reminderEnabled: false)], petNames: names, now: now), isEmpty);
    expect(planReminders(treatments: [sampleTreatment(petId: 'archivada')], petNames: names, now: now), isEmpty);
  });

  test('respeta hora y minuto configurados', () {
    final plan = planReminders(
      treatments: [sampleTreatment(nextDue: DateTime.utc(2024, 10, 29))],
      petNames: names,
      now: DateTime(2024, 10, 20),
      hour: 18,
      minute: 30,
    );
    expect(plan.single.fireAt, DateTime(2024, 10, 26, 18, 30));
  });

  test('máximo 60, conserva los más próximos y ordena por fecha', () {
    final list = [
      for (var i = 0; i < 70; i++)
        sampleTreatment(id: 't$i', nextDue: DateTime.utc(2025, 1, 1).add(Duration(days: i))),
    ];
    final plan = planReminders(treatments: list.reversed, petNames: names, now: DateTime(2024, 12, 1));
    expect(plan.length, 60);
    expect(plan.first.treatmentId, 't0');
    expect(plan.last.treatmentId, 't59');
  });

  test('el aviso sale a las 9:00 locales también en un cambio de horario (TZ=America/New_York)', () {
    final plan = planReminders(
      treatments: [sampleTreatment(nextDue: DateTime.utc(2025, 3, 10), reminderDaysBefore: 1)],
      petNames: names,
      now: DateTime(2025, 3, 1),
    );
    expect(plan.single.fireAt.hour, 9);
    expect(plan.single.fireAt.day, 9);
  });

  test('stableId es determinista, no negativo y distinto entre ids', () {
    expect(stableId('abc'), stableId('abc'));
    expect(stableId('abc'), isNot(stableId('abd')));
    expect(stableId('cualquier-uuid-largo-1234'), greaterThanOrEqualTo(0));
  });
}
```

`test/services/app_prefs_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/services/app_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('valores por defecto', () async {
    final p = await AppPrefs.load();
    expect(p.lockEnabled, isFalse);
    expect(p.reminderHour, 9);
    expect(p.reminderMinute, 0);
    expect(p.reminderDaysBefore, 3);
    expect(p.lastBackupAt, isNull);
  });

  test('guarda y lee', () async {
    final p = await AppPrefs.load();
    await p.setLockEnabled(true);
    await p.setReminderTime(18, 30);
    await p.setReminderDaysBefore(7);
    await p.setLastBackupAt(DateTime(2024, 10, 2, 12));
    expect(p.lockEnabled, isTrue);
    expect(p.reminderHour, 18);
    expect(p.reminderMinute, 30);
    expect(p.reminderDaysBefore, 7);
    expect(p.lastBackupAt, DateTime(2024, 10, 2, 12));
  });
}
```

`test/services/reminder_coordinator_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/data/database.dart';
import 'package:huellitas/data/drift_repositories.dart';
import 'package:huellitas/services/app_prefs.dart';
import 'package:huellitas/services/reminder_coordinator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fakes.dart';
import '../helpers/samples.dart';

void main() {
  late AppDatabase db;
  late FakeScheduler scheduler;
  late ReminderCoordinator coordinator;
  late DriftPetRepository pets;
  late DriftTreatmentRepository treatments;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.memory();
    pets = DriftPetRepository(db);
    treatments = DriftTreatmentRepository(db);
    scheduler = FakeScheduler();
    coordinator = ReminderCoordinator(
      pets: pets,
      treatments: treatments,
      scheduler: scheduler,
      prefs: await AppPrefs.load(),
      now: () => DateTime(2024, 10, 20, 8),
    );
  });
  tearDown(() => db.close());

  test('programa el siguiente vencimiento de cada tratamiento activo', () async {
    await pets.save(samplePet());
    await treatments.save(sampleTreatment());
    await treatments.save(sampleTreatment(id: 't2', name: 'NexGard', nextDue: DateTime.utc(2024, 11, 5)));
    await coordinator.sync();
    expect(scheduler.last.map((r) => r.treatmentId), ['t1', 't2']);
  });

  test('una mascota archivada deja de generar avisos', () async {
    await pets.save(samplePet());
    await treatments.save(sampleTreatment());
    await coordinator.sync();
    expect(scheduler.last.length, 1);

    await pets.archive('p1');
    await coordinator.sync();
    expect(scheduler.last, isEmpty);
  });
}
```

- [ ] **Step 2: Ejecutar y ver que fallan**

Run: `flutter test test/domain/reminder_plan_test.dart test/services`
Expected: FAIL (archivos inexistentes)

- [ ] **Step 3: Implementar el plan puro**

`lib/domain/reminder_plan.dart`:
```dart
import 'dates.dart';
import 'models.dart';

class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.treatmentId,
    required this.fireAt,
    required this.title,
    required this.body,
  });

  final int id;
  final String treatmentId;
  final DateTime fireAt; // hora local
  final String title;
  final String body;
}

/// FNV-1a de 32 bits. `String.hashCode` no es estable entre ejecuciones.
int stableId(String s) {
  var h = 0x811c9dc5;
  for (final c in s.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return h & 0x7FFFFFFF;
}

/// Un aviso por tratamiento activo (su siguiente vencimiento). iOS permite 64
/// pendientes; se devuelven como máximo [max], los más próximos.
List<PlannedReminder> planReminders({
  required Iterable<Treatment> treatments,
  required Map<String, String> petNames,
  required DateTime now,
  int hour = 9,
  int minute = 0,
  int max = 60,
}) {
  DateTime at(DateTime day) => DateTime(day.year, day.month, day.day, hour, minute);

  final out = <PlannedReminder>[];
  for (final t in treatments) {
    if (!t.active || !t.reminderEnabled) continue;
    final pet = petNames[t.petId];
    if (pet == null) continue; // mascota archivada o inexistente

    final due = t.nextDueDate;
    final early = at(DateTime.utc(due.year, due.month, due.day - t.reminderDaysBefore));
    final onDue = at(due);
    final DateTime fireAt;
    if (early.isAfter(now)) {
      fireAt = early;
    } else if (onDue.isAfter(now)) {
      fireAt = onDue;
    } else {
      continue;
    }

    final days = daysUntil(due, fireAt);
    out.add(PlannedReminder(
      id: stableId(t.id),
      treatmentId: t.id,
      fireAt: fireAt,
      title: '${t.name} · $pet',
      body: days <= 0 ? 'Toca hoy' : 'Vence en $days ${days == 1 ? 'día' : 'días'}',
    ));
  }
  out.sort((a, b) => a.fireAt.compareTo(b.fireAt));
  return out.length > max ? out.sublist(0, max) : out;
}
```

- [ ] **Step 4: Preferencias, interfaz y coordinador**

`lib/services/app_prefs.dart`:
```dart
import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs {
  AppPrefs(this._p);
  final SharedPreferences _p;

  static Future<AppPrefs> load() async => AppPrefs(await SharedPreferences.getInstance());

  bool get lockEnabled => _p.getBool('lockEnabled') ?? false;
  Future<void> setLockEnabled(bool v) => _p.setBool('lockEnabled', v);

  int get reminderHour => _p.getInt('reminderHour') ?? 9;
  int get reminderMinute => _p.getInt('reminderMinute') ?? 0;
  Future<void> setReminderTime(int hour, int minute) async {
    await _p.setInt('reminderHour', hour);
    await _p.setInt('reminderMinute', minute);
  }

  int get reminderDaysBefore => _p.getInt('reminderDaysBefore') ?? 3;
  Future<void> setReminderDaysBefore(int d) => _p.setInt('reminderDaysBefore', d);

  DateTime? get lastBackupAt {
    final ms = _p.getInt('lastBackupAt');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setLastBackupAt(DateTime d) => _p.setInt('lastBackupAt', d.millisecondsSinceEpoch);
}
```

`lib/services/reminder_scheduler.dart`:
```dart
import '../domain/reminder_plan.dart';

abstract class ReminderScheduler {
  /// Cancela todo lo programado y programa [reminders].
  Future<void> replaceAll(List<PlannedReminder> reminders);
  Future<bool> hasPermission();
  Future<bool> requestPermission();
}
```

`lib/services/reminder_coordinator.dart`:
```dart
import '../domain/reminder_plan.dart';
import '../domain/repositories.dart';
import 'app_prefs.dart';
import 'reminder_scheduler.dart';

class ReminderCoordinator {
  ReminderCoordinator({
    required PetRepository pets,
    required TreatmentRepository treatments,
    required ReminderScheduler scheduler,
    required AppPrefs prefs,
    required DateTime Function() now,
  })  : _pets = pets,
        _treatments = treatments,
        _scheduler = scheduler,
        _prefs = prefs,
        _now = now;

  final PetRepository _pets;
  final TreatmentRepository _treatments;
  final ReminderScheduler _scheduler;
  final AppPrefs _prefs;
  final DateTime Function() _now;

  /// Recalcula y reprograma todos los avisos. Llamar al abrir la app y tras
  /// cualquier cambio en mascotas, tratamientos o ajustes de recordatorio.
  Future<void> sync() async {
    final pets = await _pets.all();
    final names = {for (final p in pets) if (!p.archived) p.id: p.name};
    final plan = planReminders(
      treatments: await _treatments.active(),
      petNames: names,
      now: _now(),
      hour: _prefs.reminderHour,
      minute: _prefs.reminderMinute,
    );
    await _scheduler.replaceAll(plan);
  }
}
```

- [ ] **Step 5: Adaptador de notificaciones locales** **[API]**

`lib/services/local_notifications_scheduler.dart`:
```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/reminder_plan.dart';
import 'reminder_scheduler.dart';

/// Notificaciones locales. Se usa programación inexacta (`inexactAllowWhileIdle`)
/// a propósito: no requiere el permiso de alarmas exactas en Android y para un
/// aviso diario de las 9:00 unos minutos de diferencia no importan.
class LocalNotificationsScheduler implements ReminderScheduler {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tzdata.initializeTimeZones();
    // [API] en versiones recientes flutter_timezone devuelve un objeto con
    // `.identifier` en vez de un String.
    final name = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(name));
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  @override
  Future<void> replaceAll(List<PlannedReminder> reminders) async {
    await _plugin.cancelAll();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'treatments',
        'Recordatorios de salud',
        channelDescription: 'Avisos de vacunas, desparasitación y antipulgas',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    for (final r in reminders) {
      await _plugin.zonedSchedule(
        r.id,
        r.title,
        r.body,
        tz.TZDateTime.from(r.fireAt, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  @override
  Future<bool> hasPermission() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final o = await ios.checkPermissions();
      return o?.isEnabled ?? false;
    }
    final android =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await android?.areNotificationsEnabled() ?? true;
  }

  @override
  Future<bool> requestPermission() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    final android =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? true;
  }
}
```

- [ ] **Step 6: Ejecutar y ver que pasan**

Run: `flutter test test/domain/reminder_plan_test.dart test/services && TZ=America/New_York flutter test test/domain/reminder_plan_test.dart`
Expected: PASS (ambas). `flutter analyze` sin errores (si el adaptador marca diferencias de API, ajustarlas según el README instalado).

- [ ] **Step 7: Commit**

```bash
git add lib test
git commit -m "feat: reminder planning, prefs, coordinator and local notifications adapter"
```

---

### Task 6: Almacén de adjuntos (fotos comprimidas)

**Files:**
- Create: `lib/services/attachment_store.dart`
- Test: `test/services/attachment_store_test.dart`

**Interfaces:**
- Produces:
```dart
class AttachmentException implements Exception { const AttachmentException(this.message); final String message; }
typedef CompressFn = Future<void> Function(File source, String targetPath);
class AttachmentStore {
  AttachmentStore({required Directory root, required String Function() newId, CompressFn? compress});
  Future<String> importImage(File source);   // -> 'attachments/<id>.jpg' (comprimida)
  Future<String> importPdf(File source);     // -> 'attachments/<id>.pdf' (copia)
  File fileFor(String relativePath);
  Future<void> delete(String relativePath);  // no falla si no existe
}
```

- [ ] **Step 1: Prueba que falla**

`test/services/attachment_store_test.dart`:
```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/services/attachment_store.dart';

void main() {
  late Directory root;
  late File source;
  var n = 0;

  setUp(() {
    n = 0;
    root = Directory.systemTemp.createTempSync('huellitas_att_');
    source = File('${root.path}/origen.jpg')..writeAsStringSync('foto original grande');
  });
  tearDown(() => root.deleteSync(recursive: true));

  AttachmentStore store({CompressFn? compress}) => AttachmentStore(
        root: root,
        newId: () => 'id${n++}',
        compress: compress ?? (src, target) async => File(target).writeAsStringSync('comprimida'),
      );

  test('importImage guarda la versión comprimida bajo attachments/ y devuelve ruta relativa', () async {
    final rel = await store().importImage(source);
    expect(rel, 'attachments/id0.jpg');
    expect(File('${root.path}/$rel').readAsStringSync(), 'comprimida');
  });

  test('si la compresión falla lanza AttachmentException y no deja archivo', () async {
    final s = store(compress: (_, __) async => throw const AttachmentException('x'));
    await expectLater(s.importImage(source), throwsA(isA<AttachmentException>()));
    expect(File('${root.path}/attachments/id0.jpg').existsSync(), isFalse);
  });

  test('importPdf copia el archivo', () async {
    final pdf = File('${root.path}/r.pdf')..writeAsStringSync('%PDF');
    final rel = await store().importPdf(pdf);
    expect(rel, 'attachments/id0.pdf');
    expect(File('${root.path}/$rel').readAsStringSync(), '%PDF');
  });

  test('delete borra y no falla si no existe', () async {
    final s = store();
    final rel = await s.importImage(source);
    await s.delete(rel);
    expect(s.fileFor(rel).existsSync(), isFalse);
    await s.delete(rel); // no lanza
  });
}
```

- [ ] **Step 2: Ejecutar y ver que falla**

Run: `flutter test test/services/attachment_store_test.dart`
Expected: FAIL (archivo inexistente)

- [ ] **Step 3: Implementar** **[API]**

`lib/services/attachment_store.dart`:
```dart
import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;

class AttachmentException implements Exception {
  const AttachmentException(this.message);
  final String message;
  @override
  String toString() => message;
}

typedef CompressFn = Future<void> Function(File source, String targetPath);

class AttachmentStore {
  AttachmentStore({
    required this.root,
    required String Function() newId,
    CompressFn? compress,
  })  : _newId = newId,
        _compress = compress ?? _defaultCompress;

  /// Carpeta de documentos de la app; los adjuntos viven en `root/attachments`.
  final Directory root;
  final String Function() _newId;
  final CompressFn _compress;

  Future<String> importImage(File source) async {
    final rel = p.posix.join('attachments', '${_newId()}.jpg');
    final target = fileFor(rel);
    await target.parent.create(recursive: true);
    try {
      await _compress(source, target.path);
    } catch (e) {
      await delete(rel);
      if (e is AttachmentException) rethrow;
      throw const AttachmentException('No se pudo guardar la foto');
    }
    return rel;
  }

  Future<String> importPdf(File source) async {
    final rel = p.posix.join('attachments', '${_newId()}.pdf');
    final target = fileFor(rel);
    await target.parent.create(recursive: true);
    await source.copy(target.path);
    return rel;
  }

  File fileFor(String relativePath) => File(p.join(root.path, relativePath));

  Future<void> delete(String relativePath) async {
    final f = fileFor(relativePath);
    if (await f.exists()) await f.delete();
  }
}

Future<void> _defaultCompress(File source, String targetPath) async {
  // [API] el tipo de retorno (File/XFile) cambia entre versiones.
  final result = await FlutterImageCompress.compressAndGetFile(
    source.absolute.path,
    targetPath,
    minWidth: 1600,
    minHeight: 1600,
    quality: 80,
    format: CompressFormat.jpeg,
  );
  if (result == null) throw const AttachmentException('No se pudo comprimir la imagen');
}
```

- [ ] **Step 4: Ejecutar y ver que pasa**

Run: `flutter test test/services/attachment_store_test.dart && flutter analyze`
Expected: PASS y sin problemas.

- [ ] **Step 5: Commit**

```bash
git add lib/services/attachment_store.dart test/services/attachment_store_test.dart
git commit -m "feat(services): attachment store with image compression"
```

---

### Task 7: Respaldo (exportar e importar `.zip`)

**Files:**
- Create: `lib/services/backup_codec.dart`, `lib/services/backup_service.dart`
- Test: `test/services/backup_service_test.dart`

**Interfaces:**
- Consumes: `BackupStore`, `BackupData` (Task 3), modelos.
- Produces:
```dart
const int kBackupSchemaVersion = 1;
Map<String,dynamic> backupToJson(BackupData d, {required int schemaVersion, required DateTime exportedAt});
BackupData backupFromJson(Map<String,dynamic> j);
class BackupException implements Exception { const BackupException(this.message); final String message; }
class BackupSummary { final int pets; final int events; final int attachments; }
class PreparedBackup { final BackupData data; final Directory tempDir; final BackupSummary summary; }
class BackupService {
  BackupService({required BackupStore store, required Directory root, required DateTime Function() now, int appSchemaVersion = kBackupSchemaVersion});
  Future<File> export(Directory outDir);                 // outDir/huellitas-AAAA-MM-DD.zip
  Future<PreparedBackup> prepare(File zip);              // valida y extrae a root/.import_tmp; BackupException si es inválido
  Future<void> commit(PreparedBackup prepared);          // reemplaza todo de forma atómica
  Future<void> discard(PreparedBackup prepared);
}
```

- [ ] **Step 1: Escribir las pruebas que fallan**

`test/services/backup_service_test.dart`:
```dart
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/data/database.dart';
import 'package:huellitas/data/drift_backup_store.dart';
import 'package:huellitas/domain/backup_data.dart';
import 'package:huellitas/services/backup_codec.dart';
import 'package:huellitas/services/backup_service.dart';

import '../helpers/samples.dart';

class ThrowingStore extends DriftBackupStore {
  ThrowingStore(super.db);
  @override
  Future<void> replaceAll(BackupData data) async => throw StateError('falla simulada');
}

void main() {
  late AppDatabase dbA;
  late AppDatabase dbB;
  late Directory rootA;
  late Directory rootB;
  late Directory out;
  final now = DateTime(2024, 10, 2, 12);

  BackupService serviceFor(AppDatabase db, Directory root, {DriftBackupStore? store}) => BackupService(
        store: store ?? DriftBackupStore(db),
        root: root,
        now: () => now,
      );

  String canonical(BackupData d) => jsonEncode(backupToJson(d, schemaVersion: 1, exportedAt: now));

  Future<void> seed() async {
    File('${rootA.path}/attachments/pet1.jpg')
      ..createSync(recursive: true)
      ..writeAsStringSync('foto-mascota');
    File('${rootA.path}/attachments/a1.jpg').writeAsStringSync('foto-carnet');
    await DriftBackupStore(dbA).replaceAll(BackupData(
      pets: [samplePet(photoPath: 'attachments/pet1.jpg')],
      weights: const [],
      treatments: [sampleTreatment()],
      events: [sampleEvent(treatmentId: 't1')],
      attachments: [sampleAttachment()],
    ));
  }

  File zipWith(Map<String, List<int>> files, String name) {
    final a = Archive();
    files.forEach((path, bytes) => a.addFile(ArchiveFile(path, bytes.length, bytes)));
    final f = File('${out.path}/$name')..writeAsBytesSync(ZipEncoder().encode(a)!);
    return f;
  }

  Map<String, dynamic> json({int version = 1, List<Map<String, dynamic>>? attachments, String? petPhoto}) {
    final data = BackupData(
      pets: [samplePet(photoPath: petPhoto)],
      weights: const [],
      treatments: const [],
      events: [sampleEvent()],
      attachments: const [],
    );
    final j = backupToJson(data, schemaVersion: version, exportedAt: now);
    if (attachments != null) j['attachments'] = attachments;
    return j;
  }

  setUp(() {
    dbA = AppDatabase.memory();
    dbB = AppDatabase.memory();
    rootA = Directory.systemTemp.createTempSync('huellitas_a_');
    rootB = Directory.systemTemp.createTempSync('huellitas_b_');
    out = Directory.systemTemp.createTempSync('huellitas_out_');
  });
  tearDown(() async {
    await dbA.close();
    await dbB.close();
    for (final d in [rootA, rootB, out]) {
      d.deleteSync(recursive: true);
    }
  });

  test('exportar e importar en otro teléfono devuelve los mismos datos y archivos', () async {
    await seed();
    final zip = await serviceFor(dbA, rootA).export(out);
    expect(zip.path.endsWith('huellitas-2024-10-02.zip'), isTrue);

    final b = serviceFor(dbB, rootB);
    final prepared = await b.prepare(zip);
    expect(prepared.summary.pets, 1);
    expect(prepared.summary.events, 1);
    await b.commit(prepared);

    final a = await DriftBackupStore(dbA).readAll();
    final c = await DriftBackupStore(dbB).readAll();
    expect(canonical(c), canonical(a));
    expect(File('${rootB.path}/attachments/a1.jpg').readAsStringSync(), 'foto-carnet');
    expect(File('${rootB.path}/attachments/pet1.jpg').readAsStringSync(), 'foto-mascota');
    expect(Directory('${rootB.path}/.import_tmp').existsSync(), isFalse);
  });

  test('importar reemplaza los datos y archivos anteriores', () async {
    await seed();
    final zip = await serviceFor(dbA, rootA).export(out);

    File('${rootB.path}/attachments/viejo.jpg')
      ..createSync(recursive: true)
      ..writeAsStringSync('viejo');
    await DriftBackupStore(dbB).replaceAll(BackupData(
      pets: [samplePet(id: 'otra', name: 'Otra')],
      weights: const [],
      treatments: const [],
      events: const [],
      attachments: const [],
    ));

    final b = serviceFor(dbB, rootB);
    await b.commit(await b.prepare(zip));
    expect((await DriftBackupStore(dbB).readAll()).pets.map((p) => p.id), ['p1']);
    expect(File('${rootB.path}/attachments/viejo.jpg').existsSync(), isFalse);
    expect(Directory('${rootB.path}/attachments.old').existsSync(), isFalse);
  });

  test('un respaldo de versión más nueva se rechaza', () async {
    final zip = zipWith({'backup.json': utf8.encode(jsonEncode(json(version: 99)))}, 'nuevo.zip');
    await expectLater(serviceFor(dbB, rootB).prepare(zip), throwsA(isA<BackupException>()));
  });

  test('un archivo que no es zip o sin backup.json se rechaza', () async {
    final basura = File('${out.path}/basura.zip')..writeAsStringSync('no soy un zip');
    await expectLater(serviceFor(dbB, rootB).prepare(basura), throwsA(isA<BackupException>()));
    final sinJson = zipWith({'otra.txt': utf8.encode('x')}, 'sin.zip');
    await expectLater(serviceFor(dbB, rootB).prepare(sinJson), throwsA(isA<BackupException>()));
  });

  test('si falta una foto referenciada se rechaza y no se tocan los datos', () async {
    await DriftBackupStore(dbB).replaceAll(BackupData(
      pets: [samplePet(id: 'intacta')],
      weights: const [],
      treatments: const [],
      events: const [],
      attachments: const [],
    ));
    final zip = zipWith({
      'backup.json': utf8.encode(jsonEncode(json(petPhoto: 'attachments/falta.jpg'))),
    }, 'falta.zip');
    await expectLater(serviceFor(dbB, rootB).prepare(zip), throwsA(isA<BackupException>()));
    expect((await DriftBackupStore(dbB).readAll()).pets.single.id, 'intacta');
  });

  test('rutas con ../ o absolutas se rechazan (zip-slip)', () async {
    for (final bad in ['../evil.jpg', 'attachments/../../evil.jpg', '/etc/passwd']) {
      final zip = zipWith({
        'backup.json': utf8.encode(jsonEncode(json(petPhoto: bad))),
        bad: utf8.encode('x'),
      }, 'slip.zip');
      await expectLater(serviceFor(dbB, rootB).prepare(zip), throwsA(isA<BackupException>()), reason: bad);
    }
    expect(File('${rootB.path}/../evil.jpg').existsSync(), isFalse);
  });

  test('si falla la escritura en la BD se restauran los archivos anteriores', () async {
    await seed();
    final zip = await serviceFor(dbA, rootA).export(out);

    File('${rootB.path}/attachments/viejo.jpg')
      ..createSync(recursive: true)
      ..writeAsStringSync('viejo');
    final b = serviceFor(dbB, rootB, store: ThrowingStore(dbB));
    final prepared = await b.prepare(zip);
    await expectLater(b.commit(prepared), throwsA(isA<BackupException>()));
    expect(File('${rootB.path}/attachments/viejo.jpg').readAsStringSync(), 'viejo');
    expect(File('${rootB.path}/attachments/a1.jpg').existsSync(), isFalse);
  });
}
```

- [ ] **Step 2: Ejecutar y ver que falla**

Run: `flutter test test/services/backup_service_test.dart`
Expected: FAIL (archivos inexistentes)

- [ ] **Step 3: Codec JSON**

`lib/services/backup_codec.dart`:
```dart
import '../domain/backup_data.dart';
import '../domain/enums.dart';
import '../domain/models.dart';

const int kBackupSchemaVersion = 1;

// Instantes se guardan en UTC y se leen en hora local; los días calendario se
// guardan y leen como medianoche UTC.
String _iso(DateTime d) => d.toUtc().toIso8601String();
DateTime _instant(Object? v) => DateTime.parse(v as String).toLocal();
DateTime _day(Object? v) => DateTime.parse(v as String).toUtc();
T? _enumOrNull<T extends Enum>(List<T> values, Object? v) =>
    v == null ? null : values.byName(v as String);
double? _doubleOrNull(Object? v) => (v as num?)?.toDouble();

Map<String, dynamic> backupToJson(
  BackupData d, {
  required int schemaVersion,
  required DateTime exportedAt,
}) =>
    {
      'schemaVersion': schemaVersion,
      'exportedAt': _iso(exportedAt),
      'pets': [
        for (final p in d.pets)
          {
            'id': p.id,
            'name': p.name,
            'species': p.species.name,
            'breed': p.breed,
            'sex': p.sex?.name,
            'neutered': p.neutered,
            'birthDate': p.birthDate == null ? null : _iso(p.birthDate!),
            'microchip': p.microchip,
            'photoPath': p.photoPath,
            'allergiesNotes': p.allergiesNotes,
            'vetName': p.vetName,
            'vetClinic': p.vetClinic,
            'vetPhone': p.vetPhone,
            'createdAt': _iso(p.createdAt),
            'archived': p.archived,
          },
      ],
      'weights': [
        for (final w in d.weights)
          {'id': w.id, 'petId': w.petId, 'date': _iso(w.date), 'kg': w.kg, 'note': w.note},
      ],
      'treatments': [
        for (final t in d.treatments)
          {
            'id': t.id,
            'petId': t.petId,
            'type': t.type.name,
            'name': t.name,
            'intervalValue': t.intervalValue,
            'intervalUnit': t.intervalUnit.name,
            'nextDueDate': _iso(t.nextDueDate),
            'reminderDaysBefore': t.reminderDaysBefore,
            'reminderEnabled': t.reminderEnabled,
            'active': t.active,
          },
      ],
      'events': [
        for (final e in d.events)
          {
            'id': e.id,
            'petId': e.petId,
            'treatmentId': e.treatmentId,
            'type': e.type.name,
            'title': e.title,
            'occurredAt': _iso(e.occurredAt),
            'product': e.product,
            'lot': e.lot,
            'vetName': e.vetName,
            'clinic': e.clinic,
            'notes': e.notes,
            'weightKg': e.weightKg,
            'createdAt': _iso(e.createdAt),
          },
      ],
      'attachments': [
        for (final a in d.attachments)
          {
            'id': a.id,
            'eventId': a.eventId,
            'relativePath': a.relativePath,
            'kind': a.kind.name,
            'label': a.label,
          },
      ],
    };

BackupData backupFromJson(Map<String, dynamic> j) {
  List<Map<String, dynamic>> list(String key) =>
      (j[key] as List).cast<Map<String, dynamic>>();

  return BackupData(
    pets: [
      for (final m in list('pets'))
        Pet(
          id: m['id'] as String,
          name: m['name'] as String,
          species: PetSpecies.values.byName(m['species'] as String),
          breed: m['breed'] as String?,
          sex: _enumOrNull(PetSex.values, m['sex']),
          neutered: m['neutered'] as bool,
          birthDate: m['birthDate'] == null ? null : _day(m['birthDate']),
          microchip: m['microchip'] as String?,
          photoPath: m['photoPath'] as String?,
          allergiesNotes: m['allergiesNotes'] as String?,
          vetName: m['vetName'] as String?,
          vetClinic: m['vetClinic'] as String?,
          vetPhone: m['vetPhone'] as String?,
          createdAt: _instant(m['createdAt']),
          archived: m['archived'] as bool,
        ),
    ],
    weights: [
      for (final m in list('weights'))
        WeightEntry(
          id: m['id'] as String,
          petId: m['petId'] as String,
          date: _day(m['date']),
          kg: (m['kg'] as num).toDouble(),
          note: m['note'] as String?,
        ),
    ],
    treatments: [
      for (final m in list('treatments'))
        Treatment(
          id: m['id'] as String,
          petId: m['petId'] as String,
          type: EventType.values.byName(m['type'] as String),
          name: m['name'] as String,
          intervalValue: m['intervalValue'] as int,
          intervalUnit: IntervalUnit.values.byName(m['intervalUnit'] as String),
          nextDueDate: _day(m['nextDueDate']),
          reminderDaysBefore: m['reminderDaysBefore'] as int,
          reminderEnabled: m['reminderEnabled'] as bool,
          active: m['active'] as bool,
        ),
    ],
    events: [
      for (final m in list('events'))
        HealthEvent(
          id: m['id'] as String,
          petId: m['petId'] as String,
          treatmentId: m['treatmentId'] as String?,
          type: EventType.values.byName(m['type'] as String),
          title: m['title'] as String,
          occurredAt: _instant(m['occurredAt']),
          product: m['product'] as String?,
          lot: m['lot'] as String?,
          vetName: m['vetName'] as String?,
          clinic: m['clinic'] as String?,
          notes: m['notes'] as String?,
          weightKg: _doubleOrNull(m['weightKg']),
          createdAt: _instant(m['createdAt']),
        ),
    ],
    attachments: [
      for (final m in list('attachments'))
        Attachment(
          id: m['id'] as String,
          eventId: m['eventId'] as String,
          relativePath: m['relativePath'] as String,
          kind: AttachmentKind.values.byName(m['kind'] as String),
          label: m['label'] as String?,
        ),
    ],
  );
}
```

- [ ] **Step 4: Servicio de respaldo** **[API]**

`lib/services/backup_service.dart`:
```dart
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../domain/backup_data.dart';
import '../domain/repositories.dart';
import 'backup_codec.dart';

export 'backup_codec.dart' show kBackupSchemaVersion;

class BackupException implements Exception {
  const BackupException(this.message);
  final String message;
  @override
  String toString() => message;
}

class BackupSummary {
  const BackupSummary({required this.pets, required this.events, required this.attachments});
  final int pets;
  final int events;
  final int attachments;
}

class PreparedBackup {
  const PreparedBackup({required this.data, required this.tempDir, required this.summary});
  final BackupData data;
  final Directory tempDir;
  final BackupSummary summary;
}

class BackupService {
  BackupService({
    required BackupStore store,
    required Directory root,
    required DateTime Function() now,
    int appSchemaVersion = kBackupSchemaVersion,
  })  : _store = store,
        _root = root,
        _now = now,
        _appSchemaVersion = appSchemaVersion;

  final BackupStore _store;
  final Directory _root;
  final DateTime Function() _now;
  final int _appSchemaVersion;

  Directory get _tmp => Directory(p.join(_root.path, '.import_tmp'));

  static bool _isSafe(String path) {
    final n = p.posix.normalize(path);
    return !p.posix.isAbsolute(n) &&
        n.startsWith('attachments/') &&
        !n.split('/').contains('..');
  }

  Set<String> _referencedPaths(BackupData d) => {
        for (final a in d.attachments) a.relativePath,
        for (final pet in d.pets)
          if (pet.photoPath != null) pet.photoPath!,
      };

  Future<File> export(Directory outDir) async {
    final data = await _store.readAll();
    final now = _now();
    final archive = Archive();

    final jsonBytes = utf8.encode(jsonEncode(
      backupToJson(data, schemaVersion: _appSchemaVersion, exportedAt: now),
    ));
    archive.addFile(ArchiveFile('backup.json', jsonBytes.length, jsonBytes));

    for (final rel in _referencedPaths(data)) {
      final f = File(p.join(_root.path, rel));
      if (await f.exists()) {
        final bytes = await f.readAsBytes();
        archive.addFile(ArchiveFile(rel, bytes.length, bytes));
      }
    }

    String two(int n) => n.toString().padLeft(2, '0');
    final name = 'huellitas-${now.year}-${two(now.month)}-${two(now.day)}.zip';
    await outDir.create(recursive: true);
    final file = File(p.join(outDir.path, name));
    await file.writeAsBytes(ZipEncoder().encode(archive)!);
    return file;
  }

  Future<PreparedBackup> prepare(File zip) async {
    const invalid = BackupException('El archivo no es un respaldo válido de Huellitas.');
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(await zip.readAsBytes());
    } catch (_) {
      throw invalid;
    }

    final jsonFile = archive.findFile('backup.json');
    if (jsonFile == null) throw invalid;

    final BackupData data;
    try {
      final map = jsonDecode(utf8.decode(jsonFile.content as List<int>)) as Map<String, dynamic>;
      final version = map['schemaVersion'];
      if (version is! int) throw invalid;
      if (version > _appSchemaVersion) {
        throw const BackupException(
          'Este respaldo es de una versión más nueva de Huellitas. Actualiza la app e inténtalo de nuevo.',
        );
      }
      data = backupFromJson(map);
    } on BackupException {
      rethrow;
    } catch (_) {
      throw invalid;
    }

    final paths = _referencedPaths(data);
    for (final rel in paths) {
      if (!_isSafe(rel)) throw invalid;
      final f = archive.findFile(rel);
      if (f == null || !f.isFile) {
        throw BackupException('Al respaldo le falta un archivo ($rel).');
      }
    }

    final tmp = _tmp;
    if (await tmp.exists()) await tmp.delete(recursive: true);
    await tmp.create(recursive: true);
    try {
      for (final rel in paths) {
        final out = File(p.join(tmp.path, rel));
        await out.parent.create(recursive: true);
        await out.writeAsBytes(archive.findFile(rel)!.content as List<int>);
      }
    } catch (_) {
      await tmp.delete(recursive: true);
      throw const BackupException('No se pudo leer el respaldo.');
    }

    return PreparedBackup(
      data: data,
      tempDir: tmp,
      summary: BackupSummary(
        pets: data.pets.length,
        events: data.events.length,
        attachments: data.attachments.length,
      ),
    );
  }

  Future<void> commit(PreparedBackup prepared) async {
    final live = Directory(p.join(_root.path, 'attachments'));
    final old = Directory(p.join(_root.path, 'attachments.old'));
    final incoming = Directory(p.join(prepared.tempDir.path, 'attachments'));

    if (await old.exists()) await old.delete(recursive: true);
    final hadLive = await live.exists();
    if (hadLive) await live.rename(old.path);

    try {
      if (await incoming.exists()) {
        await incoming.rename(live.path);
      } else {
        await live.create(recursive: true);
      }
      await _store.replaceAll(prepared.data);
    } catch (_) {
      if (await live.exists()) await live.delete(recursive: true);
      if (hadLive) await old.rename(live.path);
      await discard(prepared);
      throw const BackupException('No se pudo restaurar el respaldo. Tus datos no cambiaron.');
    }

    if (await old.exists()) await old.delete(recursive: true);
    await discard(prepared);
  }

  Future<void> discard(PreparedBackup prepared) async {
    if (await prepared.tempDir.exists()) await prepared.tempDir.delete(recursive: true);
  }
}
```

- [ ] **Step 5: Ejecutar y ver que pasan**

Run: `flutter test test/services/backup_service_test.dart && TZ=America/Mexico_City flutter test test/services/backup_service_test.dart`
Expected: PASS (ambas). `flutter analyze` limpio (si `archive` reporta diferencias de API —`ZipEncoder().encode`, `findFile`, `content`— ajustar según su README).

- [ ] **Step 6: Commit**

```bash
git add lib/services test/services
git commit -m "feat(services): zip backup export/import with atomic restore"
```

---

### Task 8: PIN, tema, providers, navegación y arranque

**Files:**
- Create: `lib/services/pin_store.dart`, `lib/ui/theme.dart`, `lib/ui/widgets.dart`, `lib/ui/format.dart`, `lib/app/providers.dart`, `lib/app/router.dart`, `lib/app/app.dart`, `assets/google_fonts/` (fuentes)
- Modify: `lib/main.dart`, `pubspec.yaml`
- Test: `test/helpers/pump_app.dart`, `test/services/pin_store_test.dart`, `test/ui/app_shell_test.dart`

**Interfaces:**
- Consumes: todo lo anterior.
- Produces (usado por todas las pantallas):
```dart
// services/pin_store.dart
abstract class SecretStore { Future<String?> read(String key); Future<void> write(String key, String value); Future<void> delete(String key); }
class SecureSecretStore implements SecretStore {}
class PinStore { PinStore(SecretStore s); Future<bool> get hasPin; Future<void> setPin(String pin); /* 4 dígitos, ArgumentError si no */ Future<bool> verify(String pin); Future<void> clear(); }

// ui/theme.dart
class AppColors { static const canvas, card, primary, orange, orangeText, coral, ink, inkSoft, inkFaint, divider; }
ThemeData buildTheme({bool bundledFont = true});

// ui/widgets.dart
class AppCard extends StatelessWidget { AppCard({required Widget child, EdgeInsets padding, VoidCallback? onTap, Color? stripe}); }
class StatusChip extends StatelessWidget { StatusChip(String label, StatusKind kind); /* enum StatusKind { ok, soon, overdue } */ factory StatusChip.forDue(DueStatus s, String label); }
class SectionHeader extends StatelessWidget { SectionHeader(String title, {Widget? trailing}); }
class PetAvatar extends ConsumerWidget { PetAvatar({required Pet pet, double size = 48}); }

// ui/format.dart
String fmtDay(DateTime d);        // '29 oct 2024'
String fmtDateTime(DateTime d);   // '15 oct 2024 · 11:30 hrs'
IconData iconForType(EventType t);

// app/providers.dart  (nombres exactos)
databaseProvider, docsDirProvider, prefsProvider, schedulerProvider, secretStoreProvider,
clockProvider (DateTime Function()), idGeneratorProvider (String Function()),
petRepoProvider, treatmentRepoProvider, eventRepoProvider, weightRepoProvider, backupStoreProvider,
attachmentStoreProvider, healthServiceProvider, reminderCoordinatorProvider, backupServiceProvider, pinStoreProvider,
petsProvider (StreamProvider<List<Pet>>), activeTreatmentsProvider (StreamProvider<List<Treatment>>),
selectedPetIdProvider (NotifierProvider<SelectedPetId,String?> con .select(String?)),
currentPetProvider (Provider<Pet?>),
eventsForPetProvider / weightsForPetProvider (StreamProvider.family<…, String>)

// test/helpers/pump_app.dart
class TestEnv { AppDatabase db; FakeScheduler scheduler; AppPrefs prefs; Directory docs; DateTime now; List<Override> overrides; }
Future<TestEnv> createEnv({DateTime? now});
Future<void> pumpScreen(WidgetTester tester, TestEnv env, Widget screen);   // abre la pantalla en /screen; rutas desconocidas muestran 'NAV:<ruta>'
Future<T> runDb<T>(WidgetTester tester, Future<T> Function() f);            // envuelve tester.runAsync
```

- [ ] **Step 1: Prueba de PinStore que falla**

`test/services/pin_store_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/services/pin_store.dart';

class InMemorySecretStore implements SecretStore {
  final Map<String, String> data = {};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async => data[key] = value;
  @override
  Future<void> delete(String key) async => data.remove(key);
}

void main() {
  late InMemorySecretStore secrets;
  late PinStore pin;
  setUp(() {
    secrets = InMemorySecretStore();
    pin = PinStore(secrets);
  });

  test('sin PIN configurado: hasPin falso y verify falso', () async {
    expect(await pin.hasPin, isFalse);
    expect(await pin.verify('1234'), isFalse);
  });

  test('setPin y verify', () async {
    await pin.setPin('4821');
    expect(await pin.hasPin, isTrue);
    expect(await pin.verify('4821'), isTrue);
    expect(await pin.verify('4822'), isFalse);
  });

  test('no guarda el PIN en claro', () async {
    await pin.setPin('4821');
    expect(secrets.data.values.any((v) => v.contains('4821')), isFalse);
  });

  test('rechaza PIN que no sea de 4 dígitos', () {
    for (final bad in ['123', '12345', 'abcd', '12 4', '']) {
      expect(() => pin.setPin(bad), throwsArgumentError, reason: bad);
    }
  });

  test('clear elimina el PIN', () async {
    await pin.setPin('4821');
    await pin.clear();
    expect(await pin.hasPin, isFalse);
  });
}
```
Run: `flutter test test/services/pin_store_test.dart` → Expected: FAIL.

- [ ] **Step 2: Implementar PinStore**

`lib/services/pin_store.dart`:
```dart
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecureSecretStore implements SecretStore {
  const SecureSecretStore([this._storage = const FlutterSecureStorage()]);
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);
  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);
  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class PinStore {
  PinStore(this._secrets);
  final SecretStore _secrets;

  static final _fourDigits = RegExp(r'^\d{4}$');

  Future<bool> get hasPin async => (await _secrets.read('pin_hash')) != null;

  Future<void> setPin(String pin) async {
    if (!_fourDigits.hasMatch(pin)) {
      throw ArgumentError.value(pin, 'pin', 'debe tener 4 dígitos');
    }
    final salt = _newSalt();
    await _secrets.write('pin_salt', salt);
    await _secrets.write('pin_hash', _hash(salt, pin));
  }

  Future<bool> verify(String pin) async {
    final salt = await _secrets.read('pin_salt');
    final hash = await _secrets.read('pin_hash');
    if (salt == null || hash == null) return false;
    return _hash(salt, pin) == hash;
  }

  Future<void> clear() async {
    await _secrets.delete('pin_salt');
    await _secrets.delete('pin_hash');
  }

  static String _hash(String salt, String pin) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  static String _newSalt() {
    final r = Random.secure();
    return base64UrlEncode(List<int>.generate(16, (_) => r.nextInt(256)));
  }
}
```
Run: `flutter test test/services/pin_store_test.dart` → Expected: PASS.

- [ ] **Step 3: Fuente incluida en la app (funciona sin internet)**

1. Descargar *Plus Jakarta Sans* de `https://fonts.google.com/specimen/Plus+Jakarta+Sans` (botón «Get font»).
2. Copiar a `assets/google_fonts/` los archivos estáticos `PlusJakartaSans-Regular.ttf`, `PlusJakartaSans-Medium.ttf`, `PlusJakartaSans-SemiBold.ttf`, `PlusJakartaSans-Bold.ttf` (los nombres deben coincidir exactamente).
3. En `pubspec.yaml`, bajo `flutter:` agregar:
```yaml
  assets:
    - assets/google_fonts/
```

- [ ] **Step 4: Tema y widgets compartidos**

`lib/ui/theme.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const canvas = Color(0xFFFBF9F5);
  static const card = Color(0xFFFFFFFF);
  static const primary = Color(0xFF2BA38B);
  static const orange = Color(0xFFFF9F5A);
  static const orangeText = Color(0xFFD67430);
  static const coral = Color(0xFFFF5A5F);
  static const ink = Color(0xFF1D2A29);
  static const inkSoft = Color(0xFF6E7C7A);
  static const inkFaint = Color(0xFFA0ABA9);
  static const divider = Color(0xFFEAE6DE);
}

/// [bundledFont] = false en pruebas (evita buscar la fuente en los assets).
ThemeData buildTheme({bool bundledFont = true}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    surface: AppColors.canvas,
    error: AppColors.coral,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.canvas,
  );
  final text = bundledFont
      ? GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
      : base.textTheme;
  return base.copyWith(
    textTheme: text.apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.canvas,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.ink,
      elevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.canvas,
      indicatorColor: AppColors.primary.withValues(alpha: 0.12),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    ),
  );
}
```

`lib/ui/format.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/enums.dart';

String fmtDay(DateTime d) => DateFormat('d MMM y', 'es_MX').format(d);

String fmtDateTime(DateTime d) => DateFormat("d MMM y · HH:mm 'hrs'", 'es_MX').format(d);

IconData iconForType(EventType t) => switch (t) {
      EventType.vaccine => Icons.vaccines,
      EventType.deworming => Icons.medication,
      EventType.fleaTick => Icons.pest_control,
      EventType.illness => Icons.thermostat,
      EventType.checkup => Icons.medical_services,
    };
```

`lib/ui/widgets.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../domain/models.dart';
import '../domain/treatment_status.dart';
import 'theme.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.stripe,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? stripe;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: stripe == null
              ? content
              : IntrinsicHeight(
                  child: Row(children: [
                    Container(width: 4, color: stripe),
                    Expanded(child: content),
                  ]),
                ),
        ),
      ),
    );
  }
}

enum StatusKind { ok, soon, overdue }

class StatusChip extends StatelessWidget {
  const StatusChip(this.label, this.kind, {super.key});

  factory StatusChip.forDue(DueStatus s, String label, {Key? key}) => StatusChip(
        label,
        switch (s) {
          DueStatus.overdue => StatusKind.overdue,
          DueStatus.dueSoon => StatusKind.soon,
          DueStatus.upcoming => StatusKind.ok,
        },
        key: key,
      );

  final String label;
  final StatusKind kind;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (kind) {
      StatusKind.ok => (AppColors.primary, AppColors.primary),
      StatusKind.soon => (AppColors.orange, AppColors.orangeText),
      StatusKind.overdue => (AppColors.coral, AppColors.coral),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Row(children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
          if (trailing != null) trailing!,
        ]),
      );
}

class PetAvatar extends ConsumerWidget {
  const PetAvatar({super.key, required this.pet, this.size = 48});
  final Pet pet;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rel = pet.photoPath;
    final file = rel == null ? null : ref.watch(attachmentStoreProvider).fileFor(rel);
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: (file != null && file.existsSync())
            ? Image.file(file, fit: BoxFit.cover)
            : ColoredBox(
                color: AppColors.primary.withValues(alpha: 0.12),
                child: Icon(Icons.pets, color: AppColors.primary, size: size * 0.5),
              ),
      ),
    );
  }
}
```

- [ ] **Step 5: Providers**

`lib/app/providers.dart`:
```dart
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/database.dart';
import '../data/drift_backup_store.dart';
import '../data/drift_repositories.dart';
import '../domain/health_service.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';
import '../services/app_prefs.dart';
import '../services/attachment_store.dart';
import '../services/backup_service.dart';
import '../services/pin_store.dart';
import '../services/reminder_coordinator.dart';
import '../services/reminder_scheduler.dart';

// Se sobreescriben en main.dart (y en las pruebas).
final databaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError('override'));
final docsDirProvider = Provider<Directory>((ref) => throw UnimplementedError('override'));
final prefsProvider = Provider<AppPrefs>((ref) => throw UnimplementedError('override'));
final schedulerProvider = Provider<ReminderScheduler>((ref) => throw UnimplementedError('override'));

final secretStoreProvider = Provider<SecretStore>((ref) => const SecureSecretStore());
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
final idGeneratorProvider = Provider<String Function()>((ref) => () => const Uuid().v4());

final petRepoProvider =
    Provider<PetRepository>((ref) => DriftPetRepository(ref.watch(databaseProvider)));
final treatmentRepoProvider =
    Provider<TreatmentRepository>((ref) => DriftTreatmentRepository(ref.watch(databaseProvider)));
final eventRepoProvider =
    Provider<EventRepository>((ref) => DriftEventRepository(ref.watch(databaseProvider)));
final weightRepoProvider =
    Provider<WeightRepository>((ref) => DriftWeightRepository(ref.watch(databaseProvider)));
final backupStoreProvider =
    Provider<BackupStore>((ref) => DriftBackupStore(ref.watch(databaseProvider)));

final attachmentStoreProvider = Provider<AttachmentStore>((ref) => AttachmentStore(
      root: ref.watch(docsDirProvider),
      newId: ref.watch(idGeneratorProvider),
    ));

final healthServiceProvider = Provider<HealthService>((ref) => HealthService(
      events: ref.watch(eventRepoProvider),
      treatments: ref.watch(treatmentRepoProvider),
      weights: ref.watch(weightRepoProvider),
      now: ref.watch(clockProvider),
      newId: ref.watch(idGeneratorProvider),
    ));

final reminderCoordinatorProvider = Provider<ReminderCoordinator>((ref) => ReminderCoordinator(
      pets: ref.watch(petRepoProvider),
      treatments: ref.watch(treatmentRepoProvider),
      scheduler: ref.watch(schedulerProvider),
      prefs: ref.watch(prefsProvider),
      now: ref.watch(clockProvider),
    ));

final backupServiceProvider = Provider<BackupService>((ref) => BackupService(
      store: ref.watch(backupStoreProvider),
      root: ref.watch(docsDirProvider),
      now: ref.watch(clockProvider),
    ));

final pinStoreProvider = Provider<PinStore>((ref) => PinStore(ref.watch(secretStoreProvider)));

final petsProvider =
    StreamProvider<List<Pet>>((ref) => ref.watch(petRepoProvider).watchAll());

final activeTreatmentsProvider = StreamProvider<List<Treatment>>(
    (ref) => ref.watch(treatmentRepoProvider).watchActive());

class SelectedPetId extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? id) => state = id;
}

final selectedPetIdProvider = NotifierProvider<SelectedPetId, String?>(SelectedPetId.new);

/// La mascota seleccionada, o la primera si no hay selección válida.
final currentPetProvider = Provider<Pet?>((ref) {
  final pets = ref.watch(petsProvider).asData?.value ?? const <Pet>[];
  if (pets.isEmpty) return null;
  final id = ref.watch(selectedPetIdProvider);
  return pets.firstWhere((p) => p.id == id, orElse: () => pets.first);
});

final eventsForPetProvider = StreamProvider.family<List<HealthEvent>, String>(
    (ref, petId) => ref.watch(eventRepoProvider).watchForPet(petId));

final weightsForPetProvider = StreamProvider.family<List<WeightEntry>, String>(
    (ref, petId) => ref.watch(weightRepoProvider).watchForPet(petId));
```

- [ ] **Step 6: Navegación, app y arranque**

`lib/app/router.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Pantalla provisional; cada tarea de UI reemplaza la suya por la real.
class _Stub extends StatelessWidget {
  const _Stub(this.title);
  final String title;
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: Text(title)), body: Center(child: Text(title)));
}

GoRouter buildRouter({required String initialLocation}) => GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/onboarding',
          parentNavigatorKey: rootNavigatorKey,
          builder: (_, __) => const _Stub('Onboarding'),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => AppShell(shell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(path: '/home', builder: (_, __) => const _Stub('Inicio')),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/history', builder: (_, __) => const _Stub('Historial')),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/pets', builder: (_, __) => const _Stub('Mascotas')),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/settings', builder: (_, __) => const _Stub('Ajustes')),
            ]),
          ],
        ),
      ],
    );

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: shell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
            NavigationDestination(icon: Icon(Icons.event_note_outlined), selectedIcon: Icon(Icons.event_note), label: 'Historial'),
            NavigationDestination(icon: Icon(Icons.pets_outlined), selectedIcon: Icon(Icons.pets), label: 'Mascotas'),
            NavigationDestination(icon: Icon(Icons.tune), label: 'Ajustes'),
          ],
        ),
      );
}
```

`lib/app/app.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ui/theme.dart';
import 'providers.dart';
import 'router.dart';

class HuellitasApp extends ConsumerStatefulWidget {
  const HuellitasApp({super.key, required this.initialLocation, this.bundledFont = true});
  final String initialLocation;
  final bool bundledFont;

  @override
  ConsumerState<HuellitasApp> createState() => _HuellitasAppState();
}

class _HuellitasAppState extends ConsumerState<HuellitasApp> {
  late final GoRouter _router = buildRouter(initialLocation: widget.initialLocation);

  @override
  void initState() {
    super.initState();
    // Reprograma los avisos cada vez que se abre la app.
    Future.microtask(() => ref.read(reminderCoordinatorProvider).sync());
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'Huellitas',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(bundledFont: widget.bundledFont),
        routerConfig: _router,
        locale: const Locale('es', 'MX'),
        supportedLocales: const [Locale('es', 'MX')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      );
}
```

`lib/main.dart`:
```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'data/database.dart';
import 'data/drift_repositories.dart';
import 'services/app_prefs.dart';
import 'services/local_notifications_scheduler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false; // la fuente va incluida en assets
  await initializeDateFormatting('es_MX');

  final docs = await getApplicationDocumentsDirectory();
  final db = AppDatabase.file(File(p.join(docs.path, 'huellitas.sqlite')));
  final prefs = await AppPrefs.load();
  final scheduler = LocalNotificationsScheduler();
  await scheduler.init();

  final hasPets = (await DriftPetRepository(db).all()).any((p) => !p.archived);

  runApp(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      docsDirProvider.overrideWithValue(docs),
      prefsProvider.overrideWithValue(prefs),
      schedulerProvider.overrideWithValue(scheduler),
    ],
    child: HuellitasApp(initialLocation: hasPets ? '/home' : '/onboarding'),
  ));
}
```
- [ ] **Step 7: Arnés de pruebas y prueba del shell**

`test/helpers/pump_app.dart`:
```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:huellitas/app/providers.dart';
import 'package:huellitas/data/database.dart';
import 'package:huellitas/services/app_prefs.dart';
import 'package:huellitas/services/pin_store.dart';
import 'package:huellitas/ui/theme.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

class InMemorySecrets implements SecretStore {
  final Map<String, String> data = {};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async => data[key] = value;
  @override
  Future<void> delete(String key) async => data.remove(key);
}

class TestEnv {
  TestEnv({
    required this.db,
    required this.scheduler,
    required this.prefs,
    required this.docs,
    required this.now,
    required this.secrets,
  });

  final AppDatabase db;
  final FakeScheduler scheduler;
  final AppPrefs prefs;
  final Directory docs;
  final DateTime now;
  final InMemorySecrets secrets;
  final List<String> shared = [];
  int _ids = 0;

  /// Agregar aquí los overrides de providers que se creen en tareas posteriores.
  List<Override> get overrides => [
        databaseProvider.overrideWithValue(db),
        docsDirProvider.overrideWithValue(docs),
        prefsProvider.overrideWithValue(prefs),
        schedulerProvider.overrideWithValue(scheduler),
        secretStoreProvider.overrideWithValue(secrets),
        clockProvider.overrideWithValue(() => now),
        idGeneratorProvider.overrideWithValue(() => 'id${_ids++}'),
      ];
}

Future<TestEnv> createEnv({DateTime? now}) async {
  SharedPreferences.setMockInitialValues({});
  await initializeDateFormatting('es_MX');
  return TestEnv(
    db: AppDatabase.memory(),
    scheduler: FakeScheduler(),
    prefs: await AppPrefs.load(),
    docs: Directory.systemTemp.createTempSync('huellitas_test_'),
    now: now ?? DateTime(2024, 10, 24, 10),
    secrets: InMemorySecrets(),
  );
}

/// Abre [screen] en la ruta /screen, encima de una pantalla con un botón
/// «open». Cualquier ruta desconocida muestra 'NAV:<ruta>' para poder
/// comprobar la navegación.
Future<void> pumpScreen(WidgetTester tester, TestEnv env, Widget screen) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (c, _) => Scaffold(
          body: Center(child: TextButton(onPressed: () => c.push('/screen'), child: const Text('open'))),
        ),
      ),
      GoRoute(path: '/screen', builder: (_, __) => screen),
    ],
    errorBuilder: (_, state) => Scaffold(body: Center(child: Text('NAV:${state.uri}'))),
  );
  await tester.pumpWidget(ProviderScope(
    overrides: env.overrides,
    child: MaterialApp.router(
      routerConfig: router,
      theme: buildTheme(bundledFont: false),
      locale: const Locale('es', 'MX'),
      supportedLocales: const [Locale('es', 'MX')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
    await env.db.close();
  });
}

/// Para sembrar o consultar la BD dentro de un testWidgets sin que el reloj
/// falso de Flutter bloquee las operaciones asíncronas.
Future<T> runDb<T>(WidgetTester tester, Future<T> Function() f) async =>
    (await tester.runAsync(f)) as T;
```

`test/ui/app_shell_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/app/app.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('el shell muestra las 4 pestañas y navega', (tester) async {
    final env = await createEnv();
    await tester.pumpWidget(ProviderScope(
      overrides: env.overrides,
      child: const HuellitasApp(initialLocation: '/home', bundledFont: false),
    ));
    await tester.pumpAndSettle();

    for (final label in ['Inicio', 'Historial', 'Mascotas', 'Ajustes']) {
      expect(find.text(label), findsWidgets);
    }
    await tester.tap(find.text('Ajustes').last);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);

    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
      await env.db.close();
    });
  });
}
```

- [ ] **Step 8: Ejecutar todo**

Run: `flutter pub get && flutter analyze && flutter test`
Expected: sin problemas y todas las pruebas PASS. (Si un test de widgets se cuelga por la BD, envolver la operación en `runDb`.)

- [ ] **Step 9: Commit**

```bash
git add .
git commit -m "feat(app): PIN store, theme, providers, router shell and bootstrap"
```

---

### Task 9: Configuración de plataformas (permisos y notificaciones)

**Files:**
- Modify: `ios/Podfile`, `ios/Runner/Info.plist`, `ios/Runner/AppDelegate.swift`
- Modify: `android/app/build.gradle.kts` (o `build.gradle`), `android/app/src/main/AndroidManifest.xml`, `android/app/src/main/kotlin/com/huellitas/huellitas/MainActivity.kt`

**Interfaces:**
- Produces: la app compila y abre en simulador iOS y en Android con permisos de cámara, fotos, Face ID, notificaciones y biometría.

- [ ] **Step 1: iOS — versión mínima y textos de permisos**

En `ios/Podfile` dejar (sin comentar) la línea:
```ruby
platform :ios, '13.0'
```
En `ios/Runner/Info.plist`, dentro del `<dict>` principal, agregar (y cambiar `CFBundleDisplayName` si ya existe):
```xml
<key>CFBundleDisplayName</key>
<string>Huellitas</string>
<key>NSCameraUsageDescription</key>
<string>Huellitas usa la cámara para fotografiar recetas y carnets de vacunación de tu mascota.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Huellitas necesita acceder a tus fotos para adjuntar recetas y la foto de tu mascota.</string>
<key>NSFaceIDUsageDescription</key>
<string>Huellitas usa Face ID para proteger el historial de tus mascotas.</string>
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

- [ ] **Step 2: iOS — delegado de notificaciones** **[API]**

Según el README de `flutter_local_notifications` (sección iOS), en `ios/Runner/AppDelegate.swift`, dentro de `application(_:didFinishLaunchingWithOptions:)` y antes del `return`, agregar:
```swift
if #available(iOS 10.0, *) {
  UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
}
```
Si la plantilla de Flutter instalada usa otra estructura de `AppDelegate`, seguir la versión vigente del README.

- [ ] **Step 3: Android — SDK mínimo y desugaring** **[API]**

En `android/app/build.gradle.kts`, dentro de `android { defaultConfig { ... } }` fijar `minSdk = 24`, y agregar:
```kotlin
android {
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
    }
}

dependencies {
    // Copiar la versión exacta de desugar_jdk_libs que indique el README vigente de flutter_local_notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

- [ ] **Step 4: Android — manifiesto**

En `android/app/src/main/AndroidManifest.xml`: poner `android:label="Huellitas"` en `<application>`, agregar antes de `<application>`:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
```
y dentro de `<application>`:
```xml
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON" />
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
</receiver>
```

- [ ] **Step 5: Android — `MainActivity` compatible con biometría**

`android/app/src/main/kotlin/com/huellitas/huellitas/MainActivity.kt`:
```kotlin
package com.huellitas.huellitas

import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
```

- [ ] **Step 6: Verificar que compila**

Run: `flutter build apk --debug && flutter build ios --simulator --no-codesign`
Expected: ambos terminan con `Built ...`. Luego `flutter run` en un simulador: se ve el shell con las 4 pestañas.

- [ ] **Step 7: Commit**

```bash
git add ios android
git commit -m "chore: platform permissions, notifications and biometric setup"
```

---

### Task 10: Onboarding, lista de mascotas y formulario de mascota

**Files:**
- Create: `lib/ui/onboarding/onboarding_screen.dart`, `lib/ui/pets/pets_screen.dart`, `lib/ui/pets/pet_form_screen.dart`
- Modify: `lib/ui/format.dart`, `lib/app/router.dart`
- Test: `test/ui/pet_form_test.dart`

**Interfaces:**
- Consumes: providers y widgets (Task 8), `AttachmentStore`, `ageLabel`, `percentUpToDate`.
- Produces: `OnboardingScreen()`, `PetsScreen()`, `PetFormScreen({String? petId, bool first = false})`, `String speciesLabel(PetSpecies)`; rutas `/onboarding`, `/pets`, `/pets/new?first=1`, `/pets/:id/edit`.

- [ ] **Step 1: Escribir la prueba que falla**

`test/ui/pet_form_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/data/drift_repositories.dart';
import 'package:huellitas/domain/enums.dart';
import 'package:huellitas/ui/pets/pet_form_screen.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('sin nombre muestra el error y no guarda', (tester) async {
    final env = await createEnv();
    await pumpScreen(tester, env, const PetFormScreen(first: true));

    await tester.ensureVisible(find.text('Guardar mascota'));
    await tester.tap(find.text('Guardar mascota'));
    await tester.pumpAndSettle();

    expect(find.text('Escribe el nombre'), findsOneWidget);
    final pets = await runDb(tester, () => DriftPetRepository(env.db).all());
    expect(pets, isEmpty);
  });

  testWidgets('guarda una gata, programa avisos y va a Inicio', (tester) async {
    final env = await createEnv();
    await pumpScreen(tester, env, const PetFormScreen(first: true));

    await tester.enterText(find.byKey(const Key('petNameField')), '  Misi ');
    await tester.tap(find.text('Gato'));
    await tester.pump();
    await tester.ensureVisible(find.text('Guardar mascota'));
    await tester.tap(find.text('Guardar mascota'));
    await tester.pumpAndSettle();

    final pets = await runDb(tester, () => DriftPetRepository(env.db).all());
    expect(pets.single.name, 'Misi');
    expect(pets.single.species, PetSpecies.cat);
    expect(env.scheduler.syncCount, greaterThan(0));
    expect(find.text('NAV:/home'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Ejecutar y ver que falla**

Run: `flutter test test/ui/pet_form_test.dart`
Expected: FAIL (`pet_form_screen.dart` no existe)

- [ ] **Step 3: Etiquetas de especie**

Agregar a `lib/ui/format.dart` (y `import '../domain/enums.dart';` ya existe):
```dart
String speciesLabel(PetSpecies s) => switch (s) {
      PetSpecies.dog => 'Perro',
      PetSpecies.cat => 'Gato',
      PetSpecies.other => 'Otra mascota',
    };
```

- [ ] **Step 4: Formulario de mascota**

`lib/ui/pets/pet_form_screen.dart`:
```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/providers.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../../services/attachment_store.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets.dart';

class PetFormScreen extends ConsumerStatefulWidget {
  const PetFormScreen({super.key, this.petId, this.first = false});
  final String? petId;
  final bool first;

  @override
  ConsumerState<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends ConsumerState<PetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _breed = TextEditingController();
  final _microchip = TextEditingController();
  final _allergies = TextEditingController();
  final _vetName = TextEditingController();
  final _vetClinic = TextEditingController();
  final _vetPhone = TextEditingController();
  PetSpecies _species = PetSpecies.dog;
  PetSex? _sex;
  bool _neutered = false;
  DateTime? _birth;
  String? _photo;
  String? _originalPhoto;
  Pet? _existing;
  late bool _loading = widget.petId != null;
  bool _saved = false;
  late final AttachmentStore _store = ref.read(attachmentStoreProvider);

  @override
  void initState() {
    super.initState();
    if (widget.petId != null) _load();
  }

  Future<void> _load() async {
    final p = await ref.read(petRepoProvider).get(widget.petId!);
    if (p != null) {
      _existing = p;
      _name.text = p.name;
      _breed.text = p.breed ?? '';
      _microchip.text = p.microchip ?? '';
      _allergies.text = p.allergiesNotes ?? '';
      _vetName.text = p.vetName ?? '';
      _vetClinic.text = p.vetClinic ?? '';
      _vetPhone.text = p.vetPhone ?? '';
      _species = p.species;
      _sex = p.sex;
      _neutered = p.neutered;
      _birth = p.birthDate;
      _photo = _originalPhoto = p.photoPath;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    if (!_saved && _photo != null && _photo != _originalPhoto) {
      unawaited(_store.delete(_photo!)); // foto nueva que nunca se guardó
    }
    for (final c in [_name, _breed, _microchip, _allergies, _vetName, _vetClinic, _vetPhone]) {
      c.dispose();
    }
    super.dispose();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _pickPhoto(ImageSource source) async {
    final x = await ImagePicker().pickImage(source: source);
    if (x == null) return;
    try {
      final rel = await _store.importImage(File(x.path));
      if (_photo != null && _photo != _originalPhoto) await _store.delete(_photo!);
      if (mounted) setState(() => _photo = rel);
    } on AttachmentException catch (e) {
      if (mounted) _snack(e.message);
    }
  }

  Future<void> _pickBirth() async {
    final now = ref.read(clockProvider)();
    final d = await showDatePicker(
      context: context,
      initialDate: _birth ?? now,
      firstDate: DateTime(1990),
      lastDate: now,
    );
    if (d != null) setState(() => _birth = DateTime.utc(d.year, d.month, d.day));
  }

  String? _n(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final isNew = _existing == null;
    final pet = Pet(
      id: _existing?.id ?? ref.read(idGeneratorProvider)(),
      name: _name.text.trim(),
      species: _species,
      breed: _n(_breed),
      sex: _sex,
      neutered: _neutered,
      birthDate: _birth,
      microchip: _n(_microchip),
      photoPath: _photo,
      allergiesNotes: _n(_allergies),
      vetName: _n(_vetName),
      vetClinic: _n(_vetClinic),
      vetPhone: _n(_vetPhone),
      createdAt: _existing?.createdAt ?? ref.read(clockProvider)(),
      archived: _existing?.archived ?? false,
    );
    await ref.read(petRepoProvider).save(pet);
    if (_originalPhoto != null && _originalPhoto != _photo) {
      await _store.delete(_originalPhoto!);
    }
    _saved = true;
    if (isNew) ref.read(selectedPetIdProvider.notifier).select(pet.id);
    await ref.read(reminderCoordinatorProvider).sync();
    if (!mounted) return;
    if (widget.first) {
      context.go('/home');
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final photoFile = _photo == null ? null : _store.fileFor(_photo!);
    return Scaffold(
      appBar: AppBar(
        title: Text(_existing == null ? 'Nueva mascota' : 'Editar mascota'),
        leading: widget.first ? null : TextButton(onPressed: () => context.pop(), child: const Text('Cancelar')),
        leadingWidth: 90,
        actions: [TextButton(onPressed: _save, child: const Text('Guardar'))],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: GestureDetector(
                  onTap: () => _pickPhoto(ImageSource.gallery),
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    backgroundImage: (photoFile != null && photoFile.existsSync()) ? FileImage(photoFile) : null,
                    child: (photoFile != null && photoFile.existsSync())
                        ? null
                        : const Icon(Icons.add_a_photo, color: AppColors.primary, size: 32),
                  ),
                ),
              ),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                TextButton(onPressed: () => _pickPhoto(ImageSource.camera), child: const Text('Tomar foto')),
                TextButton(onPressed: () => _pickPhoto(ImageSource.gallery), child: const Text('Elegir de la galería')),
              ]),
              const SectionHeader('Datos'),
              TextFormField(
                key: const Key('petNameField'),
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nombre de la mascota *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe el nombre' : null,
              ),
              const SizedBox(height: 12),
              SegmentedButton<PetSpecies>(
                segments: [
                  for (final s in PetSpecies.values) ButtonSegment(value: s, label: Text(speciesLabel(s).replaceAll(' mascota', ''))),
                ],
                selected: {_species},
                onSelectionChanged: (s) => setState(() => _species = s.first),
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _breed, decoration: const InputDecoration(labelText: 'Raza o cruza')),
              const SizedBox(height: 12),
              SegmentedButton<PetSex>(
                emptySelectionAllowed: true,
                segments: const [
                  ButtonSegment(value: PetSex.male, label: Text('Macho')),
                  ButtonSegment(value: PetSex.female, label: Text('Hembra')),
                ],
                selected: _sex == null ? <PetSex>{} : {_sex!},
                onSelectionChanged: (s) => setState(() => _sex = s.isEmpty ? null : s.first),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Esterilizado'),
                subtitle: const Text('Castración o ligadura quirúrgica'),
                value: _neutered,
                onChanged: (v) => setState(() => _neutered = v),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha de nacimiento o adopción'),
                subtitle: Text(_birth == null ? 'Sin definir' : fmtDay(_birth!)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickBirth,
              ),
              TextFormField(controller: _microchip, decoration: const InputDecoration(labelText: 'Número de microchip (opcional)')),
              const SizedBox(height: 12),
              TextFormField(
                controller: _allergies,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Alergias o condiciones'),
              ),
              const SectionHeader('Veterinario'),
              TextFormField(controller: _vetName, decoration: const InputDecoration(labelText: 'Nombre')),
              const SizedBox(height: 12),
              TextFormField(controller: _vetClinic, decoration: const InputDecoration(labelText: 'Clínica')),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vetPhone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Teléfono'),
              ),
              const SizedBox(height: 24),
              FilledButton(onPressed: _save, child: const Text('Guardar mascota')),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Onboarding y lista de mascotas**

`lib/ui/onboarding/onboarding_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _slides = [
    (Icons.vaccines, 'Nunca olvides una vacuna', 'Huellitas te avisa antes de cada vacuna, desparasitación y antipulgas.'),
    (Icons.event_note, 'Todo su historial en un lugar', 'Guarda enfermedades, consultas y fotos de recetas y carnets.'),
    (Icons.ios_share, 'Respalda y lleva su carnet', 'Tus datos viven en tu teléfono. Exporta un respaldo y un carnet en PDF cuando lo necesites.'),
  ];

  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _start() => context.go('/pets/new?first=1');

  @override
  Widget build(BuildContext context) {
    final last = _page == _slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: _start, child: const Text('Omitir')),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) {
                  final (icon, title, body) = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 96, color: AppColors.primary),
                        const SizedBox(height: 24),
                        Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        Text(body, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.inkSoft)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < _slides.length; i++)
                Container(
                  margin: const EdgeInsets.all(4),
                  width: i == _page ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _page ? AppColors.primary : AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ]),
            Padding(
              padding: const EdgeInsets.all(24),
              child: FilledButton(
                onPressed: last
                    ? _start
                    : () => _controller.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
                child: Text(last ? 'Agregar mi primera mascota' : 'Siguiente'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

`lib/ui/pets/pets_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/age.dart';
import '../../domain/dates.dart';
import '../../domain/models.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets.dart';

class PetsScreen extends ConsumerWidget {
  const PetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pets = ref.watch(petsProvider).asData?.value ?? const <Pet>[];
    final treatments = ref.watch(activeTreatmentsProvider).asData?.value ?? const <Treatment>[];
    final now = ref.watch(clockProvider)();

    return Scaffold(
      appBar: AppBar(title: const Text('Mascotas')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              avatar: const Icon(Icons.lock, size: 16, color: AppColors.primary),
              label: Text('${pets.length} ${pets.length == 1 ? 'compañero' : 'compañeros'} · 100% local'),
            ),
          ),
          const SizedBox(height: 8),
          for (final pet in pets)
            _PetCard(
              pet: pet,
              overdue: treatments.where((t) => t.petId == pet.id && daysUntil(t.nextDueDate, now) < 0).length,
              now: now,
            ),
          AppCard(
            onTap: () => context.push('/pets/new'),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Icon(Icons.add, color: AppColors.primary), SizedBox(width: 8), Text('Agregar mascota')],
            ),
          ),
        ],
      ),
    );
  }
}

class _PetCard extends ConsumerWidget {
  const _PetCard({required this.pet, required this.overdue, required this.now});
  final Pet pet;
  final int overdue;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = [
      pet.breed ?? speciesLabel(pet.species),
      if (pet.birthDate != null) ageLabel(pet.birthDate!, now),
    ].join(' • ');
    return AppCard(
      onTap: () {
        ref.read(selectedPetIdProvider.notifier).select(pet.id);
        context.push('/pets/${pet.id}');
      },
      child: Row(children: [
        PetAvatar(pet: pet, size: 56),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(pet.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            Text(detail, style: const TextStyle(color: AppColors.inkSoft)),
          ]),
        ),
        overdue > 0
            ? StatusChip('$overdue ${overdue == 1 ? 'atrasada' : 'atrasadas'}', StatusKind.overdue)
            : const StatusChip('Al día', StatusKind.ok),
      ]),
    );
  }
}
```

- [ ] **Step 6: Conectar rutas**

En `lib/app/router.dart` agregar imports de `OnboardingScreen`, `PetsScreen`, `PetFormScreen`, y reemplazar:
- `/onboarding` → `builder: (_, __) => const OnboardingScreen()`
- `/pets` → `builder: (_, __) => const PetsScreen()`
- Agregar en la lista principal de `routes` (después del `StatefulShellRoute`):
```dart
GoRoute(
  path: '/pets/new',
  parentNavigatorKey: rootNavigatorKey,
  builder: (_, s) => PetFormScreen(first: s.uri.queryParameters['first'] == '1'),
),
GoRoute(
  path: '/pets/:id/edit',
  parentNavigatorKey: rootNavigatorKey,
  builder: (_, s) => PetFormScreen(petId: s.pathParameters['id']),
),
```

- [ ] **Step 7: Ejecutar y ver que pasa**

Run: `flutter test test/ui/pet_form_test.dart && flutter analyze`
Expected: PASS y sin problemas. (Si una prueba se cuelga, envolver en `runDb` la operación de BD que corresponda.)

- [ ] **Step 8: Commit**

```bash
git add lib test
git commit -m "feat(ui): onboarding, pets list and pet form"
```

---

### Task 11: Inicio

**Files:**
- Create: `lib/domain/home_logic.dart`, `lib/ui/home/home_screen.dart`
- Modify: `lib/app/providers.dart` (agregar `notificationsAllowedProvider`), `lib/app/router.dart`
- Test: `test/domain/home_logic_test.dart`, `test/ui/home_screen_test.dart`

**Interfaces:**
- Consumes: providers (Task 8), `HealthService.markDone`, `ReminderCoordinator.sync`.
- Produces:
```dart
const int backupReminderDays = 30;
class HomeItem { final Treatment treatment; final DueStatus status; final String label; }
List<HomeItem> homeItems(Iterable<Treatment> treatments, DateTime today);   // activos, por fecha ascendente
bool needsBackupReminder({required DateTime? lastBackup, required DateTime now, required bool hasData});
final notificationsAllowedProvider = FutureProvider.autoDispose<bool>(...);   // en providers.dart
class HomeScreen extends ConsumerWidget {}
```

- [ ] **Step 1: Pruebas que fallan**

`test/domain/home_logic_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/domain/home_logic.dart';
import 'package:huellitas/domain/treatment_status.dart';

import '../helpers/samples.dart';

void main() {
  final today = DateTime.utc(2024, 10, 24);

  test('homeItems ordena por fecha, excluye inactivos y calcula estado y texto', () {
    final items = homeItems([
      sampleTreatment(id: 'b', nextDue: DateTime.utc(2024, 11, 5)),
      sampleTreatment(id: 'a', nextDue: DateTime.utc(2024, 10, 21)),
      sampleTreatment(id: 'x', nextDue: DateTime.utc(2024, 10, 1), active: false),
    ], today);
    expect(items.map((i) => i.treatment.id), ['a', 'b']);
    expect(items.first.status, DueStatus.overdue);
    expect(items.first.label, 'Atrasada · hace 3 días');
    expect(items.last.label, 'En 12 días');
  });

  group('needsBackupReminder', () {
    final now = DateTime(2024, 10, 24);
    test('sin datos no avisa', () {
      expect(needsBackupReminder(lastBackup: null, now: now, hasData: false), isFalse);
    });
    test('con datos y sin respaldo avisa', () {
      expect(needsBackupReminder(lastBackup: null, now: now, hasData: true), isTrue);
    });
    test('29 días no avisa, 30 sí', () {
      expect(needsBackupReminder(lastBackup: now.subtract(const Duration(days: 29)), now: now, hasData: true), isFalse);
      expect(needsBackupReminder(lastBackup: now.subtract(const Duration(days: 30)), now: now, hasData: true), isTrue);
    });
  });
}
```

`test/ui/home_screen_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/data/drift_repositories.dart';
import 'package:huellitas/ui/home/home_screen.dart';

import '../helpers/pump_app.dart';
import '../helpers/samples.dart';

void main() {
  testWidgets('sin mascotas invita a agregar la primera', (tester) async {
    final env = await createEnv();
    await pumpScreen(tester, env, const HomeScreen());
    expect(find.text('Agrega tu primera mascota'), findsOneWidget);
    await tester.tap(find.text('Agrega tu primera mascota'));
    await tester.pumpAndSettle();
    expect(find.text('NAV:/pets/new?first=1'), findsOneWidget);
  });

  testWidgets('mascota sin tratamientos: todo bajo control y sin recordatorios', (tester) async {
    final env = await createEnv();
    await runDb(tester, () => DriftPetRepository(env.db).save(samplePet()));
    await pumpScreen(tester, env, const HomeScreen());
    expect(find.text('Todo bajo control'), findsOneWidget);
    expect(find.textContaining('Aún no hay recordatorios'), findsOneWidget);
  });

  testWidgets('tratamiento atrasado: se ve y "Marcar como hecha" lo mueve y reprograma avisos', (tester) async {
    final env = await createEnv(); // hoy = 24 oct 2024
    await runDb(tester, () async {
      await DriftPetRepository(env.db).save(samplePet());
      await DriftTreatmentRepository(env.db)
          .save(sampleTreatment(nextDue: DateTime.utc(2024, 10, 21)));
    });
    await pumpScreen(tester, env, const HomeScreen());

    expect(find.text('Atrasada · hace 3 días'), findsOneWidget);
    expect(find.text('1 tarea atrasada'), findsOneWidget);

    await tester.tap(find.text('Marcar como hecha').first);
    await tester.pumpAndSettle();

    final t = await runDb(tester, () => DriftTreatmentRepository(env.db).get('t1'));
    expect(t!.nextDueDate, DateTime.utc(2025, 10, 24));
    final events = await runDb(tester, () => DriftEventRepository(env.db).watchForPet('p1').first);
    expect(events.length, 1);
    expect(env.scheduler.syncCount, greaterThan(0));
  });
}
```

- [ ] **Step 2: Ejecutar y ver que fallan**

Run: `flutter test test/domain/home_logic_test.dart test/ui/home_screen_test.dart`
Expected: FAIL

- [ ] **Step 3: Lógica pura**

`lib/domain/home_logic.dart`:
```dart
import 'models.dart';
import 'treatment_status.dart';

const int backupReminderDays = 30;

class HomeItem {
  const HomeItem(this.treatment, this.status, this.label);
  final Treatment treatment;
  final DueStatus status;
  final String label;
}

List<HomeItem> homeItems(Iterable<Treatment> treatments, DateTime today) {
  final list = treatments.where((t) => t.active).toList()
    ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
  return [
    for (final t in list)
      HomeItem(t, dueStatus(t.nextDueDate, today), dueLabel(t.nextDueDate, today)),
  ];
}

bool needsBackupReminder({
  required DateTime? lastBackup,
  required DateTime now,
  required bool hasData,
}) {
  if (!hasData) return false;
  if (lastBackup == null) return true;
  return now.difference(lastBackup).inDays >= backupReminderDays;
}
```

- [ ] **Step 4: Provider de permiso y pantalla**

Agregar al final de `lib/app/providers.dart`:
```dart
final notificationsAllowedProvider = FutureProvider.autoDispose<bool>(
    (ref) => ref.watch(schedulerProvider).hasPermission());
```

`lib/ui/home/home_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/home_logic.dart';
import '../../domain/models.dart';
import '../../domain/treatment_status.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsAsync = ref.watch(petsProvider);
    if (petsAsync.asData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final pets = petsAsync.asData!.value;
    final pet = ref.watch(currentPetProvider);

    if (pet == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Inicio')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.pets, size: 56, color: AppColors.primary),
              const SizedBox(height: 12),
              const Text('Aún no tienes mascotas'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/pets/new?first=1'),
                child: const Text('Agrega tu primera mascota'),
              ),
            ]),
          ),
        ),
      );
    }

    final now = ref.watch(clockProvider)();
    final all = ref.watch(activeTreatmentsProvider).asData?.value ?? const <Treatment>[];
    final mine = all.where((t) => t.petId == pet.id).toList();
    final events = ref.watch(eventsForPetProvider(pet.id)).asData?.value ?? const <HealthEvent>[];
    final items = homeItems(mine, now);
    final overdue = items.where((i) => i.status == DueStatus.overdue).length;
    final percent = percentUpToDate(mine, now);
    final notificationsOk = ref.watch(notificationsAllowedProvider).asData?.value ?? true;
    final remindBackup = needsBackupReminder(
      lastBackup: ref.watch(prefsProvider).lastBackupAt,
      now: now,
      hasData: events.isNotEmpty,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Inicio')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/events/new?petId=${pet.id}'),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo evento'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          if (pets.length > 1)
            SizedBox(
              height: 72,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final p in pets)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () => ref.read(selectedPetIdProvider.notifier).select(p.id),
                        child: Column(children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: p.id == pet.id ? AppColors.primary : Colors.transparent, width: 2),
                            ),
                            child: PetAvatar(pet: p, size: 44),
                          ),
                          Text(p.name, style: const TextStyle(fontSize: 12)),
                        ]),
                      ),
                    ),
                ],
              ),
            ),
          if (!notificationsOk)
            AppCard(
              stripe: AppColors.orange,
              child: Row(children: [
                const Expanded(child: Text('Los avisos están desactivados. Actívalos para que Huellitas te recuerde.')),
                TextButton(
                  onPressed: () async {
                    await ref.read(schedulerProvider).requestPermission();
                    ref.invalidate(notificationsAllowedProvider);
                    await ref.read(reminderCoordinatorProvider).sync();
                  },
                  child: const Text('Activar'),
                ),
              ]),
            ),
          if (remindBackup)
            AppCard(
              stripe: AppColors.primary,
              onTap: () => context.go('/settings'),
              child: const Text('Haz un respaldo para no perder el historial si cambias de teléfono.'),
            ),
          AppCard(
            child: Row(children: [
              Icon(overdue == 0 ? Icons.verified : Icons.warning_amber_rounded,
                  color: overdue == 0 ? AppColors.primary : AppColors.coral, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Estado general', style: TextStyle(color: AppColors.inkSoft)),
                  Text(
                    overdue == 0 ? 'Todo bajo control' : (overdue == 1 ? '1 tarea atrasada' : '$overdue tareas atrasadas'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ]),
              ),
              StatusChip('$percent% al día', overdue == 0 ? StatusKind.ok : StatusKind.overdue),
            ]),
          ),
          const SectionHeader('Lo que toca pronto'),
          if (items.isEmpty)
            const AppCard(
              child: Text('Aún no hay recordatorios. Registra una vacuna o desparasitación con frecuencia y aquí verás cuándo toca la siguiente.'),
            ),
          for (final item in items) _ReminderCard(item: item),
          if (events.isNotEmpty) ...[
            const SectionHeader('Registrado recientemente'),
            for (final e in events.take(2))
              AppCard(
                onTap: () => context.push('/events/${e.id}'),
                child: Row(children: [
                  Icon(iconForType(e.type), color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(fmtDay(e.occurredAt), style: const TextStyle(color: AppColors.inkSoft)),
                    ]),
                  ),
                ]),
              ),
          ],
        ],
      ),
    );
  }
}

class _ReminderCard extends ConsumerWidget {
  const _ReminderCard({required this.item});
  final HomeItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = item.treatment;
    final stripe = switch (item.status) {
      DueStatus.overdue => AppColors.coral,
      DueStatus.dueSoon => AppColors.orange,
      DueStatus.upcoming => AppColors.primary,
    };
    return AppCard(
      stripe: stripe,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(iconForType(t.type), color: stripe),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(t.type.label, style: const TextStyle(color: AppColors.inkSoft)),
            ]),
          ),
          StatusChip.forDue(item.status, item.label),
        ]),
        const SizedBox(height: 8),
        Text('Fecha: ${fmtDay(t.nextDueDate)}', style: const TextStyle(color: AppColors.inkSoft)),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: () async {
            await ref.read(healthServiceProvider).markDone(t.id);
            await ref.read(reminderCoordinatorProvider).sync();
          },
          icon: const Icon(Icons.check),
          label: const Text('Marcar como hecha'),
        ),
      ]),
    );
  }
}
```

- [ ] **Step 5: Ruta y verificación**

En `lib/app/router.dart`: importar `HomeScreen` y reemplazar el stub de `/home` por `const HomeScreen()`.

Run: `flutter test test/domain/home_logic_test.dart test/ui/home_screen_test.dart && flutter analyze`
Expected: PASS y sin problemas.

- [ ] **Step 6: Commit**

```bash
git add lib test
git commit -m "feat(ui): home screen with due reminders and mark-as-done"
```

---

### Task 12: Formulario de evento de salud

**Files:**
- Create: `lib/ui/events/event_form_screen.dart`
- Modify: `lib/app/router.dart`
- Test: `test/ui/event_form_test.dart`

**Interfaces:**
- Consumes: `HealthService.logEvent`, `LogEventInput`, `NewAttachment`, `AttachmentStore.importImage`, `addInterval`.
- Produces: `EventFormScreen({String? petId, EventType? initialType})`; ruta `/events/new?petId=…&type=…`.

- [ ] **Step 1: Prueba que falla**

`test/ui/event_form_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/data/drift_repositories.dart';
import 'package:huellitas/ui/events/event_form_screen.dart';

import '../helpers/pump_app.dart';
import '../helpers/samples.dart';

void main() {
  Future<TestEnv> setup(WidgetTester tester) async {
    final env = await createEnv(); // hoy = 24 oct 2024
    await runDb(tester, () => DriftPetRepository(env.db).save(samplePet()));
    await pumpScreen(tester, env, const EventFormScreen(petId: 'p1'));
    return env;
  }

  testWidgets('sin nombre muestra el error y no guarda', (tester) async {
    final env = await setup(tester);
    await tester.ensureVisible(find.text('Guardar en historial'));
    await tester.tap(find.text('Guardar en historial'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe el nombre'), findsOneWidget);
    final events = await runDb(tester, () => DriftEventRepository(env.db).watchForPet('p1').first);
    expect(events, isEmpty);
  });

  testWidgets('vacuna con repetición de 1 año guarda evento y tratamiento y reprograma avisos', (tester) async {
    final env = await setup(tester);
    await tester.enterText(find.byKey(const Key('eventTitleField')), 'Antirrábica');
    await tester.ensureVisible(find.text('1 año'));
    await tester.tap(find.text('1 año'));
    await tester.pump();
    expect(find.textContaining('Próxima dosis sugerida'), findsOneWidget);

    await tester.ensureVisible(find.text('Guardar en historial'));
    await tester.tap(find.text('Guardar en historial'));
    await tester.pumpAndSettle();

    final events = await runDb(tester, () => DriftEventRepository(env.db).watchForPet('p1').first);
    expect(events.single.title, 'Antirrábica');
    final treatments = await runDb(tester, () => DriftTreatmentRepository(env.db).active());
    expect(treatments.single.nextDueDate, DateTime.utc(2025, 10, 24));
    expect(env.scheduler.syncCount, greaterThan(0));
    expect(find.text('open'), findsOneWidget); // volvió a la pantalla anterior
  });

  testWidgets('enfermedad no ofrece frecuencia de repetición', (tester) async {
    await setup(tester);
    expect(find.text('Frecuencia de repetición'), findsOneWidget);
    await tester.ensureVisible(find.text('Enfermedad'));
    await tester.tap(find.text('Enfermedad'));
    await tester.pump();
    expect(find.text('Frecuencia de repetición'), findsNothing);
  });

  testWidgets('peso inválido muestra error', (tester) async {
    await setup(tester);
    await tester.enterText(find.byKey(const Key('eventTitleField')), 'Consulta');
    await tester.enterText(find.byKey(const Key('eventWeightField')), 'abc');
    await tester.ensureVisible(find.text('Guardar en historial'));
    await tester.tap(find.text('Guardar en historial'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe un peso válido'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Ejecutar y ver que falla**

Run: `flutter test test/ui/event_form_test.dart`
Expected: FAIL

- [ ] **Step 3: Implementar**

`lib/ui/events/event_form_screen.dart`:
```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/providers.dart';
import '../../domain/dates.dart';
import '../../domain/enums.dart';
import '../../domain/health_service.dart';
import '../../domain/models.dart';
import '../../services/attachment_store.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets.dart';

class _Freq {
  const _Freq(this.label, this.value, this.unit);
  final String label;
  final int? value;
  final IntervalUnit? unit;
}

const _freqs = [
  _Freq('Ninguna', null, null),
  _Freq('1 mes', 1, IntervalUnit.months),
  _Freq('3 meses', 3, IntervalUnit.months),
  _Freq('6 meses', 6, IntervalUnit.months),
  _Freq('1 año', 1, IntervalUnit.years),
];

String _titleLabel(EventType t) => switch (t) {
      EventType.vaccine => 'Nombre de la vacuna *',
      EventType.deworming || EventType.fleaTick => 'Producto *',
      EventType.illness => 'Síntoma o diagnóstico *',
      EventType.checkup => 'Motivo de la consulta *',
    };

class EventFormScreen extends ConsumerStatefulWidget {
  const EventFormScreen({super.key, this.petId, this.initialType});
  final String? petId;
  final EventType? initialType;

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _notes = TextEditingController();
  final _vet = TextEditingController();
  final _clinic = TextEditingController();
  final _lot = TextEditingController();
  final _weight = TextEditingController();
  final List<NewAttachment> _attachments = [];
  late String? _petId = widget.petId ?? ref.read(currentPetProvider)?.id;
  late EventType _type = widget.initialType ?? EventType.vaccine;
  late DateTime _date = ref.read(clockProvider)();
  late int _daysBefore = ref.read(prefsProvider).reminderDaysBefore;
  late final AttachmentStore _store = ref.read(attachmentStoreProvider);
  int _freqIndex = 0;
  bool _reminder = true;
  bool _saved = false;
  bool _saving = false;

  @override
  void dispose() {
    if (!_saved) {
      for (final a in _attachments) {
        unawaited(_store.delete(a.relativePath)); // fotos que nunca se guardaron
      }
    }
    for (final c in [_title, _notes, _vet, _clinic, _lot, _weight]) {
      c.dispose();
    }
    super.dispose();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  double? get _parsedWeight => double.tryParse(_weight.text.trim().replaceAll(',', '.'));

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      setState(() => _date = DateTime(d.year, d.month, d.day, _date.hour, _date.minute));
    }
  }

  Future<void> _addPhoto(ImageSource source) async {
    final x = await ImagePicker().pickImage(source: source);
    if (x == null) return;
    try {
      final rel = await _store.importImage(File(x.path));
      if (mounted) {
        setState(() => _attachments.add(
              NewAttachment(relativePath: rel, kind: AttachmentKind.image, label: 'Comprobante'),
            ));
      }
    } on AttachmentException catch (e) {
      if (mounted) _snack(e.message);
    }
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    if (_petId == null) {
      _snack('Primero agrega una mascota');
      return;
    }
    setState(() => _saving = true);
    final freq = _type.canRecur ? _freqs[_freqIndex] : _freqs[0];
    final title = _title.text.trim();
    try {
      await ref.read(healthServiceProvider).logEvent(LogEventInput(
            petId: _petId!,
            type: _type,
            title: title,
            occurredAt: _date,
            product: _type.canRecur ? title : null,
            lot: _lot.text,
            vetName: _vet.text,
            clinic: _clinic.text,
            notes: _notes.text,
            weightKg: _parsedWeight,
            intervalValue: freq.value,
            intervalUnit: freq.unit,
            reminderEnabled: _reminder,
            reminderDaysBefore: _daysBefore,
            attachments: _attachments,
          ));
      _saved = true;
      await ref.read(reminderCoordinatorProvider).sync();
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        _snack('No se pudo guardar el registro');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pets = ref.watch(petsProvider).asData?.value ?? const <Pet>[];
    final freq = _freqs[_freqIndex];
    final next = (_type.canRecur && freq.value != null)
        ? addInterval(_date, freq.value!, freq.unit!)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar evento'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (pets.length > 1)
                DropdownButtonFormField<String>(
                  initialValue: _petId,
                  decoration: const InputDecoration(labelText: 'Mascota'),
                  items: [for (final p in pets) DropdownMenuItem(value: p.id, child: Text(p.name))],
                  onChanged: (v) => setState(() => _petId = v),
                ),
              const SectionHeader('Tipo de evento'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final t in EventType.values)
                  ChoiceChip(
                    avatar: Icon(iconForType(t), size: 18),
                    label: Text(t.label),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  ),
              ]),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('eventTitleField'),
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: _titleLabel(_type)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe el nombre' : null,
              ),
              if (_type == EventType.vaccine)
                Wrap(spacing: 8, children: [
                  for (final s in const ['Antirrábica', 'Múltiple', 'Giardia'])
                    ActionChip(label: Text('+ $s'), onPressed: () => setState(() => _title.text = s)),
                ]),
              const SectionHeader('Fecha'),
              ListTile(
                tileColor: AppColors.card,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: const Text('Fecha de aplicación o evento'),
                subtitle: Text(fmtDay(_date)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              if (_type.canRecur) ...[
                const SectionHeader('Frecuencia de repetición'),
                Wrap(spacing: 8, children: [
                  for (var i = 0; i < _freqs.length; i++)
                    ChoiceChip(
                      label: Text(_freqs[i].label),
                      selected: _freqIndex == i,
                      onSelected: (_) => setState(() => _freqIndex = i),
                    ),
                ]),
              ],
              if (next != null) ...[
                const SizedBox(height: 12),
                AppCard(
                  stripe: AppColors.primary,
                  child: Text('Próxima dosis sugerida: ${fmtDay(next)}'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Recordatorio previo'),
                  subtitle: Text('Avisarme $_daysBefore ${_daysBefore == 1 ? 'día' : 'días'} antes por notificación'),
                  value: _reminder,
                  onChanged: (v) => setState(() => _reminder = v),
                ),
                if (_reminder)
                  Row(children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _daysBefore > 1 ? () => setState(() => _daysBefore--) : null,
                    ),
                    Text('$_daysBefore'),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _daysBefore < 14 ? () => setState(() => _daysBefore++) : null,
                    ),
                  ]),
              ],
              const SectionHeader('Detalles'),
              TextFormField(
                key: const Key('eventNotesField'),
                controller: _notes,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Notas o indicaciones del veterinario'),
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _vet, decoration: const InputDecoration(labelText: 'Veterinario')),
              const SizedBox(height: 12),
              TextFormField(controller: _clinic, decoration: const InputDecoration(labelText: 'Clínica')),
              const SizedBox(height: 12),
              TextFormField(controller: _lot, decoration: const InputDecoration(labelText: 'Lote (opcional)')),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('eventWeightField'),
                controller: _weight,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Peso del día en kg (opcional)'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final w = _parsedWeight;
                  return (w == null || w <= 0 || w >= 300) ? 'Escribe un peso válido' : null;
                },
              ),
              const SectionHeader('Comprobante y carnet'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final a in _attachments)
                  Stack(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_store.fileFor(a.relativePath), width: 72, height: 72, fit: BoxFit.cover),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () {
                          unawaited(_store.delete(a.relativePath));
                          setState(() => _attachments.remove(a));
                        },
                        child: const CircleAvatar(radius: 10, child: Icon(Icons.close, size: 12)),
                      ),
                    ),
                  ]),
              ]),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _addPhoto(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Cámara'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _addPhoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galería'),
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.check_circle),
                label: const Text('Guardar en historial'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```
(**[API]** `DropdownButtonFormField.initialValue` reemplazó a `value` en Flutter recientes; si el analizador la marca, usar `value`.)

- [ ] **Step 4: Ruta**

En `lib/app/router.dart` agregar:
```dart
GoRoute(
  path: '/events/new',
  parentNavigatorKey: rootNavigatorKey,
  builder: (_, s) {
    final type = s.uri.queryParameters['type'];
    return EventFormScreen(
      petId: s.uri.queryParameters['petId'],
      initialType: type == null ? null : EventType.values.byName(type),
    );
  },
),
```
(importar `EventFormScreen` y `enums.dart`; esta ruta debe ir **antes** de `/events/:id` cuando se agregue).

- [ ] **Step 5: Ejecutar y ver que pasa**

Run: `flutter test test/ui/event_form_test.dart && flutter analyze`
Expected: PASS y sin problemas.

- [ ] **Step 6: Commit**

```bash
git add lib test
git commit -m "feat(ui): health event form with recurrence preview and photos"
```

---

### Task 13: Detalle de evento (con eliminar)

**Files:**
- Create: `lib/ui/events/event_detail_screen.dart`
- Modify: `lib/app/router.dart`
- Test: `test/ui/event_detail_test.dart`

**Interfaces:**
- Consumes: `EventRepository.get/attachmentsFor/delete`, `TreatmentRepository.get`, `AttachmentStore.delete`.
- Produces: `EventDetailScreen({required String eventId})`; ruta `/events/:id`.
- Alcance acotado a propósito: el detalle permite **ver y eliminar**; editar un evento existente no está en la primera versión (se elimina y se vuelve a registrar). Eliminar un evento **no** recalcula la fecha del tratamiento asociado.

- [ ] **Step 1: Prueba que falla**

`test/ui/event_detail_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/data/drift_repositories.dart';
import 'package:huellitas/ui/events/event_detail_screen.dart';

import '../helpers/pump_app.dart';
import '../helpers/samples.dart';

void main() {
  Future<TestEnv> setup(WidgetTester tester) async {
    final env = await createEnv();
    await runDb(tester, () async {
      await DriftPetRepository(env.db).save(samplePet());
      await DriftEventRepository(env.db).save(sampleEvent(notes: 'Sin reacciones'), const []);
    });
    await pumpScreen(tester, env, const EventDetailScreen(eventId: 'e1'));
    return env;
  }

  testWidgets('muestra el detalle del evento', (tester) async {
    await setup(tester);
    expect(find.text('Antirrábica'), findsWidgets);
    expect(find.text('Sin reacciones'), findsOneWidget);
    expect(find.text('Dra. Carmen Morales'), findsOneWidget);
    expect(find.text('Toby'), findsOneWidget);
  });

  testWidgets('eliminar pide confirmación, borra el evento y regresa', (tester) async {
    final env = await setup(tester);
    await tester.tap(find.byKey(const Key('deleteEventButton')));
    await tester.pumpAndSettle();
    expect(find.text('¿Eliminar este registro?'), findsOneWidget);

    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    final e = await runDb(tester, () => DriftEventRepository(env.db).get('e1'));
    expect(e, isNull);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('cancelar la confirmación no borra', (tester) async {
    final env = await setup(tester);
    await tester.tap(find.byKey(const Key('deleteEventButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    final e = await runDb(tester, () => DriftEventRepository(env.db).get('e1'));
    expect(e, isNotNull);
  });
}
```
(El evento de prueba no tiene adjuntos a propósito: borrar archivos reales es E/S real y se prueba en `attachment_store_test`.)

- [ ] **Step 2: Ejecutar y ver que falla**

Run: `flutter test test/ui/event_detail_test.dart`
Expected: FAIL

- [ ] **Step 3: Implementar**

`lib/ui/events/event_detail_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/models.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets.dart';

class EventDetail {
  const EventDetail(this.event, this.attachments, this.treatment, this.pet);
  final HealthEvent event;
  final List<Attachment> attachments;
  final Treatment? treatment;
  final Pet? pet;
}

final eventDetailProvider =
    FutureProvider.autoDispose.family<EventDetail?, String>((ref, id) async {
  final events = ref.read(eventRepoProvider);
  final event = await events.get(id);
  if (event == null) return null;
  final attachments = await events.attachmentsFor(id);
  final treatment = event.treatmentId == null
      ? null
      : await ref.read(treatmentRepoProvider).get(event.treatmentId!);
  final pet = await ref.read(petRepoProvider).get(event.petId);
  return EventDetail(event, attachments, treatment, pet);
});

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.eventId});
  final String eventId;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar este registro?'),
        content: const Text('También se borrarán sus fotos. Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;
    final paths = await ref.read(eventRepoProvider).delete(eventId);
    final store = ref.read(attachmentStoreProvider);
    for (final p in paths) {
      await store.delete(p);
    }
    if (context.mounted) context.pop();
  }

  void _openPhoto(BuildContext context, WidgetRef ref, Attachment a) {
    final file = ref.read(attachmentStoreProvider).fileFor(a.relativePath);
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(child: Image.file(file)),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(eventDetailProvider(eventId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle'),
        actions: [
          IconButton(
            key: const Key('deleteEventButton'),
            icon: const Icon(Icons.delete_outline, color: AppColors.coral),
            onPressed: () => _delete(context, ref),
          ),
        ],
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('No se pudo cargar el registro')),
        data: (d) {
          if (d == null) return const Center(child: Text('Este registro ya no existe'));
          final e = d.event;
          Widget row(String label, String? value) => value == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(width: 110, child: Text(label, style: const TextStyle(color: AppColors.inkSoft))),
                    Expanded(child: Text(value)),
                  ]),
                );
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppCard(
                child: Row(children: [
                  Icon(iconForType(e.type), color: AppColors.primary, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      Text(e.type.label, style: const TextStyle(color: AppColors.inkSoft)),
                    ]),
                  ),
                ]),
              ),
              AppCard(
                child: Column(children: [
                  row('Mascota', d.pet?.name),
                  row('Fecha', fmtDateTime(e.occurredAt)),
                  row('Producto', e.product),
                  row('Lote', e.lot),
                  row('Veterinario', e.vetName),
                  row('Clínica', e.clinic),
                  row('Peso', e.weightKg == null ? null : '${e.weightKg} kg'),
                  row('Notas', e.notes),
                ]),
              ),
              if (d.treatment != null && d.treatment!.active)
                AppCard(
                  stripe: AppColors.primary,
                  child: Text('Próxima dosis: ${fmtDay(d.treatment!.nextDueDate)}'),
                ),
              if (d.attachments.isNotEmpty) ...[
                const SectionHeader('Comprobante y carnet'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final a in d.attachments)
                    GestureDetector(
                      onTap: () => _openPhoto(context, ref, a),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          ref.read(attachmentStoreProvider).fileFor(a.relativePath),
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(width: 96, height: 96, child: Icon(Icons.broken_image)),
                        ),
                      ),
                    ),
                ]),
              ],
            ],
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 4: Ruta**

En `lib/app/router.dart` (después de `/events/new`):
```dart
GoRoute(
  path: '/events/:id',
  parentNavigatorKey: rootNavigatorKey,
  builder: (_, s) => EventDetailScreen(eventId: s.pathParameters['id']!),
),
```

- [ ] **Step 5: Ejecutar y ver que pasa**

Run: `flutter test test/ui/event_detail_test.dart && flutter analyze`
Expected: PASS y sin problemas.

- [ ] **Step 6: Commit**

```bash
git add lib test
git commit -m "feat(ui): event detail with delete"
```

---

### Task 14: Exportación a PDF

**Files:**
- Create: `lib/services/pdf_exporter.dart`, `lib/services/share_service.dart`, `lib/ui/share_helpers.dart`
- Modify: `lib/app/providers.dart`, `test/helpers/pump_app.dart`
- Test: `test/services/pdf_exporter_test.dart`

**Interfaces:**
- Consumes: `Pet`, `HealthEvent`, `Treatment`.
- Produces:
```dart
class PdfExporter {
  const PdfExporter();
  Future<Uint8List> history({required Pet pet, required List<HealthEvent> events, required DateTime generatedAt});
  Future<Uint8List> carnet({required Pet pet, required List<HealthEvent> vaccines,
      required Map<String, Treatment> treatmentsById, required DateTime generatedAt});
}
typedef ShareFile = Future<void> Function(String path);
Future<void> shareFileWithSystem(String path);          // único lugar que toca share_plus
final pdfExporterProvider, shareFileProvider            // en providers.dart
Future<void> sharePdf(WidgetRef ref, Uint8List bytes, String filename);   // ui/share_helpers.dart
```

- [ ] **Step 1: Prueba que falla**

`test/services/pdf_exporter_test.dart`:
```dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/domain/enums.dart';
import 'package:huellitas/services/pdf_exporter.dart';

import '../helpers/samples.dart';

bool isPdf(Uint8List b) => String.fromCharCodes(b.take(4)) == '%PDF';

void main() {
  const exporter = PdfExporter();
  final at = DateTime(2024, 10, 24);

  test('historial con acentos genera un PDF', () async {
    final bytes = await exporter.history(
      pet: samplePet(name: 'Ñandú'),
      events: [
        sampleEvent(title: 'Desparasitación interna', notes: 'Sin reacción gastrointestinal'),
        sampleEvent(id: 'e2', type: EventType.checkup, title: 'Consulta de rutina'),
      ],
      generatedAt: at,
    );
    expect(isPdf(bytes), isTrue);
  });

  test('historial sin eventos también genera PDF', () async {
    final bytes = await exporter.history(pet: samplePet(), events: const [], generatedAt: at);
    expect(isPdf(bytes), isTrue);
  });

  test('carnet con y sin tratamiento asociado genera PDF', () async {
    final bytes = await exporter.carnet(
      pet: samplePet(),
      vaccines: [sampleEvent(treatmentId: 't1'), sampleEvent(id: 'e2', title: 'Giardia')],
      treatmentsById: {'t1': sampleTreatment()},
      generatedAt: at,
    );
    expect(isPdf(bytes), isTrue);
  });
}
```

- [ ] **Step 2: Ejecutar y ver que falla**

Run: `flutter test test/services/pdf_exporter_test.dart`
Expected: FAIL

- [ ] **Step 3: Implementar el generador** **[API]**

`lib/services/pdf_exporter.dart`:
```dart
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/enums.dart';
import '../domain/models.dart';

// El PDF usa la fuente estándar (Latin-1): acentos y ñ funcionan; evitar
// símbolos como viñetas o guiones largos.
const _disclaimer =
    'Documento generado por la persona usuaria con Huellitas a partir de sus propios registros. '
    'No es un documento oficial ni sustituye el carnet del veterinario.';

class PdfExporter {
  const PdfExporter();

  static final _day = DateFormat('dd/MM/yyyy');

  String _petLine(Pet p) {
    final parts = <String>[
      switch (p.species) {
        PetSpecies.dog => 'Perro',
        PetSpecies.cat => 'Gato',
        PetSpecies.other => 'Otra mascota',
      },
      if (p.breed != null) p.breed!,
      if (p.birthDate != null) 'Nacimiento: ${_day.format(p.birthDate!)}',
      if (p.microchip != null) 'Microchip: ${p.microchip}',
    ];
    return parts.join(' - ');
  }

  String _vet(HealthEvent e) =>
      [e.vetName, e.clinic].whereType<String>().where((s) => s.isNotEmpty).join(' / ');

  pw.TextStyle get _small => const pw.TextStyle(fontSize: 8);

  Future<Uint8List> history({
    required Pet pet,
    required List<HealthEvent> events,
    required DateTime generatedAt,
  }) async {
    final doc = pw.Document();
    doc.addPage(pw.MultiPage(
      build: (_) => [
        pw.Header(
          level: 0,
          child: pw.Text('Historial de salud - ${pet.name}',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Text(_petLine(pet)),
        pw.SizedBox(height: 12),
        if (events.isEmpty)
          pw.Text('Sin registros.')
        else
          pw.TableHelper.fromTextArray(
            headers: ['Fecha', 'Tipo', 'Detalle', 'Veterinario'],
            data: [
              for (final e in events)
                [
                  _day.format(e.occurredAt),
                  e.type.label,
                  [e.title, if (e.lot != null) 'Lote ${e.lot}', if (e.notes != null) e.notes!].join(' - '),
                  _vet(e),
                ],
            ],
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
        pw.SizedBox(height: 16),
        pw.Text('Generado el ${_day.format(generatedAt)}', style: _small),
        pw.Text(_disclaimer, style: _small),
      ],
    ));
    return doc.save();
  }

  Future<Uint8List> carnet({
    required Pet pet,
    required List<HealthEvent> vaccines,
    required Map<String, Treatment> treatmentsById,
    required DateTime generatedAt,
  }) async {
    final doc = pw.Document();
    doc.addPage(pw.MultiPage(
      build: (_) => [
        pw.Header(
          level: 0,
          child: pw.Text('Carnet de vacunacion - ${pet.name}',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Text(_petLine(pet)),
        pw.SizedBox(height: 12),
        if (vaccines.isEmpty)
          pw.Text('Aun no hay vacunas registradas.')
        else
          pw.TableHelper.fromTextArray(
            headers: ['Vacuna', 'Aplicada', 'Lote', 'Proxima', 'Veterinario'],
            data: [
              for (final e in vaccines)
                [
                  e.title,
                  _day.format(e.occurredAt),
                  e.lot ?? '',
                  _next(treatmentsById[e.treatmentId]),
                  _vet(e),
                ],
            ],
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
        pw.SizedBox(height: 16),
        pw.Text('Generado el ${_day.format(generatedAt)}', style: _small),
        pw.Text(_disclaimer, style: _small),
      ],
    ));
    return doc.save();
  }

  String _next(Treatment? t) => (t != null && t.active) ? _day.format(t.nextDueDate) : '';
}
```

- [ ] **Step 4: Compartir y providers** **[API]**

`lib/services/share_service.dart`:
```dart
import 'package:share_plus/share_plus.dart';

typedef ShareFile = Future<void> Function(String path);

/// Único lugar que toca share_plus. [API] en versiones recientes se usa
/// `SharePlus.instance.share(ShareParams(files: [...]))`; en anteriores,
/// `Share.shareXFiles([...])`.
Future<void> shareFileWithSystem(String path) async {
  await SharePlus.instance.share(ShareParams(files: [XFile(path)]));
}
```

Agregar a `lib/app/providers.dart` (con los imports `../services/pdf_exporter.dart` y `../services/share_service.dart`):
```dart
final pdfExporterProvider = Provider<PdfExporter>((ref) => const PdfExporter());
final shareFileProvider = Provider<ShareFile>((ref) => shareFileWithSystem);
```

`lib/ui/share_helpers.dart`:
```dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../app/providers.dart';

/// Guarda [bytes] en la carpeta temporal y abre la hoja de compartir del sistema.
Future<void> sharePdf(WidgetRef ref, Uint8List bytes, String filename) async {
  final dir = await getTemporaryDirectory();
  final file = File(p.join(dir.path, filename));
  await file.writeAsBytes(bytes);
  await ref.read(shareFileProvider)(file.path);
}
```

En `test/helpers/pump_app.dart`, dentro de `overrides`, agregar (e importar `providers.dart` ya está):
```dart
        shareFileProvider.overrideWithValue((path) async => shared.add(path)),
```

- [ ] **Step 5: Ejecutar y ver que pasa**

Run: `flutter test test/services/pdf_exporter_test.dart && flutter analyze`
Expected: PASS y sin problemas.

- [ ] **Step 6: Commit**

```bash
git add lib test
git commit -m "feat(services): PDF export for history and vaccination record"
```

---

### Task 15: Historial (filtros, búsqueda, PDF)

**Files:**
- Create: `lib/domain/history_logic.dart`, `lib/ui/history/history_screen.dart`
- Modify: `lib/app/router.dart`
- Test: `test/domain/history_logic_test.dart`, `test/ui/history_screen_test.dart`

**Interfaces:**
- Consumes: `foldText`, `eventsForPetProvider`, `PdfExporter.history`, `sharePdf`.
- Produces:
```dart
List<HealthEvent> filterEvents(List<HealthEvent> events, {EventType? type, String query = ''});
class MonthGroup { final int year; final int month; final List<HealthEvent> events; }
List<MonthGroup> groupByMonth(List<HealthEvent> events);   // grupos del más reciente al más antiguo
class HistoryScreen extends ConsumerStatefulWidget {}
```

- [ ] **Step 1: Pruebas que fallan**

`test/domain/history_logic_test.dart`:
```dart
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
```

`test/ui/history_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/data/drift_repositories.dart';
import 'package:huellitas/domain/enums.dart';
import 'package:huellitas/ui/history/history_screen.dart';

import '../helpers/pump_app.dart';
import '../helpers/samples.dart';

void main() {
  testWidgets('filtra por búsqueda y por tipo, y permite restablecer', (tester) async {
    final env = await createEnv();
    await runDb(tester, () async {
      await DriftPetRepository(env.db).save(samplePet());
      final events = DriftEventRepository(env.db);
      await events.save(sampleEvent(id: 'a', title: 'Antirrábica', occurredAt: DateTime(2024, 10, 15)), const []);
      await events.save(
          sampleEvent(id: 'b', type: EventType.deworming, title: 'Desparasitación interna', occurredAt: DateTime(2024, 8, 10)),
          const []);
      await events.save(
          sampleEvent(id: 'c', type: EventType.checkup, title: 'Consulta dental', occurredAt: DateTime(2024, 8, 2)),
          const []);
    });
    await pumpScreen(tester, env, const HistoryScreen());

    expect(find.text('Antirrábica'), findsOneWidget);
    expect(find.text('Consulta dental'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('historySearch')), 'rabi');
    await tester.pumpAndSettle();
    expect(find.text('Antirrábica'), findsOneWidget);
    expect(find.text('Consulta dental'), findsNothing);

    await tester.enterText(find.byKey(const Key('historySearch')), '');
    await tester.tap(find.text('Consultas'));
    await tester.pumpAndSettle();
    expect(find.text('Consulta dental'), findsOneWidget);
    expect(find.text('Antirrábica'), findsNothing);

    await tester.enterText(find.byKey(const Key('historySearch')), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('Sin coincidencias'), findsOneWidget);

    await tester.tap(find.text('Restablecer filtros'));
    await tester.pumpAndSettle();
    expect(find.text('Antirrábica'), findsOneWidget);
    expect(find.text('Consulta dental'), findsOneWidget);
  });

  testWidgets('sin registros muestra el estado vacío', (tester) async {
    final env = await createEnv();
    await runDb(tester, () => DriftPetRepository(env.db).save(samplePet()));
    await pumpScreen(tester, env, const HistoryScreen());
    expect(find.text('Aún no hay registros'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Ejecutar y ver que fallan**

Run: `flutter test test/domain/history_logic_test.dart test/ui/history_screen_test.dart`
Expected: FAIL

- [ ] **Step 3: Lógica pura**

`lib/domain/history_logic.dart`:
```dart
import 'enums.dart';
import 'models.dart';
import 'text.dart';

String _haystack(HealthEvent e) => foldText(
      [e.title, e.product, e.notes, e.vetName, e.clinic, e.lot].whereType<String>().join(' '),
    );

List<HealthEvent> filterEvents(
  List<HealthEvent> events, {
  EventType? type,
  String query = '',
}) {
  final q = foldText(query.trim());
  return [
    for (final e in events)
      if ((type == null || e.type == type) && (q.isEmpty || _haystack(e).contains(q))) e,
  ];
}

class MonthGroup {
  MonthGroup(this.year, this.month, this.events);
  final int year;
  final int month;
  final List<HealthEvent> events;
}

List<MonthGroup> groupByMonth(List<HealthEvent> events) {
  final sorted = [...events]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  final groups = <MonthGroup>[];
  for (final e in sorted) {
    final last = groups.isEmpty ? null : groups.last;
    if (last != null && last.year == e.occurredAt.year && last.month == e.occurredAt.month) {
      last.events.add(e);
    } else {
      groups.add(MonthGroup(e.occurredAt.year, e.occurredAt.month, [e]));
    }
  }
  return groups;
}
```

- [ ] **Step 4: Pantalla**

`lib/ui/history/history_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../domain/enums.dart';
import '../../domain/history_logic.dart';
import '../../domain/models.dart';
import '../format.dart';
import '../share_helpers.dart';
import '../theme.dart';
import '../widgets.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _search = TextEditingController();
  EventType? _type;
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reset() => setState(() {
        _type = null;
        _query = '';
        _search.clear();
      });

  Future<void> _export(Pet pet, List<HealthEvent> events) async {
    final bytes = await ref.read(pdfExporterProvider).history(
          pet: pet,
          events: events,
          generatedAt: ref.read(clockProvider)(),
        );
    await sharePdf(ref, bytes, 'historial-${pet.name}.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final pets = ref.watch(petsProvider).asData?.value ?? const <Pet>[];
    final pet = ref.watch(currentPetProvider);
    if (pet == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Historial')),
        body: const Center(child: Text('Agrega una mascota para ver su historial')),
      );
    }
    final all = ref.watch(eventsForPetProvider(pet.id)).asData?.value ?? const <HealthEvent>[];
    final shown = filterEvents(all, type: _type, query: _query);
    final groups = groupByMonth(shown);
    final monthFmt = DateFormat('MMMM y', 'es_MX');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        actions: [
          IconButton(
            key: const Key('exportHistoryPdf'),
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar PDF',
            onPressed: () => _export(pet, all),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (pets.length > 1)
            Wrap(spacing: 8, children: [
              for (final p in pets)
                ChoiceChip(
                  label: Text(p.name),
                  selected: p.id == pet.id,
                  onSelected: (_) => ref.read(selectedPetIdProvider.notifier).select(p.id),
                ),
            ]),
          const SizedBox(height: 8),
          TextField(
            key: const Key('historySearch'),
            controller: _search,
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar en el historial'),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(label: const Text('Todo'), selected: _type == null, onSelected: (_) => setState(() => _type = null)),
              ),
              for (final t in EventType.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(t.pluralLabel),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  ),
                ),
            ]),
          ),
          if (all.isEmpty)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Aún no hay registros')))
          else if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(children: [
                const Icon(Icons.search_off, size: 48, color: AppColors.inkFaint),
                const SizedBox(height: 8),
                const Text('Sin coincidencias'),
                const SizedBox(height: 12),
                FilledButton.tonal(onPressed: _reset, child: const Text('Restablecer filtros')),
              ]),
            )
          else
            for (final g in groups) ...[
              SectionHeader(toBeginningOfSentenceCase(monthFmt.format(DateTime(g.year, g.month))) ?? ''),
              for (final e in g.events) _EventTile(event: e),
            ],
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});
  final HealthEvent event;

  @override
  Widget build(BuildContext context) {
    final vet = [event.vetName, event.clinic].whereType<String>().join(' | ');
    return AppCard(
      onTap: () => context.push('/events/${event.id}'),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(iconForType(event.type), color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(event.title, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(fmtDateTime(event.occurredAt), style: const TextStyle(color: AppColors.inkSoft)),
            if (vet.isNotEmpty) Text(vet, style: const TextStyle(color: AppColors.inkSoft)),
            if (event.notes != null) Text(event.notes!, maxLines: 2, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ]),
    );
  }
}
```

- [ ] **Step 5: Ruta y verificación**

En `lib/app/router.dart`: importar `HistoryScreen` y reemplazar el stub de `/history`.

Run: `flutter test test/domain/history_logic_test.dart test/ui/history_screen_test.dart && flutter analyze`
Expected: PASS y sin problemas.

- [ ] **Step 6: Commit**

```bash
git add lib test
git commit -m "feat(ui): history with filters, search and PDF export"
```

---

### Task 16: Perfil de mascota y peso

**Files:**
- Create: `lib/domain/weight_logic.dart`, `lib/ui/profile/profile_screen.dart`, `lib/ui/profile/weight_screen.dart`
- Modify: `lib/app/router.dart`
- Test: `test/domain/weight_logic_test.dart`, `test/ui/profile_screen_test.dart`, `test/ui/weight_screen_test.dart`

**Interfaces:**
- Consumes: `WeightRepository`, `weightsForPetProvider`, `ageLabel`, `dueStatus/dueLabel`.
- Produces:
```dart
class WeightTrend { final double current; final double? deltaVsMonthAgo; }
WeightTrend? weightTrend(List<WeightEntry> entries, DateTime today);   // delta frente al último registro de hace 30 días o más
class ProfileScreen extends ConsumerWidget { ProfileScreen({required String petId}); }
class WeightScreen extends ConsumerWidget { WeightScreen({required String petId}); }
```
Rutas: `/pets/:id`, `/pets/:id/weight`. Sin «rango ideal» ni etiquetas «Óptimo/Ideal» (decisión de la spec).

- [ ] **Step 1: Pruebas que fallan**

`test/domain/weight_logic_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/domain/models.dart';
import 'package:huellitas/domain/weight_logic.dart';

WeightEntry w(String id, DateTime d, double kg) => WeightEntry(id: id, petId: 'p1', date: d, kg: kg);

void main() {
  final today = DateTime.utc(2024, 10, 24);

  test('sin registros es nulo', () {
    expect(weightTrend(const [], today), isNull);
  });

  test('un solo registro: peso actual y sin variación', () {
    final t = weightTrend([w('a', DateTime.utc(2024, 10, 1), 28.5)], today)!;
    expect(t.current, 28.5);
    expect(t.deltaVsMonthAgo, isNull);
  });

  test('variación frente al último registro de hace 30 días o más', () {
    final t = weightTrend([
      w('a', DateTime.utc(2024, 10, 1), 28.5),
      w('b', DateTime.utc(2024, 8, 3), 28.2),
      w('c', DateTime.utc(2024, 6, 10), 27.9),
    ], today)!;
    expect(t.current, 28.5);
    expect(t.deltaVsMonthAgo, closeTo(0.3, 0.0001));
  });

  test('si todos los registros son recientes no hay variación', () {
    final t = weightTrend([
      w('a', DateTime.utc(2024, 10, 20), 28.5),
      w('b', DateTime.utc(2024, 10, 10), 28.2),
    ], today)!;
    expect(t.deltaVsMonthAgo, isNull);
  });

  test('no depende del orden de entrada', () {
    final t = weightTrend([
      w('c', DateTime.utc(2024, 6, 10), 27.9),
      w('a', DateTime.utc(2024, 10, 1), 28.5),
    ], today)!;
    expect(t.current, 28.5);
    expect(t.deltaVsMonthAgo, closeTo(0.6, 0.0001));
  });
}
```

`test/ui/profile_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/data/drift_repositories.dart';
import 'package:huellitas/ui/profile/profile_screen.dart';

import '../helpers/pump_app.dart';
import '../helpers/samples.dart';

void main() {
  Future<TestEnv> setup(WidgetTester tester) async {
    final env = await createEnv(); // hoy = 24 oct 2024
    await runDb(tester, () async {
      await DriftPetRepository(env.db).save(samplePet());
      await DriftTreatmentRepository(env.db).save(sampleTreatment(nextDue: DateTime.utc(2024, 10, 21)));
    });
    await pumpScreen(tester, env, const ProfileScreen(petId: 'p1'));
    return env;
  }

  testWidgets('muestra datos de la mascota y el estado de protección', (tester) async {
    await setup(tester);
    expect(find.text('Toby'), findsWidgets);
    expect(find.text('3a 4m'), findsOneWidget);
    expect(find.text('Antirrábica'), findsOneWidget);
    expect(find.text('Atrasada · hace 3 días'), findsOneWidget);
    expect(find.text('Dra. Carmen Morales'), findsOneWidget);
  });

  testWidgets('archivar pide confirmación y oculta a la mascota', (tester) async {
    final env = await setup(tester);
    await tester.ensureVisible(find.text('Archivar mascota'));
    await tester.tap(find.text('Archivar mascota'));
    await tester.pumpAndSettle();
    expect(find.text('¿Archivar a Toby?'), findsOneWidget);

    await tester.tap(find.text('Archivar'));
    await tester.pumpAndSettle();

    final visible = await runDb(tester, () => DriftPetRepository(env.db).watchAll().first);
    expect(visible, isEmpty);
    expect(find.text('NAV:/pets'), findsOneWidget);
    expect(env.scheduler.syncCount, greaterThan(0));
  });
}
```

`test/ui/weight_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/data/drift_repositories.dart';
import 'package:huellitas/domain/models.dart';
import 'package:huellitas/ui/profile/weight_screen.dart';

import '../helpers/pump_app.dart';
import '../helpers/samples.dart';

void main() {
  Future<TestEnv> setup(WidgetTester tester) async {
    final env = await createEnv(); // hoy = 24 oct 2024
    await runDb(tester, () async {
      await DriftPetRepository(env.db).save(samplePet());
      final weights = DriftWeightRepository(env.db);
      await weights.save(WeightEntry(id: 'w1', petId: 'p1', date: DateTime.utc(2024, 10, 1), kg: 28.5));
      await weights.save(WeightEntry(id: 'w2', petId: 'p1', date: DateTime.utc(2024, 8, 3), kg: 28.2));
    });
    await pumpScreen(tester, env, const WeightScreen(petId: 'p1'));
    return env;
  }

  testWidgets('muestra peso actual y variación; no muestra rango ideal', (tester) async {
    await setup(tester);
    expect(find.text('28.5 kg'), findsWidgets);
    expect(find.textContaining('+0.3 kg vs mes pasado'), findsOneWidget);
    expect(find.textContaining('Rango ideal'), findsNothing);
    expect(find.textContaining('Óptimo'), findsNothing);
  });

  testWidgets('registrar peso valida y guarda con coma decimal', (tester) async {
    final env = await setup(tester);
    await tester.tap(find.text('Registrar peso'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('weightField')), '0');
    await tester.tap(find.text('Guardar peso'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe un peso válido'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('weightField')), '29,1');
    await tester.tap(find.text('Guardar peso'));
    await tester.pumpAndSettle();

    final list = await runDb(tester, () => DriftWeightRepository(env.db).watchForPet('p1').first);
    expect(list.first.kg, 29.1);
    expect(list.length, 3);
  });
}
```

- [ ] **Step 2: Ejecutar y ver que fallan**

Run: `flutter test test/domain/weight_logic_test.dart test/ui/profile_screen_test.dart test/ui/weight_screen_test.dart`
Expected: FAIL

- [ ] **Step 3: Lógica de peso**

`lib/domain/weight_logic.dart`:
```dart
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
```
(El caso «no depende del orden» espera `0.6` = 28.5 − 27.9: `double.parse(...toStringAsFixed(1))` da `0.6`; `closeTo` cubre el redondeo.)

- [ ] **Step 4: Pantalla de peso**

`lib/ui/profile/weight_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/dates.dart';
import '../../domain/models.dart';
import '../../domain/weight_logic.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets.dart';

class WeightScreen extends ConsumerWidget {
  const WeightScreen({super.key, required this.petId});
  final String petId;

  Future<void> _add(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _AddWeightSheet(petId: petId),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(weightsForPetProvider(petId)).asData?.value ?? const <WeightEntry>[];
    final now = ref.watch(clockProvider)();
    final trend = weightTrend(entries, now);
    final delta = trend?.deltaVsMonthAgo;

    return Scaffold(
      appBar: AppBar(title: const Text('Peso')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(Icons.add),
        label: const Text('Registrar peso'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          AppCard(
            child: trend == null
                ? const Text('Aún no hay registros de peso.')
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Peso actual', style: TextStyle(color: AppColors.inkSoft)),
                    Text('${trend.current.toStringAsFixed(1)} kg',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                    if (delta != null)
                      Text('${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} kg vs mes pasado',
                          style: const TextStyle(color: AppColors.inkSoft)),
                  ]),
          ),
          if (entries.length >= 2)
            AppCard(
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: CustomPaint(painter: _WeightChartPainter(entries)),
              ),
            ),
          const SectionHeader('Registros'),
          for (final e in entries)
            Dismissible(
              key: ValueKey(e.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                color: AppColors.coral,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) => ref.read(weightRepoProvider).delete(e.id),
              child: AppCard(
                child: Row(children: [
                  const Icon(Icons.scale, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${e.kg.toStringAsFixed(1)} kg', style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text([fmtDay(e.date), if (e.note != null) e.note!].join(' · '),
                          style: const TextStyle(color: AppColors.inkSoft)),
                    ]),
                  ),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

class _WeightChartPainter extends CustomPainter {
  _WeightChartPainter(List<WeightEntry> entries)
      : points = ([...entries]..sort((a, b) => a.date.compareTo(b.date)));
  final List<WeightEntry> points;

  @override
  void paint(Canvas canvas, Size size) {
    final minKg = points.map((p) => p.kg).reduce((a, b) => a < b ? a : b);
    final maxKg = points.map((p) => p.kg).reduce((a, b) => a > b ? a : b);
    final range = (maxKg - minKg) == 0 ? 1.0 : (maxKg - minKg);
    final t0 = points.first.date.millisecondsSinceEpoch;
    final span = (points.last.date.millisecondsSinceEpoch - t0).clamp(1, 1 << 62);

    Offset at(WeightEntry p) => Offset(
          (p.date.millisecondsSinceEpoch - t0) / span * (size.width - 16) + 8,
          size.height - 16 - (p.kg - minKg) / range * (size.height - 32),
        );

    final line = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(at(points.first).dx, at(points.first).dy);
    for (final p in points.skip(1)) {
      path.lineTo(at(p).dx, at(p).dy);
    }
    canvas.drawPath(path, line);
    final dot = Paint()..color = AppColors.primary;
    for (final p in points) {
      canvas.drawCircle(at(p), 4, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter old) => old.points != points;
}

class _AddWeightSheet extends ConsumerStatefulWidget {
  const _AddWeightSheet({required this.petId});
  final String petId;

  @override
  ConsumerState<_AddWeightSheet> createState() => _AddWeightSheetState();
}

class _AddWeightSheetState extends ConsumerState<_AddWeightSheet> {
  final _formKey = GlobalKey<FormState>();
  final _kg = TextEditingController();
  final _note = TextEditingController();
  late DateTime _date = ref.read(clockProvider)();

  @override
  void dispose() {
    _kg.dispose();
    _note.dispose();
    super.dispose();
  }

  double? get _parsed => double.tryParse(_kg.text.trim().replaceAll(',', '.'));

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: ref.read(clockProvider)(),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final note = _note.text.trim();
    await ref.read(weightRepoProvider).save(WeightEntry(
          id: ref.read(idGeneratorProvider)(),
          petId: widget.petId,
          date: dateOnly(_date),
          kg: _parsed!,
          note: note.isEmpty ? null : note,
        ));
    if (mounted) Navigator.of(context).pop(); // hoja modal, no es una ruta de go_router
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Agregar peso', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('weightField'),
              controller: _kg,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Peso en kg'),
              validator: (v) {
                final w = _parsed;
                return (w == null || w <= 0 || w >= 300) ? 'Escribe un peso válido' : null;
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fecha'),
              subtitle: Text(fmtDay(_date)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            TextFormField(controller: _note, decoration: const InputDecoration(labelText: 'Nota (opcional)')),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Guardar peso')),
          ]),
        ),
      );
}
```

- [ ] **Step 5: Pantalla de perfil**

`lib/ui/profile/profile_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/age.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../../domain/treatment_status.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, required this.petId});
  final String petId;

  Future<void> _archive(BuildContext context, WidgetRef ref, Pet pet) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('¿Archivar a ${pet.name}?'),
        content: const Text('Dejará de aparecer y de generar avisos. Su historial se conserva en los respaldos.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Archivar')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(petRepoProvider).archive(pet.id);
    ref.read(selectedPetIdProvider.notifier).select(null);
    await ref.read(reminderCoordinatorProvider).sync();
    if (context.mounted) context.go('/pets');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pets = ref.watch(petsProvider).asData?.value ?? const <Pet>[];
    final pet = pets.where((p) => p.id == petId).firstOrNull;
    if (pet == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }
    final now = ref.watch(clockProvider)();
    final treatments = (ref.watch(activeTreatmentsProvider).asData?.value ?? const <Treatment>[])
        .where((t) => t.petId == petId)
        .toList();
    final events = ref.watch(eventsForPetProvider(petId)).asData?.value ?? const <HealthEvent>[];
    final weights = ref.watch(weightsForPetProvider(petId)).asData?.value ?? const <WeightEntry>[];
    final lastWeight = weights.firstOrNull;

    HealthEvent? lastFor(Treatment t) => events.where((e) => e.treatmentId == t.id).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(pet.name),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: () => context.push('/pets/${pet.id}/edit')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: PetAvatar(pet: pet, size: 96)),
          const SizedBox(height: 12),
          Center(child: Text(pet.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700))),
          Center(
            child: Text(
              [
                pet.breed ?? speciesLabel(pet.species),
                if (pet.sex != null) (pet.sex == PetSex.male ? 'Macho' : 'Hembra'),
                if (pet.neutered) 'Esterilizado',
              ].join(' • '),
              style: const TextStyle(color: AppColors.inkSoft),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Edad', style: TextStyle(color: AppColors.inkSoft)),
                  Text(pet.birthDate == null ? '-' : ageLabel(pet.birthDate!, now),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                ]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppCard(
                onTap: () => context.push('/pets/${pet.id}/weight'),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Peso', style: TextStyle(color: AppColors.inkSoft)),
                  Text(lastWeight == null ? 'Registrar' : '${lastWeight.kg.toStringAsFixed(1)} kg',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                ]),
              ),
            ),
          ]),
          if (pet.microchip != null)
            AppCard(
              child: Row(children: [
                const Icon(Icons.tag, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(child: Text('Microchip ${pet.microchip}')),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () => Clipboard.setData(ClipboardData(text: pet.microchip!)),
                ),
              ]),
            ),
          const SectionHeader('Estatus de protección'),
          if (treatments.isEmpty)
            const AppCard(child: Text('Aún no hay vacunas ni tratamientos con repetición.')),
          for (final t in treatments)
            AppCard(
              child: Row(children: [
                Icon(iconForType(t.type), color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                      lastFor(t) == null ? t.type.label : 'Última: ${fmtDay(lastFor(t)!.occurredAt)}',
                      style: const TextStyle(color: AppColors.inkSoft),
                    ),
                  ]),
                ),
                StatusChip.forDue(dueStatus(t.nextDueDate, now), dueLabel(t.nextDueDate, now)),
              ]),
            ),
          if (pet.allergiesNotes != null) ...[
            const SectionHeader('Alergias y condiciones'),
            AppCard(child: Text(pet.allergiesNotes!)),
          ],
          if (pet.vetName != null || pet.vetClinic != null || pet.vetPhone != null) ...[
            const SectionHeader('Veterinario'),
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (pet.vetName != null) Text(pet.vetName!),
                if (pet.vetClinic != null) Text(pet.vetClinic!, style: const TextStyle(color: AppColors.inkSoft)),
                if (pet.vetPhone != null) Text(pet.vetPhone!, style: const TextStyle(color: AppColors.inkSoft)),
              ]),
            ),
          ],
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () {
              ref.read(selectedPetIdProvider.notifier).select(pet.id);
              context.go('/history');
            },
            icon: const Icon(Icons.history_edu),
            label: const Text('Ver historial completo'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.push('/pets/${pet.id}/carnet'),
            icon: const Icon(Icons.badge),
            label: const Text('Carnet de vacunación'),
          ),
          const SizedBox(height: 8),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.coral),
            onPressed: () => _archive(context, ref, pet),
            child: const Text('Archivar mascota'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Rutas y verificación**

En `lib/app/router.dart` agregar (importando ambas pantallas), después de `/pets/:id/edit`:
```dart
GoRoute(
  path: '/pets/:id',
  parentNavigatorKey: rootNavigatorKey,
  builder: (_, s) => ProfileScreen(petId: s.pathParameters['id']!),
),
GoRoute(
  path: '/pets/:id/weight',
  parentNavigatorKey: rootNavigatorKey,
  builder: (_, s) => WeightScreen(petId: s.pathParameters['id']!),
),
```

Run: `flutter test test/domain/weight_logic_test.dart test/ui/profile_screen_test.dart test/ui/weight_screen_test.dart && flutter analyze`
Expected: PASS y sin problemas.

- [ ] **Step 7: Commit**

```bash
git add lib test
git commit -m "feat(ui): pet profile and weight tracking"
```

---

### Task 17: Carnet de vacunación

**Files:**
- Create: `lib/ui/carnet/carnet_screen.dart`
- Modify: `lib/app/router.dart`
- Test: `test/ui/carnet_screen_test.dart`

**Interfaces:**
- Consumes: `eventsForPetProvider`, `activeTreatmentsProvider`, `PdfExporter.carnet`, `sharePdf`.
- Produces: `CarnetScreen({required String petId})`; ruta `/pets/:id/carnet`. Sin sello, folio, QR, Wallet ni textos de validez oficial.

- [ ] **Step 1: Prueba que falla**

`test/ui/carnet_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/data/drift_repositories.dart';
import 'package:huellitas/domain/enums.dart';
import 'package:huellitas/ui/carnet/carnet_screen.dart';

import '../helpers/pump_app.dart';
import '../helpers/samples.dart';

void main() {
  testWidgets('lista solo vacunas, con aviso de que lo genera el usuario y sin textos oficiales', (tester) async {
    final env = await createEnv();
    await runDb(tester, () async {
      await DriftPetRepository(env.db).save(samplePet());
      await DriftTreatmentRepository(env.db).save(sampleTreatment());
      final events = DriftEventRepository(env.db);
      await events.save(sampleEvent(id: 'v', title: 'Antirrábica', treatmentId: 't1'), const []);
      await events.save(
          sampleEvent(id: 'd', type: EventType.deworming, title: 'Desparasitación interna'), const []);
    });
    await pumpScreen(tester, env, const CarnetScreen(petId: 'p1'));

    expect(find.text('Carnet de vacunación'), findsWidgets);
    expect(find.text('Resumen generado por ti a partir de tus registros'), findsOneWidget);
    expect(find.text('Antirrábica'), findsOneWidget);
    expect(find.text('Desparasitación interna'), findsNothing);
    expect(find.textContaining('Oficial'), findsNothing);
    expect(find.textContaining('SENASICA'), findsNothing);
    expect(find.textContaining('Folio'), findsNothing);
  });

  testWidgets('sin vacunas muestra el estado vacío', (tester) async {
    final env = await createEnv();
    await runDb(tester, () => DriftPetRepository(env.db).save(samplePet()));
    await pumpScreen(tester, env, const CarnetScreen(petId: 'p1'));
    expect(find.text('Aún no hay vacunas registradas'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Ejecutar y ver que falla**

Run: `flutter test test/ui/carnet_screen_test.dart`
Expected: FAIL

- [ ] **Step 3: Implementar**

`lib/ui/carnet/carnet_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/age.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../../domain/treatment_status.dart';
import '../format.dart';
import '../share_helpers.dart';
import '../theme.dart';
import '../widgets.dart';

class CarnetScreen extends ConsumerWidget {
  const CarnetScreen({super.key, required this.petId});
  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pet = (ref.watch(petsProvider).asData?.value ?? const <Pet>[])
        .where((p) => p.id == petId)
        .firstOrNull;
    if (pet == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }
    final now = ref.watch(clockProvider)();
    final vaccines = (ref.watch(eventsForPetProvider(petId)).asData?.value ?? const <HealthEvent>[])
        .where((e) => e.type == EventType.vaccine)
        .toList();
    final treatments = {
      for (final t in ref.watch(activeTreatmentsProvider).asData?.value ?? const <Treatment>[]) t.id: t,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Carnet de vacunación')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            stripe: AppColors.primary,
            child: const Row(children: [
              Icon(Icons.info_outline, color: AppColors.primary),
              SizedBox(width: 12),
              Expanded(child: Text('Resumen generado por ti a partir de tus registros')),
            ]),
          ),
          AppCard(
            child: Row(children: [
              PetAvatar(pet: pet, size: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(pet.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  Text(
                    [
                      pet.breed ?? speciesLabel(pet.species),
                      if (pet.birthDate != null) ageLabel(pet.birthDate!, now),
                    ].join(' • '),
                    style: const TextStyle(color: AppColors.inkSoft),
                  ),
                  if (pet.microchip != null)
                    Text('Microchip ${pet.microchip}', style: const TextStyle(color: AppColors.inkSoft)),
                ]),
              ),
            ]),
          ),
          const SectionHeader('Historial de vacunas'),
          if (vaccines.isEmpty) const AppCard(child: Text('Aún no hay vacunas registradas')),
          for (final e in vaccines) _VaccineTile(event: e, treatment: treatments[e.treatmentId], now: now),
          const SizedBox(height: 8),
          FilledButton.icon(
            key: const Key('carnetPdf'),
            onPressed: () async {
              final bytes = await ref.read(pdfExporterProvider).carnet(
                    pet: pet,
                    vaccines: vaccines,
                    treatmentsById: treatments,
                    generatedAt: now,
                  );
              await sharePdf(ref, bytes, 'carnet-${pet.name}.pdf');
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Descargar PDF'),
          ),
        ],
      ),
    );
  }
}

class _VaccineTile extends StatelessWidget {
  const _VaccineTile({required this.event, required this.treatment, required this.now});
  final HealthEvent event;
  final Treatment? treatment;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final t = treatment;
    final vet = [event.vetName, event.clinic].whereType<String>().join(' | ');
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(event.title, style: const TextStyle(fontWeight: FontWeight.w700))),
          if (t != null && t.active) StatusChip.forDue(dueStatus(t.nextDueDate, now), dueLabel(t.nextDueDate, now)),
        ]),
        Text('Aplicada: ${fmtDay(event.occurredAt)}', style: const TextStyle(color: AppColors.inkSoft)),
        if (event.lot != null) Text('Lote ${event.lot}', style: const TextStyle(color: AppColors.inkSoft)),
        if (vet.isNotEmpty) Text(vet, style: const TextStyle(color: AppColors.inkSoft)),
        if (t != null && t.active)
          Text('Próxima: ${fmtDay(t.nextDueDate)}', style: const TextStyle(color: AppColors.inkSoft)),
      ]),
    );
  }
}
```

- [ ] **Step 4: Ruta y verificación**

En `lib/app/router.dart` agregar:
```dart
GoRoute(
  path: '/pets/:id/carnet',
  parentNavigatorKey: rootNavigatorKey,
  builder: (_, s) => CarnetScreen(petId: s.pathParameters['id']!),
),
```
Run: `flutter test test/ui/carnet_screen_test.dart && flutter analyze`
Expected: PASS y sin problemas.

- [ ] **Step 5: Commit**

```bash
git add lib test
git commit -m "feat(ui): vaccination record screen (user-generated summary)"
```

---

### Task 18: Ajustes, bloqueo y respaldo en la interfaz

**Files:**
- Create: `lib/services/platform_hooks.dart`, `lib/app/app_info.dart`, `lib/ui/settings/pin_pad.dart`, `lib/ui/settings/lock_screen.dart`, `lib/ui/settings/lock_gate.dart`, `lib/ui/settings/pin_setup_screen.dart`, `lib/ui/settings/settings_screen.dart`
- Modify: `lib/app/providers.dart`, `lib/app/app.dart`, `lib/app/router.dart`, `test/helpers/pump_app.dart`
- Test: `test/ui/lock_test.dart`, `test/ui/settings_screen_test.dart`

**Interfaces:**
- Consumes: `PinStore`, `AppPrefs`, `BackupService`, `ReminderCoordinator`, `PdfExporter`, `sharePdf`.
- Produces:
```dart
// services/platform_hooks.dart  — único lugar con las APIs de local_auth y file_picker
Future<bool> authenticateWithBiometrics();
Future<File?> pickBackupZip();
// providers.dart
typedef BiometricAuth = Future<bool> Function();
typedef PickBackupFile = Future<File?> Function();
final biometricAuthProvider, pickBackupFileProvider
// app/app_info.dart
const String kAppVersion = '1.0.0';
class PinPad extends StatefulWidget { PinPad({required void Function(String pin) onComplete}); }   // teclas con Key('pin_0'..'pin_9')
class LockScreen extends ConsumerStatefulWidget { LockScreen({required VoidCallback onUnlocked}); }
class LockGate extends ConsumerStatefulWidget { LockGate({required Widget child}); }
class PinSetupScreen extends ConsumerStatefulWidget {}        // ruta /settings/pin; hace pop(true) al confirmar
class SettingsScreen extends ConsumerStatefulWidget {}
```

- [ ] **Step 1: Hooks de plataforma y providers** **[API]**

`lib/services/platform_hooks.dart`:
```dart
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:local_auth/local_auth.dart';

/// Único lugar con las APIs de local_auth y file_picker, que cambian entre
/// versiones. Ajustar aquí si el analizador marca diferencias.
Future<bool> authenticateWithBiometrics() async {
  final auth = LocalAuthentication();
  try {
    if (!await auth.canCheckBiometrics) return false;
    return await auth.authenticate(
      localizedReason: 'Desbloquea Huellitas',
      biometricOnly: true,
    );
  } catch (_) {
    return false;
  }
}

Future<File?> pickBackupZip() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['zip'],
  );
  final path = result?.files.single.path;
  return path == null ? null : File(path);
}
```

Agregar a `lib/app/providers.dart` (importar `dart:io` ya está, y `../services/platform_hooks.dart`):
```dart
typedef BiometricAuth = Future<bool> Function();
typedef PickBackupFile = Future<File?> Function();

final biometricAuthProvider = Provider<BiometricAuth>((ref) => authenticateWithBiometrics);
final pickBackupFileProvider = Provider<PickBackupFile>((ref) => pickBackupZip);
```
`lib/app/app_info.dart`:
```dart
/// Mantener sincronizada con `version:` de pubspec.yaml.
const String kAppVersion = '1.0.0';
```
En `test/helpers/pump_app.dart`, agregar a `overrides`:
```dart
        biometricAuthProvider.overrideWithValue(() async => false),
```
y en `TestEnv` un campo `File? pickedBackup;` con el override
```dart
        pickBackupFileProvider.overrideWithValue(() async => pickedBackup),
```

- [ ] **Step 2: Pruebas que fallan**

`test/ui/lock_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/services/pin_store.dart';
import 'package:huellitas/ui/settings/lock_gate.dart';
import 'package:huellitas/ui/settings/lock_screen.dart';
import 'package:huellitas/ui/settings/pin_setup_screen.dart';

import '../helpers/pump_app.dart';

Future<void> enter(WidgetTester tester, String pin) async {
  for (final d in pin.split('')) {
    await tester.tap(find.byKey(Key('pin_$d')));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('LockScreen: PIN incorrecto muestra error; correcto desbloquea', (tester) async {
    final env = await createEnv();
    await PinStore(env.secrets).setPin('1234');
    var unlocked = 0;
    await pumpScreen(tester, env, LockScreen(onUnlocked: () => unlocked++));

    await enter(tester, '9999');
    expect(find.text('PIN incorrecto'), findsOneWidget);
    expect(unlocked, 0);

    await enter(tester, '1234');
    expect(unlocked, 1);
  });

  testWidgets('LockGate con bloqueo activo oculta el contenido hasta ingresar el PIN', (tester) async {
    final env = await createEnv();
    await PinStore(env.secrets).setPin('1234');
    await env.prefs.setLockEnabled(true);
    await pumpScreen(tester, env, const LockGate(child: Scaffold(body: Text('contenido'))));

    expect(find.byKey(const Key('pin_1')), findsOneWidget);
    await enter(tester, '1234');
    expect(find.byKey(const Key('pin_1')), findsNothing);
    expect(find.text('contenido'), findsOneWidget);
  });

  testWidgets('LockGate con bloqueo desactivado no muestra el teclado', (tester) async {
    final env = await createEnv();
    await pumpScreen(tester, env, const LockGate(child: Scaffold(body: Text('contenido'))));
    expect(find.byKey(const Key('pin_1')), findsNothing);
    expect(find.text('contenido'), findsOneWidget);
  });

  testWidgets('PinSetupScreen: PINes distintos reinician; iguales lo guardan', (tester) async {
    final env = await createEnv();
    await pumpScreen(tester, env, const PinSetupScreen());

    expect(find.text('Elige un PIN de 4 dígitos'), findsOneWidget);
    await enter(tester, '1234');
    expect(find.text('Confirma tu PIN'), findsOneWidget);
    await enter(tester, '4321');
    expect(find.text('Los PIN no coinciden'), findsOneWidget);
    expect(await PinStore(env.secrets).hasPin, isFalse);

    await enter(tester, '1234');
    await enter(tester, '1234');
    expect(await PinStore(env.secrets).hasPin, isTrue);
    expect(find.text('open'), findsOneWidget);
  });
}
```

`test/ui/settings_screen_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/ui/settings/settings_screen.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('muestra las secciones y que aún no hay respaldo', (tester) async {
    final env = await createEnv();
    await pumpScreen(tester, env, const SettingsScreen());
    expect(find.text('Bloquear con Face ID / huella'), findsOneWidget);
    expect(find.text('Hora del aviso'), findsOneWidget);
    expect(find.text('Exportar respaldo'), findsOneWidget);
    expect(find.text('Importar respaldo'), findsOneWidget);
    expect(find.text('Aún no has hecho un respaldo'), findsOneWidget);
    expect(find.textContaining('WhatsApp'), findsNothing);
    expect(find.textContaining('sesión'), findsNothing);
  });

  testWidgets('con respaldo previo muestra la fecha', (tester) async {
    final env = await createEnv();
    await env.prefs.setLastBackupAt(DateTime(2024, 10, 2, 12));
    await pumpScreen(tester, env, const SettingsScreen());
    expect(find.textContaining('Último respaldo'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Ejecutar y ver que fallan**

Run: `flutter test test/ui/lock_test.dart test/ui/settings_screen_test.dart`
Expected: FAIL

- [ ] **Step 4: Teclado, bloqueo y configuración de PIN**

`lib/ui/settings/pin_pad.dart`:
```dart
import 'package:flutter/material.dart';

import '../theme.dart';

/// Teclado numérico de 4 dígitos. Llama a [onComplete] con el PIN y se limpia.
class PinPad extends StatefulWidget {
  const PinPad({super.key, required this.onComplete});
  final void Function(String pin) onComplete;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _pin = '';

  void _tap(String d) {
    if (_pin.length >= 4) return;
    setState(() => _pin += d);
    if (_pin.length == 4) {
      final done = _pin;
      setState(() => _pin = '');
      widget.onComplete(done);
    }
  }

  void _back() {
    if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Widget _key(String label, VoidCallback onTap, {Key? key}) => SizedBox(
        width: 72,
        height: 56,
        child: TextButton(
          key: key,
          onPressed: onTap,
          child: Text(label, style: const TextStyle(fontSize: 24, color: AppColors.ink)),
        ),
      );

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < 4; i++)
            Container(
              margin: const EdgeInsets.all(8),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < _pin.length ? AppColors.primary : AppColors.divider,
              ),
            ),
        ]),
        const SizedBox(height: 16),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (final d in row) _key(d, () => _tap(d), key: Key('pin_$d')),
          ]),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const SizedBox(width: 72),
          _key('0', () => _tap('0'), key: const Key('pin_0')),
          SizedBox(
            width: 72,
            height: 56,
            child: IconButton(onPressed: _back, icon: const Icon(Icons.backspace_outlined)),
          ),
        ]),
      ]);
}
```

`lib/ui/settings/lock_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../theme.dart';
import 'pin_pad.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key, required this.onUnlocked});
  final VoidCallback onUnlocked;

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  bool _error = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometrics());
  }

  Future<void> _tryBiometrics() async {
    if (await ref.read(biometricAuthProvider)()) widget.onUnlocked();
  }

  Future<void> _verify(String pin) async {
    final ok = await ref.read(pinStoreProvider).verify(pin);
    if (ok) {
      widget.onUnlocked();
    } else if (mounted) {
      setState(() => _error = true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.lock, size: 48, color: AppColors.primary),
              const SizedBox(height: 12),
              Text('Huellitas', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              const Text('Ingresa tu PIN', style: TextStyle(color: AppColors.inkSoft)),
              SizedBox(
                height: 28,
                child: _error ? const Text('PIN incorrecto', style: TextStyle(color: AppColors.coral)) : null,
              ),
              PinPad(onComplete: _verify),
              TextButton(onPressed: _tryBiometrics, child: const Text('Usar Face ID o huella')),
            ]),
          ),
        ),
      );
}
```

`lib/ui/settings/lock_gate.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import 'lock_screen.dart';

/// Cubre la app con la pantalla de bloqueo al iniciar y cada vez que vuelve
/// del segundo plano, si el bloqueo está activado.
class LockGate extends ConsumerStatefulWidget {
  const LockGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate> with WidgetsBindingObserver {
  late bool _locked = ref.read(prefsProvider).lockEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && ref.read(prefsProvider).lockEnabled) {
      setState(() => _locked = true);
    }
  }

  @override
  Widget build(BuildContext context) => Stack(children: [
        widget.child,
        if (_locked)
          Positioned.fill(child: LockScreen(onUnlocked: () => setState(() => _locked = false))),
      ]);
}
```

`lib/ui/settings/pin_setup_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../theme.dart';
import 'pin_pad.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  String? _first;
  String? _error;

  Future<void> _onPin(String pin) async {
    if (_first == null) {
      setState(() {
        _first = pin;
        _error = null;
      });
    } else if (_first == pin) {
      await ref.read(pinStoreProvider).setPin(pin);
      if (mounted) context.pop(true);
    } else {
      setState(() {
        _first = null;
        _error = 'Los PIN no coinciden';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('PIN de respaldo')),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_first == null ? 'Elige un PIN de 4 dígitos' : 'Confirma tu PIN',
                style: Theme.of(context).textTheme.titleMedium),
            SizedBox(
              height: 28,
              child: _error == null ? null : Text(_error!, style: const TextStyle(color: AppColors.coral)),
            ),
            PinPad(onComplete: _onPin),
          ]),
        ),
      );
}
```

- [ ] **Step 5: Pantalla de ajustes**

`lib/ui/settings/settings_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../app/app_info.dart';
import '../../app/providers.dart';
import '../../domain/models.dart';
import '../../services/backup_service.dart';
import '../format.dart';
import '../share_helpers.dart';
import '../theme.dart';
import '../widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _toggleLock(bool enable) async {
    final prefs = ref.read(prefsProvider);
    if (enable) {
      final ok = await context.push<bool>('/settings/pin');
      if (ok == true) await prefs.setLockEnabled(true);
    } else {
      await ref.read(pinStoreProvider).clear();
      await prefs.setLockEnabled(false);
    }
    if (mounted) setState(() {});
  }

  Future<void> _pickTime() async {
    final prefs = ref.read(prefsProvider);
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: prefs.reminderHour, minute: prefs.reminderMinute),
    );
    if (t == null) return;
    await prefs.setReminderTime(t.hour, t.minute);
    await ref.read(reminderCoordinatorProvider).sync();
    if (mounted) setState(() {});
  }

  Future<void> _pickDays() async {
    final prefs = ref.read(prefsProvider);
    final d = await showDialog<int>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Avisar con anticipación'),
        children: [
          for (final n in const [1, 2, 3, 5, 7, 14])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, n),
              child: Text('$n ${n == 1 ? 'día' : 'días'} antes'),
            ),
        ],
      ),
    );
    if (d == null) return;
    await prefs.setReminderDaysBefore(d);
    if (mounted) setState(() {});
  }

  Future<void> _export() async {
    try {
      final dir = await getTemporaryDirectory();
      final file = await ref.read(backupServiceProvider).export(dir);
      await ref.read(shareFileProvider)(file.path);
      await ref.read(prefsProvider).setLastBackupAt(ref.read(clockProvider)());
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) _snack('No se pudo crear el respaldo');
    }
  }

  Future<void> _import() async {
    final file = await ref.read(pickBackupFileProvider)();
    if (file == null) return;
    final service = ref.read(backupServiceProvider);
    try {
      final prepared = await service.prepare(file);
      if (!mounted) {
        await service.discard(prepared);
        return;
      }
      final s = prepared.summary;
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Importar respaldo'),
          content: Text(
            'Se encontraron ${s.pets} ${s.pets == 1 ? 'mascota' : 'mascotas'} y ${s.events} '
            '${s.events == 1 ? 'registro' : 'registros'}. Esto reemplazará todos los datos de este teléfono. ¿Continuar?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reemplazar')),
          ],
        ),
      );
      if (ok != true) {
        await service.discard(prepared);
        return;
      }
      await service.commit(prepared);
      ref.read(selectedPetIdProvider.notifier).select(null);
      await ref.read(reminderCoordinatorProvider).sync();
      if (mounted) _snack('Respaldo importado');
    } on BackupException catch (e) {
      if (mounted) _snack(e.message);
    }
  }

  Future<void> _exportPdf() async {
    final pet = ref.read(currentPetProvider);
    if (pet == null) {
      _snack('Agrega una mascota primero');
      return;
    }
    final events = await ref.read(eventRepoProvider).watchForPet(pet.id).first;
    final bytes = await ref.read(pdfExporterProvider).history(
          pet: pet,
          events: events,
          generatedAt: ref.read(clockProvider)(),
        );
    await sharePdf(ref, bytes, 'historial-${pet.name}.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(prefsProvider);
    final notifOk = ref.watch(notificationsAllowedProvider).asData?.value ?? true;
    final last = prefs.lastBackupAt;
    final time = TimeOfDay(hour: prefs.reminderHour, minute: prefs.reminderMinute).format(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            stripe: AppColors.primary,
            child: const Row(children: [
              Icon(Icons.phonelink_lock, color: AppColors.primary),
              SizedBox(width: 12),
              Expanded(child: Text('Modo 100% sin nube: tus datos nunca salen de este teléfono.')),
            ]),
          ),
          const SectionHeader('Seguridad'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              SwitchListTile(
                key: const Key('lockSwitch'),
                title: const Text('Bloquear con Face ID / huella'),
                subtitle: const Text('Protege el historial de tus mascotas si alguien usa tu teléfono'),
                value: prefs.lockEnabled,
                onChanged: _toggleLock,
              ),
              ListTile(
                title: const Text('Cambiar PIN'),
                enabled: prefs.lockEnabled,
                trailing: const Icon(Icons.chevron_right),
                onTap: prefs.lockEnabled ? () => context.push<bool>('/settings/pin') : null,
              ),
            ]),
          ),
          const SectionHeader('Recordatorios'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              ListTile(
                title: const Text('Hora del aviso'),
                trailing: Text(time),
                onTap: _pickTime,
              ),
              ListTile(
                title: const Text('Avisar con anticipación'),
                subtitle: const Text('Valor por defecto para nuevos recordatorios'),
                trailing: Text('${prefs.reminderDaysBefore} días antes'),
                onTap: _pickDays,
              ),
              ListTile(
                title: const Text('Notificaciones'),
                trailing: StatusChip(notifOk ? 'Activadas' : 'Desactivadas', notifOk ? StatusKind.ok : StatusKind.overdue),
                onTap: notifOk
                    ? null
                    : () async {
                        await ref.read(schedulerProvider).requestPermission();
                        ref.invalidate(notificationsAllowedProvider);
                        await ref.read(reminderCoordinatorProvider).sync();
                      },
              ),
            ]),
          ),
          const SectionHeader('Respaldo'),
          const AppCard(
            child: Text('Tus datos viven solo en este teléfono. Haz un respaldo para no perderlos si cambias de celular.'),
          ),
          FilledButton.icon(onPressed: _export, icon: const Icon(Icons.upload), label: const Text('Exportar respaldo')),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Center(
              child: Text(
                last == null ? 'Aún no has hecho un respaldo' : 'Último respaldo: ${fmtDay(last)}',
                style: const TextStyle(color: AppColors.inkSoft),
              ),
            ),
          ),
          OutlinedButton.icon(onPressed: _import, icon: const Icon(Icons.download), label: const Text('Importar respaldo')),
          const SectionHeader('Datos'),
          AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Exportar historial en PDF'),
              onTap: _exportPdf,
            ),
          ),
          const SectionHeader('Acerca de'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              ListTile(
                title: const Text('Privacidad'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Privacidad'),
                    content: const Text(
                      'Huellitas guarda toda la información y las fotos solo en tu teléfono. '
                      'No tiene cuentas, no envía datos a ningún servidor y no usa publicidad ni analíticas de terceros.',
                    ),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
                  ),
                ),
              ),
              const ListTile(title: Text('Versión'), trailing: Text(kAppVersion)),
            ]),
          ),
        ],
      ),
    );
  }
}
```
(`Pet` import no usado: si el analizador lo marca, quitar `import '../../domain/models.dart';`.)

- [ ] **Step 6: Conectar bloqueo y rutas**

En `lib/app/app.dart`, dentro de `MaterialApp.router(...)` agregar:
```dart
builder: (context, child) => LockGate(child: child ?? const SizedBox.shrink()),
```
(importar `../ui/settings/lock_gate.dart`).

En `lib/app/router.dart`: importar `SettingsScreen` y `PinSetupScreen`; reemplazar el stub de `/settings` por `const SettingsScreen()` y agregar:
```dart
GoRoute(
  path: '/settings/pin',
  parentNavigatorKey: rootNavigatorKey,
  builder: (_, __) => const PinSetupScreen(),
),
```
Eliminar la clase `_Stub` si ya no se usa.

- [ ] **Step 7: Ejecutar todo**

Run: `flutter test && flutter analyze`
Expected: todas las pruebas PASS y sin problemas.

- [ ] **Step 8: Commit**

```bash
git add lib test
git commit -m "feat(ui): settings, app lock with PIN, and backup import/export UI"
```

---

### Task 19: Preparación para publicar y verificación en teléfonos reales

**Files:**
- Create: `docs/privacy-policy.md`, `docs/release-checklist.md`, `assets/icon/icon.png` (la aporta la persona)
- Modify: `pubspec.yaml`

**Interfaces:**
- Consumes: la app completa.
- Produces: política de privacidad publicable, ícono, checklist de tiendas y verificación manual.

- [ ] **Step 1: Política de privacidad**

`docs/privacy-policy.md`:
```markdown
# Política de privacidad de Huellitas

Última actualización: 11 de octubre de 2026

Huellitas es una aplicación para llevar el control de la salud de tus mascotas
(vacunas, desparasitación, antipulgas, consultas y enfermedades).

## Qué información guarda la app

La información que tú escribes (datos de tus mascotas, registros de salud, peso)
y las fotos que adjuntas se guardan **únicamente en tu teléfono**.

## Qué no hacemos

- No tenemos servidores ni cuentas de usuario.
- No enviamos tu información a ningún servidor.
- No usamos publicidad ni herramientas de analítica de terceros.
- No vendemos ni compartimos datos, porque no los recibimos.

## Permisos que solicita la app

- **Cámara y fotos:** para adjuntar fotos de recetas, carnets y de tu mascota.
- **Notificaciones:** para avisarte de vacunas y tratamientos próximos.
- **Face ID o huella:** para el bloqueo opcional. Huellitas no recibe ni guarda
  tus datos biométricos; los gestiona el sistema operativo de tu teléfono.

## Respaldos

Cuando exportas un respaldo, se crea un archivo que tú decides dónde guardar o
con quién compartir. Huellitas no sube ese archivo a ningún lado.

## Eliminar tus datos

Al desinstalar la aplicación se eliminan sus datos del teléfono. Si hiciste
respaldos, bórralos de donde los hayas guardado.

## Importante

Huellitas es una herramienta de organización personal. No sustituye la
orientación de un médico veterinario ni el carnet oficial que este te entregue.

## Contacto

Para dudas escríbenos a: <correo que elija la persona>
```

- [ ] **Step 2: Completar el contacto**

Preguntar a la persona qué correo quiere publicar como contacto (no usar ninguno por su cuenta) y reemplazar `<correo que elija la persona>`.
Run: `grep -n "<correo" docs/privacy-policy.md`
Expected: sin salida.

- [ ] **Step 3: Publicar la política**

La persona debe alojarla en una URL pública (por ejemplo, GitHub Pages o una página pública de Notion/Google Docs). Ambas tiendas piden esa URL.

- [ ] **Step 4: Ícono de la app**

La persona aporta una imagen cuadrada de 1024×1024 px sin transparencia en `assets/icon/icon.png` (se puede diseñar con Canva). Luego:
```bash
flutter pub add --dev flutter_launcher_icons
```
Agregar a `pubspec.yaml`:
```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/icon.png"
  remove_alpha_ios: true
```
Run: `dart run flutter_launcher_icons`
Expected: genera los íconos de iOS y Android sin errores.

- [ ] **Step 5: Checklist de publicación**

`docs/release-checklist.md`:
```markdown
# Checklist de publicación — Huellitas

## Cuentas (la persona)
- [ ] Apple Developer Program (99 USD/año): developer.apple.com/programs
- [ ] Google Play Console (25 USD, pago único): play.google.com/console

## Identidad y versión
- [ ] Identificador `com.huellitas.huellitas` confirmado (no se puede cambiar después de publicar)
- [ ] `version:` en pubspec.yaml y `kAppVersion` coinciden

## App Store (iOS)
- [ ] En Xcode: abrir `ios/Runner.xcworkspace`, elegir el equipo en Signing & Capabilities
- [ ] `flutter build ipa` y subir con Transporter/Xcode
- [ ] Ficha: nombre, descripción, capturas, URL de la política de privacidad
- [ ] Privacidad de la app: «Data Not Collected»
- [ ] `ITSAppUsesNonExemptEncryption` = false (ya en Info.plist)
- [ ] Clasificación por edad completada

## Google Play (Android)
- [ ] Crear llave de firma y configurar `key.properties` (guía: docs.flutter.dev/deployment/android)
- [ ] `flutter build appbundle` y subir a una pista de pruebas
- [ ] Formulario «Seguridad de los datos»: no se recopilan datos
- [ ] Clasificación de contenido y público objetivo (no dirigido a menores)
- [ ] Verificar el requisito vigente de pruebas cerradas para cuentas personales nuevas
      (Google ha exigido un mínimo de testers durante varios días antes de producción)

## Textos de la ficha
- [ ] No afirmar validez oficial, certificación ni reemplazo del veterinario
- [ ] Mencionar que los datos se guardan solo en el teléfono y que hay respaldo manual
```

- [ ] **Step 6: Verificación manual en iPhone y Android reales**

Con la app instalada (`flutter run --release` en cada teléfono), marcar cada punto:
- [ ] Onboarding → crear mascota → aparece en Inicio.
- [ ] Registrar vacuna con repetición «1 mes» y aviso de 1 día antes; en Ajustes poner la hora a 2 minutos en el futuro y verificar que **llega la notificación con la app cerrada**.
- [ ] Reiniciar el teléfono: los avisos siguen programados (al abrir la app se reprograman).
- [ ] Denegar el permiso de notificaciones: aparece el aviso en Inicio y Ajustes y la app sigue funcionando.
- [ ] Android 13 o superior: el permiso de notificaciones se solicita.
- [ ] Adjuntar foto con cámara y desde galería; se ve en el detalle; al eliminar el evento desaparece.
- [ ] Activar bloqueo (PIN + Face ID/huella); enviar la app a segundo plano y volver: pide desbloqueo. PIN erróneo muestra error.
- [ ] Exportar respaldo y guardarlo en Archivos/iCloud Drive (iPhone) y en Google Drive (Android).
- [ ] Importar ese respaldo **en otro teléfono** (o tras borrar la app): mascotas, eventos y fotos idénticos.
- [ ] Importar un archivo que no es respaldo: mensaje claro y datos intactos.
- [ ] Exportar PDF de historial y carnet: se abren y se leen bien los acentos.
- [ ] Cambiar la zona horaria del teléfono: las fechas de vencimiento **no** se mueven de día.
- [ ] Modo avión: todo funciona.

- [ ] **Step 7: Verificación final y commit**

Run: `flutter analyze && flutter test`
Expected: sin problemas; todas las pruebas PASS.
```bash
git add .
git commit -m "chore: privacy policy, release checklist and launcher icon"
```

---

## Self-Review

**1. Cobertura de la spec**

| Spec | Tarea |
|---|---|
| §2 Flutter, 100 % local, sin login, bloqueo opcional, respaldo manual | 0, 7, 8, 18 |
| §3.1 Mascotas con perfil | 10, 16 |
| §3.2 Eventos de salud con fotos | 12, 13 |
| §3.3 Tratamientos recurrentes y próxima fecha | 1, 4 |
| §3.4 Inicio «Lo que toca pronto» | 11 |
| §3.5 Historial con filtros, búsqueda, PDF | 14, 15 |
| §3.6 Historial de peso | 16 |
| §3.7 Carnet de vacunación (sin sello/oficial) | 14, 17 |
| §3.8 Ajustes: bloqueo, recordatorios, respaldo | 18 |
| §4 Modelo de datos y reglas | 2, 3, 4 |
| §5 Arquitectura en capas y repositorios | 3, 8 |
| §5 Recordatorios (solo siguiente vencimiento, ≤ 64, reprogramar) | 5, 8 (`HuellitasApp.initState`), 11–18 (`sync` tras cada cambio) |
| §5 Respaldo atómico, `schemaVersion` | 7 |
| §6 Pantallas aprobadas / eliminadas | 10–18 (sin login ni compartir; peso sin «rango ideal») |
| §7 Manejo de errores | 5 (permiso), 6 y 12 (foto), 7 (respaldo), 18 (PIN, recordatorio de respaldo vía 11) |
| §8 Pruebas automáticas 1–6 y manuales | 1–18 y 19 |
| §9 Publicación | 19 |

**2. Búsqueda de marcadores sin completar:** el único dato que el plan no puede escribir por la persona es el correo de contacto de la política (Task 19, pasos 1–2, con verificación `grep`). Los demás **[API]** son advertencias de versión, cada una con la prueba que fija el comportamiento esperado.

**3. Consistencia de tipos:** `HealthService`, `LogEventInput`, `NewAttachment`, `ReminderScheduler`, `PlannedReminder`, `PreparedBackup`, `PinStore`, `weightTrend`, `filterEvents/groupByMonth`, `homeItems/needsBackupReminder`, `shareFileProvider/sharePdf` y los nombres de providers se usan con las mismas firmas en todas las tareas que los consumen.

**4. Review Focus:** cada una de las cinco entradas tiene su prueba (Tasks 2, 3, 4, 5 y 7); la captura retroactiva que no atrasa la fecha está en Task 4.

**Interpretaciones y límites que conviene que la persona conozca**
- **«Al día»:** se interpreta como «no atrasada». El `% al día` cuenta los tratamientos no atrasados; los estados «Vence en N días» (≤ 7) y «En N días» (> 7) son informativos.
- **Editar un evento ya guardado no está en la primera versión** (se elimina y se registra de nuevo). Eliminar un evento no recalcula la fecha del tratamiento asociado.
- **Avisos inexactos en Android** (`inexactAllowWhileIdle`): pueden llegar unos minutos tarde a cambio de no pedir el permiso de alarmas exactas.
- **El código no se ejecutó al escribir este plan** (no había Flutter instalado): las APIs marcadas **[API]** pueden requerir ajustes menores al correr `flutter analyze`.
