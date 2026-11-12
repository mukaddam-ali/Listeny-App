import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/abstract_session.dart';
import 'package:ffmpeg_kit_flutter_new/src/ffmpeg_kit_factory.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listeny/library/media_signature.dart';

/// Simulates only the native boundary; real AudioConversionService chooses args.
class FakeFfmpeg {
  final commands = <List<String>>[];
  final returnCodes = <int>[];

  /// Bytes written for a conversion output; defaults to a genuine tiny MP3.
  List<int>? outputBytes;

  /// Bytes written for an artwork extraction (`-frames:v`); defaults to a
  /// tiny valid JPEG.
  List<int>? coverBytes;

  /// When set, artwork extraction is simulated as output that GROWS over time
  /// through this writer (path, isCancelled) instead of one instant write,
  /// so tests can prove a size limit stops it while it is still running.
  Future<void> Function(String path, bool Function() isCancelled)? outputWriter;

  /// When set, creating an FFmpeg session blocks until this completes, so
  /// tests can cancel while the session id is not yet available.
  Future<void>? sessionDelay;

  /// Completed when an FFmpeg session is first requested (lets a test wait
  /// until the request is genuinely in flight before cancelling).
  Completer<void>? sessionRequestedSignal;

  /// Session ids FFmpegKit.cancel was called for.
  final cancelledSessions = <int>[];

  /// Overrides what FFprobe "reports" for a path (null = probe failed).
  /// By default the desktop `ffprobe` binary is used when installed, so
  /// probing is genuine; otherwise a small signature-based stand-in.
  Future<Map<String, dynamic>?> Function(String path)? probeHandler;

  /// Per-path FFprobe results (null value = probe failed); other paths
  /// (e.g. a produced output) are probed normally.
  final probeOverrides = <String, Map<String, dynamic>?>{};
  final _probePaths = <int, String>{};
  static bool? _hasFfprobe;
  final _sessions = <int, List<String>>{};
  final _codes = <int, int>{};
  int _nextId = 0;

  void install() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter.arthenica.com/ffmpeg_kit_event'),
      (_) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter.arthenica.com/ffmpeg_kit'),
      (call) async {
        switch (call.method) {
          case 'getPlatform':
            return 'android';
          case 'getArch':
            return 'arm64-v8a';
          case 'getPackageName':
            return 'full-gpl';
          case 'isLTSBuild':
            return false;
          case 'getLogLevel':
            return 16;
          case 'mediaInformationSession':
            final probeArgs = List<String>.from(
              call.arguments['arguments'] as List,
            );
            final probeId = ++_nextId;
            _probePaths[probeId] = probeArgs[probeArgs.indexOf('-i') + 1];
            return {'sessionId': probeId};
          case 'mediaInformationSessionExecute':
            return null;
          case 'getMediaInformation':
            return _probe(_probePaths[call.arguments['sessionId']]!);
          case 'ffmpegSession':
            final signal = sessionRequestedSignal;
            if (signal != null && !signal.isCompleted) signal.complete();
            final delay = sessionDelay;
            if (delay != null) await delay;
            final args = List<String>.from(call.arguments['arguments'] as List);
            final id = ++_nextId;
            commands.add(args);
            _sessions[id] = args;
            return {'sessionId': id};
          case 'cancelSession':
            cancelledSessions.add(call.arguments['sessionId'] as int);
            return null;
          case 'asyncFFmpegSessionExecute':
            final id = call.arguments['sessionId'] as int;
            final args = _sessions[id]!;
            _codes[id] = returnCodes.isEmpty ? 0 : returnCodes.removeAt(0);
            final isExtraction = args.contains('-frames:v');
            if (isExtraction && outputWriter != null) {
              // Growing output: return immediately, finish when the writer
              // ends (it stops early once the session is cancelled).
              unawaited(() async {
                bool cancelled() => cancelledSessions.contains(id);
                await outputWriter!(args.last, cancelled);
                if (cancelled()) _codes[id] = 255;
                FFmpegKitFactory.getFFmpegSessionCompleteCallback(id)!(
                  AbstractSession.createFFmpegSessionFromMap({
                    'sessionId': id,
                    'command': '',
                  }),
                );
              }());
              return null;
            }
            // A decode-validation run writes nowhere (`-f null -`).
            if (args.last != '-') {
              // A genuine tiny MP3 (or, for artwork extraction, a tiny valid
              // JPEG), so outputs pass their signature checks.
              await File(args.last).writeAsBytes(
                isExtraction
                    ? (coverBytes ?? _tinyJpeg)
                    : (outputBytes ??
                          File('test/fixtures/audio/tone.mp3')
                              .readAsBytesSync()),
              );
            }
            Future<void>(() {
              FFmpegKitFactory.getFFmpegSessionCompleteCallback(id)!(
                AbstractSession.createFFmpegSessionFromMap({
                  'sessionId': id,
                  'command': '',
                }),
              );
            });
            return null;
          case 'abstractSessionGetReturnCode':
            return _codes[call.arguments['sessionId']];
          default:
            return null;
        }
      },
    );
  }

  Future<Map<String, dynamic>?> _probe(String path) async {
    final handler = probeHandler;
    if (handler != null) return handler(path);
    if (probeOverrides.containsKey(path)) return probeOverrides[path];
    return realProbe(path);
  }

  /// The default probe (desktop ffprobe when installed), for handlers that
  /// override only some paths.
  Future<Map<String, dynamic>?> realProbe(String path) async {
    _hasFfprobe ??= await _canRun('ffprobe');
    if (_hasFfprobe!) {
      final r = await Process.run('ffprobe', [
        '-v', 'error', '-print_format', 'json', '-show_format',
        '-show_streams', '-i', path, //
      ], stdoutEncoding: utf8);
      if (r.exitCode != 0) return null;
      return jsonDecode(r.stdout as String) as Map<String, dynamic>;
    }
    return _standIn(path);
  }

  static Future<bool> _canRun(String exe) async {
    try {
      return (await Process.run(exe, ['-version'])).exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Signature-based stand-in used only when `ffprobe` is unavailable.
  Map<String, dynamic>? _standIn(String path) {
    final file = File(path);
    if (!file.existsSync()) return null;
    final head = file.openSync().readSync(512);
    final ext = classifyMediaResponse(head: head)?.extension;
    if (ext == null) return null;
    const codecs = {
      'mp3': 'mp3',
      'm4a': 'aac',
      'mp4': 'aac',
      'aac': 'aac',
      'ogg': 'vorbis',
      'flac': 'flac',
      'wav': 'pcm_u8',
      'webm': 'opus',
    };
    return {
      'format': {'format_name': ext == 'mp3' ? 'mp3' : ext, 'tags': {}},
      'streams': [
        {'index': 0, 'codec_type': 'audio', 'codec_name': codecs[ext]},
      ],
    };
  }

  /// A genuine, fully decodable JPEG (96x96).
  static List<int> get _tinyJpeg =>
      File('test/fixtures/audio/cover_valid.jpg').readAsBytesSync();
}
