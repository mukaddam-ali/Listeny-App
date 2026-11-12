// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get commonPlay => 'चलाएं';

  @override
  String get commonPause => 'रोकें';

  @override
  String get commonShuffle => 'शफ़ल';

  @override
  String get commonCancel => 'रद्द करें';

  @override
  String get commonSave => 'सहेजें';

  @override
  String get commonDone => 'हो गया';

  @override
  String get commonClear => 'हटाएं';

  @override
  String get commonDelete => 'मिटाएं';

  @override
  String get commonAddToPlaylistTooltip => 'प्लेलिस्ट में जोड़ें';

  @override
  String commonSelectedCount(int count) {
    return '$count चुने गए';
  }

  @override
  String commonTrackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ट्रैक',
      one: '1 ट्रैक',
    );
    return '$_temp0';
  }

  @override
  String get commonNoFavoritesYet =>
      'अभी तक कोई पसंदीदा नहीं है। किसी ट्रैक पर दिल के आइकन को टैप करके जोड़ें।';

  @override
  String get commonRemoveFromLibrary => 'लाइब्रेरी से हटाएं';

  @override
  String get commonDeleteFromDevice => 'डिवाइस से मिटाएं';

  @override
  String get commonNextTrack => 'अगला ट्रैक';

  @override
  String get commonSearchTooltip => 'खोजें';

  @override
  String get commonImportTooltip => 'इंपोर्ट करें';

  @override
  String get navLibrary => 'लाइब्रेरी';

  @override
  String get navPlaylists => 'प्लेलिस्ट';

  @override
  String get navSearch => 'खोजें';

  @override
  String get navDownload => 'डाउनलोड';

  @override
  String get navSettings => 'सेटिंग्स';

  @override
  String get formatJustNow => 'अभी-अभी';

  @override
  String formatMinutesAgo(int minutes) {
    return '$minutes मिनट पहले';
  }

  @override
  String formatHoursAgo(int hours) {
    return '$hours घंटे पहले';
  }

  @override
  String formatDaysAgo(int days) {
    return '$days दिन पहले';
  }

  @override
  String formatHoursMinutes(int hours, int minutes) {
    return '$hours घं $minutes मि';
  }

  @override
  String formatMinutesOnly(int minutes) {
    return '$minutes मि';
  }

  @override
  String get libraryTitle => 'लाइब्रेरी';

  @override
  String get libraryExitSelectionTooltip => 'चयन से बाहर निकलें';

  @override
  String get libraryRecentlyAdded => 'हाल ही में जोड़े गए';

  @override
  String get libraryFilterTracks => 'ट्रैक';

  @override
  String get libraryFilterAlbums => 'एल्बम';

  @override
  String get libraryFilterRecentlyPlayed => 'हाल ही में चलाए गए';

  @override
  String get libraryFilterFavorites => 'पसंदीदा';

  @override
  String get libraryRecentlyPlayedEmpty =>
      'आपके द्वारा चलाए गए ट्रैक यहां दिखेंगे';

  @override
  String get libraryEmptyTitle => 'अभी तक कोई ट्रैक नहीं';

  @override
  String get libraryEmptyBody =>
      'अपनी लाइब्रेरी बनाना शुरू करने के लिए फ़ाइल्स ऐप से ऑडियो इंपोर्ट करें।';

  @override
  String get libraryImportAudioButton => 'ऑडियो इंपोर्ट करें';

  @override
  String get libraryPrivacyNote => 'आपकी लाइब्रेरी आपके डिवाइस पर ही रहती है।';

  @override
  String get artistEyebrow => 'कलाकार';

  @override
  String artistAlbumCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count एल्बम',
      one: '1 एल्बम',
    );
    return '$_temp0';
  }

  @override
  String get artistMostPlayed => 'सबसे ज़्यादा सुने गए';

  @override
  String get artistAlbumsHeader => 'एल्बम';

  @override
  String get searchHint => 'ट्रैक, एल्बम, कलाकार';

  @override
  String get searchEmptyLibrary =>
      'अपनी लाइब्रेरी बनाना शुरू करने के लिए ऑडियो इंपोर्ट करें।';

  @override
  String get searchNoResults => 'कोई परिणाम नहीं';

  @override
  String get searchContextLabel => 'खोज';

  @override
  String get settingsTitle => 'सेटिंग्स';

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
  String get settingsStorageUsed => 'उपयोग किया गया स्टोरेज';

  @override
  String get settingsSectionPlayback => 'प्लेबैक';

  @override
  String get settingsRememberPosition => 'प्लेबैक स्थिति याद रखें';

  @override
  String get settingsKeepPlayingWhenClosed => 'ऐप बंद होने पर भी चलाते रहें';

  @override
  String get settingsSectionDebug => 'डीबग (केवल डीबग बिल्ड)';

  @override
  String get settingsImportTestFiles => 'पुश की गई टेस्ट फ़ाइलें इंपोर्ट करें';

  @override
  String settingsDebugAddedSkipped(int added, int skipped) {
    return '$added जोड़े गए, $skipped छोड़े गए';
  }

  @override
  String get settingsSectionAbout => 'ऐप के बारे में';

  @override
  String get settingsVersion => 'वर्शन';

  @override
  String get settingsFooterNote =>
      'इंपोर्ट किए गए ट्रैक स्थानीय रूप से सहेजे जाते हैं। डाउनलोड के लिए इंटरनेट ज़रूरी है।';

  @override
  String get settingsAppearance => 'दिखावट';

  @override
  String get settingsThemeLight => 'लाइट';

  @override
  String get settingsThemeDark => 'डार्क';

  @override
  String get settingsThemeSystem => 'सिस्टम';

  @override
  String get newPlaylistTitle => 'नई प्लेलिस्ट';

  @override
  String get newPlaylistCreate => 'बनाएं';

  @override
  String get newPlaylistNameHint => 'प्लेलिस्ट का नाम';

  @override
  String get newPlaylistArtworkHintChange => 'कवर बदलने के लिए उसे टैप करें।';

  @override
  String get newPlaylistArtworkHintAdd =>
      'फ़ोटो जोड़ने के लिए कवर टैप करें, या इसे खाली छोड़ दें और आपके जोड़े गए ट्रैक से एक अपने आप बन जाएगा।';

  @override
  String get playlistDeleted => 'प्लेलिस्ट मिटाई गई';

  @override
  String get playlistMenuRename => 'नाम बदलें';

  @override
  String get playlistMenuChangeArtwork => 'कवर बदलें';

  @override
  String get playlistMenuRemoveArtwork => 'कवर हटाएं';

  @override
  String get playlistMenuDeletePlaylist => 'प्लेलिस्ट मिटाएं';

  @override
  String playlistCreatedOn(String date) {
    return '$date को बनाई गई';
  }

  @override
  String get playlistAddTracksButton => 'ट्रैक जोड़ें';

  @override
  String get playlistEmptyTracks =>
      'अभी तक कोई ट्रैक नहीं — इस प्लेलिस्ट को बनाने के लिए \"ट्रैक जोड़ें\" टैप करें।';

  @override
  String get playlistRenameDialogTitle => 'प्लेलिस्ट का नाम बदलें';

  @override
  String get playlistDeleteDialogTitle => 'प्लेलिस्ट मिटाएं?';

  @override
  String playlistDeleteDialogBody(String name) {
    return '\"$name\" मिटा दी जाएगी। ट्रैक आपकी लाइब्रेरी में बने रहेंगे।';
  }

  @override
  String get playlistsPickTracksLater => 'ट्रैक बाद में चुनें';

  @override
  String get queueTitle => 'कतार';

  @override
  String get queueNowPlaying => 'अभी चल रहा है';

  @override
  String get queuePlayingNext => 'आगे बजेगा';

  @override
  String get queueNothingQueued => 'आगे कुछ भी कतार में नहीं है।';

  @override
  String queueThenContinuesFrom(String source) {
    return 'फिर $source से जारी रहेगा';
  }

  @override
  String get nowPlayingNothingPlaying => 'कुछ भी नहीं चल रहा';

  @override
  String nowPlayingFrom(String source) {
    return '$source से चल रहा है';
  }

  @override
  String get nowPlayingMoreOptionsTooltip => 'और विकल्प';

  @override
  String get nowPlayingAddFavoriteTooltip => 'पसंदीदा में जोड़ें';

  @override
  String get nowPlayingRemoveFavoriteTooltip => 'पसंदीदा से हटाएं';

  @override
  String get nowPlayingPreviousTrackTooltip => 'पिछला ट्रैक';

  @override
  String get nowPlayingShuffleOn => 'शफ़ल: चालू';

  @override
  String get nowPlayingShuffleOff => 'शफ़ल: बंद';

  @override
  String get nowPlayingRepeatTrack => 'ट्रैक';

  @override
  String get nowPlayingRepeatQueue => 'कतार';

  @override
  String get nowPlayingPlaybackDeviceTooltip => 'प्लेबैक डिवाइस';

  @override
  String get nowPlayingPlaybackDeviceMessage =>
      'प्लेबैक डिवाइस बदलने के लिए अपने डिवाइस की ब्लूटूथ/आउटपुट सेटिंग्स का उपयोग करें।';

  @override
  String get nowPlayingRewind10Tooltip => '10 सेकंड पीछे जाएं';

  @override
  String get nowPlayingForward10Tooltip => '10 सेकंड आगे जाएं';

  @override
  String bulkAddToPlaylistTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ट्रैक प्लेलिस्ट में जोड़ें',
      one: 'प्लेलिस्ट में जोड़ें',
    );
    return '$_temp0';
  }

  @override
  String bulkDeleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ट्रैक मिटाएं?',
      one: '1 ट्रैक मिटाएं?',
    );
    return '$_temp0';
  }

  @override
  String get bulkDeleteChooseHow => 'इन्हें हटाने का तरीका चुनें।';

  @override
  String get contextMenuPlayNow => 'अभी चलाएं';

  @override
  String get contextMenuPlayNext => 'आगे चलाएं';

  @override
  String get contextMenuAddToQueue => 'कतार में जोड़ें';

  @override
  String get contextMenuAddToPlaylistEllipsis => 'प्लेलिस्ट में जोड़ें…';

  @override
  String get contextMenuFavorite => 'पसंदीदा बनाएं';

  @override
  String get contextMenuRemoveFavorite => 'पसंदीदा से हटाएं';

  @override
  String get contextMenuViewAlbum => 'एल्बम देखें';

  @override
  String get contextMenuViewArtist => 'कलाकार देखें';

  @override
  String get renameTrackDialogTitle => 'ट्रैक का नाम बदलें';

  @override
  String get renameTrackHint => 'शीर्षक';

  @override
  String get renameAlbumDialogTitle => 'एल्बम का नाम बदलें';

  @override
  String get renameAlbumHint => 'एल्बम का नाम';

  @override
  String renameAlbumCollisionMessage(String name, String albumArtist) {
    return '\"$name\" नाम से $albumArtist का एक एल्बम पहले से मौजूद है।';
  }

  @override
  String get deleteFromDeviceDialogTitle => 'डिवाइस से मिटाएं?';

  @override
  String deleteFromDeviceDialogBody(String title) {
    return '\"$title\" हमेशा के लिए मिटा दिया जाएगा और वापस नहीं लाया जा सकेगा।';
  }

  @override
  String get miniPlayerDismissTooltip => 'बंद करें';

  @override
  String get songRowOptionsTooltip => 'ट्रैक विकल्प';

  @override
  String songRowDeleteDialogTitle(String title) {
    return '\"$title\" मिटाएं?';
  }

  @override
  String get deviceBrowserTitle => 'ऑडियो चुनें';

  @override
  String deviceBrowserImportButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ट्रैक इंपोर्ट करें',
      one: '1 ट्रैक इंपोर्ट करें',
    );
    return '$_temp0';
  }

  @override
  String get deviceBrowserPermissionTitle => 'ऑडियो एक्सेस ज़रूरी है';

  @override
  String get deviceBrowserPermissionMessage =>
      'Listeny को आपके डिवाइस पर मौजूद ऑडियो फ़ाइलें देखने के लिए अनुमति चाहिए। अपना ऑडियो ब्राउज़ करने और इंपोर्ट करने के लिए इसे सेटिंग्स में दें।';

  @override
  String get deviceBrowserOpenSettings => 'सेटिंग्स खोलें';

  @override
  String get deviceBrowserErrorTitle => 'आपका ऑडियो पढ़ा नहीं जा सका';

  @override
  String get deviceBrowserUnknownError => 'एक अज्ञात त्रुटि हुई।';

  @override
  String get deviceBrowserRetry => 'फिर कोशिश करें';

  @override
  String get deviceBrowserNoAudioTitle => 'कोई ऑडियो फ़ाइल नहीं मिली';

  @override
  String get deviceBrowserNoAudioMessage =>
      'अपने डिवाइस में ऑडियो जोड़ें (डाउनलोड, ट्रांसफ़र, आदि) और फिर कोशिश करने के लिए नीचे खींचें।';

  @override
  String get deviceBrowserSearchHint => 'अपना ऑडियो खोजें';

  @override
  String get deviceBrowserNoMatches => 'कोई मेल नहीं मिला';

  @override
  String get deviceBrowserSelectAll => 'सभी चुनें';

  @override
  String get deviceBrowserDeselectAll => 'सभी अचयनित करें';

  @override
  String get importFlowContextWhatsNew => 'नया क्या है';

  @override
  String get importFlowImportingTitle => 'ऑडियो इंपोर्ट हो रहा है';

  @override
  String importFlowProcessedOfTotal(int processed, int total) {
    return '$total में से $processed फ़ाइलें · मेटाडेटा पढ़ा जा रहा है';
  }

  @override
  String get importFlowCopiedNote =>
      'ऐप में कॉपी किया गया — मूल फ़ाइलें अछूती हैं।';

  @override
  String importFlowAddedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ट्रैक जोड़े गए',
      one: '1 ट्रैक जोड़ा गया',
    );
    return '$_temp0';
  }

  @override
  String importFlowArtistsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count कलाकार',
      one: '1 कलाकार',
    );
    return '$_temp0';
  }

  @override
  String importFlowDuplicatesSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count डुप्लिकेट छोड़े गए',
      one: '1 डुप्लिकेट छोड़ा गया',
    );
    return '$_temp0';
  }

  @override
  String get importFlowAlreadyInLibrary =>
      'पहले से आपकी लाइब्रेरी में मौजूद है';

  @override
  String importFlowUnsupportedSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count फ़ाइलें समर्थित नहीं हैं',
      one: '1 फ़ाइल समर्थित नहीं है',
    );
    return '$_temp0';
  }

  @override
  String importFlowCorruptSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count फ़ाइलें पढ़ी नहीं जा सकीं',
      one: '1 फ़ाइल पढ़ी नहीं जा सकी',
    );
    return '$_temp0';
  }

  @override
  String get importFlowPlayWhatsNew => 'नया जोड़ा गया चलाएं';

  @override
  String get downloadInstructions =>
      'किसी ऑडियो या वीडियो फ़ाइल का सीधा लिंक पेस्ट करें — MP3, M4A, AAC, WAV, FLAC, OGG, MP4, WebM।';

  @override
  String get downloadUrlHint => 'https://example.com/track.mp3';

  @override
  String get downloadPasteTooltip => 'पेस्ट करें';

  @override
  String get downloadInvalidUrlError =>
      'किसी मीडिया फ़ाइल का सही लिंक पेस्ट करें।';

  @override
  String get downloadFormatLabel => 'फ़ॉर्मेट';

  @override
  String get downloadFormatBestAvailable => 'उपलब्ध सर्वश्रेष्ठ ऑडियो';

  @override
  String get downloadFormatMp3 => 'MP3';

  @override
  String get downloadAnotherButton => 'एक और डाउनलोड करें';

  @override
  String get downloadAudioButton => 'ऑडियो डाउनलोड करें';

  @override
  String get downloadResolvingLink => 'लिंक हल किया जा रहा है…';

  @override
  String get downloadDownloadingIndeterminate => 'डाउनलोड हो रहा है…';

  @override
  String downloadDownloadingPercent(int percent) {
    return 'डाउनलोड हो रहा है $percent%';
  }

  @override
  String get downloadConverting => 'बदला जा रहा है…';

  @override
  String get downloadImporting => 'आपकी लाइब्रेरी में इंपोर्ट हो रहा है…';

  @override
  String get downloadCancelled => 'रद्द किया गया।';

  @override
  String get downloadQueued => 'खाली स्लॉट की प्रतीक्षा में…';

  @override
  String get downloadRemoveTooltip => 'हटाएं';

  @override
  String get downloadGenericError => 'कुछ गड़बड़ हो गई। कृपया फिर कोशिश करें।';

  @override
  String downloadAddedToLibrary(String title) {
    return '✓ आपकी लाइब्रेरी में जोड़ा गया\n$title';
  }

  @override
  String get downloadNothingNewAdded =>
      'इस लिंक से आपकी लाइब्रेरी में कुछ भी नया नहीं जुड़ा।';

  @override
  String get downloadHistoryTitle => 'डाउनलोड इतिहास';

  @override
  String get downloadHistoryEmpty => 'आपका डाउनलोड इतिहास यहां दिखेगा।';

  @override
  String get downloadClearHistoryDialogTitle => 'डाउनलोड इतिहास साफ़ करें?';

  @override
  String get downloadClearHistoryDialogBody =>
      'यह केवल इतिहास सूची साफ़ करता है — यह कोई ट्रैक नहीं हटाता।';

  @override
  String get downloadSourceDirectLink => 'सीधा लिंक';

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
