/// The audio file extensions Listeny can actually decode and play, matching
/// what the design's own error screens promise ("iOS cannot decode Ogg
/// Vorbis. Supported: MP3, M4A, AAC, WAV, FLAC, AIFF.").
const supportedAudioExtensions = [
  'mp3',
  'm4a',
  'aac',
  'wav',
  'flac',
  'aif',
  'aiff',
];

String extensionOf(String fileName) =>
    fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';

bool isSupportedAudioFile(String fileName) =>
    supportedAudioExtensions.contains(extensionOf(fileName));
