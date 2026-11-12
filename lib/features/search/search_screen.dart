import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/diagnostics/startup_log.dart';
import '../../core/diagnostics/perf_log.dart';
import '../../app/theme/nocturne_colors.dart';
import '../../core/models/track.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../library/library_repository.dart';
import '../../playback/playback_service.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/song_row.dart';
import '../playlists/playlist_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  String _query = '';
  late final _allTracks = context.read<LibraryRepository>().watchAllTracks();
  late final _playlists = context.read<LibraryRepository>().watchPlaylists();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  void _onChanged(String value) {
    if (PerfLog.enabled) {
      PerfLog.end('search-update', 'superseded');
      PerfLog.begin('search-update', 'query changed (debounce 250ms included)');
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    StartupLog.markOnce('tab-Search', 'tab Search first build');
    final playback = context.read<PlaybackService>();
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: NocturneColors.bg,
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onChanged,
          style: TextStyle(color: NocturneColors.text, fontSize: 16),
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            hintStyle: TextStyle(color: NocturneColors.iconMuted),
            prefixIcon: Icon(
              Icons.search,
              size: 20,
              color: NocturneColors.iconMuted,
            ),
            filled: true,
            fillColor: NocturneColors.neutral900,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _debounce?.cancel();
                      _controller.clear();
                      setState(() => _query = '');
                    },
                  ),
          ),
        ),
      ),
      body: StreamBuilder<List<Track>>(
        stream: _allTracks,
        initialData: _allTracks.value,
        builder: (context, tracksSnapshot) {
          final allTracks = tracksSnapshot.data ?? const [];
          if (allTracks.isEmpty) {
            return Center(child: Text(l10n.searchEmptyLibrary));
          }

          final q = _query.toLowerCase();
          if (q.isEmpty) {
            return _SongList(
              tracks: allTracks,
              playback: playback,
              contextLabel: l10n.searchContextLabel,
            );
          }

          PerfLog.step('search-update', 'filter START');
          final matchedTracks = allTracks
              .where(
                (t) =>
                    t.title.toLowerCase().contains(q) ||
                    t.artist.toLowerCase().contains(q) ||
                    t.album.toLowerCase().contains(q),
              )
              .toList();
          PerfLog.step(
            'search-update',
            'filter END tracks=${matchedTracks.length} of ${allTracks.length}',
          );

          return StreamBuilder<List<Playlist>>(
            stream: _playlists,
            initialData: _playlists.value,
            builder: (context, playlistsSnapshot) {
              final matchedPlaylists = (playlistsSnapshot.data ?? const [])
                  .where((p) => p.name.toLowerCase().contains(q))
                  .toList();

              PerfLog.step(
                'search-update',
                'results built tracks=${matchedTracks.length} '
                    'playlists=${matchedPlaylists.length}',
              );
              PerfLog.endAfterFrame('search-update', 'results rendered');
              if (matchedTracks.isEmpty && matchedPlaylists.isEmpty) {
                return Center(child: Text(l10n.searchNoResults));
              }

              return ListView(
                children: [
                  if (matchedTracks.isNotEmpty) ...[
                    SectionHeader(title: l10n.libraryFilterTracks),
                    _SongList(
                      tracks: matchedTracks,
                      playback: playback,
                      shrinkWrap: true,
                      contextLabel: l10n.searchContextLabel,
                    ),
                  ],
                  if (matchedPlaylists.isNotEmpty) ...[
                    SectionHeader(title: l10n.navPlaylists),
                    for (final playlist in matchedPlaylists)
                      ListTile(
                        leading: Icon(
                          Icons.queue_music,
                          color: NocturneColors.neutral400,
                        ),
                        title: _Highlighted(text: playlist.name, query: _query),
                        subtitle: Text(
                          l10n.commonTrackCount(playlist.songCount),
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                PlaylistDetailScreen(playlistId: playlist.id),
                          ),
                        ),
                      ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// The normal library song list — reused as-is for "no query yet, show
/// everything" and for a typed query's matched-songs section, so both give
/// the same tap-to-play/context-menu/artwork behavior as every other list.
class _SongList extends StatelessWidget {
  final List<Track> tracks;
  final PlaybackService playback;
  final bool shrinkWrap;
  final String contextLabel;
  const _SongList({
    required this.tracks,
    required this.playback,
    required this.contextLabel,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      itemCount: tracks.length,
      itemBuilder: (context, i) {
        final track = tracks[i];
        return StreamBuilder<Track?>(
          stream: playback.currentTrack,
          initialData: playback.currentTrack.value,
          builder: (context, current) => SongRow(
            track: track,
            isCurrent: current.data?.id == track.id,
            playContext: tracks,
            showDivider: true,
            onTap: () => playback.loadQueue(
              tracks,
              startIndex: i,
              contextName: contextLabel,
            ),
          ),
        );
      },
    );
  }
}

class _Highlighted extends StatelessWidget {
  final String text;
  final String query;
  const _Highlighted({required this.text, required this.query});

  @override
  Widget build(BuildContext context) {
    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    final index = q.isEmpty ? -1 : lower.indexOf(q);
    final baseStyle = TextStyle(
      fontSize: 15.5,
      fontWeight: FontWeight.w500,
      color: NocturneColors.text,
    );
    if (index < 0) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: baseStyle,
      );
    }
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + q.length),
            style: TextStyle(color: NocturneColors.accent200),
          ),
          TextSpan(text: text.substring(index + q.length)),
        ],
      ),
    );
  }
}
