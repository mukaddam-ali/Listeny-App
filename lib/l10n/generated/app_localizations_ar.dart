// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get commonPlay => 'تشغيل';

  @override
  String get commonPause => 'إيقاف مؤقت';

  @override
  String get commonShuffle => 'عشوائي';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonSave => 'حفظ';

  @override
  String get commonDone => 'تم';

  @override
  String get commonClear => 'مسح';

  @override
  String get commonDelete => 'حذف';

  @override
  String get commonAddToPlaylistTooltip => 'إضافة إلى قائمة التشغيل';

  @override
  String commonSelectedCount(int count) {
    return 'تم تحديد $count';
  }

  @override
  String commonTrackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مقطوعة',
      many: '$count مقطوعة',
      few: '$count مقطوعات',
      two: 'مقطوعتان',
      one: 'مقطوعة واحدة',
      zero: 'لا مقطوعات',
    );
    return '$_temp0';
  }

  @override
  String get commonNoFavoritesYet =>
      'لا توجد مفضلات بعد. اضغط على أيقونة القلب في أي مقطوعة لإضافتها.';

  @override
  String get commonRemoveFromLibrary => 'إزالة من المكتبة';

  @override
  String get commonDeleteFromDevice => 'حذف من الجهاز';

  @override
  String get commonNextTrack => 'المقطوعة التالية';

  @override
  String get commonSearchTooltip => 'بحث';

  @override
  String get commonImportTooltip => 'استيراد';

  @override
  String get navLibrary => 'المكتبة';

  @override
  String get navPlaylists => 'قوائم التشغيل';

  @override
  String get navSearch => 'بحث';

  @override
  String get navDownload => 'تنزيل';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get formatJustNow => 'الآن';

  @override
  String formatMinutesAgo(int minutes) {
    return 'قبل $minutes د';
  }

  @override
  String formatHoursAgo(int hours) {
    return 'قبل $hours س';
  }

  @override
  String formatDaysAgo(int days) {
    return 'قبل $days يوم';
  }

  @override
  String formatHoursMinutes(int hours, int minutes) {
    return '$hours س $minutes د';
  }

  @override
  String formatMinutesOnly(int minutes) {
    return '$minutes د';
  }

  @override
  String get libraryTitle => 'المكتبة';

  @override
  String get libraryExitSelectionTooltip => 'الخروج من وضع التحديد';

  @override
  String get libraryRecentlyAdded => 'أُضيف مؤخرًا';

  @override
  String get libraryFilterTracks => 'المقطوعات';

  @override
  String get libraryFilterAlbums => 'الألبومات';

  @override
  String get libraryFilterRecentlyPlayed => 'شُغِّل مؤخرًا';

  @override
  String get libraryFilterFavorites => 'المفضلة';

  @override
  String get libraryRecentlyPlayedEmpty => 'ستظهر هنا المقطوعات التي تشغّلها';

  @override
  String get libraryEmptyTitle => 'لا توجد مقطوعات بعد';

  @override
  String get libraryEmptyBody =>
      'استورد الصوتيات من تطبيق الملفات لبدء إنشاء مكتبتك.';

  @override
  String get libraryImportAudioButton => 'استيراد صوتيات';

  @override
  String get libraryPrivacyNote => 'تبقى مكتبتك على جهازك.';

  @override
  String get artistEyebrow => 'الفنان';

  @override
  String artistAlbumCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ألبوم',
      many: '$count ألبومًا',
      few: '$count ألبومات',
      two: 'ألبومان',
      one: 'ألبوم واحد',
      zero: 'لا ألبومات',
    );
    return '$_temp0';
  }

  @override
  String get artistMostPlayed => 'الأكثر تشغيلًا';

  @override
  String get artistAlbumsHeader => 'الألبومات';

  @override
  String get searchHint => 'المقطوعات، الألبومات، الفنانون';

  @override
  String get searchEmptyLibrary => 'استورد صوتيات لبدء إنشاء مكتبتك.';

  @override
  String get searchNoResults => 'لا نتائج';

  @override
  String get searchContextLabel => 'بحث';

  @override
  String get settingsTitle => 'الإعدادات';

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
  String get settingsStorageUsed => 'التخزين المستخدَم';

  @override
  String get settingsSectionPlayback => 'التشغيل';

  @override
  String get settingsRememberPosition => 'تذكُّر موضع التشغيل';

  @override
  String get settingsKeepPlayingWhenClosed =>
      'الاستمرار في التشغيل عند إغلاق التطبيق';

  @override
  String get settingsSectionDebug => 'تصحيح الأخطاء (إصدارات التصحيح فقط)';

  @override
  String get settingsImportTestFiles => 'استيراد ملفات الاختبار المرسَلة';

  @override
  String settingsDebugAddedSkipped(int added, int skipped) {
    return 'أُضيف $added، وتم تخطي $skipped';
  }

  @override
  String get settingsSectionAbout => 'حول التطبيق';

  @override
  String get settingsVersion => 'الإصدار';

  @override
  String get settingsFooterNote =>
      'تُخزَّن المقطوعات المستوردة محليًا. تتطلب التنزيلات اتصالًا بالإنترنت.';

  @override
  String get settingsAppearance => 'المظهر';

  @override
  String get settingsThemeLight => 'فاتح';

  @override
  String get settingsThemeDark => 'داكن';

  @override
  String get settingsThemeSystem => 'النظام';

  @override
  String get newPlaylistTitle => 'قائمة تشغيل جديدة';

  @override
  String get newPlaylistCreate => 'إنشاء';

  @override
  String get newPlaylistNameHint => 'اسم قائمة التشغيل';

  @override
  String get newPlaylistArtworkHintChange => 'اضغط على الغلاف لتغييره.';

  @override
  String get newPlaylistArtworkHintAdd =>
      'اضغط على الغلاف لإضافة صورة، أو اتركه وسيتم إنشاء غلاف تلقائيًا من المقطوعات التي تضيفها.';

  @override
  String get playlistDeleted => 'تم حذف قائمة التشغيل';

  @override
  String get playlistMenuRename => 'إعادة تسمية';

  @override
  String get playlistMenuChangeArtwork => 'تغيير الغلاف';

  @override
  String get playlistMenuRemoveArtwork => 'إزالة الغلاف';

  @override
  String get playlistMenuDeletePlaylist => 'حذف قائمة التشغيل';

  @override
  String playlistCreatedOn(String date) {
    return 'أُنشئت في $date';
  }

  @override
  String get playlistAddTracksButton => 'إضافة مقطوعات';

  @override
  String get playlistEmptyTracks =>
      'لا توجد مقطوعات بعد — اضغط على \"إضافة مقطوعات\" لبناء قائمة التشغيل هذه.';

  @override
  String get playlistRenameDialogTitle => 'إعادة تسمية قائمة التشغيل';

  @override
  String get playlistDeleteDialogTitle => 'حذف قائمة التشغيل؟';

  @override
  String playlistDeleteDialogBody(String name) {
    return 'سيتم حذف \"$name\". ستبقى المقطوعات في مكتبتك.';
  }

  @override
  String get playlistsPickTracksLater => 'اختر المقطوعات لاحقًا';

  @override
  String get queueTitle => 'قائمة الانتظار';

  @override
  String get queueNowPlaying => 'قيد التشغيل الآن';

  @override
  String get queuePlayingNext => 'التالي في التشغيل';

  @override
  String get queueNothingQueued => 'لا شيء في قائمة الانتظار.';

  @override
  String queueThenContinuesFrom(String source) {
    return 'ثم يتابع من $source';
  }

  @override
  String get nowPlayingNothingPlaying => 'لا يوجد تشغيل حاليًا';

  @override
  String nowPlayingFrom(String source) {
    return 'يتم التشغيل من $source';
  }

  @override
  String get nowPlayingMoreOptionsTooltip => 'المزيد من الخيارات';

  @override
  String get nowPlayingAddFavoriteTooltip => 'إضافة إلى المفضلة';

  @override
  String get nowPlayingRemoveFavoriteTooltip => 'إزالة من المفضلة';

  @override
  String get nowPlayingPreviousTrackTooltip => 'المقطوعة السابقة';

  @override
  String get nowPlayingShuffleOn => 'التشغيل العشوائي: مفعّل';

  @override
  String get nowPlayingShuffleOff => 'التشغيل العشوائي: متوقف';

  @override
  String get nowPlayingRepeatTrack => 'المقطوعة';

  @override
  String get nowPlayingRepeatQueue => 'قائمة الانتظار';

  @override
  String get nowPlayingPlaybackDeviceTooltip => 'جهاز التشغيل';

  @override
  String get nowPlayingPlaybackDeviceMessage =>
      'استخدم إعدادات البلوتوث/الإخراج في جهازك لتبديل جهاز التشغيل.';

  @override
  String get nowPlayingRewind10Tooltip => 'إرجاع 10 ثوانٍ';

  @override
  String get nowPlayingForward10Tooltip => 'التقديم 10 ثوانٍ';

  @override
  String bulkAddToPlaylistTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'إضافة $count مقطوعة إلى قائمة التشغيل',
      one: 'إضافة إلى قائمة التشغيل',
    );
    return '$_temp0';
  }

  @override
  String bulkDeleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'حذف $count مقطوعة؟',
      two: 'حذف مقطوعتين؟',
      one: 'حذف مقطوعة واحدة؟',
    );
    return '$_temp0';
  }

  @override
  String get bulkDeleteChooseHow => 'اختر كيفية إزالتها.';

  @override
  String get contextMenuPlayNow => 'تشغيل الآن';

  @override
  String get contextMenuPlayNext => 'تشغيل التالي';

  @override
  String get contextMenuAddToQueue => 'إضافة إلى قائمة الانتظار';

  @override
  String get contextMenuAddToPlaylistEllipsis => 'إضافة إلى قائمة التشغيل…';

  @override
  String get contextMenuFavorite => 'إضافة للمفضلة';

  @override
  String get contextMenuRemoveFavorite => 'إزالة من المفضلة';

  @override
  String get contextMenuViewAlbum => 'عرض الألبوم';

  @override
  String get contextMenuViewArtist => 'عرض الفنان';

  @override
  String get renameTrackDialogTitle => 'إعادة تسمية المقطوعة';

  @override
  String get renameTrackHint => 'العنوان';

  @override
  String get renameAlbumDialogTitle => 'إعادة تسمية الألبوم';

  @override
  String get renameAlbumHint => 'اسم الألبوم';

  @override
  String renameAlbumCollisionMessage(String name, String albumArtist) {
    return 'يوجد بالفعل ألبوم باسم \"$name\" لـ$albumArtist.';
  }

  @override
  String get deleteFromDeviceDialogTitle => 'الحذف من الجهاز؟';

  @override
  String deleteFromDeviceDialogBody(String title) {
    return 'سيتم حذف \"$title\" نهائيًا ولا يمكن استرجاعه.';
  }

  @override
  String get miniPlayerDismissTooltip => 'إغلاق';

  @override
  String get songRowOptionsTooltip => 'خيارات المقطوعة';

  @override
  String songRowDeleteDialogTitle(String title) {
    return 'حذف \"$title\"؟';
  }

  @override
  String get deviceBrowserTitle => 'اختيار الصوتيات';

  @override
  String deviceBrowserImportButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'استيراد $count مقطوعة',
      one: 'استيراد مقطوعة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get deviceBrowserPermissionTitle => 'الوصول إلى الصوتيات مطلوب';

  @override
  String get deviceBrowserPermissionMessage =>
      'يحتاج Listeny إلى إذن للوصول إلى الملفات الصوتية على جهازك. امنحه من الإعدادات لتصفح صوتياتك واستيرادها.';

  @override
  String get deviceBrowserOpenSettings => 'فتح الإعدادات';

  @override
  String get deviceBrowserErrorTitle => 'تعذّرت قراءة الصوتيات';

  @override
  String get deviceBrowserUnknownError => 'حدث خطأ غير معروف.';

  @override
  String get deviceBrowserRetry => 'إعادة المحاولة';

  @override
  String get deviceBrowserNoAudioTitle => 'لم يُعثر على ملفات صوتية';

  @override
  String get deviceBrowserNoAudioMessage =>
      'أضِف صوتيات إلى جهازك (تنزيلات، عمليات نقل، إلخ) ثم اسحب للأسفل لإعادة المحاولة.';

  @override
  String get deviceBrowserSearchHint => 'البحث في صوتياتك';

  @override
  String get deviceBrowserNoMatches => 'لا تطابقات';

  @override
  String get deviceBrowserSelectAll => 'تحديد الكل';

  @override
  String get deviceBrowserDeselectAll => 'إلغاء تحديد الكل';

  @override
  String get importFlowContextWhatsNew => 'الجديد';

  @override
  String get importFlowImportingTitle => 'جارٍ استيراد الصوتيات';

  @override
  String importFlowProcessedOfTotal(int processed, int total) {
    return '$processed من $total ملفًا · جارٍ قراءة البيانات الوصفية';
  }

  @override
  String get importFlowCopiedNote =>
      'تم النسخ داخل التطبيق — الملفات الأصلية لم تتأثر.';

  @override
  String importFlowAddedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تمت إضافة $count مقطوعة',
      one: 'تمت إضافة مقطوعة واحدة',
    );
    return '$_temp0';
  }

  @override
  String importFlowArtistsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فنان',
      two: 'فنانان',
      one: 'فنان واحد',
    );
    return '$_temp0';
  }

  @override
  String importFlowDuplicatesSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم تخطي $count عنصر مكرر',
      one: 'تم تخطي عنصر مكرر واحد',
    );
    return '$_temp0';
  }

  @override
  String get importFlowAlreadyInLibrary => 'موجود بالفعل في مكتبتك';

  @override
  String importFlowUnsupportedSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ملف غير مدعوم',
      one: 'ملف واحد غير مدعوم',
    );
    return '$_temp0';
  }

  @override
  String importFlowCorruptSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تعذّرت قراءة $count ملف',
      one: 'تعذّرت قراءة ملف واحد',
    );
    return '$_temp0';
  }

  @override
  String get importFlowPlayWhatsNew => 'تشغيل الجديد';

  @override
  String get downloadInstructions =>
      'الصق رابطاً مباشراً لملف صوتي أو فيديو — MP3 وM4A وAAC وWAV وFLAC وOGG وMP4 وWebM.';

  @override
  String get downloadUrlHint => 'https://example.com/track.mp3';

  @override
  String get downloadPasteTooltip => 'لصق';

  @override
  String get downloadInvalidUrlError => 'الصق رابطًا صالحًا لملف وسائط.';

  @override
  String get downloadFormatLabel => 'الصيغة';

  @override
  String get downloadFormatBestAvailable => 'أفضل جودة صوت متاحة';

  @override
  String get downloadFormatMp3 => 'MP3';

  @override
  String get downloadAnotherButton => 'تنزيل ملف آخر';

  @override
  String get downloadAudioButton => 'تنزيل الصوت';

  @override
  String get downloadResolvingLink => 'جارٍ تحليل الرابط…';

  @override
  String get downloadDownloadingIndeterminate => 'جارٍ التنزيل…';

  @override
  String downloadDownloadingPercent(int percent) {
    return 'جارٍ التنزيل $percent%';
  }

  @override
  String get downloadConverting => 'جارٍ التحويل…';

  @override
  String get downloadImporting => 'جارٍ الاستيراد إلى مكتبتك…';

  @override
  String get downloadCancelled => 'تم الإلغاء.';

  @override
  String get downloadQueued => 'بانتظار دور التنزيل…';

  @override
  String get downloadRemoveTooltip => 'إزالة';

  @override
  String get downloadGenericError => 'حدث خطأ ما. يرجى إعادة المحاولة.';

  @override
  String downloadAddedToLibrary(String title) {
    return '✓ أُضيف إلى مكتبتك\n$title';
  }

  @override
  String get downloadNothingNewAdded =>
      'لم يُضِف هذا الرابط أي جديد إلى مكتبتك.';

  @override
  String get downloadHistoryTitle => 'سجل التنزيلات';

  @override
  String get downloadHistoryEmpty => 'سيظهر سجل تنزيلاتك هنا.';

  @override
  String get downloadClearHistoryDialogTitle => 'مسح سجل التنزيلات؟';

  @override
  String get downloadClearHistoryDialogBody =>
      'يؤدي هذا فقط إلى مسح قائمة السجل — ولا يُزيل أي مقطوعات.';

  @override
  String get downloadSourceDirectLink => 'رابط مباشر';

  @override
  String get trimMenuLabel => 'قص';

  @override
  String get trimTitle => 'قص المقطع الصوتي';

  @override
  String get trimStartLabel => 'البداية';

  @override
  String get trimEndLabel => 'النهاية';

  @override
  String get trimLengthLabel => 'المدة';

  @override
  String get trimPreviewFromLabel => 'المعاينة من';

  @override
  String get trimPreview => 'معاينة';

  @override
  String get trimStopPreview => 'إيقاف المعاينة';

  @override
  String get trimFadeLabel => 'تلاشي عند البداية والنهاية';

  @override
  String get trimFadeOff => 'بدون';

  @override
  String get trimSaveNew => 'حفظ كمقطع جديد';

  @override
  String get trimReplaceOriginal => 'استبدال الأصلي';

  @override
  String get trimSaved => 'تم حفظ المقطع المقصوص';

  @override
  String get trimReplaced => 'تم استبدال الأصلي بالمقطع المقصوص';

  @override
  String get trimFailed => 'تعذر قص هذا الملف';

  @override
  String get trimTooShort => 'اختر ثانية واحدة على الأقل';

  @override
  String get trimDuplicate => 'هذا المقطع موجود بالفعل في مكتبتك';

  @override
  String get trimWorking => 'جارٍ القص…';

  @override
  String get importVideoButton => 'استيراد فيديو كـ MP3';

  @override
  String get importVideoConverting => 'جارٍ تحويل الفيديو إلى MP3…';

  @override
  String get importVideoDone => 'تمت الإضافة إلى مكتبتك بصيغة MP3';

  @override
  String get importVideoFailed => 'تعذر استخراج الصوت من هذا الفيديو';

  @override
  String get importVideoDuplicate => 'هذا المقطع موجود بالفعل في مكتبتك';

  @override
  String get importVideoFromGallery => 'من الاستوديو / الصور';

  @override
  String get importVideoFromFiles => 'من الملفات';

  @override
  String get importVideoNameTitle => 'سمِّ هذا المقطع';

  @override
  String get importVideoNameHint => 'اسم المقطع';
}
