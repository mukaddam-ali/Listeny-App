// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get commonPlay => 'Reproducir';

  @override
  String get commonPause => 'Pausar';

  @override
  String get commonShuffle => 'Aleatorio';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonDone => 'Listo';

  @override
  String get commonClear => 'Borrar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonAddToPlaylistTooltip => 'Añadir a lista';

  @override
  String commonSelectedCount(int count) {
    return '$count seleccionados';
  }

  @override
  String commonTrackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pistas',
      one: '1 pista',
    );
    return '$_temp0';
  }

  @override
  String get commonNoFavoritesYet =>
      'Aún no tienes favoritos. Toca el corazón de una pista para añadirla.';

  @override
  String get commonRemoveFromLibrary => 'Quitar de la biblioteca';

  @override
  String get commonDeleteFromDevice => 'Eliminar del dispositivo';

  @override
  String get commonNextTrack => 'Pista siguiente';

  @override
  String get commonSearchTooltip => 'Buscar';

  @override
  String get commonImportTooltip => 'Importar';

  @override
  String get navLibrary => 'Biblioteca';

  @override
  String get navPlaylists => 'Listas';

  @override
  String get navSearch => 'Buscar';

  @override
  String get navDownload => 'Descargar';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get formatJustNow => 'Justo ahora';

  @override
  String formatMinutesAgo(int minutes) {
    return 'hace $minutes min';
  }

  @override
  String formatHoursAgo(int hours) {
    return 'hace $hours h';
  }

  @override
  String formatDaysAgo(int days) {
    return 'hace $days d';
  }

  @override
  String formatHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String formatMinutesOnly(int minutes) {
    return '$minutes min';
  }

  @override
  String get libraryTitle => 'Biblioteca';

  @override
  String get libraryExitSelectionTooltip => 'Salir de la selección';

  @override
  String get libraryRecentlyAdded => 'Añadidos recientemente';

  @override
  String get libraryFilterTracks => 'Pistas';

  @override
  String get libraryFilterAlbums => 'Álbumes';

  @override
  String get libraryFilterRecentlyPlayed => 'Reproducidos recientemente';

  @override
  String get libraryFilterFavorites => 'Favoritos';

  @override
  String get libraryRecentlyPlayedEmpty =>
      'Las pistas que reproduzcas aparecerán aquí';

  @override
  String get libraryEmptyTitle => 'Aún no hay pistas';

  @override
  String get libraryEmptyBody =>
      'Importa audio desde la app Archivos para empezar a crear tu biblioteca.';

  @override
  String get libraryImportAudioButton => 'Importar audio';

  @override
  String get libraryPrivacyNote => 'Tu biblioteca permanece en tu dispositivo.';

  @override
  String get artistEyebrow => 'ARTISTA';

  @override
  String artistAlbumCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count álbumes',
      one: '1 álbum',
    );
    return '$_temp0';
  }

  @override
  String get artistMostPlayed => 'Más reproducidas';

  @override
  String get artistAlbumsHeader => 'Álbumes';

  @override
  String get searchHint => 'Pistas, álbumes, artistas';

  @override
  String get searchEmptyLibrary =>
      'Importa audio para empezar a crear tu biblioteca.';

  @override
  String get searchNoResults => 'Sin resultados';

  @override
  String get searchContextLabel => 'Búsqueda';

  @override
  String get settingsTitle => 'Ajustes';

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
  String get settingsStorageUsed => 'Almacenamiento usado';

  @override
  String get settingsSectionPlayback => 'Reproducción';

  @override
  String get settingsRememberPosition => 'Recordar posición de reproducción';

  @override
  String get settingsKeepPlayingWhenClosed =>
      'Seguir reproduciendo cuando la app está cerrada';

  @override
  String get settingsSectionDebug =>
      'Depuración (solo compilaciones de depuración)';

  @override
  String get settingsImportTestFiles => 'Importar archivos de prueba';

  @override
  String settingsDebugAddedSkipped(int added, int skipped) {
    return 'Añadidas $added, omitidas $skipped';
  }

  @override
  String get settingsSectionAbout => 'Acerca de';

  @override
  String get settingsVersion => 'Versión';

  @override
  String get settingsFooterNote =>
      'Las pistas importadas se guardan localmente. Las descargas requieren conexión a internet.';

  @override
  String get settingsAppearance => 'APARIENCIA';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Oscuro';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get newPlaylistTitle => 'Nueva lista';

  @override
  String get newPlaylistCreate => 'Crear';

  @override
  String get newPlaylistNameHint => 'Nombre de la lista';

  @override
  String get newPlaylistArtworkHintChange => 'Toca la portada para cambiarla.';

  @override
  String get newPlaylistArtworkHintAdd =>
      'Toca la portada para añadir una foto, o déjala y se generará una a partir de las pistas que añadas.';

  @override
  String get playlistDeleted => 'Lista eliminada';

  @override
  String get playlistMenuRename => 'Cambiar nombre';

  @override
  String get playlistMenuChangeArtwork => 'Cambiar portada';

  @override
  String get playlistMenuRemoveArtwork => 'Quitar portada';

  @override
  String get playlistMenuDeletePlaylist => 'Eliminar lista';

  @override
  String playlistCreatedOn(String date) {
    return 'Creada el $date';
  }

  @override
  String get playlistAddTracksButton => 'Añadir pistas';

  @override
  String get playlistEmptyTracks =>
      'Aún no hay pistas: toca \"Añadir pistas\" para crear esta lista.';

  @override
  String get playlistRenameDialogTitle => 'Cambiar nombre de la lista';

  @override
  String get playlistDeleteDialogTitle => '¿Eliminar lista?';

  @override
  String playlistDeleteDialogBody(String name) {
    return '\"$name\" se eliminará. Las pistas permanecerán en tu biblioteca.';
  }

  @override
  String get playlistsPickTracksLater => 'Elegir pistas más tarde';

  @override
  String get queueTitle => 'Cola';

  @override
  String get queueNowPlaying => 'REPRODUCIENDO AHORA';

  @override
  String get queuePlayingNext => 'A CONTINUACIÓN';

  @override
  String get queueNothingQueued => 'No hay nada en cola.';

  @override
  String queueThenContinuesFrom(String source) {
    return 'LUEGO CONTINÚA DESDE $source';
  }

  @override
  String get nowPlayingNothingPlaying => 'No hay nada reproduciéndose';

  @override
  String nowPlayingFrom(String source) {
    return 'REPRODUCIENDO DESDE $source';
  }

  @override
  String get nowPlayingMoreOptionsTooltip => 'Más opciones';

  @override
  String get nowPlayingAddFavoriteTooltip => 'Añadir a favoritos';

  @override
  String get nowPlayingRemoveFavoriteTooltip => 'Quitar de favoritos';

  @override
  String get nowPlayingPreviousTrackTooltip => 'Pista anterior';

  @override
  String get nowPlayingShuffleOn => 'Aleatorio: activado';

  @override
  String get nowPlayingShuffleOff => 'Aleatorio: desactivado';

  @override
  String get nowPlayingRepeatTrack => 'Pista';

  @override
  String get nowPlayingRepeatQueue => 'Cola';

  @override
  String get nowPlayingPlaybackDeviceTooltip => 'Dispositivo de reproducción';

  @override
  String get nowPlayingPlaybackDeviceMessage =>
      'Usa los ajustes de Bluetooth/salida de tu dispositivo para cambiar el dispositivo de reproducción.';

  @override
  String get nowPlayingRewind10Tooltip => 'Retroceder 10 segundos';

  @override
  String get nowPlayingForward10Tooltip => 'Avanzar 10 segundos';

  @override
  String bulkAddToPlaylistTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Añadir $count pistas a la lista',
      one: 'Añadir a lista',
    );
    return '$_temp0';
  }

  @override
  String bulkDeleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¿Eliminar $count pistas?',
      one: '¿Eliminar 1 pista?',
    );
    return '$_temp0';
  }

  @override
  String get bulkDeleteChooseHow => 'Elige cómo quitarlas.';

  @override
  String get contextMenuPlayNow => 'Reproducir ahora';

  @override
  String get contextMenuPlayNext => 'Reproducir a continuación';

  @override
  String get contextMenuAddToQueue => 'Añadir a la cola';

  @override
  String get contextMenuAddToPlaylistEllipsis => 'Añadir a lista…';

  @override
  String get contextMenuFavorite => 'Favorito';

  @override
  String get contextMenuRemoveFavorite => 'Quitar de favoritos';

  @override
  String get contextMenuViewAlbum => 'Ver álbum';

  @override
  String get contextMenuViewArtist => 'Ver artista';

  @override
  String get renameTrackDialogTitle => 'Renombrar pista';

  @override
  String get renameTrackHint => 'Título';

  @override
  String get renameAlbumDialogTitle => 'Renombrar álbum';

  @override
  String get renameAlbumHint => 'Nombre del álbum';

  @override
  String renameAlbumCollisionMessage(String name, String albumArtist) {
    return 'Ya existe un álbum llamado \"$name\" de $albumArtist.';
  }

  @override
  String get deleteFromDeviceDialogTitle => '¿Eliminar del dispositivo?';

  @override
  String deleteFromDeviceDialogBody(String title) {
    return '\"$title\" se eliminará permanentemente y no se podrá recuperar.';
  }

  @override
  String get miniPlayerDismissTooltip => 'Cerrar';

  @override
  String get songRowOptionsTooltip => 'Opciones de la pista';

  @override
  String songRowDeleteDialogTitle(String title) {
    return '¿Eliminar \"$title\"?';
  }

  @override
  String get deviceBrowserTitle => 'Elegir audio';

  @override
  String deviceBrowserImportButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importar $count pistas',
      one: 'Importar 1 pista',
    );
    return '$_temp0';
  }

  @override
  String get deviceBrowserPermissionTitle => 'Se necesita acceso al audio';

  @override
  String get deviceBrowserPermissionMessage =>
      'Listeny necesita permiso para ver los archivos de audio de tu dispositivo. Concédelo en Ajustes para explorar e importar tu audio.';

  @override
  String get deviceBrowserOpenSettings => 'Abrir Ajustes';

  @override
  String get deviceBrowserErrorTitle => 'No se pudo leer tu audio';

  @override
  String get deviceBrowserUnknownError => 'Ocurrió un error desconocido.';

  @override
  String get deviceBrowserRetry => 'Reintentar';

  @override
  String get deviceBrowserNoAudioTitle => 'No se encontraron archivos de audio';

  @override
  String get deviceBrowserNoAudioMessage =>
      'Añade audio a tu dispositivo (descargas, transferencias, etc.) y desliza hacia abajo para reintentar.';

  @override
  String get deviceBrowserSearchHint => 'Buscar en tu audio';

  @override
  String get deviceBrowserNoMatches => 'Sin coincidencias';

  @override
  String get deviceBrowserSelectAll => 'Seleccionar todo';

  @override
  String get deviceBrowserDeselectAll => 'Deseleccionar todo';

  @override
  String get importFlowContextWhatsNew => 'Novedades';

  @override
  String get importFlowImportingTitle => 'Importando audio';

  @override
  String importFlowProcessedOfTotal(int processed, int total) {
    return '$processed de $total archivos · leyendo metadatos';
  }

  @override
  String get importFlowCopiedNote =>
      'Copiado dentro de la app; los originales no se modificaron.';

  @override
  String importFlowAddedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pistas añadidas',
      one: '1 pista añadida',
    );
    return '$_temp0';
  }

  @override
  String importFlowArtistsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count artistas',
      one: '1 artista',
    );
    return '$_temp0';
  }

  @override
  String importFlowDuplicatesSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count duplicados omitidos',
      one: '1 duplicado omitido',
    );
    return '$_temp0';
  }

  @override
  String get importFlowAlreadyInLibrary => 'Ya está en tu biblioteca';

  @override
  String importFlowUnsupportedSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos no compatibles',
      one: '1 archivo no compatible',
    );
    return '$_temp0';
  }

  @override
  String importFlowCorruptSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos no se pudieron leer',
      one: '1 archivo no se pudo leer',
    );
    return '$_temp0';
  }

  @override
  String get importFlowPlayWhatsNew => 'Reproducir novedades';

  @override
  String get downloadInstructions =>
      'Pega un enlace directo a un archivo de audio o vídeo: MP3, M4A, AAC, WAV, FLAC, OGG, MP4, WebM.';

  @override
  String get downloadUrlHint => 'https://ejemplo.com/pista.mp3';

  @override
  String get downloadPasteTooltip => 'Pegar';

  @override
  String get downloadInvalidUrlError =>
      'Pega un enlace válido a un archivo multimedia.';

  @override
  String get downloadFormatLabel => 'Formato';

  @override
  String get downloadFormatBestAvailable => 'Mejor audio disponible';

  @override
  String get downloadFormatMp3 => 'MP3';

  @override
  String get downloadAnotherButton => 'Descargar otro';

  @override
  String get downloadAudioButton => 'Descargar audio';

  @override
  String get downloadResolvingLink => 'Resolviendo enlace…';

  @override
  String get downloadDownloadingIndeterminate => 'Descargando…';

  @override
  String downloadDownloadingPercent(int percent) {
    return 'Descargando $percent%';
  }

  @override
  String get downloadConverting => 'Convirtiendo…';

  @override
  String get downloadImporting => 'Importando a tu biblioteca…';

  @override
  String get downloadCancelled => 'Cancelado.';

  @override
  String get downloadQueued => 'Esperando un hueco libre…';

  @override
  String get downloadRemoveTooltip => 'Quitar';

  @override
  String get downloadGenericError => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String downloadAddedToLibrary(String title) {
    return '✓ Añadido a tu biblioteca\n$title';
  }

  @override
  String get downloadNothingNewAdded =>
      'Este enlace no añadió nada nuevo a tu biblioteca.';

  @override
  String get downloadHistoryTitle => 'Historial de descargas';

  @override
  String get downloadHistoryEmpty =>
      'Tu historial de descargas aparecerá aquí.';

  @override
  String get downloadClearHistoryDialogTitle =>
      '¿Borrar historial de descargas?';

  @override
  String get downloadClearHistoryDialogBody =>
      'Esto solo borra la lista de historial; no elimina ninguna pista.';

  @override
  String get downloadSourceDirectLink => 'Enlace directo';

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
