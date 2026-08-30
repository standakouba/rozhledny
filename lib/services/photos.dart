import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/ids.dart';

/// Fotky návštěv leží v adresáři aplikace, v databázi je jen jméno souboru.
///
/// Důvod je export: ZIP se skládá z `data.json` a složky `photos/`, takže
/// jména musí být stabilní a nezávislá na absolutní cestě, která se mezi
/// telefony liší.
class PhotoStorage {
  PhotoStorage(this.dir);

  final Directory dir;

  File file(String fileName) => File(p.join(dir.path, fileName));

  /// Zkopíruje vyfocený nebo vybraný snímek k sobě a vrátí jméno souboru.
  Future<String> save(XFile picked) async {
    final ext = p.extension(picked.path).toLowerCase();
    final fileName = '${newUuid()}${ext.isEmpty ? '.jpg' : ext}';
    await File(picked.path).copy(p.join(dir.path, fileName));
    return fileName;
  }

  /// Kopii z importu ukládáme pod jménem, které přišlo — jinak by se při
  /// opakovaném importu tatáž fotka přidala znovu pod novým jménem.
  Future<void> saveBytes(String fileName, List<int> bytes) =>
      file(fileName).writeAsBytes(bytes);

  Future<void> delete(String fileName) async {
    final f = file(fileName);
    if (f.existsSync()) await f.delete();
  }
}

final photoStorageProvider = FutureProvider<PhotoStorage>((ref) async {
  final base = await getApplicationDocumentsDirectory();
  final dir = Directory(p.join(base.path, 'photos'));
  if (!dir.existsSync()) await dir.create(recursive: true);
  return PhotoStorage(dir);
});

final imagePickerProvider = Provider<ImagePicker>((ref) => ImagePicker());
