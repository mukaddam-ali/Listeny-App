import 'dart:io';

import 'package:flutter/services.dart';

/// Identity of a file the app published into the public Music folder; the
/// same fields the library sync keys its source rows on.
class SavedMusicFile {
  final int id;
  final String volume;
  final String path;
  final int sizeBytes;
  final int modifiedSec;

  const SavedMusicFile({
    required this.id,
    required this.volume,
    required this.path,
    required this.sizeBytes,
    required this.modifiedSec,
  });

  String get sourceKey => 'ms:$volume:$id';
}

/// Publishes a finished download into the device's public Music/Listeny
/// folder (Android MediaStore) so it is a real local file, visible to file
/// managers and other players. The app owns the row it creates, so on
/// Android 11+ it can read, play and delete it with NO storage permission —
/// the library then references that file in place instead of keeping a
/// second copy, and the user never has to expose their other audio files.
///
/// Best-effort by contract: neither method throws. [save] returns null when
/// unsupported (iOS, Android 10 and older) or on any failure, and the caller
/// falls back to the normal app-private import.
class PublicMusicSaver {
  final MethodChannel _channel;

  PublicMusicSaver({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('listeny/media_store');

  Future<SavedMusicFile?> save({
    required String path,
    required String name,
  }) async {
    if (!Platform.isAndroid) return null;
    try {
      final r = await _channel.invokeMapMethod<String, Object?>('saveToMusic', {
        'path': path,
        'name': name,
      });
      if (r == null || r.isEmpty) return null;
      return SavedMusicFile(
        id: (r['id'] as num).toInt(),
        volume: r['volume'] as String,
        path: r['path'] as String,
        sizeBytes: (r['size'] as num).toInt(),
        modifiedSec: (r['modifiedSec'] as num).toInt(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Removes a file [save] just created (e.g. the import was a duplicate).
  Future<void> discard(SavedMusicFile file) async {
    try {
      await _channel.invokeMethod<bool>('discardSaved', {
        'volume': file.volume,
        'id': file.id,
      });
    } catch (_) {}
  }
}
