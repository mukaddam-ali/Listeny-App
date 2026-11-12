import 'package:flutter_test/flutter_test.dart';
import 'package:listeny/library/provider_capability.dart';
import 'package:listeny/library/url_classifier.dart';

void main() {
  const c = UrlClassifier();

  group('UrlClassifier', () {
    test('valid http and https webpages', () {
      expect(c.classify('http://example.com/page'), UrlClass.genericWebpage);
      expect(c.classify('https://example.com/page'), UrlClass.genericWebpage);
    });

    test('invalid and unsupported', () {
      expect(c.classify(''), UrlClass.invalid);
      expect(c.classify('http://'), UrlClass.invalid);
      expect(c.classify('http://[::1'), UrlClass.invalid);
      expect(c.classify('ftp://example.com/a.mp3'), UrlClass.unsupportedScheme);
      expect(c.classify('file:///a.mp3'), UrlClass.unsupportedScheme);
      expect(c.classify('song.mp3'), UrlClass.unsupportedScheme);
    });

    test('embedded credentials', () {
      expect(
        c.classify('https://user:pw@example.com/a.mp3'),
        UrlClass.embeddedCredentials,
      );
    });

    test('direct media by extension, case, query, fragment, encoding', () {
      expect(c.classify('https://x.com/song.mp3'), UrlClass.directAudio);
      expect(c.classify('https://x.com/SONG.MP3'), UrlClass.directAudio);
      expect(
        c.classify('https://x.com/song.mp3?token=x'),
        UrlClass.directAudio,
      );
      expect(c.classify('https://x.com/song.mp3#t=5'), UrlClass.directAudio);
      expect(c.classify('https://x.com/my%20song.mp3'), UrlClass.directAudio);
      expect(c.classify('https://x.com/v.mp4'), UrlClass.directVideo);
      expect(c.classify('https://x.com/page?f=a.mp3'), UrlClass.genericWebpage);
    });

    test('providers, including subdomains', () {
      expect(
        c.classify('https://www.instagram.com/reel/abc/'),
        UrlClass.instagram,
      );
      expect(
        c.classify('https://www.facebook.com/reel/123'),
        UrlClass.facebook,
      );
      expect(
        c.classify('https://drive.google.com/file/d/1/view'),
        UrlClass.googleDrive,
      );
    });

    test('provider detection takes precedence over extension', () {
      expect(
        c.classify('https://drive.google.com/uc/song.mp3'),
        UrlClass.googleDrive,
      );
      expect(c.classify('https://www.instagram.com/v.mp4'), UrlClass.instagram);
    });

    test('non-public hosts are unknownProvider', () {
      expect(c.classify('http://localhost/a'), UrlClass.unknownProvider);
      expect(c.classify('http://192.168.1.2/a'), UrlClass.unknownProvider);
    });
  });

  group('ProviderCapabilityProfile', () {
    test('currentRuntime allows importable classes only', () {
      const p = ProviderCapabilityProfile.currentRuntime;
      expect(p.allows(UrlClass.directAudio), isTrue);
      expect(p.allows(UrlClass.genericWebpage), isTrue);
      expect(p.allows(UrlClass.invalid), isFalse);
      expect(p.allows(UrlClass.embeddedCredentials), isFalse);
      expect(p.allows(UrlClass.unsupportedScheme), isFalse);
    });

    test('restricted profile is deterministic', () {
      const p = ProviderCapabilityProfile.only({UrlClass.directAudio});
      expect(p.allows(UrlClass.directAudio), isTrue);
      expect(p.allows(UrlClass.googleDrive), isFalse);
    });
  });
}
