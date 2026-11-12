# Local patch

Vendored from `audio_metadata_reader` 1.7.1, with changes in
`lib/src/parsers/tags/id3v2.dart` and `lib/src/parsers/tags/id3v1.dart`.

## Why

Real imported files were showing Chinese/Japanese-looking characters in the
title/artist/album fields of tracks whose actual tags were plain Latin text.
The root cause was in upstream's ID3v2 text decoding
(`getTextFromFrame`/`TXXXFrame`/`getUnsynchronisedLyric`, which back
TALB/TIT2/TPE1/TPE2/... — album, title, artist, etc.):

- ID3v2's text encoding byte can be 0 (Latin-1), 1 (UTF-16 with a leading
  byte-order mark), 2 (UTF-16BE, no BOM — added in ID3v2.4) or 3 (UTF-8).
  Upstream's encoding-1 path always decoded as little-endian, ignoring
  whatever endianness the BOM actually declared. A big-endian-BOM value
  decoded as little-endian comes out byte-swapped, and byte-swapping
  ordinary Latin code points lands them inside the CJK Unified Ideographs
  Unicode block (e.g. 'A' is U+0041; swapped, U+4100) — exactly the
  "Chinese/Japanese-looking" symptom reported.
- Upstream's encoding-2 path *also* always decoded as little-endian instead
  of the big-endian the spec requires for that encoding.
- The UTF-16 double-null terminator scan wasn't 2-byte aligned relative to
  where the actual character data starts (i.e. past any BOM), so a single
  0x00 byte landing at an odd offset — the low or high byte of a non-Latin
  BMP character below U+0100, which happens for plenty of real-world
  scripts — could be mistaken for half the terminator and truncate genuine
  text.
- `TXXXFrame` and `getUnsynchronisedLyric` each reimplemented this same
  logic independently, with their own variants of the same bugs.
- Separately, in `id3v1.dart` (ID3v1 has no per-tag encoding byte at all —
  the spec is always Latin-1), `_extract` decoded as UTF-8 whenever a null
  terminator happened to be found before the field's end, and Latin-1
  otherwise. Besides being spec-inconsistent, `utf8.decode` throws on a
  byte sequence that isn't valid UTF-8 — which ordinary accented Latin-1
  text (e.g. 'é' = a lone 0xE9) very often isn't — a real crash risk on the
  terminated-before-`end` path.

## What changed

`id3v2.dart` now has one shared, tested decode path
(`decodeId3TextValue`/`_decodeId3Utf16`) that every text-reading call site
goes through: it detects the actual BOM for encoding 1, decodes encoding 2 as
big-endian per spec, aligns the terminator scan to the real start of
character data, and trims a stray trailing odd byte on a truncated/malformed
value instead of handing the decoder half a character. `TXXXFrame` and
`getUnsynchronisedLyric` were rewritten on top of it instead of keeping their
own copies of the same logic.

`id3v1.dart`'s `_extract` always decodes as Latin-1 now, matching the spec —
never throws (every byte 0-255 is a valid Latin-1 code point), and is
byte-identical to the old UTF-8 path for plain ASCII text (the common case),
so this is a strict improvement, not just a behavior change.

Genuine non-Latin metadata (real Chinese/Japanese/Arabic/etc. tags, correctly
encoded per spec) is unaffected — nothing here rejects or second-guesses a
correctly-decoded non-Latin script; the fix is purely about picking the
*correct* decoder for the encoding byte/BOM that's actually present.

## Removal

Drop this override and delete this folder once upstream fixes ID3v2 UTF-16
BOM/encoding-2 decoding and ID3v1's encoding inconsistency (tracked upstream
at https://github.com/ClementBeal/audio_metadata_reader/issues — no fix
merged as of 1.7.1) and a fixed release is published.
