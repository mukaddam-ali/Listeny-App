import 'package:dio/dio.dart';

import 'provider_capability.dart';
import 'url_classifier.dart';

/// What kind of media a resolved URL points at — mainly informs how the
/// Download tab describes what it's doing ("extracting audio from video…")
/// rather than driving conversion decisions directly (see
/// [AudioConversionService], which decides purely from whether the file is
/// already in a format Listeny can play).
enum MediaSourceKind { audio, video }

/// Which resolver handled a link — drives Download History's source label,
/// nothing more (conversion/playback decisions never branch on this).
enum MediaSourceOrigin { direct, googleDrive }

/// Called with every URL (the first request and each redirect target)
/// before it is contacted; throw to refuse it. Lets callers enforce their
/// own destination rules (e.g. provider ownership) inside the shared
/// redirect path.
typedef DestinationPolicy = void Function(Uri url);

/// A single, concrete way to fetch one candidate's bytes — one attempt, not
/// a retry strategy. Several of these can come from one
/// [ByteStreamSourceProvider] when a source might need to fall back from
/// one candidate to another.
abstract class ByteStreamSource {
  /// Total size in bytes, if known — used for progress reporting. Null
  /// means "unknown", which callers should render as indeterminate
  /// progress rather than a stuck 0%.
  int? get contentLength;

  /// This candidate's real file extension (no dot) — candidates from the
  /// same provider can differ (e.g. "m4a" for one, "webm" for a fallback),
  /// so callers must ask this per-candidate rather than assuming it upfront
  /// from whichever candidate was merely *preferred*.
  String get fileExtension;

  /// Opens the byte stream. Must only be called once.
  Stream<List<int>> open();
}

/// A source whose transport can be aborted before awaiting stream cancellation.
abstract class CancellableByteStreamSource implements ByteStreamSource {
  void cancel();
}

/// Supplies an ordered, retry-aware sequence of [ByteStreamSource]
/// candidates for one download attempt. [LinkImportService] tries each
/// candidate [next] returns in turn, falling back to the next one if a
/// candidate is rejected or incomplete — for sources where the
/// initially-preferred stream can occasionally fail to deliver any bytes
/// even though the link itself is perfectly valid.
abstract class ByteStreamSourceProvider {
  /// Returns the next candidate to try, or null once every reasonable
  /// option has been exhausted. May perform real async work between calls
  /// (e.g. waiting briefly and refreshing a manifest).
  Future<ByteStreamSource?> next();

  /// Releases whatever resource every candidate this provider has handed
  /// out depended on (e.g. closes a shared HTTP client) — called once,
  /// after the whole attempt ends, regardless of outcome. Safe to call
  /// even if [next] was never called.
  Future<void> dispose();
}

/// Why a resolver that handled (or was asked to handle) a URL couldn't
/// produce media. [unsupportedLink] means "not mine / not supported"; the
/// rest mean the resolver recognized the link but can't provide media.
enum MediaResolutionFailure {
  unsupportedLink,
  privateContent,
  authenticationRequired,
  downloadNotPermitted,
  mediaUnavailable,
  noMediaFound,
  malformedUrl,

  /// Direct-media transport failures.
  responseTooLarge,
  invalidMediaResponse,
  redirectRejected,
  incompleteDownload,
}

/// How a resolved file's bytes are obtained — transport/source provenance
/// only. This says nothing about whether downloading is legally permitted.
enum MediaAccessBasis {
  /// The URL itself is a publicly reachable media file.
  publicDirectLink,

  /// A provider-specific resolver supplies the bytes via the provider's
  /// own stream/transport.
  providerStream,

  /// Bytes come from a provider's official API under authorization (or an
  /// API key). Transport provenance only - not proof of any right to the
  /// file.
  authorizedProviderApi,
}

/// What a [MediaUrlResolver] figured out about a URL: where the actual
/// media bytes live, what to call the downloaded file, and roughly what
/// kind of media it is.
class ResolvedMedia {
  final Uri downloadUrl;
  final String suggestedFileName;
  final MediaSourceKind kind;

  /// The provider that resolved this link (see [MediaSourceOrigin]).
  final MediaSourceOrigin origin;

  /// The URL as the user pasted it, when the resolver recorded it.
  final Uri? originalUrl;
  final MediaAccessBasis accessBasis;
  final String? mimeType;
  final int? expectedBytes;
  final String? title;
  final String? artist;
  final String? album;
  final Duration? duration;

  /// When [downloadUrl] (or a signed URL behind it) stops working, if known.
  final DateTime? expiresAt;

  /// A thumbnail/cover image (the artwork URL) for the source media, if the
  /// resolver found one — a plain, already-public URL (never signed/expiring),
  /// fetched once and cached locally by [LinkImportService] rather than
  /// depended on remotely afterward. Null for sources with no thumbnail
  /// concept.
  final Uri? thumbnailUrl;

  /// When set, the actual bytes must come from here instead of a plain
  /// HTTP GET on [downloadUrl] — for sources whose CDN needs a fetch
  /// protocol a plain downloader can't replicate. [downloadUrl] is still
  /// populated for reference/display even when this is used.
  final ByteStreamSourceProvider? byteSourceProvider;

  /// Destination rule the actual download must apply to its first request
  /// and every redirect target — set by resolvers whose
  /// resolution-time policy must not be lost between probe and download.
  /// Null for links the user pasted straight to a media file.
  final DestinationPolicy? destinationPolicy;

  /// Extra request headers the download needs (e.g. an official API
  /// authorization header). Dropped by the safe redirect path whenever a
  /// redirect leaves the origin.
  final Map<String, String>? downloadHeaders;

  const ResolvedMedia({
    required this.downloadUrl,
    required this.suggestedFileName,
    required this.kind,
    required this.origin,
    this.originalUrl,
    this.accessBasis = MediaAccessBasis.publicDirectLink,
    this.mimeType,
    this.expectedBytes,
    this.title,
    this.artist,
    this.album,
    this.duration,
    this.expiresAt,
    this.thumbnailUrl,
    this.byteSourceProvider,
    this.destinationPolicy,
    this.downloadHeaders,
  });

  /// This result with [policy] attached to its fetch plan.
  ResolvedMedia withDestinationPolicy(DestinationPolicy policy) =>
      ResolvedMedia(
        downloadUrl: downloadUrl,
        suggestedFileName: suggestedFileName,
        kind: kind,
        origin: origin,
        originalUrl: originalUrl,
        accessBasis: accessBasis,
        mimeType: mimeType,
        expectedBytes: expectedBytes,
        title: title,
        artist: artist,
        album: album,
        duration: duration,
        expiresAt: expiresAt,
        thumbnailUrl: thumbnailUrl,
        byteSourceProvider: byteSourceProvider,
        destinationPolicy: policy,
        downloadHeaders: downloadHeaders,
      );
}

/// Thrown by a [MediaUrlResolver] that recognized a URL but can't provide
/// media for it (or, as [UnsupportedLinkException], doesn't handle it).
/// [MediaUrlResolverRegistry] never falls through to another resolver after
/// one of these.
class MediaResolutionException implements Exception {
  final MediaResolutionFailure failure;
  const MediaResolutionException(this.failure);
}

/// [MediaResolutionFailure.unsupportedLink]: nothing can handle this URL.
class UnsupportedLinkException extends MediaResolutionException {
  const UnsupportedLinkException()
    : super(MediaResolutionFailure.unsupportedLink);
}

/// One strategy for turning a URL the user pasted into an actual
/// downloadable media file.
abstract class MediaUrlResolver {
  /// Cheap, pure check (no network) for whether this resolver handles
  /// [url]. Once true, the resolver owns the outcome: failures propagate.
  bool supports(Uri url);

  /// Resolves [url]. Throws [MediaResolutionException] (or
  /// [UnsupportedLinkException]) if it can't provide media. Any network
  /// work must honor [cancelToken]; a cancelled resolve throws
  /// `DownloadCancelledException`.
  Future<ResolvedMedia> resolve(Uri url, {CancelToken? cancelToken});
}

/// Picks the first resolver (in list order) whose [MediaUrlResolver.supports]
/// accepts the URL and returns its result — or its failure.
class MediaUrlResolverRegistry {
  final List<MediaUrlResolver> resolvers;

  /// Optional capability policy. When set, a URL whose class the profile
  /// doesn't allow is refused outright — it never reaches any resolver, so
  /// a disabled provider can't fall through into the direct catch-all. Null (the default) applies no policy.
  final ProviderCapabilityProfile? profile;

  const MediaUrlResolverRegistry(this.resolvers, {this.profile});

  /// Why [url] is refused by policy, or null when it may proceed.
  MediaResolutionFailure? blockedBy(Uri url) {
    final policy = profile;
    if (policy == null) return null;
    final urlClass = const UrlClassifier().classifyUri(url);
    if (policy.allows(urlClass)) return null;
    switch (urlClass) {
      case UrlClass.instagram:
      case UrlClass.facebook:
      case UrlClass.googleDrive:
        return MediaResolutionFailure.downloadNotPermitted;
      default:
        return MediaResolutionFailure.unsupportedLink;
    }
  }

  /// The resolver that would handle [url], or null if none does (or policy
  /// refuses it).
  MediaUrlResolver? select(Uri url) {
    if (blockedBy(url) != null) return null;
    for (final resolver in resolvers) {
      if (resolver.supports(url)) return resolver;
    }
    return null;
  }

  /// Throws [UnsupportedLinkException] if no resolver supports [url]; any
  /// failure from the selected resolver propagates unchanged.
  Future<ResolvedMedia> resolve(Uri url, {CancelToken? cancelToken}) async {
    final blocked = blockedBy(url);
    if (blocked == MediaResolutionFailure.unsupportedLink) {
      throw const UnsupportedLinkException();
    }
    if (blocked != null) throw MediaResolutionException(blocked);
    final resolver = select(url);
    if (resolver == null) throw const UnsupportedLinkException();
    return resolver.resolve(url, cancelToken: cancelToken);
  }
}
