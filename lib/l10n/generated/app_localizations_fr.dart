// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get commonPlay => 'Lecture';

  @override
  String get commonPause => 'Pause';

  @override
  String get commonShuffle => 'Aléatoire';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonDone => 'Terminé';

  @override
  String get commonClear => 'Effacer';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonAddToPlaylistTooltip => 'Ajouter à la playlist';

  @override
  String commonSelectedCount(int count) {
    return '$count sélectionné(s)';
  }

  @override
  String commonTrackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres',
      one: '1 titre',
    );
    return '$_temp0';
  }

  @override
  String get commonNoFavoritesYet =>
      'Aucun favori pour l\'instant. Touchez le cœur d\'un titre pour l\'ajouter.';

  @override
  String get commonRemoveFromLibrary => 'Retirer de la bibliothèque';

  @override
  String get commonDeleteFromDevice => 'Supprimer de l\'appareil';

  @override
  String get commonNextTrack => 'Titre suivant';

  @override
  String get commonSearchTooltip => 'Rechercher';

  @override
  String get commonImportTooltip => 'Importer';

  @override
  String get navLibrary => 'Bibliothèque';

  @override
  String get navPlaylists => 'Playlists';

  @override
  String get navSearch => 'Recherche';

  @override
  String get navDownload => 'Téléchargement';

  @override
  String get navSettings => 'Réglages';

  @override
  String get formatJustNow => 'À l\'instant';

  @override
  String formatMinutesAgo(int minutes) {
    return 'il y a $minutes min';
  }

  @override
  String formatHoursAgo(int hours) {
    return 'il y a $hours h';
  }

  @override
  String formatDaysAgo(int days) {
    return 'il y a $days j';
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
  String get libraryTitle => 'Bibliothèque';

  @override
  String get libraryExitSelectionTooltip => 'Quitter la sélection';

  @override
  String get libraryRecentlyAdded => 'Ajoutés récemment';

  @override
  String get libraryFilterTracks => 'Titres';

  @override
  String get libraryFilterAlbums => 'Albums';

  @override
  String get libraryFilterRecentlyPlayed => 'Écoutés récemment';

  @override
  String get libraryFilterFavorites => 'Favoris';

  @override
  String get libraryRecentlyPlayedEmpty =>
      'Les titres que vous écoutez apparaîtront ici';

  @override
  String get libraryEmptyTitle => 'Aucun titre pour l\'instant';

  @override
  String get libraryEmptyBody =>
      'Importez de l\'audio depuis l\'app Fichiers pour commencer à créer votre bibliothèque.';

  @override
  String get libraryImportAudioButton => 'Importer de l\'audio';

  @override
  String get libraryPrivacyNote =>
      'Votre bibliothèque reste sur votre appareil.';

  @override
  String get artistEyebrow => 'ARTISTE';

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
  String get artistMostPlayed => 'Les plus écoutés';

  @override
  String get artistAlbumsHeader => 'Albums';

  @override
  String get searchHint => 'Titres, albums, artistes';

  @override
  String get searchEmptyLibrary =>
      'Importez de l\'audio pour commencer à créer votre bibliothèque.';

  @override
  String get searchNoResults => 'Aucun résultat';

  @override
  String get searchContextLabel => 'Recherche';

  @override
  String get settingsTitle => 'Réglages';

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
  String get settingsStorageUsed => 'Stockage utilisé';

  @override
  String get settingsSectionPlayback => 'Lecture';

  @override
  String get settingsRememberPosition => 'Mémoriser la position de lecture';

  @override
  String get settingsKeepPlayingWhenClosed =>
      'Continuer la lecture quand l\'app est fermée';

  @override
  String get settingsSectionDebug =>
      'Débogage (versions de débogage uniquement)';

  @override
  String get settingsImportTestFiles => 'Importer les fichiers de test';

  @override
  String settingsDebugAddedSkipped(int added, int skipped) {
    return '$added ajouté(s), $skipped ignoré(s)';
  }

  @override
  String get settingsSectionAbout => 'À propos';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsFooterNote =>
      'Les titres importés sont stockés localement. Les téléchargements nécessitent une connexion internet.';

  @override
  String get settingsAppearance => 'APPARENCE';

  @override
  String get settingsThemeLight => 'Clair';

  @override
  String get settingsThemeDark => 'Sombre';

  @override
  String get settingsThemeSystem => 'Système';

  @override
  String get newPlaylistTitle => 'Nouvelle playlist';

  @override
  String get newPlaylistCreate => 'Créer';

  @override
  String get newPlaylistNameHint => 'Nom de la playlist';

  @override
  String get newPlaylistArtworkHintChange =>
      'Touchez la pochette pour la changer.';

  @override
  String get newPlaylistArtworkHintAdd =>
      'Touchez la pochette pour ajouter une photo, ou laissez-la vide pour en générer une à partir des titres ajoutés.';

  @override
  String get playlistDeleted => 'Playlist supprimée';

  @override
  String get playlistMenuRename => 'Renommer';

  @override
  String get playlistMenuChangeArtwork => 'Changer la pochette';

  @override
  String get playlistMenuRemoveArtwork => 'Retirer la pochette';

  @override
  String get playlistMenuDeletePlaylist => 'Supprimer la playlist';

  @override
  String playlistCreatedOn(String date) {
    return 'Créée le $date';
  }

  @override
  String get playlistAddTracksButton => 'Ajouter des titres';

  @override
  String get playlistEmptyTracks =>
      'Aucun titre pour l\'instant — touchez « Ajouter des titres » pour créer cette playlist.';

  @override
  String get playlistRenameDialogTitle => 'Renommer la playlist';

  @override
  String get playlistDeleteDialogTitle => 'Supprimer la playlist ?';

  @override
  String playlistDeleteDialogBody(String name) {
    return '« $name » sera supprimée. Les titres resteront dans votre bibliothèque.';
  }

  @override
  String get playlistsPickTracksLater => 'Choisir les titres plus tard';

  @override
  String get queueTitle => 'File d\'attente';

  @override
  String get queueNowPlaying => 'LECTURE EN COURS';

  @override
  String get queuePlayingNext => 'À SUIVRE';

  @override
  String get queueNothingQueued => 'Rien en attente pour l\'instant.';

  @override
  String queueThenContinuesFrom(String source) {
    return 'PUIS CONTINUE AVEC $source';
  }

  @override
  String get nowPlayingNothingPlaying => 'Rien n\'est en cours de lecture';

  @override
  String nowPlayingFrom(String source) {
    return 'LECTURE DEPUIS $source';
  }

  @override
  String get nowPlayingMoreOptionsTooltip => 'Plus d\'options';

  @override
  String get nowPlayingAddFavoriteTooltip => 'Ajouter aux favoris';

  @override
  String get nowPlayingRemoveFavoriteTooltip => 'Retirer des favoris';

  @override
  String get nowPlayingPreviousTrackTooltip => 'Titre précédent';

  @override
  String get nowPlayingShuffleOn => 'Lecture aléatoire : activée';

  @override
  String get nowPlayingShuffleOff => 'Lecture aléatoire : désactivée';

  @override
  String get nowPlayingRepeatTrack => 'Titre';

  @override
  String get nowPlayingRepeatQueue => 'File d\'attente';

  @override
  String get nowPlayingPlaybackDeviceTooltip => 'Appareil de lecture';

  @override
  String get nowPlayingPlaybackDeviceMessage =>
      'Utilisez les réglages Bluetooth/sortie de votre appareil pour changer l\'appareil de lecture.';

  @override
  String get nowPlayingRewind10Tooltip => 'Reculer de 10 secondes';

  @override
  String get nowPlayingForward10Tooltip => 'Avancer de 10 secondes';

  @override
  String bulkAddToPlaylistTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ajouter $count titres à la playlist',
      one: 'Ajouter à la playlist',
    );
    return '$_temp0';
  }

  @override
  String bulkDeleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Supprimer $count titres ?',
      one: 'Supprimer 1 titre ?',
    );
    return '$_temp0';
  }

  @override
  String get bulkDeleteChooseHow => 'Choisissez comment les supprimer.';

  @override
  String get contextMenuPlayNow => 'Lire maintenant';

  @override
  String get contextMenuPlayNext => 'Lire ensuite';

  @override
  String get contextMenuAddToQueue => 'Ajouter à la file d\'attente';

  @override
  String get contextMenuAddToPlaylistEllipsis => 'Ajouter à la playlist…';

  @override
  String get contextMenuFavorite => 'Ajouter aux favoris';

  @override
  String get contextMenuRemoveFavorite => 'Retirer des favoris';

  @override
  String get contextMenuViewAlbum => 'Voir l\'album';

  @override
  String get contextMenuViewArtist => 'Voir l\'artiste';

  @override
  String get renameTrackDialogTitle => 'Renommer le titre';

  @override
  String get renameTrackHint => 'Titre';

  @override
  String get renameAlbumDialogTitle => 'Renommer l\'album';

  @override
  String get renameAlbumHint => 'Nom de l\'album';

  @override
  String renameAlbumCollisionMessage(String name, String albumArtist) {
    return 'Un album nommé « $name » de $albumArtist existe déjà.';
  }

  @override
  String get deleteFromDeviceDialogTitle => 'Supprimer de l\'appareil ?';

  @override
  String deleteFromDeviceDialogBody(String title) {
    return '« $title » sera définitivement supprimé et ne pourra pas être récupéré.';
  }

  @override
  String get miniPlayerDismissTooltip => 'Fermer';

  @override
  String get songRowOptionsTooltip => 'Options du titre';

  @override
  String songRowDeleteDialogTitle(String title) {
    return 'Supprimer « $title » ?';
  }

  @override
  String get deviceBrowserTitle => 'Choisir l\'audio';

  @override
  String deviceBrowserImportButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importer $count titres',
      one: 'Importer 1 titre',
    );
    return '$_temp0';
  }

  @override
  String get deviceBrowserPermissionTitle => 'Accès à l\'audio requis';

  @override
  String get deviceBrowserPermissionMessage =>
      'Listeny a besoin d\'une autorisation pour voir les fichiers audio de votre appareil. Accordez-la dans les Réglages pour parcourir et importer votre audio.';

  @override
  String get deviceBrowserOpenSettings => 'Ouvrir les Réglages';

  @override
  String get deviceBrowserErrorTitle => 'Impossible de lire votre audio';

  @override
  String get deviceBrowserUnknownError =>
      'Une erreur inconnue s\'est produite.';

  @override
  String get deviceBrowserRetry => 'Réessayer';

  @override
  String get deviceBrowserNoAudioTitle => 'Aucun fichier audio trouvé';

  @override
  String get deviceBrowserNoAudioMessage =>
      'Ajoutez de l\'audio à votre appareil (téléchargements, transferts, etc.) puis tirez vers le bas pour réessayer.';

  @override
  String get deviceBrowserSearchHint => 'Rechercher dans votre audio';

  @override
  String get deviceBrowserNoMatches => 'Aucune correspondance';

  @override
  String get deviceBrowserSelectAll => 'Tout sélectionner';

  @override
  String get deviceBrowserDeselectAll => 'Tout désélectionner';

  @override
  String get importFlowContextWhatsNew => 'Nouveautés';

  @override
  String get importFlowImportingTitle => 'Importation de l\'audio';

  @override
  String importFlowProcessedOfTotal(int processed, int total) {
    return '$processed sur $total fichiers · lecture des métadonnées';
  }

  @override
  String get importFlowCopiedNote =>
      'Copié dans l\'application — les originaux restent intacts.';

  @override
  String importFlowAddedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres ajoutés',
      one: '1 titre ajouté',
    );
    return '$_temp0';
  }

  @override
  String importFlowArtistsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count artistes',
      one: '1 artiste',
    );
    return '$_temp0';
  }

  @override
  String importFlowDuplicatesSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count doublons ignorés',
      one: '1 doublon ignoré',
    );
    return '$_temp0';
  }

  @override
  String get importFlowAlreadyInLibrary =>
      'Déjà présent dans votre bibliothèque';

  @override
  String importFlowUnsupportedSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers non pris en charge',
      one: '1 fichier non pris en charge',
    );
    return '$_temp0';
  }

  @override
  String importFlowCorruptSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers n\'ont pas pu être lus',
      one: '1 fichier n\'a pas pu être lu',
    );
    return '$_temp0';
  }

  @override
  String get importFlowPlayWhatsNew => 'Lire les nouveautés';

  @override
  String get downloadInstructions =>
      'Collez un lien direct vers un fichier audio ou vidéo — MP3, M4A, AAC, WAV, FLAC, OGG, MP4, WebM.';

  @override
  String get downloadUrlHint => 'https://exemple.com/titre.mp3';

  @override
  String get downloadPasteTooltip => 'Coller';

  @override
  String get downloadInvalidUrlError =>
      'Collez un lien valide vers un fichier multimédia.';

  @override
  String get downloadFormatLabel => 'Format';

  @override
  String get downloadFormatBestAvailable =>
      'Meilleure qualité audio disponible';

  @override
  String get downloadFormatMp3 => 'MP3';

  @override
  String get downloadAnotherButton => 'Télécharger un autre';

  @override
  String get downloadAudioButton => 'Télécharger l\'audio';

  @override
  String get downloadResolvingLink => 'Résolution du lien…';

  @override
  String get downloadDownloadingIndeterminate => 'Téléchargement…';

  @override
  String downloadDownloadingPercent(int percent) {
    return 'Téléchargement $percent %';
  }

  @override
  String get downloadConverting => 'Conversion…';

  @override
  String get downloadImporting => 'Importation dans votre bibliothèque…';

  @override
  String get downloadCancelled => 'Annulé.';

  @override
  String get downloadQueued => 'En attente d\'une place libre…';

  @override
  String get downloadRemoveTooltip => 'Retirer';

  @override
  String get downloadGenericError =>
      'Un problème est survenu. Veuillez réessayer.';

  @override
  String downloadAddedToLibrary(String title) {
    return '✓ Ajouté à votre bibliothèque\n$title';
  }

  @override
  String get downloadNothingNewAdded =>
      'Ce lien n\'a rien ajouté de nouveau à votre bibliothèque.';

  @override
  String get downloadHistoryTitle => 'Historique des téléchargements';

  @override
  String get downloadHistoryEmpty =>
      'Votre historique de téléchargements apparaîtra ici.';

  @override
  String get downloadClearHistoryDialogTitle =>
      'Effacer l\'historique des téléchargements ?';

  @override
  String get downloadClearHistoryDialogBody =>
      'Cela efface uniquement la liste d\'historique — aucun titre n\'est supprimé.';

  @override
  String get downloadSourceDirectLink => 'Lien direct';

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
