import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Copies an already-picked image file into Listeny's own artwork storage
/// (the same `<appDocs>/artwork/` directory [ImportService] uses), so the
/// app never depends on the original file staying where the user picked it
/// from. Returns the new local path. Kept separate from [pickAndSaveArtwork]
/// so it's testable without going through the platform file picker.
Future<String> copyArtworkFile(String sourcePath) async {
  final appDir = await getApplicationDocumentsDirectory();
  final artworkDir = Directory(p.join(appDir.path, 'artwork'))
    ..createSync(recursive: true);
  final ext = p.extension(sourcePath);
  final destPath = p.join(artworkDir.path, '${const Uuid().v4()}$ext');
  await File(sourcePath).copy(destPath);
  return destPath;
}

/// Lets the user pick an image from their device (via the same `file_picker`
/// dependency already used for audio import — no new package, no broad
/// storage permission) and saves a local copy into app storage. Returns null
/// if the user cancelled the picker.
Future<String?> pickAndSaveArtwork() async {
  final files = await FilePicker.pickFiles(type: FileType.image);
  if (files.isEmpty) return null;
  final pickedPath = files.first.path;
  if (pickedPath == null) return null;
  return copyArtworkFile(pickedPath);
}
