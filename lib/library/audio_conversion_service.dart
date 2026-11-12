import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'file_name_sanitizer.dart';

class ConversionCancelledException implements Exception {
  const ConversionCancelledException();
}

class ConversionFailedException implements Exception {
  final String message;
  const ConversionFailedException(this.message);

  @override
  String toString() => message;
}

/// Text tags a resolver knows about. Only used to fill tags the media file
/// itself lacks — callers pass just the missing ones, so stronger embedded
/// tags are never overwritten.
class TrackMetadataFallback {
  final String? title;
  final String? artist;
  final String? album;
  const TrackMetadataFallback({this.title, this.artist, this.album});

  bool get isEmpty => title == null && artist == null && album == null;
}

/// An attached-picture stream (cover art) in a source file.
class SourcePicture {
  final int streamIndex;
  final String codec;
  const SourcePicture(this.streamIndex, this.codec);
}

/// What FFprobe conclusively reports about a source file: the codec of its
/// first audio stream, its container(s), its text tags and cover streams.
/// Codec/container come from the demuxers themselves, not from bytes,
/// extensions or MIME types.
class SourceProbe {
  /// `codec_name` of the first audio stream; null if there is none.
  final String? audioCodec;

  /// FFprobe `format_name` split on commas (e.g. {mp3}, {matroska, webm}).
  final Set<String> formatNames;

  /// Lower-cased, non-blank container + first-audio-stream tags.
  final Map<String, String> tags;
  final List<SourcePicture> pictures;
  const SourceProbe({
    required this.audioCodec,
    required this.formatNames,
    required this.tags,
    required this.pictures,
  });

  /// Actual MP3 audio in an actual MP3 file (not MP3 inside MP4, and not
  /// AAC behind an ID3 tag).
  bool get isMp3File => audioCodec == 'mp3' && formatNames.contains('mp3');

  /// The first audio stream is MP3, so it can be stream-copied.
  bool get hasMp3Audio => audioCodec == 'mp3';

  /// Parses FFprobe's JSON (`-show_format -show_streams`); null if unusable.
  static SourceProbe? fromJson(Map<dynamic, dynamic>? json) {
    if (json == null) return null;
    final streams = json['streams'];
    final format = json['format'];
    if (streams is! List || format is! Map) return null;

    Map<String, String> lowered(Object? tags) {
      if (tags is! Map) return const {};
      return {
        for (final e in tags.entries)
          if ('${e.value}'.trim().isNotEmpty)
            '${e.key}'.toLowerCase(): '${e.value}',
      };
    }

    Map<dynamic, dynamic>? firstAudio;
    final pictures = <SourcePicture>[];
    for (final s in streams) {
      if (s is! Map) continue;
      final type = s['codec_type'];
      if (type == 'audio' && firstAudio == null) firstAudio = s;
      final disposition = s['disposition'];
      final attached =
          disposition is Map &&
          (disposition['attached_pic'] == 1 ||
              disposition['attached_pic'] == true);
      if (type == 'video' && attached && s['index'] is int) {
        pictures.add(SourcePicture(s['index'] as int, '${s['codec_name']}'));
      }
    }
    return SourceProbe(
      audioCodec: firstAudio == null ? null : '${firstAudio['codec_name']}',
      formatNames: '${format['format_name'] ?? ''}'
          .split(',')
          .where((n) => n.isNotEmpty)
          .toSet(),
      tags: {...lowered(format['tags']), ...lowered(firstAudio?['tags'])},
      pictures: pictures,
    );
  }
}

/// Embedded cover art found in (and extracted from) a source file.
/// [unknown] means the source may carry art that could not be determined or
/// extracted, so a remote thumbnail must not be assumed to be the fallback.
class EmbeddedArtwork {
  final String? path;
  final bool unknown;
  const EmbeddedArtwork.found(String this.path) : unknown = false;
  const EmbeddedArtwork.absent() : path = null, unknown = false;
  const EmbeddedArtwork.unknown() : path = null, unknown = true;
}

/// Turns a downloaded file into the one thing URL imports produce: a
/// validated MP3. A file that is already a decodable MP3 passes through
/// untouched (unless missing tags must be filled, which is a lossless
/// stream-copy remux, never a re-encode); anything else is transcoded with
/// libmp3lame. Input and output must both prove to hold a real decodable
/// audio stream — extensions, MIME types, magic bytes and tags alone never
/// count.
const _maxArtworkBytes = 10 * 1024 * 1024;

class AudioConversionService {
  final _uuid = const Uuid();
  int? _activeSessionId;
  bool _cancelRequested = false;

  /// Returns the path of a validated MP3 ready for [ImportService] — either
  /// [inputPath] itself or a new file written into [outputDir].
  /// Throws [ConversionFailedException] for input without decodable audio or
  /// output that fails validation, [ConversionCancelledException] on cancel.
  Future<String> process({
    required String inputPath,
    required String outputDir,
    TrackMetadataFallback? fallbackMetadata,
  }) async {
    _cancelRequested = false;
    // Codec/container come from FFprobe, never from the extension, MIME
    // type, tags or leading bytes.
    final probe = await probeSource(inputPath);
    _throwIfCancelled();
    await validateDecodableAudio(inputPath);
    _throwIfCancelled();

    // Resolver tags only fill fields the probe PROVED absent; if the source
    // could not be probed, its tags are unknown and are left alone.
    final fill = _metadataArgs(_missingOnly(probe, fallbackMetadata));
    if (probe != null && probe.isMp3File && fill.isEmpty) return inputPath;

    final output = p.join(outputDir, '${_uuid.v4()}.mp3');
    // Audio only (never a video stream), tags carried over, ID3v2.3 so
    // Unicode tags read back everywhere. Only genuine MP3 audio is
    // stream-copied (no re-encode); every other codec is transcoded.
    final codec = (probe?.hasMp3Audio ?? false)
        ? '-c:a copy'
        : '-c:a libmp3lame -q:a 2';
    await _runFfmpeg(
      inputPath: inputPath,
      outputPath: output,
      args: '-map 0:a:0 -vn $codec -map_metadata 0 -id3v2_version 3 $fill',
    );
    try {
      await _validateMp3Output(output);
      return output;
    } catch (_) {
      await _deleteQuietly(output);
      rethrow;
    }
  }

  /// Cancels the FFmpeg session currently running, if any. Safe to call
  /// even when nothing is running.
  Future<void> cancel() async {
    _cancelRequested = true;
    final id = _activeSessionId;
    if (id != null) await FFmpegKit.cancel(id);
  }

  /// FFmpeg arguments that decode [inputPath]'s first audio stream to
  /// nowhere: fails if there is no audio stream or the data can't be
  /// decoded. Exposed so tests can run the exact same check with a real
  /// FFmpeg binary.
  static List<String> decodeValidationArgs(String inputPath) => [
    '-nostdin',
    '-v',
    'error',
    '-xerror',
    '-i',
    inputPath,
    '-map',
    '0:a:0',
    '-f',
    'null',
    '-',
  ];

  /// Proves [inputPath] holds a real, decodable audio stream.
  /// Throws [ConversionFailedException] when there is none and
  /// [ConversionCancelledException] when cancelled.
  Future<void> validateDecodableAudio(String inputPath) async {
    final command = decodeValidationArgs(inputPath)
        .map((a) => a.contains(' ') ? '"$a"' : a)
        .join(' ');
    final returnCode = await _execute(command);
    if (ReturnCode.isCancel(returnCode) || _cancelRequested) {
      throw const ConversionCancelledException();
    }
    if (!ReturnCode.isSuccess(returnCode)) {
      throw const ConversionFailedException(
        "This link didn't contain playable audio.",
      );
    }
  }

  Future<void> _validateMp3Output(String path) async {
    const failure = ConversionFailedException(
      'Could not create a valid MP3 from this file.',
    );
    final file = File(path);
    if (!await file.exists() || await file.length() == 0) throw failure;
    final probe = await probeSource(path);
    if (probe == null || !probe.isMp3File) throw failure;
    try {
      await validateDecodableAudio(path);
    } on ConversionFailedException {
      throw failure;
    }
  }

  /// Probes [path] with FFprobe (through FFmpegKit). Null when the file
  /// could not be probed at all — callers must treat that as "unknown".
  Future<SourceProbe?> probeSource(String path) async {
    try {
      final session = await FFprobeKit.getMediaInformation(path);
      return SourceProbe.fromJson(
        session.getMediaInformation()?.getAllProperties(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Extracts the source's embedded cover, if any, to [outputDir] (bounded
  /// to one frame and 10 MB). Uses FFmpeg so it works for containers the
  /// Dart tag reader cannot inspect; never touches the network.
  Future<EmbeddedArtwork> extractEmbeddedArtwork(
    String inputPath,
    String outputDir,
  ) async {
    // First conversion step of a run: start with a clean cancel flag.
    _cancelRequested = false;
    final probe = await probeSource(inputPath);
    // Cancel may have landed while probing: never start FFmpeg after it.
    if (_cancelRequested) throw const ConversionCancelledException();
    if (probe == null) return const EmbeddedArtwork.unknown();
    if (probe.pictures.isEmpty) return const EmbeddedArtwork.absent();
    final pic = probe.pictures.first;
    final isPng = pic.codec == 'png';
    final output = p.join(
      outputDir,
      '${_uuid.v4()}_cover.${isPng ? 'png' : 'jpg'}',
    );
    final copy = (pic.codec == 'mjpeg' || isPng) ? '-c:v copy' : '';
    // `-fs` stops FFmpeg's muxer past the cap; the size watcher below cancels
    // the session as soon as the growing file crosses it (a single huge
    // picture packet is written in one go, which `-fs` alone can't split).
    final run = await _executeBounded(
      '-y -i "$inputPath" -map 0:${pic.streamIndex} -frames:v 1 $copy '
      '-fs ${_maxArtworkBytes + 1} "$output"',
      output,
      _maxArtworkBytes,
    );
    if (_cancelRequested) {
      await _deleteQuietly(output);
      throw const ConversionCancelledException();
    }
    if (run.oversized) {
      // Our own limit stopped it: the source has art we won't take.
      await _deleteQuietly(output);
      return const EmbeddedArtwork.unknown();
    }
    if (ReturnCode.isCancel(run.code)) {
      await _deleteQuietly(output);
      throw const ConversionCancelledException();
    }
    final ok =
        ReturnCode.isSuccess(run.code) &&
        await _isWithinLimitAndImage(File(output));
    if (!ok) {
      // The source has art we could not extract: not "absent".
      await _deleteQuietly(output);
      return const EmbeddedArtwork.unknown();
    }
    return EmbeddedArtwork.found(output);
  }

  /// Runs [command] like [_execute], but watches [outputPath] while it is
  /// written and cancels the session the moment it grows past [maxBytes].
  Future<({ReturnCode? code, bool oversized})> _executeBounded(
    String command,
    String outputPath,
    int maxBytes,
  ) async {
    final completer = Completer<ReturnCode?>();
    final session = await FFmpegKit.executeAsync(command, (
      completedSession,
    ) async {
      if (!completer.isCompleted) {
        completer.complete(await completedSession.getReturnCode());
      }
    });
    final id = session.getSessionId();
    _activeSessionId = id;
    if (_cancelRequested && id != null) await FFmpegKit.cancel(id);
    var oversized = false;
    final watcher = Timer.periodic(const Duration(milliseconds: 10), (_) {
      if (oversized) return;
      try {
        final f = File(outputPath);
        if (f.existsSync() && f.lengthSync() > maxBytes) {
          oversized = true;
          if (id != null) unawaited(FFmpegKit.cancel(id));
        }
      } catch (_) {
        // Best effort; the post-run check still applies.
      }
    });
    final code = await completer.future;
    watcher.cancel();
    _activeSessionId = null;
    return (code: code, oversized: oversized);
  }

  /// Within the size cap and a COMPLETE, decodable JPEG or PNG: cheap
  /// structural checks first (signature, sane dimensions, end marker), then
  /// a real decode by the platform image codec at a tiny target size (so a
  /// huge-dimension image can't blow up memory). A signed-but-truncated or
  /// corrupt image fails here.
  Future<bool> _isWithinLimitAndImage(File file) async {
    try {
      if (!await file.exists()) return false;
      final length = await file.length();
      if (length == 0 || length > _maxArtworkBytes) return false;
      final bytes = await file.readAsBytes();
      final size = _structurallyCompleteImageSize(bytes);
      if (size == null) return false;
      final (w, h) = size;
      if (w <= 0 || h <= 0 || w > 16384 || h > 16384 || w * h > 40000000) {
        return false;
      }
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: w > 64 ? 64 : null,
      );
      try {
        final frame = await codec.getNextFrame();
        frame.image.dispose();
      } finally {
        codec.dispose();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// (width, height) of a JPEG/PNG whose signature, header and end marker
  /// are intact, else null.
  (int, int)? _structurallyCompleteImageSize(Uint8List b) {
    const pngSignature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
    const pngEnd = [0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82];
    bool startsWith(List<int> sig) =>
        b.length >= sig.length &&
        [for (var i = 0; i < sig.length; i++) b[i] == sig[i]].every((x) => x);

    if (startsWith(pngSignature)) {
      // IHDR must come first; IEND (with its CRC) must close the file.
      if (b.length < 33 || String.fromCharCodes(b.sublist(12, 16)) != 'IHDR') {
        return null;
      }
      final tail = b.sublist(b.length - 8);
      for (var i = 0; i < 8; i++) {
        if (tail[i] != pngEnd[i]) return null;
      }
      int be32(int o) =>
          (b[o] << 24) | (b[o + 1] << 16) | (b[o + 2] << 8) | b[o + 3];
      return (be32(16), be32(20));
    }

    if (b.length > 4 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) {
      // Must end with EOI (allowing trailing zero padding).
      var end = b.length;
      while (end > 2 && b[end - 1] == 0) {
        end--;
      }
      if (end < 4 || b[end - 2] != 0xFF || b[end - 1] != 0xD9) return null;
      // Walk segments to the frame header for the dimensions.
      var i = 2;
      while (i + 4 <= b.length) {
        if (b[i] != 0xFF) return null;
        while (i < b.length && b[i] == 0xFF) {
          i++;
        }
        if (i >= b.length) return null;
        final marker = b[i++];
        if (marker == 0x01 || (marker >= 0xD0 && marker <= 0xD7)) continue;
        if (marker == 0xD9 || marker == 0xDA) return null; // no frame header
        if (i + 2 > b.length) return null;
        final len = (b[i] << 8) | b[i + 1];
        final isFrame =
            marker >= 0xC0 &&
            marker <= 0xCF &&
            marker != 0xC4 &&
            marker != 0xC8 &&
            marker != 0xCC;
        if (isFrame) {
          if (i + 7 > b.length) return null;
          return ((b[i + 5] << 8) | b[i + 6], (b[i + 3] << 8) | b[i + 4]);
        }
        i += len;
      }
    }
    return null;
  }

  TrackMetadataFallback? _missingOnly(
    SourceProbe? probe,
    TrackMetadataFallback? fallback,
  ) {
    if (probe == null || fallback == null) return null;
    return TrackMetadataFallback(
      title: probe.tags.containsKey('title') ? null : fallback.title,
      artist: probe.tags.containsKey('artist') ? null : fallback.artist,
      album: probe.tags.containsKey('album') ? null : fallback.album,
    );
  }

  /// `-metadata key="value"` arguments for the given fallback tags. FFmpegKit
  /// has no escape for a double quote inside a quoted argument and keeps
  /// backslashes literally, so those two characters are neutralized;
  /// everything else (including all Unicode) passes through.
  String _metadataArgs(TrackMetadataFallback? fallback) {
    if (fallback == null) return '';
    String? clean(String? v) =>
        sanitizeMetadataText(v)?.replaceAll('"', "'").replaceAll(r'\', '/');
    final pairs = <String, String?>{
      'title': clean(fallback.title),
      'artist': clean(fallback.artist),
      'album': clean(fallback.album),
    };
    return pairs.entries
        .where((e) => e.value != null)
        .map((e) => '-metadata ${e.key}="${e.value}"')
        .join(' ');
  }

  Future<ReturnCode?> _execute(String command) async {
    final completer = Completer<ReturnCode?>();
    final session = await FFmpegKit.executeAsync(command, (
      completedSession,
    ) async {
      if (!completer.isCompleted) {
        completer.complete(await completedSession.getReturnCode());
      }
    });
    final id = session.getSessionId();
    _activeSessionId = id;
    // A cancel that arrived before the session id existed had nothing to
    // act on; honor it now, on THIS session only.
    if (_cancelRequested && id != null) await FFmpegKit.cancel(id);
    final returnCode = await completer.future;
    _activeSessionId = null;
    return returnCode;
  }

  Future<void> _runFfmpeg({
    required String inputPath,
    required String outputPath,
    required String args,
  }) async {
    final returnCode = await _execute('-y -i "$inputPath" $args "$outputPath"');

    if (ReturnCode.isCancel(returnCode) || _cancelRequested) {
      await _deleteQuietly(outputPath);
      throw const ConversionCancelledException();
    }
    if (!ReturnCode.isSuccess(returnCode)) {
      await _deleteQuietly(outputPath);
      throw const ConversionFailedException('Could not convert this file.');
    }
  }

  void _throwIfCancelled() {
    if (_cancelRequested) throw const ConversionCancelledException();
  }

  Future<void> _deleteQuietly(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {
      // Best-effort cleanup only.
    }
  }
}
