import 'media_url_resolver.dart';
import 'provider_capability.dart';
import 'url_classifier.dart';

/// URL classes that belong to a provider-specific resolver. A generic
/// resolver must never contact, probe or hand off URLs of these classes.
const knownProviderClasses = {
  UrlClass.instagram,
  UrlClass.facebook,
  UrlClass.googleDrive,
};

/// Pure check on whether [url] is owned by a known provider (per
/// [UrlClassifier], the single source of host knowledge).
bool isKnownProviderUrl(Uri url) =>
    knownProviderClasses.contains(const UrlClassifier().classifyUri(url));

/// Throws unless [url] is free of provider ownership: a disabled provider
/// (per [profile]) is `downloadNotPermitted`; otherwise it is simply not
/// something a generic resolver may handle (`unsupportedLink`). Apply to
/// every URL before it is contacted — the pasted URL, each redirect hop,
/// each candidate, and any handoff target.
void enforceNotProviderOwned(Uri url, {ProviderCapabilityProfile? profile}) {
  final urlClass = const UrlClassifier().classifyUri(url);
  if (!knownProviderClasses.contains(urlClass)) return;
  if (profile != null && !profile.allows(urlClass)) {
    throw const MediaResolutionException(
      MediaResolutionFailure.downloadNotPermitted,
    );
  }
  throw const UnsupportedLinkException();
}
