# Local patch

Vendored from `android_file_picker` 1.0.2 (the Android backend of
`file_picker`), with one change in
`android/src/main/kotlin/com/mr/flutter/plugin/filepicker/FileUtils.kt`:

The `ACTION_OPEN_DOCUMENT` intent (used for `FileType.any`/`.custom`) now
sets `DocumentsContract.EXTRA_INITIAL_URI` to the external-storage provider's
root, so the picker opens on real internal storage instead of the OS's
"Recent" tab.

## Why

Upstream always opens on "Recent" with no way to change it. On some OEM
builds (confirmed: Samsung OneUI, Galaxy A50) that tab's backing index can be
broken/empty regardless of what's actually on the device, making the picker
look empty even when the user has plenty of files. `EXTRA_INITIAL_URI` is a
standard, documented Android API for hinting a starting location — it's a
suggestion, not a restriction, so it's a no-op on devices where "Recent"
already works fine.

## Removal

Drop this override and delete this folder once upstream exposes a way to set
the picker's starting location for `pickFiles` (only `saveFile` supports
`initialDirectory` as of 1.0.2), or if a real fix for the OEM `Recent`-index
bug ships instead.
