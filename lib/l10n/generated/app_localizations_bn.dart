// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get commonPlay => 'চালান';

  @override
  String get commonPause => 'বিরতি';

  @override
  String get commonShuffle => 'শাফল';

  @override
  String get commonCancel => 'বাতিল';

  @override
  String get commonSave => 'সংরক্ষণ করুন';

  @override
  String get commonDone => 'সম্পন্ন';

  @override
  String get commonClear => 'সাফ করুন';

  @override
  String get commonDelete => 'মুছুন';

  @override
  String get commonAddToPlaylistTooltip => 'প্লেলিস্টে যোগ করুন';

  @override
  String commonSelectedCount(int count) {
    return '$countটি নির্বাচিত';
  }

  @override
  String commonTrackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি ট্র্যাক',
      one: '১টি ট্র্যাক',
    );
    return '$_temp0';
  }

  @override
  String get commonNoFavoritesYet =>
      'এখনও কোনো প্রিয় নেই। কোনো ট্র্যাক যোগ করতে হৃদয় আইকনে ট্যাপ করুন।';

  @override
  String get commonRemoveFromLibrary => 'লাইব্রেরি থেকে সরান';

  @override
  String get commonDeleteFromDevice => 'ডিভাইস থেকে মুছুন';

  @override
  String get commonNextTrack => 'পরবর্তী ট্র্যাক';

  @override
  String get commonSearchTooltip => 'খুঁজুন';

  @override
  String get commonImportTooltip => 'ইম্পোর্ট করুন';

  @override
  String get navLibrary => 'লাইব্রেরি';

  @override
  String get navPlaylists => 'প্লেলিস্ট';

  @override
  String get navSearch => 'খুঁজুন';

  @override
  String get navDownload => 'ডাউনলোড';

  @override
  String get navSettings => 'সেটিংস';

  @override
  String get formatJustNow => 'এইমাত্র';

  @override
  String formatMinutesAgo(int minutes) {
    return '$minutes মিনিট আগে';
  }

  @override
  String formatHoursAgo(int hours) {
    return '$hours ঘণ্টা আগে';
  }

  @override
  String formatDaysAgo(int days) {
    return '$days দিন আগে';
  }

  @override
  String formatHoursMinutes(int hours, int minutes) {
    return '$hours ঘ $minutes মি';
  }

  @override
  String formatMinutesOnly(int minutes) {
    return '$minutes মি';
  }

  @override
  String get libraryTitle => 'লাইব্রেরি';

  @override
  String get libraryExitSelectionTooltip => 'নির্বাচন থেকে বেরিয়ে আসুন';

  @override
  String get libraryRecentlyAdded => 'সম্প্রতি যোগ করা হয়েছে';

  @override
  String get libraryFilterTracks => 'ট্র্যাক';

  @override
  String get libraryFilterAlbums => 'অ্যালবাম';

  @override
  String get libraryFilterRecentlyPlayed => 'সম্প্রতি চালানো হয়েছে';

  @override
  String get libraryFilterFavorites => 'প্রিয়';

  @override
  String get libraryRecentlyPlayedEmpty =>
      'আপনি যে ট্র্যাকগুলো চালাবেন সেগুলো এখানে দেখা যাবে';

  @override
  String get libraryEmptyTitle => 'এখনও কোনো ট্র্যাক নেই';

  @override
  String get libraryEmptyBody =>
      'আপনার লাইব্রেরি তৈরি শুরু করতে ফাইলস অ্যাপ থেকে অডিও ইম্পোর্ট করুন।';

  @override
  String get libraryImportAudioButton => 'অডিও ইম্পোর্ট করুন';

  @override
  String get libraryPrivacyNote => 'আপনার লাইব্রেরি আপনার ডিভাইসেই থাকে।';

  @override
  String get artistEyebrow => 'শিল্পী';

  @override
  String artistAlbumCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি অ্যালবাম',
      one: '১টি অ্যালবাম',
    );
    return '$_temp0';
  }

  @override
  String get artistMostPlayed => 'সবচেয়ে বেশি শোনা';

  @override
  String get artistAlbumsHeader => 'অ্যালবাম';

  @override
  String get searchHint => 'ট্র্যাক, অ্যালবাম, শিল্পী';

  @override
  String get searchEmptyLibrary =>
      'আপনার লাইব্রেরি তৈরি শুরু করতে অডিও ইম্পোর্ট করুন।';

  @override
  String get searchNoResults => 'কোনো ফলাফল নেই';

  @override
  String get searchContextLabel => 'খোঁজ';

  @override
  String get settingsTitle => 'সেটিংস';

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
  String get settingsStorageUsed => 'ব্যবহৃত স্টোরেজ';

  @override
  String get settingsSectionPlayback => 'প্লেব্যাক';

  @override
  String get settingsRememberPosition => 'প্লেব্যাক অবস্থান মনে রাখুন';

  @override
  String get settingsKeepPlayingWhenClosed => 'অ্যাপ বন্ধ হলেও চলতে থাকুন';

  @override
  String get settingsSectionDebug => 'ডিবাগ (শুধু ডিবাগ বিল্ডে)';

  @override
  String get settingsImportTestFiles => 'পুশ করা টেস্ট ফাইল ইম্পোর্ট করুন';

  @override
  String settingsDebugAddedSkipped(int added, int skipped) {
    return '$addedটি যোগ হয়েছে, $skippedটি বাদ দেওয়া হয়েছে';
  }

  @override
  String get settingsSectionAbout => 'সম্পর্কে';

  @override
  String get settingsVersion => 'সংস্করণ';

  @override
  String get settingsFooterNote =>
      'ইম্পোর্ট করা ট্র্যাক স্থানীয়ভাবে সংরক্ষিত হয়। ডাউনলোডের জন্য ইন্টারনেট প্রয়োজন।';

  @override
  String get settingsAppearance => 'চেহারা';

  @override
  String get settingsThemeLight => 'হালকা';

  @override
  String get settingsThemeDark => 'গাঢ়';

  @override
  String get settingsThemeSystem => 'সিস্টেম';

  @override
  String get newPlaylistTitle => 'নতুন প্লেলিস্ট';

  @override
  String get newPlaylistCreate => 'তৈরি করুন';

  @override
  String get newPlaylistNameHint => 'প্লেলিস্টের নাম';

  @override
  String get newPlaylistArtworkHintChange => 'কভার পরিবর্তন করতে ট্যাপ করুন।';

  @override
  String get newPlaylistArtworkHintAdd =>
      'ছবি যোগ করতে কভারে ট্যাপ করুন, অথবা খালি রাখুন এবং আপনার যোগ করা ট্র্যাক থেকে একটি স্বয়ংক্রিয়ভাবে তৈরি হবে।';

  @override
  String get playlistDeleted => 'প্লেলিস্ট মুছে ফেলা হয়েছে';

  @override
  String get playlistMenuRename => 'নাম পরিবর্তন করুন';

  @override
  String get playlistMenuChangeArtwork => 'কভার পরিবর্তন করুন';

  @override
  String get playlistMenuRemoveArtwork => 'কভার সরান';

  @override
  String get playlistMenuDeletePlaylist => 'প্লেলিস্ট মুছুন';

  @override
  String playlistCreatedOn(String date) {
    return '$date তারিখে তৈরি';
  }

  @override
  String get playlistAddTracksButton => 'ট্র্যাক যোগ করুন';

  @override
  String get playlistEmptyTracks =>
      'এখনও কোনো ট্র্যাক নেই — এই প্লেলিস্ট তৈরি করতে \"ট্র্যাক যোগ করুন\"-এ ট্যাপ করুন।';

  @override
  String get playlistRenameDialogTitle => 'প্লেলিস্টের নাম পরিবর্তন করুন';

  @override
  String get playlistDeleteDialogTitle => 'প্লেলিস্ট মুছবেন?';

  @override
  String playlistDeleteDialogBody(String name) {
    return '\"$name\" মুছে ফেলা হবে। ট্র্যাকগুলো আপনার লাইব্রেরিতে থেকে যাবে।';
  }

  @override
  String get playlistsPickTracksLater => 'পরে ট্র্যাক বেছে নিন';

  @override
  String get queueTitle => 'সারি';

  @override
  String get queueNowPlaying => 'এখন বাজছে';

  @override
  String get queuePlayingNext => 'এরপর বাজবে';

  @override
  String get queueNothingQueued => 'সারিতে কিছু নেই।';

  @override
  String queueThenContinuesFrom(String source) {
    return 'এরপর $source থেকে চলতে থাকবে';
  }

  @override
  String get nowPlayingNothingPlaying => 'কিছুই বাজছে না';

  @override
  String nowPlayingFrom(String source) {
    return '$source থেকে বাজছে';
  }

  @override
  String get nowPlayingMoreOptionsTooltip => 'আরও অপশন';

  @override
  String get nowPlayingAddFavoriteTooltip => 'প্রিয়তে যোগ করুন';

  @override
  String get nowPlayingRemoveFavoriteTooltip => 'প্রিয় থেকে সরান';

  @override
  String get nowPlayingPreviousTrackTooltip => 'আগের ট্র্যাক';

  @override
  String get nowPlayingShuffleOn => 'শাফল: চালু';

  @override
  String get nowPlayingShuffleOff => 'শাফল: বন্ধ';

  @override
  String get nowPlayingRepeatTrack => 'ট্র্যাক';

  @override
  String get nowPlayingRepeatQueue => 'সারি';

  @override
  String get nowPlayingPlaybackDeviceTooltip => 'প্লেব্যাক ডিভাইস';

  @override
  String get nowPlayingPlaybackDeviceMessage =>
      'প্লেব্যাক ডিভাইস পাল্টাতে আপনার ডিভাইসের ব্লুটুথ/আউটপুট সেটিংস ব্যবহার করুন।';

  @override
  String get nowPlayingRewind10Tooltip => '১০ সেকেন্ড পিছনে যান';

  @override
  String get nowPlayingForward10Tooltip => '১০ সেকেন্ড এগিয়ে যান';

  @override
  String bulkAddToPlaylistTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি ট্র্যাক প্লেলিস্টে যোগ করুন',
      one: 'প্লেলিস্টে যোগ করুন',
    );
    return '$_temp0';
  }

  @override
  String bulkDeleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি ট্র্যাক মুছবেন?',
      one: '১টি ট্র্যাক মুছবেন?',
    );
    return '$_temp0';
  }

  @override
  String get bulkDeleteChooseHow => 'কীভাবে সরাবেন তা বেছে নিন।';

  @override
  String get contextMenuPlayNow => 'এখনই চালান';

  @override
  String get contextMenuPlayNext => 'এরপর চালান';

  @override
  String get contextMenuAddToQueue => 'সারিতে যোগ করুন';

  @override
  String get contextMenuAddToPlaylistEllipsis => 'প্লেলিস্টে যোগ করুন…';

  @override
  String get contextMenuFavorite => 'প্রিয় করুন';

  @override
  String get contextMenuRemoveFavorite => 'প্রিয় থেকে সরান';

  @override
  String get contextMenuViewAlbum => 'অ্যালবাম দেখুন';

  @override
  String get contextMenuViewArtist => 'শিল্পী দেখুন';

  @override
  String get renameTrackDialogTitle => 'ট্র্যাকের নাম পরিবর্তন করুন';

  @override
  String get renameTrackHint => 'শিরোনাম';

  @override
  String get renameAlbumDialogTitle => 'অ্যালবামের নাম পরিবর্তন করুন';

  @override
  String get renameAlbumHint => 'অ্যালবামের নাম';

  @override
  String renameAlbumCollisionMessage(String name, String albumArtist) {
    return '\"$name\" নামে $albumArtist-এর একটি অ্যালবাম ইতিমধ্যে আছে।';
  }

  @override
  String get deleteFromDeviceDialogTitle => 'ডিভাইস থেকে মুছবেন?';

  @override
  String deleteFromDeviceDialogBody(String title) {
    return '\"$title\" স্থায়ীভাবে মুছে ফেলা হবে এবং পুনরুদ্ধার করা যাবে না।';
  }

  @override
  String get miniPlayerDismissTooltip => 'বন্ধ করুন';

  @override
  String get songRowOptionsTooltip => 'ট্র্যাক অপশন';

  @override
  String songRowDeleteDialogTitle(String title) {
    return '\"$title\" মুছবেন?';
  }

  @override
  String get deviceBrowserTitle => 'অডিও বেছে নিন';

  @override
  String deviceBrowserImportButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি ট্র্যাক ইম্পোর্ট করুন',
      one: '১টি ট্র্যাক ইম্পোর্ট করুন',
    );
    return '$_temp0';
  }

  @override
  String get deviceBrowserPermissionTitle => 'অডিও অ্যাক্সেস প্রয়োজন';

  @override
  String get deviceBrowserPermissionMessage =>
      'আপনার ডিভাইসের অডিও ফাইল দেখতে Listeny-র অনুমতি প্রয়োজন। আপনার অডিও ব্রাউজ ও ইম্পোর্ট করতে সেটিংসে অনুমতি দিন।';

  @override
  String get deviceBrowserOpenSettings => 'সেটিংস খুলুন';

  @override
  String get deviceBrowserErrorTitle => 'আপনার অডিও পড়া যায়নি';

  @override
  String get deviceBrowserUnknownError => 'একটি অজানা ত্রুটি ঘটেছে।';

  @override
  String get deviceBrowserRetry => 'আবার চেষ্টা করুন';

  @override
  String get deviceBrowserNoAudioTitle => 'কোনো অডিও ফাইল পাওয়া যায়নি';

  @override
  String get deviceBrowserNoAudioMessage =>
      'আপনার ডিভাইসে অডিও যোগ করুন (ডাউনলোড, ট্রান্সফার ইত্যাদি) এবং আবার চেষ্টা করতে নিচে টানুন।';

  @override
  String get deviceBrowserSearchHint => 'আপনার অডিও খুঁজুন';

  @override
  String get deviceBrowserNoMatches => 'কোনো মিল নেই';

  @override
  String get deviceBrowserSelectAll => 'সব নির্বাচন করুন';

  @override
  String get deviceBrowserDeselectAll => 'সব বাতিল করুন';

  @override
  String get importFlowContextWhatsNew => 'নতুন কী যোগ হলো';

  @override
  String get importFlowImportingTitle => 'অডিও ইম্পোর্ট হচ্ছে';

  @override
  String importFlowProcessedOfTotal(int processed, int total) {
    return '$totalটির মধ্যে $processedটি ফাইল · মেটাডেটা পড়া হচ্ছে';
  }

  @override
  String get importFlowCopiedNote =>
      'অ্যাপের মধ্যে কপি করা হয়েছে — মূল ফাইলগুলো অক্ষত আছে।';

  @override
  String importFlowAddedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি ট্র্যাক যোগ হয়েছে',
      one: '১টি ট্র্যাক যোগ হয়েছে',
    );
    return '$_temp0';
  }

  @override
  String importFlowArtistsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countজন শিল্পী',
      one: '১জন শিল্পী',
    );
    return '$_temp0';
  }

  @override
  String importFlowDuplicatesSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি ডুপ্লিকেট বাদ দেওয়া হয়েছে',
      one: '১টি ডুপ্লিকেট বাদ দেওয়া হয়েছে',
    );
    return '$_temp0';
  }

  @override
  String get importFlowAlreadyInLibrary => 'আপনার লাইব্রেরিতে আগে থেকেই আছে';

  @override
  String importFlowUnsupportedSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি ফাইল সমর্থিত নয়',
      one: '১টি ফাইল সমর্থিত নয়',
    );
    return '$_temp0';
  }

  @override
  String importFlowCorruptSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি ফাইল পড়া যায়নি',
      one: '১টি ফাইল পড়া যায়নি',
    );
    return '$_temp0';
  }

  @override
  String get importFlowPlayWhatsNew => 'নতুন যোগ হওয়া চালান';

  @override
  String get downloadInstructions =>
      'একটি অডিও বা ভিডিও ফাইলের সরাসরি লিঙ্ক পেস্ট করুন — MP3, M4A, AAC, WAV, FLAC, OGG, MP4, WebM।';

  @override
  String get downloadUrlHint => 'https://example.com/track.mp3';

  @override
  String get downloadPasteTooltip => 'পেস্ট করুন';

  @override
  String get downloadInvalidUrlError =>
      'একটি মিডিয়া ফাইলের সঠিক লিঙ্ক পেস্ট করুন।';

  @override
  String get downloadFormatLabel => 'ফরম্যাট';

  @override
  String get downloadFormatBestAvailable => 'সর্বোত্তম উপলব্ধ অডিও';

  @override
  String get downloadFormatMp3 => 'MP3';

  @override
  String get downloadAnotherButton => 'আরেকটি ডাউনলোড করুন';

  @override
  String get downloadAudioButton => 'অডিও ডাউনলোড করুন';

  @override
  String get downloadResolvingLink => 'লিঙ্ক শনাক্ত করা হচ্ছে…';

  @override
  String get downloadDownloadingIndeterminate => 'ডাউনলোড হচ্ছে…';

  @override
  String downloadDownloadingPercent(int percent) {
    return 'ডাউনলোড হচ্ছে $percent%';
  }

  @override
  String get downloadConverting => 'রূপান্তর হচ্ছে…';

  @override
  String get downloadImporting => 'আপনার লাইব্রেরিতে ইম্পোর্ট হচ্ছে…';

  @override
  String get downloadCancelled => 'বাতিল করা হয়েছে।';

  @override
  String get downloadQueued => 'একটি স্লটের অপেক্ষায়…';

  @override
  String get downloadRemoveTooltip => 'সরান';

  @override
  String get downloadGenericError => 'কিছু ভুল হয়েছে। আবার চেষ্টা করুন।';

  @override
  String downloadAddedToLibrary(String title) {
    return '✓ আপনার লাইব্রেরিতে যোগ হয়েছে\n$title';
  }

  @override
  String get downloadNothingNewAdded =>
      'এই লিঙ্ক আপনার লাইব্রেরিতে নতুন কিছু যোগ করেনি।';

  @override
  String get downloadHistoryTitle => 'ডাউনলোড ইতিহাস';

  @override
  String get downloadHistoryEmpty => 'আপনার ডাউনলোড ইতিহাস এখানে দেখা যাবে।';

  @override
  String get downloadClearHistoryDialogTitle => 'ডাউনলোড ইতিহাস মুছবেন?';

  @override
  String get downloadClearHistoryDialogBody =>
      'এটি শুধু ইতিহাসের তালিকা মুছে দেয় — কোনো ট্র্যাক সরায় না।';

  @override
  String get downloadSourceDirectLink => 'সরাসরি লিঙ্ক';

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
