// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get commonPlay => 'چلائیں';

  @override
  String get commonPause => 'روکیں';

  @override
  String get commonShuffle => 'بے ترتیب';

  @override
  String get commonCancel => 'منسوخ کریں';

  @override
  String get commonSave => 'محفوظ کریں';

  @override
  String get commonDone => 'ہو گیا';

  @override
  String get commonClear => 'صاف کریں';

  @override
  String get commonDelete => 'حذف کریں';

  @override
  String get commonAddToPlaylistTooltip => 'پلے لسٹ میں شامل کریں';

  @override
  String commonSelectedCount(int count) {
    return '$count منتخب';
  }

  @override
  String commonTrackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ٹریکس',
      one: '1 ٹریک',
    );
    return '$_temp0';
  }

  @override
  String get commonNoFavoritesYet =>
      'ابھی تک کوئی پسندیدہ نہیں۔ کسی ٹریک کو شامل کرنے کے لیے دل کے آئیکن پر تھپتھپائیں۔';

  @override
  String get commonRemoveFromLibrary => 'لائبریری سے ہٹائیں';

  @override
  String get commonDeleteFromDevice => 'ڈیوائس سے حذف کریں';

  @override
  String get commonNextTrack => 'اگلا ٹریک';

  @override
  String get commonSearchTooltip => 'تلاش کریں';

  @override
  String get commonImportTooltip => 'درآمد کریں';

  @override
  String get navLibrary => 'لائبریری';

  @override
  String get navPlaylists => 'پلے لسٹس';

  @override
  String get navSearch => 'تلاش';

  @override
  String get navDownload => 'ڈاؤن لوڈ';

  @override
  String get navSettings => 'ترتیبات';

  @override
  String get formatJustNow => 'ابھی ابھی';

  @override
  String formatMinutesAgo(int minutes) {
    return '$minutes منٹ پہلے';
  }

  @override
  String formatHoursAgo(int hours) {
    return '$hours گھنٹے پہلے';
  }

  @override
  String formatDaysAgo(int days) {
    return '$days دن پہلے';
  }

  @override
  String formatHoursMinutes(int hours, int minutes) {
    return '$hours گھنٹے $minutes منٹ';
  }

  @override
  String formatMinutesOnly(int minutes) {
    return '$minutes منٹ';
  }

  @override
  String get libraryTitle => 'لائبریری';

  @override
  String get libraryExitSelectionTooltip => 'انتخاب سے باہر نکلیں';

  @override
  String get libraryRecentlyAdded => 'حال ہی میں شامل کردہ';

  @override
  String get libraryFilterTracks => 'ٹریکس';

  @override
  String get libraryFilterAlbums => 'البمز';

  @override
  String get libraryFilterRecentlyPlayed => 'حال ہی میں چلائے گئے';

  @override
  String get libraryFilterFavorites => 'پسندیدہ';

  @override
  String get libraryRecentlyPlayedEmpty =>
      'آپ جو ٹریکس چلائیں گے وہ یہاں دکھائی دیں گے';

  @override
  String get libraryEmptyTitle => 'ابھی تک کوئی ٹریک نہیں';

  @override
  String get libraryEmptyBody =>
      'اپنی لائبریری بنانا شروع کرنے کے لیے فائلز ایپ سے آڈیو درآمد کریں۔';

  @override
  String get libraryImportAudioButton => 'آڈیو درآمد کریں';

  @override
  String get libraryPrivacyNote => 'آپ کی لائبریری آپ کے ڈیوائس پر ہی رہتی ہے۔';

  @override
  String get artistEyebrow => 'فنکار';

  @override
  String artistAlbumCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count البمز',
      one: '1 البم',
    );
    return '$_temp0';
  }

  @override
  String get artistMostPlayed => 'سب سے زیادہ سنے گئے';

  @override
  String get artistAlbumsHeader => 'البمز';

  @override
  String get searchHint => 'ٹریکس، البمز، فنکار';

  @override
  String get searchEmptyLibrary =>
      'اپنی لائبریری بنانا شروع کرنے کے لیے آڈیو درآمد کریں۔';

  @override
  String get searchNoResults => 'کوئی نتیجہ نہیں';

  @override
  String get searchContextLabel => 'تلاش';

  @override
  String get settingsTitle => 'ترتیبات';

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
  String get settingsStorageUsed => 'استعمال شدہ اسٹوریج';

  @override
  String get settingsSectionPlayback => 'پلے بیک';

  @override
  String get settingsRememberPosition => 'پلے بیک پوزیشن یاد رکھیں';

  @override
  String get settingsKeepPlayingWhenClosed => 'ایپ بند ہونے پر بھی چلاتے رہیں';

  @override
  String get settingsSectionDebug => 'ڈیبگ (صرف ڈیبگ بلڈز)';

  @override
  String get settingsImportTestFiles => 'بھیجی گئی ٹیسٹ فائلیں درآمد کریں';

  @override
  String settingsDebugAddedSkipped(int added, int skipped) {
    return '$added شامل کی گئیں، $skipped نظر انداز کی گئیں';
  }

  @override
  String get settingsSectionAbout => 'ایپ کے بارے میں';

  @override
  String get settingsVersion => 'ورژن';

  @override
  String get settingsFooterNote =>
      'درآمد شدہ ٹریکس مقامی طور پر محفوظ ہوتے ہیں۔ ڈاؤن لوڈز کے لیے انٹرنیٹ درکار ہے۔';

  @override
  String get settingsAppearance => 'ظاہری شکل';

  @override
  String get settingsThemeLight => 'لائٹ';

  @override
  String get settingsThemeDark => 'ڈارک';

  @override
  String get settingsThemeSystem => 'سسٹم';

  @override
  String get newPlaylistTitle => 'نئی پلے لسٹ';

  @override
  String get newPlaylistCreate => 'بنائیں';

  @override
  String get newPlaylistNameHint => 'پلے لسٹ کا نام';

  @override
  String get newPlaylistArtworkHintChange =>
      'کور تبدیل کرنے کے لیے اسے تھپتھپائیں۔';

  @override
  String get newPlaylistArtworkHintAdd =>
      'تصویر شامل کرنے کے لیے کور پر تھپتھپائیں، یا اسے چھوڑ دیں اور آپ کے شامل کردہ ٹریکس سے خودکار طور پر ایک بن جائے گا۔';

  @override
  String get playlistDeleted => 'پلے لسٹ حذف کر دی گئی';

  @override
  String get playlistMenuRename => 'نام تبدیل کریں';

  @override
  String get playlistMenuChangeArtwork => 'کور تبدیل کریں';

  @override
  String get playlistMenuRemoveArtwork => 'کور ہٹائیں';

  @override
  String get playlistMenuDeletePlaylist => 'پلے لسٹ حذف کریں';

  @override
  String playlistCreatedOn(String date) {
    return '$date کو بنائی گئی';
  }

  @override
  String get playlistAddTracksButton => 'ٹریکس شامل کریں';

  @override
  String get playlistEmptyTracks =>
      'ابھی تک کوئی ٹریک نہیں — یہ پلے لسٹ بنانے کے لیے \"ٹریکس شامل کریں\" پر تھپتھپائیں۔';

  @override
  String get playlistRenameDialogTitle => 'پلے لسٹ کا نام تبدیل کریں';

  @override
  String get playlistDeleteDialogTitle => 'پلے لسٹ حذف کریں؟';

  @override
  String playlistDeleteDialogBody(String name) {
    return '\"$name\" حذف کر دی جائے گی۔ ٹریکس آپ کی لائبریری میں موجود رہیں گے۔';
  }

  @override
  String get playlistsPickTracksLater => 'ٹریکس بعد میں منتخب کریں';

  @override
  String get queueTitle => 'قطار';

  @override
  String get queueNowPlaying => 'ابھی چل رہا ہے';

  @override
  String get queuePlayingNext => 'اگلی باری';

  @override
  String get queueNothingQueued => 'قطار میں کچھ نہیں۔';

  @override
  String queueThenContinuesFrom(String source) {
    return 'پھر $source سے جاری رہے گا';
  }

  @override
  String get nowPlayingNothingPlaying => 'کچھ نہیں چل رہا';

  @override
  String nowPlayingFrom(String source) {
    return '$source سے چل رہا ہے';
  }

  @override
  String get nowPlayingMoreOptionsTooltip => 'مزید اختیارات';

  @override
  String get nowPlayingAddFavoriteTooltip => 'پسندیدہ میں شامل کریں';

  @override
  String get nowPlayingRemoveFavoriteTooltip => 'پسندیدہ سے ہٹائیں';

  @override
  String get nowPlayingPreviousTrackTooltip => 'پچھلا ٹریک';

  @override
  String get nowPlayingShuffleOn => 'بے ترتیب: آن';

  @override
  String get nowPlayingShuffleOff => 'بے ترتیب: آف';

  @override
  String get nowPlayingRepeatTrack => 'ٹریک';

  @override
  String get nowPlayingRepeatQueue => 'قطار';

  @override
  String get nowPlayingPlaybackDeviceTooltip => 'پلے بیک ڈیوائس';

  @override
  String get nowPlayingPlaybackDeviceMessage =>
      'پلے بیک ڈیوائس تبدیل کرنے کے لیے اپنے ڈیوائس کی بلوٹوتھ/آؤٹ پٹ ترتیبات استعمال کریں۔';

  @override
  String get nowPlayingRewind10Tooltip => '10 سیکنڈ پیچھے جائیں';

  @override
  String get nowPlayingForward10Tooltip => '10 سیکنڈ آگے جائیں';

  @override
  String bulkAddToPlaylistTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ٹریکس پلے لسٹ میں شامل کریں',
      one: 'پلے لسٹ میں شامل کریں',
    );
    return '$_temp0';
  }

  @override
  String bulkDeleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ٹریکس حذف کریں؟',
      one: '1 ٹریک حذف کریں؟',
    );
    return '$_temp0';
  }

  @override
  String get bulkDeleteChooseHow => 'انہیں ہٹانے کا طریقہ منتخب کریں۔';

  @override
  String get contextMenuPlayNow => 'ابھی چلائیں';

  @override
  String get contextMenuPlayNext => 'آگے چلائیں';

  @override
  String get contextMenuAddToQueue => 'قطار میں شامل کریں';

  @override
  String get contextMenuAddToPlaylistEllipsis => 'پلے لسٹ میں شامل کریں…';

  @override
  String get contextMenuFavorite => 'پسندیدہ بنائیں';

  @override
  String get contextMenuRemoveFavorite => 'پسندیدہ سے ہٹائیں';

  @override
  String get contextMenuViewAlbum => 'البم دیکھیں';

  @override
  String get contextMenuViewArtist => 'فنکار دیکھیں';

  @override
  String get renameTrackDialogTitle => 'ٹریک کا نام تبدیل کریں';

  @override
  String get renameTrackHint => 'عنوان';

  @override
  String get renameAlbumDialogTitle => 'البم کا نام تبدیل کریں';

  @override
  String get renameAlbumHint => 'البم کا نام';

  @override
  String renameAlbumCollisionMessage(String name, String albumArtist) {
    return '\"$name\" نامی البم بنام $albumArtist پہلے سے موجود ہے۔';
  }

  @override
  String get deleteFromDeviceDialogTitle => 'ڈیوائس سے حذف کریں؟';

  @override
  String deleteFromDeviceDialogBody(String title) {
    return '\"$title\" مستقل طور پر حذف کر دیا جائے گا اور واپس نہیں لایا جا سکے گا۔';
  }

  @override
  String get miniPlayerDismissTooltip => 'بند کریں';

  @override
  String get songRowOptionsTooltip => 'ٹریک کے اختیارات';

  @override
  String songRowDeleteDialogTitle(String title) {
    return '\"$title\" حذف کریں؟';
  }

  @override
  String get deviceBrowserTitle => 'آڈیو منتخب کریں';

  @override
  String deviceBrowserImportButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ٹریکس درآمد کریں',
      one: '1 ٹریک درآمد کریں',
    );
    return '$_temp0';
  }

  @override
  String get deviceBrowserPermissionTitle => 'آڈیو تک رسائی درکار ہے';

  @override
  String get deviceBrowserPermissionMessage =>
      'Listeny کو آپ کے ڈیوائس پر موجود آڈیو فائلیں دیکھنے کے لیے اجازت درکار ہے۔ اپنا آڈیو براؤز اور درآمد کرنے کے لیے ترتیبات میں یہ اجازت دیں۔';

  @override
  String get deviceBrowserOpenSettings => 'ترتیبات کھولیں';

  @override
  String get deviceBrowserErrorTitle => 'آپ کا آڈیو پڑھا نہیں جا سکا';

  @override
  String get deviceBrowserUnknownError => 'ایک نامعلوم خرابی پیش آئی۔';

  @override
  String get deviceBrowserRetry => 'دوبارہ کوشش کریں';

  @override
  String get deviceBrowserNoAudioTitle => 'کوئی آڈیو فائل نہیں ملی';

  @override
  String get deviceBrowserNoAudioMessage =>
      'اپنے ڈیوائس میں آڈیو شامل کریں (ڈاؤن لوڈز، منتقلی وغیرہ) اور دوبارہ کوشش کرنے کے لیے نیچے کھینچیں۔';

  @override
  String get deviceBrowserSearchHint => 'اپنا آڈیو تلاش کریں';

  @override
  String get deviceBrowserNoMatches => 'کوئی مماثلت نہیں';

  @override
  String get deviceBrowserSelectAll => 'سب منتخب کریں';

  @override
  String get deviceBrowserDeselectAll => 'سب غیر منتخب کریں';

  @override
  String get importFlowContextWhatsNew => 'نیا کیا ہے';

  @override
  String get importFlowImportingTitle => 'آڈیو درآمد ہو رہا ہے';

  @override
  String importFlowProcessedOfTotal(int processed, int total) {
    return '$total میں سے $processed فائلیں · میٹا ڈیٹا پڑھا جا رہا ہے';
  }

  @override
  String get importFlowCopiedNote =>
      'ایپ کے اندر کاپی کر دیا گیا — اصل فائلیں محفوظ ہیں۔';

  @override
  String importFlowAddedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ٹریکس شامل کیے گئے',
      one: '1 ٹریک شامل کیا گیا',
    );
    return '$_temp0';
  }

  @override
  String importFlowArtistsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فنکار',
      one: '1 فنکار',
    );
    return '$_temp0';
  }

  @override
  String importFlowDuplicatesSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نقول نظر انداز کی گئیں',
      one: '1 نقل نظر انداز کی گئی',
    );
    return '$_temp0';
  }

  @override
  String get importFlowAlreadyInLibrary =>
      'پہلے سے ہی آپ کی لائبریری میں موجود ہے';

  @override
  String importFlowUnsupportedSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فائلیں معاون نہیں ہیں',
      one: '1 فائل معاون نہیں ہے',
    );
    return '$_temp0';
  }

  @override
  String importFlowCorruptSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فائلیں پڑھی نہیں جا سکیں',
      one: '1 فائل پڑھی نہیں جا سکی',
    );
    return '$_temp0';
  }

  @override
  String get importFlowPlayWhatsNew => 'نیا شامل کردہ چلائیں';

  @override
  String get downloadInstructions =>
      'آڈیو یا ویڈیو فائل کا براہ راست لنک پیسٹ کریں — MP3، M4A، AAC، WAV، FLAC، OGG، MP4، WebM۔';

  @override
  String get downloadUrlHint => 'https://example.com/track.mp3';

  @override
  String get downloadPasteTooltip => 'پیسٹ کریں';

  @override
  String get downloadInvalidUrlError => 'کسی میڈیا فائل کا درست لنک پیسٹ کریں۔';

  @override
  String get downloadFormatLabel => 'فارمیٹ';

  @override
  String get downloadFormatBestAvailable => 'بہترین دستیاب آڈیو';

  @override
  String get downloadFormatMp3 => 'MP3';

  @override
  String get downloadAnotherButton => 'ایک اور ڈاؤن لوڈ کریں';

  @override
  String get downloadAudioButton => 'آڈیو ڈاؤن لوڈ کریں';

  @override
  String get downloadResolvingLink => 'لنک حل کیا جا رہا ہے…';

  @override
  String get downloadDownloadingIndeterminate => 'ڈاؤن لوڈ ہو رہا ہے…';

  @override
  String downloadDownloadingPercent(int percent) {
    return 'ڈاؤن لوڈ ہو رہا ہے $percent%';
  }

  @override
  String get downloadConverting => 'تبدیل کیا جا رہا ہے…';

  @override
  String get downloadImporting => 'آپ کی لائبریری میں درآمد ہو رہا ہے…';

  @override
  String get downloadCancelled => 'منسوخ کر دیا گیا۔';

  @override
  String get downloadQueued => 'خالی جگہ کا انتظار…';

  @override
  String get downloadRemoveTooltip => 'ہٹائیں';

  @override
  String get downloadGenericError =>
      'کچھ غلط ہو گیا۔ براہ کرم دوبارہ کوشش کریں۔';

  @override
  String downloadAddedToLibrary(String title) {
    return '✓ آپ کی لائبریری میں شامل کر دیا گیا\n$title';
  }

  @override
  String get downloadNothingNewAdded =>
      'اس لنک نے آپ کی لائبریری میں کچھ نیا شامل نہیں کیا۔';

  @override
  String get downloadHistoryTitle => 'ڈاؤن لوڈ کی تاریخ';

  @override
  String get downloadHistoryEmpty =>
      'آپ کی ڈاؤن لوڈ کی تاریخ یہاں دکھائی دے گی۔';

  @override
  String get downloadClearHistoryDialogTitle => 'ڈاؤن لوڈ کی تاریخ صاف کریں؟';

  @override
  String get downloadClearHistoryDialogBody =>
      'یہ صرف تاریخ کی فہرست صاف کرتا ہے — یہ کوئی ٹریک نہیں ہٹاتا۔';

  @override
  String get downloadSourceDirectLink => 'براہ راست لنک';

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
