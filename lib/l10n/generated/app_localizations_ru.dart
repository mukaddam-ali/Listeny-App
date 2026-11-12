// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get commonPlay => 'Воспроизвести';

  @override
  String get commonPause => 'Пауза';

  @override
  String get commonShuffle => 'Перемешать';

  @override
  String get commonCancel => 'Отмена';

  @override
  String get commonSave => 'Сохранить';

  @override
  String get commonDone => 'Готово';

  @override
  String get commonClear => 'Очистить';

  @override
  String get commonDelete => 'Удалить';

  @override
  String get commonAddToPlaylistTooltip => 'Добавить в плейлист';

  @override
  String commonSelectedCount(int count) {
    return 'Выбрано: $count';
  }

  @override
  String commonTrackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count трека',
      many: '$count треков',
      few: '$count трека',
      one: '$count трек',
    );
    return '$_temp0';
  }

  @override
  String get commonNoFavoritesYet =>
      'Пока нет избранного. Нажмите на сердечко у трека, чтобы добавить его.';

  @override
  String get commonRemoveFromLibrary => 'Удалить из библиотеки';

  @override
  String get commonDeleteFromDevice => 'Удалить с устройства';

  @override
  String get commonNextTrack => 'Следующий трек';

  @override
  String get commonSearchTooltip => 'Поиск';

  @override
  String get commonImportTooltip => 'Импорт';

  @override
  String get navLibrary => 'Библиотека';

  @override
  String get navPlaylists => 'Плейлисты';

  @override
  String get navSearch => 'Поиск';

  @override
  String get navDownload => 'Загрузка';

  @override
  String get navSettings => 'Настройки';

  @override
  String get formatJustNow => 'Только что';

  @override
  String formatMinutesAgo(int minutes) {
    return '$minutes мин назад';
  }

  @override
  String formatHoursAgo(int hours) {
    return '$hours ч назад';
  }

  @override
  String formatDaysAgo(int days) {
    return '$days дн назад';
  }

  @override
  String formatHoursMinutes(int hours, int minutes) {
    return '$hours ч $minutes мин';
  }

  @override
  String formatMinutesOnly(int minutes) {
    return '$minutes мин';
  }

  @override
  String get libraryTitle => 'Библиотека';

  @override
  String get libraryExitSelectionTooltip => 'Выйти из режима выбора';

  @override
  String get libraryRecentlyAdded => 'Недавно добавленные';

  @override
  String get libraryFilterTracks => 'Треки';

  @override
  String get libraryFilterAlbums => 'Альбомы';

  @override
  String get libraryFilterRecentlyPlayed => 'Недавно прослушанные';

  @override
  String get libraryFilterFavorites => 'Избранное';

  @override
  String get libraryRecentlyPlayedEmpty =>
      'Здесь будут отображаться прослушанные вами треки';

  @override
  String get libraryEmptyTitle => 'Пока нет треков';

  @override
  String get libraryEmptyBody =>
      'Импортируйте аудио из приложения «Файлы», чтобы начать собирать библиотеку.';

  @override
  String get libraryImportAudioButton => 'Импортировать аудио';

  @override
  String get libraryPrivacyNote =>
      'Ваша библиотека остаётся на вашем устройстве.';

  @override
  String get artistEyebrow => 'ИСПОЛНИТЕЛЬ';

  @override
  String artistAlbumCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count альбома',
      many: '$count альбомов',
      few: '$count альбома',
      one: '$count альбом',
    );
    return '$_temp0';
  }

  @override
  String get artistMostPlayed => 'Популярные треки';

  @override
  String get artistAlbumsHeader => 'Альбомы';

  @override
  String get searchHint => 'Треки, альбомы, исполнители';

  @override
  String get searchEmptyLibrary =>
      'Импортируйте аудио, чтобы начать собирать библиотеку.';

  @override
  String get searchNoResults => 'Ничего не найдено';

  @override
  String get searchContextLabel => 'Поиск';

  @override
  String get settingsTitle => 'Настройки';

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
  String get settingsStorageUsed => 'Использовано места';

  @override
  String get settingsSectionPlayback => 'Воспроизведение';

  @override
  String get settingsRememberPosition => 'Запоминать позицию воспроизведения';

  @override
  String get settingsKeepPlayingWhenClosed =>
      'Продолжать воспроизведение при закрытом приложении';

  @override
  String get settingsSectionDebug => 'Отладка (только для отладочных сборок)';

  @override
  String get settingsImportTestFiles =>
      'Импортировать отправленные тестовые файлы';

  @override
  String settingsDebugAddedSkipped(int added, int skipped) {
    return 'Добавлено: $added, пропущено: $skipped';
  }

  @override
  String get settingsSectionAbout => 'О приложении';

  @override
  String get settingsVersion => 'Версия';

  @override
  String get settingsFooterNote =>
      'Импортированные треки хранятся локально. Для загрузок требуется доступ в интернет.';

  @override
  String get settingsAppearance => 'ВНЕШНИЙ ВИД';

  @override
  String get settingsThemeLight => 'Светлая';

  @override
  String get settingsThemeDark => 'Тёмная';

  @override
  String get settingsThemeSystem => 'Системная';

  @override
  String get newPlaylistTitle => 'Новый плейлист';

  @override
  String get newPlaylistCreate => 'Создать';

  @override
  String get newPlaylistNameHint => 'Название плейлиста';

  @override
  String get newPlaylistArtworkHintChange =>
      'Нажмите на обложку, чтобы изменить её.';

  @override
  String get newPlaylistArtworkHintAdd =>
      'Нажмите на обложку, чтобы добавить фото, или оставьте так — она будет сгенерирована из добавленных треков.';

  @override
  String get playlistDeleted => 'Плейлист удалён';

  @override
  String get playlistMenuRename => 'Переименовать';

  @override
  String get playlistMenuChangeArtwork => 'Изменить обложку';

  @override
  String get playlistMenuRemoveArtwork => 'Удалить обложку';

  @override
  String get playlistMenuDeletePlaylist => 'Удалить плейлист';

  @override
  String playlistCreatedOn(String date) {
    return 'Создан $date';
  }

  @override
  String get playlistAddTracksButton => 'Добавить треки';

  @override
  String get playlistEmptyTracks =>
      'Пока нет треков — нажмите «Добавить треки», чтобы наполнить этот плейлист.';

  @override
  String get playlistRenameDialogTitle => 'Переименовать плейлист';

  @override
  String get playlistDeleteDialogTitle => 'Удалить плейлист?';

  @override
  String playlistDeleteDialogBody(String name) {
    return '«$name» будет удалён. Треки останутся в вашей библиотеке.';
  }

  @override
  String get playlistsPickTracksLater => 'Выбрать треки позже';

  @override
  String get queueTitle => 'Очередь';

  @override
  String get queueNowPlaying => 'СЕЙЧАС ИГРАЕТ';

  @override
  String get queuePlayingNext => 'ДАЛЕЕ';

  @override
  String get queueNothingQueued => 'В очереди пусто.';

  @override
  String queueThenContinuesFrom(String source) {
    return 'ЗАТЕМ ПРОДОЛЖИТСЯ ИЗ $source';
  }

  @override
  String get nowPlayingNothingPlaying => 'Ничего не воспроизводится';

  @override
  String nowPlayingFrom(String source) {
    return 'ВОСПРОИЗВЕДЕНИЕ ИЗ $source';
  }

  @override
  String get nowPlayingMoreOptionsTooltip => 'Дополнительные параметры';

  @override
  String get nowPlayingAddFavoriteTooltip => 'Добавить в избранное';

  @override
  String get nowPlayingRemoveFavoriteTooltip => 'Убрать из избранного';

  @override
  String get nowPlayingPreviousTrackTooltip => 'Предыдущий трек';

  @override
  String get nowPlayingShuffleOn => 'Перемешивание: вкл.';

  @override
  String get nowPlayingShuffleOff => 'Перемешивание: выкл.';

  @override
  String get nowPlayingRepeatTrack => 'Трек';

  @override
  String get nowPlayingRepeatQueue => 'Очередь';

  @override
  String get nowPlayingPlaybackDeviceTooltip => 'Устройство воспроизведения';

  @override
  String get nowPlayingPlaybackDeviceMessage =>
      'Используйте настройки Bluetooth/вывода звука на вашем устройстве, чтобы переключить устройство воспроизведения.';

  @override
  String get nowPlayingRewind10Tooltip => 'Назад на 10 секунд';

  @override
  String get nowPlayingForward10Tooltip => 'Вперёд на 10 секунд';

  @override
  String bulkAddToPlaylistTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Добавить $count трека в плейлист',
      many: 'Добавить $count треков в плейлист',
      few: 'Добавить $count трека в плейлист',
      one: 'Добавить в плейлист',
    );
    return '$_temp0';
  }

  @override
  String bulkDeleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Удалить $count трека?',
      many: 'Удалить $count треков?',
      few: 'Удалить $count трека?',
      one: 'Удалить $count трек?',
    );
    return '$_temp0';
  }

  @override
  String get bulkDeleteChooseHow => 'Выберите способ удаления.';

  @override
  String get contextMenuPlayNow => 'Воспроизвести сейчас';

  @override
  String get contextMenuPlayNext => 'Воспроизвести следующим';

  @override
  String get contextMenuAddToQueue => 'Добавить в очередь';

  @override
  String get contextMenuAddToPlaylistEllipsis => 'Добавить в плейлист…';

  @override
  String get contextMenuFavorite => 'В избранное';

  @override
  String get contextMenuRemoveFavorite => 'Убрать из избранного';

  @override
  String get contextMenuViewAlbum => 'Открыть альбом';

  @override
  String get contextMenuViewArtist => 'Открыть исполнителя';

  @override
  String get renameTrackDialogTitle => 'Переименовать трек';

  @override
  String get renameTrackHint => 'Название';

  @override
  String get renameAlbumDialogTitle => 'Переименовать альбом';

  @override
  String get renameAlbumHint => 'Название альбома';

  @override
  String renameAlbumCollisionMessage(String name, String albumArtist) {
    return 'Альбом с названием «$name» исполнителя $albumArtist уже существует.';
  }

  @override
  String get deleteFromDeviceDialogTitle => 'Удалить с устройства?';

  @override
  String deleteFromDeviceDialogBody(String title) {
    return '«$title» будет удалён без возможности восстановления.';
  }

  @override
  String get miniPlayerDismissTooltip => 'Закрыть';

  @override
  String get songRowOptionsTooltip => 'Параметры трека';

  @override
  String songRowDeleteDialogTitle(String title) {
    return 'Удалить «$title»?';
  }

  @override
  String get deviceBrowserTitle => 'Выбор аудио';

  @override
  String deviceBrowserImportButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Импортировать $count трека',
      many: 'Импортировать $count треков',
      few: 'Импортировать $count трека',
      one: 'Импортировать $count трек',
    );
    return '$_temp0';
  }

  @override
  String get deviceBrowserPermissionTitle => 'Требуется доступ к аудио';

  @override
  String get deviceBrowserPermissionMessage =>
      'Listeny нужно разрешение для просмотра аудиофайлов на вашем устройстве. Предоставьте его в Настройках, чтобы просматривать и импортировать аудио.';

  @override
  String get deviceBrowserOpenSettings => 'Открыть настройки';

  @override
  String get deviceBrowserErrorTitle => 'Не удалось прочитать аудио';

  @override
  String get deviceBrowserUnknownError => 'Произошла неизвестная ошибка.';

  @override
  String get deviceBrowserRetry => 'Повторить';

  @override
  String get deviceBrowserNoAudioTitle => 'Аудиофайлы не найдены';

  @override
  String get deviceBrowserNoAudioMessage =>
      'Добавьте аудио на устройство (загрузки, передача файлов и т. д.) и потяните вниз, чтобы повторить попытку.';

  @override
  String get deviceBrowserSearchHint => 'Поиск по вашему аудио';

  @override
  String get deviceBrowserNoMatches => 'Совпадений нет';

  @override
  String get deviceBrowserSelectAll => 'Выбрать всё';

  @override
  String get deviceBrowserDeselectAll => 'Снять выбор';

  @override
  String get importFlowContextWhatsNew => 'Что нового';

  @override
  String get importFlowImportingTitle => 'Импорт аудио';

  @override
  String importFlowProcessedOfTotal(int processed, int total) {
    return '$processed из $total файлов · чтение метаданных';
  }

  @override
  String get importFlowCopiedNote =>
      'Скопировано в приложение — исходные файлы не изменены.';

  @override
  String importFlowAddedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Добавлено $count трека',
      many: 'Добавлено $count треков',
      few: 'Добавлено $count трека',
      one: 'Добавлен $count трек',
    );
    return '$_temp0';
  }

  @override
  String importFlowArtistsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count исполнителя',
      many: '$count исполнителей',
      few: '$count исполнителя',
      one: '$count исполнитель',
    );
    return '$_temp0';
  }

  @override
  String importFlowDuplicatesSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Пропущено $count дубликата',
      many: 'Пропущено $count дубликатов',
      few: 'Пропущено $count дубликата',
      one: 'Пропущен $count дубликат',
    );
    return '$_temp0';
  }

  @override
  String get importFlowAlreadyInLibrary => 'Уже в вашей библиотеке';

  @override
  String importFlowUnsupportedSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count файла не поддерживаются',
      many: '$count файлов не поддерживаются',
      few: '$count файла не поддерживаются',
      one: '$count файл не поддерживается',
    );
    return '$_temp0';
  }

  @override
  String importFlowCorruptSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count файла не удалось прочитать',
      many: '$count файлов не удалось прочитать',
      few: '$count файла не удалось прочитать',
      one: '$count файл не удалось прочитать',
    );
    return '$_temp0';
  }

  @override
  String get importFlowPlayWhatsNew => 'Воспроизвести новое';

  @override
  String get downloadInstructions =>
      'Вставьте прямую ссылку на аудио- или видеофайл — MP3, M4A, AAC, WAV, FLAC, OGG, MP4, WebM.';

  @override
  String get downloadUrlHint => 'https://example.com/track.mp3';

  @override
  String get downloadPasteTooltip => 'Вставить';

  @override
  String get downloadInvalidUrlError =>
      'Вставьте корректную ссылку на медиафайл.';

  @override
  String get downloadFormatLabel => 'Формат';

  @override
  String get downloadFormatBestAvailable => 'Лучшее доступное качество звука';

  @override
  String get downloadFormatMp3 => 'MP3';

  @override
  String get downloadAnotherButton => 'Загрузить ещё';

  @override
  String get downloadAudioButton => 'Загрузить аудио';

  @override
  String get downloadResolvingLink => 'Обработка ссылки…';

  @override
  String get downloadDownloadingIndeterminate => 'Загрузка…';

  @override
  String downloadDownloadingPercent(int percent) {
    return 'Загрузка $percent%';
  }

  @override
  String get downloadConverting => 'Преобразование…';

  @override
  String get downloadImporting => 'Импорт в вашу библиотеку…';

  @override
  String get downloadCancelled => 'Отменено.';

  @override
  String get downloadQueued => 'Ожидание свободного слота…';

  @override
  String get downloadRemoveTooltip => 'Убрать';

  @override
  String get downloadGenericError => 'Что-то пошло не так. Попробуйте снова.';

  @override
  String downloadAddedToLibrary(String title) {
    return '✓ Добавлено в вашу библиотеку\n$title';
  }

  @override
  String get downloadNothingNewAdded =>
      'Эта ссылка не добавила ничего нового в вашу библиотеку.';

  @override
  String get downloadHistoryTitle => 'История загрузок';

  @override
  String get downloadHistoryEmpty =>
      'Здесь будет отображаться история загрузок.';

  @override
  String get downloadClearHistoryDialogTitle => 'Очистить историю загрузок?';

  @override
  String get downloadClearHistoryDialogBody =>
      'Это только очистит список истории — треки удалены не будут.';

  @override
  String get downloadSourceDirectLink => 'Прямая ссылка';

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
