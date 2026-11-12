/// How the queue repeats once it reaches the end.
///
/// Named `PlaybackRepeatMode` (not `PlaybackRepeatMode`) because Flutter's own
/// `material.dart` already exports an unrelated `PlaybackRepeatMode` enum
/// (`RepeatingAnimationBuilder`'s), which would otherwise collide in every
/// UI file that imports both.
enum PlaybackRepeatMode { off, one, all }

/// Mirrors the audio engine's real decode/buffering state, so the UI can
/// show a loading/buffering indicator instead of a misleading frozen scrubber.
enum ProcessingState { idle, loading, buffering, ready, completed, error }
