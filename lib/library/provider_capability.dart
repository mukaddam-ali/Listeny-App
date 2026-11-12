import 'url_classifier.dart';

/// A pure allow-list of [UrlClass]es a build/platform may import from. Lets
/// store- or platform-specific policy live in one value (e.g. an
/// "approved providers only" profile) instead of scattered platform checks.
/// Nothing consults this at runtime yet: Phase A keeps every provider on.
class ProviderCapabilityProfile {
  final Set<UrlClass> _enabled;

  const ProviderCapabilityProfile.only(Set<UrlClass> enabled)
    : _enabled = enabled;

  /// Every class that can currently be imported — today's runtime behavior.
  static const currentRuntime = ProviderCapabilityProfile.only({
    UrlClass.directAudio,
    UrlClass.directVideo,
    UrlClass.genericWebpage,
    UrlClass.instagram,
    UrlClass.facebook,
    UrlClass.googleDrive,
    UrlClass.unknownProvider,
  });

  /// Whether URLs of class [urlClass] may be imported under this profile.
  /// Rejected classes (bad scheme, credentials, invalid) are never allowed.
  bool allows(UrlClass urlClass) => _enabled.contains(urlClass);
}
