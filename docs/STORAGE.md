# Storage and permissions

Where Listeny keeps your files, and which permissions it needs. Short version: you can use the app without ever granting storage access.

| How the track got in | Where the file lives | Permission needed |
|---|---|---|
| Picked from the device, or extracted from a video | A copy in the app's own storage. The original is never touched. | None |
| Downloaded from a link, Android 11 and newer | One file in `Music/Listeny`, published through MediaStore. The library points at it; there is no second copy. | None |
| Downloaded from a link, Android 10 and older, or non-MP3 output | A copy in the app's own storage | None |
| Found by library sync | The original file, referenced in place | Audio access (`READ_MEDIA_AUDIO`) |

A few consequences worth knowing:

- **You can use the app without ever granting audio access.** Downloads and manual imports work with no permission. The app only asks when it tries to sync the device library, and if you say no it doesn't keep nagging. You can still run "Sync Library" from Settings later.
- **Downloads on Android 11+ are owned by the app.** Because Listeny created the file, Android lets it read, play and delete it without any storage permission, and it can't see your other recordings or audio. The file also shows up in file managers and other music players.
- **The sync recognises those downloads.** Each one is registered under its MediaStore identity, so if you grant access later the sync skips it instead of adding it twice.
- **Uninstalling keeps the files but not the library.** Files in `Music/Listeny` stay on the phone after you uninstall. The library itself (favorites, play counts, playlists) lived inside the app and goes with it. After reinstalling you need to grant audio access once so a sync can pick the old downloads up again, because the new install no longer owns them.
- **If a referenced file is deleted from outside the app** (a file manager, say), its track stays in the library but won't play. Rescan only cleans up copies the app made itself.
- **iOS** has no shared Music folder. Files live in the app's Documents folder, which is switched on for the Files app, so you can see them there.
