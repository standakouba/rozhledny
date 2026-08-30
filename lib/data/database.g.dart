// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $TowersTable extends Towers with TableInfo<$TowersTable, Tower> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TowersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _osmTypeMeta = const VerificationMeta(
    'osmType',
  );
  @override
  late final GeneratedColumn<String> osmType = GeneratedColumn<String>(
    'osm_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _osmIdMeta = const VerificationMeta('osmId');
  @override
  late final GeneratedColumn<int> osmId = GeneratedColumn<int>(
    'osm_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
    'lon',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<double> height = GeneratedColumn<double>(
    'height',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _eleMeta = const VerificationMeta('ele');
  @override
  late final GeneratedColumn<double> ele = GeneratedColumn<double>(
    'ele',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _regionMeta = const VerificationMeta('region');
  @override
  late final GeneratedColumn<String> region = GeneratedColumn<String>(
    'region',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _websiteMeta = const VerificationMeta(
    'website',
  );
  @override
  late final GeneratedColumn<String> website = GeneratedColumn<String>(
    'website',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _openingHoursMeta = const VerificationMeta(
    'openingHours',
  );
  @override
  late final GeneratedColumn<String> openingHours = GeneratedColumn<String>(
    'opening_hours',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _feeMeta = const VerificationMeta('fee');
  @override
  late final GeneratedColumn<String> fee = GeneratedColumn<String>(
    'fee',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accessMeta = const VerificationMeta('access');
  @override
  late final GeneratedColumn<String> access = GeneratedColumn<String>(
    'access',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wikidataIdMeta = const VerificationMeta(
    'wikidataId',
  );
  @override
  late final GeneratedColumn<String> wikidataId = GeneratedColumn<String>(
    'wikidata_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wikipediaTitleMeta = const VerificationMeta(
    'wikipediaTitle',
  );
  @override
  late final GeneratedColumn<String> wikipediaTitle = GeneratedColumn<String>(
    'wikipedia_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wikipediaUrlMeta = const VerificationMeta(
    'wikipediaUrl',
  );
  @override
  late final GeneratedColumn<String> wikipediaUrl = GeneratedColumn<String>(
    'wikipedia_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wikipediaExtractMeta = const VerificationMeta(
    'wikipediaExtract',
  );
  @override
  late final GeneratedColumn<String> wikipediaExtract = GeneratedColumn<String>(
    'wikipedia_extract',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoUrlMeta = const VerificationMeta(
    'photoUrl',
  );
  @override
  late final GeneratedColumn<String> photoUrl = GeneratedColumn<String>(
    'photo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoAuthorMeta = const VerificationMeta(
    'photoAuthor',
  );
  @override
  late final GeneratedColumn<String> photoAuthor = GeneratedColumn<String>(
    'photo_author',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoLicenseMeta = const VerificationMeta(
    'photoLicense',
  );
  @override
  late final GeneratedColumn<String> photoLicense = GeneratedColumn<String>(
    'photo_license',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoLicenseUrlMeta = const VerificationMeta(
    'photoLicenseUrl',
  );
  @override
  late final GeneratedColumn<String> photoLicenseUrl = GeneratedColumn<String>(
    'photo_license_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoPageUrlMeta = const VerificationMeta(
    'photoPageUrl',
  );
  @override
  late final GeneratedColumn<String> photoPageUrl = GeneratedColumn<String>(
    'photo_page_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TowerSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TowerSource>($TowersTable.$convertersource);
  static const VerificationMeta _userModifiedMeta = const VerificationMeta(
    'userModified',
  );
  @override
  late final GeneratedColumn<bool> userModified = GeneratedColumn<bool>(
    'user_modified',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("user_modified" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _osmMissingMeta = const VerificationMeta(
    'osmMissing',
  );
  @override
  late final GeneratedColumn<bool> osmMissing = GeneratedColumn<bool>(
    'osm_missing',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("osm_missing" IN (0, 1))',
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
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    osmType,
    osmId,
    name,
    lat,
    lon,
    height,
    ele,
    region,
    website,
    note,
    openingHours,
    fee,
    access,
    wikidataId,
    wikipediaTitle,
    wikipediaUrl,
    wikipediaExtract,
    photoUrl,
    photoAuthor,
    photoLicense,
    photoLicenseUrl,
    photoPageUrl,
    source,
    userModified,
    osmMissing,
    createdAt,
    updatedAt,
    deleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'towers';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tower> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('osm_type')) {
      context.handle(
        _osmTypeMeta,
        osmType.isAcceptableOrUnknown(data['osm_type']!, _osmTypeMeta),
      );
    }
    if (data.containsKey('osm_id')) {
      context.handle(
        _osmIdMeta,
        osmId.isAcceptableOrUnknown(data['osm_id']!, _osmIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lon')) {
      context.handle(
        _lonMeta,
        lon.isAcceptableOrUnknown(data['lon']!, _lonMeta),
      );
    } else if (isInserting) {
      context.missing(_lonMeta);
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    if (data.containsKey('ele')) {
      context.handle(
        _eleMeta,
        ele.isAcceptableOrUnknown(data['ele']!, _eleMeta),
      );
    }
    if (data.containsKey('region')) {
      context.handle(
        _regionMeta,
        region.isAcceptableOrUnknown(data['region']!, _regionMeta),
      );
    }
    if (data.containsKey('website')) {
      context.handle(
        _websiteMeta,
        website.isAcceptableOrUnknown(data['website']!, _websiteMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('opening_hours')) {
      context.handle(
        _openingHoursMeta,
        openingHours.isAcceptableOrUnknown(
          data['opening_hours']!,
          _openingHoursMeta,
        ),
      );
    }
    if (data.containsKey('fee')) {
      context.handle(
        _feeMeta,
        fee.isAcceptableOrUnknown(data['fee']!, _feeMeta),
      );
    }
    if (data.containsKey('access')) {
      context.handle(
        _accessMeta,
        access.isAcceptableOrUnknown(data['access']!, _accessMeta),
      );
    }
    if (data.containsKey('wikidata_id')) {
      context.handle(
        _wikidataIdMeta,
        wikidataId.isAcceptableOrUnknown(data['wikidata_id']!, _wikidataIdMeta),
      );
    }
    if (data.containsKey('wikipedia_title')) {
      context.handle(
        _wikipediaTitleMeta,
        wikipediaTitle.isAcceptableOrUnknown(
          data['wikipedia_title']!,
          _wikipediaTitleMeta,
        ),
      );
    }
    if (data.containsKey('wikipedia_url')) {
      context.handle(
        _wikipediaUrlMeta,
        wikipediaUrl.isAcceptableOrUnknown(
          data['wikipedia_url']!,
          _wikipediaUrlMeta,
        ),
      );
    }
    if (data.containsKey('wikipedia_extract')) {
      context.handle(
        _wikipediaExtractMeta,
        wikipediaExtract.isAcceptableOrUnknown(
          data['wikipedia_extract']!,
          _wikipediaExtractMeta,
        ),
      );
    }
    if (data.containsKey('photo_url')) {
      context.handle(
        _photoUrlMeta,
        photoUrl.isAcceptableOrUnknown(data['photo_url']!, _photoUrlMeta),
      );
    }
    if (data.containsKey('photo_author')) {
      context.handle(
        _photoAuthorMeta,
        photoAuthor.isAcceptableOrUnknown(
          data['photo_author']!,
          _photoAuthorMeta,
        ),
      );
    }
    if (data.containsKey('photo_license')) {
      context.handle(
        _photoLicenseMeta,
        photoLicense.isAcceptableOrUnknown(
          data['photo_license']!,
          _photoLicenseMeta,
        ),
      );
    }
    if (data.containsKey('photo_license_url')) {
      context.handle(
        _photoLicenseUrlMeta,
        photoLicenseUrl.isAcceptableOrUnknown(
          data['photo_license_url']!,
          _photoLicenseUrlMeta,
        ),
      );
    }
    if (data.containsKey('photo_page_url')) {
      context.handle(
        _photoPageUrlMeta,
        photoPageUrl.isAcceptableOrUnknown(
          data['photo_page_url']!,
          _photoPageUrlMeta,
        ),
      );
    }
    if (data.containsKey('user_modified')) {
      context.handle(
        _userModifiedMeta,
        userModified.isAcceptableOrUnknown(
          data['user_modified']!,
          _userModifiedMeta,
        ),
      );
    }
    if (data.containsKey('osm_missing')) {
      context.handle(
        _osmMissingMeta,
        osmMissing.isAcceptableOrUnknown(data['osm_missing']!, _osmMissingMeta),
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tower map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tower(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      osmType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}osm_type'],
      ),
      osmId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}osm_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lon'],
      )!,
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}height'],
      ),
      ele: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ele'],
      ),
      region: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}region'],
      ),
      website: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}website'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      openingHours: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}opening_hours'],
      ),
      fee: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fee'],
      ),
      access: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}access'],
      ),
      wikidataId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wikidata_id'],
      ),
      wikipediaTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wikipedia_title'],
      ),
      wikipediaUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wikipedia_url'],
      ),
      wikipediaExtract: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wikipedia_extract'],
      ),
      photoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_url'],
      ),
      photoAuthor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_author'],
      ),
      photoLicense: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_license'],
      ),
      photoLicenseUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_license_url'],
      ),
      photoPageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_page_url'],
      ),
      source: $TowersTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      userModified: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}user_modified'],
      )!,
      osmMissing: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}osm_missing'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
    );
  }

  @override
  $TowersTable createAlias(String alias) {
    return $TowersTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TowerSource, String, String> $convertersource =
      const EnumNameConverter<TowerSource>(TowerSource.values);
}

class Tower extends DataClass implements Insertable<Tower> {
  final int id;
  final String uuid;
  final String? osmType;
  final int? osmId;
  final String? name;
  final double lat;
  final double lon;
  final double? height;
  final double? ele;
  final String? region;
  final String? website;
  final String? note;
  final String? openingHours;
  final String? fee;
  final String? access;
  final String? wikidataId;
  final String? wikipediaTitle;
  final String? wikipediaUrl;
  final String? wikipediaExtract;
  final String? photoUrl;
  final String? photoAuthor;
  final String? photoLicense;
  final String? photoLicenseUrl;
  final String? photoPageUrl;
  final TowerSource source;

  /// Ručně upravený záznam z OSM. Pozdější aktualizace dat ho nesmí přepsat.
  final bool userModified;

  /// Rozhledna, která z OSM zmizela. Nemaže se — můžou na ní viset návštěvy.
  final bool osmMissing;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Tombstone místo skutečného smazání, jinak by import záznam vzkřísil.
  final bool deleted;
  const Tower({
    required this.id,
    required this.uuid,
    this.osmType,
    this.osmId,
    this.name,
    required this.lat,
    required this.lon,
    this.height,
    this.ele,
    this.region,
    this.website,
    this.note,
    this.openingHours,
    this.fee,
    this.access,
    this.wikidataId,
    this.wikipediaTitle,
    this.wikipediaUrl,
    this.wikipediaExtract,
    this.photoUrl,
    this.photoAuthor,
    this.photoLicense,
    this.photoLicenseUrl,
    this.photoPageUrl,
    required this.source,
    required this.userModified,
    required this.osmMissing,
    required this.createdAt,
    required this.updatedAt,
    required this.deleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    if (!nullToAbsent || osmType != null) {
      map['osm_type'] = Variable<String>(osmType);
    }
    if (!nullToAbsent || osmId != null) {
      map['osm_id'] = Variable<int>(osmId);
    }
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<double>(height);
    }
    if (!nullToAbsent || ele != null) {
      map['ele'] = Variable<double>(ele);
    }
    if (!nullToAbsent || region != null) {
      map['region'] = Variable<String>(region);
    }
    if (!nullToAbsent || website != null) {
      map['website'] = Variable<String>(website);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || openingHours != null) {
      map['opening_hours'] = Variable<String>(openingHours);
    }
    if (!nullToAbsent || fee != null) {
      map['fee'] = Variable<String>(fee);
    }
    if (!nullToAbsent || access != null) {
      map['access'] = Variable<String>(access);
    }
    if (!nullToAbsent || wikidataId != null) {
      map['wikidata_id'] = Variable<String>(wikidataId);
    }
    if (!nullToAbsent || wikipediaTitle != null) {
      map['wikipedia_title'] = Variable<String>(wikipediaTitle);
    }
    if (!nullToAbsent || wikipediaUrl != null) {
      map['wikipedia_url'] = Variable<String>(wikipediaUrl);
    }
    if (!nullToAbsent || wikipediaExtract != null) {
      map['wikipedia_extract'] = Variable<String>(wikipediaExtract);
    }
    if (!nullToAbsent || photoUrl != null) {
      map['photo_url'] = Variable<String>(photoUrl);
    }
    if (!nullToAbsent || photoAuthor != null) {
      map['photo_author'] = Variable<String>(photoAuthor);
    }
    if (!nullToAbsent || photoLicense != null) {
      map['photo_license'] = Variable<String>(photoLicense);
    }
    if (!nullToAbsent || photoLicenseUrl != null) {
      map['photo_license_url'] = Variable<String>(photoLicenseUrl);
    }
    if (!nullToAbsent || photoPageUrl != null) {
      map['photo_page_url'] = Variable<String>(photoPageUrl);
    }
    {
      map['source'] = Variable<String>(
        $TowersTable.$convertersource.toSql(source),
      );
    }
    map['user_modified'] = Variable<bool>(userModified);
    map['osm_missing'] = Variable<bool>(osmMissing);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['deleted'] = Variable<bool>(deleted);
    return map;
  }

  TowersCompanion toCompanion(bool nullToAbsent) {
    return TowersCompanion(
      id: Value(id),
      uuid: Value(uuid),
      osmType: osmType == null && nullToAbsent
          ? const Value.absent()
          : Value(osmType),
      osmId: osmId == null && nullToAbsent
          ? const Value.absent()
          : Value(osmId),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      lat: Value(lat),
      lon: Value(lon),
      height: height == null && nullToAbsent
          ? const Value.absent()
          : Value(height),
      ele: ele == null && nullToAbsent ? const Value.absent() : Value(ele),
      region: region == null && nullToAbsent
          ? const Value.absent()
          : Value(region),
      website: website == null && nullToAbsent
          ? const Value.absent()
          : Value(website),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      openingHours: openingHours == null && nullToAbsent
          ? const Value.absent()
          : Value(openingHours),
      fee: fee == null && nullToAbsent ? const Value.absent() : Value(fee),
      access: access == null && nullToAbsent
          ? const Value.absent()
          : Value(access),
      wikidataId: wikidataId == null && nullToAbsent
          ? const Value.absent()
          : Value(wikidataId),
      wikipediaTitle: wikipediaTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(wikipediaTitle),
      wikipediaUrl: wikipediaUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(wikipediaUrl),
      wikipediaExtract: wikipediaExtract == null && nullToAbsent
          ? const Value.absent()
          : Value(wikipediaExtract),
      photoUrl: photoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(photoUrl),
      photoAuthor: photoAuthor == null && nullToAbsent
          ? const Value.absent()
          : Value(photoAuthor),
      photoLicense: photoLicense == null && nullToAbsent
          ? const Value.absent()
          : Value(photoLicense),
      photoLicenseUrl: photoLicenseUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(photoLicenseUrl),
      photoPageUrl: photoPageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPageUrl),
      source: Value(source),
      userModified: Value(userModified),
      osmMissing: Value(osmMissing),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deleted: Value(deleted),
    );
  }

  factory Tower.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tower(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      osmType: serializer.fromJson<String?>(json['osmType']),
      osmId: serializer.fromJson<int?>(json['osmId']),
      name: serializer.fromJson<String?>(json['name']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      height: serializer.fromJson<double?>(json['height']),
      ele: serializer.fromJson<double?>(json['ele']),
      region: serializer.fromJson<String?>(json['region']),
      website: serializer.fromJson<String?>(json['website']),
      note: serializer.fromJson<String?>(json['note']),
      openingHours: serializer.fromJson<String?>(json['openingHours']),
      fee: serializer.fromJson<String?>(json['fee']),
      access: serializer.fromJson<String?>(json['access']),
      wikidataId: serializer.fromJson<String?>(json['wikidataId']),
      wikipediaTitle: serializer.fromJson<String?>(json['wikipediaTitle']),
      wikipediaUrl: serializer.fromJson<String?>(json['wikipediaUrl']),
      wikipediaExtract: serializer.fromJson<String?>(json['wikipediaExtract']),
      photoUrl: serializer.fromJson<String?>(json['photoUrl']),
      photoAuthor: serializer.fromJson<String?>(json['photoAuthor']),
      photoLicense: serializer.fromJson<String?>(json['photoLicense']),
      photoLicenseUrl: serializer.fromJson<String?>(json['photoLicenseUrl']),
      photoPageUrl: serializer.fromJson<String?>(json['photoPageUrl']),
      source: $TowersTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      userModified: serializer.fromJson<bool>(json['userModified']),
      osmMissing: serializer.fromJson<bool>(json['osmMissing']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'osmType': serializer.toJson<String?>(osmType),
      'osmId': serializer.toJson<int?>(osmId),
      'name': serializer.toJson<String?>(name),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'height': serializer.toJson<double?>(height),
      'ele': serializer.toJson<double?>(ele),
      'region': serializer.toJson<String?>(region),
      'website': serializer.toJson<String?>(website),
      'note': serializer.toJson<String?>(note),
      'openingHours': serializer.toJson<String?>(openingHours),
      'fee': serializer.toJson<String?>(fee),
      'access': serializer.toJson<String?>(access),
      'wikidataId': serializer.toJson<String?>(wikidataId),
      'wikipediaTitle': serializer.toJson<String?>(wikipediaTitle),
      'wikipediaUrl': serializer.toJson<String?>(wikipediaUrl),
      'wikipediaExtract': serializer.toJson<String?>(wikipediaExtract),
      'photoUrl': serializer.toJson<String?>(photoUrl),
      'photoAuthor': serializer.toJson<String?>(photoAuthor),
      'photoLicense': serializer.toJson<String?>(photoLicense),
      'photoLicenseUrl': serializer.toJson<String?>(photoLicenseUrl),
      'photoPageUrl': serializer.toJson<String?>(photoPageUrl),
      'source': serializer.toJson<String>(
        $TowersTable.$convertersource.toJson(source),
      ),
      'userModified': serializer.toJson<bool>(userModified),
      'osmMissing': serializer.toJson<bool>(osmMissing),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deleted': serializer.toJson<bool>(deleted),
    };
  }

  Tower copyWith({
    int? id,
    String? uuid,
    Value<String?> osmType = const Value.absent(),
    Value<int?> osmId = const Value.absent(),
    Value<String?> name = const Value.absent(),
    double? lat,
    double? lon,
    Value<double?> height = const Value.absent(),
    Value<double?> ele = const Value.absent(),
    Value<String?> region = const Value.absent(),
    Value<String?> website = const Value.absent(),
    Value<String?> note = const Value.absent(),
    Value<String?> openingHours = const Value.absent(),
    Value<String?> fee = const Value.absent(),
    Value<String?> access = const Value.absent(),
    Value<String?> wikidataId = const Value.absent(),
    Value<String?> wikipediaTitle = const Value.absent(),
    Value<String?> wikipediaUrl = const Value.absent(),
    Value<String?> wikipediaExtract = const Value.absent(),
    Value<String?> photoUrl = const Value.absent(),
    Value<String?> photoAuthor = const Value.absent(),
    Value<String?> photoLicense = const Value.absent(),
    Value<String?> photoLicenseUrl = const Value.absent(),
    Value<String?> photoPageUrl = const Value.absent(),
    TowerSource? source,
    bool? userModified,
    bool? osmMissing,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? deleted,
  }) => Tower(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    osmType: osmType.present ? osmType.value : this.osmType,
    osmId: osmId.present ? osmId.value : this.osmId,
    name: name.present ? name.value : this.name,
    lat: lat ?? this.lat,
    lon: lon ?? this.lon,
    height: height.present ? height.value : this.height,
    ele: ele.present ? ele.value : this.ele,
    region: region.present ? region.value : this.region,
    website: website.present ? website.value : this.website,
    note: note.present ? note.value : this.note,
    openingHours: openingHours.present ? openingHours.value : this.openingHours,
    fee: fee.present ? fee.value : this.fee,
    access: access.present ? access.value : this.access,
    wikidataId: wikidataId.present ? wikidataId.value : this.wikidataId,
    wikipediaTitle: wikipediaTitle.present
        ? wikipediaTitle.value
        : this.wikipediaTitle,
    wikipediaUrl: wikipediaUrl.present ? wikipediaUrl.value : this.wikipediaUrl,
    wikipediaExtract: wikipediaExtract.present
        ? wikipediaExtract.value
        : this.wikipediaExtract,
    photoUrl: photoUrl.present ? photoUrl.value : this.photoUrl,
    photoAuthor: photoAuthor.present ? photoAuthor.value : this.photoAuthor,
    photoLicense: photoLicense.present ? photoLicense.value : this.photoLicense,
    photoLicenseUrl: photoLicenseUrl.present
        ? photoLicenseUrl.value
        : this.photoLicenseUrl,
    photoPageUrl: photoPageUrl.present ? photoPageUrl.value : this.photoPageUrl,
    source: source ?? this.source,
    userModified: userModified ?? this.userModified,
    osmMissing: osmMissing ?? this.osmMissing,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deleted: deleted ?? this.deleted,
  );
  Tower copyWithCompanion(TowersCompanion data) {
    return Tower(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      osmType: data.osmType.present ? data.osmType.value : this.osmType,
      osmId: data.osmId.present ? data.osmId.value : this.osmId,
      name: data.name.present ? data.name.value : this.name,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      height: data.height.present ? data.height.value : this.height,
      ele: data.ele.present ? data.ele.value : this.ele,
      region: data.region.present ? data.region.value : this.region,
      website: data.website.present ? data.website.value : this.website,
      note: data.note.present ? data.note.value : this.note,
      openingHours: data.openingHours.present
          ? data.openingHours.value
          : this.openingHours,
      fee: data.fee.present ? data.fee.value : this.fee,
      access: data.access.present ? data.access.value : this.access,
      wikidataId: data.wikidataId.present
          ? data.wikidataId.value
          : this.wikidataId,
      wikipediaTitle: data.wikipediaTitle.present
          ? data.wikipediaTitle.value
          : this.wikipediaTitle,
      wikipediaUrl: data.wikipediaUrl.present
          ? data.wikipediaUrl.value
          : this.wikipediaUrl,
      wikipediaExtract: data.wikipediaExtract.present
          ? data.wikipediaExtract.value
          : this.wikipediaExtract,
      photoUrl: data.photoUrl.present ? data.photoUrl.value : this.photoUrl,
      photoAuthor: data.photoAuthor.present
          ? data.photoAuthor.value
          : this.photoAuthor,
      photoLicense: data.photoLicense.present
          ? data.photoLicense.value
          : this.photoLicense,
      photoLicenseUrl: data.photoLicenseUrl.present
          ? data.photoLicenseUrl.value
          : this.photoLicenseUrl,
      photoPageUrl: data.photoPageUrl.present
          ? data.photoPageUrl.value
          : this.photoPageUrl,
      source: data.source.present ? data.source.value : this.source,
      userModified: data.userModified.present
          ? data.userModified.value
          : this.userModified,
      osmMissing: data.osmMissing.present
          ? data.osmMissing.value
          : this.osmMissing,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tower(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('osmType: $osmType, ')
          ..write('osmId: $osmId, ')
          ..write('name: $name, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('height: $height, ')
          ..write('ele: $ele, ')
          ..write('region: $region, ')
          ..write('website: $website, ')
          ..write('note: $note, ')
          ..write('openingHours: $openingHours, ')
          ..write('fee: $fee, ')
          ..write('access: $access, ')
          ..write('wikidataId: $wikidataId, ')
          ..write('wikipediaTitle: $wikipediaTitle, ')
          ..write('wikipediaUrl: $wikipediaUrl, ')
          ..write('wikipediaExtract: $wikipediaExtract, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('photoAuthor: $photoAuthor, ')
          ..write('photoLicense: $photoLicense, ')
          ..write('photoLicenseUrl: $photoLicenseUrl, ')
          ..write('photoPageUrl: $photoPageUrl, ')
          ..write('source: $source, ')
          ..write('userModified: $userModified, ')
          ..write('osmMissing: $osmMissing, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    uuid,
    osmType,
    osmId,
    name,
    lat,
    lon,
    height,
    ele,
    region,
    website,
    note,
    openingHours,
    fee,
    access,
    wikidataId,
    wikipediaTitle,
    wikipediaUrl,
    wikipediaExtract,
    photoUrl,
    photoAuthor,
    photoLicense,
    photoLicenseUrl,
    photoPageUrl,
    source,
    userModified,
    osmMissing,
    createdAt,
    updatedAt,
    deleted,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tower &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.osmType == this.osmType &&
          other.osmId == this.osmId &&
          other.name == this.name &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.height == this.height &&
          other.ele == this.ele &&
          other.region == this.region &&
          other.website == this.website &&
          other.note == this.note &&
          other.openingHours == this.openingHours &&
          other.fee == this.fee &&
          other.access == this.access &&
          other.wikidataId == this.wikidataId &&
          other.wikipediaTitle == this.wikipediaTitle &&
          other.wikipediaUrl == this.wikipediaUrl &&
          other.wikipediaExtract == this.wikipediaExtract &&
          other.photoUrl == this.photoUrl &&
          other.photoAuthor == this.photoAuthor &&
          other.photoLicense == this.photoLicense &&
          other.photoLicenseUrl == this.photoLicenseUrl &&
          other.photoPageUrl == this.photoPageUrl &&
          other.source == this.source &&
          other.userModified == this.userModified &&
          other.osmMissing == this.osmMissing &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deleted == this.deleted);
}

class TowersCompanion extends UpdateCompanion<Tower> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String?> osmType;
  final Value<int?> osmId;
  final Value<String?> name;
  final Value<double> lat;
  final Value<double> lon;
  final Value<double?> height;
  final Value<double?> ele;
  final Value<String?> region;
  final Value<String?> website;
  final Value<String?> note;
  final Value<String?> openingHours;
  final Value<String?> fee;
  final Value<String?> access;
  final Value<String?> wikidataId;
  final Value<String?> wikipediaTitle;
  final Value<String?> wikipediaUrl;
  final Value<String?> wikipediaExtract;
  final Value<String?> photoUrl;
  final Value<String?> photoAuthor;
  final Value<String?> photoLicense;
  final Value<String?> photoLicenseUrl;
  final Value<String?> photoPageUrl;
  final Value<TowerSource> source;
  final Value<bool> userModified;
  final Value<bool> osmMissing;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> deleted;
  const TowersCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.osmType = const Value.absent(),
    this.osmId = const Value.absent(),
    this.name = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.height = const Value.absent(),
    this.ele = const Value.absent(),
    this.region = const Value.absent(),
    this.website = const Value.absent(),
    this.note = const Value.absent(),
    this.openingHours = const Value.absent(),
    this.fee = const Value.absent(),
    this.access = const Value.absent(),
    this.wikidataId = const Value.absent(),
    this.wikipediaTitle = const Value.absent(),
    this.wikipediaUrl = const Value.absent(),
    this.wikipediaExtract = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.photoAuthor = const Value.absent(),
    this.photoLicense = const Value.absent(),
    this.photoLicenseUrl = const Value.absent(),
    this.photoPageUrl = const Value.absent(),
    this.source = const Value.absent(),
    this.userModified = const Value.absent(),
    this.osmMissing = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
  });
  TowersCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    this.osmType = const Value.absent(),
    this.osmId = const Value.absent(),
    this.name = const Value.absent(),
    required double lat,
    required double lon,
    this.height = const Value.absent(),
    this.ele = const Value.absent(),
    this.region = const Value.absent(),
    this.website = const Value.absent(),
    this.note = const Value.absent(),
    this.openingHours = const Value.absent(),
    this.fee = const Value.absent(),
    this.access = const Value.absent(),
    this.wikidataId = const Value.absent(),
    this.wikipediaTitle = const Value.absent(),
    this.wikipediaUrl = const Value.absent(),
    this.wikipediaExtract = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.photoAuthor = const Value.absent(),
    this.photoLicense = const Value.absent(),
    this.photoLicenseUrl = const Value.absent(),
    this.photoPageUrl = const Value.absent(),
    required TowerSource source,
    this.userModified = const Value.absent(),
    this.osmMissing = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deleted = const Value.absent(),
  }) : uuid = Value(uuid),
       lat = Value(lat),
       lon = Value(lon),
       source = Value(source),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Tower> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? osmType,
    Expression<int>? osmId,
    Expression<String>? name,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<double>? height,
    Expression<double>? ele,
    Expression<String>? region,
    Expression<String>? website,
    Expression<String>? note,
    Expression<String>? openingHours,
    Expression<String>? fee,
    Expression<String>? access,
    Expression<String>? wikidataId,
    Expression<String>? wikipediaTitle,
    Expression<String>? wikipediaUrl,
    Expression<String>? wikipediaExtract,
    Expression<String>? photoUrl,
    Expression<String>? photoAuthor,
    Expression<String>? photoLicense,
    Expression<String>? photoLicenseUrl,
    Expression<String>? photoPageUrl,
    Expression<String>? source,
    Expression<bool>? userModified,
    Expression<bool>? osmMissing,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? deleted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (osmType != null) 'osm_type': osmType,
      if (osmId != null) 'osm_id': osmId,
      if (name != null) 'name': name,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (height != null) 'height': height,
      if (ele != null) 'ele': ele,
      if (region != null) 'region': region,
      if (website != null) 'website': website,
      if (note != null) 'note': note,
      if (openingHours != null) 'opening_hours': openingHours,
      if (fee != null) 'fee': fee,
      if (access != null) 'access': access,
      if (wikidataId != null) 'wikidata_id': wikidataId,
      if (wikipediaTitle != null) 'wikipedia_title': wikipediaTitle,
      if (wikipediaUrl != null) 'wikipedia_url': wikipediaUrl,
      if (wikipediaExtract != null) 'wikipedia_extract': wikipediaExtract,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (photoAuthor != null) 'photo_author': photoAuthor,
      if (photoLicense != null) 'photo_license': photoLicense,
      if (photoLicenseUrl != null) 'photo_license_url': photoLicenseUrl,
      if (photoPageUrl != null) 'photo_page_url': photoPageUrl,
      if (source != null) 'source': source,
      if (userModified != null) 'user_modified': userModified,
      if (osmMissing != null) 'osm_missing': osmMissing,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deleted != null) 'deleted': deleted,
    });
  }

  TowersCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String?>? osmType,
    Value<int?>? osmId,
    Value<String?>? name,
    Value<double>? lat,
    Value<double>? lon,
    Value<double?>? height,
    Value<double?>? ele,
    Value<String?>? region,
    Value<String?>? website,
    Value<String?>? note,
    Value<String?>? openingHours,
    Value<String?>? fee,
    Value<String?>? access,
    Value<String?>? wikidataId,
    Value<String?>? wikipediaTitle,
    Value<String?>? wikipediaUrl,
    Value<String?>? wikipediaExtract,
    Value<String?>? photoUrl,
    Value<String?>? photoAuthor,
    Value<String?>? photoLicense,
    Value<String?>? photoLicenseUrl,
    Value<String?>? photoPageUrl,
    Value<TowerSource>? source,
    Value<bool>? userModified,
    Value<bool>? osmMissing,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? deleted,
  }) {
    return TowersCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      osmType: osmType ?? this.osmType,
      osmId: osmId ?? this.osmId,
      name: name ?? this.name,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      height: height ?? this.height,
      ele: ele ?? this.ele,
      region: region ?? this.region,
      website: website ?? this.website,
      note: note ?? this.note,
      openingHours: openingHours ?? this.openingHours,
      fee: fee ?? this.fee,
      access: access ?? this.access,
      wikidataId: wikidataId ?? this.wikidataId,
      wikipediaTitle: wikipediaTitle ?? this.wikipediaTitle,
      wikipediaUrl: wikipediaUrl ?? this.wikipediaUrl,
      wikipediaExtract: wikipediaExtract ?? this.wikipediaExtract,
      photoUrl: photoUrl ?? this.photoUrl,
      photoAuthor: photoAuthor ?? this.photoAuthor,
      photoLicense: photoLicense ?? this.photoLicense,
      photoLicenseUrl: photoLicenseUrl ?? this.photoLicenseUrl,
      photoPageUrl: photoPageUrl ?? this.photoPageUrl,
      source: source ?? this.source,
      userModified: userModified ?? this.userModified,
      osmMissing: osmMissing ?? this.osmMissing,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (osmType.present) {
      map['osm_type'] = Variable<String>(osmType.value);
    }
    if (osmId.present) {
      map['osm_id'] = Variable<int>(osmId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (height.present) {
      map['height'] = Variable<double>(height.value);
    }
    if (ele.present) {
      map['ele'] = Variable<double>(ele.value);
    }
    if (region.present) {
      map['region'] = Variable<String>(region.value);
    }
    if (website.present) {
      map['website'] = Variable<String>(website.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (openingHours.present) {
      map['opening_hours'] = Variable<String>(openingHours.value);
    }
    if (fee.present) {
      map['fee'] = Variable<String>(fee.value);
    }
    if (access.present) {
      map['access'] = Variable<String>(access.value);
    }
    if (wikidataId.present) {
      map['wikidata_id'] = Variable<String>(wikidataId.value);
    }
    if (wikipediaTitle.present) {
      map['wikipedia_title'] = Variable<String>(wikipediaTitle.value);
    }
    if (wikipediaUrl.present) {
      map['wikipedia_url'] = Variable<String>(wikipediaUrl.value);
    }
    if (wikipediaExtract.present) {
      map['wikipedia_extract'] = Variable<String>(wikipediaExtract.value);
    }
    if (photoUrl.present) {
      map['photo_url'] = Variable<String>(photoUrl.value);
    }
    if (photoAuthor.present) {
      map['photo_author'] = Variable<String>(photoAuthor.value);
    }
    if (photoLicense.present) {
      map['photo_license'] = Variable<String>(photoLicense.value);
    }
    if (photoLicenseUrl.present) {
      map['photo_license_url'] = Variable<String>(photoLicenseUrl.value);
    }
    if (photoPageUrl.present) {
      map['photo_page_url'] = Variable<String>(photoPageUrl.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $TowersTable.$convertersource.toSql(source.value),
      );
    }
    if (userModified.present) {
      map['user_modified'] = Variable<bool>(userModified.value);
    }
    if (osmMissing.present) {
      map['osm_missing'] = Variable<bool>(osmMissing.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TowersCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('osmType: $osmType, ')
          ..write('osmId: $osmId, ')
          ..write('name: $name, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('height: $height, ')
          ..write('ele: $ele, ')
          ..write('region: $region, ')
          ..write('website: $website, ')
          ..write('note: $note, ')
          ..write('openingHours: $openingHours, ')
          ..write('fee: $fee, ')
          ..write('access: $access, ')
          ..write('wikidataId: $wikidataId, ')
          ..write('wikipediaTitle: $wikipediaTitle, ')
          ..write('wikipediaUrl: $wikipediaUrl, ')
          ..write('wikipediaExtract: $wikipediaExtract, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('photoAuthor: $photoAuthor, ')
          ..write('photoLicense: $photoLicense, ')
          ..write('photoLicenseUrl: $photoLicenseUrl, ')
          ..write('photoPageUrl: $photoPageUrl, ')
          ..write('source: $source, ')
          ..write('userModified: $userModified, ')
          ..write('osmMissing: $osmMissing, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted')
          ..write(')'))
        .toString();
  }
}

class $VisitsTable extends Visits with TableInfo<$VisitsTable, Visit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VisitsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _towerUuidMeta = const VerificationMeta(
    'towerUuid',
  );
  @override
  late final GeneratedColumn<String> towerUuid = GeneratedColumn<String>(
    'tower_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visitedOnMeta = const VerificationMeta(
    'visitedOn',
  );
  @override
  late final GeneratedColumn<DateTime> visitedOn = GeneratedColumn<DateTime>(
    'visited_on',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    towerUuid,
    visitedOn,
    rating,
    note,
    createdAt,
    updatedAt,
    deleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'visits';
  @override
  VerificationContext validateIntegrity(
    Insertable<Visit> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('tower_uuid')) {
      context.handle(
        _towerUuidMeta,
        towerUuid.isAcceptableOrUnknown(data['tower_uuid']!, _towerUuidMeta),
      );
    } else if (isInserting) {
      context.missing(_towerUuidMeta);
    }
    if (data.containsKey('visited_on')) {
      context.handle(
        _visitedOnMeta,
        visitedOn.isAcceptableOrUnknown(data['visited_on']!, _visitedOnMeta),
      );
    } else if (isInserting) {
      context.missing(_visitedOnMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Visit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Visit(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      towerUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tower_uuid'],
      )!,
      visitedOn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}visited_on'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
    );
  }

  @override
  $VisitsTable createAlias(String alias) {
    return $VisitsTable(attachedDatabase, alias);
  }
}

class Visit extends DataClass implements Insertable<Visit> {
  final int id;
  final String uuid;
  final String towerUuid;

  /// Jen datum, bez času — zapisuje se i zpětně z papírové mapy.
  final DateTime visitedOn;
  final int? rating;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool deleted;
  const Visit({
    required this.id,
    required this.uuid,
    required this.towerUuid,
    required this.visitedOn,
    this.rating,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    required this.deleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['tower_uuid'] = Variable<String>(towerUuid);
    map['visited_on'] = Variable<DateTime>(visitedOn);
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<int>(rating);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['deleted'] = Variable<bool>(deleted);
    return map;
  }

  VisitsCompanion toCompanion(bool nullToAbsent) {
    return VisitsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      towerUuid: Value(towerUuid),
      visitedOn: Value(visitedOn),
      rating: rating == null && nullToAbsent
          ? const Value.absent()
          : Value(rating),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deleted: Value(deleted),
    );
  }

  factory Visit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Visit(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      towerUuid: serializer.fromJson<String>(json['towerUuid']),
      visitedOn: serializer.fromJson<DateTime>(json['visitedOn']),
      rating: serializer.fromJson<int?>(json['rating']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'towerUuid': serializer.toJson<String>(towerUuid),
      'visitedOn': serializer.toJson<DateTime>(visitedOn),
      'rating': serializer.toJson<int?>(rating),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deleted': serializer.toJson<bool>(deleted),
    };
  }

  Visit copyWith({
    int? id,
    String? uuid,
    String? towerUuid,
    DateTime? visitedOn,
    Value<int?> rating = const Value.absent(),
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? deleted,
  }) => Visit(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    towerUuid: towerUuid ?? this.towerUuid,
    visitedOn: visitedOn ?? this.visitedOn,
    rating: rating.present ? rating.value : this.rating,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deleted: deleted ?? this.deleted,
  );
  Visit copyWithCompanion(VisitsCompanion data) {
    return Visit(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      towerUuid: data.towerUuid.present ? data.towerUuid.value : this.towerUuid,
      visitedOn: data.visitedOn.present ? data.visitedOn.value : this.visitedOn,
      rating: data.rating.present ? data.rating.value : this.rating,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Visit(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('towerUuid: $towerUuid, ')
          ..write('visitedOn: $visitedOn, ')
          ..write('rating: $rating, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    towerUuid,
    visitedOn,
    rating,
    note,
    createdAt,
    updatedAt,
    deleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Visit &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.towerUuid == this.towerUuid &&
          other.visitedOn == this.visitedOn &&
          other.rating == this.rating &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deleted == this.deleted);
}

class VisitsCompanion extends UpdateCompanion<Visit> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> towerUuid;
  final Value<DateTime> visitedOn;
  final Value<int?> rating;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> deleted;
  const VisitsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.towerUuid = const Value.absent(),
    this.visitedOn = const Value.absent(),
    this.rating = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
  });
  VisitsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String towerUuid,
    required DateTime visitedOn,
    this.rating = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deleted = const Value.absent(),
  }) : uuid = Value(uuid),
       towerUuid = Value(towerUuid),
       visitedOn = Value(visitedOn),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Visit> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? towerUuid,
    Expression<DateTime>? visitedOn,
    Expression<int>? rating,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? deleted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (towerUuid != null) 'tower_uuid': towerUuid,
      if (visitedOn != null) 'visited_on': visitedOn,
      if (rating != null) 'rating': rating,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deleted != null) 'deleted': deleted,
    });
  }

  VisitsCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String>? towerUuid,
    Value<DateTime>? visitedOn,
    Value<int?>? rating,
    Value<String?>? note,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? deleted,
  }) {
    return VisitsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      towerUuid: towerUuid ?? this.towerUuid,
      visitedOn: visitedOn ?? this.visitedOn,
      rating: rating ?? this.rating,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (towerUuid.present) {
      map['tower_uuid'] = Variable<String>(towerUuid.value);
    }
    if (visitedOn.present) {
      map['visited_on'] = Variable<DateTime>(visitedOn.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VisitsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('towerUuid: $towerUuid, ')
          ..write('visitedOn: $visitedOn, ')
          ..write('rating: $rating, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted')
          ..write(')'))
        .toString();
  }
}

class $PhotosTable extends Photos with TableInfo<$PhotosTable, Photo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PhotosTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _visitUuidMeta = const VerificationMeta(
    'visitUuid',
  );
  @override
  late final GeneratedColumn<String> visitUuid = GeneratedColumn<String>(
    'visit_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    visitUuid,
    fileName,
    createdAt,
    deleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'photos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Photo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('visit_uuid')) {
      context.handle(
        _visitUuidMeta,
        visitUuid.isAcceptableOrUnknown(data['visit_uuid']!, _visitUuidMeta),
      );
    } else if (isInserting) {
      context.missing(_visitUuidMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Photo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Photo(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      visitUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visit_uuid'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
    );
  }

  @override
  $PhotosTable createAlias(String alias) {
    return $PhotosTable(attachedDatabase, alias);
  }
}

class Photo extends DataClass implements Insertable<Photo> {
  final int id;
  final String uuid;
  final String visitUuid;
  final String fileName;
  final DateTime createdAt;
  final bool deleted;
  const Photo({
    required this.id,
    required this.uuid,
    required this.visitUuid,
    required this.fileName,
    required this.createdAt,
    required this.deleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['visit_uuid'] = Variable<String>(visitUuid);
    map['file_name'] = Variable<String>(fileName);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['deleted'] = Variable<bool>(deleted);
    return map;
  }

  PhotosCompanion toCompanion(bool nullToAbsent) {
    return PhotosCompanion(
      id: Value(id),
      uuid: Value(uuid),
      visitUuid: Value(visitUuid),
      fileName: Value(fileName),
      createdAt: Value(createdAt),
      deleted: Value(deleted),
    );
  }

  factory Photo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Photo(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      visitUuid: serializer.fromJson<String>(json['visitUuid']),
      fileName: serializer.fromJson<String>(json['fileName']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'visitUuid': serializer.toJson<String>(visitUuid),
      'fileName': serializer.toJson<String>(fileName),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'deleted': serializer.toJson<bool>(deleted),
    };
  }

  Photo copyWith({
    int? id,
    String? uuid,
    String? visitUuid,
    String? fileName,
    DateTime? createdAt,
    bool? deleted,
  }) => Photo(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    visitUuid: visitUuid ?? this.visitUuid,
    fileName: fileName ?? this.fileName,
    createdAt: createdAt ?? this.createdAt,
    deleted: deleted ?? this.deleted,
  );
  Photo copyWithCompanion(PhotosCompanion data) {
    return Photo(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      visitUuid: data.visitUuid.present ? data.visitUuid.value : this.visitUuid,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Photo(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('visitUuid: $visitUuid, ')
          ..write('fileName: $fileName, ')
          ..write('createdAt: $createdAt, ')
          ..write('deleted: $deleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, uuid, visitUuid, fileName, createdAt, deleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Photo &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.visitUuid == this.visitUuid &&
          other.fileName == this.fileName &&
          other.createdAt == this.createdAt &&
          other.deleted == this.deleted);
}

class PhotosCompanion extends UpdateCompanion<Photo> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> visitUuid;
  final Value<String> fileName;
  final Value<DateTime> createdAt;
  final Value<bool> deleted;
  const PhotosCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.visitUuid = const Value.absent(),
    this.fileName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deleted = const Value.absent(),
  });
  PhotosCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String visitUuid,
    required String fileName,
    required DateTime createdAt,
    this.deleted = const Value.absent(),
  }) : uuid = Value(uuid),
       visitUuid = Value(visitUuid),
       fileName = Value(fileName),
       createdAt = Value(createdAt);
  static Insertable<Photo> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? visitUuid,
    Expression<String>? fileName,
    Expression<DateTime>? createdAt,
    Expression<bool>? deleted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (visitUuid != null) 'visit_uuid': visitUuid,
      if (fileName != null) 'file_name': fileName,
      if (createdAt != null) 'created_at': createdAt,
      if (deleted != null) 'deleted': deleted,
    });
  }

  PhotosCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String>? visitUuid,
    Value<String>? fileName,
    Value<DateTime>? createdAt,
    Value<bool>? deleted,
  }) {
    return PhotosCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      visitUuid: visitUuid ?? this.visitUuid,
      fileName: fileName ?? this.fileName,
      createdAt: createdAt ?? this.createdAt,
      deleted: deleted ?? this.deleted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (visitUuid.present) {
      map['visit_uuid'] = Variable<String>(visitUuid.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PhotosCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('visitUuid: $visitUuid, ')
          ..write('fileName: $fileName, ')
          ..write('createdAt: $createdAt, ')
          ..write('deleted: $deleted')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TowersTable towers = $TowersTable(this);
  late final $VisitsTable visits = $VisitsTable(this);
  late final $PhotosTable photos = $PhotosTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [towers, visits, photos];
}

typedef $$TowersTableCreateCompanionBuilder = TowersCompanion Function({
  Value<int> id,
  required String uuid,
  Value<String?> osmType,
  Value<int?> osmId,
  Value<String?> name,
  required double lat,
  required double lon,
  Value<double?> height,
  Value<double?> ele,
  Value<String?> region,
  Value<String?> website,
  Value<String?> note,
  Value<String?> openingHours,
  Value<String?> fee,
  Value<String?> access,
  Value<String?> wikidataId,
  Value<String?> wikipediaTitle,
  Value<String?> wikipediaUrl,
  Value<String?> wikipediaExtract,
  Value<String?> photoUrl,
  Value<String?> photoAuthor,
  Value<String?> photoLicense,
  Value<String?> photoLicenseUrl,
  Value<String?> photoPageUrl,
  required TowerSource source,
  Value<bool> userModified,
  Value<bool> osmMissing,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<bool> deleted,
});
typedef $$TowersTableUpdateCompanionBuilder = TowersCompanion Function({
  Value<int> id,
  Value<String> uuid,
  Value<String?> osmType,
  Value<int?> osmId,
  Value<String?> name,
  Value<double> lat,
  Value<double> lon,
  Value<double?> height,
  Value<double?> ele,
  Value<String?> region,
  Value<String?> website,
  Value<String?> note,
  Value<String?> openingHours,
  Value<String?> fee,
  Value<String?> access,
  Value<String?> wikidataId,
  Value<String?> wikipediaTitle,
  Value<String?> wikipediaUrl,
  Value<String?> wikipediaExtract,
  Value<String?> photoUrl,
  Value<String?> photoAuthor,
  Value<String?> photoLicense,
  Value<String?> photoLicenseUrl,
  Value<String?> photoPageUrl,
  Value<TowerSource> source,
  Value<bool> userModified,
  Value<bool> osmMissing,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> deleted,
});

class $$TowersTableFilterComposer
    extends Composer<_$AppDatabase, $TowersTable> {
  $$TowersTableFilterComposer({
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

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get osmType => $composableBuilder(
    column: $table.osmType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get osmId => $composableBuilder(
    column: $table.osmId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ele => $composableBuilder(
    column: $table.ele,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get region => $composableBuilder(
    column: $table.region,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get website => $composableBuilder(
    column: $table.website,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get openingHours => $composableBuilder(
    column: $table.openingHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fee => $composableBuilder(
    column: $table.fee,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get access => $composableBuilder(
    column: $table.access,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wikidataId => $composableBuilder(
    column: $table.wikidataId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wikipediaTitle => $composableBuilder(
    column: $table.wikipediaTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wikipediaUrl => $composableBuilder(
    column: $table.wikipediaUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wikipediaExtract => $composableBuilder(
    column: $table.wikipediaExtract,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoAuthor => $composableBuilder(
    column: $table.photoAuthor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoLicense => $composableBuilder(
    column: $table.photoLicense,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoLicenseUrl => $composableBuilder(
    column: $table.photoLicenseUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPageUrl => $composableBuilder(
    column: $table.photoPageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TowerSource, TowerSource, String> get source =>
      $composableBuilder(
        column: $table.source,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get userModified => $composableBuilder(
    column: $table.userModified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get osmMissing => $composableBuilder(
    column: $table.osmMissing,
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

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TowersTableOrderingComposer
    extends Composer<_$AppDatabase, $TowersTable> {
  $$TowersTableOrderingComposer({
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

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get osmType => $composableBuilder(
    column: $table.osmType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get osmId => $composableBuilder(
    column: $table.osmId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ele => $composableBuilder(
    column: $table.ele,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get region => $composableBuilder(
    column: $table.region,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get website => $composableBuilder(
    column: $table.website,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get openingHours => $composableBuilder(
    column: $table.openingHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fee => $composableBuilder(
    column: $table.fee,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get access => $composableBuilder(
    column: $table.access,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wikidataId => $composableBuilder(
    column: $table.wikidataId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wikipediaTitle => $composableBuilder(
    column: $table.wikipediaTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wikipediaUrl => $composableBuilder(
    column: $table.wikipediaUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wikipediaExtract => $composableBuilder(
    column: $table.wikipediaExtract,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoAuthor => $composableBuilder(
    column: $table.photoAuthor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoLicense => $composableBuilder(
    column: $table.photoLicense,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoLicenseUrl => $composableBuilder(
    column: $table.photoLicenseUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPageUrl => $composableBuilder(
    column: $table.photoPageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get userModified => $composableBuilder(
    column: $table.userModified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get osmMissing => $composableBuilder(
    column: $table.osmMissing,
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

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TowersTableAnnotationComposer
    extends Composer<_$AppDatabase, $TowersTable> {
  $$TowersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get osmType =>
      $composableBuilder(column: $table.osmType, builder: (column) => column);

  GeneratedColumn<int> get osmId =>
      $composableBuilder(column: $table.osmId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => column);

  GeneratedColumn<double> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<double> get ele =>
      $composableBuilder(column: $table.ele, builder: (column) => column);

  GeneratedColumn<String> get region =>
      $composableBuilder(column: $table.region, builder: (column) => column);

  GeneratedColumn<String> get website =>
      $composableBuilder(column: $table.website, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get openingHours => $composableBuilder(
    column: $table.openingHours,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fee =>
      $composableBuilder(column: $table.fee, builder: (column) => column);

  GeneratedColumn<String> get access =>
      $composableBuilder(column: $table.access, builder: (column) => column);

  GeneratedColumn<String> get wikidataId => $composableBuilder(
    column: $table.wikidataId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get wikipediaTitle => $composableBuilder(
    column: $table.wikipediaTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get wikipediaUrl => $composableBuilder(
    column: $table.wikipediaUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get wikipediaExtract => $composableBuilder(
    column: $table.wikipediaExtract,
    builder: (column) => column,
  );

  GeneratedColumn<String> get photoUrl =>
      $composableBuilder(column: $table.photoUrl, builder: (column) => column);

  GeneratedColumn<String> get photoAuthor => $composableBuilder(
    column: $table.photoAuthor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get photoLicense => $composableBuilder(
    column: $table.photoLicense,
    builder: (column) => column,
  );

  GeneratedColumn<String> get photoLicenseUrl => $composableBuilder(
    column: $table.photoLicenseUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get photoPageUrl => $composableBuilder(
    column: $table.photoPageUrl,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<TowerSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<bool> get userModified => $composableBuilder(
    column: $table.userModified,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get osmMissing => $composableBuilder(
    column: $table.osmMissing,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);
}

class $$TowersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TowersTable,
          Tower,
          $$TowersTableFilterComposer,
          $$TowersTableOrderingComposer,
          $$TowersTableAnnotationComposer,
          $$TowersTableCreateCompanionBuilder,
          $$TowersTableUpdateCompanionBuilder,
          (Tower, BaseReferences<_$AppDatabase, $TowersTable, Tower>),
          Tower,
          PrefetchHooks Function()
        > {
  $$TowersTableTableManager(_$AppDatabase db, $TowersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TowersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TowersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TowersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String?> osmType = const Value.absent(),
                Value<int?> osmId = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lon = const Value.absent(),
                Value<double?> height = const Value.absent(),
                Value<double?> ele = const Value.absent(),
                Value<String?> region = const Value.absent(),
                Value<String?> website = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> openingHours = const Value.absent(),
                Value<String?> fee = const Value.absent(),
                Value<String?> access = const Value.absent(),
                Value<String?> wikidataId = const Value.absent(),
                Value<String?> wikipediaTitle = const Value.absent(),
                Value<String?> wikipediaUrl = const Value.absent(),
                Value<String?> wikipediaExtract = const Value.absent(),
                Value<String?> photoUrl = const Value.absent(),
                Value<String?> photoAuthor = const Value.absent(),
                Value<String?> photoLicense = const Value.absent(),
                Value<String?> photoLicenseUrl = const Value.absent(),
                Value<String?> photoPageUrl = const Value.absent(),
                Value<TowerSource> source = const Value.absent(),
                Value<bool> userModified = const Value.absent(),
                Value<bool> osmMissing = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
              }) => TowersCompanion(
                id: id,
                uuid: uuid,
                osmType: osmType,
                osmId: osmId,
                name: name,
                lat: lat,
                lon: lon,
                height: height,
                ele: ele,
                region: region,
                website: website,
                note: note,
                openingHours: openingHours,
                fee: fee,
                access: access,
                wikidataId: wikidataId,
                wikipediaTitle: wikipediaTitle,
                wikipediaUrl: wikipediaUrl,
                wikipediaExtract: wikipediaExtract,
                photoUrl: photoUrl,
                photoAuthor: photoAuthor,
                photoLicense: photoLicense,
                photoLicenseUrl: photoLicenseUrl,
                photoPageUrl: photoPageUrl,
                source: source,
                userModified: userModified,
                osmMissing: osmMissing,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deleted: deleted,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                Value<String?> osmType = const Value.absent(),
                Value<int?> osmId = const Value.absent(),
                Value<String?> name = const Value.absent(),
                required double lat,
                required double lon,
                Value<double?> height = const Value.absent(),
                Value<double?> ele = const Value.absent(),
                Value<String?> region = const Value.absent(),
                Value<String?> website = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> openingHours = const Value.absent(),
                Value<String?> fee = const Value.absent(),
                Value<String?> access = const Value.absent(),
                Value<String?> wikidataId = const Value.absent(),
                Value<String?> wikipediaTitle = const Value.absent(),
                Value<String?> wikipediaUrl = const Value.absent(),
                Value<String?> wikipediaExtract = const Value.absent(),
                Value<String?> photoUrl = const Value.absent(),
                Value<String?> photoAuthor = const Value.absent(),
                Value<String?> photoLicense = const Value.absent(),
                Value<String?> photoLicenseUrl = const Value.absent(),
                Value<String?> photoPageUrl = const Value.absent(),
                required TowerSource source,
                Value<bool> userModified = const Value.absent(),
                Value<bool> osmMissing = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<bool> deleted = const Value.absent(),
              }) => TowersCompanion.insert(
                id: id,
                uuid: uuid,
                osmType: osmType,
                osmId: osmId,
                name: name,
                lat: lat,
                lon: lon,
                height: height,
                ele: ele,
                region: region,
                website: website,
                note: note,
                openingHours: openingHours,
                fee: fee,
                access: access,
                wikidataId: wikidataId,
                wikipediaTitle: wikipediaTitle,
                wikipediaUrl: wikipediaUrl,
                wikipediaExtract: wikipediaExtract,
                photoUrl: photoUrl,
                photoAuthor: photoAuthor,
                photoLicense: photoLicense,
                photoLicenseUrl: photoLicenseUrl,
                photoPageUrl: photoPageUrl,
                source: source,
                userModified: userModified,
                osmMissing: osmMissing,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deleted: deleted,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TowersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TowersTable,
      Tower,
      $$TowersTableFilterComposer,
      $$TowersTableOrderingComposer,
      $$TowersTableAnnotationComposer,
      $$TowersTableCreateCompanionBuilder,
      $$TowersTableUpdateCompanionBuilder,
      (Tower, BaseReferences<_$AppDatabase, $TowersTable, Tower>),
      Tower,
      PrefetchHooks Function()
    >;
typedef $$VisitsTableCreateCompanionBuilder = VisitsCompanion Function({
  Value<int> id,
  required String uuid,
  required String towerUuid,
  required DateTime visitedOn,
  Value<int?> rating,
  Value<String?> note,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<bool> deleted,
});
typedef $$VisitsTableUpdateCompanionBuilder = VisitsCompanion Function({
  Value<int> id,
  Value<String> uuid,
  Value<String> towerUuid,
  Value<DateTime> visitedOn,
  Value<int?> rating,
  Value<String?> note,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> deleted,
});

class $$VisitsTableFilterComposer
    extends Composer<_$AppDatabase, $VisitsTable> {
  $$VisitsTableFilterComposer({
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

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get towerUuid => $composableBuilder(
    column: $table.towerUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get visitedOn => $composableBuilder(
    column: $table.visitedOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
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

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VisitsTableOrderingComposer
    extends Composer<_$AppDatabase, $VisitsTable> {
  $$VisitsTableOrderingComposer({
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

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get towerUuid => $composableBuilder(
    column: $table.towerUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get visitedOn => $composableBuilder(
    column: $table.visitedOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
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

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VisitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VisitsTable> {
  $$VisitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get towerUuid =>
      $composableBuilder(column: $table.towerUuid, builder: (column) => column);

  GeneratedColumn<DateTime> get visitedOn =>
      $composableBuilder(column: $table.visitedOn, builder: (column) => column);

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);
}

class $$VisitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VisitsTable,
          Visit,
          $$VisitsTableFilterComposer,
          $$VisitsTableOrderingComposer,
          $$VisitsTableAnnotationComposer,
          $$VisitsTableCreateCompanionBuilder,
          $$VisitsTableUpdateCompanionBuilder,
          (Visit, BaseReferences<_$AppDatabase, $VisitsTable, Visit>),
          Visit,
          PrefetchHooks Function()
        > {
  $$VisitsTableTableManager(_$AppDatabase db, $VisitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VisitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VisitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VisitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> towerUuid = const Value.absent(),
                Value<DateTime> visitedOn = const Value.absent(),
                Value<int?> rating = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
              }) => VisitsCompanion(
                id: id,
                uuid: uuid,
                towerUuid: towerUuid,
                visitedOn: visitedOn,
                rating: rating,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deleted: deleted,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required String towerUuid,
                required DateTime visitedOn,
                Value<int?> rating = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<bool> deleted = const Value.absent(),
              }) => VisitsCompanion.insert(
                id: id,
                uuid: uuid,
                towerUuid: towerUuid,
                visitedOn: visitedOn,
                rating: rating,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deleted: deleted,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VisitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VisitsTable,
      Visit,
      $$VisitsTableFilterComposer,
      $$VisitsTableOrderingComposer,
      $$VisitsTableAnnotationComposer,
      $$VisitsTableCreateCompanionBuilder,
      $$VisitsTableUpdateCompanionBuilder,
      (Visit, BaseReferences<_$AppDatabase, $VisitsTable, Visit>),
      Visit,
      PrefetchHooks Function()
    >;
typedef $$PhotosTableCreateCompanionBuilder = PhotosCompanion Function({
  Value<int> id,
  required String uuid,
  required String visitUuid,
  required String fileName,
  required DateTime createdAt,
  Value<bool> deleted,
});
typedef $$PhotosTableUpdateCompanionBuilder = PhotosCompanion Function({
  Value<int> id,
  Value<String> uuid,
  Value<String> visitUuid,
  Value<String> fileName,
  Value<DateTime> createdAt,
  Value<bool> deleted,
});

class $$PhotosTableFilterComposer
    extends Composer<_$AppDatabase, $PhotosTable> {
  $$PhotosTableFilterComposer({
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

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visitUuid => $composableBuilder(
    column: $table.visitUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PhotosTableOrderingComposer
    extends Composer<_$AppDatabase, $PhotosTable> {
  $$PhotosTableOrderingComposer({
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

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visitUuid => $composableBuilder(
    column: $table.visitUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PhotosTableAnnotationComposer
    extends Composer<_$AppDatabase, $PhotosTable> {
  $$PhotosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get visitUuid =>
      $composableBuilder(column: $table.visitUuid, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);
}

class $$PhotosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PhotosTable,
          Photo,
          $$PhotosTableFilterComposer,
          $$PhotosTableOrderingComposer,
          $$PhotosTableAnnotationComposer,
          $$PhotosTableCreateCompanionBuilder,
          $$PhotosTableUpdateCompanionBuilder,
          (Photo, BaseReferences<_$AppDatabase, $PhotosTable, Photo>),
          Photo,
          PrefetchHooks Function()
        > {
  $$PhotosTableTableManager(_$AppDatabase db, $PhotosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PhotosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PhotosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PhotosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> visitUuid = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
              }) => PhotosCompanion(
                id: id,
                uuid: uuid,
                visitUuid: visitUuid,
                fileName: fileName,
                createdAt: createdAt,
                deleted: deleted,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required String visitUuid,
                required String fileName,
                required DateTime createdAt,
                Value<bool> deleted = const Value.absent(),
              }) => PhotosCompanion.insert(
                id: id,
                uuid: uuid,
                visitUuid: visitUuid,
                fileName: fileName,
                createdAt: createdAt,
                deleted: deleted,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PhotosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PhotosTable,
      Photo,
      $$PhotosTableFilterComposer,
      $$PhotosTableOrderingComposer,
      $$PhotosTableAnnotationComposer,
      $$PhotosTableCreateCompanionBuilder,
      $$PhotosTableUpdateCompanionBuilder,
      (Photo, BaseReferences<_$AppDatabase, $PhotosTable, Photo>),
      Photo,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TowersTableTableManager get towers =>
      $$TowersTableTableManager(_db, _db.towers);
  $$VisitsTableTableManager get visits =>
      $$VisitsTableTableManager(_db, _db.visits);
  $$PhotosTableTableManager get photos =>
      $$PhotosTableTableManager(_db, _db.photos);
}
