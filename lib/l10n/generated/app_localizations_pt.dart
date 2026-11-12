// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get commonPlay => 'Reproduzir';

  @override
  String get commonPause => 'Pausar';

  @override
  String get commonShuffle => 'Aleatório';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonSave => 'Salvar';

  @override
  String get commonDone => 'Concluído';

  @override
  String get commonClear => 'Limpar';

  @override
  String get commonDelete => 'Excluir';

  @override
  String get commonAddToPlaylistTooltip => 'Adicionar à playlist';

  @override
  String commonSelectedCount(int count) {
    return '$count selecionadas';
  }

  @override
  String commonTrackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count faixas',
      one: '1 faixa',
    );
    return '$_temp0';
  }

  @override
  String get commonNoFavoritesYet =>
      'Ainda não há favoritos. Toque no coração de uma faixa para adicioná-la.';

  @override
  String get commonRemoveFromLibrary => 'Remover da biblioteca';

  @override
  String get commonDeleteFromDevice => 'Excluir do dispositivo';

  @override
  String get commonNextTrack => 'Próxima faixa';

  @override
  String get commonSearchTooltip => 'Pesquisar';

  @override
  String get commonImportTooltip => 'Importar';

  @override
  String get navLibrary => 'Biblioteca';

  @override
  String get navPlaylists => 'Playlists';

  @override
  String get navSearch => 'Pesquisar';

  @override
  String get navDownload => 'Baixar';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get formatJustNow => 'Agora mesmo';

  @override
  String formatMinutesAgo(int minutes) {
    return 'há $minutes min';
  }

  @override
  String formatHoursAgo(int hours) {
    return 'há $hours h';
  }

  @override
  String formatDaysAgo(int days) {
    return 'há $days d';
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
  String get libraryExitSelectionTooltip => 'Sair da seleção';

  @override
  String get libraryRecentlyAdded => 'Adicionadas recentemente';

  @override
  String get libraryFilterTracks => 'Faixas';

  @override
  String get libraryFilterAlbums => 'Álbuns';

  @override
  String get libraryFilterRecentlyPlayed => 'Tocadas recentemente';

  @override
  String get libraryFilterFavorites => 'Favoritas';

  @override
  String get libraryRecentlyPlayedEmpty =>
      'As faixas que você reproduzir aparecerão aqui';

  @override
  String get libraryEmptyTitle => 'Ainda não há faixas';

  @override
  String get libraryEmptyBody =>
      'Importe áudio do app Arquivos para começar a montar sua biblioteca.';

  @override
  String get libraryImportAudioButton => 'Importar áudio';

  @override
  String get libraryPrivacyNote =>
      'Sua biblioteca permanece no seu dispositivo.';

  @override
  String get artistEyebrow => 'ARTISTA';

  @override
  String artistAlbumCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count álbuns',
      one: '1 álbum',
    );
    return '$_temp0';
  }

  @override
  String get artistMostPlayed => 'Mais tocadas';

  @override
  String get artistAlbumsHeader => 'Álbuns';

  @override
  String get searchHint => 'Faixas, álbuns, artistas';

  @override
  String get searchEmptyLibrary =>
      'Importe áudio para começar a montar sua biblioteca.';

  @override
  String get searchNoResults => 'Nenhum resultado';

  @override
  String get searchContextLabel => 'Pesquisa';

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
  String get settingsStorageUsed => 'Armazenamento usado';

  @override
  String get settingsSectionPlayback => 'Reprodução';

  @override
  String get settingsRememberPosition => 'Lembrar posição de reprodução';

  @override
  String get settingsKeepPlayingWhenClosed =>
      'Continuar reproduzindo com o app fechado';

  @override
  String get settingsSectionDebug => 'Depuração (apenas builds de depuração)';

  @override
  String get settingsImportTestFiles => 'Importar arquivos de teste enviados';

  @override
  String settingsDebugAddedSkipped(int added, int skipped) {
    return '$added adicionadas, $skipped ignoradas';
  }

  @override
  String get settingsSectionAbout => 'Sobre';

  @override
  String get settingsVersion => 'Versão';

  @override
  String get settingsFooterNote =>
      'As faixas importadas são armazenadas localmente. Os downloads exigem acesso à internet.';

  @override
  String get settingsAppearance => 'APARÊNCIA';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Escuro';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get newPlaylistTitle => 'Nova playlist';

  @override
  String get newPlaylistCreate => 'Criar';

  @override
  String get newPlaylistNameHint => 'Nome da playlist';

  @override
  String get newPlaylistArtworkHintChange => 'Toque na capa para alterá-la.';

  @override
  String get newPlaylistArtworkHintAdd =>
      'Toque na capa para adicionar uma foto, ou deixe em branco e uma será gerada a partir das faixas que você adicionar.';

  @override
  String get playlistDeleted => 'Playlist excluída';

  @override
  String get playlistMenuRename => 'Renomear';

  @override
  String get playlistMenuChangeArtwork => 'Alterar capa';

  @override
  String get playlistMenuRemoveArtwork => 'Remover capa';

  @override
  String get playlistMenuDeletePlaylist => 'Excluir playlist';

  @override
  String playlistCreatedOn(String date) {
    return 'Criada em $date';
  }

  @override
  String get playlistAddTracksButton => 'Adicionar faixas';

  @override
  String get playlistEmptyTracks =>
      'Ainda não há faixas — toque em \"Adicionar faixas\" para montar esta playlist.';

  @override
  String get playlistRenameDialogTitle => 'Renomear playlist';

  @override
  String get playlistDeleteDialogTitle => 'Excluir playlist?';

  @override
  String playlistDeleteDialogBody(String name) {
    return '\"$name\" será excluída. As faixas permanecerão na sua biblioteca.';
  }

  @override
  String get playlistsPickTracksLater => 'Escolher faixas depois';

  @override
  String get queueTitle => 'Fila';

  @override
  String get queueNowPlaying => 'TOCANDO AGORA';

  @override
  String get queuePlayingNext => 'A SEGUIR';

  @override
  String get queueNothingQueued => 'Nada na fila.';

  @override
  String queueThenContinuesFrom(String source) {
    return 'DEPOIS CONTINUA DE $source';
  }

  @override
  String get nowPlayingNothingPlaying => 'Nada tocando';

  @override
  String nowPlayingFrom(String source) {
    return 'TOCANDO DE $source';
  }

  @override
  String get nowPlayingMoreOptionsTooltip => 'Mais opções';

  @override
  String get nowPlayingAddFavoriteTooltip => 'Adicionar aos favoritos';

  @override
  String get nowPlayingRemoveFavoriteTooltip => 'Remover dos favoritos';

  @override
  String get nowPlayingPreviousTrackTooltip => 'Faixa anterior';

  @override
  String get nowPlayingShuffleOn => 'Aleatório: ativado';

  @override
  String get nowPlayingShuffleOff => 'Aleatório: desativado';

  @override
  String get nowPlayingRepeatTrack => 'Faixa';

  @override
  String get nowPlayingRepeatQueue => 'Fila';

  @override
  String get nowPlayingPlaybackDeviceTooltip => 'Dispositivo de reprodução';

  @override
  String get nowPlayingPlaybackDeviceMessage =>
      'Use as configurações de Bluetooth/saída do seu dispositivo para trocar o dispositivo de reprodução.';

  @override
  String get nowPlayingRewind10Tooltip => 'Retroceder 10 segundos';

  @override
  String get nowPlayingForward10Tooltip => 'Avançar 10 segundos';

  @override
  String bulkAddToPlaylistTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Adicionar $count faixas à playlist',
      one: 'Adicionar à playlist',
    );
    return '$_temp0';
  }

  @override
  String bulkDeleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Excluir $count faixas?',
      one: 'Excluir 1 faixa?',
    );
    return '$_temp0';
  }

  @override
  String get bulkDeleteChooseHow => 'Escolha como removê-las.';

  @override
  String get contextMenuPlayNow => 'Tocar agora';

  @override
  String get contextMenuPlayNext => 'Tocar em seguida';

  @override
  String get contextMenuAddToQueue => 'Adicionar à fila';

  @override
  String get contextMenuAddToPlaylistEllipsis => 'Adicionar à playlist…';

  @override
  String get contextMenuFavorite => 'Favoritar';

  @override
  String get contextMenuRemoveFavorite => 'Remover favorito';

  @override
  String get contextMenuViewAlbum => 'Ver álbum';

  @override
  String get contextMenuViewArtist => 'Ver artista';

  @override
  String get renameTrackDialogTitle => 'Renomear faixa';

  @override
  String get renameTrackHint => 'Título';

  @override
  String get renameAlbumDialogTitle => 'Renomear álbum';

  @override
  String get renameAlbumHint => 'Nome do álbum';

  @override
  String renameAlbumCollisionMessage(String name, String albumArtist) {
    return 'Já existe um álbum chamado \"$name\" de $albumArtist.';
  }

  @override
  String get deleteFromDeviceDialogTitle => 'Excluir do dispositivo?';

  @override
  String deleteFromDeviceDialogBody(String title) {
    return '\"$title\" será excluída permanentemente e não poderá ser recuperada.';
  }

  @override
  String get miniPlayerDismissTooltip => 'Dispensar';

  @override
  String get songRowOptionsTooltip => 'Opções da faixa';

  @override
  String songRowDeleteDialogTitle(String title) {
    return 'Excluir \"$title\"?';
  }

  @override
  String get deviceBrowserTitle => 'Escolher áudio';

  @override
  String deviceBrowserImportButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importar $count faixas',
      one: 'Importar 1 faixa',
    );
    return '$_temp0';
  }

  @override
  String get deviceBrowserPermissionTitle => 'Acesso ao áudio necessário';

  @override
  String get deviceBrowserPermissionMessage =>
      'O Listeny precisa de permissão para ver os arquivos de áudio do seu dispositivo. Conceda-a nos Ajustes para navegar e importar seu áudio.';

  @override
  String get deviceBrowserOpenSettings => 'Abrir Ajustes';

  @override
  String get deviceBrowserErrorTitle => 'Não foi possível ler seu áudio';

  @override
  String get deviceBrowserUnknownError => 'Ocorreu um erro desconhecido.';

  @override
  String get deviceBrowserRetry => 'Tentar novamente';

  @override
  String get deviceBrowserNoAudioTitle => 'Nenhum arquivo de áudio encontrado';

  @override
  String get deviceBrowserNoAudioMessage =>
      'Adicione áudio ao seu dispositivo (downloads, transferências etc.) e puxe para baixo para tentar novamente.';

  @override
  String get deviceBrowserSearchHint => 'Pesquisar seu áudio';

  @override
  String get deviceBrowserNoMatches => 'Nenhuma correspondência';

  @override
  String get deviceBrowserSelectAll => 'Selecionar tudo';

  @override
  String get deviceBrowserDeselectAll => 'Desmarcar tudo';

  @override
  String get importFlowContextWhatsNew => 'Novidades';

  @override
  String get importFlowImportingTitle => 'Importando áudio';

  @override
  String importFlowProcessedOfTotal(int processed, int total) {
    return '$processed de $total arquivos · lendo metadados';
  }

  @override
  String get importFlowCopiedNote =>
      'Copiado para dentro do app — os originais não foram alterados.';

  @override
  String importFlowAddedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count faixas adicionadas',
      one: '1 faixa adicionada',
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
      other: '$count duplicatas ignoradas',
      one: '1 duplicata ignorada',
    );
    return '$_temp0';
  }

  @override
  String get importFlowAlreadyInLibrary => 'Já está na sua biblioteca';

  @override
  String importFlowUnsupportedSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arquivos não suportados',
      one: '1 arquivo não suportado',
    );
    return '$_temp0';
  }

  @override
  String importFlowCorruptSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arquivos não puderam ser lidos',
      one: '1 arquivo não pôde ser lido',
    );
    return '$_temp0';
  }

  @override
  String get importFlowPlayWhatsNew => 'Tocar novidades';

  @override
  String get downloadInstructions =>
      'Cole um link direto para um arquivo de áudio ou vídeo — MP3, M4A, AAC, WAV, FLAC, OGG, MP4, WebM.';

  @override
  String get downloadUrlHint => 'https://exemplo.com/faixa.mp3';

  @override
  String get downloadPasteTooltip => 'Colar';

  @override
  String get downloadInvalidUrlError =>
      'Cole um link válido para um arquivo de mídia.';

  @override
  String get downloadFormatLabel => 'Formato';

  @override
  String get downloadFormatBestAvailable => 'Melhor áudio disponível';

  @override
  String get downloadFormatMp3 => 'MP3';

  @override
  String get downloadAnotherButton => 'Baixar outra';

  @override
  String get downloadAudioButton => 'Baixar áudio';

  @override
  String get downloadResolvingLink => 'Resolvendo link…';

  @override
  String get downloadDownloadingIndeterminate => 'Baixando…';

  @override
  String downloadDownloadingPercent(int percent) {
    return 'Baixando $percent%';
  }

  @override
  String get downloadConverting => 'Convertendo…';

  @override
  String get downloadImporting => 'Importando para sua biblioteca…';

  @override
  String get downloadCancelled => 'Cancelado.';

  @override
  String get downloadQueued => 'Aguardando uma vaga livre…';

  @override
  String get downloadRemoveTooltip => 'Remover';

  @override
  String get downloadGenericError => 'Algo deu errado. Tente novamente.';

  @override
  String downloadAddedToLibrary(String title) {
    return '✓ Adicionada à sua biblioteca\n$title';
  }

  @override
  String get downloadNothingNewAdded =>
      'Este link não adicionou nada novo à sua biblioteca.';

  @override
  String get downloadHistoryTitle => 'Histórico de downloads';

  @override
  String get downloadHistoryEmpty =>
      'Seu histórico de downloads aparecerá aqui.';

  @override
  String get downloadClearHistoryDialogTitle =>
      'Limpar histórico de downloads?';

  @override
  String get downloadClearHistoryDialogBody =>
      'Isso apenas limpa a lista de histórico — não remove nenhuma faixa.';

  @override
  String get downloadSourceDirectLink => 'Link direto';

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
