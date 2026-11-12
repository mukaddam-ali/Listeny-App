import 'package:flutter/services.dart';

/// One audio file already known to the device's own media index.
class DeviceAudioFile {
  final String name;
  final String path;
  final int sizeBytes;
  final Duration duration;

  /// Display-friendly containing folder, e.g. "Music" or "WhatsApp/Media/WhatsApp Audio".
  final String folder;

  const DeviceAudioFile({
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.duration,
    required this.folder,
  });
}

/// Enumerates audio files already indexed by the platform's media library
/// (Android's MediaStore, queried natively in MainActivity.kt) instead of
/// launching a system file-picker UI. This is what the in-app music browser
/// (device_music_browser_screen.dart) uses in place of the system document
/// picker, which crashes on some devices — see MainActivity.kt for the
/// full explanation of why this exists.
class MediaStoreAudioSource {
  static const _channel = MethodChannel('listeny/media_store');

  Future<List<DeviceAudioFile>> queryAudioFiles() async {
    final raw = await _channel.invokeMethod<List<Object?>>('queryAudioFiles');
    if (raw == null) return [];
    return raw
        .map((entry) => Map<Object?, Object?>.from(entry as Map))
        .where((map) => (map['path'] as String?)?.isNotEmpty ?? false)
        .map((map) {
          final path = map['path'] as String;
          return DeviceAudioFile(
            name: map['name'] as String? ?? path.split('/').last,
            path: path,
            sizeBytes: (map['sizeBytes'] as num?)?.toInt() ?? 0,
            duration: Duration(
              milliseconds: (map['durationMs'] as num?)?.toInt() ?? 0,
            ),
            folder: _folderOf(path),
          );
        })
        .toList();
  }

  String _folderOf(String path) {
    final parts = path.split('/')..removeLast();
    // Trim the common "/storage/emulated/0/" device-storage prefix so
    // folders read naturally ("Music") instead of as a full absolute path.
    // Falls back to the raw parent path on layouts that don't match it
    // (e.g. some removable-SD-card mount points).
    final idx = parts.indexOf('0');
    final relevant = idx >= 0
        ? parts.sublist(idx + 1)
        : parts.where((p) => p.isNotEmpty).toList();
    return relevant.isEmpty ? 'Storage' : relevant.join('/');
  }
}
