// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'banco.dart';

// ignore_for_file: type=lint
class CatVersoes extends Table with TableInfo<CatVersoes, CatVersao> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CatVersoes(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _catalogoMeta = const VerificationMeta(
    'catalogo',
  );
  late final GeneratedColumn<String> catalogo = GeneratedColumn<String>(
    'catalogo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL PRIMARY KEY CHECK (catalogo IN (\'irpf\', \'parametros\', \'feriados\', \'rubricas\', \'profissoes\', \'parsers\'))',
  );
  static const VerificationMeta _versaoMeta = const VerificationMeta('versao');
  late final GeneratedColumn<int> versao = GeneratedColumn<int>(
    'versao',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _publicadoEmMeta = const VerificationMeta(
    'publicadoEm',
  );
  late final GeneratedColumn<int> publicadoEm = GeneratedColumn<int>(
    'publicado_em',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _baixadoEmMeta = const VerificationMeta(
    'baixadoEm',
  );
  late final GeneratedColumn<int> baixadoEm = GeneratedColumn<int>(
    'baixado_em',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _hashMeta = const VerificationMeta('hash');
  late final GeneratedColumn<String> hash = GeneratedColumn<String>(
    'hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    catalogo,
    versao,
    publicadoEm,
    baixadoEm,
    hash,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cat_versoes';
  @override
  VerificationContext validateIntegrity(
    Insertable<CatVersao> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('catalogo')) {
      context.handle(
        _catalogoMeta,
        catalogo.isAcceptableOrUnknown(data['catalogo']!, _catalogoMeta),
      );
    } else if (isInserting) {
      context.missing(_catalogoMeta);
    }
    if (data.containsKey('versao')) {
      context.handle(
        _versaoMeta,
        versao.isAcceptableOrUnknown(data['versao']!, _versaoMeta),
      );
    } else if (isInserting) {
      context.missing(_versaoMeta);
    }
    if (data.containsKey('publicado_em')) {
      context.handle(
        _publicadoEmMeta,
        publicadoEm.isAcceptableOrUnknown(
          data['publicado_em']!,
          _publicadoEmMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_publicadoEmMeta);
    }
    if (data.containsKey('baixado_em')) {
      context.handle(
        _baixadoEmMeta,
        baixadoEm.isAcceptableOrUnknown(data['baixado_em']!, _baixadoEmMeta),
      );
    } else if (isInserting) {
      context.missing(_baixadoEmMeta);
    }
    if (data.containsKey('hash')) {
      context.handle(
        _hashMeta,
        hash.isAcceptableOrUnknown(data['hash']!, _hashMeta),
      );
    } else if (isInserting) {
      context.missing(_hashMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {catalogo};
  @override
  CatVersao map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CatVersao(
      catalogo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}catalogo'],
      )!,
      versao: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}versao'],
      )!,
      publicadoEm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}publicado_em'],
      )!,
      baixadoEm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}baixado_em'],
      )!,
      hash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash'],
      )!,
    );
  }

  @override
  CatVersoes createAlias(String alias) {
    return CatVersoes(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class CatVersao extends DataClass implements Insertable<CatVersao> {
  final String catalogo;
  final int versao;
  final int publicadoEm;
  final int baixadoEm;
  final String hash;
  const CatVersao({
    required this.catalogo,
    required this.versao,
    required this.publicadoEm,
    required this.baixadoEm,
    required this.hash,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['catalogo'] = Variable<String>(catalogo);
    map['versao'] = Variable<int>(versao);
    map['publicado_em'] = Variable<int>(publicadoEm);
    map['baixado_em'] = Variable<int>(baixadoEm);
    map['hash'] = Variable<String>(hash);
    return map;
  }

  CatVersoesCompanion toCompanion(bool nullToAbsent) {
    return CatVersoesCompanion(
      catalogo: Value(catalogo),
      versao: Value(versao),
      publicadoEm: Value(publicadoEm),
      baixadoEm: Value(baixadoEm),
      hash: Value(hash),
    );
  }

  factory CatVersao.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CatVersao(
      catalogo: serializer.fromJson<String>(json['catalogo']),
      versao: serializer.fromJson<int>(json['versao']),
      publicadoEm: serializer.fromJson<int>(json['publicado_em']),
      baixadoEm: serializer.fromJson<int>(json['baixado_em']),
      hash: serializer.fromJson<String>(json['hash']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'catalogo': serializer.toJson<String>(catalogo),
      'versao': serializer.toJson<int>(versao),
      'publicado_em': serializer.toJson<int>(publicadoEm),
      'baixado_em': serializer.toJson<int>(baixadoEm),
      'hash': serializer.toJson<String>(hash),
    };
  }

  CatVersao copyWith({
    String? catalogo,
    int? versao,
    int? publicadoEm,
    int? baixadoEm,
    String? hash,
  }) => CatVersao(
    catalogo: catalogo ?? this.catalogo,
    versao: versao ?? this.versao,
    publicadoEm: publicadoEm ?? this.publicadoEm,
    baixadoEm: baixadoEm ?? this.baixadoEm,
    hash: hash ?? this.hash,
  );
  CatVersao copyWithCompanion(CatVersoesCompanion data) {
    return CatVersao(
      catalogo: data.catalogo.present ? data.catalogo.value : this.catalogo,
      versao: data.versao.present ? data.versao.value : this.versao,
      publicadoEm: data.publicadoEm.present
          ? data.publicadoEm.value
          : this.publicadoEm,
      baixadoEm: data.baixadoEm.present ? data.baixadoEm.value : this.baixadoEm,
      hash: data.hash.present ? data.hash.value : this.hash,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CatVersao(')
          ..write('catalogo: $catalogo, ')
          ..write('versao: $versao, ')
          ..write('publicadoEm: $publicadoEm, ')
          ..write('baixadoEm: $baixadoEm, ')
          ..write('hash: $hash')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(catalogo, versao, publicadoEm, baixadoEm, hash);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CatVersao &&
          other.catalogo == this.catalogo &&
          other.versao == this.versao &&
          other.publicadoEm == this.publicadoEm &&
          other.baixadoEm == this.baixadoEm &&
          other.hash == this.hash);
}

class CatVersoesCompanion extends UpdateCompanion<CatVersao> {
  final Value<String> catalogo;
  final Value<int> versao;
  final Value<int> publicadoEm;
  final Value<int> baixadoEm;
  final Value<String> hash;
  final Value<int> rowid;
  const CatVersoesCompanion({
    this.catalogo = const Value.absent(),
    this.versao = const Value.absent(),
    this.publicadoEm = const Value.absent(),
    this.baixadoEm = const Value.absent(),
    this.hash = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CatVersoesCompanion.insert({
    required String catalogo,
    required int versao,
    required int publicadoEm,
    required int baixadoEm,
    required String hash,
    this.rowid = const Value.absent(),
  }) : catalogo = Value(catalogo),
       versao = Value(versao),
       publicadoEm = Value(publicadoEm),
       baixadoEm = Value(baixadoEm),
       hash = Value(hash);
  static Insertable<CatVersao> custom({
    Expression<String>? catalogo,
    Expression<int>? versao,
    Expression<int>? publicadoEm,
    Expression<int>? baixadoEm,
    Expression<String>? hash,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (catalogo != null) 'catalogo': catalogo,
      if (versao != null) 'versao': versao,
      if (publicadoEm != null) 'publicado_em': publicadoEm,
      if (baixadoEm != null) 'baixado_em': baixadoEm,
      if (hash != null) 'hash': hash,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CatVersoesCompanion copyWith({
    Value<String>? catalogo,
    Value<int>? versao,
    Value<int>? publicadoEm,
    Value<int>? baixadoEm,
    Value<String>? hash,
    Value<int>? rowid,
  }) {
    return CatVersoesCompanion(
      catalogo: catalogo ?? this.catalogo,
      versao: versao ?? this.versao,
      publicadoEm: publicadoEm ?? this.publicadoEm,
      baixadoEm: baixadoEm ?? this.baixadoEm,
      hash: hash ?? this.hash,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (catalogo.present) {
      map['catalogo'] = Variable<String>(catalogo.value);
    }
    if (versao.present) {
      map['versao'] = Variable<int>(versao.value);
    }
    if (publicadoEm.present) {
      map['publicado_em'] = Variable<int>(publicadoEm.value);
    }
    if (baixadoEm.present) {
      map['baixado_em'] = Variable<int>(baixadoEm.value);
    }
    if (hash.present) {
      map['hash'] = Variable<String>(hash.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CatVersoesCompanion(')
          ..write('catalogo: $catalogo, ')
          ..write('versao: $versao, ')
          ..write('publicadoEm: $publicadoEm, ')
          ..write('baixadoEm: $baixadoEm, ')
          ..write('hash: $hash, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class CatTabelasIrpf extends Table
    with TableInfo<CatTabelasIrpf, CatTabelaIrpf> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CatTabelasIrpf(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _vigenciaInicioMeta = const VerificationMeta(
    'vigenciaInicio',
  );
  late final GeneratedColumn<String> vigenciaInicio = GeneratedColumn<String>(
    'vigencia_inicio',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _vigenciaFimMeta = const VerificationMeta(
    'vigenciaFim',
  );
  late final GeneratedColumn<String> vigenciaFim = GeneratedColumn<String>(
    'vigencia_fim',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _fonteLegalMeta = const VerificationMeta(
    'fonteLegal',
  );
  late final GeneratedColumn<String> fonteLegal = GeneratedColumn<String>(
    'fonte_legal',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _deducaoDependenteCentavosMeta =
      const VerificationMeta('deducaoDependenteCentavos');
  late final GeneratedColumn<int> deducaoDependenteCentavos =
      GeneratedColumn<int>(
        'deducao_dependente_centavos',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    vigenciaInicio,
    vigenciaFim,
    fonteLegal,
    deducaoDependenteCentavos,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cat_tabelas_irpf';
  @override
  VerificationContext validateIntegrity(
    Insertable<CatTabelaIrpf> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('vigencia_inicio')) {
      context.handle(
        _vigenciaInicioMeta,
        vigenciaInicio.isAcceptableOrUnknown(
          data['vigencia_inicio']!,
          _vigenciaInicioMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_vigenciaInicioMeta);
    }
    if (data.containsKey('vigencia_fim')) {
      context.handle(
        _vigenciaFimMeta,
        vigenciaFim.isAcceptableOrUnknown(
          data['vigencia_fim']!,
          _vigenciaFimMeta,
        ),
      );
    }
    if (data.containsKey('fonte_legal')) {
      context.handle(
        _fonteLegalMeta,
        fonteLegal.isAcceptableOrUnknown(data['fonte_legal']!, _fonteLegalMeta),
      );
    } else if (isInserting) {
      context.missing(_fonteLegalMeta);
    }
    if (data.containsKey('deducao_dependente_centavos')) {
      context.handle(
        _deducaoDependenteCentavosMeta,
        deducaoDependenteCentavos.isAcceptableOrUnknown(
          data['deducao_dependente_centavos']!,
          _deducaoDependenteCentavosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deducaoDependenteCentavosMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CatTabelaIrpf map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CatTabelaIrpf(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      vigenciaInicio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vigencia_inicio'],
      )!,
      vigenciaFim: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vigencia_fim'],
      ),
      fonteLegal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fonte_legal'],
      )!,
      deducaoDependenteCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deducao_dependente_centavos'],
      )!,
    );
  }

  @override
  CatTabelasIrpf createAlias(String alias) {
    return CatTabelasIrpf(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class CatTabelaIrpf extends DataClass implements Insertable<CatTabelaIrpf> {
  final int id;
  final String vigenciaInicio;
  final String? vigenciaFim;
  final String fonteLegal;
  final int deducaoDependenteCentavos;
  const CatTabelaIrpf({
    required this.id,
    required this.vigenciaInicio,
    this.vigenciaFim,
    required this.fonteLegal,
    required this.deducaoDependenteCentavos,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['vigencia_inicio'] = Variable<String>(vigenciaInicio);
    if (!nullToAbsent || vigenciaFim != null) {
      map['vigencia_fim'] = Variable<String>(vigenciaFim);
    }
    map['fonte_legal'] = Variable<String>(fonteLegal);
    map['deducao_dependente_centavos'] = Variable<int>(
      deducaoDependenteCentavos,
    );
    return map;
  }

  CatTabelasIrpfCompanion toCompanion(bool nullToAbsent) {
    return CatTabelasIrpfCompanion(
      id: Value(id),
      vigenciaInicio: Value(vigenciaInicio),
      vigenciaFim: vigenciaFim == null && nullToAbsent
          ? const Value.absent()
          : Value(vigenciaFim),
      fonteLegal: Value(fonteLegal),
      deducaoDependenteCentavos: Value(deducaoDependenteCentavos),
    );
  }

  factory CatTabelaIrpf.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CatTabelaIrpf(
      id: serializer.fromJson<int>(json['id']),
      vigenciaInicio: serializer.fromJson<String>(json['vigencia_inicio']),
      vigenciaFim: serializer.fromJson<String?>(json['vigencia_fim']),
      fonteLegal: serializer.fromJson<String>(json['fonte_legal']),
      deducaoDependenteCentavos: serializer.fromJson<int>(
        json['deducao_dependente_centavos'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'vigencia_inicio': serializer.toJson<String>(vigenciaInicio),
      'vigencia_fim': serializer.toJson<String?>(vigenciaFim),
      'fonte_legal': serializer.toJson<String>(fonteLegal),
      'deducao_dependente_centavos': serializer.toJson<int>(
        deducaoDependenteCentavos,
      ),
    };
  }

  CatTabelaIrpf copyWith({
    int? id,
    String? vigenciaInicio,
    Value<String?> vigenciaFim = const Value.absent(),
    String? fonteLegal,
    int? deducaoDependenteCentavos,
  }) => CatTabelaIrpf(
    id: id ?? this.id,
    vigenciaInicio: vigenciaInicio ?? this.vigenciaInicio,
    vigenciaFim: vigenciaFim.present ? vigenciaFim.value : this.vigenciaFim,
    fonteLegal: fonteLegal ?? this.fonteLegal,
    deducaoDependenteCentavos:
        deducaoDependenteCentavos ?? this.deducaoDependenteCentavos,
  );
  CatTabelaIrpf copyWithCompanion(CatTabelasIrpfCompanion data) {
    return CatTabelaIrpf(
      id: data.id.present ? data.id.value : this.id,
      vigenciaInicio: data.vigenciaInicio.present
          ? data.vigenciaInicio.value
          : this.vigenciaInicio,
      vigenciaFim: data.vigenciaFim.present
          ? data.vigenciaFim.value
          : this.vigenciaFim,
      fonteLegal: data.fonteLegal.present
          ? data.fonteLegal.value
          : this.fonteLegal,
      deducaoDependenteCentavos: data.deducaoDependenteCentavos.present
          ? data.deducaoDependenteCentavos.value
          : this.deducaoDependenteCentavos,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CatTabelaIrpf(')
          ..write('id: $id, ')
          ..write('vigenciaInicio: $vigenciaInicio, ')
          ..write('vigenciaFim: $vigenciaFim, ')
          ..write('fonteLegal: $fonteLegal, ')
          ..write('deducaoDependenteCentavos: $deducaoDependenteCentavos')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    vigenciaInicio,
    vigenciaFim,
    fonteLegal,
    deducaoDependenteCentavos,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CatTabelaIrpf &&
          other.id == this.id &&
          other.vigenciaInicio == this.vigenciaInicio &&
          other.vigenciaFim == this.vigenciaFim &&
          other.fonteLegal == this.fonteLegal &&
          other.deducaoDependenteCentavos == this.deducaoDependenteCentavos);
}

class CatTabelasIrpfCompanion extends UpdateCompanion<CatTabelaIrpf> {
  final Value<int> id;
  final Value<String> vigenciaInicio;
  final Value<String?> vigenciaFim;
  final Value<String> fonteLegal;
  final Value<int> deducaoDependenteCentavos;
  const CatTabelasIrpfCompanion({
    this.id = const Value.absent(),
    this.vigenciaInicio = const Value.absent(),
    this.vigenciaFim = const Value.absent(),
    this.fonteLegal = const Value.absent(),
    this.deducaoDependenteCentavos = const Value.absent(),
  });
  CatTabelasIrpfCompanion.insert({
    this.id = const Value.absent(),
    required String vigenciaInicio,
    this.vigenciaFim = const Value.absent(),
    required String fonteLegal,
    required int deducaoDependenteCentavos,
  }) : vigenciaInicio = Value(vigenciaInicio),
       fonteLegal = Value(fonteLegal),
       deducaoDependenteCentavos = Value(deducaoDependenteCentavos);
  static Insertable<CatTabelaIrpf> custom({
    Expression<int>? id,
    Expression<String>? vigenciaInicio,
    Expression<String>? vigenciaFim,
    Expression<String>? fonteLegal,
    Expression<int>? deducaoDependenteCentavos,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vigenciaInicio != null) 'vigencia_inicio': vigenciaInicio,
      if (vigenciaFim != null) 'vigencia_fim': vigenciaFim,
      if (fonteLegal != null) 'fonte_legal': fonteLegal,
      if (deducaoDependenteCentavos != null)
        'deducao_dependente_centavos': deducaoDependenteCentavos,
    });
  }

  CatTabelasIrpfCompanion copyWith({
    Value<int>? id,
    Value<String>? vigenciaInicio,
    Value<String?>? vigenciaFim,
    Value<String>? fonteLegal,
    Value<int>? deducaoDependenteCentavos,
  }) {
    return CatTabelasIrpfCompanion(
      id: id ?? this.id,
      vigenciaInicio: vigenciaInicio ?? this.vigenciaInicio,
      vigenciaFim: vigenciaFim ?? this.vigenciaFim,
      fonteLegal: fonteLegal ?? this.fonteLegal,
      deducaoDependenteCentavos:
          deducaoDependenteCentavos ?? this.deducaoDependenteCentavos,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (vigenciaInicio.present) {
      map['vigencia_inicio'] = Variable<String>(vigenciaInicio.value);
    }
    if (vigenciaFim.present) {
      map['vigencia_fim'] = Variable<String>(vigenciaFim.value);
    }
    if (fonteLegal.present) {
      map['fonte_legal'] = Variable<String>(fonteLegal.value);
    }
    if (deducaoDependenteCentavos.present) {
      map['deducao_dependente_centavos'] = Variable<int>(
        deducaoDependenteCentavos.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CatTabelasIrpfCompanion(')
          ..write('id: $id, ')
          ..write('vigenciaInicio: $vigenciaInicio, ')
          ..write('vigenciaFim: $vigenciaFim, ')
          ..write('fonteLegal: $fonteLegal, ')
          ..write('deducaoDependenteCentavos: $deducaoDependenteCentavos')
          ..write(')'))
        .toString();
  }
}

class CatFaixasIrpf extends Table with TableInfo<CatFaixasIrpf, CatFaixaIrpf> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CatFaixasIrpf(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tabelaIdMeta = const VerificationMeta(
    'tabelaId',
  );
  late final GeneratedColumn<int> tabelaId = GeneratedColumn<int>(
    'tabela_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES cat_tabelas_irpf(id)',
  );
  static const VerificationMeta _ordemMeta = const VerificationMeta('ordem');
  late final GeneratedColumn<int> ordem = GeneratedColumn<int>(
    'ordem',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _limiteSuperiorCentavosMeta =
      const VerificationMeta('limiteSuperiorCentavos');
  late final GeneratedColumn<int> limiteSuperiorCentavos = GeneratedColumn<int>(
    'limite_superior_centavos',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _aliquotaBpMeta = const VerificationMeta(
    'aliquotaBp',
  );
  late final GeneratedColumn<int> aliquotaBp = GeneratedColumn<int>(
    'aliquota_bp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _parcelaDeduzirCentavosMeta =
      const VerificationMeta('parcelaDeduzirCentavos');
  late final GeneratedColumn<int> parcelaDeduzirCentavos = GeneratedColumn<int>(
    'parcela_deduzir_centavos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    tabelaId,
    ordem,
    limiteSuperiorCentavos,
    aliquotaBp,
    parcelaDeduzirCentavos,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cat_faixas_irpf';
  @override
  VerificationContext validateIntegrity(
    Insertable<CatFaixaIrpf> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tabela_id')) {
      context.handle(
        _tabelaIdMeta,
        tabelaId.isAcceptableOrUnknown(data['tabela_id']!, _tabelaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tabelaIdMeta);
    }
    if (data.containsKey('ordem')) {
      context.handle(
        _ordemMeta,
        ordem.isAcceptableOrUnknown(data['ordem']!, _ordemMeta),
      );
    } else if (isInserting) {
      context.missing(_ordemMeta);
    }
    if (data.containsKey('limite_superior_centavos')) {
      context.handle(
        _limiteSuperiorCentavosMeta,
        limiteSuperiorCentavos.isAcceptableOrUnknown(
          data['limite_superior_centavos']!,
          _limiteSuperiorCentavosMeta,
        ),
      );
    }
    if (data.containsKey('aliquota_bp')) {
      context.handle(
        _aliquotaBpMeta,
        aliquotaBp.isAcceptableOrUnknown(data['aliquota_bp']!, _aliquotaBpMeta),
      );
    } else if (isInserting) {
      context.missing(_aliquotaBpMeta);
    }
    if (data.containsKey('parcela_deduzir_centavos')) {
      context.handle(
        _parcelaDeduzirCentavosMeta,
        parcelaDeduzirCentavos.isAcceptableOrUnknown(
          data['parcela_deduzir_centavos']!,
          _parcelaDeduzirCentavosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_parcelaDeduzirCentavosMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tabelaId, ordem};
  @override
  CatFaixaIrpf map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CatFaixaIrpf(
      tabelaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tabela_id'],
      )!,
      ordem: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ordem'],
      )!,
      limiteSuperiorCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}limite_superior_centavos'],
      ),
      aliquotaBp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}aliquota_bp'],
      )!,
      parcelaDeduzirCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parcela_deduzir_centavos'],
      )!,
    );
  }

  @override
  CatFaixasIrpf createAlias(String alias) {
    return CatFaixasIrpf(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['PRIMARY KEY(tabela_id, ordem)'];
  @override
  bool get dontWriteConstraints => true;
}

class CatFaixaIrpf extends DataClass implements Insertable<CatFaixaIrpf> {
  final int tabelaId;
  final int ordem;
  final int? limiteSuperiorCentavos;

  /// NULL na última faixa
  final int aliquotaBp;

  /// 27,5% = 2750
  final int parcelaDeduzirCentavos;
  const CatFaixaIrpf({
    required this.tabelaId,
    required this.ordem,
    this.limiteSuperiorCentavos,
    required this.aliquotaBp,
    required this.parcelaDeduzirCentavos,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tabela_id'] = Variable<int>(tabelaId);
    map['ordem'] = Variable<int>(ordem);
    if (!nullToAbsent || limiteSuperiorCentavos != null) {
      map['limite_superior_centavos'] = Variable<int>(limiteSuperiorCentavos);
    }
    map['aliquota_bp'] = Variable<int>(aliquotaBp);
    map['parcela_deduzir_centavos'] = Variable<int>(parcelaDeduzirCentavos);
    return map;
  }

  CatFaixasIrpfCompanion toCompanion(bool nullToAbsent) {
    return CatFaixasIrpfCompanion(
      tabelaId: Value(tabelaId),
      ordem: Value(ordem),
      limiteSuperiorCentavos: limiteSuperiorCentavos == null && nullToAbsent
          ? const Value.absent()
          : Value(limiteSuperiorCentavos),
      aliquotaBp: Value(aliquotaBp),
      parcelaDeduzirCentavos: Value(parcelaDeduzirCentavos),
    );
  }

  factory CatFaixaIrpf.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CatFaixaIrpf(
      tabelaId: serializer.fromJson<int>(json['tabela_id']),
      ordem: serializer.fromJson<int>(json['ordem']),
      limiteSuperiorCentavos: serializer.fromJson<int?>(
        json['limite_superior_centavos'],
      ),
      aliquotaBp: serializer.fromJson<int>(json['aliquota_bp']),
      parcelaDeduzirCentavos: serializer.fromJson<int>(
        json['parcela_deduzir_centavos'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tabela_id': serializer.toJson<int>(tabelaId),
      'ordem': serializer.toJson<int>(ordem),
      'limite_superior_centavos': serializer.toJson<int?>(
        limiteSuperiorCentavos,
      ),
      'aliquota_bp': serializer.toJson<int>(aliquotaBp),
      'parcela_deduzir_centavos': serializer.toJson<int>(
        parcelaDeduzirCentavos,
      ),
    };
  }

  CatFaixaIrpf copyWith({
    int? tabelaId,
    int? ordem,
    Value<int?> limiteSuperiorCentavos = const Value.absent(),
    int? aliquotaBp,
    int? parcelaDeduzirCentavos,
  }) => CatFaixaIrpf(
    tabelaId: tabelaId ?? this.tabelaId,
    ordem: ordem ?? this.ordem,
    limiteSuperiorCentavos: limiteSuperiorCentavos.present
        ? limiteSuperiorCentavos.value
        : this.limiteSuperiorCentavos,
    aliquotaBp: aliquotaBp ?? this.aliquotaBp,
    parcelaDeduzirCentavos:
        parcelaDeduzirCentavos ?? this.parcelaDeduzirCentavos,
  );
  CatFaixaIrpf copyWithCompanion(CatFaixasIrpfCompanion data) {
    return CatFaixaIrpf(
      tabelaId: data.tabelaId.present ? data.tabelaId.value : this.tabelaId,
      ordem: data.ordem.present ? data.ordem.value : this.ordem,
      limiteSuperiorCentavos: data.limiteSuperiorCentavos.present
          ? data.limiteSuperiorCentavos.value
          : this.limiteSuperiorCentavos,
      aliquotaBp: data.aliquotaBp.present
          ? data.aliquotaBp.value
          : this.aliquotaBp,
      parcelaDeduzirCentavos: data.parcelaDeduzirCentavos.present
          ? data.parcelaDeduzirCentavos.value
          : this.parcelaDeduzirCentavos,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CatFaixaIrpf(')
          ..write('tabelaId: $tabelaId, ')
          ..write('ordem: $ordem, ')
          ..write('limiteSuperiorCentavos: $limiteSuperiorCentavos, ')
          ..write('aliquotaBp: $aliquotaBp, ')
          ..write('parcelaDeduzirCentavos: $parcelaDeduzirCentavos')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    tabelaId,
    ordem,
    limiteSuperiorCentavos,
    aliquotaBp,
    parcelaDeduzirCentavos,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CatFaixaIrpf &&
          other.tabelaId == this.tabelaId &&
          other.ordem == this.ordem &&
          other.limiteSuperiorCentavos == this.limiteSuperiorCentavos &&
          other.aliquotaBp == this.aliquotaBp &&
          other.parcelaDeduzirCentavos == this.parcelaDeduzirCentavos);
}

class CatFaixasIrpfCompanion extends UpdateCompanion<CatFaixaIrpf> {
  final Value<int> tabelaId;
  final Value<int> ordem;
  final Value<int?> limiteSuperiorCentavos;
  final Value<int> aliquotaBp;
  final Value<int> parcelaDeduzirCentavos;
  final Value<int> rowid;
  const CatFaixasIrpfCompanion({
    this.tabelaId = const Value.absent(),
    this.ordem = const Value.absent(),
    this.limiteSuperiorCentavos = const Value.absent(),
    this.aliquotaBp = const Value.absent(),
    this.parcelaDeduzirCentavos = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CatFaixasIrpfCompanion.insert({
    required int tabelaId,
    required int ordem,
    this.limiteSuperiorCentavos = const Value.absent(),
    required int aliquotaBp,
    required int parcelaDeduzirCentavos,
    this.rowid = const Value.absent(),
  }) : tabelaId = Value(tabelaId),
       ordem = Value(ordem),
       aliquotaBp = Value(aliquotaBp),
       parcelaDeduzirCentavos = Value(parcelaDeduzirCentavos);
  static Insertable<CatFaixaIrpf> custom({
    Expression<int>? tabelaId,
    Expression<int>? ordem,
    Expression<int>? limiteSuperiorCentavos,
    Expression<int>? aliquotaBp,
    Expression<int>? parcelaDeduzirCentavos,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tabelaId != null) 'tabela_id': tabelaId,
      if (ordem != null) 'ordem': ordem,
      if (limiteSuperiorCentavos != null)
        'limite_superior_centavos': limiteSuperiorCentavos,
      if (aliquotaBp != null) 'aliquota_bp': aliquotaBp,
      if (parcelaDeduzirCentavos != null)
        'parcela_deduzir_centavos': parcelaDeduzirCentavos,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CatFaixasIrpfCompanion copyWith({
    Value<int>? tabelaId,
    Value<int>? ordem,
    Value<int?>? limiteSuperiorCentavos,
    Value<int>? aliquotaBp,
    Value<int>? parcelaDeduzirCentavos,
    Value<int>? rowid,
  }) {
    return CatFaixasIrpfCompanion(
      tabelaId: tabelaId ?? this.tabelaId,
      ordem: ordem ?? this.ordem,
      limiteSuperiorCentavos:
          limiteSuperiorCentavos ?? this.limiteSuperiorCentavos,
      aliquotaBp: aliquotaBp ?? this.aliquotaBp,
      parcelaDeduzirCentavos:
          parcelaDeduzirCentavos ?? this.parcelaDeduzirCentavos,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tabelaId.present) {
      map['tabela_id'] = Variable<int>(tabelaId.value);
    }
    if (ordem.present) {
      map['ordem'] = Variable<int>(ordem.value);
    }
    if (limiteSuperiorCentavos.present) {
      map['limite_superior_centavos'] = Variable<int>(
        limiteSuperiorCentavos.value,
      );
    }
    if (aliquotaBp.present) {
      map['aliquota_bp'] = Variable<int>(aliquotaBp.value);
    }
    if (parcelaDeduzirCentavos.present) {
      map['parcela_deduzir_centavos'] = Variable<int>(
        parcelaDeduzirCentavos.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CatFaixasIrpfCompanion(')
          ..write('tabelaId: $tabelaId, ')
          ..write('ordem: $ordem, ')
          ..write('limiteSuperiorCentavos: $limiteSuperiorCentavos, ')
          ..write('aliquotaBp: $aliquotaBp, ')
          ..write('parcelaDeduzirCentavos: $parcelaDeduzirCentavos, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class CatParametrosFiscais extends Table
    with TableInfo<CatParametrosFiscais, CatParametroFiscal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CatParametrosFiscais(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _chaveMeta = const VerificationMeta('chave');
  late final GeneratedColumn<String> chave = GeneratedColumn<String>(
    'chave',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _vigenciaInicioMeta = const VerificationMeta(
    'vigenciaInicio',
  );
  late final GeneratedColumn<String> vigenciaInicio = GeneratedColumn<String>(
    'vigencia_inicio',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _vigenciaFimMeta = const VerificationMeta(
    'vigenciaFim',
  );
  late final GeneratedColumn<String> vigenciaFim = GeneratedColumn<String>(
    'vigencia_fim',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _valorMeta = const VerificationMeta('valor');
  late final GeneratedColumn<int> valor = GeneratedColumn<int>(
    'valor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _unidadeMeta = const VerificationMeta(
    'unidade',
  );
  late final GeneratedColumn<String> unidade = GeneratedColumn<String>(
    'unidade',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (unidade IN (\'centavos\', \'bp\', \'inteiro\'))',
  );
  static const VerificationMeta _fonteLegalMeta = const VerificationMeta(
    'fonteLegal',
  );
  late final GeneratedColumn<String> fonteLegal = GeneratedColumn<String>(
    'fonte_legal',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _statusValidacaoMeta = const VerificationMeta(
    'statusValidacao',
  );
  late final GeneratedColumn<String> statusValidacao = GeneratedColumn<String>(
    'status_validacao',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (status_validacao IN (\'validado\', \'pendente_contador\'))',
  );
  @override
  List<GeneratedColumn> get $columns => [
    chave,
    vigenciaInicio,
    vigenciaFim,
    valor,
    unidade,
    fonteLegal,
    statusValidacao,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cat_parametros_fiscais';
  @override
  VerificationContext validateIntegrity(
    Insertable<CatParametroFiscal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('chave')) {
      context.handle(
        _chaveMeta,
        chave.isAcceptableOrUnknown(data['chave']!, _chaveMeta),
      );
    } else if (isInserting) {
      context.missing(_chaveMeta);
    }
    if (data.containsKey('vigencia_inicio')) {
      context.handle(
        _vigenciaInicioMeta,
        vigenciaInicio.isAcceptableOrUnknown(
          data['vigencia_inicio']!,
          _vigenciaInicioMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_vigenciaInicioMeta);
    }
    if (data.containsKey('vigencia_fim')) {
      context.handle(
        _vigenciaFimMeta,
        vigenciaFim.isAcceptableOrUnknown(
          data['vigencia_fim']!,
          _vigenciaFimMeta,
        ),
      );
    }
    if (data.containsKey('valor')) {
      context.handle(
        _valorMeta,
        valor.isAcceptableOrUnknown(data['valor']!, _valorMeta),
      );
    } else if (isInserting) {
      context.missing(_valorMeta);
    }
    if (data.containsKey('unidade')) {
      context.handle(
        _unidadeMeta,
        unidade.isAcceptableOrUnknown(data['unidade']!, _unidadeMeta),
      );
    } else if (isInserting) {
      context.missing(_unidadeMeta);
    }
    if (data.containsKey('fonte_legal')) {
      context.handle(
        _fonteLegalMeta,
        fonteLegal.isAcceptableOrUnknown(data['fonte_legal']!, _fonteLegalMeta),
      );
    } else if (isInserting) {
      context.missing(_fonteLegalMeta);
    }
    if (data.containsKey('status_validacao')) {
      context.handle(
        _statusValidacaoMeta,
        statusValidacao.isAcceptableOrUnknown(
          data['status_validacao']!,
          _statusValidacaoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_statusValidacaoMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {chave, vigenciaInicio};
  @override
  CatParametroFiscal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CatParametroFiscal(
      chave: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chave'],
      )!,
      vigenciaInicio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vigencia_inicio'],
      )!,
      vigenciaFim: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vigencia_fim'],
      ),
      valor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}valor'],
      )!,
      unidade: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unidade'],
      )!,
      fonteLegal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fonte_legal'],
      )!,
      statusValidacao: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status_validacao'],
      )!,
    );
  }

  @override
  CatParametrosFiscais createAlias(String alias) {
    return CatParametrosFiscais(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(chave, vigencia_inicio)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class CatParametroFiscal extends DataClass
    implements Insertable<CatParametroFiscal> {
  final String chave;

  /// 'desconto_simplificado_mensal',
  final String vigenciaInicio;

  /// 'trava_home_office_pct', 'darf_minimo',
  final String? vigenciaFim;

  /// 'isencao_2026_teto', 'redutor_2026_*'
  final int valor;
  final String unidade;
  final String fonteLegal;
  final String statusValidacao;
  const CatParametroFiscal({
    required this.chave,
    required this.vigenciaInicio,
    this.vigenciaFim,
    required this.valor,
    required this.unidade,
    required this.fonteLegal,
    required this.statusValidacao,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['chave'] = Variable<String>(chave);
    map['vigencia_inicio'] = Variable<String>(vigenciaInicio);
    if (!nullToAbsent || vigenciaFim != null) {
      map['vigencia_fim'] = Variable<String>(vigenciaFim);
    }
    map['valor'] = Variable<int>(valor);
    map['unidade'] = Variable<String>(unidade);
    map['fonte_legal'] = Variable<String>(fonteLegal);
    map['status_validacao'] = Variable<String>(statusValidacao);
    return map;
  }

  CatParametrosFiscaisCompanion toCompanion(bool nullToAbsent) {
    return CatParametrosFiscaisCompanion(
      chave: Value(chave),
      vigenciaInicio: Value(vigenciaInicio),
      vigenciaFim: vigenciaFim == null && nullToAbsent
          ? const Value.absent()
          : Value(vigenciaFim),
      valor: Value(valor),
      unidade: Value(unidade),
      fonteLegal: Value(fonteLegal),
      statusValidacao: Value(statusValidacao),
    );
  }

  factory CatParametroFiscal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CatParametroFiscal(
      chave: serializer.fromJson<String>(json['chave']),
      vigenciaInicio: serializer.fromJson<String>(json['vigencia_inicio']),
      vigenciaFim: serializer.fromJson<String?>(json['vigencia_fim']),
      valor: serializer.fromJson<int>(json['valor']),
      unidade: serializer.fromJson<String>(json['unidade']),
      fonteLegal: serializer.fromJson<String>(json['fonte_legal']),
      statusValidacao: serializer.fromJson<String>(json['status_validacao']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'chave': serializer.toJson<String>(chave),
      'vigencia_inicio': serializer.toJson<String>(vigenciaInicio),
      'vigencia_fim': serializer.toJson<String?>(vigenciaFim),
      'valor': serializer.toJson<int>(valor),
      'unidade': serializer.toJson<String>(unidade),
      'fonte_legal': serializer.toJson<String>(fonteLegal),
      'status_validacao': serializer.toJson<String>(statusValidacao),
    };
  }

  CatParametroFiscal copyWith({
    String? chave,
    String? vigenciaInicio,
    Value<String?> vigenciaFim = const Value.absent(),
    int? valor,
    String? unidade,
    String? fonteLegal,
    String? statusValidacao,
  }) => CatParametroFiscal(
    chave: chave ?? this.chave,
    vigenciaInicio: vigenciaInicio ?? this.vigenciaInicio,
    vigenciaFim: vigenciaFim.present ? vigenciaFim.value : this.vigenciaFim,
    valor: valor ?? this.valor,
    unidade: unidade ?? this.unidade,
    fonteLegal: fonteLegal ?? this.fonteLegal,
    statusValidacao: statusValidacao ?? this.statusValidacao,
  );
  CatParametroFiscal copyWithCompanion(CatParametrosFiscaisCompanion data) {
    return CatParametroFiscal(
      chave: data.chave.present ? data.chave.value : this.chave,
      vigenciaInicio: data.vigenciaInicio.present
          ? data.vigenciaInicio.value
          : this.vigenciaInicio,
      vigenciaFim: data.vigenciaFim.present
          ? data.vigenciaFim.value
          : this.vigenciaFim,
      valor: data.valor.present ? data.valor.value : this.valor,
      unidade: data.unidade.present ? data.unidade.value : this.unidade,
      fonteLegal: data.fonteLegal.present
          ? data.fonteLegal.value
          : this.fonteLegal,
      statusValidacao: data.statusValidacao.present
          ? data.statusValidacao.value
          : this.statusValidacao,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CatParametroFiscal(')
          ..write('chave: $chave, ')
          ..write('vigenciaInicio: $vigenciaInicio, ')
          ..write('vigenciaFim: $vigenciaFim, ')
          ..write('valor: $valor, ')
          ..write('unidade: $unidade, ')
          ..write('fonteLegal: $fonteLegal, ')
          ..write('statusValidacao: $statusValidacao')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    chave,
    vigenciaInicio,
    vigenciaFim,
    valor,
    unidade,
    fonteLegal,
    statusValidacao,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CatParametroFiscal &&
          other.chave == this.chave &&
          other.vigenciaInicio == this.vigenciaInicio &&
          other.vigenciaFim == this.vigenciaFim &&
          other.valor == this.valor &&
          other.unidade == this.unidade &&
          other.fonteLegal == this.fonteLegal &&
          other.statusValidacao == this.statusValidacao);
}

class CatParametrosFiscaisCompanion
    extends UpdateCompanion<CatParametroFiscal> {
  final Value<String> chave;
  final Value<String> vigenciaInicio;
  final Value<String?> vigenciaFim;
  final Value<int> valor;
  final Value<String> unidade;
  final Value<String> fonteLegal;
  final Value<String> statusValidacao;
  final Value<int> rowid;
  const CatParametrosFiscaisCompanion({
    this.chave = const Value.absent(),
    this.vigenciaInicio = const Value.absent(),
    this.vigenciaFim = const Value.absent(),
    this.valor = const Value.absent(),
    this.unidade = const Value.absent(),
    this.fonteLegal = const Value.absent(),
    this.statusValidacao = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CatParametrosFiscaisCompanion.insert({
    required String chave,
    required String vigenciaInicio,
    this.vigenciaFim = const Value.absent(),
    required int valor,
    required String unidade,
    required String fonteLegal,
    required String statusValidacao,
    this.rowid = const Value.absent(),
  }) : chave = Value(chave),
       vigenciaInicio = Value(vigenciaInicio),
       valor = Value(valor),
       unidade = Value(unidade),
       fonteLegal = Value(fonteLegal),
       statusValidacao = Value(statusValidacao);
  static Insertable<CatParametroFiscal> custom({
    Expression<String>? chave,
    Expression<String>? vigenciaInicio,
    Expression<String>? vigenciaFim,
    Expression<int>? valor,
    Expression<String>? unidade,
    Expression<String>? fonteLegal,
    Expression<String>? statusValidacao,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (chave != null) 'chave': chave,
      if (vigenciaInicio != null) 'vigencia_inicio': vigenciaInicio,
      if (vigenciaFim != null) 'vigencia_fim': vigenciaFim,
      if (valor != null) 'valor': valor,
      if (unidade != null) 'unidade': unidade,
      if (fonteLegal != null) 'fonte_legal': fonteLegal,
      if (statusValidacao != null) 'status_validacao': statusValidacao,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CatParametrosFiscaisCompanion copyWith({
    Value<String>? chave,
    Value<String>? vigenciaInicio,
    Value<String?>? vigenciaFim,
    Value<int>? valor,
    Value<String>? unidade,
    Value<String>? fonteLegal,
    Value<String>? statusValidacao,
    Value<int>? rowid,
  }) {
    return CatParametrosFiscaisCompanion(
      chave: chave ?? this.chave,
      vigenciaInicio: vigenciaInicio ?? this.vigenciaInicio,
      vigenciaFim: vigenciaFim ?? this.vigenciaFim,
      valor: valor ?? this.valor,
      unidade: unidade ?? this.unidade,
      fonteLegal: fonteLegal ?? this.fonteLegal,
      statusValidacao: statusValidacao ?? this.statusValidacao,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (chave.present) {
      map['chave'] = Variable<String>(chave.value);
    }
    if (vigenciaInicio.present) {
      map['vigencia_inicio'] = Variable<String>(vigenciaInicio.value);
    }
    if (vigenciaFim.present) {
      map['vigencia_fim'] = Variable<String>(vigenciaFim.value);
    }
    if (valor.present) {
      map['valor'] = Variable<int>(valor.value);
    }
    if (unidade.present) {
      map['unidade'] = Variable<String>(unidade.value);
    }
    if (fonteLegal.present) {
      map['fonte_legal'] = Variable<String>(fonteLegal.value);
    }
    if (statusValidacao.present) {
      map['status_validacao'] = Variable<String>(statusValidacao.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CatParametrosFiscaisCompanion(')
          ..write('chave: $chave, ')
          ..write('vigenciaInicio: $vigenciaInicio, ')
          ..write('vigenciaFim: $vigenciaFim, ')
          ..write('valor: $valor, ')
          ..write('unidade: $unidade, ')
          ..write('fonteLegal: $fonteLegal, ')
          ..write('statusValidacao: $statusValidacao, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class CatFeriadosBancarios extends Table
    with TableInfo<CatFeriadosBancarios, CatFeriadoBancario> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CatFeriadosBancarios(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
    'nome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [data, nome];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cat_feriados_bancarios';
  @override
  VerificationContext validateIntegrity(
    Insertable<CatFeriadoBancario> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {data};
  @override
  CatFeriadoBancario map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CatFeriadoBancario(
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      )!,
      nome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome'],
      )!,
    );
  }

  @override
  CatFeriadosBancarios createAlias(String alias) {
    return CatFeriadosBancarios(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class CatFeriadoBancario extends DataClass
    implements Insertable<CatFeriadoBancario> {
  final String data;
  final String nome;
  const CatFeriadoBancario({required this.data, required this.nome});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['data'] = Variable<String>(data);
    map['nome'] = Variable<String>(nome);
    return map;
  }

  CatFeriadosBancariosCompanion toCompanion(bool nullToAbsent) {
    return CatFeriadosBancariosCompanion(data: Value(data), nome: Value(nome));
  }

  factory CatFeriadoBancario.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CatFeriadoBancario(
      data: serializer.fromJson<String>(json['data']),
      nome: serializer.fromJson<String>(json['nome']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'data': serializer.toJson<String>(data),
      'nome': serializer.toJson<String>(nome),
    };
  }

  CatFeriadoBancario copyWith({String? data, String? nome}) =>
      CatFeriadoBancario(data: data ?? this.data, nome: nome ?? this.nome);
  CatFeriadoBancario copyWithCompanion(CatFeriadosBancariosCompanion data) {
    return CatFeriadoBancario(
      data: data.data.present ? data.data.value : this.data,
      nome: data.nome.present ? data.nome.value : this.nome,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CatFeriadoBancario(')
          ..write('data: $data, ')
          ..write('nome: $nome')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(data, nome);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CatFeriadoBancario &&
          other.data == this.data &&
          other.nome == this.nome);
}

class CatFeriadosBancariosCompanion
    extends UpdateCompanion<CatFeriadoBancario> {
  final Value<String> data;
  final Value<String> nome;
  final Value<int> rowid;
  const CatFeriadosBancariosCompanion({
    this.data = const Value.absent(),
    this.nome = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CatFeriadosBancariosCompanion.insert({
    required String data,
    required String nome,
    this.rowid = const Value.absent(),
  }) : data = Value(data),
       nome = Value(nome);
  static Insertable<CatFeriadoBancario> custom({
    Expression<String>? data,
    Expression<String>? nome,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (data != null) 'data': data,
      if (nome != null) 'nome': nome,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CatFeriadosBancariosCompanion copyWith({
    Value<String>? data,
    Value<String>? nome,
    Value<int>? rowid,
  }) {
    return CatFeriadosBancariosCompanion(
      data: data ?? this.data,
      nome: nome ?? this.nome,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CatFeriadosBancariosCompanion(')
          ..write('data: $data, ')
          ..write('nome: $nome, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class CatRubricas extends Table with TableInfo<CatRubricas, CatRubrica> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CatRubricas(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _codigoMeta = const VerificationMeta('codigo');
  late final GeneratedColumn<String> codigo = GeneratedColumn<String>(
    'codigo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
    'nome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _dedutivelMeta = const VerificationMeta(
    'dedutivel',
  );
  late final GeneratedColumn<int> dedutivel = GeneratedColumn<int>(
    'dedutivel',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _travaHomeOfficeMeta = const VerificationMeta(
    'travaHomeOffice',
  );
  late final GeneratedColumn<int> travaHomeOffice = GeneratedColumn<int>(
    'trava_home_office',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _exigeValidacaoContadorMeta =
      const VerificationMeta('exigeValidacaoContador');
  late final GeneratedColumn<int> exigeValidacaoContador = GeneratedColumn<int>(
    'exige_validacao_contador',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _ordemMeta = const VerificationMeta('ordem');
  late final GeneratedColumn<int> ordem = GeneratedColumn<int>(
    'ordem',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _ativoMeta = const VerificationMeta('ativo');
  late final GeneratedColumn<int> ativo = GeneratedColumn<int>(
    'ativo',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 1',
    defaultValue: const CustomExpression('1'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    codigo,
    nome,
    dedutivel,
    travaHomeOffice,
    exigeValidacaoContador,
    ordem,
    ativo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cat_rubricas';
  @override
  VerificationContext validateIntegrity(
    Insertable<CatRubrica> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('codigo')) {
      context.handle(
        _codigoMeta,
        codigo.isAcceptableOrUnknown(data['codigo']!, _codigoMeta),
      );
    } else if (isInserting) {
      context.missing(_codigoMeta);
    }
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('dedutivel')) {
      context.handle(
        _dedutivelMeta,
        dedutivel.isAcceptableOrUnknown(data['dedutivel']!, _dedutivelMeta),
      );
    } else if (isInserting) {
      context.missing(_dedutivelMeta);
    }
    if (data.containsKey('trava_home_office')) {
      context.handle(
        _travaHomeOfficeMeta,
        travaHomeOffice.isAcceptableOrUnknown(
          data['trava_home_office']!,
          _travaHomeOfficeMeta,
        ),
      );
    }
    if (data.containsKey('exige_validacao_contador')) {
      context.handle(
        _exigeValidacaoContadorMeta,
        exigeValidacaoContador.isAcceptableOrUnknown(
          data['exige_validacao_contador']!,
          _exigeValidacaoContadorMeta,
        ),
      );
    }
    if (data.containsKey('ordem')) {
      context.handle(
        _ordemMeta,
        ordem.isAcceptableOrUnknown(data['ordem']!, _ordemMeta),
      );
    }
    if (data.containsKey('ativo')) {
      context.handle(
        _ativoMeta,
        ativo.isAcceptableOrUnknown(data['ativo']!, _ativoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {codigo};
  @override
  CatRubrica map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CatRubrica(
      codigo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}codigo'],
      )!,
      nome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome'],
      )!,
      dedutivel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dedutivel'],
      )!,
      travaHomeOffice: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}trava_home_office'],
      )!,
      exigeValidacaoContador: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exige_validacao_contador'],
      )!,
      ordem: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ordem'],
      ),
      ativo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ativo'],
      )!,
    );
  }

  @override
  CatRubricas createAlias(String alias) {
    return CatRubricas(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class CatRubrica extends DataClass implements Insertable<CatRubrica> {
  final String codigo;
  final String nome;
  final int dedutivel;
  final int travaHomeOffice;
  final int exigeValidacaoContador;
  final int? ordem;
  final int ativo;
  const CatRubrica({
    required this.codigo,
    required this.nome,
    required this.dedutivel,
    required this.travaHomeOffice,
    required this.exigeValidacaoContador,
    this.ordem,
    required this.ativo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['codigo'] = Variable<String>(codigo);
    map['nome'] = Variable<String>(nome);
    map['dedutivel'] = Variable<int>(dedutivel);
    map['trava_home_office'] = Variable<int>(travaHomeOffice);
    map['exige_validacao_contador'] = Variable<int>(exigeValidacaoContador);
    if (!nullToAbsent || ordem != null) {
      map['ordem'] = Variable<int>(ordem);
    }
    map['ativo'] = Variable<int>(ativo);
    return map;
  }

  CatRubricasCompanion toCompanion(bool nullToAbsent) {
    return CatRubricasCompanion(
      codigo: Value(codigo),
      nome: Value(nome),
      dedutivel: Value(dedutivel),
      travaHomeOffice: Value(travaHomeOffice),
      exigeValidacaoContador: Value(exigeValidacaoContador),
      ordem: ordem == null && nullToAbsent
          ? const Value.absent()
          : Value(ordem),
      ativo: Value(ativo),
    );
  }

  factory CatRubrica.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CatRubrica(
      codigo: serializer.fromJson<String>(json['codigo']),
      nome: serializer.fromJson<String>(json['nome']),
      dedutivel: serializer.fromJson<int>(json['dedutivel']),
      travaHomeOffice: serializer.fromJson<int>(json['trava_home_office']),
      exigeValidacaoContador: serializer.fromJson<int>(
        json['exige_validacao_contador'],
      ),
      ordem: serializer.fromJson<int?>(json['ordem']),
      ativo: serializer.fromJson<int>(json['ativo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'codigo': serializer.toJson<String>(codigo),
      'nome': serializer.toJson<String>(nome),
      'dedutivel': serializer.toJson<int>(dedutivel),
      'trava_home_office': serializer.toJson<int>(travaHomeOffice),
      'exige_validacao_contador': serializer.toJson<int>(
        exigeValidacaoContador,
      ),
      'ordem': serializer.toJson<int?>(ordem),
      'ativo': serializer.toJson<int>(ativo),
    };
  }

  CatRubrica copyWith({
    String? codigo,
    String? nome,
    int? dedutivel,
    int? travaHomeOffice,
    int? exigeValidacaoContador,
    Value<int?> ordem = const Value.absent(),
    int? ativo,
  }) => CatRubrica(
    codigo: codigo ?? this.codigo,
    nome: nome ?? this.nome,
    dedutivel: dedutivel ?? this.dedutivel,
    travaHomeOffice: travaHomeOffice ?? this.travaHomeOffice,
    exigeValidacaoContador:
        exigeValidacaoContador ?? this.exigeValidacaoContador,
    ordem: ordem.present ? ordem.value : this.ordem,
    ativo: ativo ?? this.ativo,
  );
  CatRubrica copyWithCompanion(CatRubricasCompanion data) {
    return CatRubrica(
      codigo: data.codigo.present ? data.codigo.value : this.codigo,
      nome: data.nome.present ? data.nome.value : this.nome,
      dedutivel: data.dedutivel.present ? data.dedutivel.value : this.dedutivel,
      travaHomeOffice: data.travaHomeOffice.present
          ? data.travaHomeOffice.value
          : this.travaHomeOffice,
      exigeValidacaoContador: data.exigeValidacaoContador.present
          ? data.exigeValidacaoContador.value
          : this.exigeValidacaoContador,
      ordem: data.ordem.present ? data.ordem.value : this.ordem,
      ativo: data.ativo.present ? data.ativo.value : this.ativo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CatRubrica(')
          ..write('codigo: $codigo, ')
          ..write('nome: $nome, ')
          ..write('dedutivel: $dedutivel, ')
          ..write('travaHomeOffice: $travaHomeOffice, ')
          ..write('exigeValidacaoContador: $exigeValidacaoContador, ')
          ..write('ordem: $ordem, ')
          ..write('ativo: $ativo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    codigo,
    nome,
    dedutivel,
    travaHomeOffice,
    exigeValidacaoContador,
    ordem,
    ativo,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CatRubrica &&
          other.codigo == this.codigo &&
          other.nome == this.nome &&
          other.dedutivel == this.dedutivel &&
          other.travaHomeOffice == this.travaHomeOffice &&
          other.exigeValidacaoContador == this.exigeValidacaoContador &&
          other.ordem == this.ordem &&
          other.ativo == this.ativo);
}

class CatRubricasCompanion extends UpdateCompanion<CatRubrica> {
  final Value<String> codigo;
  final Value<String> nome;
  final Value<int> dedutivel;
  final Value<int> travaHomeOffice;
  final Value<int> exigeValidacaoContador;
  final Value<int?> ordem;
  final Value<int> ativo;
  final Value<int> rowid;
  const CatRubricasCompanion({
    this.codigo = const Value.absent(),
    this.nome = const Value.absent(),
    this.dedutivel = const Value.absent(),
    this.travaHomeOffice = const Value.absent(),
    this.exigeValidacaoContador = const Value.absent(),
    this.ordem = const Value.absent(),
    this.ativo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CatRubricasCompanion.insert({
    required String codigo,
    required String nome,
    required int dedutivel,
    this.travaHomeOffice = const Value.absent(),
    this.exigeValidacaoContador = const Value.absent(),
    this.ordem = const Value.absent(),
    this.ativo = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : codigo = Value(codigo),
       nome = Value(nome),
       dedutivel = Value(dedutivel);
  static Insertable<CatRubrica> custom({
    Expression<String>? codigo,
    Expression<String>? nome,
    Expression<int>? dedutivel,
    Expression<int>? travaHomeOffice,
    Expression<int>? exigeValidacaoContador,
    Expression<int>? ordem,
    Expression<int>? ativo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (codigo != null) 'codigo': codigo,
      if (nome != null) 'nome': nome,
      if (dedutivel != null) 'dedutivel': dedutivel,
      if (travaHomeOffice != null) 'trava_home_office': travaHomeOffice,
      if (exigeValidacaoContador != null)
        'exige_validacao_contador': exigeValidacaoContador,
      if (ordem != null) 'ordem': ordem,
      if (ativo != null) 'ativo': ativo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CatRubricasCompanion copyWith({
    Value<String>? codigo,
    Value<String>? nome,
    Value<int>? dedutivel,
    Value<int>? travaHomeOffice,
    Value<int>? exigeValidacaoContador,
    Value<int?>? ordem,
    Value<int>? ativo,
    Value<int>? rowid,
  }) {
    return CatRubricasCompanion(
      codigo: codigo ?? this.codigo,
      nome: nome ?? this.nome,
      dedutivel: dedutivel ?? this.dedutivel,
      travaHomeOffice: travaHomeOffice ?? this.travaHomeOffice,
      exigeValidacaoContador:
          exigeValidacaoContador ?? this.exigeValidacaoContador,
      ordem: ordem ?? this.ordem,
      ativo: ativo ?? this.ativo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (codigo.present) {
      map['codigo'] = Variable<String>(codigo.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (dedutivel.present) {
      map['dedutivel'] = Variable<int>(dedutivel.value);
    }
    if (travaHomeOffice.present) {
      map['trava_home_office'] = Variable<int>(travaHomeOffice.value);
    }
    if (exigeValidacaoContador.present) {
      map['exige_validacao_contador'] = Variable<int>(
        exigeValidacaoContador.value,
      );
    }
    if (ordem.present) {
      map['ordem'] = Variable<int>(ordem.value);
    }
    if (ativo.present) {
      map['ativo'] = Variable<int>(ativo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CatRubricasCompanion(')
          ..write('codigo: $codigo, ')
          ..write('nome: $nome, ')
          ..write('dedutivel: $dedutivel, ')
          ..write('travaHomeOffice: $travaHomeOffice, ')
          ..write('exigeValidacaoContador: $exigeValidacaoContador, ')
          ..write('ordem: $ordem, ')
          ..write('ativo: $ativo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class CatProfissoes extends Table with TableInfo<CatProfissoes, CatProfissao> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CatProfissoes(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _codigoMeta = const VerificationMeta('codigo');
  late final GeneratedColumn<String> codigo = GeneratedColumn<String>(
    'codigo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
    'nome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _regulamentadaMeta = const VerificationMeta(
    'regulamentada',
  );
  late final GeneratedColumn<int> regulamentada = GeneratedColumn<int>(
    'regulamentada',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _conselhoMeta = const VerificationMeta(
    'conselho',
  );
  late final GeneratedColumn<String> conselho = GeneratedColumn<String>(
    'conselho',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _meiPermitidoMeta = const VerificationMeta(
    'meiPermitido',
  );
  late final GeneratedColumn<int> meiPermitido = GeneratedColumn<int>(
    'mei_permitido',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _ativoMeta = const VerificationMeta('ativo');
  late final GeneratedColumn<int> ativo = GeneratedColumn<int>(
    'ativo',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 1',
    defaultValue: const CustomExpression('1'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    codigo,
    nome,
    regulamentada,
    conselho,
    meiPermitido,
    ativo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cat_profissoes';
  @override
  VerificationContext validateIntegrity(
    Insertable<CatProfissao> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('codigo')) {
      context.handle(
        _codigoMeta,
        codigo.isAcceptableOrUnknown(data['codigo']!, _codigoMeta),
      );
    } else if (isInserting) {
      context.missing(_codigoMeta);
    }
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('regulamentada')) {
      context.handle(
        _regulamentadaMeta,
        regulamentada.isAcceptableOrUnknown(
          data['regulamentada']!,
          _regulamentadaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_regulamentadaMeta);
    }
    if (data.containsKey('conselho')) {
      context.handle(
        _conselhoMeta,
        conselho.isAcceptableOrUnknown(data['conselho']!, _conselhoMeta),
      );
    }
    if (data.containsKey('mei_permitido')) {
      context.handle(
        _meiPermitidoMeta,
        meiPermitido.isAcceptableOrUnknown(
          data['mei_permitido']!,
          _meiPermitidoMeta,
        ),
      );
    }
    if (data.containsKey('ativo')) {
      context.handle(
        _ativoMeta,
        ativo.isAcceptableOrUnknown(data['ativo']!, _ativoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {codigo};
  @override
  CatProfissao map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CatProfissao(
      codigo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}codigo'],
      )!,
      nome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome'],
      )!,
      regulamentada: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}regulamentada'],
      )!,
      conselho: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conselho'],
      ),
      meiPermitido: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mei_permitido'],
      ),
      ativo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ativo'],
      )!,
    );
  }

  @override
  CatProfissoes createAlias(String alias) {
    return CatProfissoes(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class CatProfissao extends DataClass implements Insertable<CatProfissao> {
  final String codigo;
  final String nome;
  final int regulamentada;

  /// ativa exigência de CPF do pagador
  final String? conselho;
  final int? meiPermitido;

  /// NULL = validar; alerta de radar
  final int ativo;
  const CatProfissao({
    required this.codigo,
    required this.nome,
    required this.regulamentada,
    this.conselho,
    this.meiPermitido,
    required this.ativo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['codigo'] = Variable<String>(codigo);
    map['nome'] = Variable<String>(nome);
    map['regulamentada'] = Variable<int>(regulamentada);
    if (!nullToAbsent || conselho != null) {
      map['conselho'] = Variable<String>(conselho);
    }
    if (!nullToAbsent || meiPermitido != null) {
      map['mei_permitido'] = Variable<int>(meiPermitido);
    }
    map['ativo'] = Variable<int>(ativo);
    return map;
  }

  CatProfissoesCompanion toCompanion(bool nullToAbsent) {
    return CatProfissoesCompanion(
      codigo: Value(codigo),
      nome: Value(nome),
      regulamentada: Value(regulamentada),
      conselho: conselho == null && nullToAbsent
          ? const Value.absent()
          : Value(conselho),
      meiPermitido: meiPermitido == null && nullToAbsent
          ? const Value.absent()
          : Value(meiPermitido),
      ativo: Value(ativo),
    );
  }

  factory CatProfissao.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CatProfissao(
      codigo: serializer.fromJson<String>(json['codigo']),
      nome: serializer.fromJson<String>(json['nome']),
      regulamentada: serializer.fromJson<int>(json['regulamentada']),
      conselho: serializer.fromJson<String?>(json['conselho']),
      meiPermitido: serializer.fromJson<int?>(json['mei_permitido']),
      ativo: serializer.fromJson<int>(json['ativo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'codigo': serializer.toJson<String>(codigo),
      'nome': serializer.toJson<String>(nome),
      'regulamentada': serializer.toJson<int>(regulamentada),
      'conselho': serializer.toJson<String?>(conselho),
      'mei_permitido': serializer.toJson<int?>(meiPermitido),
      'ativo': serializer.toJson<int>(ativo),
    };
  }

  CatProfissao copyWith({
    String? codigo,
    String? nome,
    int? regulamentada,
    Value<String?> conselho = const Value.absent(),
    Value<int?> meiPermitido = const Value.absent(),
    int? ativo,
  }) => CatProfissao(
    codigo: codigo ?? this.codigo,
    nome: nome ?? this.nome,
    regulamentada: regulamentada ?? this.regulamentada,
    conselho: conselho.present ? conselho.value : this.conselho,
    meiPermitido: meiPermitido.present ? meiPermitido.value : this.meiPermitido,
    ativo: ativo ?? this.ativo,
  );
  CatProfissao copyWithCompanion(CatProfissoesCompanion data) {
    return CatProfissao(
      codigo: data.codigo.present ? data.codigo.value : this.codigo,
      nome: data.nome.present ? data.nome.value : this.nome,
      regulamentada: data.regulamentada.present
          ? data.regulamentada.value
          : this.regulamentada,
      conselho: data.conselho.present ? data.conselho.value : this.conselho,
      meiPermitido: data.meiPermitido.present
          ? data.meiPermitido.value
          : this.meiPermitido,
      ativo: data.ativo.present ? data.ativo.value : this.ativo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CatProfissao(')
          ..write('codigo: $codigo, ')
          ..write('nome: $nome, ')
          ..write('regulamentada: $regulamentada, ')
          ..write('conselho: $conselho, ')
          ..write('meiPermitido: $meiPermitido, ')
          ..write('ativo: $ativo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(codigo, nome, regulamentada, conselho, meiPermitido, ativo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CatProfissao &&
          other.codigo == this.codigo &&
          other.nome == this.nome &&
          other.regulamentada == this.regulamentada &&
          other.conselho == this.conselho &&
          other.meiPermitido == this.meiPermitido &&
          other.ativo == this.ativo);
}

class CatProfissoesCompanion extends UpdateCompanion<CatProfissao> {
  final Value<String> codigo;
  final Value<String> nome;
  final Value<int> regulamentada;
  final Value<String?> conselho;
  final Value<int?> meiPermitido;
  final Value<int> ativo;
  final Value<int> rowid;
  const CatProfissoesCompanion({
    this.codigo = const Value.absent(),
    this.nome = const Value.absent(),
    this.regulamentada = const Value.absent(),
    this.conselho = const Value.absent(),
    this.meiPermitido = const Value.absent(),
    this.ativo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CatProfissoesCompanion.insert({
    required String codigo,
    required String nome,
    required int regulamentada,
    this.conselho = const Value.absent(),
    this.meiPermitido = const Value.absent(),
    this.ativo = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : codigo = Value(codigo),
       nome = Value(nome),
       regulamentada = Value(regulamentada);
  static Insertable<CatProfissao> custom({
    Expression<String>? codigo,
    Expression<String>? nome,
    Expression<int>? regulamentada,
    Expression<String>? conselho,
    Expression<int>? meiPermitido,
    Expression<int>? ativo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (codigo != null) 'codigo': codigo,
      if (nome != null) 'nome': nome,
      if (regulamentada != null) 'regulamentada': regulamentada,
      if (conselho != null) 'conselho': conselho,
      if (meiPermitido != null) 'mei_permitido': meiPermitido,
      if (ativo != null) 'ativo': ativo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CatProfissoesCompanion copyWith({
    Value<String>? codigo,
    Value<String>? nome,
    Value<int>? regulamentada,
    Value<String?>? conselho,
    Value<int?>? meiPermitido,
    Value<int>? ativo,
    Value<int>? rowid,
  }) {
    return CatProfissoesCompanion(
      codigo: codigo ?? this.codigo,
      nome: nome ?? this.nome,
      regulamentada: regulamentada ?? this.regulamentada,
      conselho: conselho ?? this.conselho,
      meiPermitido: meiPermitido ?? this.meiPermitido,
      ativo: ativo ?? this.ativo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (codigo.present) {
      map['codigo'] = Variable<String>(codigo.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (regulamentada.present) {
      map['regulamentada'] = Variable<int>(regulamentada.value);
    }
    if (conselho.present) {
      map['conselho'] = Variable<String>(conselho.value);
    }
    if (meiPermitido.present) {
      map['mei_permitido'] = Variable<int>(meiPermitido.value);
    }
    if (ativo.present) {
      map['ativo'] = Variable<int>(ativo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CatProfissoesCompanion(')
          ..write('codigo: $codigo, ')
          ..write('nome: $nome, ')
          ..write('regulamentada: $regulamentada, ')
          ..write('conselho: $conselho, ')
          ..write('meiPermitido: $meiPermitido, ')
          ..write('ativo: $ativo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class CatPerfisParser extends Table
    with TableInfo<CatPerfisParser, CatPerfilParser> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CatPerfisParser(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _codigoMeta = const VerificationMeta('codigo');
  late final GeneratedColumn<String> codigo = GeneratedColumn<String>(
    'codigo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _bancoNomeMeta = const VerificationMeta(
    'bancoNome',
  );
  late final GeneratedColumn<String> bancoNome = GeneratedColumn<String>(
    'banco_nome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _formatoMeta = const VerificationMeta(
    'formato',
  );
  late final GeneratedColumn<String> formato = GeneratedColumn<String>(
    'formato',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (formato IN (\'ofx\', \'csv\'))',
  );
  static const VerificationMeta _definicaoJsonMeta = const VerificationMeta(
    'definicaoJson',
  );
  late final GeneratedColumn<String> definicaoJson = GeneratedColumn<String>(
    'definicao_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _versaoMeta = const VerificationMeta('versao');
  late final GeneratedColumn<int> versao = GeneratedColumn<int>(
    'versao',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    codigo,
    bancoNome,
    formato,
    definicaoJson,
    versao,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cat_perfis_parser';
  @override
  VerificationContext validateIntegrity(
    Insertable<CatPerfilParser> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('codigo')) {
      context.handle(
        _codigoMeta,
        codigo.isAcceptableOrUnknown(data['codigo']!, _codigoMeta),
      );
    } else if (isInserting) {
      context.missing(_codigoMeta);
    }
    if (data.containsKey('banco_nome')) {
      context.handle(
        _bancoNomeMeta,
        bancoNome.isAcceptableOrUnknown(data['banco_nome']!, _bancoNomeMeta),
      );
    } else if (isInserting) {
      context.missing(_bancoNomeMeta);
    }
    if (data.containsKey('formato')) {
      context.handle(
        _formatoMeta,
        formato.isAcceptableOrUnknown(data['formato']!, _formatoMeta),
      );
    } else if (isInserting) {
      context.missing(_formatoMeta);
    }
    if (data.containsKey('definicao_json')) {
      context.handle(
        _definicaoJsonMeta,
        definicaoJson.isAcceptableOrUnknown(
          data['definicao_json']!,
          _definicaoJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_definicaoJsonMeta);
    }
    if (data.containsKey('versao')) {
      context.handle(
        _versaoMeta,
        versao.isAcceptableOrUnknown(data['versao']!, _versaoMeta),
      );
    } else if (isInserting) {
      context.missing(_versaoMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {codigo};
  @override
  CatPerfilParser map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CatPerfilParser(
      codigo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}codigo'],
      )!,
      bancoNome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}banco_nome'],
      )!,
      formato: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}formato'],
      )!,
      definicaoJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}definicao_json'],
      )!,
      versao: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}versao'],
      )!,
    );
  }

  @override
  CatPerfisParser createAlias(String alias) {
    return CatPerfisParser(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class CatPerfilParser extends DataClass implements Insertable<CatPerfilParser> {
  final String codigo;

  /// 'nubank_csv_v2', 'itau_ofx'
  final String bancoNome;
  final String formato;
  final String definicaoJson;
  final int versao;
  const CatPerfilParser({
    required this.codigo,
    required this.bancoNome,
    required this.formato,
    required this.definicaoJson,
    required this.versao,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['codigo'] = Variable<String>(codigo);
    map['banco_nome'] = Variable<String>(bancoNome);
    map['formato'] = Variable<String>(formato);
    map['definicao_json'] = Variable<String>(definicaoJson);
    map['versao'] = Variable<int>(versao);
    return map;
  }

  CatPerfisParserCompanion toCompanion(bool nullToAbsent) {
    return CatPerfisParserCompanion(
      codigo: Value(codigo),
      bancoNome: Value(bancoNome),
      formato: Value(formato),
      definicaoJson: Value(definicaoJson),
      versao: Value(versao),
    );
  }

  factory CatPerfilParser.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CatPerfilParser(
      codigo: serializer.fromJson<String>(json['codigo']),
      bancoNome: serializer.fromJson<String>(json['banco_nome']),
      formato: serializer.fromJson<String>(json['formato']),
      definicaoJson: serializer.fromJson<String>(json['definicao_json']),
      versao: serializer.fromJson<int>(json['versao']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'codigo': serializer.toJson<String>(codigo),
      'banco_nome': serializer.toJson<String>(bancoNome),
      'formato': serializer.toJson<String>(formato),
      'definicao_json': serializer.toJson<String>(definicaoJson),
      'versao': serializer.toJson<int>(versao),
    };
  }

  CatPerfilParser copyWith({
    String? codigo,
    String? bancoNome,
    String? formato,
    String? definicaoJson,
    int? versao,
  }) => CatPerfilParser(
    codigo: codigo ?? this.codigo,
    bancoNome: bancoNome ?? this.bancoNome,
    formato: formato ?? this.formato,
    definicaoJson: definicaoJson ?? this.definicaoJson,
    versao: versao ?? this.versao,
  );
  CatPerfilParser copyWithCompanion(CatPerfisParserCompanion data) {
    return CatPerfilParser(
      codigo: data.codigo.present ? data.codigo.value : this.codigo,
      bancoNome: data.bancoNome.present ? data.bancoNome.value : this.bancoNome,
      formato: data.formato.present ? data.formato.value : this.formato,
      definicaoJson: data.definicaoJson.present
          ? data.definicaoJson.value
          : this.definicaoJson,
      versao: data.versao.present ? data.versao.value : this.versao,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CatPerfilParser(')
          ..write('codigo: $codigo, ')
          ..write('bancoNome: $bancoNome, ')
          ..write('formato: $formato, ')
          ..write('definicaoJson: $definicaoJson, ')
          ..write('versao: $versao')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(codigo, bancoNome, formato, definicaoJson, versao);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CatPerfilParser &&
          other.codigo == this.codigo &&
          other.bancoNome == this.bancoNome &&
          other.formato == this.formato &&
          other.definicaoJson == this.definicaoJson &&
          other.versao == this.versao);
}

class CatPerfisParserCompanion extends UpdateCompanion<CatPerfilParser> {
  final Value<String> codigo;
  final Value<String> bancoNome;
  final Value<String> formato;
  final Value<String> definicaoJson;
  final Value<int> versao;
  final Value<int> rowid;
  const CatPerfisParserCompanion({
    this.codigo = const Value.absent(),
    this.bancoNome = const Value.absent(),
    this.formato = const Value.absent(),
    this.definicaoJson = const Value.absent(),
    this.versao = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CatPerfisParserCompanion.insert({
    required String codigo,
    required String bancoNome,
    required String formato,
    required String definicaoJson,
    required int versao,
    this.rowid = const Value.absent(),
  }) : codigo = Value(codigo),
       bancoNome = Value(bancoNome),
       formato = Value(formato),
       definicaoJson = Value(definicaoJson),
       versao = Value(versao);
  static Insertable<CatPerfilParser> custom({
    Expression<String>? codigo,
    Expression<String>? bancoNome,
    Expression<String>? formato,
    Expression<String>? definicaoJson,
    Expression<int>? versao,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (codigo != null) 'codigo': codigo,
      if (bancoNome != null) 'banco_nome': bancoNome,
      if (formato != null) 'formato': formato,
      if (definicaoJson != null) 'definicao_json': definicaoJson,
      if (versao != null) 'versao': versao,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CatPerfisParserCompanion copyWith({
    Value<String>? codigo,
    Value<String>? bancoNome,
    Value<String>? formato,
    Value<String>? definicaoJson,
    Value<int>? versao,
    Value<int>? rowid,
  }) {
    return CatPerfisParserCompanion(
      codigo: codigo ?? this.codigo,
      bancoNome: bancoNome ?? this.bancoNome,
      formato: formato ?? this.formato,
      definicaoJson: definicaoJson ?? this.definicaoJson,
      versao: versao ?? this.versao,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (codigo.present) {
      map['codigo'] = Variable<String>(codigo.value);
    }
    if (bancoNome.present) {
      map['banco_nome'] = Variable<String>(bancoNome.value);
    }
    if (formato.present) {
      map['formato'] = Variable<String>(formato.value);
    }
    if (definicaoJson.present) {
      map['definicao_json'] = Variable<String>(definicaoJson.value);
    }
    if (versao.present) {
      map['versao'] = Variable<int>(versao.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CatPerfisParserCompanion(')
          ..write('codigo: $codigo, ')
          ..write('bancoNome: $bancoNome, ')
          ..write('formato: $formato, ')
          ..write('definicaoJson: $definicaoJson, ')
          ..write('versao: $versao, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Perfil extends Table with TableInfo<Perfil, PerfilLocal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Perfil(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (id = 1)',
  );
  static const VerificationMeta _usuarioRemotoIdMeta = const VerificationMeta(
    'usuarioRemotoId',
  );
  late final GeneratedColumn<String> usuarioRemotoId = GeneratedColumn<String>(
    'usuario_remoto_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
    'nome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _cpfMeta = const VerificationMeta('cpf');
  late final GeneratedColumn<String> cpf = GeneratedColumn<String>(
    'cpf',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _profissaoCodigoMeta = const VerificationMeta(
    'profissaoCodigo',
  );
  late final GeneratedColumn<String> profissaoCodigo = GeneratedColumn<String>(
    'profissao_codigo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES cat_profissoes(codigo)',
  );
  static const VerificationMeta _exigeCpfPagadorMeta = const VerificationMeta(
    'exigeCpfPagador',
  );
  late final GeneratedColumn<int> exigeCpfPagador = GeneratedColumn<int>(
    'exige_cpf_pagador',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _onboardingCompletoMeta =
      const VerificationMeta('onboardingCompleto');
  late final GeneratedColumn<int> onboardingCompleto = GeneratedColumn<int>(
    'onboarding_completo',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _codigoRecuperacaoConfirmadoEmMeta =
      const VerificationMeta('codigoRecuperacaoConfirmadoEm');
  late final GeneratedColumn<int> codigoRecuperacaoConfirmadoEm =
      GeneratedColumn<int>(
        'codigo_recuperacao_confirmado_em',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        $customConstraints: '',
      );
  static const VerificationMeta _criadoEmMeta = const VerificationMeta(
    'criadoEm',
  );
  late final GeneratedColumn<int> criadoEm = GeneratedColumn<int>(
    'criado_em',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _atualizadoEmMeta = const VerificationMeta(
    'atualizadoEm',
  );
  late final GeneratedColumn<int> atualizadoEm = GeneratedColumn<int>(
    'atualizado_em',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    usuarioRemotoId,
    nome,
    cpf,
    profissaoCodigo,
    exigeCpfPagador,
    onboardingCompleto,
    codigoRecuperacaoConfirmadoEm,
    criadoEm,
    atualizadoEm,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'perfil';
  @override
  VerificationContext validateIntegrity(
    Insertable<PerfilLocal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('usuario_remoto_id')) {
      context.handle(
        _usuarioRemotoIdMeta,
        usuarioRemotoId.isAcceptableOrUnknown(
          data['usuario_remoto_id']!,
          _usuarioRemotoIdMeta,
        ),
      );
    }
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('cpf')) {
      context.handle(
        _cpfMeta,
        cpf.isAcceptableOrUnknown(data['cpf']!, _cpfMeta),
      );
    } else if (isInserting) {
      context.missing(_cpfMeta);
    }
    if (data.containsKey('profissao_codigo')) {
      context.handle(
        _profissaoCodigoMeta,
        profissaoCodigo.isAcceptableOrUnknown(
          data['profissao_codigo']!,
          _profissaoCodigoMeta,
        ),
      );
    }
    if (data.containsKey('exige_cpf_pagador')) {
      context.handle(
        _exigeCpfPagadorMeta,
        exigeCpfPagador.isAcceptableOrUnknown(
          data['exige_cpf_pagador']!,
          _exigeCpfPagadorMeta,
        ),
      );
    }
    if (data.containsKey('onboarding_completo')) {
      context.handle(
        _onboardingCompletoMeta,
        onboardingCompleto.isAcceptableOrUnknown(
          data['onboarding_completo']!,
          _onboardingCompletoMeta,
        ),
      );
    }
    if (data.containsKey('codigo_recuperacao_confirmado_em')) {
      context.handle(
        _codigoRecuperacaoConfirmadoEmMeta,
        codigoRecuperacaoConfirmadoEm.isAcceptableOrUnknown(
          data['codigo_recuperacao_confirmado_em']!,
          _codigoRecuperacaoConfirmadoEmMeta,
        ),
      );
    }
    if (data.containsKey('criado_em')) {
      context.handle(
        _criadoEmMeta,
        criadoEm.isAcceptableOrUnknown(data['criado_em']!, _criadoEmMeta),
      );
    } else if (isInserting) {
      context.missing(_criadoEmMeta);
    }
    if (data.containsKey('atualizado_em')) {
      context.handle(
        _atualizadoEmMeta,
        atualizadoEm.isAcceptableOrUnknown(
          data['atualizado_em']!,
          _atualizadoEmMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_atualizadoEmMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PerfilLocal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PerfilLocal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      usuarioRemotoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}usuario_remoto_id'],
      ),
      nome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome'],
      )!,
      cpf: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cpf'],
      )!,
      profissaoCodigo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profissao_codigo'],
      ),
      exigeCpfPagador: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exige_cpf_pagador'],
      )!,
      onboardingCompleto: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}onboarding_completo'],
      )!,
      codigoRecuperacaoConfirmadoEm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}codigo_recuperacao_confirmado_em'],
      ),
      criadoEm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}criado_em'],
      )!,
      atualizadoEm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}atualizado_em'],
      )!,
    );
  }

  @override
  Perfil createAlias(String alias) {
    return Perfil(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class PerfilLocal extends DataClass implements Insertable<PerfilLocal> {
  final int id;

  /// linha única
  final String? usuarioRemotoId;

  /// auth.users.id; NULL antes do login
  final String nome;
  final String cpf;

  /// claro dentro do arquivo cifrado
  final String? profissaoCodigo;
  final int exigeCpfPagador;
  final int onboardingCompleto;
  final int? codigoRecuperacaoConfirmadoEm;
  final int criadoEm;
  final int atualizadoEm;
  const PerfilLocal({
    required this.id,
    this.usuarioRemotoId,
    required this.nome,
    required this.cpf,
    this.profissaoCodigo,
    required this.exigeCpfPagador,
    required this.onboardingCompleto,
    this.codigoRecuperacaoConfirmadoEm,
    required this.criadoEm,
    required this.atualizadoEm,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || usuarioRemotoId != null) {
      map['usuario_remoto_id'] = Variable<String>(usuarioRemotoId);
    }
    map['nome'] = Variable<String>(nome);
    map['cpf'] = Variable<String>(cpf);
    if (!nullToAbsent || profissaoCodigo != null) {
      map['profissao_codigo'] = Variable<String>(profissaoCodigo);
    }
    map['exige_cpf_pagador'] = Variable<int>(exigeCpfPagador);
    map['onboarding_completo'] = Variable<int>(onboardingCompleto);
    if (!nullToAbsent || codigoRecuperacaoConfirmadoEm != null) {
      map['codigo_recuperacao_confirmado_em'] = Variable<int>(
        codigoRecuperacaoConfirmadoEm,
      );
    }
    map['criado_em'] = Variable<int>(criadoEm);
    map['atualizado_em'] = Variable<int>(atualizadoEm);
    return map;
  }

  PerfilCompanion toCompanion(bool nullToAbsent) {
    return PerfilCompanion(
      id: Value(id),
      usuarioRemotoId: usuarioRemotoId == null && nullToAbsent
          ? const Value.absent()
          : Value(usuarioRemotoId),
      nome: Value(nome),
      cpf: Value(cpf),
      profissaoCodigo: profissaoCodigo == null && nullToAbsent
          ? const Value.absent()
          : Value(profissaoCodigo),
      exigeCpfPagador: Value(exigeCpfPagador),
      onboardingCompleto: Value(onboardingCompleto),
      codigoRecuperacaoConfirmadoEm:
          codigoRecuperacaoConfirmadoEm == null && nullToAbsent
          ? const Value.absent()
          : Value(codigoRecuperacaoConfirmadoEm),
      criadoEm: Value(criadoEm),
      atualizadoEm: Value(atualizadoEm),
    );
  }

  factory PerfilLocal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PerfilLocal(
      id: serializer.fromJson<int>(json['id']),
      usuarioRemotoId: serializer.fromJson<String?>(json['usuario_remoto_id']),
      nome: serializer.fromJson<String>(json['nome']),
      cpf: serializer.fromJson<String>(json['cpf']),
      profissaoCodigo: serializer.fromJson<String?>(json['profissao_codigo']),
      exigeCpfPagador: serializer.fromJson<int>(json['exige_cpf_pagador']),
      onboardingCompleto: serializer.fromJson<int>(json['onboarding_completo']),
      codigoRecuperacaoConfirmadoEm: serializer.fromJson<int?>(
        json['codigo_recuperacao_confirmado_em'],
      ),
      criadoEm: serializer.fromJson<int>(json['criado_em']),
      atualizadoEm: serializer.fromJson<int>(json['atualizado_em']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'usuario_remoto_id': serializer.toJson<String?>(usuarioRemotoId),
      'nome': serializer.toJson<String>(nome),
      'cpf': serializer.toJson<String>(cpf),
      'profissao_codigo': serializer.toJson<String?>(profissaoCodigo),
      'exige_cpf_pagador': serializer.toJson<int>(exigeCpfPagador),
      'onboarding_completo': serializer.toJson<int>(onboardingCompleto),
      'codigo_recuperacao_confirmado_em': serializer.toJson<int?>(
        codigoRecuperacaoConfirmadoEm,
      ),
      'criado_em': serializer.toJson<int>(criadoEm),
      'atualizado_em': serializer.toJson<int>(atualizadoEm),
    };
  }

  PerfilLocal copyWith({
    int? id,
    Value<String?> usuarioRemotoId = const Value.absent(),
    String? nome,
    String? cpf,
    Value<String?> profissaoCodigo = const Value.absent(),
    int? exigeCpfPagador,
    int? onboardingCompleto,
    Value<int?> codigoRecuperacaoConfirmadoEm = const Value.absent(),
    int? criadoEm,
    int? atualizadoEm,
  }) => PerfilLocal(
    id: id ?? this.id,
    usuarioRemotoId: usuarioRemotoId.present
        ? usuarioRemotoId.value
        : this.usuarioRemotoId,
    nome: nome ?? this.nome,
    cpf: cpf ?? this.cpf,
    profissaoCodigo: profissaoCodigo.present
        ? profissaoCodigo.value
        : this.profissaoCodigo,
    exigeCpfPagador: exigeCpfPagador ?? this.exigeCpfPagador,
    onboardingCompleto: onboardingCompleto ?? this.onboardingCompleto,
    codigoRecuperacaoConfirmadoEm: codigoRecuperacaoConfirmadoEm.present
        ? codigoRecuperacaoConfirmadoEm.value
        : this.codigoRecuperacaoConfirmadoEm,
    criadoEm: criadoEm ?? this.criadoEm,
    atualizadoEm: atualizadoEm ?? this.atualizadoEm,
  );
  PerfilLocal copyWithCompanion(PerfilCompanion data) {
    return PerfilLocal(
      id: data.id.present ? data.id.value : this.id,
      usuarioRemotoId: data.usuarioRemotoId.present
          ? data.usuarioRemotoId.value
          : this.usuarioRemotoId,
      nome: data.nome.present ? data.nome.value : this.nome,
      cpf: data.cpf.present ? data.cpf.value : this.cpf,
      profissaoCodigo: data.profissaoCodigo.present
          ? data.profissaoCodigo.value
          : this.profissaoCodigo,
      exigeCpfPagador: data.exigeCpfPagador.present
          ? data.exigeCpfPagador.value
          : this.exigeCpfPagador,
      onboardingCompleto: data.onboardingCompleto.present
          ? data.onboardingCompleto.value
          : this.onboardingCompleto,
      codigoRecuperacaoConfirmadoEm: data.codigoRecuperacaoConfirmadoEm.present
          ? data.codigoRecuperacaoConfirmadoEm.value
          : this.codigoRecuperacaoConfirmadoEm,
      criadoEm: data.criadoEm.present ? data.criadoEm.value : this.criadoEm,
      atualizadoEm: data.atualizadoEm.present
          ? data.atualizadoEm.value
          : this.atualizadoEm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PerfilLocal(')
          ..write('id: $id, ')
          ..write('usuarioRemotoId: $usuarioRemotoId, ')
          ..write('nome: $nome, ')
          ..write('cpf: $cpf, ')
          ..write('profissaoCodigo: $profissaoCodigo, ')
          ..write('exigeCpfPagador: $exigeCpfPagador, ')
          ..write('onboardingCompleto: $onboardingCompleto, ')
          ..write(
            'codigoRecuperacaoConfirmadoEm: $codigoRecuperacaoConfirmadoEm, ',
          )
          ..write('criadoEm: $criadoEm, ')
          ..write('atualizadoEm: $atualizadoEm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    usuarioRemotoId,
    nome,
    cpf,
    profissaoCodigo,
    exigeCpfPagador,
    onboardingCompleto,
    codigoRecuperacaoConfirmadoEm,
    criadoEm,
    atualizadoEm,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PerfilLocal &&
          other.id == this.id &&
          other.usuarioRemotoId == this.usuarioRemotoId &&
          other.nome == this.nome &&
          other.cpf == this.cpf &&
          other.profissaoCodigo == this.profissaoCodigo &&
          other.exigeCpfPagador == this.exigeCpfPagador &&
          other.onboardingCompleto == this.onboardingCompleto &&
          other.codigoRecuperacaoConfirmadoEm ==
              this.codigoRecuperacaoConfirmadoEm &&
          other.criadoEm == this.criadoEm &&
          other.atualizadoEm == this.atualizadoEm);
}

class PerfilCompanion extends UpdateCompanion<PerfilLocal> {
  final Value<int> id;
  final Value<String?> usuarioRemotoId;
  final Value<String> nome;
  final Value<String> cpf;
  final Value<String?> profissaoCodigo;
  final Value<int> exigeCpfPagador;
  final Value<int> onboardingCompleto;
  final Value<int?> codigoRecuperacaoConfirmadoEm;
  final Value<int> criadoEm;
  final Value<int> atualizadoEm;
  const PerfilCompanion({
    this.id = const Value.absent(),
    this.usuarioRemotoId = const Value.absent(),
    this.nome = const Value.absent(),
    this.cpf = const Value.absent(),
    this.profissaoCodigo = const Value.absent(),
    this.exigeCpfPagador = const Value.absent(),
    this.onboardingCompleto = const Value.absent(),
    this.codigoRecuperacaoConfirmadoEm = const Value.absent(),
    this.criadoEm = const Value.absent(),
    this.atualizadoEm = const Value.absent(),
  });
  PerfilCompanion.insert({
    this.id = const Value.absent(),
    this.usuarioRemotoId = const Value.absent(),
    required String nome,
    required String cpf,
    this.profissaoCodigo = const Value.absent(),
    this.exigeCpfPagador = const Value.absent(),
    this.onboardingCompleto = const Value.absent(),
    this.codigoRecuperacaoConfirmadoEm = const Value.absent(),
    required int criadoEm,
    required int atualizadoEm,
  }) : nome = Value(nome),
       cpf = Value(cpf),
       criadoEm = Value(criadoEm),
       atualizadoEm = Value(atualizadoEm);
  static Insertable<PerfilLocal> custom({
    Expression<int>? id,
    Expression<String>? usuarioRemotoId,
    Expression<String>? nome,
    Expression<String>? cpf,
    Expression<String>? profissaoCodigo,
    Expression<int>? exigeCpfPagador,
    Expression<int>? onboardingCompleto,
    Expression<int>? codigoRecuperacaoConfirmadoEm,
    Expression<int>? criadoEm,
    Expression<int>? atualizadoEm,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (usuarioRemotoId != null) 'usuario_remoto_id': usuarioRemotoId,
      if (nome != null) 'nome': nome,
      if (cpf != null) 'cpf': cpf,
      if (profissaoCodigo != null) 'profissao_codigo': profissaoCodigo,
      if (exigeCpfPagador != null) 'exige_cpf_pagador': exigeCpfPagador,
      if (onboardingCompleto != null) 'onboarding_completo': onboardingCompleto,
      if (codigoRecuperacaoConfirmadoEm != null)
        'codigo_recuperacao_confirmado_em': codigoRecuperacaoConfirmadoEm,
      if (criadoEm != null) 'criado_em': criadoEm,
      if (atualizadoEm != null) 'atualizado_em': atualizadoEm,
    });
  }

  PerfilCompanion copyWith({
    Value<int>? id,
    Value<String?>? usuarioRemotoId,
    Value<String>? nome,
    Value<String>? cpf,
    Value<String?>? profissaoCodigo,
    Value<int>? exigeCpfPagador,
    Value<int>? onboardingCompleto,
    Value<int?>? codigoRecuperacaoConfirmadoEm,
    Value<int>? criadoEm,
    Value<int>? atualizadoEm,
  }) {
    return PerfilCompanion(
      id: id ?? this.id,
      usuarioRemotoId: usuarioRemotoId ?? this.usuarioRemotoId,
      nome: nome ?? this.nome,
      cpf: cpf ?? this.cpf,
      profissaoCodigo: profissaoCodigo ?? this.profissaoCodigo,
      exigeCpfPagador: exigeCpfPagador ?? this.exigeCpfPagador,
      onboardingCompleto: onboardingCompleto ?? this.onboardingCompleto,
      codigoRecuperacaoConfirmadoEm:
          codigoRecuperacaoConfirmadoEm ?? this.codigoRecuperacaoConfirmadoEm,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (usuarioRemotoId.present) {
      map['usuario_remoto_id'] = Variable<String>(usuarioRemotoId.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (cpf.present) {
      map['cpf'] = Variable<String>(cpf.value);
    }
    if (profissaoCodigo.present) {
      map['profissao_codigo'] = Variable<String>(profissaoCodigo.value);
    }
    if (exigeCpfPagador.present) {
      map['exige_cpf_pagador'] = Variable<int>(exigeCpfPagador.value);
    }
    if (onboardingCompleto.present) {
      map['onboarding_completo'] = Variable<int>(onboardingCompleto.value);
    }
    if (codigoRecuperacaoConfirmadoEm.present) {
      map['codigo_recuperacao_confirmado_em'] = Variable<int>(
        codigoRecuperacaoConfirmadoEm.value,
      );
    }
    if (criadoEm.present) {
      map['criado_em'] = Variable<int>(criadoEm.value);
    }
    if (atualizadoEm.present) {
      map['atualizado_em'] = Variable<int>(atualizadoEm.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PerfilCompanion(')
          ..write('id: $id, ')
          ..write('usuarioRemotoId: $usuarioRemotoId, ')
          ..write('nome: $nome, ')
          ..write('cpf: $cpf, ')
          ..write('profissaoCodigo: $profissaoCodigo, ')
          ..write('exigeCpfPagador: $exigeCpfPagador, ')
          ..write('onboardingCompleto: $onboardingCompleto, ')
          ..write(
            'codigoRecuperacaoConfirmadoEm: $codigoRecuperacaoConfirmadoEm, ',
          )
          ..write('criadoEm: $criadoEm, ')
          ..write('atualizadoEm: $atualizadoEm')
          ..write(')'))
        .toString();
  }
}

class AceitesTermosLocal extends Table
    with TableInfo<AceitesTermosLocal, AceiteTermosLocal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  AceitesTermosLocal(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _documentoMeta = const VerificationMeta(
    'documento',
  );
  late final GeneratedColumn<String> documento = GeneratedColumn<String>(
    'documento',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (documento IN (\'termos_uso\', \'politica_privacidade\'))',
  );
  static const VerificationMeta _versaoMeta = const VerificationMeta('versao');
  late final GeneratedColumn<String> versao = GeneratedColumn<String>(
    'versao',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _aceitoEmMeta = const VerificationMeta(
    'aceitoEm',
  );
  late final GeneratedColumn<int> aceitoEm = GeneratedColumn<int>(
    'aceito_em',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _sincronizadoMeta = const VerificationMeta(
    'sincronizado',
  );
  late final GeneratedColumn<int> sincronizado = GeneratedColumn<int>(
    'sincronizado',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    documento,
    versao,
    aceitoEm,
    sincronizado,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'aceites_termos_local';
  @override
  VerificationContext validateIntegrity(
    Insertable<AceiteTermosLocal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('documento')) {
      context.handle(
        _documentoMeta,
        documento.isAcceptableOrUnknown(data['documento']!, _documentoMeta),
      );
    } else if (isInserting) {
      context.missing(_documentoMeta);
    }
    if (data.containsKey('versao')) {
      context.handle(
        _versaoMeta,
        versao.isAcceptableOrUnknown(data['versao']!, _versaoMeta),
      );
    } else if (isInserting) {
      context.missing(_versaoMeta);
    }
    if (data.containsKey('aceito_em')) {
      context.handle(
        _aceitoEmMeta,
        aceitoEm.isAcceptableOrUnknown(data['aceito_em']!, _aceitoEmMeta),
      );
    } else if (isInserting) {
      context.missing(_aceitoEmMeta);
    }
    if (data.containsKey('sincronizado')) {
      context.handle(
        _sincronizadoMeta,
        sincronizado.isAcceptableOrUnknown(
          data['sincronizado']!,
          _sincronizadoMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {documento, versao};
  @override
  AceiteTermosLocal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AceiteTermosLocal(
      documento: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}documento'],
      )!,
      versao: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}versao'],
      )!,
      aceitoEm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}aceito_em'],
      )!,
      sincronizado: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sincronizado'],
      )!,
    );
  }

  @override
  AceitesTermosLocal createAlias(String alias) {
    return AceitesTermosLocal(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(documento, versao)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class AceiteTermosLocal extends DataClass
    implements Insertable<AceiteTermosLocal> {
  /// espelho; o registro que vale está no servidor
  final String documento;
  final String versao;
  final int aceitoEm;
  final int sincronizado;
  const AceiteTermosLocal({
    required this.documento,
    required this.versao,
    required this.aceitoEm,
    required this.sincronizado,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['documento'] = Variable<String>(documento);
    map['versao'] = Variable<String>(versao);
    map['aceito_em'] = Variable<int>(aceitoEm);
    map['sincronizado'] = Variable<int>(sincronizado);
    return map;
  }

  AceitesTermosLocalCompanion toCompanion(bool nullToAbsent) {
    return AceitesTermosLocalCompanion(
      documento: Value(documento),
      versao: Value(versao),
      aceitoEm: Value(aceitoEm),
      sincronizado: Value(sincronizado),
    );
  }

  factory AceiteTermosLocal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AceiteTermosLocal(
      documento: serializer.fromJson<String>(json['documento']),
      versao: serializer.fromJson<String>(json['versao']),
      aceitoEm: serializer.fromJson<int>(json['aceito_em']),
      sincronizado: serializer.fromJson<int>(json['sincronizado']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'documento': serializer.toJson<String>(documento),
      'versao': serializer.toJson<String>(versao),
      'aceito_em': serializer.toJson<int>(aceitoEm),
      'sincronizado': serializer.toJson<int>(sincronizado),
    };
  }

  AceiteTermosLocal copyWith({
    String? documento,
    String? versao,
    int? aceitoEm,
    int? sincronizado,
  }) => AceiteTermosLocal(
    documento: documento ?? this.documento,
    versao: versao ?? this.versao,
    aceitoEm: aceitoEm ?? this.aceitoEm,
    sincronizado: sincronizado ?? this.sincronizado,
  );
  AceiteTermosLocal copyWithCompanion(AceitesTermosLocalCompanion data) {
    return AceiteTermosLocal(
      documento: data.documento.present ? data.documento.value : this.documento,
      versao: data.versao.present ? data.versao.value : this.versao,
      aceitoEm: data.aceitoEm.present ? data.aceitoEm.value : this.aceitoEm,
      sincronizado: data.sincronizado.present
          ? data.sincronizado.value
          : this.sincronizado,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AceiteTermosLocal(')
          ..write('documento: $documento, ')
          ..write('versao: $versao, ')
          ..write('aceitoEm: $aceitoEm, ')
          ..write('sincronizado: $sincronizado')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(documento, versao, aceitoEm, sincronizado);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AceiteTermosLocal &&
          other.documento == this.documento &&
          other.versao == this.versao &&
          other.aceitoEm == this.aceitoEm &&
          other.sincronizado == this.sincronizado);
}

class AceitesTermosLocalCompanion extends UpdateCompanion<AceiteTermosLocal> {
  final Value<String> documento;
  final Value<String> versao;
  final Value<int> aceitoEm;
  final Value<int> sincronizado;
  final Value<int> rowid;
  const AceitesTermosLocalCompanion({
    this.documento = const Value.absent(),
    this.versao = const Value.absent(),
    this.aceitoEm = const Value.absent(),
    this.sincronizado = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AceitesTermosLocalCompanion.insert({
    required String documento,
    required String versao,
    required int aceitoEm,
    this.sincronizado = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : documento = Value(documento),
       versao = Value(versao),
       aceitoEm = Value(aceitoEm);
  static Insertable<AceiteTermosLocal> custom({
    Expression<String>? documento,
    Expression<String>? versao,
    Expression<int>? aceitoEm,
    Expression<int>? sincronizado,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (documento != null) 'documento': documento,
      if (versao != null) 'versao': versao,
      if (aceitoEm != null) 'aceito_em': aceitoEm,
      if (sincronizado != null) 'sincronizado': sincronizado,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AceitesTermosLocalCompanion copyWith({
    Value<String>? documento,
    Value<String>? versao,
    Value<int>? aceitoEm,
    Value<int>? sincronizado,
    Value<int>? rowid,
  }) {
    return AceitesTermosLocalCompanion(
      documento: documento ?? this.documento,
      versao: versao ?? this.versao,
      aceitoEm: aceitoEm ?? this.aceitoEm,
      sincronizado: sincronizado ?? this.sincronizado,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (documento.present) {
      map['documento'] = Variable<String>(documento.value);
    }
    if (versao.present) {
      map['versao'] = Variable<String>(versao.value);
    }
    if (aceitoEm.present) {
      map['aceito_em'] = Variable<int>(aceitoEm.value);
    }
    if (sincronizado.present) {
      map['sincronizado'] = Variable<int>(sincronizado.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AceitesTermosLocalCompanion(')
          ..write('documento: $documento, ')
          ..write('versao: $versao, ')
          ..write('aceitoEm: $aceitoEm, ')
          ..write('sincronizado: $sincronizado, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ContasBancarias extends Table
    with TableInfo<ContasBancarias, ContaBancaria> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ContasBancarias(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _apelidoMeta = const VerificationMeta(
    'apelido',
  );
  late final GeneratedColumn<String> apelido = GeneratedColumn<String>(
    'apelido',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _bancoCodigoMeta = const VerificationMeta(
    'bancoCodigo',
  );
  late final GeneratedColumn<String> bancoCodigo = GeneratedColumn<String>(
    'banco_codigo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _origemMeta = const VerificationMeta('origem');
  late final GeneratedColumn<String> origem = GeneratedColumn<String>(
    'origem',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT \'manual\' CHECK (origem IN (\'manual\', \'open_finance\'))',
    defaultValue: const CustomExpression('\'manual\''),
  );
  static const VerificationMeta _ativaMeta = const VerificationMeta('ativa');
  late final GeneratedColumn<int> ativa = GeneratedColumn<int>(
    'ativa',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 1',
    defaultValue: const CustomExpression('1'),
  );
  static const VerificationMeta _criadoEmMeta = const VerificationMeta(
    'criadoEm',
  );
  late final GeneratedColumn<int> criadoEm = GeneratedColumn<int>(
    'criado_em',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    apelido,
    bancoCodigo,
    origem,
    ativa,
    criadoEm,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contas_bancarias';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContaBancaria> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('apelido')) {
      context.handle(
        _apelidoMeta,
        apelido.isAcceptableOrUnknown(data['apelido']!, _apelidoMeta),
      );
    } else if (isInserting) {
      context.missing(_apelidoMeta);
    }
    if (data.containsKey('banco_codigo')) {
      context.handle(
        _bancoCodigoMeta,
        bancoCodigo.isAcceptableOrUnknown(
          data['banco_codigo']!,
          _bancoCodigoMeta,
        ),
      );
    }
    if (data.containsKey('origem')) {
      context.handle(
        _origemMeta,
        origem.isAcceptableOrUnknown(data['origem']!, _origemMeta),
      );
    }
    if (data.containsKey('ativa')) {
      context.handle(
        _ativaMeta,
        ativa.isAcceptableOrUnknown(data['ativa']!, _ativaMeta),
      );
    }
    if (data.containsKey('criado_em')) {
      context.handle(
        _criadoEmMeta,
        criadoEm.isAcceptableOrUnknown(data['criado_em']!, _criadoEmMeta),
      );
    } else if (isInserting) {
      context.missing(_criadoEmMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ContaBancaria map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContaBancaria(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      apelido: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}apelido'],
      )!,
      bancoCodigo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}banco_codigo'],
      ),
      origem: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origem'],
      )!,
      ativa: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ativa'],
      )!,
      criadoEm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}criado_em'],
      )!,
    );
  }

  @override
  ContasBancarias createAlias(String alias) {
    return ContasBancarias(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class ContaBancaria extends DataClass implements Insertable<ContaBancaria> {
  final String id;
  final String apelido;
  final String? bancoCodigo;
  final String origem;

  /// open_finance = Fase 2
  final int ativa;
  final int criadoEm;
  const ContaBancaria({
    required this.id,
    required this.apelido,
    this.bancoCodigo,
    required this.origem,
    required this.ativa,
    required this.criadoEm,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['apelido'] = Variable<String>(apelido);
    if (!nullToAbsent || bancoCodigo != null) {
      map['banco_codigo'] = Variable<String>(bancoCodigo);
    }
    map['origem'] = Variable<String>(origem);
    map['ativa'] = Variable<int>(ativa);
    map['criado_em'] = Variable<int>(criadoEm);
    return map;
  }

  ContasBancariasCompanion toCompanion(bool nullToAbsent) {
    return ContasBancariasCompanion(
      id: Value(id),
      apelido: Value(apelido),
      bancoCodigo: bancoCodigo == null && nullToAbsent
          ? const Value.absent()
          : Value(bancoCodigo),
      origem: Value(origem),
      ativa: Value(ativa),
      criadoEm: Value(criadoEm),
    );
  }

  factory ContaBancaria.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContaBancaria(
      id: serializer.fromJson<String>(json['id']),
      apelido: serializer.fromJson<String>(json['apelido']),
      bancoCodigo: serializer.fromJson<String?>(json['banco_codigo']),
      origem: serializer.fromJson<String>(json['origem']),
      ativa: serializer.fromJson<int>(json['ativa']),
      criadoEm: serializer.fromJson<int>(json['criado_em']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'apelido': serializer.toJson<String>(apelido),
      'banco_codigo': serializer.toJson<String?>(bancoCodigo),
      'origem': serializer.toJson<String>(origem),
      'ativa': serializer.toJson<int>(ativa),
      'criado_em': serializer.toJson<int>(criadoEm),
    };
  }

  ContaBancaria copyWith({
    String? id,
    String? apelido,
    Value<String?> bancoCodigo = const Value.absent(),
    String? origem,
    int? ativa,
    int? criadoEm,
  }) => ContaBancaria(
    id: id ?? this.id,
    apelido: apelido ?? this.apelido,
    bancoCodigo: bancoCodigo.present ? bancoCodigo.value : this.bancoCodigo,
    origem: origem ?? this.origem,
    ativa: ativa ?? this.ativa,
    criadoEm: criadoEm ?? this.criadoEm,
  );
  ContaBancaria copyWithCompanion(ContasBancariasCompanion data) {
    return ContaBancaria(
      id: data.id.present ? data.id.value : this.id,
      apelido: data.apelido.present ? data.apelido.value : this.apelido,
      bancoCodigo: data.bancoCodigo.present
          ? data.bancoCodigo.value
          : this.bancoCodigo,
      origem: data.origem.present ? data.origem.value : this.origem,
      ativa: data.ativa.present ? data.ativa.value : this.ativa,
      criadoEm: data.criadoEm.present ? data.criadoEm.value : this.criadoEm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContaBancaria(')
          ..write('id: $id, ')
          ..write('apelido: $apelido, ')
          ..write('bancoCodigo: $bancoCodigo, ')
          ..write('origem: $origem, ')
          ..write('ativa: $ativa, ')
          ..write('criadoEm: $criadoEm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, apelido, bancoCodigo, origem, ativa, criadoEm);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContaBancaria &&
          other.id == this.id &&
          other.apelido == this.apelido &&
          other.bancoCodigo == this.bancoCodigo &&
          other.origem == this.origem &&
          other.ativa == this.ativa &&
          other.criadoEm == this.criadoEm);
}

class ContasBancariasCompanion extends UpdateCompanion<ContaBancaria> {
  final Value<String> id;
  final Value<String> apelido;
  final Value<String?> bancoCodigo;
  final Value<String> origem;
  final Value<int> ativa;
  final Value<int> criadoEm;
  final Value<int> rowid;
  const ContasBancariasCompanion({
    this.id = const Value.absent(),
    this.apelido = const Value.absent(),
    this.bancoCodigo = const Value.absent(),
    this.origem = const Value.absent(),
    this.ativa = const Value.absent(),
    this.criadoEm = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContasBancariasCompanion.insert({
    required String id,
    required String apelido,
    this.bancoCodigo = const Value.absent(),
    this.origem = const Value.absent(),
    this.ativa = const Value.absent(),
    required int criadoEm,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       apelido = Value(apelido),
       criadoEm = Value(criadoEm);
  static Insertable<ContaBancaria> custom({
    Expression<String>? id,
    Expression<String>? apelido,
    Expression<String>? bancoCodigo,
    Expression<String>? origem,
    Expression<int>? ativa,
    Expression<int>? criadoEm,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (apelido != null) 'apelido': apelido,
      if (bancoCodigo != null) 'banco_codigo': bancoCodigo,
      if (origem != null) 'origem': origem,
      if (ativa != null) 'ativa': ativa,
      if (criadoEm != null) 'criado_em': criadoEm,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContasBancariasCompanion copyWith({
    Value<String>? id,
    Value<String>? apelido,
    Value<String?>? bancoCodigo,
    Value<String>? origem,
    Value<int>? ativa,
    Value<int>? criadoEm,
    Value<int>? rowid,
  }) {
    return ContasBancariasCompanion(
      id: id ?? this.id,
      apelido: apelido ?? this.apelido,
      bancoCodigo: bancoCodigo ?? this.bancoCodigo,
      origem: origem ?? this.origem,
      ativa: ativa ?? this.ativa,
      criadoEm: criadoEm ?? this.criadoEm,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (apelido.present) {
      map['apelido'] = Variable<String>(apelido.value);
    }
    if (bancoCodigo.present) {
      map['banco_codigo'] = Variable<String>(bancoCodigo.value);
    }
    if (origem.present) {
      map['origem'] = Variable<String>(origem.value);
    }
    if (ativa.present) {
      map['ativa'] = Variable<int>(ativa.value);
    }
    if (criadoEm.present) {
      map['criado_em'] = Variable<int>(criadoEm.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContasBancariasCompanion(')
          ..write('id: $id, ')
          ..write('apelido: $apelido, ')
          ..write('bancoCodigo: $bancoCodigo, ')
          ..write('origem: $origem, ')
          ..write('ativa: $ativa, ')
          ..write('criadoEm: $criadoEm, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Importacoes extends Table with TableInfo<Importacoes, Importacao> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Importacoes(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _contaIdMeta = const VerificationMeta(
    'contaId',
  );
  late final GeneratedColumn<String> contaId = GeneratedColumn<String>(
    'conta_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES contas_bancarias(id)',
  );
  static const VerificationMeta _formatoMeta = const VerificationMeta(
    'formato',
  );
  late final GeneratedColumn<String> formato = GeneratedColumn<String>(
    'formato',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (formato IN (\'ofx\', \'csv\'))',
  );
  static const VerificationMeta _nomeArquivoMeta = const VerificationMeta(
    'nomeArquivo',
  );
  late final GeneratedColumn<String> nomeArquivo = GeneratedColumn<String>(
    'nome_arquivo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _hashArquivoMeta = const VerificationMeta(
    'hashArquivo',
  );
  late final GeneratedColumn<String> hashArquivo = GeneratedColumn<String>(
    'hash_arquivo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _parserCodigoMeta = const VerificationMeta(
    'parserCodigo',
  );
  late final GeneratedColumn<String> parserCodigo = GeneratedColumn<String>(
    'parser_codigo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _parserVersaoMeta = const VerificationMeta(
    'parserVersao',
  );
  late final GeneratedColumn<int> parserVersao = GeneratedColumn<int>(
    'parser_versao',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _previaJsonMeta = const VerificationMeta(
    'previaJson',
  );
  late final GeneratedColumn<String> previaJson = GeneratedColumn<String>(
    'previa_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _periodoInicioMeta = const VerificationMeta(
    'periodoInicio',
  );
  late final GeneratedColumn<String> periodoInicio = GeneratedColumn<String>(
    'periodo_inicio',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _periodoFimMeta = const VerificationMeta(
    'periodoFim',
  );
  late final GeneratedColumn<String> periodoFim = GeneratedColumn<String>(
    'periodo_fim',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _totalLinhasMeta = const VerificationMeta(
    'totalLinhas',
  );
  late final GeneratedColumn<int> totalLinhas = GeneratedColumn<int>(
    'total_linhas',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _totalImportadasMeta = const VerificationMeta(
    'totalImportadas',
  );
  late final GeneratedColumn<int> totalImportadas = GeneratedColumn<int>(
    'total_importadas',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _totalDuplicadasMeta = const VerificationMeta(
    'totalDuplicadas',
  );
  late final GeneratedColumn<int> totalDuplicadas = GeneratedColumn<int>(
    'total_duplicadas',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _totalIgnoradasMeta = const VerificationMeta(
    'totalIgnoradas',
  );
  late final GeneratedColumn<int> totalIgnoradas = GeneratedColumn<int>(
    'total_ignoradas',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT \'previa\' CHECK (status IN (\'previa\', \'confirmada\', \'descartada\', \'erro\'))',
    defaultValue: const CustomExpression('\'previa\''),
  );
  static const VerificationMeta _erroDetalheMeta = const VerificationMeta(
    'erroDetalhe',
  );
  late final GeneratedColumn<String> erroDetalhe = GeneratedColumn<String>(
    'erro_detalhe',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _criadoEmMeta = const VerificationMeta(
    'criadoEm',
  );
  late final GeneratedColumn<int> criadoEm = GeneratedColumn<int>(
    'criado_em',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    contaId,
    formato,
    nomeArquivo,
    hashArquivo,
    parserCodigo,
    parserVersao,
    previaJson,
    periodoInicio,
    periodoFim,
    totalLinhas,
    totalImportadas,
    totalDuplicadas,
    totalIgnoradas,
    status,
    erroDetalhe,
    criadoEm,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'importacoes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Importacao> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('conta_id')) {
      context.handle(
        _contaIdMeta,
        contaId.isAcceptableOrUnknown(data['conta_id']!, _contaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_contaIdMeta);
    }
    if (data.containsKey('formato')) {
      context.handle(
        _formatoMeta,
        formato.isAcceptableOrUnknown(data['formato']!, _formatoMeta),
      );
    } else if (isInserting) {
      context.missing(_formatoMeta);
    }
    if (data.containsKey('nome_arquivo')) {
      context.handle(
        _nomeArquivoMeta,
        nomeArquivo.isAcceptableOrUnknown(
          data['nome_arquivo']!,
          _nomeArquivoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nomeArquivoMeta);
    }
    if (data.containsKey('hash_arquivo')) {
      context.handle(
        _hashArquivoMeta,
        hashArquivo.isAcceptableOrUnknown(
          data['hash_arquivo']!,
          _hashArquivoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_hashArquivoMeta);
    }
    if (data.containsKey('parser_codigo')) {
      context.handle(
        _parserCodigoMeta,
        parserCodigo.isAcceptableOrUnknown(
          data['parser_codigo']!,
          _parserCodigoMeta,
        ),
      );
    }
    if (data.containsKey('parser_versao')) {
      context.handle(
        _parserVersaoMeta,
        parserVersao.isAcceptableOrUnknown(
          data['parser_versao']!,
          _parserVersaoMeta,
        ),
      );
    }
    if (data.containsKey('previa_json')) {
      context.handle(
        _previaJsonMeta,
        previaJson.isAcceptableOrUnknown(data['previa_json']!, _previaJsonMeta),
      );
    }
    if (data.containsKey('periodo_inicio')) {
      context.handle(
        _periodoInicioMeta,
        periodoInicio.isAcceptableOrUnknown(
          data['periodo_inicio']!,
          _periodoInicioMeta,
        ),
      );
    }
    if (data.containsKey('periodo_fim')) {
      context.handle(
        _periodoFimMeta,
        periodoFim.isAcceptableOrUnknown(data['periodo_fim']!, _periodoFimMeta),
      );
    }
    if (data.containsKey('total_linhas')) {
      context.handle(
        _totalLinhasMeta,
        totalLinhas.isAcceptableOrUnknown(
          data['total_linhas']!,
          _totalLinhasMeta,
        ),
      );
    }
    if (data.containsKey('total_importadas')) {
      context.handle(
        _totalImportadasMeta,
        totalImportadas.isAcceptableOrUnknown(
          data['total_importadas']!,
          _totalImportadasMeta,
        ),
      );
    }
    if (data.containsKey('total_duplicadas')) {
      context.handle(
        _totalDuplicadasMeta,
        totalDuplicadas.isAcceptableOrUnknown(
          data['total_duplicadas']!,
          _totalDuplicadasMeta,
        ),
      );
    }
    if (data.containsKey('total_ignoradas')) {
      context.handle(
        _totalIgnoradasMeta,
        totalIgnoradas.isAcceptableOrUnknown(
          data['total_ignoradas']!,
          _totalIgnoradasMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('erro_detalhe')) {
      context.handle(
        _erroDetalheMeta,
        erroDetalhe.isAcceptableOrUnknown(
          data['erro_detalhe']!,
          _erroDetalheMeta,
        ),
      );
    }
    if (data.containsKey('criado_em')) {
      context.handle(
        _criadoEmMeta,
        criadoEm.isAcceptableOrUnknown(data['criado_em']!, _criadoEmMeta),
      );
    } else if (isInserting) {
      context.missing(_criadoEmMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Importacao map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Importacao(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      contaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conta_id'],
      )!,
      formato: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}formato'],
      )!,
      nomeArquivo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome_arquivo'],
      )!,
      hashArquivo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash_arquivo'],
      )!,
      parserCodigo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parser_codigo'],
      ),
      parserVersao: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parser_versao'],
      ),
      previaJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}previa_json'],
      ),
      periodoInicio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}periodo_inicio'],
      ),
      periodoFim: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}periodo_fim'],
      ),
      totalLinhas: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_linhas'],
      ),
      totalImportadas: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_importadas'],
      ),
      totalDuplicadas: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_duplicadas'],
      ),
      totalIgnoradas: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_ignoradas'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      erroDetalhe: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}erro_detalhe'],
      ),
      criadoEm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}criado_em'],
      )!,
    );
  }

  @override
  Importacoes createAlias(String alias) {
    return Importacoes(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Importacao extends DataClass implements Insertable<Importacao> {
  final String id;
  final String contaId;
  final String formato;
  final String nomeArquivo;
  final String hashArquivo;

  /// SHA-256 do arquivo
  final String? parserCodigo;

  /// perfil de banco usado
  final int? parserVersao;
  final String? previaJson;

  /// preenchido em 'previa', NULL após confirmar
  final String? periodoInicio;
  final String? periodoFim;
  final int? totalLinhas;
  final int? totalImportadas;
  final int? totalDuplicadas;
  final int? totalIgnoradas;
  final String status;
  final String? erroDetalhe;
  final int criadoEm;
  const Importacao({
    required this.id,
    required this.contaId,
    required this.formato,
    required this.nomeArquivo,
    required this.hashArquivo,
    this.parserCodigo,
    this.parserVersao,
    this.previaJson,
    this.periodoInicio,
    this.periodoFim,
    this.totalLinhas,
    this.totalImportadas,
    this.totalDuplicadas,
    this.totalIgnoradas,
    required this.status,
    this.erroDetalhe,
    required this.criadoEm,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['conta_id'] = Variable<String>(contaId);
    map['formato'] = Variable<String>(formato);
    map['nome_arquivo'] = Variable<String>(nomeArquivo);
    map['hash_arquivo'] = Variable<String>(hashArquivo);
    if (!nullToAbsent || parserCodigo != null) {
      map['parser_codigo'] = Variable<String>(parserCodigo);
    }
    if (!nullToAbsent || parserVersao != null) {
      map['parser_versao'] = Variable<int>(parserVersao);
    }
    if (!nullToAbsent || previaJson != null) {
      map['previa_json'] = Variable<String>(previaJson);
    }
    if (!nullToAbsent || periodoInicio != null) {
      map['periodo_inicio'] = Variable<String>(periodoInicio);
    }
    if (!nullToAbsent || periodoFim != null) {
      map['periodo_fim'] = Variable<String>(periodoFim);
    }
    if (!nullToAbsent || totalLinhas != null) {
      map['total_linhas'] = Variable<int>(totalLinhas);
    }
    if (!nullToAbsent || totalImportadas != null) {
      map['total_importadas'] = Variable<int>(totalImportadas);
    }
    if (!nullToAbsent || totalDuplicadas != null) {
      map['total_duplicadas'] = Variable<int>(totalDuplicadas);
    }
    if (!nullToAbsent || totalIgnoradas != null) {
      map['total_ignoradas'] = Variable<int>(totalIgnoradas);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || erroDetalhe != null) {
      map['erro_detalhe'] = Variable<String>(erroDetalhe);
    }
    map['criado_em'] = Variable<int>(criadoEm);
    return map;
  }

  ImportacoesCompanion toCompanion(bool nullToAbsent) {
    return ImportacoesCompanion(
      id: Value(id),
      contaId: Value(contaId),
      formato: Value(formato),
      nomeArquivo: Value(nomeArquivo),
      hashArquivo: Value(hashArquivo),
      parserCodigo: parserCodigo == null && nullToAbsent
          ? const Value.absent()
          : Value(parserCodigo),
      parserVersao: parserVersao == null && nullToAbsent
          ? const Value.absent()
          : Value(parserVersao),
      previaJson: previaJson == null && nullToAbsent
          ? const Value.absent()
          : Value(previaJson),
      periodoInicio: periodoInicio == null && nullToAbsent
          ? const Value.absent()
          : Value(periodoInicio),
      periodoFim: periodoFim == null && nullToAbsent
          ? const Value.absent()
          : Value(periodoFim),
      totalLinhas: totalLinhas == null && nullToAbsent
          ? const Value.absent()
          : Value(totalLinhas),
      totalImportadas: totalImportadas == null && nullToAbsent
          ? const Value.absent()
          : Value(totalImportadas),
      totalDuplicadas: totalDuplicadas == null && nullToAbsent
          ? const Value.absent()
          : Value(totalDuplicadas),
      totalIgnoradas: totalIgnoradas == null && nullToAbsent
          ? const Value.absent()
          : Value(totalIgnoradas),
      status: Value(status),
      erroDetalhe: erroDetalhe == null && nullToAbsent
          ? const Value.absent()
          : Value(erroDetalhe),
      criadoEm: Value(criadoEm),
    );
  }

  factory Importacao.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Importacao(
      id: serializer.fromJson<String>(json['id']),
      contaId: serializer.fromJson<String>(json['conta_id']),
      formato: serializer.fromJson<String>(json['formato']),
      nomeArquivo: serializer.fromJson<String>(json['nome_arquivo']),
      hashArquivo: serializer.fromJson<String>(json['hash_arquivo']),
      parserCodigo: serializer.fromJson<String?>(json['parser_codigo']),
      parserVersao: serializer.fromJson<int?>(json['parser_versao']),
      previaJson: serializer.fromJson<String?>(json['previa_json']),
      periodoInicio: serializer.fromJson<String?>(json['periodo_inicio']),
      periodoFim: serializer.fromJson<String?>(json['periodo_fim']),
      totalLinhas: serializer.fromJson<int?>(json['total_linhas']),
      totalImportadas: serializer.fromJson<int?>(json['total_importadas']),
      totalDuplicadas: serializer.fromJson<int?>(json['total_duplicadas']),
      totalIgnoradas: serializer.fromJson<int?>(json['total_ignoradas']),
      status: serializer.fromJson<String>(json['status']),
      erroDetalhe: serializer.fromJson<String?>(json['erro_detalhe']),
      criadoEm: serializer.fromJson<int>(json['criado_em']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'conta_id': serializer.toJson<String>(contaId),
      'formato': serializer.toJson<String>(formato),
      'nome_arquivo': serializer.toJson<String>(nomeArquivo),
      'hash_arquivo': serializer.toJson<String>(hashArquivo),
      'parser_codigo': serializer.toJson<String?>(parserCodigo),
      'parser_versao': serializer.toJson<int?>(parserVersao),
      'previa_json': serializer.toJson<String?>(previaJson),
      'periodo_inicio': serializer.toJson<String?>(periodoInicio),
      'periodo_fim': serializer.toJson<String?>(periodoFim),
      'total_linhas': serializer.toJson<int?>(totalLinhas),
      'total_importadas': serializer.toJson<int?>(totalImportadas),
      'total_duplicadas': serializer.toJson<int?>(totalDuplicadas),
      'total_ignoradas': serializer.toJson<int?>(totalIgnoradas),
      'status': serializer.toJson<String>(status),
      'erro_detalhe': serializer.toJson<String?>(erroDetalhe),
      'criado_em': serializer.toJson<int>(criadoEm),
    };
  }

  Importacao copyWith({
    String? id,
    String? contaId,
    String? formato,
    String? nomeArquivo,
    String? hashArquivo,
    Value<String?> parserCodigo = const Value.absent(),
    Value<int?> parserVersao = const Value.absent(),
    Value<String?> previaJson = const Value.absent(),
    Value<String?> periodoInicio = const Value.absent(),
    Value<String?> periodoFim = const Value.absent(),
    Value<int?> totalLinhas = const Value.absent(),
    Value<int?> totalImportadas = const Value.absent(),
    Value<int?> totalDuplicadas = const Value.absent(),
    Value<int?> totalIgnoradas = const Value.absent(),
    String? status,
    Value<String?> erroDetalhe = const Value.absent(),
    int? criadoEm,
  }) => Importacao(
    id: id ?? this.id,
    contaId: contaId ?? this.contaId,
    formato: formato ?? this.formato,
    nomeArquivo: nomeArquivo ?? this.nomeArquivo,
    hashArquivo: hashArquivo ?? this.hashArquivo,
    parserCodigo: parserCodigo.present ? parserCodigo.value : this.parserCodigo,
    parserVersao: parserVersao.present ? parserVersao.value : this.parserVersao,
    previaJson: previaJson.present ? previaJson.value : this.previaJson,
    periodoInicio: periodoInicio.present
        ? periodoInicio.value
        : this.periodoInicio,
    periodoFim: periodoFim.present ? periodoFim.value : this.periodoFim,
    totalLinhas: totalLinhas.present ? totalLinhas.value : this.totalLinhas,
    totalImportadas: totalImportadas.present
        ? totalImportadas.value
        : this.totalImportadas,
    totalDuplicadas: totalDuplicadas.present
        ? totalDuplicadas.value
        : this.totalDuplicadas,
    totalIgnoradas: totalIgnoradas.present
        ? totalIgnoradas.value
        : this.totalIgnoradas,
    status: status ?? this.status,
    erroDetalhe: erroDetalhe.present ? erroDetalhe.value : this.erroDetalhe,
    criadoEm: criadoEm ?? this.criadoEm,
  );
  Importacao copyWithCompanion(ImportacoesCompanion data) {
    return Importacao(
      id: data.id.present ? data.id.value : this.id,
      contaId: data.contaId.present ? data.contaId.value : this.contaId,
      formato: data.formato.present ? data.formato.value : this.formato,
      nomeArquivo: data.nomeArquivo.present
          ? data.nomeArquivo.value
          : this.nomeArquivo,
      hashArquivo: data.hashArquivo.present
          ? data.hashArquivo.value
          : this.hashArquivo,
      parserCodigo: data.parserCodigo.present
          ? data.parserCodigo.value
          : this.parserCodigo,
      parserVersao: data.parserVersao.present
          ? data.parserVersao.value
          : this.parserVersao,
      previaJson: data.previaJson.present
          ? data.previaJson.value
          : this.previaJson,
      periodoInicio: data.periodoInicio.present
          ? data.periodoInicio.value
          : this.periodoInicio,
      periodoFim: data.periodoFim.present
          ? data.periodoFim.value
          : this.periodoFim,
      totalLinhas: data.totalLinhas.present
          ? data.totalLinhas.value
          : this.totalLinhas,
      totalImportadas: data.totalImportadas.present
          ? data.totalImportadas.value
          : this.totalImportadas,
      totalDuplicadas: data.totalDuplicadas.present
          ? data.totalDuplicadas.value
          : this.totalDuplicadas,
      totalIgnoradas: data.totalIgnoradas.present
          ? data.totalIgnoradas.value
          : this.totalIgnoradas,
      status: data.status.present ? data.status.value : this.status,
      erroDetalhe: data.erroDetalhe.present
          ? data.erroDetalhe.value
          : this.erroDetalhe,
      criadoEm: data.criadoEm.present ? data.criadoEm.value : this.criadoEm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Importacao(')
          ..write('id: $id, ')
          ..write('contaId: $contaId, ')
          ..write('formato: $formato, ')
          ..write('nomeArquivo: $nomeArquivo, ')
          ..write('hashArquivo: $hashArquivo, ')
          ..write('parserCodigo: $parserCodigo, ')
          ..write('parserVersao: $parserVersao, ')
          ..write('previaJson: $previaJson, ')
          ..write('periodoInicio: $periodoInicio, ')
          ..write('periodoFim: $periodoFim, ')
          ..write('totalLinhas: $totalLinhas, ')
          ..write('totalImportadas: $totalImportadas, ')
          ..write('totalDuplicadas: $totalDuplicadas, ')
          ..write('totalIgnoradas: $totalIgnoradas, ')
          ..write('status: $status, ')
          ..write('erroDetalhe: $erroDetalhe, ')
          ..write('criadoEm: $criadoEm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    contaId,
    formato,
    nomeArquivo,
    hashArquivo,
    parserCodigo,
    parserVersao,
    previaJson,
    periodoInicio,
    periodoFim,
    totalLinhas,
    totalImportadas,
    totalDuplicadas,
    totalIgnoradas,
    status,
    erroDetalhe,
    criadoEm,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Importacao &&
          other.id == this.id &&
          other.contaId == this.contaId &&
          other.formato == this.formato &&
          other.nomeArquivo == this.nomeArquivo &&
          other.hashArquivo == this.hashArquivo &&
          other.parserCodigo == this.parserCodigo &&
          other.parserVersao == this.parserVersao &&
          other.previaJson == this.previaJson &&
          other.periodoInicio == this.periodoInicio &&
          other.periodoFim == this.periodoFim &&
          other.totalLinhas == this.totalLinhas &&
          other.totalImportadas == this.totalImportadas &&
          other.totalDuplicadas == this.totalDuplicadas &&
          other.totalIgnoradas == this.totalIgnoradas &&
          other.status == this.status &&
          other.erroDetalhe == this.erroDetalhe &&
          other.criadoEm == this.criadoEm);
}

class ImportacoesCompanion extends UpdateCompanion<Importacao> {
  final Value<String> id;
  final Value<String> contaId;
  final Value<String> formato;
  final Value<String> nomeArquivo;
  final Value<String> hashArquivo;
  final Value<String?> parserCodigo;
  final Value<int?> parserVersao;
  final Value<String?> previaJson;
  final Value<String?> periodoInicio;
  final Value<String?> periodoFim;
  final Value<int?> totalLinhas;
  final Value<int?> totalImportadas;
  final Value<int?> totalDuplicadas;
  final Value<int?> totalIgnoradas;
  final Value<String> status;
  final Value<String?> erroDetalhe;
  final Value<int> criadoEm;
  final Value<int> rowid;
  const ImportacoesCompanion({
    this.id = const Value.absent(),
    this.contaId = const Value.absent(),
    this.formato = const Value.absent(),
    this.nomeArquivo = const Value.absent(),
    this.hashArquivo = const Value.absent(),
    this.parserCodigo = const Value.absent(),
    this.parserVersao = const Value.absent(),
    this.previaJson = const Value.absent(),
    this.periodoInicio = const Value.absent(),
    this.periodoFim = const Value.absent(),
    this.totalLinhas = const Value.absent(),
    this.totalImportadas = const Value.absent(),
    this.totalDuplicadas = const Value.absent(),
    this.totalIgnoradas = const Value.absent(),
    this.status = const Value.absent(),
    this.erroDetalhe = const Value.absent(),
    this.criadoEm = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImportacoesCompanion.insert({
    required String id,
    required String contaId,
    required String formato,
    required String nomeArquivo,
    required String hashArquivo,
    this.parserCodigo = const Value.absent(),
    this.parserVersao = const Value.absent(),
    this.previaJson = const Value.absent(),
    this.periodoInicio = const Value.absent(),
    this.periodoFim = const Value.absent(),
    this.totalLinhas = const Value.absent(),
    this.totalImportadas = const Value.absent(),
    this.totalDuplicadas = const Value.absent(),
    this.totalIgnoradas = const Value.absent(),
    this.status = const Value.absent(),
    this.erroDetalhe = const Value.absent(),
    required int criadoEm,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       contaId = Value(contaId),
       formato = Value(formato),
       nomeArquivo = Value(nomeArquivo),
       hashArquivo = Value(hashArquivo),
       criadoEm = Value(criadoEm);
  static Insertable<Importacao> custom({
    Expression<String>? id,
    Expression<String>? contaId,
    Expression<String>? formato,
    Expression<String>? nomeArquivo,
    Expression<String>? hashArquivo,
    Expression<String>? parserCodigo,
    Expression<int>? parserVersao,
    Expression<String>? previaJson,
    Expression<String>? periodoInicio,
    Expression<String>? periodoFim,
    Expression<int>? totalLinhas,
    Expression<int>? totalImportadas,
    Expression<int>? totalDuplicadas,
    Expression<int>? totalIgnoradas,
    Expression<String>? status,
    Expression<String>? erroDetalhe,
    Expression<int>? criadoEm,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (contaId != null) 'conta_id': contaId,
      if (formato != null) 'formato': formato,
      if (nomeArquivo != null) 'nome_arquivo': nomeArquivo,
      if (hashArquivo != null) 'hash_arquivo': hashArquivo,
      if (parserCodigo != null) 'parser_codigo': parserCodigo,
      if (parserVersao != null) 'parser_versao': parserVersao,
      if (previaJson != null) 'previa_json': previaJson,
      if (periodoInicio != null) 'periodo_inicio': periodoInicio,
      if (periodoFim != null) 'periodo_fim': periodoFim,
      if (totalLinhas != null) 'total_linhas': totalLinhas,
      if (totalImportadas != null) 'total_importadas': totalImportadas,
      if (totalDuplicadas != null) 'total_duplicadas': totalDuplicadas,
      if (totalIgnoradas != null) 'total_ignoradas': totalIgnoradas,
      if (status != null) 'status': status,
      if (erroDetalhe != null) 'erro_detalhe': erroDetalhe,
      if (criadoEm != null) 'criado_em': criadoEm,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImportacoesCompanion copyWith({
    Value<String>? id,
    Value<String>? contaId,
    Value<String>? formato,
    Value<String>? nomeArquivo,
    Value<String>? hashArquivo,
    Value<String?>? parserCodigo,
    Value<int?>? parserVersao,
    Value<String?>? previaJson,
    Value<String?>? periodoInicio,
    Value<String?>? periodoFim,
    Value<int?>? totalLinhas,
    Value<int?>? totalImportadas,
    Value<int?>? totalDuplicadas,
    Value<int?>? totalIgnoradas,
    Value<String>? status,
    Value<String?>? erroDetalhe,
    Value<int>? criadoEm,
    Value<int>? rowid,
  }) {
    return ImportacoesCompanion(
      id: id ?? this.id,
      contaId: contaId ?? this.contaId,
      formato: formato ?? this.formato,
      nomeArquivo: nomeArquivo ?? this.nomeArquivo,
      hashArquivo: hashArquivo ?? this.hashArquivo,
      parserCodigo: parserCodigo ?? this.parserCodigo,
      parserVersao: parserVersao ?? this.parserVersao,
      previaJson: previaJson ?? this.previaJson,
      periodoInicio: periodoInicio ?? this.periodoInicio,
      periodoFim: periodoFim ?? this.periodoFim,
      totalLinhas: totalLinhas ?? this.totalLinhas,
      totalImportadas: totalImportadas ?? this.totalImportadas,
      totalDuplicadas: totalDuplicadas ?? this.totalDuplicadas,
      totalIgnoradas: totalIgnoradas ?? this.totalIgnoradas,
      status: status ?? this.status,
      erroDetalhe: erroDetalhe ?? this.erroDetalhe,
      criadoEm: criadoEm ?? this.criadoEm,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (contaId.present) {
      map['conta_id'] = Variable<String>(contaId.value);
    }
    if (formato.present) {
      map['formato'] = Variable<String>(formato.value);
    }
    if (nomeArquivo.present) {
      map['nome_arquivo'] = Variable<String>(nomeArquivo.value);
    }
    if (hashArquivo.present) {
      map['hash_arquivo'] = Variable<String>(hashArquivo.value);
    }
    if (parserCodigo.present) {
      map['parser_codigo'] = Variable<String>(parserCodigo.value);
    }
    if (parserVersao.present) {
      map['parser_versao'] = Variable<int>(parserVersao.value);
    }
    if (previaJson.present) {
      map['previa_json'] = Variable<String>(previaJson.value);
    }
    if (periodoInicio.present) {
      map['periodo_inicio'] = Variable<String>(periodoInicio.value);
    }
    if (periodoFim.present) {
      map['periodo_fim'] = Variable<String>(periodoFim.value);
    }
    if (totalLinhas.present) {
      map['total_linhas'] = Variable<int>(totalLinhas.value);
    }
    if (totalImportadas.present) {
      map['total_importadas'] = Variable<int>(totalImportadas.value);
    }
    if (totalDuplicadas.present) {
      map['total_duplicadas'] = Variable<int>(totalDuplicadas.value);
    }
    if (totalIgnoradas.present) {
      map['total_ignoradas'] = Variable<int>(totalIgnoradas.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (erroDetalhe.present) {
      map['erro_detalhe'] = Variable<String>(erroDetalhe.value);
    }
    if (criadoEm.present) {
      map['criado_em'] = Variable<int>(criadoEm.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportacoesCompanion(')
          ..write('id: $id, ')
          ..write('contaId: $contaId, ')
          ..write('formato: $formato, ')
          ..write('nomeArquivo: $nomeArquivo, ')
          ..write('hashArquivo: $hashArquivo, ')
          ..write('parserCodigo: $parserCodigo, ')
          ..write('parserVersao: $parserVersao, ')
          ..write('previaJson: $previaJson, ')
          ..write('periodoInicio: $periodoInicio, ')
          ..write('periodoFim: $periodoFim, ')
          ..write('totalLinhas: $totalLinhas, ')
          ..write('totalImportadas: $totalImportadas, ')
          ..write('totalDuplicadas: $totalDuplicadas, ')
          ..write('totalIgnoradas: $totalIgnoradas, ')
          ..write('status: $status, ')
          ..write('erroDetalhe: $erroDetalhe, ')
          ..write('criadoEm: $criadoEm, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Transacoes extends Table with TableInfo<Transacoes, Transacao> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Transacoes(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _contaIdMeta = const VerificationMeta(
    'contaId',
  );
  late final GeneratedColumn<String> contaId = GeneratedColumn<String>(
    'conta_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES contas_bancarias(id)',
  );
  static const VerificationMeta _importacaoIdMeta = const VerificationMeta(
    'importacaoId',
  );
  late final GeneratedColumn<String> importacaoId = GeneratedColumn<String>(
    'importacao_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES importacoes(id)',
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _valorCentavosMeta = const VerificationMeta(
    'valorCentavos',
  );
  late final GeneratedColumn<int> valorCentavos = GeneratedColumn<int>(
    'valor_centavos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _descricaoRawMeta = const VerificationMeta(
    'descricaoRaw',
  );
  late final GeneratedColumn<String> descricaoRaw = GeneratedColumn<String>(
    'descricao_raw',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _fitidMeta = const VerificationMeta('fitid');
  late final GeneratedColumn<String> fitid = GeneratedColumn<String>(
    'fitid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _contraparteNomeRawMeta =
      const VerificationMeta('contraparteNomeRaw');
  late final GeneratedColumn<String> contraparteNomeRaw =
      GeneratedColumn<String>(
        'contraparte_nome_raw',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: '',
      );
  static const VerificationMeta _contraparteDocMeta = const VerificationMeta(
    'contraparteDoc',
  );
  late final GeneratedColumn<String> contraparteDoc = GeneratedColumn<String>(
    'contraparte_doc',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _contraparteTipoMeta = const VerificationMeta(
    'contraparteTipo',
  );
  late final GeneratedColumn<String> contraparteTipo = GeneratedColumn<String>(
    'contraparte_tipo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (contraparte_tipo IN (\'pf\', \'pj\', \'desconhecido\'))',
  );
  static const VerificationMeta _criadoEmMeta = const VerificationMeta(
    'criadoEm',
  );
  late final GeneratedColumn<int> criadoEm = GeneratedColumn<int>(
    'criado_em',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    contaId,
    importacaoId,
    data,
    valorCentavos,
    descricaoRaw,
    fitid,
    contraparteNomeRaw,
    contraparteDoc,
    contraparteTipo,
    criadoEm,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transacoes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Transacao> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('conta_id')) {
      context.handle(
        _contaIdMeta,
        contaId.isAcceptableOrUnknown(data['conta_id']!, _contaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_contaIdMeta);
    }
    if (data.containsKey('importacao_id')) {
      context.handle(
        _importacaoIdMeta,
        importacaoId.isAcceptableOrUnknown(
          data['importacao_id']!,
          _importacaoIdMeta,
        ),
      );
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('valor_centavos')) {
      context.handle(
        _valorCentavosMeta,
        valorCentavos.isAcceptableOrUnknown(
          data['valor_centavos']!,
          _valorCentavosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_valorCentavosMeta);
    }
    if (data.containsKey('descricao_raw')) {
      context.handle(
        _descricaoRawMeta,
        descricaoRaw.isAcceptableOrUnknown(
          data['descricao_raw']!,
          _descricaoRawMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descricaoRawMeta);
    }
    if (data.containsKey('fitid')) {
      context.handle(
        _fitidMeta,
        fitid.isAcceptableOrUnknown(data['fitid']!, _fitidMeta),
      );
    }
    if (data.containsKey('contraparte_nome_raw')) {
      context.handle(
        _contraparteNomeRawMeta,
        contraparteNomeRaw.isAcceptableOrUnknown(
          data['contraparte_nome_raw']!,
          _contraparteNomeRawMeta,
        ),
      );
    }
    if (data.containsKey('contraparte_doc')) {
      context.handle(
        _contraparteDocMeta,
        contraparteDoc.isAcceptableOrUnknown(
          data['contraparte_doc']!,
          _contraparteDocMeta,
        ),
      );
    }
    if (data.containsKey('contraparte_tipo')) {
      context.handle(
        _contraparteTipoMeta,
        contraparteTipo.isAcceptableOrUnknown(
          data['contraparte_tipo']!,
          _contraparteTipoMeta,
        ),
      );
    }
    if (data.containsKey('criado_em')) {
      context.handle(
        _criadoEmMeta,
        criadoEm.isAcceptableOrUnknown(data['criado_em']!, _criadoEmMeta),
      );
    } else if (isInserting) {
      context.missing(_criadoEmMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transacao map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transacao(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      contaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conta_id'],
      )!,
      importacaoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}importacao_id'],
      ),
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      )!,
      valorCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}valor_centavos'],
      )!,
      descricaoRaw: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}descricao_raw'],
      )!,
      fitid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fitid'],
      ),
      contraparteNomeRaw: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contraparte_nome_raw'],
      ),
      contraparteDoc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contraparte_doc'],
      ),
      contraparteTipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contraparte_tipo'],
      ),
      criadoEm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}criado_em'],
      )!,
    );
  }

  @override
  Transacoes createAlias(String alias) {
    return Transacoes(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Transacao extends DataClass implements Insertable<Transacao> {
  final String id;
  final String contaId;
  final String? importacaoId;
  final String data;
  final int valorCentavos;

  /// >0 crédito, <0 débito
  final String descricaoRaw;

  /// linha original, imutável
  final String? fitid;

  /// id único do OFX / Identificador do CSV
  final String? contraparteNomeRaw;
  final String? contraparteDoc;
  final String? contraparteTipo;
  final int criadoEm;
  const Transacao({
    required this.id,
    required this.contaId,
    this.importacaoId,
    required this.data,
    required this.valorCentavos,
    required this.descricaoRaw,
    this.fitid,
    this.contraparteNomeRaw,
    this.contraparteDoc,
    this.contraparteTipo,
    required this.criadoEm,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['conta_id'] = Variable<String>(contaId);
    if (!nullToAbsent || importacaoId != null) {
      map['importacao_id'] = Variable<String>(importacaoId);
    }
    map['data'] = Variable<String>(data);
    map['valor_centavos'] = Variable<int>(valorCentavos);
    map['descricao_raw'] = Variable<String>(descricaoRaw);
    if (!nullToAbsent || fitid != null) {
      map['fitid'] = Variable<String>(fitid);
    }
    if (!nullToAbsent || contraparteNomeRaw != null) {
      map['contraparte_nome_raw'] = Variable<String>(contraparteNomeRaw);
    }
    if (!nullToAbsent || contraparteDoc != null) {
      map['contraparte_doc'] = Variable<String>(contraparteDoc);
    }
    if (!nullToAbsent || contraparteTipo != null) {
      map['contraparte_tipo'] = Variable<String>(contraparteTipo);
    }
    map['criado_em'] = Variable<int>(criadoEm);
    return map;
  }

  TransacoesCompanion toCompanion(bool nullToAbsent) {
    return TransacoesCompanion(
      id: Value(id),
      contaId: Value(contaId),
      importacaoId: importacaoId == null && nullToAbsent
          ? const Value.absent()
          : Value(importacaoId),
      data: Value(data),
      valorCentavos: Value(valorCentavos),
      descricaoRaw: Value(descricaoRaw),
      fitid: fitid == null && nullToAbsent
          ? const Value.absent()
          : Value(fitid),
      contraparteNomeRaw: contraparteNomeRaw == null && nullToAbsent
          ? const Value.absent()
          : Value(contraparteNomeRaw),
      contraparteDoc: contraparteDoc == null && nullToAbsent
          ? const Value.absent()
          : Value(contraparteDoc),
      contraparteTipo: contraparteTipo == null && nullToAbsent
          ? const Value.absent()
          : Value(contraparteTipo),
      criadoEm: Value(criadoEm),
    );
  }

  factory Transacao.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transacao(
      id: serializer.fromJson<String>(json['id']),
      contaId: serializer.fromJson<String>(json['conta_id']),
      importacaoId: serializer.fromJson<String?>(json['importacao_id']),
      data: serializer.fromJson<String>(json['data']),
      valorCentavos: serializer.fromJson<int>(json['valor_centavos']),
      descricaoRaw: serializer.fromJson<String>(json['descricao_raw']),
      fitid: serializer.fromJson<String?>(json['fitid']),
      contraparteNomeRaw: serializer.fromJson<String?>(
        json['contraparte_nome_raw'],
      ),
      contraparteDoc: serializer.fromJson<String?>(json['contraparte_doc']),
      contraparteTipo: serializer.fromJson<String?>(json['contraparte_tipo']),
      criadoEm: serializer.fromJson<int>(json['criado_em']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'conta_id': serializer.toJson<String>(contaId),
      'importacao_id': serializer.toJson<String?>(importacaoId),
      'data': serializer.toJson<String>(data),
      'valor_centavos': serializer.toJson<int>(valorCentavos),
      'descricao_raw': serializer.toJson<String>(descricaoRaw),
      'fitid': serializer.toJson<String?>(fitid),
      'contraparte_nome_raw': serializer.toJson<String?>(contraparteNomeRaw),
      'contraparte_doc': serializer.toJson<String?>(contraparteDoc),
      'contraparte_tipo': serializer.toJson<String?>(contraparteTipo),
      'criado_em': serializer.toJson<int>(criadoEm),
    };
  }

  Transacao copyWith({
    String? id,
    String? contaId,
    Value<String?> importacaoId = const Value.absent(),
    String? data,
    int? valorCentavos,
    String? descricaoRaw,
    Value<String?> fitid = const Value.absent(),
    Value<String?> contraparteNomeRaw = const Value.absent(),
    Value<String?> contraparteDoc = const Value.absent(),
    Value<String?> contraparteTipo = const Value.absent(),
    int? criadoEm,
  }) => Transacao(
    id: id ?? this.id,
    contaId: contaId ?? this.contaId,
    importacaoId: importacaoId.present ? importacaoId.value : this.importacaoId,
    data: data ?? this.data,
    valorCentavos: valorCentavos ?? this.valorCentavos,
    descricaoRaw: descricaoRaw ?? this.descricaoRaw,
    fitid: fitid.present ? fitid.value : this.fitid,
    contraparteNomeRaw: contraparteNomeRaw.present
        ? contraparteNomeRaw.value
        : this.contraparteNomeRaw,
    contraparteDoc: contraparteDoc.present
        ? contraparteDoc.value
        : this.contraparteDoc,
    contraparteTipo: contraparteTipo.present
        ? contraparteTipo.value
        : this.contraparteTipo,
    criadoEm: criadoEm ?? this.criadoEm,
  );
  Transacao copyWithCompanion(TransacoesCompanion data) {
    return Transacao(
      id: data.id.present ? data.id.value : this.id,
      contaId: data.contaId.present ? data.contaId.value : this.contaId,
      importacaoId: data.importacaoId.present
          ? data.importacaoId.value
          : this.importacaoId,
      data: data.data.present ? data.data.value : this.data,
      valorCentavos: data.valorCentavos.present
          ? data.valorCentavos.value
          : this.valorCentavos,
      descricaoRaw: data.descricaoRaw.present
          ? data.descricaoRaw.value
          : this.descricaoRaw,
      fitid: data.fitid.present ? data.fitid.value : this.fitid,
      contraparteNomeRaw: data.contraparteNomeRaw.present
          ? data.contraparteNomeRaw.value
          : this.contraparteNomeRaw,
      contraparteDoc: data.contraparteDoc.present
          ? data.contraparteDoc.value
          : this.contraparteDoc,
      contraparteTipo: data.contraparteTipo.present
          ? data.contraparteTipo.value
          : this.contraparteTipo,
      criadoEm: data.criadoEm.present ? data.criadoEm.value : this.criadoEm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transacao(')
          ..write('id: $id, ')
          ..write('contaId: $contaId, ')
          ..write('importacaoId: $importacaoId, ')
          ..write('data: $data, ')
          ..write('valorCentavos: $valorCentavos, ')
          ..write('descricaoRaw: $descricaoRaw, ')
          ..write('fitid: $fitid, ')
          ..write('contraparteNomeRaw: $contraparteNomeRaw, ')
          ..write('contraparteDoc: $contraparteDoc, ')
          ..write('contraparteTipo: $contraparteTipo, ')
          ..write('criadoEm: $criadoEm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    contaId,
    importacaoId,
    data,
    valorCentavos,
    descricaoRaw,
    fitid,
    contraparteNomeRaw,
    contraparteDoc,
    contraparteTipo,
    criadoEm,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transacao &&
          other.id == this.id &&
          other.contaId == this.contaId &&
          other.importacaoId == this.importacaoId &&
          other.data == this.data &&
          other.valorCentavos == this.valorCentavos &&
          other.descricaoRaw == this.descricaoRaw &&
          other.fitid == this.fitid &&
          other.contraparteNomeRaw == this.contraparteNomeRaw &&
          other.contraparteDoc == this.contraparteDoc &&
          other.contraparteTipo == this.contraparteTipo &&
          other.criadoEm == this.criadoEm);
}

class TransacoesCompanion extends UpdateCompanion<Transacao> {
  final Value<String> id;
  final Value<String> contaId;
  final Value<String?> importacaoId;
  final Value<String> data;
  final Value<int> valorCentavos;
  final Value<String> descricaoRaw;
  final Value<String?> fitid;
  final Value<String?> contraparteNomeRaw;
  final Value<String?> contraparteDoc;
  final Value<String?> contraparteTipo;
  final Value<int> criadoEm;
  final Value<int> rowid;
  const TransacoesCompanion({
    this.id = const Value.absent(),
    this.contaId = const Value.absent(),
    this.importacaoId = const Value.absent(),
    this.data = const Value.absent(),
    this.valorCentavos = const Value.absent(),
    this.descricaoRaw = const Value.absent(),
    this.fitid = const Value.absent(),
    this.contraparteNomeRaw = const Value.absent(),
    this.contraparteDoc = const Value.absent(),
    this.contraparteTipo = const Value.absent(),
    this.criadoEm = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransacoesCompanion.insert({
    required String id,
    required String contaId,
    this.importacaoId = const Value.absent(),
    required String data,
    required int valorCentavos,
    required String descricaoRaw,
    this.fitid = const Value.absent(),
    this.contraparteNomeRaw = const Value.absent(),
    this.contraparteDoc = const Value.absent(),
    this.contraparteTipo = const Value.absent(),
    required int criadoEm,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       contaId = Value(contaId),
       data = Value(data),
       valorCentavos = Value(valorCentavos),
       descricaoRaw = Value(descricaoRaw),
       criadoEm = Value(criadoEm);
  static Insertable<Transacao> custom({
    Expression<String>? id,
    Expression<String>? contaId,
    Expression<String>? importacaoId,
    Expression<String>? data,
    Expression<int>? valorCentavos,
    Expression<String>? descricaoRaw,
    Expression<String>? fitid,
    Expression<String>? contraparteNomeRaw,
    Expression<String>? contraparteDoc,
    Expression<String>? contraparteTipo,
    Expression<int>? criadoEm,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (contaId != null) 'conta_id': contaId,
      if (importacaoId != null) 'importacao_id': importacaoId,
      if (data != null) 'data': data,
      if (valorCentavos != null) 'valor_centavos': valorCentavos,
      if (descricaoRaw != null) 'descricao_raw': descricaoRaw,
      if (fitid != null) 'fitid': fitid,
      if (contraparteNomeRaw != null)
        'contraparte_nome_raw': contraparteNomeRaw,
      if (contraparteDoc != null) 'contraparte_doc': contraparteDoc,
      if (contraparteTipo != null) 'contraparte_tipo': contraparteTipo,
      if (criadoEm != null) 'criado_em': criadoEm,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransacoesCompanion copyWith({
    Value<String>? id,
    Value<String>? contaId,
    Value<String?>? importacaoId,
    Value<String>? data,
    Value<int>? valorCentavos,
    Value<String>? descricaoRaw,
    Value<String?>? fitid,
    Value<String?>? contraparteNomeRaw,
    Value<String?>? contraparteDoc,
    Value<String?>? contraparteTipo,
    Value<int>? criadoEm,
    Value<int>? rowid,
  }) {
    return TransacoesCompanion(
      id: id ?? this.id,
      contaId: contaId ?? this.contaId,
      importacaoId: importacaoId ?? this.importacaoId,
      data: data ?? this.data,
      valorCentavos: valorCentavos ?? this.valorCentavos,
      descricaoRaw: descricaoRaw ?? this.descricaoRaw,
      fitid: fitid ?? this.fitid,
      contraparteNomeRaw: contraparteNomeRaw ?? this.contraparteNomeRaw,
      contraparteDoc: contraparteDoc ?? this.contraparteDoc,
      contraparteTipo: contraparteTipo ?? this.contraparteTipo,
      criadoEm: criadoEm ?? this.criadoEm,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (contaId.present) {
      map['conta_id'] = Variable<String>(contaId.value);
    }
    if (importacaoId.present) {
      map['importacao_id'] = Variable<String>(importacaoId.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (valorCentavos.present) {
      map['valor_centavos'] = Variable<int>(valorCentavos.value);
    }
    if (descricaoRaw.present) {
      map['descricao_raw'] = Variable<String>(descricaoRaw.value);
    }
    if (fitid.present) {
      map['fitid'] = Variable<String>(fitid.value);
    }
    if (contraparteNomeRaw.present) {
      map['contraparte_nome_raw'] = Variable<String>(contraparteNomeRaw.value);
    }
    if (contraparteDoc.present) {
      map['contraparte_doc'] = Variable<String>(contraparteDoc.value);
    }
    if (contraparteTipo.present) {
      map['contraparte_tipo'] = Variable<String>(contraparteTipo.value);
    }
    if (criadoEm.present) {
      map['criado_em'] = Variable<int>(criadoEm.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransacoesCompanion(')
          ..write('id: $id, ')
          ..write('contaId: $contaId, ')
          ..write('importacaoId: $importacaoId, ')
          ..write('data: $data, ')
          ..write('valorCentavos: $valorCentavos, ')
          ..write('descricaoRaw: $descricaoRaw, ')
          ..write('fitid: $fitid, ')
          ..write('contraparteNomeRaw: $contraparteNomeRaw, ')
          ..write('contraparteDoc: $contraparteDoc, ')
          ..write('contraparteTipo: $contraparteTipo, ')
          ..write('criadoEm: $criadoEm, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Remetentes extends Table with TableInfo<Remetentes, Remetente> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Remetentes(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
    'nome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _cpfMeta = const VerificationMeta('cpf');
  late final GeneratedColumn<String> cpf = GeneratedColumn<String>(
    'cpf',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _classificacaoPadraoMeta =
      const VerificationMeta('classificacaoPadrao');
  late final GeneratedColumn<String>
  classificacaoPadrao = GeneratedColumn<String>(
    'classificacao_padrao',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (classificacao_padrao IN (\'tributavel\', \'pessoal\', \'reembolso\', \'repasse_terceiros\'))',
  );
  static const VerificationMeta _titularRemetenteIdMeta =
      const VerificationMeta('titularRemetenteId');
  late final GeneratedColumn<String> titularRemetenteId =
      GeneratedColumn<String>(
        'titular_remetente_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: 'REFERENCES remetentes(id)',
      );
  static const VerificationMeta _observacoesMeta = const VerificationMeta(
    'observacoes',
  );
  late final GeneratedColumn<String> observacoes = GeneratedColumn<String>(
    'observacoes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _criadoEmMeta = const VerificationMeta(
    'criadoEm',
  );
  late final GeneratedColumn<int> criadoEm = GeneratedColumn<int>(
    'criado_em',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nome,
    cpf,
    classificacaoPadrao,
    titularRemetenteId,
    observacoes,
    criadoEm,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'remetentes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Remetente> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('cpf')) {
      context.handle(
        _cpfMeta,
        cpf.isAcceptableOrUnknown(data['cpf']!, _cpfMeta),
      );
    }
    if (data.containsKey('classificacao_padrao')) {
      context.handle(
        _classificacaoPadraoMeta,
        classificacaoPadrao.isAcceptableOrUnknown(
          data['classificacao_padrao']!,
          _classificacaoPadraoMeta,
        ),
      );
    }
    if (data.containsKey('titular_remetente_id')) {
      context.handle(
        _titularRemetenteIdMeta,
        titularRemetenteId.isAcceptableOrUnknown(
          data['titular_remetente_id']!,
          _titularRemetenteIdMeta,
        ),
      );
    }
    if (data.containsKey('observacoes')) {
      context.handle(
        _observacoesMeta,
        observacoes.isAcceptableOrUnknown(
          data['observacoes']!,
          _observacoesMeta,
        ),
      );
    }
    if (data.containsKey('criado_em')) {
      context.handle(
        _criadoEmMeta,
        criadoEm.isAcceptableOrUnknown(data['criado_em']!, _criadoEmMeta),
      );
    } else if (isInserting) {
      context.missing(_criadoEmMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Remetente map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Remetente(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome'],
      )!,
      cpf: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cpf'],
      ),
      classificacaoPadrao: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}classificacao_padrao'],
      ),
      titularRemetenteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}titular_remetente_id'],
      ),
      observacoes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}observacoes'],
      ),
      criadoEm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}criado_em'],
      )!,
    );
  }

  @override
  Remetentes createAlias(String alias) {
    return Remetentes(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Remetente extends DataClass implements Insertable<Remetente> {
  final String id;
  final String nome;
  final String? cpf;
  final String? classificacaoPadrao;
  final String? titularRemetenteId;

  /// mãe paga a sessão do filho
  final String? observacoes;
  final int criadoEm;
  const Remetente({
    required this.id,
    required this.nome,
    this.cpf,
    this.classificacaoPadrao,
    this.titularRemetenteId,
    this.observacoes,
    required this.criadoEm,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nome'] = Variable<String>(nome);
    if (!nullToAbsent || cpf != null) {
      map['cpf'] = Variable<String>(cpf);
    }
    if (!nullToAbsent || classificacaoPadrao != null) {
      map['classificacao_padrao'] = Variable<String>(classificacaoPadrao);
    }
    if (!nullToAbsent || titularRemetenteId != null) {
      map['titular_remetente_id'] = Variable<String>(titularRemetenteId);
    }
    if (!nullToAbsent || observacoes != null) {
      map['observacoes'] = Variable<String>(observacoes);
    }
    map['criado_em'] = Variable<int>(criadoEm);
    return map;
  }

  RemetentesCompanion toCompanion(bool nullToAbsent) {
    return RemetentesCompanion(
      id: Value(id),
      nome: Value(nome),
      cpf: cpf == null && nullToAbsent ? const Value.absent() : Value(cpf),
      classificacaoPadrao: classificacaoPadrao == null && nullToAbsent
          ? const Value.absent()
          : Value(classificacaoPadrao),
      titularRemetenteId: titularRemetenteId == null && nullToAbsent
          ? const Value.absent()
          : Value(titularRemetenteId),
      observacoes: observacoes == null && nullToAbsent
          ? const Value.absent()
          : Value(observacoes),
      criadoEm: Value(criadoEm),
    );
  }

  factory Remetente.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Remetente(
      id: serializer.fromJson<String>(json['id']),
      nome: serializer.fromJson<String>(json['nome']),
      cpf: serializer.fromJson<String?>(json['cpf']),
      classificacaoPadrao: serializer.fromJson<String?>(
        json['classificacao_padrao'],
      ),
      titularRemetenteId: serializer.fromJson<String?>(
        json['titular_remetente_id'],
      ),
      observacoes: serializer.fromJson<String?>(json['observacoes']),
      criadoEm: serializer.fromJson<int>(json['criado_em']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nome': serializer.toJson<String>(nome),
      'cpf': serializer.toJson<String?>(cpf),
      'classificacao_padrao': serializer.toJson<String?>(classificacaoPadrao),
      'titular_remetente_id': serializer.toJson<String?>(titularRemetenteId),
      'observacoes': serializer.toJson<String?>(observacoes),
      'criado_em': serializer.toJson<int>(criadoEm),
    };
  }

  Remetente copyWith({
    String? id,
    String? nome,
    Value<String?> cpf = const Value.absent(),
    Value<String?> classificacaoPadrao = const Value.absent(),
    Value<String?> titularRemetenteId = const Value.absent(),
    Value<String?> observacoes = const Value.absent(),
    int? criadoEm,
  }) => Remetente(
    id: id ?? this.id,
    nome: nome ?? this.nome,
    cpf: cpf.present ? cpf.value : this.cpf,
    classificacaoPadrao: classificacaoPadrao.present
        ? classificacaoPadrao.value
        : this.classificacaoPadrao,
    titularRemetenteId: titularRemetenteId.present
        ? titularRemetenteId.value
        : this.titularRemetenteId,
    observacoes: observacoes.present ? observacoes.value : this.observacoes,
    criadoEm: criadoEm ?? this.criadoEm,
  );
  Remetente copyWithCompanion(RemetentesCompanion data) {
    return Remetente(
      id: data.id.present ? data.id.value : this.id,
      nome: data.nome.present ? data.nome.value : this.nome,
      cpf: data.cpf.present ? data.cpf.value : this.cpf,
      classificacaoPadrao: data.classificacaoPadrao.present
          ? data.classificacaoPadrao.value
          : this.classificacaoPadrao,
      titularRemetenteId: data.titularRemetenteId.present
          ? data.titularRemetenteId.value
          : this.titularRemetenteId,
      observacoes: data.observacoes.present
          ? data.observacoes.value
          : this.observacoes,
      criadoEm: data.criadoEm.present ? data.criadoEm.value : this.criadoEm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Remetente(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('cpf: $cpf, ')
          ..write('classificacaoPadrao: $classificacaoPadrao, ')
          ..write('titularRemetenteId: $titularRemetenteId, ')
          ..write('observacoes: $observacoes, ')
          ..write('criadoEm: $criadoEm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    nome,
    cpf,
    classificacaoPadrao,
    titularRemetenteId,
    observacoes,
    criadoEm,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Remetente &&
          other.id == this.id &&
          other.nome == this.nome &&
          other.cpf == this.cpf &&
          other.classificacaoPadrao == this.classificacaoPadrao &&
          other.titularRemetenteId == this.titularRemetenteId &&
          other.observacoes == this.observacoes &&
          other.criadoEm == this.criadoEm);
}

class RemetentesCompanion extends UpdateCompanion<Remetente> {
  final Value<String> id;
  final Value<String> nome;
  final Value<String?> cpf;
  final Value<String?> classificacaoPadrao;
  final Value<String?> titularRemetenteId;
  final Value<String?> observacoes;
  final Value<int> criadoEm;
  final Value<int> rowid;
  const RemetentesCompanion({
    this.id = const Value.absent(),
    this.nome = const Value.absent(),
    this.cpf = const Value.absent(),
    this.classificacaoPadrao = const Value.absent(),
    this.titularRemetenteId = const Value.absent(),
    this.observacoes = const Value.absent(),
    this.criadoEm = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RemetentesCompanion.insert({
    required String id,
    required String nome,
    this.cpf = const Value.absent(),
    this.classificacaoPadrao = const Value.absent(),
    this.titularRemetenteId = const Value.absent(),
    this.observacoes = const Value.absent(),
    required int criadoEm,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nome = Value(nome),
       criadoEm = Value(criadoEm);
  static Insertable<Remetente> custom({
    Expression<String>? id,
    Expression<String>? nome,
    Expression<String>? cpf,
    Expression<String>? classificacaoPadrao,
    Expression<String>? titularRemetenteId,
    Expression<String>? observacoes,
    Expression<int>? criadoEm,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nome != null) 'nome': nome,
      if (cpf != null) 'cpf': cpf,
      if (classificacaoPadrao != null)
        'classificacao_padrao': classificacaoPadrao,
      if (titularRemetenteId != null)
        'titular_remetente_id': titularRemetenteId,
      if (observacoes != null) 'observacoes': observacoes,
      if (criadoEm != null) 'criado_em': criadoEm,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RemetentesCompanion copyWith({
    Value<String>? id,
    Value<String>? nome,
    Value<String?>? cpf,
    Value<String?>? classificacaoPadrao,
    Value<String?>? titularRemetenteId,
    Value<String?>? observacoes,
    Value<int>? criadoEm,
    Value<int>? rowid,
  }) {
    return RemetentesCompanion(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      cpf: cpf ?? this.cpf,
      classificacaoPadrao: classificacaoPadrao ?? this.classificacaoPadrao,
      titularRemetenteId: titularRemetenteId ?? this.titularRemetenteId,
      observacoes: observacoes ?? this.observacoes,
      criadoEm: criadoEm ?? this.criadoEm,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (cpf.present) {
      map['cpf'] = Variable<String>(cpf.value);
    }
    if (classificacaoPadrao.present) {
      map['classificacao_padrao'] = Variable<String>(classificacaoPadrao.value);
    }
    if (titularRemetenteId.present) {
      map['titular_remetente_id'] = Variable<String>(titularRemetenteId.value);
    }
    if (observacoes.present) {
      map['observacoes'] = Variable<String>(observacoes.value);
    }
    if (criadoEm.present) {
      map['criado_em'] = Variable<int>(criadoEm.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemetentesCompanion(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('cpf: $cpf, ')
          ..write('classificacaoPadrao: $classificacaoPadrao, ')
          ..write('titularRemetenteId: $titularRemetenteId, ')
          ..write('observacoes: $observacoes, ')
          ..write('criadoEm: $criadoEm, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ApuracoesMensais extends Table
    with TableInfo<ApuracoesMensais, ApuracaoLocal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ApuracoesMensais(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _competenciaMeta = const VerificationMeta(
    'competencia',
  );
  late final GeneratedColumn<String> competencia = GeneratedColumn<String>(
    'competencia',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _versaoMeta = const VerificationMeta('versao');
  late final GeneratedColumn<int> versao = GeneratedColumn<int>(
    'versao',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 1',
    defaultValue: const CustomExpression('1'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT \'rascunho\' CHECK (status IN (\'rascunho\', \'fechada\', \'substituida\'))',
    defaultValue: const CustomExpression('\'rascunho\''),
  );
  static const VerificationMeta _receitaBrutaCentavosMeta =
      const VerificationMeta('receitaBrutaCentavos');
  late final GeneratedColumn<int> receitaBrutaCentavos = GeneratedColumn<int>(
    'receita_bruta_centavos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _despesasLivroCaixaCentavosMeta =
      const VerificationMeta('despesasLivroCaixaCentavos');
  late final GeneratedColumn<int> despesasLivroCaixaCentavos =
      GeneratedColumn<int>(
        'despesas_livro_caixa_centavos',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      );
  static const VerificationMeta _saldoNegativoAnteriorCentavosMeta =
      const VerificationMeta('saldoNegativoAnteriorCentavos');
  late final GeneratedColumn<int> saldoNegativoAnteriorCentavos =
      GeneratedColumn<int>(
        'saldo_negativo_anterior_centavos',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        $customConstraints: 'NOT NULL DEFAULT 0',
        defaultValue: const CustomExpression('0'),
      );
  static const VerificationMeta _saldoNegativoUtilizadoCentavosMeta =
      const VerificationMeta('saldoNegativoUtilizadoCentavos');
  late final GeneratedColumn<int> saldoNegativoUtilizadoCentavos =
      GeneratedColumn<int>(
        'saldo_negativo_utilizado_centavos',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        $customConstraints: 'NOT NULL DEFAULT 0',
        defaultValue: const CustomExpression('0'),
      );
  static const VerificationMeta _saldoNegativoTransportadoCentavosMeta =
      const VerificationMeta('saldoNegativoTransportadoCentavos');
  late final GeneratedColumn<int> saldoNegativoTransportadoCentavos =
      GeneratedColumn<int>(
        'saldo_negativo_transportado_centavos',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        $customConstraints: 'NOT NULL DEFAULT 0',
        defaultValue: const CustomExpression('0'),
      );
  static const VerificationMeta _inssCentavosMeta = const VerificationMeta(
    'inssCentavos',
  );
  late final GeneratedColumn<int> inssCentavos = GeneratedColumn<int>(
    'inss_centavos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _qtdeDependentesMeta = const VerificationMeta(
    'qtdeDependentes',
  );
  late final GeneratedColumn<int> qtdeDependentes = GeneratedColumn<int>(
    'qtde_dependentes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _deducaoDependentesCentavosMeta =
      const VerificationMeta('deducaoDependentesCentavos');
  late final GeneratedColumn<int> deducaoDependentesCentavos =
      GeneratedColumn<int>(
        'deducao_dependentes_centavos',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      );
  static const VerificationMeta _descontoSimplificadoCentavosMeta =
      const VerificationMeta('descontoSimplificadoCentavos');
  late final GeneratedColumn<int> descontoSimplificadoCentavos =
      GeneratedColumn<int>(
        'desconto_simplificado_centavos',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      );
  static const VerificationMeta _impostoCenarioRealCentavosMeta =
      const VerificationMeta('impostoCenarioRealCentavos');
  late final GeneratedColumn<int> impostoCenarioRealCentavos =
      GeneratedColumn<int>(
        'imposto_cenario_real_centavos',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      );
  static const VerificationMeta _impostoCenarioSimplificadoCentavosMeta =
      const VerificationMeta('impostoCenarioSimplificadoCentavos');
  late final GeneratedColumn<int> impostoCenarioSimplificadoCentavos =
      GeneratedColumn<int>(
        'imposto_cenario_simplificado_centavos',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      );
  static const VerificationMeta _cenarioAplicadoMeta = const VerificationMeta(
    'cenarioAplicado',
  );
  late final GeneratedColumn<String> cenarioAplicado = GeneratedColumn<String>(
    'cenario_aplicado',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (cenario_aplicado IN (\'real\', \'simplificado\'))',
  );
  static const VerificationMeta _baseCalculoCentavosMeta =
      const VerificationMeta('baseCalculoCentavos');
  late final GeneratedColumn<int> baseCalculoCentavos = GeneratedColumn<int>(
    'base_calculo_centavos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _aliquotaBpMeta = const VerificationMeta(
    'aliquotaBp',
  );
  late final GeneratedColumn<int> aliquotaBp = GeneratedColumn<int>(
    'aliquota_bp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _parcelaDeduzirCentavosMeta =
      const VerificationMeta('parcelaDeduzirCentavos');
  late final GeneratedColumn<int> parcelaDeduzirCentavos = GeneratedColumn<int>(
    'parcela_deduzir_centavos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _impostoApuradoCentavosMeta =
      const VerificationMeta('impostoApuradoCentavos');
  late final GeneratedColumn<int> impostoApuradoCentavos = GeneratedColumn<int>(
    'imposto_apurado_centavos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _redutorLeiCentavosMeta =
      const VerificationMeta('redutorLeiCentavos');
  late final GeneratedColumn<int> redutorLeiCentavos = GeneratedColumn<int>(
    'redutor_lei_centavos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _impostoDevidoCentavosMeta =
      const VerificationMeta('impostoDevidoCentavos');
  late final GeneratedColumn<int> impostoDevidoCentavos = GeneratedColumn<int>(
    'imposto_devido_centavos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _impostoDiferidoAnteriorCentavosMeta =
      const VerificationMeta('impostoDiferidoAnteriorCentavos');
  late final GeneratedColumn<int> impostoDiferidoAnteriorCentavos =
      GeneratedColumn<int>(
        'imposto_diferido_anterior_centavos',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        $customConstraints: 'NOT NULL DEFAULT 0',
        defaultValue: const CustomExpression('0'),
      );
  static const VerificationMeta _impostoDiferidoCentavosMeta =
      const VerificationMeta('impostoDiferidoCentavos');
  late final GeneratedColumn<int> impostoDiferidoCentavos =
      GeneratedColumn<int>(
        'imposto_diferido_centavos',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        $customConstraints: 'NOT NULL DEFAULT 0',
        defaultValue: const CustomExpression('0'),
      );
  static const VerificationMeta _isentoMeta = const VerificationMeta('isento');
  late final GeneratedColumn<int> isento = GeneratedColumn<int>(
    'isento',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _tabelaIrpfIdMeta = const VerificationMeta(
    'tabelaIrpfId',
  );
  late final GeneratedColumn<int> tabelaIrpfId = GeneratedColumn<int>(
    'tabela_irpf_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES cat_tabelas_irpf(id)',
  );
  static const VerificationMeta _catalogoVersoesSnapshotMeta =
      const VerificationMeta('catalogoVersoesSnapshot');
  late final GeneratedColumn<String> catalogoVersoesSnapshot =
      GeneratedColumn<String>(
        'catalogo_versoes_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      );
  static const VerificationMeta _parametrosSnapshotMeta =
      const VerificationMeta('parametrosSnapshot');
  late final GeneratedColumn<String> parametrosSnapshot =
      GeneratedColumn<String>(
        'parametros_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      );
  static const VerificationMeta _motorVersaoMeta = const VerificationMeta(
    'motorVersao',
  );
  late final GeneratedColumn<String> motorVersao = GeneratedColumn<String>(
    'motor_versao',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _appVersaoMeta = const VerificationMeta(
    'appVersao',
  );
  late final GeneratedColumn<String> appVersao = GeneratedColumn<String>(
    'app_versao',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _calculadaEmMeta = const VerificationMeta(
    'calculadaEm',
  );
  late final GeneratedColumn<int> calculadaEm = GeneratedColumn<int>(
    'calculada_em',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _fechadaEmMeta = const VerificationMeta(
    'fechadaEm',
  );
  late final GeneratedColumn<int> fechadaEm = GeneratedColumn<int>(
    'fechada_em',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    competencia,
    versao,
    status,
    receitaBrutaCentavos,
    despesasLivroCaixaCentavos,
    saldoNegativoAnteriorCentavos,
    saldoNegativoUtilizadoCentavos,
    saldoNegativoTransportadoCentavos,
    inssCentavos,
    qtdeDependentes,
    deducaoDependentesCentavos,
    descontoSimplificadoCentavos,
    impostoCenarioRealCentavos,
    impostoCenarioSimplificadoCentavos,
    cenarioAplicado,
    baseCalculoCentavos,
    aliquotaBp,
    parcelaDeduzirCentavos,
    impostoApuradoCentavos,
    redutorLeiCentavos,
    impostoDevidoCentavos,
    impostoDiferidoAnteriorCentavos,
    impostoDiferidoCentavos,
    isento,
    tabelaIrpfId,
    catalogoVersoesSnapshot,
    parametrosSnapshot,
    motorVersao,
    appVersao,
    calculadaEm,
    fechadaEm,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'apuracoes_mensais';
  @override
  VerificationContext validateIntegrity(
    Insertable<ApuracaoLocal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('competencia')) {
      context.handle(
        _competenciaMeta,
        competencia.isAcceptableOrUnknown(
          data['competencia']!,
          _competenciaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_competenciaMeta);
    }
    if (data.containsKey('versao')) {
      context.handle(
        _versaoMeta,
        versao.isAcceptableOrUnknown(data['versao']!, _versaoMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('receita_bruta_centavos')) {
      context.handle(
        _receitaBrutaCentavosMeta,
        receitaBrutaCentavos.isAcceptableOrUnknown(
          data['receita_bruta_centavos']!,
          _receitaBrutaCentavosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_receitaBrutaCentavosMeta);
    }
    if (data.containsKey('despesas_livro_caixa_centavos')) {
      context.handle(
        _despesasLivroCaixaCentavosMeta,
        despesasLivroCaixaCentavos.isAcceptableOrUnknown(
          data['despesas_livro_caixa_centavos']!,
          _despesasLivroCaixaCentavosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_despesasLivroCaixaCentavosMeta);
    }
    if (data.containsKey('saldo_negativo_anterior_centavos')) {
      context.handle(
        _saldoNegativoAnteriorCentavosMeta,
        saldoNegativoAnteriorCentavos.isAcceptableOrUnknown(
          data['saldo_negativo_anterior_centavos']!,
          _saldoNegativoAnteriorCentavosMeta,
        ),
      );
    }
    if (data.containsKey('saldo_negativo_utilizado_centavos')) {
      context.handle(
        _saldoNegativoUtilizadoCentavosMeta,
        saldoNegativoUtilizadoCentavos.isAcceptableOrUnknown(
          data['saldo_negativo_utilizado_centavos']!,
          _saldoNegativoUtilizadoCentavosMeta,
        ),
      );
    }
    if (data.containsKey('saldo_negativo_transportado_centavos')) {
      context.handle(
        _saldoNegativoTransportadoCentavosMeta,
        saldoNegativoTransportadoCentavos.isAcceptableOrUnknown(
          data['saldo_negativo_transportado_centavos']!,
          _saldoNegativoTransportadoCentavosMeta,
        ),
      );
    }
    if (data.containsKey('inss_centavos')) {
      context.handle(
        _inssCentavosMeta,
        inssCentavos.isAcceptableOrUnknown(
          data['inss_centavos']!,
          _inssCentavosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_inssCentavosMeta);
    }
    if (data.containsKey('qtde_dependentes')) {
      context.handle(
        _qtdeDependentesMeta,
        qtdeDependentes.isAcceptableOrUnknown(
          data['qtde_dependentes']!,
          _qtdeDependentesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_qtdeDependentesMeta);
    }
    if (data.containsKey('deducao_dependentes_centavos')) {
      context.handle(
        _deducaoDependentesCentavosMeta,
        deducaoDependentesCentavos.isAcceptableOrUnknown(
          data['deducao_dependentes_centavos']!,
          _deducaoDependentesCentavosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deducaoDependentesCentavosMeta);
    }
    if (data.containsKey('desconto_simplificado_centavos')) {
      context.handle(
        _descontoSimplificadoCentavosMeta,
        descontoSimplificadoCentavos.isAcceptableOrUnknown(
          data['desconto_simplificado_centavos']!,
          _descontoSimplificadoCentavosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descontoSimplificadoCentavosMeta);
    }
    if (data.containsKey('imposto_cenario_real_centavos')) {
      context.handle(
        _impostoCenarioRealCentavosMeta,
        impostoCenarioRealCentavos.isAcceptableOrUnknown(
          data['imposto_cenario_real_centavos']!,
          _impostoCenarioRealCentavosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_impostoCenarioRealCentavosMeta);
    }
    if (data.containsKey('imposto_cenario_simplificado_centavos')) {
      context.handle(
        _impostoCenarioSimplificadoCentavosMeta,
        impostoCenarioSimplificadoCentavos.isAcceptableOrUnknown(
          data['imposto_cenario_simplificado_centavos']!,
          _impostoCenarioSimplificadoCentavosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_impostoCenarioSimplificadoCentavosMeta);
    }
    if (data.containsKey('cenario_aplicado')) {
      context.handle(
        _cenarioAplicadoMeta,
        cenarioAplicado.isAcceptableOrUnknown(
          data['cenario_aplicado']!,
          _cenarioAplicadoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cenarioAplicadoMeta);
    }
    if (data.containsKey('base_calculo_centavos')) {
      context.handle(
        _baseCalculoCentavosMeta,
        baseCalculoCentavos.isAcceptableOrUnknown(
          data['base_calculo_centavos']!,
          _baseCalculoCentavosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_baseCalculoCentavosMeta);
    }
    if (data.containsKey('aliquota_bp')) {
      context.handle(
        _aliquotaBpMeta,
        aliquotaBp.isAcceptableOrUnknown(data['aliquota_bp']!, _aliquotaBpMeta),
      );
    } else if (isInserting) {
      context.missing(_aliquotaBpMeta);
    }
    if (data.containsKey('parcela_deduzir_centavos')) {
      context.handle(
        _parcelaDeduzirCentavosMeta,
        parcelaDeduzirCentavos.isAcceptableOrUnknown(
          data['parcela_deduzir_centavos']!,
          _parcelaDeduzirCentavosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_parcelaDeduzirCentavosMeta);
    }
    if (data.containsKey('imposto_apurado_centavos')) {
      context.handle(
        _impostoApuradoCentavosMeta,
        impostoApuradoCentavos.isAcceptableOrUnknown(
          data['imposto_apurado_centavos']!,
          _impostoApuradoCentavosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_impostoApuradoCentavosMeta);
    }
    if (data.containsKey('redutor_lei_centavos')) {
      context.handle(
        _redutorLeiCentavosMeta,
        redutorLeiCentavos.isAcceptableOrUnknown(
          data['redutor_lei_centavos']!,
          _redutorLeiCentavosMeta,
        ),
      );
    }
    if (data.containsKey('imposto_devido_centavos')) {
      context.handle(
        _impostoDevidoCentavosMeta,
        impostoDevidoCentavos.isAcceptableOrUnknown(
          data['imposto_devido_centavos']!,
          _impostoDevidoCentavosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_impostoDevidoCentavosMeta);
    }
    if (data.containsKey('imposto_diferido_anterior_centavos')) {
      context.handle(
        _impostoDiferidoAnteriorCentavosMeta,
        impostoDiferidoAnteriorCentavos.isAcceptableOrUnknown(
          data['imposto_diferido_anterior_centavos']!,
          _impostoDiferidoAnteriorCentavosMeta,
        ),
      );
    }
    if (data.containsKey('imposto_diferido_centavos')) {
      context.handle(
        _impostoDiferidoCentavosMeta,
        impostoDiferidoCentavos.isAcceptableOrUnknown(
          data['imposto_diferido_centavos']!,
          _impostoDiferidoCentavosMeta,
        ),
      );
    }
    if (data.containsKey('isento')) {
      context.handle(
        _isentoMeta,
        isento.isAcceptableOrUnknown(data['isento']!, _isentoMeta),
      );
    }
    if (data.containsKey('tabela_irpf_id')) {
      context.handle(
        _tabelaIrpfIdMeta,
        tabelaIrpfId.isAcceptableOrUnknown(
          data['tabela_irpf_id']!,
          _tabelaIrpfIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tabelaIrpfIdMeta);
    }
    if (data.containsKey('catalogo_versoes_snapshot')) {
      context.handle(
        _catalogoVersoesSnapshotMeta,
        catalogoVersoesSnapshot.isAcceptableOrUnknown(
          data['catalogo_versoes_snapshot']!,
          _catalogoVersoesSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_catalogoVersoesSnapshotMeta);
    }
    if (data.containsKey('parametros_snapshot')) {
      context.handle(
        _parametrosSnapshotMeta,
        parametrosSnapshot.isAcceptableOrUnknown(
          data['parametros_snapshot']!,
          _parametrosSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_parametrosSnapshotMeta);
    }
    if (data.containsKey('motor_versao')) {
      context.handle(
        _motorVersaoMeta,
        motorVersao.isAcceptableOrUnknown(
          data['motor_versao']!,
          _motorVersaoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_motorVersaoMeta);
    }
    if (data.containsKey('app_versao')) {
      context.handle(
        _appVersaoMeta,
        appVersao.isAcceptableOrUnknown(data['app_versao']!, _appVersaoMeta),
      );
    } else if (isInserting) {
      context.missing(_appVersaoMeta);
    }
    if (data.containsKey('calculada_em')) {
      context.handle(
        _calculadaEmMeta,
        calculadaEm.isAcceptableOrUnknown(
          data['calculada_em']!,
          _calculadaEmMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_calculadaEmMeta);
    }
    if (data.containsKey('fechada_em')) {
      context.handle(
        _fechadaEmMeta,
        fechadaEm.isAcceptableOrUnknown(data['fechada_em']!, _fechadaEmMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {competencia, versao},
  ];
  @override
  ApuracaoLocal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ApuracaoLocal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      competencia: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}competencia'],
      )!,
      versao: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}versao'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      receitaBrutaCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}receita_bruta_centavos'],
      )!,
      despesasLivroCaixaCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}despesas_livro_caixa_centavos'],
      )!,
      saldoNegativoAnteriorCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}saldo_negativo_anterior_centavos'],
      )!,
      saldoNegativoUtilizadoCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}saldo_negativo_utilizado_centavos'],
      )!,
      saldoNegativoTransportadoCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}saldo_negativo_transportado_centavos'],
      )!,
      inssCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}inss_centavos'],
      )!,
      qtdeDependentes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}qtde_dependentes'],
      )!,
      deducaoDependentesCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deducao_dependentes_centavos'],
      )!,
      descontoSimplificadoCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}desconto_simplificado_centavos'],
      )!,
      impostoCenarioRealCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}imposto_cenario_real_centavos'],
      )!,
      impostoCenarioSimplificadoCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}imposto_cenario_simplificado_centavos'],
      )!,
      cenarioAplicado: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cenario_aplicado'],
      )!,
      baseCalculoCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_calculo_centavos'],
      )!,
      aliquotaBp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}aliquota_bp'],
      )!,
      parcelaDeduzirCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parcela_deduzir_centavos'],
      )!,
      impostoApuradoCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}imposto_apurado_centavos'],
      )!,
      redutorLeiCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}redutor_lei_centavos'],
      )!,
      impostoDevidoCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}imposto_devido_centavos'],
      )!,
      impostoDiferidoAnteriorCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}imposto_diferido_anterior_centavos'],
      )!,
      impostoDiferidoCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}imposto_diferido_centavos'],
      )!,
      isento: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}isento'],
      )!,
      tabelaIrpfId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tabela_irpf_id'],
      )!,
      catalogoVersoesSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}catalogo_versoes_snapshot'],
      )!,
      parametrosSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parametros_snapshot'],
      )!,
      motorVersao: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}motor_versao'],
      )!,
      appVersao: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}app_versao'],
      )!,
      calculadaEm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}calculada_em'],
      )!,
      fechadaEm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fechada_em'],
      ),
    );
  }

  @override
  ApuracoesMensais createAlias(String alias) {
    return ApuracoesMensais(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['UNIQUE(competencia, versao)'];
  @override
  bool get dontWriteConstraints => true;
}

class ApuracaoLocal extends DataClass implements Insertable<ApuracaoLocal> {
  final String id;
  final String competencia;
  final int versao;
  final String status;
  final int receitaBrutaCentavos;
  final int despesasLivroCaixaCentavos;

  /// já com trava de 20%
  final int saldoNegativoAnteriorCentavos;
  final int saldoNegativoUtilizadoCentavos;
  final int saldoNegativoTransportadoCentavos;
  final int inssCentavos;
  final int qtdeDependentes;
  final int deducaoDependentesCentavos;
  final int descontoSimplificadoCentavos;

  /// os dois cenários, ambos gravados; o app mostra por que escolheu
  final int impostoCenarioRealCentavos;
  final int impostoCenarioSimplificadoCentavos;
  final String cenarioAplicado;
  final int baseCalculoCentavos;
  final int aliquotaBp;
  final int parcelaDeduzirCentavos;
  final int impostoApuradoCentavos;
  final int redutorLeiCentavos;

  /// Lei 15.270/2025:
  final int impostoDevidoCentavos;

  /// incide sobre o IMPOSTO
  final int impostoDiferidoAnteriorCentavos;

  /// mínimo do DARF
  final int impostoDiferidoCentavos;
  final int isento;
  final int tabelaIrpfId;
  final String catalogoVersoesSnapshot;

  /// JSON: versão de cada catálogo usado
  final String parametrosSnapshot;

  /// JSON
  final String motorVersao;

  /// semver do motor
  final String appVersao;
  final int calculadaEm;
  final int? fechadaEm;
  const ApuracaoLocal({
    required this.id,
    required this.competencia,
    required this.versao,
    required this.status,
    required this.receitaBrutaCentavos,
    required this.despesasLivroCaixaCentavos,
    required this.saldoNegativoAnteriorCentavos,
    required this.saldoNegativoUtilizadoCentavos,
    required this.saldoNegativoTransportadoCentavos,
    required this.inssCentavos,
    required this.qtdeDependentes,
    required this.deducaoDependentesCentavos,
    required this.descontoSimplificadoCentavos,
    required this.impostoCenarioRealCentavos,
    required this.impostoCenarioSimplificadoCentavos,
    required this.cenarioAplicado,
    required this.baseCalculoCentavos,
    required this.aliquotaBp,
    required this.parcelaDeduzirCentavos,
    required this.impostoApuradoCentavos,
    required this.redutorLeiCentavos,
    required this.impostoDevidoCentavos,
    required this.impostoDiferidoAnteriorCentavos,
    required this.impostoDiferidoCentavos,
    required this.isento,
    required this.tabelaIrpfId,
    required this.catalogoVersoesSnapshot,
    required this.parametrosSnapshot,
    required this.motorVersao,
    required this.appVersao,
    required this.calculadaEm,
    this.fechadaEm,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['competencia'] = Variable<String>(competencia);
    map['versao'] = Variable<int>(versao);
    map['status'] = Variable<String>(status);
    map['receita_bruta_centavos'] = Variable<int>(receitaBrutaCentavos);
    map['despesas_livro_caixa_centavos'] = Variable<int>(
      despesasLivroCaixaCentavos,
    );
    map['saldo_negativo_anterior_centavos'] = Variable<int>(
      saldoNegativoAnteriorCentavos,
    );
    map['saldo_negativo_utilizado_centavos'] = Variable<int>(
      saldoNegativoUtilizadoCentavos,
    );
    map['saldo_negativo_transportado_centavos'] = Variable<int>(
      saldoNegativoTransportadoCentavos,
    );
    map['inss_centavos'] = Variable<int>(inssCentavos);
    map['qtde_dependentes'] = Variable<int>(qtdeDependentes);
    map['deducao_dependentes_centavos'] = Variable<int>(
      deducaoDependentesCentavos,
    );
    map['desconto_simplificado_centavos'] = Variable<int>(
      descontoSimplificadoCentavos,
    );
    map['imposto_cenario_real_centavos'] = Variable<int>(
      impostoCenarioRealCentavos,
    );
    map['imposto_cenario_simplificado_centavos'] = Variable<int>(
      impostoCenarioSimplificadoCentavos,
    );
    map['cenario_aplicado'] = Variable<String>(cenarioAplicado);
    map['base_calculo_centavos'] = Variable<int>(baseCalculoCentavos);
    map['aliquota_bp'] = Variable<int>(aliquotaBp);
    map['parcela_deduzir_centavos'] = Variable<int>(parcelaDeduzirCentavos);
    map['imposto_apurado_centavos'] = Variable<int>(impostoApuradoCentavos);
    map['redutor_lei_centavos'] = Variable<int>(redutorLeiCentavos);
    map['imposto_devido_centavos'] = Variable<int>(impostoDevidoCentavos);
    map['imposto_diferido_anterior_centavos'] = Variable<int>(
      impostoDiferidoAnteriorCentavos,
    );
    map['imposto_diferido_centavos'] = Variable<int>(impostoDiferidoCentavos);
    map['isento'] = Variable<int>(isento);
    map['tabela_irpf_id'] = Variable<int>(tabelaIrpfId);
    map['catalogo_versoes_snapshot'] = Variable<String>(
      catalogoVersoesSnapshot,
    );
    map['parametros_snapshot'] = Variable<String>(parametrosSnapshot);
    map['motor_versao'] = Variable<String>(motorVersao);
    map['app_versao'] = Variable<String>(appVersao);
    map['calculada_em'] = Variable<int>(calculadaEm);
    if (!nullToAbsent || fechadaEm != null) {
      map['fechada_em'] = Variable<int>(fechadaEm);
    }
    return map;
  }

  ApuracoesMensaisCompanion toCompanion(bool nullToAbsent) {
    return ApuracoesMensaisCompanion(
      id: Value(id),
      competencia: Value(competencia),
      versao: Value(versao),
      status: Value(status),
      receitaBrutaCentavos: Value(receitaBrutaCentavos),
      despesasLivroCaixaCentavos: Value(despesasLivroCaixaCentavos),
      saldoNegativoAnteriorCentavos: Value(saldoNegativoAnteriorCentavos),
      saldoNegativoUtilizadoCentavos: Value(saldoNegativoUtilizadoCentavos),
      saldoNegativoTransportadoCentavos: Value(
        saldoNegativoTransportadoCentavos,
      ),
      inssCentavos: Value(inssCentavos),
      qtdeDependentes: Value(qtdeDependentes),
      deducaoDependentesCentavos: Value(deducaoDependentesCentavos),
      descontoSimplificadoCentavos: Value(descontoSimplificadoCentavos),
      impostoCenarioRealCentavos: Value(impostoCenarioRealCentavos),
      impostoCenarioSimplificadoCentavos: Value(
        impostoCenarioSimplificadoCentavos,
      ),
      cenarioAplicado: Value(cenarioAplicado),
      baseCalculoCentavos: Value(baseCalculoCentavos),
      aliquotaBp: Value(aliquotaBp),
      parcelaDeduzirCentavos: Value(parcelaDeduzirCentavos),
      impostoApuradoCentavos: Value(impostoApuradoCentavos),
      redutorLeiCentavos: Value(redutorLeiCentavos),
      impostoDevidoCentavos: Value(impostoDevidoCentavos),
      impostoDiferidoAnteriorCentavos: Value(impostoDiferidoAnteriorCentavos),
      impostoDiferidoCentavos: Value(impostoDiferidoCentavos),
      isento: Value(isento),
      tabelaIrpfId: Value(tabelaIrpfId),
      catalogoVersoesSnapshot: Value(catalogoVersoesSnapshot),
      parametrosSnapshot: Value(parametrosSnapshot),
      motorVersao: Value(motorVersao),
      appVersao: Value(appVersao),
      calculadaEm: Value(calculadaEm),
      fechadaEm: fechadaEm == null && nullToAbsent
          ? const Value.absent()
          : Value(fechadaEm),
    );
  }

  factory ApuracaoLocal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ApuracaoLocal(
      id: serializer.fromJson<String>(json['id']),
      competencia: serializer.fromJson<String>(json['competencia']),
      versao: serializer.fromJson<int>(json['versao']),
      status: serializer.fromJson<String>(json['status']),
      receitaBrutaCentavos: serializer.fromJson<int>(
        json['receita_bruta_centavos'],
      ),
      despesasLivroCaixaCentavos: serializer.fromJson<int>(
        json['despesas_livro_caixa_centavos'],
      ),
      saldoNegativoAnteriorCentavos: serializer.fromJson<int>(
        json['saldo_negativo_anterior_centavos'],
      ),
      saldoNegativoUtilizadoCentavos: serializer.fromJson<int>(
        json['saldo_negativo_utilizado_centavos'],
      ),
      saldoNegativoTransportadoCentavos: serializer.fromJson<int>(
        json['saldo_negativo_transportado_centavos'],
      ),
      inssCentavos: serializer.fromJson<int>(json['inss_centavos']),
      qtdeDependentes: serializer.fromJson<int>(json['qtde_dependentes']),
      deducaoDependentesCentavos: serializer.fromJson<int>(
        json['deducao_dependentes_centavos'],
      ),
      descontoSimplificadoCentavos: serializer.fromJson<int>(
        json['desconto_simplificado_centavos'],
      ),
      impostoCenarioRealCentavos: serializer.fromJson<int>(
        json['imposto_cenario_real_centavos'],
      ),
      impostoCenarioSimplificadoCentavos: serializer.fromJson<int>(
        json['imposto_cenario_simplificado_centavos'],
      ),
      cenarioAplicado: serializer.fromJson<String>(json['cenario_aplicado']),
      baseCalculoCentavos: serializer.fromJson<int>(
        json['base_calculo_centavos'],
      ),
      aliquotaBp: serializer.fromJson<int>(json['aliquota_bp']),
      parcelaDeduzirCentavos: serializer.fromJson<int>(
        json['parcela_deduzir_centavos'],
      ),
      impostoApuradoCentavos: serializer.fromJson<int>(
        json['imposto_apurado_centavos'],
      ),
      redutorLeiCentavos: serializer.fromJson<int>(
        json['redutor_lei_centavos'],
      ),
      impostoDevidoCentavos: serializer.fromJson<int>(
        json['imposto_devido_centavos'],
      ),
      impostoDiferidoAnteriorCentavos: serializer.fromJson<int>(
        json['imposto_diferido_anterior_centavos'],
      ),
      impostoDiferidoCentavos: serializer.fromJson<int>(
        json['imposto_diferido_centavos'],
      ),
      isento: serializer.fromJson<int>(json['isento']),
      tabelaIrpfId: serializer.fromJson<int>(json['tabela_irpf_id']),
      catalogoVersoesSnapshot: serializer.fromJson<String>(
        json['catalogo_versoes_snapshot'],
      ),
      parametrosSnapshot: serializer.fromJson<String>(
        json['parametros_snapshot'],
      ),
      motorVersao: serializer.fromJson<String>(json['motor_versao']),
      appVersao: serializer.fromJson<String>(json['app_versao']),
      calculadaEm: serializer.fromJson<int>(json['calculada_em']),
      fechadaEm: serializer.fromJson<int?>(json['fechada_em']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'competencia': serializer.toJson<String>(competencia),
      'versao': serializer.toJson<int>(versao),
      'status': serializer.toJson<String>(status),
      'receita_bruta_centavos': serializer.toJson<int>(receitaBrutaCentavos),
      'despesas_livro_caixa_centavos': serializer.toJson<int>(
        despesasLivroCaixaCentavos,
      ),
      'saldo_negativo_anterior_centavos': serializer.toJson<int>(
        saldoNegativoAnteriorCentavos,
      ),
      'saldo_negativo_utilizado_centavos': serializer.toJson<int>(
        saldoNegativoUtilizadoCentavos,
      ),
      'saldo_negativo_transportado_centavos': serializer.toJson<int>(
        saldoNegativoTransportadoCentavos,
      ),
      'inss_centavos': serializer.toJson<int>(inssCentavos),
      'qtde_dependentes': serializer.toJson<int>(qtdeDependentes),
      'deducao_dependentes_centavos': serializer.toJson<int>(
        deducaoDependentesCentavos,
      ),
      'desconto_simplificado_centavos': serializer.toJson<int>(
        descontoSimplificadoCentavos,
      ),
      'imposto_cenario_real_centavos': serializer.toJson<int>(
        impostoCenarioRealCentavos,
      ),
      'imposto_cenario_simplificado_centavos': serializer.toJson<int>(
        impostoCenarioSimplificadoCentavos,
      ),
      'cenario_aplicado': serializer.toJson<String>(cenarioAplicado),
      'base_calculo_centavos': serializer.toJson<int>(baseCalculoCentavos),
      'aliquota_bp': serializer.toJson<int>(aliquotaBp),
      'parcela_deduzir_centavos': serializer.toJson<int>(
        parcelaDeduzirCentavos,
      ),
      'imposto_apurado_centavos': serializer.toJson<int>(
        impostoApuradoCentavos,
      ),
      'redutor_lei_centavos': serializer.toJson<int>(redutorLeiCentavos),
      'imposto_devido_centavos': serializer.toJson<int>(impostoDevidoCentavos),
      'imposto_diferido_anterior_centavos': serializer.toJson<int>(
        impostoDiferidoAnteriorCentavos,
      ),
      'imposto_diferido_centavos': serializer.toJson<int>(
        impostoDiferidoCentavos,
      ),
      'isento': serializer.toJson<int>(isento),
      'tabela_irpf_id': serializer.toJson<int>(tabelaIrpfId),
      'catalogo_versoes_snapshot': serializer.toJson<String>(
        catalogoVersoesSnapshot,
      ),
      'parametros_snapshot': serializer.toJson<String>(parametrosSnapshot),
      'motor_versao': serializer.toJson<String>(motorVersao),
      'app_versao': serializer.toJson<String>(appVersao),
      'calculada_em': serializer.toJson<int>(calculadaEm),
      'fechada_em': serializer.toJson<int?>(fechadaEm),
    };
  }

  ApuracaoLocal copyWith({
    String? id,
    String? competencia,
    int? versao,
    String? status,
    int? receitaBrutaCentavos,
    int? despesasLivroCaixaCentavos,
    int? saldoNegativoAnteriorCentavos,
    int? saldoNegativoUtilizadoCentavos,
    int? saldoNegativoTransportadoCentavos,
    int? inssCentavos,
    int? qtdeDependentes,
    int? deducaoDependentesCentavos,
    int? descontoSimplificadoCentavos,
    int? impostoCenarioRealCentavos,
    int? impostoCenarioSimplificadoCentavos,
    String? cenarioAplicado,
    int? baseCalculoCentavos,
    int? aliquotaBp,
    int? parcelaDeduzirCentavos,
    int? impostoApuradoCentavos,
    int? redutorLeiCentavos,
    int? impostoDevidoCentavos,
    int? impostoDiferidoAnteriorCentavos,
    int? impostoDiferidoCentavos,
    int? isento,
    int? tabelaIrpfId,
    String? catalogoVersoesSnapshot,
    String? parametrosSnapshot,
    String? motorVersao,
    String? appVersao,
    int? calculadaEm,
    Value<int?> fechadaEm = const Value.absent(),
  }) => ApuracaoLocal(
    id: id ?? this.id,
    competencia: competencia ?? this.competencia,
    versao: versao ?? this.versao,
    status: status ?? this.status,
    receitaBrutaCentavos: receitaBrutaCentavos ?? this.receitaBrutaCentavos,
    despesasLivroCaixaCentavos:
        despesasLivroCaixaCentavos ?? this.despesasLivroCaixaCentavos,
    saldoNegativoAnteriorCentavos:
        saldoNegativoAnteriorCentavos ?? this.saldoNegativoAnteriorCentavos,
    saldoNegativoUtilizadoCentavos:
        saldoNegativoUtilizadoCentavos ?? this.saldoNegativoUtilizadoCentavos,
    saldoNegativoTransportadoCentavos:
        saldoNegativoTransportadoCentavos ??
        this.saldoNegativoTransportadoCentavos,
    inssCentavos: inssCentavos ?? this.inssCentavos,
    qtdeDependentes: qtdeDependentes ?? this.qtdeDependentes,
    deducaoDependentesCentavos:
        deducaoDependentesCentavos ?? this.deducaoDependentesCentavos,
    descontoSimplificadoCentavos:
        descontoSimplificadoCentavos ?? this.descontoSimplificadoCentavos,
    impostoCenarioRealCentavos:
        impostoCenarioRealCentavos ?? this.impostoCenarioRealCentavos,
    impostoCenarioSimplificadoCentavos:
        impostoCenarioSimplificadoCentavos ??
        this.impostoCenarioSimplificadoCentavos,
    cenarioAplicado: cenarioAplicado ?? this.cenarioAplicado,
    baseCalculoCentavos: baseCalculoCentavos ?? this.baseCalculoCentavos,
    aliquotaBp: aliquotaBp ?? this.aliquotaBp,
    parcelaDeduzirCentavos:
        parcelaDeduzirCentavos ?? this.parcelaDeduzirCentavos,
    impostoApuradoCentavos:
        impostoApuradoCentavos ?? this.impostoApuradoCentavos,
    redutorLeiCentavos: redutorLeiCentavos ?? this.redutorLeiCentavos,
    impostoDevidoCentavos: impostoDevidoCentavos ?? this.impostoDevidoCentavos,
    impostoDiferidoAnteriorCentavos:
        impostoDiferidoAnteriorCentavos ?? this.impostoDiferidoAnteriorCentavos,
    impostoDiferidoCentavos:
        impostoDiferidoCentavos ?? this.impostoDiferidoCentavos,
    isento: isento ?? this.isento,
    tabelaIrpfId: tabelaIrpfId ?? this.tabelaIrpfId,
    catalogoVersoesSnapshot:
        catalogoVersoesSnapshot ?? this.catalogoVersoesSnapshot,
    parametrosSnapshot: parametrosSnapshot ?? this.parametrosSnapshot,
    motorVersao: motorVersao ?? this.motorVersao,
    appVersao: appVersao ?? this.appVersao,
    calculadaEm: calculadaEm ?? this.calculadaEm,
    fechadaEm: fechadaEm.present ? fechadaEm.value : this.fechadaEm,
  );
  ApuracaoLocal copyWithCompanion(ApuracoesMensaisCompanion data) {
    return ApuracaoLocal(
      id: data.id.present ? data.id.value : this.id,
      competencia: data.competencia.present
          ? data.competencia.value
          : this.competencia,
      versao: data.versao.present ? data.versao.value : this.versao,
      status: data.status.present ? data.status.value : this.status,
      receitaBrutaCentavos: data.receitaBrutaCentavos.present
          ? data.receitaBrutaCentavos.value
          : this.receitaBrutaCentavos,
      despesasLivroCaixaCentavos: data.despesasLivroCaixaCentavos.present
          ? data.despesasLivroCaixaCentavos.value
          : this.despesasLivroCaixaCentavos,
      saldoNegativoAnteriorCentavos: data.saldoNegativoAnteriorCentavos.present
          ? data.saldoNegativoAnteriorCentavos.value
          : this.saldoNegativoAnteriorCentavos,
      saldoNegativoUtilizadoCentavos:
          data.saldoNegativoUtilizadoCentavos.present
          ? data.saldoNegativoUtilizadoCentavos.value
          : this.saldoNegativoUtilizadoCentavos,
      saldoNegativoTransportadoCentavos:
          data.saldoNegativoTransportadoCentavos.present
          ? data.saldoNegativoTransportadoCentavos.value
          : this.saldoNegativoTransportadoCentavos,
      inssCentavos: data.inssCentavos.present
          ? data.inssCentavos.value
          : this.inssCentavos,
      qtdeDependentes: data.qtdeDependentes.present
          ? data.qtdeDependentes.value
          : this.qtdeDependentes,
      deducaoDependentesCentavos: data.deducaoDependentesCentavos.present
          ? data.deducaoDependentesCentavos.value
          : this.deducaoDependentesCentavos,
      descontoSimplificadoCentavos: data.descontoSimplificadoCentavos.present
          ? data.descontoSimplificadoCentavos.value
          : this.descontoSimplificadoCentavos,
      impostoCenarioRealCentavos: data.impostoCenarioRealCentavos.present
          ? data.impostoCenarioRealCentavos.value
          : this.impostoCenarioRealCentavos,
      impostoCenarioSimplificadoCentavos:
          data.impostoCenarioSimplificadoCentavos.present
          ? data.impostoCenarioSimplificadoCentavos.value
          : this.impostoCenarioSimplificadoCentavos,
      cenarioAplicado: data.cenarioAplicado.present
          ? data.cenarioAplicado.value
          : this.cenarioAplicado,
      baseCalculoCentavos: data.baseCalculoCentavos.present
          ? data.baseCalculoCentavos.value
          : this.baseCalculoCentavos,
      aliquotaBp: data.aliquotaBp.present
          ? data.aliquotaBp.value
          : this.aliquotaBp,
      parcelaDeduzirCentavos: data.parcelaDeduzirCentavos.present
          ? data.parcelaDeduzirCentavos.value
          : this.parcelaDeduzirCentavos,
      impostoApuradoCentavos: data.impostoApuradoCentavos.present
          ? data.impostoApuradoCentavos.value
          : this.impostoApuradoCentavos,
      redutorLeiCentavos: data.redutorLeiCentavos.present
          ? data.redutorLeiCentavos.value
          : this.redutorLeiCentavos,
      impostoDevidoCentavos: data.impostoDevidoCentavos.present
          ? data.impostoDevidoCentavos.value
          : this.impostoDevidoCentavos,
      impostoDiferidoAnteriorCentavos:
          data.impostoDiferidoAnteriorCentavos.present
          ? data.impostoDiferidoAnteriorCentavos.value
          : this.impostoDiferidoAnteriorCentavos,
      impostoDiferidoCentavos: data.impostoDiferidoCentavos.present
          ? data.impostoDiferidoCentavos.value
          : this.impostoDiferidoCentavos,
      isento: data.isento.present ? data.isento.value : this.isento,
      tabelaIrpfId: data.tabelaIrpfId.present
          ? data.tabelaIrpfId.value
          : this.tabelaIrpfId,
      catalogoVersoesSnapshot: data.catalogoVersoesSnapshot.present
          ? data.catalogoVersoesSnapshot.value
          : this.catalogoVersoesSnapshot,
      parametrosSnapshot: data.parametrosSnapshot.present
          ? data.parametrosSnapshot.value
          : this.parametrosSnapshot,
      motorVersao: data.motorVersao.present
          ? data.motorVersao.value
          : this.motorVersao,
      appVersao: data.appVersao.present ? data.appVersao.value : this.appVersao,
      calculadaEm: data.calculadaEm.present
          ? data.calculadaEm.value
          : this.calculadaEm,
      fechadaEm: data.fechadaEm.present ? data.fechadaEm.value : this.fechadaEm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ApuracaoLocal(')
          ..write('id: $id, ')
          ..write('competencia: $competencia, ')
          ..write('versao: $versao, ')
          ..write('status: $status, ')
          ..write('receitaBrutaCentavos: $receitaBrutaCentavos, ')
          ..write('despesasLivroCaixaCentavos: $despesasLivroCaixaCentavos, ')
          ..write(
            'saldoNegativoAnteriorCentavos: $saldoNegativoAnteriorCentavos, ',
          )
          ..write(
            'saldoNegativoUtilizadoCentavos: $saldoNegativoUtilizadoCentavos, ',
          )
          ..write(
            'saldoNegativoTransportadoCentavos: $saldoNegativoTransportadoCentavos, ',
          )
          ..write('inssCentavos: $inssCentavos, ')
          ..write('qtdeDependentes: $qtdeDependentes, ')
          ..write('deducaoDependentesCentavos: $deducaoDependentesCentavos, ')
          ..write(
            'descontoSimplificadoCentavos: $descontoSimplificadoCentavos, ',
          )
          ..write('impostoCenarioRealCentavos: $impostoCenarioRealCentavos, ')
          ..write(
            'impostoCenarioSimplificadoCentavos: $impostoCenarioSimplificadoCentavos, ',
          )
          ..write('cenarioAplicado: $cenarioAplicado, ')
          ..write('baseCalculoCentavos: $baseCalculoCentavos, ')
          ..write('aliquotaBp: $aliquotaBp, ')
          ..write('parcelaDeduzirCentavos: $parcelaDeduzirCentavos, ')
          ..write('impostoApuradoCentavos: $impostoApuradoCentavos, ')
          ..write('redutorLeiCentavos: $redutorLeiCentavos, ')
          ..write('impostoDevidoCentavos: $impostoDevidoCentavos, ')
          ..write(
            'impostoDiferidoAnteriorCentavos: $impostoDiferidoAnteriorCentavos, ',
          )
          ..write('impostoDiferidoCentavos: $impostoDiferidoCentavos, ')
          ..write('isento: $isento, ')
          ..write('tabelaIrpfId: $tabelaIrpfId, ')
          ..write('catalogoVersoesSnapshot: $catalogoVersoesSnapshot, ')
          ..write('parametrosSnapshot: $parametrosSnapshot, ')
          ..write('motorVersao: $motorVersao, ')
          ..write('appVersao: $appVersao, ')
          ..write('calculadaEm: $calculadaEm, ')
          ..write('fechadaEm: $fechadaEm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    competencia,
    versao,
    status,
    receitaBrutaCentavos,
    despesasLivroCaixaCentavos,
    saldoNegativoAnteriorCentavos,
    saldoNegativoUtilizadoCentavos,
    saldoNegativoTransportadoCentavos,
    inssCentavos,
    qtdeDependentes,
    deducaoDependentesCentavos,
    descontoSimplificadoCentavos,
    impostoCenarioRealCentavos,
    impostoCenarioSimplificadoCentavos,
    cenarioAplicado,
    baseCalculoCentavos,
    aliquotaBp,
    parcelaDeduzirCentavos,
    impostoApuradoCentavos,
    redutorLeiCentavos,
    impostoDevidoCentavos,
    impostoDiferidoAnteriorCentavos,
    impostoDiferidoCentavos,
    isento,
    tabelaIrpfId,
    catalogoVersoesSnapshot,
    parametrosSnapshot,
    motorVersao,
    appVersao,
    calculadaEm,
    fechadaEm,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ApuracaoLocal &&
          other.id == this.id &&
          other.competencia == this.competencia &&
          other.versao == this.versao &&
          other.status == this.status &&
          other.receitaBrutaCentavos == this.receitaBrutaCentavos &&
          other.despesasLivroCaixaCentavos == this.despesasLivroCaixaCentavos &&
          other.saldoNegativoAnteriorCentavos ==
              this.saldoNegativoAnteriorCentavos &&
          other.saldoNegativoUtilizadoCentavos ==
              this.saldoNegativoUtilizadoCentavos &&
          other.saldoNegativoTransportadoCentavos ==
              this.saldoNegativoTransportadoCentavos &&
          other.inssCentavos == this.inssCentavos &&
          other.qtdeDependentes == this.qtdeDependentes &&
          other.deducaoDependentesCentavos == this.deducaoDependentesCentavos &&
          other.descontoSimplificadoCentavos ==
              this.descontoSimplificadoCentavos &&
          other.impostoCenarioRealCentavos == this.impostoCenarioRealCentavos &&
          other.impostoCenarioSimplificadoCentavos ==
              this.impostoCenarioSimplificadoCentavos &&
          other.cenarioAplicado == this.cenarioAplicado &&
          other.baseCalculoCentavos == this.baseCalculoCentavos &&
          other.aliquotaBp == this.aliquotaBp &&
          other.parcelaDeduzirCentavos == this.parcelaDeduzirCentavos &&
          other.impostoApuradoCentavos == this.impostoApuradoCentavos &&
          other.redutorLeiCentavos == this.redutorLeiCentavos &&
          other.impostoDevidoCentavos == this.impostoDevidoCentavos &&
          other.impostoDiferidoAnteriorCentavos ==
              this.impostoDiferidoAnteriorCentavos &&
          other.impostoDiferidoCentavos == this.impostoDiferidoCentavos &&
          other.isento == this.isento &&
          other.tabelaIrpfId == this.tabelaIrpfId &&
          other.catalogoVersoesSnapshot == this.catalogoVersoesSnapshot &&
          other.parametrosSnapshot == this.parametrosSnapshot &&
          other.motorVersao == this.motorVersao &&
          other.appVersao == this.appVersao &&
          other.calculadaEm == this.calculadaEm &&
          other.fechadaEm == this.fechadaEm);
}

class ApuracoesMensaisCompanion extends UpdateCompanion<ApuracaoLocal> {
  final Value<String> id;
  final Value<String> competencia;
  final Value<int> versao;
  final Value<String> status;
  final Value<int> receitaBrutaCentavos;
  final Value<int> despesasLivroCaixaCentavos;
  final Value<int> saldoNegativoAnteriorCentavos;
  final Value<int> saldoNegativoUtilizadoCentavos;
  final Value<int> saldoNegativoTransportadoCentavos;
  final Value<int> inssCentavos;
  final Value<int> qtdeDependentes;
  final Value<int> deducaoDependentesCentavos;
  final Value<int> descontoSimplificadoCentavos;
  final Value<int> impostoCenarioRealCentavos;
  final Value<int> impostoCenarioSimplificadoCentavos;
  final Value<String> cenarioAplicado;
  final Value<int> baseCalculoCentavos;
  final Value<int> aliquotaBp;
  final Value<int> parcelaDeduzirCentavos;
  final Value<int> impostoApuradoCentavos;
  final Value<int> redutorLeiCentavos;
  final Value<int> impostoDevidoCentavos;
  final Value<int> impostoDiferidoAnteriorCentavos;
  final Value<int> impostoDiferidoCentavos;
  final Value<int> isento;
  final Value<int> tabelaIrpfId;
  final Value<String> catalogoVersoesSnapshot;
  final Value<String> parametrosSnapshot;
  final Value<String> motorVersao;
  final Value<String> appVersao;
  final Value<int> calculadaEm;
  final Value<int?> fechadaEm;
  final Value<int> rowid;
  const ApuracoesMensaisCompanion({
    this.id = const Value.absent(),
    this.competencia = const Value.absent(),
    this.versao = const Value.absent(),
    this.status = const Value.absent(),
    this.receitaBrutaCentavos = const Value.absent(),
    this.despesasLivroCaixaCentavos = const Value.absent(),
    this.saldoNegativoAnteriorCentavos = const Value.absent(),
    this.saldoNegativoUtilizadoCentavos = const Value.absent(),
    this.saldoNegativoTransportadoCentavos = const Value.absent(),
    this.inssCentavos = const Value.absent(),
    this.qtdeDependentes = const Value.absent(),
    this.deducaoDependentesCentavos = const Value.absent(),
    this.descontoSimplificadoCentavos = const Value.absent(),
    this.impostoCenarioRealCentavos = const Value.absent(),
    this.impostoCenarioSimplificadoCentavos = const Value.absent(),
    this.cenarioAplicado = const Value.absent(),
    this.baseCalculoCentavos = const Value.absent(),
    this.aliquotaBp = const Value.absent(),
    this.parcelaDeduzirCentavos = const Value.absent(),
    this.impostoApuradoCentavos = const Value.absent(),
    this.redutorLeiCentavos = const Value.absent(),
    this.impostoDevidoCentavos = const Value.absent(),
    this.impostoDiferidoAnteriorCentavos = const Value.absent(),
    this.impostoDiferidoCentavos = const Value.absent(),
    this.isento = const Value.absent(),
    this.tabelaIrpfId = const Value.absent(),
    this.catalogoVersoesSnapshot = const Value.absent(),
    this.parametrosSnapshot = const Value.absent(),
    this.motorVersao = const Value.absent(),
    this.appVersao = const Value.absent(),
    this.calculadaEm = const Value.absent(),
    this.fechadaEm = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ApuracoesMensaisCompanion.insert({
    required String id,
    required String competencia,
    this.versao = const Value.absent(),
    this.status = const Value.absent(),
    required int receitaBrutaCentavos,
    required int despesasLivroCaixaCentavos,
    this.saldoNegativoAnteriorCentavos = const Value.absent(),
    this.saldoNegativoUtilizadoCentavos = const Value.absent(),
    this.saldoNegativoTransportadoCentavos = const Value.absent(),
    required int inssCentavos,
    required int qtdeDependentes,
    required int deducaoDependentesCentavos,
    required int descontoSimplificadoCentavos,
    required int impostoCenarioRealCentavos,
    required int impostoCenarioSimplificadoCentavos,
    required String cenarioAplicado,
    required int baseCalculoCentavos,
    required int aliquotaBp,
    required int parcelaDeduzirCentavos,
    required int impostoApuradoCentavos,
    this.redutorLeiCentavos = const Value.absent(),
    required int impostoDevidoCentavos,
    this.impostoDiferidoAnteriorCentavos = const Value.absent(),
    this.impostoDiferidoCentavos = const Value.absent(),
    this.isento = const Value.absent(),
    required int tabelaIrpfId,
    required String catalogoVersoesSnapshot,
    required String parametrosSnapshot,
    required String motorVersao,
    required String appVersao,
    required int calculadaEm,
    this.fechadaEm = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       competencia = Value(competencia),
       receitaBrutaCentavos = Value(receitaBrutaCentavos),
       despesasLivroCaixaCentavos = Value(despesasLivroCaixaCentavos),
       inssCentavos = Value(inssCentavos),
       qtdeDependentes = Value(qtdeDependentes),
       deducaoDependentesCentavos = Value(deducaoDependentesCentavos),
       descontoSimplificadoCentavos = Value(descontoSimplificadoCentavos),
       impostoCenarioRealCentavos = Value(impostoCenarioRealCentavos),
       impostoCenarioSimplificadoCentavos = Value(
         impostoCenarioSimplificadoCentavos,
       ),
       cenarioAplicado = Value(cenarioAplicado),
       baseCalculoCentavos = Value(baseCalculoCentavos),
       aliquotaBp = Value(aliquotaBp),
       parcelaDeduzirCentavos = Value(parcelaDeduzirCentavos),
       impostoApuradoCentavos = Value(impostoApuradoCentavos),
       impostoDevidoCentavos = Value(impostoDevidoCentavos),
       tabelaIrpfId = Value(tabelaIrpfId),
       catalogoVersoesSnapshot = Value(catalogoVersoesSnapshot),
       parametrosSnapshot = Value(parametrosSnapshot),
       motorVersao = Value(motorVersao),
       appVersao = Value(appVersao),
       calculadaEm = Value(calculadaEm);
  static Insertable<ApuracaoLocal> custom({
    Expression<String>? id,
    Expression<String>? competencia,
    Expression<int>? versao,
    Expression<String>? status,
    Expression<int>? receitaBrutaCentavos,
    Expression<int>? despesasLivroCaixaCentavos,
    Expression<int>? saldoNegativoAnteriorCentavos,
    Expression<int>? saldoNegativoUtilizadoCentavos,
    Expression<int>? saldoNegativoTransportadoCentavos,
    Expression<int>? inssCentavos,
    Expression<int>? qtdeDependentes,
    Expression<int>? deducaoDependentesCentavos,
    Expression<int>? descontoSimplificadoCentavos,
    Expression<int>? impostoCenarioRealCentavos,
    Expression<int>? impostoCenarioSimplificadoCentavos,
    Expression<String>? cenarioAplicado,
    Expression<int>? baseCalculoCentavos,
    Expression<int>? aliquotaBp,
    Expression<int>? parcelaDeduzirCentavos,
    Expression<int>? impostoApuradoCentavos,
    Expression<int>? redutorLeiCentavos,
    Expression<int>? impostoDevidoCentavos,
    Expression<int>? impostoDiferidoAnteriorCentavos,
    Expression<int>? impostoDiferidoCentavos,
    Expression<int>? isento,
    Expression<int>? tabelaIrpfId,
    Expression<String>? catalogoVersoesSnapshot,
    Expression<String>? parametrosSnapshot,
    Expression<String>? motorVersao,
    Expression<String>? appVersao,
    Expression<int>? calculadaEm,
    Expression<int>? fechadaEm,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (competencia != null) 'competencia': competencia,
      if (versao != null) 'versao': versao,
      if (status != null) 'status': status,
      if (receitaBrutaCentavos != null)
        'receita_bruta_centavos': receitaBrutaCentavos,
      if (despesasLivroCaixaCentavos != null)
        'despesas_livro_caixa_centavos': despesasLivroCaixaCentavos,
      if (saldoNegativoAnteriorCentavos != null)
        'saldo_negativo_anterior_centavos': saldoNegativoAnteriorCentavos,
      if (saldoNegativoUtilizadoCentavos != null)
        'saldo_negativo_utilizado_centavos': saldoNegativoUtilizadoCentavos,
      if (saldoNegativoTransportadoCentavos != null)
        'saldo_negativo_transportado_centavos':
            saldoNegativoTransportadoCentavos,
      if (inssCentavos != null) 'inss_centavos': inssCentavos,
      if (qtdeDependentes != null) 'qtde_dependentes': qtdeDependentes,
      if (deducaoDependentesCentavos != null)
        'deducao_dependentes_centavos': deducaoDependentesCentavos,
      if (descontoSimplificadoCentavos != null)
        'desconto_simplificado_centavos': descontoSimplificadoCentavos,
      if (impostoCenarioRealCentavos != null)
        'imposto_cenario_real_centavos': impostoCenarioRealCentavos,
      if (impostoCenarioSimplificadoCentavos != null)
        'imposto_cenario_simplificado_centavos':
            impostoCenarioSimplificadoCentavos,
      if (cenarioAplicado != null) 'cenario_aplicado': cenarioAplicado,
      if (baseCalculoCentavos != null)
        'base_calculo_centavos': baseCalculoCentavos,
      if (aliquotaBp != null) 'aliquota_bp': aliquotaBp,
      if (parcelaDeduzirCentavos != null)
        'parcela_deduzir_centavos': parcelaDeduzirCentavos,
      if (impostoApuradoCentavos != null)
        'imposto_apurado_centavos': impostoApuradoCentavos,
      if (redutorLeiCentavos != null)
        'redutor_lei_centavos': redutorLeiCentavos,
      if (impostoDevidoCentavos != null)
        'imposto_devido_centavos': impostoDevidoCentavos,
      if (impostoDiferidoAnteriorCentavos != null)
        'imposto_diferido_anterior_centavos': impostoDiferidoAnteriorCentavos,
      if (impostoDiferidoCentavos != null)
        'imposto_diferido_centavos': impostoDiferidoCentavos,
      if (isento != null) 'isento': isento,
      if (tabelaIrpfId != null) 'tabela_irpf_id': tabelaIrpfId,
      if (catalogoVersoesSnapshot != null)
        'catalogo_versoes_snapshot': catalogoVersoesSnapshot,
      if (parametrosSnapshot != null) 'parametros_snapshot': parametrosSnapshot,
      if (motorVersao != null) 'motor_versao': motorVersao,
      if (appVersao != null) 'app_versao': appVersao,
      if (calculadaEm != null) 'calculada_em': calculadaEm,
      if (fechadaEm != null) 'fechada_em': fechadaEm,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ApuracoesMensaisCompanion copyWith({
    Value<String>? id,
    Value<String>? competencia,
    Value<int>? versao,
    Value<String>? status,
    Value<int>? receitaBrutaCentavos,
    Value<int>? despesasLivroCaixaCentavos,
    Value<int>? saldoNegativoAnteriorCentavos,
    Value<int>? saldoNegativoUtilizadoCentavos,
    Value<int>? saldoNegativoTransportadoCentavos,
    Value<int>? inssCentavos,
    Value<int>? qtdeDependentes,
    Value<int>? deducaoDependentesCentavos,
    Value<int>? descontoSimplificadoCentavos,
    Value<int>? impostoCenarioRealCentavos,
    Value<int>? impostoCenarioSimplificadoCentavos,
    Value<String>? cenarioAplicado,
    Value<int>? baseCalculoCentavos,
    Value<int>? aliquotaBp,
    Value<int>? parcelaDeduzirCentavos,
    Value<int>? impostoApuradoCentavos,
    Value<int>? redutorLeiCentavos,
    Value<int>? impostoDevidoCentavos,
    Value<int>? impostoDiferidoAnteriorCentavos,
    Value<int>? impostoDiferidoCentavos,
    Value<int>? isento,
    Value<int>? tabelaIrpfId,
    Value<String>? catalogoVersoesSnapshot,
    Value<String>? parametrosSnapshot,
    Value<String>? motorVersao,
    Value<String>? appVersao,
    Value<int>? calculadaEm,
    Value<int?>? fechadaEm,
    Value<int>? rowid,
  }) {
    return ApuracoesMensaisCompanion(
      id: id ?? this.id,
      competencia: competencia ?? this.competencia,
      versao: versao ?? this.versao,
      status: status ?? this.status,
      receitaBrutaCentavos: receitaBrutaCentavos ?? this.receitaBrutaCentavos,
      despesasLivroCaixaCentavos:
          despesasLivroCaixaCentavos ?? this.despesasLivroCaixaCentavos,
      saldoNegativoAnteriorCentavos:
          saldoNegativoAnteriorCentavos ?? this.saldoNegativoAnteriorCentavos,
      saldoNegativoUtilizadoCentavos:
          saldoNegativoUtilizadoCentavos ?? this.saldoNegativoUtilizadoCentavos,
      saldoNegativoTransportadoCentavos:
          saldoNegativoTransportadoCentavos ??
          this.saldoNegativoTransportadoCentavos,
      inssCentavos: inssCentavos ?? this.inssCentavos,
      qtdeDependentes: qtdeDependentes ?? this.qtdeDependentes,
      deducaoDependentesCentavos:
          deducaoDependentesCentavos ?? this.deducaoDependentesCentavos,
      descontoSimplificadoCentavos:
          descontoSimplificadoCentavos ?? this.descontoSimplificadoCentavos,
      impostoCenarioRealCentavos:
          impostoCenarioRealCentavos ?? this.impostoCenarioRealCentavos,
      impostoCenarioSimplificadoCentavos:
          impostoCenarioSimplificadoCentavos ??
          this.impostoCenarioSimplificadoCentavos,
      cenarioAplicado: cenarioAplicado ?? this.cenarioAplicado,
      baseCalculoCentavos: baseCalculoCentavos ?? this.baseCalculoCentavos,
      aliquotaBp: aliquotaBp ?? this.aliquotaBp,
      parcelaDeduzirCentavos:
          parcelaDeduzirCentavos ?? this.parcelaDeduzirCentavos,
      impostoApuradoCentavos:
          impostoApuradoCentavos ?? this.impostoApuradoCentavos,
      redutorLeiCentavos: redutorLeiCentavos ?? this.redutorLeiCentavos,
      impostoDevidoCentavos:
          impostoDevidoCentavos ?? this.impostoDevidoCentavos,
      impostoDiferidoAnteriorCentavos:
          impostoDiferidoAnteriorCentavos ??
          this.impostoDiferidoAnteriorCentavos,
      impostoDiferidoCentavos:
          impostoDiferidoCentavos ?? this.impostoDiferidoCentavos,
      isento: isento ?? this.isento,
      tabelaIrpfId: tabelaIrpfId ?? this.tabelaIrpfId,
      catalogoVersoesSnapshot:
          catalogoVersoesSnapshot ?? this.catalogoVersoesSnapshot,
      parametrosSnapshot: parametrosSnapshot ?? this.parametrosSnapshot,
      motorVersao: motorVersao ?? this.motorVersao,
      appVersao: appVersao ?? this.appVersao,
      calculadaEm: calculadaEm ?? this.calculadaEm,
      fechadaEm: fechadaEm ?? this.fechadaEm,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (competencia.present) {
      map['competencia'] = Variable<String>(competencia.value);
    }
    if (versao.present) {
      map['versao'] = Variable<int>(versao.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (receitaBrutaCentavos.present) {
      map['receita_bruta_centavos'] = Variable<int>(receitaBrutaCentavos.value);
    }
    if (despesasLivroCaixaCentavos.present) {
      map['despesas_livro_caixa_centavos'] = Variable<int>(
        despesasLivroCaixaCentavos.value,
      );
    }
    if (saldoNegativoAnteriorCentavos.present) {
      map['saldo_negativo_anterior_centavos'] = Variable<int>(
        saldoNegativoAnteriorCentavos.value,
      );
    }
    if (saldoNegativoUtilizadoCentavos.present) {
      map['saldo_negativo_utilizado_centavos'] = Variable<int>(
        saldoNegativoUtilizadoCentavos.value,
      );
    }
    if (saldoNegativoTransportadoCentavos.present) {
      map['saldo_negativo_transportado_centavos'] = Variable<int>(
        saldoNegativoTransportadoCentavos.value,
      );
    }
    if (inssCentavos.present) {
      map['inss_centavos'] = Variable<int>(inssCentavos.value);
    }
    if (qtdeDependentes.present) {
      map['qtde_dependentes'] = Variable<int>(qtdeDependentes.value);
    }
    if (deducaoDependentesCentavos.present) {
      map['deducao_dependentes_centavos'] = Variable<int>(
        deducaoDependentesCentavos.value,
      );
    }
    if (descontoSimplificadoCentavos.present) {
      map['desconto_simplificado_centavos'] = Variable<int>(
        descontoSimplificadoCentavos.value,
      );
    }
    if (impostoCenarioRealCentavos.present) {
      map['imposto_cenario_real_centavos'] = Variable<int>(
        impostoCenarioRealCentavos.value,
      );
    }
    if (impostoCenarioSimplificadoCentavos.present) {
      map['imposto_cenario_simplificado_centavos'] = Variable<int>(
        impostoCenarioSimplificadoCentavos.value,
      );
    }
    if (cenarioAplicado.present) {
      map['cenario_aplicado'] = Variable<String>(cenarioAplicado.value);
    }
    if (baseCalculoCentavos.present) {
      map['base_calculo_centavos'] = Variable<int>(baseCalculoCentavos.value);
    }
    if (aliquotaBp.present) {
      map['aliquota_bp'] = Variable<int>(aliquotaBp.value);
    }
    if (parcelaDeduzirCentavos.present) {
      map['parcela_deduzir_centavos'] = Variable<int>(
        parcelaDeduzirCentavos.value,
      );
    }
    if (impostoApuradoCentavos.present) {
      map['imposto_apurado_centavos'] = Variable<int>(
        impostoApuradoCentavos.value,
      );
    }
    if (redutorLeiCentavos.present) {
      map['redutor_lei_centavos'] = Variable<int>(redutorLeiCentavos.value);
    }
    if (impostoDevidoCentavos.present) {
      map['imposto_devido_centavos'] = Variable<int>(
        impostoDevidoCentavos.value,
      );
    }
    if (impostoDiferidoAnteriorCentavos.present) {
      map['imposto_diferido_anterior_centavos'] = Variable<int>(
        impostoDiferidoAnteriorCentavos.value,
      );
    }
    if (impostoDiferidoCentavos.present) {
      map['imposto_diferido_centavos'] = Variable<int>(
        impostoDiferidoCentavos.value,
      );
    }
    if (isento.present) {
      map['isento'] = Variable<int>(isento.value);
    }
    if (tabelaIrpfId.present) {
      map['tabela_irpf_id'] = Variable<int>(tabelaIrpfId.value);
    }
    if (catalogoVersoesSnapshot.present) {
      map['catalogo_versoes_snapshot'] = Variable<String>(
        catalogoVersoesSnapshot.value,
      );
    }
    if (parametrosSnapshot.present) {
      map['parametros_snapshot'] = Variable<String>(parametrosSnapshot.value);
    }
    if (motorVersao.present) {
      map['motor_versao'] = Variable<String>(motorVersao.value);
    }
    if (appVersao.present) {
      map['app_versao'] = Variable<String>(appVersao.value);
    }
    if (calculadaEm.present) {
      map['calculada_em'] = Variable<int>(calculadaEm.value);
    }
    if (fechadaEm.present) {
      map['fechada_em'] = Variable<int>(fechadaEm.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ApuracoesMensaisCompanion(')
          ..write('id: $id, ')
          ..write('competencia: $competencia, ')
          ..write('versao: $versao, ')
          ..write('status: $status, ')
          ..write('receitaBrutaCentavos: $receitaBrutaCentavos, ')
          ..write('despesasLivroCaixaCentavos: $despesasLivroCaixaCentavos, ')
          ..write(
            'saldoNegativoAnteriorCentavos: $saldoNegativoAnteriorCentavos, ',
          )
          ..write(
            'saldoNegativoUtilizadoCentavos: $saldoNegativoUtilizadoCentavos, ',
          )
          ..write(
            'saldoNegativoTransportadoCentavos: $saldoNegativoTransportadoCentavos, ',
          )
          ..write('inssCentavos: $inssCentavos, ')
          ..write('qtdeDependentes: $qtdeDependentes, ')
          ..write('deducaoDependentesCentavos: $deducaoDependentesCentavos, ')
          ..write(
            'descontoSimplificadoCentavos: $descontoSimplificadoCentavos, ',
          )
          ..write('impostoCenarioRealCentavos: $impostoCenarioRealCentavos, ')
          ..write(
            'impostoCenarioSimplificadoCentavos: $impostoCenarioSimplificadoCentavos, ',
          )
          ..write('cenarioAplicado: $cenarioAplicado, ')
          ..write('baseCalculoCentavos: $baseCalculoCentavos, ')
          ..write('aliquotaBp: $aliquotaBp, ')
          ..write('parcelaDeduzirCentavos: $parcelaDeduzirCentavos, ')
          ..write('impostoApuradoCentavos: $impostoApuradoCentavos, ')
          ..write('redutorLeiCentavos: $redutorLeiCentavos, ')
          ..write('impostoDevidoCentavos: $impostoDevidoCentavos, ')
          ..write(
            'impostoDiferidoAnteriorCentavos: $impostoDiferidoAnteriorCentavos, ',
          )
          ..write('impostoDiferidoCentavos: $impostoDiferidoCentavos, ')
          ..write('isento: $isento, ')
          ..write('tabelaIrpfId: $tabelaIrpfId, ')
          ..write('catalogoVersoesSnapshot: $catalogoVersoesSnapshot, ')
          ..write('parametrosSnapshot: $parametrosSnapshot, ')
          ..write('motorVersao: $motorVersao, ')
          ..write('appVersao: $appVersao, ')
          ..write('calculadaEm: $calculadaEm, ')
          ..write('fechadaEm: $fechadaEm, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Lancamentos extends Table with TableInfo<Lancamentos, Lancamento> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Lancamentos(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _transacaoIdMeta = const VerificationMeta(
    'transacaoId',
  );
  late final GeneratedColumn<String> transacaoId = GeneratedColumn<String>(
    'transacao_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'UNIQUE REFERENCES transacoes(id)',
  );
  static const VerificationMeta _competenciaMeta = const VerificationMeta(
    'competencia',
  );
  late final GeneratedColumn<String> competencia = GeneratedColumn<String>(
    'competencia',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _dataRecebimentoMeta = const VerificationMeta(
    'dataRecebimento',
  );
  late final GeneratedColumn<String> dataRecebimento = GeneratedColumn<String>(
    'data_recebimento',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _valorCentavosMeta = const VerificationMeta(
    'valorCentavos',
  );
  late final GeneratedColumn<int> valorCentavos = GeneratedColumn<int>(
    'valor_centavos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (valor_centavos > 0)',
  );
  static const VerificationMeta _classificacaoMeta = const VerificationMeta(
    'classificacao',
  );
  late final GeneratedColumn<String> classificacao = GeneratedColumn<String>(
    'classificacao',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (classificacao IN (\'tributavel\', \'pessoal\', \'reembolso\', \'repasse_terceiros\'))',
  );
  static const VerificationMeta _remetenteIdMeta = const VerificationMeta(
    'remetenteId',
  );
  late final GeneratedColumn<String> remetenteId = GeneratedColumn<String>(
    'remetente_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES remetentes(id)',
  );
  static const VerificationMeta _cpfPagadorMeta = const VerificationMeta(
    'cpfPagador',
  );
  late final GeneratedColumn<String> cpfPagador = GeneratedColumn<String>(
    'cpf_pagador',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _nomePagadorMeta = const VerificationMeta(
    'nomePagador',
  );
  late final GeneratedColumn<String> nomePagador = GeneratedColumn<String>(
    'nome_pagador',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _origemClassificacaoMeta =
      const VerificationMeta('origemClassificacao');
  late final GeneratedColumn<String>
  origemClassificacao = GeneratedColumn<String>(
    'origem_classificacao',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT \'manual\' CHECK (origem_classificacao IN (\'manual\', \'sugestao_aceita\', \'regra_remetente\'))',
    defaultValue: const CustomExpression('\'manual\''),
  );
  static const VerificationMeta _apuracaoIdMeta = const VerificationMeta(
    'apuracaoId',
  );
  late final GeneratedColumn<String> apuracaoId = GeneratedColumn<String>(
    'apuracao_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES apuracoes_mensais(id)',
  );
  static const VerificationMeta _criadoEmMeta = const VerificationMeta(
    'criadoEm',
  );
  late final GeneratedColumn<int> criadoEm = GeneratedColumn<int>(
    'criado_em',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _atualizadoEmMeta = const VerificationMeta(
    'atualizadoEm',
  );
  late final GeneratedColumn<int> atualizadoEm = GeneratedColumn<int>(
    'atualizado_em',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    transacaoId,
    competencia,
    dataRecebimento,
    valorCentavos,
    classificacao,
    remetenteId,
    cpfPagador,
    nomePagador,
    origemClassificacao,
    apuracaoId,
    criadoEm,
    atualizadoEm,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lancamentos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Lancamento> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('transacao_id')) {
      context.handle(
        _transacaoIdMeta,
        transacaoId.isAcceptableOrUnknown(
          data['transacao_id']!,
          _transacaoIdMeta,
        ),
      );
    }
    if (data.containsKey('competencia')) {
      context.handle(
        _competenciaMeta,
        competencia.isAcceptableOrUnknown(
          data['competencia']!,
          _competenciaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_competenciaMeta);
    }
    if (data.containsKey('data_recebimento')) {
      context.handle(
        _dataRecebimentoMeta,
        dataRecebimento.isAcceptableOrUnknown(
          data['data_recebimento']!,
          _dataRecebimentoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dataRecebimentoMeta);
    }
    if (data.containsKey('valor_centavos')) {
      context.handle(
        _valorCentavosMeta,
        valorCentavos.isAcceptableOrUnknown(
          data['valor_centavos']!,
          _valorCentavosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_valorCentavosMeta);
    }
    if (data.containsKey('classificacao')) {
      context.handle(
        _classificacaoMeta,
        classificacao.isAcceptableOrUnknown(
          data['classificacao']!,
          _classificacaoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_classificacaoMeta);
    }
    if (data.containsKey('remetente_id')) {
      context.handle(
        _remetenteIdMeta,
        remetenteId.isAcceptableOrUnknown(
          data['remetente_id']!,
          _remetenteIdMeta,
        ),
      );
    }
    if (data.containsKey('cpf_pagador')) {
      context.handle(
        _cpfPagadorMeta,
        cpfPagador.isAcceptableOrUnknown(data['cpf_pagador']!, _cpfPagadorMeta),
      );
    }
    if (data.containsKey('nome_pagador')) {
      context.handle(
        _nomePagadorMeta,
        nomePagador.isAcceptableOrUnknown(
          data['nome_pagador']!,
          _nomePagadorMeta,
        ),
      );
    }
    if (data.containsKey('origem_classificacao')) {
      context.handle(
        _origemClassificacaoMeta,
        origemClassificacao.isAcceptableOrUnknown(
          data['origem_classificacao']!,
          _origemClassificacaoMeta,
        ),
      );
    }
    if (data.containsKey('apuracao_id')) {
      context.handle(
        _apuracaoIdMeta,
        apuracaoId.isAcceptableOrUnknown(data['apuracao_id']!, _apuracaoIdMeta),
      );
    }
    if (data.containsKey('criado_em')) {
      context.handle(
        _criadoEmMeta,
        criadoEm.isAcceptableOrUnknown(data['criado_em']!, _criadoEmMeta),
      );
    } else if (isInserting) {
      context.missing(_criadoEmMeta);
    }
    if (data.containsKey('atualizado_em')) {
      context.handle(
        _atualizadoEmMeta,
        atualizadoEm.isAcceptableOrUnknown(
          data['atualizado_em']!,
          _atualizadoEmMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_atualizadoEmMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Lancamento map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Lancamento(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      transacaoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transacao_id'],
      ),
      competencia: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}competencia'],
      )!,
      dataRecebimento: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_recebimento'],
      )!,
      valorCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}valor_centavos'],
      )!,
      classificacao: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}classificacao'],
      )!,
      remetenteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remetente_id'],
      ),
      cpfPagador: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cpf_pagador'],
      ),
      nomePagador: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome_pagador'],
      ),
      origemClassificacao: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origem_classificacao'],
      )!,
      apuracaoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}apuracao_id'],
      ),
      criadoEm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}criado_em'],
      )!,
      atualizadoEm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}atualizado_em'],
      )!,
    );
  }

  @override
  Lancamentos createAlias(String alias) {
    return Lancamentos(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Lancamento extends DataClass implements Insertable<Lancamento> {
  final String id;
  final String? transacaoId;

  /// NULL = manual
  final String competencia;

  /// 'YYYY-MM'
  final String dataRecebimento;
  final int valorCentavos;
  final String classificacao;
  final String? remetenteId;
  final String? cpfPagador;

  /// snapshot: e-CAC exige CPF POR LANÇAMENTO
  final String? nomePagador;

  /// e o cadastro do remetente pode mudar depois
  final String origemClassificacao;
  final String? apuracaoId;
  final int criadoEm;
  final int atualizadoEm;
  const Lancamento({
    required this.id,
    this.transacaoId,
    required this.competencia,
    required this.dataRecebimento,
    required this.valorCentavos,
    required this.classificacao,
    this.remetenteId,
    this.cpfPagador,
    this.nomePagador,
    required this.origemClassificacao,
    this.apuracaoId,
    required this.criadoEm,
    required this.atualizadoEm,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || transacaoId != null) {
      map['transacao_id'] = Variable<String>(transacaoId);
    }
    map['competencia'] = Variable<String>(competencia);
    map['data_recebimento'] = Variable<String>(dataRecebimento);
    map['valor_centavos'] = Variable<int>(valorCentavos);
    map['classificacao'] = Variable<String>(classificacao);
    if (!nullToAbsent || remetenteId != null) {
      map['remetente_id'] = Variable<String>(remetenteId);
    }
    if (!nullToAbsent || cpfPagador != null) {
      map['cpf_pagador'] = Variable<String>(cpfPagador);
    }
    if (!nullToAbsent || nomePagador != null) {
      map['nome_pagador'] = Variable<String>(nomePagador);
    }
    map['origem_classificacao'] = Variable<String>(origemClassificacao);
    if (!nullToAbsent || apuracaoId != null) {
      map['apuracao_id'] = Variable<String>(apuracaoId);
    }
    map['criado_em'] = Variable<int>(criadoEm);
    map['atualizado_em'] = Variable<int>(atualizadoEm);
    return map;
  }

  LancamentosCompanion toCompanion(bool nullToAbsent) {
    return LancamentosCompanion(
      id: Value(id),
      transacaoId: transacaoId == null && nullToAbsent
          ? const Value.absent()
          : Value(transacaoId),
      competencia: Value(competencia),
      dataRecebimento: Value(dataRecebimento),
      valorCentavos: Value(valorCentavos),
      classificacao: Value(classificacao),
      remetenteId: remetenteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remetenteId),
      cpfPagador: cpfPagador == null && nullToAbsent
          ? const Value.absent()
          : Value(cpfPagador),
      nomePagador: nomePagador == null && nullToAbsent
          ? const Value.absent()
          : Value(nomePagador),
      origemClassificacao: Value(origemClassificacao),
      apuracaoId: apuracaoId == null && nullToAbsent
          ? const Value.absent()
          : Value(apuracaoId),
      criadoEm: Value(criadoEm),
      atualizadoEm: Value(atualizadoEm),
    );
  }

  factory Lancamento.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Lancamento(
      id: serializer.fromJson<String>(json['id']),
      transacaoId: serializer.fromJson<String?>(json['transacao_id']),
      competencia: serializer.fromJson<String>(json['competencia']),
      dataRecebimento: serializer.fromJson<String>(json['data_recebimento']),
      valorCentavos: serializer.fromJson<int>(json['valor_centavos']),
      classificacao: serializer.fromJson<String>(json['classificacao']),
      remetenteId: serializer.fromJson<String?>(json['remetente_id']),
      cpfPagador: serializer.fromJson<String?>(json['cpf_pagador']),
      nomePagador: serializer.fromJson<String?>(json['nome_pagador']),
      origemClassificacao: serializer.fromJson<String>(
        json['origem_classificacao'],
      ),
      apuracaoId: serializer.fromJson<String?>(json['apuracao_id']),
      criadoEm: serializer.fromJson<int>(json['criado_em']),
      atualizadoEm: serializer.fromJson<int>(json['atualizado_em']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'transacao_id': serializer.toJson<String?>(transacaoId),
      'competencia': serializer.toJson<String>(competencia),
      'data_recebimento': serializer.toJson<String>(dataRecebimento),
      'valor_centavos': serializer.toJson<int>(valorCentavos),
      'classificacao': serializer.toJson<String>(classificacao),
      'remetente_id': serializer.toJson<String?>(remetenteId),
      'cpf_pagador': serializer.toJson<String?>(cpfPagador),
      'nome_pagador': serializer.toJson<String?>(nomePagador),
      'origem_classificacao': serializer.toJson<String>(origemClassificacao),
      'apuracao_id': serializer.toJson<String?>(apuracaoId),
      'criado_em': serializer.toJson<int>(criadoEm),
      'atualizado_em': serializer.toJson<int>(atualizadoEm),
    };
  }

  Lancamento copyWith({
    String? id,
    Value<String?> transacaoId = const Value.absent(),
    String? competencia,
    String? dataRecebimento,
    int? valorCentavos,
    String? classificacao,
    Value<String?> remetenteId = const Value.absent(),
    Value<String?> cpfPagador = const Value.absent(),
    Value<String?> nomePagador = const Value.absent(),
    String? origemClassificacao,
    Value<String?> apuracaoId = const Value.absent(),
    int? criadoEm,
    int? atualizadoEm,
  }) => Lancamento(
    id: id ?? this.id,
    transacaoId: transacaoId.present ? transacaoId.value : this.transacaoId,
    competencia: competencia ?? this.competencia,
    dataRecebimento: dataRecebimento ?? this.dataRecebimento,
    valorCentavos: valorCentavos ?? this.valorCentavos,
    classificacao: classificacao ?? this.classificacao,
    remetenteId: remetenteId.present ? remetenteId.value : this.remetenteId,
    cpfPagador: cpfPagador.present ? cpfPagador.value : this.cpfPagador,
    nomePagador: nomePagador.present ? nomePagador.value : this.nomePagador,
    origemClassificacao: origemClassificacao ?? this.origemClassificacao,
    apuracaoId: apuracaoId.present ? apuracaoId.value : this.apuracaoId,
    criadoEm: criadoEm ?? this.criadoEm,
    atualizadoEm: atualizadoEm ?? this.atualizadoEm,
  );
  Lancamento copyWithCompanion(LancamentosCompanion data) {
    return Lancamento(
      id: data.id.present ? data.id.value : this.id,
      transacaoId: data.transacaoId.present
          ? data.transacaoId.value
          : this.transacaoId,
      competencia: data.competencia.present
          ? data.competencia.value
          : this.competencia,
      dataRecebimento: data.dataRecebimento.present
          ? data.dataRecebimento.value
          : this.dataRecebimento,
      valorCentavos: data.valorCentavos.present
          ? data.valorCentavos.value
          : this.valorCentavos,
      classificacao: data.classificacao.present
          ? data.classificacao.value
          : this.classificacao,
      remetenteId: data.remetenteId.present
          ? data.remetenteId.value
          : this.remetenteId,
      cpfPagador: data.cpfPagador.present
          ? data.cpfPagador.value
          : this.cpfPagador,
      nomePagador: data.nomePagador.present
          ? data.nomePagador.value
          : this.nomePagador,
      origemClassificacao: data.origemClassificacao.present
          ? data.origemClassificacao.value
          : this.origemClassificacao,
      apuracaoId: data.apuracaoId.present
          ? data.apuracaoId.value
          : this.apuracaoId,
      criadoEm: data.criadoEm.present ? data.criadoEm.value : this.criadoEm,
      atualizadoEm: data.atualizadoEm.present
          ? data.atualizadoEm.value
          : this.atualizadoEm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Lancamento(')
          ..write('id: $id, ')
          ..write('transacaoId: $transacaoId, ')
          ..write('competencia: $competencia, ')
          ..write('dataRecebimento: $dataRecebimento, ')
          ..write('valorCentavos: $valorCentavos, ')
          ..write('classificacao: $classificacao, ')
          ..write('remetenteId: $remetenteId, ')
          ..write('cpfPagador: $cpfPagador, ')
          ..write('nomePagador: $nomePagador, ')
          ..write('origemClassificacao: $origemClassificacao, ')
          ..write('apuracaoId: $apuracaoId, ')
          ..write('criadoEm: $criadoEm, ')
          ..write('atualizadoEm: $atualizadoEm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    transacaoId,
    competencia,
    dataRecebimento,
    valorCentavos,
    classificacao,
    remetenteId,
    cpfPagador,
    nomePagador,
    origemClassificacao,
    apuracaoId,
    criadoEm,
    atualizadoEm,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Lancamento &&
          other.id == this.id &&
          other.transacaoId == this.transacaoId &&
          other.competencia == this.competencia &&
          other.dataRecebimento == this.dataRecebimento &&
          other.valorCentavos == this.valorCentavos &&
          other.classificacao == this.classificacao &&
          other.remetenteId == this.remetenteId &&
          other.cpfPagador == this.cpfPagador &&
          other.nomePagador == this.nomePagador &&
          other.origemClassificacao == this.origemClassificacao &&
          other.apuracaoId == this.apuracaoId &&
          other.criadoEm == this.criadoEm &&
          other.atualizadoEm == this.atualizadoEm);
}

class LancamentosCompanion extends UpdateCompanion<Lancamento> {
  final Value<String> id;
  final Value<String?> transacaoId;
  final Value<String> competencia;
  final Value<String> dataRecebimento;
  final Value<int> valorCentavos;
  final Value<String> classificacao;
  final Value<String?> remetenteId;
  final Value<String?> cpfPagador;
  final Value<String?> nomePagador;
  final Value<String> origemClassificacao;
  final Value<String?> apuracaoId;
  final Value<int> criadoEm;
  final Value<int> atualizadoEm;
  final Value<int> rowid;
  const LancamentosCompanion({
    this.id = const Value.absent(),
    this.transacaoId = const Value.absent(),
    this.competencia = const Value.absent(),
    this.dataRecebimento = const Value.absent(),
    this.valorCentavos = const Value.absent(),
    this.classificacao = const Value.absent(),
    this.remetenteId = const Value.absent(),
    this.cpfPagador = const Value.absent(),
    this.nomePagador = const Value.absent(),
    this.origemClassificacao = const Value.absent(),
    this.apuracaoId = const Value.absent(),
    this.criadoEm = const Value.absent(),
    this.atualizadoEm = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LancamentosCompanion.insert({
    required String id,
    this.transacaoId = const Value.absent(),
    required String competencia,
    required String dataRecebimento,
    required int valorCentavos,
    required String classificacao,
    this.remetenteId = const Value.absent(),
    this.cpfPagador = const Value.absent(),
    this.nomePagador = const Value.absent(),
    this.origemClassificacao = const Value.absent(),
    this.apuracaoId = const Value.absent(),
    required int criadoEm,
    required int atualizadoEm,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       competencia = Value(competencia),
       dataRecebimento = Value(dataRecebimento),
       valorCentavos = Value(valorCentavos),
       classificacao = Value(classificacao),
       criadoEm = Value(criadoEm),
       atualizadoEm = Value(atualizadoEm);
  static Insertable<Lancamento> custom({
    Expression<String>? id,
    Expression<String>? transacaoId,
    Expression<String>? competencia,
    Expression<String>? dataRecebimento,
    Expression<int>? valorCentavos,
    Expression<String>? classificacao,
    Expression<String>? remetenteId,
    Expression<String>? cpfPagador,
    Expression<String>? nomePagador,
    Expression<String>? origemClassificacao,
    Expression<String>? apuracaoId,
    Expression<int>? criadoEm,
    Expression<int>? atualizadoEm,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transacaoId != null) 'transacao_id': transacaoId,
      if (competencia != null) 'competencia': competencia,
      if (dataRecebimento != null) 'data_recebimento': dataRecebimento,
      if (valorCentavos != null) 'valor_centavos': valorCentavos,
      if (classificacao != null) 'classificacao': classificacao,
      if (remetenteId != null) 'remetente_id': remetenteId,
      if (cpfPagador != null) 'cpf_pagador': cpfPagador,
      if (nomePagador != null) 'nome_pagador': nomePagador,
      if (origemClassificacao != null)
        'origem_classificacao': origemClassificacao,
      if (apuracaoId != null) 'apuracao_id': apuracaoId,
      if (criadoEm != null) 'criado_em': criadoEm,
      if (atualizadoEm != null) 'atualizado_em': atualizadoEm,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LancamentosCompanion copyWith({
    Value<String>? id,
    Value<String?>? transacaoId,
    Value<String>? competencia,
    Value<String>? dataRecebimento,
    Value<int>? valorCentavos,
    Value<String>? classificacao,
    Value<String?>? remetenteId,
    Value<String?>? cpfPagador,
    Value<String?>? nomePagador,
    Value<String>? origemClassificacao,
    Value<String?>? apuracaoId,
    Value<int>? criadoEm,
    Value<int>? atualizadoEm,
    Value<int>? rowid,
  }) {
    return LancamentosCompanion(
      id: id ?? this.id,
      transacaoId: transacaoId ?? this.transacaoId,
      competencia: competencia ?? this.competencia,
      dataRecebimento: dataRecebimento ?? this.dataRecebimento,
      valorCentavos: valorCentavos ?? this.valorCentavos,
      classificacao: classificacao ?? this.classificacao,
      remetenteId: remetenteId ?? this.remetenteId,
      cpfPagador: cpfPagador ?? this.cpfPagador,
      nomePagador: nomePagador ?? this.nomePagador,
      origemClassificacao: origemClassificacao ?? this.origemClassificacao,
      apuracaoId: apuracaoId ?? this.apuracaoId,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (transacaoId.present) {
      map['transacao_id'] = Variable<String>(transacaoId.value);
    }
    if (competencia.present) {
      map['competencia'] = Variable<String>(competencia.value);
    }
    if (dataRecebimento.present) {
      map['data_recebimento'] = Variable<String>(dataRecebimento.value);
    }
    if (valorCentavos.present) {
      map['valor_centavos'] = Variable<int>(valorCentavos.value);
    }
    if (classificacao.present) {
      map['classificacao'] = Variable<String>(classificacao.value);
    }
    if (remetenteId.present) {
      map['remetente_id'] = Variable<String>(remetenteId.value);
    }
    if (cpfPagador.present) {
      map['cpf_pagador'] = Variable<String>(cpfPagador.value);
    }
    if (nomePagador.present) {
      map['nome_pagador'] = Variable<String>(nomePagador.value);
    }
    if (origemClassificacao.present) {
      map['origem_classificacao'] = Variable<String>(origemClassificacao.value);
    }
    if (apuracaoId.present) {
      map['apuracao_id'] = Variable<String>(apuracaoId.value);
    }
    if (criadoEm.present) {
      map['criado_em'] = Variable<int>(criadoEm.value);
    }
    if (atualizadoEm.present) {
      map['atualizado_em'] = Variable<int>(atualizadoEm.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LancamentosCompanion(')
          ..write('id: $id, ')
          ..write('transacaoId: $transacaoId, ')
          ..write('competencia: $competencia, ')
          ..write('dataRecebimento: $dataRecebimento, ')
          ..write('valorCentavos: $valorCentavos, ')
          ..write('classificacao: $classificacao, ')
          ..write('remetenteId: $remetenteId, ')
          ..write('cpfPagador: $cpfPagador, ')
          ..write('nomePagador: $nomePagador, ')
          ..write('origemClassificacao: $origemClassificacao, ')
          ..write('apuracaoId: $apuracaoId, ')
          ..write('criadoEm: $criadoEm, ')
          ..write('atualizadoEm: $atualizadoEm, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class HistoricoClassificacaoTable extends Table
    with TableInfo<HistoricoClassificacaoTable, HistoricoClassificacao> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  HistoricoClassificacaoTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT',
  );
  static const VerificationMeta _lancamentoIdMeta = const VerificationMeta(
    'lancamentoId',
  );
  late final GeneratedColumn<String> lancamentoId = GeneratedColumn<String>(
    'lancamento_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES lancamentos(id)',
  );
  static const VerificationMeta _deMeta = const VerificationMeta('de');
  late final GeneratedColumn<String> de = GeneratedColumn<String>(
    'de',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _paraMeta = const VerificationMeta('para');
  late final GeneratedColumn<String> para = GeneratedColumn<String>(
    'para',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _motivoMeta = const VerificationMeta('motivo');
  late final GeneratedColumn<String> motivo = GeneratedColumn<String>(
    'motivo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _criadoEmMeta = const VerificationMeta(
    'criadoEm',
  );
  late final GeneratedColumn<int> criadoEm = GeneratedColumn<int>(
    'criado_em',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    lancamentoId,
    de,
    para,
    motivo,
    criadoEm,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'historico_classificacao';
  @override
  VerificationContext validateIntegrity(
    Insertable<HistoricoClassificacao> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('lancamento_id')) {
      context.handle(
        _lancamentoIdMeta,
        lancamentoId.isAcceptableOrUnknown(
          data['lancamento_id']!,
          _lancamentoIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lancamentoIdMeta);
    }
    if (data.containsKey('de')) {
      context.handle(_deMeta, de.isAcceptableOrUnknown(data['de']!, _deMeta));
    }
    if (data.containsKey('para')) {
      context.handle(
        _paraMeta,
        para.isAcceptableOrUnknown(data['para']!, _paraMeta),
      );
    } else if (isInserting) {
      context.missing(_paraMeta);
    }
    if (data.containsKey('motivo')) {
      context.handle(
        _motivoMeta,
        motivo.isAcceptableOrUnknown(data['motivo']!, _motivoMeta),
      );
    }
    if (data.containsKey('criado_em')) {
      context.handle(
        _criadoEmMeta,
        criadoEm.isAcceptableOrUnknown(data['criado_em']!, _criadoEmMeta),
      );
    } else if (isInserting) {
      context.missing(_criadoEmMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HistoricoClassificacao map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HistoricoClassificacao(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      lancamentoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lancamento_id'],
      )!,
      de: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}de'],
      ),
      para: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}para'],
      )!,
      motivo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}motivo'],
      ),
      criadoEm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}criado_em'],
      )!,
    );
  }

  @override
  HistoricoClassificacaoTable createAlias(String alias) {
    return HistoricoClassificacaoTable(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class HistoricoClassificacao extends DataClass
    implements Insertable<HistoricoClassificacao> {
  final int id;
  final String lancamentoId;
  final String? de;
  final String para;
  final String? motivo;
  final int criadoEm;
  const HistoricoClassificacao({
    required this.id,
    required this.lancamentoId,
    this.de,
    required this.para,
    this.motivo,
    required this.criadoEm,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['lancamento_id'] = Variable<String>(lancamentoId);
    if (!nullToAbsent || de != null) {
      map['de'] = Variable<String>(de);
    }
    map['para'] = Variable<String>(para);
    if (!nullToAbsent || motivo != null) {
      map['motivo'] = Variable<String>(motivo);
    }
    map['criado_em'] = Variable<int>(criadoEm);
    return map;
  }

  HistoricoClassificacaoCompanion toCompanion(bool nullToAbsent) {
    return HistoricoClassificacaoCompanion(
      id: Value(id),
      lancamentoId: Value(lancamentoId),
      de: de == null && nullToAbsent ? const Value.absent() : Value(de),
      para: Value(para),
      motivo: motivo == null && nullToAbsent
          ? const Value.absent()
          : Value(motivo),
      criadoEm: Value(criadoEm),
    );
  }

  factory HistoricoClassificacao.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HistoricoClassificacao(
      id: serializer.fromJson<int>(json['id']),
      lancamentoId: serializer.fromJson<String>(json['lancamento_id']),
      de: serializer.fromJson<String?>(json['de']),
      para: serializer.fromJson<String>(json['para']),
      motivo: serializer.fromJson<String?>(json['motivo']),
      criadoEm: serializer.fromJson<int>(json['criado_em']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lancamento_id': serializer.toJson<String>(lancamentoId),
      'de': serializer.toJson<String?>(de),
      'para': serializer.toJson<String>(para),
      'motivo': serializer.toJson<String?>(motivo),
      'criado_em': serializer.toJson<int>(criadoEm),
    };
  }

  HistoricoClassificacao copyWith({
    int? id,
    String? lancamentoId,
    Value<String?> de = const Value.absent(),
    String? para,
    Value<String?> motivo = const Value.absent(),
    int? criadoEm,
  }) => HistoricoClassificacao(
    id: id ?? this.id,
    lancamentoId: lancamentoId ?? this.lancamentoId,
    de: de.present ? de.value : this.de,
    para: para ?? this.para,
    motivo: motivo.present ? motivo.value : this.motivo,
    criadoEm: criadoEm ?? this.criadoEm,
  );
  HistoricoClassificacao copyWithCompanion(
    HistoricoClassificacaoCompanion data,
  ) {
    return HistoricoClassificacao(
      id: data.id.present ? data.id.value : this.id,
      lancamentoId: data.lancamentoId.present
          ? data.lancamentoId.value
          : this.lancamentoId,
      de: data.de.present ? data.de.value : this.de,
      para: data.para.present ? data.para.value : this.para,
      motivo: data.motivo.present ? data.motivo.value : this.motivo,
      criadoEm: data.criadoEm.present ? data.criadoEm.value : this.criadoEm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HistoricoClassificacao(')
          ..write('id: $id, ')
          ..write('lancamentoId: $lancamentoId, ')
          ..write('de: $de, ')
          ..write('para: $para, ')
          ..write('motivo: $motivo, ')
          ..write('criadoEm: $criadoEm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, lancamentoId, de, para, motivo, criadoEm);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HistoricoClassificacao &&
          other.id == this.id &&
          other.lancamentoId == this.lancamentoId &&
          other.de == this.de &&
          other.para == this.para &&
          other.motivo == this.motivo &&
          other.criadoEm == this.criadoEm);
}

class HistoricoClassificacaoCompanion
    extends UpdateCompanion<HistoricoClassificacao> {
  final Value<int> id;
  final Value<String> lancamentoId;
  final Value<String?> de;
  final Value<String> para;
  final Value<String?> motivo;
  final Value<int> criadoEm;
  const HistoricoClassificacaoCompanion({
    this.id = const Value.absent(),
    this.lancamentoId = const Value.absent(),
    this.de = const Value.absent(),
    this.para = const Value.absent(),
    this.motivo = const Value.absent(),
    this.criadoEm = const Value.absent(),
  });
  HistoricoClassificacaoCompanion.insert({
    this.id = const Value.absent(),
    required String lancamentoId,
    this.de = const Value.absent(),
    required String para,
    this.motivo = const Value.absent(),
    required int criadoEm,
  }) : lancamentoId = Value(lancamentoId),
       para = Value(para),
       criadoEm = Value(criadoEm);
  static Insertable<HistoricoClassificacao> custom({
    Expression<int>? id,
    Expression<String>? lancamentoId,
    Expression<String>? de,
    Expression<String>? para,
    Expression<String>? motivo,
    Expression<int>? criadoEm,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lancamentoId != null) 'lancamento_id': lancamentoId,
      if (de != null) 'de': de,
      if (para != null) 'para': para,
      if (motivo != null) 'motivo': motivo,
      if (criadoEm != null) 'criado_em': criadoEm,
    });
  }

  HistoricoClassificacaoCompanion copyWith({
    Value<int>? id,
    Value<String>? lancamentoId,
    Value<String?>? de,
    Value<String>? para,
    Value<String?>? motivo,
    Value<int>? criadoEm,
  }) {
    return HistoricoClassificacaoCompanion(
      id: id ?? this.id,
      lancamentoId: lancamentoId ?? this.lancamentoId,
      de: de ?? this.de,
      para: para ?? this.para,
      motivo: motivo ?? this.motivo,
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lancamentoId.present) {
      map['lancamento_id'] = Variable<String>(lancamentoId.value);
    }
    if (de.present) {
      map['de'] = Variable<String>(de.value);
    }
    if (para.present) {
      map['para'] = Variable<String>(para.value);
    }
    if (motivo.present) {
      map['motivo'] = Variable<String>(motivo.value);
    }
    if (criadoEm.present) {
      map['criado_em'] = Variable<int>(criadoEm.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HistoricoClassificacaoCompanion(')
          ..write('id: $id, ')
          ..write('lancamentoId: $lancamentoId, ')
          ..write('de: $de, ')
          ..write('para: $para, ')
          ..write('motivo: $motivo, ')
          ..write('criadoEm: $criadoEm')
          ..write(')'))
        .toString();
  }
}

class DespesasLivroCaixa extends Table
    with TableInfo<DespesasLivroCaixa, DespesaLivroCaixa> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  DespesasLivroCaixa(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _rubricaCodigoMeta = const VerificationMeta(
    'rubricaCodigo',
  );
  late final GeneratedColumn<String> rubricaCodigo = GeneratedColumn<String>(
    'rubrica_codigo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES cat_rubricas(codigo)',
  );
  static const VerificationMeta _competenciaMeta = const VerificationMeta(
    'competencia',
  );
  late final GeneratedColumn<String> competencia = GeneratedColumn<String>(
    'competencia',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _dataPagamentoMeta = const VerificationMeta(
    'dataPagamento',
  );
  late final GeneratedColumn<String> dataPagamento = GeneratedColumn<String>(
    'data_pagamento',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _valorCentavosMeta = const VerificationMeta(
    'valorCentavos',
  );
  late final GeneratedColumn<int> valorCentavos = GeneratedColumn<int>(
    'valor_centavos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (valor_centavos > 0)',
  );
  static const VerificationMeta _valorDedutivelCentavosMeta =
      const VerificationMeta('valorDedutivelCentavos');
  late final GeneratedColumn<int> valorDedutivelCentavos = GeneratedColumn<int>(
    'valor_dedutivel_centavos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _descricaoMeta = const VerificationMeta(
    'descricao',
  );
  late final GeneratedColumn<String> descricao = GeneratedColumn<String>(
    'descricao',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _homeOfficeMeta = const VerificationMeta(
    'homeOffice',
  );
  late final GeneratedColumn<int> homeOffice = GeneratedColumn<int>(
    'home_office',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _anexoPathMeta = const VerificationMeta(
    'anexoPath',
  );
  late final GeneratedColumn<String> anexoPath = GeneratedColumn<String>(
    'anexo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _apuracaoIdMeta = const VerificationMeta(
    'apuracaoId',
  );
  late final GeneratedColumn<String> apuracaoId = GeneratedColumn<String>(
    'apuracao_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES apuracoes_mensais(id)',
  );
  static const VerificationMeta _criadoEmMeta = const VerificationMeta(
    'criadoEm',
  );
  late final GeneratedColumn<int> criadoEm = GeneratedColumn<int>(
    'criado_em',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    rubricaCodigo,
    competencia,
    dataPagamento,
    valorCentavos,
    valorDedutivelCentavos,
    descricao,
    homeOffice,
    anexoPath,
    apuracaoId,
    criadoEm,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'despesas_livro_caixa';
  @override
  VerificationContext validateIntegrity(
    Insertable<DespesaLivroCaixa> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('rubrica_codigo')) {
      context.handle(
        _rubricaCodigoMeta,
        rubricaCodigo.isAcceptableOrUnknown(
          data['rubrica_codigo']!,
          _rubricaCodigoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rubricaCodigoMeta);
    }
    if (data.containsKey('competencia')) {
      context.handle(
        _competenciaMeta,
        competencia.isAcceptableOrUnknown(
          data['competencia']!,
          _competenciaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_competenciaMeta);
    }
    if (data.containsKey('data_pagamento')) {
      context.handle(
        _dataPagamentoMeta,
        dataPagamento.isAcceptableOrUnknown(
          data['data_pagamento']!,
          _dataPagamentoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dataPagamentoMeta);
    }
    if (data.containsKey('valor_centavos')) {
      context.handle(
        _valorCentavosMeta,
        valorCentavos.isAcceptableOrUnknown(
          data['valor_centavos']!,
          _valorCentavosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_valorCentavosMeta);
    }
    if (data.containsKey('valor_dedutivel_centavos')) {
      context.handle(
        _valorDedutivelCentavosMeta,
        valorDedutivelCentavos.isAcceptableOrUnknown(
          data['valor_dedutivel_centavos']!,
          _valorDedutivelCentavosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_valorDedutivelCentavosMeta);
    }
    if (data.containsKey('descricao')) {
      context.handle(
        _descricaoMeta,
        descricao.isAcceptableOrUnknown(data['descricao']!, _descricaoMeta),
      );
    }
    if (data.containsKey('home_office')) {
      context.handle(
        _homeOfficeMeta,
        homeOffice.isAcceptableOrUnknown(data['home_office']!, _homeOfficeMeta),
      );
    }
    if (data.containsKey('anexo_path')) {
      context.handle(
        _anexoPathMeta,
        anexoPath.isAcceptableOrUnknown(data['anexo_path']!, _anexoPathMeta),
      );
    }
    if (data.containsKey('apuracao_id')) {
      context.handle(
        _apuracaoIdMeta,
        apuracaoId.isAcceptableOrUnknown(data['apuracao_id']!, _apuracaoIdMeta),
      );
    }
    if (data.containsKey('criado_em')) {
      context.handle(
        _criadoEmMeta,
        criadoEm.isAcceptableOrUnknown(data['criado_em']!, _criadoEmMeta),
      );
    } else if (isInserting) {
      context.missing(_criadoEmMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DespesaLivroCaixa map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DespesaLivroCaixa(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      rubricaCodigo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rubrica_codigo'],
      )!,
      competencia: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}competencia'],
      )!,
      dataPagamento: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_pagamento'],
      )!,
      valorCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}valor_centavos'],
      )!,
      valorDedutivelCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}valor_dedutivel_centavos'],
      )!,
      descricao: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}descricao'],
      ),
      homeOffice: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}home_office'],
      )!,
      anexoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}anexo_path'],
      ),
      apuracaoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}apuracao_id'],
      ),
      criadoEm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}criado_em'],
      )!,
    );
  }

  @override
  DespesasLivroCaixa createAlias(String alias) {
    return DespesasLivroCaixa(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class DespesaLivroCaixa extends DataClass
    implements Insertable<DespesaLivroCaixa> {
  final String id;
  final String rubricaCodigo;
  final String competencia;
  final String dataPagamento;

  /// regime de caixa
  final int valorCentavos;
  final int valorDedutivelCentavos;

  /// após trava de home office
  final String? descricao;
  final int homeOffice;
  final String? anexoPath;

  /// caminho local; Fase 2
  final String? apuracaoId;
  final int criadoEm;
  const DespesaLivroCaixa({
    required this.id,
    required this.rubricaCodigo,
    required this.competencia,
    required this.dataPagamento,
    required this.valorCentavos,
    required this.valorDedutivelCentavos,
    this.descricao,
    required this.homeOffice,
    this.anexoPath,
    this.apuracaoId,
    required this.criadoEm,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['rubrica_codigo'] = Variable<String>(rubricaCodigo);
    map['competencia'] = Variable<String>(competencia);
    map['data_pagamento'] = Variable<String>(dataPagamento);
    map['valor_centavos'] = Variable<int>(valorCentavos);
    map['valor_dedutivel_centavos'] = Variable<int>(valorDedutivelCentavos);
    if (!nullToAbsent || descricao != null) {
      map['descricao'] = Variable<String>(descricao);
    }
    map['home_office'] = Variable<int>(homeOffice);
    if (!nullToAbsent || anexoPath != null) {
      map['anexo_path'] = Variable<String>(anexoPath);
    }
    if (!nullToAbsent || apuracaoId != null) {
      map['apuracao_id'] = Variable<String>(apuracaoId);
    }
    map['criado_em'] = Variable<int>(criadoEm);
    return map;
  }

  DespesasLivroCaixaCompanion toCompanion(bool nullToAbsent) {
    return DespesasLivroCaixaCompanion(
      id: Value(id),
      rubricaCodigo: Value(rubricaCodigo),
      competencia: Value(competencia),
      dataPagamento: Value(dataPagamento),
      valorCentavos: Value(valorCentavos),
      valorDedutivelCentavos: Value(valorDedutivelCentavos),
      descricao: descricao == null && nullToAbsent
          ? const Value.absent()
          : Value(descricao),
      homeOffice: Value(homeOffice),
      anexoPath: anexoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(anexoPath),
      apuracaoId: apuracaoId == null && nullToAbsent
          ? const Value.absent()
          : Value(apuracaoId),
      criadoEm: Value(criadoEm),
    );
  }

  factory DespesaLivroCaixa.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DespesaLivroCaixa(
      id: serializer.fromJson<String>(json['id']),
      rubricaCodigo: serializer.fromJson<String>(json['rubrica_codigo']),
      competencia: serializer.fromJson<String>(json['competencia']),
      dataPagamento: serializer.fromJson<String>(json['data_pagamento']),
      valorCentavos: serializer.fromJson<int>(json['valor_centavos']),
      valorDedutivelCentavos: serializer.fromJson<int>(
        json['valor_dedutivel_centavos'],
      ),
      descricao: serializer.fromJson<String?>(json['descricao']),
      homeOffice: serializer.fromJson<int>(json['home_office']),
      anexoPath: serializer.fromJson<String?>(json['anexo_path']),
      apuracaoId: serializer.fromJson<String?>(json['apuracao_id']),
      criadoEm: serializer.fromJson<int>(json['criado_em']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'rubrica_codigo': serializer.toJson<String>(rubricaCodigo),
      'competencia': serializer.toJson<String>(competencia),
      'data_pagamento': serializer.toJson<String>(dataPagamento),
      'valor_centavos': serializer.toJson<int>(valorCentavos),
      'valor_dedutivel_centavos': serializer.toJson<int>(
        valorDedutivelCentavos,
      ),
      'descricao': serializer.toJson<String?>(descricao),
      'home_office': serializer.toJson<int>(homeOffice),
      'anexo_path': serializer.toJson<String?>(anexoPath),
      'apuracao_id': serializer.toJson<String?>(apuracaoId),
      'criado_em': serializer.toJson<int>(criadoEm),
    };
  }

  DespesaLivroCaixa copyWith({
    String? id,
    String? rubricaCodigo,
    String? competencia,
    String? dataPagamento,
    int? valorCentavos,
    int? valorDedutivelCentavos,
    Value<String?> descricao = const Value.absent(),
    int? homeOffice,
    Value<String?> anexoPath = const Value.absent(),
    Value<String?> apuracaoId = const Value.absent(),
    int? criadoEm,
  }) => DespesaLivroCaixa(
    id: id ?? this.id,
    rubricaCodigo: rubricaCodigo ?? this.rubricaCodigo,
    competencia: competencia ?? this.competencia,
    dataPagamento: dataPagamento ?? this.dataPagamento,
    valorCentavos: valorCentavos ?? this.valorCentavos,
    valorDedutivelCentavos:
        valorDedutivelCentavos ?? this.valorDedutivelCentavos,
    descricao: descricao.present ? descricao.value : this.descricao,
    homeOffice: homeOffice ?? this.homeOffice,
    anexoPath: anexoPath.present ? anexoPath.value : this.anexoPath,
    apuracaoId: apuracaoId.present ? apuracaoId.value : this.apuracaoId,
    criadoEm: criadoEm ?? this.criadoEm,
  );
  DespesaLivroCaixa copyWithCompanion(DespesasLivroCaixaCompanion data) {
    return DespesaLivroCaixa(
      id: data.id.present ? data.id.value : this.id,
      rubricaCodigo: data.rubricaCodigo.present
          ? data.rubricaCodigo.value
          : this.rubricaCodigo,
      competencia: data.competencia.present
          ? data.competencia.value
          : this.competencia,
      dataPagamento: data.dataPagamento.present
          ? data.dataPagamento.value
          : this.dataPagamento,
      valorCentavos: data.valorCentavos.present
          ? data.valorCentavos.value
          : this.valorCentavos,
      valorDedutivelCentavos: data.valorDedutivelCentavos.present
          ? data.valorDedutivelCentavos.value
          : this.valorDedutivelCentavos,
      descricao: data.descricao.present ? data.descricao.value : this.descricao,
      homeOffice: data.homeOffice.present
          ? data.homeOffice.value
          : this.homeOffice,
      anexoPath: data.anexoPath.present ? data.anexoPath.value : this.anexoPath,
      apuracaoId: data.apuracaoId.present
          ? data.apuracaoId.value
          : this.apuracaoId,
      criadoEm: data.criadoEm.present ? data.criadoEm.value : this.criadoEm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DespesaLivroCaixa(')
          ..write('id: $id, ')
          ..write('rubricaCodigo: $rubricaCodigo, ')
          ..write('competencia: $competencia, ')
          ..write('dataPagamento: $dataPagamento, ')
          ..write('valorCentavos: $valorCentavos, ')
          ..write('valorDedutivelCentavos: $valorDedutivelCentavos, ')
          ..write('descricao: $descricao, ')
          ..write('homeOffice: $homeOffice, ')
          ..write('anexoPath: $anexoPath, ')
          ..write('apuracaoId: $apuracaoId, ')
          ..write('criadoEm: $criadoEm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    rubricaCodigo,
    competencia,
    dataPagamento,
    valorCentavos,
    valorDedutivelCentavos,
    descricao,
    homeOffice,
    anexoPath,
    apuracaoId,
    criadoEm,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DespesaLivroCaixa &&
          other.id == this.id &&
          other.rubricaCodigo == this.rubricaCodigo &&
          other.competencia == this.competencia &&
          other.dataPagamento == this.dataPagamento &&
          other.valorCentavos == this.valorCentavos &&
          other.valorDedutivelCentavos == this.valorDedutivelCentavos &&
          other.descricao == this.descricao &&
          other.homeOffice == this.homeOffice &&
          other.anexoPath == this.anexoPath &&
          other.apuracaoId == this.apuracaoId &&
          other.criadoEm == this.criadoEm);
}

class DespesasLivroCaixaCompanion extends UpdateCompanion<DespesaLivroCaixa> {
  final Value<String> id;
  final Value<String> rubricaCodigo;
  final Value<String> competencia;
  final Value<String> dataPagamento;
  final Value<int> valorCentavos;
  final Value<int> valorDedutivelCentavos;
  final Value<String?> descricao;
  final Value<int> homeOffice;
  final Value<String?> anexoPath;
  final Value<String?> apuracaoId;
  final Value<int> criadoEm;
  final Value<int> rowid;
  const DespesasLivroCaixaCompanion({
    this.id = const Value.absent(),
    this.rubricaCodigo = const Value.absent(),
    this.competencia = const Value.absent(),
    this.dataPagamento = const Value.absent(),
    this.valorCentavos = const Value.absent(),
    this.valorDedutivelCentavos = const Value.absent(),
    this.descricao = const Value.absent(),
    this.homeOffice = const Value.absent(),
    this.anexoPath = const Value.absent(),
    this.apuracaoId = const Value.absent(),
    this.criadoEm = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DespesasLivroCaixaCompanion.insert({
    required String id,
    required String rubricaCodigo,
    required String competencia,
    required String dataPagamento,
    required int valorCentavos,
    required int valorDedutivelCentavos,
    this.descricao = const Value.absent(),
    this.homeOffice = const Value.absent(),
    this.anexoPath = const Value.absent(),
    this.apuracaoId = const Value.absent(),
    required int criadoEm,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       rubricaCodigo = Value(rubricaCodigo),
       competencia = Value(competencia),
       dataPagamento = Value(dataPagamento),
       valorCentavos = Value(valorCentavos),
       valorDedutivelCentavos = Value(valorDedutivelCentavos),
       criadoEm = Value(criadoEm);
  static Insertable<DespesaLivroCaixa> custom({
    Expression<String>? id,
    Expression<String>? rubricaCodigo,
    Expression<String>? competencia,
    Expression<String>? dataPagamento,
    Expression<int>? valorCentavos,
    Expression<int>? valorDedutivelCentavos,
    Expression<String>? descricao,
    Expression<int>? homeOffice,
    Expression<String>? anexoPath,
    Expression<String>? apuracaoId,
    Expression<int>? criadoEm,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rubricaCodigo != null) 'rubrica_codigo': rubricaCodigo,
      if (competencia != null) 'competencia': competencia,
      if (dataPagamento != null) 'data_pagamento': dataPagamento,
      if (valorCentavos != null) 'valor_centavos': valorCentavos,
      if (valorDedutivelCentavos != null)
        'valor_dedutivel_centavos': valorDedutivelCentavos,
      if (descricao != null) 'descricao': descricao,
      if (homeOffice != null) 'home_office': homeOffice,
      if (anexoPath != null) 'anexo_path': anexoPath,
      if (apuracaoId != null) 'apuracao_id': apuracaoId,
      if (criadoEm != null) 'criado_em': criadoEm,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DespesasLivroCaixaCompanion copyWith({
    Value<String>? id,
    Value<String>? rubricaCodigo,
    Value<String>? competencia,
    Value<String>? dataPagamento,
    Value<int>? valorCentavos,
    Value<int>? valorDedutivelCentavos,
    Value<String?>? descricao,
    Value<int>? homeOffice,
    Value<String?>? anexoPath,
    Value<String?>? apuracaoId,
    Value<int>? criadoEm,
    Value<int>? rowid,
  }) {
    return DespesasLivroCaixaCompanion(
      id: id ?? this.id,
      rubricaCodigo: rubricaCodigo ?? this.rubricaCodigo,
      competencia: competencia ?? this.competencia,
      dataPagamento: dataPagamento ?? this.dataPagamento,
      valorCentavos: valorCentavos ?? this.valorCentavos,
      valorDedutivelCentavos:
          valorDedutivelCentavos ?? this.valorDedutivelCentavos,
      descricao: descricao ?? this.descricao,
      homeOffice: homeOffice ?? this.homeOffice,
      anexoPath: anexoPath ?? this.anexoPath,
      apuracaoId: apuracaoId ?? this.apuracaoId,
      criadoEm: criadoEm ?? this.criadoEm,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (rubricaCodigo.present) {
      map['rubrica_codigo'] = Variable<String>(rubricaCodigo.value);
    }
    if (competencia.present) {
      map['competencia'] = Variable<String>(competencia.value);
    }
    if (dataPagamento.present) {
      map['data_pagamento'] = Variable<String>(dataPagamento.value);
    }
    if (valorCentavos.present) {
      map['valor_centavos'] = Variable<int>(valorCentavos.value);
    }
    if (valorDedutivelCentavos.present) {
      map['valor_dedutivel_centavos'] = Variable<int>(
        valorDedutivelCentavos.value,
      );
    }
    if (descricao.present) {
      map['descricao'] = Variable<String>(descricao.value);
    }
    if (homeOffice.present) {
      map['home_office'] = Variable<int>(homeOffice.value);
    }
    if (anexoPath.present) {
      map['anexo_path'] = Variable<String>(anexoPath.value);
    }
    if (apuracaoId.present) {
      map['apuracao_id'] = Variable<String>(apuracaoId.value);
    }
    if (criadoEm.present) {
      map['criado_em'] = Variable<int>(criadoEm.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DespesasLivroCaixaCompanion(')
          ..write('id: $id, ')
          ..write('rubricaCodigo: $rubricaCodigo, ')
          ..write('competencia: $competencia, ')
          ..write('dataPagamento: $dataPagamento, ')
          ..write('valorCentavos: $valorCentavos, ')
          ..write('valorDedutivelCentavos: $valorDedutivelCentavos, ')
          ..write('descricao: $descricao, ')
          ..write('homeOffice: $homeOffice, ')
          ..write('anexoPath: $anexoPath, ')
          ..write('apuracaoId: $apuracaoId, ')
          ..write('criadoEm: $criadoEm, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class PagamentosInss extends Table
    with TableInfo<PagamentosInss, PagamentoInss> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  PagamentosInss(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _competenciaMeta = const VerificationMeta(
    'competencia',
  );
  late final GeneratedColumn<String> competencia = GeneratedColumn<String>(
    'competencia',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _valorCentavosMeta = const VerificationMeta(
    'valorCentavos',
  );
  late final GeneratedColumn<int> valorCentavos = GeneratedColumn<int>(
    'valor_centavos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (valor_centavos > 0)',
  );
  static const VerificationMeta _observacaoMeta = const VerificationMeta(
    'observacao',
  );
  late final GeneratedColumn<String> observacao = GeneratedColumn<String>(
    'observacao',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _criadoEmMeta = const VerificationMeta(
    'criadoEm',
  );
  late final GeneratedColumn<int> criadoEm = GeneratedColumn<int>(
    'criado_em',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    competencia,
    valorCentavos,
    observacao,
    criadoEm,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pagamentos_inss';
  @override
  VerificationContext validateIntegrity(
    Insertable<PagamentoInss> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('competencia')) {
      context.handle(
        _competenciaMeta,
        competencia.isAcceptableOrUnknown(
          data['competencia']!,
          _competenciaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_competenciaMeta);
    }
    if (data.containsKey('valor_centavos')) {
      context.handle(
        _valorCentavosMeta,
        valorCentavos.isAcceptableOrUnknown(
          data['valor_centavos']!,
          _valorCentavosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_valorCentavosMeta);
    }
    if (data.containsKey('observacao')) {
      context.handle(
        _observacaoMeta,
        observacao.isAcceptableOrUnknown(data['observacao']!, _observacaoMeta),
      );
    }
    if (data.containsKey('criado_em')) {
      context.handle(
        _criadoEmMeta,
        criadoEm.isAcceptableOrUnknown(data['criado_em']!, _criadoEmMeta),
      );
    } else if (isInserting) {
      context.missing(_criadoEmMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PagamentoInss map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PagamentoInss(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      competencia: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}competencia'],
      )!,
      valorCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}valor_centavos'],
      )!,
      observacao: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}observacao'],
      ),
      criadoEm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}criado_em'],
      )!,
    );
  }

  @override
  PagamentosInss createAlias(String alias) {
    return PagamentosInss(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class PagamentoInss extends DataClass implements Insertable<PagamentoInss> {
  final String id;
  final String competencia;

  /// mês do PAGAMENTO efetivo
  final int valorCentavos;
  final String? observacao;
  final int criadoEm;
  const PagamentoInss({
    required this.id,
    required this.competencia,
    required this.valorCentavos,
    this.observacao,
    required this.criadoEm,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['competencia'] = Variable<String>(competencia);
    map['valor_centavos'] = Variable<int>(valorCentavos);
    if (!nullToAbsent || observacao != null) {
      map['observacao'] = Variable<String>(observacao);
    }
    map['criado_em'] = Variable<int>(criadoEm);
    return map;
  }

  PagamentosInssCompanion toCompanion(bool nullToAbsent) {
    return PagamentosInssCompanion(
      id: Value(id),
      competencia: Value(competencia),
      valorCentavos: Value(valorCentavos),
      observacao: observacao == null && nullToAbsent
          ? const Value.absent()
          : Value(observacao),
      criadoEm: Value(criadoEm),
    );
  }

  factory PagamentoInss.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PagamentoInss(
      id: serializer.fromJson<String>(json['id']),
      competencia: serializer.fromJson<String>(json['competencia']),
      valorCentavos: serializer.fromJson<int>(json['valor_centavos']),
      observacao: serializer.fromJson<String?>(json['observacao']),
      criadoEm: serializer.fromJson<int>(json['criado_em']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'competencia': serializer.toJson<String>(competencia),
      'valor_centavos': serializer.toJson<int>(valorCentavos),
      'observacao': serializer.toJson<String?>(observacao),
      'criado_em': serializer.toJson<int>(criadoEm),
    };
  }

  PagamentoInss copyWith({
    String? id,
    String? competencia,
    int? valorCentavos,
    Value<String?> observacao = const Value.absent(),
    int? criadoEm,
  }) => PagamentoInss(
    id: id ?? this.id,
    competencia: competencia ?? this.competencia,
    valorCentavos: valorCentavos ?? this.valorCentavos,
    observacao: observacao.present ? observacao.value : this.observacao,
    criadoEm: criadoEm ?? this.criadoEm,
  );
  PagamentoInss copyWithCompanion(PagamentosInssCompanion data) {
    return PagamentoInss(
      id: data.id.present ? data.id.value : this.id,
      competencia: data.competencia.present
          ? data.competencia.value
          : this.competencia,
      valorCentavos: data.valorCentavos.present
          ? data.valorCentavos.value
          : this.valorCentavos,
      observacao: data.observacao.present
          ? data.observacao.value
          : this.observacao,
      criadoEm: data.criadoEm.present ? data.criadoEm.value : this.criadoEm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PagamentoInss(')
          ..write('id: $id, ')
          ..write('competencia: $competencia, ')
          ..write('valorCentavos: $valorCentavos, ')
          ..write('observacao: $observacao, ')
          ..write('criadoEm: $criadoEm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, competencia, valorCentavos, observacao, criadoEm);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PagamentoInss &&
          other.id == this.id &&
          other.competencia == this.competencia &&
          other.valorCentavos == this.valorCentavos &&
          other.observacao == this.observacao &&
          other.criadoEm == this.criadoEm);
}

class PagamentosInssCompanion extends UpdateCompanion<PagamentoInss> {
  final Value<String> id;
  final Value<String> competencia;
  final Value<int> valorCentavos;
  final Value<String?> observacao;
  final Value<int> criadoEm;
  final Value<int> rowid;
  const PagamentosInssCompanion({
    this.id = const Value.absent(),
    this.competencia = const Value.absent(),
    this.valorCentavos = const Value.absent(),
    this.observacao = const Value.absent(),
    this.criadoEm = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PagamentosInssCompanion.insert({
    required String id,
    required String competencia,
    required int valorCentavos,
    this.observacao = const Value.absent(),
    required int criadoEm,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       competencia = Value(competencia),
       valorCentavos = Value(valorCentavos),
       criadoEm = Value(criadoEm);
  static Insertable<PagamentoInss> custom({
    Expression<String>? id,
    Expression<String>? competencia,
    Expression<int>? valorCentavos,
    Expression<String>? observacao,
    Expression<int>? criadoEm,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (competencia != null) 'competencia': competencia,
      if (valorCentavos != null) 'valor_centavos': valorCentavos,
      if (observacao != null) 'observacao': observacao,
      if (criadoEm != null) 'criado_em': criadoEm,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PagamentosInssCompanion copyWith({
    Value<String>? id,
    Value<String>? competencia,
    Value<int>? valorCentavos,
    Value<String?>? observacao,
    Value<int>? criadoEm,
    Value<int>? rowid,
  }) {
    return PagamentosInssCompanion(
      id: id ?? this.id,
      competencia: competencia ?? this.competencia,
      valorCentavos: valorCentavos ?? this.valorCentavos,
      observacao: observacao ?? this.observacao,
      criadoEm: criadoEm ?? this.criadoEm,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (competencia.present) {
      map['competencia'] = Variable<String>(competencia.value);
    }
    if (valorCentavos.present) {
      map['valor_centavos'] = Variable<int>(valorCentavos.value);
    }
    if (observacao.present) {
      map['observacao'] = Variable<String>(observacao.value);
    }
    if (criadoEm.present) {
      map['criado_em'] = Variable<int>(criadoEm.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PagamentosInssCompanion(')
          ..write('id: $id, ')
          ..write('competencia: $competencia, ')
          ..write('valorCentavos: $valorCentavos, ')
          ..write('observacao: $observacao, ')
          ..write('criadoEm: $criadoEm, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Dependentes extends Table with TableInfo<Dependentes, Dependente> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Dependentes(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
    'nome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _vigenciaInicioMeta = const VerificationMeta(
    'vigenciaInicio',
  );
  late final GeneratedColumn<String> vigenciaInicio = GeneratedColumn<String>(
    'vigencia_inicio',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _vigenciaFimMeta = const VerificationMeta(
    'vigenciaFim',
  );
  late final GeneratedColumn<String> vigenciaFim = GeneratedColumn<String>(
    'vigencia_fim',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _criadoEmMeta = const VerificationMeta(
    'criadoEm',
  );
  late final GeneratedColumn<int> criadoEm = GeneratedColumn<int>(
    'criado_em',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nome,
    vigenciaInicio,
    vigenciaFim,
    criadoEm,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dependentes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Dependente> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('vigencia_inicio')) {
      context.handle(
        _vigenciaInicioMeta,
        vigenciaInicio.isAcceptableOrUnknown(
          data['vigencia_inicio']!,
          _vigenciaInicioMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_vigenciaInicioMeta);
    }
    if (data.containsKey('vigencia_fim')) {
      context.handle(
        _vigenciaFimMeta,
        vigenciaFim.isAcceptableOrUnknown(
          data['vigencia_fim']!,
          _vigenciaFimMeta,
        ),
      );
    }
    if (data.containsKey('criado_em')) {
      context.handle(
        _criadoEmMeta,
        criadoEm.isAcceptableOrUnknown(data['criado_em']!, _criadoEmMeta),
      );
    } else if (isInserting) {
      context.missing(_criadoEmMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Dependente map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Dependente(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome'],
      )!,
      vigenciaInicio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vigencia_inicio'],
      )!,
      vigenciaFim: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vigencia_fim'],
      ),
      criadoEm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}criado_em'],
      )!,
    );
  }

  @override
  Dependentes createAlias(String alias) {
    return Dependentes(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Dependente extends DataClass implements Insertable<Dependente> {
  final String id;
  final String nome;
  final String vigenciaInicio;
  final String? vigenciaFim;
  final int criadoEm;
  const Dependente({
    required this.id,
    required this.nome,
    required this.vigenciaInicio,
    this.vigenciaFim,
    required this.criadoEm,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nome'] = Variable<String>(nome);
    map['vigencia_inicio'] = Variable<String>(vigenciaInicio);
    if (!nullToAbsent || vigenciaFim != null) {
      map['vigencia_fim'] = Variable<String>(vigenciaFim);
    }
    map['criado_em'] = Variable<int>(criadoEm);
    return map;
  }

  DependentesCompanion toCompanion(bool nullToAbsent) {
    return DependentesCompanion(
      id: Value(id),
      nome: Value(nome),
      vigenciaInicio: Value(vigenciaInicio),
      vigenciaFim: vigenciaFim == null && nullToAbsent
          ? const Value.absent()
          : Value(vigenciaFim),
      criadoEm: Value(criadoEm),
    );
  }

  factory Dependente.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Dependente(
      id: serializer.fromJson<String>(json['id']),
      nome: serializer.fromJson<String>(json['nome']),
      vigenciaInicio: serializer.fromJson<String>(json['vigencia_inicio']),
      vigenciaFim: serializer.fromJson<String?>(json['vigencia_fim']),
      criadoEm: serializer.fromJson<int>(json['criado_em']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nome': serializer.toJson<String>(nome),
      'vigencia_inicio': serializer.toJson<String>(vigenciaInicio),
      'vigencia_fim': serializer.toJson<String?>(vigenciaFim),
      'criado_em': serializer.toJson<int>(criadoEm),
    };
  }

  Dependente copyWith({
    String? id,
    String? nome,
    String? vigenciaInicio,
    Value<String?> vigenciaFim = const Value.absent(),
    int? criadoEm,
  }) => Dependente(
    id: id ?? this.id,
    nome: nome ?? this.nome,
    vigenciaInicio: vigenciaInicio ?? this.vigenciaInicio,
    vigenciaFim: vigenciaFim.present ? vigenciaFim.value : this.vigenciaFim,
    criadoEm: criadoEm ?? this.criadoEm,
  );
  Dependente copyWithCompanion(DependentesCompanion data) {
    return Dependente(
      id: data.id.present ? data.id.value : this.id,
      nome: data.nome.present ? data.nome.value : this.nome,
      vigenciaInicio: data.vigenciaInicio.present
          ? data.vigenciaInicio.value
          : this.vigenciaInicio,
      vigenciaFim: data.vigenciaFim.present
          ? data.vigenciaFim.value
          : this.vigenciaFim,
      criadoEm: data.criadoEm.present ? data.criadoEm.value : this.criadoEm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Dependente(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('vigenciaInicio: $vigenciaInicio, ')
          ..write('vigenciaFim: $vigenciaFim, ')
          ..write('criadoEm: $criadoEm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, nome, vigenciaInicio, vigenciaFim, criadoEm);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Dependente &&
          other.id == this.id &&
          other.nome == this.nome &&
          other.vigenciaInicio == this.vigenciaInicio &&
          other.vigenciaFim == this.vigenciaFim &&
          other.criadoEm == this.criadoEm);
}

class DependentesCompanion extends UpdateCompanion<Dependente> {
  final Value<String> id;
  final Value<String> nome;
  final Value<String> vigenciaInicio;
  final Value<String?> vigenciaFim;
  final Value<int> criadoEm;
  final Value<int> rowid;
  const DependentesCompanion({
    this.id = const Value.absent(),
    this.nome = const Value.absent(),
    this.vigenciaInicio = const Value.absent(),
    this.vigenciaFim = const Value.absent(),
    this.criadoEm = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DependentesCompanion.insert({
    required String id,
    required String nome,
    required String vigenciaInicio,
    this.vigenciaFim = const Value.absent(),
    required int criadoEm,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nome = Value(nome),
       vigenciaInicio = Value(vigenciaInicio),
       criadoEm = Value(criadoEm);
  static Insertable<Dependente> custom({
    Expression<String>? id,
    Expression<String>? nome,
    Expression<String>? vigenciaInicio,
    Expression<String>? vigenciaFim,
    Expression<int>? criadoEm,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nome != null) 'nome': nome,
      if (vigenciaInicio != null) 'vigencia_inicio': vigenciaInicio,
      if (vigenciaFim != null) 'vigencia_fim': vigenciaFim,
      if (criadoEm != null) 'criado_em': criadoEm,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DependentesCompanion copyWith({
    Value<String>? id,
    Value<String>? nome,
    Value<String>? vigenciaInicio,
    Value<String?>? vigenciaFim,
    Value<int>? criadoEm,
    Value<int>? rowid,
  }) {
    return DependentesCompanion(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      vigenciaInicio: vigenciaInicio ?? this.vigenciaInicio,
      vigenciaFim: vigenciaFim ?? this.vigenciaFim,
      criadoEm: criadoEm ?? this.criadoEm,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (vigenciaInicio.present) {
      map['vigencia_inicio'] = Variable<String>(vigenciaInicio.value);
    }
    if (vigenciaFim.present) {
      map['vigencia_fim'] = Variable<String>(vigenciaFim.value);
    }
    if (criadoEm.present) {
      map['criado_em'] = Variable<int>(criadoEm.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DependentesCompanion(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('vigenciaInicio: $vigenciaInicio, ')
          ..write('vigenciaFim: $vigenciaFim, ')
          ..write('criadoEm: $criadoEm, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Darfs extends Table with TableInfo<Darfs, DarfLocal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Darfs(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _apuracaoIdMeta = const VerificationMeta(
    'apuracaoId',
  );
  late final GeneratedColumn<String> apuracaoId = GeneratedColumn<String>(
    'apuracao_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES apuracoes_mensais(id)',
  );
  static const VerificationMeta _codigoReceitaMeta = const VerificationMeta(
    'codigoReceita',
  );
  late final GeneratedColumn<String> codigoReceita = GeneratedColumn<String>(
    'codigo_receita',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'0190\'',
    defaultValue: const CustomExpression('\'0190\''),
  );
  static const VerificationMeta _competenciaMeta = const VerificationMeta(
    'competencia',
  );
  late final GeneratedColumn<String> competencia = GeneratedColumn<String>(
    'competencia',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _valorCentavosMeta = const VerificationMeta(
    'valorCentavos',
  );
  late final GeneratedColumn<int> valorCentavos = GeneratedColumn<int>(
    'valor_centavos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _vencimentoMeta = const VerificationMeta(
    'vencimento',
  );
  late final GeneratedColumn<String> vencimento = GeneratedColumn<String>(
    'vencimento',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _vencimentoAntecipadoMeta =
      const VerificationMeta('vencimentoAntecipado');
  late final GeneratedColumn<int> vencimentoAntecipado = GeneratedColumn<int>(
    'vencimento_antecipado',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _codigoBarrasMeta = const VerificationMeta(
    'codigoBarras',
  );
  late final GeneratedColumn<String> codigoBarras = GeneratedColumn<String>(
    'codigo_barras',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT \'gerado\' CHECK (status IN (\'gerado\', \'pago\', \'vencido\', \'cancelado\'))',
    defaultValue: const CustomExpression('\'gerado\''),
  );
  static const VerificationMeta _pagoEmMeta = const VerificationMeta('pagoEm');
  late final GeneratedColumn<String> pagoEm = GeneratedColumn<String>(
    'pago_em',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _valorPagoCentavosMeta = const VerificationMeta(
    'valorPagoCentavos',
  );
  late final GeneratedColumn<int> valorPagoCentavos = GeneratedColumn<int>(
    'valor_pago_centavos',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _criadoEmMeta = const VerificationMeta(
    'criadoEm',
  );
  late final GeneratedColumn<int> criadoEm = GeneratedColumn<int>(
    'criado_em',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    apuracaoId,
    codigoReceita,
    competencia,
    valorCentavos,
    vencimento,
    vencimentoAntecipado,
    codigoBarras,
    status,
    pagoEm,
    valorPagoCentavos,
    criadoEm,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'darfs';
  @override
  VerificationContext validateIntegrity(
    Insertable<DarfLocal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('apuracao_id')) {
      context.handle(
        _apuracaoIdMeta,
        apuracaoId.isAcceptableOrUnknown(data['apuracao_id']!, _apuracaoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_apuracaoIdMeta);
    }
    if (data.containsKey('codigo_receita')) {
      context.handle(
        _codigoReceitaMeta,
        codigoReceita.isAcceptableOrUnknown(
          data['codigo_receita']!,
          _codigoReceitaMeta,
        ),
      );
    }
    if (data.containsKey('competencia')) {
      context.handle(
        _competenciaMeta,
        competencia.isAcceptableOrUnknown(
          data['competencia']!,
          _competenciaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_competenciaMeta);
    }
    if (data.containsKey('valor_centavos')) {
      context.handle(
        _valorCentavosMeta,
        valorCentavos.isAcceptableOrUnknown(
          data['valor_centavos']!,
          _valorCentavosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_valorCentavosMeta);
    }
    if (data.containsKey('vencimento')) {
      context.handle(
        _vencimentoMeta,
        vencimento.isAcceptableOrUnknown(data['vencimento']!, _vencimentoMeta),
      );
    } else if (isInserting) {
      context.missing(_vencimentoMeta);
    }
    if (data.containsKey('vencimento_antecipado')) {
      context.handle(
        _vencimentoAntecipadoMeta,
        vencimentoAntecipado.isAcceptableOrUnknown(
          data['vencimento_antecipado']!,
          _vencimentoAntecipadoMeta,
        ),
      );
    }
    if (data.containsKey('codigo_barras')) {
      context.handle(
        _codigoBarrasMeta,
        codigoBarras.isAcceptableOrUnknown(
          data['codigo_barras']!,
          _codigoBarrasMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('pago_em')) {
      context.handle(
        _pagoEmMeta,
        pagoEm.isAcceptableOrUnknown(data['pago_em']!, _pagoEmMeta),
      );
    }
    if (data.containsKey('valor_pago_centavos')) {
      context.handle(
        _valorPagoCentavosMeta,
        valorPagoCentavos.isAcceptableOrUnknown(
          data['valor_pago_centavos']!,
          _valorPagoCentavosMeta,
        ),
      );
    }
    if (data.containsKey('criado_em')) {
      context.handle(
        _criadoEmMeta,
        criadoEm.isAcceptableOrUnknown(data['criado_em']!, _criadoEmMeta),
      );
    } else if (isInserting) {
      context.missing(_criadoEmMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DarfLocal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DarfLocal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      apuracaoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}apuracao_id'],
      )!,
      codigoReceita: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}codigo_receita'],
      )!,
      competencia: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}competencia'],
      )!,
      valorCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}valor_centavos'],
      )!,
      vencimento: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vencimento'],
      )!,
      vencimentoAntecipado: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vencimento_antecipado'],
      )!,
      codigoBarras: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}codigo_barras'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      pagoEm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pago_em'],
      ),
      valorPagoCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}valor_pago_centavos'],
      ),
      criadoEm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}criado_em'],
      )!,
    );
  }

  @override
  Darfs createAlias(String alias) {
    return Darfs(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class DarfLocal extends DataClass implements Insertable<DarfLocal> {
  final String id;
  final String apuracaoId;
  final String codigoReceita;
  final String competencia;
  final int valorCentavos;
  final String vencimento;

  /// último dia útil do mês seguinte, antecipado
  final int vencimentoAntecipado;
  final String? codigoBarras;
  final String status;
  final String? pagoEm;
  final int? valorPagoCentavos;

  /// p/ o relatório anual fechar ao centavo
  final int criadoEm;
  const DarfLocal({
    required this.id,
    required this.apuracaoId,
    required this.codigoReceita,
    required this.competencia,
    required this.valorCentavos,
    required this.vencimento,
    required this.vencimentoAntecipado,
    this.codigoBarras,
    required this.status,
    this.pagoEm,
    this.valorPagoCentavos,
    required this.criadoEm,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['apuracao_id'] = Variable<String>(apuracaoId);
    map['codigo_receita'] = Variable<String>(codigoReceita);
    map['competencia'] = Variable<String>(competencia);
    map['valor_centavos'] = Variable<int>(valorCentavos);
    map['vencimento'] = Variable<String>(vencimento);
    map['vencimento_antecipado'] = Variable<int>(vencimentoAntecipado);
    if (!nullToAbsent || codigoBarras != null) {
      map['codigo_barras'] = Variable<String>(codigoBarras);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || pagoEm != null) {
      map['pago_em'] = Variable<String>(pagoEm);
    }
    if (!nullToAbsent || valorPagoCentavos != null) {
      map['valor_pago_centavos'] = Variable<int>(valorPagoCentavos);
    }
    map['criado_em'] = Variable<int>(criadoEm);
    return map;
  }

  DarfsCompanion toCompanion(bool nullToAbsent) {
    return DarfsCompanion(
      id: Value(id),
      apuracaoId: Value(apuracaoId),
      codigoReceita: Value(codigoReceita),
      competencia: Value(competencia),
      valorCentavos: Value(valorCentavos),
      vencimento: Value(vencimento),
      vencimentoAntecipado: Value(vencimentoAntecipado),
      codigoBarras: codigoBarras == null && nullToAbsent
          ? const Value.absent()
          : Value(codigoBarras),
      status: Value(status),
      pagoEm: pagoEm == null && nullToAbsent
          ? const Value.absent()
          : Value(pagoEm),
      valorPagoCentavos: valorPagoCentavos == null && nullToAbsent
          ? const Value.absent()
          : Value(valorPagoCentavos),
      criadoEm: Value(criadoEm),
    );
  }

  factory DarfLocal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DarfLocal(
      id: serializer.fromJson<String>(json['id']),
      apuracaoId: serializer.fromJson<String>(json['apuracao_id']),
      codigoReceita: serializer.fromJson<String>(json['codigo_receita']),
      competencia: serializer.fromJson<String>(json['competencia']),
      valorCentavos: serializer.fromJson<int>(json['valor_centavos']),
      vencimento: serializer.fromJson<String>(json['vencimento']),
      vencimentoAntecipado: serializer.fromJson<int>(
        json['vencimento_antecipado'],
      ),
      codigoBarras: serializer.fromJson<String?>(json['codigo_barras']),
      status: serializer.fromJson<String>(json['status']),
      pagoEm: serializer.fromJson<String?>(json['pago_em']),
      valorPagoCentavos: serializer.fromJson<int?>(json['valor_pago_centavos']),
      criadoEm: serializer.fromJson<int>(json['criado_em']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'apuracao_id': serializer.toJson<String>(apuracaoId),
      'codigo_receita': serializer.toJson<String>(codigoReceita),
      'competencia': serializer.toJson<String>(competencia),
      'valor_centavos': serializer.toJson<int>(valorCentavos),
      'vencimento': serializer.toJson<String>(vencimento),
      'vencimento_antecipado': serializer.toJson<int>(vencimentoAntecipado),
      'codigo_barras': serializer.toJson<String?>(codigoBarras),
      'status': serializer.toJson<String>(status),
      'pago_em': serializer.toJson<String?>(pagoEm),
      'valor_pago_centavos': serializer.toJson<int?>(valorPagoCentavos),
      'criado_em': serializer.toJson<int>(criadoEm),
    };
  }

  DarfLocal copyWith({
    String? id,
    String? apuracaoId,
    String? codigoReceita,
    String? competencia,
    int? valorCentavos,
    String? vencimento,
    int? vencimentoAntecipado,
    Value<String?> codigoBarras = const Value.absent(),
    String? status,
    Value<String?> pagoEm = const Value.absent(),
    Value<int?> valorPagoCentavos = const Value.absent(),
    int? criadoEm,
  }) => DarfLocal(
    id: id ?? this.id,
    apuracaoId: apuracaoId ?? this.apuracaoId,
    codigoReceita: codigoReceita ?? this.codigoReceita,
    competencia: competencia ?? this.competencia,
    valorCentavos: valorCentavos ?? this.valorCentavos,
    vencimento: vencimento ?? this.vencimento,
    vencimentoAntecipado: vencimentoAntecipado ?? this.vencimentoAntecipado,
    codigoBarras: codigoBarras.present ? codigoBarras.value : this.codigoBarras,
    status: status ?? this.status,
    pagoEm: pagoEm.present ? pagoEm.value : this.pagoEm,
    valorPagoCentavos: valorPagoCentavos.present
        ? valorPagoCentavos.value
        : this.valorPagoCentavos,
    criadoEm: criadoEm ?? this.criadoEm,
  );
  DarfLocal copyWithCompanion(DarfsCompanion data) {
    return DarfLocal(
      id: data.id.present ? data.id.value : this.id,
      apuracaoId: data.apuracaoId.present
          ? data.apuracaoId.value
          : this.apuracaoId,
      codigoReceita: data.codigoReceita.present
          ? data.codigoReceita.value
          : this.codigoReceita,
      competencia: data.competencia.present
          ? data.competencia.value
          : this.competencia,
      valorCentavos: data.valorCentavos.present
          ? data.valorCentavos.value
          : this.valorCentavos,
      vencimento: data.vencimento.present
          ? data.vencimento.value
          : this.vencimento,
      vencimentoAntecipado: data.vencimentoAntecipado.present
          ? data.vencimentoAntecipado.value
          : this.vencimentoAntecipado,
      codigoBarras: data.codigoBarras.present
          ? data.codigoBarras.value
          : this.codigoBarras,
      status: data.status.present ? data.status.value : this.status,
      pagoEm: data.pagoEm.present ? data.pagoEm.value : this.pagoEm,
      valorPagoCentavos: data.valorPagoCentavos.present
          ? data.valorPagoCentavos.value
          : this.valorPagoCentavos,
      criadoEm: data.criadoEm.present ? data.criadoEm.value : this.criadoEm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DarfLocal(')
          ..write('id: $id, ')
          ..write('apuracaoId: $apuracaoId, ')
          ..write('codigoReceita: $codigoReceita, ')
          ..write('competencia: $competencia, ')
          ..write('valorCentavos: $valorCentavos, ')
          ..write('vencimento: $vencimento, ')
          ..write('vencimentoAntecipado: $vencimentoAntecipado, ')
          ..write('codigoBarras: $codigoBarras, ')
          ..write('status: $status, ')
          ..write('pagoEm: $pagoEm, ')
          ..write('valorPagoCentavos: $valorPagoCentavos, ')
          ..write('criadoEm: $criadoEm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    apuracaoId,
    codigoReceita,
    competencia,
    valorCentavos,
    vencimento,
    vencimentoAntecipado,
    codigoBarras,
    status,
    pagoEm,
    valorPagoCentavos,
    criadoEm,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DarfLocal &&
          other.id == this.id &&
          other.apuracaoId == this.apuracaoId &&
          other.codigoReceita == this.codigoReceita &&
          other.competencia == this.competencia &&
          other.valorCentavos == this.valorCentavos &&
          other.vencimento == this.vencimento &&
          other.vencimentoAntecipado == this.vencimentoAntecipado &&
          other.codigoBarras == this.codigoBarras &&
          other.status == this.status &&
          other.pagoEm == this.pagoEm &&
          other.valorPagoCentavos == this.valorPagoCentavos &&
          other.criadoEm == this.criadoEm);
}

class DarfsCompanion extends UpdateCompanion<DarfLocal> {
  final Value<String> id;
  final Value<String> apuracaoId;
  final Value<String> codigoReceita;
  final Value<String> competencia;
  final Value<int> valorCentavos;
  final Value<String> vencimento;
  final Value<int> vencimentoAntecipado;
  final Value<String?> codigoBarras;
  final Value<String> status;
  final Value<String?> pagoEm;
  final Value<int?> valorPagoCentavos;
  final Value<int> criadoEm;
  final Value<int> rowid;
  const DarfsCompanion({
    this.id = const Value.absent(),
    this.apuracaoId = const Value.absent(),
    this.codigoReceita = const Value.absent(),
    this.competencia = const Value.absent(),
    this.valorCentavos = const Value.absent(),
    this.vencimento = const Value.absent(),
    this.vencimentoAntecipado = const Value.absent(),
    this.codigoBarras = const Value.absent(),
    this.status = const Value.absent(),
    this.pagoEm = const Value.absent(),
    this.valorPagoCentavos = const Value.absent(),
    this.criadoEm = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DarfsCompanion.insert({
    required String id,
    required String apuracaoId,
    this.codigoReceita = const Value.absent(),
    required String competencia,
    required int valorCentavos,
    required String vencimento,
    this.vencimentoAntecipado = const Value.absent(),
    this.codigoBarras = const Value.absent(),
    this.status = const Value.absent(),
    this.pagoEm = const Value.absent(),
    this.valorPagoCentavos = const Value.absent(),
    required int criadoEm,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       apuracaoId = Value(apuracaoId),
       competencia = Value(competencia),
       valorCentavos = Value(valorCentavos),
       vencimento = Value(vencimento),
       criadoEm = Value(criadoEm);
  static Insertable<DarfLocal> custom({
    Expression<String>? id,
    Expression<String>? apuracaoId,
    Expression<String>? codigoReceita,
    Expression<String>? competencia,
    Expression<int>? valorCentavos,
    Expression<String>? vencimento,
    Expression<int>? vencimentoAntecipado,
    Expression<String>? codigoBarras,
    Expression<String>? status,
    Expression<String>? pagoEm,
    Expression<int>? valorPagoCentavos,
    Expression<int>? criadoEm,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (apuracaoId != null) 'apuracao_id': apuracaoId,
      if (codigoReceita != null) 'codigo_receita': codigoReceita,
      if (competencia != null) 'competencia': competencia,
      if (valorCentavos != null) 'valor_centavos': valorCentavos,
      if (vencimento != null) 'vencimento': vencimento,
      if (vencimentoAntecipado != null)
        'vencimento_antecipado': vencimentoAntecipado,
      if (codigoBarras != null) 'codigo_barras': codigoBarras,
      if (status != null) 'status': status,
      if (pagoEm != null) 'pago_em': pagoEm,
      if (valorPagoCentavos != null) 'valor_pago_centavos': valorPagoCentavos,
      if (criadoEm != null) 'criado_em': criadoEm,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DarfsCompanion copyWith({
    Value<String>? id,
    Value<String>? apuracaoId,
    Value<String>? codigoReceita,
    Value<String>? competencia,
    Value<int>? valorCentavos,
    Value<String>? vencimento,
    Value<int>? vencimentoAntecipado,
    Value<String?>? codigoBarras,
    Value<String>? status,
    Value<String?>? pagoEm,
    Value<int?>? valorPagoCentavos,
    Value<int>? criadoEm,
    Value<int>? rowid,
  }) {
    return DarfsCompanion(
      id: id ?? this.id,
      apuracaoId: apuracaoId ?? this.apuracaoId,
      codigoReceita: codigoReceita ?? this.codigoReceita,
      competencia: competencia ?? this.competencia,
      valorCentavos: valorCentavos ?? this.valorCentavos,
      vencimento: vencimento ?? this.vencimento,
      vencimentoAntecipado: vencimentoAntecipado ?? this.vencimentoAntecipado,
      codigoBarras: codigoBarras ?? this.codigoBarras,
      status: status ?? this.status,
      pagoEm: pagoEm ?? this.pagoEm,
      valorPagoCentavos: valorPagoCentavos ?? this.valorPagoCentavos,
      criadoEm: criadoEm ?? this.criadoEm,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (apuracaoId.present) {
      map['apuracao_id'] = Variable<String>(apuracaoId.value);
    }
    if (codigoReceita.present) {
      map['codigo_receita'] = Variable<String>(codigoReceita.value);
    }
    if (competencia.present) {
      map['competencia'] = Variable<String>(competencia.value);
    }
    if (valorCentavos.present) {
      map['valor_centavos'] = Variable<int>(valorCentavos.value);
    }
    if (vencimento.present) {
      map['vencimento'] = Variable<String>(vencimento.value);
    }
    if (vencimentoAntecipado.present) {
      map['vencimento_antecipado'] = Variable<int>(vencimentoAntecipado.value);
    }
    if (codigoBarras.present) {
      map['codigo_barras'] = Variable<String>(codigoBarras.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (pagoEm.present) {
      map['pago_em'] = Variable<String>(pagoEm.value);
    }
    if (valorPagoCentavos.present) {
      map['valor_pago_centavos'] = Variable<int>(valorPagoCentavos.value);
    }
    if (criadoEm.present) {
      map['criado_em'] = Variable<int>(criadoEm.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DarfsCompanion(')
          ..write('id: $id, ')
          ..write('apuracaoId: $apuracaoId, ')
          ..write('codigoReceita: $codigoReceita, ')
          ..write('competencia: $competencia, ')
          ..write('valorCentavos: $valorCentavos, ')
          ..write('vencimento: $vencimento, ')
          ..write('vencimentoAntecipado: $vencimentoAntecipado, ')
          ..write('codigoBarras: $codigoBarras, ')
          ..write('status: $status, ')
          ..write('pagoEm: $pagoEm, ')
          ..write('valorPagoCentavos: $valorPagoCentavos, ')
          ..write('criadoEm: $criadoEm, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class NotificacoesLocais extends Table
    with TableInfo<NotificacoesLocais, NotificacaoLocal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  NotificacoesLocais(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (tipo IN (\'lembrete_darf\', \'lembrete_importacao\', \'radar_pf_cnpj\', \'backup\', \'sistema\'))',
  );
  static const VerificationMeta _referenciaIdMeta = const VerificationMeta(
    'referenciaId',
  );
  late final GeneratedColumn<String> referenciaId = GeneratedColumn<String>(
    'referencia_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _agendadaParaMeta = const VerificationMeta(
    'agendadaPara',
  );
  late final GeneratedColumn<int> agendadaPara = GeneratedColumn<int>(
    'agendada_para',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _osNotifIdMeta = const VerificationMeta(
    'osNotifId',
  );
  late final GeneratedColumn<int> osNotifId = GeneratedColumn<int>(
    'os_notif_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT \'agendada\' CHECK (status IN (\'agendada\', \'disparada\', \'cancelada\'))',
    defaultValue: const CustomExpression('\'agendada\''),
  );
  static const VerificationMeta _criadoEmMeta = const VerificationMeta(
    'criadoEm',
  );
  late final GeneratedColumn<int> criadoEm = GeneratedColumn<int>(
    'criado_em',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tipo,
    referenciaId,
    agendadaPara,
    osNotifId,
    status,
    criadoEm,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notificacoes_locais';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotificacaoLocal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('referencia_id')) {
      context.handle(
        _referenciaIdMeta,
        referenciaId.isAcceptableOrUnknown(
          data['referencia_id']!,
          _referenciaIdMeta,
        ),
      );
    }
    if (data.containsKey('agendada_para')) {
      context.handle(
        _agendadaParaMeta,
        agendadaPara.isAcceptableOrUnknown(
          data['agendada_para']!,
          _agendadaParaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_agendadaParaMeta);
    }
    if (data.containsKey('os_notif_id')) {
      context.handle(
        _osNotifIdMeta,
        osNotifId.isAcceptableOrUnknown(data['os_notif_id']!, _osNotifIdMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('criado_em')) {
      context.handle(
        _criadoEmMeta,
        criadoEm.isAcceptableOrUnknown(data['criado_em']!, _criadoEmMeta),
      );
    } else if (isInserting) {
      context.missing(_criadoEmMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NotificacaoLocal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotificacaoLocal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      referenciaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}referencia_id'],
      ),
      agendadaPara: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}agendada_para'],
      )!,
      osNotifId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}os_notif_id'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      criadoEm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}criado_em'],
      )!,
    );
  }

  @override
  NotificacoesLocais createAlias(String alias) {
    return NotificacoesLocais(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class NotificacaoLocal extends DataClass
    implements Insertable<NotificacaoLocal> {
  final String id;
  final String tipo;
  final String? referenciaId;
  final int agendadaPara;
  final int? osNotifId;

  /// id devolvido pelo agendador do SO
  final String status;
  final int criadoEm;
  const NotificacaoLocal({
    required this.id,
    required this.tipo,
    this.referenciaId,
    required this.agendadaPara,
    this.osNotifId,
    required this.status,
    required this.criadoEm,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tipo'] = Variable<String>(tipo);
    if (!nullToAbsent || referenciaId != null) {
      map['referencia_id'] = Variable<String>(referenciaId);
    }
    map['agendada_para'] = Variable<int>(agendadaPara);
    if (!nullToAbsent || osNotifId != null) {
      map['os_notif_id'] = Variable<int>(osNotifId);
    }
    map['status'] = Variable<String>(status);
    map['criado_em'] = Variable<int>(criadoEm);
    return map;
  }

  NotificacoesLocaisCompanion toCompanion(bool nullToAbsent) {
    return NotificacoesLocaisCompanion(
      id: Value(id),
      tipo: Value(tipo),
      referenciaId: referenciaId == null && nullToAbsent
          ? const Value.absent()
          : Value(referenciaId),
      agendadaPara: Value(agendadaPara),
      osNotifId: osNotifId == null && nullToAbsent
          ? const Value.absent()
          : Value(osNotifId),
      status: Value(status),
      criadoEm: Value(criadoEm),
    );
  }

  factory NotificacaoLocal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotificacaoLocal(
      id: serializer.fromJson<String>(json['id']),
      tipo: serializer.fromJson<String>(json['tipo']),
      referenciaId: serializer.fromJson<String?>(json['referencia_id']),
      agendadaPara: serializer.fromJson<int>(json['agendada_para']),
      osNotifId: serializer.fromJson<int?>(json['os_notif_id']),
      status: serializer.fromJson<String>(json['status']),
      criadoEm: serializer.fromJson<int>(json['criado_em']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tipo': serializer.toJson<String>(tipo),
      'referencia_id': serializer.toJson<String?>(referenciaId),
      'agendada_para': serializer.toJson<int>(agendadaPara),
      'os_notif_id': serializer.toJson<int?>(osNotifId),
      'status': serializer.toJson<String>(status),
      'criado_em': serializer.toJson<int>(criadoEm),
    };
  }

  NotificacaoLocal copyWith({
    String? id,
    String? tipo,
    Value<String?> referenciaId = const Value.absent(),
    int? agendadaPara,
    Value<int?> osNotifId = const Value.absent(),
    String? status,
    int? criadoEm,
  }) => NotificacaoLocal(
    id: id ?? this.id,
    tipo: tipo ?? this.tipo,
    referenciaId: referenciaId.present ? referenciaId.value : this.referenciaId,
    agendadaPara: agendadaPara ?? this.agendadaPara,
    osNotifId: osNotifId.present ? osNotifId.value : this.osNotifId,
    status: status ?? this.status,
    criadoEm: criadoEm ?? this.criadoEm,
  );
  NotificacaoLocal copyWithCompanion(NotificacoesLocaisCompanion data) {
    return NotificacaoLocal(
      id: data.id.present ? data.id.value : this.id,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      referenciaId: data.referenciaId.present
          ? data.referenciaId.value
          : this.referenciaId,
      agendadaPara: data.agendadaPara.present
          ? data.agendadaPara.value
          : this.agendadaPara,
      osNotifId: data.osNotifId.present ? data.osNotifId.value : this.osNotifId,
      status: data.status.present ? data.status.value : this.status,
      criadoEm: data.criadoEm.present ? data.criadoEm.value : this.criadoEm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotificacaoLocal(')
          ..write('id: $id, ')
          ..write('tipo: $tipo, ')
          ..write('referenciaId: $referenciaId, ')
          ..write('agendadaPara: $agendadaPara, ')
          ..write('osNotifId: $osNotifId, ')
          ..write('status: $status, ')
          ..write('criadoEm: $criadoEm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tipo,
    referenciaId,
    agendadaPara,
    osNotifId,
    status,
    criadoEm,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificacaoLocal &&
          other.id == this.id &&
          other.tipo == this.tipo &&
          other.referenciaId == this.referenciaId &&
          other.agendadaPara == this.agendadaPara &&
          other.osNotifId == this.osNotifId &&
          other.status == this.status &&
          other.criadoEm == this.criadoEm);
}

class NotificacoesLocaisCompanion extends UpdateCompanion<NotificacaoLocal> {
  final Value<String> id;
  final Value<String> tipo;
  final Value<String?> referenciaId;
  final Value<int> agendadaPara;
  final Value<int?> osNotifId;
  final Value<String> status;
  final Value<int> criadoEm;
  final Value<int> rowid;
  const NotificacoesLocaisCompanion({
    this.id = const Value.absent(),
    this.tipo = const Value.absent(),
    this.referenciaId = const Value.absent(),
    this.agendadaPara = const Value.absent(),
    this.osNotifId = const Value.absent(),
    this.status = const Value.absent(),
    this.criadoEm = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotificacoesLocaisCompanion.insert({
    required String id,
    required String tipo,
    this.referenciaId = const Value.absent(),
    required int agendadaPara,
    this.osNotifId = const Value.absent(),
    this.status = const Value.absent(),
    required int criadoEm,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tipo = Value(tipo),
       agendadaPara = Value(agendadaPara),
       criadoEm = Value(criadoEm);
  static Insertable<NotificacaoLocal> custom({
    Expression<String>? id,
    Expression<String>? tipo,
    Expression<String>? referenciaId,
    Expression<int>? agendadaPara,
    Expression<int>? osNotifId,
    Expression<String>? status,
    Expression<int>? criadoEm,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tipo != null) 'tipo': tipo,
      if (referenciaId != null) 'referencia_id': referenciaId,
      if (agendadaPara != null) 'agendada_para': agendadaPara,
      if (osNotifId != null) 'os_notif_id': osNotifId,
      if (status != null) 'status': status,
      if (criadoEm != null) 'criado_em': criadoEm,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotificacoesLocaisCompanion copyWith({
    Value<String>? id,
    Value<String>? tipo,
    Value<String?>? referenciaId,
    Value<int>? agendadaPara,
    Value<int?>? osNotifId,
    Value<String>? status,
    Value<int>? criadoEm,
    Value<int>? rowid,
  }) {
    return NotificacoesLocaisCompanion(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      referenciaId: referenciaId ?? this.referenciaId,
      agendadaPara: agendadaPara ?? this.agendadaPara,
      osNotifId: osNotifId ?? this.osNotifId,
      status: status ?? this.status,
      criadoEm: criadoEm ?? this.criadoEm,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (referenciaId.present) {
      map['referencia_id'] = Variable<String>(referenciaId.value);
    }
    if (agendadaPara.present) {
      map['agendada_para'] = Variable<int>(agendadaPara.value);
    }
    if (osNotifId.present) {
      map['os_notif_id'] = Variable<int>(osNotifId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (criadoEm.present) {
      map['criado_em'] = Variable<int>(criadoEm.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotificacoesLocaisCompanion(')
          ..write('id: $id, ')
          ..write('tipo: $tipo, ')
          ..write('referenciaId: $referenciaId, ')
          ..write('agendadaPara: $agendadaPara, ')
          ..write('osNotifId: $osNotifId, ')
          ..write('status: $status, ')
          ..write('criadoEm: $criadoEm, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class BackupEstadoTable extends Table
    with TableInfo<BackupEstadoTable, BackupEstado> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  BackupEstadoTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (id = 1)',
  );
  static const VerificationMeta _ultimaSeqMeta = const VerificationMeta(
    'ultimaSeq',
  );
  late final GeneratedColumn<int> ultimaSeq = GeneratedColumn<int>(
    'ultima_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _ultimoHashMeta = const VerificationMeta(
    'ultimoHash',
  );
  late final GeneratedColumn<String> ultimoHash = GeneratedColumn<String>(
    'ultimo_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _ultimoEmMeta = const VerificationMeta(
    'ultimoEm',
  );
  late final GeneratedColumn<int> ultimoEm = GeneratedColumn<int>(
    'ultimo_em',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _formatoVersaoMeta = const VerificationMeta(
    'formatoVersao',
  );
  late final GeneratedColumn<int> formatoVersao = GeneratedColumn<int>(
    'formato_versao',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _tamanhoBytesMeta = const VerificationMeta(
    'tamanhoBytes',
  );
  late final GeneratedColumn<int> tamanhoBytes = GeneratedColumn<int>(
    'tamanho_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _resultadoMeta = const VerificationMeta(
    'resultado',
  );
  late final GeneratedColumn<String> resultado = GeneratedColumn<String>(
    'resultado',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (resultado IN (\'ok\', \'falha\', \'pendente\'))',
  );
  static const VerificationMeta _erroDetalheMeta = const VerificationMeta(
    'erroDetalhe',
  );
  late final GeneratedColumn<String> erroDetalhe = GeneratedColumn<String>(
    'erro_detalhe',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ultimaSeq,
    ultimoHash,
    ultimoEm,
    formatoVersao,
    tamanhoBytes,
    resultado,
    erroDetalhe,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'backup_estado';
  @override
  VerificationContext validateIntegrity(
    Insertable<BackupEstado> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ultima_seq')) {
      context.handle(
        _ultimaSeqMeta,
        ultimaSeq.isAcceptableOrUnknown(data['ultima_seq']!, _ultimaSeqMeta),
      );
    }
    if (data.containsKey('ultimo_hash')) {
      context.handle(
        _ultimoHashMeta,
        ultimoHash.isAcceptableOrUnknown(data['ultimo_hash']!, _ultimoHashMeta),
      );
    }
    if (data.containsKey('ultimo_em')) {
      context.handle(
        _ultimoEmMeta,
        ultimoEm.isAcceptableOrUnknown(data['ultimo_em']!, _ultimoEmMeta),
      );
    }
    if (data.containsKey('formato_versao')) {
      context.handle(
        _formatoVersaoMeta,
        formatoVersao.isAcceptableOrUnknown(
          data['formato_versao']!,
          _formatoVersaoMeta,
        ),
      );
    }
    if (data.containsKey('tamanho_bytes')) {
      context.handle(
        _tamanhoBytesMeta,
        tamanhoBytes.isAcceptableOrUnknown(
          data['tamanho_bytes']!,
          _tamanhoBytesMeta,
        ),
      );
    }
    if (data.containsKey('resultado')) {
      context.handle(
        _resultadoMeta,
        resultado.isAcceptableOrUnknown(data['resultado']!, _resultadoMeta),
      );
    }
    if (data.containsKey('erro_detalhe')) {
      context.handle(
        _erroDetalheMeta,
        erroDetalhe.isAcceptableOrUnknown(
          data['erro_detalhe']!,
          _erroDetalheMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BackupEstado map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BackupEstado(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      ultimaSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ultima_seq'],
      ),
      ultimoHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ultimo_hash'],
      ),
      ultimoEm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ultimo_em'],
      ),
      formatoVersao: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}formato_versao'],
      ),
      tamanhoBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tamanho_bytes'],
      ),
      resultado: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resultado'],
      ),
      erroDetalhe: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}erro_detalhe'],
      ),
    );
  }

  @override
  BackupEstadoTable createAlias(String alias) {
    return BackupEstadoTable(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class BackupEstado extends DataClass implements Insertable<BackupEstado> {
  final int id;
  final int? ultimaSeq;
  final String? ultimoHash;
  final int? ultimoEm;
  final int? formatoVersao;
  final int? tamanhoBytes;
  final String? resultado;
  final String? erroDetalhe;
  const BackupEstado({
    required this.id,
    this.ultimaSeq,
    this.ultimoHash,
    this.ultimoEm,
    this.formatoVersao,
    this.tamanhoBytes,
    this.resultado,
    this.erroDetalhe,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || ultimaSeq != null) {
      map['ultima_seq'] = Variable<int>(ultimaSeq);
    }
    if (!nullToAbsent || ultimoHash != null) {
      map['ultimo_hash'] = Variable<String>(ultimoHash);
    }
    if (!nullToAbsent || ultimoEm != null) {
      map['ultimo_em'] = Variable<int>(ultimoEm);
    }
    if (!nullToAbsent || formatoVersao != null) {
      map['formato_versao'] = Variable<int>(formatoVersao);
    }
    if (!nullToAbsent || tamanhoBytes != null) {
      map['tamanho_bytes'] = Variable<int>(tamanhoBytes);
    }
    if (!nullToAbsent || resultado != null) {
      map['resultado'] = Variable<String>(resultado);
    }
    if (!nullToAbsent || erroDetalhe != null) {
      map['erro_detalhe'] = Variable<String>(erroDetalhe);
    }
    return map;
  }

  BackupEstadoCompanion toCompanion(bool nullToAbsent) {
    return BackupEstadoCompanion(
      id: Value(id),
      ultimaSeq: ultimaSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(ultimaSeq),
      ultimoHash: ultimoHash == null && nullToAbsent
          ? const Value.absent()
          : Value(ultimoHash),
      ultimoEm: ultimoEm == null && nullToAbsent
          ? const Value.absent()
          : Value(ultimoEm),
      formatoVersao: formatoVersao == null && nullToAbsent
          ? const Value.absent()
          : Value(formatoVersao),
      tamanhoBytes: tamanhoBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(tamanhoBytes),
      resultado: resultado == null && nullToAbsent
          ? const Value.absent()
          : Value(resultado),
      erroDetalhe: erroDetalhe == null && nullToAbsent
          ? const Value.absent()
          : Value(erroDetalhe),
    );
  }

  factory BackupEstado.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BackupEstado(
      id: serializer.fromJson<int>(json['id']),
      ultimaSeq: serializer.fromJson<int?>(json['ultima_seq']),
      ultimoHash: serializer.fromJson<String?>(json['ultimo_hash']),
      ultimoEm: serializer.fromJson<int?>(json['ultimo_em']),
      formatoVersao: serializer.fromJson<int?>(json['formato_versao']),
      tamanhoBytes: serializer.fromJson<int?>(json['tamanho_bytes']),
      resultado: serializer.fromJson<String?>(json['resultado']),
      erroDetalhe: serializer.fromJson<String?>(json['erro_detalhe']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ultima_seq': serializer.toJson<int?>(ultimaSeq),
      'ultimo_hash': serializer.toJson<String?>(ultimoHash),
      'ultimo_em': serializer.toJson<int?>(ultimoEm),
      'formato_versao': serializer.toJson<int?>(formatoVersao),
      'tamanho_bytes': serializer.toJson<int?>(tamanhoBytes),
      'resultado': serializer.toJson<String?>(resultado),
      'erro_detalhe': serializer.toJson<String?>(erroDetalhe),
    };
  }

  BackupEstado copyWith({
    int? id,
    Value<int?> ultimaSeq = const Value.absent(),
    Value<String?> ultimoHash = const Value.absent(),
    Value<int?> ultimoEm = const Value.absent(),
    Value<int?> formatoVersao = const Value.absent(),
    Value<int?> tamanhoBytes = const Value.absent(),
    Value<String?> resultado = const Value.absent(),
    Value<String?> erroDetalhe = const Value.absent(),
  }) => BackupEstado(
    id: id ?? this.id,
    ultimaSeq: ultimaSeq.present ? ultimaSeq.value : this.ultimaSeq,
    ultimoHash: ultimoHash.present ? ultimoHash.value : this.ultimoHash,
    ultimoEm: ultimoEm.present ? ultimoEm.value : this.ultimoEm,
    formatoVersao: formatoVersao.present
        ? formatoVersao.value
        : this.formatoVersao,
    tamanhoBytes: tamanhoBytes.present ? tamanhoBytes.value : this.tamanhoBytes,
    resultado: resultado.present ? resultado.value : this.resultado,
    erroDetalhe: erroDetalhe.present ? erroDetalhe.value : this.erroDetalhe,
  );
  BackupEstado copyWithCompanion(BackupEstadoCompanion data) {
    return BackupEstado(
      id: data.id.present ? data.id.value : this.id,
      ultimaSeq: data.ultimaSeq.present ? data.ultimaSeq.value : this.ultimaSeq,
      ultimoHash: data.ultimoHash.present
          ? data.ultimoHash.value
          : this.ultimoHash,
      ultimoEm: data.ultimoEm.present ? data.ultimoEm.value : this.ultimoEm,
      formatoVersao: data.formatoVersao.present
          ? data.formatoVersao.value
          : this.formatoVersao,
      tamanhoBytes: data.tamanhoBytes.present
          ? data.tamanhoBytes.value
          : this.tamanhoBytes,
      resultado: data.resultado.present ? data.resultado.value : this.resultado,
      erroDetalhe: data.erroDetalhe.present
          ? data.erroDetalhe.value
          : this.erroDetalhe,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BackupEstado(')
          ..write('id: $id, ')
          ..write('ultimaSeq: $ultimaSeq, ')
          ..write('ultimoHash: $ultimoHash, ')
          ..write('ultimoEm: $ultimoEm, ')
          ..write('formatoVersao: $formatoVersao, ')
          ..write('tamanhoBytes: $tamanhoBytes, ')
          ..write('resultado: $resultado, ')
          ..write('erroDetalhe: $erroDetalhe')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ultimaSeq,
    ultimoHash,
    ultimoEm,
    formatoVersao,
    tamanhoBytes,
    resultado,
    erroDetalhe,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BackupEstado &&
          other.id == this.id &&
          other.ultimaSeq == this.ultimaSeq &&
          other.ultimoHash == this.ultimoHash &&
          other.ultimoEm == this.ultimoEm &&
          other.formatoVersao == this.formatoVersao &&
          other.tamanhoBytes == this.tamanhoBytes &&
          other.resultado == this.resultado &&
          other.erroDetalhe == this.erroDetalhe);
}

class BackupEstadoCompanion extends UpdateCompanion<BackupEstado> {
  final Value<int> id;
  final Value<int?> ultimaSeq;
  final Value<String?> ultimoHash;
  final Value<int?> ultimoEm;
  final Value<int?> formatoVersao;
  final Value<int?> tamanhoBytes;
  final Value<String?> resultado;
  final Value<String?> erroDetalhe;
  const BackupEstadoCompanion({
    this.id = const Value.absent(),
    this.ultimaSeq = const Value.absent(),
    this.ultimoHash = const Value.absent(),
    this.ultimoEm = const Value.absent(),
    this.formatoVersao = const Value.absent(),
    this.tamanhoBytes = const Value.absent(),
    this.resultado = const Value.absent(),
    this.erroDetalhe = const Value.absent(),
  });
  BackupEstadoCompanion.insert({
    this.id = const Value.absent(),
    this.ultimaSeq = const Value.absent(),
    this.ultimoHash = const Value.absent(),
    this.ultimoEm = const Value.absent(),
    this.formatoVersao = const Value.absent(),
    this.tamanhoBytes = const Value.absent(),
    this.resultado = const Value.absent(),
    this.erroDetalhe = const Value.absent(),
  });
  static Insertable<BackupEstado> custom({
    Expression<int>? id,
    Expression<int>? ultimaSeq,
    Expression<String>? ultimoHash,
    Expression<int>? ultimoEm,
    Expression<int>? formatoVersao,
    Expression<int>? tamanhoBytes,
    Expression<String>? resultado,
    Expression<String>? erroDetalhe,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ultimaSeq != null) 'ultima_seq': ultimaSeq,
      if (ultimoHash != null) 'ultimo_hash': ultimoHash,
      if (ultimoEm != null) 'ultimo_em': ultimoEm,
      if (formatoVersao != null) 'formato_versao': formatoVersao,
      if (tamanhoBytes != null) 'tamanho_bytes': tamanhoBytes,
      if (resultado != null) 'resultado': resultado,
      if (erroDetalhe != null) 'erro_detalhe': erroDetalhe,
    });
  }

  BackupEstadoCompanion copyWith({
    Value<int>? id,
    Value<int?>? ultimaSeq,
    Value<String?>? ultimoHash,
    Value<int?>? ultimoEm,
    Value<int?>? formatoVersao,
    Value<int?>? tamanhoBytes,
    Value<String?>? resultado,
    Value<String?>? erroDetalhe,
  }) {
    return BackupEstadoCompanion(
      id: id ?? this.id,
      ultimaSeq: ultimaSeq ?? this.ultimaSeq,
      ultimoHash: ultimoHash ?? this.ultimoHash,
      ultimoEm: ultimoEm ?? this.ultimoEm,
      formatoVersao: formatoVersao ?? this.formatoVersao,
      tamanhoBytes: tamanhoBytes ?? this.tamanhoBytes,
      resultado: resultado ?? this.resultado,
      erroDetalhe: erroDetalhe ?? this.erroDetalhe,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ultimaSeq.present) {
      map['ultima_seq'] = Variable<int>(ultimaSeq.value);
    }
    if (ultimoHash.present) {
      map['ultimo_hash'] = Variable<String>(ultimoHash.value);
    }
    if (ultimoEm.present) {
      map['ultimo_em'] = Variable<int>(ultimoEm.value);
    }
    if (formatoVersao.present) {
      map['formato_versao'] = Variable<int>(formatoVersao.value);
    }
    if (tamanhoBytes.present) {
      map['tamanho_bytes'] = Variable<int>(tamanhoBytes.value);
    }
    if (resultado.present) {
      map['resultado'] = Variable<String>(resultado.value);
    }
    if (erroDetalhe.present) {
      map['erro_detalhe'] = Variable<String>(erroDetalhe.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BackupEstadoCompanion(')
          ..write('id: $id, ')
          ..write('ultimaSeq: $ultimaSeq, ')
          ..write('ultimoHash: $ultimoHash, ')
          ..write('ultimoEm: $ultimoEm, ')
          ..write('formatoVersao: $formatoVersao, ')
          ..write('tamanhoBytes: $tamanhoBytes, ')
          ..write('resultado: $resultado, ')
          ..write('erroDetalhe: $erroDetalhe')
          ..write(')'))
        .toString();
  }
}

class EnviosSuporte extends Table with TableInfo<EnviosSuporte, EnvioSuporte> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  EnviosSuporte(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _arquivoNomeMeta = const VerificationMeta(
    'arquivoNome',
  );
  late final GeneratedColumn<String> arquivoNome = GeneratedColumn<String>(
    'arquivo_nome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _motivoMeta = const VerificationMeta('motivo');
  late final GeneratedColumn<String> motivo = GeneratedColumn<String>(
    'motivo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _consentimentoEmMeta = const VerificationMeta(
    'consentimentoEm',
  );
  late final GeneratedColumn<int> consentimentoEm = GeneratedColumn<int>(
    'consentimento_em',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _enviadoEmMeta = const VerificationMeta(
    'enviadoEm',
  );
  late final GeneratedColumn<int> enviadoEm = GeneratedColumn<int>(
    'enviado_em',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _pathRemotoMeta = const VerificationMeta(
    'pathRemoto',
  );
  late final GeneratedColumn<String> pathRemoto = GeneratedColumn<String>(
    'path_remoto',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _expiraEmMeta = const VerificationMeta(
    'expiraEm',
  );
  late final GeneratedColumn<int> expiraEm = GeneratedColumn<int>(
    'expira_em',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    arquivoNome,
    motivo,
    consentimentoEm,
    enviadoEm,
    pathRemoto,
    expiraEm,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'envios_suporte';
  @override
  VerificationContext validateIntegrity(
    Insertable<EnvioSuporte> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('arquivo_nome')) {
      context.handle(
        _arquivoNomeMeta,
        arquivoNome.isAcceptableOrUnknown(
          data['arquivo_nome']!,
          _arquivoNomeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_arquivoNomeMeta);
    }
    if (data.containsKey('motivo')) {
      context.handle(
        _motivoMeta,
        motivo.isAcceptableOrUnknown(data['motivo']!, _motivoMeta),
      );
    } else if (isInserting) {
      context.missing(_motivoMeta);
    }
    if (data.containsKey('consentimento_em')) {
      context.handle(
        _consentimentoEmMeta,
        consentimentoEm.isAcceptableOrUnknown(
          data['consentimento_em']!,
          _consentimentoEmMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_consentimentoEmMeta);
    }
    if (data.containsKey('enviado_em')) {
      context.handle(
        _enviadoEmMeta,
        enviadoEm.isAcceptableOrUnknown(data['enviado_em']!, _enviadoEmMeta),
      );
    }
    if (data.containsKey('path_remoto')) {
      context.handle(
        _pathRemotoMeta,
        pathRemoto.isAcceptableOrUnknown(data['path_remoto']!, _pathRemotoMeta),
      );
    }
    if (data.containsKey('expira_em')) {
      context.handle(
        _expiraEmMeta,
        expiraEm.isAcceptableOrUnknown(data['expira_em']!, _expiraEmMeta),
      );
    } else if (isInserting) {
      context.missing(_expiraEmMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EnvioSuporte map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EnvioSuporte(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      arquivoNome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}arquivo_nome'],
      )!,
      motivo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}motivo'],
      )!,
      consentimentoEm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}consentimento_em'],
      )!,
      enviadoEm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}enviado_em'],
      ),
      pathRemoto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path_remoto'],
      ),
      expiraEm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expira_em'],
      )!,
    );
  }

  @override
  EnviosSuporte createAlias(String alias) {
    return EnviosSuporte(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class EnvioSuporte extends DataClass implements Insertable<EnvioSuporte> {
  /// bucket é write-only: o registro vive aqui
  final String id;
  final String arquivoNome;
  final String motivo;
  final int consentimentoEm;
  final int? enviadoEm;
  final String? pathRemoto;
  final int expiraEm;
  const EnvioSuporte({
    required this.id,
    required this.arquivoNome,
    required this.motivo,
    required this.consentimentoEm,
    this.enviadoEm,
    this.pathRemoto,
    required this.expiraEm,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['arquivo_nome'] = Variable<String>(arquivoNome);
    map['motivo'] = Variable<String>(motivo);
    map['consentimento_em'] = Variable<int>(consentimentoEm);
    if (!nullToAbsent || enviadoEm != null) {
      map['enviado_em'] = Variable<int>(enviadoEm);
    }
    if (!nullToAbsent || pathRemoto != null) {
      map['path_remoto'] = Variable<String>(pathRemoto);
    }
    map['expira_em'] = Variable<int>(expiraEm);
    return map;
  }

  EnviosSuporteCompanion toCompanion(bool nullToAbsent) {
    return EnviosSuporteCompanion(
      id: Value(id),
      arquivoNome: Value(arquivoNome),
      motivo: Value(motivo),
      consentimentoEm: Value(consentimentoEm),
      enviadoEm: enviadoEm == null && nullToAbsent
          ? const Value.absent()
          : Value(enviadoEm),
      pathRemoto: pathRemoto == null && nullToAbsent
          ? const Value.absent()
          : Value(pathRemoto),
      expiraEm: Value(expiraEm),
    );
  }

  factory EnvioSuporte.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EnvioSuporte(
      id: serializer.fromJson<String>(json['id']),
      arquivoNome: serializer.fromJson<String>(json['arquivo_nome']),
      motivo: serializer.fromJson<String>(json['motivo']),
      consentimentoEm: serializer.fromJson<int>(json['consentimento_em']),
      enviadoEm: serializer.fromJson<int?>(json['enviado_em']),
      pathRemoto: serializer.fromJson<String?>(json['path_remoto']),
      expiraEm: serializer.fromJson<int>(json['expira_em']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'arquivo_nome': serializer.toJson<String>(arquivoNome),
      'motivo': serializer.toJson<String>(motivo),
      'consentimento_em': serializer.toJson<int>(consentimentoEm),
      'enviado_em': serializer.toJson<int?>(enviadoEm),
      'path_remoto': serializer.toJson<String?>(pathRemoto),
      'expira_em': serializer.toJson<int>(expiraEm),
    };
  }

  EnvioSuporte copyWith({
    String? id,
    String? arquivoNome,
    String? motivo,
    int? consentimentoEm,
    Value<int?> enviadoEm = const Value.absent(),
    Value<String?> pathRemoto = const Value.absent(),
    int? expiraEm,
  }) => EnvioSuporte(
    id: id ?? this.id,
    arquivoNome: arquivoNome ?? this.arquivoNome,
    motivo: motivo ?? this.motivo,
    consentimentoEm: consentimentoEm ?? this.consentimentoEm,
    enviadoEm: enviadoEm.present ? enviadoEm.value : this.enviadoEm,
    pathRemoto: pathRemoto.present ? pathRemoto.value : this.pathRemoto,
    expiraEm: expiraEm ?? this.expiraEm,
  );
  EnvioSuporte copyWithCompanion(EnviosSuporteCompanion data) {
    return EnvioSuporte(
      id: data.id.present ? data.id.value : this.id,
      arquivoNome: data.arquivoNome.present
          ? data.arquivoNome.value
          : this.arquivoNome,
      motivo: data.motivo.present ? data.motivo.value : this.motivo,
      consentimentoEm: data.consentimentoEm.present
          ? data.consentimentoEm.value
          : this.consentimentoEm,
      enviadoEm: data.enviadoEm.present ? data.enviadoEm.value : this.enviadoEm,
      pathRemoto: data.pathRemoto.present
          ? data.pathRemoto.value
          : this.pathRemoto,
      expiraEm: data.expiraEm.present ? data.expiraEm.value : this.expiraEm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EnvioSuporte(')
          ..write('id: $id, ')
          ..write('arquivoNome: $arquivoNome, ')
          ..write('motivo: $motivo, ')
          ..write('consentimentoEm: $consentimentoEm, ')
          ..write('enviadoEm: $enviadoEm, ')
          ..write('pathRemoto: $pathRemoto, ')
          ..write('expiraEm: $expiraEm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    arquivoNome,
    motivo,
    consentimentoEm,
    enviadoEm,
    pathRemoto,
    expiraEm,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EnvioSuporte &&
          other.id == this.id &&
          other.arquivoNome == this.arquivoNome &&
          other.motivo == this.motivo &&
          other.consentimentoEm == this.consentimentoEm &&
          other.enviadoEm == this.enviadoEm &&
          other.pathRemoto == this.pathRemoto &&
          other.expiraEm == this.expiraEm);
}

class EnviosSuporteCompanion extends UpdateCompanion<EnvioSuporte> {
  final Value<String> id;
  final Value<String> arquivoNome;
  final Value<String> motivo;
  final Value<int> consentimentoEm;
  final Value<int?> enviadoEm;
  final Value<String?> pathRemoto;
  final Value<int> expiraEm;
  final Value<int> rowid;
  const EnviosSuporteCompanion({
    this.id = const Value.absent(),
    this.arquivoNome = const Value.absent(),
    this.motivo = const Value.absent(),
    this.consentimentoEm = const Value.absent(),
    this.enviadoEm = const Value.absent(),
    this.pathRemoto = const Value.absent(),
    this.expiraEm = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EnviosSuporteCompanion.insert({
    required String id,
    required String arquivoNome,
    required String motivo,
    required int consentimentoEm,
    this.enviadoEm = const Value.absent(),
    this.pathRemoto = const Value.absent(),
    required int expiraEm,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       arquivoNome = Value(arquivoNome),
       motivo = Value(motivo),
       consentimentoEm = Value(consentimentoEm),
       expiraEm = Value(expiraEm);
  static Insertable<EnvioSuporte> custom({
    Expression<String>? id,
    Expression<String>? arquivoNome,
    Expression<String>? motivo,
    Expression<int>? consentimentoEm,
    Expression<int>? enviadoEm,
    Expression<String>? pathRemoto,
    Expression<int>? expiraEm,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (arquivoNome != null) 'arquivo_nome': arquivoNome,
      if (motivo != null) 'motivo': motivo,
      if (consentimentoEm != null) 'consentimento_em': consentimentoEm,
      if (enviadoEm != null) 'enviado_em': enviadoEm,
      if (pathRemoto != null) 'path_remoto': pathRemoto,
      if (expiraEm != null) 'expira_em': expiraEm,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EnviosSuporteCompanion copyWith({
    Value<String>? id,
    Value<String>? arquivoNome,
    Value<String>? motivo,
    Value<int>? consentimentoEm,
    Value<int?>? enviadoEm,
    Value<String?>? pathRemoto,
    Value<int>? expiraEm,
    Value<int>? rowid,
  }) {
    return EnviosSuporteCompanion(
      id: id ?? this.id,
      arquivoNome: arquivoNome ?? this.arquivoNome,
      motivo: motivo ?? this.motivo,
      consentimentoEm: consentimentoEm ?? this.consentimentoEm,
      enviadoEm: enviadoEm ?? this.enviadoEm,
      pathRemoto: pathRemoto ?? this.pathRemoto,
      expiraEm: expiraEm ?? this.expiraEm,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (arquivoNome.present) {
      map['arquivo_nome'] = Variable<String>(arquivoNome.value);
    }
    if (motivo.present) {
      map['motivo'] = Variable<String>(motivo.value);
    }
    if (consentimentoEm.present) {
      map['consentimento_em'] = Variable<int>(consentimentoEm.value);
    }
    if (enviadoEm.present) {
      map['enviado_em'] = Variable<int>(enviadoEm.value);
    }
    if (pathRemoto.present) {
      map['path_remoto'] = Variable<String>(pathRemoto.value);
    }
    if (expiraEm.present) {
      map['expira_em'] = Variable<int>(expiraEm.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EnviosSuporteCompanion(')
          ..write('id: $id, ')
          ..write('arquivoNome: $arquivoNome, ')
          ..write('motivo: $motivo, ')
          ..write('consentimentoEm: $consentimentoEm, ')
          ..write('enviadoEm: $enviadoEm, ')
          ..write('pathRemoto: $pathRemoto, ')
          ..write('expiraEm: $expiraEm, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class AuditoriaTable extends Table with TableInfo<AuditoriaTable, Auditoria> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  AuditoriaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT',
  );
  static const VerificationMeta _entidadeMeta = const VerificationMeta(
    'entidade',
  );
  late final GeneratedColumn<String> entidade = GeneratedColumn<String>(
    'entidade',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _entidadeIdMeta = const VerificationMeta(
    'entidadeId',
  );
  late final GeneratedColumn<String> entidadeId = GeneratedColumn<String>(
    'entidade_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _acaoMeta = const VerificationMeta('acao');
  late final GeneratedColumn<String> acao = GeneratedColumn<String>(
    'acao',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (acao IN (\'criar\', \'atualizar\', \'excluir\', \'recalcular\'))',
  );
  static const VerificationMeta _detalheMeta = const VerificationMeta(
    'detalhe',
  );
  late final GeneratedColumn<String> detalhe = GeneratedColumn<String>(
    'detalhe',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _criadoEmMeta = const VerificationMeta(
    'criadoEm',
  );
  late final GeneratedColumn<int> criadoEm = GeneratedColumn<int>(
    'criado_em',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entidade,
    entidadeId,
    acao,
    detalhe,
    criadoEm,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'auditoria';
  @override
  VerificationContext validateIntegrity(
    Insertable<Auditoria> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entidade')) {
      context.handle(
        _entidadeMeta,
        entidade.isAcceptableOrUnknown(data['entidade']!, _entidadeMeta),
      );
    } else if (isInserting) {
      context.missing(_entidadeMeta);
    }
    if (data.containsKey('entidade_id')) {
      context.handle(
        _entidadeIdMeta,
        entidadeId.isAcceptableOrUnknown(data['entidade_id']!, _entidadeIdMeta),
      );
    }
    if (data.containsKey('acao')) {
      context.handle(
        _acaoMeta,
        acao.isAcceptableOrUnknown(data['acao']!, _acaoMeta),
      );
    } else if (isInserting) {
      context.missing(_acaoMeta);
    }
    if (data.containsKey('detalhe')) {
      context.handle(
        _detalheMeta,
        detalhe.isAcceptableOrUnknown(data['detalhe']!, _detalheMeta),
      );
    }
    if (data.containsKey('criado_em')) {
      context.handle(
        _criadoEmMeta,
        criadoEm.isAcceptableOrUnknown(data['criado_em']!, _criadoEmMeta),
      );
    } else if (isInserting) {
      context.missing(_criadoEmMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Auditoria map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Auditoria(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      entidade: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entidade'],
      )!,
      entidadeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entidade_id'],
      ),
      acao: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}acao'],
      )!,
      detalhe: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detalhe'],
      ),
      criadoEm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}criado_em'],
      )!,
    );
  }

  @override
  AuditoriaTable createAlias(String alias) {
    return AuditoriaTable(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Auditoria extends DataClass implements Insertable<Auditoria> {
  final int id;
  final String entidade;
  final String? entidadeId;
  final String acao;
  final String? detalhe;

  /// JSON
  final int criadoEm;
  const Auditoria({
    required this.id,
    required this.entidade,
    this.entidadeId,
    required this.acao,
    this.detalhe,
    required this.criadoEm,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entidade'] = Variable<String>(entidade);
    if (!nullToAbsent || entidadeId != null) {
      map['entidade_id'] = Variable<String>(entidadeId);
    }
    map['acao'] = Variable<String>(acao);
    if (!nullToAbsent || detalhe != null) {
      map['detalhe'] = Variable<String>(detalhe);
    }
    map['criado_em'] = Variable<int>(criadoEm);
    return map;
  }

  AuditoriaCompanion toCompanion(bool nullToAbsent) {
    return AuditoriaCompanion(
      id: Value(id),
      entidade: Value(entidade),
      entidadeId: entidadeId == null && nullToAbsent
          ? const Value.absent()
          : Value(entidadeId),
      acao: Value(acao),
      detalhe: detalhe == null && nullToAbsent
          ? const Value.absent()
          : Value(detalhe),
      criadoEm: Value(criadoEm),
    );
  }

  factory Auditoria.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Auditoria(
      id: serializer.fromJson<int>(json['id']),
      entidade: serializer.fromJson<String>(json['entidade']),
      entidadeId: serializer.fromJson<String?>(json['entidade_id']),
      acao: serializer.fromJson<String>(json['acao']),
      detalhe: serializer.fromJson<String?>(json['detalhe']),
      criadoEm: serializer.fromJson<int>(json['criado_em']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entidade': serializer.toJson<String>(entidade),
      'entidade_id': serializer.toJson<String?>(entidadeId),
      'acao': serializer.toJson<String>(acao),
      'detalhe': serializer.toJson<String?>(detalhe),
      'criado_em': serializer.toJson<int>(criadoEm),
    };
  }

  Auditoria copyWith({
    int? id,
    String? entidade,
    Value<String?> entidadeId = const Value.absent(),
    String? acao,
    Value<String?> detalhe = const Value.absent(),
    int? criadoEm,
  }) => Auditoria(
    id: id ?? this.id,
    entidade: entidade ?? this.entidade,
    entidadeId: entidadeId.present ? entidadeId.value : this.entidadeId,
    acao: acao ?? this.acao,
    detalhe: detalhe.present ? detalhe.value : this.detalhe,
    criadoEm: criadoEm ?? this.criadoEm,
  );
  Auditoria copyWithCompanion(AuditoriaCompanion data) {
    return Auditoria(
      id: data.id.present ? data.id.value : this.id,
      entidade: data.entidade.present ? data.entidade.value : this.entidade,
      entidadeId: data.entidadeId.present
          ? data.entidadeId.value
          : this.entidadeId,
      acao: data.acao.present ? data.acao.value : this.acao,
      detalhe: data.detalhe.present ? data.detalhe.value : this.detalhe,
      criadoEm: data.criadoEm.present ? data.criadoEm.value : this.criadoEm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Auditoria(')
          ..write('id: $id, ')
          ..write('entidade: $entidade, ')
          ..write('entidadeId: $entidadeId, ')
          ..write('acao: $acao, ')
          ..write('detalhe: $detalhe, ')
          ..write('criadoEm: $criadoEm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, entidade, entidadeId, acao, detalhe, criadoEm);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Auditoria &&
          other.id == this.id &&
          other.entidade == this.entidade &&
          other.entidadeId == this.entidadeId &&
          other.acao == this.acao &&
          other.detalhe == this.detalhe &&
          other.criadoEm == this.criadoEm);
}

class AuditoriaCompanion extends UpdateCompanion<Auditoria> {
  final Value<int> id;
  final Value<String> entidade;
  final Value<String?> entidadeId;
  final Value<String> acao;
  final Value<String?> detalhe;
  final Value<int> criadoEm;
  const AuditoriaCompanion({
    this.id = const Value.absent(),
    this.entidade = const Value.absent(),
    this.entidadeId = const Value.absent(),
    this.acao = const Value.absent(),
    this.detalhe = const Value.absent(),
    this.criadoEm = const Value.absent(),
  });
  AuditoriaCompanion.insert({
    this.id = const Value.absent(),
    required String entidade,
    this.entidadeId = const Value.absent(),
    required String acao,
    this.detalhe = const Value.absent(),
    required int criadoEm,
  }) : entidade = Value(entidade),
       acao = Value(acao),
       criadoEm = Value(criadoEm);
  static Insertable<Auditoria> custom({
    Expression<int>? id,
    Expression<String>? entidade,
    Expression<String>? entidadeId,
    Expression<String>? acao,
    Expression<String>? detalhe,
    Expression<int>? criadoEm,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entidade != null) 'entidade': entidade,
      if (entidadeId != null) 'entidade_id': entidadeId,
      if (acao != null) 'acao': acao,
      if (detalhe != null) 'detalhe': detalhe,
      if (criadoEm != null) 'criado_em': criadoEm,
    });
  }

  AuditoriaCompanion copyWith({
    Value<int>? id,
    Value<String>? entidade,
    Value<String?>? entidadeId,
    Value<String>? acao,
    Value<String?>? detalhe,
    Value<int>? criadoEm,
  }) {
    return AuditoriaCompanion(
      id: id ?? this.id,
      entidade: entidade ?? this.entidade,
      entidadeId: entidadeId ?? this.entidadeId,
      acao: acao ?? this.acao,
      detalhe: detalhe ?? this.detalhe,
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entidade.present) {
      map['entidade'] = Variable<String>(entidade.value);
    }
    if (entidadeId.present) {
      map['entidade_id'] = Variable<String>(entidadeId.value);
    }
    if (acao.present) {
      map['acao'] = Variable<String>(acao.value);
    }
    if (detalhe.present) {
      map['detalhe'] = Variable<String>(detalhe.value);
    }
    if (criadoEm.present) {
      map['criado_em'] = Variable<int>(criadoEm.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditoriaCompanion(')
          ..write('id: $id, ')
          ..write('entidade: $entidade, ')
          ..write('entidadeId: $entidadeId, ')
          ..write('acao: $acao, ')
          ..write('detalhe: $detalhe, ')
          ..write('criadoEm: $criadoEm')
          ..write(')'))
        .toString();
  }
}

abstract class _$BancoLocal extends GeneratedDatabase {
  _$BancoLocal(QueryExecutor e) : super(e);
  $BancoLocalManager get managers => $BancoLocalManager(this);
  late final CatVersoes catVersoes = CatVersoes(this);
  late final CatTabelasIrpf catTabelasIrpf = CatTabelasIrpf(this);
  late final CatFaixasIrpf catFaixasIrpf = CatFaixasIrpf(this);
  late final CatParametrosFiscais catParametrosFiscais = CatParametrosFiscais(
    this,
  );
  late final CatFeriadosBancarios catFeriadosBancarios = CatFeriadosBancarios(
    this,
  );
  late final CatRubricas catRubricas = CatRubricas(this);
  late final CatProfissoes catProfissoes = CatProfissoes(this);
  late final CatPerfisParser catPerfisParser = CatPerfisParser(this);
  late final Perfil perfil = Perfil(this);
  late final AceitesTermosLocal aceitesTermosLocal = AceitesTermosLocal(this);
  late final ContasBancarias contasBancarias = ContasBancarias(this);
  late final Importacoes importacoes = Importacoes(this);
  late final Index uqImportacaoHash = Index(
    'uq_importacao_hash',
    'CREATE UNIQUE INDEX uq_importacao_hash ON importacoes (hash_arquivo) WHERE status = \'confirmada\'',
  );
  late final Transacoes transacoes = Transacoes(this);
  late final Index idxTransacoesFitid = Index(
    'idx_transacoes_fitid',
    'CREATE INDEX idx_transacoes_fitid ON transacoes (conta_id, fitid) WHERE fitid IS NOT NULL',
  );
  late final Index idxTransacoesData = Index(
    'idx_transacoes_data',
    'CREATE INDEX idx_transacoes_data ON transacoes (data)',
  );
  late final Trigger trgTransacoesImutaveis = Trigger(
    'CREATE TRIGGER trg_transacoes_imutaveis BEFORE UPDATE ON transacoes BEGIN SELECT RAISE (ABORT, \'transacao é imutável: reclassifique o lançamento\');END',
    'trg_transacoes_imutaveis',
  );
  late final Remetentes remetentes = Remetentes(this);
  late final Index uqRemetentesCpf = Index(
    'uq_remetentes_cpf',
    'CREATE UNIQUE INDEX uq_remetentes_cpf ON remetentes (cpf) WHERE cpf IS NOT NULL',
  );
  late final ApuracoesMensais apuracoesMensais = ApuracoesMensais(this);
  late final Index uqApuracaoAtiva = Index(
    'uq_apuracao_ativa',
    'CREATE UNIQUE INDEX uq_apuracao_ativa ON apuracoes_mensais (competencia) WHERE status != \'substituida\'',
  );
  late final Lancamentos lancamentos = Lancamentos(this);
  late final Index idxLancamentosComp = Index(
    'idx_lancamentos_comp',
    'CREATE INDEX idx_lancamentos_comp ON lancamentos (competencia)',
  );
  late final HistoricoClassificacaoTable historicoClassificacao =
      HistoricoClassificacaoTable(this);
  late final DespesasLivroCaixa despesasLivroCaixa = DespesasLivroCaixa(this);
  late final Index idxDespesasComp = Index(
    'idx_despesas_comp',
    'CREATE INDEX idx_despesas_comp ON despesas_livro_caixa (competencia)',
  );
  late final PagamentosInss pagamentosInss = PagamentosInss(this);
  late final Dependentes dependentes = Dependentes(this);
  late final Darfs darfs = Darfs(this);
  late final Index idxDarfsVenc = Index(
    'idx_darfs_venc',
    'CREATE INDEX idx_darfs_venc ON darfs (vencimento) WHERE status = \'gerado\'',
  );
  late final NotificacoesLocais notificacoesLocais = NotificacoesLocais(this);
  late final BackupEstadoTable backupEstado = BackupEstadoTable(this);
  late final EnviosSuporte enviosSuporte = EnviosSuporte(this);
  late final AuditoriaTable auditoria = AuditoriaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    catVersoes,
    catTabelasIrpf,
    catFaixasIrpf,
    catParametrosFiscais,
    catFeriadosBancarios,
    catRubricas,
    catProfissoes,
    catPerfisParser,
    perfil,
    aceitesTermosLocal,
    contasBancarias,
    importacoes,
    uqImportacaoHash,
    transacoes,
    idxTransacoesFitid,
    idxTransacoesData,
    trgTransacoesImutaveis,
    remetentes,
    uqRemetentesCpf,
    apuracoesMensais,
    uqApuracaoAtiva,
    lancamentos,
    idxLancamentosComp,
    historicoClassificacao,
    despesasLivroCaixa,
    idxDespesasComp,
    pagamentosInss,
    dependentes,
    darfs,
    idxDarfsVenc,
    notificacoesLocais,
    backupEstado,
    enviosSuporte,
    auditoria,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'transacoes',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [],
    ),
  ]);
}

typedef $CatVersoesCreateCompanionBuilder =
    CatVersoesCompanion Function({
      required String catalogo,
      required int versao,
      required int publicadoEm,
      required int baixadoEm,
      required String hash,
      Value<int> rowid,
    });
typedef $CatVersoesUpdateCompanionBuilder =
    CatVersoesCompanion Function({
      Value<String> catalogo,
      Value<int> versao,
      Value<int> publicadoEm,
      Value<int> baixadoEm,
      Value<String> hash,
      Value<int> rowid,
    });

class $CatVersoesFilterComposer extends Composer<_$BancoLocal, CatVersoes> {
  $CatVersoesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get catalogo => $composableBuilder(
    column: $table.catalogo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get versao => $composableBuilder(
    column: $table.versao,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get publicadoEm => $composableBuilder(
    column: $table.publicadoEm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baixadoEm => $composableBuilder(
    column: $table.baixadoEm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnFilters(column),
  );
}

class $CatVersoesOrderingComposer extends Composer<_$BancoLocal, CatVersoes> {
  $CatVersoesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get catalogo => $composableBuilder(
    column: $table.catalogo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get versao => $composableBuilder(
    column: $table.versao,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get publicadoEm => $composableBuilder(
    column: $table.publicadoEm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baixadoEm => $composableBuilder(
    column: $table.baixadoEm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnOrderings(column),
  );
}

class $CatVersoesAnnotationComposer extends Composer<_$BancoLocal, CatVersoes> {
  $CatVersoesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get catalogo =>
      $composableBuilder(column: $table.catalogo, builder: (column) => column);

  GeneratedColumn<int> get versao =>
      $composableBuilder(column: $table.versao, builder: (column) => column);

  GeneratedColumn<int> get publicadoEm => $composableBuilder(
    column: $table.publicadoEm,
    builder: (column) => column,
  );

  GeneratedColumn<int> get baixadoEm =>
      $composableBuilder(column: $table.baixadoEm, builder: (column) => column);

  GeneratedColumn<String> get hash =>
      $composableBuilder(column: $table.hash, builder: (column) => column);
}

class $CatVersoesTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          CatVersoes,
          CatVersao,
          $CatVersoesFilterComposer,
          $CatVersoesOrderingComposer,
          $CatVersoesAnnotationComposer,
          $CatVersoesCreateCompanionBuilder,
          $CatVersoesUpdateCompanionBuilder,
          (CatVersao, BaseReferences<_$BancoLocal, CatVersoes, CatVersao>),
          CatVersao,
          PrefetchHooks Function()
        > {
  $CatVersoesTableManager(_$BancoLocal db, CatVersoes table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $CatVersoesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $CatVersoesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $CatVersoesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> catalogo = const Value.absent(),
                Value<int> versao = const Value.absent(),
                Value<int> publicadoEm = const Value.absent(),
                Value<int> baixadoEm = const Value.absent(),
                Value<String> hash = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CatVersoesCompanion(
                catalogo: catalogo,
                versao: versao,
                publicadoEm: publicadoEm,
                baixadoEm: baixadoEm,
                hash: hash,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String catalogo,
                required int versao,
                required int publicadoEm,
                required int baixadoEm,
                required String hash,
                Value<int> rowid = const Value.absent(),
              }) => CatVersoesCompanion.insert(
                catalogo: catalogo,
                versao: versao,
                publicadoEm: publicadoEm,
                baixadoEm: baixadoEm,
                hash: hash,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $CatVersoesProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      CatVersoes,
      CatVersao,
      $CatVersoesFilterComposer,
      $CatVersoesOrderingComposer,
      $CatVersoesAnnotationComposer,
      $CatVersoesCreateCompanionBuilder,
      $CatVersoesUpdateCompanionBuilder,
      (CatVersao, BaseReferences<_$BancoLocal, CatVersoes, CatVersao>),
      CatVersao,
      PrefetchHooks Function()
    >;
typedef $CatTabelasIrpfCreateCompanionBuilder =
    CatTabelasIrpfCompanion Function({
      Value<int> id,
      required String vigenciaInicio,
      Value<String?> vigenciaFim,
      required String fonteLegal,
      required int deducaoDependenteCentavos,
    });
typedef $CatTabelasIrpfUpdateCompanionBuilder =
    CatTabelasIrpfCompanion Function({
      Value<int> id,
      Value<String> vigenciaInicio,
      Value<String?> vigenciaFim,
      Value<String> fonteLegal,
      Value<int> deducaoDependenteCentavos,
    });

final class $CatTabelasIrpfReferences
    extends BaseReferences<_$BancoLocal, CatTabelasIrpf, CatTabelaIrpf> {
  $CatTabelasIrpfReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<CatFaixasIrpf, List<CatFaixaIrpf>>
  _catFaixasIrpfRefsTable(_$BancoLocal db) => MultiTypedResultKey.fromTable(
    db.catFaixasIrpf,
    aliasName: 'cat_tabelas_irpf__id__cat_faixas_irpf__tabela_id',
  );

  $CatFaixasIrpfProcessedTableManager get catFaixasIrpfRefs {
    final manager = $CatFaixasIrpfTableManager(
      $_db,
      $_db.catFaixasIrpf,
    ).filter((f) => f.tabelaId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_catFaixasIrpfRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<ApuracoesMensais, List<ApuracaoLocal>>
  _apuracoesMensaisRefsTable(_$BancoLocal db) => MultiTypedResultKey.fromTable(
    db.apuracoesMensais,
    aliasName: 'cat_tabelas_irpf__id__apuracoes_mensais__tabela_irpf_id',
  );

  $ApuracoesMensaisProcessedTableManager get apuracoesMensaisRefs {
    final manager = $ApuracoesMensaisTableManager(
      $_db,
      $_db.apuracoesMensais,
    ).filter((f) => f.tabelaIrpfId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _apuracoesMensaisRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $CatTabelasIrpfFilterComposer
    extends Composer<_$BancoLocal, CatTabelasIrpf> {
  $CatTabelasIrpfFilterComposer({
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

  ColumnFilters<String> get vigenciaInicio => $composableBuilder(
    column: $table.vigenciaInicio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vigenciaFim => $composableBuilder(
    column: $table.vigenciaFim,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fonteLegal => $composableBuilder(
    column: $table.fonteLegal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deducaoDependenteCentavos => $composableBuilder(
    column: $table.deducaoDependenteCentavos,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> catFaixasIrpfRefs(
    Expression<bool> Function($CatFaixasIrpfFilterComposer f) f,
  ) {
    final $CatFaixasIrpfFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.catFaixasIrpf,
      getReferencedColumn: (t) => t.tabelaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CatFaixasIrpfFilterComposer(
            $db: $db,
            $table: $db.catFaixasIrpf,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> apuracoesMensaisRefs(
    Expression<bool> Function($ApuracoesMensaisFilterComposer f) f,
  ) {
    final $ApuracoesMensaisFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.apuracoesMensais,
      getReferencedColumn: (t) => t.tabelaIrpfId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ApuracoesMensaisFilterComposer(
            $db: $db,
            $table: $db.apuracoesMensais,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $CatTabelasIrpfOrderingComposer
    extends Composer<_$BancoLocal, CatTabelasIrpf> {
  $CatTabelasIrpfOrderingComposer({
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

  ColumnOrderings<String> get vigenciaInicio => $composableBuilder(
    column: $table.vigenciaInicio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vigenciaFim => $composableBuilder(
    column: $table.vigenciaFim,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fonteLegal => $composableBuilder(
    column: $table.fonteLegal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deducaoDependenteCentavos => $composableBuilder(
    column: $table.deducaoDependenteCentavos,
    builder: (column) => ColumnOrderings(column),
  );
}

class $CatTabelasIrpfAnnotationComposer
    extends Composer<_$BancoLocal, CatTabelasIrpf> {
  $CatTabelasIrpfAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get vigenciaInicio => $composableBuilder(
    column: $table.vigenciaInicio,
    builder: (column) => column,
  );

  GeneratedColumn<String> get vigenciaFim => $composableBuilder(
    column: $table.vigenciaFim,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fonteLegal => $composableBuilder(
    column: $table.fonteLegal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deducaoDependenteCentavos => $composableBuilder(
    column: $table.deducaoDependenteCentavos,
    builder: (column) => column,
  );

  Expression<T> catFaixasIrpfRefs<T extends Object>(
    Expression<T> Function($CatFaixasIrpfAnnotationComposer a) f,
  ) {
    final $CatFaixasIrpfAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.catFaixasIrpf,
      getReferencedColumn: (t) => t.tabelaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CatFaixasIrpfAnnotationComposer(
            $db: $db,
            $table: $db.catFaixasIrpf,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> apuracoesMensaisRefs<T extends Object>(
    Expression<T> Function($ApuracoesMensaisAnnotationComposer a) f,
  ) {
    final $ApuracoesMensaisAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.apuracoesMensais,
      getReferencedColumn: (t) => t.tabelaIrpfId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ApuracoesMensaisAnnotationComposer(
            $db: $db,
            $table: $db.apuracoesMensais,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $CatTabelasIrpfTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          CatTabelasIrpf,
          CatTabelaIrpf,
          $CatTabelasIrpfFilterComposer,
          $CatTabelasIrpfOrderingComposer,
          $CatTabelasIrpfAnnotationComposer,
          $CatTabelasIrpfCreateCompanionBuilder,
          $CatTabelasIrpfUpdateCompanionBuilder,
          (CatTabelaIrpf, $CatTabelasIrpfReferences),
          CatTabelaIrpf,
          PrefetchHooks Function({
            bool catFaixasIrpfRefs,
            bool apuracoesMensaisRefs,
          })
        > {
  $CatTabelasIrpfTableManager(_$BancoLocal db, CatTabelasIrpf table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $CatTabelasIrpfFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $CatTabelasIrpfOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $CatTabelasIrpfAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> vigenciaInicio = const Value.absent(),
                Value<String?> vigenciaFim = const Value.absent(),
                Value<String> fonteLegal = const Value.absent(),
                Value<int> deducaoDependenteCentavos = const Value.absent(),
              }) => CatTabelasIrpfCompanion(
                id: id,
                vigenciaInicio: vigenciaInicio,
                vigenciaFim: vigenciaFim,
                fonteLegal: fonteLegal,
                deducaoDependenteCentavos: deducaoDependenteCentavos,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String vigenciaInicio,
                Value<String?> vigenciaFim = const Value.absent(),
                required String fonteLegal,
                required int deducaoDependenteCentavos,
              }) => CatTabelasIrpfCompanion.insert(
                id: id,
                vigenciaInicio: vigenciaInicio,
                vigenciaFim: vigenciaFim,
                fonteLegal: fonteLegal,
                deducaoDependenteCentavos: deducaoDependenteCentavos,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $CatTabelasIrpfReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({catFaixasIrpfRefs = false, apuracoesMensaisRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (catFaixasIrpfRefs) db.catFaixasIrpf,
                    if (apuracoesMensaisRefs) db.apuracoesMensais,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (catFaixasIrpfRefs)
                        await $_getPrefetchedData<
                          CatTabelaIrpf,
                          CatTabelasIrpf,
                          CatFaixaIrpf
                        >(
                          currentTable: table,
                          referencedTable: $CatTabelasIrpfReferences
                              ._catFaixasIrpfRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $CatTabelasIrpfReferences(
                                db,
                                table,
                                p0,
                              ).catFaixasIrpfRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.tabelaId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (apuracoesMensaisRefs)
                        await $_getPrefetchedData<
                          CatTabelaIrpf,
                          CatTabelasIrpf,
                          ApuracaoLocal
                        >(
                          currentTable: table,
                          referencedTable: $CatTabelasIrpfReferences
                              ._apuracoesMensaisRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $CatTabelasIrpfReferences(
                                db,
                                table,
                                p0,
                              ).apuracoesMensaisRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.tabelaIrpfId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $CatTabelasIrpfProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      CatTabelasIrpf,
      CatTabelaIrpf,
      $CatTabelasIrpfFilterComposer,
      $CatTabelasIrpfOrderingComposer,
      $CatTabelasIrpfAnnotationComposer,
      $CatTabelasIrpfCreateCompanionBuilder,
      $CatTabelasIrpfUpdateCompanionBuilder,
      (CatTabelaIrpf, $CatTabelasIrpfReferences),
      CatTabelaIrpf,
      PrefetchHooks Function({
        bool catFaixasIrpfRefs,
        bool apuracoesMensaisRefs,
      })
    >;
typedef $CatFaixasIrpfCreateCompanionBuilder =
    CatFaixasIrpfCompanion Function({
      required int tabelaId,
      required int ordem,
      Value<int?> limiteSuperiorCentavos,
      required int aliquotaBp,
      required int parcelaDeduzirCentavos,
      Value<int> rowid,
    });
typedef $CatFaixasIrpfUpdateCompanionBuilder =
    CatFaixasIrpfCompanion Function({
      Value<int> tabelaId,
      Value<int> ordem,
      Value<int?> limiteSuperiorCentavos,
      Value<int> aliquotaBp,
      Value<int> parcelaDeduzirCentavos,
      Value<int> rowid,
    });

final class $CatFaixasIrpfReferences
    extends BaseReferences<_$BancoLocal, CatFaixasIrpf, CatFaixaIrpf> {
  $CatFaixasIrpfReferences(super.$_db, super.$_table, super.$_typedResult);

  static CatTabelasIrpf _tabelaIdTable(_$BancoLocal db) => db.catTabelasIrpf
      .createAlias('cat_faixas_irpf__tabela_id__cat_tabelas_irpf__id');

  $CatTabelasIrpfProcessedTableManager get tabelaId {
    final $_column = $_itemColumn<int>('tabela_id')!;

    final manager = $CatTabelasIrpfTableManager(
      $_db,
      $_db.catTabelasIrpf,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tabelaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $CatFaixasIrpfFilterComposer
    extends Composer<_$BancoLocal, CatFaixasIrpf> {
  $CatFaixasIrpfFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get ordem => $composableBuilder(
    column: $table.ordem,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get limiteSuperiorCentavos => $composableBuilder(
    column: $table.limiteSuperiorCentavos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get aliquotaBp => $composableBuilder(
    column: $table.aliquotaBp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get parcelaDeduzirCentavos => $composableBuilder(
    column: $table.parcelaDeduzirCentavos,
    builder: (column) => ColumnFilters(column),
  );

  $CatTabelasIrpfFilterComposer get tabelaId {
    final $CatTabelasIrpfFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tabelaId,
      referencedTable: $db.catTabelasIrpf,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CatTabelasIrpfFilterComposer(
            $db: $db,
            $table: $db.catTabelasIrpf,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CatFaixasIrpfOrderingComposer
    extends Composer<_$BancoLocal, CatFaixasIrpf> {
  $CatFaixasIrpfOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get ordem => $composableBuilder(
    column: $table.ordem,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get limiteSuperiorCentavos => $composableBuilder(
    column: $table.limiteSuperiorCentavos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get aliquotaBp => $composableBuilder(
    column: $table.aliquotaBp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get parcelaDeduzirCentavos => $composableBuilder(
    column: $table.parcelaDeduzirCentavos,
    builder: (column) => ColumnOrderings(column),
  );

  $CatTabelasIrpfOrderingComposer get tabelaId {
    final $CatTabelasIrpfOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tabelaId,
      referencedTable: $db.catTabelasIrpf,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CatTabelasIrpfOrderingComposer(
            $db: $db,
            $table: $db.catTabelasIrpf,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CatFaixasIrpfAnnotationComposer
    extends Composer<_$BancoLocal, CatFaixasIrpf> {
  $CatFaixasIrpfAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get ordem =>
      $composableBuilder(column: $table.ordem, builder: (column) => column);

  GeneratedColumn<int> get limiteSuperiorCentavos => $composableBuilder(
    column: $table.limiteSuperiorCentavos,
    builder: (column) => column,
  );

  GeneratedColumn<int> get aliquotaBp => $composableBuilder(
    column: $table.aliquotaBp,
    builder: (column) => column,
  );

  GeneratedColumn<int> get parcelaDeduzirCentavos => $composableBuilder(
    column: $table.parcelaDeduzirCentavos,
    builder: (column) => column,
  );

  $CatTabelasIrpfAnnotationComposer get tabelaId {
    final $CatTabelasIrpfAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tabelaId,
      referencedTable: $db.catTabelasIrpf,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CatTabelasIrpfAnnotationComposer(
            $db: $db,
            $table: $db.catTabelasIrpf,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CatFaixasIrpfTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          CatFaixasIrpf,
          CatFaixaIrpf,
          $CatFaixasIrpfFilterComposer,
          $CatFaixasIrpfOrderingComposer,
          $CatFaixasIrpfAnnotationComposer,
          $CatFaixasIrpfCreateCompanionBuilder,
          $CatFaixasIrpfUpdateCompanionBuilder,
          (CatFaixaIrpf, $CatFaixasIrpfReferences),
          CatFaixaIrpf,
          PrefetchHooks Function({bool tabelaId})
        > {
  $CatFaixasIrpfTableManager(_$BancoLocal db, CatFaixasIrpf table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $CatFaixasIrpfFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $CatFaixasIrpfOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $CatFaixasIrpfAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> tabelaId = const Value.absent(),
                Value<int> ordem = const Value.absent(),
                Value<int?> limiteSuperiorCentavos = const Value.absent(),
                Value<int> aliquotaBp = const Value.absent(),
                Value<int> parcelaDeduzirCentavos = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CatFaixasIrpfCompanion(
                tabelaId: tabelaId,
                ordem: ordem,
                limiteSuperiorCentavos: limiteSuperiorCentavos,
                aliquotaBp: aliquotaBp,
                parcelaDeduzirCentavos: parcelaDeduzirCentavos,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int tabelaId,
                required int ordem,
                Value<int?> limiteSuperiorCentavos = const Value.absent(),
                required int aliquotaBp,
                required int parcelaDeduzirCentavos,
                Value<int> rowid = const Value.absent(),
              }) => CatFaixasIrpfCompanion.insert(
                tabelaId: tabelaId,
                ordem: ordem,
                limiteSuperiorCentavos: limiteSuperiorCentavos,
                aliquotaBp: aliquotaBp,
                parcelaDeduzirCentavos: parcelaDeduzirCentavos,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $CatFaixasIrpfReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({tabelaId = false}) {
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
                    if (tabelaId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.tabelaId,
                                referencedTable: $CatFaixasIrpfReferences
                                    ._tabelaIdTable(db),
                                referencedColumn: $CatFaixasIrpfReferences
                                    ._tabelaIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $CatFaixasIrpfProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      CatFaixasIrpf,
      CatFaixaIrpf,
      $CatFaixasIrpfFilterComposer,
      $CatFaixasIrpfOrderingComposer,
      $CatFaixasIrpfAnnotationComposer,
      $CatFaixasIrpfCreateCompanionBuilder,
      $CatFaixasIrpfUpdateCompanionBuilder,
      (CatFaixaIrpf, $CatFaixasIrpfReferences),
      CatFaixaIrpf,
      PrefetchHooks Function({bool tabelaId})
    >;
typedef $CatParametrosFiscaisCreateCompanionBuilder =
    CatParametrosFiscaisCompanion Function({
      required String chave,
      required String vigenciaInicio,
      Value<String?> vigenciaFim,
      required int valor,
      required String unidade,
      required String fonteLegal,
      required String statusValidacao,
      Value<int> rowid,
    });
typedef $CatParametrosFiscaisUpdateCompanionBuilder =
    CatParametrosFiscaisCompanion Function({
      Value<String> chave,
      Value<String> vigenciaInicio,
      Value<String?> vigenciaFim,
      Value<int> valor,
      Value<String> unidade,
      Value<String> fonteLegal,
      Value<String> statusValidacao,
      Value<int> rowid,
    });

class $CatParametrosFiscaisFilterComposer
    extends Composer<_$BancoLocal, CatParametrosFiscais> {
  $CatParametrosFiscaisFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get chave => $composableBuilder(
    column: $table.chave,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vigenciaInicio => $composableBuilder(
    column: $table.vigenciaInicio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vigenciaFim => $composableBuilder(
    column: $table.vigenciaFim,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get valor => $composableBuilder(
    column: $table.valor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unidade => $composableBuilder(
    column: $table.unidade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fonteLegal => $composableBuilder(
    column: $table.fonteLegal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get statusValidacao => $composableBuilder(
    column: $table.statusValidacao,
    builder: (column) => ColumnFilters(column),
  );
}

class $CatParametrosFiscaisOrderingComposer
    extends Composer<_$BancoLocal, CatParametrosFiscais> {
  $CatParametrosFiscaisOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get chave => $composableBuilder(
    column: $table.chave,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vigenciaInicio => $composableBuilder(
    column: $table.vigenciaInicio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vigenciaFim => $composableBuilder(
    column: $table.vigenciaFim,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get valor => $composableBuilder(
    column: $table.valor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unidade => $composableBuilder(
    column: $table.unidade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fonteLegal => $composableBuilder(
    column: $table.fonteLegal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statusValidacao => $composableBuilder(
    column: $table.statusValidacao,
    builder: (column) => ColumnOrderings(column),
  );
}

class $CatParametrosFiscaisAnnotationComposer
    extends Composer<_$BancoLocal, CatParametrosFiscais> {
  $CatParametrosFiscaisAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get chave =>
      $composableBuilder(column: $table.chave, builder: (column) => column);

  GeneratedColumn<String> get vigenciaInicio => $composableBuilder(
    column: $table.vigenciaInicio,
    builder: (column) => column,
  );

  GeneratedColumn<String> get vigenciaFim => $composableBuilder(
    column: $table.vigenciaFim,
    builder: (column) => column,
  );

  GeneratedColumn<int> get valor =>
      $composableBuilder(column: $table.valor, builder: (column) => column);

  GeneratedColumn<String> get unidade =>
      $composableBuilder(column: $table.unidade, builder: (column) => column);

  GeneratedColumn<String> get fonteLegal => $composableBuilder(
    column: $table.fonteLegal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get statusValidacao => $composableBuilder(
    column: $table.statusValidacao,
    builder: (column) => column,
  );
}

class $CatParametrosFiscaisTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          CatParametrosFiscais,
          CatParametroFiscal,
          $CatParametrosFiscaisFilterComposer,
          $CatParametrosFiscaisOrderingComposer,
          $CatParametrosFiscaisAnnotationComposer,
          $CatParametrosFiscaisCreateCompanionBuilder,
          $CatParametrosFiscaisUpdateCompanionBuilder,
          (
            CatParametroFiscal,
            BaseReferences<
              _$BancoLocal,
              CatParametrosFiscais,
              CatParametroFiscal
            >,
          ),
          CatParametroFiscal,
          PrefetchHooks Function()
        > {
  $CatParametrosFiscaisTableManager(_$BancoLocal db, CatParametrosFiscais table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $CatParametrosFiscaisFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $CatParametrosFiscaisOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $CatParametrosFiscaisAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> chave = const Value.absent(),
                Value<String> vigenciaInicio = const Value.absent(),
                Value<String?> vigenciaFim = const Value.absent(),
                Value<int> valor = const Value.absent(),
                Value<String> unidade = const Value.absent(),
                Value<String> fonteLegal = const Value.absent(),
                Value<String> statusValidacao = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CatParametrosFiscaisCompanion(
                chave: chave,
                vigenciaInicio: vigenciaInicio,
                vigenciaFim: vigenciaFim,
                valor: valor,
                unidade: unidade,
                fonteLegal: fonteLegal,
                statusValidacao: statusValidacao,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String chave,
                required String vigenciaInicio,
                Value<String?> vigenciaFim = const Value.absent(),
                required int valor,
                required String unidade,
                required String fonteLegal,
                required String statusValidacao,
                Value<int> rowid = const Value.absent(),
              }) => CatParametrosFiscaisCompanion.insert(
                chave: chave,
                vigenciaInicio: vigenciaInicio,
                vigenciaFim: vigenciaFim,
                valor: valor,
                unidade: unidade,
                fonteLegal: fonteLegal,
                statusValidacao: statusValidacao,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $CatParametrosFiscaisProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      CatParametrosFiscais,
      CatParametroFiscal,
      $CatParametrosFiscaisFilterComposer,
      $CatParametrosFiscaisOrderingComposer,
      $CatParametrosFiscaisAnnotationComposer,
      $CatParametrosFiscaisCreateCompanionBuilder,
      $CatParametrosFiscaisUpdateCompanionBuilder,
      (
        CatParametroFiscal,
        BaseReferences<_$BancoLocal, CatParametrosFiscais, CatParametroFiscal>,
      ),
      CatParametroFiscal,
      PrefetchHooks Function()
    >;
typedef $CatFeriadosBancariosCreateCompanionBuilder =
    CatFeriadosBancariosCompanion Function({
      required String data,
      required String nome,
      Value<int> rowid,
    });
typedef $CatFeriadosBancariosUpdateCompanionBuilder =
    CatFeriadosBancariosCompanion Function({
      Value<String> data,
      Value<String> nome,
      Value<int> rowid,
    });

class $CatFeriadosBancariosFilterComposer
    extends Composer<_$BancoLocal, CatFeriadosBancarios> {
  $CatFeriadosBancariosFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnFilters(column),
  );
}

class $CatFeriadosBancariosOrderingComposer
    extends Composer<_$BancoLocal, CatFeriadosBancarios> {
  $CatFeriadosBancariosOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnOrderings(column),
  );
}

class $CatFeriadosBancariosAnnotationComposer
    extends Composer<_$BancoLocal, CatFeriadosBancarios> {
  $CatFeriadosBancariosAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);
}

class $CatFeriadosBancariosTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          CatFeriadosBancarios,
          CatFeriadoBancario,
          $CatFeriadosBancariosFilterComposer,
          $CatFeriadosBancariosOrderingComposer,
          $CatFeriadosBancariosAnnotationComposer,
          $CatFeriadosBancariosCreateCompanionBuilder,
          $CatFeriadosBancariosUpdateCompanionBuilder,
          (
            CatFeriadoBancario,
            BaseReferences<
              _$BancoLocal,
              CatFeriadosBancarios,
              CatFeriadoBancario
            >,
          ),
          CatFeriadoBancario,
          PrefetchHooks Function()
        > {
  $CatFeriadosBancariosTableManager(_$BancoLocal db, CatFeriadosBancarios table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $CatFeriadosBancariosFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $CatFeriadosBancariosOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $CatFeriadosBancariosAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> data = const Value.absent(),
                Value<String> nome = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CatFeriadosBancariosCompanion(
                data: data,
                nome: nome,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String data,
                required String nome,
                Value<int> rowid = const Value.absent(),
              }) => CatFeriadosBancariosCompanion.insert(
                data: data,
                nome: nome,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $CatFeriadosBancariosProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      CatFeriadosBancarios,
      CatFeriadoBancario,
      $CatFeriadosBancariosFilterComposer,
      $CatFeriadosBancariosOrderingComposer,
      $CatFeriadosBancariosAnnotationComposer,
      $CatFeriadosBancariosCreateCompanionBuilder,
      $CatFeriadosBancariosUpdateCompanionBuilder,
      (
        CatFeriadoBancario,
        BaseReferences<_$BancoLocal, CatFeriadosBancarios, CatFeriadoBancario>,
      ),
      CatFeriadoBancario,
      PrefetchHooks Function()
    >;
typedef $CatRubricasCreateCompanionBuilder =
    CatRubricasCompanion Function({
      required String codigo,
      required String nome,
      required int dedutivel,
      Value<int> travaHomeOffice,
      Value<int> exigeValidacaoContador,
      Value<int?> ordem,
      Value<int> ativo,
      Value<int> rowid,
    });
typedef $CatRubricasUpdateCompanionBuilder =
    CatRubricasCompanion Function({
      Value<String> codigo,
      Value<String> nome,
      Value<int> dedutivel,
      Value<int> travaHomeOffice,
      Value<int> exigeValidacaoContador,
      Value<int?> ordem,
      Value<int> ativo,
      Value<int> rowid,
    });

final class $CatRubricasReferences
    extends BaseReferences<_$BancoLocal, CatRubricas, CatRubrica> {
  $CatRubricasReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<DespesasLivroCaixa, List<DespesaLivroCaixa>>
  _despesasLivroCaixaRefsTable(_$BancoLocal db) =>
      MultiTypedResultKey.fromTable(
        db.despesasLivroCaixa,
        aliasName: 'cat_rubricas__codigo__despesas_livro_caixa__rubrica_codigo',
      );

  $DespesasLivroCaixaProcessedTableManager get despesasLivroCaixaRefs {
    final manager =
        $DespesasLivroCaixaTableManager($_db, $_db.despesasLivroCaixa).filter(
          (f) =>
              f.rubricaCodigo.codigo.sqlEquals($_itemColumn<String>('codigo')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _despesasLivroCaixaRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $CatRubricasFilterComposer extends Composer<_$BancoLocal, CatRubricas> {
  $CatRubricasFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get codigo => $composableBuilder(
    column: $table.codigo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dedutivel => $composableBuilder(
    column: $table.dedutivel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get travaHomeOffice => $composableBuilder(
    column: $table.travaHomeOffice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get exigeValidacaoContador => $composableBuilder(
    column: $table.exigeValidacaoContador,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ordem => $composableBuilder(
    column: $table.ordem,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ativo => $composableBuilder(
    column: $table.ativo,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> despesasLivroCaixaRefs(
    Expression<bool> Function($DespesasLivroCaixaFilterComposer f) f,
  ) {
    final $DespesasLivroCaixaFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codigo,
      referencedTable: $db.despesasLivroCaixa,
      getReferencedColumn: (t) => t.rubricaCodigo,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $DespesasLivroCaixaFilterComposer(
            $db: $db,
            $table: $db.despesasLivroCaixa,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $CatRubricasOrderingComposer extends Composer<_$BancoLocal, CatRubricas> {
  $CatRubricasOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get codigo => $composableBuilder(
    column: $table.codigo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dedutivel => $composableBuilder(
    column: $table.dedutivel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get travaHomeOffice => $composableBuilder(
    column: $table.travaHomeOffice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get exigeValidacaoContador => $composableBuilder(
    column: $table.exigeValidacaoContador,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ordem => $composableBuilder(
    column: $table.ordem,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ativo => $composableBuilder(
    column: $table.ativo,
    builder: (column) => ColumnOrderings(column),
  );
}

class $CatRubricasAnnotationComposer
    extends Composer<_$BancoLocal, CatRubricas> {
  $CatRubricasAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get codigo =>
      $composableBuilder(column: $table.codigo, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<int> get dedutivel =>
      $composableBuilder(column: $table.dedutivel, builder: (column) => column);

  GeneratedColumn<int> get travaHomeOffice => $composableBuilder(
    column: $table.travaHomeOffice,
    builder: (column) => column,
  );

  GeneratedColumn<int> get exigeValidacaoContador => $composableBuilder(
    column: $table.exigeValidacaoContador,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ordem =>
      $composableBuilder(column: $table.ordem, builder: (column) => column);

  GeneratedColumn<int> get ativo =>
      $composableBuilder(column: $table.ativo, builder: (column) => column);

  Expression<T> despesasLivroCaixaRefs<T extends Object>(
    Expression<T> Function($DespesasLivroCaixaAnnotationComposer a) f,
  ) {
    final $DespesasLivroCaixaAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codigo,
      referencedTable: $db.despesasLivroCaixa,
      getReferencedColumn: (t) => t.rubricaCodigo,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $DespesasLivroCaixaAnnotationComposer(
            $db: $db,
            $table: $db.despesasLivroCaixa,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $CatRubricasTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          CatRubricas,
          CatRubrica,
          $CatRubricasFilterComposer,
          $CatRubricasOrderingComposer,
          $CatRubricasAnnotationComposer,
          $CatRubricasCreateCompanionBuilder,
          $CatRubricasUpdateCompanionBuilder,
          (CatRubrica, $CatRubricasReferences),
          CatRubrica,
          PrefetchHooks Function({bool despesasLivroCaixaRefs})
        > {
  $CatRubricasTableManager(_$BancoLocal db, CatRubricas table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $CatRubricasFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $CatRubricasOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $CatRubricasAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> codigo = const Value.absent(),
                Value<String> nome = const Value.absent(),
                Value<int> dedutivel = const Value.absent(),
                Value<int> travaHomeOffice = const Value.absent(),
                Value<int> exigeValidacaoContador = const Value.absent(),
                Value<int?> ordem = const Value.absent(),
                Value<int> ativo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CatRubricasCompanion(
                codigo: codigo,
                nome: nome,
                dedutivel: dedutivel,
                travaHomeOffice: travaHomeOffice,
                exigeValidacaoContador: exigeValidacaoContador,
                ordem: ordem,
                ativo: ativo,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String codigo,
                required String nome,
                required int dedutivel,
                Value<int> travaHomeOffice = const Value.absent(),
                Value<int> exigeValidacaoContador = const Value.absent(),
                Value<int?> ordem = const Value.absent(),
                Value<int> ativo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CatRubricasCompanion.insert(
                codigo: codigo,
                nome: nome,
                dedutivel: dedutivel,
                travaHomeOffice: travaHomeOffice,
                exigeValidacaoContador: exigeValidacaoContador,
                ordem: ordem,
                ativo: ativo,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $CatRubricasReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({despesasLivroCaixaRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (despesasLivroCaixaRefs) db.despesasLivroCaixa,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (despesasLivroCaixaRefs)
                    await $_getPrefetchedData<
                      CatRubrica,
                      CatRubricas,
                      DespesaLivroCaixa
                    >(
                      currentTable: table,
                      referencedTable: $CatRubricasReferences
                          ._despesasLivroCaixaRefsTable(db),
                      managerFromTypedResult: (p0) => $CatRubricasReferences(
                        db,
                        table,
                        p0,
                      ).despesasLivroCaixaRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.rubricaCodigo == item.codigo,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $CatRubricasProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      CatRubricas,
      CatRubrica,
      $CatRubricasFilterComposer,
      $CatRubricasOrderingComposer,
      $CatRubricasAnnotationComposer,
      $CatRubricasCreateCompanionBuilder,
      $CatRubricasUpdateCompanionBuilder,
      (CatRubrica, $CatRubricasReferences),
      CatRubrica,
      PrefetchHooks Function({bool despesasLivroCaixaRefs})
    >;
typedef $CatProfissoesCreateCompanionBuilder =
    CatProfissoesCompanion Function({
      required String codigo,
      required String nome,
      required int regulamentada,
      Value<String?> conselho,
      Value<int?> meiPermitido,
      Value<int> ativo,
      Value<int> rowid,
    });
typedef $CatProfissoesUpdateCompanionBuilder =
    CatProfissoesCompanion Function({
      Value<String> codigo,
      Value<String> nome,
      Value<int> regulamentada,
      Value<String?> conselho,
      Value<int?> meiPermitido,
      Value<int> ativo,
      Value<int> rowid,
    });

final class $CatProfissoesReferences
    extends BaseReferences<_$BancoLocal, CatProfissoes, CatProfissao> {
  $CatProfissoesReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<Perfil, List<PerfilLocal>> _perfilRefsTable(
    _$BancoLocal db,
  ) => MultiTypedResultKey.fromTable(
    db.perfil,
    aliasName: 'cat_profissoes__codigo__perfil__profissao_codigo',
  );

  $PerfilProcessedTableManager get perfilRefs {
    final manager = $PerfilTableManager($_db, $_db.perfil).filter(
      (f) =>
          f.profissaoCodigo.codigo.sqlEquals($_itemColumn<String>('codigo')!),
    );

    final cache = $_typedResult.readTableOrNull(_perfilRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $CatProfissoesFilterComposer
    extends Composer<_$BancoLocal, CatProfissoes> {
  $CatProfissoesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get codigo => $composableBuilder(
    column: $table.codigo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get regulamentada => $composableBuilder(
    column: $table.regulamentada,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conselho => $composableBuilder(
    column: $table.conselho,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get meiPermitido => $composableBuilder(
    column: $table.meiPermitido,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ativo => $composableBuilder(
    column: $table.ativo,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> perfilRefs(
    Expression<bool> Function($PerfilFilterComposer f) f,
  ) {
    final $PerfilFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codigo,
      referencedTable: $db.perfil,
      getReferencedColumn: (t) => t.profissaoCodigo,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PerfilFilterComposer(
            $db: $db,
            $table: $db.perfil,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $CatProfissoesOrderingComposer
    extends Composer<_$BancoLocal, CatProfissoes> {
  $CatProfissoesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get codigo => $composableBuilder(
    column: $table.codigo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get regulamentada => $composableBuilder(
    column: $table.regulamentada,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conselho => $composableBuilder(
    column: $table.conselho,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get meiPermitido => $composableBuilder(
    column: $table.meiPermitido,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ativo => $composableBuilder(
    column: $table.ativo,
    builder: (column) => ColumnOrderings(column),
  );
}

class $CatProfissoesAnnotationComposer
    extends Composer<_$BancoLocal, CatProfissoes> {
  $CatProfissoesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get codigo =>
      $composableBuilder(column: $table.codigo, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<int> get regulamentada => $composableBuilder(
    column: $table.regulamentada,
    builder: (column) => column,
  );

  GeneratedColumn<String> get conselho =>
      $composableBuilder(column: $table.conselho, builder: (column) => column);

  GeneratedColumn<int> get meiPermitido => $composableBuilder(
    column: $table.meiPermitido,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ativo =>
      $composableBuilder(column: $table.ativo, builder: (column) => column);

  Expression<T> perfilRefs<T extends Object>(
    Expression<T> Function($PerfilAnnotationComposer a) f,
  ) {
    final $PerfilAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.codigo,
      referencedTable: $db.perfil,
      getReferencedColumn: (t) => t.profissaoCodigo,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PerfilAnnotationComposer(
            $db: $db,
            $table: $db.perfil,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $CatProfissoesTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          CatProfissoes,
          CatProfissao,
          $CatProfissoesFilterComposer,
          $CatProfissoesOrderingComposer,
          $CatProfissoesAnnotationComposer,
          $CatProfissoesCreateCompanionBuilder,
          $CatProfissoesUpdateCompanionBuilder,
          (CatProfissao, $CatProfissoesReferences),
          CatProfissao,
          PrefetchHooks Function({bool perfilRefs})
        > {
  $CatProfissoesTableManager(_$BancoLocal db, CatProfissoes table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $CatProfissoesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $CatProfissoesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $CatProfissoesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> codigo = const Value.absent(),
                Value<String> nome = const Value.absent(),
                Value<int> regulamentada = const Value.absent(),
                Value<String?> conselho = const Value.absent(),
                Value<int?> meiPermitido = const Value.absent(),
                Value<int> ativo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CatProfissoesCompanion(
                codigo: codigo,
                nome: nome,
                regulamentada: regulamentada,
                conselho: conselho,
                meiPermitido: meiPermitido,
                ativo: ativo,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String codigo,
                required String nome,
                required int regulamentada,
                Value<String?> conselho = const Value.absent(),
                Value<int?> meiPermitido = const Value.absent(),
                Value<int> ativo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CatProfissoesCompanion.insert(
                codigo: codigo,
                nome: nome,
                regulamentada: regulamentada,
                conselho: conselho,
                meiPermitido: meiPermitido,
                ativo: ativo,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $CatProfissoesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({perfilRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (perfilRefs) db.perfil],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (perfilRefs)
                    await $_getPrefetchedData<
                      CatProfissao,
                      CatProfissoes,
                      PerfilLocal
                    >(
                      currentTable: table,
                      referencedTable: $CatProfissoesReferences
                          ._perfilRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $CatProfissoesReferences(db, table, p0).perfilRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.profissaoCodigo == item.codigo,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $CatProfissoesProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      CatProfissoes,
      CatProfissao,
      $CatProfissoesFilterComposer,
      $CatProfissoesOrderingComposer,
      $CatProfissoesAnnotationComposer,
      $CatProfissoesCreateCompanionBuilder,
      $CatProfissoesUpdateCompanionBuilder,
      (CatProfissao, $CatProfissoesReferences),
      CatProfissao,
      PrefetchHooks Function({bool perfilRefs})
    >;
typedef $CatPerfisParserCreateCompanionBuilder =
    CatPerfisParserCompanion Function({
      required String codigo,
      required String bancoNome,
      required String formato,
      required String definicaoJson,
      required int versao,
      Value<int> rowid,
    });
typedef $CatPerfisParserUpdateCompanionBuilder =
    CatPerfisParserCompanion Function({
      Value<String> codigo,
      Value<String> bancoNome,
      Value<String> formato,
      Value<String> definicaoJson,
      Value<int> versao,
      Value<int> rowid,
    });

class $CatPerfisParserFilterComposer
    extends Composer<_$BancoLocal, CatPerfisParser> {
  $CatPerfisParserFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get codigo => $composableBuilder(
    column: $table.codigo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bancoNome => $composableBuilder(
    column: $table.bancoNome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get formato => $composableBuilder(
    column: $table.formato,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get definicaoJson => $composableBuilder(
    column: $table.definicaoJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get versao => $composableBuilder(
    column: $table.versao,
    builder: (column) => ColumnFilters(column),
  );
}

class $CatPerfisParserOrderingComposer
    extends Composer<_$BancoLocal, CatPerfisParser> {
  $CatPerfisParserOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get codigo => $composableBuilder(
    column: $table.codigo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bancoNome => $composableBuilder(
    column: $table.bancoNome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get formato => $composableBuilder(
    column: $table.formato,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get definicaoJson => $composableBuilder(
    column: $table.definicaoJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get versao => $composableBuilder(
    column: $table.versao,
    builder: (column) => ColumnOrderings(column),
  );
}

class $CatPerfisParserAnnotationComposer
    extends Composer<_$BancoLocal, CatPerfisParser> {
  $CatPerfisParserAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get codigo =>
      $composableBuilder(column: $table.codigo, builder: (column) => column);

  GeneratedColumn<String> get bancoNome =>
      $composableBuilder(column: $table.bancoNome, builder: (column) => column);

  GeneratedColumn<String> get formato =>
      $composableBuilder(column: $table.formato, builder: (column) => column);

  GeneratedColumn<String> get definicaoJson => $composableBuilder(
    column: $table.definicaoJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get versao =>
      $composableBuilder(column: $table.versao, builder: (column) => column);
}

class $CatPerfisParserTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          CatPerfisParser,
          CatPerfilParser,
          $CatPerfisParserFilterComposer,
          $CatPerfisParserOrderingComposer,
          $CatPerfisParserAnnotationComposer,
          $CatPerfisParserCreateCompanionBuilder,
          $CatPerfisParserUpdateCompanionBuilder,
          (
            CatPerfilParser,
            BaseReferences<_$BancoLocal, CatPerfisParser, CatPerfilParser>,
          ),
          CatPerfilParser,
          PrefetchHooks Function()
        > {
  $CatPerfisParserTableManager(_$BancoLocal db, CatPerfisParser table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $CatPerfisParserFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $CatPerfisParserOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $CatPerfisParserAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> codigo = const Value.absent(),
                Value<String> bancoNome = const Value.absent(),
                Value<String> formato = const Value.absent(),
                Value<String> definicaoJson = const Value.absent(),
                Value<int> versao = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CatPerfisParserCompanion(
                codigo: codigo,
                bancoNome: bancoNome,
                formato: formato,
                definicaoJson: definicaoJson,
                versao: versao,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String codigo,
                required String bancoNome,
                required String formato,
                required String definicaoJson,
                required int versao,
                Value<int> rowid = const Value.absent(),
              }) => CatPerfisParserCompanion.insert(
                codigo: codigo,
                bancoNome: bancoNome,
                formato: formato,
                definicaoJson: definicaoJson,
                versao: versao,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $CatPerfisParserProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      CatPerfisParser,
      CatPerfilParser,
      $CatPerfisParserFilterComposer,
      $CatPerfisParserOrderingComposer,
      $CatPerfisParserAnnotationComposer,
      $CatPerfisParserCreateCompanionBuilder,
      $CatPerfisParserUpdateCompanionBuilder,
      (
        CatPerfilParser,
        BaseReferences<_$BancoLocal, CatPerfisParser, CatPerfilParser>,
      ),
      CatPerfilParser,
      PrefetchHooks Function()
    >;
typedef $PerfilCreateCompanionBuilder =
    PerfilCompanion Function({
      Value<int> id,
      Value<String?> usuarioRemotoId,
      required String nome,
      required String cpf,
      Value<String?> profissaoCodigo,
      Value<int> exigeCpfPagador,
      Value<int> onboardingCompleto,
      Value<int?> codigoRecuperacaoConfirmadoEm,
      required int criadoEm,
      required int atualizadoEm,
    });
typedef $PerfilUpdateCompanionBuilder =
    PerfilCompanion Function({
      Value<int> id,
      Value<String?> usuarioRemotoId,
      Value<String> nome,
      Value<String> cpf,
      Value<String?> profissaoCodigo,
      Value<int> exigeCpfPagador,
      Value<int> onboardingCompleto,
      Value<int?> codigoRecuperacaoConfirmadoEm,
      Value<int> criadoEm,
      Value<int> atualizadoEm,
    });

final class $PerfilReferences
    extends BaseReferences<_$BancoLocal, Perfil, PerfilLocal> {
  $PerfilReferences(super.$_db, super.$_table, super.$_typedResult);

  static CatProfissoes _profissaoCodigoTable(_$BancoLocal db) => db
      .catProfissoes
      .createAlias('perfil__profissao_codigo__cat_profissoes__codigo');

  $CatProfissoesProcessedTableManager? get profissaoCodigo {
    final $_column = $_itemColumn<String>('profissao_codigo');
    if ($_column == null) return null;
    final manager = $CatProfissoesTableManager(
      $_db,
      $_db.catProfissoes,
    ).filter((f) => f.codigo.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_profissaoCodigoTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $PerfilFilterComposer extends Composer<_$BancoLocal, Perfil> {
  $PerfilFilterComposer({
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

  ColumnFilters<String> get usuarioRemotoId => $composableBuilder(
    column: $table.usuarioRemotoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cpf => $composableBuilder(
    column: $table.cpf,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get exigeCpfPagador => $composableBuilder(
    column: $table.exigeCpfPagador,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get onboardingCompleto => $composableBuilder(
    column: $table.onboardingCompleto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get codigoRecuperacaoConfirmadoEm => $composableBuilder(
    column: $table.codigoRecuperacaoConfirmadoEm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get criadoEm => $composableBuilder(
    column: $table.criadoEm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get atualizadoEm => $composableBuilder(
    column: $table.atualizadoEm,
    builder: (column) => ColumnFilters(column),
  );

  $CatProfissoesFilterComposer get profissaoCodigo {
    final $CatProfissoesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profissaoCodigo,
      referencedTable: $db.catProfissoes,
      getReferencedColumn: (t) => t.codigo,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CatProfissoesFilterComposer(
            $db: $db,
            $table: $db.catProfissoes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $PerfilOrderingComposer extends Composer<_$BancoLocal, Perfil> {
  $PerfilOrderingComposer({
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

  ColumnOrderings<String> get usuarioRemotoId => $composableBuilder(
    column: $table.usuarioRemotoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cpf => $composableBuilder(
    column: $table.cpf,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get exigeCpfPagador => $composableBuilder(
    column: $table.exigeCpfPagador,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get onboardingCompleto => $composableBuilder(
    column: $table.onboardingCompleto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get codigoRecuperacaoConfirmadoEm => $composableBuilder(
    column: $table.codigoRecuperacaoConfirmadoEm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get criadoEm => $composableBuilder(
    column: $table.criadoEm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get atualizadoEm => $composableBuilder(
    column: $table.atualizadoEm,
    builder: (column) => ColumnOrderings(column),
  );

  $CatProfissoesOrderingComposer get profissaoCodigo {
    final $CatProfissoesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profissaoCodigo,
      referencedTable: $db.catProfissoes,
      getReferencedColumn: (t) => t.codigo,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CatProfissoesOrderingComposer(
            $db: $db,
            $table: $db.catProfissoes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $PerfilAnnotationComposer extends Composer<_$BancoLocal, Perfil> {
  $PerfilAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get usuarioRemotoId => $composableBuilder(
    column: $table.usuarioRemotoId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<String> get cpf =>
      $composableBuilder(column: $table.cpf, builder: (column) => column);

  GeneratedColumn<int> get exigeCpfPagador => $composableBuilder(
    column: $table.exigeCpfPagador,
    builder: (column) => column,
  );

  GeneratedColumn<int> get onboardingCompleto => $composableBuilder(
    column: $table.onboardingCompleto,
    builder: (column) => column,
  );

  GeneratedColumn<int> get codigoRecuperacaoConfirmadoEm => $composableBuilder(
    column: $table.codigoRecuperacaoConfirmadoEm,
    builder: (column) => column,
  );

  GeneratedColumn<int> get criadoEm =>
      $composableBuilder(column: $table.criadoEm, builder: (column) => column);

  GeneratedColumn<int> get atualizadoEm => $composableBuilder(
    column: $table.atualizadoEm,
    builder: (column) => column,
  );

  $CatProfissoesAnnotationComposer get profissaoCodigo {
    final $CatProfissoesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profissaoCodigo,
      referencedTable: $db.catProfissoes,
      getReferencedColumn: (t) => t.codigo,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CatProfissoesAnnotationComposer(
            $db: $db,
            $table: $db.catProfissoes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $PerfilTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          Perfil,
          PerfilLocal,
          $PerfilFilterComposer,
          $PerfilOrderingComposer,
          $PerfilAnnotationComposer,
          $PerfilCreateCompanionBuilder,
          $PerfilUpdateCompanionBuilder,
          (PerfilLocal, $PerfilReferences),
          PerfilLocal,
          PrefetchHooks Function({bool profissaoCodigo})
        > {
  $PerfilTableManager(_$BancoLocal db, Perfil table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $PerfilFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $PerfilOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $PerfilAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> usuarioRemotoId = const Value.absent(),
                Value<String> nome = const Value.absent(),
                Value<String> cpf = const Value.absent(),
                Value<String?> profissaoCodigo = const Value.absent(),
                Value<int> exigeCpfPagador = const Value.absent(),
                Value<int> onboardingCompleto = const Value.absent(),
                Value<int?> codigoRecuperacaoConfirmadoEm =
                    const Value.absent(),
                Value<int> criadoEm = const Value.absent(),
                Value<int> atualizadoEm = const Value.absent(),
              }) => PerfilCompanion(
                id: id,
                usuarioRemotoId: usuarioRemotoId,
                nome: nome,
                cpf: cpf,
                profissaoCodigo: profissaoCodigo,
                exigeCpfPagador: exigeCpfPagador,
                onboardingCompleto: onboardingCompleto,
                codigoRecuperacaoConfirmadoEm: codigoRecuperacaoConfirmadoEm,
                criadoEm: criadoEm,
                atualizadoEm: atualizadoEm,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> usuarioRemotoId = const Value.absent(),
                required String nome,
                required String cpf,
                Value<String?> profissaoCodigo = const Value.absent(),
                Value<int> exigeCpfPagador = const Value.absent(),
                Value<int> onboardingCompleto = const Value.absent(),
                Value<int?> codigoRecuperacaoConfirmadoEm =
                    const Value.absent(),
                required int criadoEm,
                required int atualizadoEm,
              }) => PerfilCompanion.insert(
                id: id,
                usuarioRemotoId: usuarioRemotoId,
                nome: nome,
                cpf: cpf,
                profissaoCodigo: profissaoCodigo,
                exigeCpfPagador: exigeCpfPagador,
                onboardingCompleto: onboardingCompleto,
                codigoRecuperacaoConfirmadoEm: codigoRecuperacaoConfirmadoEm,
                criadoEm: criadoEm,
                atualizadoEm: atualizadoEm,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), $PerfilReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({profissaoCodigo = false}) {
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
                    if (profissaoCodigo) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.profissaoCodigo,
                                referencedTable: $PerfilReferences
                                    ._profissaoCodigoTable(db),
                                referencedColumn: $PerfilReferences
                                    ._profissaoCodigoTable(db)
                                    .codigo,
                              )
                              as T;
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

typedef $PerfilProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      Perfil,
      PerfilLocal,
      $PerfilFilterComposer,
      $PerfilOrderingComposer,
      $PerfilAnnotationComposer,
      $PerfilCreateCompanionBuilder,
      $PerfilUpdateCompanionBuilder,
      (PerfilLocal, $PerfilReferences),
      PerfilLocal,
      PrefetchHooks Function({bool profissaoCodigo})
    >;
typedef $AceitesTermosLocalCreateCompanionBuilder =
    AceitesTermosLocalCompanion Function({
      required String documento,
      required String versao,
      required int aceitoEm,
      Value<int> sincronizado,
      Value<int> rowid,
    });
typedef $AceitesTermosLocalUpdateCompanionBuilder =
    AceitesTermosLocalCompanion Function({
      Value<String> documento,
      Value<String> versao,
      Value<int> aceitoEm,
      Value<int> sincronizado,
      Value<int> rowid,
    });

class $AceitesTermosLocalFilterComposer
    extends Composer<_$BancoLocal, AceitesTermosLocal> {
  $AceitesTermosLocalFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get documento => $composableBuilder(
    column: $table.documento,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get versao => $composableBuilder(
    column: $table.versao,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get aceitoEm => $composableBuilder(
    column: $table.aceitoEm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sincronizado => $composableBuilder(
    column: $table.sincronizado,
    builder: (column) => ColumnFilters(column),
  );
}

class $AceitesTermosLocalOrderingComposer
    extends Composer<_$BancoLocal, AceitesTermosLocal> {
  $AceitesTermosLocalOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get documento => $composableBuilder(
    column: $table.documento,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get versao => $composableBuilder(
    column: $table.versao,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get aceitoEm => $composableBuilder(
    column: $table.aceitoEm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sincronizado => $composableBuilder(
    column: $table.sincronizado,
    builder: (column) => ColumnOrderings(column),
  );
}

class $AceitesTermosLocalAnnotationComposer
    extends Composer<_$BancoLocal, AceitesTermosLocal> {
  $AceitesTermosLocalAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get documento =>
      $composableBuilder(column: $table.documento, builder: (column) => column);

  GeneratedColumn<String> get versao =>
      $composableBuilder(column: $table.versao, builder: (column) => column);

  GeneratedColumn<int> get aceitoEm =>
      $composableBuilder(column: $table.aceitoEm, builder: (column) => column);

  GeneratedColumn<int> get sincronizado => $composableBuilder(
    column: $table.sincronizado,
    builder: (column) => column,
  );
}

class $AceitesTermosLocalTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          AceitesTermosLocal,
          AceiteTermosLocal,
          $AceitesTermosLocalFilterComposer,
          $AceitesTermosLocalOrderingComposer,
          $AceitesTermosLocalAnnotationComposer,
          $AceitesTermosLocalCreateCompanionBuilder,
          $AceitesTermosLocalUpdateCompanionBuilder,
          (
            AceiteTermosLocal,
            BaseReferences<_$BancoLocal, AceitesTermosLocal, AceiteTermosLocal>,
          ),
          AceiteTermosLocal,
          PrefetchHooks Function()
        > {
  $AceitesTermosLocalTableManager(_$BancoLocal db, AceitesTermosLocal table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $AceitesTermosLocalFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $AceitesTermosLocalOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $AceitesTermosLocalAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> documento = const Value.absent(),
                Value<String> versao = const Value.absent(),
                Value<int> aceitoEm = const Value.absent(),
                Value<int> sincronizado = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AceitesTermosLocalCompanion(
                documento: documento,
                versao: versao,
                aceitoEm: aceitoEm,
                sincronizado: sincronizado,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String documento,
                required String versao,
                required int aceitoEm,
                Value<int> sincronizado = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AceitesTermosLocalCompanion.insert(
                documento: documento,
                versao: versao,
                aceitoEm: aceitoEm,
                sincronizado: sincronizado,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $AceitesTermosLocalProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      AceitesTermosLocal,
      AceiteTermosLocal,
      $AceitesTermosLocalFilterComposer,
      $AceitesTermosLocalOrderingComposer,
      $AceitesTermosLocalAnnotationComposer,
      $AceitesTermosLocalCreateCompanionBuilder,
      $AceitesTermosLocalUpdateCompanionBuilder,
      (
        AceiteTermosLocal,
        BaseReferences<_$BancoLocal, AceitesTermosLocal, AceiteTermosLocal>,
      ),
      AceiteTermosLocal,
      PrefetchHooks Function()
    >;
typedef $ContasBancariasCreateCompanionBuilder =
    ContasBancariasCompanion Function({
      required String id,
      required String apelido,
      Value<String?> bancoCodigo,
      Value<String> origem,
      Value<int> ativa,
      required int criadoEm,
      Value<int> rowid,
    });
typedef $ContasBancariasUpdateCompanionBuilder =
    ContasBancariasCompanion Function({
      Value<String> id,
      Value<String> apelido,
      Value<String?> bancoCodigo,
      Value<String> origem,
      Value<int> ativa,
      Value<int> criadoEm,
      Value<int> rowid,
    });

final class $ContasBancariasReferences
    extends BaseReferences<_$BancoLocal, ContasBancarias, ContaBancaria> {
  $ContasBancariasReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<Importacoes, List<Importacao>>
  _importacoesRefsTable(_$BancoLocal db) => MultiTypedResultKey.fromTable(
    db.importacoes,
    aliasName: 'contas_bancarias__id__importacoes__conta_id',
  );

  $ImportacoesProcessedTableManager get importacoesRefs {
    final manager = $ImportacoesTableManager(
      $_db,
      $_db.importacoes,
    ).filter((f) => f.contaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_importacoesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<Transacoes, List<Transacao>> _transacoesRefsTable(
    _$BancoLocal db,
  ) => MultiTypedResultKey.fromTable(
    db.transacoes,
    aliasName: 'contas_bancarias__id__transacoes__conta_id',
  );

  $TransacoesProcessedTableManager get transacoesRefs {
    final manager = $TransacoesTableManager(
      $_db,
      $_db.transacoes,
    ).filter((f) => f.contaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_transacoesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $ContasBancariasFilterComposer
    extends Composer<_$BancoLocal, ContasBancarias> {
  $ContasBancariasFilterComposer({
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

  ColumnFilters<String> get apelido => $composableBuilder(
    column: $table.apelido,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bancoCodigo => $composableBuilder(
    column: $table.bancoCodigo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origem => $composableBuilder(
    column: $table.origem,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ativa => $composableBuilder(
    column: $table.ativa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get criadoEm => $composableBuilder(
    column: $table.criadoEm,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> importacoesRefs(
    Expression<bool> Function($ImportacoesFilterComposer f) f,
  ) {
    final $ImportacoesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.importacoes,
      getReferencedColumn: (t) => t.contaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ImportacoesFilterComposer(
            $db: $db,
            $table: $db.importacoes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> transacoesRefs(
    Expression<bool> Function($TransacoesFilterComposer f) f,
  ) {
    final $TransacoesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transacoes,
      getReferencedColumn: (t) => t.contaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TransacoesFilterComposer(
            $db: $db,
            $table: $db.transacoes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $ContasBancariasOrderingComposer
    extends Composer<_$BancoLocal, ContasBancarias> {
  $ContasBancariasOrderingComposer({
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

  ColumnOrderings<String> get apelido => $composableBuilder(
    column: $table.apelido,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bancoCodigo => $composableBuilder(
    column: $table.bancoCodigo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origem => $composableBuilder(
    column: $table.origem,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ativa => $composableBuilder(
    column: $table.ativa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get criadoEm => $composableBuilder(
    column: $table.criadoEm,
    builder: (column) => ColumnOrderings(column),
  );
}

class $ContasBancariasAnnotationComposer
    extends Composer<_$BancoLocal, ContasBancarias> {
  $ContasBancariasAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get apelido =>
      $composableBuilder(column: $table.apelido, builder: (column) => column);

  GeneratedColumn<String> get bancoCodigo => $composableBuilder(
    column: $table.bancoCodigo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get origem =>
      $composableBuilder(column: $table.origem, builder: (column) => column);

  GeneratedColumn<int> get ativa =>
      $composableBuilder(column: $table.ativa, builder: (column) => column);

  GeneratedColumn<int> get criadoEm =>
      $composableBuilder(column: $table.criadoEm, builder: (column) => column);

  Expression<T> importacoesRefs<T extends Object>(
    Expression<T> Function($ImportacoesAnnotationComposer a) f,
  ) {
    final $ImportacoesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.importacoes,
      getReferencedColumn: (t) => t.contaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ImportacoesAnnotationComposer(
            $db: $db,
            $table: $db.importacoes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> transacoesRefs<T extends Object>(
    Expression<T> Function($TransacoesAnnotationComposer a) f,
  ) {
    final $TransacoesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transacoes,
      getReferencedColumn: (t) => t.contaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TransacoesAnnotationComposer(
            $db: $db,
            $table: $db.transacoes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $ContasBancariasTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          ContasBancarias,
          ContaBancaria,
          $ContasBancariasFilterComposer,
          $ContasBancariasOrderingComposer,
          $ContasBancariasAnnotationComposer,
          $ContasBancariasCreateCompanionBuilder,
          $ContasBancariasUpdateCompanionBuilder,
          (ContaBancaria, $ContasBancariasReferences),
          ContaBancaria,
          PrefetchHooks Function({bool importacoesRefs, bool transacoesRefs})
        > {
  $ContasBancariasTableManager(_$BancoLocal db, ContasBancarias table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ContasBancariasFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ContasBancariasOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ContasBancariasAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> apelido = const Value.absent(),
                Value<String?> bancoCodigo = const Value.absent(),
                Value<String> origem = const Value.absent(),
                Value<int> ativa = const Value.absent(),
                Value<int> criadoEm = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContasBancariasCompanion(
                id: id,
                apelido: apelido,
                bancoCodigo: bancoCodigo,
                origem: origem,
                ativa: ativa,
                criadoEm: criadoEm,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String apelido,
                Value<String?> bancoCodigo = const Value.absent(),
                Value<String> origem = const Value.absent(),
                Value<int> ativa = const Value.absent(),
                required int criadoEm,
                Value<int> rowid = const Value.absent(),
              }) => ContasBancariasCompanion.insert(
                id: id,
                apelido: apelido,
                bancoCodigo: bancoCodigo,
                origem: origem,
                ativa: ativa,
                criadoEm: criadoEm,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $ContasBancariasReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({importacoesRefs = false, transacoesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (importacoesRefs) db.importacoes,
                    if (transacoesRefs) db.transacoes,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (importacoesRefs)
                        await $_getPrefetchedData<
                          ContaBancaria,
                          ContasBancarias,
                          Importacao
                        >(
                          currentTable: table,
                          referencedTable: $ContasBancariasReferences
                              ._importacoesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $ContasBancariasReferences(
                                db,
                                table,
                                p0,
                              ).importacoesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.contaId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (transacoesRefs)
                        await $_getPrefetchedData<
                          ContaBancaria,
                          ContasBancarias,
                          Transacao
                        >(
                          currentTable: table,
                          referencedTable: $ContasBancariasReferences
                              ._transacoesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $ContasBancariasReferences(
                                db,
                                table,
                                p0,
                              ).transacoesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.contaId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $ContasBancariasProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      ContasBancarias,
      ContaBancaria,
      $ContasBancariasFilterComposer,
      $ContasBancariasOrderingComposer,
      $ContasBancariasAnnotationComposer,
      $ContasBancariasCreateCompanionBuilder,
      $ContasBancariasUpdateCompanionBuilder,
      (ContaBancaria, $ContasBancariasReferences),
      ContaBancaria,
      PrefetchHooks Function({bool importacoesRefs, bool transacoesRefs})
    >;
typedef $ImportacoesCreateCompanionBuilder =
    ImportacoesCompanion Function({
      required String id,
      required String contaId,
      required String formato,
      required String nomeArquivo,
      required String hashArquivo,
      Value<String?> parserCodigo,
      Value<int?> parserVersao,
      Value<String?> previaJson,
      Value<String?> periodoInicio,
      Value<String?> periodoFim,
      Value<int?> totalLinhas,
      Value<int?> totalImportadas,
      Value<int?> totalDuplicadas,
      Value<int?> totalIgnoradas,
      Value<String> status,
      Value<String?> erroDetalhe,
      required int criadoEm,
      Value<int> rowid,
    });
typedef $ImportacoesUpdateCompanionBuilder =
    ImportacoesCompanion Function({
      Value<String> id,
      Value<String> contaId,
      Value<String> formato,
      Value<String> nomeArquivo,
      Value<String> hashArquivo,
      Value<String?> parserCodigo,
      Value<int?> parserVersao,
      Value<String?> previaJson,
      Value<String?> periodoInicio,
      Value<String?> periodoFim,
      Value<int?> totalLinhas,
      Value<int?> totalImportadas,
      Value<int?> totalDuplicadas,
      Value<int?> totalIgnoradas,
      Value<String> status,
      Value<String?> erroDetalhe,
      Value<int> criadoEm,
      Value<int> rowid,
    });

final class $ImportacoesReferences
    extends BaseReferences<_$BancoLocal, Importacoes, Importacao> {
  $ImportacoesReferences(super.$_db, super.$_table, super.$_typedResult);

  static ContasBancarias _contaIdTable(_$BancoLocal db) => db.contasBancarias
      .createAlias('importacoes__conta_id__contas_bancarias__id');

  $ContasBancariasProcessedTableManager get contaId {
    final $_column = $_itemColumn<String>('conta_id')!;

    final manager = $ContasBancariasTableManager(
      $_db,
      $_db.contasBancarias,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_contaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<Transacoes, List<Transacao>> _transacoesRefsTable(
    _$BancoLocal db,
  ) => MultiTypedResultKey.fromTable(
    db.transacoes,
    aliasName: 'importacoes__id__transacoes__importacao_id',
  );

  $TransacoesProcessedTableManager get transacoesRefs {
    final manager = $TransacoesTableManager(
      $_db,
      $_db.transacoes,
    ).filter((f) => f.importacaoId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_transacoesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $ImportacoesFilterComposer extends Composer<_$BancoLocal, Importacoes> {
  $ImportacoesFilterComposer({
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

  ColumnFilters<String> get formato => $composableBuilder(
    column: $table.formato,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nomeArquivo => $composableBuilder(
    column: $table.nomeArquivo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hashArquivo => $composableBuilder(
    column: $table.hashArquivo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parserCodigo => $composableBuilder(
    column: $table.parserCodigo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get parserVersao => $composableBuilder(
    column: $table.parserVersao,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get previaJson => $composableBuilder(
    column: $table.previaJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get periodoInicio => $composableBuilder(
    column: $table.periodoInicio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get periodoFim => $composableBuilder(
    column: $table.periodoFim,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalLinhas => $composableBuilder(
    column: $table.totalLinhas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalImportadas => $composableBuilder(
    column: $table.totalImportadas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalDuplicadas => $composableBuilder(
    column: $table.totalDuplicadas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalIgnoradas => $composableBuilder(
    column: $table.totalIgnoradas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get erroDetalhe => $composableBuilder(
    column: $table.erroDetalhe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get criadoEm => $composableBuilder(
    column: $table.criadoEm,
    builder: (column) => ColumnFilters(column),
  );

  $ContasBancariasFilterComposer get contaId {
    final $ContasBancariasFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contaId,
      referencedTable: $db.contasBancarias,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ContasBancariasFilterComposer(
            $db: $db,
            $table: $db.contasBancarias,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> transacoesRefs(
    Expression<bool> Function($TransacoesFilterComposer f) f,
  ) {
    final $TransacoesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transacoes,
      getReferencedColumn: (t) => t.importacaoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TransacoesFilterComposer(
            $db: $db,
            $table: $db.transacoes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $ImportacoesOrderingComposer extends Composer<_$BancoLocal, Importacoes> {
  $ImportacoesOrderingComposer({
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

  ColumnOrderings<String> get formato => $composableBuilder(
    column: $table.formato,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nomeArquivo => $composableBuilder(
    column: $table.nomeArquivo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hashArquivo => $composableBuilder(
    column: $table.hashArquivo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parserCodigo => $composableBuilder(
    column: $table.parserCodigo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get parserVersao => $composableBuilder(
    column: $table.parserVersao,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get previaJson => $composableBuilder(
    column: $table.previaJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get periodoInicio => $composableBuilder(
    column: $table.periodoInicio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get periodoFim => $composableBuilder(
    column: $table.periodoFim,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalLinhas => $composableBuilder(
    column: $table.totalLinhas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalImportadas => $composableBuilder(
    column: $table.totalImportadas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalDuplicadas => $composableBuilder(
    column: $table.totalDuplicadas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalIgnoradas => $composableBuilder(
    column: $table.totalIgnoradas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get erroDetalhe => $composableBuilder(
    column: $table.erroDetalhe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get criadoEm => $composableBuilder(
    column: $table.criadoEm,
    builder: (column) => ColumnOrderings(column),
  );

  $ContasBancariasOrderingComposer get contaId {
    final $ContasBancariasOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contaId,
      referencedTable: $db.contasBancarias,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ContasBancariasOrderingComposer(
            $db: $db,
            $table: $db.contasBancarias,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ImportacoesAnnotationComposer
    extends Composer<_$BancoLocal, Importacoes> {
  $ImportacoesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get formato =>
      $composableBuilder(column: $table.formato, builder: (column) => column);

  GeneratedColumn<String> get nomeArquivo => $composableBuilder(
    column: $table.nomeArquivo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hashArquivo => $composableBuilder(
    column: $table.hashArquivo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get parserCodigo => $composableBuilder(
    column: $table.parserCodigo,
    builder: (column) => column,
  );

  GeneratedColumn<int> get parserVersao => $composableBuilder(
    column: $table.parserVersao,
    builder: (column) => column,
  );

  GeneratedColumn<String> get previaJson => $composableBuilder(
    column: $table.previaJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get periodoInicio => $composableBuilder(
    column: $table.periodoInicio,
    builder: (column) => column,
  );

  GeneratedColumn<String> get periodoFim => $composableBuilder(
    column: $table.periodoFim,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalLinhas => $composableBuilder(
    column: $table.totalLinhas,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalImportadas => $composableBuilder(
    column: $table.totalImportadas,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalDuplicadas => $composableBuilder(
    column: $table.totalDuplicadas,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalIgnoradas => $composableBuilder(
    column: $table.totalIgnoradas,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get erroDetalhe => $composableBuilder(
    column: $table.erroDetalhe,
    builder: (column) => column,
  );

  GeneratedColumn<int> get criadoEm =>
      $composableBuilder(column: $table.criadoEm, builder: (column) => column);

  $ContasBancariasAnnotationComposer get contaId {
    final $ContasBancariasAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contaId,
      referencedTable: $db.contasBancarias,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ContasBancariasAnnotationComposer(
            $db: $db,
            $table: $db.contasBancarias,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> transacoesRefs<T extends Object>(
    Expression<T> Function($TransacoesAnnotationComposer a) f,
  ) {
    final $TransacoesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transacoes,
      getReferencedColumn: (t) => t.importacaoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TransacoesAnnotationComposer(
            $db: $db,
            $table: $db.transacoes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $ImportacoesTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          Importacoes,
          Importacao,
          $ImportacoesFilterComposer,
          $ImportacoesOrderingComposer,
          $ImportacoesAnnotationComposer,
          $ImportacoesCreateCompanionBuilder,
          $ImportacoesUpdateCompanionBuilder,
          (Importacao, $ImportacoesReferences),
          Importacao,
          PrefetchHooks Function({bool contaId, bool transacoesRefs})
        > {
  $ImportacoesTableManager(_$BancoLocal db, Importacoes table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ImportacoesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ImportacoesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ImportacoesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> contaId = const Value.absent(),
                Value<String> formato = const Value.absent(),
                Value<String> nomeArquivo = const Value.absent(),
                Value<String> hashArquivo = const Value.absent(),
                Value<String?> parserCodigo = const Value.absent(),
                Value<int?> parserVersao = const Value.absent(),
                Value<String?> previaJson = const Value.absent(),
                Value<String?> periodoInicio = const Value.absent(),
                Value<String?> periodoFim = const Value.absent(),
                Value<int?> totalLinhas = const Value.absent(),
                Value<int?> totalImportadas = const Value.absent(),
                Value<int?> totalDuplicadas = const Value.absent(),
                Value<int?> totalIgnoradas = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> erroDetalhe = const Value.absent(),
                Value<int> criadoEm = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImportacoesCompanion(
                id: id,
                contaId: contaId,
                formato: formato,
                nomeArquivo: nomeArquivo,
                hashArquivo: hashArquivo,
                parserCodigo: parserCodigo,
                parserVersao: parserVersao,
                previaJson: previaJson,
                periodoInicio: periodoInicio,
                periodoFim: periodoFim,
                totalLinhas: totalLinhas,
                totalImportadas: totalImportadas,
                totalDuplicadas: totalDuplicadas,
                totalIgnoradas: totalIgnoradas,
                status: status,
                erroDetalhe: erroDetalhe,
                criadoEm: criadoEm,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String contaId,
                required String formato,
                required String nomeArquivo,
                required String hashArquivo,
                Value<String?> parserCodigo = const Value.absent(),
                Value<int?> parserVersao = const Value.absent(),
                Value<String?> previaJson = const Value.absent(),
                Value<String?> periodoInicio = const Value.absent(),
                Value<String?> periodoFim = const Value.absent(),
                Value<int?> totalLinhas = const Value.absent(),
                Value<int?> totalImportadas = const Value.absent(),
                Value<int?> totalDuplicadas = const Value.absent(),
                Value<int?> totalIgnoradas = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> erroDetalhe = const Value.absent(),
                required int criadoEm,
                Value<int> rowid = const Value.absent(),
              }) => ImportacoesCompanion.insert(
                id: id,
                contaId: contaId,
                formato: formato,
                nomeArquivo: nomeArquivo,
                hashArquivo: hashArquivo,
                parserCodigo: parserCodigo,
                parserVersao: parserVersao,
                previaJson: previaJson,
                periodoInicio: periodoInicio,
                periodoFim: periodoFim,
                totalLinhas: totalLinhas,
                totalImportadas: totalImportadas,
                totalDuplicadas: totalDuplicadas,
                totalIgnoradas: totalIgnoradas,
                status: status,
                erroDetalhe: erroDetalhe,
                criadoEm: criadoEm,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $ImportacoesReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({contaId = false, transacoesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (transacoesRefs) db.transacoes],
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
                    if (contaId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.contaId,
                                referencedTable: $ImportacoesReferences
                                    ._contaIdTable(db),
                                referencedColumn: $ImportacoesReferences
                                    ._contaIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transacoesRefs)
                    await $_getPrefetchedData<
                      Importacao,
                      Importacoes,
                      Transacao
                    >(
                      currentTable: table,
                      referencedTable: $ImportacoesReferences
                          ._transacoesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $ImportacoesReferences(db, table, p0).transacoesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.importacaoId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $ImportacoesProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      Importacoes,
      Importacao,
      $ImportacoesFilterComposer,
      $ImportacoesOrderingComposer,
      $ImportacoesAnnotationComposer,
      $ImportacoesCreateCompanionBuilder,
      $ImportacoesUpdateCompanionBuilder,
      (Importacao, $ImportacoesReferences),
      Importacao,
      PrefetchHooks Function({bool contaId, bool transacoesRefs})
    >;
typedef $TransacoesCreateCompanionBuilder =
    TransacoesCompanion Function({
      required String id,
      required String contaId,
      Value<String?> importacaoId,
      required String data,
      required int valorCentavos,
      required String descricaoRaw,
      Value<String?> fitid,
      Value<String?> contraparteNomeRaw,
      Value<String?> contraparteDoc,
      Value<String?> contraparteTipo,
      required int criadoEm,
      Value<int> rowid,
    });
typedef $TransacoesUpdateCompanionBuilder =
    TransacoesCompanion Function({
      Value<String> id,
      Value<String> contaId,
      Value<String?> importacaoId,
      Value<String> data,
      Value<int> valorCentavos,
      Value<String> descricaoRaw,
      Value<String?> fitid,
      Value<String?> contraparteNomeRaw,
      Value<String?> contraparteDoc,
      Value<String?> contraparteTipo,
      Value<int> criadoEm,
      Value<int> rowid,
    });

final class $TransacoesReferences
    extends BaseReferences<_$BancoLocal, Transacoes, Transacao> {
  $TransacoesReferences(super.$_db, super.$_table, super.$_typedResult);

  static ContasBancarias _contaIdTable(_$BancoLocal db) => db.contasBancarias
      .createAlias('transacoes__conta_id__contas_bancarias__id');

  $ContasBancariasProcessedTableManager get contaId {
    final $_column = $_itemColumn<String>('conta_id')!;

    final manager = $ContasBancariasTableManager(
      $_db,
      $_db.contasBancarias,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_contaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Importacoes _importacaoIdTable(_$BancoLocal db) =>
      db.importacoes.createAlias('transacoes__importacao_id__importacoes__id');

  $ImportacoesProcessedTableManager? get importacaoId {
    final $_column = $_itemColumn<String>('importacao_id');
    if ($_column == null) return null;
    final manager = $ImportacoesTableManager(
      $_db,
      $_db.importacoes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_importacaoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<Lancamentos, List<Lancamento>>
  _lancamentosRefsTable(_$BancoLocal db) => MultiTypedResultKey.fromTable(
    db.lancamentos,
    aliasName: 'transacoes__id__lancamentos__transacao_id',
  );

  $LancamentosProcessedTableManager get lancamentosRefs {
    final manager = $LancamentosTableManager(
      $_db,
      $_db.lancamentos,
    ).filter((f) => f.transacaoId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_lancamentosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $TransacoesFilterComposer extends Composer<_$BancoLocal, Transacoes> {
  $TransacoesFilterComposer({
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

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get valorCentavos => $composableBuilder(
    column: $table.valorCentavos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descricaoRaw => $composableBuilder(
    column: $table.descricaoRaw,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fitid => $composableBuilder(
    column: $table.fitid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contraparteNomeRaw => $composableBuilder(
    column: $table.contraparteNomeRaw,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contraparteDoc => $composableBuilder(
    column: $table.contraparteDoc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contraparteTipo => $composableBuilder(
    column: $table.contraparteTipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get criadoEm => $composableBuilder(
    column: $table.criadoEm,
    builder: (column) => ColumnFilters(column),
  );

  $ContasBancariasFilterComposer get contaId {
    final $ContasBancariasFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contaId,
      referencedTable: $db.contasBancarias,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ContasBancariasFilterComposer(
            $db: $db,
            $table: $db.contasBancarias,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $ImportacoesFilterComposer get importacaoId {
    final $ImportacoesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.importacaoId,
      referencedTable: $db.importacoes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ImportacoesFilterComposer(
            $db: $db,
            $table: $db.importacoes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> lancamentosRefs(
    Expression<bool> Function($LancamentosFilterComposer f) f,
  ) {
    final $LancamentosFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lancamentos,
      getReferencedColumn: (t) => t.transacaoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $LancamentosFilterComposer(
            $db: $db,
            $table: $db.lancamentos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $TransacoesOrderingComposer extends Composer<_$BancoLocal, Transacoes> {
  $TransacoesOrderingComposer({
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

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get valorCentavos => $composableBuilder(
    column: $table.valorCentavos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descricaoRaw => $composableBuilder(
    column: $table.descricaoRaw,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fitid => $composableBuilder(
    column: $table.fitid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contraparteNomeRaw => $composableBuilder(
    column: $table.contraparteNomeRaw,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contraparteDoc => $composableBuilder(
    column: $table.contraparteDoc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contraparteTipo => $composableBuilder(
    column: $table.contraparteTipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get criadoEm => $composableBuilder(
    column: $table.criadoEm,
    builder: (column) => ColumnOrderings(column),
  );

  $ContasBancariasOrderingComposer get contaId {
    final $ContasBancariasOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contaId,
      referencedTable: $db.contasBancarias,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ContasBancariasOrderingComposer(
            $db: $db,
            $table: $db.contasBancarias,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $ImportacoesOrderingComposer get importacaoId {
    final $ImportacoesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.importacaoId,
      referencedTable: $db.importacoes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ImportacoesOrderingComposer(
            $db: $db,
            $table: $db.importacoes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $TransacoesAnnotationComposer extends Composer<_$BancoLocal, Transacoes> {
  $TransacoesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<int> get valorCentavos => $composableBuilder(
    column: $table.valorCentavos,
    builder: (column) => column,
  );

  GeneratedColumn<String> get descricaoRaw => $composableBuilder(
    column: $table.descricaoRaw,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fitid =>
      $composableBuilder(column: $table.fitid, builder: (column) => column);

  GeneratedColumn<String> get contraparteNomeRaw => $composableBuilder(
    column: $table.contraparteNomeRaw,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contraparteDoc => $composableBuilder(
    column: $table.contraparteDoc,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contraparteTipo => $composableBuilder(
    column: $table.contraparteTipo,
    builder: (column) => column,
  );

  GeneratedColumn<int> get criadoEm =>
      $composableBuilder(column: $table.criadoEm, builder: (column) => column);

  $ContasBancariasAnnotationComposer get contaId {
    final $ContasBancariasAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contaId,
      referencedTable: $db.contasBancarias,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ContasBancariasAnnotationComposer(
            $db: $db,
            $table: $db.contasBancarias,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $ImportacoesAnnotationComposer get importacaoId {
    final $ImportacoesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.importacaoId,
      referencedTable: $db.importacoes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ImportacoesAnnotationComposer(
            $db: $db,
            $table: $db.importacoes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> lancamentosRefs<T extends Object>(
    Expression<T> Function($LancamentosAnnotationComposer a) f,
  ) {
    final $LancamentosAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lancamentos,
      getReferencedColumn: (t) => t.transacaoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $LancamentosAnnotationComposer(
            $db: $db,
            $table: $db.lancamentos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $TransacoesTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          Transacoes,
          Transacao,
          $TransacoesFilterComposer,
          $TransacoesOrderingComposer,
          $TransacoesAnnotationComposer,
          $TransacoesCreateCompanionBuilder,
          $TransacoesUpdateCompanionBuilder,
          (Transacao, $TransacoesReferences),
          Transacao,
          PrefetchHooks Function({
            bool contaId,
            bool importacaoId,
            bool lancamentosRefs,
          })
        > {
  $TransacoesTableManager(_$BancoLocal db, Transacoes table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $TransacoesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $TransacoesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $TransacoesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> contaId = const Value.absent(),
                Value<String?> importacaoId = const Value.absent(),
                Value<String> data = const Value.absent(),
                Value<int> valorCentavos = const Value.absent(),
                Value<String> descricaoRaw = const Value.absent(),
                Value<String?> fitid = const Value.absent(),
                Value<String?> contraparteNomeRaw = const Value.absent(),
                Value<String?> contraparteDoc = const Value.absent(),
                Value<String?> contraparteTipo = const Value.absent(),
                Value<int> criadoEm = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransacoesCompanion(
                id: id,
                contaId: contaId,
                importacaoId: importacaoId,
                data: data,
                valorCentavos: valorCentavos,
                descricaoRaw: descricaoRaw,
                fitid: fitid,
                contraparteNomeRaw: contraparteNomeRaw,
                contraparteDoc: contraparteDoc,
                contraparteTipo: contraparteTipo,
                criadoEm: criadoEm,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String contaId,
                Value<String?> importacaoId = const Value.absent(),
                required String data,
                required int valorCentavos,
                required String descricaoRaw,
                Value<String?> fitid = const Value.absent(),
                Value<String?> contraparteNomeRaw = const Value.absent(),
                Value<String?> contraparteDoc = const Value.absent(),
                Value<String?> contraparteTipo = const Value.absent(),
                required int criadoEm,
                Value<int> rowid = const Value.absent(),
              }) => TransacoesCompanion.insert(
                id: id,
                contaId: contaId,
                importacaoId: importacaoId,
                data: data,
                valorCentavos: valorCentavos,
                descricaoRaw: descricaoRaw,
                fitid: fitid,
                contraparteNomeRaw: contraparteNomeRaw,
                contraparteDoc: contraparteDoc,
                contraparteTipo: contraparteTipo,
                criadoEm: criadoEm,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $TransacoesReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                contaId = false,
                importacaoId = false,
                lancamentosRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (lancamentosRefs) db.lancamentos,
                  ],
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
                        if (contaId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.contaId,
                                    referencedTable: $TransacoesReferences
                                        ._contaIdTable(db),
                                    referencedColumn: $TransacoesReferences
                                        ._contaIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (importacaoId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.importacaoId,
                                    referencedTable: $TransacoesReferences
                                        ._importacaoIdTable(db),
                                    referencedColumn: $TransacoesReferences
                                        ._importacaoIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (lancamentosRefs)
                        await $_getPrefetchedData<
                          Transacao,
                          Transacoes,
                          Lancamento
                        >(
                          currentTable: table,
                          referencedTable: $TransacoesReferences
                              ._lancamentosRefsTable(db),
                          managerFromTypedResult: (p0) => $TransacoesReferences(
                            db,
                            table,
                            p0,
                          ).lancamentosRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.transacaoId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $TransacoesProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      Transacoes,
      Transacao,
      $TransacoesFilterComposer,
      $TransacoesOrderingComposer,
      $TransacoesAnnotationComposer,
      $TransacoesCreateCompanionBuilder,
      $TransacoesUpdateCompanionBuilder,
      (Transacao, $TransacoesReferences),
      Transacao,
      PrefetchHooks Function({
        bool contaId,
        bool importacaoId,
        bool lancamentosRefs,
      })
    >;
typedef $RemetentesCreateCompanionBuilder =
    RemetentesCompanion Function({
      required String id,
      required String nome,
      Value<String?> cpf,
      Value<String?> classificacaoPadrao,
      Value<String?> titularRemetenteId,
      Value<String?> observacoes,
      required int criadoEm,
      Value<int> rowid,
    });
typedef $RemetentesUpdateCompanionBuilder =
    RemetentesCompanion Function({
      Value<String> id,
      Value<String> nome,
      Value<String?> cpf,
      Value<String?> classificacaoPadrao,
      Value<String?> titularRemetenteId,
      Value<String?> observacoes,
      Value<int> criadoEm,
      Value<int> rowid,
    });

final class $RemetentesReferences
    extends BaseReferences<_$BancoLocal, Remetentes, Remetente> {
  $RemetentesReferences(super.$_db, super.$_table, super.$_typedResult);

  static Remetentes _titularRemetenteIdTable(_$BancoLocal db) => db.remetentes
      .createAlias('remetentes__titular_remetente_id__remetentes__id');

  $RemetentesProcessedTableManager? get titularRemetenteId {
    final $_column = $_itemColumn<String>('titular_remetente_id');
    if ($_column == null) return null;
    final manager = $RemetentesTableManager(
      $_db,
      $_db.remetentes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_titularRemetenteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<Lancamentos, List<Lancamento>>
  _lancamentosRefsTable(_$BancoLocal db) => MultiTypedResultKey.fromTable(
    db.lancamentos,
    aliasName: 'remetentes__id__lancamentos__remetente_id',
  );

  $LancamentosProcessedTableManager get lancamentosRefs {
    final manager = $LancamentosTableManager(
      $_db,
      $_db.lancamentos,
    ).filter((f) => f.remetenteId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_lancamentosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $RemetentesFilterComposer extends Composer<_$BancoLocal, Remetentes> {
  $RemetentesFilterComposer({
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

  ColumnFilters<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cpf => $composableBuilder(
    column: $table.cpf,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get classificacaoPadrao => $composableBuilder(
    column: $table.classificacaoPadrao,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get observacoes => $composableBuilder(
    column: $table.observacoes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get criadoEm => $composableBuilder(
    column: $table.criadoEm,
    builder: (column) => ColumnFilters(column),
  );

  $RemetentesFilterComposer get titularRemetenteId {
    final $RemetentesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.titularRemetenteId,
      referencedTable: $db.remetentes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RemetentesFilterComposer(
            $db: $db,
            $table: $db.remetentes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> lancamentosRefs(
    Expression<bool> Function($LancamentosFilterComposer f) f,
  ) {
    final $LancamentosFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lancamentos,
      getReferencedColumn: (t) => t.remetenteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $LancamentosFilterComposer(
            $db: $db,
            $table: $db.lancamentos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $RemetentesOrderingComposer extends Composer<_$BancoLocal, Remetentes> {
  $RemetentesOrderingComposer({
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

  ColumnOrderings<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cpf => $composableBuilder(
    column: $table.cpf,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get classificacaoPadrao => $composableBuilder(
    column: $table.classificacaoPadrao,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get observacoes => $composableBuilder(
    column: $table.observacoes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get criadoEm => $composableBuilder(
    column: $table.criadoEm,
    builder: (column) => ColumnOrderings(column),
  );

  $RemetentesOrderingComposer get titularRemetenteId {
    final $RemetentesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.titularRemetenteId,
      referencedTable: $db.remetentes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RemetentesOrderingComposer(
            $db: $db,
            $table: $db.remetentes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $RemetentesAnnotationComposer extends Composer<_$BancoLocal, Remetentes> {
  $RemetentesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<String> get cpf =>
      $composableBuilder(column: $table.cpf, builder: (column) => column);

  GeneratedColumn<String> get classificacaoPadrao => $composableBuilder(
    column: $table.classificacaoPadrao,
    builder: (column) => column,
  );

  GeneratedColumn<String> get observacoes => $composableBuilder(
    column: $table.observacoes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get criadoEm =>
      $composableBuilder(column: $table.criadoEm, builder: (column) => column);

  $RemetentesAnnotationComposer get titularRemetenteId {
    final $RemetentesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.titularRemetenteId,
      referencedTable: $db.remetentes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RemetentesAnnotationComposer(
            $db: $db,
            $table: $db.remetentes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> lancamentosRefs<T extends Object>(
    Expression<T> Function($LancamentosAnnotationComposer a) f,
  ) {
    final $LancamentosAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lancamentos,
      getReferencedColumn: (t) => t.remetenteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $LancamentosAnnotationComposer(
            $db: $db,
            $table: $db.lancamentos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $RemetentesTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          Remetentes,
          Remetente,
          $RemetentesFilterComposer,
          $RemetentesOrderingComposer,
          $RemetentesAnnotationComposer,
          $RemetentesCreateCompanionBuilder,
          $RemetentesUpdateCompanionBuilder,
          (Remetente, $RemetentesReferences),
          Remetente,
          PrefetchHooks Function({
            bool titularRemetenteId,
            bool lancamentosRefs,
          })
        > {
  $RemetentesTableManager(_$BancoLocal db, Remetentes table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $RemetentesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $RemetentesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $RemetentesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nome = const Value.absent(),
                Value<String?> cpf = const Value.absent(),
                Value<String?> classificacaoPadrao = const Value.absent(),
                Value<String?> titularRemetenteId = const Value.absent(),
                Value<String?> observacoes = const Value.absent(),
                Value<int> criadoEm = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemetentesCompanion(
                id: id,
                nome: nome,
                cpf: cpf,
                classificacaoPadrao: classificacaoPadrao,
                titularRemetenteId: titularRemetenteId,
                observacoes: observacoes,
                criadoEm: criadoEm,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nome,
                Value<String?> cpf = const Value.absent(),
                Value<String?> classificacaoPadrao = const Value.absent(),
                Value<String?> titularRemetenteId = const Value.absent(),
                Value<String?> observacoes = const Value.absent(),
                required int criadoEm,
                Value<int> rowid = const Value.absent(),
              }) => RemetentesCompanion.insert(
                id: id,
                nome: nome,
                cpf: cpf,
                classificacaoPadrao: classificacaoPadrao,
                titularRemetenteId: titularRemetenteId,
                observacoes: observacoes,
                criadoEm: criadoEm,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $RemetentesReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({titularRemetenteId = false, lancamentosRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (lancamentosRefs) db.lancamentos,
                  ],
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
                        if (titularRemetenteId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.titularRemetenteId,
                                    referencedTable: $RemetentesReferences
                                        ._titularRemetenteIdTable(db),
                                    referencedColumn: $RemetentesReferences
                                        ._titularRemetenteIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (lancamentosRefs)
                        await $_getPrefetchedData<
                          Remetente,
                          Remetentes,
                          Lancamento
                        >(
                          currentTable: table,
                          referencedTable: $RemetentesReferences
                              ._lancamentosRefsTable(db),
                          managerFromTypedResult: (p0) => $RemetentesReferences(
                            db,
                            table,
                            p0,
                          ).lancamentosRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.remetenteId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $RemetentesProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      Remetentes,
      Remetente,
      $RemetentesFilterComposer,
      $RemetentesOrderingComposer,
      $RemetentesAnnotationComposer,
      $RemetentesCreateCompanionBuilder,
      $RemetentesUpdateCompanionBuilder,
      (Remetente, $RemetentesReferences),
      Remetente,
      PrefetchHooks Function({bool titularRemetenteId, bool lancamentosRefs})
    >;
typedef $ApuracoesMensaisCreateCompanionBuilder =
    ApuracoesMensaisCompanion Function({
      required String id,
      required String competencia,
      Value<int> versao,
      Value<String> status,
      required int receitaBrutaCentavos,
      required int despesasLivroCaixaCentavos,
      Value<int> saldoNegativoAnteriorCentavos,
      Value<int> saldoNegativoUtilizadoCentavos,
      Value<int> saldoNegativoTransportadoCentavos,
      required int inssCentavos,
      required int qtdeDependentes,
      required int deducaoDependentesCentavos,
      required int descontoSimplificadoCentavos,
      required int impostoCenarioRealCentavos,
      required int impostoCenarioSimplificadoCentavos,
      required String cenarioAplicado,
      required int baseCalculoCentavos,
      required int aliquotaBp,
      required int parcelaDeduzirCentavos,
      required int impostoApuradoCentavos,
      Value<int> redutorLeiCentavos,
      required int impostoDevidoCentavos,
      Value<int> impostoDiferidoAnteriorCentavos,
      Value<int> impostoDiferidoCentavos,
      Value<int> isento,
      required int tabelaIrpfId,
      required String catalogoVersoesSnapshot,
      required String parametrosSnapshot,
      required String motorVersao,
      required String appVersao,
      required int calculadaEm,
      Value<int?> fechadaEm,
      Value<int> rowid,
    });
typedef $ApuracoesMensaisUpdateCompanionBuilder =
    ApuracoesMensaisCompanion Function({
      Value<String> id,
      Value<String> competencia,
      Value<int> versao,
      Value<String> status,
      Value<int> receitaBrutaCentavos,
      Value<int> despesasLivroCaixaCentavos,
      Value<int> saldoNegativoAnteriorCentavos,
      Value<int> saldoNegativoUtilizadoCentavos,
      Value<int> saldoNegativoTransportadoCentavos,
      Value<int> inssCentavos,
      Value<int> qtdeDependentes,
      Value<int> deducaoDependentesCentavos,
      Value<int> descontoSimplificadoCentavos,
      Value<int> impostoCenarioRealCentavos,
      Value<int> impostoCenarioSimplificadoCentavos,
      Value<String> cenarioAplicado,
      Value<int> baseCalculoCentavos,
      Value<int> aliquotaBp,
      Value<int> parcelaDeduzirCentavos,
      Value<int> impostoApuradoCentavos,
      Value<int> redutorLeiCentavos,
      Value<int> impostoDevidoCentavos,
      Value<int> impostoDiferidoAnteriorCentavos,
      Value<int> impostoDiferidoCentavos,
      Value<int> isento,
      Value<int> tabelaIrpfId,
      Value<String> catalogoVersoesSnapshot,
      Value<String> parametrosSnapshot,
      Value<String> motorVersao,
      Value<String> appVersao,
      Value<int> calculadaEm,
      Value<int?> fechadaEm,
      Value<int> rowid,
    });

final class $ApuracoesMensaisReferences
    extends BaseReferences<_$BancoLocal, ApuracoesMensais, ApuracaoLocal> {
  $ApuracoesMensaisReferences(super.$_db, super.$_table, super.$_typedResult);

  static CatTabelasIrpf _tabelaIrpfIdTable(_$BancoLocal db) => db.catTabelasIrpf
      .createAlias('apuracoes_mensais__tabela_irpf_id__cat_tabelas_irpf__id');

  $CatTabelasIrpfProcessedTableManager get tabelaIrpfId {
    final $_column = $_itemColumn<int>('tabela_irpf_id')!;

    final manager = $CatTabelasIrpfTableManager(
      $_db,
      $_db.catTabelasIrpf,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tabelaIrpfIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<Lancamentos, List<Lancamento>>
  _lancamentosRefsTable(_$BancoLocal db) => MultiTypedResultKey.fromTable(
    db.lancamentos,
    aliasName: 'apuracoes_mensais__id__lancamentos__apuracao_id',
  );

  $LancamentosProcessedTableManager get lancamentosRefs {
    final manager = $LancamentosTableManager(
      $_db,
      $_db.lancamentos,
    ).filter((f) => f.apuracaoId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_lancamentosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<DespesasLivroCaixa, List<DespesaLivroCaixa>>
  _despesasLivroCaixaRefsTable(_$BancoLocal db) =>
      MultiTypedResultKey.fromTable(
        db.despesasLivroCaixa,
        aliasName: 'apuracoes_mensais__id__despesas_livro_caixa__apuracao_id',
      );

  $DespesasLivroCaixaProcessedTableManager get despesasLivroCaixaRefs {
    final manager = $DespesasLivroCaixaTableManager(
      $_db,
      $_db.despesasLivroCaixa,
    ).filter((f) => f.apuracaoId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _despesasLivroCaixaRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<Darfs, List<DarfLocal>> _darfsRefsTable(
    _$BancoLocal db,
  ) => MultiTypedResultKey.fromTable(
    db.darfs,
    aliasName: 'apuracoes_mensais__id__darfs__apuracao_id',
  );

  $DarfsProcessedTableManager get darfsRefs {
    final manager = $DarfsTableManager(
      $_db,
      $_db.darfs,
    ).filter((f) => f.apuracaoId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_darfsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $ApuracoesMensaisFilterComposer
    extends Composer<_$BancoLocal, ApuracoesMensais> {
  $ApuracoesMensaisFilterComposer({
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

  ColumnFilters<String> get competencia => $composableBuilder(
    column: $table.competencia,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get versao => $composableBuilder(
    column: $table.versao,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get receitaBrutaCentavos => $composableBuilder(
    column: $table.receitaBrutaCentavos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get despesasLivroCaixaCentavos => $composableBuilder(
    column: $table.despesasLivroCaixaCentavos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get saldoNegativoAnteriorCentavos => $composableBuilder(
    column: $table.saldoNegativoAnteriorCentavos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get saldoNegativoUtilizadoCentavos => $composableBuilder(
    column: $table.saldoNegativoUtilizadoCentavos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get saldoNegativoTransportadoCentavos =>
      $composableBuilder(
        column: $table.saldoNegativoTransportadoCentavos,
        builder: (column) => ColumnFilters(column),
      );

  ColumnFilters<int> get inssCentavos => $composableBuilder(
    column: $table.inssCentavos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get qtdeDependentes => $composableBuilder(
    column: $table.qtdeDependentes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deducaoDependentesCentavos => $composableBuilder(
    column: $table.deducaoDependentesCentavos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get descontoSimplificadoCentavos => $composableBuilder(
    column: $table.descontoSimplificadoCentavos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get impostoCenarioRealCentavos => $composableBuilder(
    column: $table.impostoCenarioRealCentavos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get impostoCenarioSimplificadoCentavos =>
      $composableBuilder(
        column: $table.impostoCenarioSimplificadoCentavos,
        builder: (column) => ColumnFilters(column),
      );

  ColumnFilters<String> get cenarioAplicado => $composableBuilder(
    column: $table.cenarioAplicado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseCalculoCentavos => $composableBuilder(
    column: $table.baseCalculoCentavos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get aliquotaBp => $composableBuilder(
    column: $table.aliquotaBp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get parcelaDeduzirCentavos => $composableBuilder(
    column: $table.parcelaDeduzirCentavos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get impostoApuradoCentavos => $composableBuilder(
    column: $table.impostoApuradoCentavos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get redutorLeiCentavos => $composableBuilder(
    column: $table.redutorLeiCentavos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get impostoDevidoCentavos => $composableBuilder(
    column: $table.impostoDevidoCentavos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get impostoDiferidoAnteriorCentavos => $composableBuilder(
    column: $table.impostoDiferidoAnteriorCentavos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get impostoDiferidoCentavos => $composableBuilder(
    column: $table.impostoDiferidoCentavos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isento => $composableBuilder(
    column: $table.isento,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get catalogoVersoesSnapshot => $composableBuilder(
    column: $table.catalogoVersoesSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parametrosSnapshot => $composableBuilder(
    column: $table.parametrosSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get motorVersao => $composableBuilder(
    column: $table.motorVersao,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appVersao => $composableBuilder(
    column: $table.appVersao,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get calculadaEm => $composableBuilder(
    column: $table.calculadaEm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fechadaEm => $composableBuilder(
    column: $table.fechadaEm,
    builder: (column) => ColumnFilters(column),
  );

  $CatTabelasIrpfFilterComposer get tabelaIrpfId {
    final $CatTabelasIrpfFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tabelaIrpfId,
      referencedTable: $db.catTabelasIrpf,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CatTabelasIrpfFilterComposer(
            $db: $db,
            $table: $db.catTabelasIrpf,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> lancamentosRefs(
    Expression<bool> Function($LancamentosFilterComposer f) f,
  ) {
    final $LancamentosFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lancamentos,
      getReferencedColumn: (t) => t.apuracaoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $LancamentosFilterComposer(
            $db: $db,
            $table: $db.lancamentos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> despesasLivroCaixaRefs(
    Expression<bool> Function($DespesasLivroCaixaFilterComposer f) f,
  ) {
    final $DespesasLivroCaixaFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.despesasLivroCaixa,
      getReferencedColumn: (t) => t.apuracaoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $DespesasLivroCaixaFilterComposer(
            $db: $db,
            $table: $db.despesasLivroCaixa,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> darfsRefs(
    Expression<bool> Function($DarfsFilterComposer f) f,
  ) {
    final $DarfsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.darfs,
      getReferencedColumn: (t) => t.apuracaoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $DarfsFilterComposer(
            $db: $db,
            $table: $db.darfs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $ApuracoesMensaisOrderingComposer
    extends Composer<_$BancoLocal, ApuracoesMensais> {
  $ApuracoesMensaisOrderingComposer({
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

  ColumnOrderings<String> get competencia => $composableBuilder(
    column: $table.competencia,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get versao => $composableBuilder(
    column: $table.versao,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get receitaBrutaCentavos => $composableBuilder(
    column: $table.receitaBrutaCentavos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get despesasLivroCaixaCentavos => $composableBuilder(
    column: $table.despesasLivroCaixaCentavos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get saldoNegativoAnteriorCentavos => $composableBuilder(
    column: $table.saldoNegativoAnteriorCentavos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get saldoNegativoUtilizadoCentavos => $composableBuilder(
    column: $table.saldoNegativoUtilizadoCentavos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get saldoNegativoTransportadoCentavos =>
      $composableBuilder(
        column: $table.saldoNegativoTransportadoCentavos,
        builder: (column) => ColumnOrderings(column),
      );

  ColumnOrderings<int> get inssCentavos => $composableBuilder(
    column: $table.inssCentavos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get qtdeDependentes => $composableBuilder(
    column: $table.qtdeDependentes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deducaoDependentesCentavos => $composableBuilder(
    column: $table.deducaoDependentesCentavos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get descontoSimplificadoCentavos => $composableBuilder(
    column: $table.descontoSimplificadoCentavos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get impostoCenarioRealCentavos => $composableBuilder(
    column: $table.impostoCenarioRealCentavos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get impostoCenarioSimplificadoCentavos =>
      $composableBuilder(
        column: $table.impostoCenarioSimplificadoCentavos,
        builder: (column) => ColumnOrderings(column),
      );

  ColumnOrderings<String> get cenarioAplicado => $composableBuilder(
    column: $table.cenarioAplicado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseCalculoCentavos => $composableBuilder(
    column: $table.baseCalculoCentavos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get aliquotaBp => $composableBuilder(
    column: $table.aliquotaBp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get parcelaDeduzirCentavos => $composableBuilder(
    column: $table.parcelaDeduzirCentavos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get impostoApuradoCentavos => $composableBuilder(
    column: $table.impostoApuradoCentavos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get redutorLeiCentavos => $composableBuilder(
    column: $table.redutorLeiCentavos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get impostoDevidoCentavos => $composableBuilder(
    column: $table.impostoDevidoCentavos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get impostoDiferidoAnteriorCentavos =>
      $composableBuilder(
        column: $table.impostoDiferidoAnteriorCentavos,
        builder: (column) => ColumnOrderings(column),
      );

  ColumnOrderings<int> get impostoDiferidoCentavos => $composableBuilder(
    column: $table.impostoDiferidoCentavos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isento => $composableBuilder(
    column: $table.isento,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get catalogoVersoesSnapshot => $composableBuilder(
    column: $table.catalogoVersoesSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parametrosSnapshot => $composableBuilder(
    column: $table.parametrosSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get motorVersao => $composableBuilder(
    column: $table.motorVersao,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appVersao => $composableBuilder(
    column: $table.appVersao,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get calculadaEm => $composableBuilder(
    column: $table.calculadaEm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fechadaEm => $composableBuilder(
    column: $table.fechadaEm,
    builder: (column) => ColumnOrderings(column),
  );

  $CatTabelasIrpfOrderingComposer get tabelaIrpfId {
    final $CatTabelasIrpfOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tabelaIrpfId,
      referencedTable: $db.catTabelasIrpf,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CatTabelasIrpfOrderingComposer(
            $db: $db,
            $table: $db.catTabelasIrpf,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ApuracoesMensaisAnnotationComposer
    extends Composer<_$BancoLocal, ApuracoesMensais> {
  $ApuracoesMensaisAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get competencia => $composableBuilder(
    column: $table.competencia,
    builder: (column) => column,
  );

  GeneratedColumn<int> get versao =>
      $composableBuilder(column: $table.versao, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get receitaBrutaCentavos => $composableBuilder(
    column: $table.receitaBrutaCentavos,
    builder: (column) => column,
  );

  GeneratedColumn<int> get despesasLivroCaixaCentavos => $composableBuilder(
    column: $table.despesasLivroCaixaCentavos,
    builder: (column) => column,
  );

  GeneratedColumn<int> get saldoNegativoAnteriorCentavos => $composableBuilder(
    column: $table.saldoNegativoAnteriorCentavos,
    builder: (column) => column,
  );

  GeneratedColumn<int> get saldoNegativoUtilizadoCentavos => $composableBuilder(
    column: $table.saldoNegativoUtilizadoCentavos,
    builder: (column) => column,
  );

  GeneratedColumn<int> get saldoNegativoTransportadoCentavos =>
      $composableBuilder(
        column: $table.saldoNegativoTransportadoCentavos,
        builder: (column) => column,
      );

  GeneratedColumn<int> get inssCentavos => $composableBuilder(
    column: $table.inssCentavos,
    builder: (column) => column,
  );

  GeneratedColumn<int> get qtdeDependentes => $composableBuilder(
    column: $table.qtdeDependentes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deducaoDependentesCentavos => $composableBuilder(
    column: $table.deducaoDependentesCentavos,
    builder: (column) => column,
  );

  GeneratedColumn<int> get descontoSimplificadoCentavos => $composableBuilder(
    column: $table.descontoSimplificadoCentavos,
    builder: (column) => column,
  );

  GeneratedColumn<int> get impostoCenarioRealCentavos => $composableBuilder(
    column: $table.impostoCenarioRealCentavos,
    builder: (column) => column,
  );

  GeneratedColumn<int> get impostoCenarioSimplificadoCentavos =>
      $composableBuilder(
        column: $table.impostoCenarioSimplificadoCentavos,
        builder: (column) => column,
      );

  GeneratedColumn<String> get cenarioAplicado => $composableBuilder(
    column: $table.cenarioAplicado,
    builder: (column) => column,
  );

  GeneratedColumn<int> get baseCalculoCentavos => $composableBuilder(
    column: $table.baseCalculoCentavos,
    builder: (column) => column,
  );

  GeneratedColumn<int> get aliquotaBp => $composableBuilder(
    column: $table.aliquotaBp,
    builder: (column) => column,
  );

  GeneratedColumn<int> get parcelaDeduzirCentavos => $composableBuilder(
    column: $table.parcelaDeduzirCentavos,
    builder: (column) => column,
  );

  GeneratedColumn<int> get impostoApuradoCentavos => $composableBuilder(
    column: $table.impostoApuradoCentavos,
    builder: (column) => column,
  );

  GeneratedColumn<int> get redutorLeiCentavos => $composableBuilder(
    column: $table.redutorLeiCentavos,
    builder: (column) => column,
  );

  GeneratedColumn<int> get impostoDevidoCentavos => $composableBuilder(
    column: $table.impostoDevidoCentavos,
    builder: (column) => column,
  );

  GeneratedColumn<int> get impostoDiferidoAnteriorCentavos =>
      $composableBuilder(
        column: $table.impostoDiferidoAnteriorCentavos,
        builder: (column) => column,
      );

  GeneratedColumn<int> get impostoDiferidoCentavos => $composableBuilder(
    column: $table.impostoDiferidoCentavos,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isento =>
      $composableBuilder(column: $table.isento, builder: (column) => column);

  GeneratedColumn<String> get catalogoVersoesSnapshot => $composableBuilder(
    column: $table.catalogoVersoesSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get parametrosSnapshot => $composableBuilder(
    column: $table.parametrosSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get motorVersao => $composableBuilder(
    column: $table.motorVersao,
    builder: (column) => column,
  );

  GeneratedColumn<String> get appVersao =>
      $composableBuilder(column: $table.appVersao, builder: (column) => column);

  GeneratedColumn<int> get calculadaEm => $composableBuilder(
    column: $table.calculadaEm,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fechadaEm =>
      $composableBuilder(column: $table.fechadaEm, builder: (column) => column);

  $CatTabelasIrpfAnnotationComposer get tabelaIrpfId {
    final $CatTabelasIrpfAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tabelaIrpfId,
      referencedTable: $db.catTabelasIrpf,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CatTabelasIrpfAnnotationComposer(
            $db: $db,
            $table: $db.catTabelasIrpf,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> lancamentosRefs<T extends Object>(
    Expression<T> Function($LancamentosAnnotationComposer a) f,
  ) {
    final $LancamentosAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lancamentos,
      getReferencedColumn: (t) => t.apuracaoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $LancamentosAnnotationComposer(
            $db: $db,
            $table: $db.lancamentos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> despesasLivroCaixaRefs<T extends Object>(
    Expression<T> Function($DespesasLivroCaixaAnnotationComposer a) f,
  ) {
    final $DespesasLivroCaixaAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.despesasLivroCaixa,
      getReferencedColumn: (t) => t.apuracaoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $DespesasLivroCaixaAnnotationComposer(
            $db: $db,
            $table: $db.despesasLivroCaixa,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> darfsRefs<T extends Object>(
    Expression<T> Function($DarfsAnnotationComposer a) f,
  ) {
    final $DarfsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.darfs,
      getReferencedColumn: (t) => t.apuracaoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $DarfsAnnotationComposer(
            $db: $db,
            $table: $db.darfs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $ApuracoesMensaisTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          ApuracoesMensais,
          ApuracaoLocal,
          $ApuracoesMensaisFilterComposer,
          $ApuracoesMensaisOrderingComposer,
          $ApuracoesMensaisAnnotationComposer,
          $ApuracoesMensaisCreateCompanionBuilder,
          $ApuracoesMensaisUpdateCompanionBuilder,
          (ApuracaoLocal, $ApuracoesMensaisReferences),
          ApuracaoLocal,
          PrefetchHooks Function({
            bool tabelaIrpfId,
            bool lancamentosRefs,
            bool despesasLivroCaixaRefs,
            bool darfsRefs,
          })
        > {
  $ApuracoesMensaisTableManager(_$BancoLocal db, ApuracoesMensais table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ApuracoesMensaisFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ApuracoesMensaisOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ApuracoesMensaisAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> competencia = const Value.absent(),
                Value<int> versao = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> receitaBrutaCentavos = const Value.absent(),
                Value<int> despesasLivroCaixaCentavos = const Value.absent(),
                Value<int> saldoNegativoAnteriorCentavos = const Value.absent(),
                Value<int> saldoNegativoUtilizadoCentavos =
                    const Value.absent(),
                Value<int> saldoNegativoTransportadoCentavos =
                    const Value.absent(),
                Value<int> inssCentavos = const Value.absent(),
                Value<int> qtdeDependentes = const Value.absent(),
                Value<int> deducaoDependentesCentavos = const Value.absent(),
                Value<int> descontoSimplificadoCentavos = const Value.absent(),
                Value<int> impostoCenarioRealCentavos = const Value.absent(),
                Value<int> impostoCenarioSimplificadoCentavos =
                    const Value.absent(),
                Value<String> cenarioAplicado = const Value.absent(),
                Value<int> baseCalculoCentavos = const Value.absent(),
                Value<int> aliquotaBp = const Value.absent(),
                Value<int> parcelaDeduzirCentavos = const Value.absent(),
                Value<int> impostoApuradoCentavos = const Value.absent(),
                Value<int> redutorLeiCentavos = const Value.absent(),
                Value<int> impostoDevidoCentavos = const Value.absent(),
                Value<int> impostoDiferidoAnteriorCentavos =
                    const Value.absent(),
                Value<int> impostoDiferidoCentavos = const Value.absent(),
                Value<int> isento = const Value.absent(),
                Value<int> tabelaIrpfId = const Value.absent(),
                Value<String> catalogoVersoesSnapshot = const Value.absent(),
                Value<String> parametrosSnapshot = const Value.absent(),
                Value<String> motorVersao = const Value.absent(),
                Value<String> appVersao = const Value.absent(),
                Value<int> calculadaEm = const Value.absent(),
                Value<int?> fechadaEm = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ApuracoesMensaisCompanion(
                id: id,
                competencia: competencia,
                versao: versao,
                status: status,
                receitaBrutaCentavos: receitaBrutaCentavos,
                despesasLivroCaixaCentavos: despesasLivroCaixaCentavos,
                saldoNegativoAnteriorCentavos: saldoNegativoAnteriorCentavos,
                saldoNegativoUtilizadoCentavos: saldoNegativoUtilizadoCentavos,
                saldoNegativoTransportadoCentavos:
                    saldoNegativoTransportadoCentavos,
                inssCentavos: inssCentavos,
                qtdeDependentes: qtdeDependentes,
                deducaoDependentesCentavos: deducaoDependentesCentavos,
                descontoSimplificadoCentavos: descontoSimplificadoCentavos,
                impostoCenarioRealCentavos: impostoCenarioRealCentavos,
                impostoCenarioSimplificadoCentavos:
                    impostoCenarioSimplificadoCentavos,
                cenarioAplicado: cenarioAplicado,
                baseCalculoCentavos: baseCalculoCentavos,
                aliquotaBp: aliquotaBp,
                parcelaDeduzirCentavos: parcelaDeduzirCentavos,
                impostoApuradoCentavos: impostoApuradoCentavos,
                redutorLeiCentavos: redutorLeiCentavos,
                impostoDevidoCentavos: impostoDevidoCentavos,
                impostoDiferidoAnteriorCentavos:
                    impostoDiferidoAnteriorCentavos,
                impostoDiferidoCentavos: impostoDiferidoCentavos,
                isento: isento,
                tabelaIrpfId: tabelaIrpfId,
                catalogoVersoesSnapshot: catalogoVersoesSnapshot,
                parametrosSnapshot: parametrosSnapshot,
                motorVersao: motorVersao,
                appVersao: appVersao,
                calculadaEm: calculadaEm,
                fechadaEm: fechadaEm,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String competencia,
                Value<int> versao = const Value.absent(),
                Value<String> status = const Value.absent(),
                required int receitaBrutaCentavos,
                required int despesasLivroCaixaCentavos,
                Value<int> saldoNegativoAnteriorCentavos = const Value.absent(),
                Value<int> saldoNegativoUtilizadoCentavos =
                    const Value.absent(),
                Value<int> saldoNegativoTransportadoCentavos =
                    const Value.absent(),
                required int inssCentavos,
                required int qtdeDependentes,
                required int deducaoDependentesCentavos,
                required int descontoSimplificadoCentavos,
                required int impostoCenarioRealCentavos,
                required int impostoCenarioSimplificadoCentavos,
                required String cenarioAplicado,
                required int baseCalculoCentavos,
                required int aliquotaBp,
                required int parcelaDeduzirCentavos,
                required int impostoApuradoCentavos,
                Value<int> redutorLeiCentavos = const Value.absent(),
                required int impostoDevidoCentavos,
                Value<int> impostoDiferidoAnteriorCentavos =
                    const Value.absent(),
                Value<int> impostoDiferidoCentavos = const Value.absent(),
                Value<int> isento = const Value.absent(),
                required int tabelaIrpfId,
                required String catalogoVersoesSnapshot,
                required String parametrosSnapshot,
                required String motorVersao,
                required String appVersao,
                required int calculadaEm,
                Value<int?> fechadaEm = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ApuracoesMensaisCompanion.insert(
                id: id,
                competencia: competencia,
                versao: versao,
                status: status,
                receitaBrutaCentavos: receitaBrutaCentavos,
                despesasLivroCaixaCentavos: despesasLivroCaixaCentavos,
                saldoNegativoAnteriorCentavos: saldoNegativoAnteriorCentavos,
                saldoNegativoUtilizadoCentavos: saldoNegativoUtilizadoCentavos,
                saldoNegativoTransportadoCentavos:
                    saldoNegativoTransportadoCentavos,
                inssCentavos: inssCentavos,
                qtdeDependentes: qtdeDependentes,
                deducaoDependentesCentavos: deducaoDependentesCentavos,
                descontoSimplificadoCentavos: descontoSimplificadoCentavos,
                impostoCenarioRealCentavos: impostoCenarioRealCentavos,
                impostoCenarioSimplificadoCentavos:
                    impostoCenarioSimplificadoCentavos,
                cenarioAplicado: cenarioAplicado,
                baseCalculoCentavos: baseCalculoCentavos,
                aliquotaBp: aliquotaBp,
                parcelaDeduzirCentavos: parcelaDeduzirCentavos,
                impostoApuradoCentavos: impostoApuradoCentavos,
                redutorLeiCentavos: redutorLeiCentavos,
                impostoDevidoCentavos: impostoDevidoCentavos,
                impostoDiferidoAnteriorCentavos:
                    impostoDiferidoAnteriorCentavos,
                impostoDiferidoCentavos: impostoDiferidoCentavos,
                isento: isento,
                tabelaIrpfId: tabelaIrpfId,
                catalogoVersoesSnapshot: catalogoVersoesSnapshot,
                parametrosSnapshot: parametrosSnapshot,
                motorVersao: motorVersao,
                appVersao: appVersao,
                calculadaEm: calculadaEm,
                fechadaEm: fechadaEm,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $ApuracoesMensaisReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                tabelaIrpfId = false,
                lancamentosRefs = false,
                despesasLivroCaixaRefs = false,
                darfsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (lancamentosRefs) db.lancamentos,
                    if (despesasLivroCaixaRefs) db.despesasLivroCaixa,
                    if (darfsRefs) db.darfs,
                  ],
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
                        if (tabelaIrpfId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.tabelaIrpfId,
                                    referencedTable: $ApuracoesMensaisReferences
                                        ._tabelaIrpfIdTable(db),
                                    referencedColumn:
                                        $ApuracoesMensaisReferences
                                            ._tabelaIrpfIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (lancamentosRefs)
                        await $_getPrefetchedData<
                          ApuracaoLocal,
                          ApuracoesMensais,
                          Lancamento
                        >(
                          currentTable: table,
                          referencedTable: $ApuracoesMensaisReferences
                              ._lancamentosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $ApuracoesMensaisReferences(
                                db,
                                table,
                                p0,
                              ).lancamentosRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.apuracaoId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (despesasLivroCaixaRefs)
                        await $_getPrefetchedData<
                          ApuracaoLocal,
                          ApuracoesMensais,
                          DespesaLivroCaixa
                        >(
                          currentTable: table,
                          referencedTable: $ApuracoesMensaisReferences
                              ._despesasLivroCaixaRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $ApuracoesMensaisReferences(
                                db,
                                table,
                                p0,
                              ).despesasLivroCaixaRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.apuracaoId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (darfsRefs)
                        await $_getPrefetchedData<
                          ApuracaoLocal,
                          ApuracoesMensais,
                          DarfLocal
                        >(
                          currentTable: table,
                          referencedTable: $ApuracoesMensaisReferences
                              ._darfsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $ApuracoesMensaisReferences(
                                db,
                                table,
                                p0,
                              ).darfsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.apuracaoId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $ApuracoesMensaisProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      ApuracoesMensais,
      ApuracaoLocal,
      $ApuracoesMensaisFilterComposer,
      $ApuracoesMensaisOrderingComposer,
      $ApuracoesMensaisAnnotationComposer,
      $ApuracoesMensaisCreateCompanionBuilder,
      $ApuracoesMensaisUpdateCompanionBuilder,
      (ApuracaoLocal, $ApuracoesMensaisReferences),
      ApuracaoLocal,
      PrefetchHooks Function({
        bool tabelaIrpfId,
        bool lancamentosRefs,
        bool despesasLivroCaixaRefs,
        bool darfsRefs,
      })
    >;
typedef $LancamentosCreateCompanionBuilder =
    LancamentosCompanion Function({
      required String id,
      Value<String?> transacaoId,
      required String competencia,
      required String dataRecebimento,
      required int valorCentavos,
      required String classificacao,
      Value<String?> remetenteId,
      Value<String?> cpfPagador,
      Value<String?> nomePagador,
      Value<String> origemClassificacao,
      Value<String?> apuracaoId,
      required int criadoEm,
      required int atualizadoEm,
      Value<int> rowid,
    });
typedef $LancamentosUpdateCompanionBuilder =
    LancamentosCompanion Function({
      Value<String> id,
      Value<String?> transacaoId,
      Value<String> competencia,
      Value<String> dataRecebimento,
      Value<int> valorCentavos,
      Value<String> classificacao,
      Value<String?> remetenteId,
      Value<String?> cpfPagador,
      Value<String?> nomePagador,
      Value<String> origemClassificacao,
      Value<String?> apuracaoId,
      Value<int> criadoEm,
      Value<int> atualizadoEm,
      Value<int> rowid,
    });

final class $LancamentosReferences
    extends BaseReferences<_$BancoLocal, Lancamentos, Lancamento> {
  $LancamentosReferences(super.$_db, super.$_table, super.$_typedResult);

  static Transacoes _transacaoIdTable(_$BancoLocal db) =>
      db.transacoes.createAlias('lancamentos__transacao_id__transacoes__id');

  $TransacoesProcessedTableManager? get transacaoId {
    final $_column = $_itemColumn<String>('transacao_id');
    if ($_column == null) return null;
    final manager = $TransacoesTableManager(
      $_db,
      $_db.transacoes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_transacaoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Remetentes _remetenteIdTable(_$BancoLocal db) =>
      db.remetentes.createAlias('lancamentos__remetente_id__remetentes__id');

  $RemetentesProcessedTableManager? get remetenteId {
    final $_column = $_itemColumn<String>('remetente_id');
    if ($_column == null) return null;
    final manager = $RemetentesTableManager(
      $_db,
      $_db.remetentes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_remetenteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static ApuracoesMensais _apuracaoIdTable(_$BancoLocal db) => db
      .apuracoesMensais
      .createAlias('lancamentos__apuracao_id__apuracoes_mensais__id');

  $ApuracoesMensaisProcessedTableManager? get apuracaoId {
    final $_column = $_itemColumn<String>('apuracao_id');
    if ($_column == null) return null;
    final manager = $ApuracoesMensaisTableManager(
      $_db,
      $_db.apuracoesMensais,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_apuracaoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    HistoricoClassificacaoTable,
    List<HistoricoClassificacao>
  >
  _historicoClassificacaoRefsTable(_$BancoLocal db) =>
      MultiTypedResultKey.fromTable(
        db.historicoClassificacao,
        aliasName: 'lancamentos__id__historico_classificacao__lancamento_id',
      );

  $HistoricoClassificacaoTableProcessedTableManager
  get historicoClassificacaoRefs {
    final manager = $HistoricoClassificacaoTableTableManager(
      $_db,
      $_db.historicoClassificacao,
    ).filter((f) => f.lancamentoId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _historicoClassificacaoRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $LancamentosFilterComposer extends Composer<_$BancoLocal, Lancamentos> {
  $LancamentosFilterComposer({
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

  ColumnFilters<String> get competencia => $composableBuilder(
    column: $table.competencia,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataRecebimento => $composableBuilder(
    column: $table.dataRecebimento,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get valorCentavos => $composableBuilder(
    column: $table.valorCentavos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get classificacao => $composableBuilder(
    column: $table.classificacao,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cpfPagador => $composableBuilder(
    column: $table.cpfPagador,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nomePagador => $composableBuilder(
    column: $table.nomePagador,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origemClassificacao => $composableBuilder(
    column: $table.origemClassificacao,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get criadoEm => $composableBuilder(
    column: $table.criadoEm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get atualizadoEm => $composableBuilder(
    column: $table.atualizadoEm,
    builder: (column) => ColumnFilters(column),
  );

  $TransacoesFilterComposer get transacaoId {
    final $TransacoesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transacaoId,
      referencedTable: $db.transacoes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TransacoesFilterComposer(
            $db: $db,
            $table: $db.transacoes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $RemetentesFilterComposer get remetenteId {
    final $RemetentesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.remetenteId,
      referencedTable: $db.remetentes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RemetentesFilterComposer(
            $db: $db,
            $table: $db.remetentes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $ApuracoesMensaisFilterComposer get apuracaoId {
    final $ApuracoesMensaisFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.apuracaoId,
      referencedTable: $db.apuracoesMensais,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ApuracoesMensaisFilterComposer(
            $db: $db,
            $table: $db.apuracoesMensais,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> historicoClassificacaoRefs(
    Expression<bool> Function($HistoricoClassificacaoTableFilterComposer f) f,
  ) {
    final $HistoricoClassificacaoTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.historicoClassificacao,
          getReferencedColumn: (t) => t.lancamentoId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $HistoricoClassificacaoTableFilterComposer(
                $db: $db,
                $table: $db.historicoClassificacao,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $LancamentosOrderingComposer extends Composer<_$BancoLocal, Lancamentos> {
  $LancamentosOrderingComposer({
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

  ColumnOrderings<String> get competencia => $composableBuilder(
    column: $table.competencia,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataRecebimento => $composableBuilder(
    column: $table.dataRecebimento,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get valorCentavos => $composableBuilder(
    column: $table.valorCentavos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get classificacao => $composableBuilder(
    column: $table.classificacao,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cpfPagador => $composableBuilder(
    column: $table.cpfPagador,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nomePagador => $composableBuilder(
    column: $table.nomePagador,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origemClassificacao => $composableBuilder(
    column: $table.origemClassificacao,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get criadoEm => $composableBuilder(
    column: $table.criadoEm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get atualizadoEm => $composableBuilder(
    column: $table.atualizadoEm,
    builder: (column) => ColumnOrderings(column),
  );

  $TransacoesOrderingComposer get transacaoId {
    final $TransacoesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transacaoId,
      referencedTable: $db.transacoes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TransacoesOrderingComposer(
            $db: $db,
            $table: $db.transacoes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $RemetentesOrderingComposer get remetenteId {
    final $RemetentesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.remetenteId,
      referencedTable: $db.remetentes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RemetentesOrderingComposer(
            $db: $db,
            $table: $db.remetentes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $ApuracoesMensaisOrderingComposer get apuracaoId {
    final $ApuracoesMensaisOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.apuracaoId,
      referencedTable: $db.apuracoesMensais,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ApuracoesMensaisOrderingComposer(
            $db: $db,
            $table: $db.apuracoesMensais,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $LancamentosAnnotationComposer
    extends Composer<_$BancoLocal, Lancamentos> {
  $LancamentosAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get competencia => $composableBuilder(
    column: $table.competencia,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dataRecebimento => $composableBuilder(
    column: $table.dataRecebimento,
    builder: (column) => column,
  );

  GeneratedColumn<int> get valorCentavos => $composableBuilder(
    column: $table.valorCentavos,
    builder: (column) => column,
  );

  GeneratedColumn<String> get classificacao => $composableBuilder(
    column: $table.classificacao,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cpfPagador => $composableBuilder(
    column: $table.cpfPagador,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nomePagador => $composableBuilder(
    column: $table.nomePagador,
    builder: (column) => column,
  );

  GeneratedColumn<String> get origemClassificacao => $composableBuilder(
    column: $table.origemClassificacao,
    builder: (column) => column,
  );

  GeneratedColumn<int> get criadoEm =>
      $composableBuilder(column: $table.criadoEm, builder: (column) => column);

  GeneratedColumn<int> get atualizadoEm => $composableBuilder(
    column: $table.atualizadoEm,
    builder: (column) => column,
  );

  $TransacoesAnnotationComposer get transacaoId {
    final $TransacoesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transacaoId,
      referencedTable: $db.transacoes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TransacoesAnnotationComposer(
            $db: $db,
            $table: $db.transacoes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $RemetentesAnnotationComposer get remetenteId {
    final $RemetentesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.remetenteId,
      referencedTable: $db.remetentes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RemetentesAnnotationComposer(
            $db: $db,
            $table: $db.remetentes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $ApuracoesMensaisAnnotationComposer get apuracaoId {
    final $ApuracoesMensaisAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.apuracaoId,
      referencedTable: $db.apuracoesMensais,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ApuracoesMensaisAnnotationComposer(
            $db: $db,
            $table: $db.apuracoesMensais,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> historicoClassificacaoRefs<T extends Object>(
    Expression<T> Function($HistoricoClassificacaoTableAnnotationComposer a) f,
  ) {
    final $HistoricoClassificacaoTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.historicoClassificacao,
          getReferencedColumn: (t) => t.lancamentoId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $HistoricoClassificacaoTableAnnotationComposer(
                $db: $db,
                $table: $db.historicoClassificacao,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $LancamentosTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          Lancamentos,
          Lancamento,
          $LancamentosFilterComposer,
          $LancamentosOrderingComposer,
          $LancamentosAnnotationComposer,
          $LancamentosCreateCompanionBuilder,
          $LancamentosUpdateCompanionBuilder,
          (Lancamento, $LancamentosReferences),
          Lancamento,
          PrefetchHooks Function({
            bool transacaoId,
            bool remetenteId,
            bool apuracaoId,
            bool historicoClassificacaoRefs,
          })
        > {
  $LancamentosTableManager(_$BancoLocal db, Lancamentos table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $LancamentosFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $LancamentosOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $LancamentosAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> transacaoId = const Value.absent(),
                Value<String> competencia = const Value.absent(),
                Value<String> dataRecebimento = const Value.absent(),
                Value<int> valorCentavos = const Value.absent(),
                Value<String> classificacao = const Value.absent(),
                Value<String?> remetenteId = const Value.absent(),
                Value<String?> cpfPagador = const Value.absent(),
                Value<String?> nomePagador = const Value.absent(),
                Value<String> origemClassificacao = const Value.absent(),
                Value<String?> apuracaoId = const Value.absent(),
                Value<int> criadoEm = const Value.absent(),
                Value<int> atualizadoEm = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LancamentosCompanion(
                id: id,
                transacaoId: transacaoId,
                competencia: competencia,
                dataRecebimento: dataRecebimento,
                valorCentavos: valorCentavos,
                classificacao: classificacao,
                remetenteId: remetenteId,
                cpfPagador: cpfPagador,
                nomePagador: nomePagador,
                origemClassificacao: origemClassificacao,
                apuracaoId: apuracaoId,
                criadoEm: criadoEm,
                atualizadoEm: atualizadoEm,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> transacaoId = const Value.absent(),
                required String competencia,
                required String dataRecebimento,
                required int valorCentavos,
                required String classificacao,
                Value<String?> remetenteId = const Value.absent(),
                Value<String?> cpfPagador = const Value.absent(),
                Value<String?> nomePagador = const Value.absent(),
                Value<String> origemClassificacao = const Value.absent(),
                Value<String?> apuracaoId = const Value.absent(),
                required int criadoEm,
                required int atualizadoEm,
                Value<int> rowid = const Value.absent(),
              }) => LancamentosCompanion.insert(
                id: id,
                transacaoId: transacaoId,
                competencia: competencia,
                dataRecebimento: dataRecebimento,
                valorCentavos: valorCentavos,
                classificacao: classificacao,
                remetenteId: remetenteId,
                cpfPagador: cpfPagador,
                nomePagador: nomePagador,
                origemClassificacao: origemClassificacao,
                apuracaoId: apuracaoId,
                criadoEm: criadoEm,
                atualizadoEm: atualizadoEm,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $LancamentosReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                transacaoId = false,
                remetenteId = false,
                apuracaoId = false,
                historicoClassificacaoRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (historicoClassificacaoRefs) db.historicoClassificacao,
                  ],
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
                        if (transacaoId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.transacaoId,
                                    referencedTable: $LancamentosReferences
                                        ._transacaoIdTable(db),
                                    referencedColumn: $LancamentosReferences
                                        ._transacaoIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (remetenteId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.remetenteId,
                                    referencedTable: $LancamentosReferences
                                        ._remetenteIdTable(db),
                                    referencedColumn: $LancamentosReferences
                                        ._remetenteIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (apuracaoId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.apuracaoId,
                                    referencedTable: $LancamentosReferences
                                        ._apuracaoIdTable(db),
                                    referencedColumn: $LancamentosReferences
                                        ._apuracaoIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (historicoClassificacaoRefs)
                        await $_getPrefetchedData<
                          Lancamento,
                          Lancamentos,
                          HistoricoClassificacao
                        >(
                          currentTable: table,
                          referencedTable: $LancamentosReferences
                              ._historicoClassificacaoRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $LancamentosReferences(
                                db,
                                table,
                                p0,
                              ).historicoClassificacaoRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.lancamentoId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $LancamentosProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      Lancamentos,
      Lancamento,
      $LancamentosFilterComposer,
      $LancamentosOrderingComposer,
      $LancamentosAnnotationComposer,
      $LancamentosCreateCompanionBuilder,
      $LancamentosUpdateCompanionBuilder,
      (Lancamento, $LancamentosReferences),
      Lancamento,
      PrefetchHooks Function({
        bool transacaoId,
        bool remetenteId,
        bool apuracaoId,
        bool historicoClassificacaoRefs,
      })
    >;
typedef $HistoricoClassificacaoTableCreateCompanionBuilder =
    HistoricoClassificacaoCompanion Function({
      Value<int> id,
      required String lancamentoId,
      Value<String?> de,
      required String para,
      Value<String?> motivo,
      required int criadoEm,
    });
typedef $HistoricoClassificacaoTableUpdateCompanionBuilder =
    HistoricoClassificacaoCompanion Function({
      Value<int> id,
      Value<String> lancamentoId,
      Value<String?> de,
      Value<String> para,
      Value<String?> motivo,
      Value<int> criadoEm,
    });

final class $HistoricoClassificacaoTableReferences
    extends
        BaseReferences<
          _$BancoLocal,
          HistoricoClassificacaoTable,
          HistoricoClassificacao
        > {
  $HistoricoClassificacaoTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static Lancamentos _lancamentoIdTable(_$BancoLocal db) => db.lancamentos
      .createAlias('historico_classificacao__lancamento_id__lancamentos__id');

  $LancamentosProcessedTableManager get lancamentoId {
    final $_column = $_itemColumn<String>('lancamento_id')!;

    final manager = $LancamentosTableManager(
      $_db,
      $_db.lancamentos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_lancamentoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $HistoricoClassificacaoTableFilterComposer
    extends Composer<_$BancoLocal, HistoricoClassificacaoTable> {
  $HistoricoClassificacaoTableFilterComposer({
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

  ColumnFilters<String> get de => $composableBuilder(
    column: $table.de,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get para => $composableBuilder(
    column: $table.para,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get motivo => $composableBuilder(
    column: $table.motivo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get criadoEm => $composableBuilder(
    column: $table.criadoEm,
    builder: (column) => ColumnFilters(column),
  );

  $LancamentosFilterComposer get lancamentoId {
    final $LancamentosFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lancamentoId,
      referencedTable: $db.lancamentos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $LancamentosFilterComposer(
            $db: $db,
            $table: $db.lancamentos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $HistoricoClassificacaoTableOrderingComposer
    extends Composer<_$BancoLocal, HistoricoClassificacaoTable> {
  $HistoricoClassificacaoTableOrderingComposer({
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

  ColumnOrderings<String> get de => $composableBuilder(
    column: $table.de,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get para => $composableBuilder(
    column: $table.para,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get motivo => $composableBuilder(
    column: $table.motivo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get criadoEm => $composableBuilder(
    column: $table.criadoEm,
    builder: (column) => ColumnOrderings(column),
  );

  $LancamentosOrderingComposer get lancamentoId {
    final $LancamentosOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lancamentoId,
      referencedTable: $db.lancamentos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $LancamentosOrderingComposer(
            $db: $db,
            $table: $db.lancamentos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $HistoricoClassificacaoTableAnnotationComposer
    extends Composer<_$BancoLocal, HistoricoClassificacaoTable> {
  $HistoricoClassificacaoTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get de =>
      $composableBuilder(column: $table.de, builder: (column) => column);

  GeneratedColumn<String> get para =>
      $composableBuilder(column: $table.para, builder: (column) => column);

  GeneratedColumn<String> get motivo =>
      $composableBuilder(column: $table.motivo, builder: (column) => column);

  GeneratedColumn<int> get criadoEm =>
      $composableBuilder(column: $table.criadoEm, builder: (column) => column);

  $LancamentosAnnotationComposer get lancamentoId {
    final $LancamentosAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lancamentoId,
      referencedTable: $db.lancamentos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $LancamentosAnnotationComposer(
            $db: $db,
            $table: $db.lancamentos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $HistoricoClassificacaoTableTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          HistoricoClassificacaoTable,
          HistoricoClassificacao,
          $HistoricoClassificacaoTableFilterComposer,
          $HistoricoClassificacaoTableOrderingComposer,
          $HistoricoClassificacaoTableAnnotationComposer,
          $HistoricoClassificacaoTableCreateCompanionBuilder,
          $HistoricoClassificacaoTableUpdateCompanionBuilder,
          (HistoricoClassificacao, $HistoricoClassificacaoTableReferences),
          HistoricoClassificacao,
          PrefetchHooks Function({bool lancamentoId})
        > {
  $HistoricoClassificacaoTableTableManager(
    _$BancoLocal db,
    HistoricoClassificacaoTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $HistoricoClassificacaoTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $HistoricoClassificacaoTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $HistoricoClassificacaoTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> lancamentoId = const Value.absent(),
                Value<String?> de = const Value.absent(),
                Value<String> para = const Value.absent(),
                Value<String?> motivo = const Value.absent(),
                Value<int> criadoEm = const Value.absent(),
              }) => HistoricoClassificacaoCompanion(
                id: id,
                lancamentoId: lancamentoId,
                de: de,
                para: para,
                motivo: motivo,
                criadoEm: criadoEm,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String lancamentoId,
                Value<String?> de = const Value.absent(),
                required String para,
                Value<String?> motivo = const Value.absent(),
                required int criadoEm,
              }) => HistoricoClassificacaoCompanion.insert(
                id: id,
                lancamentoId: lancamentoId,
                de: de,
                para: para,
                motivo: motivo,
                criadoEm: criadoEm,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $HistoricoClassificacaoTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({lancamentoId = false}) {
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
                    if (lancamentoId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.lancamentoId,
                                referencedTable:
                                    $HistoricoClassificacaoTableReferences
                                        ._lancamentoIdTable(db),
                                referencedColumn:
                                    $HistoricoClassificacaoTableReferences
                                        ._lancamentoIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $HistoricoClassificacaoTableProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      HistoricoClassificacaoTable,
      HistoricoClassificacao,
      $HistoricoClassificacaoTableFilterComposer,
      $HistoricoClassificacaoTableOrderingComposer,
      $HistoricoClassificacaoTableAnnotationComposer,
      $HistoricoClassificacaoTableCreateCompanionBuilder,
      $HistoricoClassificacaoTableUpdateCompanionBuilder,
      (HistoricoClassificacao, $HistoricoClassificacaoTableReferences),
      HistoricoClassificacao,
      PrefetchHooks Function({bool lancamentoId})
    >;
typedef $DespesasLivroCaixaCreateCompanionBuilder =
    DespesasLivroCaixaCompanion Function({
      required String id,
      required String rubricaCodigo,
      required String competencia,
      required String dataPagamento,
      required int valorCentavos,
      required int valorDedutivelCentavos,
      Value<String?> descricao,
      Value<int> homeOffice,
      Value<String?> anexoPath,
      Value<String?> apuracaoId,
      required int criadoEm,
      Value<int> rowid,
    });
typedef $DespesasLivroCaixaUpdateCompanionBuilder =
    DespesasLivroCaixaCompanion Function({
      Value<String> id,
      Value<String> rubricaCodigo,
      Value<String> competencia,
      Value<String> dataPagamento,
      Value<int> valorCentavos,
      Value<int> valorDedutivelCentavos,
      Value<String?> descricao,
      Value<int> homeOffice,
      Value<String?> anexoPath,
      Value<String?> apuracaoId,
      Value<int> criadoEm,
      Value<int> rowid,
    });

final class $DespesasLivroCaixaReferences
    extends
        BaseReferences<_$BancoLocal, DespesasLivroCaixa, DespesaLivroCaixa> {
  $DespesasLivroCaixaReferences(super.$_db, super.$_table, super.$_typedResult);

  static CatRubricas _rubricaCodigoTable(_$BancoLocal db) =>
      db.catRubricas.createAlias(
        'despesas_livro_caixa__rubrica_codigo__cat_rubricas__codigo',
      );

  $CatRubricasProcessedTableManager get rubricaCodigo {
    final $_column = $_itemColumn<String>('rubrica_codigo')!;

    final manager = $CatRubricasTableManager(
      $_db,
      $_db.catRubricas,
    ).filter((f) => f.codigo.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_rubricaCodigoTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static ApuracoesMensais _apuracaoIdTable(_$BancoLocal db) => db
      .apuracoesMensais
      .createAlias('despesas_livro_caixa__apuracao_id__apuracoes_mensais__id');

  $ApuracoesMensaisProcessedTableManager? get apuracaoId {
    final $_column = $_itemColumn<String>('apuracao_id');
    if ($_column == null) return null;
    final manager = $ApuracoesMensaisTableManager(
      $_db,
      $_db.apuracoesMensais,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_apuracaoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $DespesasLivroCaixaFilterComposer
    extends Composer<_$BancoLocal, DespesasLivroCaixa> {
  $DespesasLivroCaixaFilterComposer({
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

  ColumnFilters<String> get competencia => $composableBuilder(
    column: $table.competencia,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataPagamento => $composableBuilder(
    column: $table.dataPagamento,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get valorCentavos => $composableBuilder(
    column: $table.valorCentavos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get valorDedutivelCentavos => $composableBuilder(
    column: $table.valorDedutivelCentavos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descricao => $composableBuilder(
    column: $table.descricao,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get homeOffice => $composableBuilder(
    column: $table.homeOffice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get anexoPath => $composableBuilder(
    column: $table.anexoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get criadoEm => $composableBuilder(
    column: $table.criadoEm,
    builder: (column) => ColumnFilters(column),
  );

  $CatRubricasFilterComposer get rubricaCodigo {
    final $CatRubricasFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rubricaCodigo,
      referencedTable: $db.catRubricas,
      getReferencedColumn: (t) => t.codigo,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CatRubricasFilterComposer(
            $db: $db,
            $table: $db.catRubricas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $ApuracoesMensaisFilterComposer get apuracaoId {
    final $ApuracoesMensaisFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.apuracaoId,
      referencedTable: $db.apuracoesMensais,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ApuracoesMensaisFilterComposer(
            $db: $db,
            $table: $db.apuracoesMensais,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $DespesasLivroCaixaOrderingComposer
    extends Composer<_$BancoLocal, DespesasLivroCaixa> {
  $DespesasLivroCaixaOrderingComposer({
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

  ColumnOrderings<String> get competencia => $composableBuilder(
    column: $table.competencia,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataPagamento => $composableBuilder(
    column: $table.dataPagamento,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get valorCentavos => $composableBuilder(
    column: $table.valorCentavos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get valorDedutivelCentavos => $composableBuilder(
    column: $table.valorDedutivelCentavos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descricao => $composableBuilder(
    column: $table.descricao,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get homeOffice => $composableBuilder(
    column: $table.homeOffice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get anexoPath => $composableBuilder(
    column: $table.anexoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get criadoEm => $composableBuilder(
    column: $table.criadoEm,
    builder: (column) => ColumnOrderings(column),
  );

  $CatRubricasOrderingComposer get rubricaCodigo {
    final $CatRubricasOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rubricaCodigo,
      referencedTable: $db.catRubricas,
      getReferencedColumn: (t) => t.codigo,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CatRubricasOrderingComposer(
            $db: $db,
            $table: $db.catRubricas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $ApuracoesMensaisOrderingComposer get apuracaoId {
    final $ApuracoesMensaisOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.apuracaoId,
      referencedTable: $db.apuracoesMensais,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ApuracoesMensaisOrderingComposer(
            $db: $db,
            $table: $db.apuracoesMensais,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $DespesasLivroCaixaAnnotationComposer
    extends Composer<_$BancoLocal, DespesasLivroCaixa> {
  $DespesasLivroCaixaAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get competencia => $composableBuilder(
    column: $table.competencia,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dataPagamento => $composableBuilder(
    column: $table.dataPagamento,
    builder: (column) => column,
  );

  GeneratedColumn<int> get valorCentavos => $composableBuilder(
    column: $table.valorCentavos,
    builder: (column) => column,
  );

  GeneratedColumn<int> get valorDedutivelCentavos => $composableBuilder(
    column: $table.valorDedutivelCentavos,
    builder: (column) => column,
  );

  GeneratedColumn<String> get descricao =>
      $composableBuilder(column: $table.descricao, builder: (column) => column);

  GeneratedColumn<int> get homeOffice => $composableBuilder(
    column: $table.homeOffice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get anexoPath =>
      $composableBuilder(column: $table.anexoPath, builder: (column) => column);

  GeneratedColumn<int> get criadoEm =>
      $composableBuilder(column: $table.criadoEm, builder: (column) => column);

  $CatRubricasAnnotationComposer get rubricaCodigo {
    final $CatRubricasAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rubricaCodigo,
      referencedTable: $db.catRubricas,
      getReferencedColumn: (t) => t.codigo,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CatRubricasAnnotationComposer(
            $db: $db,
            $table: $db.catRubricas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $ApuracoesMensaisAnnotationComposer get apuracaoId {
    final $ApuracoesMensaisAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.apuracaoId,
      referencedTable: $db.apuracoesMensais,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ApuracoesMensaisAnnotationComposer(
            $db: $db,
            $table: $db.apuracoesMensais,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $DespesasLivroCaixaTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          DespesasLivroCaixa,
          DespesaLivroCaixa,
          $DespesasLivroCaixaFilterComposer,
          $DespesasLivroCaixaOrderingComposer,
          $DespesasLivroCaixaAnnotationComposer,
          $DespesasLivroCaixaCreateCompanionBuilder,
          $DespesasLivroCaixaUpdateCompanionBuilder,
          (DespesaLivroCaixa, $DespesasLivroCaixaReferences),
          DespesaLivroCaixa,
          PrefetchHooks Function({bool rubricaCodigo, bool apuracaoId})
        > {
  $DespesasLivroCaixaTableManager(_$BancoLocal db, DespesasLivroCaixa table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $DespesasLivroCaixaFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $DespesasLivroCaixaOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $DespesasLivroCaixaAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> rubricaCodigo = const Value.absent(),
                Value<String> competencia = const Value.absent(),
                Value<String> dataPagamento = const Value.absent(),
                Value<int> valorCentavos = const Value.absent(),
                Value<int> valorDedutivelCentavos = const Value.absent(),
                Value<String?> descricao = const Value.absent(),
                Value<int> homeOffice = const Value.absent(),
                Value<String?> anexoPath = const Value.absent(),
                Value<String?> apuracaoId = const Value.absent(),
                Value<int> criadoEm = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DespesasLivroCaixaCompanion(
                id: id,
                rubricaCodigo: rubricaCodigo,
                competencia: competencia,
                dataPagamento: dataPagamento,
                valorCentavos: valorCentavos,
                valorDedutivelCentavos: valorDedutivelCentavos,
                descricao: descricao,
                homeOffice: homeOffice,
                anexoPath: anexoPath,
                apuracaoId: apuracaoId,
                criadoEm: criadoEm,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String rubricaCodigo,
                required String competencia,
                required String dataPagamento,
                required int valorCentavos,
                required int valorDedutivelCentavos,
                Value<String?> descricao = const Value.absent(),
                Value<int> homeOffice = const Value.absent(),
                Value<String?> anexoPath = const Value.absent(),
                Value<String?> apuracaoId = const Value.absent(),
                required int criadoEm,
                Value<int> rowid = const Value.absent(),
              }) => DespesasLivroCaixaCompanion.insert(
                id: id,
                rubricaCodigo: rubricaCodigo,
                competencia: competencia,
                dataPagamento: dataPagamento,
                valorCentavos: valorCentavos,
                valorDedutivelCentavos: valorDedutivelCentavos,
                descricao: descricao,
                homeOffice: homeOffice,
                anexoPath: anexoPath,
                apuracaoId: apuracaoId,
                criadoEm: criadoEm,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $DespesasLivroCaixaReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({rubricaCodigo = false, apuracaoId = false}) {
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
                    if (rubricaCodigo) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.rubricaCodigo,
                                referencedTable: $DespesasLivroCaixaReferences
                                    ._rubricaCodigoTable(db),
                                referencedColumn: $DespesasLivroCaixaReferences
                                    ._rubricaCodigoTable(db)
                                    .codigo,
                              )
                              as T;
                    }
                    if (apuracaoId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.apuracaoId,
                                referencedTable: $DespesasLivroCaixaReferences
                                    ._apuracaoIdTable(db),
                                referencedColumn: $DespesasLivroCaixaReferences
                                    ._apuracaoIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $DespesasLivroCaixaProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      DespesasLivroCaixa,
      DespesaLivroCaixa,
      $DespesasLivroCaixaFilterComposer,
      $DespesasLivroCaixaOrderingComposer,
      $DespesasLivroCaixaAnnotationComposer,
      $DespesasLivroCaixaCreateCompanionBuilder,
      $DespesasLivroCaixaUpdateCompanionBuilder,
      (DespesaLivroCaixa, $DespesasLivroCaixaReferences),
      DespesaLivroCaixa,
      PrefetchHooks Function({bool rubricaCodigo, bool apuracaoId})
    >;
typedef $PagamentosInssCreateCompanionBuilder =
    PagamentosInssCompanion Function({
      required String id,
      required String competencia,
      required int valorCentavos,
      Value<String?> observacao,
      required int criadoEm,
      Value<int> rowid,
    });
typedef $PagamentosInssUpdateCompanionBuilder =
    PagamentosInssCompanion Function({
      Value<String> id,
      Value<String> competencia,
      Value<int> valorCentavos,
      Value<String?> observacao,
      Value<int> criadoEm,
      Value<int> rowid,
    });

class $PagamentosInssFilterComposer
    extends Composer<_$BancoLocal, PagamentosInss> {
  $PagamentosInssFilterComposer({
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

  ColumnFilters<String> get competencia => $composableBuilder(
    column: $table.competencia,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get valorCentavos => $composableBuilder(
    column: $table.valorCentavos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get observacao => $composableBuilder(
    column: $table.observacao,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get criadoEm => $composableBuilder(
    column: $table.criadoEm,
    builder: (column) => ColumnFilters(column),
  );
}

class $PagamentosInssOrderingComposer
    extends Composer<_$BancoLocal, PagamentosInss> {
  $PagamentosInssOrderingComposer({
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

  ColumnOrderings<String> get competencia => $composableBuilder(
    column: $table.competencia,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get valorCentavos => $composableBuilder(
    column: $table.valorCentavos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get observacao => $composableBuilder(
    column: $table.observacao,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get criadoEm => $composableBuilder(
    column: $table.criadoEm,
    builder: (column) => ColumnOrderings(column),
  );
}

class $PagamentosInssAnnotationComposer
    extends Composer<_$BancoLocal, PagamentosInss> {
  $PagamentosInssAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get competencia => $composableBuilder(
    column: $table.competencia,
    builder: (column) => column,
  );

  GeneratedColumn<int> get valorCentavos => $composableBuilder(
    column: $table.valorCentavos,
    builder: (column) => column,
  );

  GeneratedColumn<String> get observacao => $composableBuilder(
    column: $table.observacao,
    builder: (column) => column,
  );

  GeneratedColumn<int> get criadoEm =>
      $composableBuilder(column: $table.criadoEm, builder: (column) => column);
}

class $PagamentosInssTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          PagamentosInss,
          PagamentoInss,
          $PagamentosInssFilterComposer,
          $PagamentosInssOrderingComposer,
          $PagamentosInssAnnotationComposer,
          $PagamentosInssCreateCompanionBuilder,
          $PagamentosInssUpdateCompanionBuilder,
          (
            PagamentoInss,
            BaseReferences<_$BancoLocal, PagamentosInss, PagamentoInss>,
          ),
          PagamentoInss,
          PrefetchHooks Function()
        > {
  $PagamentosInssTableManager(_$BancoLocal db, PagamentosInss table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $PagamentosInssFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $PagamentosInssOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $PagamentosInssAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> competencia = const Value.absent(),
                Value<int> valorCentavos = const Value.absent(),
                Value<String?> observacao = const Value.absent(),
                Value<int> criadoEm = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PagamentosInssCompanion(
                id: id,
                competencia: competencia,
                valorCentavos: valorCentavos,
                observacao: observacao,
                criadoEm: criadoEm,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String competencia,
                required int valorCentavos,
                Value<String?> observacao = const Value.absent(),
                required int criadoEm,
                Value<int> rowid = const Value.absent(),
              }) => PagamentosInssCompanion.insert(
                id: id,
                competencia: competencia,
                valorCentavos: valorCentavos,
                observacao: observacao,
                criadoEm: criadoEm,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $PagamentosInssProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      PagamentosInss,
      PagamentoInss,
      $PagamentosInssFilterComposer,
      $PagamentosInssOrderingComposer,
      $PagamentosInssAnnotationComposer,
      $PagamentosInssCreateCompanionBuilder,
      $PagamentosInssUpdateCompanionBuilder,
      (
        PagamentoInss,
        BaseReferences<_$BancoLocal, PagamentosInss, PagamentoInss>,
      ),
      PagamentoInss,
      PrefetchHooks Function()
    >;
typedef $DependentesCreateCompanionBuilder =
    DependentesCompanion Function({
      required String id,
      required String nome,
      required String vigenciaInicio,
      Value<String?> vigenciaFim,
      required int criadoEm,
      Value<int> rowid,
    });
typedef $DependentesUpdateCompanionBuilder =
    DependentesCompanion Function({
      Value<String> id,
      Value<String> nome,
      Value<String> vigenciaInicio,
      Value<String?> vigenciaFim,
      Value<int> criadoEm,
      Value<int> rowid,
    });

class $DependentesFilterComposer extends Composer<_$BancoLocal, Dependentes> {
  $DependentesFilterComposer({
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

  ColumnFilters<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vigenciaInicio => $composableBuilder(
    column: $table.vigenciaInicio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vigenciaFim => $composableBuilder(
    column: $table.vigenciaFim,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get criadoEm => $composableBuilder(
    column: $table.criadoEm,
    builder: (column) => ColumnFilters(column),
  );
}

class $DependentesOrderingComposer extends Composer<_$BancoLocal, Dependentes> {
  $DependentesOrderingComposer({
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

  ColumnOrderings<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vigenciaInicio => $composableBuilder(
    column: $table.vigenciaInicio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vigenciaFim => $composableBuilder(
    column: $table.vigenciaFim,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get criadoEm => $composableBuilder(
    column: $table.criadoEm,
    builder: (column) => ColumnOrderings(column),
  );
}

class $DependentesAnnotationComposer
    extends Composer<_$BancoLocal, Dependentes> {
  $DependentesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<String> get vigenciaInicio => $composableBuilder(
    column: $table.vigenciaInicio,
    builder: (column) => column,
  );

  GeneratedColumn<String> get vigenciaFim => $composableBuilder(
    column: $table.vigenciaFim,
    builder: (column) => column,
  );

  GeneratedColumn<int> get criadoEm =>
      $composableBuilder(column: $table.criadoEm, builder: (column) => column);
}

class $DependentesTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          Dependentes,
          Dependente,
          $DependentesFilterComposer,
          $DependentesOrderingComposer,
          $DependentesAnnotationComposer,
          $DependentesCreateCompanionBuilder,
          $DependentesUpdateCompanionBuilder,
          (Dependente, BaseReferences<_$BancoLocal, Dependentes, Dependente>),
          Dependente,
          PrefetchHooks Function()
        > {
  $DependentesTableManager(_$BancoLocal db, Dependentes table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $DependentesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $DependentesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $DependentesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nome = const Value.absent(),
                Value<String> vigenciaInicio = const Value.absent(),
                Value<String?> vigenciaFim = const Value.absent(),
                Value<int> criadoEm = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DependentesCompanion(
                id: id,
                nome: nome,
                vigenciaInicio: vigenciaInicio,
                vigenciaFim: vigenciaFim,
                criadoEm: criadoEm,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nome,
                required String vigenciaInicio,
                Value<String?> vigenciaFim = const Value.absent(),
                required int criadoEm,
                Value<int> rowid = const Value.absent(),
              }) => DependentesCompanion.insert(
                id: id,
                nome: nome,
                vigenciaInicio: vigenciaInicio,
                vigenciaFim: vigenciaFim,
                criadoEm: criadoEm,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $DependentesProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      Dependentes,
      Dependente,
      $DependentesFilterComposer,
      $DependentesOrderingComposer,
      $DependentesAnnotationComposer,
      $DependentesCreateCompanionBuilder,
      $DependentesUpdateCompanionBuilder,
      (Dependente, BaseReferences<_$BancoLocal, Dependentes, Dependente>),
      Dependente,
      PrefetchHooks Function()
    >;
typedef $DarfsCreateCompanionBuilder =
    DarfsCompanion Function({
      required String id,
      required String apuracaoId,
      Value<String> codigoReceita,
      required String competencia,
      required int valorCentavos,
      required String vencimento,
      Value<int> vencimentoAntecipado,
      Value<String?> codigoBarras,
      Value<String> status,
      Value<String?> pagoEm,
      Value<int?> valorPagoCentavos,
      required int criadoEm,
      Value<int> rowid,
    });
typedef $DarfsUpdateCompanionBuilder =
    DarfsCompanion Function({
      Value<String> id,
      Value<String> apuracaoId,
      Value<String> codigoReceita,
      Value<String> competencia,
      Value<int> valorCentavos,
      Value<String> vencimento,
      Value<int> vencimentoAntecipado,
      Value<String?> codigoBarras,
      Value<String> status,
      Value<String?> pagoEm,
      Value<int?> valorPagoCentavos,
      Value<int> criadoEm,
      Value<int> rowid,
    });

final class $DarfsReferences
    extends BaseReferences<_$BancoLocal, Darfs, DarfLocal> {
  $DarfsReferences(super.$_db, super.$_table, super.$_typedResult);

  static ApuracoesMensais _apuracaoIdTable(_$BancoLocal db) => db
      .apuracoesMensais
      .createAlias('darfs__apuracao_id__apuracoes_mensais__id');

  $ApuracoesMensaisProcessedTableManager get apuracaoId {
    final $_column = $_itemColumn<String>('apuracao_id')!;

    final manager = $ApuracoesMensaisTableManager(
      $_db,
      $_db.apuracoesMensais,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_apuracaoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $DarfsFilterComposer extends Composer<_$BancoLocal, Darfs> {
  $DarfsFilterComposer({
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

  ColumnFilters<String> get codigoReceita => $composableBuilder(
    column: $table.codigoReceita,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get competencia => $composableBuilder(
    column: $table.competencia,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get valorCentavos => $composableBuilder(
    column: $table.valorCentavos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vencimento => $composableBuilder(
    column: $table.vencimento,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get vencimentoAntecipado => $composableBuilder(
    column: $table.vencimentoAntecipado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codigoBarras => $composableBuilder(
    column: $table.codigoBarras,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pagoEm => $composableBuilder(
    column: $table.pagoEm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get valorPagoCentavos => $composableBuilder(
    column: $table.valorPagoCentavos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get criadoEm => $composableBuilder(
    column: $table.criadoEm,
    builder: (column) => ColumnFilters(column),
  );

  $ApuracoesMensaisFilterComposer get apuracaoId {
    final $ApuracoesMensaisFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.apuracaoId,
      referencedTable: $db.apuracoesMensais,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ApuracoesMensaisFilterComposer(
            $db: $db,
            $table: $db.apuracoesMensais,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $DarfsOrderingComposer extends Composer<_$BancoLocal, Darfs> {
  $DarfsOrderingComposer({
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

  ColumnOrderings<String> get codigoReceita => $composableBuilder(
    column: $table.codigoReceita,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get competencia => $composableBuilder(
    column: $table.competencia,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get valorCentavos => $composableBuilder(
    column: $table.valorCentavos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vencimento => $composableBuilder(
    column: $table.vencimento,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get vencimentoAntecipado => $composableBuilder(
    column: $table.vencimentoAntecipado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codigoBarras => $composableBuilder(
    column: $table.codigoBarras,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pagoEm => $composableBuilder(
    column: $table.pagoEm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get valorPagoCentavos => $composableBuilder(
    column: $table.valorPagoCentavos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get criadoEm => $composableBuilder(
    column: $table.criadoEm,
    builder: (column) => ColumnOrderings(column),
  );

  $ApuracoesMensaisOrderingComposer get apuracaoId {
    final $ApuracoesMensaisOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.apuracaoId,
      referencedTable: $db.apuracoesMensais,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ApuracoesMensaisOrderingComposer(
            $db: $db,
            $table: $db.apuracoesMensais,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $DarfsAnnotationComposer extends Composer<_$BancoLocal, Darfs> {
  $DarfsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get codigoReceita => $composableBuilder(
    column: $table.codigoReceita,
    builder: (column) => column,
  );

  GeneratedColumn<String> get competencia => $composableBuilder(
    column: $table.competencia,
    builder: (column) => column,
  );

  GeneratedColumn<int> get valorCentavos => $composableBuilder(
    column: $table.valorCentavos,
    builder: (column) => column,
  );

  GeneratedColumn<String> get vencimento => $composableBuilder(
    column: $table.vencimento,
    builder: (column) => column,
  );

  GeneratedColumn<int> get vencimentoAntecipado => $composableBuilder(
    column: $table.vencimentoAntecipado,
    builder: (column) => column,
  );

  GeneratedColumn<String> get codigoBarras => $composableBuilder(
    column: $table.codigoBarras,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get pagoEm =>
      $composableBuilder(column: $table.pagoEm, builder: (column) => column);

  GeneratedColumn<int> get valorPagoCentavos => $composableBuilder(
    column: $table.valorPagoCentavos,
    builder: (column) => column,
  );

  GeneratedColumn<int> get criadoEm =>
      $composableBuilder(column: $table.criadoEm, builder: (column) => column);

  $ApuracoesMensaisAnnotationComposer get apuracaoId {
    final $ApuracoesMensaisAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.apuracaoId,
      referencedTable: $db.apuracoesMensais,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ApuracoesMensaisAnnotationComposer(
            $db: $db,
            $table: $db.apuracoesMensais,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $DarfsTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          Darfs,
          DarfLocal,
          $DarfsFilterComposer,
          $DarfsOrderingComposer,
          $DarfsAnnotationComposer,
          $DarfsCreateCompanionBuilder,
          $DarfsUpdateCompanionBuilder,
          (DarfLocal, $DarfsReferences),
          DarfLocal,
          PrefetchHooks Function({bool apuracaoId})
        > {
  $DarfsTableManager(_$BancoLocal db, Darfs table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $DarfsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $DarfsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $DarfsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> apuracaoId = const Value.absent(),
                Value<String> codigoReceita = const Value.absent(),
                Value<String> competencia = const Value.absent(),
                Value<int> valorCentavos = const Value.absent(),
                Value<String> vencimento = const Value.absent(),
                Value<int> vencimentoAntecipado = const Value.absent(),
                Value<String?> codigoBarras = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> pagoEm = const Value.absent(),
                Value<int?> valorPagoCentavos = const Value.absent(),
                Value<int> criadoEm = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DarfsCompanion(
                id: id,
                apuracaoId: apuracaoId,
                codigoReceita: codigoReceita,
                competencia: competencia,
                valorCentavos: valorCentavos,
                vencimento: vencimento,
                vencimentoAntecipado: vencimentoAntecipado,
                codigoBarras: codigoBarras,
                status: status,
                pagoEm: pagoEm,
                valorPagoCentavos: valorPagoCentavos,
                criadoEm: criadoEm,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String apuracaoId,
                Value<String> codigoReceita = const Value.absent(),
                required String competencia,
                required int valorCentavos,
                required String vencimento,
                Value<int> vencimentoAntecipado = const Value.absent(),
                Value<String?> codigoBarras = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> pagoEm = const Value.absent(),
                Value<int?> valorPagoCentavos = const Value.absent(),
                required int criadoEm,
                Value<int> rowid = const Value.absent(),
              }) => DarfsCompanion.insert(
                id: id,
                apuracaoId: apuracaoId,
                codigoReceita: codigoReceita,
                competencia: competencia,
                valorCentavos: valorCentavos,
                vencimento: vencimento,
                vencimentoAntecipado: vencimentoAntecipado,
                codigoBarras: codigoBarras,
                status: status,
                pagoEm: pagoEm,
                valorPagoCentavos: valorPagoCentavos,
                criadoEm: criadoEm,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), $DarfsReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({apuracaoId = false}) {
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
                    if (apuracaoId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.apuracaoId,
                                referencedTable: $DarfsReferences
                                    ._apuracaoIdTable(db),
                                referencedColumn: $DarfsReferences
                                    ._apuracaoIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $DarfsProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      Darfs,
      DarfLocal,
      $DarfsFilterComposer,
      $DarfsOrderingComposer,
      $DarfsAnnotationComposer,
      $DarfsCreateCompanionBuilder,
      $DarfsUpdateCompanionBuilder,
      (DarfLocal, $DarfsReferences),
      DarfLocal,
      PrefetchHooks Function({bool apuracaoId})
    >;
typedef $NotificacoesLocaisCreateCompanionBuilder =
    NotificacoesLocaisCompanion Function({
      required String id,
      required String tipo,
      Value<String?> referenciaId,
      required int agendadaPara,
      Value<int?> osNotifId,
      Value<String> status,
      required int criadoEm,
      Value<int> rowid,
    });
typedef $NotificacoesLocaisUpdateCompanionBuilder =
    NotificacoesLocaisCompanion Function({
      Value<String> id,
      Value<String> tipo,
      Value<String?> referenciaId,
      Value<int> agendadaPara,
      Value<int?> osNotifId,
      Value<String> status,
      Value<int> criadoEm,
      Value<int> rowid,
    });

class $NotificacoesLocaisFilterComposer
    extends Composer<_$BancoLocal, NotificacoesLocais> {
  $NotificacoesLocaisFilterComposer({
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

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referenciaId => $composableBuilder(
    column: $table.referenciaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get agendadaPara => $composableBuilder(
    column: $table.agendadaPara,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get osNotifId => $composableBuilder(
    column: $table.osNotifId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get criadoEm => $composableBuilder(
    column: $table.criadoEm,
    builder: (column) => ColumnFilters(column),
  );
}

class $NotificacoesLocaisOrderingComposer
    extends Composer<_$BancoLocal, NotificacoesLocais> {
  $NotificacoesLocaisOrderingComposer({
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

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referenciaId => $composableBuilder(
    column: $table.referenciaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get agendadaPara => $composableBuilder(
    column: $table.agendadaPara,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get osNotifId => $composableBuilder(
    column: $table.osNotifId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get criadoEm => $composableBuilder(
    column: $table.criadoEm,
    builder: (column) => ColumnOrderings(column),
  );
}

class $NotificacoesLocaisAnnotationComposer
    extends Composer<_$BancoLocal, NotificacoesLocais> {
  $NotificacoesLocaisAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<String> get referenciaId => $composableBuilder(
    column: $table.referenciaId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get agendadaPara => $composableBuilder(
    column: $table.agendadaPara,
    builder: (column) => column,
  );

  GeneratedColumn<int> get osNotifId =>
      $composableBuilder(column: $table.osNotifId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get criadoEm =>
      $composableBuilder(column: $table.criadoEm, builder: (column) => column);
}

class $NotificacoesLocaisTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          NotificacoesLocais,
          NotificacaoLocal,
          $NotificacoesLocaisFilterComposer,
          $NotificacoesLocaisOrderingComposer,
          $NotificacoesLocaisAnnotationComposer,
          $NotificacoesLocaisCreateCompanionBuilder,
          $NotificacoesLocaisUpdateCompanionBuilder,
          (
            NotificacaoLocal,
            BaseReferences<_$BancoLocal, NotificacoesLocais, NotificacaoLocal>,
          ),
          NotificacaoLocal,
          PrefetchHooks Function()
        > {
  $NotificacoesLocaisTableManager(_$BancoLocal db, NotificacoesLocais table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $NotificacoesLocaisFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $NotificacoesLocaisOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $NotificacoesLocaisAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<String?> referenciaId = const Value.absent(),
                Value<int> agendadaPara = const Value.absent(),
                Value<int?> osNotifId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> criadoEm = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotificacoesLocaisCompanion(
                id: id,
                tipo: tipo,
                referenciaId: referenciaId,
                agendadaPara: agendadaPara,
                osNotifId: osNotifId,
                status: status,
                criadoEm: criadoEm,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tipo,
                Value<String?> referenciaId = const Value.absent(),
                required int agendadaPara,
                Value<int?> osNotifId = const Value.absent(),
                Value<String> status = const Value.absent(),
                required int criadoEm,
                Value<int> rowid = const Value.absent(),
              }) => NotificacoesLocaisCompanion.insert(
                id: id,
                tipo: tipo,
                referenciaId: referenciaId,
                agendadaPara: agendadaPara,
                osNotifId: osNotifId,
                status: status,
                criadoEm: criadoEm,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $NotificacoesLocaisProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      NotificacoesLocais,
      NotificacaoLocal,
      $NotificacoesLocaisFilterComposer,
      $NotificacoesLocaisOrderingComposer,
      $NotificacoesLocaisAnnotationComposer,
      $NotificacoesLocaisCreateCompanionBuilder,
      $NotificacoesLocaisUpdateCompanionBuilder,
      (
        NotificacaoLocal,
        BaseReferences<_$BancoLocal, NotificacoesLocais, NotificacaoLocal>,
      ),
      NotificacaoLocal,
      PrefetchHooks Function()
    >;
typedef $BackupEstadoTableCreateCompanionBuilder =
    BackupEstadoCompanion Function({
      Value<int> id,
      Value<int?> ultimaSeq,
      Value<String?> ultimoHash,
      Value<int?> ultimoEm,
      Value<int?> formatoVersao,
      Value<int?> tamanhoBytes,
      Value<String?> resultado,
      Value<String?> erroDetalhe,
    });
typedef $BackupEstadoTableUpdateCompanionBuilder =
    BackupEstadoCompanion Function({
      Value<int> id,
      Value<int?> ultimaSeq,
      Value<String?> ultimoHash,
      Value<int?> ultimoEm,
      Value<int?> formatoVersao,
      Value<int?> tamanhoBytes,
      Value<String?> resultado,
      Value<String?> erroDetalhe,
    });

class $BackupEstadoTableFilterComposer
    extends Composer<_$BancoLocal, BackupEstadoTable> {
  $BackupEstadoTableFilterComposer({
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

  ColumnFilters<int> get ultimaSeq => $composableBuilder(
    column: $table.ultimaSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ultimoHash => $composableBuilder(
    column: $table.ultimoHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ultimoEm => $composableBuilder(
    column: $table.ultimoEm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get formatoVersao => $composableBuilder(
    column: $table.formatoVersao,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tamanhoBytes => $composableBuilder(
    column: $table.tamanhoBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resultado => $composableBuilder(
    column: $table.resultado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get erroDetalhe => $composableBuilder(
    column: $table.erroDetalhe,
    builder: (column) => ColumnFilters(column),
  );
}

class $BackupEstadoTableOrderingComposer
    extends Composer<_$BancoLocal, BackupEstadoTable> {
  $BackupEstadoTableOrderingComposer({
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

  ColumnOrderings<int> get ultimaSeq => $composableBuilder(
    column: $table.ultimaSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ultimoHash => $composableBuilder(
    column: $table.ultimoHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ultimoEm => $composableBuilder(
    column: $table.ultimoEm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get formatoVersao => $composableBuilder(
    column: $table.formatoVersao,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tamanhoBytes => $composableBuilder(
    column: $table.tamanhoBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resultado => $composableBuilder(
    column: $table.resultado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get erroDetalhe => $composableBuilder(
    column: $table.erroDetalhe,
    builder: (column) => ColumnOrderings(column),
  );
}

class $BackupEstadoTableAnnotationComposer
    extends Composer<_$BancoLocal, BackupEstadoTable> {
  $BackupEstadoTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get ultimaSeq =>
      $composableBuilder(column: $table.ultimaSeq, builder: (column) => column);

  GeneratedColumn<String> get ultimoHash => $composableBuilder(
    column: $table.ultimoHash,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ultimoEm =>
      $composableBuilder(column: $table.ultimoEm, builder: (column) => column);

  GeneratedColumn<int> get formatoVersao => $composableBuilder(
    column: $table.formatoVersao,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tamanhoBytes => $composableBuilder(
    column: $table.tamanhoBytes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resultado =>
      $composableBuilder(column: $table.resultado, builder: (column) => column);

  GeneratedColumn<String> get erroDetalhe => $composableBuilder(
    column: $table.erroDetalhe,
    builder: (column) => column,
  );
}

class $BackupEstadoTableTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          BackupEstadoTable,
          BackupEstado,
          $BackupEstadoTableFilterComposer,
          $BackupEstadoTableOrderingComposer,
          $BackupEstadoTableAnnotationComposer,
          $BackupEstadoTableCreateCompanionBuilder,
          $BackupEstadoTableUpdateCompanionBuilder,
          (
            BackupEstado,
            BaseReferences<_$BancoLocal, BackupEstadoTable, BackupEstado>,
          ),
          BackupEstado,
          PrefetchHooks Function()
        > {
  $BackupEstadoTableTableManager(_$BancoLocal db, BackupEstadoTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $BackupEstadoTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $BackupEstadoTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $BackupEstadoTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> ultimaSeq = const Value.absent(),
                Value<String?> ultimoHash = const Value.absent(),
                Value<int?> ultimoEm = const Value.absent(),
                Value<int?> formatoVersao = const Value.absent(),
                Value<int?> tamanhoBytes = const Value.absent(),
                Value<String?> resultado = const Value.absent(),
                Value<String?> erroDetalhe = const Value.absent(),
              }) => BackupEstadoCompanion(
                id: id,
                ultimaSeq: ultimaSeq,
                ultimoHash: ultimoHash,
                ultimoEm: ultimoEm,
                formatoVersao: formatoVersao,
                tamanhoBytes: tamanhoBytes,
                resultado: resultado,
                erroDetalhe: erroDetalhe,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> ultimaSeq = const Value.absent(),
                Value<String?> ultimoHash = const Value.absent(),
                Value<int?> ultimoEm = const Value.absent(),
                Value<int?> formatoVersao = const Value.absent(),
                Value<int?> tamanhoBytes = const Value.absent(),
                Value<String?> resultado = const Value.absent(),
                Value<String?> erroDetalhe = const Value.absent(),
              }) => BackupEstadoCompanion.insert(
                id: id,
                ultimaSeq: ultimaSeq,
                ultimoHash: ultimoHash,
                ultimoEm: ultimoEm,
                formatoVersao: formatoVersao,
                tamanhoBytes: tamanhoBytes,
                resultado: resultado,
                erroDetalhe: erroDetalhe,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $BackupEstadoTableProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      BackupEstadoTable,
      BackupEstado,
      $BackupEstadoTableFilterComposer,
      $BackupEstadoTableOrderingComposer,
      $BackupEstadoTableAnnotationComposer,
      $BackupEstadoTableCreateCompanionBuilder,
      $BackupEstadoTableUpdateCompanionBuilder,
      (
        BackupEstado,
        BaseReferences<_$BancoLocal, BackupEstadoTable, BackupEstado>,
      ),
      BackupEstado,
      PrefetchHooks Function()
    >;
typedef $EnviosSuporteCreateCompanionBuilder =
    EnviosSuporteCompanion Function({
      required String id,
      required String arquivoNome,
      required String motivo,
      required int consentimentoEm,
      Value<int?> enviadoEm,
      Value<String?> pathRemoto,
      required int expiraEm,
      Value<int> rowid,
    });
typedef $EnviosSuporteUpdateCompanionBuilder =
    EnviosSuporteCompanion Function({
      Value<String> id,
      Value<String> arquivoNome,
      Value<String> motivo,
      Value<int> consentimentoEm,
      Value<int?> enviadoEm,
      Value<String?> pathRemoto,
      Value<int> expiraEm,
      Value<int> rowid,
    });

class $EnviosSuporteFilterComposer
    extends Composer<_$BancoLocal, EnviosSuporte> {
  $EnviosSuporteFilterComposer({
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

  ColumnFilters<String> get arquivoNome => $composableBuilder(
    column: $table.arquivoNome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get motivo => $composableBuilder(
    column: $table.motivo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get consentimentoEm => $composableBuilder(
    column: $table.consentimentoEm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get enviadoEm => $composableBuilder(
    column: $table.enviadoEm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pathRemoto => $composableBuilder(
    column: $table.pathRemoto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expiraEm => $composableBuilder(
    column: $table.expiraEm,
    builder: (column) => ColumnFilters(column),
  );
}

class $EnviosSuporteOrderingComposer
    extends Composer<_$BancoLocal, EnviosSuporte> {
  $EnviosSuporteOrderingComposer({
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

  ColumnOrderings<String> get arquivoNome => $composableBuilder(
    column: $table.arquivoNome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get motivo => $composableBuilder(
    column: $table.motivo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get consentimentoEm => $composableBuilder(
    column: $table.consentimentoEm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get enviadoEm => $composableBuilder(
    column: $table.enviadoEm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pathRemoto => $composableBuilder(
    column: $table.pathRemoto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expiraEm => $composableBuilder(
    column: $table.expiraEm,
    builder: (column) => ColumnOrderings(column),
  );
}

class $EnviosSuporteAnnotationComposer
    extends Composer<_$BancoLocal, EnviosSuporte> {
  $EnviosSuporteAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get arquivoNome => $composableBuilder(
    column: $table.arquivoNome,
    builder: (column) => column,
  );

  GeneratedColumn<String> get motivo =>
      $composableBuilder(column: $table.motivo, builder: (column) => column);

  GeneratedColumn<int> get consentimentoEm => $composableBuilder(
    column: $table.consentimentoEm,
    builder: (column) => column,
  );

  GeneratedColumn<int> get enviadoEm =>
      $composableBuilder(column: $table.enviadoEm, builder: (column) => column);

  GeneratedColumn<String> get pathRemoto => $composableBuilder(
    column: $table.pathRemoto,
    builder: (column) => column,
  );

  GeneratedColumn<int> get expiraEm =>
      $composableBuilder(column: $table.expiraEm, builder: (column) => column);
}

class $EnviosSuporteTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          EnviosSuporte,
          EnvioSuporte,
          $EnviosSuporteFilterComposer,
          $EnviosSuporteOrderingComposer,
          $EnviosSuporteAnnotationComposer,
          $EnviosSuporteCreateCompanionBuilder,
          $EnviosSuporteUpdateCompanionBuilder,
          (
            EnvioSuporte,
            BaseReferences<_$BancoLocal, EnviosSuporte, EnvioSuporte>,
          ),
          EnvioSuporte,
          PrefetchHooks Function()
        > {
  $EnviosSuporteTableManager(_$BancoLocal db, EnviosSuporte table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $EnviosSuporteFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $EnviosSuporteOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $EnviosSuporteAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> arquivoNome = const Value.absent(),
                Value<String> motivo = const Value.absent(),
                Value<int> consentimentoEm = const Value.absent(),
                Value<int?> enviadoEm = const Value.absent(),
                Value<String?> pathRemoto = const Value.absent(),
                Value<int> expiraEm = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EnviosSuporteCompanion(
                id: id,
                arquivoNome: arquivoNome,
                motivo: motivo,
                consentimentoEm: consentimentoEm,
                enviadoEm: enviadoEm,
                pathRemoto: pathRemoto,
                expiraEm: expiraEm,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String arquivoNome,
                required String motivo,
                required int consentimentoEm,
                Value<int?> enviadoEm = const Value.absent(),
                Value<String?> pathRemoto = const Value.absent(),
                required int expiraEm,
                Value<int> rowid = const Value.absent(),
              }) => EnviosSuporteCompanion.insert(
                id: id,
                arquivoNome: arquivoNome,
                motivo: motivo,
                consentimentoEm: consentimentoEm,
                enviadoEm: enviadoEm,
                pathRemoto: pathRemoto,
                expiraEm: expiraEm,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $EnviosSuporteProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      EnviosSuporte,
      EnvioSuporte,
      $EnviosSuporteFilterComposer,
      $EnviosSuporteOrderingComposer,
      $EnviosSuporteAnnotationComposer,
      $EnviosSuporteCreateCompanionBuilder,
      $EnviosSuporteUpdateCompanionBuilder,
      (EnvioSuporte, BaseReferences<_$BancoLocal, EnviosSuporte, EnvioSuporte>),
      EnvioSuporte,
      PrefetchHooks Function()
    >;
typedef $AuditoriaTableCreateCompanionBuilder =
    AuditoriaCompanion Function({
      Value<int> id,
      required String entidade,
      Value<String?> entidadeId,
      required String acao,
      Value<String?> detalhe,
      required int criadoEm,
    });
typedef $AuditoriaTableUpdateCompanionBuilder =
    AuditoriaCompanion Function({
      Value<int> id,
      Value<String> entidade,
      Value<String?> entidadeId,
      Value<String> acao,
      Value<String?> detalhe,
      Value<int> criadoEm,
    });

class $AuditoriaTableFilterComposer
    extends Composer<_$BancoLocal, AuditoriaTable> {
  $AuditoriaTableFilterComposer({
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

  ColumnFilters<String> get entidade => $composableBuilder(
    column: $table.entidade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entidadeId => $composableBuilder(
    column: $table.entidadeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get acao => $composableBuilder(
    column: $table.acao,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detalhe => $composableBuilder(
    column: $table.detalhe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get criadoEm => $composableBuilder(
    column: $table.criadoEm,
    builder: (column) => ColumnFilters(column),
  );
}

class $AuditoriaTableOrderingComposer
    extends Composer<_$BancoLocal, AuditoriaTable> {
  $AuditoriaTableOrderingComposer({
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

  ColumnOrderings<String> get entidade => $composableBuilder(
    column: $table.entidade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entidadeId => $composableBuilder(
    column: $table.entidadeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get acao => $composableBuilder(
    column: $table.acao,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detalhe => $composableBuilder(
    column: $table.detalhe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get criadoEm => $composableBuilder(
    column: $table.criadoEm,
    builder: (column) => ColumnOrderings(column),
  );
}

class $AuditoriaTableAnnotationComposer
    extends Composer<_$BancoLocal, AuditoriaTable> {
  $AuditoriaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entidade =>
      $composableBuilder(column: $table.entidade, builder: (column) => column);

  GeneratedColumn<String> get entidadeId => $composableBuilder(
    column: $table.entidadeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get acao =>
      $composableBuilder(column: $table.acao, builder: (column) => column);

  GeneratedColumn<String> get detalhe =>
      $composableBuilder(column: $table.detalhe, builder: (column) => column);

  GeneratedColumn<int> get criadoEm =>
      $composableBuilder(column: $table.criadoEm, builder: (column) => column);
}

class $AuditoriaTableTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          AuditoriaTable,
          Auditoria,
          $AuditoriaTableFilterComposer,
          $AuditoriaTableOrderingComposer,
          $AuditoriaTableAnnotationComposer,
          $AuditoriaTableCreateCompanionBuilder,
          $AuditoriaTableUpdateCompanionBuilder,
          (Auditoria, BaseReferences<_$BancoLocal, AuditoriaTable, Auditoria>),
          Auditoria,
          PrefetchHooks Function()
        > {
  $AuditoriaTableTableManager(_$BancoLocal db, AuditoriaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $AuditoriaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $AuditoriaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $AuditoriaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> entidade = const Value.absent(),
                Value<String?> entidadeId = const Value.absent(),
                Value<String> acao = const Value.absent(),
                Value<String?> detalhe = const Value.absent(),
                Value<int> criadoEm = const Value.absent(),
              }) => AuditoriaCompanion(
                id: id,
                entidade: entidade,
                entidadeId: entidadeId,
                acao: acao,
                detalhe: detalhe,
                criadoEm: criadoEm,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String entidade,
                Value<String?> entidadeId = const Value.absent(),
                required String acao,
                Value<String?> detalhe = const Value.absent(),
                required int criadoEm,
              }) => AuditoriaCompanion.insert(
                id: id,
                entidade: entidade,
                entidadeId: entidadeId,
                acao: acao,
                detalhe: detalhe,
                criadoEm: criadoEm,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $AuditoriaTableProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      AuditoriaTable,
      Auditoria,
      $AuditoriaTableFilterComposer,
      $AuditoriaTableOrderingComposer,
      $AuditoriaTableAnnotationComposer,
      $AuditoriaTableCreateCompanionBuilder,
      $AuditoriaTableUpdateCompanionBuilder,
      (Auditoria, BaseReferences<_$BancoLocal, AuditoriaTable, Auditoria>),
      Auditoria,
      PrefetchHooks Function()
    >;

class $BancoLocalManager {
  final _$BancoLocal _db;
  $BancoLocalManager(this._db);
  $CatVersoesTableManager get catVersoes =>
      $CatVersoesTableManager(_db, _db.catVersoes);
  $CatTabelasIrpfTableManager get catTabelasIrpf =>
      $CatTabelasIrpfTableManager(_db, _db.catTabelasIrpf);
  $CatFaixasIrpfTableManager get catFaixasIrpf =>
      $CatFaixasIrpfTableManager(_db, _db.catFaixasIrpf);
  $CatParametrosFiscaisTableManager get catParametrosFiscais =>
      $CatParametrosFiscaisTableManager(_db, _db.catParametrosFiscais);
  $CatFeriadosBancariosTableManager get catFeriadosBancarios =>
      $CatFeriadosBancariosTableManager(_db, _db.catFeriadosBancarios);
  $CatRubricasTableManager get catRubricas =>
      $CatRubricasTableManager(_db, _db.catRubricas);
  $CatProfissoesTableManager get catProfissoes =>
      $CatProfissoesTableManager(_db, _db.catProfissoes);
  $CatPerfisParserTableManager get catPerfisParser =>
      $CatPerfisParserTableManager(_db, _db.catPerfisParser);
  $PerfilTableManager get perfil => $PerfilTableManager(_db, _db.perfil);
  $AceitesTermosLocalTableManager get aceitesTermosLocal =>
      $AceitesTermosLocalTableManager(_db, _db.aceitesTermosLocal);
  $ContasBancariasTableManager get contasBancarias =>
      $ContasBancariasTableManager(_db, _db.contasBancarias);
  $ImportacoesTableManager get importacoes =>
      $ImportacoesTableManager(_db, _db.importacoes);
  $TransacoesTableManager get transacoes =>
      $TransacoesTableManager(_db, _db.transacoes);
  $RemetentesTableManager get remetentes =>
      $RemetentesTableManager(_db, _db.remetentes);
  $ApuracoesMensaisTableManager get apuracoesMensais =>
      $ApuracoesMensaisTableManager(_db, _db.apuracoesMensais);
  $LancamentosTableManager get lancamentos =>
      $LancamentosTableManager(_db, _db.lancamentos);
  $HistoricoClassificacaoTableTableManager get historicoClassificacao =>
      $HistoricoClassificacaoTableTableManager(_db, _db.historicoClassificacao);
  $DespesasLivroCaixaTableManager get despesasLivroCaixa =>
      $DespesasLivroCaixaTableManager(_db, _db.despesasLivroCaixa);
  $PagamentosInssTableManager get pagamentosInss =>
      $PagamentosInssTableManager(_db, _db.pagamentosInss);
  $DependentesTableManager get dependentes =>
      $DependentesTableManager(_db, _db.dependentes);
  $DarfsTableManager get darfs => $DarfsTableManager(_db, _db.darfs);
  $NotificacoesLocaisTableManager get notificacoesLocais =>
      $NotificacoesLocaisTableManager(_db, _db.notificacoesLocais);
  $BackupEstadoTableTableManager get backupEstado =>
      $BackupEstadoTableTableManager(_db, _db.backupEstado);
  $EnviosSuporteTableManager get enviosSuporte =>
      $EnviosSuporteTableManager(_db, _db.enviosSuporte);
  $AuditoriaTableTableManager get auditoria =>
      $AuditoriaTableTableManager(_db, _db.auditoria);
}
