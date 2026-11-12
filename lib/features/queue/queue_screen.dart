import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/nocturne_colors.dart';
import '../../core/models/track.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../playback/playback_service.dart';
import '../../shared/widgets/artwork_view.dart';

/// Matches the design's 1i: current track pinned at top, a reorderable
/// "Playing next" list below it, then a footer naming what the queue falls
/// back to once the manual upcoming list runs out.
class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playback = context.watch<PlaybackService>();
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: NocturneColors.bg,
      appBar: AppBar(title: Text(l10n.queueTitle)),
      body: StreamBuilder<List<Track>>(
        stream: playback.queue,
        initialData: playback.queue.value,
        builder: (context, queueSnapshot) {
          final queue = queueSnapshot.data ?? const <Track>[];
          return StreamBuilder<int?>(
            stream: playback.currentIndex,
            initialData: playback.currentIndex.value,
            builder: (context, indexSnapshot) {
              final currentIndex = indexSnapshot.data;
              final current =
                  (currentIndex != null && currentIndex < queue.length)
                  ? queue[currentIndex]
                  : null;
              final upcoming = (currentIndex != null)
                  ? queue.sublist((currentIndex + 1).clamp(0, queue.length))
                  : queue;

              return StreamBuilder<String?>(
                stream: playback.contextName,
                initialData: playback.contextName.value,
                builder: (context, ctxSnapshot) {
                  return ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 8,
                    ),
                    children: [
                      if (current != null) ...[
                        Text(
                          l10n.queueNowPlaying,
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 0.09,
                            color: NocturneColors.accent300,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            ArtworkView(
                              artworkPath: current.artworkPath,
                              seed: current.artworkSeed,
                              size: 52,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    current.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    current.artist,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: NocturneColors.textMuted(0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: Divider(height: 1),
                        ),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.queuePlayingNext,
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 0.09,
                              color: NocturneColors.textMuted(0.45),
                            ),
                          ),
                          if (upcoming.isNotEmpty)
                            TextButton(
                              onPressed: playback.clearUpcoming,
                              child: Text(
                                l10n.commonClear,
                                style: TextStyle(
                                  color: NocturneColors.accent300,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (upcoming.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(l10n.queueNothingQueued),
                        )
                      else
                        ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: upcoming.length,
                          onReorderItem: (oldIndex, newIndex) {
                            final base = (currentIndex ?? -1) + 1;
                            playback.moveQueueItem(
                              base + oldIndex,
                              base + newIndex,
                            );
                          },
                          itemBuilder: (context, i) {
                            final track = upcoming[i];
                            return ListTile(
                              key: ValueKey('${track.id}-$i'),
                              leading: ArtworkView(
                                artworkPath: track.artworkPath,
                                seed: track.artworkSeed,
                                size: 42,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              title: Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(track.artist),
                              trailing: ReorderableDragStartListener(
                                index: i,
                                child: Icon(
                                  Icons.drag_handle,
                                  color: NocturneColors.iconMuted,
                                ),
                              ),
                              onTap: () => playback.skipToIndex(
                                (currentIndex ?? -1) + 1 + i,
                              ),
                            );
                          },
                        ),
                      if (ctxSnapshot.data != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            l10n.queueThenContinuesFrom(
                              ctxSnapshot.data!.toUpperCase(),
                            ),
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 0.09,
                              color: NocturneColors.textMuted(0.4),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
