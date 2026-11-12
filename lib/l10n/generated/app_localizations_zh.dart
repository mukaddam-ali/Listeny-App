// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get commonPlay => '播放';

  @override
  String get commonPause => '暂停';

  @override
  String get commonShuffle => '随机播放';

  @override
  String get commonCancel => '取消';

  @override
  String get commonSave => '保存';

  @override
  String get commonDone => '完成';

  @override
  String get commonClear => '清除';

  @override
  String get commonDelete => '删除';

  @override
  String get commonAddToPlaylistTooltip => '添加到播放列表';

  @override
  String commonSelectedCount(int count) {
    return '已选择 $count 项';
  }

  @override
  String commonTrackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 首曲目',
    );
    return '$_temp0';
  }

  @override
  String get commonNoFavoritesYet => '暂无收藏。点按曲目上的心形图标即可添加。';

  @override
  String get commonRemoveFromLibrary => '从音乐库中移除';

  @override
  String get commonDeleteFromDevice => '从设备中删除';

  @override
  String get commonNextTrack => '下一曲';

  @override
  String get commonSearchTooltip => '搜索';

  @override
  String get commonImportTooltip => '导入';

  @override
  String get navLibrary => '音乐库';

  @override
  String get navPlaylists => '播放列表';

  @override
  String get navSearch => '搜索';

  @override
  String get navDownload => '下载';

  @override
  String get navSettings => '设置';

  @override
  String get formatJustNow => '刚刚';

  @override
  String formatMinutesAgo(int minutes) {
    return '$minutes 分钟前';
  }

  @override
  String formatHoursAgo(int hours) {
    return '$hours 小时前';
  }

  @override
  String formatDaysAgo(int days) {
    return '$days 天前';
  }

  @override
  String formatHoursMinutes(int hours, int minutes) {
    return '$hours 小时 $minutes 分钟';
  }

  @override
  String formatMinutesOnly(int minutes) {
    return '$minutes 分钟';
  }

  @override
  String get libraryTitle => '音乐库';

  @override
  String get libraryExitSelectionTooltip => '退出选择模式';

  @override
  String get libraryRecentlyAdded => '最近添加';

  @override
  String get libraryFilterTracks => '曲目';

  @override
  String get libraryFilterAlbums => '专辑';

  @override
  String get libraryFilterRecentlyPlayed => '最近播放';

  @override
  String get libraryFilterFavorites => '收藏';

  @override
  String get libraryRecentlyPlayedEmpty => '你播放过的曲目会显示在这里';

  @override
  String get libraryEmptyTitle => '暂无曲目';

  @override
  String get libraryEmptyBody => '从“文件”应用导入音频，开始构建你的音乐库。';

  @override
  String get libraryImportAudioButton => '导入音频';

  @override
  String get libraryPrivacyNote => '你的音乐库仅保存在本设备上。';

  @override
  String get artistEyebrow => '艺人';

  @override
  String artistAlbumCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 张专辑',
    );
    return '$_temp0';
  }

  @override
  String get artistMostPlayed => '最常播放';

  @override
  String get artistAlbumsHeader => '专辑';

  @override
  String get searchHint => '曲目、专辑、艺人';

  @override
  String get searchEmptyLibrary => '导入音频，开始构建你的音乐库。';

  @override
  String get searchNoResults => '无搜索结果';

  @override
  String get searchContextLabel => '搜索';

  @override
  String get settingsTitle => '设置';

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
  String get settingsStorageUsed => '已用存储空间';

  @override
  String get settingsSectionPlayback => '播放';

  @override
  String get settingsRememberPosition => '记住播放位置';

  @override
  String get settingsKeepPlayingWhenClosed => '应用关闭后继续播放';

  @override
  String get settingsSectionDebug => '调试（仅限调试版本）';

  @override
  String get settingsImportTestFiles => '导入推送的测试文件';

  @override
  String settingsDebugAddedSkipped(int added, int skipped) {
    return '已添加 $added 个，跳过 $skipped 个';
  }

  @override
  String get settingsSectionAbout => '关于';

  @override
  String get settingsVersion => '版本';

  @override
  String get settingsFooterNote => '导入的曲目保存在本地。下载功能需要联网。';

  @override
  String get settingsAppearance => '外观';

  @override
  String get settingsThemeLight => '浅色';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsThemeSystem => '跟随系统';

  @override
  String get newPlaylistTitle => '新建播放列表';

  @override
  String get newPlaylistCreate => '创建';

  @override
  String get newPlaylistNameHint => '播放列表名称';

  @override
  String get newPlaylistArtworkHintChange => '点按封面即可更换。';

  @override
  String get newPlaylistArtworkHintAdd => '点按封面添加图片，或留空以根据添加的曲目自动生成封面。';

  @override
  String get playlistDeleted => '播放列表已删除';

  @override
  String get playlistMenuRename => '重命名';

  @override
  String get playlistMenuChangeArtwork => '更改封面';

  @override
  String get playlistMenuRemoveArtwork => '移除封面';

  @override
  String get playlistMenuDeletePlaylist => '删除播放列表';

  @override
  String playlistCreatedOn(String date) {
    return '创建于 $date';
  }

  @override
  String get playlistAddTracksButton => '添加曲目';

  @override
  String get playlistEmptyTracks => '暂无曲目——点按“添加曲目”来构建这个播放列表。';

  @override
  String get playlistRenameDialogTitle => '重命名播放列表';

  @override
  String get playlistDeleteDialogTitle => '删除播放列表？';

  @override
  String playlistDeleteDialogBody(String name) {
    return '“$name”将被删除。曲目仍会保留在你的音乐库中。';
  }

  @override
  String get playlistsPickTracksLater => '稍后再选曲目';

  @override
  String get queueTitle => '播放队列';

  @override
  String get queueNowPlaying => '正在播放';

  @override
  String get queuePlayingNext => '接下来播放';

  @override
  String get queueNothingQueued => '接下来没有排队的曲目。';

  @override
  String queueThenContinuesFrom(String source) {
    return '之后将继续播放：$source';
  }

  @override
  String get nowPlayingNothingPlaying => '当前没有播放内容';

  @override
  String nowPlayingFrom(String source) {
    return '正在播放来自：$source';
  }

  @override
  String get nowPlayingMoreOptionsTooltip => '更多选项';

  @override
  String get nowPlayingAddFavoriteTooltip => '添加到收藏';

  @override
  String get nowPlayingRemoveFavoriteTooltip => '从收藏中移除';

  @override
  String get nowPlayingPreviousTrackTooltip => '上一曲';

  @override
  String get nowPlayingShuffleOn => '随机播放：开';

  @override
  String get nowPlayingShuffleOff => '随机播放：关';

  @override
  String get nowPlayingRepeatTrack => '单曲';

  @override
  String get nowPlayingRepeatQueue => '队列';

  @override
  String get nowPlayingPlaybackDeviceTooltip => '播放设备';

  @override
  String get nowPlayingPlaybackDeviceMessage => '请使用设备的蓝牙/输出设置来切换播放设备。';

  @override
  String get nowPlayingRewind10Tooltip => '快退 10 秒';

  @override
  String get nowPlayingForward10Tooltip => '快进 10 秒';

  @override
  String bulkAddToPlaylistTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '将 $count 首曲目添加到播放列表',
    );
    return '$_temp0';
  }

  @override
  String bulkDeleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '删除 $count 首曲目？',
    );
    return '$_temp0';
  }

  @override
  String get bulkDeleteChooseHow => '请选择移除方式。';

  @override
  String get contextMenuPlayNow => '立即播放';

  @override
  String get contextMenuPlayNext => '下一首播放';

  @override
  String get contextMenuAddToQueue => '添加到队列';

  @override
  String get contextMenuAddToPlaylistEllipsis => '添加到播放列表…';

  @override
  String get contextMenuFavorite => '收藏';

  @override
  String get contextMenuRemoveFavorite => '取消收藏';

  @override
  String get contextMenuViewAlbum => '查看专辑';

  @override
  String get contextMenuViewArtist => '查看艺人';

  @override
  String get renameTrackDialogTitle => '重命名曲目';

  @override
  String get renameTrackHint => '标题';

  @override
  String get renameAlbumDialogTitle => '重命名专辑';

  @override
  String get renameAlbumHint => '专辑名称';

  @override
  String renameAlbumCollisionMessage(String name, String albumArtist) {
    return '已存在一张由 $albumArtist 创作、名为“$name”的专辑。';
  }

  @override
  String get deleteFromDeviceDialogTitle => '从设备中删除？';

  @override
  String deleteFromDeviceDialogBody(String title) {
    return '“$title”将被永久删除，且无法恢复。';
  }

  @override
  String get miniPlayerDismissTooltip => '关闭';

  @override
  String get songRowOptionsTooltip => '曲目选项';

  @override
  String songRowDeleteDialogTitle(String title) {
    return '删除“$title”？';
  }

  @override
  String get deviceBrowserTitle => '选择音频';

  @override
  String deviceBrowserImportButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '导入 $count 首曲目',
    );
    return '$_temp0';
  }

  @override
  String get deviceBrowserPermissionTitle => '需要音频访问权限';

  @override
  String get deviceBrowserPermissionMessage =>
      'Listeny 需要权限才能查看设备上的音频文件。请在设置中授予权限，以便浏览和导入音频。';

  @override
  String get deviceBrowserOpenSettings => '打开设置';

  @override
  String get deviceBrowserErrorTitle => '无法读取你的音频';

  @override
  String get deviceBrowserUnknownError => '发生未知错误。';

  @override
  String get deviceBrowserRetry => '重试';

  @override
  String get deviceBrowserNoAudioTitle => '未找到音频文件';

  @override
  String get deviceBrowserNoAudioMessage => '请向设备添加音频（下载、传输等），然后下拉重试。';

  @override
  String get deviceBrowserSearchHint => '搜索你的音频';

  @override
  String get deviceBrowserNoMatches => '没有匹配项';

  @override
  String get deviceBrowserSelectAll => '全选';

  @override
  String get deviceBrowserDeselectAll => '取消全选';

  @override
  String get importFlowContextWhatsNew => '新添加内容';

  @override
  String get importFlowImportingTitle => '正在导入音频';

  @override
  String importFlowProcessedOfTotal(int processed, int total) {
    return '已处理 $processed/$total 个文件 · 正在读取元数据';
  }

  @override
  String get importFlowCopiedNote => '已复制到应用内——原文件未受影响。';

  @override
  String importFlowAddedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已添加 $count 首曲目',
    );
    return '$_temp0';
  }

  @override
  String importFlowArtistsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 位艺人',
    );
    return '$_temp0';
  }

  @override
  String importFlowDuplicatesSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已跳过 $count 个重复项',
    );
    return '$_temp0';
  }

  @override
  String get importFlowAlreadyInLibrary => '已存在于你的音乐库中';

  @override
  String importFlowUnsupportedSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个文件不受支持',
    );
    return '$_temp0';
  }

  @override
  String importFlowCorruptSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个文件无法读取',
    );
    return '$_temp0';
  }

  @override
  String get importFlowPlayWhatsNew => '播放新添加内容';

  @override
  String get downloadInstructions =>
      '粘贴音频或视频文件的直接链接——支持 MP3、M4A、AAC、WAV、FLAC、OGG、MP4、WebM。';

  @override
  String get downloadUrlHint => 'https://example.com/track.mp3';

  @override
  String get downloadPasteTooltip => '粘贴';

  @override
  String get downloadInvalidUrlError => '请粘贴一个有效的媒体文件链接。';

  @override
  String get downloadFormatLabel => '格式';

  @override
  String get downloadFormatBestAvailable => '可用的最佳音质';

  @override
  String get downloadFormatMp3 => 'MP3';

  @override
  String get downloadAnotherButton => '下载另一个';

  @override
  String get downloadAudioButton => '下载音频';

  @override
  String get downloadResolvingLink => '正在解析链接…';

  @override
  String get downloadDownloadingIndeterminate => '正在下载…';

  @override
  String downloadDownloadingPercent(int percent) {
    return '正在下载 $percent%';
  }

  @override
  String get downloadConverting => '正在转换…';

  @override
  String get downloadImporting => '正在导入到你的音乐库…';

  @override
  String get downloadCancelled => '已取消。';

  @override
  String get downloadQueued => '正在等待空闲位置…';

  @override
  String get downloadRemoveTooltip => '移除';

  @override
  String get downloadGenericError => '出了点问题，请重试。';

  @override
  String downloadAddedToLibrary(String title) {
    return '✓ 已添加到你的音乐库\n$title';
  }

  @override
  String get downloadNothingNewAdded => '这个链接没有为你的音乐库添加任何新内容。';

  @override
  String get downloadHistoryTitle => '下载历史';

  @override
  String get downloadHistoryEmpty => '你的下载历史会显示在这里。';

  @override
  String get downloadClearHistoryDialogTitle => '清除下载历史？';

  @override
  String get downloadClearHistoryDialogBody => '此操作仅清除历史记录列表——不会删除任何曲目。';

  @override
  String get downloadSourceDirectLink => '直接链接';

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
