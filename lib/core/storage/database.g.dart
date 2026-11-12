// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SongsTable extends Songs with TableInfo<$SongsTable, Song> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SongsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
    'artist',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _albumMeta = const VerificationMeta('album');
  @override
  late final GeneratedColumn<String> album = GeneratedColumn<String>(
    'album',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _albumArtistMeta = const VerificationMeta(
    'albumArtist',
  );
  @override
  late final GeneratedColumn<String> albumArtist = GeneratedColumn<String>(
    'album_artist',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trackNumberMeta = const VerificationMeta(
    'trackNumber',
  );
  @override
  late final GeneratedColumn<int> trackNumber = GeneratedColumn<int>(
    'track_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _discNumberMeta = const VerificationMeta(
    'discNumber',
  );
  @override
  late final GeneratedColumn<int> discNumber = GeneratedColumn<int>(
    'disc_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bitrateKbpsMeta = const VerificationMeta(
    'bitrateKbps',
  );
  @override
  late final GeneratedColumn<int> bitrateKbps = GeneratedColumn<int>(
    'bitrate_kbps',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sampleRateHzMeta = const VerificationMeta(
    'sampleRateHz',
  );
  @override
  late final GeneratedColumn<int> sampleRateHz = GeneratedColumn<int>(
    'sample_rate_hz',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bitDepthMeta = const VerificationMeta(
    'bitDepth',
  );
  @override
  late final GeneratedColumn<int> bitDepth = GeneratedColumn<int>(
    'bit_depth',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileSizeBytesMeta = const VerificationMeta(
    'fileSizeBytes',
  );
  @override
  late final GeneratedColumn<int> fileSizeBytes = GeneratedColumn<int>(
    'file_size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateAddedMsMeta = const VerificationMeta(
    'dateAddedMs',
  );
  @override
  late final GeneratedColumn<int> dateAddedMs = GeneratedColumn<int>(
    'date_added_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artworkPathMeta = const VerificationMeta(
    'artworkPath',
  );
  @override
  late final GeneratedColumn<String> artworkPath = GeneratedColumn<String>(
    'artwork_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _favoriteMeta = const VerificationMeta(
    'favorite',
  );
  @override
  late final GeneratedColumn<bool> favorite = GeneratedColumn<bool>(
    'favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _playCountMeta = const VerificationMeta(
    'playCount',
  );
  @override
  late final GeneratedColumn<int> playCount = GeneratedColumn<int>(
    'play_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastPlayedMsMeta = const VerificationMeta(
    'lastPlayedMs',
  );
  @override
  late final GeneratedColumn<int> lastPlayedMs = GeneratedColumn<int>(
    'last_played_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    filePath,
    title,
    artist,
    album,
    albumArtist,
    trackNumber,
    discNumber,
    year,
    durationMs,
    format,
    bitrateKbps,
    sampleRateHz,
    bitDepth,
    fileSizeBytes,
    dateAddedMs,
    artworkPath,
    favorite,
    playCount,
    lastPlayedMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'songs';
  @override
  VerificationContext validateIntegrity(
    Insertable<Song> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('artist')) {
      context.handle(
        _artistMeta,
        artist.isAcceptableOrUnknown(data['artist']!, _artistMeta),
      );
    } else if (isInserting) {
      context.missing(_artistMeta);
    }
    if (data.containsKey('album')) {
      context.handle(
        _albumMeta,
        album.isAcceptableOrUnknown(data['album']!, _albumMeta),
      );
    } else if (isInserting) {
      context.missing(_albumMeta);
    }
    if (data.containsKey('album_artist')) {
      context.handle(
        _albumArtistMeta,
        albumArtist.isAcceptableOrUnknown(
          data['album_artist']!,
          _albumArtistMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_albumArtistMeta);
    }
    if (data.containsKey('track_number')) {
      context.handle(
        _trackNumberMeta,
        trackNumber.isAcceptableOrUnknown(
          data['track_number']!,
          _trackNumberMeta,
        ),
      );
    }
    if (data.containsKey('disc_number')) {
      context.handle(
        _discNumberMeta,
        discNumber.isAcceptableOrUnknown(data['disc_number']!, _discNumberMeta),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    } else if (isInserting) {
      context.missing(_formatMeta);
    }
    if (data.containsKey('bitrate_kbps')) {
      context.handle(
        _bitrateKbpsMeta,
        bitrateKbps.isAcceptableOrUnknown(
          data['bitrate_kbps']!,
          _bitrateKbpsMeta,
        ),
      );
    }
    if (data.containsKey('sample_rate_hz')) {
      context.handle(
        _sampleRateHzMeta,
        sampleRateHz.isAcceptableOrUnknown(
          data['sample_rate_hz']!,
          _sampleRateHzMeta,
        ),
      );
    }
    if (data.containsKey('bit_depth')) {
      context.handle(
        _bitDepthMeta,
        bitDepth.isAcceptableOrUnknown(data['bit_depth']!, _bitDepthMeta),
      );
    }
    if (data.containsKey('file_size_bytes')) {
      context.handle(
        _fileSizeBytesMeta,
        fileSizeBytes.isAcceptableOrUnknown(
          data['file_size_bytes']!,
          _fileSizeBytesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fileSizeBytesMeta);
    }
    if (data.containsKey('date_added_ms')) {
      context.handle(
        _dateAddedMsMeta,
        dateAddedMs.isAcceptableOrUnknown(
          data['date_added_ms']!,
          _dateAddedMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dateAddedMsMeta);
    }
    if (data.containsKey('artwork_path')) {
      context.handle(
        _artworkPathMeta,
        artworkPath.isAcceptableOrUnknown(
          data['artwork_path']!,
          _artworkPathMeta,
        ),
      );
    }
    if (data.containsKey('favorite')) {
      context.handle(
        _favoriteMeta,
        favorite.isAcceptableOrUnknown(data['favorite']!, _favoriteMeta),
      );
    }
    if (data.containsKey('play_count')) {
      context.handle(
        _playCountMeta,
        playCount.isAcceptableOrUnknown(data['play_count']!, _playCountMeta),
      );
    }
    if (data.containsKey('last_played_ms')) {
      context.handle(
        _lastPlayedMsMeta,
        lastPlayedMs.isAcceptableOrUnknown(
          data['last_played_ms']!,
          _lastPlayedMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Song map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Song(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      artist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist'],
      )!,
      album: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album'],
      )!,
      albumArtist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album_artist'],
      )!,
      trackNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_number'],
      ),
      discNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}disc_number'],
      ),
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format'],
      )!,
      bitrateKbps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bitrate_kbps'],
      ),
      sampleRateHz: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sample_rate_hz'],
      ),
      bitDepth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bit_depth'],
      ),
      fileSizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size_bytes'],
      )!,
      dateAddedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date_added_ms'],
      )!,
      artworkPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artwork_path'],
      ),
      favorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}favorite'],
      )!,
      playCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}play_count'],
      )!,
      lastPlayedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_played_ms'],
      ),
    );
  }

  @override
  $SongsTable createAlias(String alias) {
    return $SongsTable(attachedDatabase, alias);
  }
}

class Song extends DataClass implements Insertable<Song> {
  final String id;
  final String filePath;
  final String title;
  final String artist;
  final String album;
  final String albumArtist;
  final int? trackNumber;
  final int? discNumber;
  final int? year;
  final int durationMs;
  final String format;
  final int? bitrateKbps;
  final int? sampleRateHz;
  final int? bitDepth;
  final int fileSizeBytes;
  final int dateAddedMs;
  final String? artworkPath;
  final bool favorite;
  final int playCount;
  final int? lastPlayedMs;
  const Song({
    required this.id,
    required this.filePath,
    required this.title,
    required this.artist,
    required this.album,
    required this.albumArtist,
    this.trackNumber,
    this.discNumber,
    this.year,
    required this.durationMs,
    required this.format,
    this.bitrateKbps,
    this.sampleRateHz,
    this.bitDepth,
    required this.fileSizeBytes,
    required this.dateAddedMs,
    this.artworkPath,
    required this.favorite,
    required this.playCount,
    this.lastPlayedMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['file_path'] = Variable<String>(filePath);
    map['title'] = Variable<String>(title);
    map['artist'] = Variable<String>(artist);
    map['album'] = Variable<String>(album);
    map['album_artist'] = Variable<String>(albumArtist);
    if (!nullToAbsent || trackNumber != null) {
      map['track_number'] = Variable<int>(trackNumber);
    }
    if (!nullToAbsent || discNumber != null) {
      map['disc_number'] = Variable<int>(discNumber);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    map['duration_ms'] = Variable<int>(durationMs);
    map['format'] = Variable<String>(format);
    if (!nullToAbsent || bitrateKbps != null) {
      map['bitrate_kbps'] = Variable<int>(bitrateKbps);
    }
    if (!nullToAbsent || sampleRateHz != null) {
      map['sample_rate_hz'] = Variable<int>(sampleRateHz);
    }
    if (!nullToAbsent || bitDepth != null) {
      map['bit_depth'] = Variable<int>(bitDepth);
    }
    map['file_size_bytes'] = Variable<int>(fileSizeBytes);
    map['date_added_ms'] = Variable<int>(dateAddedMs);
    if (!nullToAbsent || artworkPath != null) {
      map['artwork_path'] = Variable<String>(artworkPath);
    }
    map['favorite'] = Variable<bool>(favorite);
    map['play_count'] = Variable<int>(playCount);
    if (!nullToAbsent || lastPlayedMs != null) {
      map['last_played_ms'] = Variable<int>(lastPlayedMs);
    }
    return map;
  }

  SongsCompanion toCompanion(bool nullToAbsent) {
    return SongsCompanion(
      id: Value(id),
      filePath: Value(filePath),
      title: Value(title),
      artist: Value(artist),
      album: Value(album),
      albumArtist: Value(albumArtist),
      trackNumber: trackNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(trackNumber),
      discNumber: discNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(discNumber),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      durationMs: Value(durationMs),
      format: Value(format),
      bitrateKbps: bitrateKbps == null && nullToAbsent
          ? const Value.absent()
          : Value(bitrateKbps),
      sampleRateHz: sampleRateHz == null && nullToAbsent
          ? const Value.absent()
          : Value(sampleRateHz),
      bitDepth: bitDepth == null && nullToAbsent
          ? const Value.absent()
          : Value(bitDepth),
      fileSizeBytes: Value(fileSizeBytes),
      dateAddedMs: Value(dateAddedMs),
      artworkPath: artworkPath == null && nullToAbsent
          ? const Value.absent()
          : Value(artworkPath),
      favorite: Value(favorite),
      playCount: Value(playCount),
      lastPlayedMs: lastPlayedMs == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPlayedMs),
    );
  }

  factory Song.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Song(
      id: serializer.fromJson<String>(json['id']),
      filePath: serializer.fromJson<String>(json['filePath']),
      title: serializer.fromJson<String>(json['title']),
      artist: serializer.fromJson<String>(json['artist']),
      album: serializer.fromJson<String>(json['album']),
      albumArtist: serializer.fromJson<String>(json['albumArtist']),
      trackNumber: serializer.fromJson<int?>(json['trackNumber']),
      discNumber: serializer.fromJson<int?>(json['discNumber']),
      year: serializer.fromJson<int?>(json['year']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      format: serializer.fromJson<String>(json['format']),
      bitrateKbps: serializer.fromJson<int?>(json['bitrateKbps']),
      sampleRateHz: serializer.fromJson<int?>(json['sampleRateHz']),
      bitDepth: serializer.fromJson<int?>(json['bitDepth']),
      fileSizeBytes: serializer.fromJson<int>(json['fileSizeBytes']),
      dateAddedMs: serializer.fromJson<int>(json['dateAddedMs']),
      artworkPath: serializer.fromJson<String?>(json['artworkPath']),
      favorite: serializer.fromJson<bool>(json['favorite']),
      playCount: serializer.fromJson<int>(json['playCount']),
      lastPlayedMs: serializer.fromJson<int?>(json['lastPlayedMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'filePath': serializer.toJson<String>(filePath),
      'title': serializer.toJson<String>(title),
      'artist': serializer.toJson<String>(artist),
      'album': serializer.toJson<String>(album),
      'albumArtist': serializer.toJson<String>(albumArtist),
      'trackNumber': serializer.toJson<int?>(trackNumber),
      'discNumber': serializer.toJson<int?>(discNumber),
      'year': serializer.toJson<int?>(year),
      'durationMs': serializer.toJson<int>(durationMs),
      'format': serializer.toJson<String>(format),
      'bitrateKbps': serializer.toJson<int?>(bitrateKbps),
      'sampleRateHz': serializer.toJson<int?>(sampleRateHz),
      'bitDepth': serializer.toJson<int?>(bitDepth),
      'fileSizeBytes': serializer.toJson<int>(fileSizeBytes),
      'dateAddedMs': serializer.toJson<int>(dateAddedMs),
      'artworkPath': serializer.toJson<String?>(artworkPath),
      'favorite': serializer.toJson<bool>(favorite),
      'playCount': serializer.toJson<int>(playCount),
      'lastPlayedMs': serializer.toJson<int?>(lastPlayedMs),
    };
  }

  Song copyWith({
    String? id,
    String? filePath,
    String? title,
    String? artist,
    String? album,
    String? albumArtist,
    Value<int?> trackNumber = const Value.absent(),
    Value<int?> discNumber = const Value.absent(),
    Value<int?> year = const Value.absent(),
    int? durationMs,
    String? format,
    Value<int?> bitrateKbps = const Value.absent(),
    Value<int?> sampleRateHz = const Value.absent(),
    Value<int?> bitDepth = const Value.absent(),
    int? fileSizeBytes,
    int? dateAddedMs,
    Value<String?> artworkPath = const Value.absent(),
    bool? favorite,
    int? playCount,
    Value<int?> lastPlayedMs = const Value.absent(),
  }) => Song(
    id: id ?? this.id,
    filePath: filePath ?? this.filePath,
    title: title ?? this.title,
    artist: artist ?? this.artist,
    album: album ?? this.album,
    albumArtist: albumArtist ?? this.albumArtist,
    trackNumber: trackNumber.present ? trackNumber.value : this.trackNumber,
    discNumber: discNumber.present ? discNumber.value : this.discNumber,
    year: year.present ? year.value : this.year,
    durationMs: durationMs ?? this.durationMs,
    format: format ?? this.format,
    bitrateKbps: bitrateKbps.present ? bitrateKbps.value : this.bitrateKbps,
    sampleRateHz: sampleRateHz.present ? sampleRateHz.value : this.sampleRateHz,
    bitDepth: bitDepth.present ? bitDepth.value : this.bitDepth,
    fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
    dateAddedMs: dateAddedMs ?? this.dateAddedMs,
    artworkPath: artworkPath.present ? artworkPath.value : this.artworkPath,
    favorite: favorite ?? this.favorite,
    playCount: playCount ?? this.playCount,
    lastPlayedMs: lastPlayedMs.present ? lastPlayedMs.value : this.lastPlayedMs,
  );
  Song copyWithCompanion(SongsCompanion data) {
    return Song(
      id: data.id.present ? data.id.value : this.id,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      title: data.title.present ? data.title.value : this.title,
      artist: data.artist.present ? data.artist.value : this.artist,
      album: data.album.present ? data.album.value : this.album,
      albumArtist: data.albumArtist.present
          ? data.albumArtist.value
          : this.albumArtist,
      trackNumber: data.trackNumber.present
          ? data.trackNumber.value
          : this.trackNumber,
      discNumber: data.discNumber.present
          ? data.discNumber.value
          : this.discNumber,
      year: data.year.present ? data.year.value : this.year,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      format: data.format.present ? data.format.value : this.format,
      bitrateKbps: data.bitrateKbps.present
          ? data.bitrateKbps.value
          : this.bitrateKbps,
      sampleRateHz: data.sampleRateHz.present
          ? data.sampleRateHz.value
          : this.sampleRateHz,
      bitDepth: data.bitDepth.present ? data.bitDepth.value : this.bitDepth,
      fileSizeBytes: data.fileSizeBytes.present
          ? data.fileSizeBytes.value
          : this.fileSizeBytes,
      dateAddedMs: data.dateAddedMs.present
          ? data.dateAddedMs.value
          : this.dateAddedMs,
      artworkPath: data.artworkPath.present
          ? data.artworkPath.value
          : this.artworkPath,
      favorite: data.favorite.present ? data.favorite.value : this.favorite,
      playCount: data.playCount.present ? data.playCount.value : this.playCount,
      lastPlayedMs: data.lastPlayedMs.present
          ? data.lastPlayedMs.value
          : this.lastPlayedMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Song(')
          ..write('id: $id, ')
          ..write('filePath: $filePath, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('albumArtist: $albumArtist, ')
          ..write('trackNumber: $trackNumber, ')
          ..write('discNumber: $discNumber, ')
          ..write('year: $year, ')
          ..write('durationMs: $durationMs, ')
          ..write('format: $format, ')
          ..write('bitrateKbps: $bitrateKbps, ')
          ..write('sampleRateHz: $sampleRateHz, ')
          ..write('bitDepth: $bitDepth, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('dateAddedMs: $dateAddedMs, ')
          ..write('artworkPath: $artworkPath, ')
          ..write('favorite: $favorite, ')
          ..write('playCount: $playCount, ')
          ..write('lastPlayedMs: $lastPlayedMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    filePath,
    title,
    artist,
    album,
    albumArtist,
    trackNumber,
    discNumber,
    year,
    durationMs,
    format,
    bitrateKbps,
    sampleRateHz,
    bitDepth,
    fileSizeBytes,
    dateAddedMs,
    artworkPath,
    favorite,
    playCount,
    lastPlayedMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Song &&
          other.id == this.id &&
          other.filePath == this.filePath &&
          other.title == this.title &&
          other.artist == this.artist &&
          other.album == this.album &&
          other.albumArtist == this.albumArtist &&
          other.trackNumber == this.trackNumber &&
          other.discNumber == this.discNumber &&
          other.year == this.year &&
          other.durationMs == this.durationMs &&
          other.format == this.format &&
          other.bitrateKbps == this.bitrateKbps &&
          other.sampleRateHz == this.sampleRateHz &&
          other.bitDepth == this.bitDepth &&
          other.fileSizeBytes == this.fileSizeBytes &&
          other.dateAddedMs == this.dateAddedMs &&
          other.artworkPath == this.artworkPath &&
          other.favorite == this.favorite &&
          other.playCount == this.playCount &&
          other.lastPlayedMs == this.lastPlayedMs);
}

class SongsCompanion extends UpdateCompanion<Song> {
  final Value<String> id;
  final Value<String> filePath;
  final Value<String> title;
  final Value<String> artist;
  final Value<String> album;
  final Value<String> albumArtist;
  final Value<int?> trackNumber;
  final Value<int?> discNumber;
  final Value<int?> year;
  final Value<int> durationMs;
  final Value<String> format;
  final Value<int?> bitrateKbps;
  final Value<int?> sampleRateHz;
  final Value<int?> bitDepth;
  final Value<int> fileSizeBytes;
  final Value<int> dateAddedMs;
  final Value<String?> artworkPath;
  final Value<bool> favorite;
  final Value<int> playCount;
  final Value<int?> lastPlayedMs;
  final Value<int> rowid;
  const SongsCompanion({
    this.id = const Value.absent(),
    this.filePath = const Value.absent(),
    this.title = const Value.absent(),
    this.artist = const Value.absent(),
    this.album = const Value.absent(),
    this.albumArtist = const Value.absent(),
    this.trackNumber = const Value.absent(),
    this.discNumber = const Value.absent(),
    this.year = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.format = const Value.absent(),
    this.bitrateKbps = const Value.absent(),
    this.sampleRateHz = const Value.absent(),
    this.bitDepth = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.dateAddedMs = const Value.absent(),
    this.artworkPath = const Value.absent(),
    this.favorite = const Value.absent(),
    this.playCount = const Value.absent(),
    this.lastPlayedMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SongsCompanion.insert({
    required String id,
    required String filePath,
    required String title,
    required String artist,
    required String album,
    required String albumArtist,
    this.trackNumber = const Value.absent(),
    this.discNumber = const Value.absent(),
    this.year = const Value.absent(),
    required int durationMs,
    required String format,
    this.bitrateKbps = const Value.absent(),
    this.sampleRateHz = const Value.absent(),
    this.bitDepth = const Value.absent(),
    required int fileSizeBytes,
    required int dateAddedMs,
    this.artworkPath = const Value.absent(),
    this.favorite = const Value.absent(),
    this.playCount = const Value.absent(),
    this.lastPlayedMs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       filePath = Value(filePath),
       title = Value(title),
       artist = Value(artist),
       album = Value(album),
       albumArtist = Value(albumArtist),
       durationMs = Value(durationMs),
       format = Value(format),
       fileSizeBytes = Value(fileSizeBytes),
       dateAddedMs = Value(dateAddedMs);
  static Insertable<Song> custom({
    Expression<String>? id,
    Expression<String>? filePath,
    Expression<String>? title,
    Expression<String>? artist,
    Expression<String>? album,
    Expression<String>? albumArtist,
    Expression<int>? trackNumber,
    Expression<int>? discNumber,
    Expression<int>? year,
    Expression<int>? durationMs,
    Expression<String>? format,
    Expression<int>? bitrateKbps,
    Expression<int>? sampleRateHz,
    Expression<int>? bitDepth,
    Expression<int>? fileSizeBytes,
    Expression<int>? dateAddedMs,
    Expression<String>? artworkPath,
    Expression<bool>? favorite,
    Expression<int>? playCount,
    Expression<int>? lastPlayedMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (filePath != null) 'file_path': filePath,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (album != null) 'album': album,
      if (albumArtist != null) 'album_artist': albumArtist,
      if (trackNumber != null) 'track_number': trackNumber,
      if (discNumber != null) 'disc_number': discNumber,
      if (year != null) 'year': year,
      if (durationMs != null) 'duration_ms': durationMs,
      if (format != null) 'format': format,
      if (bitrateKbps != null) 'bitrate_kbps': bitrateKbps,
      if (sampleRateHz != null) 'sample_rate_hz': sampleRateHz,
      if (bitDepth != null) 'bit_depth': bitDepth,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (dateAddedMs != null) 'date_added_ms': dateAddedMs,
      if (artworkPath != null) 'artwork_path': artworkPath,
      if (favorite != null) 'favorite': favorite,
      if (playCount != null) 'play_count': playCount,
      if (lastPlayedMs != null) 'last_played_ms': lastPlayedMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SongsCompanion copyWith({
    Value<String>? id,
    Value<String>? filePath,
    Value<String>? title,
    Value<String>? artist,
    Value<String>? album,
    Value<String>? albumArtist,
    Value<int?>? trackNumber,
    Value<int?>? discNumber,
    Value<int?>? year,
    Value<int>? durationMs,
    Value<String>? format,
    Value<int?>? bitrateKbps,
    Value<int?>? sampleRateHz,
    Value<int?>? bitDepth,
    Value<int>? fileSizeBytes,
    Value<int>? dateAddedMs,
    Value<String?>? artworkPath,
    Value<bool>? favorite,
    Value<int>? playCount,
    Value<int?>? lastPlayedMs,
    Value<int>? rowid,
  }) {
    return SongsCompanion(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      albumArtist: albumArtist ?? this.albumArtist,
      trackNumber: trackNumber ?? this.trackNumber,
      discNumber: discNumber ?? this.discNumber,
      year: year ?? this.year,
      durationMs: durationMs ?? this.durationMs,
      format: format ?? this.format,
      bitrateKbps: bitrateKbps ?? this.bitrateKbps,
      sampleRateHz: sampleRateHz ?? this.sampleRateHz,
      bitDepth: bitDepth ?? this.bitDepth,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      dateAddedMs: dateAddedMs ?? this.dateAddedMs,
      artworkPath: artworkPath ?? this.artworkPath,
      favorite: favorite ?? this.favorite,
      playCount: playCount ?? this.playCount,
      lastPlayedMs: lastPlayedMs ?? this.lastPlayedMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (album.present) {
      map['album'] = Variable<String>(album.value);
    }
    if (albumArtist.present) {
      map['album_artist'] = Variable<String>(albumArtist.value);
    }
    if (trackNumber.present) {
      map['track_number'] = Variable<int>(trackNumber.value);
    }
    if (discNumber.present) {
      map['disc_number'] = Variable<int>(discNumber.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (bitrateKbps.present) {
      map['bitrate_kbps'] = Variable<int>(bitrateKbps.value);
    }
    if (sampleRateHz.present) {
      map['sample_rate_hz'] = Variable<int>(sampleRateHz.value);
    }
    if (bitDepth.present) {
      map['bit_depth'] = Variable<int>(bitDepth.value);
    }
    if (fileSizeBytes.present) {
      map['file_size_bytes'] = Variable<int>(fileSizeBytes.value);
    }
    if (dateAddedMs.present) {
      map['date_added_ms'] = Variable<int>(dateAddedMs.value);
    }
    if (artworkPath.present) {
      map['artwork_path'] = Variable<String>(artworkPath.value);
    }
    if (favorite.present) {
      map['favorite'] = Variable<bool>(favorite.value);
    }
    if (playCount.present) {
      map['play_count'] = Variable<int>(playCount.value);
    }
    if (lastPlayedMs.present) {
      map['last_played_ms'] = Variable<int>(lastPlayedMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SongsCompanion(')
          ..write('id: $id, ')
          ..write('filePath: $filePath, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('albumArtist: $albumArtist, ')
          ..write('trackNumber: $trackNumber, ')
          ..write('discNumber: $discNumber, ')
          ..write('year: $year, ')
          ..write('durationMs: $durationMs, ')
          ..write('format: $format, ')
          ..write('bitrateKbps: $bitrateKbps, ')
          ..write('sampleRateHz: $sampleRateHz, ')
          ..write('bitDepth: $bitDepth, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('dateAddedMs: $dateAddedMs, ')
          ..write('artworkPath: $artworkPath, ')
          ..write('favorite: $favorite, ')
          ..write('playCount: $playCount, ')
          ..write('lastPlayedMs: $lastPlayedMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaylistsTable extends Playlists
    with TableInfo<$PlaylistsTable, Playlist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _artworkPathMeta = const VerificationMeta(
    'artworkPath',
  );
  @override
  late final GeneratedColumn<String> artworkPath = GeneratedColumn<String>(
    'artwork_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, artworkPath, createdAtMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlists';
  @override
  VerificationContext validateIntegrity(
    Insertable<Playlist> instance, {
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
    if (data.containsKey('artwork_path')) {
      context.handle(
        _artworkPathMeta,
        artworkPath.isAcceptableOrUnknown(
          data['artwork_path']!,
          _artworkPathMeta,
        ),
      );
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Playlist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Playlist(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      artworkPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artwork_path'],
      ),
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
    );
  }

  @override
  $PlaylistsTable createAlias(String alias) {
    return $PlaylistsTable(attachedDatabase, alias);
  }
}

class Playlist extends DataClass implements Insertable<Playlist> {
  final String id;
  final String name;

  /// Custom artwork path if the user chose one; null means "generate a
  /// collage from member songs" (computed at read time, not stored).
  final String? artworkPath;
  final int createdAtMs;
  const Playlist({
    required this.id,
    required this.name,
    this.artworkPath,
    required this.createdAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || artworkPath != null) {
      map['artwork_path'] = Variable<String>(artworkPath);
    }
    map['created_at_ms'] = Variable<int>(createdAtMs);
    return map;
  }

  PlaylistsCompanion toCompanion(bool nullToAbsent) {
    return PlaylistsCompanion(
      id: Value(id),
      name: Value(name),
      artworkPath: artworkPath == null && nullToAbsent
          ? const Value.absent()
          : Value(artworkPath),
      createdAtMs: Value(createdAtMs),
    );
  }

  factory Playlist.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Playlist(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      artworkPath: serializer.fromJson<String?>(json['artworkPath']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'artworkPath': serializer.toJson<String?>(artworkPath),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
    };
  }

  Playlist copyWith({
    String? id,
    String? name,
    Value<String?> artworkPath = const Value.absent(),
    int? createdAtMs,
  }) => Playlist(
    id: id ?? this.id,
    name: name ?? this.name,
    artworkPath: artworkPath.present ? artworkPath.value : this.artworkPath,
    createdAtMs: createdAtMs ?? this.createdAtMs,
  );
  Playlist copyWithCompanion(PlaylistsCompanion data) {
    return Playlist(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      artworkPath: data.artworkPath.present
          ? data.artworkPath.value
          : this.artworkPath,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Playlist(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('artworkPath: $artworkPath, ')
          ..write('createdAtMs: $createdAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, artworkPath, createdAtMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Playlist &&
          other.id == this.id &&
          other.name == this.name &&
          other.artworkPath == this.artworkPath &&
          other.createdAtMs == this.createdAtMs);
}

class PlaylistsCompanion extends UpdateCompanion<Playlist> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> artworkPath;
  final Value<int> createdAtMs;
  final Value<int> rowid;
  const PlaylistsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.artworkPath = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaylistsCompanion.insert({
    required String id,
    required String name,
    this.artworkPath = const Value.absent(),
    required int createdAtMs,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAtMs = Value(createdAtMs);
  static Insertable<Playlist> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? artworkPath,
    Expression<int>? createdAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (artworkPath != null) 'artwork_path': artworkPath,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaylistsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? artworkPath,
    Value<int>? createdAtMs,
    Value<int>? rowid,
  }) {
    return PlaylistsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      artworkPath: artworkPath ?? this.artworkPath,
      createdAtMs: createdAtMs ?? this.createdAtMs,
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
    if (artworkPath.present) {
      map['artwork_path'] = Variable<String>(artworkPath.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('artworkPath: $artworkPath, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaylistSongsTable extends PlaylistSongs
    with TableInfo<$PlaylistSongsTable, PlaylistSong> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistSongsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _playlistIdMeta = const VerificationMeta(
    'playlistId',
  );
  @override
  late final GeneratedColumn<String> playlistId = GeneratedColumn<String>(
    'playlist_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES playlists (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _songIdMeta = const VerificationMeta('songId');
  @override
  late final GeneratedColumn<String> songId = GeneratedColumn<String>(
    'song_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES songs (id) ON DELETE CASCADE',
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
  @override
  List<GeneratedColumn> get $columns => [id, playlistId, songId, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlist_songs';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaylistSong> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('song_id')) {
      context.handle(
        _songIdMeta,
        songId.isAcceptableOrUnknown(data['song_id']!, _songIdMeta),
      );
    } else if (isInserting) {
      context.missing(_songIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaylistSong map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaylistSong(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}playlist_id'],
      )!,
      songId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}song_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $PlaylistSongsTable createAlias(String alias) {
    return $PlaylistSongsTable(attachedDatabase, alias);
  }
}

class PlaylistSong extends DataClass implements Insertable<PlaylistSong> {
  final int id;
  final String playlistId;
  final String songId;
  final int position;
  const PlaylistSong({
    required this.id,
    required this.playlistId,
    required this.songId,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['playlist_id'] = Variable<String>(playlistId);
    map['song_id'] = Variable<String>(songId);
    map['position'] = Variable<int>(position);
    return map;
  }

  PlaylistSongsCompanion toCompanion(bool nullToAbsent) {
    return PlaylistSongsCompanion(
      id: Value(id),
      playlistId: Value(playlistId),
      songId: Value(songId),
      position: Value(position),
    );
  }

  factory PlaylistSong.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaylistSong(
      id: serializer.fromJson<int>(json['id']),
      playlistId: serializer.fromJson<String>(json['playlistId']),
      songId: serializer.fromJson<String>(json['songId']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'playlistId': serializer.toJson<String>(playlistId),
      'songId': serializer.toJson<String>(songId),
      'position': serializer.toJson<int>(position),
    };
  }

  PlaylistSong copyWith({
    int? id,
    String? playlistId,
    String? songId,
    int? position,
  }) => PlaylistSong(
    id: id ?? this.id,
    playlistId: playlistId ?? this.playlistId,
    songId: songId ?? this.songId,
    position: position ?? this.position,
  );
  PlaylistSong copyWithCompanion(PlaylistSongsCompanion data) {
    return PlaylistSong(
      id: data.id.present ? data.id.value : this.id,
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      songId: data.songId.present ? data.songId.value : this.songId,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistSong(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('songId: $songId, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, playlistId, songId, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistSong &&
          other.id == this.id &&
          other.playlistId == this.playlistId &&
          other.songId == this.songId &&
          other.position == this.position);
}

class PlaylistSongsCompanion extends UpdateCompanion<PlaylistSong> {
  final Value<int> id;
  final Value<String> playlistId;
  final Value<String> songId;
  final Value<int> position;
  const PlaylistSongsCompanion({
    this.id = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.songId = const Value.absent(),
    this.position = const Value.absent(),
  });
  PlaylistSongsCompanion.insert({
    this.id = const Value.absent(),
    required String playlistId,
    required String songId,
    required int position,
  }) : playlistId = Value(playlistId),
       songId = Value(songId),
       position = Value(position);
  static Insertable<PlaylistSong> custom({
    Expression<int>? id,
    Expression<String>? playlistId,
    Expression<String>? songId,
    Expression<int>? position,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playlistId != null) 'playlist_id': playlistId,
      if (songId != null) 'song_id': songId,
      if (position != null) 'position': position,
    });
  }

  PlaylistSongsCompanion copyWith({
    Value<int>? id,
    Value<String>? playlistId,
    Value<String>? songId,
    Value<int>? position,
  }) {
    return PlaylistSongsCompanion(
      id: id ?? this.id,
      playlistId: playlistId ?? this.playlistId,
      songId: songId ?? this.songId,
      position: position ?? this.position,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (playlistId.present) {
      map['playlist_id'] = Variable<String>(playlistId.value);
    }
    if (songId.present) {
      map['song_id'] = Variable<String>(songId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistSongsCompanion(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('songId: $songId, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }
}

class $DownloadHistoryEntriesTable extends DownloadHistoryEntries
    with TableInfo<$DownloadHistoryEntriesTable, DownloadHistoryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadHistoryEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outputFormatMeta = const VerificationMeta(
    'outputFormat',
  );
  @override
  late final GeneratedColumn<String> outputFormat = GeneratedColumn<String>(
    'output_format',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timestampMsMeta = const VerificationMeta(
    'timestampMs',
  );
  @override
  late final GeneratedColumn<int> timestampMs = GeneratedColumn<int>(
    'timestamp_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    sourceType,
    status,
    outputFormat,
    message,
    timestampMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'download_history_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadHistoryEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceTypeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('output_format')) {
      context.handle(
        _outputFormatMeta,
        outputFormat.isAcceptableOrUnknown(
          data['output_format']!,
          _outputFormatMeta,
        ),
      );
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    }
    if (data.containsKey('timestamp_ms')) {
      context.handle(
        _timestampMsMeta,
        timestampMs.isAcceptableOrUnknown(
          data['timestamp_ms']!,
          _timestampMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timestampMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DownloadHistoryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadHistoryEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      outputFormat: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}output_format'],
      ),
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      ),
      timestampMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp_ms'],
      )!,
    );
  }

  @override
  $DownloadHistoryEntriesTable createAlias(String alias) {
    return $DownloadHistoryEntriesTable(attachedDatabase, alias);
  }
}

class DownloadHistoryEntry extends DataClass
    implements Insertable<DownloadHistoryEntry> {
  final String id;
  final String title;

  /// 'direct' | 'googleDrive'.
  final String sourceType;

  /// 'success' | 'failed'.
  final String status;

  /// The output file's extension (e.g. 'm4a', 'mp3') — only set on success.
  final String? outputFormat;

  /// Short failure reason — only set on failure.
  final String? message;
  final int timestampMs;
  const DownloadHistoryEntry({
    required this.id,
    required this.title,
    required this.sourceType,
    required this.status,
    this.outputFormat,
    this.message,
    required this.timestampMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['source_type'] = Variable<String>(sourceType);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || outputFormat != null) {
      map['output_format'] = Variable<String>(outputFormat);
    }
    if (!nullToAbsent || message != null) {
      map['message'] = Variable<String>(message);
    }
    map['timestamp_ms'] = Variable<int>(timestampMs);
    return map;
  }

  DownloadHistoryEntriesCompanion toCompanion(bool nullToAbsent) {
    return DownloadHistoryEntriesCompanion(
      id: Value(id),
      title: Value(title),
      sourceType: Value(sourceType),
      status: Value(status),
      outputFormat: outputFormat == null && nullToAbsent
          ? const Value.absent()
          : Value(outputFormat),
      message: message == null && nullToAbsent
          ? const Value.absent()
          : Value(message),
      timestampMs: Value(timestampMs),
    );
  }

  factory DownloadHistoryEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadHistoryEntry(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      status: serializer.fromJson<String>(json['status']),
      outputFormat: serializer.fromJson<String?>(json['outputFormat']),
      message: serializer.fromJson<String?>(json['message']),
      timestampMs: serializer.fromJson<int>(json['timestampMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'sourceType': serializer.toJson<String>(sourceType),
      'status': serializer.toJson<String>(status),
      'outputFormat': serializer.toJson<String?>(outputFormat),
      'message': serializer.toJson<String?>(message),
      'timestampMs': serializer.toJson<int>(timestampMs),
    };
  }

  DownloadHistoryEntry copyWith({
    String? id,
    String? title,
    String? sourceType,
    String? status,
    Value<String?> outputFormat = const Value.absent(),
    Value<String?> message = const Value.absent(),
    int? timestampMs,
  }) => DownloadHistoryEntry(
    id: id ?? this.id,
    title: title ?? this.title,
    sourceType: sourceType ?? this.sourceType,
    status: status ?? this.status,
    outputFormat: outputFormat.present ? outputFormat.value : this.outputFormat,
    message: message.present ? message.value : this.message,
    timestampMs: timestampMs ?? this.timestampMs,
  );
  DownloadHistoryEntry copyWithCompanion(DownloadHistoryEntriesCompanion data) {
    return DownloadHistoryEntry(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      status: data.status.present ? data.status.value : this.status,
      outputFormat: data.outputFormat.present
          ? data.outputFormat.value
          : this.outputFormat,
      message: data.message.present ? data.message.value : this.message,
      timestampMs: data.timestampMs.present
          ? data.timestampMs.value
          : this.timestampMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadHistoryEntry(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('sourceType: $sourceType, ')
          ..write('status: $status, ')
          ..write('outputFormat: $outputFormat, ')
          ..write('message: $message, ')
          ..write('timestampMs: $timestampMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    sourceType,
    status,
    outputFormat,
    message,
    timestampMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadHistoryEntry &&
          other.id == this.id &&
          other.title == this.title &&
          other.sourceType == this.sourceType &&
          other.status == this.status &&
          other.outputFormat == this.outputFormat &&
          other.message == this.message &&
          other.timestampMs == this.timestampMs);
}

class DownloadHistoryEntriesCompanion
    extends UpdateCompanion<DownloadHistoryEntry> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> sourceType;
  final Value<String> status;
  final Value<String?> outputFormat;
  final Value<String?> message;
  final Value<int> timestampMs;
  final Value<int> rowid;
  const DownloadHistoryEntriesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.status = const Value.absent(),
    this.outputFormat = const Value.absent(),
    this.message = const Value.absent(),
    this.timestampMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadHistoryEntriesCompanion.insert({
    required String id,
    required String title,
    required String sourceType,
    required String status,
    this.outputFormat = const Value.absent(),
    this.message = const Value.absent(),
    required int timestampMs,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       sourceType = Value(sourceType),
       status = Value(status),
       timestampMs = Value(timestampMs);
  static Insertable<DownloadHistoryEntry> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? sourceType,
    Expression<String>? status,
    Expression<String>? outputFormat,
    Expression<String>? message,
    Expression<int>? timestampMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (sourceType != null) 'source_type': sourceType,
      if (status != null) 'status': status,
      if (outputFormat != null) 'output_format': outputFormat,
      if (message != null) 'message': message,
      if (timestampMs != null) 'timestamp_ms': timestampMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadHistoryEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? sourceType,
    Value<String>? status,
    Value<String?>? outputFormat,
    Value<String?>? message,
    Value<int>? timestampMs,
    Value<int>? rowid,
  }) {
    return DownloadHistoryEntriesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      sourceType: sourceType ?? this.sourceType,
      status: status ?? this.status,
      outputFormat: outputFormat ?? this.outputFormat,
      message: message ?? this.message,
      timestampMs: timestampMs ?? this.timestampMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (outputFormat.present) {
      map['output_format'] = Variable<String>(outputFormat.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (timestampMs.present) {
      map['timestamp_ms'] = Variable<int>(timestampMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadHistoryEntriesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('sourceType: $sourceType, ')
          ..write('status: $status, ')
          ..write('outputFormat: $outputFormat, ')
          ..write('message: $message, ')
          ..write('timestampMs: $timestampMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LibrarySourcesTable extends LibrarySources
    with TableInfo<$LibrarySourcesTable, LibrarySource> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LibrarySourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceKeyMeta = const VerificationMeta(
    'sourceKey',
  );
  @override
  late final GeneratedColumn<String> sourceKey = GeneratedColumn<String>(
    'source_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
    'track_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _volumeMeta = const VerificationMeta('volume');
  @override
  late final GeneratedColumn<String> volume = GeneratedColumn<String>(
    'volume',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _modifiedSecMeta = const VerificationMeta(
    'modifiedSec',
  );
  @override
  late final GeneratedColumn<int> modifiedSec = GeneratedColumn<int>(
    'modified_sec',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    sourceKey,
    trackId,
    state,
    sizeBytes,
    volume,
    path,
    modifiedSec,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'library_sources';
  @override
  VerificationContext validateIntegrity(
    Insertable<LibrarySource> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source_key')) {
      context.handle(
        _sourceKeyMeta,
        sourceKey.isAcceptableOrUnknown(data['source_key']!, _sourceKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceKeyMeta);
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    }
    if (data.containsKey('volume')) {
      context.handle(
        _volumeMeta,
        volume.isAcceptableOrUnknown(data['volume']!, _volumeMeta),
      );
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    }
    if (data.containsKey('modified_sec')) {
      context.handle(
        _modifiedSecMeta,
        modifiedSec.isAcceptableOrUnknown(
          data['modified_sec']!,
          _modifiedSecMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceKey};
  @override
  LibrarySource map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LibrarySource(
      sourceKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_key'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_id'],
      ),
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      volume: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}volume'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      modifiedSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}modified_sec'],
      )!,
    );
  }

  @override
  $LibrarySourcesTable createAlias(String alias) {
    return $LibrarySourcesTable(attachedDatabase, alias);
  }
}

class LibrarySource extends DataClass implements Insertable<LibrarySource> {
  final String sourceKey;
  final String? trackId;
  final String state;
  final int sizeBytes;
  final String volume;
  final String path;
  final int modifiedSec;
  const LibrarySource({
    required this.sourceKey,
    this.trackId,
    required this.state,
    required this.sizeBytes,
    required this.volume,
    required this.path,
    required this.modifiedSec,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_key'] = Variable<String>(sourceKey);
    if (!nullToAbsent || trackId != null) {
      map['track_id'] = Variable<String>(trackId);
    }
    map['state'] = Variable<String>(state);
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['volume'] = Variable<String>(volume);
    map['path'] = Variable<String>(path);
    map['modified_sec'] = Variable<int>(modifiedSec);
    return map;
  }

  LibrarySourcesCompanion toCompanion(bool nullToAbsent) {
    return LibrarySourcesCompanion(
      sourceKey: Value(sourceKey),
      trackId: trackId == null && nullToAbsent
          ? const Value.absent()
          : Value(trackId),
      state: Value(state),
      sizeBytes: Value(sizeBytes),
      volume: Value(volume),
      path: Value(path),
      modifiedSec: Value(modifiedSec),
    );
  }

  factory LibrarySource.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LibrarySource(
      sourceKey: serializer.fromJson<String>(json['sourceKey']),
      trackId: serializer.fromJson<String?>(json['trackId']),
      state: serializer.fromJson<String>(json['state']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      volume: serializer.fromJson<String>(json['volume']),
      path: serializer.fromJson<String>(json['path']),
      modifiedSec: serializer.fromJson<int>(json['modifiedSec']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sourceKey': serializer.toJson<String>(sourceKey),
      'trackId': serializer.toJson<String?>(trackId),
      'state': serializer.toJson<String>(state),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'volume': serializer.toJson<String>(volume),
      'path': serializer.toJson<String>(path),
      'modifiedSec': serializer.toJson<int>(modifiedSec),
    };
  }

  LibrarySource copyWith({
    String? sourceKey,
    Value<String?> trackId = const Value.absent(),
    String? state,
    int? sizeBytes,
    String? volume,
    String? path,
    int? modifiedSec,
  }) => LibrarySource(
    sourceKey: sourceKey ?? this.sourceKey,
    trackId: trackId.present ? trackId.value : this.trackId,
    state: state ?? this.state,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    volume: volume ?? this.volume,
    path: path ?? this.path,
    modifiedSec: modifiedSec ?? this.modifiedSec,
  );
  LibrarySource copyWithCompanion(LibrarySourcesCompanion data) {
    return LibrarySource(
      sourceKey: data.sourceKey.present ? data.sourceKey.value : this.sourceKey,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      state: data.state.present ? data.state.value : this.state,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      volume: data.volume.present ? data.volume.value : this.volume,
      path: data.path.present ? data.path.value : this.path,
      modifiedSec: data.modifiedSec.present
          ? data.modifiedSec.value
          : this.modifiedSec,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LibrarySource(')
          ..write('sourceKey: $sourceKey, ')
          ..write('trackId: $trackId, ')
          ..write('state: $state, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('volume: $volume, ')
          ..write('path: $path, ')
          ..write('modifiedSec: $modifiedSec')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sourceKey,
    trackId,
    state,
    sizeBytes,
    volume,
    path,
    modifiedSec,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibrarySource &&
          other.sourceKey == this.sourceKey &&
          other.trackId == this.trackId &&
          other.state == this.state &&
          other.sizeBytes == this.sizeBytes &&
          other.volume == this.volume &&
          other.path == this.path &&
          other.modifiedSec == this.modifiedSec);
}

class LibrarySourcesCompanion extends UpdateCompanion<LibrarySource> {
  final Value<String> sourceKey;
  final Value<String?> trackId;
  final Value<String> state;
  final Value<int> sizeBytes;
  final Value<String> volume;
  final Value<String> path;
  final Value<int> modifiedSec;
  final Value<int> rowid;
  const LibrarySourcesCompanion({
    this.sourceKey = const Value.absent(),
    this.trackId = const Value.absent(),
    this.state = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.volume = const Value.absent(),
    this.path = const Value.absent(),
    this.modifiedSec = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LibrarySourcesCompanion.insert({
    required String sourceKey,
    this.trackId = const Value.absent(),
    required String state,
    this.sizeBytes = const Value.absent(),
    this.volume = const Value.absent(),
    this.path = const Value.absent(),
    this.modifiedSec = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sourceKey = Value(sourceKey),
       state = Value(state);
  static Insertable<LibrarySource> custom({
    Expression<String>? sourceKey,
    Expression<String>? trackId,
    Expression<String>? state,
    Expression<int>? sizeBytes,
    Expression<String>? volume,
    Expression<String>? path,
    Expression<int>? modifiedSec,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceKey != null) 'source_key': sourceKey,
      if (trackId != null) 'track_id': trackId,
      if (state != null) 'state': state,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (volume != null) 'volume': volume,
      if (path != null) 'path': path,
      if (modifiedSec != null) 'modified_sec': modifiedSec,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LibrarySourcesCompanion copyWith({
    Value<String>? sourceKey,
    Value<String?>? trackId,
    Value<String>? state,
    Value<int>? sizeBytes,
    Value<String>? volume,
    Value<String>? path,
    Value<int>? modifiedSec,
    Value<int>? rowid,
  }) {
    return LibrarySourcesCompanion(
      sourceKey: sourceKey ?? this.sourceKey,
      trackId: trackId ?? this.trackId,
      state: state ?? this.state,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      volume: volume ?? this.volume,
      path: path ?? this.path,
      modifiedSec: modifiedSec ?? this.modifiedSec,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceKey.present) {
      map['source_key'] = Variable<String>(sourceKey.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (volume.present) {
      map['volume'] = Variable<String>(volume.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (modifiedSec.present) {
      map['modified_sec'] = Variable<int>(modifiedSec.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LibrarySourcesCompanion(')
          ..write('sourceKey: $sourceKey, ')
          ..write('trackId: $trackId, ')
          ..write('state: $state, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('volume: $volume, ')
          ..write('path: $path, ')
          ..write('modifiedSec: $modifiedSec, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SongsTable songs = $SongsTable(this);
  late final $PlaylistsTable playlists = $PlaylistsTable(this);
  late final $PlaylistSongsTable playlistSongs = $PlaylistSongsTable(this);
  late final $DownloadHistoryEntriesTable downloadHistoryEntries =
      $DownloadHistoryEntriesTable(this);
  late final $LibrarySourcesTable librarySources = $LibrarySourcesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    songs,
    playlists,
    playlistSongs,
    downloadHistoryEntries,
    librarySources,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'playlists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('playlist_songs', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'songs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('playlist_songs', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$SongsTableCreateCompanionBuilder = SongsCompanion Function({
  required String id,
  required String filePath,
  required String title,
  required String artist,
  required String album,
  required String albumArtist,
  Value<int?> trackNumber,
  Value<int?> discNumber,
  Value<int?> year,
  required int durationMs,
  required String format,
  Value<int?> bitrateKbps,
  Value<int?> sampleRateHz,
  Value<int?> bitDepth,
  required int fileSizeBytes,
  required int dateAddedMs,
  Value<String?> artworkPath,
  Value<bool> favorite,
  Value<int> playCount,
  Value<int?> lastPlayedMs,
  Value<int> rowid,
});
typedef $$SongsTableUpdateCompanionBuilder = SongsCompanion Function({
  Value<String> id,
  Value<String> filePath,
  Value<String> title,
  Value<String> artist,
  Value<String> album,
  Value<String> albumArtist,
  Value<int?> trackNumber,
  Value<int?> discNumber,
  Value<int?> year,
  Value<int> durationMs,
  Value<String> format,
  Value<int?> bitrateKbps,
  Value<int?> sampleRateHz,
  Value<int?> bitDepth,
  Value<int> fileSizeBytes,
  Value<int> dateAddedMs,
  Value<String?> artworkPath,
  Value<bool> favorite,
  Value<int> playCount,
  Value<int?> lastPlayedMs,
  Value<int> rowid,
});

final class $$SongsTableReferences
    extends BaseReferences<_$AppDatabase, $SongsTable, Song> {
  $$SongsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PlaylistSongsTable, List<PlaylistSong>>
  _playlistSongsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.playlistSongs,
    aliasName: 'songs__id__playlist_songs__song_id',
  );

  $$PlaylistSongsTableProcessedTableManager get playlistSongsRefs {
    final manager = $$PlaylistSongsTableTableManager(
      $_db,
      $_db.playlistSongs,
    ).filter((f) => f.songId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_playlistSongsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SongsTableFilterComposer extends Composer<_$AppDatabase, $SongsTable> {
  $$SongsTableFilterComposer({
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

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get albumArtist => $composableBuilder(
    column: $table.albumArtist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trackNumber => $composableBuilder(
    column: $table.trackNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discNumber => $composableBuilder(
    column: $table.discNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bitrateKbps => $composableBuilder(
    column: $table.bitrateKbps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sampleRateHz => $composableBuilder(
    column: $table.sampleRateHz,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bitDepth => $composableBuilder(
    column: $table.bitDepth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dateAddedMs => $composableBuilder(
    column: $table.dateAddedMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artworkPath => $composableBuilder(
    column: $table.artworkPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get favorite => $composableBuilder(
    column: $table.favorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playCount => $composableBuilder(
    column: $table.playCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastPlayedMs => $composableBuilder(
    column: $table.lastPlayedMs,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> playlistSongsRefs(
    Expression<bool> Function($$PlaylistSongsTableFilterComposer f) f,
  ) {
    final $$PlaylistSongsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistSongs,
      getReferencedColumn: (t) => t.songId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistSongsTableFilterComposer(
            $db: $db,
            $table: $db.playlistSongs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SongsTableOrderingComposer
    extends Composer<_$AppDatabase, $SongsTable> {
  $$SongsTableOrderingComposer({
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

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get albumArtist => $composableBuilder(
    column: $table.albumArtist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trackNumber => $composableBuilder(
    column: $table.trackNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discNumber => $composableBuilder(
    column: $table.discNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bitrateKbps => $composableBuilder(
    column: $table.bitrateKbps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sampleRateHz => $composableBuilder(
    column: $table.sampleRateHz,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bitDepth => $composableBuilder(
    column: $table.bitDepth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dateAddedMs => $composableBuilder(
    column: $table.dateAddedMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artworkPath => $composableBuilder(
    column: $table.artworkPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get favorite => $composableBuilder(
    column: $table.favorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playCount => $composableBuilder(
    column: $table.playCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastPlayedMs => $composableBuilder(
    column: $table.lastPlayedMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SongsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SongsTable> {
  $$SongsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<String> get album =>
      $composableBuilder(column: $table.album, builder: (column) => column);

  GeneratedColumn<String> get albumArtist => $composableBuilder(
    column: $table.albumArtist,
    builder: (column) => column,
  );

  GeneratedColumn<int> get trackNumber => $composableBuilder(
    column: $table.trackNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get discNumber => $composableBuilder(
    column: $table.discNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<int> get bitrateKbps => $composableBuilder(
    column: $table.bitrateKbps,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sampleRateHz => $composableBuilder(
    column: $table.sampleRateHz,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bitDepth =>
      $composableBuilder(column: $table.bitDepth, builder: (column) => column);

  GeneratedColumn<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dateAddedMs => $composableBuilder(
    column: $table.dateAddedMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get artworkPath => $composableBuilder(
    column: $table.artworkPath,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get favorite =>
      $composableBuilder(column: $table.favorite, builder: (column) => column);

  GeneratedColumn<int> get playCount =>
      $composableBuilder(column: $table.playCount, builder: (column) => column);

  GeneratedColumn<int> get lastPlayedMs => $composableBuilder(
    column: $table.lastPlayedMs,
    builder: (column) => column,
  );

  Expression<T> playlistSongsRefs<T extends Object>(
    Expression<T> Function($$PlaylistSongsTableAnnotationComposer a) f,
  ) {
    final $$PlaylistSongsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistSongs,
      getReferencedColumn: (t) => t.songId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistSongsTableAnnotationComposer(
            $db: $db,
            $table: $db.playlistSongs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SongsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SongsTable,
          Song,
          $$SongsTableFilterComposer,
          $$SongsTableOrderingComposer,
          $$SongsTableAnnotationComposer,
          $$SongsTableCreateCompanionBuilder,
          $$SongsTableUpdateCompanionBuilder,
          (Song, $$SongsTableReferences),
          Song,
          PrefetchHooks Function({bool playlistSongsRefs})
        > {
  $$SongsTableTableManager(_$AppDatabase db, $SongsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SongsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SongsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SongsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> artist = const Value.absent(),
                Value<String> album = const Value.absent(),
                Value<String> albumArtist = const Value.absent(),
                Value<int?> trackNumber = const Value.absent(),
                Value<int?> discNumber = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<String> format = const Value.absent(),
                Value<int?> bitrateKbps = const Value.absent(),
                Value<int?> sampleRateHz = const Value.absent(),
                Value<int?> bitDepth = const Value.absent(),
                Value<int> fileSizeBytes = const Value.absent(),
                Value<int> dateAddedMs = const Value.absent(),
                Value<String?> artworkPath = const Value.absent(),
                Value<bool> favorite = const Value.absent(),
                Value<int> playCount = const Value.absent(),
                Value<int?> lastPlayedMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SongsCompanion(
                id: id,
                filePath: filePath,
                title: title,
                artist: artist,
                album: album,
                albumArtist: albumArtist,
                trackNumber: trackNumber,
                discNumber: discNumber,
                year: year,
                durationMs: durationMs,
                format: format,
                bitrateKbps: bitrateKbps,
                sampleRateHz: sampleRateHz,
                bitDepth: bitDepth,
                fileSizeBytes: fileSizeBytes,
                dateAddedMs: dateAddedMs,
                artworkPath: artworkPath,
                favorite: favorite,
                playCount: playCount,
                lastPlayedMs: lastPlayedMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String filePath,
                required String title,
                required String artist,
                required String album,
                required String albumArtist,
                Value<int?> trackNumber = const Value.absent(),
                Value<int?> discNumber = const Value.absent(),
                Value<int?> year = const Value.absent(),
                required int durationMs,
                required String format,
                Value<int?> bitrateKbps = const Value.absent(),
                Value<int?> sampleRateHz = const Value.absent(),
                Value<int?> bitDepth = const Value.absent(),
                required int fileSizeBytes,
                required int dateAddedMs,
                Value<String?> artworkPath = const Value.absent(),
                Value<bool> favorite = const Value.absent(),
                Value<int> playCount = const Value.absent(),
                Value<int?> lastPlayedMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SongsCompanion.insert(
                id: id,
                filePath: filePath,
                title: title,
                artist: artist,
                album: album,
                albumArtist: albumArtist,
                trackNumber: trackNumber,
                discNumber: discNumber,
                year: year,
                durationMs: durationMs,
                format: format,
                bitrateKbps: bitrateKbps,
                sampleRateHz: sampleRateHz,
                bitDepth: bitDepth,
                fileSizeBytes: fileSizeBytes,
                dateAddedMs: dateAddedMs,
                artworkPath: artworkPath,
                favorite: favorite,
                playCount: playCount,
                lastPlayedMs: lastPlayedMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$SongsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({playlistSongsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (playlistSongsRefs) db.playlistSongs,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (playlistSongsRefs)
                    await $_getPrefetchedData<Song, $SongsTable, PlaylistSong>(
                      currentTable: table,
                      referencedTable: $$SongsTableReferences
                          ._playlistSongsRefsTable(db),
                      managerFromTypedResult: (p0) => $$SongsTableReferences(
                        db,
                        table,
                        p0,
                      ).playlistSongsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.songId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SongsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SongsTable,
      Song,
      $$SongsTableFilterComposer,
      $$SongsTableOrderingComposer,
      $$SongsTableAnnotationComposer,
      $$SongsTableCreateCompanionBuilder,
      $$SongsTableUpdateCompanionBuilder,
      (Song, $$SongsTableReferences),
      Song,
      PrefetchHooks Function({bool playlistSongsRefs})
    >;
typedef $$PlaylistsTableCreateCompanionBuilder = PlaylistsCompanion Function({
  required String id,
  required String name,
  Value<String?> artworkPath,
  required int createdAtMs,
  Value<int> rowid,
});
typedef $$PlaylistsTableUpdateCompanionBuilder = PlaylistsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> artworkPath,
  Value<int> createdAtMs,
  Value<int> rowid,
});

final class $$PlaylistsTableReferences
    extends BaseReferences<_$AppDatabase, $PlaylistsTable, Playlist> {
  $$PlaylistsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PlaylistSongsTable, List<PlaylistSong>>
  _playlistSongsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.playlistSongs,
    aliasName: 'playlists__id__playlist_songs__playlist_id',
  );

  $$PlaylistSongsTableProcessedTableManager get playlistSongsRefs {
    final manager = $$PlaylistSongsTableTableManager(
      $_db,
      $_db.playlistSongs,
    ).filter((f) => f.playlistId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_playlistSongsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlaylistsTableFilterComposer
    extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableFilterComposer({
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

  ColumnFilters<String> get artworkPath => $composableBuilder(
    column: $table.artworkPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> playlistSongsRefs(
    Expression<bool> Function($$PlaylistSongsTableFilterComposer f) f,
  ) {
    final $$PlaylistSongsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistSongs,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistSongsTableFilterComposer(
            $db: $db,
            $table: $db.playlistSongs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlaylistsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableOrderingComposer({
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

  ColumnOrderings<String> get artworkPath => $composableBuilder(
    column: $table.artworkPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlaylistsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableAnnotationComposer({
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

  GeneratedColumn<String> get artworkPath => $composableBuilder(
    column: $table.artworkPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  Expression<T> playlistSongsRefs<T extends Object>(
    Expression<T> Function($$PlaylistSongsTableAnnotationComposer a) f,
  ) {
    final $$PlaylistSongsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistSongs,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistSongsTableAnnotationComposer(
            $db: $db,
            $table: $db.playlistSongs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlaylistsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaylistsTable,
          Playlist,
          $$PlaylistsTableFilterComposer,
          $$PlaylistsTableOrderingComposer,
          $$PlaylistsTableAnnotationComposer,
          $$PlaylistsTableCreateCompanionBuilder,
          $$PlaylistsTableUpdateCompanionBuilder,
          (Playlist, $$PlaylistsTableReferences),
          Playlist,
          PrefetchHooks Function({bool playlistSongsRefs})
        > {
  $$PlaylistsTableTableManager(_$AppDatabase db, $PlaylistsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> artworkPath = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaylistsCompanion(
                id: id,
                name: name,
                artworkPath: artworkPath,
                createdAtMs: createdAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> artworkPath = const Value.absent(),
                required int createdAtMs,
                Value<int> rowid = const Value.absent(),
              }) => PlaylistsCompanion.insert(
                id: id,
                name: name,
                artworkPath: artworkPath,
                createdAtMs: createdAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlaylistsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playlistSongsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (playlistSongsRefs) db.playlistSongs,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (playlistSongsRefs)
                    await $_getPrefetchedData<
                      Playlist,
                      $PlaylistsTable,
                      PlaylistSong
                    >(
                      currentTable: table,
                      referencedTable: $$PlaylistsTableReferences
                          ._playlistSongsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$PlaylistsTableReferences(
                            db,
                            table,
                            p0,
                          ).playlistSongsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.playlistId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PlaylistsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaylistsTable,
      Playlist,
      $$PlaylistsTableFilterComposer,
      $$PlaylistsTableOrderingComposer,
      $$PlaylistsTableAnnotationComposer,
      $$PlaylistsTableCreateCompanionBuilder,
      $$PlaylistsTableUpdateCompanionBuilder,
      (Playlist, $$PlaylistsTableReferences),
      Playlist,
      PrefetchHooks Function({bool playlistSongsRefs})
    >;
typedef $$PlaylistSongsTableCreateCompanionBuilder =
    PlaylistSongsCompanion Function({
      Value<int> id,
      required String playlistId,
      required String songId,
      required int position,
    });
typedef $$PlaylistSongsTableUpdateCompanionBuilder =
    PlaylistSongsCompanion Function({
      Value<int> id,
      Value<String> playlistId,
      Value<String> songId,
      Value<int> position,
    });

final class $$PlaylistSongsTableReferences
    extends BaseReferences<_$AppDatabase, $PlaylistSongsTable, PlaylistSong> {
  $$PlaylistSongsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlaylistsTable _playlistIdTable(_$AppDatabase db) =>
      db.playlists.createAlias('playlist_songs__playlist_id__playlists__id');

  $$PlaylistsTableProcessedTableManager get playlistId {
    final $_column = $_itemColumn<String>('playlist_id')!;

    final manager = $$PlaylistsTableTableManager(
      $_db,
      $_db.playlists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SongsTable _songIdTable(_$AppDatabase db) =>
      db.songs.createAlias('playlist_songs__song_id__songs__id');

  $$SongsTableProcessedTableManager get songId {
    final $_column = $_itemColumn<String>('song_id')!;

    final manager = $$SongsTableTableManager(
      $_db,
      $_db.songs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_songIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlaylistSongsTableFilterComposer
    extends Composer<_$AppDatabase, $PlaylistSongsTable> {
  $$PlaylistSongsTableFilterComposer({
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

  $$PlaylistsTableFilterComposer get playlistId {
    final $$PlaylistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableFilterComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SongsTableFilterComposer get songId {
    final $$SongsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.songId,
      referencedTable: $db.songs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SongsTableFilterComposer(
            $db: $db,
            $table: $db.songs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistSongsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaylistSongsTable> {
  $$PlaylistSongsTableOrderingComposer({
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

  $$PlaylistsTableOrderingComposer get playlistId {
    final $$PlaylistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableOrderingComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SongsTableOrderingComposer get songId {
    final $$SongsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.songId,
      referencedTable: $db.songs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SongsTableOrderingComposer(
            $db: $db,
            $table: $db.songs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistSongsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaylistSongsTable> {
  $$PlaylistSongsTableAnnotationComposer({
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

  $$PlaylistsTableAnnotationComposer get playlistId {
    final $$PlaylistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableAnnotationComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SongsTableAnnotationComposer get songId {
    final $$SongsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.songId,
      referencedTable: $db.songs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SongsTableAnnotationComposer(
            $db: $db,
            $table: $db.songs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistSongsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaylistSongsTable,
          PlaylistSong,
          $$PlaylistSongsTableFilterComposer,
          $$PlaylistSongsTableOrderingComposer,
          $$PlaylistSongsTableAnnotationComposer,
          $$PlaylistSongsTableCreateCompanionBuilder,
          $$PlaylistSongsTableUpdateCompanionBuilder,
          (PlaylistSong, $$PlaylistSongsTableReferences),
          PlaylistSong,
          PrefetchHooks Function({bool playlistId, bool songId})
        > {
  $$PlaylistSongsTableTableManager(_$AppDatabase db, $PlaylistSongsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistSongsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistSongsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistSongsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> playlistId = const Value.absent(),
                Value<String> songId = const Value.absent(),
                Value<int> position = const Value.absent(),
              }) => PlaylistSongsCompanion(
                id: id,
                playlistId: playlistId,
                songId: songId,
                position: position,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String playlistId,
                required String songId,
                required int position,
              }) => PlaylistSongsCompanion.insert(
                id: id,
                playlistId: playlistId,
                songId: songId,
                position: position,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlaylistSongsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playlistId = false, songId = false}) {
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
                    if (playlistId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.playlistId,
                        referencedTable: $$PlaylistSongsTableReferences
                            ._playlistIdTable(db),
                        referencedColumn: $$PlaylistSongsTableReferences
                            ._playlistIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (songId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.songId,
                        referencedTable: $$PlaylistSongsTableReferences
                            ._songIdTable(db),
                        referencedColumn: $$PlaylistSongsTableReferences
                            ._songIdTable(db)
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

typedef $$PlaylistSongsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaylistSongsTable,
      PlaylistSong,
      $$PlaylistSongsTableFilterComposer,
      $$PlaylistSongsTableOrderingComposer,
      $$PlaylistSongsTableAnnotationComposer,
      $$PlaylistSongsTableCreateCompanionBuilder,
      $$PlaylistSongsTableUpdateCompanionBuilder,
      (PlaylistSong, $$PlaylistSongsTableReferences),
      PlaylistSong,
      PrefetchHooks Function({bool playlistId, bool songId})
    >;
typedef $$DownloadHistoryEntriesTableCreateCompanionBuilder =
    DownloadHistoryEntriesCompanion Function({
      required String id,
      required String title,
      required String sourceType,
      required String status,
      Value<String?> outputFormat,
      Value<String?> message,
      required int timestampMs,
      Value<int> rowid,
    });
typedef $$DownloadHistoryEntriesTableUpdateCompanionBuilder =
    DownloadHistoryEntriesCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> sourceType,
      Value<String> status,
      Value<String?> outputFormat,
      Value<String?> message,
      Value<int> timestampMs,
      Value<int> rowid,
    });

class $$DownloadHistoryEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $DownloadHistoryEntriesTable> {
  $$DownloadHistoryEntriesTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outputFormat => $composableBuilder(
    column: $table.outputFormat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestampMs => $composableBuilder(
    column: $table.timestampMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DownloadHistoryEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $DownloadHistoryEntriesTable> {
  $$DownloadHistoryEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outputFormat => $composableBuilder(
    column: $table.outputFormat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestampMs => $composableBuilder(
    column: $table.timestampMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DownloadHistoryEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DownloadHistoryEntriesTable> {
  $$DownloadHistoryEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get outputFormat => $composableBuilder(
    column: $table.outputFormat,
    builder: (column) => column,
  );

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<int> get timestampMs => $composableBuilder(
    column: $table.timestampMs,
    builder: (column) => column,
  );
}

class $$DownloadHistoryEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DownloadHistoryEntriesTable,
          DownloadHistoryEntry,
          $$DownloadHistoryEntriesTableFilterComposer,
          $$DownloadHistoryEntriesTableOrderingComposer,
          $$DownloadHistoryEntriesTableAnnotationComposer,
          $$DownloadHistoryEntriesTableCreateCompanionBuilder,
          $$DownloadHistoryEntriesTableUpdateCompanionBuilder,
          (
            DownloadHistoryEntry,
            BaseReferences<
              _$AppDatabase,
              $DownloadHistoryEntriesTable,
              DownloadHistoryEntry
            >,
          ),
          DownloadHistoryEntry,
          PrefetchHooks Function()
        > {
  $$DownloadHistoryEntriesTableTableManager(
    _$AppDatabase db,
    $DownloadHistoryEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadHistoryEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$DownloadHistoryEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DownloadHistoryEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> outputFormat = const Value.absent(),
                Value<String?> message = const Value.absent(),
                Value<int> timestampMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadHistoryEntriesCompanion(
                id: id,
                title: title,
                sourceType: sourceType,
                status: status,
                outputFormat: outputFormat,
                message: message,
                timestampMs: timestampMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String sourceType,
                required String status,
                Value<String?> outputFormat = const Value.absent(),
                Value<String?> message = const Value.absent(),
                required int timestampMs,
                Value<int> rowid = const Value.absent(),
              }) => DownloadHistoryEntriesCompanion.insert(
                id: id,
                title: title,
                sourceType: sourceType,
                status: status,
                outputFormat: outputFormat,
                message: message,
                timestampMs: timestampMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DownloadHistoryEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DownloadHistoryEntriesTable,
      DownloadHistoryEntry,
      $$DownloadHistoryEntriesTableFilterComposer,
      $$DownloadHistoryEntriesTableOrderingComposer,
      $$DownloadHistoryEntriesTableAnnotationComposer,
      $$DownloadHistoryEntriesTableCreateCompanionBuilder,
      $$DownloadHistoryEntriesTableUpdateCompanionBuilder,
      (
        DownloadHistoryEntry,
        BaseReferences<
          _$AppDatabase,
          $DownloadHistoryEntriesTable,
          DownloadHistoryEntry
        >,
      ),
      DownloadHistoryEntry,
      PrefetchHooks Function()
    >;
typedef $$LibrarySourcesTableCreateCompanionBuilder =
    LibrarySourcesCompanion Function({
      required String sourceKey,
      Value<String?> trackId,
      required String state,
      Value<int> sizeBytes,
      Value<String> volume,
      Value<String> path,
      Value<int> modifiedSec,
      Value<int> rowid,
    });
typedef $$LibrarySourcesTableUpdateCompanionBuilder =
    LibrarySourcesCompanion Function({
      Value<String> sourceKey,
      Value<String?> trackId,
      Value<String> state,
      Value<int> sizeBytes,
      Value<String> volume,
      Value<String> path,
      Value<int> modifiedSec,
      Value<int> rowid,
    });

class $$LibrarySourcesTableFilterComposer
    extends Composer<_$AppDatabase, $LibrarySourcesTable> {
  $$LibrarySourcesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sourceKey => $composableBuilder(
    column: $table.sourceKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get volume => $composableBuilder(
    column: $table.volume,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get modifiedSec => $composableBuilder(
    column: $table.modifiedSec,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LibrarySourcesTableOrderingComposer
    extends Composer<_$AppDatabase, $LibrarySourcesTable> {
  $$LibrarySourcesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sourceKey => $composableBuilder(
    column: $table.sourceKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get volume => $composableBuilder(
    column: $table.volume,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get modifiedSec => $composableBuilder(
    column: $table.modifiedSec,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LibrarySourcesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LibrarySourcesTable> {
  $$LibrarySourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sourceKey =>
      $composableBuilder(column: $table.sourceKey, builder: (column) => column);

  GeneratedColumn<String> get trackId =>
      $composableBuilder(column: $table.trackId, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<String> get volume =>
      $composableBuilder(column: $table.volume, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<int> get modifiedSec => $composableBuilder(
    column: $table.modifiedSec,
    builder: (column) => column,
  );
}

class $$LibrarySourcesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LibrarySourcesTable,
          LibrarySource,
          $$LibrarySourcesTableFilterComposer,
          $$LibrarySourcesTableOrderingComposer,
          $$LibrarySourcesTableAnnotationComposer,
          $$LibrarySourcesTableCreateCompanionBuilder,
          $$LibrarySourcesTableUpdateCompanionBuilder,
          (
            LibrarySource,
            BaseReferences<_$AppDatabase, $LibrarySourcesTable, LibrarySource>,
          ),
          LibrarySource,
          PrefetchHooks Function()
        > {
  $$LibrarySourcesTableTableManager(
    _$AppDatabase db,
    $LibrarySourcesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LibrarySourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LibrarySourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LibrarySourcesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> sourceKey = const Value.absent(),
                Value<String?> trackId = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<String> volume = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<int> modifiedSec = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LibrarySourcesCompanion(
                sourceKey: sourceKey,
                trackId: trackId,
                state: state,
                sizeBytes: sizeBytes,
                volume: volume,
                path: path,
                modifiedSec: modifiedSec,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sourceKey,
                Value<String?> trackId = const Value.absent(),
                required String state,
                Value<int> sizeBytes = const Value.absent(),
                Value<String> volume = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<int> modifiedSec = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LibrarySourcesCompanion.insert(
                sourceKey: sourceKey,
                trackId: trackId,
                state: state,
                sizeBytes: sizeBytes,
                volume: volume,
                path: path,
                modifiedSec: modifiedSec,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LibrarySourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LibrarySourcesTable,
      LibrarySource,
      $$LibrarySourcesTableFilterComposer,
      $$LibrarySourcesTableOrderingComposer,
      $$LibrarySourcesTableAnnotationComposer,
      $$LibrarySourcesTableCreateCompanionBuilder,
      $$LibrarySourcesTableUpdateCompanionBuilder,
      (
        LibrarySource,
        BaseReferences<_$AppDatabase, $LibrarySourcesTable, LibrarySource>,
      ),
      LibrarySource,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SongsTableTableManager get songs =>
      $$SongsTableTableManager(_db, _db.songs);
  $$PlaylistsTableTableManager get playlists =>
      $$PlaylistsTableTableManager(_db, _db.playlists);
  $$PlaylistSongsTableTableManager get playlistSongs =>
      $$PlaylistSongsTableTableManager(_db, _db.playlistSongs);
  $$DownloadHistoryEntriesTableTableManager get downloadHistoryEntries =>
      $$DownloadHistoryEntriesTableTableManager(
        _db,
        _db.downloadHistoryEntries,
      );
  $$LibrarySourcesTableTableManager get librarySources =>
      $$LibrarySourcesTableTableManager(_db, _db.librarySources);
}
