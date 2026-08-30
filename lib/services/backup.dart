import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';

import '../data/database.dart';
import 'photos.dart';

/// Formát zálohy. Zvýší se, až se schéma změní tak, že by starší import
/// nešel načíst — pak podle něj půjde rozhodnout, co s tím.
const backupFormatVersion = 1;

const _dataFileName = 'data.json';
const _photosDir = 'photos/';

/// Obsah zálohy před zápisem do databáze.
class BackupPayload {
  const BackupPayload({
    required this.towers,
    required this.visits,
    required this.photos,
  });

  final List<Tower> towers;
  final List<Visit> visits;
  final List<Photo> photos;
}

/// Co import udělal. Slouží k tomu, aby uživatel viděl, že se něco stalo,
/// a hlavně aby si všiml podezřelých dvojic.
class MergeReport {
  MergeReport();

  int towersAdded = 0;
  int towersUpdated = 0;
  int visitsAdded = 0;
  int visitsUpdated = 0;
  int photosAdded = 0;

  /// Skupiny návštěv téže rozhledny ve stejný den — kandidáti na duplicitu.
  List<List<Visit>> suspectedDuplicates = const [];

  bool get changedAnything =>
      towersAdded + towersUpdated + visitsAdded + visitsUpdated + photosAdded >
          0;

  String get summary {
    if (!changedAnything) return 'Nic nového — všechno už jste měli.';
    final parts = <String>[
      if (towersAdded > 0) '$towersAdded nových rozhleden',
      if (towersUpdated > 0) '$towersUpdated upravených rozhleden',
      if (visitsAdded > 0) '$visitsAdded nových návštěv',
      if (visitsUpdated > 0) '$visitsUpdated aktualizovaných návštěv',
      if (photosAdded > 0) '$photosAdded fotek',
    ];
    return 'Přidáno: ${parts.join(', ')}.';
  }
}

// ------------------------------------------------------------ serializace

Map<String, dynamic> encodeBackup(BackupPayload p) => {
      'formatVersion': backupFormatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'towers': [for (final t in p.towers) t.toJson()],
      'visits': [for (final v in p.visits) v.toJson()],
      'photos': [for (final ph in p.photos) ph.toJson()],
    };

BackupPayload decodeBackup(Map<String, dynamic> json) {
  final version = json['formatVersion'] as int?;
  if (version == null || version > backupFormatVersion) {
    throw const FormatException(
        'Záloha je z novější verze aplikace, aktualizujte ji.');
  }
  return BackupPayload(
    towers: [
      for (final t in (json['towers'] as List? ?? const []))
        Tower.fromJson(t as Map<String, dynamic>),
    ],
    visits: [
      for (final v in (json['visits'] as List? ?? const []))
        Visit.fromJson(v as Map<String, dynamic>),
    ],
    photos: [
      for (final p in (json['photos'] as List? ?? const []))
        Photo.fromJson(p as Map<String, dynamic>),
    ],
  );
}

// ---------------------------------------------------------------- merge

/// Sloučí zálohu do databáze. **Nikdy nepřepisuje naslepo.**
///
/// Párování je podle `uuid`; při kolizi vyhrává novější `updatedAt`. Díky
/// deterministickým UUID rozhleden z OSM se návštěvy z druhého telefonu
/// navěsí na správný bod, i když ho ten telefon neposílal.
Future<MergeReport> mergeBackup(AppDatabase db, BackupPayload payload) async {
  final report = MergeReport();

  await db.transaction(() async {
    for (final t in payload.towers) {
      final existing = await db.towerByUuid(t.uuid);
      if (existing == null) {
        await db.upsertTower(_withLocalId(t.toCompanion(false), null));
        report.towersAdded++;
      } else if (t.updatedAt.isAfter(existing.updatedAt)) {
        await db.upsertTower(_withLocalId(t.toCompanion(false), existing.id));
        report.towersUpdated++;
      }
    }

    for (final v in payload.visits) {
      final existing = await db.visitByUuid(v.uuid);
      if (existing == null) {
        await db.upsertVisit(_withLocalId(v.toCompanion(false), null));
        report.visitsAdded++;
      } else if (v.updatedAt.isAfter(existing.updatedAt)) {
        await db.upsertVisit(_withLocalId(v.toCompanion(false), existing.id));
        report.visitsUpdated++;
      }
    }

    for (final p in payload.photos) {
      // Fotky se needitují, takže stačí "znám ji už?" — bez toho by opakovaný
      // import tutéž fotku přidal znovu pod novým id.
      if (await db.photoByUuid(p.uuid) == null) {
        await db.insertPhoto(_withLocalId(p.toCompanion(false), null));
        report.photosAdded++;
      }
    }
  });

  report.suspectedDuplicates = await db.duplicateVisitGroups();
  return report;
}

/// Nahradí `id` ze zálohy tím lokálním, nebo ho zahodí u nového záznamu.
///
/// Bez tohohle import maže data: `toCompanion` nese autoincrement `id` z cizí
/// databáze, kde má stejné číslo úplně jiný záznam. `insertOnConflictUpdate`
/// pak narazí na primární klíč a **přepíše místní řádek** — dvě nezávisle
/// zapsané návštěvy s `id = 1` se sloučí v jednu a jedna nenávratně zmizí.
T _withLocalId<T extends UpdateCompanion<dynamic>>(T companion, int? localId) {
  final value = localId == null ? const Value<int>.absent() : Value(localId);
  return switch (companion) {
    TowersCompanion c => c.copyWith(id: value) as T,
    VisitsCompanion c => c.copyWith(id: value) as T,
    PhotosCompanion c => c.copyWith(id: value) as T,
    _ => companion,
  };
}

// ------------------------------------------------------------- ZIP / soubor

/// Sestaví ZIP s `data.json` a složkou `photos/`.
///
/// ZIP proto, že fotky se nedají rozumně nacpat do JSONu — base64 by soubor
/// nafoukl o třetinu a poslat pár set fotek mailem by přestalo jít.
Future<List<int>> buildBackupArchive({
  required BackupPayload payload,
  required PhotoStorage storage,
}) async {
  final archive = Archive();

  final json = utf8.encode(const JsonEncoder.withIndent('  ')
      .convert(encodeBackup(payload)));
  archive.addFile(ArchiveFile(_dataFileName, json.length, json));

  for (final photo in payload.photos) {
    final file = storage.file(photo.fileName);
    if (!file.existsSync()) continue; // fotka smazaná mimo aplikaci
    final bytes = await file.readAsBytes();
    archive.addFile(
        ArchiveFile('$_photosDir${photo.fileName}', bytes.length, bytes));
  }

  return ZipEncoder().encode(archive);
}

/// Rozbalí zálohu, uloží fotky a sloučí data.
Future<MergeReport> restoreBackupArchive({
  required List<int> zipBytes,
  required AppDatabase db,
  required PhotoStorage storage,
}) async {
  final archive = ZipDecoder().decodeBytes(zipBytes);

  final dataFile = archive.files.where((f) => f.name == _dataFileName).firstOrNull;
  if (dataFile == null) {
    throw const FormatException('V souboru chybí data.json — není to záloha '
        'z téhle aplikace?');
  }

  final payload = decodeBackup(
      jsonDecode(utf8.decode(dataFile.content as List<int>))
          as Map<String, dynamic>);

  // Fotky nejdřív na disk, teprve pak do databáze — kdyby zápis spadl,
  // ať radši zůstane soubor bez záznamu než záznam bez souboru.
  for (final entry in archive.files) {
    if (!entry.isFile || !entry.name.startsWith(_photosDir)) continue;
    final name = entry.name.substring(_photosDir.length);
    if (name.isEmpty || name.contains('/') || name.contains('\\')) continue;
    if (storage.file(name).existsSync()) continue;
    await storage.saveBytes(name, entry.content as List<int>);
  }

  return mergeBackup(db, payload);
}

Future<File> writeBackupToFile(List<int> bytes, Directory dir) async {
  final stamp = DateTime.now()
      .toIso8601String()
      .substring(0, 16)
      .replaceAll(':', '-');
  final file = File('${dir.path}/rozhledny-$stamp.zip');
  await file.writeAsBytes(bytes);
  return file;
}
