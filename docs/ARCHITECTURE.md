# How it's built

A tour of the code for anyone who wants to read it or contribute.

## Layout

```
lib/
├── main.dart                 Shows a themed loading screen straight away, then
│                             wires up the database, audio engine and services
│                             in the background so a slow device never looks frozen.
├── app/                      Root MaterialApp, the bottom-nav shell (one
│                             Navigator per tab) and the mini-player, plus the
│                             Nocturne theme tokens.
├── core/
│   ├── models/               The Track model.
│   ├── storage/              Drift database and migrations.
│   ├── diagnostics/          Startup and frame-timing instrumentation.
│   └── audio_formats.dart    The list of supported extensions.
├── playback/                 Everything about playing audio. Screens talk to
│                             the PlaybackService interface and never touch
│                             just_audio or audio_service types directly.
├── library/                  Import, download, conversion and sync logic, and
│                             the LibraryRepository every screen reads from.
├── features/                 One folder per screen: library, album, artist,
│                             playlists, queue, search, now_playing, download,
│                             import, trim, settings.
├── shared/                   Widgets reused across screens (song rows, context
│                             menu, artwork, bulk actions).
└── l10n/                     Translation files and generated localizations.

android/.../MainActivity.kt   Native side: the MediaStore queries, publishing
                              downloads to Music/Listeny, and deleting files.
third_party/                  Vendored, patched dependencies.
tool/                         Build helpers.
test/                         Unit and widget tests, mirroring lib/.
```

## Internals

### Playback

`ListenyAudioHandler` is the real `audio_service` handler. It owns the foreground service, the MediaSession and the queue, and drives `just_audio`. `AudioServicePlaybackService` adapts that to the app's own `PlaybackService` interface, which is all the UI ever sees. That separation is why most of the playback logic can be tested without a device.

Playback state (what was playing, and where) is saved by `PlaybackStatePersistence`. Plays are counted through a small gate that ignores metadata-only refreshes of the same track, so renaming an album doesn't inflate the play count.

### Import

Every way of getting audio in ends up in the same `ImportService`: read the tags and artwork, check for duplicates, then write the track. Tags and artwork are parsed with a pure-Dart reader on purpose, to avoid another native plugin that might crash on one manufacturer's phones. Only artwork that decodes as a real image is kept.

### Link downloads

`LinkImportService` runs one link from start to finish: resolve it, stream the bytes to a scratch file (with a first-byte timeout and cancel), convert to MP3 with FFmpeg if needed, grab a thumbnail as fallback artwork, then import. A list of resolvers decides how each kind of link is handled (a direct link to an audio or video file, or a public Google Drive file). On Android 11+ the final MP3 is published to `Music/Listeny` and imported by reference. If the import turns out to be a duplicate, that published file is removed again so nothing is left behind. Every attempt, success or failure, goes into the download history.

Anything else, including links to streaming sites and social networks, is refused as an unsupported link.

### Library sync

`LocalLibrarySyncService` asks MediaStore for the device's MP3s, a page at a time and one storage volume at a time, and adds each as a reference to the original file. Nothing is copied and nothing is ever deleted by a scan. It remembers every item it has looked at by a stable identity (volume plus MediaStore id, never a file name), so repeat syncs only look at what's new. It detects moved files, compares content byte-for-byte before calling something a duplicate, and handles reused ids safely. It reports Android 10 as unsupported rather than guessing, because scoped storage there blocks the path-based reads the app relies on.

### Why not the system file picker on Android?

The stock picker (`com.android.documentsui`) throws `SecurityException: ...CACHE_CONTENT` on some Work Profile / Knox configurations. Device logs showed it's a system-app bug, not something application code can fix. Instead of depending on something that can take the whole app down, `MainActivity.kt` queries `MediaStore.Audio.Media` itself and the app shows its own folder browser. It's also the scoped-storage-correct way to list audio without asking for the broad `MANAGE_EXTERNAL_STORAGE` permission.

## Design system

The UI follows a design called Nocturne, ported from the HTML prototype in this repo (`design/Music Player - Screen Board.dc.html` and `design/_ds/`). The original is dark-only. Light mode is derived by flipping which end of each tonal ramp plays the "near background" role, so every color token is right in both themes without each widget handling it.

- Background `#161826` dark / `#F4F5FA` light; accent `#9184D9` dark / `#6A5CD0` light.
- Inter, bundled as a variable font, so there are no network font fetches.
- A compact spacing scale and small, consistent corner radii (`lib/app/theme/`).
- Tracks with no embedded artwork get a gradient generated from the title and artist, so the same song always looks the same.

## Tests and CI

```bash
flutter analyze
flutter test
```

The suite covers the import and download pipeline, URL resolvers, the library sync (including its safety rules), the database migrations, playback behaviour and a good part of the UI.

`codemagic.yaml` defines three workflows:

| Workflow | What it does | Trigger |
|---|---|---|
| `ios-simulator-build` | `flutter analyze`, then an unsigned iOS release build | Push to `main` |
| `ios-device-unsigned-ipa` | Builds an unsigned device IPA for sideloading with Sideloadly | Push to `main` |
| `android-apk` | Builds the universal release APK | Manual |

None of them need an Apple Developer account.
