import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../../app/theme/nocturne_colors.dart';
import '../../core/copy_title.dart';
import '../../core/models/track.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../library/audio_trim_service.dart';
import '../../library/file_name_sanitizer.dart';
import '../../library/import_models.dart';
import '../../library/import_service.dart';
import '../../library/library_repository.dart';
import '../../library/public_music_saver.dart';
import '../../playback/playback_service.dart';
import 'trim_time.dart';

/// Lets the user pick a start/end on the track's waveform, preview it, and
/// save the cut either as a new library track or in place of the original.
class TrimScreen extends StatefulWidget {
  final Track track;
  const TrimScreen({super.key, required this.track});

  @override
  State<TrimScreen> createState() => _TrimScreenState();
}

class _TrimScreenState extends State<TrimScreen> {
  static const _fadeChoices = [0.0, 1.0, 2.0, 3.0];
  static const _minGap = Duration(milliseconds: 100);
  static const double _thumb = 10;

  final _trimmer = AudioTrimService();
  final _player = AudioPlayer();

  List<double> _peaks = const [];
  Duration _total = Duration.zero;
  RangeValues _range = const RangeValues(0, 1);
  double _fade = 0;
  bool _previewing = false;
  bool _busy = false;

  // Where a preview starts. Follows the start handle until the user moves it.
  Duration _cursor = Duration.zero;
  bool _cursorMoved = false;
  // Live playback position while previewing (drawn as a thin line).
  final _live = ValueNotifier<Duration?>(null);
  Duration _clipStart = Duration.zero;

  @override
  void initState() {
    super.initState();
    _total = widget.track.duration;
    _range = RangeValues(0, _total.inMilliseconds.toDouble());
    _load();
  }

  Future<void> _load() async {
    final playback = context.read<PlaybackService>();
    await playback.pause();
    final peaks = await _trimmer.waveform(widget.track.filePath);
    var total = _total;
    try {
      total = await _player.setFilePath(widget.track.filePath) ?? total;
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _peaks = peaks;
      if (total > Duration.zero && total != _total) {
        _total = total;
        _range = RangeValues(0, total.inMilliseconds.toDouble());
      }
    });
    _player.playerStateStream.listen((s) {
      if (!mounted) return;
      final playing =
          s.playing && s.processingState != ProcessingState.completed;
      if (!playing) _live.value = null;
      if (playing != _previewing) setState(() => _previewing = playing);
    });
    _player
        .createPositionStream(
          minPeriod: const Duration(milliseconds: 30),
          maxPeriod: const Duration(milliseconds: 60),
        )
        .listen((pos) {
          if (_player.playing) _live.value = _clipStart + pos;
        });
  }

  @override
  void dispose() {
    _live.dispose();
    _player.dispose();
    super.dispose();
  }

  Duration get _start => Duration(milliseconds: _range.start.round());
  Duration get _end => Duration(milliseconds: _range.end.round());

  /// The preview start, kept inside the selected section.
  Duration get _previewFrom {
    if (!_cursorMoved || _end - _start <= _minGap) return _start;
    final latest = _end - _minGap;
    if (_cursor < _start) return _start;
    if (_cursor > latest) return latest;
    return _cursor;
  }

  void _setRange(RangeValues v) => setState(() => _range = v);

  void _setStart(Duration d) {
    final latest = _end - _minGap;
    final start = d < Duration.zero ? Duration.zero : (d > latest ? latest : d);
    _player.pause();
    setState(() {
      _range = RangeValues(start.inMilliseconds.toDouble(), _range.end);
    });
  }

  void _setEnd(Duration d) {
    final earliest = _start + _minGap;
    final end = d < earliest ? earliest : (d > _total ? _total : d);
    _player.pause();
    setState(() {
      _range = RangeValues(_range.start, end.inMilliseconds.toDouble());
    });
  }

  void _setCursor(Duration d) {
    _player.pause();
    setState(() {
      _cursor = d;
      _cursorMoved = true;
    });
  }

  Future<void> _togglePreview() async {
    if (_previewing) {
      await _player.pause();
      return;
    }
    final from = _previewFrom;
    _clipStart = from;
    await _player.setClip(start: from, end: _end);
    await _player.seek(Duration.zero);
    await _player.play();
  }

  Future<void> _save({required bool replace}) async {
    final l10n = AppLocalizations.of(context);
    if (_end - _start < const Duration(seconds: 1)) {
      _toast(l10n.trimTooShort);
      return;
    }
    final importService = context.read<ImportService>();
    final library = context.read<LibraryRepository>();
    final navigator = Navigator.of(context);
    final original = widget.track;
    await _player.pause();
    setState(() => _busy = true);

    String? output;
    SavedMusicFile? saved;
    try {
      // A new track is named "Name (2)", "Name (3)"...; a replacement keeps
      // the original's name.
      final title = replace
          ? original.title
          : nextCopyTitle(
              original.title,
              (await library.getAllTracksOnce()).map((t) => t.title),
            );
      output = await _trimmer.trim(
        inputPath: original.filePath,
        start: _start,
        end: _end,
        fadeSeconds: _fade,
        title: title,
      );
      final fileName =
          '${sanitizeFileName(title, fallback: 'Trim')}${p.extension(output)}';
      // Android 11+: publish into Music/Listeny so the file shows up in file
      // managers, and reference it in place. Elsewhere this is null and the
      // normal app-private import is used.
      saved = await PublicMusicSaver().save(path: output, name: fileName);
      final results = await importService.importFiles([
        PickedFile(
          name: fileName,
          path: saved?.path ?? output,
          // Same cover as the original, including one picked in the app.
          externalArtworkPath: original.artworkPath,
          preferExternalArtwork: original.artworkPath != null,
          referencedSource: saved == null
              ? null
              : ReferencedSource(
                  sourceKey: saved.sourceKey,
                  volume: saved.volume,
                  sizeBytes: saved.sizeBytes,
                  modifiedSec: saved.modifiedSec,
                ),
        ),
      ]).toList();
      final result = results.last.latest;
      if (result.outcome == ImportFileOutcome.duplicate) {
        if (saved != null) await PublicMusicSaver().discard(saved);
        _toast(l10n.trimDuplicate);
      } else if (result.outcome != ImportFileOutcome.added) {
        if (saved != null) await PublicMusicSaver().discard(saved);
        _toast(l10n.trimFailed);
      } else {
        if (replace) {
          await library.deleteTrackFromDevice(original);
          await library.renameTrack(result.track!.id, original.title);
        }
        _toast(replace ? l10n.trimReplaced : l10n.trimSaved);
        if (mounted) navigator.pop(true);
      }
    } catch (_) {
      _toast(l10n.trimFailed);
    } finally {
      if (output != null) {
        try {
          await File(output).delete();
        } catch (_) {}
      }
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final totalMs = _total.inMilliseconds.toDouble();
    final ready = totalMs > 0;
    return Scaffold(
      backgroundColor: NocturneColors.bg,
      appBar: AppBar(title: Text(l10n.trimTitle)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 40,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 120,
                      child: Stack(
                        children: [
                          // Same horizontal inset as the slider track below, so the
                          // waveform, handles and cursor line all line up.
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: _thumb,
                              ),
                              child: CustomPaint(
                                painter: _WaveformPainter(
                                  peaks: _peaks,
                                  rtl:
                                      Directionality.of(context) ==
                                      TextDirection.rtl,
                                  from: ready ? _range.start / totalMs : 0,
                                  to: ready ? _range.end / totalMs : 1,
                                  cursor: ready
                                      ? _previewFrom.inMilliseconds / totalMs
                                      : 0,
                                  totalMs: totalMs,
                                  live: _live,
                                  active: NocturneColors.accent,
                                  inactive: NocturneColors.neutral700,
                                  cursorColor: NocturneColors.textMuted(0.95),
                                  liveColor: NocturneColors.textMuted(0.5),
                                ),
                              ),
                            ),
                          ),
                          if (ready)
                            Positioned.fill(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 0,
                                  activeTrackColor: Colors.transparent,
                                  inactiveTrackColor: Colors.transparent,
                                  rangeTrackShape:
                                      const RoundedRectRangeSliderTrackShape(),
                                  overlayShape: SliderComponentShape.noOverlay,
                                  rangeThumbShape:
                                      const RoundRangeSliderThumbShape(
                                        enabledThumbRadius: _thumb,
                                      ),
                                ),
                                child: RangeSlider(
                                  values: _range,
                                  min: 0,
                                  max: totalMs,
                                  onChangeStart: (_) => _player.pause(),
                                  onChanged: _busy ? null : _setRange,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Drag this handle to choose where the preview starts, e.g. the
                    // middle, or just before the end to hear how it finishes.
                    if (ready)
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          activeTrackColor: Colors.transparent,
                          inactiveTrackColor: NocturneColors.neutral700,
                          thumbColor: NocturneColors.textMuted(0.95),
                          overlayShape: SliderComponentShape.noOverlay,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: _thumb,
                          ),
                        ),
                        child: Slider(
                          value: _previewFrom.inMilliseconds.toDouble().clamp(
                            _range.start,
                            _range.end,
                          ),
                          min: _range.start,
                          max: _range.end > _range.start
                              ? _range.end
                              : _range.start + 1,
                          onChanged: _busy
                              ? null
                              : (v) => _setCursor(
                                  Duration(milliseconds: v.round()),
                                ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _TimeField(
                            label: l10n.trimStartLabel,
                            value: _start,
                            enabled: ready && !_busy,
                            onChanged: _setStart,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TimeField(
                            label: l10n.trimEndLabel,
                            value: _end,
                            enabled: ready && !_busy,
                            onChanged: _setEnd,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TimeField(
                            label: l10n.trimPreviewFromLabel,
                            value: _previewFrom,
                            enabled: ready && !_busy,
                            onChanged: (d) => _setCursor(d),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _TimeLabel(
                      l10n.trimLengthLabel,
                      formatTrimTime(_end - _start),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      l10n.trimFadeLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: NocturneColors.textMuted(0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final f in _fadeChoices)
                          ChoiceChip(
                            label: Text(
                              f == 0 ? l10n.trimFadeOff : '${f.toInt()}s',
                            ),
                            selected: _fade == f,
                            onSelected: _busy
                                ? null
                                : (_) => setState(() => _fade = f),
                          ),
                      ],
                    ),
                    const Spacer(),
                    if (_busy)
                      Center(
                        child: Column(
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 10),
                            Text(l10n.trimWorking),
                          ],
                        ),
                      )
                    else ...[
                      OutlinedButton.icon(
                        onPressed: ready ? _togglePreview : null,
                        icon: Icon(_previewing ? Icons.stop : Icons.play_arrow),
                        label: Text(
                          _previewing ? l10n.trimStopPreview : l10n.trimPreview,
                        ),
                      ),
                      const SizedBox(height: 10),
                      FilledButton(
                        onPressed: ready ? () => _save(replace: false) : null,
                        child: Text(l10n.trimSaveNew),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: ready ? () => _save(replace: true) : null,
                        child: Text(l10n.trimReplaceOriginal),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A labelled text box for typing an exact time (`13`, `13.5`, `1:05.25`,
/// `1:02:03`). Committed when the keyboard's done key is pressed or the box
/// loses focus; the screen clamps it and the box shows the value actually used.
class _TimeField extends StatefulWidget {
  final String label;
  final Duration value;
  final bool enabled;
  final ValueChanged<Duration> onChanged;
  const _TimeField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  State<_TimeField> createState() => _TimeFieldState();
}

class _TimeFieldState extends State<_TimeField> {
  late final TextEditingController _controller = TextEditingController(
    text: formatTrimTime(widget.value),
  );
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _commit();
    });
  }

  @override
  void didUpdateWidget(_TimeField old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus && old.value != widget.value) _show();
  }

  @override
  void dispose() {
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _show() => _controller.text = formatTrimTime(widget.value);

  void _commit() {
    final parsed = parseTrimTime(_controller.text);
    if (parsed != null) widget.onChanged(parsed);
    // The screen may have clamped (or ignored) what was typed: show the value
    // it really uses once it has rebuilt.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_focus.hasFocus) _show();
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focus,
      enabled: widget.enabled,
      keyboardType: TextInputType.datetime,
      textInputAction: TextInputAction.done,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp('[0-9٠-٩۰-۹:.,٫]')),
      ],
      onSubmitted: (_) => _commit(),
      onTap: () => _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      ),
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: widget.label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _TimeLabel extends StatelessWidget {
  final String label;
  final String value;
  const _TimeLabel(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: NocturneColors.textMuted(0.5)),
        ),
        Text(value, style: const TextStyle(fontSize: 15)),
      ],
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> peaks;
  final double from;
  final double to;
  final double cursor;
  final double totalMs;
  final ValueListenable<Duration?> live;
  final bool rtl;
  final Color active;
  final Color inactive;
  final Color cursorColor;
  final Color liveColor;
  _WaveformPainter({
    required this.peaks,
    required this.from,
    required this.to,
    required this.cursor,
    required this.totalMs,
    required this.live,
    required this.rtl,
    required this.active,
    required this.inactive,
    required this.cursorColor,
    required this.liveColor,
  }) : super(repaint: live);

  double _x(double frac, double width) =>
      rtl ? width * (1 - frac) : width * frac;

  @override
  void paint(Canvas canvas, Size size) {
    if (peaks.isEmpty) {
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        Paint()
          ..color = inactive
          ..strokeWidth = 2,
      );
    } else {
      final step = size.width / peaks.length;
      final paint = Paint()
        ..strokeWidth = (step * 0.6).clamp(1.0, 6.0)
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < peaks.length; i++) {
        final x = step * (i + 0.5);
        final frac = rtl ? 1 - x / size.width : x / size.width;
        paint.color = (frac >= from && frac <= to) ? active : inactive;
        final h = (peaks[i] * size.height).clamp(3.0, size.height);
        canvas.drawLine(
          Offset(x, (size.height - h) / 2),
          Offset(x, (size.height + h) / 2),
          paint,
        );
      }
    }
    if (totalMs <= 0) return;

    final pos = live.value;
    if (pos != null) {
      final x = _x((pos.inMilliseconds / totalMs).clamp(0.0, 1.0), size.width);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = liveColor
          ..strokeWidth = 1.5,
      );
    }
    final cx = _x(cursor.clamp(0.0, 1.0), size.width);
    canvas.drawLine(
      Offset(cx, 0),
      Offset(cx, size.height),
      Paint()
        ..color = cursorColor
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.peaks != peaks ||
      old.from != from ||
      old.to != to ||
      old.cursor != cursor ||
      old.totalMs != totalMs ||
      old.rtl != rtl ||
      old.cursorColor != cursorColor;
}
