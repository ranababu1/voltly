// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ChargingSessionsTable extends ChargingSessions
    with TableInfo<$ChargingSessionsTable, ChargingSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChargingSessionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastObservedAtMeta = const VerificationMeta(
    'lastObservedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastObservedAt =
      GeneratedColumn<DateTime>(
        'last_observed_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _startLevelPercentMeta = const VerificationMeta(
    'startLevelPercent',
  );
  @override
  late final GeneratedColumn<double> startLevelPercent =
      GeneratedColumn<double>(
        'start_level_percent',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _endLevelPercentMeta = const VerificationMeta(
    'endLevelPercent',
  );
  @override
  late final GeneratedColumn<double> endLevelPercent = GeneratedColumn<double>(
    'end_level_percent',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ChargingSessionState, String>
  sessionState =
      GeneratedColumn<String>(
        'session_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ChargingSessionState>(
        $ChargingSessionsTable.$convertersessionState,
      );
  static const VerificationMeta _sampleCountMeta = const VerificationMeta(
    'sampleCount',
  );
  @override
  late final GeneratedColumn<int> sampleCount = GeneratedColumn<int>(
    'sample_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _maxSamplingGapMsMeta = const VerificationMeta(
    'maxSamplingGapMs',
  );
  @override
  late final GeneratedColumn<int> maxSamplingGapMs = GeneratedColumn<int>(
    'max_sampling_gap_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hasSamplingGapsMeta = const VerificationMeta(
    'hasSamplingGaps',
  );
  @override
  late final GeneratedColumn<bool> hasSamplingGaps = GeneratedColumn<bool>(
    'has_sampling_gaps',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_sampling_gaps" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _samplesPrunedMeta = const VerificationMeta(
    'samplesPruned',
  );
  @override
  late final GeneratedColumn<bool> samplesPruned = GeneratedColumn<bool>(
    'samples_pruned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("samples_pruned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    startedAt,
    endedAt,
    lastObservedAt,
    startLevelPercent,
    endLevelPercent,
    sessionState,
    sampleCount,
    maxSamplingGapMs,
    hasSamplingGaps,
    samplesPruned,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'charging_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChargingSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('last_observed_at')) {
      context.handle(
        _lastObservedAtMeta,
        lastObservedAt.isAcceptableOrUnknown(
          data['last_observed_at']!,
          _lastObservedAtMeta,
        ),
      );
    }
    if (data.containsKey('start_level_percent')) {
      context.handle(
        _startLevelPercentMeta,
        startLevelPercent.isAcceptableOrUnknown(
          data['start_level_percent']!,
          _startLevelPercentMeta,
        ),
      );
    }
    if (data.containsKey('end_level_percent')) {
      context.handle(
        _endLevelPercentMeta,
        endLevelPercent.isAcceptableOrUnknown(
          data['end_level_percent']!,
          _endLevelPercentMeta,
        ),
      );
    }
    if (data.containsKey('sample_count')) {
      context.handle(
        _sampleCountMeta,
        sampleCount.isAcceptableOrUnknown(
          data['sample_count']!,
          _sampleCountMeta,
        ),
      );
    }
    if (data.containsKey('max_sampling_gap_ms')) {
      context.handle(
        _maxSamplingGapMsMeta,
        maxSamplingGapMs.isAcceptableOrUnknown(
          data['max_sampling_gap_ms']!,
          _maxSamplingGapMsMeta,
        ),
      );
    }
    if (data.containsKey('has_sampling_gaps')) {
      context.handle(
        _hasSamplingGapsMeta,
        hasSamplingGaps.isAcceptableOrUnknown(
          data['has_sampling_gaps']!,
          _hasSamplingGapsMeta,
        ),
      );
    }
    if (data.containsKey('samples_pruned')) {
      context.handle(
        _samplesPrunedMeta,
        samplesPruned.isAcceptableOrUnknown(
          data['samples_pruned']!,
          _samplesPrunedMeta,
        ),
      );
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
  ChargingSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChargingSessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      lastObservedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_observed_at'],
      ),
      startLevelPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}start_level_percent'],
      ),
      endLevelPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}end_level_percent'],
      ),
      sessionState: $ChargingSessionsTable.$convertersessionState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}session_state'],
        )!,
      ),
      sampleCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sample_count'],
      )!,
      maxSamplingGapMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_sampling_gap_ms'],
      ),
      hasSamplingGaps: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_sampling_gaps'],
      )!,
      samplesPruned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}samples_pruned'],
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
  $ChargingSessionsTable createAlias(String alias) {
    return $ChargingSessionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ChargingSessionState, String, String>
  $convertersessionState = const EnumNameConverter<ChargingSessionState>(
    ChargingSessionState.values,
  );
}

class ChargingSessionRow extends DataClass
    implements Insertable<ChargingSessionRow> {
  final int id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final DateTime? lastObservedAt;
  final double? startLevelPercent;
  final double? endLevelPercent;
  final ChargingSessionState sessionState;
  final int sampleCount;
  final int? maxSamplingGapMs;
  final bool hasSamplingGaps;
  final bool samplesPruned;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ChargingSessionRow({
    required this.id,
    required this.startedAt,
    this.endedAt,
    this.lastObservedAt,
    this.startLevelPercent,
    this.endLevelPercent,
    required this.sessionState,
    required this.sampleCount,
    this.maxSamplingGapMs,
    required this.hasSamplingGaps,
    required this.samplesPruned,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    if (!nullToAbsent || lastObservedAt != null) {
      map['last_observed_at'] = Variable<DateTime>(lastObservedAt);
    }
    if (!nullToAbsent || startLevelPercent != null) {
      map['start_level_percent'] = Variable<double>(startLevelPercent);
    }
    if (!nullToAbsent || endLevelPercent != null) {
      map['end_level_percent'] = Variable<double>(endLevelPercent);
    }
    {
      map['session_state'] = Variable<String>(
        $ChargingSessionsTable.$convertersessionState.toSql(sessionState),
      );
    }
    map['sample_count'] = Variable<int>(sampleCount);
    if (!nullToAbsent || maxSamplingGapMs != null) {
      map['max_sampling_gap_ms'] = Variable<int>(maxSamplingGapMs);
    }
    map['has_sampling_gaps'] = Variable<bool>(hasSamplingGaps);
    map['samples_pruned'] = Variable<bool>(samplesPruned);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ChargingSessionsCompanion toCompanion(bool nullToAbsent) {
    return ChargingSessionsCompanion(
      id: Value(id),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      lastObservedAt: lastObservedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastObservedAt),
      startLevelPercent: startLevelPercent == null && nullToAbsent
          ? const Value.absent()
          : Value(startLevelPercent),
      endLevelPercent: endLevelPercent == null && nullToAbsent
          ? const Value.absent()
          : Value(endLevelPercent),
      sessionState: Value(sessionState),
      sampleCount: Value(sampleCount),
      maxSamplingGapMs: maxSamplingGapMs == null && nullToAbsent
          ? const Value.absent()
          : Value(maxSamplingGapMs),
      hasSamplingGaps: Value(hasSamplingGaps),
      samplesPruned: Value(samplesPruned),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ChargingSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChargingSessionRow(
      id: serializer.fromJson<int>(json['id']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      lastObservedAt: serializer.fromJson<DateTime?>(json['lastObservedAt']),
      startLevelPercent: serializer.fromJson<double?>(
        json['startLevelPercent'],
      ),
      endLevelPercent: serializer.fromJson<double?>(json['endLevelPercent']),
      sessionState: $ChargingSessionsTable.$convertersessionState.fromJson(
        serializer.fromJson<String>(json['sessionState']),
      ),
      sampleCount: serializer.fromJson<int>(json['sampleCount']),
      maxSamplingGapMs: serializer.fromJson<int?>(json['maxSamplingGapMs']),
      hasSamplingGaps: serializer.fromJson<bool>(json['hasSamplingGaps']),
      samplesPruned: serializer.fromJson<bool>(json['samplesPruned']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'lastObservedAt': serializer.toJson<DateTime?>(lastObservedAt),
      'startLevelPercent': serializer.toJson<double?>(startLevelPercent),
      'endLevelPercent': serializer.toJson<double?>(endLevelPercent),
      'sessionState': serializer.toJson<String>(
        $ChargingSessionsTable.$convertersessionState.toJson(sessionState),
      ),
      'sampleCount': serializer.toJson<int>(sampleCount),
      'maxSamplingGapMs': serializer.toJson<int?>(maxSamplingGapMs),
      'hasSamplingGaps': serializer.toJson<bool>(hasSamplingGaps),
      'samplesPruned': serializer.toJson<bool>(samplesPruned),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ChargingSessionRow copyWith({
    int? id,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    Value<DateTime?> lastObservedAt = const Value.absent(),
    Value<double?> startLevelPercent = const Value.absent(),
    Value<double?> endLevelPercent = const Value.absent(),
    ChargingSessionState? sessionState,
    int? sampleCount,
    Value<int?> maxSamplingGapMs = const Value.absent(),
    bool? hasSamplingGaps,
    bool? samplesPruned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ChargingSessionRow(
    id: id ?? this.id,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    lastObservedAt: lastObservedAt.present
        ? lastObservedAt.value
        : this.lastObservedAt,
    startLevelPercent: startLevelPercent.present
        ? startLevelPercent.value
        : this.startLevelPercent,
    endLevelPercent: endLevelPercent.present
        ? endLevelPercent.value
        : this.endLevelPercent,
    sessionState: sessionState ?? this.sessionState,
    sampleCount: sampleCount ?? this.sampleCount,
    maxSamplingGapMs: maxSamplingGapMs.present
        ? maxSamplingGapMs.value
        : this.maxSamplingGapMs,
    hasSamplingGaps: hasSamplingGaps ?? this.hasSamplingGaps,
    samplesPruned: samplesPruned ?? this.samplesPruned,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ChargingSessionRow copyWithCompanion(ChargingSessionsCompanion data) {
    return ChargingSessionRow(
      id: data.id.present ? data.id.value : this.id,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      lastObservedAt: data.lastObservedAt.present
          ? data.lastObservedAt.value
          : this.lastObservedAt,
      startLevelPercent: data.startLevelPercent.present
          ? data.startLevelPercent.value
          : this.startLevelPercent,
      endLevelPercent: data.endLevelPercent.present
          ? data.endLevelPercent.value
          : this.endLevelPercent,
      sessionState: data.sessionState.present
          ? data.sessionState.value
          : this.sessionState,
      sampleCount: data.sampleCount.present
          ? data.sampleCount.value
          : this.sampleCount,
      maxSamplingGapMs: data.maxSamplingGapMs.present
          ? data.maxSamplingGapMs.value
          : this.maxSamplingGapMs,
      hasSamplingGaps: data.hasSamplingGaps.present
          ? data.hasSamplingGaps.value
          : this.hasSamplingGaps,
      samplesPruned: data.samplesPruned.present
          ? data.samplesPruned.value
          : this.samplesPruned,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChargingSessionRow(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('lastObservedAt: $lastObservedAt, ')
          ..write('startLevelPercent: $startLevelPercent, ')
          ..write('endLevelPercent: $endLevelPercent, ')
          ..write('sessionState: $sessionState, ')
          ..write('sampleCount: $sampleCount, ')
          ..write('maxSamplingGapMs: $maxSamplingGapMs, ')
          ..write('hasSamplingGaps: $hasSamplingGaps, ')
          ..write('samplesPruned: $samplesPruned, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    startedAt,
    endedAt,
    lastObservedAt,
    startLevelPercent,
    endLevelPercent,
    sessionState,
    sampleCount,
    maxSamplingGapMs,
    hasSamplingGaps,
    samplesPruned,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChargingSessionRow &&
          other.id == this.id &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.lastObservedAt == this.lastObservedAt &&
          other.startLevelPercent == this.startLevelPercent &&
          other.endLevelPercent == this.endLevelPercent &&
          other.sessionState == this.sessionState &&
          other.sampleCount == this.sampleCount &&
          other.maxSamplingGapMs == this.maxSamplingGapMs &&
          other.hasSamplingGaps == this.hasSamplingGaps &&
          other.samplesPruned == this.samplesPruned &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ChargingSessionsCompanion extends UpdateCompanion<ChargingSessionRow> {
  final Value<int> id;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<DateTime?> lastObservedAt;
  final Value<double?> startLevelPercent;
  final Value<double?> endLevelPercent;
  final Value<ChargingSessionState> sessionState;
  final Value<int> sampleCount;
  final Value<int?> maxSamplingGapMs;
  final Value<bool> hasSamplingGaps;
  final Value<bool> samplesPruned;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ChargingSessionsCompanion({
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.lastObservedAt = const Value.absent(),
    this.startLevelPercent = const Value.absent(),
    this.endLevelPercent = const Value.absent(),
    this.sessionState = const Value.absent(),
    this.sampleCount = const Value.absent(),
    this.maxSamplingGapMs = const Value.absent(),
    this.hasSamplingGaps = const Value.absent(),
    this.samplesPruned = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ChargingSessionsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.lastObservedAt = const Value.absent(),
    this.startLevelPercent = const Value.absent(),
    this.endLevelPercent = const Value.absent(),
    required ChargingSessionState sessionState,
    this.sampleCount = const Value.absent(),
    this.maxSamplingGapMs = const Value.absent(),
    this.hasSamplingGaps = const Value.absent(),
    this.samplesPruned = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : startedAt = Value(startedAt),
       sessionState = Value(sessionState);
  static Insertable<ChargingSessionRow> custom({
    Expression<int>? id,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<DateTime>? lastObservedAt,
    Expression<double>? startLevelPercent,
    Expression<double>? endLevelPercent,
    Expression<String>? sessionState,
    Expression<int>? sampleCount,
    Expression<int>? maxSamplingGapMs,
    Expression<bool>? hasSamplingGaps,
    Expression<bool>? samplesPruned,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (lastObservedAt != null) 'last_observed_at': lastObservedAt,
      if (startLevelPercent != null) 'start_level_percent': startLevelPercent,
      if (endLevelPercent != null) 'end_level_percent': endLevelPercent,
      if (sessionState != null) 'session_state': sessionState,
      if (sampleCount != null) 'sample_count': sampleCount,
      if (maxSamplingGapMs != null) 'max_sampling_gap_ms': maxSamplingGapMs,
      if (hasSamplingGaps != null) 'has_sampling_gaps': hasSamplingGaps,
      if (samplesPruned != null) 'samples_pruned': samplesPruned,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ChargingSessionsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<DateTime?>? lastObservedAt,
    Value<double?>? startLevelPercent,
    Value<double?>? endLevelPercent,
    Value<ChargingSessionState>? sessionState,
    Value<int>? sampleCount,
    Value<int?>? maxSamplingGapMs,
    Value<bool>? hasSamplingGaps,
    Value<bool>? samplesPruned,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return ChargingSessionsCompanion(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      lastObservedAt: lastObservedAt ?? this.lastObservedAt,
      startLevelPercent: startLevelPercent ?? this.startLevelPercent,
      endLevelPercent: endLevelPercent ?? this.endLevelPercent,
      sessionState: sessionState ?? this.sessionState,
      sampleCount: sampleCount ?? this.sampleCount,
      maxSamplingGapMs: maxSamplingGapMs ?? this.maxSamplingGapMs,
      hasSamplingGaps: hasSamplingGaps ?? this.hasSamplingGaps,
      samplesPruned: samplesPruned ?? this.samplesPruned,
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
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (lastObservedAt.present) {
      map['last_observed_at'] = Variable<DateTime>(lastObservedAt.value);
    }
    if (startLevelPercent.present) {
      map['start_level_percent'] = Variable<double>(startLevelPercent.value);
    }
    if (endLevelPercent.present) {
      map['end_level_percent'] = Variable<double>(endLevelPercent.value);
    }
    if (sessionState.present) {
      map['session_state'] = Variable<String>(
        $ChargingSessionsTable.$convertersessionState.toSql(sessionState.value),
      );
    }
    if (sampleCount.present) {
      map['sample_count'] = Variable<int>(sampleCount.value);
    }
    if (maxSamplingGapMs.present) {
      map['max_sampling_gap_ms'] = Variable<int>(maxSamplingGapMs.value);
    }
    if (hasSamplingGaps.present) {
      map['has_sampling_gaps'] = Variable<bool>(hasSamplingGaps.value);
    }
    if (samplesPruned.present) {
      map['samples_pruned'] = Variable<bool>(samplesPruned.value);
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
    return (StringBuffer('ChargingSessionsCompanion(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('lastObservedAt: $lastObservedAt, ')
          ..write('startLevelPercent: $startLevelPercent, ')
          ..write('endLevelPercent: $endLevelPercent, ')
          ..write('sessionState: $sessionState, ')
          ..write('sampleCount: $sampleCount, ')
          ..write('maxSamplingGapMs: $maxSamplingGapMs, ')
          ..write('hasSamplingGaps: $hasSamplingGaps, ')
          ..write('samplesPruned: $samplesPruned, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TelemetrySamplesTable extends TelemetrySamples
    with TableInfo<$TelemetrySamplesTable, TelemetrySampleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TelemetrySamplesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES charging_sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _observedAtMeta = const VerificationMeta(
    'observedAt',
  );
  @override
  late final GeneratedColumn<DateTime> observedAt = GeneratedColumn<DateTime>(
    'observed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _batteryLevelPercentMeta =
      const VerificationMeta('batteryLevelPercent');
  @override
  late final GeneratedColumn<double> batteryLevelPercent =
      GeneratedColumn<double>(
        'battery_level_percent',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  @override
  late final GeneratedColumnWithTypeConverter<BatteryChargingState?, String>
  chargingState =
      GeneratedColumn<String>(
        'charging_state',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<BatteryChargingState?>(
        $TelemetrySamplesTable.$converterchargingStaten,
      );
  @override
  late final GeneratedColumnWithTypeConverter<BatteryPlugSource?, String>
  plugSource =
      GeneratedColumn<String>(
        'plug_source',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<BatteryPlugSource?>(
        $TelemetrySamplesTable.$converterplugSourcen,
      );
  static const VerificationMeta _voltageVoltsMeta = const VerificationMeta(
    'voltageVolts',
  );
  @override
  late final GeneratedColumn<double> voltageVolts = GeneratedColumn<double>(
    'voltage_volts',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentAmpsMeta = const VerificationMeta(
    'currentAmps',
  );
  @override
  late final GeneratedColumn<double> currentAmps = GeneratedColumn<double>(
    'current_amps',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentAverageAmpsMeta =
      const VerificationMeta('currentAverageAmps');
  @override
  late final GeneratedColumn<double> currentAverageAmps =
      GeneratedColumn<double>(
        'current_average_amps',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _temperatureCelsiusMeta =
      const VerificationMeta('temperatureCelsius');
  @override
  late final GeneratedColumn<double> temperatureCelsius =
      GeneratedColumn<double>(
        'temperature_celsius',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _chargeCounterMahMeta = const VerificationMeta(
    'chargeCounterMah',
  );
  @override
  late final GeneratedColumn<double> chargeCounterMah = GeneratedColumn<double>(
    'charge_counter_mah',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _powerWattsMeta = const VerificationMeta(
    'powerWatts',
  );
  @override
  late final GeneratedColumn<double> powerWatts = GeneratedColumn<double>(
    'power_watts',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _snapshotSchemaVersionMeta =
      const VerificationMeta('snapshotSchemaVersion');
  @override
  late final GeneratedColumn<int> snapshotSchemaVersion = GeneratedColumn<int>(
    'snapshot_schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _availabilityMetadataMeta =
      const VerificationMeta('availabilityMetadata');
  @override
  late final GeneratedColumn<String> availabilityMetadata =
      GeneratedColumn<String>(
        'availability_metadata',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _sourceMetadataMeta = const VerificationMeta(
    'sourceMetadata',
  );
  @override
  late final GeneratedColumn<String> sourceMetadata = GeneratedColumn<String>(
    'source_metadata',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    observedAt,
    batteryLevelPercent,
    chargingState,
    plugSource,
    voltageVolts,
    currentAmps,
    currentAverageAmps,
    temperatureCelsius,
    chargeCounterMah,
    powerWatts,
    snapshotSchemaVersion,
    availabilityMetadata,
    sourceMetadata,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'telemetry_samples';
  @override
  VerificationContext validateIntegrity(
    Insertable<TelemetrySampleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    }
    if (data.containsKey('observed_at')) {
      context.handle(
        _observedAtMeta,
        observedAt.isAcceptableOrUnknown(data['observed_at']!, _observedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_observedAtMeta);
    }
    if (data.containsKey('battery_level_percent')) {
      context.handle(
        _batteryLevelPercentMeta,
        batteryLevelPercent.isAcceptableOrUnknown(
          data['battery_level_percent']!,
          _batteryLevelPercentMeta,
        ),
      );
    }
    if (data.containsKey('voltage_volts')) {
      context.handle(
        _voltageVoltsMeta,
        voltageVolts.isAcceptableOrUnknown(
          data['voltage_volts']!,
          _voltageVoltsMeta,
        ),
      );
    }
    if (data.containsKey('current_amps')) {
      context.handle(
        _currentAmpsMeta,
        currentAmps.isAcceptableOrUnknown(
          data['current_amps']!,
          _currentAmpsMeta,
        ),
      );
    }
    if (data.containsKey('current_average_amps')) {
      context.handle(
        _currentAverageAmpsMeta,
        currentAverageAmps.isAcceptableOrUnknown(
          data['current_average_amps']!,
          _currentAverageAmpsMeta,
        ),
      );
    }
    if (data.containsKey('temperature_celsius')) {
      context.handle(
        _temperatureCelsiusMeta,
        temperatureCelsius.isAcceptableOrUnknown(
          data['temperature_celsius']!,
          _temperatureCelsiusMeta,
        ),
      );
    }
    if (data.containsKey('charge_counter_mah')) {
      context.handle(
        _chargeCounterMahMeta,
        chargeCounterMah.isAcceptableOrUnknown(
          data['charge_counter_mah']!,
          _chargeCounterMahMeta,
        ),
      );
    }
    if (data.containsKey('power_watts')) {
      context.handle(
        _powerWattsMeta,
        powerWatts.isAcceptableOrUnknown(data['power_watts']!, _powerWattsMeta),
      );
    }
    if (data.containsKey('snapshot_schema_version')) {
      context.handle(
        _snapshotSchemaVersionMeta,
        snapshotSchemaVersion.isAcceptableOrUnknown(
          data['snapshot_schema_version']!,
          _snapshotSchemaVersionMeta,
        ),
      );
    }
    if (data.containsKey('availability_metadata')) {
      context.handle(
        _availabilityMetadataMeta,
        availabilityMetadata.isAcceptableOrUnknown(
          data['availability_metadata']!,
          _availabilityMetadataMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_availabilityMetadataMeta);
    }
    if (data.containsKey('source_metadata')) {
      context.handle(
        _sourceMetadataMeta,
        sourceMetadata.isAcceptableOrUnknown(
          data['source_metadata']!,
          _sourceMetadataMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TelemetrySampleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TelemetrySampleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      ),
      observedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}observed_at'],
      )!,
      batteryLevelPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}battery_level_percent'],
      ),
      chargingState: $TelemetrySamplesTable.$converterchargingStaten.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}charging_state'],
        ),
      ),
      plugSource: $TelemetrySamplesTable.$converterplugSourcen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}plug_source'],
        ),
      ),
      voltageVolts: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}voltage_volts'],
      ),
      currentAmps: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_amps'],
      ),
      currentAverageAmps: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_average_amps'],
      ),
      temperatureCelsius: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}temperature_celsius'],
      ),
      chargeCounterMah: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}charge_counter_mah'],
      ),
      powerWatts: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}power_watts'],
      ),
      snapshotSchemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}snapshot_schema_version'],
      )!,
      availabilityMetadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}availability_metadata'],
      )!,
      sourceMetadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_metadata'],
      ),
    );
  }

  @override
  $TelemetrySamplesTable createAlias(String alias) {
    return $TelemetrySamplesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<BatteryChargingState, String, String>
  $converterchargingState = const EnumNameConverter<BatteryChargingState>(
    BatteryChargingState.values,
  );
  static JsonTypeConverter2<BatteryChargingState?, String?, String?>
  $converterchargingStaten = JsonTypeConverter2.asNullable(
    $converterchargingState,
  );
  static JsonTypeConverter2<BatteryPlugSource, String, String>
  $converterplugSource = const EnumNameConverter<BatteryPlugSource>(
    BatteryPlugSource.values,
  );
  static JsonTypeConverter2<BatteryPlugSource?, String?, String?>
  $converterplugSourcen = JsonTypeConverter2.asNullable($converterplugSource);
}

class TelemetrySampleRow extends DataClass
    implements Insertable<TelemetrySampleRow> {
  final int id;
  final int? sessionId;
  final DateTime observedAt;
  final double? batteryLevelPercent;
  final BatteryChargingState? chargingState;
  final BatteryPlugSource? plugSource;
  final double? voltageVolts;
  final double? currentAmps;
  final double? currentAverageAmps;
  final double? temperatureCelsius;
  final double? chargeCounterMah;
  final double? powerWatts;
  final int snapshotSchemaVersion;

  /// JSON map of per-metric availability, provenance, observation time, unit
  /// and reason. Scalar values remain in their own columns for querying.
  final String availabilityMetadata;
  final String? sourceMetadata;
  const TelemetrySampleRow({
    required this.id,
    this.sessionId,
    required this.observedAt,
    this.batteryLevelPercent,
    this.chargingState,
    this.plugSource,
    this.voltageVolts,
    this.currentAmps,
    this.currentAverageAmps,
    this.temperatureCelsius,
    this.chargeCounterMah,
    this.powerWatts,
    required this.snapshotSchemaVersion,
    required this.availabilityMetadata,
    this.sourceMetadata,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<int>(sessionId);
    }
    map['observed_at'] = Variable<DateTime>(observedAt);
    if (!nullToAbsent || batteryLevelPercent != null) {
      map['battery_level_percent'] = Variable<double>(batteryLevelPercent);
    }
    if (!nullToAbsent || chargingState != null) {
      map['charging_state'] = Variable<String>(
        $TelemetrySamplesTable.$converterchargingStaten.toSql(chargingState),
      );
    }
    if (!nullToAbsent || plugSource != null) {
      map['plug_source'] = Variable<String>(
        $TelemetrySamplesTable.$converterplugSourcen.toSql(plugSource),
      );
    }
    if (!nullToAbsent || voltageVolts != null) {
      map['voltage_volts'] = Variable<double>(voltageVolts);
    }
    if (!nullToAbsent || currentAmps != null) {
      map['current_amps'] = Variable<double>(currentAmps);
    }
    if (!nullToAbsent || currentAverageAmps != null) {
      map['current_average_amps'] = Variable<double>(currentAverageAmps);
    }
    if (!nullToAbsent || temperatureCelsius != null) {
      map['temperature_celsius'] = Variable<double>(temperatureCelsius);
    }
    if (!nullToAbsent || chargeCounterMah != null) {
      map['charge_counter_mah'] = Variable<double>(chargeCounterMah);
    }
    if (!nullToAbsent || powerWatts != null) {
      map['power_watts'] = Variable<double>(powerWatts);
    }
    map['snapshot_schema_version'] = Variable<int>(snapshotSchemaVersion);
    map['availability_metadata'] = Variable<String>(availabilityMetadata);
    if (!nullToAbsent || sourceMetadata != null) {
      map['source_metadata'] = Variable<String>(sourceMetadata);
    }
    return map;
  }

  TelemetrySamplesCompanion toCompanion(bool nullToAbsent) {
    return TelemetrySamplesCompanion(
      id: Value(id),
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
      observedAt: Value(observedAt),
      batteryLevelPercent: batteryLevelPercent == null && nullToAbsent
          ? const Value.absent()
          : Value(batteryLevelPercent),
      chargingState: chargingState == null && nullToAbsent
          ? const Value.absent()
          : Value(chargingState),
      plugSource: plugSource == null && nullToAbsent
          ? const Value.absent()
          : Value(plugSource),
      voltageVolts: voltageVolts == null && nullToAbsent
          ? const Value.absent()
          : Value(voltageVolts),
      currentAmps: currentAmps == null && nullToAbsent
          ? const Value.absent()
          : Value(currentAmps),
      currentAverageAmps: currentAverageAmps == null && nullToAbsent
          ? const Value.absent()
          : Value(currentAverageAmps),
      temperatureCelsius: temperatureCelsius == null && nullToAbsent
          ? const Value.absent()
          : Value(temperatureCelsius),
      chargeCounterMah: chargeCounterMah == null && nullToAbsent
          ? const Value.absent()
          : Value(chargeCounterMah),
      powerWatts: powerWatts == null && nullToAbsent
          ? const Value.absent()
          : Value(powerWatts),
      snapshotSchemaVersion: Value(snapshotSchemaVersion),
      availabilityMetadata: Value(availabilityMetadata),
      sourceMetadata: sourceMetadata == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceMetadata),
    );
  }

  factory TelemetrySampleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TelemetrySampleRow(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int?>(json['sessionId']),
      observedAt: serializer.fromJson<DateTime>(json['observedAt']),
      batteryLevelPercent: serializer.fromJson<double?>(
        json['batteryLevelPercent'],
      ),
      chargingState: $TelemetrySamplesTable.$converterchargingStaten.fromJson(
        serializer.fromJson<String?>(json['chargingState']),
      ),
      plugSource: $TelemetrySamplesTable.$converterplugSourcen.fromJson(
        serializer.fromJson<String?>(json['plugSource']),
      ),
      voltageVolts: serializer.fromJson<double?>(json['voltageVolts']),
      currentAmps: serializer.fromJson<double?>(json['currentAmps']),
      currentAverageAmps: serializer.fromJson<double?>(
        json['currentAverageAmps'],
      ),
      temperatureCelsius: serializer.fromJson<double?>(
        json['temperatureCelsius'],
      ),
      chargeCounterMah: serializer.fromJson<double?>(json['chargeCounterMah']),
      powerWatts: serializer.fromJson<double?>(json['powerWatts']),
      snapshotSchemaVersion: serializer.fromJson<int>(
        json['snapshotSchemaVersion'],
      ),
      availabilityMetadata: serializer.fromJson<String>(
        json['availabilityMetadata'],
      ),
      sourceMetadata: serializer.fromJson<String?>(json['sourceMetadata']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int?>(sessionId),
      'observedAt': serializer.toJson<DateTime>(observedAt),
      'batteryLevelPercent': serializer.toJson<double?>(batteryLevelPercent),
      'chargingState': serializer.toJson<String?>(
        $TelemetrySamplesTable.$converterchargingStaten.toJson(chargingState),
      ),
      'plugSource': serializer.toJson<String?>(
        $TelemetrySamplesTable.$converterplugSourcen.toJson(plugSource),
      ),
      'voltageVolts': serializer.toJson<double?>(voltageVolts),
      'currentAmps': serializer.toJson<double?>(currentAmps),
      'currentAverageAmps': serializer.toJson<double?>(currentAverageAmps),
      'temperatureCelsius': serializer.toJson<double?>(temperatureCelsius),
      'chargeCounterMah': serializer.toJson<double?>(chargeCounterMah),
      'powerWatts': serializer.toJson<double?>(powerWatts),
      'snapshotSchemaVersion': serializer.toJson<int>(snapshotSchemaVersion),
      'availabilityMetadata': serializer.toJson<String>(availabilityMetadata),
      'sourceMetadata': serializer.toJson<String?>(sourceMetadata),
    };
  }

  TelemetrySampleRow copyWith({
    int? id,
    Value<int?> sessionId = const Value.absent(),
    DateTime? observedAt,
    Value<double?> batteryLevelPercent = const Value.absent(),
    Value<BatteryChargingState?> chargingState = const Value.absent(),
    Value<BatteryPlugSource?> plugSource = const Value.absent(),
    Value<double?> voltageVolts = const Value.absent(),
    Value<double?> currentAmps = const Value.absent(),
    Value<double?> currentAverageAmps = const Value.absent(),
    Value<double?> temperatureCelsius = const Value.absent(),
    Value<double?> chargeCounterMah = const Value.absent(),
    Value<double?> powerWatts = const Value.absent(),
    int? snapshotSchemaVersion,
    String? availabilityMetadata,
    Value<String?> sourceMetadata = const Value.absent(),
  }) => TelemetrySampleRow(
    id: id ?? this.id,
    sessionId: sessionId.present ? sessionId.value : this.sessionId,
    observedAt: observedAt ?? this.observedAt,
    batteryLevelPercent: batteryLevelPercent.present
        ? batteryLevelPercent.value
        : this.batteryLevelPercent,
    chargingState: chargingState.present
        ? chargingState.value
        : this.chargingState,
    plugSource: plugSource.present ? plugSource.value : this.plugSource,
    voltageVolts: voltageVolts.present ? voltageVolts.value : this.voltageVolts,
    currentAmps: currentAmps.present ? currentAmps.value : this.currentAmps,
    currentAverageAmps: currentAverageAmps.present
        ? currentAverageAmps.value
        : this.currentAverageAmps,
    temperatureCelsius: temperatureCelsius.present
        ? temperatureCelsius.value
        : this.temperatureCelsius,
    chargeCounterMah: chargeCounterMah.present
        ? chargeCounterMah.value
        : this.chargeCounterMah,
    powerWatts: powerWatts.present ? powerWatts.value : this.powerWatts,
    snapshotSchemaVersion: snapshotSchemaVersion ?? this.snapshotSchemaVersion,
    availabilityMetadata: availabilityMetadata ?? this.availabilityMetadata,
    sourceMetadata: sourceMetadata.present
        ? sourceMetadata.value
        : this.sourceMetadata,
  );
  TelemetrySampleRow copyWithCompanion(TelemetrySamplesCompanion data) {
    return TelemetrySampleRow(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      observedAt: data.observedAt.present
          ? data.observedAt.value
          : this.observedAt,
      batteryLevelPercent: data.batteryLevelPercent.present
          ? data.batteryLevelPercent.value
          : this.batteryLevelPercent,
      chargingState: data.chargingState.present
          ? data.chargingState.value
          : this.chargingState,
      plugSource: data.plugSource.present
          ? data.plugSource.value
          : this.plugSource,
      voltageVolts: data.voltageVolts.present
          ? data.voltageVolts.value
          : this.voltageVolts,
      currentAmps: data.currentAmps.present
          ? data.currentAmps.value
          : this.currentAmps,
      currentAverageAmps: data.currentAverageAmps.present
          ? data.currentAverageAmps.value
          : this.currentAverageAmps,
      temperatureCelsius: data.temperatureCelsius.present
          ? data.temperatureCelsius.value
          : this.temperatureCelsius,
      chargeCounterMah: data.chargeCounterMah.present
          ? data.chargeCounterMah.value
          : this.chargeCounterMah,
      powerWatts: data.powerWatts.present
          ? data.powerWatts.value
          : this.powerWatts,
      snapshotSchemaVersion: data.snapshotSchemaVersion.present
          ? data.snapshotSchemaVersion.value
          : this.snapshotSchemaVersion,
      availabilityMetadata: data.availabilityMetadata.present
          ? data.availabilityMetadata.value
          : this.availabilityMetadata,
      sourceMetadata: data.sourceMetadata.present
          ? data.sourceMetadata.value
          : this.sourceMetadata,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TelemetrySampleRow(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('observedAt: $observedAt, ')
          ..write('batteryLevelPercent: $batteryLevelPercent, ')
          ..write('chargingState: $chargingState, ')
          ..write('plugSource: $plugSource, ')
          ..write('voltageVolts: $voltageVolts, ')
          ..write('currentAmps: $currentAmps, ')
          ..write('currentAverageAmps: $currentAverageAmps, ')
          ..write('temperatureCelsius: $temperatureCelsius, ')
          ..write('chargeCounterMah: $chargeCounterMah, ')
          ..write('powerWatts: $powerWatts, ')
          ..write('snapshotSchemaVersion: $snapshotSchemaVersion, ')
          ..write('availabilityMetadata: $availabilityMetadata, ')
          ..write('sourceMetadata: $sourceMetadata')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    observedAt,
    batteryLevelPercent,
    chargingState,
    plugSource,
    voltageVolts,
    currentAmps,
    currentAverageAmps,
    temperatureCelsius,
    chargeCounterMah,
    powerWatts,
    snapshotSchemaVersion,
    availabilityMetadata,
    sourceMetadata,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TelemetrySampleRow &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.observedAt == this.observedAt &&
          other.batteryLevelPercent == this.batteryLevelPercent &&
          other.chargingState == this.chargingState &&
          other.plugSource == this.plugSource &&
          other.voltageVolts == this.voltageVolts &&
          other.currentAmps == this.currentAmps &&
          other.currentAverageAmps == this.currentAverageAmps &&
          other.temperatureCelsius == this.temperatureCelsius &&
          other.chargeCounterMah == this.chargeCounterMah &&
          other.powerWatts == this.powerWatts &&
          other.snapshotSchemaVersion == this.snapshotSchemaVersion &&
          other.availabilityMetadata == this.availabilityMetadata &&
          other.sourceMetadata == this.sourceMetadata);
}

class TelemetrySamplesCompanion extends UpdateCompanion<TelemetrySampleRow> {
  final Value<int> id;
  final Value<int?> sessionId;
  final Value<DateTime> observedAt;
  final Value<double?> batteryLevelPercent;
  final Value<BatteryChargingState?> chargingState;
  final Value<BatteryPlugSource?> plugSource;
  final Value<double?> voltageVolts;
  final Value<double?> currentAmps;
  final Value<double?> currentAverageAmps;
  final Value<double?> temperatureCelsius;
  final Value<double?> chargeCounterMah;
  final Value<double?> powerWatts;
  final Value<int> snapshotSchemaVersion;
  final Value<String> availabilityMetadata;
  final Value<String?> sourceMetadata;
  const TelemetrySamplesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.observedAt = const Value.absent(),
    this.batteryLevelPercent = const Value.absent(),
    this.chargingState = const Value.absent(),
    this.plugSource = const Value.absent(),
    this.voltageVolts = const Value.absent(),
    this.currentAmps = const Value.absent(),
    this.currentAverageAmps = const Value.absent(),
    this.temperatureCelsius = const Value.absent(),
    this.chargeCounterMah = const Value.absent(),
    this.powerWatts = const Value.absent(),
    this.snapshotSchemaVersion = const Value.absent(),
    this.availabilityMetadata = const Value.absent(),
    this.sourceMetadata = const Value.absent(),
  });
  TelemetrySamplesCompanion.insert({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    required DateTime observedAt,
    this.batteryLevelPercent = const Value.absent(),
    this.chargingState = const Value.absent(),
    this.plugSource = const Value.absent(),
    this.voltageVolts = const Value.absent(),
    this.currentAmps = const Value.absent(),
    this.currentAverageAmps = const Value.absent(),
    this.temperatureCelsius = const Value.absent(),
    this.chargeCounterMah = const Value.absent(),
    this.powerWatts = const Value.absent(),
    this.snapshotSchemaVersion = const Value.absent(),
    required String availabilityMetadata,
    this.sourceMetadata = const Value.absent(),
  }) : observedAt = Value(observedAt),
       availabilityMetadata = Value(availabilityMetadata);
  static Insertable<TelemetrySampleRow> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<DateTime>? observedAt,
    Expression<double>? batteryLevelPercent,
    Expression<String>? chargingState,
    Expression<String>? plugSource,
    Expression<double>? voltageVolts,
    Expression<double>? currentAmps,
    Expression<double>? currentAverageAmps,
    Expression<double>? temperatureCelsius,
    Expression<double>? chargeCounterMah,
    Expression<double>? powerWatts,
    Expression<int>? snapshotSchemaVersion,
    Expression<String>? availabilityMetadata,
    Expression<String>? sourceMetadata,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (observedAt != null) 'observed_at': observedAt,
      if (batteryLevelPercent != null)
        'battery_level_percent': batteryLevelPercent,
      if (chargingState != null) 'charging_state': chargingState,
      if (plugSource != null) 'plug_source': plugSource,
      if (voltageVolts != null) 'voltage_volts': voltageVolts,
      if (currentAmps != null) 'current_amps': currentAmps,
      if (currentAverageAmps != null)
        'current_average_amps': currentAverageAmps,
      if (temperatureCelsius != null) 'temperature_celsius': temperatureCelsius,
      if (chargeCounterMah != null) 'charge_counter_mah': chargeCounterMah,
      if (powerWatts != null) 'power_watts': powerWatts,
      if (snapshotSchemaVersion != null)
        'snapshot_schema_version': snapshotSchemaVersion,
      if (availabilityMetadata != null)
        'availability_metadata': availabilityMetadata,
      if (sourceMetadata != null) 'source_metadata': sourceMetadata,
    });
  }

  TelemetrySamplesCompanion copyWith({
    Value<int>? id,
    Value<int?>? sessionId,
    Value<DateTime>? observedAt,
    Value<double?>? batteryLevelPercent,
    Value<BatteryChargingState?>? chargingState,
    Value<BatteryPlugSource?>? plugSource,
    Value<double?>? voltageVolts,
    Value<double?>? currentAmps,
    Value<double?>? currentAverageAmps,
    Value<double?>? temperatureCelsius,
    Value<double?>? chargeCounterMah,
    Value<double?>? powerWatts,
    Value<int>? snapshotSchemaVersion,
    Value<String>? availabilityMetadata,
    Value<String?>? sourceMetadata,
  }) {
    return TelemetrySamplesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      observedAt: observedAt ?? this.observedAt,
      batteryLevelPercent: batteryLevelPercent ?? this.batteryLevelPercent,
      chargingState: chargingState ?? this.chargingState,
      plugSource: plugSource ?? this.plugSource,
      voltageVolts: voltageVolts ?? this.voltageVolts,
      currentAmps: currentAmps ?? this.currentAmps,
      currentAverageAmps: currentAverageAmps ?? this.currentAverageAmps,
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
      chargeCounterMah: chargeCounterMah ?? this.chargeCounterMah,
      powerWatts: powerWatts ?? this.powerWatts,
      snapshotSchemaVersion:
          snapshotSchemaVersion ?? this.snapshotSchemaVersion,
      availabilityMetadata: availabilityMetadata ?? this.availabilityMetadata,
      sourceMetadata: sourceMetadata ?? this.sourceMetadata,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (observedAt.present) {
      map['observed_at'] = Variable<DateTime>(observedAt.value);
    }
    if (batteryLevelPercent.present) {
      map['battery_level_percent'] = Variable<double>(
        batteryLevelPercent.value,
      );
    }
    if (chargingState.present) {
      map['charging_state'] = Variable<String>(
        $TelemetrySamplesTable.$converterchargingStaten.toSql(
          chargingState.value,
        ),
      );
    }
    if (plugSource.present) {
      map['plug_source'] = Variable<String>(
        $TelemetrySamplesTable.$converterplugSourcen.toSql(plugSource.value),
      );
    }
    if (voltageVolts.present) {
      map['voltage_volts'] = Variable<double>(voltageVolts.value);
    }
    if (currentAmps.present) {
      map['current_amps'] = Variable<double>(currentAmps.value);
    }
    if (currentAverageAmps.present) {
      map['current_average_amps'] = Variable<double>(currentAverageAmps.value);
    }
    if (temperatureCelsius.present) {
      map['temperature_celsius'] = Variable<double>(temperatureCelsius.value);
    }
    if (chargeCounterMah.present) {
      map['charge_counter_mah'] = Variable<double>(chargeCounterMah.value);
    }
    if (powerWatts.present) {
      map['power_watts'] = Variable<double>(powerWatts.value);
    }
    if (snapshotSchemaVersion.present) {
      map['snapshot_schema_version'] = Variable<int>(
        snapshotSchemaVersion.value,
      );
    }
    if (availabilityMetadata.present) {
      map['availability_metadata'] = Variable<String>(
        availabilityMetadata.value,
      );
    }
    if (sourceMetadata.present) {
      map['source_metadata'] = Variable<String>(sourceMetadata.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TelemetrySamplesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('observedAt: $observedAt, ')
          ..write('batteryLevelPercent: $batteryLevelPercent, ')
          ..write('chargingState: $chargingState, ')
          ..write('plugSource: $plugSource, ')
          ..write('voltageVolts: $voltageVolts, ')
          ..write('currentAmps: $currentAmps, ')
          ..write('currentAverageAmps: $currentAverageAmps, ')
          ..write('temperatureCelsius: $temperatureCelsius, ')
          ..write('chargeCounterMah: $chargeCounterMah, ')
          ..write('powerWatts: $powerWatts, ')
          ..write('snapshotSchemaVersion: $snapshotSchemaVersion, ')
          ..write('availabilityMetadata: $availabilityMetadata, ')
          ..write('sourceMetadata: $sourceMetadata')
          ..write(')'))
        .toString();
  }
}

abstract class _$VoltlyDatabase extends GeneratedDatabase {
  _$VoltlyDatabase(QueryExecutor e) : super(e);
  $VoltlyDatabaseManager get managers => $VoltlyDatabaseManager(this);
  late final $ChargingSessionsTable chargingSessions = $ChargingSessionsTable(
    this,
  );
  late final $TelemetrySamplesTable telemetrySamples = $TelemetrySamplesTable(
    this,
  );
  late final Index idxChargingSessionsStartedAt = Index(
    'idx_charging_sessions_started_at',
    'CREATE INDEX idx_charging_sessions_started_at ON charging_sessions (started_at)',
  );
  late final Index idxChargingSessionsStateStartedAt = Index(
    'idx_charging_sessions_state_started_at',
    'CREATE INDEX idx_charging_sessions_state_started_at ON charging_sessions (session_state, started_at)',
  );
  late final Index idxTelemetrySamplesSessionObservedAt = Index(
    'idx_telemetry_samples_session_observed_at',
    'CREATE UNIQUE INDEX idx_telemetry_samples_session_observed_at ON telemetry_samples (session_id, observed_at)',
  );
  late final Index idxTelemetrySamplesObservedAt = Index(
    'idx_telemetry_samples_observed_at',
    'CREATE INDEX idx_telemetry_samples_observed_at ON telemetry_samples (observed_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    chargingSessions,
    telemetrySamples,
    idxChargingSessionsStartedAt,
    idxChargingSessionsStateStartedAt,
    idxTelemetrySamplesSessionObservedAt,
    idxTelemetrySamplesObservedAt,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'charging_sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('telemetry_samples', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ChargingSessionsTableCreateCompanionBuilder =
    ChargingSessionsCompanion Function({
      Value<int> id,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      Value<DateTime?> lastObservedAt,
      Value<double?> startLevelPercent,
      Value<double?> endLevelPercent,
      required ChargingSessionState sessionState,
      Value<int> sampleCount,
      Value<int?> maxSamplingGapMs,
      Value<bool> hasSamplingGaps,
      Value<bool> samplesPruned,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$ChargingSessionsTableUpdateCompanionBuilder =
    ChargingSessionsCompanion Function({
      Value<int> id,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<DateTime?> lastObservedAt,
      Value<double?> startLevelPercent,
      Value<double?> endLevelPercent,
      Value<ChargingSessionState> sessionState,
      Value<int> sampleCount,
      Value<int?> maxSamplingGapMs,
      Value<bool> hasSamplingGaps,
      Value<bool> samplesPruned,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$ChargingSessionsTableReferences
    extends
        BaseReferences<
          _$VoltlyDatabase,
          $ChargingSessionsTable,
          ChargingSessionRow
        > {
  $$ChargingSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$TelemetrySamplesTable, List<TelemetrySampleRow>>
  _telemetrySamplesRefsTable(_$VoltlyDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.telemetrySamples,
        aliasName: 'charging_sessions__id__telemetry_samples__session_id',
      );

  $$TelemetrySamplesTableProcessedTableManager get telemetrySamplesRefs {
    final manager = $$TelemetrySamplesTableTableManager(
      $_db,
      $_db.telemetrySamples,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _telemetrySamplesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ChargingSessionsTableFilterComposer
    extends Composer<_$VoltlyDatabase, $ChargingSessionsTable> {
  $$ChargingSessionsTableFilterComposer({
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

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastObservedAt => $composableBuilder(
    column: $table.lastObservedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get startLevelPercent => $composableBuilder(
    column: $table.startLevelPercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get endLevelPercent => $composableBuilder(
    column: $table.endLevelPercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    ChargingSessionState,
    ChargingSessionState,
    String
  >
  get sessionState => $composableBuilder(
    column: $table.sessionState,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get sampleCount => $composableBuilder(
    column: $table.sampleCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxSamplingGapMs => $composableBuilder(
    column: $table.maxSamplingGapMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasSamplingGaps => $composableBuilder(
    column: $table.hasSamplingGaps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get samplesPruned => $composableBuilder(
    column: $table.samplesPruned,
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

  Expression<bool> telemetrySamplesRefs(
    Expression<bool> Function($$TelemetrySamplesTableFilterComposer f) f,
  ) {
    final $$TelemetrySamplesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.telemetrySamples,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TelemetrySamplesTableFilterComposer(
            $db: $db,
            $table: $db.telemetrySamples,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChargingSessionsTableOrderingComposer
    extends Composer<_$VoltlyDatabase, $ChargingSessionsTable> {
  $$ChargingSessionsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastObservedAt => $composableBuilder(
    column: $table.lastObservedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get startLevelPercent => $composableBuilder(
    column: $table.startLevelPercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get endLevelPercent => $composableBuilder(
    column: $table.endLevelPercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionState => $composableBuilder(
    column: $table.sessionState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sampleCount => $composableBuilder(
    column: $table.sampleCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxSamplingGapMs => $composableBuilder(
    column: $table.maxSamplingGapMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasSamplingGaps => $composableBuilder(
    column: $table.hasSamplingGaps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get samplesPruned => $composableBuilder(
    column: $table.samplesPruned,
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

class $$ChargingSessionsTableAnnotationComposer
    extends Composer<_$VoltlyDatabase, $ChargingSessionsTable> {
  $$ChargingSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastObservedAt => $composableBuilder(
    column: $table.lastObservedAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get startLevelPercent => $composableBuilder(
    column: $table.startLevelPercent,
    builder: (column) => column,
  );

  GeneratedColumn<double> get endLevelPercent => $composableBuilder(
    column: $table.endLevelPercent,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ChargingSessionState, String>
  get sessionState => $composableBuilder(
    column: $table.sessionState,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sampleCount => $composableBuilder(
    column: $table.sampleCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get maxSamplingGapMs => $composableBuilder(
    column: $table.maxSamplingGapMs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasSamplingGaps => $composableBuilder(
    column: $table.hasSamplingGaps,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get samplesPruned => $composableBuilder(
    column: $table.samplesPruned,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> telemetrySamplesRefs<T extends Object>(
    Expression<T> Function($$TelemetrySamplesTableAnnotationComposer a) f,
  ) {
    final $$TelemetrySamplesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.telemetrySamples,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TelemetrySamplesTableAnnotationComposer(
            $db: $db,
            $table: $db.telemetrySamples,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChargingSessionsTableTableManager
    extends
        RootTableManager<
          _$VoltlyDatabase,
          $ChargingSessionsTable,
          ChargingSessionRow,
          $$ChargingSessionsTableFilterComposer,
          $$ChargingSessionsTableOrderingComposer,
          $$ChargingSessionsTableAnnotationComposer,
          $$ChargingSessionsTableCreateCompanionBuilder,
          $$ChargingSessionsTableUpdateCompanionBuilder,
          (ChargingSessionRow, $$ChargingSessionsTableReferences),
          ChargingSessionRow,
          PrefetchHooks Function({bool telemetrySamplesRefs})
        > {
  $$ChargingSessionsTableTableManager(
    _$VoltlyDatabase db,
    $ChargingSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChargingSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChargingSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChargingSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<DateTime?> lastObservedAt = const Value.absent(),
                Value<double?> startLevelPercent = const Value.absent(),
                Value<double?> endLevelPercent = const Value.absent(),
                Value<ChargingSessionState> sessionState = const Value.absent(),
                Value<int> sampleCount = const Value.absent(),
                Value<int?> maxSamplingGapMs = const Value.absent(),
                Value<bool> hasSamplingGaps = const Value.absent(),
                Value<bool> samplesPruned = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ChargingSessionsCompanion(
                id: id,
                startedAt: startedAt,
                endedAt: endedAt,
                lastObservedAt: lastObservedAt,
                startLevelPercent: startLevelPercent,
                endLevelPercent: endLevelPercent,
                sessionState: sessionState,
                sampleCount: sampleCount,
                maxSamplingGapMs: maxSamplingGapMs,
                hasSamplingGaps: hasSamplingGaps,
                samplesPruned: samplesPruned,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<DateTime?> lastObservedAt = const Value.absent(),
                Value<double?> startLevelPercent = const Value.absent(),
                Value<double?> endLevelPercent = const Value.absent(),
                required ChargingSessionState sessionState,
                Value<int> sampleCount = const Value.absent(),
                Value<int?> maxSamplingGapMs = const Value.absent(),
                Value<bool> hasSamplingGaps = const Value.absent(),
                Value<bool> samplesPruned = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ChargingSessionsCompanion.insert(
                id: id,
                startedAt: startedAt,
                endedAt: endedAt,
                lastObservedAt: lastObservedAt,
                startLevelPercent: startLevelPercent,
                endLevelPercent: endLevelPercent,
                sessionState: sessionState,
                sampleCount: sampleCount,
                maxSamplingGapMs: maxSamplingGapMs,
                hasSamplingGaps: hasSamplingGaps,
                samplesPruned: samplesPruned,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ChargingSessionsTable, ChargingSessionRow>(
                    table,
                  ),
                  $$ChargingSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({telemetrySamplesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (telemetrySamplesRefs) db.telemetrySamples,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (telemetrySamplesRefs)
                    await $_getPrefetchedData<
                      ChargingSessionRow,
                      $ChargingSessionsTable,
                      TelemetrySampleRow
                    >(
                      currentTable: table,
                      referencedTable: $$ChargingSessionsTableReferences
                          ._telemetrySamplesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ChargingSessionsTableReferences(
                            db,
                            table,
                            p0,
                          ).telemetrySamplesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.sessionId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ChargingSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$VoltlyDatabase,
      $ChargingSessionsTable,
      ChargingSessionRow,
      $$ChargingSessionsTableFilterComposer,
      $$ChargingSessionsTableOrderingComposer,
      $$ChargingSessionsTableAnnotationComposer,
      $$ChargingSessionsTableCreateCompanionBuilder,
      $$ChargingSessionsTableUpdateCompanionBuilder,
      (ChargingSessionRow, $$ChargingSessionsTableReferences),
      ChargingSessionRow,
      PrefetchHooks Function({bool telemetrySamplesRefs})
    >;
typedef $$TelemetrySamplesTableCreateCompanionBuilder =
    TelemetrySamplesCompanion Function({
      Value<int> id,
      Value<int?> sessionId,
      required DateTime observedAt,
      Value<double?> batteryLevelPercent,
      Value<BatteryChargingState?> chargingState,
      Value<BatteryPlugSource?> plugSource,
      Value<double?> voltageVolts,
      Value<double?> currentAmps,
      Value<double?> currentAverageAmps,
      Value<double?> temperatureCelsius,
      Value<double?> chargeCounterMah,
      Value<double?> powerWatts,
      Value<int> snapshotSchemaVersion,
      required String availabilityMetadata,
      Value<String?> sourceMetadata,
    });
typedef $$TelemetrySamplesTableUpdateCompanionBuilder =
    TelemetrySamplesCompanion Function({
      Value<int> id,
      Value<int?> sessionId,
      Value<DateTime> observedAt,
      Value<double?> batteryLevelPercent,
      Value<BatteryChargingState?> chargingState,
      Value<BatteryPlugSource?> plugSource,
      Value<double?> voltageVolts,
      Value<double?> currentAmps,
      Value<double?> currentAverageAmps,
      Value<double?> temperatureCelsius,
      Value<double?> chargeCounterMah,
      Value<double?> powerWatts,
      Value<int> snapshotSchemaVersion,
      Value<String> availabilityMetadata,
      Value<String?> sourceMetadata,
    });

final class $$TelemetrySamplesTableReferences
    extends
        BaseReferences<
          _$VoltlyDatabase,
          $TelemetrySamplesTable,
          TelemetrySampleRow
        > {
  $$TelemetrySamplesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ChargingSessionsTable _sessionIdTable(_$VoltlyDatabase db) => db
      .chargingSessions
      .createAlias('telemetry_samples__session_id__charging_sessions__id');

  $$ChargingSessionsTableProcessedTableManager? get sessionId {
    final $_column = $_itemColumn<int>('session_id');
    if ($_column == null) return null;
    final manager = $$ChargingSessionsTableTableManager(
      $_db,
      $_db.chargingSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TelemetrySamplesTableFilterComposer
    extends Composer<_$VoltlyDatabase, $TelemetrySamplesTable> {
  $$TelemetrySamplesTableFilterComposer({
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

  ColumnFilters<DateTime> get observedAt => $composableBuilder(
    column: $table.observedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get batteryLevelPercent => $composableBuilder(
    column: $table.batteryLevelPercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    BatteryChargingState?,
    BatteryChargingState,
    String
  >
  get chargingState => $composableBuilder(
    column: $table.chargingState,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<BatteryPlugSource?, BatteryPlugSource, String>
  get plugSource => $composableBuilder(
    column: $table.plugSource,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<double> get voltageVolts => $composableBuilder(
    column: $table.voltageVolts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get currentAmps => $composableBuilder(
    column: $table.currentAmps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get currentAverageAmps => $composableBuilder(
    column: $table.currentAverageAmps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get temperatureCelsius => $composableBuilder(
    column: $table.temperatureCelsius,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get chargeCounterMah => $composableBuilder(
    column: $table.chargeCounterMah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get powerWatts => $composableBuilder(
    column: $table.powerWatts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get snapshotSchemaVersion => $composableBuilder(
    column: $table.snapshotSchemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get availabilityMetadata => $composableBuilder(
    column: $table.availabilityMetadata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceMetadata => $composableBuilder(
    column: $table.sourceMetadata,
    builder: (column) => ColumnFilters(column),
  );

  $$ChargingSessionsTableFilterComposer get sessionId {
    final $$ChargingSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.chargingSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChargingSessionsTableFilterComposer(
            $db: $db,
            $table: $db.chargingSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TelemetrySamplesTableOrderingComposer
    extends Composer<_$VoltlyDatabase, $TelemetrySamplesTable> {
  $$TelemetrySamplesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get observedAt => $composableBuilder(
    column: $table.observedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get batteryLevelPercent => $composableBuilder(
    column: $table.batteryLevelPercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chargingState => $composableBuilder(
    column: $table.chargingState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plugSource => $composableBuilder(
    column: $table.plugSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get voltageVolts => $composableBuilder(
    column: $table.voltageVolts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get currentAmps => $composableBuilder(
    column: $table.currentAmps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get currentAverageAmps => $composableBuilder(
    column: $table.currentAverageAmps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get temperatureCelsius => $composableBuilder(
    column: $table.temperatureCelsius,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get chargeCounterMah => $composableBuilder(
    column: $table.chargeCounterMah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get powerWatts => $composableBuilder(
    column: $table.powerWatts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get snapshotSchemaVersion => $composableBuilder(
    column: $table.snapshotSchemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get availabilityMetadata => $composableBuilder(
    column: $table.availabilityMetadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceMetadata => $composableBuilder(
    column: $table.sourceMetadata,
    builder: (column) => ColumnOrderings(column),
  );

  $$ChargingSessionsTableOrderingComposer get sessionId {
    final $$ChargingSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.chargingSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChargingSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.chargingSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TelemetrySamplesTableAnnotationComposer
    extends Composer<_$VoltlyDatabase, $TelemetrySamplesTable> {
  $$TelemetrySamplesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get observedAt => $composableBuilder(
    column: $table.observedAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get batteryLevelPercent => $composableBuilder(
    column: $table.batteryLevelPercent,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<BatteryChargingState?, String>
  get chargingState => $composableBuilder(
    column: $table.chargingState,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<BatteryPlugSource?, String> get plugSource =>
      $composableBuilder(
        column: $table.plugSource,
        builder: (column) => column,
      );

  GeneratedColumn<double> get voltageVolts => $composableBuilder(
    column: $table.voltageVolts,
    builder: (column) => column,
  );

  GeneratedColumn<double> get currentAmps => $composableBuilder(
    column: $table.currentAmps,
    builder: (column) => column,
  );

  GeneratedColumn<double> get currentAverageAmps => $composableBuilder(
    column: $table.currentAverageAmps,
    builder: (column) => column,
  );

  GeneratedColumn<double> get temperatureCelsius => $composableBuilder(
    column: $table.temperatureCelsius,
    builder: (column) => column,
  );

  GeneratedColumn<double> get chargeCounterMah => $composableBuilder(
    column: $table.chargeCounterMah,
    builder: (column) => column,
  );

  GeneratedColumn<double> get powerWatts => $composableBuilder(
    column: $table.powerWatts,
    builder: (column) => column,
  );

  GeneratedColumn<int> get snapshotSchemaVersion => $composableBuilder(
    column: $table.snapshotSchemaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get availabilityMetadata => $composableBuilder(
    column: $table.availabilityMetadata,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceMetadata => $composableBuilder(
    column: $table.sourceMetadata,
    builder: (column) => column,
  );

  $$ChargingSessionsTableAnnotationComposer get sessionId {
    final $$ChargingSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.chargingSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChargingSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.chargingSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TelemetrySamplesTableTableManager
    extends
        RootTableManager<
          _$VoltlyDatabase,
          $TelemetrySamplesTable,
          TelemetrySampleRow,
          $$TelemetrySamplesTableFilterComposer,
          $$TelemetrySamplesTableOrderingComposer,
          $$TelemetrySamplesTableAnnotationComposer,
          $$TelemetrySamplesTableCreateCompanionBuilder,
          $$TelemetrySamplesTableUpdateCompanionBuilder,
          (TelemetrySampleRow, $$TelemetrySamplesTableReferences),
          TelemetrySampleRow,
          PrefetchHooks Function({bool sessionId})
        > {
  $$TelemetrySamplesTableTableManager(
    _$VoltlyDatabase db,
    $TelemetrySamplesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TelemetrySamplesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TelemetrySamplesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TelemetrySamplesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> sessionId = const Value.absent(),
                Value<DateTime> observedAt = const Value.absent(),
                Value<double?> batteryLevelPercent = const Value.absent(),
                Value<BatteryChargingState?> chargingState =
                    const Value.absent(),
                Value<BatteryPlugSource?> plugSource = const Value.absent(),
                Value<double?> voltageVolts = const Value.absent(),
                Value<double?> currentAmps = const Value.absent(),
                Value<double?> currentAverageAmps = const Value.absent(),
                Value<double?> temperatureCelsius = const Value.absent(),
                Value<double?> chargeCounterMah = const Value.absent(),
                Value<double?> powerWatts = const Value.absent(),
                Value<int> snapshotSchemaVersion = const Value.absent(),
                Value<String> availabilityMetadata = const Value.absent(),
                Value<String?> sourceMetadata = const Value.absent(),
              }) => TelemetrySamplesCompanion(
                id: id,
                sessionId: sessionId,
                observedAt: observedAt,
                batteryLevelPercent: batteryLevelPercent,
                chargingState: chargingState,
                plugSource: plugSource,
                voltageVolts: voltageVolts,
                currentAmps: currentAmps,
                currentAverageAmps: currentAverageAmps,
                temperatureCelsius: temperatureCelsius,
                chargeCounterMah: chargeCounterMah,
                powerWatts: powerWatts,
                snapshotSchemaVersion: snapshotSchemaVersion,
                availabilityMetadata: availabilityMetadata,
                sourceMetadata: sourceMetadata,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> sessionId = const Value.absent(),
                required DateTime observedAt,
                Value<double?> batteryLevelPercent = const Value.absent(),
                Value<BatteryChargingState?> chargingState =
                    const Value.absent(),
                Value<BatteryPlugSource?> plugSource = const Value.absent(),
                Value<double?> voltageVolts = const Value.absent(),
                Value<double?> currentAmps = const Value.absent(),
                Value<double?> currentAverageAmps = const Value.absent(),
                Value<double?> temperatureCelsius = const Value.absent(),
                Value<double?> chargeCounterMah = const Value.absent(),
                Value<double?> powerWatts = const Value.absent(),
                Value<int> snapshotSchemaVersion = const Value.absent(),
                required String availabilityMetadata,
                Value<String?> sourceMetadata = const Value.absent(),
              }) => TelemetrySamplesCompanion.insert(
                id: id,
                sessionId: sessionId,
                observedAt: observedAt,
                batteryLevelPercent: batteryLevelPercent,
                chargingState: chargingState,
                plugSource: plugSource,
                voltageVolts: voltageVolts,
                currentAmps: currentAmps,
                currentAverageAmps: currentAverageAmps,
                temperatureCelsius: temperatureCelsius,
                chargeCounterMah: chargeCounterMah,
                powerWatts: powerWatts,
                snapshotSchemaVersion: snapshotSchemaVersion,
                availabilityMetadata: availabilityMetadata,
                sourceMetadata: sourceMetadata,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TelemetrySamplesTable, TelemetrySampleRow>(
                    table,
                  ),
                  $$TelemetrySamplesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
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
                    if (sessionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sessionId,
                        referencedTable: $$TelemetrySamplesTableReferences
                            ._sessionIdTable(db),
                        referencedColumn: $$TelemetrySamplesTableReferences
                            ._sessionIdTable(db)
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

typedef $$TelemetrySamplesTableProcessedTableManager =
    ProcessedTableManager<
      _$VoltlyDatabase,
      $TelemetrySamplesTable,
      TelemetrySampleRow,
      $$TelemetrySamplesTableFilterComposer,
      $$TelemetrySamplesTableOrderingComposer,
      $$TelemetrySamplesTableAnnotationComposer,
      $$TelemetrySamplesTableCreateCompanionBuilder,
      $$TelemetrySamplesTableUpdateCompanionBuilder,
      (TelemetrySampleRow, $$TelemetrySamplesTableReferences),
      TelemetrySampleRow,
      PrefetchHooks Function({bool sessionId})
    >;

class $VoltlyDatabaseManager {
  final _$VoltlyDatabase _db;
  $VoltlyDatabaseManager(this._db);
  $$ChargingSessionsTableTableManager get chargingSessions =>
      $$ChargingSessionsTableTableManager(_db, _db.chargingSessions);
  $$TelemetrySamplesTableTableManager get telemetrySamples =>
      $$TelemetrySamplesTableTableManager(_db, _db.telemetrySamples);
}
