// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $PetsTable extends Pets with TableInfo<$PetsTable, PetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PetSpecies, String> species =
      GeneratedColumn<String>(
        'species',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<PetSpecies>($PetsTable.$converterspecies);
  static const VerificationMeta _breedMeta = const VerificationMeta('breed');
  @override
  late final GeneratedColumn<String> breed = GeneratedColumn<String>(
    'breed',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PetSex?, String> sex =
      GeneratedColumn<String>(
        'sex',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<PetSex?>($PetsTable.$convertersexn);
  static const VerificationMeta _neuteredMeta = const VerificationMeta(
    'neutered',
  );
  @override
  late final GeneratedColumn<bool> neutered = GeneratedColumn<bool>(
    'neutered',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("neutered" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _birthDateMeta = const VerificationMeta(
    'birthDate',
  );
  @override
  late final GeneratedColumn<DateTime> birthDate = GeneratedColumn<DateTime>(
    'birth_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _microchipMeta = const VerificationMeta(
    'microchip',
  );
  @override
  late final GeneratedColumn<String> microchip = GeneratedColumn<String>(
    'microchip',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoPathMeta = const VerificationMeta(
    'photoPath',
  );
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
    'photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoFocusXMeta = const VerificationMeta(
    'photoFocusX',
  );
  @override
  late final GeneratedColumn<double> photoFocusX = GeneratedColumn<double>(
    'photo_focus_x',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _photoFocusYMeta = const VerificationMeta(
    'photoFocusY',
  );
  @override
  late final GeneratedColumn<double> photoFocusY = GeneratedColumn<double>(
    'photo_focus_y',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _photoZoomMeta = const VerificationMeta(
    'photoZoom',
  );
  @override
  late final GeneratedColumn<double> photoZoom = GeneratedColumn<double>(
    'photo_zoom',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _allergiesNotesMeta = const VerificationMeta(
    'allergiesNotes',
  );
  @override
  late final GeneratedColumn<String> allergiesNotes = GeneratedColumn<String>(
    'allergies_notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _vetNameMeta = const VerificationMeta(
    'vetName',
  );
  @override
  late final GeneratedColumn<String> vetName = GeneratedColumn<String>(
    'vet_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _vetClinicMeta = const VerificationMeta(
    'vetClinic',
  );
  @override
  late final GeneratedColumn<String> vetClinic = GeneratedColumn<String>(
    'vet_clinic',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _vetPhoneMeta = const VerificationMeta(
    'vetPhone',
  );
  @override
  late final GeneratedColumn<String> vetPhone = GeneratedColumn<String>(
    'vet_phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    species,
    breed,
    sex,
    neutered,
    birthDate,
    microchip,
    photoPath,
    photoFocusX,
    photoFocusY,
    photoZoom,
    allergiesNotes,
    vetName,
    vetClinic,
    vetPhone,
    createdAt,
    archived,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pets';
  @override
  VerificationContext validateIntegrity(
    Insertable<PetRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('breed')) {
      context.handle(
        _breedMeta,
        breed.isAcceptableOrUnknown(data['breed']!, _breedMeta),
      );
    }
    if (data.containsKey('neutered')) {
      context.handle(
        _neuteredMeta,
        neutered.isAcceptableOrUnknown(data['neutered']!, _neuteredMeta),
      );
    }
    if (data.containsKey('birth_date')) {
      context.handle(
        _birthDateMeta,
        birthDate.isAcceptableOrUnknown(data['birth_date']!, _birthDateMeta),
      );
    }
    if (data.containsKey('microchip')) {
      context.handle(
        _microchipMeta,
        microchip.isAcceptableOrUnknown(data['microchip']!, _microchipMeta),
      );
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    }
    if (data.containsKey('photo_focus_x')) {
      context.handle(
        _photoFocusXMeta,
        photoFocusX.isAcceptableOrUnknown(
          data['photo_focus_x']!,
          _photoFocusXMeta,
        ),
      );
    }
    if (data.containsKey('photo_focus_y')) {
      context.handle(
        _photoFocusYMeta,
        photoFocusY.isAcceptableOrUnknown(
          data['photo_focus_y']!,
          _photoFocusYMeta,
        ),
      );
    }
    if (data.containsKey('photo_zoom')) {
      context.handle(
        _photoZoomMeta,
        photoZoom.isAcceptableOrUnknown(data['photo_zoom']!, _photoZoomMeta),
      );
    }
    if (data.containsKey('allergies_notes')) {
      context.handle(
        _allergiesNotesMeta,
        allergiesNotes.isAcceptableOrUnknown(
          data['allergies_notes']!,
          _allergiesNotesMeta,
        ),
      );
    }
    if (data.containsKey('vet_name')) {
      context.handle(
        _vetNameMeta,
        vetName.isAcceptableOrUnknown(data['vet_name']!, _vetNameMeta),
      );
    }
    if (data.containsKey('vet_clinic')) {
      context.handle(
        _vetClinicMeta,
        vetClinic.isAcceptableOrUnknown(data['vet_clinic']!, _vetClinicMeta),
      );
    }
    if (data.containsKey('vet_phone')) {
      context.handle(
        _vetPhoneMeta,
        vetPhone.isAcceptableOrUnknown(data['vet_phone']!, _vetPhoneMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PetRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      species: $PetsTable.$converterspecies.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}species'],
        )!,
      ),
      breed: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}breed'],
      ),
      sex: $PetsTable.$convertersexn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sex'],
        ),
      ),
      neutered: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}neutered'],
      )!,
      birthDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}birth_date'],
      ),
      microchip: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}microchip'],
      ),
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      ),
      photoFocusX: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}photo_focus_x'],
      )!,
      photoFocusY: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}photo_focus_y'],
      )!,
      photoZoom: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}photo_zoom'],
      )!,
      allergiesNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}allergies_notes'],
      ),
      vetName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vet_name'],
      ),
      vetClinic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vet_clinic'],
      ),
      vetPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vet_phone'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
    );
  }

  @override
  $PetsTable createAlias(String alias) {
    return $PetsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PetSpecies, String, String> $converterspecies =
      const EnumNameConverter<PetSpecies>(PetSpecies.values);
  static JsonTypeConverter2<PetSex, String, String> $convertersex =
      const EnumNameConverter<PetSex>(PetSex.values);
  static JsonTypeConverter2<PetSex?, String?, String?> $convertersexn =
      JsonTypeConverter2.asNullable($convertersex);
}

class PetRow extends DataClass implements Insertable<PetRow> {
  final String id;
  final String name;
  final PetSpecies species;
  final String? breed;
  final PetSex? sex;
  final bool neutered;
  final DateTime? birthDate;
  final String? microchip;
  final String? photoPath;
  final double photoFocusX;
  final double photoFocusY;
  final double photoZoom;
  final String? allergiesNotes;
  final String? vetName;
  final String? vetClinic;
  final String? vetPhone;
  final DateTime createdAt;
  final bool archived;
  const PetRow({
    required this.id,
    required this.name,
    required this.species,
    this.breed,
    this.sex,
    required this.neutered,
    this.birthDate,
    this.microchip,
    this.photoPath,
    required this.photoFocusX,
    required this.photoFocusY,
    required this.photoZoom,
    this.allergiesNotes,
    this.vetName,
    this.vetClinic,
    this.vetPhone,
    required this.createdAt,
    required this.archived,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    {
      map['species'] = Variable<String>(
        $PetsTable.$converterspecies.toSql(species),
      );
    }
    if (!nullToAbsent || breed != null) {
      map['breed'] = Variable<String>(breed);
    }
    if (!nullToAbsent || sex != null) {
      map['sex'] = Variable<String>($PetsTable.$convertersexn.toSql(sex));
    }
    map['neutered'] = Variable<bool>(neutered);
    if (!nullToAbsent || birthDate != null) {
      map['birth_date'] = Variable<DateTime>(birthDate);
    }
    if (!nullToAbsent || microchip != null) {
      map['microchip'] = Variable<String>(microchip);
    }
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    map['photo_focus_x'] = Variable<double>(photoFocusX);
    map['photo_focus_y'] = Variable<double>(photoFocusY);
    map['photo_zoom'] = Variable<double>(photoZoom);
    if (!nullToAbsent || allergiesNotes != null) {
      map['allergies_notes'] = Variable<String>(allergiesNotes);
    }
    if (!nullToAbsent || vetName != null) {
      map['vet_name'] = Variable<String>(vetName);
    }
    if (!nullToAbsent || vetClinic != null) {
      map['vet_clinic'] = Variable<String>(vetClinic);
    }
    if (!nullToAbsent || vetPhone != null) {
      map['vet_phone'] = Variable<String>(vetPhone);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['archived'] = Variable<bool>(archived);
    return map;
  }

  PetsCompanion toCompanion(bool nullToAbsent) {
    return PetsCompanion(
      id: Value(id),
      name: Value(name),
      species: Value(species),
      breed: breed == null && nullToAbsent
          ? const Value.absent()
          : Value(breed),
      sex: sex == null && nullToAbsent ? const Value.absent() : Value(sex),
      neutered: Value(neutered),
      birthDate: birthDate == null && nullToAbsent
          ? const Value.absent()
          : Value(birthDate),
      microchip: microchip == null && nullToAbsent
          ? const Value.absent()
          : Value(microchip),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      photoFocusX: Value(photoFocusX),
      photoFocusY: Value(photoFocusY),
      photoZoom: Value(photoZoom),
      allergiesNotes: allergiesNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(allergiesNotes),
      vetName: vetName == null && nullToAbsent
          ? const Value.absent()
          : Value(vetName),
      vetClinic: vetClinic == null && nullToAbsent
          ? const Value.absent()
          : Value(vetClinic),
      vetPhone: vetPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(vetPhone),
      createdAt: Value(createdAt),
      archived: Value(archived),
    );
  }

  factory PetRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PetRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      species: $PetsTable.$converterspecies.fromJson(
        serializer.fromJson<String>(json['species']),
      ),
      breed: serializer.fromJson<String?>(json['breed']),
      sex: $PetsTable.$convertersexn.fromJson(
        serializer.fromJson<String?>(json['sex']),
      ),
      neutered: serializer.fromJson<bool>(json['neutered']),
      birthDate: serializer.fromJson<DateTime?>(json['birthDate']),
      microchip: serializer.fromJson<String?>(json['microchip']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      photoFocusX: serializer.fromJson<double>(json['photoFocusX']),
      photoFocusY: serializer.fromJson<double>(json['photoFocusY']),
      photoZoom: serializer.fromJson<double>(json['photoZoom']),
      allergiesNotes: serializer.fromJson<String?>(json['allergiesNotes']),
      vetName: serializer.fromJson<String?>(json['vetName']),
      vetClinic: serializer.fromJson<String?>(json['vetClinic']),
      vetPhone: serializer.fromJson<String?>(json['vetPhone']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      archived: serializer.fromJson<bool>(json['archived']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'species': serializer.toJson<String>(
        $PetsTable.$converterspecies.toJson(species),
      ),
      'breed': serializer.toJson<String?>(breed),
      'sex': serializer.toJson<String?>($PetsTable.$convertersexn.toJson(sex)),
      'neutered': serializer.toJson<bool>(neutered),
      'birthDate': serializer.toJson<DateTime?>(birthDate),
      'microchip': serializer.toJson<String?>(microchip),
      'photoPath': serializer.toJson<String?>(photoPath),
      'photoFocusX': serializer.toJson<double>(photoFocusX),
      'photoFocusY': serializer.toJson<double>(photoFocusY),
      'photoZoom': serializer.toJson<double>(photoZoom),
      'allergiesNotes': serializer.toJson<String?>(allergiesNotes),
      'vetName': serializer.toJson<String?>(vetName),
      'vetClinic': serializer.toJson<String?>(vetClinic),
      'vetPhone': serializer.toJson<String?>(vetPhone),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'archived': serializer.toJson<bool>(archived),
    };
  }

  PetRow copyWith({
    String? id,
    String? name,
    PetSpecies? species,
    Value<String?> breed = const Value.absent(),
    Value<PetSex?> sex = const Value.absent(),
    bool? neutered,
    Value<DateTime?> birthDate = const Value.absent(),
    Value<String?> microchip = const Value.absent(),
    Value<String?> photoPath = const Value.absent(),
    double? photoFocusX,
    double? photoFocusY,
    double? photoZoom,
    Value<String?> allergiesNotes = const Value.absent(),
    Value<String?> vetName = const Value.absent(),
    Value<String?> vetClinic = const Value.absent(),
    Value<String?> vetPhone = const Value.absent(),
    DateTime? createdAt,
    bool? archived,
  }) => PetRow(
    id: id ?? this.id,
    name: name ?? this.name,
    species: species ?? this.species,
    breed: breed.present ? breed.value : this.breed,
    sex: sex.present ? sex.value : this.sex,
    neutered: neutered ?? this.neutered,
    birthDate: birthDate.present ? birthDate.value : this.birthDate,
    microchip: microchip.present ? microchip.value : this.microchip,
    photoPath: photoPath.present ? photoPath.value : this.photoPath,
    photoFocusX: photoFocusX ?? this.photoFocusX,
    photoFocusY: photoFocusY ?? this.photoFocusY,
    photoZoom: photoZoom ?? this.photoZoom,
    allergiesNotes: allergiesNotes.present
        ? allergiesNotes.value
        : this.allergiesNotes,
    vetName: vetName.present ? vetName.value : this.vetName,
    vetClinic: vetClinic.present ? vetClinic.value : this.vetClinic,
    vetPhone: vetPhone.present ? vetPhone.value : this.vetPhone,
    createdAt: createdAt ?? this.createdAt,
    archived: archived ?? this.archived,
  );
  PetRow copyWithCompanion(PetsCompanion data) {
    return PetRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      species: data.species.present ? data.species.value : this.species,
      breed: data.breed.present ? data.breed.value : this.breed,
      sex: data.sex.present ? data.sex.value : this.sex,
      neutered: data.neutered.present ? data.neutered.value : this.neutered,
      birthDate: data.birthDate.present ? data.birthDate.value : this.birthDate,
      microchip: data.microchip.present ? data.microchip.value : this.microchip,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      photoFocusX: data.photoFocusX.present
          ? data.photoFocusX.value
          : this.photoFocusX,
      photoFocusY: data.photoFocusY.present
          ? data.photoFocusY.value
          : this.photoFocusY,
      photoZoom: data.photoZoom.present ? data.photoZoom.value : this.photoZoom,
      allergiesNotes: data.allergiesNotes.present
          ? data.allergiesNotes.value
          : this.allergiesNotes,
      vetName: data.vetName.present ? data.vetName.value : this.vetName,
      vetClinic: data.vetClinic.present ? data.vetClinic.value : this.vetClinic,
      vetPhone: data.vetPhone.present ? data.vetPhone.value : this.vetPhone,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      archived: data.archived.present ? data.archived.value : this.archived,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PetRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('species: $species, ')
          ..write('breed: $breed, ')
          ..write('sex: $sex, ')
          ..write('neutered: $neutered, ')
          ..write('birthDate: $birthDate, ')
          ..write('microchip: $microchip, ')
          ..write('photoPath: $photoPath, ')
          ..write('photoFocusX: $photoFocusX, ')
          ..write('photoFocusY: $photoFocusY, ')
          ..write('photoZoom: $photoZoom, ')
          ..write('allergiesNotes: $allergiesNotes, ')
          ..write('vetName: $vetName, ')
          ..write('vetClinic: $vetClinic, ')
          ..write('vetPhone: $vetPhone, ')
          ..write('createdAt: $createdAt, ')
          ..write('archived: $archived')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    species,
    breed,
    sex,
    neutered,
    birthDate,
    microchip,
    photoPath,
    photoFocusX,
    photoFocusY,
    photoZoom,
    allergiesNotes,
    vetName,
    vetClinic,
    vetPhone,
    createdAt,
    archived,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PetRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.species == this.species &&
          other.breed == this.breed &&
          other.sex == this.sex &&
          other.neutered == this.neutered &&
          other.birthDate == this.birthDate &&
          other.microchip == this.microchip &&
          other.photoPath == this.photoPath &&
          other.photoFocusX == this.photoFocusX &&
          other.photoFocusY == this.photoFocusY &&
          other.photoZoom == this.photoZoom &&
          other.allergiesNotes == this.allergiesNotes &&
          other.vetName == this.vetName &&
          other.vetClinic == this.vetClinic &&
          other.vetPhone == this.vetPhone &&
          other.createdAt == this.createdAt &&
          other.archived == this.archived);
}

class PetsCompanion extends UpdateCompanion<PetRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<PetSpecies> species;
  final Value<String?> breed;
  final Value<PetSex?> sex;
  final Value<bool> neutered;
  final Value<DateTime?> birthDate;
  final Value<String?> microchip;
  final Value<String?> photoPath;
  final Value<double> photoFocusX;
  final Value<double> photoFocusY;
  final Value<double> photoZoom;
  final Value<String?> allergiesNotes;
  final Value<String?> vetName;
  final Value<String?> vetClinic;
  final Value<String?> vetPhone;
  final Value<DateTime> createdAt;
  final Value<bool> archived;
  final Value<int> rowid;
  const PetsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.species = const Value.absent(),
    this.breed = const Value.absent(),
    this.sex = const Value.absent(),
    this.neutered = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.microchip = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.photoFocusX = const Value.absent(),
    this.photoFocusY = const Value.absent(),
    this.photoZoom = const Value.absent(),
    this.allergiesNotes = const Value.absent(),
    this.vetName = const Value.absent(),
    this.vetClinic = const Value.absent(),
    this.vetPhone = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.archived = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PetsCompanion.insert({
    required String id,
    required String name,
    required PetSpecies species,
    this.breed = const Value.absent(),
    this.sex = const Value.absent(),
    this.neutered = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.microchip = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.photoFocusX = const Value.absent(),
    this.photoFocusY = const Value.absent(),
    this.photoZoom = const Value.absent(),
    this.allergiesNotes = const Value.absent(),
    this.vetName = const Value.absent(),
    this.vetClinic = const Value.absent(),
    this.vetPhone = const Value.absent(),
    required DateTime createdAt,
    this.archived = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       species = Value(species),
       createdAt = Value(createdAt);
  static Insertable<PetRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? species,
    Expression<String>? breed,
    Expression<String>? sex,
    Expression<bool>? neutered,
    Expression<DateTime>? birthDate,
    Expression<String>? microchip,
    Expression<String>? photoPath,
    Expression<double>? photoFocusX,
    Expression<double>? photoFocusY,
    Expression<double>? photoZoom,
    Expression<String>? allergiesNotes,
    Expression<String>? vetName,
    Expression<String>? vetClinic,
    Expression<String>? vetPhone,
    Expression<DateTime>? createdAt,
    Expression<bool>? archived,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (species != null) 'species': species,
      if (breed != null) 'breed': breed,
      if (sex != null) 'sex': sex,
      if (neutered != null) 'neutered': neutered,
      if (birthDate != null) 'birth_date': birthDate,
      if (microchip != null) 'microchip': microchip,
      if (photoPath != null) 'photo_path': photoPath,
      if (photoFocusX != null) 'photo_focus_x': photoFocusX,
      if (photoFocusY != null) 'photo_focus_y': photoFocusY,
      if (photoZoom != null) 'photo_zoom': photoZoom,
      if (allergiesNotes != null) 'allergies_notes': allergiesNotes,
      if (vetName != null) 'vet_name': vetName,
      if (vetClinic != null) 'vet_clinic': vetClinic,
      if (vetPhone != null) 'vet_phone': vetPhone,
      if (createdAt != null) 'created_at': createdAt,
      if (archived != null) 'archived': archived,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PetsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<PetSpecies>? species,
    Value<String?>? breed,
    Value<PetSex?>? sex,
    Value<bool>? neutered,
    Value<DateTime?>? birthDate,
    Value<String?>? microchip,
    Value<String?>? photoPath,
    Value<double>? photoFocusX,
    Value<double>? photoFocusY,
    Value<double>? photoZoom,
    Value<String?>? allergiesNotes,
    Value<String?>? vetName,
    Value<String?>? vetClinic,
    Value<String?>? vetPhone,
    Value<DateTime>? createdAt,
    Value<bool>? archived,
    Value<int>? rowid,
  }) {
    return PetsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      sex: sex ?? this.sex,
      neutered: neutered ?? this.neutered,
      birthDate: birthDate ?? this.birthDate,
      microchip: microchip ?? this.microchip,
      photoPath: photoPath ?? this.photoPath,
      photoFocusX: photoFocusX ?? this.photoFocusX,
      photoFocusY: photoFocusY ?? this.photoFocusY,
      photoZoom: photoZoom ?? this.photoZoom,
      allergiesNotes: allergiesNotes ?? this.allergiesNotes,
      vetName: vetName ?? this.vetName,
      vetClinic: vetClinic ?? this.vetClinic,
      vetPhone: vetPhone ?? this.vetPhone,
      createdAt: createdAt ?? this.createdAt,
      archived: archived ?? this.archived,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (species.present) {
      map['species'] = Variable<String>(
        $PetsTable.$converterspecies.toSql(species.value),
      );
    }
    if (breed.present) {
      map['breed'] = Variable<String>(breed.value);
    }
    if (sex.present) {
      map['sex'] = Variable<String>($PetsTable.$convertersexn.toSql(sex.value));
    }
    if (neutered.present) {
      map['neutered'] = Variable<bool>(neutered.value);
    }
    if (birthDate.present) {
      map['birth_date'] = Variable<DateTime>(birthDate.value);
    }
    if (microchip.present) {
      map['microchip'] = Variable<String>(microchip.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (photoFocusX.present) {
      map['photo_focus_x'] = Variable<double>(photoFocusX.value);
    }
    if (photoFocusY.present) {
      map['photo_focus_y'] = Variable<double>(photoFocusY.value);
    }
    if (photoZoom.present) {
      map['photo_zoom'] = Variable<double>(photoZoom.value);
    }
    if (allergiesNotes.present) {
      map['allergies_notes'] = Variable<String>(allergiesNotes.value);
    }
    if (vetName.present) {
      map['vet_name'] = Variable<String>(vetName.value);
    }
    if (vetClinic.present) {
      map['vet_clinic'] = Variable<String>(vetClinic.value);
    }
    if (vetPhone.present) {
      map['vet_phone'] = Variable<String>(vetPhone.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PetsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('species: $species, ')
          ..write('breed: $breed, ')
          ..write('sex: $sex, ')
          ..write('neutered: $neutered, ')
          ..write('birthDate: $birthDate, ')
          ..write('microchip: $microchip, ')
          ..write('photoPath: $photoPath, ')
          ..write('photoFocusX: $photoFocusX, ')
          ..write('photoFocusY: $photoFocusY, ')
          ..write('photoZoom: $photoZoom, ')
          ..write('allergiesNotes: $allergiesNotes, ')
          ..write('vetName: $vetName, ')
          ..write('vetClinic: $vetClinic, ')
          ..write('vetPhone: $vetPhone, ')
          ..write('createdAt: $createdAt, ')
          ..write('archived: $archived, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeightEntriesTable extends WeightEntries
    with TableInfo<$WeightEntriesTable, WeightRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeightEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _petIdMeta = const VerificationMeta('petId');
  @override
  late final GeneratedColumn<String> petId = GeneratedColumn<String>(
    'pet_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kgMeta = const VerificationMeta('kg');
  @override
  late final GeneratedColumn<double> kg = GeneratedColumn<double>(
    'kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, petId, date, kg, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weight_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeightRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('pet_id')) {
      context.handle(
        _petIdMeta,
        petId.isAcceptableOrUnknown(data['pet_id']!, _petIdMeta),
      );
    } else if (isInserting) {
      context.missing(_petIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('kg')) {
      context.handle(_kgMeta, kg.isAcceptableOrUnknown(data['kg']!, _kgMeta));
    } else if (isInserting) {
      context.missing(_kgMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeightRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeightRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      petId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pet_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      kg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kg'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $WeightEntriesTable createAlias(String alias) {
    return $WeightEntriesTable(attachedDatabase, alias);
  }
}

class WeightRow extends DataClass implements Insertable<WeightRow> {
  final String id;
  final String petId;
  final DateTime date;
  final double kg;
  final String? note;
  const WeightRow({
    required this.id,
    required this.petId,
    required this.date,
    required this.kg,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['pet_id'] = Variable<String>(petId);
    map['date'] = Variable<DateTime>(date);
    map['kg'] = Variable<double>(kg);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  WeightEntriesCompanion toCompanion(bool nullToAbsent) {
    return WeightEntriesCompanion(
      id: Value(id),
      petId: Value(petId),
      date: Value(date),
      kg: Value(kg),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory WeightRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeightRow(
      id: serializer.fromJson<String>(json['id']),
      petId: serializer.fromJson<String>(json['petId']),
      date: serializer.fromJson<DateTime>(json['date']),
      kg: serializer.fromJson<double>(json['kg']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'petId': serializer.toJson<String>(petId),
      'date': serializer.toJson<DateTime>(date),
      'kg': serializer.toJson<double>(kg),
      'note': serializer.toJson<String?>(note),
    };
  }

  WeightRow copyWith({
    String? id,
    String? petId,
    DateTime? date,
    double? kg,
    Value<String?> note = const Value.absent(),
  }) => WeightRow(
    id: id ?? this.id,
    petId: petId ?? this.petId,
    date: date ?? this.date,
    kg: kg ?? this.kg,
    note: note.present ? note.value : this.note,
  );
  WeightRow copyWithCompanion(WeightEntriesCompanion data) {
    return WeightRow(
      id: data.id.present ? data.id.value : this.id,
      petId: data.petId.present ? data.petId.value : this.petId,
      date: data.date.present ? data.date.value : this.date,
      kg: data.kg.present ? data.kg.value : this.kg,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeightRow(')
          ..write('id: $id, ')
          ..write('petId: $petId, ')
          ..write('date: $date, ')
          ..write('kg: $kg, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, petId, date, kg, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeightRow &&
          other.id == this.id &&
          other.petId == this.petId &&
          other.date == this.date &&
          other.kg == this.kg &&
          other.note == this.note);
}

class WeightEntriesCompanion extends UpdateCompanion<WeightRow> {
  final Value<String> id;
  final Value<String> petId;
  final Value<DateTime> date;
  final Value<double> kg;
  final Value<String?> note;
  final Value<int> rowid;
  const WeightEntriesCompanion({
    this.id = const Value.absent(),
    this.petId = const Value.absent(),
    this.date = const Value.absent(),
    this.kg = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeightEntriesCompanion.insert({
    required String id,
    required String petId,
    required DateTime date,
    required double kg,
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       petId = Value(petId),
       date = Value(date),
       kg = Value(kg);
  static Insertable<WeightRow> custom({
    Expression<String>? id,
    Expression<String>? petId,
    Expression<DateTime>? date,
    Expression<double>? kg,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (petId != null) 'pet_id': petId,
      if (date != null) 'date': date,
      if (kg != null) 'kg': kg,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeightEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? petId,
    Value<DateTime>? date,
    Value<double>? kg,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return WeightEntriesCompanion(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      date: date ?? this.date,
      kg: kg ?? this.kg,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (petId.present) {
      map['pet_id'] = Variable<String>(petId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (kg.present) {
      map['kg'] = Variable<double>(kg.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeightEntriesCompanion(')
          ..write('id: $id, ')
          ..write('petId: $petId, ')
          ..write('date: $date, ')
          ..write('kg: $kg, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TreatmentsTable extends Treatments
    with TableInfo<$TreatmentsTable, TreatmentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TreatmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _petIdMeta = const VerificationMeta('petId');
  @override
  late final GeneratedColumn<String> petId = GeneratedColumn<String>(
    'pet_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<EventType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<EventType>($TreatmentsTable.$convertertype);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intervalValueMeta = const VerificationMeta(
    'intervalValue',
  );
  @override
  late final GeneratedColumn<int> intervalValue = GeneratedColumn<int>(
    'interval_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<IntervalUnit, String>
  intervalUnit = GeneratedColumn<String>(
    'interval_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<IntervalUnit>($TreatmentsTable.$converterintervalUnit);
  static const VerificationMeta _nextDueDateMeta = const VerificationMeta(
    'nextDueDate',
  );
  @override
  late final GeneratedColumn<DateTime> nextDueDate = GeneratedColumn<DateTime>(
    'next_due_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reminderDaysBeforeMeta =
      const VerificationMeta('reminderDaysBefore');
  @override
  late final GeneratedColumn<int> reminderDaysBefore = GeneratedColumn<int>(
    'reminder_days_before',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  static const VerificationMeta _reminderEnabledMeta = const VerificationMeta(
    'reminderEnabled',
  );
  @override
  late final GeneratedColumn<bool> reminderEnabled = GeneratedColumn<bool>(
    'reminder_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("reminder_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    petId,
    type,
    name,
    intervalValue,
    intervalUnit,
    nextDueDate,
    reminderDaysBefore,
    reminderEnabled,
    active,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'treatments';
  @override
  VerificationContext validateIntegrity(
    Insertable<TreatmentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('pet_id')) {
      context.handle(
        _petIdMeta,
        petId.isAcceptableOrUnknown(data['pet_id']!, _petIdMeta),
      );
    } else if (isInserting) {
      context.missing(_petIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('interval_value')) {
      context.handle(
        _intervalValueMeta,
        intervalValue.isAcceptableOrUnknown(
          data['interval_value']!,
          _intervalValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_intervalValueMeta);
    }
    if (data.containsKey('next_due_date')) {
      context.handle(
        _nextDueDateMeta,
        nextDueDate.isAcceptableOrUnknown(
          data['next_due_date']!,
          _nextDueDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nextDueDateMeta);
    }
    if (data.containsKey('reminder_days_before')) {
      context.handle(
        _reminderDaysBeforeMeta,
        reminderDaysBefore.isAcceptableOrUnknown(
          data['reminder_days_before']!,
          _reminderDaysBeforeMeta,
        ),
      );
    }
    if (data.containsKey('reminder_enabled')) {
      context.handle(
        _reminderEnabledMeta,
        reminderEnabled.isAcceptableOrUnknown(
          data['reminder_enabled']!,
          _reminderEnabledMeta,
        ),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TreatmentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TreatmentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      petId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pet_id'],
      )!,
      type: $TreatmentsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      intervalValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_value'],
      )!,
      intervalUnit: $TreatmentsTable.$converterintervalUnit.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}interval_unit'],
        )!,
      ),
      nextDueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_due_date'],
      )!,
      reminderDaysBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_days_before'],
      )!,
      reminderEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}reminder_enabled'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
    );
  }

  @override
  $TreatmentsTable createAlias(String alias) {
    return $TreatmentsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<EventType, String, String> $convertertype =
      const EnumNameConverter<EventType>(EventType.values);
  static JsonTypeConverter2<IntervalUnit, String, String>
  $converterintervalUnit = const EnumNameConverter<IntervalUnit>(
    IntervalUnit.values,
  );
}

class TreatmentRow extends DataClass implements Insertable<TreatmentRow> {
  final String id;
  final String petId;
  final EventType type;
  final String name;
  final int intervalValue;
  final IntervalUnit intervalUnit;
  final DateTime nextDueDate;
  final int reminderDaysBefore;
  final bool reminderEnabled;
  final bool active;
  const TreatmentRow({
    required this.id,
    required this.petId,
    required this.type,
    required this.name,
    required this.intervalValue,
    required this.intervalUnit,
    required this.nextDueDate,
    required this.reminderDaysBefore,
    required this.reminderEnabled,
    required this.active,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['pet_id'] = Variable<String>(petId);
    {
      map['type'] = Variable<String>(
        $TreatmentsTable.$convertertype.toSql(type),
      );
    }
    map['name'] = Variable<String>(name);
    map['interval_value'] = Variable<int>(intervalValue);
    {
      map['interval_unit'] = Variable<String>(
        $TreatmentsTable.$converterintervalUnit.toSql(intervalUnit),
      );
    }
    map['next_due_date'] = Variable<DateTime>(nextDueDate);
    map['reminder_days_before'] = Variable<int>(reminderDaysBefore);
    map['reminder_enabled'] = Variable<bool>(reminderEnabled);
    map['active'] = Variable<bool>(active);
    return map;
  }

  TreatmentsCompanion toCompanion(bool nullToAbsent) {
    return TreatmentsCompanion(
      id: Value(id),
      petId: Value(petId),
      type: Value(type),
      name: Value(name),
      intervalValue: Value(intervalValue),
      intervalUnit: Value(intervalUnit),
      nextDueDate: Value(nextDueDate),
      reminderDaysBefore: Value(reminderDaysBefore),
      reminderEnabled: Value(reminderEnabled),
      active: Value(active),
    );
  }

  factory TreatmentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TreatmentRow(
      id: serializer.fromJson<String>(json['id']),
      petId: serializer.fromJson<String>(json['petId']),
      type: $TreatmentsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      name: serializer.fromJson<String>(json['name']),
      intervalValue: serializer.fromJson<int>(json['intervalValue']),
      intervalUnit: $TreatmentsTable.$converterintervalUnit.fromJson(
        serializer.fromJson<String>(json['intervalUnit']),
      ),
      nextDueDate: serializer.fromJson<DateTime>(json['nextDueDate']),
      reminderDaysBefore: serializer.fromJson<int>(json['reminderDaysBefore']),
      reminderEnabled: serializer.fromJson<bool>(json['reminderEnabled']),
      active: serializer.fromJson<bool>(json['active']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'petId': serializer.toJson<String>(petId),
      'type': serializer.toJson<String>(
        $TreatmentsTable.$convertertype.toJson(type),
      ),
      'name': serializer.toJson<String>(name),
      'intervalValue': serializer.toJson<int>(intervalValue),
      'intervalUnit': serializer.toJson<String>(
        $TreatmentsTable.$converterintervalUnit.toJson(intervalUnit),
      ),
      'nextDueDate': serializer.toJson<DateTime>(nextDueDate),
      'reminderDaysBefore': serializer.toJson<int>(reminderDaysBefore),
      'reminderEnabled': serializer.toJson<bool>(reminderEnabled),
      'active': serializer.toJson<bool>(active),
    };
  }

  TreatmentRow copyWith({
    String? id,
    String? petId,
    EventType? type,
    String? name,
    int? intervalValue,
    IntervalUnit? intervalUnit,
    DateTime? nextDueDate,
    int? reminderDaysBefore,
    bool? reminderEnabled,
    bool? active,
  }) => TreatmentRow(
    id: id ?? this.id,
    petId: petId ?? this.petId,
    type: type ?? this.type,
    name: name ?? this.name,
    intervalValue: intervalValue ?? this.intervalValue,
    intervalUnit: intervalUnit ?? this.intervalUnit,
    nextDueDate: nextDueDate ?? this.nextDueDate,
    reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
    reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    active: active ?? this.active,
  );
  TreatmentRow copyWithCompanion(TreatmentsCompanion data) {
    return TreatmentRow(
      id: data.id.present ? data.id.value : this.id,
      petId: data.petId.present ? data.petId.value : this.petId,
      type: data.type.present ? data.type.value : this.type,
      name: data.name.present ? data.name.value : this.name,
      intervalValue: data.intervalValue.present
          ? data.intervalValue.value
          : this.intervalValue,
      intervalUnit: data.intervalUnit.present
          ? data.intervalUnit.value
          : this.intervalUnit,
      nextDueDate: data.nextDueDate.present
          ? data.nextDueDate.value
          : this.nextDueDate,
      reminderDaysBefore: data.reminderDaysBefore.present
          ? data.reminderDaysBefore.value
          : this.reminderDaysBefore,
      reminderEnabled: data.reminderEnabled.present
          ? data.reminderEnabled.value
          : this.reminderEnabled,
      active: data.active.present ? data.active.value : this.active,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TreatmentRow(')
          ..write('id: $id, ')
          ..write('petId: $petId, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('intervalValue: $intervalValue, ')
          ..write('intervalUnit: $intervalUnit, ')
          ..write('nextDueDate: $nextDueDate, ')
          ..write('reminderDaysBefore: $reminderDaysBefore, ')
          ..write('reminderEnabled: $reminderEnabled, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    petId,
    type,
    name,
    intervalValue,
    intervalUnit,
    nextDueDate,
    reminderDaysBefore,
    reminderEnabled,
    active,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TreatmentRow &&
          other.id == this.id &&
          other.petId == this.petId &&
          other.type == this.type &&
          other.name == this.name &&
          other.intervalValue == this.intervalValue &&
          other.intervalUnit == this.intervalUnit &&
          other.nextDueDate == this.nextDueDate &&
          other.reminderDaysBefore == this.reminderDaysBefore &&
          other.reminderEnabled == this.reminderEnabled &&
          other.active == this.active);
}

class TreatmentsCompanion extends UpdateCompanion<TreatmentRow> {
  final Value<String> id;
  final Value<String> petId;
  final Value<EventType> type;
  final Value<String> name;
  final Value<int> intervalValue;
  final Value<IntervalUnit> intervalUnit;
  final Value<DateTime> nextDueDate;
  final Value<int> reminderDaysBefore;
  final Value<bool> reminderEnabled;
  final Value<bool> active;
  final Value<int> rowid;
  const TreatmentsCompanion({
    this.id = const Value.absent(),
    this.petId = const Value.absent(),
    this.type = const Value.absent(),
    this.name = const Value.absent(),
    this.intervalValue = const Value.absent(),
    this.intervalUnit = const Value.absent(),
    this.nextDueDate = const Value.absent(),
    this.reminderDaysBefore = const Value.absent(),
    this.reminderEnabled = const Value.absent(),
    this.active = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TreatmentsCompanion.insert({
    required String id,
    required String petId,
    required EventType type,
    required String name,
    required int intervalValue,
    required IntervalUnit intervalUnit,
    required DateTime nextDueDate,
    this.reminderDaysBefore = const Value.absent(),
    this.reminderEnabled = const Value.absent(),
    this.active = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       petId = Value(petId),
       type = Value(type),
       name = Value(name),
       intervalValue = Value(intervalValue),
       intervalUnit = Value(intervalUnit),
       nextDueDate = Value(nextDueDate);
  static Insertable<TreatmentRow> custom({
    Expression<String>? id,
    Expression<String>? petId,
    Expression<String>? type,
    Expression<String>? name,
    Expression<int>? intervalValue,
    Expression<String>? intervalUnit,
    Expression<DateTime>? nextDueDate,
    Expression<int>? reminderDaysBefore,
    Expression<bool>? reminderEnabled,
    Expression<bool>? active,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (petId != null) 'pet_id': petId,
      if (type != null) 'type': type,
      if (name != null) 'name': name,
      if (intervalValue != null) 'interval_value': intervalValue,
      if (intervalUnit != null) 'interval_unit': intervalUnit,
      if (nextDueDate != null) 'next_due_date': nextDueDate,
      if (reminderDaysBefore != null)
        'reminder_days_before': reminderDaysBefore,
      if (reminderEnabled != null) 'reminder_enabled': reminderEnabled,
      if (active != null) 'active': active,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TreatmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? petId,
    Value<EventType>? type,
    Value<String>? name,
    Value<int>? intervalValue,
    Value<IntervalUnit>? intervalUnit,
    Value<DateTime>? nextDueDate,
    Value<int>? reminderDaysBefore,
    Value<bool>? reminderEnabled,
    Value<bool>? active,
    Value<int>? rowid,
  }) {
    return TreatmentsCompanion(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      type: type ?? this.type,
      name: name ?? this.name,
      intervalValue: intervalValue ?? this.intervalValue,
      intervalUnit: intervalUnit ?? this.intervalUnit,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      active: active ?? this.active,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (petId.present) {
      map['pet_id'] = Variable<String>(petId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $TreatmentsTable.$convertertype.toSql(type.value),
      );
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (intervalValue.present) {
      map['interval_value'] = Variable<int>(intervalValue.value);
    }
    if (intervalUnit.present) {
      map['interval_unit'] = Variable<String>(
        $TreatmentsTable.$converterintervalUnit.toSql(intervalUnit.value),
      );
    }
    if (nextDueDate.present) {
      map['next_due_date'] = Variable<DateTime>(nextDueDate.value);
    }
    if (reminderDaysBefore.present) {
      map['reminder_days_before'] = Variable<int>(reminderDaysBefore.value);
    }
    if (reminderEnabled.present) {
      map['reminder_enabled'] = Variable<bool>(reminderEnabled.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TreatmentsCompanion(')
          ..write('id: $id, ')
          ..write('petId: $petId, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('intervalValue: $intervalValue, ')
          ..write('intervalUnit: $intervalUnit, ')
          ..write('nextDueDate: $nextDueDate, ')
          ..write('reminderDaysBefore: $reminderDaysBefore, ')
          ..write('reminderEnabled: $reminderEnabled, ')
          ..write('active: $active, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HealthEventsTable extends HealthEvents
    with TableInfo<$HealthEventsTable, EventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HealthEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _petIdMeta = const VerificationMeta('petId');
  @override
  late final GeneratedColumn<String> petId = GeneratedColumn<String>(
    'pet_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _treatmentIdMeta = const VerificationMeta(
    'treatmentId',
  );
  @override
  late final GeneratedColumn<String> treatmentId = GeneratedColumn<String>(
    'treatment_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<EventType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<EventType>($HealthEventsTable.$convertertype);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productMeta = const VerificationMeta(
    'product',
  );
  @override
  late final GeneratedColumn<String> product = GeneratedColumn<String>(
    'product',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lotMeta = const VerificationMeta('lot');
  @override
  late final GeneratedColumn<String> lot = GeneratedColumn<String>(
    'lot',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _vetNameMeta = const VerificationMeta(
    'vetName',
  );
  @override
  late final GeneratedColumn<String> vetName = GeneratedColumn<String>(
    'vet_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clinicMeta = const VerificationMeta('clinic');
  @override
  late final GeneratedColumn<String> clinic = GeneratedColumn<String>(
    'clinic',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    petId,
    treatmentId,
    type,
    title,
    occurredAt,
    product,
    lot,
    vetName,
    clinic,
    notes,
    weightKg,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'health_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('pet_id')) {
      context.handle(
        _petIdMeta,
        petId.isAcceptableOrUnknown(data['pet_id']!, _petIdMeta),
      );
    } else if (isInserting) {
      context.missing(_petIdMeta);
    }
    if (data.containsKey('treatment_id')) {
      context.handle(
        _treatmentIdMeta,
        treatmentId.isAcceptableOrUnknown(
          data['treatment_id']!,
          _treatmentIdMeta,
        ),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('product')) {
      context.handle(
        _productMeta,
        product.isAcceptableOrUnknown(data['product']!, _productMeta),
      );
    }
    if (data.containsKey('lot')) {
      context.handle(
        _lotMeta,
        lot.isAcceptableOrUnknown(data['lot']!, _lotMeta),
      );
    }
    if (data.containsKey('vet_name')) {
      context.handle(
        _vetNameMeta,
        vetName.isAcceptableOrUnknown(data['vet_name']!, _vetNameMeta),
      );
    }
    if (data.containsKey('clinic')) {
      context.handle(
        _clinicMeta,
        clinic.isAcceptableOrUnknown(data['clinic']!, _clinicMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      petId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pet_id'],
      )!,
      treatmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}treatment_id'],
      ),
      type: $HealthEventsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      product: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product'],
      ),
      lot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lot'],
      ),
      vetName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vet_name'],
      ),
      clinic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clinic'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $HealthEventsTable createAlias(String alias) {
    return $HealthEventsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<EventType, String, String> $convertertype =
      const EnumNameConverter<EventType>(EventType.values);
}

class EventRow extends DataClass implements Insertable<EventRow> {
  final String id;
  final String petId;
  final String? treatmentId;
  final EventType type;
  final String title;
  final DateTime occurredAt;
  final String? product;
  final String? lot;
  final String? vetName;
  final String? clinic;
  final String? notes;
  final double? weightKg;
  final DateTime createdAt;
  const EventRow({
    required this.id,
    required this.petId,
    this.treatmentId,
    required this.type,
    required this.title,
    required this.occurredAt,
    this.product,
    this.lot,
    this.vetName,
    this.clinic,
    this.notes,
    this.weightKg,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['pet_id'] = Variable<String>(petId);
    if (!nullToAbsent || treatmentId != null) {
      map['treatment_id'] = Variable<String>(treatmentId);
    }
    {
      map['type'] = Variable<String>(
        $HealthEventsTable.$convertertype.toSql(type),
      );
    }
    map['title'] = Variable<String>(title);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    if (!nullToAbsent || product != null) {
      map['product'] = Variable<String>(product);
    }
    if (!nullToAbsent || lot != null) {
      map['lot'] = Variable<String>(lot);
    }
    if (!nullToAbsent || vetName != null) {
      map['vet_name'] = Variable<String>(vetName);
    }
    if (!nullToAbsent || clinic != null) {
      map['clinic'] = Variable<String>(clinic);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<double>(weightKg);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  HealthEventsCompanion toCompanion(bool nullToAbsent) {
    return HealthEventsCompanion(
      id: Value(id),
      petId: Value(petId),
      treatmentId: treatmentId == null && nullToAbsent
          ? const Value.absent()
          : Value(treatmentId),
      type: Value(type),
      title: Value(title),
      occurredAt: Value(occurredAt),
      product: product == null && nullToAbsent
          ? const Value.absent()
          : Value(product),
      lot: lot == null && nullToAbsent ? const Value.absent() : Value(lot),
      vetName: vetName == null && nullToAbsent
          ? const Value.absent()
          : Value(vetName),
      clinic: clinic == null && nullToAbsent
          ? const Value.absent()
          : Value(clinic),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
      createdAt: Value(createdAt),
    );
  }

  factory EventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventRow(
      id: serializer.fromJson<String>(json['id']),
      petId: serializer.fromJson<String>(json['petId']),
      treatmentId: serializer.fromJson<String?>(json['treatmentId']),
      type: $HealthEventsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      title: serializer.fromJson<String>(json['title']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      product: serializer.fromJson<String?>(json['product']),
      lot: serializer.fromJson<String?>(json['lot']),
      vetName: serializer.fromJson<String?>(json['vetName']),
      clinic: serializer.fromJson<String?>(json['clinic']),
      notes: serializer.fromJson<String?>(json['notes']),
      weightKg: serializer.fromJson<double?>(json['weightKg']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'petId': serializer.toJson<String>(petId),
      'treatmentId': serializer.toJson<String?>(treatmentId),
      'type': serializer.toJson<String>(
        $HealthEventsTable.$convertertype.toJson(type),
      ),
      'title': serializer.toJson<String>(title),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'product': serializer.toJson<String?>(product),
      'lot': serializer.toJson<String?>(lot),
      'vetName': serializer.toJson<String?>(vetName),
      'clinic': serializer.toJson<String?>(clinic),
      'notes': serializer.toJson<String?>(notes),
      'weightKg': serializer.toJson<double?>(weightKg),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  EventRow copyWith({
    String? id,
    String? petId,
    Value<String?> treatmentId = const Value.absent(),
    EventType? type,
    String? title,
    DateTime? occurredAt,
    Value<String?> product = const Value.absent(),
    Value<String?> lot = const Value.absent(),
    Value<String?> vetName = const Value.absent(),
    Value<String?> clinic = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<double?> weightKg = const Value.absent(),
    DateTime? createdAt,
  }) => EventRow(
    id: id ?? this.id,
    petId: petId ?? this.petId,
    treatmentId: treatmentId.present ? treatmentId.value : this.treatmentId,
    type: type ?? this.type,
    title: title ?? this.title,
    occurredAt: occurredAt ?? this.occurredAt,
    product: product.present ? product.value : this.product,
    lot: lot.present ? lot.value : this.lot,
    vetName: vetName.present ? vetName.value : this.vetName,
    clinic: clinic.present ? clinic.value : this.clinic,
    notes: notes.present ? notes.value : this.notes,
    weightKg: weightKg.present ? weightKg.value : this.weightKg,
    createdAt: createdAt ?? this.createdAt,
  );
  EventRow copyWithCompanion(HealthEventsCompanion data) {
    return EventRow(
      id: data.id.present ? data.id.value : this.id,
      petId: data.petId.present ? data.petId.value : this.petId,
      treatmentId: data.treatmentId.present
          ? data.treatmentId.value
          : this.treatmentId,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      product: data.product.present ? data.product.value : this.product,
      lot: data.lot.present ? data.lot.value : this.lot,
      vetName: data.vetName.present ? data.vetName.value : this.vetName,
      clinic: data.clinic.present ? data.clinic.value : this.clinic,
      notes: data.notes.present ? data.notes.value : this.notes,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventRow(')
          ..write('id: $id, ')
          ..write('petId: $petId, ')
          ..write('treatmentId: $treatmentId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('product: $product, ')
          ..write('lot: $lot, ')
          ..write('vetName: $vetName, ')
          ..write('clinic: $clinic, ')
          ..write('notes: $notes, ')
          ..write('weightKg: $weightKg, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    petId,
    treatmentId,
    type,
    title,
    occurredAt,
    product,
    lot,
    vetName,
    clinic,
    notes,
    weightKg,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventRow &&
          other.id == this.id &&
          other.petId == this.petId &&
          other.treatmentId == this.treatmentId &&
          other.type == this.type &&
          other.title == this.title &&
          other.occurredAt == this.occurredAt &&
          other.product == this.product &&
          other.lot == this.lot &&
          other.vetName == this.vetName &&
          other.clinic == this.clinic &&
          other.notes == this.notes &&
          other.weightKg == this.weightKg &&
          other.createdAt == this.createdAt);
}

class HealthEventsCompanion extends UpdateCompanion<EventRow> {
  final Value<String> id;
  final Value<String> petId;
  final Value<String?> treatmentId;
  final Value<EventType> type;
  final Value<String> title;
  final Value<DateTime> occurredAt;
  final Value<String?> product;
  final Value<String?> lot;
  final Value<String?> vetName;
  final Value<String?> clinic;
  final Value<String?> notes;
  final Value<double?> weightKg;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const HealthEventsCompanion({
    this.id = const Value.absent(),
    this.petId = const Value.absent(),
    this.treatmentId = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.product = const Value.absent(),
    this.lot = const Value.absent(),
    this.vetName = const Value.absent(),
    this.clinic = const Value.absent(),
    this.notes = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HealthEventsCompanion.insert({
    required String id,
    required String petId,
    this.treatmentId = const Value.absent(),
    required EventType type,
    required String title,
    required DateTime occurredAt,
    this.product = const Value.absent(),
    this.lot = const Value.absent(),
    this.vetName = const Value.absent(),
    this.clinic = const Value.absent(),
    this.notes = const Value.absent(),
    this.weightKg = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       petId = Value(petId),
       type = Value(type),
       title = Value(title),
       occurredAt = Value(occurredAt),
       createdAt = Value(createdAt);
  static Insertable<EventRow> custom({
    Expression<String>? id,
    Expression<String>? petId,
    Expression<String>? treatmentId,
    Expression<String>? type,
    Expression<String>? title,
    Expression<DateTime>? occurredAt,
    Expression<String>? product,
    Expression<String>? lot,
    Expression<String>? vetName,
    Expression<String>? clinic,
    Expression<String>? notes,
    Expression<double>? weightKg,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (petId != null) 'pet_id': petId,
      if (treatmentId != null) 'treatment_id': treatmentId,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (product != null) 'product': product,
      if (lot != null) 'lot': lot,
      if (vetName != null) 'vet_name': vetName,
      if (clinic != null) 'clinic': clinic,
      if (notes != null) 'notes': notes,
      if (weightKg != null) 'weight_kg': weightKg,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HealthEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? petId,
    Value<String?>? treatmentId,
    Value<EventType>? type,
    Value<String>? title,
    Value<DateTime>? occurredAt,
    Value<String?>? product,
    Value<String?>? lot,
    Value<String?>? vetName,
    Value<String?>? clinic,
    Value<String?>? notes,
    Value<double?>? weightKg,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return HealthEventsCompanion(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      treatmentId: treatmentId ?? this.treatmentId,
      type: type ?? this.type,
      title: title ?? this.title,
      occurredAt: occurredAt ?? this.occurredAt,
      product: product ?? this.product,
      lot: lot ?? this.lot,
      vetName: vetName ?? this.vetName,
      clinic: clinic ?? this.clinic,
      notes: notes ?? this.notes,
      weightKg: weightKg ?? this.weightKg,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (petId.present) {
      map['pet_id'] = Variable<String>(petId.value);
    }
    if (treatmentId.present) {
      map['treatment_id'] = Variable<String>(treatmentId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $HealthEventsTable.$convertertype.toSql(type.value),
      );
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (product.present) {
      map['product'] = Variable<String>(product.value);
    }
    if (lot.present) {
      map['lot'] = Variable<String>(lot.value);
    }
    if (vetName.present) {
      map['vet_name'] = Variable<String>(vetName.value);
    }
    if (clinic.present) {
      map['clinic'] = Variable<String>(clinic.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HealthEventsCompanion(')
          ..write('id: $id, ')
          ..write('petId: $petId, ')
          ..write('treatmentId: $treatmentId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('product: $product, ')
          ..write('lot: $lot, ')
          ..write('vetName: $vetName, ')
          ..write('clinic: $clinic, ')
          ..write('notes: $notes, ')
          ..write('weightKg: $weightKg, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttachmentsTable extends Attachments
    with TableInfo<$AttachmentsTable, AttachmentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relativePathMeta = const VerificationMeta(
    'relativePath',
  );
  @override
  late final GeneratedColumn<String> relativePath = GeneratedColumn<String>(
    'relative_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AttachmentKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AttachmentKind>($AttachmentsTable.$converterkind);
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    eventId,
    relativePath,
    kind,
    label,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttachmentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('relative_path')) {
      context.handle(
        _relativePathMeta,
        relativePath.isAcceptableOrUnknown(
          data['relative_path']!,
          _relativePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relativePathMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttachmentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttachmentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      relativePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relative_path'],
      )!,
      kind: $AttachmentsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
    );
  }

  @override
  $AttachmentsTable createAlias(String alias) {
    return $AttachmentsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AttachmentKind, String, String> $converterkind =
      const EnumNameConverter<AttachmentKind>(AttachmentKind.values);
}

class AttachmentRow extends DataClass implements Insertable<AttachmentRow> {
  final String id;
  final String eventId;
  final String relativePath;
  final AttachmentKind kind;
  final String? label;
  const AttachmentRow({
    required this.id,
    required this.eventId,
    required this.relativePath,
    required this.kind,
    this.label,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['event_id'] = Variable<String>(eventId);
    map['relative_path'] = Variable<String>(relativePath);
    {
      map['kind'] = Variable<String>(
        $AttachmentsTable.$converterkind.toSql(kind),
      );
    }
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    return map;
  }

  AttachmentsCompanion toCompanion(bool nullToAbsent) {
    return AttachmentsCompanion(
      id: Value(id),
      eventId: Value(eventId),
      relativePath: Value(relativePath),
      kind: Value(kind),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
    );
  }

  factory AttachmentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttachmentRow(
      id: serializer.fromJson<String>(json['id']),
      eventId: serializer.fromJson<String>(json['eventId']),
      relativePath: serializer.fromJson<String>(json['relativePath']),
      kind: $AttachmentsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      label: serializer.fromJson<String?>(json['label']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'eventId': serializer.toJson<String>(eventId),
      'relativePath': serializer.toJson<String>(relativePath),
      'kind': serializer.toJson<String>(
        $AttachmentsTable.$converterkind.toJson(kind),
      ),
      'label': serializer.toJson<String?>(label),
    };
  }

  AttachmentRow copyWith({
    String? id,
    String? eventId,
    String? relativePath,
    AttachmentKind? kind,
    Value<String?> label = const Value.absent(),
  }) => AttachmentRow(
    id: id ?? this.id,
    eventId: eventId ?? this.eventId,
    relativePath: relativePath ?? this.relativePath,
    kind: kind ?? this.kind,
    label: label.present ? label.value : this.label,
  );
  AttachmentRow copyWithCompanion(AttachmentsCompanion data) {
    return AttachmentRow(
      id: data.id.present ? data.id.value : this.id,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      relativePath: data.relativePath.present
          ? data.relativePath.value
          : this.relativePath,
      kind: data.kind.present ? data.kind.value : this.kind,
      label: data.label.present ? data.label.value : this.label,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentRow(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('relativePath: $relativePath, ')
          ..write('kind: $kind, ')
          ..write('label: $label')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, eventId, relativePath, kind, label);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttachmentRow &&
          other.id == this.id &&
          other.eventId == this.eventId &&
          other.relativePath == this.relativePath &&
          other.kind == this.kind &&
          other.label == this.label);
}

class AttachmentsCompanion extends UpdateCompanion<AttachmentRow> {
  final Value<String> id;
  final Value<String> eventId;
  final Value<String> relativePath;
  final Value<AttachmentKind> kind;
  final Value<String?> label;
  final Value<int> rowid;
  const AttachmentsCompanion({
    this.id = const Value.absent(),
    this.eventId = const Value.absent(),
    this.relativePath = const Value.absent(),
    this.kind = const Value.absent(),
    this.label = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttachmentsCompanion.insert({
    required String id,
    required String eventId,
    required String relativePath,
    required AttachmentKind kind,
    this.label = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       eventId = Value(eventId),
       relativePath = Value(relativePath),
       kind = Value(kind);
  static Insertable<AttachmentRow> custom({
    Expression<String>? id,
    Expression<String>? eventId,
    Expression<String>? relativePath,
    Expression<String>? kind,
    Expression<String>? label,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventId != null) 'event_id': eventId,
      if (relativePath != null) 'relative_path': relativePath,
      if (kind != null) 'kind': kind,
      if (label != null) 'label': label,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttachmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? eventId,
    Value<String>? relativePath,
    Value<AttachmentKind>? kind,
    Value<String?>? label,
    Value<int>? rowid,
  }) {
    return AttachmentsCompanion(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      relativePath: relativePath ?? this.relativePath,
      kind: kind ?? this.kind,
      label: label ?? this.label,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (relativePath.present) {
      map['relative_path'] = Variable<String>(relativePath.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $AttachmentsTable.$converterkind.toSql(kind.value),
      );
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('relativePath: $relativePath, ')
          ..write('kind: $kind, ')
          ..write('label: $label, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PetsTable pets = $PetsTable(this);
  late final $WeightEntriesTable weightEntries = $WeightEntriesTable(this);
  late final $TreatmentsTable treatments = $TreatmentsTable(this);
  late final $HealthEventsTable healthEvents = $HealthEventsTable(this);
  late final $AttachmentsTable attachments = $AttachmentsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    pets,
    weightEntries,
    treatments,
    healthEvents,
    attachments,
  ];
}

typedef $$PetsTableCreateCompanionBuilder = PetsCompanion Function({
  required String id,
  required String name,
  required PetSpecies species,
  Value<String?> breed,
  Value<PetSex?> sex,
  Value<bool> neutered,
  Value<DateTime?> birthDate,
  Value<String?> microchip,
  Value<String?> photoPath,
  Value<double> photoFocusX,
  Value<double> photoFocusY,
  Value<double> photoZoom,
  Value<String?> allergiesNotes,
  Value<String?> vetName,
  Value<String?> vetClinic,
  Value<String?> vetPhone,
  required DateTime createdAt,
  Value<bool> archived,
  Value<int> rowid,
});
typedef $$PetsTableUpdateCompanionBuilder = PetsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<PetSpecies> species,
  Value<String?> breed,
  Value<PetSex?> sex,
  Value<bool> neutered,
  Value<DateTime?> birthDate,
  Value<String?> microchip,
  Value<String?> photoPath,
  Value<double> photoFocusX,
  Value<double> photoFocusY,
  Value<double> photoZoom,
  Value<String?> allergiesNotes,
  Value<String?> vetName,
  Value<String?> vetClinic,
  Value<String?> vetPhone,
  Value<DateTime> createdAt,
  Value<bool> archived,
  Value<int> rowid,
});

class $$PetsTableFilterComposer extends Composer<_$AppDatabase, $PetsTable> {
  $$PetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PetSpecies, PetSpecies, String> get species =>
      $composableBuilder(
        column: $table.species,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get breed => $composableBuilder(
    column: $table.breed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PetSex?, PetSex, String> get sex =>
      $composableBuilder(
        column: $table.sex,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get neutered => $composableBuilder(
    column: $table.neutered,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get birthDate => $composableBuilder(
    column: $table.birthDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get microchip => $composableBuilder(
    column: $table.microchip,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get photoFocusX => $composableBuilder(
    column: $table.photoFocusX,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get photoFocusY => $composableBuilder(
    column: $table.photoFocusY,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get photoZoom => $composableBuilder(
    column: $table.photoZoom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get allergiesNotes => $composableBuilder(
    column: $table.allergiesNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vetName => $composableBuilder(
    column: $table.vetName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vetClinic => $composableBuilder(
    column: $table.vetClinic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vetPhone => $composableBuilder(
    column: $table.vetPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PetsTableOrderingComposer extends Composer<_$AppDatabase, $PetsTable> {
  $$PetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get species => $composableBuilder(
    column: $table.species,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get breed => $composableBuilder(
    column: $table.breed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get neutered => $composableBuilder(
    column: $table.neutered,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get birthDate => $composableBuilder(
    column: $table.birthDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get microchip => $composableBuilder(
    column: $table.microchip,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get photoFocusX => $composableBuilder(
    column: $table.photoFocusX,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get photoFocusY => $composableBuilder(
    column: $table.photoFocusY,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get photoZoom => $composableBuilder(
    column: $table.photoZoom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get allergiesNotes => $composableBuilder(
    column: $table.allergiesNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vetName => $composableBuilder(
    column: $table.vetName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vetClinic => $composableBuilder(
    column: $table.vetClinic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vetPhone => $composableBuilder(
    column: $table.vetPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PetsTable> {
  $$PetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PetSpecies, String> get species =>
      $composableBuilder(column: $table.species, builder: (column) => column);

  GeneratedColumn<String> get breed =>
      $composableBuilder(column: $table.breed, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PetSex?, String> get sex =>
      $composableBuilder(column: $table.sex, builder: (column) => column);

  GeneratedColumn<bool> get neutered =>
      $composableBuilder(column: $table.neutered, builder: (column) => column);

  GeneratedColumn<DateTime> get birthDate =>
      $composableBuilder(column: $table.birthDate, builder: (column) => column);

  GeneratedColumn<String> get microchip =>
      $composableBuilder(column: $table.microchip, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<double> get photoFocusX => $composableBuilder(
    column: $table.photoFocusX,
    builder: (column) => column,
  );

  GeneratedColumn<double> get photoFocusY => $composableBuilder(
    column: $table.photoFocusY,
    builder: (column) => column,
  );

  GeneratedColumn<double> get photoZoom =>
      $composableBuilder(column: $table.photoZoom, builder: (column) => column);

  GeneratedColumn<String> get allergiesNotes => $composableBuilder(
    column: $table.allergiesNotes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get vetName =>
      $composableBuilder(column: $table.vetName, builder: (column) => column);

  GeneratedColumn<String> get vetClinic =>
      $composableBuilder(column: $table.vetClinic, builder: (column) => column);

  GeneratedColumn<String> get vetPhone =>
      $composableBuilder(column: $table.vetPhone, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);
}

class $$PetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PetsTable,
          PetRow,
          $$PetsTableFilterComposer,
          $$PetsTableOrderingComposer,
          $$PetsTableAnnotationComposer,
          $$PetsTableCreateCompanionBuilder,
          $$PetsTableUpdateCompanionBuilder,
          (PetRow, BaseReferences<_$AppDatabase, $PetsTable, PetRow>),
          PetRow,
          PrefetchHooks Function()
        > {
  $$PetsTableTableManager(_$AppDatabase db, $PetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<PetSpecies> species = const Value.absent(),
                Value<String?> breed = const Value.absent(),
                Value<PetSex?> sex = const Value.absent(),
                Value<bool> neutered = const Value.absent(),
                Value<DateTime?> birthDate = const Value.absent(),
                Value<String?> microchip = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<double> photoFocusX = const Value.absent(),
                Value<double> photoFocusY = const Value.absent(),
                Value<double> photoZoom = const Value.absent(),
                Value<String?> allergiesNotes = const Value.absent(),
                Value<String?> vetName = const Value.absent(),
                Value<String?> vetClinic = const Value.absent(),
                Value<String?> vetPhone = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PetsCompanion(
                id: id,
                name: name,
                species: species,
                breed: breed,
                sex: sex,
                neutered: neutered,
                birthDate: birthDate,
                microchip: microchip,
                photoPath: photoPath,
                photoFocusX: photoFocusX,
                photoFocusY: photoFocusY,
                photoZoom: photoZoom,
                allergiesNotes: allergiesNotes,
                vetName: vetName,
                vetClinic: vetClinic,
                vetPhone: vetPhone,
                createdAt: createdAt,
                archived: archived,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required PetSpecies species,
                Value<String?> breed = const Value.absent(),
                Value<PetSex?> sex = const Value.absent(),
                Value<bool> neutered = const Value.absent(),
                Value<DateTime?> birthDate = const Value.absent(),
                Value<String?> microchip = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<double> photoFocusX = const Value.absent(),
                Value<double> photoFocusY = const Value.absent(),
                Value<double> photoZoom = const Value.absent(),
                Value<String?> allergiesNotes = const Value.absent(),
                Value<String?> vetName = const Value.absent(),
                Value<String?> vetClinic = const Value.absent(),
                Value<String?> vetPhone = const Value.absent(),
                required DateTime createdAt,
                Value<bool> archived = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PetsCompanion.insert(
                id: id,
                name: name,
                species: species,
                breed: breed,
                sex: sex,
                neutered: neutered,
                birthDate: birthDate,
                microchip: microchip,
                photoPath: photoPath,
                photoFocusX: photoFocusX,
                photoFocusY: photoFocusY,
                photoZoom: photoZoom,
                allergiesNotes: allergiesNotes,
                vetName: vetName,
                vetClinic: vetClinic,
                vetPhone: vetPhone,
                createdAt: createdAt,
                archived: archived,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PetsTable, PetRow>(table),
                  BaseReferences<_$AppDatabase, $PetsTable, PetRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PetsTable,
      PetRow,
      $$PetsTableFilterComposer,
      $$PetsTableOrderingComposer,
      $$PetsTableAnnotationComposer,
      $$PetsTableCreateCompanionBuilder,
      $$PetsTableUpdateCompanionBuilder,
      (PetRow, BaseReferences<_$AppDatabase, $PetsTable, PetRow>),
      PetRow,
      PrefetchHooks Function()
    >;
typedef $$WeightEntriesTableCreateCompanionBuilder =
    WeightEntriesCompanion Function({
      required String id,
      required String petId,
      required DateTime date,
      required double kg,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $$WeightEntriesTableUpdateCompanionBuilder =
    WeightEntriesCompanion Function({
      Value<String> id,
      Value<String> petId,
      Value<DateTime> date,
      Value<double> kg,
      Value<String?> note,
      Value<int> rowid,
    });

class $$WeightEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $WeightEntriesTable> {
  $$WeightEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get petId => $composableBuilder(
    column: $table.petId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kg => $composableBuilder(
    column: $table.kg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeightEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $WeightEntriesTable> {
  $$WeightEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get petId => $composableBuilder(
    column: $table.petId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kg => $composableBuilder(
    column: $table.kg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeightEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeightEntriesTable> {
  $$WeightEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get petId =>
      $composableBuilder(column: $table.petId, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get kg =>
      $composableBuilder(column: $table.kg, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$WeightEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeightEntriesTable,
          WeightRow,
          $$WeightEntriesTableFilterComposer,
          $$WeightEntriesTableOrderingComposer,
          $$WeightEntriesTableAnnotationComposer,
          $$WeightEntriesTableCreateCompanionBuilder,
          $$WeightEntriesTableUpdateCompanionBuilder,
          (
            WeightRow,
            BaseReferences<_$AppDatabase, $WeightEntriesTable, WeightRow>,
          ),
          WeightRow,
          PrefetchHooks Function()
        > {
  $$WeightEntriesTableTableManager(_$AppDatabase db, $WeightEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeightEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeightEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeightEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> petId = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<double> kg = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeightEntriesCompanion(
                id: id,
                petId: petId,
                date: date,
                kg: kg,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String petId,
                required DateTime date,
                required double kg,
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeightEntriesCompanion.insert(
                id: id,
                petId: petId,
                date: date,
                kg: kg,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WeightEntriesTable, WeightRow>(table),
                  BaseReferences<_$AppDatabase, $WeightEntriesTable, WeightRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeightEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeightEntriesTable,
      WeightRow,
      $$WeightEntriesTableFilterComposer,
      $$WeightEntriesTableOrderingComposer,
      $$WeightEntriesTableAnnotationComposer,
      $$WeightEntriesTableCreateCompanionBuilder,
      $$WeightEntriesTableUpdateCompanionBuilder,
      (
        WeightRow,
        BaseReferences<_$AppDatabase, $WeightEntriesTable, WeightRow>,
      ),
      WeightRow,
      PrefetchHooks Function()
    >;
typedef $$TreatmentsTableCreateCompanionBuilder = TreatmentsCompanion Function({
  required String id,
  required String petId,
  required EventType type,
  required String name,
  required int intervalValue,
  required IntervalUnit intervalUnit,
  required DateTime nextDueDate,
  Value<int> reminderDaysBefore,
  Value<bool> reminderEnabled,
  Value<bool> active,
  Value<int> rowid,
});
typedef $$TreatmentsTableUpdateCompanionBuilder = TreatmentsCompanion Function({
  Value<String> id,
  Value<String> petId,
  Value<EventType> type,
  Value<String> name,
  Value<int> intervalValue,
  Value<IntervalUnit> intervalUnit,
  Value<DateTime> nextDueDate,
  Value<int> reminderDaysBefore,
  Value<bool> reminderEnabled,
  Value<bool> active,
  Value<int> rowid,
});

class $$TreatmentsTableFilterComposer
    extends Composer<_$AppDatabase, $TreatmentsTable> {
  $$TreatmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get petId => $composableBuilder(
    column: $table.petId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<EventType, EventType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalValue => $composableBuilder(
    column: $table.intervalValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<IntervalUnit, IntervalUnit, String>
  get intervalUnit => $composableBuilder(
    column: $table.intervalUnit,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get nextDueDate => $composableBuilder(
    column: $table.nextDueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderDaysBefore => $composableBuilder(
    column: $table.reminderDaysBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get reminderEnabled => $composableBuilder(
    column: $table.reminderEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TreatmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $TreatmentsTable> {
  $$TreatmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get petId => $composableBuilder(
    column: $table.petId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalValue => $composableBuilder(
    column: $table.intervalValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get intervalUnit => $composableBuilder(
    column: $table.intervalUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextDueDate => $composableBuilder(
    column: $table.nextDueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderDaysBefore => $composableBuilder(
    column: $table.reminderDaysBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get reminderEnabled => $composableBuilder(
    column: $table.reminderEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TreatmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TreatmentsTable> {
  $$TreatmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get petId =>
      $composableBuilder(column: $table.petId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<EventType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get intervalValue => $composableBuilder(
    column: $table.intervalValue,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<IntervalUnit, String> get intervalUnit =>
      $composableBuilder(
        column: $table.intervalUnit,
        builder: (column) => column,
      );

  GeneratedColumn<DateTime> get nextDueDate => $composableBuilder(
    column: $table.nextDueDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderDaysBefore => $composableBuilder(
    column: $table.reminderDaysBefore,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get reminderEnabled => $composableBuilder(
    column: $table.reminderEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);
}

class $$TreatmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TreatmentsTable,
          TreatmentRow,
          $$TreatmentsTableFilterComposer,
          $$TreatmentsTableOrderingComposer,
          $$TreatmentsTableAnnotationComposer,
          $$TreatmentsTableCreateCompanionBuilder,
          $$TreatmentsTableUpdateCompanionBuilder,
          (
            TreatmentRow,
            BaseReferences<_$AppDatabase, $TreatmentsTable, TreatmentRow>,
          ),
          TreatmentRow,
          PrefetchHooks Function()
        > {
  $$TreatmentsTableTableManager(_$AppDatabase db, $TreatmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TreatmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TreatmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TreatmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> petId = const Value.absent(),
                Value<EventType> type = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> intervalValue = const Value.absent(),
                Value<IntervalUnit> intervalUnit = const Value.absent(),
                Value<DateTime> nextDueDate = const Value.absent(),
                Value<int> reminderDaysBefore = const Value.absent(),
                Value<bool> reminderEnabled = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TreatmentsCompanion(
                id: id,
                petId: petId,
                type: type,
                name: name,
                intervalValue: intervalValue,
                intervalUnit: intervalUnit,
                nextDueDate: nextDueDate,
                reminderDaysBefore: reminderDaysBefore,
                reminderEnabled: reminderEnabled,
                active: active,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String petId,
                required EventType type,
                required String name,
                required int intervalValue,
                required IntervalUnit intervalUnit,
                required DateTime nextDueDate,
                Value<int> reminderDaysBefore = const Value.absent(),
                Value<bool> reminderEnabled = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TreatmentsCompanion.insert(
                id: id,
                petId: petId,
                type: type,
                name: name,
                intervalValue: intervalValue,
                intervalUnit: intervalUnit,
                nextDueDate: nextDueDate,
                reminderDaysBefore: reminderDaysBefore,
                reminderEnabled: reminderEnabled,
                active: active,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TreatmentsTable, TreatmentRow>(table),
                  BaseReferences<_$AppDatabase, $TreatmentsTable, TreatmentRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TreatmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TreatmentsTable,
      TreatmentRow,
      $$TreatmentsTableFilterComposer,
      $$TreatmentsTableOrderingComposer,
      $$TreatmentsTableAnnotationComposer,
      $$TreatmentsTableCreateCompanionBuilder,
      $$TreatmentsTableUpdateCompanionBuilder,
      (
        TreatmentRow,
        BaseReferences<_$AppDatabase, $TreatmentsTable, TreatmentRow>,
      ),
      TreatmentRow,
      PrefetchHooks Function()
    >;
typedef $$HealthEventsTableCreateCompanionBuilder =
    HealthEventsCompanion Function({
      required String id,
      required String petId,
      Value<String?> treatmentId,
      required EventType type,
      required String title,
      required DateTime occurredAt,
      Value<String?> product,
      Value<String?> lot,
      Value<String?> vetName,
      Value<String?> clinic,
      Value<String?> notes,
      Value<double?> weightKg,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$HealthEventsTableUpdateCompanionBuilder =
    HealthEventsCompanion Function({
      Value<String> id,
      Value<String> petId,
      Value<String?> treatmentId,
      Value<EventType> type,
      Value<String> title,
      Value<DateTime> occurredAt,
      Value<String?> product,
      Value<String?> lot,
      Value<String?> vetName,
      Value<String?> clinic,
      Value<String?> notes,
      Value<double?> weightKg,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$HealthEventsTableFilterComposer
    extends Composer<_$AppDatabase, $HealthEventsTable> {
  $$HealthEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get petId => $composableBuilder(
    column: $table.petId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get treatmentId => $composableBuilder(
    column: $table.treatmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<EventType, EventType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get product => $composableBuilder(
    column: $table.product,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lot => $composableBuilder(
    column: $table.lot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vetName => $composableBuilder(
    column: $table.vetName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clinic => $composableBuilder(
    column: $table.clinic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HealthEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $HealthEventsTable> {
  $$HealthEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get petId => $composableBuilder(
    column: $table.petId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get treatmentId => $composableBuilder(
    column: $table.treatmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get product => $composableBuilder(
    column: $table.product,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lot => $composableBuilder(
    column: $table.lot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vetName => $composableBuilder(
    column: $table.vetName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clinic => $composableBuilder(
    column: $table.clinic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HealthEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HealthEventsTable> {
  $$HealthEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get petId =>
      $composableBuilder(column: $table.petId, builder: (column) => column);

  GeneratedColumn<String> get treatmentId => $composableBuilder(
    column: $table.treatmentId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<EventType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get product =>
      $composableBuilder(column: $table.product, builder: (column) => column);

  GeneratedColumn<String> get lot =>
      $composableBuilder(column: $table.lot, builder: (column) => column);

  GeneratedColumn<String> get vetName =>
      $composableBuilder(column: $table.vetName, builder: (column) => column);

  GeneratedColumn<String> get clinic =>
      $composableBuilder(column: $table.clinic, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$HealthEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HealthEventsTable,
          EventRow,
          $$HealthEventsTableFilterComposer,
          $$HealthEventsTableOrderingComposer,
          $$HealthEventsTableAnnotationComposer,
          $$HealthEventsTableCreateCompanionBuilder,
          $$HealthEventsTableUpdateCompanionBuilder,
          (
            EventRow,
            BaseReferences<_$AppDatabase, $HealthEventsTable, EventRow>,
          ),
          EventRow,
          PrefetchHooks Function()
        > {
  $$HealthEventsTableTableManager(_$AppDatabase db, $HealthEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HealthEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HealthEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HealthEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> petId = const Value.absent(),
                Value<String?> treatmentId = const Value.absent(),
                Value<EventType> type = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<String?> product = const Value.absent(),
                Value<String?> lot = const Value.absent(),
                Value<String?> vetName = const Value.absent(),
                Value<String?> clinic = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HealthEventsCompanion(
                id: id,
                petId: petId,
                treatmentId: treatmentId,
                type: type,
                title: title,
                occurredAt: occurredAt,
                product: product,
                lot: lot,
                vetName: vetName,
                clinic: clinic,
                notes: notes,
                weightKg: weightKg,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String petId,
                Value<String?> treatmentId = const Value.absent(),
                required EventType type,
                required String title,
                required DateTime occurredAt,
                Value<String?> product = const Value.absent(),
                Value<String?> lot = const Value.absent(),
                Value<String?> vetName = const Value.absent(),
                Value<String?> clinic = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => HealthEventsCompanion.insert(
                id: id,
                petId: petId,
                treatmentId: treatmentId,
                type: type,
                title: title,
                occurredAt: occurredAt,
                product: product,
                lot: lot,
                vetName: vetName,
                clinic: clinic,
                notes: notes,
                weightKg: weightKg,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HealthEventsTable, EventRow>(table),
                  BaseReferences<_$AppDatabase, $HealthEventsTable, EventRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HealthEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HealthEventsTable,
      EventRow,
      $$HealthEventsTableFilterComposer,
      $$HealthEventsTableOrderingComposer,
      $$HealthEventsTableAnnotationComposer,
      $$HealthEventsTableCreateCompanionBuilder,
      $$HealthEventsTableUpdateCompanionBuilder,
      (EventRow, BaseReferences<_$AppDatabase, $HealthEventsTable, EventRow>),
      EventRow,
      PrefetchHooks Function()
    >;
typedef $$AttachmentsTableCreateCompanionBuilder =
    AttachmentsCompanion Function({
      required String id,
      required String eventId,
      required String relativePath,
      required AttachmentKind kind,
      Value<String?> label,
      Value<int> rowid,
    });
typedef $$AttachmentsTableUpdateCompanionBuilder =
    AttachmentsCompanion Function({
      Value<String> id,
      Value<String> eventId,
      Value<String> relativePath,
      Value<AttachmentKind> kind,
      Value<String?> label,
      Value<int> rowid,
    });

class $$AttachmentsTableFilterComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AttachmentKind, AttachmentKind, String>
  get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AttachmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AttachmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<AttachmentKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);
}

class $$AttachmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttachmentsTable,
          AttachmentRow,
          $$AttachmentsTableFilterComposer,
          $$AttachmentsTableOrderingComposer,
          $$AttachmentsTableAnnotationComposer,
          $$AttachmentsTableCreateCompanionBuilder,
          $$AttachmentsTableUpdateCompanionBuilder,
          (
            AttachmentRow,
            BaseReferences<_$AppDatabase, $AttachmentsTable, AttachmentRow>,
          ),
          AttachmentRow,
          PrefetchHooks Function()
        > {
  $$AttachmentsTableTableManager(_$AppDatabase db, $AttachmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttachmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> eventId = const Value.absent(),
                Value<String> relativePath = const Value.absent(),
                Value<AttachmentKind> kind = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttachmentsCompanion(
                id: id,
                eventId: eventId,
                relativePath: relativePath,
                kind: kind,
                label: label,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String eventId,
                required String relativePath,
                required AttachmentKind kind,
                Value<String?> label = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttachmentsCompanion.insert(
                id: id,
                eventId: eventId,
                relativePath: relativePath,
                kind: kind,
                label: label,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AttachmentsTable, AttachmentRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AttachmentsTable,
                    AttachmentRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AttachmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttachmentsTable,
      AttachmentRow,
      $$AttachmentsTableFilterComposer,
      $$AttachmentsTableOrderingComposer,
      $$AttachmentsTableAnnotationComposer,
      $$AttachmentsTableCreateCompanionBuilder,
      $$AttachmentsTableUpdateCompanionBuilder,
      (
        AttachmentRow,
        BaseReferences<_$AppDatabase, $AttachmentsTable, AttachmentRow>,
      ),
      AttachmentRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PetsTableTableManager get pets => $$PetsTableTableManager(_db, _db.pets);
  $$WeightEntriesTableTableManager get weightEntries =>
      $$WeightEntriesTableTableManager(_db, _db.weightEntries);
  $$TreatmentsTableTableManager get treatments =>
      $$TreatmentsTableTableManager(_db, _db.treatments);
  $$HealthEventsTableTableManager get healthEvents =>
      $$HealthEventsTableTableManager(_db, _db.healthEvents);
  $$AttachmentsTableTableManager get attachments =>
      $$AttachmentsTableTableManager(_db, _db.attachments);
}
