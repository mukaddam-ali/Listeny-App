import 'media_url_resolver.dart';

/// What a pasted URL *looks like*, decided purely from its text — no network
/// access. A classification never implies downloading is permitted or that
/// any resolver will succeed; see [ProviderCapabilityProfile] for policy.
enum UrlClass {
  directAudio,
  directVideo,
  genericWebpage,
  instagram,
  facebook,
  googleDrive,

  /// http(s), but the host isn't a public web domain (bare IP address or a
  /// single-label host such as `localhost`), so it isn't a normal webpage.
  unknownProvider,
  unsupportedScheme,
  embeddedCredentials,
  invalid,
}

/// Extensions accepted as "already points straight at a media file". Shared
/// by [UrlClassifier] and `DirectMediaUrlResolver`. Kept separate from
/// core/audio_formats.dart's supportedAudioExtensions on purpose: that list
/// is "what Listeny can play", this is "what a download link can point at
/// before conversion".
const directMediaExtensionKinds = <String, MediaSourceKind>{
  'mp3': MediaSourceKind.audio,
  'm4a': MediaSourceKind.audio,
  'aac': MediaSourceKind.audio,
  'wav': MediaSourceKind.audio,
  'flac': MediaSourceKind.audio,
  'ogg': MediaSourceKind.audio,
  'mp4': MediaSourceKind.video,
  'webm': MediaSourceKind.video,
};

class UrlClassifier {
  const UrlClassifier();

  static const _instagramHosts = ['instagram.com', 'instagr.am'];
  static const _facebookHosts = ['facebook.com', 'fb.com', 'fb.watch'];
  static const _googleDriveHosts = [
    'drive.google.com',
    'docs.google.com',
    'drive.usercontent.google.com',
  ];

  /// Classifies [raw] (as typed/pasted) without touching the network.
  UrlClass classify(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return UrlClass.invalid;
    final uri = Uri.tryParse(text);
    if (uri == null) return UrlClass.invalid;
    return classifyUri(uri);
  }

  UrlClass classifyUri(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      return UrlClass.unsupportedScheme;
    }
    if (uri.userInfo.isNotEmpty) return UrlClass.embeddedCredentials;
    final host = uri.host.toLowerCase();
    if (host.isEmpty) return UrlClass.invalid;

    // Provider first: a provider link ending in ".mp4" is still that
    // provider's link, not a direct file.
    if (_matches(host, _instagramHosts)) return UrlClass.instagram;
    if (_matches(host, _facebookHosts)) return UrlClass.facebook;
    if (_matches(host, _googleDriveHosts)) return UrlClass.googleDrive;

    final kind = directMediaExtensionKinds[_extensionOf(uri)];
    if (kind == MediaSourceKind.audio) return UrlClass.directAudio;
    if (kind == MediaSourceKind.video) return UrlClass.directVideo;

    if (!host.contains('.') || host.contains(':') || _isIpv4(host)) {
      return UrlClass.unknownProvider;
    }
    return UrlClass.genericWebpage;
  }

  // Query and fragment are already excluded from Uri.path.
  String? _extensionOf(Uri uri) {
    final String path;
    try {
      path = Uri.decodeComponent(uri.path);
    } on ArgumentError {
      return null;
    }
    final lastSegment = path.substring(path.lastIndexOf('/') + 1);
    final dot = lastSegment.lastIndexOf('.');
    if (dot < 0 || dot == lastSegment.length - 1) return null;
    return lastSegment.substring(dot + 1).toLowerCase();
  }

  bool _matches(String host, List<String> domains) =>
      domains.any((d) => host == d || host.endsWith('.$d'));

  bool _isIpv4(String host) =>
      RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(host);
}
