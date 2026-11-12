import 'dart:io';
import 'dart:math' as math;

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class TrimFailedException implements Exception {
  const TrimFailedException();

  @override
  String toString() => 'Could not trim this file.';
}

/// Cuts a section out of a local audio file with FFmpeg. Without a fade the
/// section is stream-copied (fast, no quality loss, tags and cover kept); a
/// fade needs the audio re-encoded, so that path writes an MP3.
class AudioTrimService {
  final _uuid = const Uuid();

  /// Peak amplitudes (0..1) of [path], [buckets] of them, for drawing a
  /// waveform. Decodes to 8 kHz mono PCM in a temp file; empty on failure.
  Future<List<double>> waveform(String path, {int buckets = 160}) async {
    final tmp = await getTemporaryDirectory();
    final pcm = p.join(tmp.path, '${_uuid.v4()}.pcm');
    try {
      final session = await FFmpegKit.executeWithArguments([
        '-y', '-i', path, '-map', '0:a:0', '-ac', '1', '-ar', '8000',
        '-f', 's16le', pcm,
      ]);
      if (!ReturnCode.isSuccess(await session.getReturnCode())) return const [];
      final file = File(pcm);
      final total = (await file.length()) ~/ 2;
      if (total == 0) return const [];
      final per = math.max(1, total ~/ buckets);
      final peaks = List<double>.filled(buckets, 0);
      var index = 0;
      int? carry;
      // Stream the PCM in chunks into fixed peak buckets: memory stays flat
      // however long the track is.
      await for (final chunk in file.openRead()) {
        var i = 0;
        if (carry != null && chunk.isNotEmpty) {
          final v = ((chunk[0] << 8) | carry).toSigned(16).abs();
          final b = math.min(buckets - 1, index ~/ per);
          if (v / 32768 > peaks[b]) peaks[b] = v / 32768;
          index++;
          carry = null;
          i = 1;
        }
        for (; i + 1 < chunk.length; i += 2) {
          final v = ((chunk[i + 1] << 8) | chunk[i]).toSigned(16).abs();
          final b = math.min(buckets - 1, index ~/ per);
          if (v / 32768 > peaks[b]) peaks[b] = v / 32768;
          index++;
        }
        if (i < chunk.length) carry = chunk[i];
      }
      final max = peaks.fold<double>(0, math.max);
      return max == 0 ? peaks : [for (final v in peaks) v / max];
    } catch (_) {
      return const [];
    } finally {
      try {
        await File(pcm).delete();
      } catch (_) {}
    }
  }

  /// Writes [start]..[end] of [inputPath] into a new file in the temp
  /// directory and returns its path. [fadeSeconds] > 0 fades in and out and
  /// forces an MP3 output. [title] replaces the title tag when given.
  Future<String> trim({
    required String inputPath,
    required Duration start,
    required Duration end,
    double fadeSeconds = 0,
    String? title,
  }) async {
    if (end <= start) throw const TrimFailedException();
    final tmp = await getTemporaryDirectory();
    final fade = fadeSeconds > 0;
    final ext = fade
        ? 'mp3'
        : p.extension(inputPath).replaceFirst('.', '').toLowerCase();
    final output = p.join(tmp.path, '${_uuid.v4()}.$ext');

    String sec(Duration d) => (d.inMilliseconds / 1000).toStringAsFixed(3);
    final length = (end - start).inMilliseconds / 1000;
    final f = math.min(fadeSeconds, length / 2);
    final codec = fade
        ? [
            '-af',
            'afade=t=in:st=0:d=$f,afade=t=out:st=${length - f}:d=$f',
            '-c:a', 'libmp3lame', '-q:a', '2', '-c:v', 'copy',
          ]
        : ['-c', 'copy'];
    final safeTitle = title?.replaceAll('\n', ' ');

    final session = await FFmpegKit.executeWithArguments([
      '-y', '-i', inputPath, '-ss', sec(start), '-to', sec(end),
      '-map', '0:a:0', '-map', '0:v?', ...codec, '-map_metadata', '0',
      if (safeTitle != null) ...['-metadata', 'title=$safeTitle'],
      if (ext == 'mp3') ...['-id3v2_version', '3'],
      output,
    ]);
    final ok = ReturnCode.isSuccess(await session.getReturnCode());
    final file = File(output);
    if (!ok || !await file.exists() || await file.length() == 0) {
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {}
      throw const TrimFailedException();
    }
    return output;
  }
}
