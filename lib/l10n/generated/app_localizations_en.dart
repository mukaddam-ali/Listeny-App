// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonPlay => 'Play';

  @override
  String get commonPause => 'Pause';

  @override
  String get commonShuffle => 'Shuffle';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDone => 'Done';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonAddToPlaylistTooltip => 'Add to Playlist';

  @override
  String commonSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String commonTrackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks',
      one: '1 track',
    );
    return '$_temp0';
  }

  @override
  String get commonNoFavoritesYet =>
      'No favorites yet. Tap the heart on a track to add one.';

  @override
  String get commonRemoveFromLibrary => 'Remove from Library';

  @override
  String get commonDeleteFromDevice => 'Delete from Device';

  @override
  String get commonNextTrack => 'Next track';

  @override
  String get commonSearchTooltip => 'Search';

  @override
  String get commonImportTooltip => 'Import';

  @override
  String get navLibrary => 'Library';

  @override
  String get navPlaylists => 'Playlists';

  @override
  String get navSearch => 'Search';

  @override
  String get navDownload => 'Download';

  @override
  String get navSettings => 'Settings';

  @override
  String get formatJustNow => 'Just now';

  @override
  String formatMinutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String formatHoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String formatDaysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String formatHoursMinutes(int hours, int minutes) {
    return '$hours hr $minutes min';
  }

  @override
  String formatMinutesOnly(int minutes) {
    return '$minutes min';
  }

  @override
  String get libraryTitle => 'Library';

  @override
  String get libraryExitSelectionTooltip => 'Exit selection';

  @override
  String get libraryRecentlyAdded => 'Recently added';

  @override
  String get libraryFilterTracks => 'Tracks';

  @override
  String get libraryFilterAlbums => 'Albums';

  @override
  String get libraryFilterRecentlyPlayed => 'Recently Played';

  @override
  String get libraryFilterFavorites => 'Favorites';

  @override
  String get libraryRecentlyPlayedEmpty => 'Tracks you play will appear here';

  @override
  String get libraryEmptyTitle => 'No tracks yet';

  @override
  String get libraryEmptyBody =>
      'Import audio from the Files app to start building your library.';

  @override
  String get libraryImportAudioButton => 'Import Audio';

  @override
  String get libraryPrivacyNote => 'Your library stays on your device.';

  @override
  String get artistEyebrow => 'ARTIST';

  @override
  String artistAlbumCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count albums',
      one: '1 album',
    );
    return '$_temp0';
  }

  @override
  String get artistMostPlayed => 'Most played';

  @override
  String get artistAlbumsHeader => 'Albums';

  @override
  String get searchHint => 'Tracks, albums, artists';

  @override
  String get searchEmptyLibrary =>
      'Import audio to start building your library.';

  @override
  String get searchNoResults => 'No results';

  @override
  String get searchContextLabel => 'Search';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSyncLibrary => 'Sync Library';

  @override
  String get settingsSyncLibraryRunning => 'Syncing… tap to stop';

  @override
  String get syncLibraryUpToDate => 'Library synced — no new MP3 files found.';

  @override
  String syncLibraryAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count tracks from your device.',
      one: 'Added 1 track from your device.',
    );
    return '$_temp0';
  }

  @override
  String get syncLibraryStopped =>
      'Sync stopped. Tracks found so far were kept.';

  @override
  String get syncLibraryPermissionDenied =>
      'Allow audio access to sync music from your device.';

  @override
  String get syncLibraryUnsupported =>
      'Automatic sync isn\'t supported on Android 10. Use Import instead.';

  @override
  String get syncLibraryFailed => 'Sync couldn\'t finish. Try again.';

  @override
  String get settingsStorageUsed => 'Storage Used';

  @override
  String get settingsSectionPlayback => 'Playback';

  @override
  String get settingsRememberPosition => 'Remember Playback Position';

  @override
  String get settingsKeepPlayingWhenClosed => 'Keep playing when app is closed';

  @override
  String get settingsSectionDebug => 'Debug (debug builds only)';

  @override
  String get settingsImportTestFiles => 'Import pushed test files';

  @override
  String settingsDebugAddedSkipped(int added, int skipped) {
    return 'Added $added, skipped $skipped';
  }

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsFooterNote =>
      'Imported tracks are stored locally. Downloads require internet access.';

  @override
  String get settingsAppearance => 'APPEARANCE';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get newPlaylistTitle => 'New Playlist';

  @override
  String get newPlaylistCreate => 'Create';

  @override
  String get newPlaylistNameHint => 'Playlist name';

  @override
  String get newPlaylistArtworkHintChange => 'Tap the cover to change it.';

  @override
  String get newPlaylistArtworkHintAdd =>
      'Tap the cover to add a photo, or leave it and one will be generated from the tracks you add.';

  @override
  String get playlistDeleted => 'Playlist deleted';

  @override
  String get playlistMenuRename => 'Rename';

  @override
  String get playlistMenuChangeArtwork => 'Change Artwork';

  @override
  String get playlistMenuRemoveArtwork => 'Remove Artwork';

  @override
  String get playlistMenuDeletePlaylist => 'Delete Playlist';

  @override
  String playlistCreatedOn(String date) {
    return 'Created $date';
  }

  @override
  String get playlistAddTracksButton => 'Add tracks';

  @override
  String get playlistEmptyTracks =>
      'No tracks yet — tap \"Add tracks\" to build this playlist.';

  @override
  String get playlistRenameDialogTitle => 'Rename Playlist';

  @override
  String get playlistDeleteDialogTitle => 'Delete Playlist?';

  @override
  String playlistDeleteDialogBody(String name) {
    return '\"$name\" will be deleted. Tracks stay in your library.';
  }

  @override
  String get playlistsPickTracksLater => 'Pick tracks later';

  @override
  String get queueTitle => 'Queue';

  @override
  String get queueNowPlaying => 'NOW PLAYING';

  @override
  String get queuePlayingNext => 'PLAYING NEXT';

  @override
  String get queueNothingQueued => 'Nothing queued next.';

  @override
  String queueThenContinuesFrom(String source) {
    return 'THEN CONTINUES FROM $source';
  }

  @override
  String get nowPlayingNothingPlaying => 'Nothing playing';

  @override
  String nowPlayingFrom(String source) {
    return 'PLAYING FROM $source';
  }

  @override
  String get nowPlayingMoreOptionsTooltip => 'More options';

  @override
  String get nowPlayingAddFavoriteTooltip => 'Add to favorites';

  @override
  String get nowPlayingRemoveFavoriteTooltip => 'Remove from favorites';

  @override
  String get nowPlayingPreviousTrackTooltip => 'Previous track';

  @override
  String get nowPlayingShuffleOn => 'Shuffle: on';

  @override
  String get nowPlayingShuffleOff => 'Shuffle: off';

  @override
  String get nowPlayingRepeatTrack => 'Track';

  @override
  String get nowPlayingRepeatQueue => 'Queue';

  @override
  String get nowPlayingPlaybackDeviceTooltip => 'Playback device';

  @override
  String get nowPlayingPlaybackDeviceMessage =>
      'Use your device\'s Bluetooth/output settings to switch playback devices.';

  @override
  String get nowPlayingRewind10Tooltip => 'Rewind 10 seconds';

  @override
  String get nowPlayingForward10Tooltip => 'Forward 10 seconds';

  @override
  String bulkAddToPlaylistTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $count tracks to Playlist',
      one: 'Add to Playlist',
    );
    return '$_temp0';
  }

  @override
  String bulkDeleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count tracks?',
      one: 'Delete 1 track?',
    );
    return '$_temp0';
  }

  @override
  String get bulkDeleteChooseHow => 'Choose how to remove them.';

  @override
  String get contextMenuPlayNow => 'Play Now';

  @override
  String get contextMenuPlayNext => 'Play Next';

  @override
  String get contextMenuAddToQueue => 'Add to Queue';

  @override
  String get contextMenuAddToPlaylistEllipsis => 'Add to Playlist…';

  @override
  String get contextMenuFavorite => 'Favorite';

  @override
  String get contextMenuRemoveFavorite => 'Remove Favorite';

  @override
  String get contextMenuViewAlbum => 'View Album';

  @override
  String get contextMenuViewArtist => 'View Artist';

  @override
  String get renameTrackDialogTitle => 'Rename track';

  @override
  String get renameTrackHint => 'Title';

  @override
  String get renameAlbumDialogTitle => 'Rename album';

  @override
  String get renameAlbumHint => 'Album name';

  @override
  String renameAlbumCollisionMessage(String name, String albumArtist) {
    return 'An album named \"$name\" by $albumArtist already exists.';
  }

  @override
  String get deleteFromDeviceDialogTitle => 'Delete from device?';

  @override
  String deleteFromDeviceDialogBody(String title) {
    return '\"$title\" will be permanently deleted and can\'t be recovered.';
  }

  @override
  String get miniPlayerDismissTooltip => 'Dismiss';

  @override
  String get songRowOptionsTooltip => 'Track options';

  @override
  String songRowDeleteDialogTitle(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get deviceBrowserTitle => 'Choose Audio';

  @override
  String deviceBrowserImportButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Import $count tracks',
      one: 'Import 1 track',
    );
    return '$_temp0';
  }

  @override
  String get deviceBrowserPermissionTitle => 'Audio access needed';

  @override
  String get deviceBrowserPermissionMessage =>
      'Listeny needs permission to see audio files on your device. Grant it in Settings to browse and import your audio.';

  @override
  String get deviceBrowserOpenSettings => 'Open Settings';

  @override
  String get deviceBrowserErrorTitle => 'Couldn\'t read your audio';

  @override
  String get deviceBrowserUnknownError => 'An unknown error occurred.';

  @override
  String get deviceBrowserRetry => 'Retry';

  @override
  String get deviceBrowserNoAudioTitle => 'No audio files found';

  @override
  String get deviceBrowserNoAudioMessage =>
      'Add audio to your device (downloads, transfers, etc.) and pull to retry.';

  @override
  String get deviceBrowserSearchHint => 'Search your audio';

  @override
  String get deviceBrowserNoMatches => 'No matches';

  @override
  String get deviceBrowserSelectAll => 'Select all';

  @override
  String get deviceBrowserDeselectAll => 'Deselect all';

  @override
  String get importFlowContextWhatsNew => 'What\'s new';

  @override
  String get importFlowImportingTitle => 'Importing audio';

  @override
  String importFlowProcessedOfTotal(int processed, int total) {
    return '$processed of $total files · reading metadata';
  }

  @override
  String get importFlowCopiedNote =>
      'Copied into the app — originals untouched.';

  @override
  String importFlowAddedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks added',
      one: '1 track added',
    );
    return '$_temp0';
  }

  @override
  String importFlowArtistsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count artists',
      one: '1 artist',
    );
    return '$_temp0';
  }

  @override
  String importFlowDuplicatesSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count duplicates skipped',
      one: '1 duplicate skipped',
    );
    return '$_temp0';
  }

  @override
  String get importFlowAlreadyInLibrary => 'Already in your library';

  @override
  String importFlowUnsupportedSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files not supported',
      one: '1 file not supported',
    );
    return '$_temp0';
  }

  @override
  String importFlowCorruptSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files could not be read',
      one: '1 file could not be read',
    );
    return '$_temp0';
  }

  @override
  String get importFlowPlayWhatsNew => 'Play what\'s new';

  @override
  String get downloadInstructions =>
      'Paste a direct link to an audio or video file — MP3, M4A, AAC, WAV, FLAC, OGG, MP4, WebM.';

  @override
  String get downloadUrlHint => 'https://example.com/track.mp3';

  @override
  String get downloadPasteTooltip => 'Paste';

  @override
  String get downloadInvalidUrlError => 'Paste a valid link to a media file.';

  @override
  String get downloadFormatLabel => 'Format';

  @override
  String get downloadFormatBestAvailable => 'Best available audio';

  @override
  String get downloadFormatMp3 => 'MP3';

  @override
  String get downloadAnotherButton => 'Download another';

  @override
  String get downloadAudioButton => 'Download Audio';

  @override
  String get downloadResolvingLink => 'Resolving link…';

  @override
  String get downloadDownloadingIndeterminate => 'Downloading…';

  @override
  String downloadDownloadingPercent(int percent) {
    return 'Downloading $percent%';
  }

  @override
  String get downloadConverting => 'Converting…';

  @override
  String get downloadImporting => 'Importing into your library…';

  @override
  String get downloadCancelled => 'Cancelled.';

  @override
  String get downloadQueued => 'Waiting for a free slot…';

  @override
  String get downloadRemoveTooltip => 'Remove';

  @override
  String get downloadGenericError => 'Something went wrong. Please try again.';

  @override
  String downloadAddedToLibrary(String title) {
    return '✓ Added to your library\n$title';
  }

  @override
  String get downloadNothingNewAdded =>
      'This link didn\'t add anything new to your library.';

  @override
  String get downloadHistoryTitle => 'Download History';

  @override
  String get downloadHistoryEmpty => 'Your download history will appear here.';

  @override
  String get downloadClearHistoryDialogTitle => 'Clear download history?';

  @override
  String get downloadClearHistoryDialogBody =>
      'This only clears the history list — it does not remove any tracks.';

  @override
  String get downloadSourceDirectLink => 'Direct link';

  @override
  String get trimMenuLabel => 'Trim';

  @override
  String get trimTitle => 'Trim audio';

  @override
  String get trimStartLabel => 'Start';

  @override
  String get trimEndLabel => 'End';

  @override
  String get trimLengthLabel => 'Length';

  @override
  String get trimPreviewFromLabel => 'Preview from';

  @override
  String get trimPreview => 'Preview';

  @override
  String get trimStopPreview => 'Stop preview';

  @override
  String get trimFadeLabel => 'Fade in / out';

  @override
  String get trimFadeOff => 'Off';

  @override
  String get trimSaveNew => 'Save as new track';

  @override
  String get trimReplaceOriginal => 'Replace original';

  @override
  String get trimSaved => 'Trimmed track saved';

  @override
  String get trimReplaced => 'Original replaced with the trimmed track';

  @override
  String get trimFailed => 'Could not trim this file';

  @override
  String get trimTooShort => 'Pick at least one second';

  @override
  String get trimDuplicate => 'This trimmed track is already in your library';

  @override
  String get trimWorking => 'Trimming…';

  @override
  String get importVideoButton => 'Import video as MP3';

  @override
  String get importVideoConverting => 'Converting video to MP3…';

  @override
  String get importVideoDone => 'Added to your library as MP3';

  @override
  String get importVideoFailed => 'Could not extract audio from this video';

  @override
  String get importVideoDuplicate => 'This track is already in your library';

  @override
  String get importVideoFromGallery => 'From Photos / Gallery';

  @override
  String get importVideoFromFiles => 'From Files';

  @override
  String get importVideoNameTitle => 'Name this track';

  @override
  String get importVideoNameHint => 'Track name';
}
