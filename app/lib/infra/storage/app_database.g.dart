// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $MealsTable extends Meals with TableInfo<$MealsTable, Meal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _eatenAtMeta = const VerificationMeta(
    'eatenAt',
  );
  @override
  late final GeneratedColumn<DateTime> eatenAt = GeneratedColumn<DateTime>(
    'eaten_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mealTypeMeta = const VerificationMeta(
    'mealType',
  );
  @override
  late final GeneratedColumn<String> mealType = GeneratedColumn<String>(
    'meal_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<String> confidence = GeneratedColumn<String>(
    'confidence',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _catalogVersionMeta = const VerificationMeta(
    'catalogVersion',
  );
  @override
  late final GeneratedColumn<String> catalogVersion = GeneratedColumn<String>(
    'catalog_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    eatenAt,
    mealType,
    confidence,
    catalogVersion,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meals';
  @override
  VerificationContext validateIntegrity(
    Insertable<Meal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('eaten_at')) {
      context.handle(
        _eatenAtMeta,
        eatenAt.isAcceptableOrUnknown(data['eaten_at']!, _eatenAtMeta),
      );
    } else if (isInserting) {
      context.missing(_eatenAtMeta);
    }
    if (data.containsKey('meal_type')) {
      context.handle(
        _mealTypeMeta,
        mealType.isAcceptableOrUnknown(data['meal_type']!, _mealTypeMeta),
      );
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    } else if (isInserting) {
      context.missing(_confidenceMeta);
    }
    if (data.containsKey('catalog_version')) {
      context.handle(
        _catalogVersionMeta,
        catalogVersion.isAcceptableOrUnknown(
          data['catalog_version']!,
          _catalogVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_catalogVersionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Meal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Meal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      eatenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}eaten_at'],
      )!,
      mealType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meal_type'],
      ),
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}confidence'],
      )!,
      catalogVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}catalog_version'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MealsTable createAlias(String alias) {
    return $MealsTable(attachedDatabase, alias);
  }
}

class Meal extends DataClass implements Insertable<Meal> {
  final int id;
  final DateTime eatenAt;
  final String? mealType;
  final String confidence;
  final String catalogVersion;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Meal({
    required this.id,
    required this.eatenAt,
    this.mealType,
    required this.confidence,
    required this.catalogVersion,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['eaten_at'] = Variable<DateTime>(eatenAt);
    if (!nullToAbsent || mealType != null) {
      map['meal_type'] = Variable<String>(mealType);
    }
    map['confidence'] = Variable<String>(confidence);
    map['catalog_version'] = Variable<String>(catalogVersion);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MealsCompanion toCompanion(bool nullToAbsent) {
    return MealsCompanion(
      id: Value(id),
      eatenAt: Value(eatenAt),
      mealType: mealType == null && nullToAbsent
          ? const Value.absent()
          : Value(mealType),
      confidence: Value(confidence),
      catalogVersion: Value(catalogVersion),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Meal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Meal(
      id: serializer.fromJson<int>(json['id']),
      eatenAt: serializer.fromJson<DateTime>(json['eatenAt']),
      mealType: serializer.fromJson<String?>(json['mealType']),
      confidence: serializer.fromJson<String>(json['confidence']),
      catalogVersion: serializer.fromJson<String>(json['catalogVersion']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'eatenAt': serializer.toJson<DateTime>(eatenAt),
      'mealType': serializer.toJson<String?>(mealType),
      'confidence': serializer.toJson<String>(confidence),
      'catalogVersion': serializer.toJson<String>(catalogVersion),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Meal copyWith({
    int? id,
    DateTime? eatenAt,
    Value<String?> mealType = const Value.absent(),
    String? confidence,
    String? catalogVersion,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Meal(
    id: id ?? this.id,
    eatenAt: eatenAt ?? this.eatenAt,
    mealType: mealType.present ? mealType.value : this.mealType,
    confidence: confidence ?? this.confidence,
    catalogVersion: catalogVersion ?? this.catalogVersion,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Meal copyWithCompanion(MealsCompanion data) {
    return Meal(
      id: data.id.present ? data.id.value : this.id,
      eatenAt: data.eatenAt.present ? data.eatenAt.value : this.eatenAt,
      mealType: data.mealType.present ? data.mealType.value : this.mealType,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      catalogVersion: data.catalogVersion.present
          ? data.catalogVersion.value
          : this.catalogVersion,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Meal(')
          ..write('id: $id, ')
          ..write('eatenAt: $eatenAt, ')
          ..write('mealType: $mealType, ')
          ..write('confidence: $confidence, ')
          ..write('catalogVersion: $catalogVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    eatenAt,
    mealType,
    confidence,
    catalogVersion,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Meal &&
          other.id == this.id &&
          other.eatenAt == this.eatenAt &&
          other.mealType == this.mealType &&
          other.confidence == this.confidence &&
          other.catalogVersion == this.catalogVersion &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MealsCompanion extends UpdateCompanion<Meal> {
  final Value<int> id;
  final Value<DateTime> eatenAt;
  final Value<String?> mealType;
  final Value<String> confidence;
  final Value<String> catalogVersion;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const MealsCompanion({
    this.id = const Value.absent(),
    this.eatenAt = const Value.absent(),
    this.mealType = const Value.absent(),
    this.confidence = const Value.absent(),
    this.catalogVersion = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  MealsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime eatenAt,
    this.mealType = const Value.absent(),
    required String confidence,
    required String catalogVersion,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : eatenAt = Value(eatenAt),
       confidence = Value(confidence),
       catalogVersion = Value(catalogVersion);
  static Insertable<Meal> custom({
    Expression<int>? id,
    Expression<DateTime>? eatenAt,
    Expression<String>? mealType,
    Expression<String>? confidence,
    Expression<String>? catalogVersion,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eatenAt != null) 'eaten_at': eatenAt,
      if (mealType != null) 'meal_type': mealType,
      if (confidence != null) 'confidence': confidence,
      if (catalogVersion != null) 'catalog_version': catalogVersion,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  MealsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? eatenAt,
    Value<String?>? mealType,
    Value<String>? confidence,
    Value<String>? catalogVersion,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return MealsCompanion(
      id: id ?? this.id,
      eatenAt: eatenAt ?? this.eatenAt,
      mealType: mealType ?? this.mealType,
      confidence: confidence ?? this.confidence,
      catalogVersion: catalogVersion ?? this.catalogVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (eatenAt.present) {
      map['eaten_at'] = Variable<DateTime>(eatenAt.value);
    }
    if (mealType.present) {
      map['meal_type'] = Variable<String>(mealType.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<String>(confidence.value);
    }
    if (catalogVersion.present) {
      map['catalog_version'] = Variable<String>(catalogVersion.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealsCompanion(')
          ..write('id: $id, ')
          ..write('eatenAt: $eatenAt, ')
          ..write('mealType: $mealType, ')
          ..write('confidence: $confidence, ')
          ..write('catalogVersion: $catalogVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $MealItemsTable extends MealItems
    with TableInfo<$MealItemsTable, MealItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _mealIdMeta = const VerificationMeta('mealId');
  @override
  late final GeneratedColumn<int> mealId = GeneratedColumn<int>(
    'meal_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES meals (id)',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mentionMeta = const VerificationMeta(
    'mention',
  );
  @override
  late final GeneratedColumn<String> mention = GeneratedColumn<String>(
    'mention',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _foodIdMeta = const VerificationMeta('foodId');
  @override
  late final GeneratedColumn<String> foodId = GeneratedColumn<String>(
    'food_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _personalProductIdMeta = const VerificationMeta(
    'personalProductId',
  );
  @override
  late final GeneratedColumn<String> personalProductId =
      GeneratedColumn<String>(
        'personal_product_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _nameSnapshotMeta = const VerificationMeta(
    'nameSnapshot',
  );
  @override
  late final GeneratedColumn<String> nameSnapshot = GeneratedColumn<String>(
    'name_snapshot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gramsMeta = const VerificationMeta('grams');
  @override
  late final GeneratedColumn<double> grams = GeneratedColumn<double>(
    'grams',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityInputMeta = const VerificationMeta(
    'quantityInput',
  );
  @override
  late final GeneratedColumn<double> quantityInput = GeneratedColumn<double>(
    'quantity_input',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitInputMeta = const VerificationMeta(
    'unitInput',
  );
  @override
  late final GeneratedColumn<String> unitInput = GeneratedColumn<String>(
    'unit_input',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeInputMeta = const VerificationMeta(
    'sizeInput',
  );
  @override
  late final GeneratedColumn<String> sizeInput = GeneratedColumn<String>(
    'size_input',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityBasisMeta = const VerificationMeta(
    'quantityBasis',
  );
  @override
  late final GeneratedColumn<String> quantityBasis = GeneratedColumn<String>(
    'quantity_basis',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _energyKcalMeta = const VerificationMeta(
    'energyKcal',
  );
  @override
  late final GeneratedColumn<double> energyKcal = GeneratedColumn<double>(
    'energy_kcal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinGMeta = const VerificationMeta(
    'proteinG',
  );
  @override
  late final GeneratedColumn<double> proteinG = GeneratedColumn<double>(
    'protein_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbsGMeta = const VerificationMeta('carbsG');
  @override
  late final GeneratedColumn<double> carbsG = GeneratedColumn<double>(
    'carbs_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fatGMeta = const VerificationMeta('fatG');
  @override
  late final GeneratedColumn<double> fatG = GeneratedColumn<double>(
    'fat_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<String> confidence = GeneratedColumn<String>(
    'confidence',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceRefMeta = const VerificationMeta(
    'sourceRef',
  );
  @override
  late final GeneratedColumn<String> sourceRef = GeneratedColumn<String>(
    'source_ref',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    mealId,
    position,
    mention,
    foodId,
    personalProductId,
    nameSnapshot,
    grams,
    quantityInput,
    unitInput,
    sizeInput,
    quantityBasis,
    energyKcal,
    proteinG,
    carbsG,
    fatG,
    confidence,
    sourceRef,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<MealItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('meal_id')) {
      context.handle(
        _mealIdMeta,
        mealId.isAcceptableOrUnknown(data['meal_id']!, _mealIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mealIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('mention')) {
      context.handle(
        _mentionMeta,
        mention.isAcceptableOrUnknown(data['mention']!, _mentionMeta),
      );
    } else if (isInserting) {
      context.missing(_mentionMeta);
    }
    if (data.containsKey('food_id')) {
      context.handle(
        _foodIdMeta,
        foodId.isAcceptableOrUnknown(data['food_id']!, _foodIdMeta),
      );
    }
    if (data.containsKey('personal_product_id')) {
      context.handle(
        _personalProductIdMeta,
        personalProductId.isAcceptableOrUnknown(
          data['personal_product_id']!,
          _personalProductIdMeta,
        ),
      );
    }
    if (data.containsKey('name_snapshot')) {
      context.handle(
        _nameSnapshotMeta,
        nameSnapshot.isAcceptableOrUnknown(
          data['name_snapshot']!,
          _nameSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nameSnapshotMeta);
    }
    if (data.containsKey('grams')) {
      context.handle(
        _gramsMeta,
        grams.isAcceptableOrUnknown(data['grams']!, _gramsMeta),
      );
    } else if (isInserting) {
      context.missing(_gramsMeta);
    }
    if (data.containsKey('quantity_input')) {
      context.handle(
        _quantityInputMeta,
        quantityInput.isAcceptableOrUnknown(
          data['quantity_input']!,
          _quantityInputMeta,
        ),
      );
    }
    if (data.containsKey('unit_input')) {
      context.handle(
        _unitInputMeta,
        unitInput.isAcceptableOrUnknown(data['unit_input']!, _unitInputMeta),
      );
    }
    if (data.containsKey('size_input')) {
      context.handle(
        _sizeInputMeta,
        sizeInput.isAcceptableOrUnknown(data['size_input']!, _sizeInputMeta),
      );
    }
    if (data.containsKey('quantity_basis')) {
      context.handle(
        _quantityBasisMeta,
        quantityBasis.isAcceptableOrUnknown(
          data['quantity_basis']!,
          _quantityBasisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_quantityBasisMeta);
    }
    if (data.containsKey('energy_kcal')) {
      context.handle(
        _energyKcalMeta,
        energyKcal.isAcceptableOrUnknown(data['energy_kcal']!, _energyKcalMeta),
      );
    } else if (isInserting) {
      context.missing(_energyKcalMeta);
    }
    if (data.containsKey('protein_g')) {
      context.handle(
        _proteinGMeta,
        proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta),
      );
    } else if (isInserting) {
      context.missing(_proteinGMeta);
    }
    if (data.containsKey('carbs_g')) {
      context.handle(
        _carbsGMeta,
        carbsG.isAcceptableOrUnknown(data['carbs_g']!, _carbsGMeta),
      );
    } else if (isInserting) {
      context.missing(_carbsGMeta);
    }
    if (data.containsKey('fat_g')) {
      context.handle(
        _fatGMeta,
        fatG.isAcceptableOrUnknown(data['fat_g']!, _fatGMeta),
      );
    } else if (isInserting) {
      context.missing(_fatGMeta);
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    } else if (isInserting) {
      context.missing(_confidenceMeta);
    }
    if (data.containsKey('source_ref')) {
      context.handle(
        _sourceRefMeta,
        sourceRef.isAcceptableOrUnknown(data['source_ref']!, _sourceRefMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceRefMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MealItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      mealId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}meal_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      mention: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mention'],
      )!,
      foodId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_id'],
      ),
      personalProductId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}personal_product_id'],
      ),
      nameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_snapshot'],
      )!,
      grams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grams'],
      )!,
      quantityInput: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity_input'],
      ),
      unitInput: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit_input'],
      ),
      sizeInput: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}size_input'],
      ),
      quantityBasis: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quantity_basis'],
      )!,
      energyKcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}energy_kcal'],
      )!,
      proteinG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_g'],
      )!,
      carbsG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs_g'],
      )!,
      fatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_g'],
      )!,
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}confidence'],
      )!,
      sourceRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_ref'],
      )!,
    );
  }

  @override
  $MealItemsTable createAlias(String alias) {
    return $MealItemsTable(attachedDatabase, alias);
  }
}

class MealItem extends DataClass implements Insertable<MealItem> {
  final int id;
  final int mealId;
  final int position;
  final String mention;
  final String? foodId;
  final String? personalProductId;
  final String nameSnapshot;
  final double grams;
  final double? quantityInput;
  final String? unitInput;
  final String? sizeInput;
  final String quantityBasis;
  final double energyKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final String confidence;
  final String sourceRef;
  const MealItem({
    required this.id,
    required this.mealId,
    required this.position,
    required this.mention,
    this.foodId,
    this.personalProductId,
    required this.nameSnapshot,
    required this.grams,
    this.quantityInput,
    this.unitInput,
    this.sizeInput,
    required this.quantityBasis,
    required this.energyKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.confidence,
    required this.sourceRef,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['meal_id'] = Variable<int>(mealId);
    map['position'] = Variable<int>(position);
    map['mention'] = Variable<String>(mention);
    if (!nullToAbsent || foodId != null) {
      map['food_id'] = Variable<String>(foodId);
    }
    if (!nullToAbsent || personalProductId != null) {
      map['personal_product_id'] = Variable<String>(personalProductId);
    }
    map['name_snapshot'] = Variable<String>(nameSnapshot);
    map['grams'] = Variable<double>(grams);
    if (!nullToAbsent || quantityInput != null) {
      map['quantity_input'] = Variable<double>(quantityInput);
    }
    if (!nullToAbsent || unitInput != null) {
      map['unit_input'] = Variable<String>(unitInput);
    }
    if (!nullToAbsent || sizeInput != null) {
      map['size_input'] = Variable<String>(sizeInput);
    }
    map['quantity_basis'] = Variable<String>(quantityBasis);
    map['energy_kcal'] = Variable<double>(energyKcal);
    map['protein_g'] = Variable<double>(proteinG);
    map['carbs_g'] = Variable<double>(carbsG);
    map['fat_g'] = Variable<double>(fatG);
    map['confidence'] = Variable<String>(confidence);
    map['source_ref'] = Variable<String>(sourceRef);
    return map;
  }

  MealItemsCompanion toCompanion(bool nullToAbsent) {
    return MealItemsCompanion(
      id: Value(id),
      mealId: Value(mealId),
      position: Value(position),
      mention: Value(mention),
      foodId: foodId == null && nullToAbsent
          ? const Value.absent()
          : Value(foodId),
      personalProductId: personalProductId == null && nullToAbsent
          ? const Value.absent()
          : Value(personalProductId),
      nameSnapshot: Value(nameSnapshot),
      grams: Value(grams),
      quantityInput: quantityInput == null && nullToAbsent
          ? const Value.absent()
          : Value(quantityInput),
      unitInput: unitInput == null && nullToAbsent
          ? const Value.absent()
          : Value(unitInput),
      sizeInput: sizeInput == null && nullToAbsent
          ? const Value.absent()
          : Value(sizeInput),
      quantityBasis: Value(quantityBasis),
      energyKcal: Value(energyKcal),
      proteinG: Value(proteinG),
      carbsG: Value(carbsG),
      fatG: Value(fatG),
      confidence: Value(confidence),
      sourceRef: Value(sourceRef),
    );
  }

  factory MealItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealItem(
      id: serializer.fromJson<int>(json['id']),
      mealId: serializer.fromJson<int>(json['mealId']),
      position: serializer.fromJson<int>(json['position']),
      mention: serializer.fromJson<String>(json['mention']),
      foodId: serializer.fromJson<String?>(json['foodId']),
      personalProductId: serializer.fromJson<String?>(
        json['personalProductId'],
      ),
      nameSnapshot: serializer.fromJson<String>(json['nameSnapshot']),
      grams: serializer.fromJson<double>(json['grams']),
      quantityInput: serializer.fromJson<double?>(json['quantityInput']),
      unitInput: serializer.fromJson<String?>(json['unitInput']),
      sizeInput: serializer.fromJson<String?>(json['sizeInput']),
      quantityBasis: serializer.fromJson<String>(json['quantityBasis']),
      energyKcal: serializer.fromJson<double>(json['energyKcal']),
      proteinG: serializer.fromJson<double>(json['proteinG']),
      carbsG: serializer.fromJson<double>(json['carbsG']),
      fatG: serializer.fromJson<double>(json['fatG']),
      confidence: serializer.fromJson<String>(json['confidence']),
      sourceRef: serializer.fromJson<String>(json['sourceRef']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'mealId': serializer.toJson<int>(mealId),
      'position': serializer.toJson<int>(position),
      'mention': serializer.toJson<String>(mention),
      'foodId': serializer.toJson<String?>(foodId),
      'personalProductId': serializer.toJson<String?>(personalProductId),
      'nameSnapshot': serializer.toJson<String>(nameSnapshot),
      'grams': serializer.toJson<double>(grams),
      'quantityInput': serializer.toJson<double?>(quantityInput),
      'unitInput': serializer.toJson<String?>(unitInput),
      'sizeInput': serializer.toJson<String?>(sizeInput),
      'quantityBasis': serializer.toJson<String>(quantityBasis),
      'energyKcal': serializer.toJson<double>(energyKcal),
      'proteinG': serializer.toJson<double>(proteinG),
      'carbsG': serializer.toJson<double>(carbsG),
      'fatG': serializer.toJson<double>(fatG),
      'confidence': serializer.toJson<String>(confidence),
      'sourceRef': serializer.toJson<String>(sourceRef),
    };
  }

  MealItem copyWith({
    int? id,
    int? mealId,
    int? position,
    String? mention,
    Value<String?> foodId = const Value.absent(),
    Value<String?> personalProductId = const Value.absent(),
    String? nameSnapshot,
    double? grams,
    Value<double?> quantityInput = const Value.absent(),
    Value<String?> unitInput = const Value.absent(),
    Value<String?> sizeInput = const Value.absent(),
    String? quantityBasis,
    double? energyKcal,
    double? proteinG,
    double? carbsG,
    double? fatG,
    String? confidence,
    String? sourceRef,
  }) => MealItem(
    id: id ?? this.id,
    mealId: mealId ?? this.mealId,
    position: position ?? this.position,
    mention: mention ?? this.mention,
    foodId: foodId.present ? foodId.value : this.foodId,
    personalProductId: personalProductId.present
        ? personalProductId.value
        : this.personalProductId,
    nameSnapshot: nameSnapshot ?? this.nameSnapshot,
    grams: grams ?? this.grams,
    quantityInput: quantityInput.present
        ? quantityInput.value
        : this.quantityInput,
    unitInput: unitInput.present ? unitInput.value : this.unitInput,
    sizeInput: sizeInput.present ? sizeInput.value : this.sizeInput,
    quantityBasis: quantityBasis ?? this.quantityBasis,
    energyKcal: energyKcal ?? this.energyKcal,
    proteinG: proteinG ?? this.proteinG,
    carbsG: carbsG ?? this.carbsG,
    fatG: fatG ?? this.fatG,
    confidence: confidence ?? this.confidence,
    sourceRef: sourceRef ?? this.sourceRef,
  );
  MealItem copyWithCompanion(MealItemsCompanion data) {
    return MealItem(
      id: data.id.present ? data.id.value : this.id,
      mealId: data.mealId.present ? data.mealId.value : this.mealId,
      position: data.position.present ? data.position.value : this.position,
      mention: data.mention.present ? data.mention.value : this.mention,
      foodId: data.foodId.present ? data.foodId.value : this.foodId,
      personalProductId: data.personalProductId.present
          ? data.personalProductId.value
          : this.personalProductId,
      nameSnapshot: data.nameSnapshot.present
          ? data.nameSnapshot.value
          : this.nameSnapshot,
      grams: data.grams.present ? data.grams.value : this.grams,
      quantityInput: data.quantityInput.present
          ? data.quantityInput.value
          : this.quantityInput,
      unitInput: data.unitInput.present ? data.unitInput.value : this.unitInput,
      sizeInput: data.sizeInput.present ? data.sizeInput.value : this.sizeInput,
      quantityBasis: data.quantityBasis.present
          ? data.quantityBasis.value
          : this.quantityBasis,
      energyKcal: data.energyKcal.present
          ? data.energyKcal.value
          : this.energyKcal,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      carbsG: data.carbsG.present ? data.carbsG.value : this.carbsG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      sourceRef: data.sourceRef.present ? data.sourceRef.value : this.sourceRef,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealItem(')
          ..write('id: $id, ')
          ..write('mealId: $mealId, ')
          ..write('position: $position, ')
          ..write('mention: $mention, ')
          ..write('foodId: $foodId, ')
          ..write('personalProductId: $personalProductId, ')
          ..write('nameSnapshot: $nameSnapshot, ')
          ..write('grams: $grams, ')
          ..write('quantityInput: $quantityInput, ')
          ..write('unitInput: $unitInput, ')
          ..write('sizeInput: $sizeInput, ')
          ..write('quantityBasis: $quantityBasis, ')
          ..write('energyKcal: $energyKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('confidence: $confidence, ')
          ..write('sourceRef: $sourceRef')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    mealId,
    position,
    mention,
    foodId,
    personalProductId,
    nameSnapshot,
    grams,
    quantityInput,
    unitInput,
    sizeInput,
    quantityBasis,
    energyKcal,
    proteinG,
    carbsG,
    fatG,
    confidence,
    sourceRef,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealItem &&
          other.id == this.id &&
          other.mealId == this.mealId &&
          other.position == this.position &&
          other.mention == this.mention &&
          other.foodId == this.foodId &&
          other.personalProductId == this.personalProductId &&
          other.nameSnapshot == this.nameSnapshot &&
          other.grams == this.grams &&
          other.quantityInput == this.quantityInput &&
          other.unitInput == this.unitInput &&
          other.sizeInput == this.sizeInput &&
          other.quantityBasis == this.quantityBasis &&
          other.energyKcal == this.energyKcal &&
          other.proteinG == this.proteinG &&
          other.carbsG == this.carbsG &&
          other.fatG == this.fatG &&
          other.confidence == this.confidence &&
          other.sourceRef == this.sourceRef);
}

class MealItemsCompanion extends UpdateCompanion<MealItem> {
  final Value<int> id;
  final Value<int> mealId;
  final Value<int> position;
  final Value<String> mention;
  final Value<String?> foodId;
  final Value<String?> personalProductId;
  final Value<String> nameSnapshot;
  final Value<double> grams;
  final Value<double?> quantityInput;
  final Value<String?> unitInput;
  final Value<String?> sizeInput;
  final Value<String> quantityBasis;
  final Value<double> energyKcal;
  final Value<double> proteinG;
  final Value<double> carbsG;
  final Value<double> fatG;
  final Value<String> confidence;
  final Value<String> sourceRef;
  const MealItemsCompanion({
    this.id = const Value.absent(),
    this.mealId = const Value.absent(),
    this.position = const Value.absent(),
    this.mention = const Value.absent(),
    this.foodId = const Value.absent(),
    this.personalProductId = const Value.absent(),
    this.nameSnapshot = const Value.absent(),
    this.grams = const Value.absent(),
    this.quantityInput = const Value.absent(),
    this.unitInput = const Value.absent(),
    this.sizeInput = const Value.absent(),
    this.quantityBasis = const Value.absent(),
    this.energyKcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.confidence = const Value.absent(),
    this.sourceRef = const Value.absent(),
  });
  MealItemsCompanion.insert({
    this.id = const Value.absent(),
    required int mealId,
    required int position,
    required String mention,
    this.foodId = const Value.absent(),
    this.personalProductId = const Value.absent(),
    required String nameSnapshot,
    required double grams,
    this.quantityInput = const Value.absent(),
    this.unitInput = const Value.absent(),
    this.sizeInput = const Value.absent(),
    required String quantityBasis,
    required double energyKcal,
    required double proteinG,
    required double carbsG,
    required double fatG,
    required String confidence,
    required String sourceRef,
  }) : mealId = Value(mealId),
       position = Value(position),
       mention = Value(mention),
       nameSnapshot = Value(nameSnapshot),
       grams = Value(grams),
       quantityBasis = Value(quantityBasis),
       energyKcal = Value(energyKcal),
       proteinG = Value(proteinG),
       carbsG = Value(carbsG),
       fatG = Value(fatG),
       confidence = Value(confidence),
       sourceRef = Value(sourceRef);
  static Insertable<MealItem> custom({
    Expression<int>? id,
    Expression<int>? mealId,
    Expression<int>? position,
    Expression<String>? mention,
    Expression<String>? foodId,
    Expression<String>? personalProductId,
    Expression<String>? nameSnapshot,
    Expression<double>? grams,
    Expression<double>? quantityInput,
    Expression<String>? unitInput,
    Expression<String>? sizeInput,
    Expression<String>? quantityBasis,
    Expression<double>? energyKcal,
    Expression<double>? proteinG,
    Expression<double>? carbsG,
    Expression<double>? fatG,
    Expression<String>? confidence,
    Expression<String>? sourceRef,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mealId != null) 'meal_id': mealId,
      if (position != null) 'position': position,
      if (mention != null) 'mention': mention,
      if (foodId != null) 'food_id': foodId,
      if (personalProductId != null) 'personal_product_id': personalProductId,
      if (nameSnapshot != null) 'name_snapshot': nameSnapshot,
      if (grams != null) 'grams': grams,
      if (quantityInput != null) 'quantity_input': quantityInput,
      if (unitInput != null) 'unit_input': unitInput,
      if (sizeInput != null) 'size_input': sizeInput,
      if (quantityBasis != null) 'quantity_basis': quantityBasis,
      if (energyKcal != null) 'energy_kcal': energyKcal,
      if (proteinG != null) 'protein_g': proteinG,
      if (carbsG != null) 'carbs_g': carbsG,
      if (fatG != null) 'fat_g': fatG,
      if (confidence != null) 'confidence': confidence,
      if (sourceRef != null) 'source_ref': sourceRef,
    });
  }

  MealItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? mealId,
    Value<int>? position,
    Value<String>? mention,
    Value<String?>? foodId,
    Value<String?>? personalProductId,
    Value<String>? nameSnapshot,
    Value<double>? grams,
    Value<double?>? quantityInput,
    Value<String?>? unitInput,
    Value<String?>? sizeInput,
    Value<String>? quantityBasis,
    Value<double>? energyKcal,
    Value<double>? proteinG,
    Value<double>? carbsG,
    Value<double>? fatG,
    Value<String>? confidence,
    Value<String>? sourceRef,
  }) {
    return MealItemsCompanion(
      id: id ?? this.id,
      mealId: mealId ?? this.mealId,
      position: position ?? this.position,
      mention: mention ?? this.mention,
      foodId: foodId ?? this.foodId,
      personalProductId: personalProductId ?? this.personalProductId,
      nameSnapshot: nameSnapshot ?? this.nameSnapshot,
      grams: grams ?? this.grams,
      quantityInput: quantityInput ?? this.quantityInput,
      unitInput: unitInput ?? this.unitInput,
      sizeInput: sizeInput ?? this.sizeInput,
      quantityBasis: quantityBasis ?? this.quantityBasis,
      energyKcal: energyKcal ?? this.energyKcal,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      confidence: confidence ?? this.confidence,
      sourceRef: sourceRef ?? this.sourceRef,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (mealId.present) {
      map['meal_id'] = Variable<int>(mealId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (mention.present) {
      map['mention'] = Variable<String>(mention.value);
    }
    if (foodId.present) {
      map['food_id'] = Variable<String>(foodId.value);
    }
    if (personalProductId.present) {
      map['personal_product_id'] = Variable<String>(personalProductId.value);
    }
    if (nameSnapshot.present) {
      map['name_snapshot'] = Variable<String>(nameSnapshot.value);
    }
    if (grams.present) {
      map['grams'] = Variable<double>(grams.value);
    }
    if (quantityInput.present) {
      map['quantity_input'] = Variable<double>(quantityInput.value);
    }
    if (unitInput.present) {
      map['unit_input'] = Variable<String>(unitInput.value);
    }
    if (sizeInput.present) {
      map['size_input'] = Variable<String>(sizeInput.value);
    }
    if (quantityBasis.present) {
      map['quantity_basis'] = Variable<String>(quantityBasis.value);
    }
    if (energyKcal.present) {
      map['energy_kcal'] = Variable<double>(energyKcal.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<double>(proteinG.value);
    }
    if (carbsG.present) {
      map['carbs_g'] = Variable<double>(carbsG.value);
    }
    if (fatG.present) {
      map['fat_g'] = Variable<double>(fatG.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<String>(confidence.value);
    }
    if (sourceRef.present) {
      map['source_ref'] = Variable<String>(sourceRef.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealItemsCompanion(')
          ..write('id: $id, ')
          ..write('mealId: $mealId, ')
          ..write('position: $position, ')
          ..write('mention: $mention, ')
          ..write('foodId: $foodId, ')
          ..write('personalProductId: $personalProductId, ')
          ..write('nameSnapshot: $nameSnapshot, ')
          ..write('grams: $grams, ')
          ..write('quantityInput: $quantityInput, ')
          ..write('unitInput: $unitInput, ')
          ..write('sizeInput: $sizeInput, ')
          ..write('quantityBasis: $quantityBasis, ')
          ..write('energyKcal: $energyKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('confidence: $confidence, ')
          ..write('sourceRef: $sourceRef')
          ..write(')'))
        .toString();
  }
}

class $PersonalProductsTable extends PersonalProducts
    with TableInfo<$PersonalProductsTable, PersonalProduct> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonalProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameEsMeta = const VerificationMeta('nameEs');
  @override
  late final GeneratedColumn<String> nameEs = GeneratedColumn<String>(
    'name_es',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _energyKcal100Meta = const VerificationMeta(
    'energyKcal100',
  );
  @override
  late final GeneratedColumn<double> energyKcal100 = GeneratedColumn<double>(
    'energy_kcal100',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinG100Meta = const VerificationMeta(
    'proteinG100',
  );
  @override
  late final GeneratedColumn<double> proteinG100 = GeneratedColumn<double>(
    'protein_g100',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbsG100Meta = const VerificationMeta(
    'carbsG100',
  );
  @override
  late final GeneratedColumn<double> carbsG100 = GeneratedColumn<double>(
    'carbs_g100',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fatG100Meta = const VerificationMeta(
    'fatG100',
  );
  @override
  late final GeneratedColumn<double> fatG100 = GeneratedColumn<double>(
    'fat_g100',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fiberG100Meta = const VerificationMeta(
    'fiberG100',
  );
  @override
  late final GeneratedColumn<double> fiberG100 = GeneratedColumn<double>(
    'fiber_g100',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sugarG100Meta = const VerificationMeta(
    'sugarG100',
  );
  @override
  late final GeneratedColumn<double> sugarG100 = GeneratedColumn<double>(
    'sugar_g100',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sodiumMg100Meta = const VerificationMeta(
    'sodiumMg100',
  );
  @override
  late final GeneratedColumn<double> sodiumMg100 = GeneratedColumn<double>(
    'sodium_mg100',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _servingGramsMeta = const VerificationMeta(
    'servingGrams',
  );
  @override
  late final GeneratedColumn<double> servingGrams = GeneratedColumn<double>(
    'serving_grams',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _densityGPerMlMeta = const VerificationMeta(
    'densityGPerMl',
  );
  @override
  late final GeneratedColumn<double> densityGPerMl = GeneratedColumn<double>(
    'density_g_per_ml',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceRefMeta = const VerificationMeta(
    'sourceRef',
  );
  @override
  late final GeneratedColumn<String> sourceRef = GeneratedColumn<String>(
    'source_ref',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nameEs,
    energyKcal100,
    proteinG100,
    carbsG100,
    fatG100,
    fiberG100,
    sugarG100,
    sodiumMg100,
    servingGrams,
    densityGPerMl,
    sourceRef,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'personal_products';
  @override
  VerificationContext validateIntegrity(
    Insertable<PersonalProduct> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name_es')) {
      context.handle(
        _nameEsMeta,
        nameEs.isAcceptableOrUnknown(data['name_es']!, _nameEsMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEsMeta);
    }
    if (data.containsKey('energy_kcal100')) {
      context.handle(
        _energyKcal100Meta,
        energyKcal100.isAcceptableOrUnknown(
          data['energy_kcal100']!,
          _energyKcal100Meta,
        ),
      );
    } else if (isInserting) {
      context.missing(_energyKcal100Meta);
    }
    if (data.containsKey('protein_g100')) {
      context.handle(
        _proteinG100Meta,
        proteinG100.isAcceptableOrUnknown(
          data['protein_g100']!,
          _proteinG100Meta,
        ),
      );
    } else if (isInserting) {
      context.missing(_proteinG100Meta);
    }
    if (data.containsKey('carbs_g100')) {
      context.handle(
        _carbsG100Meta,
        carbsG100.isAcceptableOrUnknown(data['carbs_g100']!, _carbsG100Meta),
      );
    } else if (isInserting) {
      context.missing(_carbsG100Meta);
    }
    if (data.containsKey('fat_g100')) {
      context.handle(
        _fatG100Meta,
        fatG100.isAcceptableOrUnknown(data['fat_g100']!, _fatG100Meta),
      );
    } else if (isInserting) {
      context.missing(_fatG100Meta);
    }
    if (data.containsKey('fiber_g100')) {
      context.handle(
        _fiberG100Meta,
        fiberG100.isAcceptableOrUnknown(data['fiber_g100']!, _fiberG100Meta),
      );
    }
    if (data.containsKey('sugar_g100')) {
      context.handle(
        _sugarG100Meta,
        sugarG100.isAcceptableOrUnknown(data['sugar_g100']!, _sugarG100Meta),
      );
    }
    if (data.containsKey('sodium_mg100')) {
      context.handle(
        _sodiumMg100Meta,
        sodiumMg100.isAcceptableOrUnknown(
          data['sodium_mg100']!,
          _sodiumMg100Meta,
        ),
      );
    }
    if (data.containsKey('serving_grams')) {
      context.handle(
        _servingGramsMeta,
        servingGrams.isAcceptableOrUnknown(
          data['serving_grams']!,
          _servingGramsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_servingGramsMeta);
    }
    if (data.containsKey('density_g_per_ml')) {
      context.handle(
        _densityGPerMlMeta,
        densityGPerMl.isAcceptableOrUnknown(
          data['density_g_per_ml']!,
          _densityGPerMlMeta,
        ),
      );
    }
    if (data.containsKey('source_ref')) {
      context.handle(
        _sourceRefMeta,
        sourceRef.isAcceptableOrUnknown(data['source_ref']!, _sourceRefMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceRefMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PersonalProduct map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PersonalProduct(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      nameEs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_es'],
      )!,
      energyKcal100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}energy_kcal100'],
      )!,
      proteinG100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_g100'],
      )!,
      carbsG100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs_g100'],
      )!,
      fatG100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_g100'],
      )!,
      fiberG100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fiber_g100'],
      ),
      sugarG100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sugar_g100'],
      ),
      sodiumMg100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sodium_mg100'],
      ),
      servingGrams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}serving_grams'],
      )!,
      densityGPerMl: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}density_g_per_ml'],
      ),
      sourceRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_ref'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PersonalProductsTable createAlias(String alias) {
    return $PersonalProductsTable(attachedDatabase, alias);
  }
}

class PersonalProduct extends DataClass implements Insertable<PersonalProduct> {
  final int id;
  final String nameEs;
  final double energyKcal100;
  final double proteinG100;
  final double carbsG100;
  final double fatG100;
  final double? fiberG100;
  final double? sugarG100;
  final double? sodiumMg100;

  /// Porción declarada en la etiqueta (R3: siempre > 0), usada como la
  /// única `PortionOption` ("porcion") del producto.
  final double servingGrams;
  final double? densityGPerMl;
  final String sourceRef;
  final DateTime createdAt;
  const PersonalProduct({
    required this.id,
    required this.nameEs,
    required this.energyKcal100,
    required this.proteinG100,
    required this.carbsG100,
    required this.fatG100,
    this.fiberG100,
    this.sugarG100,
    this.sodiumMg100,
    required this.servingGrams,
    this.densityGPerMl,
    required this.sourceRef,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name_es'] = Variable<String>(nameEs);
    map['energy_kcal100'] = Variable<double>(energyKcal100);
    map['protein_g100'] = Variable<double>(proteinG100);
    map['carbs_g100'] = Variable<double>(carbsG100);
    map['fat_g100'] = Variable<double>(fatG100);
    if (!nullToAbsent || fiberG100 != null) {
      map['fiber_g100'] = Variable<double>(fiberG100);
    }
    if (!nullToAbsent || sugarG100 != null) {
      map['sugar_g100'] = Variable<double>(sugarG100);
    }
    if (!nullToAbsent || sodiumMg100 != null) {
      map['sodium_mg100'] = Variable<double>(sodiumMg100);
    }
    map['serving_grams'] = Variable<double>(servingGrams);
    if (!nullToAbsent || densityGPerMl != null) {
      map['density_g_per_ml'] = Variable<double>(densityGPerMl);
    }
    map['source_ref'] = Variable<String>(sourceRef);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PersonalProductsCompanion toCompanion(bool nullToAbsent) {
    return PersonalProductsCompanion(
      id: Value(id),
      nameEs: Value(nameEs),
      energyKcal100: Value(energyKcal100),
      proteinG100: Value(proteinG100),
      carbsG100: Value(carbsG100),
      fatG100: Value(fatG100),
      fiberG100: fiberG100 == null && nullToAbsent
          ? const Value.absent()
          : Value(fiberG100),
      sugarG100: sugarG100 == null && nullToAbsent
          ? const Value.absent()
          : Value(sugarG100),
      sodiumMg100: sodiumMg100 == null && nullToAbsent
          ? const Value.absent()
          : Value(sodiumMg100),
      servingGrams: Value(servingGrams),
      densityGPerMl: densityGPerMl == null && nullToAbsent
          ? const Value.absent()
          : Value(densityGPerMl),
      sourceRef: Value(sourceRef),
      createdAt: Value(createdAt),
    );
  }

  factory PersonalProduct.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PersonalProduct(
      id: serializer.fromJson<int>(json['id']),
      nameEs: serializer.fromJson<String>(json['nameEs']),
      energyKcal100: serializer.fromJson<double>(json['energyKcal100']),
      proteinG100: serializer.fromJson<double>(json['proteinG100']),
      carbsG100: serializer.fromJson<double>(json['carbsG100']),
      fatG100: serializer.fromJson<double>(json['fatG100']),
      fiberG100: serializer.fromJson<double?>(json['fiberG100']),
      sugarG100: serializer.fromJson<double?>(json['sugarG100']),
      sodiumMg100: serializer.fromJson<double?>(json['sodiumMg100']),
      servingGrams: serializer.fromJson<double>(json['servingGrams']),
      densityGPerMl: serializer.fromJson<double?>(json['densityGPerMl']),
      sourceRef: serializer.fromJson<String>(json['sourceRef']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nameEs': serializer.toJson<String>(nameEs),
      'energyKcal100': serializer.toJson<double>(energyKcal100),
      'proteinG100': serializer.toJson<double>(proteinG100),
      'carbsG100': serializer.toJson<double>(carbsG100),
      'fatG100': serializer.toJson<double>(fatG100),
      'fiberG100': serializer.toJson<double?>(fiberG100),
      'sugarG100': serializer.toJson<double?>(sugarG100),
      'sodiumMg100': serializer.toJson<double?>(sodiumMg100),
      'servingGrams': serializer.toJson<double>(servingGrams),
      'densityGPerMl': serializer.toJson<double?>(densityGPerMl),
      'sourceRef': serializer.toJson<String>(sourceRef),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PersonalProduct copyWith({
    int? id,
    String? nameEs,
    double? energyKcal100,
    double? proteinG100,
    double? carbsG100,
    double? fatG100,
    Value<double?> fiberG100 = const Value.absent(),
    Value<double?> sugarG100 = const Value.absent(),
    Value<double?> sodiumMg100 = const Value.absent(),
    double? servingGrams,
    Value<double?> densityGPerMl = const Value.absent(),
    String? sourceRef,
    DateTime? createdAt,
  }) => PersonalProduct(
    id: id ?? this.id,
    nameEs: nameEs ?? this.nameEs,
    energyKcal100: energyKcal100 ?? this.energyKcal100,
    proteinG100: proteinG100 ?? this.proteinG100,
    carbsG100: carbsG100 ?? this.carbsG100,
    fatG100: fatG100 ?? this.fatG100,
    fiberG100: fiberG100.present ? fiberG100.value : this.fiberG100,
    sugarG100: sugarG100.present ? sugarG100.value : this.sugarG100,
    sodiumMg100: sodiumMg100.present ? sodiumMg100.value : this.sodiumMg100,
    servingGrams: servingGrams ?? this.servingGrams,
    densityGPerMl: densityGPerMl.present
        ? densityGPerMl.value
        : this.densityGPerMl,
    sourceRef: sourceRef ?? this.sourceRef,
    createdAt: createdAt ?? this.createdAt,
  );
  PersonalProduct copyWithCompanion(PersonalProductsCompanion data) {
    return PersonalProduct(
      id: data.id.present ? data.id.value : this.id,
      nameEs: data.nameEs.present ? data.nameEs.value : this.nameEs,
      energyKcal100: data.energyKcal100.present
          ? data.energyKcal100.value
          : this.energyKcal100,
      proteinG100: data.proteinG100.present
          ? data.proteinG100.value
          : this.proteinG100,
      carbsG100: data.carbsG100.present ? data.carbsG100.value : this.carbsG100,
      fatG100: data.fatG100.present ? data.fatG100.value : this.fatG100,
      fiberG100: data.fiberG100.present ? data.fiberG100.value : this.fiberG100,
      sugarG100: data.sugarG100.present ? data.sugarG100.value : this.sugarG100,
      sodiumMg100: data.sodiumMg100.present
          ? data.sodiumMg100.value
          : this.sodiumMg100,
      servingGrams: data.servingGrams.present
          ? data.servingGrams.value
          : this.servingGrams,
      densityGPerMl: data.densityGPerMl.present
          ? data.densityGPerMl.value
          : this.densityGPerMl,
      sourceRef: data.sourceRef.present ? data.sourceRef.value : this.sourceRef,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PersonalProduct(')
          ..write('id: $id, ')
          ..write('nameEs: $nameEs, ')
          ..write('energyKcal100: $energyKcal100, ')
          ..write('proteinG100: $proteinG100, ')
          ..write('carbsG100: $carbsG100, ')
          ..write('fatG100: $fatG100, ')
          ..write('fiberG100: $fiberG100, ')
          ..write('sugarG100: $sugarG100, ')
          ..write('sodiumMg100: $sodiumMg100, ')
          ..write('servingGrams: $servingGrams, ')
          ..write('densityGPerMl: $densityGPerMl, ')
          ..write('sourceRef: $sourceRef, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    nameEs,
    energyKcal100,
    proteinG100,
    carbsG100,
    fatG100,
    fiberG100,
    sugarG100,
    sodiumMg100,
    servingGrams,
    densityGPerMl,
    sourceRef,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PersonalProduct &&
          other.id == this.id &&
          other.nameEs == this.nameEs &&
          other.energyKcal100 == this.energyKcal100 &&
          other.proteinG100 == this.proteinG100 &&
          other.carbsG100 == this.carbsG100 &&
          other.fatG100 == this.fatG100 &&
          other.fiberG100 == this.fiberG100 &&
          other.sugarG100 == this.sugarG100 &&
          other.sodiumMg100 == this.sodiumMg100 &&
          other.servingGrams == this.servingGrams &&
          other.densityGPerMl == this.densityGPerMl &&
          other.sourceRef == this.sourceRef &&
          other.createdAt == this.createdAt);
}

class PersonalProductsCompanion extends UpdateCompanion<PersonalProduct> {
  final Value<int> id;
  final Value<String> nameEs;
  final Value<double> energyKcal100;
  final Value<double> proteinG100;
  final Value<double> carbsG100;
  final Value<double> fatG100;
  final Value<double?> fiberG100;
  final Value<double?> sugarG100;
  final Value<double?> sodiumMg100;
  final Value<double> servingGrams;
  final Value<double?> densityGPerMl;
  final Value<String> sourceRef;
  final Value<DateTime> createdAt;
  const PersonalProductsCompanion({
    this.id = const Value.absent(),
    this.nameEs = const Value.absent(),
    this.energyKcal100 = const Value.absent(),
    this.proteinG100 = const Value.absent(),
    this.carbsG100 = const Value.absent(),
    this.fatG100 = const Value.absent(),
    this.fiberG100 = const Value.absent(),
    this.sugarG100 = const Value.absent(),
    this.sodiumMg100 = const Value.absent(),
    this.servingGrams = const Value.absent(),
    this.densityGPerMl = const Value.absent(),
    this.sourceRef = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PersonalProductsCompanion.insert({
    this.id = const Value.absent(),
    required String nameEs,
    required double energyKcal100,
    required double proteinG100,
    required double carbsG100,
    required double fatG100,
    this.fiberG100 = const Value.absent(),
    this.sugarG100 = const Value.absent(),
    this.sodiumMg100 = const Value.absent(),
    required double servingGrams,
    this.densityGPerMl = const Value.absent(),
    required String sourceRef,
    this.createdAt = const Value.absent(),
  }) : nameEs = Value(nameEs),
       energyKcal100 = Value(energyKcal100),
       proteinG100 = Value(proteinG100),
       carbsG100 = Value(carbsG100),
       fatG100 = Value(fatG100),
       servingGrams = Value(servingGrams),
       sourceRef = Value(sourceRef);
  static Insertable<PersonalProduct> custom({
    Expression<int>? id,
    Expression<String>? nameEs,
    Expression<double>? energyKcal100,
    Expression<double>? proteinG100,
    Expression<double>? carbsG100,
    Expression<double>? fatG100,
    Expression<double>? fiberG100,
    Expression<double>? sugarG100,
    Expression<double>? sodiumMg100,
    Expression<double>? servingGrams,
    Expression<double>? densityGPerMl,
    Expression<String>? sourceRef,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nameEs != null) 'name_es': nameEs,
      if (energyKcal100 != null) 'energy_kcal100': energyKcal100,
      if (proteinG100 != null) 'protein_g100': proteinG100,
      if (carbsG100 != null) 'carbs_g100': carbsG100,
      if (fatG100 != null) 'fat_g100': fatG100,
      if (fiberG100 != null) 'fiber_g100': fiberG100,
      if (sugarG100 != null) 'sugar_g100': sugarG100,
      if (sodiumMg100 != null) 'sodium_mg100': sodiumMg100,
      if (servingGrams != null) 'serving_grams': servingGrams,
      if (densityGPerMl != null) 'density_g_per_ml': densityGPerMl,
      if (sourceRef != null) 'source_ref': sourceRef,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PersonalProductsCompanion copyWith({
    Value<int>? id,
    Value<String>? nameEs,
    Value<double>? energyKcal100,
    Value<double>? proteinG100,
    Value<double>? carbsG100,
    Value<double>? fatG100,
    Value<double?>? fiberG100,
    Value<double?>? sugarG100,
    Value<double?>? sodiumMg100,
    Value<double>? servingGrams,
    Value<double?>? densityGPerMl,
    Value<String>? sourceRef,
    Value<DateTime>? createdAt,
  }) {
    return PersonalProductsCompanion(
      id: id ?? this.id,
      nameEs: nameEs ?? this.nameEs,
      energyKcal100: energyKcal100 ?? this.energyKcal100,
      proteinG100: proteinG100 ?? this.proteinG100,
      carbsG100: carbsG100 ?? this.carbsG100,
      fatG100: fatG100 ?? this.fatG100,
      fiberG100: fiberG100 ?? this.fiberG100,
      sugarG100: sugarG100 ?? this.sugarG100,
      sodiumMg100: sodiumMg100 ?? this.sodiumMg100,
      servingGrams: servingGrams ?? this.servingGrams,
      densityGPerMl: densityGPerMl ?? this.densityGPerMl,
      sourceRef: sourceRef ?? this.sourceRef,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nameEs.present) {
      map['name_es'] = Variable<String>(nameEs.value);
    }
    if (energyKcal100.present) {
      map['energy_kcal100'] = Variable<double>(energyKcal100.value);
    }
    if (proteinG100.present) {
      map['protein_g100'] = Variable<double>(proteinG100.value);
    }
    if (carbsG100.present) {
      map['carbs_g100'] = Variable<double>(carbsG100.value);
    }
    if (fatG100.present) {
      map['fat_g100'] = Variable<double>(fatG100.value);
    }
    if (fiberG100.present) {
      map['fiber_g100'] = Variable<double>(fiberG100.value);
    }
    if (sugarG100.present) {
      map['sugar_g100'] = Variable<double>(sugarG100.value);
    }
    if (sodiumMg100.present) {
      map['sodium_mg100'] = Variable<double>(sodiumMg100.value);
    }
    if (servingGrams.present) {
      map['serving_grams'] = Variable<double>(servingGrams.value);
    }
    if (densityGPerMl.present) {
      map['density_g_per_ml'] = Variable<double>(densityGPerMl.value);
    }
    if (sourceRef.present) {
      map['source_ref'] = Variable<String>(sourceRef.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonalProductsCompanion(')
          ..write('id: $id, ')
          ..write('nameEs: $nameEs, ')
          ..write('energyKcal100: $energyKcal100, ')
          ..write('proteinG100: $proteinG100, ')
          ..write('carbsG100: $carbsG100, ')
          ..write('fatG100: $fatG100, ')
          ..write('fiberG100: $fiberG100, ')
          ..write('sugarG100: $sugarG100, ')
          ..write('sodiumMg100: $sodiumMg100, ')
          ..write('servingGrams: $servingGrams, ')
          ..write('densityGPerMl: $densityGPerMl, ')
          ..write('sourceRef: $sourceRef, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MealsTable meals = $MealsTable(this);
  late final $MealItemsTable mealItems = $MealItemsTable(this);
  late final $PersonalProductsTable personalProducts = $PersonalProductsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    meals,
    mealItems,
    personalProducts,
  ];
}

typedef $$MealsTableCreateCompanionBuilder = MealsCompanion Function({
  Value<int> id,
  required DateTime eatenAt,
  Value<String?> mealType,
  required String confidence,
  required String catalogVersion,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$MealsTableUpdateCompanionBuilder = MealsCompanion Function({
  Value<int> id,
  Value<DateTime> eatenAt,
  Value<String?> mealType,
  Value<String> confidence,
  Value<String> catalogVersion,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$MealsTableReferences
    extends BaseReferences<_$AppDatabase, $MealsTable, Meal> {
  $$MealsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MealItemsTable, List<MealItem>>
  _mealItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.mealItems,
    aliasName: 'meals__id__meal_items__meal_id',
  );

  $$MealItemsTableProcessedTableManager get mealItemsRefs {
    final manager = $$MealItemsTableTableManager(
      $_db,
      $_db.mealItems,
    ).filter((f) => f.mealId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_mealItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MealsTableFilterComposer extends Composer<_$AppDatabase, $MealsTable> {
  $$MealsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get eatenAt => $composableBuilder(
    column: $table.eatenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mealType => $composableBuilder(
    column: $table.mealType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get catalogVersion => $composableBuilder(
    column: $table.catalogVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> mealItemsRefs(
    Expression<bool> Function($$MealItemsTableFilterComposer f) f,
  ) {
    final $$MealItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mealItems,
      getReferencedColumn: (t) => t.mealId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealItemsTableFilterComposer(
            $db: $db,
            $table: $db.mealItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MealsTableOrderingComposer
    extends Composer<_$AppDatabase, $MealsTable> {
  $$MealsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get eatenAt => $composableBuilder(
    column: $table.eatenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mealType => $composableBuilder(
    column: $table.mealType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get catalogVersion => $composableBuilder(
    column: $table.catalogVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MealsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealsTable> {
  $$MealsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get eatenAt =>
      $composableBuilder(column: $table.eatenAt, builder: (column) => column);

  GeneratedColumn<String> get mealType =>
      $composableBuilder(column: $table.mealType, builder: (column) => column);

  GeneratedColumn<String> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get catalogVersion => $composableBuilder(
    column: $table.catalogVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> mealItemsRefs<T extends Object>(
    Expression<T> Function($$MealItemsTableAnnotationComposer a) f,
  ) {
    final $$MealItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mealItems,
      getReferencedColumn: (t) => t.mealId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.mealItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MealsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MealsTable,
          Meal,
          $$MealsTableFilterComposer,
          $$MealsTableOrderingComposer,
          $$MealsTableAnnotationComposer,
          $$MealsTableCreateCompanionBuilder,
          $$MealsTableUpdateCompanionBuilder,
          (Meal, $$MealsTableReferences),
          Meal,
          PrefetchHooks Function({bool mealItemsRefs})
        > {
  $$MealsTableTableManager(_$AppDatabase db, $MealsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> eatenAt = const Value.absent(),
                Value<String?> mealType = const Value.absent(),
                Value<String> confidence = const Value.absent(),
                Value<String> catalogVersion = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => MealsCompanion(
                id: id,
                eatenAt: eatenAt,
                mealType: mealType,
                confidence: confidence,
                catalogVersion: catalogVersion,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime eatenAt,
                Value<String?> mealType = const Value.absent(),
                required String confidence,
                required String catalogVersion,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => MealsCompanion.insert(
                id: id,
                eatenAt: eatenAt,
                mealType: mealType,
                confidence: confidence,
                catalogVersion: catalogVersion,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MealsTable, Meal>(table),
                  $$MealsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({mealItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (mealItemsRefs) db.mealItems],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (mealItemsRefs)
                    await $_getPrefetchedData<Meal, $MealsTable, MealItem>(
                      currentTable: table,
                      referencedTable: $$MealsTableReferences
                          ._mealItemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$MealsTableReferences(db, table, p0).mealItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.mealId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$MealsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MealsTable,
      Meal,
      $$MealsTableFilterComposer,
      $$MealsTableOrderingComposer,
      $$MealsTableAnnotationComposer,
      $$MealsTableCreateCompanionBuilder,
      $$MealsTableUpdateCompanionBuilder,
      (Meal, $$MealsTableReferences),
      Meal,
      PrefetchHooks Function({bool mealItemsRefs})
    >;
typedef $$MealItemsTableCreateCompanionBuilder = MealItemsCompanion Function({
  Value<int> id,
  required int mealId,
  required int position,
  required String mention,
  Value<String?> foodId,
  Value<String?> personalProductId,
  required String nameSnapshot,
  required double grams,
  Value<double?> quantityInput,
  Value<String?> unitInput,
  Value<String?> sizeInput,
  required String quantityBasis,
  required double energyKcal,
  required double proteinG,
  required double carbsG,
  required double fatG,
  required String confidence,
  required String sourceRef,
});
typedef $$MealItemsTableUpdateCompanionBuilder = MealItemsCompanion Function({
  Value<int> id,
  Value<int> mealId,
  Value<int> position,
  Value<String> mention,
  Value<String?> foodId,
  Value<String?> personalProductId,
  Value<String> nameSnapshot,
  Value<double> grams,
  Value<double?> quantityInput,
  Value<String?> unitInput,
  Value<String?> sizeInput,
  Value<String> quantityBasis,
  Value<double> energyKcal,
  Value<double> proteinG,
  Value<double> carbsG,
  Value<double> fatG,
  Value<String> confidence,
  Value<String> sourceRef,
});

final class $$MealItemsTableReferences
    extends BaseReferences<_$AppDatabase, $MealItemsTable, MealItem> {
  $$MealItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MealsTable _mealIdTable(_$AppDatabase db) =>
      db.meals.createAlias('meal_items__meal_id__meals__id');

  $$MealsTableProcessedTableManager get mealId {
    final $_column = $_itemColumn<int>('meal_id')!;

    final manager = $$MealsTableTableManager(
      $_db,
      $_db.meals,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_mealIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MealItemsTableFilterComposer
    extends Composer<_$AppDatabase, $MealItemsTable> {
  $$MealItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mention => $composableBuilder(
    column: $table.mention,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personalProductId => $composableBuilder(
    column: $table.personalProductId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameSnapshot => $composableBuilder(
    column: $table.nameSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantityInput => $composableBuilder(
    column: $table.quantityInput,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unitInput => $composableBuilder(
    column: $table.unitInput,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sizeInput => $composableBuilder(
    column: $table.sizeInput,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quantityBasis => $composableBuilder(
    column: $table.quantityBasis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get energyKcal => $composableBuilder(
    column: $table.energyKcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceRef => $composableBuilder(
    column: $table.sourceRef,
    builder: (column) => ColumnFilters(column),
  );

  $$MealsTableFilterComposer get mealId {
    final $$MealsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mealId,
      referencedTable: $db.meals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealsTableFilterComposer(
            $db: $db,
            $table: $db.meals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MealItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $MealItemsTable> {
  $$MealItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mention => $composableBuilder(
    column: $table.mention,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personalProductId => $composableBuilder(
    column: $table.personalProductId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameSnapshot => $composableBuilder(
    column: $table.nameSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantityInput => $composableBuilder(
    column: $table.quantityInput,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unitInput => $composableBuilder(
    column: $table.unitInput,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sizeInput => $composableBuilder(
    column: $table.sizeInput,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quantityBasis => $composableBuilder(
    column: $table.quantityBasis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get energyKcal => $composableBuilder(
    column: $table.energyKcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceRef => $composableBuilder(
    column: $table.sourceRef,
    builder: (column) => ColumnOrderings(column),
  );

  $$MealsTableOrderingComposer get mealId {
    final $$MealsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mealId,
      referencedTable: $db.meals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealsTableOrderingComposer(
            $db: $db,
            $table: $db.meals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MealItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealItemsTable> {
  $$MealItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get mention =>
      $composableBuilder(column: $table.mention, builder: (column) => column);

  GeneratedColumn<String> get foodId =>
      $composableBuilder(column: $table.foodId, builder: (column) => column);

  GeneratedColumn<String> get personalProductId => $composableBuilder(
    column: $table.personalProductId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nameSnapshot => $composableBuilder(
    column: $table.nameSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<double> get grams =>
      $composableBuilder(column: $table.grams, builder: (column) => column);

  GeneratedColumn<double> get quantityInput => $composableBuilder(
    column: $table.quantityInput,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unitInput =>
      $composableBuilder(column: $table.unitInput, builder: (column) => column);

  GeneratedColumn<String> get sizeInput =>
      $composableBuilder(column: $table.sizeInput, builder: (column) => column);

  GeneratedColumn<String> get quantityBasis => $composableBuilder(
    column: $table.quantityBasis,
    builder: (column) => column,
  );

  GeneratedColumn<double> get energyKcal => $composableBuilder(
    column: $table.energyKcal,
    builder: (column) => column,
  );

  GeneratedColumn<double> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<double> get carbsG =>
      $composableBuilder(column: $table.carbsG, builder: (column) => column);

  GeneratedColumn<double> get fatG =>
      $composableBuilder(column: $table.fatG, builder: (column) => column);

  GeneratedColumn<String> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceRef =>
      $composableBuilder(column: $table.sourceRef, builder: (column) => column);

  $$MealsTableAnnotationComposer get mealId {
    final $$MealsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mealId,
      referencedTable: $db.meals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealsTableAnnotationComposer(
            $db: $db,
            $table: $db.meals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MealItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MealItemsTable,
          MealItem,
          $$MealItemsTableFilterComposer,
          $$MealItemsTableOrderingComposer,
          $$MealItemsTableAnnotationComposer,
          $$MealItemsTableCreateCompanionBuilder,
          $$MealItemsTableUpdateCompanionBuilder,
          (MealItem, $$MealItemsTableReferences),
          MealItem,
          PrefetchHooks Function({bool mealId})
        > {
  $$MealItemsTableTableManager(_$AppDatabase db, $MealItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> mealId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> mention = const Value.absent(),
                Value<String?> foodId = const Value.absent(),
                Value<String?> personalProductId = const Value.absent(),
                Value<String> nameSnapshot = const Value.absent(),
                Value<double> grams = const Value.absent(),
                Value<double?> quantityInput = const Value.absent(),
                Value<String?> unitInput = const Value.absent(),
                Value<String?> sizeInput = const Value.absent(),
                Value<String> quantityBasis = const Value.absent(),
                Value<double> energyKcal = const Value.absent(),
                Value<double> proteinG = const Value.absent(),
                Value<double> carbsG = const Value.absent(),
                Value<double> fatG = const Value.absent(),
                Value<String> confidence = const Value.absent(),
                Value<String> sourceRef = const Value.absent(),
              }) => MealItemsCompanion(
                id: id,
                mealId: mealId,
                position: position,
                mention: mention,
                foodId: foodId,
                personalProductId: personalProductId,
                nameSnapshot: nameSnapshot,
                grams: grams,
                quantityInput: quantityInput,
                unitInput: unitInput,
                sizeInput: sizeInput,
                quantityBasis: quantityBasis,
                energyKcal: energyKcal,
                proteinG: proteinG,
                carbsG: carbsG,
                fatG: fatG,
                confidence: confidence,
                sourceRef: sourceRef,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int mealId,
                required int position,
                required String mention,
                Value<String?> foodId = const Value.absent(),
                Value<String?> personalProductId = const Value.absent(),
                required String nameSnapshot,
                required double grams,
                Value<double?> quantityInput = const Value.absent(),
                Value<String?> unitInput = const Value.absent(),
                Value<String?> sizeInput = const Value.absent(),
                required String quantityBasis,
                required double energyKcal,
                required double proteinG,
                required double carbsG,
                required double fatG,
                required String confidence,
                required String sourceRef,
              }) => MealItemsCompanion.insert(
                id: id,
                mealId: mealId,
                position: position,
                mention: mention,
                foodId: foodId,
                personalProductId: personalProductId,
                nameSnapshot: nameSnapshot,
                grams: grams,
                quantityInput: quantityInput,
                unitInput: unitInput,
                sizeInput: sizeInput,
                quantityBasis: quantityBasis,
                energyKcal: energyKcal,
                proteinG: proteinG,
                carbsG: carbsG,
                fatG: fatG,
                confidence: confidence,
                sourceRef: sourceRef,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MealItemsTable, MealItem>(table),
                  $$MealItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({mealId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (mealId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.mealId,
                        referencedTable: $$MealItemsTableReferences
                            ._mealIdTable(db),
                        referencedColumn: $$MealItemsTableReferences
                            ._mealIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MealItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MealItemsTable,
      MealItem,
      $$MealItemsTableFilterComposer,
      $$MealItemsTableOrderingComposer,
      $$MealItemsTableAnnotationComposer,
      $$MealItemsTableCreateCompanionBuilder,
      $$MealItemsTableUpdateCompanionBuilder,
      (MealItem, $$MealItemsTableReferences),
      MealItem,
      PrefetchHooks Function({bool mealId})
    >;
typedef $$PersonalProductsTableCreateCompanionBuilder =
    PersonalProductsCompanion Function({
      Value<int> id,
      required String nameEs,
      required double energyKcal100,
      required double proteinG100,
      required double carbsG100,
      required double fatG100,
      Value<double?> fiberG100,
      Value<double?> sugarG100,
      Value<double?> sodiumMg100,
      required double servingGrams,
      Value<double?> densityGPerMl,
      required String sourceRef,
      Value<DateTime> createdAt,
    });
typedef $$PersonalProductsTableUpdateCompanionBuilder =
    PersonalProductsCompanion Function({
      Value<int> id,
      Value<String> nameEs,
      Value<double> energyKcal100,
      Value<double> proteinG100,
      Value<double> carbsG100,
      Value<double> fatG100,
      Value<double?> fiberG100,
      Value<double?> sugarG100,
      Value<double?> sodiumMg100,
      Value<double> servingGrams,
      Value<double?> densityGPerMl,
      Value<String> sourceRef,
      Value<DateTime> createdAt,
    });

class $$PersonalProductsTableFilterComposer
    extends Composer<_$AppDatabase, $PersonalProductsTable> {
  $$PersonalProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEs => $composableBuilder(
    column: $table.nameEs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get energyKcal100 => $composableBuilder(
    column: $table.energyKcal100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinG100 => $composableBuilder(
    column: $table.proteinG100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbsG100 => $composableBuilder(
    column: $table.carbsG100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatG100 => $composableBuilder(
    column: $table.fatG100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fiberG100 => $composableBuilder(
    column: $table.fiberG100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sugarG100 => $composableBuilder(
    column: $table.sugarG100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sodiumMg100 => $composableBuilder(
    column: $table.sodiumMg100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get servingGrams => $composableBuilder(
    column: $table.servingGrams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get densityGPerMl => $composableBuilder(
    column: $table.densityGPerMl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceRef => $composableBuilder(
    column: $table.sourceRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PersonalProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $PersonalProductsTable> {
  $$PersonalProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEs => $composableBuilder(
    column: $table.nameEs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get energyKcal100 => $composableBuilder(
    column: $table.energyKcal100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinG100 => $composableBuilder(
    column: $table.proteinG100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbsG100 => $composableBuilder(
    column: $table.carbsG100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatG100 => $composableBuilder(
    column: $table.fatG100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fiberG100 => $composableBuilder(
    column: $table.fiberG100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sugarG100 => $composableBuilder(
    column: $table.sugarG100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sodiumMg100 => $composableBuilder(
    column: $table.sodiumMg100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get servingGrams => $composableBuilder(
    column: $table.servingGrams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get densityGPerMl => $composableBuilder(
    column: $table.densityGPerMl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceRef => $composableBuilder(
    column: $table.sourceRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PersonalProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PersonalProductsTable> {
  $$PersonalProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nameEs =>
      $composableBuilder(column: $table.nameEs, builder: (column) => column);

  GeneratedColumn<double> get energyKcal100 => $composableBuilder(
    column: $table.energyKcal100,
    builder: (column) => column,
  );

  GeneratedColumn<double> get proteinG100 => $composableBuilder(
    column: $table.proteinG100,
    builder: (column) => column,
  );

  GeneratedColumn<double> get carbsG100 =>
      $composableBuilder(column: $table.carbsG100, builder: (column) => column);

  GeneratedColumn<double> get fatG100 =>
      $composableBuilder(column: $table.fatG100, builder: (column) => column);

  GeneratedColumn<double> get fiberG100 =>
      $composableBuilder(column: $table.fiberG100, builder: (column) => column);

  GeneratedColumn<double> get sugarG100 =>
      $composableBuilder(column: $table.sugarG100, builder: (column) => column);

  GeneratedColumn<double> get sodiumMg100 => $composableBuilder(
    column: $table.sodiumMg100,
    builder: (column) => column,
  );

  GeneratedColumn<double> get servingGrams => $composableBuilder(
    column: $table.servingGrams,
    builder: (column) => column,
  );

  GeneratedColumn<double> get densityGPerMl => $composableBuilder(
    column: $table.densityGPerMl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceRef =>
      $composableBuilder(column: $table.sourceRef, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PersonalProductsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PersonalProductsTable,
          PersonalProduct,
          $$PersonalProductsTableFilterComposer,
          $$PersonalProductsTableOrderingComposer,
          $$PersonalProductsTableAnnotationComposer,
          $$PersonalProductsTableCreateCompanionBuilder,
          $$PersonalProductsTableUpdateCompanionBuilder,
          (
            PersonalProduct,
            BaseReferences<
              _$AppDatabase,
              $PersonalProductsTable,
              PersonalProduct
            >,
          ),
          PersonalProduct,
          PrefetchHooks Function()
        > {
  $$PersonalProductsTableTableManager(
    _$AppDatabase db,
    $PersonalProductsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PersonalProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PersonalProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PersonalProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> nameEs = const Value.absent(),
                Value<double> energyKcal100 = const Value.absent(),
                Value<double> proteinG100 = const Value.absent(),
                Value<double> carbsG100 = const Value.absent(),
                Value<double> fatG100 = const Value.absent(),
                Value<double?> fiberG100 = const Value.absent(),
                Value<double?> sugarG100 = const Value.absent(),
                Value<double?> sodiumMg100 = const Value.absent(),
                Value<double> servingGrams = const Value.absent(),
                Value<double?> densityGPerMl = const Value.absent(),
                Value<String> sourceRef = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PersonalProductsCompanion(
                id: id,
                nameEs: nameEs,
                energyKcal100: energyKcal100,
                proteinG100: proteinG100,
                carbsG100: carbsG100,
                fatG100: fatG100,
                fiberG100: fiberG100,
                sugarG100: sugarG100,
                sodiumMg100: sodiumMg100,
                servingGrams: servingGrams,
                densityGPerMl: densityGPerMl,
                sourceRef: sourceRef,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String nameEs,
                required double energyKcal100,
                required double proteinG100,
                required double carbsG100,
                required double fatG100,
                Value<double?> fiberG100 = const Value.absent(),
                Value<double?> sugarG100 = const Value.absent(),
                Value<double?> sodiumMg100 = const Value.absent(),
                required double servingGrams,
                Value<double?> densityGPerMl = const Value.absent(),
                required String sourceRef,
                Value<DateTime> createdAt = const Value.absent(),
              }) => PersonalProductsCompanion.insert(
                id: id,
                nameEs: nameEs,
                energyKcal100: energyKcal100,
                proteinG100: proteinG100,
                carbsG100: carbsG100,
                fatG100: fatG100,
                fiberG100: fiberG100,
                sugarG100: sugarG100,
                sodiumMg100: sodiumMg100,
                servingGrams: servingGrams,
                densityGPerMl: densityGPerMl,
                sourceRef: sourceRef,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PersonalProductsTable, PersonalProduct>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PersonalProductsTable,
                    PersonalProduct
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PersonalProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PersonalProductsTable,
      PersonalProduct,
      $$PersonalProductsTableFilterComposer,
      $$PersonalProductsTableOrderingComposer,
      $$PersonalProductsTableAnnotationComposer,
      $$PersonalProductsTableCreateCompanionBuilder,
      $$PersonalProductsTableUpdateCompanionBuilder,
      (
        PersonalProduct,
        BaseReferences<_$AppDatabase, $PersonalProductsTable, PersonalProduct>,
      ),
      PersonalProduct,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MealsTableTableManager get meals =>
      $$MealsTableTableManager(_db, _db.meals);
  $$MealItemsTableTableManager get mealItems =>
      $$MealItemsTableTableManager(_db, _db.mealItems);
  $$PersonalProductsTableTableManager get personalProducts =>
      $$PersonalProductsTableTableManager(_db, _db.personalProducts);
}
