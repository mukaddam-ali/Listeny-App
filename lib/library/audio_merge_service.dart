import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class MergeFailedException implements Exception {
  const MergeFailedException();

  @override
  String toString() => 'Could not merge these files.';
}

/// Joins several local audio files, one after another, into a single MP3.
/// Inputs can differ in format, sample rate and channel count, so each is
/// normalised (44.1 kHz stereo) before being concatenated and re-encoded.
class AudioMergeService {
  final _uuid = const Uuid();

  /// Writes the joined audio to a new temp file and returns its path.
  Future<String> merge({
    required List<String> inputPaths,
    required String title,
  }) async {
    if (inputPaths.length < 2) throw const MergeFailedException();
    final tmp = await getTemporaryDirectory();
    final output = p.join(tmp.path, '${_uuid.v4()}.mp3');
    final n = inputPaths.length;
    final filter = StringBuffer();
    for (var i = 0; i < n; i++) {
      filter.write(
        '[$i:a:0]aresample=44100,aformat=sample_fmts=fltp:channel_layouts=stereo[a$i];',
      );
    }
    for (var i = 0; i < n; i++) {
      filter.write('[a$i]');
    }
    filter.write('concat=n=$n:v=0:a=1[out]');

    final session = await FFmpegKit.executeWithArguments([
      '-y',
      for (final path in inputPaths) ...['-i', path],
      '-filter_complex', filter.toString(),
      '-map', '[out]',
      '-c:a', 'libmp3lame', '-q:a', '2',
      '-metadata', 'title=${title.replaceAll('\n', ' ')}',
      '-id3v2_version', '3',
      output,
    ]);
    final ok = ReturnCode.isSuccess(await session.getReturnCode());
    final file = File(output);
    if (!ok || !await file.exists() || await file.length() == 0) {
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {}
      throw const MergeFailedException();
    }
    return output;
  }
}
