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
  static const VerificationMeta _servingUnitMeta = const VerificationMeta(
    'servingUnit',
  );
  @override
  late final GeneratedColumn<String> servingUnit = GeneratedColumn<String>(
    'serving_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('g'),
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
    servingUnit,
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
    if (data.containsKey('serving_unit')) {
      context.handle(
        _servingUnitMeta,
        servingUnit.isAcceptableOrUnknown(
          data['serving_unit']!,
          _servingUnitMeta,
        ),
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
      servingUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}serving_unit'],
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

  /// SPEC-034 R5: "g" o "ml", la unidad de la porción de la etiqueta.
  final String servingUnit;
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
    required this.servingUnit,
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
    map['serving_unit'] = Variable<String>(servingUnit);
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
      servingUnit: Value(servingUnit),
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
      servingUnit: serializer.fromJson<String>(json['servingUnit']),
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
      'servingUnit': serializer.toJson<String>(servingUnit),
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
    String? servingUnit,
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
    servingUnit: servingUnit ?? this.servingUnit,
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
      servingUnit: data.servingUnit.present
          ? data.servingUnit.value
          : this.servingUnit,
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
          ..write('createdAt: $createdAt, ')
          ..write('servingUnit: $servingUnit')
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
    servingUnit,
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
          other.createdAt == this.createdAt &&
          other.servingUnit == this.servingUnit);
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
  final Value<String> servingUnit;
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
    this.servingUnit = const Value.absent(),
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
    this.servingUnit = const Value.absent(),
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
    Expression<String>? servingUnit,
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
      if (servingUnit != null) 'serving_unit': servingUnit,
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
    Value<String>? servingUnit,
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
      servingUnit: servingUnit ?? this.servingUnit,
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
    if (servingUnit.present) {
      map['serving_unit'] = Variable<String>(servingUnit.value);
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
          ..write('createdAt: $createdAt, ')
          ..write('servingUnit: $servingUnit')
          ..write(')'))
        .toString();
  }
}

class $PersonalProductAliasesTable extends PersonalProductAliases
    with TableInfo<$PersonalProductAliasesTable, PersonalProductAliase> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonalProductAliasesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES personal_products (id)',
    ),
  );
  static const VerificationMeta _termMeta = const VerificationMeta('term');
  @override
  late final GeneratedColumn<String> term = GeneratedColumn<String>(
    'term',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, productId, term];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'personal_product_aliases';
  @override
  VerificationContext validateIntegrity(
    Insertable<PersonalProductAliase> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('term')) {
      context.handle(
        _termMeta,
        term.isAcceptableOrUnknown(data['term']!, _termMeta),
      );
    } else if (isInserting) {
      context.missing(_termMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PersonalProductAliase map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PersonalProductAliase(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}product_id'],
      )!,
      term: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}term'],
      )!,
    );
  }

  @override
  $PersonalProductAliasesTable createAlias(String alias) {
    return $PersonalProductAliasesTable(attachedDatabase, alias);
  }
}

class PersonalProductAliase extends DataClass
    implements Insertable<PersonalProductAliase> {
  final int id;
  final int productId;
  final String term;
  const PersonalProductAliase({
    required this.id,
    required this.productId,
    required this.term,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['product_id'] = Variable<int>(productId);
    map['term'] = Variable<String>(term);
    return map;
  }

  PersonalProductAliasesCompanion toCompanion(bool nullToAbsent) {
    return PersonalProductAliasesCompanion(
      id: Value(id),
      productId: Value(productId),
      term: Value(term),
    );
  }

  factory PersonalProductAliase.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PersonalProductAliase(
      id: serializer.fromJson<int>(json['id']),
      productId: serializer.fromJson<int>(json['productId']),
      term: serializer.fromJson<String>(json['term']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'productId': serializer.toJson<int>(productId),
      'term': serializer.toJson<String>(term),
    };
  }

  PersonalProductAliase copyWith({int? id, int? productId, String? term}) =>
      PersonalProductAliase(
        id: id ?? this.id,
        productId: productId ?? this.productId,
        term: term ?? this.term,
      );
  PersonalProductAliase copyWithCompanion(
    PersonalProductAliasesCompanion data,
  ) {
    return PersonalProductAliase(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      term: data.term.present ? data.term.value : this.term,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PersonalProductAliase(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('term: $term')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, productId, term);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PersonalProductAliase &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.term == this.term);
}

class PersonalProductAliasesCompanion
    extends UpdateCompanion<PersonalProductAliase> {
  final Value<int> id;
  final Value<int> productId;
  final Value<String> term;
  const PersonalProductAliasesCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.term = const Value.absent(),
  });
  PersonalProductAliasesCompanion.insert({
    this.id = const Value.absent(),
    required int productId,
    required String term,
  }) : productId = Value(productId),
       term = Value(term);
  static Insertable<PersonalProductAliase> custom({
    Expression<int>? id,
    Expression<int>? productId,
    Expression<String>? term,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (term != null) 'term': term,
    });
  }

  PersonalProductAliasesCompanion copyWith({
    Value<int>? id,
    Value<int>? productId,
    Value<String>? term,
  }) {
    return PersonalProductAliasesCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      term: term ?? this.term,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (term.present) {
      map['term'] = Variable<String>(term.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonalProductAliasesCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('term: $term')
          ..write(')'))
        .toString();
  }
}

class $ConsentRecordTable extends ConsentRecord
    with TableInfo<$ConsentRecordTable, ConsentRecordData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConsentRecordTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ageConfirmedMeta = const VerificationMeta(
    'ageConfirmed',
  );
  @override
  late final GeneratedColumn<bool> ageConfirmed = GeneratedColumn<bool>(
    'age_confirmed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("age_confirmed" IN (0, 1))',
    ),
  );
  static const VerificationMeta _consentGivenMeta = const VerificationMeta(
    'consentGiven',
  );
  @override
  late final GeneratedColumn<bool> consentGiven = GeneratedColumn<bool>(
    'consent_given',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("consent_given" IN (0, 1))',
    ),
  );
  static const VerificationMeta _policyVersionMeta = const VerificationMeta(
    'policyVersion',
  );
  @override
  late final GeneratedColumn<String> policyVersion = GeneratedColumn<String>(
    'policy_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _consentedAtMeta = const VerificationMeta(
    'consentedAt',
  );
  @override
  late final GeneratedColumn<DateTime> consentedAt = GeneratedColumn<DateTime>(
    'consented_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ageConfirmed,
    consentGiven,
    policyVersion,
    consentedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'consent_record';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConsentRecordData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('age_confirmed')) {
      context.handle(
        _ageConfirmedMeta,
        ageConfirmed.isAcceptableOrUnknown(
          data['age_confirmed']!,
          _ageConfirmedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ageConfirmedMeta);
    }
    if (data.containsKey('consent_given')) {
      context.handle(
        _consentGivenMeta,
        consentGiven.isAcceptableOrUnknown(
          data['consent_given']!,
          _consentGivenMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_consentGivenMeta);
    }
    if (data.containsKey('policy_version')) {
      context.handle(
        _policyVersionMeta,
        policyVersion.isAcceptableOrUnknown(
          data['policy_version']!,
          _policyVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_policyVersionMeta);
    }
    if (data.containsKey('consented_at')) {
      context.handle(
        _consentedAtMeta,
        consentedAt.isAcceptableOrUnknown(
          data['consented_at']!,
          _consentedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_consentedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConsentRecordData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConsentRecordData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      ageConfirmed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}age_confirmed'],
      )!,
      consentGiven: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}consent_given'],
      )!,
      policyVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}policy_version'],
      )!,
      consentedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}consented_at'],
      )!,
    );
  }

  @override
  $ConsentRecordTable createAlias(String alias) {
    return $ConsentRecordTable(attachedDatabase, alias);
  }
}

class ConsentRecordData extends DataClass
    implements Insertable<ConsentRecordData> {
  final int id;
  final bool ageConfirmed;
  final bool consentGiven;
  final String policyVersion;
  final DateTime consentedAt;
  const ConsentRecordData({
    required this.id,
    required this.ageConfirmed,
    required this.consentGiven,
    required this.policyVersion,
    required this.consentedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['age_confirmed'] = Variable<bool>(ageConfirmed);
    map['consent_given'] = Variable<bool>(consentGiven);
    map['policy_version'] = Variable<String>(policyVersion);
    map['consented_at'] = Variable<DateTime>(consentedAt);
    return map;
  }

  ConsentRecordCompanion toCompanion(bool nullToAbsent) {
    return ConsentRecordCompanion(
      id: Value(id),
      ageConfirmed: Value(ageConfirmed),
      consentGiven: Value(consentGiven),
      policyVersion: Value(policyVersion),
      consentedAt: Value(consentedAt),
    );
  }

  factory ConsentRecordData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConsentRecordData(
      id: serializer.fromJson<int>(json['id']),
      ageConfirmed: serializer.fromJson<bool>(json['ageConfirmed']),
      consentGiven: serializer.fromJson<bool>(json['consentGiven']),
      policyVersion: serializer.fromJson<String>(json['policyVersion']),
      consentedAt: serializer.fromJson<DateTime>(json['consentedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ageConfirmed': serializer.toJson<bool>(ageConfirmed),
      'consentGiven': serializer.toJson<bool>(consentGiven),
      'policyVersion': serializer.toJson<String>(policyVersion),
      'consentedAt': serializer.toJson<DateTime>(consentedAt),
    };
  }

  ConsentRecordData copyWith({
    int? id,
    bool? ageConfirmed,
    bool? consentGiven,
    String? policyVersion,
    DateTime? consentedAt,
  }) => ConsentRecordData(
    id: id ?? this.id,
    ageConfirmed: ageConfirmed ?? this.ageConfirmed,
    consentGiven: consentGiven ?? this.consentGiven,
    policyVersion: policyVersion ?? this.policyVersion,
    consentedAt: consentedAt ?? this.consentedAt,
  );
  ConsentRecordData copyWithCompanion(ConsentRecordCompanion data) {
    return ConsentRecordData(
      id: data.id.present ? data.id.value : this.id,
      ageConfirmed: data.ageConfirmed.present
          ? data.ageConfirmed.value
          : this.ageConfirmed,
      consentGiven: data.consentGiven.present
          ? data.consentGiven.value
          : this.consentGiven,
      policyVersion: data.policyVersion.present
          ? data.policyVersion.value
          : this.policyVersion,
      consentedAt: data.consentedAt.present
          ? data.consentedAt.value
          : this.consentedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConsentRecordData(')
          ..write('id: $id, ')
          ..write('ageConfirmed: $ageConfirmed, ')
          ..write('consentGiven: $consentGiven, ')
          ..write('policyVersion: $policyVersion, ')
          ..write('consentedAt: $consentedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, ageConfirmed, consentGiven, policyVersion, consentedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConsentRecordData &&
          other.id == this.id &&
          other.ageConfirmed == this.ageConfirmed &&
          other.consentGiven == this.consentGiven &&
          other.policyVersion == this.policyVersion &&
          other.consentedAt == this.consentedAt);
}

class ConsentRecordCompanion extends UpdateCompanion<ConsentRecordData> {
  final Value<int> id;
  final Value<bool> ageConfirmed;
  final Value<bool> consentGiven;
  final Value<String> policyVersion;
  final Value<DateTime> consentedAt;
  const ConsentRecordCompanion({
    this.id = const Value.absent(),
    this.ageConfirmed = const Value.absent(),
    this.consentGiven = const Value.absent(),
    this.policyVersion = const Value.absent(),
    this.consentedAt = const Value.absent(),
  });
  ConsentRecordCompanion.insert({
    this.id = const Value.absent(),
    required bool ageConfirmed,
    required bool consentGiven,
    required String policyVersion,
    required DateTime consentedAt,
  }) : ageConfirmed = Value(ageConfirmed),
       consentGiven = Value(consentGiven),
       policyVersion = Value(policyVersion),
       consentedAt = Value(consentedAt);
  static Insertable<ConsentRecordData> custom({
    Expression<int>? id,
    Expression<bool>? ageConfirmed,
    Expression<bool>? consentGiven,
    Expression<String>? policyVersion,
    Expression<DateTime>? consentedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ageConfirmed != null) 'age_confirmed': ageConfirmed,
      if (consentGiven != null) 'consent_given': consentGiven,
      if (policyVersion != null) 'policy_version': policyVersion,
      if (consentedAt != null) 'consented_at': consentedAt,
    });
  }

  ConsentRecordCompanion copyWith({
    Value<int>? id,
    Value<bool>? ageConfirmed,
    Value<bool>? consentGiven,
    Value<String>? policyVersion,
    Value<DateTime>? consentedAt,
  }) {
    return ConsentRecordCompanion(
      id: id ?? this.id,
      ageConfirmed: ageConfirmed ?? this.ageConfirmed,
      consentGiven: consentGiven ?? this.consentGiven,
      policyVersion: policyVersion ?? this.policyVersion,
      consentedAt: consentedAt ?? this.consentedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ageConfirmed.present) {
      map['age_confirmed'] = Variable<bool>(ageConfirmed.value);
    }
    if (consentGiven.present) {
      map['consent_given'] = Variable<bool>(consentGiven.value);
    }
    if (policyVersion.present) {
      map['policy_version'] = Variable<String>(policyVersion.value);
    }
    if (consentedAt.present) {
      map['consented_at'] = Variable<DateTime>(consentedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConsentRecordCompanion(')
          ..write('id: $id, ')
          ..write('ageConfirmed: $ageConfirmed, ')
          ..write('consentGiven: $consentGiven, ')
          ..write('policyVersion: $policyVersion, ')
          ..write('consentedAt: $consentedAt')
          ..write(')'))
        .toString();
  }
}

class $UserProfileTable extends UserProfile
    with TableInfo<$UserProfileTable, UserProfileData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserProfileTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sexMeta = const VerificationMeta('sex');
  @override
  late final GeneratedColumn<String> sex = GeneratedColumn<String>(
    'sex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _birthDateMeta = const VerificationMeta(
    'birthDate',
  );
  @override
  late final GeneratedColumn<DateTime> birthDate = GeneratedColumn<DateTime>(
    'birth_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heightCmMeta = const VerificationMeta(
    'heightCm',
  );
  @override
  late final GeneratedColumn<double> heightCm = GeneratedColumn<double>(
    'height_cm',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activityLevelMeta = const VerificationMeta(
    'activityLevel',
  );
  @override
  late final GeneratedColumn<String> activityLevel = GeneratedColumn<String>(
    'activity_level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _measuredMaintenanceKcalMeta =
      const VerificationMeta('measuredMaintenanceKcal');
  @override
  late final GeneratedColumn<double> measuredMaintenanceKcal =
      GeneratedColumn<double>(
        'measured_maintenance_kcal',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sex,
    birthDate,
    heightCm,
    weightKg,
    activityLevel,
    measuredMaintenanceKcal,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_profile';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserProfileData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sex')) {
      context.handle(
        _sexMeta,
        sex.isAcceptableOrUnknown(data['sex']!, _sexMeta),
      );
    } else if (isInserting) {
      context.missing(_sexMeta);
    }
    if (data.containsKey('birth_date')) {
      context.handle(
        _birthDateMeta,
        birthDate.isAcceptableOrUnknown(data['birth_date']!, _birthDateMeta),
      );
    } else if (isInserting) {
      context.missing(_birthDateMeta);
    }
    if (data.containsKey('height_cm')) {
      context.handle(
        _heightCmMeta,
        heightCm.isAcceptableOrUnknown(data['height_cm']!, _heightCmMeta),
      );
    } else if (isInserting) {
      context.missing(_heightCmMeta);
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    } else if (isInserting) {
      context.missing(_weightKgMeta);
    }
    if (data.containsKey('activity_level')) {
      context.handle(
        _activityLevelMeta,
        activityLevel.isAcceptableOrUnknown(
          data['activity_level']!,
          _activityLevelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activityLevelMeta);
    }
    if (data.containsKey('measured_maintenance_kcal')) {
      context.handle(
        _measuredMaintenanceKcalMeta,
        measuredMaintenanceKcal.isAcceptableOrUnknown(
          data['measured_maintenance_kcal']!,
          _measuredMaintenanceKcalMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserProfileData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProfileData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sex'],
      )!,
      birthDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}birth_date'],
      )!,
      heightCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}height_cm'],
      )!,
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      )!,
      activityLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_level'],
      )!,
      measuredMaintenanceKcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}measured_maintenance_kcal'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $UserProfileTable createAlias(String alias) {
    return $UserProfileTable(attachedDatabase, alias);
  }
}

class UserProfileData extends DataClass implements Insertable<UserProfileData> {
  final int id;
  final String sex;
  final DateTime birthDate;
  final double heightCm;
  final double weightKg;
  final String activityLevel;

  /// SPEC-008 R4: mantenimiento medido (p. ej. promedio de un reloj); si
  /// existe, manda sobre la fórmula.
  final double? measuredMaintenanceKcal;
  final DateTime updatedAt;
  const UserProfileData({
    required this.id,
    required this.sex,
    required this.birthDate,
    required this.heightCm,
    required this.weightKg,
    required this.activityLevel,
    this.measuredMaintenanceKcal,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sex'] = Variable<String>(sex);
    map['birth_date'] = Variable<DateTime>(birthDate);
    map['height_cm'] = Variable<double>(heightCm);
    map['weight_kg'] = Variable<double>(weightKg);
    map['activity_level'] = Variable<String>(activityLevel);
    if (!nullToAbsent || measuredMaintenanceKcal != null) {
      map['measured_maintenance_kcal'] = Variable<double>(
        measuredMaintenanceKcal,
      );
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UserProfileCompanion toCompanion(bool nullToAbsent) {
    return UserProfileCompanion(
      id: Value(id),
      sex: Value(sex),
      birthDate: Value(birthDate),
      heightCm: Value(heightCm),
      weightKg: Value(weightKg),
      activityLevel: Value(activityLevel),
      measuredMaintenanceKcal: measuredMaintenanceKcal == null && nullToAbsent
          ? const Value.absent()
          : Value(measuredMaintenanceKcal),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserProfileData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProfileData(
      id: serializer.fromJson<int>(json['id']),
      sex: serializer.fromJson<String>(json['sex']),
      birthDate: serializer.fromJson<DateTime>(json['birthDate']),
      heightCm: serializer.fromJson<double>(json['heightCm']),
      weightKg: serializer.fromJson<double>(json['weightKg']),
      activityLevel: serializer.fromJson<String>(json['activityLevel']),
      measuredMaintenanceKcal: serializer.fromJson<double?>(
        json['measuredMaintenanceKcal'],
      ),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sex': serializer.toJson<String>(sex),
      'birthDate': serializer.toJson<DateTime>(birthDate),
      'heightCm': serializer.toJson<double>(heightCm),
      'weightKg': serializer.toJson<double>(weightKg),
      'activityLevel': serializer.toJson<String>(activityLevel),
      'measuredMaintenanceKcal': serializer.toJson<double?>(
        measuredMaintenanceKcal,
      ),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UserProfileData copyWith({
    int? id,
    String? sex,
    DateTime? birthDate,
    double? heightCm,
    double? weightKg,
    String? activityLevel,
    Value<double?> measuredMaintenanceKcal = const Value.absent(),
    DateTime? updatedAt,
  }) => UserProfileData(
    id: id ?? this.id,
    sex: sex ?? this.sex,
    birthDate: birthDate ?? this.birthDate,
    heightCm: heightCm ?? this.heightCm,
    weightKg: weightKg ?? this.weightKg,
    activityLevel: activityLevel ?? this.activityLevel,
    measuredMaintenanceKcal: measuredMaintenanceKcal.present
        ? measuredMaintenanceKcal.value
        : this.measuredMaintenanceKcal,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  UserProfileData copyWithCompanion(UserProfileCompanion data) {
    return UserProfileData(
      id: data.id.present ? data.id.value : this.id,
      sex: data.sex.present ? data.sex.value : this.sex,
      birthDate: data.birthDate.present ? data.birthDate.value : this.birthDate,
      heightCm: data.heightCm.present ? data.heightCm.value : this.heightCm,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      activityLevel: data.activityLevel.present
          ? data.activityLevel.value
          : this.activityLevel,
      measuredMaintenanceKcal: data.measuredMaintenanceKcal.present
          ? data.measuredMaintenanceKcal.value
          : this.measuredMaintenanceKcal,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserProfileData(')
          ..write('id: $id, ')
          ..write('sex: $sex, ')
          ..write('birthDate: $birthDate, ')
          ..write('heightCm: $heightCm, ')
          ..write('weightKg: $weightKg, ')
          ..write('activityLevel: $activityLevel, ')
          ..write('measuredMaintenanceKcal: $measuredMaintenanceKcal, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sex,
    birthDate,
    heightCm,
    weightKg,
    activityLevel,
    measuredMaintenanceKcal,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProfileData &&
          other.id == this.id &&
          other.sex == this.sex &&
          other.birthDate == this.birthDate &&
          other.heightCm == this.heightCm &&
          other.weightKg == this.weightKg &&
          other.activityLevel == this.activityLevel &&
          other.measuredMaintenanceKcal == this.measuredMaintenanceKcal &&
          other.updatedAt == this.updatedAt);
}

class UserProfileCompanion extends UpdateCompanion<UserProfileData> {
  final Value<int> id;
  final Value<String> sex;
  final Value<DateTime> birthDate;
  final Value<double> heightCm;
  final Value<double> weightKg;
  final Value<String> activityLevel;
  final Value<double?> measuredMaintenanceKcal;
  final Value<DateTime> updatedAt;
  const UserProfileCompanion({
    this.id = const Value.absent(),
    this.sex = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.activityLevel = const Value.absent(),
    this.measuredMaintenanceKcal = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  UserProfileCompanion.insert({
    this.id = const Value.absent(),
    required String sex,
    required DateTime birthDate,
    required double heightCm,
    required double weightKg,
    required String activityLevel,
    this.measuredMaintenanceKcal = const Value.absent(),
    required DateTime updatedAt,
  }) : sex = Value(sex),
       birthDate = Value(birthDate),
       heightCm = Value(heightCm),
       weightKg = Value(weightKg),
       activityLevel = Value(activityLevel),
       updatedAt = Value(updatedAt);
  static Insertable<UserProfileData> custom({
    Expression<int>? id,
    Expression<String>? sex,
    Expression<DateTime>? birthDate,
    Expression<double>? heightCm,
    Expression<double>? weightKg,
    Expression<String>? activityLevel,
    Expression<double>? measuredMaintenanceKcal,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sex != null) 'sex': sex,
      if (birthDate != null) 'birth_date': birthDate,
      if (heightCm != null) 'height_cm': heightCm,
      if (weightKg != null) 'weight_kg': weightKg,
      if (activityLevel != null) 'activity_level': activityLevel,
      if (measuredMaintenanceKcal != null)
        'measured_maintenance_kcal': measuredMaintenanceKcal,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  UserProfileCompanion copyWith({
    Value<int>? id,
    Value<String>? sex,
    Value<DateTime>? birthDate,
    Value<double>? heightCm,
    Value<double>? weightKg,
    Value<String>? activityLevel,
    Value<double?>? measuredMaintenanceKcal,
    Value<DateTime>? updatedAt,
  }) {
    return UserProfileCompanion(
      id: id ?? this.id,
      sex: sex ?? this.sex,
      birthDate: birthDate ?? this.birthDate,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      measuredMaintenanceKcal:
          measuredMaintenanceKcal ?? this.measuredMaintenanceKcal,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sex.present) {
      map['sex'] = Variable<String>(sex.value);
    }
    if (birthDate.present) {
      map['birth_date'] = Variable<DateTime>(birthDate.value);
    }
    if (heightCm.present) {
      map['height_cm'] = Variable<double>(heightCm.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (activityLevel.present) {
      map['activity_level'] = Variable<String>(activityLevel.value);
    }
    if (measuredMaintenanceKcal.present) {
      map['measured_maintenance_kcal'] = Variable<double>(
        measuredMaintenanceKcal.value,
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserProfileCompanion(')
          ..write('id: $id, ')
          ..write('sex: $sex, ')
          ..write('birthDate: $birthDate, ')
          ..write('heightCm: $heightCm, ')
          ..write('weightKg: $weightKg, ')
          ..write('activityLevel: $activityLevel, ')
          ..write('measuredMaintenanceKcal: $measuredMaintenanceKcal, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $NutritionGoalsTable extends NutritionGoals
    with TableInfo<$NutritionGoalsTable, NutritionGoal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NutritionGoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _objectiveMeta = const VerificationMeta(
    'objective',
  );
  @override
  late final GeneratedColumn<String> objective = GeneratedColumn<String>(
    'objective',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isManualMeta = const VerificationMeta(
    'isManual',
  );
  @override
  late final GeneratedColumn<bool> isManual = GeneratedColumn<bool>(
    'is_manual',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_manual" IN (0, 1))',
    ),
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    objective,
    isManual,
    energyKcal,
    proteinG,
    carbsG,
    fatG,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nutrition_goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<NutritionGoal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('objective')) {
      context.handle(
        _objectiveMeta,
        objective.isAcceptableOrUnknown(data['objective']!, _objectiveMeta),
      );
    } else if (isInserting) {
      context.missing(_objectiveMeta);
    }
    if (data.containsKey('is_manual')) {
      context.handle(
        _isManualMeta,
        isManual.isAcceptableOrUnknown(data['is_manual']!, _isManualMeta),
      );
    } else if (isInserting) {
      context.missing(_isManualMeta);
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NutritionGoal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NutritionGoal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      objective: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}objective'],
      )!,
      isManual: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_manual'],
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
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $NutritionGoalsTable createAlias(String alias) {
    return $NutritionGoalsTable(attachedDatabase, alias);
  }
}

class NutritionGoal extends DataClass implements Insertable<NutritionGoal> {
  final int id;
  final String objective;
  final bool isManual;
  final double energyKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final DateTime updatedAt;
  const NutritionGoal({
    required this.id,
    required this.objective,
    required this.isManual,
    required this.energyKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['objective'] = Variable<String>(objective);
    map['is_manual'] = Variable<bool>(isManual);
    map['energy_kcal'] = Variable<double>(energyKcal);
    map['protein_g'] = Variable<double>(proteinG);
    map['carbs_g'] = Variable<double>(carbsG);
    map['fat_g'] = Variable<double>(fatG);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  NutritionGoalsCompanion toCompanion(bool nullToAbsent) {
    return NutritionGoalsCompanion(
      id: Value(id),
      objective: Value(objective),
      isManual: Value(isManual),
      energyKcal: Value(energyKcal),
      proteinG: Value(proteinG),
      carbsG: Value(carbsG),
      fatG: Value(fatG),
      updatedAt: Value(updatedAt),
    );
  }

  factory NutritionGoal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NutritionGoal(
      id: serializer.fromJson<int>(json['id']),
      objective: serializer.fromJson<String>(json['objective']),
      isManual: serializer.fromJson<bool>(json['isManual']),
      energyKcal: serializer.fromJson<double>(json['energyKcal']),
      proteinG: serializer.fromJson<double>(json['proteinG']),
      carbsG: serializer.fromJson<double>(json['carbsG']),
      fatG: serializer.fromJson<double>(json['fatG']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'objective': serializer.toJson<String>(objective),
      'isManual': serializer.toJson<bool>(isManual),
      'energyKcal': serializer.toJson<double>(energyKcal),
      'proteinG': serializer.toJson<double>(proteinG),
      'carbsG': serializer.toJson<double>(carbsG),
      'fatG': serializer.toJson<double>(fatG),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  NutritionGoal copyWith({
    int? id,
    String? objective,
    bool? isManual,
    double? energyKcal,
    double? proteinG,
    double? carbsG,
    double? fatG,
    DateTime? updatedAt,
  }) => NutritionGoal(
    id: id ?? this.id,
    objective: objective ?? this.objective,
    isManual: isManual ?? this.isManual,
    energyKcal: energyKcal ?? this.energyKcal,
    proteinG: proteinG ?? this.proteinG,
    carbsG: carbsG ?? this.carbsG,
    fatG: fatG ?? this.fatG,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  NutritionGoal copyWithCompanion(NutritionGoalsCompanion data) {
    return NutritionGoal(
      id: data.id.present ? data.id.value : this.id,
      objective: data.objective.present ? data.objective.value : this.objective,
      isManual: data.isManual.present ? data.isManual.value : this.isManual,
      energyKcal: data.energyKcal.present
          ? data.energyKcal.value
          : this.energyKcal,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      carbsG: data.carbsG.present ? data.carbsG.value : this.carbsG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NutritionGoal(')
          ..write('id: $id, ')
          ..write('objective: $objective, ')
          ..write('isManual: $isManual, ')
          ..write('energyKcal: $energyKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    objective,
    isManual,
    energyKcal,
    proteinG,
    carbsG,
    fatG,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NutritionGoal &&
          other.id == this.id &&
          other.objective == this.objective &&
          other.isManual == this.isManual &&
          other.energyKcal == this.energyKcal &&
          other.proteinG == this.proteinG &&
          other.carbsG == this.carbsG &&
          other.fatG == this.fatG &&
          other.updatedAt == this.updatedAt);
}

class NutritionGoalsCompanion extends UpdateCompanion<NutritionGoal> {
  final Value<int> id;
  final Value<String> objective;
  final Value<bool> isManual;
  final Value<double> energyKcal;
  final Value<double> proteinG;
  final Value<double> carbsG;
  final Value<double> fatG;
  final Value<DateTime> updatedAt;
  const NutritionGoalsCompanion({
    this.id = const Value.absent(),
    this.objective = const Value.absent(),
    this.isManual = const Value.absent(),
    this.energyKcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  NutritionGoalsCompanion.insert({
    this.id = const Value.absent(),
    required String objective,
    required bool isManual,
    required double energyKcal,
    required double proteinG,
    required double carbsG,
    required double fatG,
    required DateTime updatedAt,
  }) : objective = Value(objective),
       isManual = Value(isManual),
       energyKcal = Value(energyKcal),
       proteinG = Value(proteinG),
       carbsG = Value(carbsG),
       fatG = Value(fatG),
       updatedAt = Value(updatedAt);
  static Insertable<NutritionGoal> custom({
    Expression<int>? id,
    Expression<String>? objective,
    Expression<bool>? isManual,
    Expression<double>? energyKcal,
    Expression<double>? proteinG,
    Expression<double>? carbsG,
    Expression<double>? fatG,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (objective != null) 'objective': objective,
      if (isManual != null) 'is_manual': isManual,
      if (energyKcal != null) 'energy_kcal': energyKcal,
      if (proteinG != null) 'protein_g': proteinG,
      if (carbsG != null) 'carbs_g': carbsG,
      if (fatG != null) 'fat_g': fatG,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  NutritionGoalsCompanion copyWith({
    Value<int>? id,
    Value<String>? objective,
    Value<bool>? isManual,
    Value<double>? energyKcal,
    Value<double>? proteinG,
    Value<double>? carbsG,
    Value<double>? fatG,
    Value<DateTime>? updatedAt,
  }) {
    return NutritionGoalsCompanion(
      id: id ?? this.id,
      objective: objective ?? this.objective,
      isManual: isManual ?? this.isManual,
      energyKcal: energyKcal ?? this.energyKcal,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (objective.present) {
      map['objective'] = Variable<String>(objective.value);
    }
    if (isManual.present) {
      map['is_manual'] = Variable<bool>(isManual.value);
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
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NutritionGoalsCompanion(')
          ..write('id: $id, ')
          ..write('objective: $objective, ')
          ..write('isManual: $isManual, ')
          ..write('energyKcal: $energyKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $WeightLogTable extends WeightLog
    with TableInfo<$WeightLogTable, WeightLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeightLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<DateTime> day = GeneratedColumn<DateTime>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [day, weightKg, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weight_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeightLogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    } else if (isInserting) {
      context.missing(_weightKgMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {day};
  @override
  WeightLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeightLogData(
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}day'],
      )!,
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $WeightLogTable createAlias(String alias) {
    return $WeightLogTable(attachedDatabase, alias);
  }
}

class WeightLogData extends DataClass implements Insertable<WeightLogData> {
  final DateTime day;
  final double weightKg;
  final DateTime updatedAt;
  const WeightLogData({
    required this.day,
    required this.weightKg,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day'] = Variable<DateTime>(day);
    map['weight_kg'] = Variable<double>(weightKg);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WeightLogCompanion toCompanion(bool nullToAbsent) {
    return WeightLogCompanion(
      day: Value(day),
      weightKg: Value(weightKg),
      updatedAt: Value(updatedAt),
    );
  }

  factory WeightLogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeightLogData(
      day: serializer.fromJson<DateTime>(json['day']),
      weightKg: serializer.fromJson<double>(json['weightKg']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'day': serializer.toJson<DateTime>(day),
      'weightKg': serializer.toJson<double>(weightKg),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  WeightLogData copyWith({
    DateTime? day,
    double? weightKg,
    DateTime? updatedAt,
  }) => WeightLogData(
    day: day ?? this.day,
    weightKg: weightKg ?? this.weightKg,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  WeightLogData copyWithCompanion(WeightLogCompanion data) {
    return WeightLogData(
      day: data.day.present ? data.day.value : this.day,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeightLogData(')
          ..write('day: $day, ')
          ..write('weightKg: $weightKg, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(day, weightKg, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeightLogData &&
          other.day == this.day &&
          other.weightKg == this.weightKg &&
          other.updatedAt == this.updatedAt);
}

class WeightLogCompanion extends UpdateCompanion<WeightLogData> {
  final Value<DateTime> day;
  final Value<double> weightKg;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const WeightLogCompanion({
    this.day = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeightLogCompanion.insert({
    required DateTime day,
    required double weightKg,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : day = Value(day),
       weightKg = Value(weightKg),
       updatedAt = Value(updatedAt);
  static Insertable<WeightLogData> custom({
    Expression<DateTime>? day,
    Expression<double>? weightKg,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (day != null) 'day': day,
      if (weightKg != null) 'weight_kg': weightKg,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeightLogCompanion copyWith({
    Value<DateTime>? day,
    Value<double>? weightKg,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return WeightLogCompanion(
      day: day ?? this.day,
      weightKg: weightKg ?? this.weightKg,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (day.present) {
      map['day'] = Variable<DateTime>(day.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeightLogCompanion(')
          ..write('day: $day, ')
          ..write('weightKg: $weightKg, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FavoriteMealsTable extends FavoriteMeals
    with TableInfo<$FavoriteMealsTable, FavoriteMeal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoriteMealsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
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
  List<GeneratedColumn> get $columns => [id, name, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorite_meals';
  @override
  VerificationContext validateIntegrity(
    Insertable<FavoriteMeal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
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
  FavoriteMeal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoriteMeal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FavoriteMealsTable createAlias(String alias) {
    return $FavoriteMealsTable(attachedDatabase, alias);
  }
}

class FavoriteMeal extends DataClass implements Insertable<FavoriteMeal> {
  final int id;
  final String name;
  final DateTime createdAt;
  const FavoriteMeal({
    required this.id,
    required this.name,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FavoriteMealsCompanion toCompanion(bool nullToAbsent) {
    return FavoriteMealsCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
    );
  }

  factory FavoriteMeal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoriteMeal(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  FavoriteMeal copyWith({int? id, String? name, DateTime? createdAt}) =>
      FavoriteMeal(
        id: id ?? this.id,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
      );
  FavoriteMeal copyWithCompanion(FavoriteMealsCompanion data) {
    return FavoriteMeal(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteMeal(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoriteMeal &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt);
}

class FavoriteMealsCompanion extends UpdateCompanion<FavoriteMeal> {
  final Value<int> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  const FavoriteMealsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  FavoriteMealsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.createdAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<FavoriteMeal> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  FavoriteMealsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<DateTime>? createdAt,
  }) {
    return FavoriteMealsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteMealsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $FavoriteMealItemsTable extends FavoriteMealItems
    with TableInfo<$FavoriteMealItemsTable, FavoriteMealItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoriteMealItemsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _favoriteIdMeta = const VerificationMeta(
    'favoriteId',
  );
  @override
  late final GeneratedColumn<int> favoriteId = GeneratedColumn<int>(
    'favorite_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES favorite_meals (id)',
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
  static const VerificationMeta _foodIdMeta = const VerificationMeta('foodId');
  @override
  late final GeneratedColumn<String> foodId = GeneratedColumn<String>(
    'food_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    favoriteId,
    position,
    foodId,
    mention,
    grams,
    quantityInput,
    unitInput,
    sizeInput,
    quantityBasis,
    confidence,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorite_meal_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<FavoriteMealItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('favorite_id')) {
      context.handle(
        _favoriteIdMeta,
        favoriteId.isAcceptableOrUnknown(data['favorite_id']!, _favoriteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_favoriteIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('food_id')) {
      context.handle(
        _foodIdMeta,
        foodId.isAcceptableOrUnknown(data['food_id']!, _foodIdMeta),
      );
    } else if (isInserting) {
      context.missing(_foodIdMeta);
    }
    if (data.containsKey('mention')) {
      context.handle(
        _mentionMeta,
        mention.isAcceptableOrUnknown(data['mention']!, _mentionMeta),
      );
    } else if (isInserting) {
      context.missing(_mentionMeta);
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
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    } else if (isInserting) {
      context.missing(_confidenceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FavoriteMealItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoriteMealItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      favoriteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}favorite_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      foodId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_id'],
      )!,
      mention: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mention'],
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
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}confidence'],
      )!,
    );
  }

  @override
  $FavoriteMealItemsTable createAlias(String alias) {
    return $FavoriteMealItemsTable(attachedDatabase, alias);
  }
}

class FavoriteMealItem extends DataClass
    implements Insertable<FavoriteMealItem> {
  final int id;
  final int favoriteId;
  final int position;
  final String foodId;
  final String mention;
  final double grams;
  final double? quantityInput;
  final String? unitInput;
  final String? sizeInput;
  final String quantityBasis;
  final String confidence;
  const FavoriteMealItem({
    required this.id,
    required this.favoriteId,
    required this.position,
    required this.foodId,
    required this.mention,
    required this.grams,
    this.quantityInput,
    this.unitInput,
    this.sizeInput,
    required this.quantityBasis,
    required this.confidence,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['favorite_id'] = Variable<int>(favoriteId);
    map['position'] = Variable<int>(position);
    map['food_id'] = Variable<String>(foodId);
    map['mention'] = Variable<String>(mention);
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
    map['confidence'] = Variable<String>(confidence);
    return map;
  }

  FavoriteMealItemsCompanion toCompanion(bool nullToAbsent) {
    return FavoriteMealItemsCompanion(
      id: Value(id),
      favoriteId: Value(favoriteId),
      position: Value(position),
      foodId: Value(foodId),
      mention: Value(mention),
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
      confidence: Value(confidence),
    );
  }

  factory FavoriteMealItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoriteMealItem(
      id: serializer.fromJson<int>(json['id']),
      favoriteId: serializer.fromJson<int>(json['favoriteId']),
      position: serializer.fromJson<int>(json['position']),
      foodId: serializer.fromJson<String>(json['foodId']),
      mention: serializer.fromJson<String>(json['mention']),
      grams: serializer.fromJson<double>(json['grams']),
      quantityInput: serializer.fromJson<double?>(json['quantityInput']),
      unitInput: serializer.fromJson<String?>(json['unitInput']),
      sizeInput: serializer.fromJson<String?>(json['sizeInput']),
      quantityBasis: serializer.fromJson<String>(json['quantityBasis']),
      confidence: serializer.fromJson<String>(json['confidence']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'favoriteId': serializer.toJson<int>(favoriteId),
      'position': serializer.toJson<int>(position),
      'foodId': serializer.toJson<String>(foodId),
      'mention': serializer.toJson<String>(mention),
      'grams': serializer.toJson<double>(grams),
      'quantityInput': serializer.toJson<double?>(quantityInput),
      'unitInput': serializer.toJson<String?>(unitInput),
      'sizeInput': serializer.toJson<String?>(sizeInput),
      'quantityBasis': serializer.toJson<String>(quantityBasis),
      'confidence': serializer.toJson<String>(confidence),
    };
  }

  FavoriteMealItem copyWith({
    int? id,
    int? favoriteId,
    int? position,
    String? foodId,
    String? mention,
    double? grams,
    Value<double?> quantityInput = const Value.absent(),
    Value<String?> unitInput = const Value.absent(),
    Value<String?> sizeInput = const Value.absent(),
    String? quantityBasis,
    String? confidence,
  }) => FavoriteMealItem(
    id: id ?? this.id,
    favoriteId: favoriteId ?? this.favoriteId,
    position: position ?? this.position,
    foodId: foodId ?? this.foodId,
    mention: mention ?? this.mention,
    grams: grams ?? this.grams,
    quantityInput: quantityInput.present
        ? quantityInput.value
        : this.quantityInput,
    unitInput: unitInput.present ? unitInput.value : this.unitInput,
    sizeInput: sizeInput.present ? sizeInput.value : this.sizeInput,
    quantityBasis: quantityBasis ?? this.quantityBasis,
    confidence: confidence ?? this.confidence,
  );
  FavoriteMealItem copyWithCompanion(FavoriteMealItemsCompanion data) {
    return FavoriteMealItem(
      id: data.id.present ? data.id.value : this.id,
      favoriteId: data.favoriteId.present
          ? data.favoriteId.value
          : this.favoriteId,
      position: data.position.present ? data.position.value : this.position,
      foodId: data.foodId.present ? data.foodId.value : this.foodId,
      mention: data.mention.present ? data.mention.value : this.mention,
      grams: data.grams.present ? data.grams.value : this.grams,
      quantityInput: data.quantityInput.present
          ? data.quantityInput.value
          : this.quantityInput,
      unitInput: data.unitInput.present ? data.unitInput.value : this.unitInput,
      sizeInput: data.sizeInput.present ? data.sizeInput.value : this.sizeInput,
      quantityBasis: data.quantityBasis.present
          ? data.quantityBasis.value
          : this.quantityBasis,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteMealItem(')
          ..write('id: $id, ')
          ..write('favoriteId: $favoriteId, ')
          ..write('position: $position, ')
          ..write('foodId: $foodId, ')
          ..write('mention: $mention, ')
          ..write('grams: $grams, ')
          ..write('quantityInput: $quantityInput, ')
          ..write('unitInput: $unitInput, ')
          ..write('sizeInput: $sizeInput, ')
          ..write('quantityBasis: $quantityBasis, ')
          ..write('confidence: $confidence')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    favoriteId,
    position,
    foodId,
    mention,
    grams,
    quantityInput,
    unitInput,
    sizeInput,
    quantityBasis,
    confidence,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoriteMealItem &&
          other.id == this.id &&
          other.favoriteId == this.favoriteId &&
          other.position == this.position &&
          other.foodId == this.foodId &&
          other.mention == this.mention &&
          other.grams == this.grams &&
          other.quantityInput == this.quantityInput &&
          other.unitInput == this.unitInput &&
          other.sizeInput == this.sizeInput &&
          other.quantityBasis == this.quantityBasis &&
          other.confidence == this.confidence);
}

class FavoriteMealItemsCompanion extends UpdateCompanion<FavoriteMealItem> {
  final Value<int> id;
  final Value<int> favoriteId;
  final Value<int> position;
  final Value<String> foodId;
  final Value<String> mention;
  final Value<double> grams;
  final Value<double?> quantityInput;
  final Value<String?> unitInput;
  final Value<String?> sizeInput;
  final Value<String> quantityBasis;
  final Value<String> confidence;
  const FavoriteMealItemsCompanion({
    this.id = const Value.absent(),
    this.favoriteId = const Value.absent(),
    this.position = const Value.absent(),
    this.foodId = const Value.absent(),
    this.mention = const Value.absent(),
    this.grams = const Value.absent(),
    this.quantityInput = const Value.absent(),
    this.unitInput = const Value.absent(),
    this.sizeInput = const Value.absent(),
    this.quantityBasis = const Value.absent(),
    this.confidence = const Value.absent(),
  });
  FavoriteMealItemsCompanion.insert({
    this.id = const Value.absent(),
    required int favoriteId,
    required int position,
    required String foodId,
    required String mention,
    required double grams,
    this.quantityInput = const Value.absent(),
    this.unitInput = const Value.absent(),
    this.sizeInput = const Value.absent(),
    required String quantityBasis,
    required String confidence,
  }) : favoriteId = Value(favoriteId),
       position = Value(position),
       foodId = Value(foodId),
       mention = Value(mention),
       grams = Value(grams),
       quantityBasis = Value(quantityBasis),
       confidence = Value(confidence);
  static Insertable<FavoriteMealItem> custom({
    Expression<int>? id,
    Expression<int>? favoriteId,
    Expression<int>? position,
    Expression<String>? foodId,
    Expression<String>? mention,
    Expression<double>? grams,
    Expression<double>? quantityInput,
    Expression<String>? unitInput,
    Expression<String>? sizeInput,
    Expression<String>? quantityBasis,
    Expression<String>? confidence,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (favoriteId != null) 'favorite_id': favoriteId,
      if (position != null) 'position': position,
      if (foodId != null) 'food_id': foodId,
      if (mention != null) 'mention': mention,
      if (grams != null) 'grams': grams,
      if (quantityInput != null) 'quantity_input': quantityInput,
      if (unitInput != null) 'unit_input': unitInput,
      if (sizeInput != null) 'size_input': sizeInput,
      if (quantityBasis != null) 'quantity_basis': quantityBasis,
      if (confidence != null) 'confidence': confidence,
    });
  }

  FavoriteMealItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? favoriteId,
    Value<int>? position,
    Value<String>? foodId,
    Value<String>? mention,
    Value<double>? grams,
    Value<double?>? quantityInput,
    Value<String?>? unitInput,
    Value<String?>? sizeInput,
    Value<String>? quantityBasis,
    Value<String>? confidence,
  }) {
    return FavoriteMealItemsCompanion(
      id: id ?? this.id,
      favoriteId: favoriteId ?? this.favoriteId,
      position: position ?? this.position,
      foodId: foodId ?? this.foodId,
      mention: mention ?? this.mention,
      grams: grams ?? this.grams,
      quantityInput: quantityInput ?? this.quantityInput,
      unitInput: unitInput ?? this.unitInput,
      sizeInput: sizeInput ?? this.sizeInput,
      quantityBasis: quantityBasis ?? this.quantityBasis,
      confidence: confidence ?? this.confidence,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (favoriteId.present) {
      map['favorite_id'] = Variable<int>(favoriteId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (foodId.present) {
      map['food_id'] = Variable<String>(foodId.value);
    }
    if (mention.present) {
      map['mention'] = Variable<String>(mention.value);
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
    if (confidence.present) {
      map['confidence'] = Variable<String>(confidence.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteMealItemsCompanion(')
          ..write('id: $id, ')
          ..write('favoriteId: $favoriteId, ')
          ..write('position: $position, ')
          ..write('foodId: $foodId, ')
          ..write('mention: $mention, ')
          ..write('grams: $grams, ')
          ..write('quantityInput: $quantityInput, ')
          ..write('unitInput: $unitInput, ')
          ..write('sizeInput: $sizeInput, ')
          ..write('quantityBasis: $quantityBasis, ')
          ..write('confidence: $confidence')
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
  late final $PersonalProductAliasesTable personalProductAliases =
      $PersonalProductAliasesTable(this);
  late final $ConsentRecordTable consentRecord = $ConsentRecordTable(this);
  late final $UserProfileTable userProfile = $UserProfileTable(this);
  late final $NutritionGoalsTable nutritionGoals = $NutritionGoalsTable(this);
  late final $WeightLogTable weightLog = $WeightLogTable(this);
  late final $FavoriteMealsTable favoriteMeals = $FavoriteMealsTable(this);
  late final $FavoriteMealItemsTable favoriteMealItems =
      $FavoriteMealItemsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    meals,
    mealItems,
    personalProducts,
    personalProductAliases,
    consentRecord,
    userProfile,
    nutritionGoals,
    weightLog,
    favoriteMeals,
    favoriteMealItems,
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
      Value<String> servingUnit,
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
      Value<String> servingUnit,
    });

final class $$PersonalProductsTableReferences
    extends
        BaseReferences<_$AppDatabase, $PersonalProductsTable, PersonalProduct> {
  $$PersonalProductsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $PersonalProductAliasesTable,
    List<PersonalProductAliase>
  >
  _personalProductAliasesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.personalProductAliases,
        aliasName:
            'personal_products__id__personal_product_aliases__product_id',
      );

  $$PersonalProductAliasesTableProcessedTableManager
  get personalProductAliasesRefs {
    final manager = $$PersonalProductAliasesTableTableManager(
      $_db,
      $_db.personalProductAliases,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _personalProductAliasesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

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

  ColumnFilters<String> get servingUnit => $composableBuilder(
    column: $table.servingUnit,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> personalProductAliasesRefs(
    Expression<bool> Function($$PersonalProductAliasesTableFilterComposer f) f,
  ) {
    final $$PersonalProductAliasesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.personalProductAliases,
          getReferencedColumn: (t) => t.productId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PersonalProductAliasesTableFilterComposer(
                $db: $db,
                $table: $db.personalProductAliases,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
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

  ColumnOrderings<String> get servingUnit => $composableBuilder(
    column: $table.servingUnit,
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

  GeneratedColumn<String> get servingUnit => $composableBuilder(
    column: $table.servingUnit,
    builder: (column) => column,
  );

  Expression<T> personalProductAliasesRefs<T extends Object>(
    Expression<T> Function($$PersonalProductAliasesTableAnnotationComposer a) f,
  ) {
    final $$PersonalProductAliasesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.personalProductAliases,
          getReferencedColumn: (t) => t.productId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PersonalProductAliasesTableAnnotationComposer(
                $db: $db,
                $table: $db.personalProductAliases,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
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
          (PersonalProduct, $$PersonalProductsTableReferences),
          PersonalProduct,
          PrefetchHooks Function({bool personalProductAliasesRefs})
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
                Value<String> servingUnit = const Value.absent(),
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
                servingUnit: servingUnit,
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
                Value<String> servingUnit = const Value.absent(),
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
                servingUnit: servingUnit,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PersonalProductsTable, PersonalProduct>(table),
                  $$PersonalProductsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({personalProductAliasesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (personalProductAliasesRefs) db.personalProductAliases,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (personalProductAliasesRefs)
                    await $_getPrefetchedData<
                      PersonalProduct,
                      $PersonalProductsTable,
                      PersonalProductAliase
                    >(
                      currentTable: table,
                      referencedTable: $$PersonalProductsTableReferences
                          ._personalProductAliasesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$PersonalProductsTableReferences(
                            db,
                            table,
                            p0,
                          ).personalProductAliasesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.productId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
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
      (PersonalProduct, $$PersonalProductsTableReferences),
      PersonalProduct,
      PrefetchHooks Function({bool personalProductAliasesRefs})
    >;
typedef $$PersonalProductAliasesTableCreateCompanionBuilder =
    PersonalProductAliasesCompanion Function({
      Value<int> id,
      required int productId,
      required String term,
    });
typedef $$PersonalProductAliasesTableUpdateCompanionBuilder =
    PersonalProductAliasesCompanion Function({
      Value<int> id,
      Value<int> productId,
      Value<String> term,
    });

final class $$PersonalProductAliasesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PersonalProductAliasesTable,
          PersonalProductAliase
        > {
  $$PersonalProductAliasesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PersonalProductsTable _productIdTable(_$AppDatabase db) =>
      db.personalProducts.createAlias(
        'personal_product_aliases__product_id__personal_products__id',
      );

  $$PersonalProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<int>('product_id')!;

    final manager = $$PersonalProductsTableTableManager(
      $_db,
      $_db.personalProducts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PersonalProductAliasesTableFilterComposer
    extends Composer<_$AppDatabase, $PersonalProductAliasesTable> {
  $$PersonalProductAliasesTableFilterComposer({
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

  ColumnFilters<String> get term => $composableBuilder(
    column: $table.term,
    builder: (column) => ColumnFilters(column),
  );

  $$PersonalProductsTableFilterComposer get productId {
    final $$PersonalProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.personalProducts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonalProductsTableFilterComposer(
            $db: $db,
            $table: $db.personalProducts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PersonalProductAliasesTableOrderingComposer
    extends Composer<_$AppDatabase, $PersonalProductAliasesTable> {
  $$PersonalProductAliasesTableOrderingComposer({
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

  ColumnOrderings<String> get term => $composableBuilder(
    column: $table.term,
    builder: (column) => ColumnOrderings(column),
  );

  $$PersonalProductsTableOrderingComposer get productId {
    final $$PersonalProductsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.personalProducts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonalProductsTableOrderingComposer(
            $db: $db,
            $table: $db.personalProducts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PersonalProductAliasesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PersonalProductAliasesTable> {
  $$PersonalProductAliasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get term =>
      $composableBuilder(column: $table.term, builder: (column) => column);

  $$PersonalProductsTableAnnotationComposer get productId {
    final $$PersonalProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.personalProducts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonalProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.personalProducts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PersonalProductAliasesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PersonalProductAliasesTable,
          PersonalProductAliase,
          $$PersonalProductAliasesTableFilterComposer,
          $$PersonalProductAliasesTableOrderingComposer,
          $$PersonalProductAliasesTableAnnotationComposer,
          $$PersonalProductAliasesTableCreateCompanionBuilder,
          $$PersonalProductAliasesTableUpdateCompanionBuilder,
          (PersonalProductAliase, $$PersonalProductAliasesTableReferences),
          PersonalProductAliase,
          PrefetchHooks Function({bool productId})
        > {
  $$PersonalProductAliasesTableTableManager(
    _$AppDatabase db,
    $PersonalProductAliasesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PersonalProductAliasesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PersonalProductAliasesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PersonalProductAliasesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> productId = const Value.absent(),
                Value<String> term = const Value.absent(),
              }) => PersonalProductAliasesCompanion(
                id: id,
                productId: productId,
                term: term,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int productId,
                required String term,
              }) => PersonalProductAliasesCompanion.insert(
                id: id,
                productId: productId,
                term: term,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $PersonalProductAliasesTable,
                    PersonalProductAliase
                  >(table),
                  $$PersonalProductAliasesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({productId = false}) {
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
                    if (productId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.productId,
                        referencedTable: $$PersonalProductAliasesTableReferences
                            ._productIdTable(db),
                        referencedColumn:
                            $$PersonalProductAliasesTableReferences
                                ._productIdTable(db)
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

typedef $$PersonalProductAliasesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PersonalProductAliasesTable,
      PersonalProductAliase,
      $$PersonalProductAliasesTableFilterComposer,
      $$PersonalProductAliasesTableOrderingComposer,
      $$PersonalProductAliasesTableAnnotationComposer,
      $$PersonalProductAliasesTableCreateCompanionBuilder,
      $$PersonalProductAliasesTableUpdateCompanionBuilder,
      (PersonalProductAliase, $$PersonalProductAliasesTableReferences),
      PersonalProductAliase,
      PrefetchHooks Function({bool productId})
    >;
typedef $$ConsentRecordTableCreateCompanionBuilder =
    ConsentRecordCompanion Function({
      Value<int> id,
      required bool ageConfirmed,
      required bool consentGiven,
      required String policyVersion,
      required DateTime consentedAt,
    });
typedef $$ConsentRecordTableUpdateCompanionBuilder =
    ConsentRecordCompanion Function({
      Value<int> id,
      Value<bool> ageConfirmed,
      Value<bool> consentGiven,
      Value<String> policyVersion,
      Value<DateTime> consentedAt,
    });

class $$ConsentRecordTableFilterComposer
    extends Composer<_$AppDatabase, $ConsentRecordTable> {
  $$ConsentRecordTableFilterComposer({
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

  ColumnFilters<bool> get ageConfirmed => $composableBuilder(
    column: $table.ageConfirmed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get consentGiven => $composableBuilder(
    column: $table.consentGiven,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get policyVersion => $composableBuilder(
    column: $table.policyVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get consentedAt => $composableBuilder(
    column: $table.consentedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConsentRecordTableOrderingComposer
    extends Composer<_$AppDatabase, $ConsentRecordTable> {
  $$ConsentRecordTableOrderingComposer({
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

  ColumnOrderings<bool> get ageConfirmed => $composableBuilder(
    column: $table.ageConfirmed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get consentGiven => $composableBuilder(
    column: $table.consentGiven,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get policyVersion => $composableBuilder(
    column: $table.policyVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get consentedAt => $composableBuilder(
    column: $table.consentedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConsentRecordTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConsentRecordTable> {
  $$ConsentRecordTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get ageConfirmed => $composableBuilder(
    column: $table.ageConfirmed,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get consentGiven => $composableBuilder(
    column: $table.consentGiven,
    builder: (column) => column,
  );

  GeneratedColumn<String> get policyVersion => $composableBuilder(
    column: $table.policyVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get consentedAt => $composableBuilder(
    column: $table.consentedAt,
    builder: (column) => column,
  );
}

class $$ConsentRecordTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConsentRecordTable,
          ConsentRecordData,
          $$ConsentRecordTableFilterComposer,
          $$ConsentRecordTableOrderingComposer,
          $$ConsentRecordTableAnnotationComposer,
          $$ConsentRecordTableCreateCompanionBuilder,
          $$ConsentRecordTableUpdateCompanionBuilder,
          (
            ConsentRecordData,
            BaseReferences<
              _$AppDatabase,
              $ConsentRecordTable,
              ConsentRecordData
            >,
          ),
          ConsentRecordData,
          PrefetchHooks Function()
        > {
  $$ConsentRecordTableTableManager(_$AppDatabase db, $ConsentRecordTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConsentRecordTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConsentRecordTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConsentRecordTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> ageConfirmed = const Value.absent(),
                Value<bool> consentGiven = const Value.absent(),
                Value<String> policyVersion = const Value.absent(),
                Value<DateTime> consentedAt = const Value.absent(),
              }) => ConsentRecordCompanion(
                id: id,
                ageConfirmed: ageConfirmed,
                consentGiven: consentGiven,
                policyVersion: policyVersion,
                consentedAt: consentedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required bool ageConfirmed,
                required bool consentGiven,
                required String policyVersion,
                required DateTime consentedAt,
              }) => ConsentRecordCompanion.insert(
                id: id,
                ageConfirmed: ageConfirmed,
                consentGiven: consentGiven,
                policyVersion: policyVersion,
                consentedAt: consentedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ConsentRecordTable, ConsentRecordData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ConsentRecordTable,
                    ConsentRecordData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConsentRecordTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConsentRecordTable,
      ConsentRecordData,
      $$ConsentRecordTableFilterComposer,
      $$ConsentRecordTableOrderingComposer,
      $$ConsentRecordTableAnnotationComposer,
      $$ConsentRecordTableCreateCompanionBuilder,
      $$ConsentRecordTableUpdateCompanionBuilder,
      (
        ConsentRecordData,
        BaseReferences<_$AppDatabase, $ConsentRecordTable, ConsentRecordData>,
      ),
      ConsentRecordData,
      PrefetchHooks Function()
    >;
typedef $$UserProfileTableCreateCompanionBuilder =
    UserProfileCompanion Function({
      Value<int> id,
      required String sex,
      required DateTime birthDate,
      required double heightCm,
      required double weightKg,
      required String activityLevel,
      Value<double?> measuredMaintenanceKcal,
      required DateTime updatedAt,
    });
typedef $$UserProfileTableUpdateCompanionBuilder =
    UserProfileCompanion Function({
      Value<int> id,
      Value<String> sex,
      Value<DateTime> birthDate,
      Value<double> heightCm,
      Value<double> weightKg,
      Value<String> activityLevel,
      Value<double?> measuredMaintenanceKcal,
      Value<DateTime> updatedAt,
    });

class $$UserProfileTableFilterComposer
    extends Composer<_$AppDatabase, $UserProfileTable> {
  $$UserProfileTableFilterComposer({
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

  ColumnFilters<String> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get birthDate => $composableBuilder(
    column: $table.birthDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activityLevel => $composableBuilder(
    column: $table.activityLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get measuredMaintenanceKcal => $composableBuilder(
    column: $table.measuredMaintenanceKcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserProfileTableOrderingComposer
    extends Composer<_$AppDatabase, $UserProfileTable> {
  $$UserProfileTableOrderingComposer({
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

  ColumnOrderings<String> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get birthDate => $composableBuilder(
    column: $table.birthDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityLevel => $composableBuilder(
    column: $table.activityLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get measuredMaintenanceKcal => $composableBuilder(
    column: $table.measuredMaintenanceKcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserProfileTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserProfileTable> {
  $$UserProfileTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sex =>
      $composableBuilder(column: $table.sex, builder: (column) => column);

  GeneratedColumn<DateTime> get birthDate =>
      $composableBuilder(column: $table.birthDate, builder: (column) => column);

  GeneratedColumn<double> get heightCm =>
      $composableBuilder(column: $table.heightCm, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<String> get activityLevel => $composableBuilder(
    column: $table.activityLevel,
    builder: (column) => column,
  );

  GeneratedColumn<double> get measuredMaintenanceKcal => $composableBuilder(
    column: $table.measuredMaintenanceKcal,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UserProfileTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserProfileTable,
          UserProfileData,
          $$UserProfileTableFilterComposer,
          $$UserProfileTableOrderingComposer,
          $$UserProfileTableAnnotationComposer,
          $$UserProfileTableCreateCompanionBuilder,
          $$UserProfileTableUpdateCompanionBuilder,
          (
            UserProfileData,
            BaseReferences<_$AppDatabase, $UserProfileTable, UserProfileData>,
          ),
          UserProfileData,
          PrefetchHooks Function()
        > {
  $$UserProfileTableTableManager(_$AppDatabase db, $UserProfileTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserProfileTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserProfileTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserProfileTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sex = const Value.absent(),
                Value<DateTime> birthDate = const Value.absent(),
                Value<double> heightCm = const Value.absent(),
                Value<double> weightKg = const Value.absent(),
                Value<String> activityLevel = const Value.absent(),
                Value<double?> measuredMaintenanceKcal = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => UserProfileCompanion(
                id: id,
                sex: sex,
                birthDate: birthDate,
                heightCm: heightCm,
                weightKg: weightKg,
                activityLevel: activityLevel,
                measuredMaintenanceKcal: measuredMaintenanceKcal,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sex,
                required DateTime birthDate,
                required double heightCm,
                required double weightKg,
                required String activityLevel,
                Value<double?> measuredMaintenanceKcal = const Value.absent(),
                required DateTime updatedAt,
              }) => UserProfileCompanion.insert(
                id: id,
                sex: sex,
                birthDate: birthDate,
                heightCm: heightCm,
                weightKg: weightKg,
                activityLevel: activityLevel,
                measuredMaintenanceKcal: measuredMaintenanceKcal,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UserProfileTable, UserProfileData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $UserProfileTable,
                    UserProfileData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserProfileTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserProfileTable,
      UserProfileData,
      $$UserProfileTableFilterComposer,
      $$UserProfileTableOrderingComposer,
      $$UserProfileTableAnnotationComposer,
      $$UserProfileTableCreateCompanionBuilder,
      $$UserProfileTableUpdateCompanionBuilder,
      (
        UserProfileData,
        BaseReferences<_$AppDatabase, $UserProfileTable, UserProfileData>,
      ),
      UserProfileData,
      PrefetchHooks Function()
    >;
typedef $$NutritionGoalsTableCreateCompanionBuilder =
    NutritionGoalsCompanion Function({
      Value<int> id,
      required String objective,
      required bool isManual,
      required double energyKcal,
      required double proteinG,
      required double carbsG,
      required double fatG,
      required DateTime updatedAt,
    });
typedef $$NutritionGoalsTableUpdateCompanionBuilder =
    NutritionGoalsCompanion Function({
      Value<int> id,
      Value<String> objective,
      Value<bool> isManual,
      Value<double> energyKcal,
      Value<double> proteinG,
      Value<double> carbsG,
      Value<double> fatG,
      Value<DateTime> updatedAt,
    });

class $$NutritionGoalsTableFilterComposer
    extends Composer<_$AppDatabase, $NutritionGoalsTable> {
  $$NutritionGoalsTableFilterComposer({
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

  ColumnFilters<String> get objective => $composableBuilder(
    column: $table.objective,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isManual => $composableBuilder(
    column: $table.isManual,
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

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NutritionGoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $NutritionGoalsTable> {
  $$NutritionGoalsTableOrderingComposer({
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

  ColumnOrderings<String> get objective => $composableBuilder(
    column: $table.objective,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isManual => $composableBuilder(
    column: $table.isManual,
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

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NutritionGoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NutritionGoalsTable> {
  $$NutritionGoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get objective =>
      $composableBuilder(column: $table.objective, builder: (column) => column);

  GeneratedColumn<bool> get isManual =>
      $composableBuilder(column: $table.isManual, builder: (column) => column);

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

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$NutritionGoalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NutritionGoalsTable,
          NutritionGoal,
          $$NutritionGoalsTableFilterComposer,
          $$NutritionGoalsTableOrderingComposer,
          $$NutritionGoalsTableAnnotationComposer,
          $$NutritionGoalsTableCreateCompanionBuilder,
          $$NutritionGoalsTableUpdateCompanionBuilder,
          (
            NutritionGoal,
            BaseReferences<_$AppDatabase, $NutritionGoalsTable, NutritionGoal>,
          ),
          NutritionGoal,
          PrefetchHooks Function()
        > {
  $$NutritionGoalsTableTableManager(
    _$AppDatabase db,
    $NutritionGoalsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NutritionGoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NutritionGoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NutritionGoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> objective = const Value.absent(),
                Value<bool> isManual = const Value.absent(),
                Value<double> energyKcal = const Value.absent(),
                Value<double> proteinG = const Value.absent(),
                Value<double> carbsG = const Value.absent(),
                Value<double> fatG = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => NutritionGoalsCompanion(
                id: id,
                objective: objective,
                isManual: isManual,
                energyKcal: energyKcal,
                proteinG: proteinG,
                carbsG: carbsG,
                fatG: fatG,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String objective,
                required bool isManual,
                required double energyKcal,
                required double proteinG,
                required double carbsG,
                required double fatG,
                required DateTime updatedAt,
              }) => NutritionGoalsCompanion.insert(
                id: id,
                objective: objective,
                isManual: isManual,
                energyKcal: energyKcal,
                proteinG: proteinG,
                carbsG: carbsG,
                fatG: fatG,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NutritionGoalsTable, NutritionGoal>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $NutritionGoalsTable,
                    NutritionGoal
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NutritionGoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NutritionGoalsTable,
      NutritionGoal,
      $$NutritionGoalsTableFilterComposer,
      $$NutritionGoalsTableOrderingComposer,
      $$NutritionGoalsTableAnnotationComposer,
      $$NutritionGoalsTableCreateCompanionBuilder,
      $$NutritionGoalsTableUpdateCompanionBuilder,
      (
        NutritionGoal,
        BaseReferences<_$AppDatabase, $NutritionGoalsTable, NutritionGoal>,
      ),
      NutritionGoal,
      PrefetchHooks Function()
    >;
typedef $$WeightLogTableCreateCompanionBuilder = WeightLogCompanion Function({
  required DateTime day,
  required double weightKg,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$WeightLogTableUpdateCompanionBuilder = WeightLogCompanion Function({
  Value<DateTime> day,
  Value<double> weightKg,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$WeightLogTableFilterComposer
    extends Composer<_$AppDatabase, $WeightLogTable> {
  $$WeightLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeightLogTableOrderingComposer
    extends Composer<_$AppDatabase, $WeightLogTable> {
  $$WeightLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeightLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeightLogTable> {
  $$WeightLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$WeightLogTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeightLogTable,
          WeightLogData,
          $$WeightLogTableFilterComposer,
          $$WeightLogTableOrderingComposer,
          $$WeightLogTableAnnotationComposer,
          $$WeightLogTableCreateCompanionBuilder,
          $$WeightLogTableUpdateCompanionBuilder,
          (
            WeightLogData,
            BaseReferences<_$AppDatabase, $WeightLogTable, WeightLogData>,
          ),
          WeightLogData,
          PrefetchHooks Function()
        > {
  $$WeightLogTableTableManager(_$AppDatabase db, $WeightLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeightLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeightLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeightLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> day = const Value.absent(),
                Value<double> weightKg = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeightLogCompanion(
                day: day,
                weightKg: weightKg,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required DateTime day,
                required double weightKg,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => WeightLogCompanion.insert(
                day: day,
                weightKg: weightKg,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WeightLogTable, WeightLogData>(table),
                  BaseReferences<_$AppDatabase, $WeightLogTable, WeightLogData>(
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

typedef $$WeightLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeightLogTable,
      WeightLogData,
      $$WeightLogTableFilterComposer,
      $$WeightLogTableOrderingComposer,
      $$WeightLogTableAnnotationComposer,
      $$WeightLogTableCreateCompanionBuilder,
      $$WeightLogTableUpdateCompanionBuilder,
      (
        WeightLogData,
        BaseReferences<_$AppDatabase, $WeightLogTable, WeightLogData>,
      ),
      WeightLogData,
      PrefetchHooks Function()
    >;
typedef $$FavoriteMealsTableCreateCompanionBuilder =
    FavoriteMealsCompanion Function({
      Value<int> id,
      required String name,
      Value<DateTime> createdAt,
    });
typedef $$FavoriteMealsTableUpdateCompanionBuilder =
    FavoriteMealsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<DateTime> createdAt,
    });

final class $$FavoriteMealsTableReferences
    extends BaseReferences<_$AppDatabase, $FavoriteMealsTable, FavoriteMeal> {
  $$FavoriteMealsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$FavoriteMealItemsTable, List<FavoriteMealItem>>
  _favoriteMealItemsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.favoriteMealItems,
        aliasName: 'favorite_meals__id__favorite_meal_items__favorite_id',
      );

  $$FavoriteMealItemsTableProcessedTableManager get favoriteMealItemsRefs {
    final manager = $$FavoriteMealItemsTableTableManager(
      $_db,
      $_db.favoriteMealItems,
    ).filter((f) => f.favoriteId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _favoriteMealItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FavoriteMealsTableFilterComposer
    extends Composer<_$AppDatabase, $FavoriteMealsTable> {
  $$FavoriteMealsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> favoriteMealItemsRefs(
    Expression<bool> Function($$FavoriteMealItemsTableFilterComposer f) f,
  ) {
    final $$FavoriteMealItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.favoriteMealItems,
      getReferencedColumn: (t) => t.favoriteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoriteMealItemsTableFilterComposer(
            $db: $db,
            $table: $db.favoriteMealItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FavoriteMealsTableOrderingComposer
    extends Composer<_$AppDatabase, $FavoriteMealsTable> {
  $$FavoriteMealsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FavoriteMealsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavoriteMealsTable> {
  $$FavoriteMealsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> favoriteMealItemsRefs<T extends Object>(
    Expression<T> Function($$FavoriteMealItemsTableAnnotationComposer a) f,
  ) {
    final $$FavoriteMealItemsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.favoriteMealItems,
          getReferencedColumn: (t) => t.favoriteId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FavoriteMealItemsTableAnnotationComposer(
                $db: $db,
                $table: $db.favoriteMealItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$FavoriteMealsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FavoriteMealsTable,
          FavoriteMeal,
          $$FavoriteMealsTableFilterComposer,
          $$FavoriteMealsTableOrderingComposer,
          $$FavoriteMealsTableAnnotationComposer,
          $$FavoriteMealsTableCreateCompanionBuilder,
          $$FavoriteMealsTableUpdateCompanionBuilder,
          (FavoriteMeal, $$FavoriteMealsTableReferences),
          FavoriteMeal,
          PrefetchHooks Function({bool favoriteMealItemsRefs})
        > {
  $$FavoriteMealsTableTableManager(_$AppDatabase db, $FavoriteMealsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoriteMealsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoriteMealsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoriteMealsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => FavoriteMealsCompanion(
                id: id,
                name: name,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<DateTime> createdAt = const Value.absent(),
              }) => FavoriteMealsCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FavoriteMealsTable, FavoriteMeal>(table),
                  $$FavoriteMealsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({favoriteMealItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (favoriteMealItemsRefs) db.favoriteMealItems,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (favoriteMealItemsRefs)
                    await $_getPrefetchedData<
                      FavoriteMeal,
                      $FavoriteMealsTable,
                      FavoriteMealItem
                    >(
                      currentTable: table,
                      referencedTable: $$FavoriteMealsTableReferences
                          ._favoriteMealItemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$FavoriteMealsTableReferences(
                            db,
                            table,
                            p0,
                          ).favoriteMealItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.favoriteId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$FavoriteMealsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FavoriteMealsTable,
      FavoriteMeal,
      $$FavoriteMealsTableFilterComposer,
      $$FavoriteMealsTableOrderingComposer,
      $$FavoriteMealsTableAnnotationComposer,
      $$FavoriteMealsTableCreateCompanionBuilder,
      $$FavoriteMealsTableUpdateCompanionBuilder,
      (FavoriteMeal, $$FavoriteMealsTableReferences),
      FavoriteMeal,
      PrefetchHooks Function({bool favoriteMealItemsRefs})
    >;
typedef $$FavoriteMealItemsTableCreateCompanionBuilder =
    FavoriteMealItemsCompanion Function({
      Value<int> id,
      required int favoriteId,
      required int position,
      required String foodId,
      required String mention,
      required double grams,
      Value<double?> quantityInput,
      Value<String?> unitInput,
      Value<String?> sizeInput,
      required String quantityBasis,
      required String confidence,
    });
typedef $$FavoriteMealItemsTableUpdateCompanionBuilder =
    FavoriteMealItemsCompanion Function({
      Value<int> id,
      Value<int> favoriteId,
      Value<int> position,
      Value<String> foodId,
      Value<String> mention,
      Value<double> grams,
      Value<double?> quantityInput,
      Value<String?> unitInput,
      Value<String?> sizeInput,
      Value<String> quantityBasis,
      Value<String> confidence,
    });

final class $$FavoriteMealItemsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $FavoriteMealItemsTable,
          FavoriteMealItem
        > {
  $$FavoriteMealItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $FavoriteMealsTable _favoriteIdTable(_$AppDatabase db) => db
      .favoriteMeals
      .createAlias('favorite_meal_items__favorite_id__favorite_meals__id');

  $$FavoriteMealsTableProcessedTableManager get favoriteId {
    final $_column = $_itemColumn<int>('favorite_id')!;

    final manager = $$FavoriteMealsTableTableManager(
      $_db,
      $_db.favoriteMeals,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_favoriteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FavoriteMealItemsTableFilterComposer
    extends Composer<_$AppDatabase, $FavoriteMealItemsTable> {
  $$FavoriteMealItemsTableFilterComposer({
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

  ColumnFilters<String> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mention => $composableBuilder(
    column: $table.mention,
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

  ColumnFilters<String> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  $$FavoriteMealsTableFilterComposer get favoriteId {
    final $$FavoriteMealsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.favoriteId,
      referencedTable: $db.favoriteMeals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoriteMealsTableFilterComposer(
            $db: $db,
            $table: $db.favoriteMeals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoriteMealItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $FavoriteMealItemsTable> {
  $$FavoriteMealItemsTableOrderingComposer({
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

  ColumnOrderings<String> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mention => $composableBuilder(
    column: $table.mention,
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

  ColumnOrderings<String> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  $$FavoriteMealsTableOrderingComposer get favoriteId {
    final $$FavoriteMealsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.favoriteId,
      referencedTable: $db.favoriteMeals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoriteMealsTableOrderingComposer(
            $db: $db,
            $table: $db.favoriteMeals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoriteMealItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavoriteMealItemsTable> {
  $$FavoriteMealItemsTableAnnotationComposer({
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

  GeneratedColumn<String> get foodId =>
      $composableBuilder(column: $table.foodId, builder: (column) => column);

  GeneratedColumn<String> get mention =>
      $composableBuilder(column: $table.mention, builder: (column) => column);

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

  GeneratedColumn<String> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  $$FavoriteMealsTableAnnotationComposer get favoriteId {
    final $$FavoriteMealsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.favoriteId,
      referencedTable: $db.favoriteMeals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoriteMealsTableAnnotationComposer(
            $db: $db,
            $table: $db.favoriteMeals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoriteMealItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FavoriteMealItemsTable,
          FavoriteMealItem,
          $$FavoriteMealItemsTableFilterComposer,
          $$FavoriteMealItemsTableOrderingComposer,
          $$FavoriteMealItemsTableAnnotationComposer,
          $$FavoriteMealItemsTableCreateCompanionBuilder,
          $$FavoriteMealItemsTableUpdateCompanionBuilder,
          (FavoriteMealItem, $$FavoriteMealItemsTableReferences),
          FavoriteMealItem,
          PrefetchHooks Function({bool favoriteId})
        > {
  $$FavoriteMealItemsTableTableManager(
    _$AppDatabase db,
    $FavoriteMealItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoriteMealItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoriteMealItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoriteMealItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> favoriteId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> foodId = const Value.absent(),
                Value<String> mention = const Value.absent(),
                Value<double> grams = const Value.absent(),
                Value<double?> quantityInput = const Value.absent(),
                Value<String?> unitInput = const Value.absent(),
                Value<String?> sizeInput = const Value.absent(),
                Value<String> quantityBasis = const Value.absent(),
                Value<String> confidence = const Value.absent(),
              }) => FavoriteMealItemsCompanion(
                id: id,
                favoriteId: favoriteId,
                position: position,
                foodId: foodId,
                mention: mention,
                grams: grams,
                quantityInput: quantityInput,
                unitInput: unitInput,
                sizeInput: sizeInput,
                quantityBasis: quantityBasis,
                confidence: confidence,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int favoriteId,
                required int position,
                required String foodId,
                required String mention,
                required double grams,
                Value<double?> quantityInput = const Value.absent(),
                Value<String?> unitInput = const Value.absent(),
                Value<String?> sizeInput = const Value.absent(),
                required String quantityBasis,
                required String confidence,
              }) => FavoriteMealItemsCompanion.insert(
                id: id,
                favoriteId: favoriteId,
                position: position,
                foodId: foodId,
                mention: mention,
                grams: grams,
                quantityInput: quantityInput,
                unitInput: unitInput,
                sizeInput: sizeInput,
                quantityBasis: quantityBasis,
                confidence: confidence,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FavoriteMealItemsTable, FavoriteMealItem>(table),
                  $$FavoriteMealItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({favoriteId = false}) {
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
                    if (favoriteId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.favoriteId,
                        referencedTable: $$FavoriteMealItemsTableReferences
                            ._favoriteIdTable(db),
                        referencedColumn: $$FavoriteMealItemsTableReferences
                            ._favoriteIdTable(db)
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

typedef $$FavoriteMealItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FavoriteMealItemsTable,
      FavoriteMealItem,
      $$FavoriteMealItemsTableFilterComposer,
      $$FavoriteMealItemsTableOrderingComposer,
      $$FavoriteMealItemsTableAnnotationComposer,
      $$FavoriteMealItemsTableCreateCompanionBuilder,
      $$FavoriteMealItemsTableUpdateCompanionBuilder,
      (FavoriteMealItem, $$FavoriteMealItemsTableReferences),
      FavoriteMealItem,
      PrefetchHooks Function({bool favoriteId})
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
  $$PersonalProductAliasesTableTableManager get personalProductAliases =>
      $$PersonalProductAliasesTableTableManager(
        _db,
        _db.personalProductAliases,
      );
  $$ConsentRecordTableTableManager get consentRecord =>
      $$ConsentRecordTableTableManager(_db, _db.consentRecord);
  $$UserProfileTableTableManager get userProfile =>
      $$UserProfileTableTableManager(_db, _db.userProfile);
  $$NutritionGoalsTableTableManager get nutritionGoals =>
      $$NutritionGoalsTableTableManager(_db, _db.nutritionGoals);
  $$WeightLogTableTableManager get weightLog =>
      $$WeightLogTableTableManager(_db, _db.weightLog);
  $$FavoriteMealsTableTableManager get favoriteMeals =>
      $$FavoriteMealsTableTableManager(_db, _db.favoriteMeals);
  $$FavoriteMealItemsTableTableManager get favoriteMealItems =>
      $$FavoriteMealItemsTableTableManager(_db, _db.favoriteMealItems);
}
