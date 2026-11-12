import 'dart:async';
import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listeny/library/audio_conversion_service.dart';

import 'fake_ffmpeg.dart';

/// Conversion decisions run through the real service with only the FFmpeg
/// native boundary faked (see [FakeFfmpeg]). Tests marked "real FFmpeg" then
/// execute the exact argument list the service built with a desktop `ffmpeg`
/// binary against genuine tiny fixtures (skipped when ffmpeg is absent).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final service = AudioConversionService();
  final native = FakeFfmpeg();
  late Directory scratch;
  late bool hasFfmpeg;

  setUpAll(() async {
    try {
      hasFfmpeg = (await Process.run('ffmpeg', ['-version'])).exitCode == 0;
    } catch (_) {
      hasFfmpeg = false;
    }
  });

  setUp(() {
    scratch = Directory.systemTemp.createTempSync('conversion_test_');
    native.commands.clear();
    native.returnCodes.clear();
    native.outputBytes = null;
    native.probeHandler = null;
    native.probeOverrides.clear();
    native.outputWriter = null;
    native.coverBytes = null;
    native.cancelledSessions.clear();
    native.sessionDelay = null;
    native.sessionRequestedSignal = null;
    native.install();
  });
  tearDown(() => scratch.deleteSync(recursive: true));

  /// Copies a fixture into the scratch dir under [as].
  String stage(String fixture, {String? as}) {
    final dest = '${scratch.path}/${as ?? fixture}';
    File('test/fixtures/audio/$fixture').copySync(dest);
    return dest;
  }

  Future<String> convert(String input, {TrackMetadataFallback? fallback}) =>
      service.process(
        inputPath: input,
        outputDir: scratch.path,
        fallbackMetadata: fallback,
      );

  List<String> transcodeArgs() => native.commands[1];

  /// Runs service-built arguments with a real ffmpeg.
  Future<void> runReal(List<String> args) async {
    final r = await Process.run('ffmpeg', [
      '-hide_banner',
      '-loglevel',
      'error',
      ...args,
    ]);
    expect(r.exitCode, 0, reason: '${r.stderr}');
  }

  Future<bool> realDecodes(String path) async {
    final r = await Process.run('ffmpeg', [
      '-hide_banner',
      ...AudioConversionService.decodeValidationArgs(path),
    ]);
    return r.exitCode == 0;
  }

  group('MP3 passthrough', () {
    test(
      'a valid MP3 is validated and returned untouched (no transcode)',
      () async {
        final input = stage('tone.mp3');
        final out = await convert(input);
        expect(out, input);
        expect(native.commands, hasLength(1), reason: 'validation only');
        expect(
          native.commands.single,
          containsAllInOrder(['-map', '0:a:0', '-f', 'null']),
        );
        expect(native.commands.expand((c) => c), isNot(contains('libmp3lame')));
      },
    );

    test(
      'an MP3 with tags and cover is passed through byte-for-byte',
      () async {
        final input = stage('tone_art.mp3');
        final before = File(input).readAsBytesSync();
        expect(await convert(input), input);
        expect(File(input).readAsBytesSync(), before);
      },
    );

    test(
      'the extension is never trusted: an MP3 named .m4a is still passthrough',
      () async {
        final input = stage('tone.mp3', as: 'misnamed.m4a');
        expect(await convert(input), input);
        expect(native.commands, hasLength(1));
      },
    );

    test(
      'filling a missing tag is a stream-copy remux, not a re-encode',
      () async {
        final input = stage('tone.mp3');
        final out = await convert(
          input,
          fallback: const TrackMetadataFallback(title: 'Only Title'),
        );
        expect(out, endsWith('.mp3'));
        expect(out, isNot(input));
        final args = native.commands[1];
        expect(args, containsAllInOrder(['-c:a', 'copy']));
        expect(args, isNot(contains('libmp3lame')));
        expect(args, contains('title=Only Title'));
        expect(args.any((a) => a.startsWith('artist=')), isFalse);
      },
    );
  });

  group('transcoding to MP3', () {
    const sources = {
      'tone.m4a': 'm4a',
      'video_with_audio.mp4': 'mp4',
      'tone.aac': 'aac',
      'tone.webm': 'webm',
      'tone.ogg': 'ogg',
      'tone.flac': 'flac',
      'tone.wav': 'wav',
    };

    for (final e in sources.entries) {
      test(
        '${e.value.toUpperCase()} -> MP3 (validate, libmp3lame, validate)',
        () async {
          native.commands.clear();
          final input = stage(e.key);
          final out = await convert(input);
          expect(out, endsWith('.mp3'));
          expect(out.endsWith('.${e.value}.mp3'), isFalse);
          expect(native.commands, hasLength(3));
          expect(
            native.commands[0],
            containsAllInOrder(['-i', input, '-f', 'null']),
          );
          expect(
            transcodeArgs(),
            containsAllInOrder([
              '-map',
              '0:a:0',
              '-vn',
              '-c:a',
              'libmp3lame',
              '-q:a',
              '2',
              '-map_metadata',
              '0',
              '-id3v2_version',
              '3',
            ]),
          );
          expect(
            native.commands[2],
            containsAllInOrder(['-i', out, '-f', 'null']),
          );
          expect(File(out).existsSync(), isTrue);
        },
      );
    }

    test('raw AAC no longer takes any M4A wrapping path', () async {
      await convert(stage('tone.aac'));
      final all = native.commands.expand((c) => c).toList();
      expect(all, isNot(contains('aac_adtstoasc')));
      expect(all.any((a) => a.endsWith('.m4a')), isFalse);
    });

    test('video streams are never copied into the output', () async {
      await convert(stage('video_with_audio.mp4'));
      final args = transcodeArgs();
      expect(args, contains('-vn'));
      expect(args, isNot(contains('-c:v')));
      expect(args, isNot(contains('copy')));
    });
  });

  group('validation and failure', () {
    test(
      'input without decodable audio is rejected before any conversion',
      () async {
        native.returnCodes.add(1);
        await expectLater(
          convert(stage('video_no_audio.mp4')),
          throwsA(isA<ConversionFailedException>()),
        );
        expect(native.commands, hasLength(1));
      },
    );

    test('corrupt input is rejected', () async {
      final bad = File('${scratch.path}/bad.m4a')
        ..writeAsBytesSync(List.filled(300, 9));
      native.returnCodes.add(1);
      await expectLater(
        convert(bad.path),
        throwsA(isA<ConversionFailedException>()),
      );
    });

    test('a conversion failure leaves no output', () async {
      native.returnCodes.addAll([0, 1]);
      await expectLater(
        convert(stage('tone.m4a')),
        throwsA(isA<ConversionFailedException>()),
      );
      expect(File(native.commands[1].last).existsSync(), isFalse);
    });

    test(
      'an output that fails the decode check is rejected and deleted',
      () async {
        native.returnCodes.addAll([0, 0, 1]);
        await expectLater(
          convert(stage('tone.m4a')),
          throwsA(isA<ConversionFailedException>()),
        );
        expect(File(native.commands[1].last).existsSync(), isFalse);
      },
    );

    test('an output that is not really MP3 is rejected and deleted', () async {
      native.outputBytes = List.filled(600, 7);
      await expectLater(
        convert(stage('tone.m4a')),
        throwsA(isA<ConversionFailedException>()),
      );
      expect(File(native.commands[1].last).existsSync(), isFalse);
    });

    test('an empty output is rejected and deleted', () async {
      native.outputBytes = <int>[];
      await expectLater(
        convert(stage('tone.m4a')),
        throwsA(isA<ConversionFailedException>()),
      );
      expect(File(native.commands[1].last).existsSync(), isFalse);
    });

    test('cancelling during the transcode deletes the partial MP3', () async {
      native.returnCodes.addAll([0, 255]);
      await expectLater(
        convert(stage('tone.m4a')),
        throwsA(isA<ConversionCancelledException>()),
      );
      expect(native.commands, hasLength(2), reason: 'no output validation');
      expect(File(native.commands[1].last).existsSync(), isFalse);
    });

    test('cancelling during input validation stops everything', () async {
      native.returnCodes.add(255);
      await expectLater(
        convert(stage('tone.m4a')),
        throwsA(isA<ConversionCancelledException>()),
      );
      expect(native.commands, hasLength(1));
    });

    test('validateDecodableAudio: success, failure, cancel', () async {
      await service.validateDecodableAudio('/scratch/in.mp3');
      native.returnCodes.add(1);
      await expectLater(
        service.validateDecodableAudio('/scratch/in.mp3'),
        throwsA(isA<ConversionFailedException>()),
      );
      native.returnCodes.add(255);
      await expectLater(
        service.validateDecodableAudio('/scratch/in.mp3'),
        throwsA(isA<ConversionCancelledException>()),
      );
    });
  });

  group('metadata arguments', () {
    test('title, artist and album are passed with Unicode intact', () async {
      await convert(
        stage('tone.m4a'),
        fallback: const TrackMetadataFallback(
          title: 'Café 歌曲',
          artist: 'أحمد',
          album: 'Álbum ✓',
        ),
      );
      final args = transcodeArgs();
      expect(
        args,
        containsAll(['title=Café 歌曲', 'artist=أحمد', 'album=Álbum ✓']),
      );
      expect(
        args.where((a) => a == '-metadata'),
        hasLength(3),
        reason: 'no duplicates',
      );
    });

    test('quotes and backslashes cannot break the command', () async {
      await convert(
        stage('tone.m4a'),
        fallback: TrackMetadataFallback(title: 'A "quoted" \\ title'),
      );
      expect(transcodeArgs(), contains("title=A 'quoted' / title"));
    });

    test('no fallback means no -metadata arguments', () async {
      await convert(stage('tone.m4a'));
      expect(transcodeArgs(), isNot(contains('-metadata')));
    });

    test('blank fallback values are ignored', () async {
      await convert(
        stage('tone.m4a'),
        fallback: const TrackMetadataFallback(title: '   ', artist: ''),
      );
      expect(transcodeArgs(), isNot(contains('-metadata')));
    });
  });

  group('real FFmpeg (skipped without ffmpeg)', () {
    test(
      'every supported source converts to a decodable MP3 with no video stream',
      () async {
        if (!hasFfmpeg) return;
        for (final f in [
          'tone.m4a',
          'video_with_audio.mp4',
          'tone.aac',
          'tone.webm',
          'tone.ogg',
          'tone.flac',
          'tone.wav',
        ]) {
          native.commands.clear();
          final input = stage(f);
          final out = await convert(input);
          await runReal(transcodeArgs());
          expect(await realDecodes(out), isTrue, reason: f);
          expect(
            () => readMetadata(File(out), getImage: false),
            returnsNormally,
            reason: f,
          );
          final probe = await Process.run('ffprobe', [
            '-v',
            'error',
            '-show_entries',
            'stream=codec_type',
            '-of',
            'csv=p=0',
            out,
          ]);
          expect('${probe.stdout}'.trim().split(RegExp(r'\s+')), [
            'audio',
          ], reason: f);
        }
      },
    );

    test('tags survive conversion, including Unicode', () async {
      if (!hasFfmpeg) return;
      final out = await convert(stage('tone_tagged_art.m4a'));
      await runReal(transcodeArgs());
      final meta = readMetadata(File(out), getImage: false);
      expect(meta.title, 'Café 歌曲 Test');
      expect(meta.artist, 'أحمد Artist');
      expect(meta.album, 'Álbum ✓');
    });

    test('tagged MP3 passthrough keeps its tags and cover', () async {
      final out = await convert(stage('tone_art.mp3'));
      final meta = readMetadata(File(out), getImage: true);
      expect(meta.title, 'With Art');
      expect(meta.pictures, isNotEmpty);
    });

    test('resolver metadata fills missing tags (remux and transcode), Unicode intact', () async {
      if (!hasFfmpeg) return;
      for (final f in ['tone.mp3', 'tone.m4a']) {
        native.commands.clear();
        final out = await convert(
          stage(f),
          fallback: const TrackMetadataFallback(
            title: 'Café 歌曲',
            artist: 'أحمد',
            album: 'Álbum ✓',
          ),
        );
        await runReal(native.commands[1]);
        final meta = readMetadata(File(out), getImage: false);
        expect(meta.title, 'Café 歌曲', reason: f);
        expect(meta.artist, 'أحمد', reason: f);
        expect(meta.album, 'Álbum ✓', reason: f);
      }
    });

    test('invalid inputs fail the real decode check', () async {
      if (!hasFfmpeg) return;
      final bad = File('${scratch.path}/x.bin')
        ..writeAsBytesSync(List.filled(600, 7));
      expect(await realDecodes(bad.path), isFalse);
      expect(await realDecodes(stage('video_no_audio.mp4')), isFalse);
    });
  });

  group('authoritative MP3 detection (FFprobe codec + container)', () {
    test('an ID3-prefixed decodable AAC file is NOT treated as MP3', () async {
      // Genuine ADTS AAC behind a 2 KB ID3v2 tag: the leading bytes look like
      // an MP3 to a signature heuristic, FFprobe says aac.
      for (final name in ['tone_id3_prefixed_aac.mp3', 'renamed.m4a']) {
        native.commands.clear();
        final input = stage('tone_id3_prefixed_aac.mp3', as: name);
        final out = await convert(input);
        expect(out, isNot(input), reason: name);
        expect(native.commands, hasLength(3), reason: name);
        expect(transcodeArgs(), contains('libmp3lame'), reason: name);
        expect(transcodeArgs(), isNot(containsAllInOrder(['-c:a', 'copy'])));
      }
    });

    test('a non-MP3 file with an MP3 extension transcodes', () async {
      final out = await convert(stage('tone.m4a', as: 'liar.mp3'));
      expect(native.commands, hasLength(3));
      expect(transcodeArgs(), contains('libmp3lame'));
      expect(out, isNot(endsWith('liar.mp3')));
    });

    test('a source that cannot be probed is never passed through', () async {
      final input = stage('tone.mp3');
      native.probeOverrides[input] = null;
      final out = await convert(input);
      expect(out, isNot(input));
      expect(transcodeArgs(), contains('libmp3lame'));
    });

    test(
      'MP3 audio in a non-MP3 container is copied, never passed through',
      () async {
        final input = stage('tone.mp3', as: 'x.mp4');
        native.probeOverrides[input] = {
          'format': {'format_name': 'mov,mp4,m4a,3gp,3g2,mj2', 'tags': {}},
          'streams': [
            {'index': 0, 'codec_type': 'audio', 'codec_name': 'mp3'},
          ],
        };
        final out = await convert(input);
        expect(out, isNot(input));
        expect(transcodeArgs(), containsAllInOrder(['-c:a', 'copy']));
        expect(transcodeArgs(), isNot(contains('libmp3lame')));
      },
    );

    test('a genuine MP3 needing a tag fill may be stream-copied', () async {
      await convert(
        stage('tone.mp3'),
        fallback: const TrackMetadataFallback(artist: 'Someone'),
      );
      expect(transcodeArgs(), containsAllInOrder(['-c:a', 'copy']));
      expect(transcodeArgs(), contains('artist=Someone'));
    });

    test('the final output must itself probe as a real MP3', () async {
      native.probeHandler = (path) async {
        // Inputs look like AAC in MP4; the produced .mp3 is "actually" AAC.
        return {
          'format': {'format_name': 'aac', 'tags': {}},
          'streams': [
            {'index': 0, 'codec_type': 'audio', 'codec_name': 'aac'},
          ],
        };
      };
      await expectLater(
        convert(stage('tone.m4a')),
        throwsA(isA<ConversionFailedException>()),
      );
      expect(File(native.commands[1].last).existsSync(), isFalse);
    });

    test(
      'real FFmpeg: ID3-prefixed AAC becomes a real, decodable MP3',
      () async {
        if (!hasFfmpeg) return;
        final out = await convert(stage('tone_id3_prefixed_aac.mp3'));
        await runReal(transcodeArgs());
        expect(await realDecodes(out), isTrue);
        final probe = await Process.run('ffprobe', [
          '-v',
          'error',
          '-show_entries',
          'stream=codec_name:format=format_name',
          '-of',
          'csv=p=0',
          out,
        ]);
        final text = '${probe.stdout}';
        expect(text, contains('mp3'));
        expect(text, isNot(contains('aac')));
      },
    );
  });

  group(
    'metadata precedence: embedded > resolver only when provably absent',
    () {
      const conflicting = TrackMetadataFallback(
        title: 'Resolver Title',
        artist: 'Resolver Artist',
        album: 'Resolver Album',
      );

      test(
        'WebM embedded tags (uppercase keys) win over resolver values',
        () async {
          await convert(stage('tone_tagged.webm'), fallback: conflicting);
          expect(native.commands[1], isNot(contains('-metadata')));
        },
      );

      test(
        'resolver fills only the fields the source provably lacks',
        () async {
          // tone_art.webm carries a title only.
          await convert(stage('tone_art.webm'), fallback: conflicting);
          final args = native.commands[1];
          expect(args.any((a) => a.startsWith('title=')), isFalse);
          expect(args, contains('artist=Resolver Artist'));
          expect(args, contains('album=Resolver Album'));
        },
      );

      test(
        'an uninspectable source never gets resolver tags (unknown != absent)',
        () async {
          final input = stage('tone_tagged.webm');
          native.probeOverrides[input] = null;
          await convert(input, fallback: conflicting);
          expect(
            native.commands.expand((c) => c),
            isNot(contains('-metadata')),
          );
        },
      );

      test(
        'a huge source is probed, not read: its tags are not "missing"',
        () async {
          // 101 MB (beyond any in-memory tag read); the probe reports a title.
          final big = File('${scratch.path}/big.webm');
          final raf = big.openSync(mode: FileMode.write);
          raf.truncateSync(101 * 1024 * 1024);
          raf.closeSync();
          native.probeOverrides[big.path] = {
            'format': {
              'format_name': 'matroska,webm',
              'tags': {'title': 'Embedded Big Title'},
            },
            'streams': [
              {'index': 0, 'codec_type': 'audio', 'codec_name': 'opus'},
            ],
          };
          await convert(big.path, fallback: conflicting);
          final args = native.commands[1];
          expect(args.any((a) => a.startsWith('title=')), isFalse);
          expect(args, contains('artist=Resolver Artist'));
        },
      );

      test('blank embedded values count as absent', () async {
        final input = stage('tone.webm');
        native.probeOverrides[input] = {
          'format': {
            'format_name': 'matroska,webm',
            'tags': {'title': '   ', 'artist': 'Real Artist'},
          },
          'streams': [
            {'index': 0, 'codec_type': 'audio', 'codec_name': 'opus'},
          ],
        };
        await convert(input, fallback: conflicting);
        final args = native.commands[1];
        expect(args, contains('title=Resolver Title'));
        expect(args.any((a) => a.startsWith('artist=')), isFalse);
      });

      test('real FFmpeg: WebM embedded title/artist/album survive; resolver does not overwrite', () async {
        if (!hasFfmpeg) return;
        final out = await convert(
          stage('tone_tagged.webm'),
          fallback: conflicting,
        );
        await runReal(transcodeArgs());
        final meta = readMetadata(File(out), getImage: false);
        expect(meta.title, 'Café 歌曲 WebM');
        expect(meta.artist, 'أحمد WebM');
        expect(meta.album, 'Álbum WebM');
      });

      test(
        'real FFmpeg: a partially tagged WebM gets only the missing fields',
        () async {
          if (!hasFfmpeg) return;
          final out = await convert(
            stage('tone_art.webm'),
            fallback: conflicting,
          );
          await runReal(transcodeArgs());
          final meta = readMetadata(File(out), getImage: false);
          expect(meta.title, 'Art WebM');
          expect(meta.artist, 'Resolver Artist');
          expect(meta.album, 'Resolver Album');
        },
      );
    },
  );

  group('embedded artwork extraction (FFmpeg, not the Dart tag reader)', () {
    test('a source without cover art is known to have none', () async {
      final art = await service.extractEmbeddedArtwork(
        stage('tone.m4a'),
        scratch.path,
      );
      expect(art.path, isNull);
      expect(art.unknown, isFalse);
      expect(native.commands, isEmpty, reason: 'no extraction attempted');
    });

    test('a WebM cannot carry the attachment form: known absent', () async {
      // FFmpeg's webm muxer drops attachments, so this fixture has no cover.
      final art = await service.extractEmbeddedArtwork(
        stage('tone_art.webm'),
        scratch.path,
      );
      expect(art.path, isNull);
      expect(art.unknown, isFalse);
    });

    test(
      'cover in a container the Dart reader cannot inspect is extracted',
      () async {
        // Matroska audio: the Dart tag reader has no Matroska support.
        expect(
          () => readMetadata(
            File('test/fixtures/audio/tone_art.mka'),
            getImage: true,
          ),
          throwsA(anything),
        );
        final art = await service.extractEmbeddedArtwork(
          stage('tone_art.mka'),
          scratch.path,
        );
        expect(art.path, isNotNull);
        expect(art.path, endsWith('.jpg'));
        expect(File(art.path!).existsSync(), isTrue);
        expect(
          native.commands.single,
          containsAllInOrder(['-map', '0:1', '-frames:v', '1', '-c:v', 'copy']),
        );
      },
    );

    test('cover in M4A is extracted', () async {
      final art = await service.extractEmbeddedArtwork(
        stage('tone_tagged_art.m4a'),
        scratch.path,
      );
      expect(art.path, isNotNull);
    });

    test('an un-probeable source has UNKNOWN artwork, not none', () async {
      final input = stage('tone_art.mka');
      native.probeOverrides[input] = null;
      final art = await service.extractEmbeddedArtwork(input, scratch.path);
      expect(art.path, isNull);
      expect(art.unknown, isTrue);
    });

    test('a failed extraction is unknown (the source does have art)', () async {
      native.returnCodes.add(1);
      final art = await service.extractEmbeddedArtwork(
        stage('tone_art.mka'),
        scratch.path,
      );
      expect(art.path, isNull);
      expect(art.unknown, isTrue);
      expect(
        Directory(scratch.path)
            .listSync()
            .where((e) => e.path.contains('_cover')),
        isEmpty,
      );
    });

    test(
      'cancelling during extraction throws cancelled and leaves no file',
      () async {
        native.returnCodes.add(255);
        await expectLater(
          service.extractEmbeddedArtwork(stage('tone_art.mka'), scratch.path),
          throwsA(isA<ConversionCancelledException>()),
        );
        expect(
          Directory(scratch.path)
              .listSync()
              .where((e) => e.path.contains('_cover')),
          isEmpty,
        );
      },
    );

    /// Output that keeps growing 1 MB at a time (up to 300 MB) until the
    /// session is cancelled, reporting how much it managed to write.
    int written = 0;
    Future<void> growingWriter(String path, bool Function() cancelled) async {
      final chunk = List<int>.filled(1024 * 1024, 0xFF);
      final raf = File(path).openSync(mode: FileMode.write);
      try {
        raf.writeFromSync([0xFF, 0xD8, 0xFF, 0xE0]);
        for (var i = 0; i < 300 && !cancelled(); i++) {
          raf.writeFromSync(chunk);
          written += chunk.length;
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      } finally {
        raf.closeSync();
      }
    }

    test('the 10 MB limit is enforced DURING extraction: FFmpeg is cancelled and the file removed', () async {
      written = 0;
      native.outputWriter = growingWriter;
      final art = await service.extractEmbeddedArtwork(
        stage('tone_art.mka'),
        scratch.path,
      );
      expect(art.path, isNull);
      expect(art.unknown, isTrue, reason: 'oversized is UNKNOWN, never absent');
      expect(
        native.cancelledSessions,
        hasLength(1),
        reason: 'FFmpeg was stopped',
      );
      expect(
        written,
        lessThan(20 * 1024 * 1024),
        reason: 'stopped long before the 300 MB the source would have produced',
      );
      expect(
        Directory(scratch.path)
            .listSync()
            .where((e) => e.path.contains('_cover')),
        isEmpty,
        reason: 'partial artwork deleted',
      );
    });

    test('extraction carries a muxer-level size cap as well', () async {
      await service.extractEmbeddedArtwork(stage('tone_art.mka'), scratch.path);
      final args = native.commands.single;
      expect(args, containsAllInOrder(['-fs', '${10 * 1024 * 1024 + 1}']));
    });

    test('an invalid image payload is UNKNOWN and deleted', () async {
      native.coverBytes = List.filled(2000, 7);
      final art = await service.extractEmbeddedArtwork(
        stage('tone_art.mka'),
        scratch.path,
      );
      expect(art.path, isNull);
      expect(art.unknown, isTrue);
      expect(
        Directory(scratch.path)
            .listSync()
            .where((e) => e.path.contains('_cover')),
        isEmpty,
      );
    });

    test('a small valid JPEG is FOUND', () async {
      final art = await service.extractEmbeddedArtwork(
        stage('tone_art.mka'),
        scratch.path,
      );
      expect(art.path, isNotNull);
      expect(art.unknown, isFalse);
    });

    test('user cancellation during oversized growth is cancellation, not "unknown"', () async {
      native.outputWriter = (path, cancelled) async {
        final raf = File(path).openSync(mode: FileMode.write);
        raf.writeFromSync([0xFF, 0xD8, 0xFF, 0xE0]);
        raf.closeSync();
        // Stay "running" until cancelled.
        for (var i = 0; i < 400 && !cancelled(); i++) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      };
      final future = service.extractEmbeddedArtwork(
        stage('tone_art.mka'),
        scratch.path,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await service.cancel();
      await expectLater(future, throwsA(isA<ConversionCancelledException>()));
      expect(
        Directory(scratch.path)
            .listSync()
            .where((e) => e.path.contains('_cover')),
        isEmpty,
      );
    });

    List<int> fixtureBytes(String name) =>
        File('test/fixtures/audio/$name').readAsBytesSync();

    Future<EmbeddedArtwork> extractWithCover(List<int> cover) {
      native.coverBytes = cover;
      return service.extractEmbeddedArtwork(
        stage('tone_art.mka'),
        scratch.path,
      );
    }

    bool coverLeft() =>
        Directory(scratch.path)
            .listSync()
            .any((e) => e.path.contains('_cover'));

    test('a complete, decodable JPEG is FOUND', () async {
      final art = await extractWithCover(fixtureBytes('cover_valid.jpg'));
      expect(art.path, isNotNull);
      expect(art.unknown, isFalse);
      expect(File(art.path!).existsSync(), isTrue);
    });

    test('a complete, decodable PNG is FOUND', () async {
      final art = await extractWithCover(fixtureBytes('cover_valid.png'));
      expect(art.path, isNotNull);
      expect(art.unknown, isFalse);
    });

    test(
      'a JPEG with a valid header but truncated body is UNKNOWN and deleted',
      () async {
        final jpeg = fixtureBytes('cover_valid.jpg');
        final art = await extractWithCover(jpeg.sublist(0, jpeg.length ~/ 2));
        expect(art.path, isNull);
        expect(art.unknown, isTrue);
        expect(coverLeft(), isFalse);
      },
    );

    test(
      'a JPEG truncated only at the very end (EOI missing) is UNKNOWN',
      () async {
        final jpeg = fixtureBytes('cover_valid.jpg');
        final art = await extractWithCover(jpeg.sublist(0, jpeg.length - 2));
        expect(art.unknown, isTrue);
        expect(coverLeft(), isFalse);
      },
    );

    test(
      'a PNG with a valid header but truncated body is UNKNOWN and deleted',
      () async {
        final png = fixtureBytes('cover_valid.png');
        final art = await extractWithCover(png.sublist(0, png.length ~/ 2));
        expect(art.path, isNull);
        expect(art.unknown, isTrue);
        expect(coverLeft(), isFalse);
      },
    );

    test(
      'a PNG with intact header and IEND but a corrupt body is UNKNOWN',
      () async {
        final png = List<int>.of(fixtureBytes('cover_valid.png'));
        // Corrupt the compressed image data in the middle; keep header + IEND.
        for (var i = png.length ~/ 3; i < png.length ~/ 3 + 200; i++) {
          png[i] = (png[i] ^ 0xA5) & 0xFF;
        }
        final art = await extractWithCover(png);
        expect(art.path, isNull);
        expect(art.unknown, isTrue);
        expect(coverLeft(), isFalse);
      },
    );

    test(
      'an image with absurd declared dimensions is rejected without decoding',
      () async {
        final png = List<int>.of(fixtureBytes('cover_valid.png'));
        png.setRange(16, 24, [0x7F, 0xFF, 0xFF, 0xFF, 0x7F, 0xFF, 0xFF, 0xFF]);
        final art = await extractWithCover(png);
        expect(art.unknown, isTrue);
        expect(coverLeft(), isFalse);
      },
    );

    test('cancel that lands while probing never starts FFmpeg', () async {
      final gate = Completer<void>();
      final input = stage('tone_art.mka');
      native.probeHandler = (path) async {
        await gate.future;
        return native.realProbe(path);
      };
      final future = service.extractEmbeddedArtwork(input, scratch.path);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await service.cancel();
      gate.complete();
      await expectLater(future, throwsA(isA<ConversionCancelledException>()));
      expect(native.commands, isEmpty, reason: 'extraction never started');
      expect(coverLeft(), isFalse);
    });

    test('cancel before the FFmpeg session id exists cancels THAT session once it does', () async {
      final gate = Completer<void>();
      native.sessionDelay = gate.future;
      final requested = Completer<void>();
      native.sessionRequestedSignal = requested;
      // Stay "running" until cancelled, like a long extraction.
      native.outputWriter = (path, cancelled) async {
        final raf = File(path).openSync(mode: FileMode.write);
        raf.writeFromSync([0xFF, 0xD8, 0xFF, 0xE0]);
        raf.closeSync();
        for (var i = 0; i < 600 && !cancelled(); i++) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      };
      final future = service.extractEmbeddedArtwork(
        stage('tone_art.mka'),
        scratch.path,
      );
      // Wait until the session request is genuinely in flight.
      await requested.future.timeout(const Duration(seconds: 10));
      await service.cancel(); // no session id yet: nothing to cancel
      expect(native.cancelledSessions, isEmpty);
      gate.complete(); // the session becomes available
      await expectLater(future, throwsA(isA<ConversionCancelledException>()));
      expect(
        native.cancelledSessions,
        hasLength(1),
        reason: 'that session only',
      );
      expect(coverLeft(), isFalse);
    });

    test(
      'the internal size-limit cancel stays UNKNOWN (not a user cancel)',
      () async {
        native.outputWriter = (path, cancelled) async {
          final chunk = List<int>.filled(1024 * 1024, 0xFF);
          final raf = File(path).openSync(mode: FileMode.write);
          try {
            for (var i = 0; i < 100 && !cancelled(); i++) {
              raf.writeFromSync(chunk);
              await Future<void>.delayed(const Duration(milliseconds: 5));
            }
          } finally {
            raf.closeSync();
          }
        };
        final art = await service.extractEmbeddedArtwork(
          stage('tone_art.mka'),
          scratch.path,
        );
        expect(art.unknown, isTrue);
        expect(native.cancelledSessions, hasLength(1));
        // ...and it does not poison the next run.
        native.outputWriter = null;
        final next = await service.extractEmbeddedArtwork(
          stage('tone_art.mka', as: 'again.mka'),
          scratch.path,
        );
        expect(next.path, isNotNull);
      },
    );

    test('a user cancel does not poison the next extraction', () async {
      native.returnCodes.add(255);
      await expectLater(
        service.extractEmbeddedArtwork(stage('tone_art.mka'), scratch.path),
        throwsA(isA<ConversionCancelledException>()),
      );
      final next = await service.extractEmbeddedArtwork(
        stage('tone_art.mka', as: 'again.mka'),
        scratch.path,
      );
      expect(next.path, isNotNull);
    });

    test('real FFmpeg: extracted covers are genuine JPEGs', () async {
      if (!hasFfmpeg) return;
      for (final f in ['tone_art.mka', 'tone_tagged_art.m4a', 'tone_art.mp3']) {
        native.commands.clear();
        final art = await service.extractEmbeddedArtwork(
          stage(f),
          scratch.path,
        );
        expect(art.path, isNotNull, reason: f);
        await runReal(native.commands.single);
        final bytes = File(art.path!).readAsBytesSync();
        expect(bytes.sublist(0, 2), [0xFF, 0xD8], reason: f);
      }
    });
  });
}
