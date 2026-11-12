import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_ur.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('bn'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('pt'),
    Locale('ru'),
    Locale('ur'),
    Locale('zh'),
  ];

  /// No description provided for @commonPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get commonPlay;

  /// No description provided for @commonPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get commonPause;

  /// No description provided for @commonShuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get commonShuffle;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonAddToPlaylistTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add to Playlist'**
  String get commonAddToPlaylistTooltip;

  /// No description provided for @commonSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String commonSelectedCount(int count);

  /// No description provided for @commonTrackCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 track} other{{count} tracks}}'**
  String commonTrackCount(int count);

  /// No description provided for @commonNoFavoritesYet.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet. Tap the heart on a track to add one.'**
  String get commonNoFavoritesYet;

  /// No description provided for @commonRemoveFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Remove from Library'**
  String get commonRemoveFromLibrary;

  /// No description provided for @commonDeleteFromDevice.
  ///
  /// In en, this message translates to:
  /// **'Delete from Device'**
  String get commonDeleteFromDevice;

  /// No description provided for @commonNextTrack.
  ///
  /// In en, this message translates to:
  /// **'Next track'**
  String get commonNextTrack;

  /// No description provided for @commonSearchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearchTooltip;

  /// No description provided for @commonImportTooltip.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get commonImportTooltip;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @navPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get navPlaylists;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get navDownload;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @formatJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get formatJustNow;

  /// No description provided for @formatMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String formatMinutesAgo(int minutes);

  /// No description provided for @formatHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String formatHoursAgo(int hours);

  /// No description provided for @formatDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String formatDaysAgo(int days);

  /// No description provided for @formatHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} hr {minutes} min'**
  String formatHoursMinutes(int hours, int minutes);

  /// No description provided for @formatMinutesOnly.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String formatMinutesOnly(int minutes);

  /// No description provided for @libraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryTitle;

  /// No description provided for @libraryExitSelectionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Exit selection'**
  String get libraryExitSelectionTooltip;

  /// No description provided for @libraryRecentlyAdded.
  ///
  /// In en, this message translates to:
  /// **'Recently added'**
  String get libraryRecentlyAdded;

  /// No description provided for @libraryFilterTracks.
  ///
  /// In en, this message translates to:
  /// **'Tracks'**
  String get libraryFilterTracks;

  /// No description provided for @libraryFilterAlbums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get libraryFilterAlbums;

  /// No description provided for @libraryFilterRecentlyPlayed.
  ///
  /// In en, this message translates to:
  /// **'Recently Played'**
  String get libraryFilterRecentlyPlayed;

  /// No description provided for @libraryFilterFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get libraryFilterFavorites;

  /// No description provided for @libraryRecentlyPlayedEmpty.
  ///
  /// In en, this message translates to:
  /// **'Tracks you play will appear here'**
  String get libraryRecentlyPlayedEmpty;

  /// No description provided for @libraryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No tracks yet'**
  String get libraryEmptyTitle;

  /// No description provided for @libraryEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Import audio from the Files app to start building your library.'**
  String get libraryEmptyBody;

  /// No description provided for @libraryImportAudioButton.
  ///
  /// In en, this message translates to:
  /// **'Import Audio'**
  String get libraryImportAudioButton;

  /// No description provided for @libraryPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Your library stays on your device.'**
  String get libraryPrivacyNote;

  /// No description provided for @artistEyebrow.
  ///
  /// In en, this message translates to:
  /// **'ARTIST'**
  String get artistEyebrow;

  /// No description provided for @artistAlbumCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 album} other{{count} albums}}'**
  String artistAlbumCount(int count);

  /// No description provided for @artistMostPlayed.
  ///
  /// In en, this message translates to:
  /// **'Most played'**
  String get artistMostPlayed;

  /// No description provided for @artistAlbumsHeader.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get artistAlbumsHeader;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Tracks, albums, artists'**
  String get searchHint;

  /// No description provided for @searchEmptyLibrary.
  ///
  /// In en, this message translates to:
  /// **'Import audio to start building your library.'**
  String get searchEmptyLibrary;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get searchNoResults;

  /// No description provided for @searchContextLabel.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchContextLabel;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSyncLibrary.
  ///
  /// In en, this message translates to:
  /// **'Sync Library'**
  String get settingsSyncLibrary;

  /// No description provided for @settingsSyncLibraryRunning.
  ///
  /// In en, this message translates to:
  /// **'Syncing… tap to stop'**
  String get settingsSyncLibraryRunning;

  /// No description provided for @syncLibraryUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Library synced — no new MP3 files found.'**
  String get syncLibraryUpToDate;

  /// No description provided for @syncLibraryAdded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Added 1 track from your device.} other{Added {count} tracks from your device.}}'**
  String syncLibraryAdded(int count);

  /// No description provided for @syncLibraryStopped.
  ///
  /// In en, this message translates to:
  /// **'Sync stopped. Tracks found so far were kept.'**
  String get syncLibraryStopped;

  /// No description provided for @syncLibraryPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Allow audio access to sync music from your device.'**
  String get syncLibraryPermissionDenied;

  /// No description provided for @syncLibraryUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Automatic sync isn\'t supported on Android 10. Use Import instead.'**
  String get syncLibraryUnsupported;

  /// No description provided for @syncLibraryFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync couldn\'t finish. Try again.'**
  String get syncLibraryFailed;

  /// No description provided for @settingsStorageUsed.
  ///
  /// In en, this message translates to:
  /// **'Storage Used'**
  String get settingsStorageUsed;

  /// No description provided for @settingsSectionPlayback.
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get settingsSectionPlayback;

  /// No description provided for @settingsRememberPosition.
  ///
  /// In en, this message translates to:
  /// **'Remember Playback Position'**
  String get settingsRememberPosition;

  /// No description provided for @settingsKeepPlayingWhenClosed.
  ///
  /// In en, this message translates to:
  /// **'Keep playing when app is closed'**
  String get settingsKeepPlayingWhenClosed;

  /// No description provided for @settingsSectionDebug.
  ///
  /// In en, this message translates to:
  /// **'Debug (debug builds only)'**
  String get settingsSectionDebug;

  /// No description provided for @settingsImportTestFiles.
  ///
  /// In en, this message translates to:
  /// **'Import pushed test files'**
  String get settingsImportTestFiles;

  /// No description provided for @settingsDebugAddedSkipped.
  ///
  /// In en, this message translates to:
  /// **'Added {added}, skipped {skipped}'**
  String settingsDebugAddedSkipped(int added, int skipped);

  /// No description provided for @settingsSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsFooterNote.
  ///
  /// In en, this message translates to:
  /// **'Imported tracks are stored locally. Downloads require internet access.'**
  String get settingsFooterNote;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'APPEARANCE'**
  String get settingsAppearance;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @newPlaylistTitle.
  ///
  /// In en, this message translates to:
  /// **'New Playlist'**
  String get newPlaylistTitle;

  /// No description provided for @newPlaylistCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get newPlaylistCreate;

  /// No description provided for @newPlaylistNameHint.
  ///
  /// In en, this message translates to:
  /// **'Playlist name'**
  String get newPlaylistNameHint;

  /// No description provided for @newPlaylistArtworkHintChange.
  ///
  /// In en, this message translates to:
  /// **'Tap the cover to change it.'**
  String get newPlaylistArtworkHintChange;

  /// No description provided for @newPlaylistArtworkHintAdd.
  ///
  /// In en, this message translates to:
  /// **'Tap the cover to add a photo, or leave it and one will be generated from the tracks you add.'**
  String get newPlaylistArtworkHintAdd;

  /// No description provided for @playlistDeleted.
  ///
  /// In en, this message translates to:
  /// **'Playlist deleted'**
  String get playlistDeleted;

  /// No description provided for @playlistMenuRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get playlistMenuRename;

  /// No description provided for @playlistMenuChangeArtwork.
  ///
  /// In en, this message translates to:
  /// **'Change Artwork'**
  String get playlistMenuChangeArtwork;

  /// No description provided for @playlistMenuRemoveArtwork.
  ///
  /// In en, this message translates to:
  /// **'Remove Artwork'**
  String get playlistMenuRemoveArtwork;

  /// No description provided for @playlistMenuDeletePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Delete Playlist'**
  String get playlistMenuDeletePlaylist;

  /// No description provided for @playlistCreatedOn.
  ///
  /// In en, this message translates to:
  /// **'Created {date}'**
  String playlistCreatedOn(String date);

  /// No description provided for @playlistAddTracksButton.
  ///
  /// In en, this message translates to:
  /// **'Add tracks'**
  String get playlistAddTracksButton;

  /// No description provided for @playlistEmptyTracks.
  ///
  /// In en, this message translates to:
  /// **'No tracks yet — tap \"Add tracks\" to build this playlist.'**
  String get playlistEmptyTracks;

  /// No description provided for @playlistRenameDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename Playlist'**
  String get playlistRenameDialogTitle;

  /// No description provided for @playlistDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Playlist?'**
  String get playlistDeleteDialogTitle;

  /// No description provided for @playlistDeleteDialogBody.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be deleted. Tracks stay in your library.'**
  String playlistDeleteDialogBody(String name);

  /// No description provided for @playlistsPickTracksLater.
  ///
  /// In en, this message translates to:
  /// **'Pick tracks later'**
  String get playlistsPickTracksLater;

  /// No description provided for @queueTitle.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get queueTitle;

  /// No description provided for @queueNowPlaying.
  ///
  /// In en, this message translates to:
  /// **'NOW PLAYING'**
  String get queueNowPlaying;

  /// No description provided for @queuePlayingNext.
  ///
  /// In en, this message translates to:
  /// **'PLAYING NEXT'**
  String get queuePlayingNext;

  /// No description provided for @queueNothingQueued.
  ///
  /// In en, this message translates to:
  /// **'Nothing queued next.'**
  String get queueNothingQueued;

  /// No description provided for @queueThenContinuesFrom.
  ///
  /// In en, this message translates to:
  /// **'THEN CONTINUES FROM {source}'**
  String queueThenContinuesFrom(String source);

  /// No description provided for @nowPlayingNothingPlaying.
  ///
  /// In en, this message translates to:
  /// **'Nothing playing'**
  String get nowPlayingNothingPlaying;

  /// No description provided for @nowPlayingFrom.
  ///
  /// In en, this message translates to:
  /// **'PLAYING FROM {source}'**
  String nowPlayingFrom(String source);

  /// No description provided for @nowPlayingMoreOptionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get nowPlayingMoreOptionsTooltip;

  /// No description provided for @nowPlayingAddFavoriteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get nowPlayingAddFavoriteTooltip;

  /// No description provided for @nowPlayingRemoveFavoriteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get nowPlayingRemoveFavoriteTooltip;

  /// No description provided for @nowPlayingPreviousTrackTooltip.
  ///
  /// In en, this message translates to:
  /// **'Previous track'**
  String get nowPlayingPreviousTrackTooltip;

  /// No description provided for @nowPlayingShuffleOn.
  ///
  /// In en, this message translates to:
  /// **'Shuffle: on'**
  String get nowPlayingShuffleOn;

  /// No description provided for @nowPlayingShuffleOff.
  ///
  /// In en, this message translates to:
  /// **'Shuffle: off'**
  String get nowPlayingShuffleOff;

  /// No description provided for @nowPlayingRepeatTrack.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get nowPlayingRepeatTrack;

  /// No description provided for @nowPlayingRepeatQueue.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get nowPlayingRepeatQueue;

  /// No description provided for @nowPlayingPlaybackDeviceTooltip.
  ///
  /// In en, this message translates to:
  /// **'Playback device'**
  String get nowPlayingPlaybackDeviceTooltip;

  /// No description provided for @nowPlayingPlaybackDeviceMessage.
  ///
  /// In en, this message translates to:
  /// **'Use your device\'s Bluetooth/output settings to switch playback devices.'**
  String get nowPlayingPlaybackDeviceMessage;

  /// No description provided for @nowPlayingRewind10Tooltip.
  ///
  /// In en, this message translates to:
  /// **'Rewind 10 seconds'**
  String get nowPlayingRewind10Tooltip;

  /// No description provided for @nowPlayingForward10Tooltip.
  ///
  /// In en, this message translates to:
  /// **'Forward 10 seconds'**
  String get nowPlayingForward10Tooltip;

  /// No description provided for @bulkAddToPlaylistTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Add to Playlist} other{Add {count} tracks to Playlist}}'**
  String bulkAddToPlaylistTitle(int count);

  /// No description provided for @bulkDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Delete 1 track?} other{Delete {count} tracks?}}'**
  String bulkDeleteTitle(int count);

  /// No description provided for @bulkDeleteChooseHow.
  ///
  /// In en, this message translates to:
  /// **'Choose how to remove them.'**
  String get bulkDeleteChooseHow;

  /// No description provided for @contextMenuPlayNow.
  ///
  /// In en, this message translates to:
  /// **'Play Now'**
  String get contextMenuPlayNow;

  /// No description provided for @contextMenuPlayNext.
  ///
  /// In en, this message translates to:
  /// **'Play Next'**
  String get contextMenuPlayNext;

  /// No description provided for @contextMenuAddToQueue.
  ///
  /// In en, this message translates to:
  /// **'Add to Queue'**
  String get contextMenuAddToQueue;

  /// No description provided for @contextMenuAddToPlaylistEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Add to Playlist…'**
  String get contextMenuAddToPlaylistEllipsis;

  /// No description provided for @contextMenuFavorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get contextMenuFavorite;

  /// No description provided for @contextMenuRemoveFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove Favorite'**
  String get contextMenuRemoveFavorite;

  /// No description provided for @contextMenuViewAlbum.
  ///
  /// In en, this message translates to:
  /// **'View Album'**
  String get contextMenuViewAlbum;

  /// No description provided for @contextMenuViewArtist.
  ///
  /// In en, this message translates to:
  /// **'View Artist'**
  String get contextMenuViewArtist;

  /// No description provided for @renameTrackDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename track'**
  String get renameTrackDialogTitle;

  /// No description provided for @renameTrackHint.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get renameTrackHint;

  /// No description provided for @renameAlbumDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename album'**
  String get renameAlbumDialogTitle;

  /// No description provided for @renameAlbumHint.
  ///
  /// In en, this message translates to:
  /// **'Album name'**
  String get renameAlbumHint;

  /// No description provided for @renameAlbumCollisionMessage.
  ///
  /// In en, this message translates to:
  /// **'An album named \"{name}\" by {albumArtist} already exists.'**
  String renameAlbumCollisionMessage(String name, String albumArtist);

  /// No description provided for @deleteFromDeviceDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete from device?'**
  String get deleteFromDeviceDialogTitle;

  /// No description provided for @deleteFromDeviceDialogBody.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" will be permanently deleted and can\'t be recovered.'**
  String deleteFromDeviceDialogBody(String title);

  /// No description provided for @miniPlayerDismissTooltip.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get miniPlayerDismissTooltip;

  /// No description provided for @songRowOptionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Track options'**
  String get songRowOptionsTooltip;

  /// No description provided for @songRowDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"?'**
  String songRowDeleteDialogTitle(String title);

  /// No description provided for @deviceBrowserTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Audio'**
  String get deviceBrowserTitle;

  /// No description provided for @deviceBrowserImportButton.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Import 1 track} other{Import {count} tracks}}'**
  String deviceBrowserImportButton(int count);

  /// No description provided for @deviceBrowserPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Audio access needed'**
  String get deviceBrowserPermissionTitle;

  /// No description provided for @deviceBrowserPermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'Listeny needs permission to see audio files on your device. Grant it in Settings to browse and import your audio.'**
  String get deviceBrowserPermissionMessage;

  /// No description provided for @deviceBrowserOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get deviceBrowserOpenSettings;

  /// No description provided for @deviceBrowserErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read your audio'**
  String get deviceBrowserErrorTitle;

  /// No description provided for @deviceBrowserUnknownError.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred.'**
  String get deviceBrowserUnknownError;

  /// No description provided for @deviceBrowserRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get deviceBrowserRetry;

  /// No description provided for @deviceBrowserNoAudioTitle.
  ///
  /// In en, this message translates to:
  /// **'No audio files found'**
  String get deviceBrowserNoAudioTitle;

  /// No description provided for @deviceBrowserNoAudioMessage.
  ///
  /// In en, this message translates to:
  /// **'Add audio to your device (downloads, transfers, etc.) and pull to retry.'**
  String get deviceBrowserNoAudioMessage;

  /// No description provided for @deviceBrowserSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search your audio'**
  String get deviceBrowserSearchHint;

  /// No description provided for @deviceBrowserNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get deviceBrowserNoMatches;

  /// No description provided for @deviceBrowserSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get deviceBrowserSelectAll;

  /// No description provided for @deviceBrowserDeselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get deviceBrowserDeselectAll;

  /// No description provided for @importFlowContextWhatsNew.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get importFlowContextWhatsNew;

  /// No description provided for @importFlowImportingTitle.
  ///
  /// In en, this message translates to:
  /// **'Importing audio'**
  String get importFlowImportingTitle;

  /// No description provided for @importFlowProcessedOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{processed} of {total} files · reading metadata'**
  String importFlowProcessedOfTotal(int processed, int total);

  /// No description provided for @importFlowCopiedNote.
  ///
  /// In en, this message translates to:
  /// **'Copied into the app — originals untouched.'**
  String get importFlowCopiedNote;

  /// No description provided for @importFlowAddedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 track added} other{{count} tracks added}}'**
  String importFlowAddedCount(int count);

  /// No description provided for @importFlowArtistsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 artist} other{{count} artists}}'**
  String importFlowArtistsCount(int count);

  /// No description provided for @importFlowDuplicatesSkipped.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 duplicate skipped} other{{count} duplicates skipped}}'**
  String importFlowDuplicatesSkipped(int count);

  /// No description provided for @importFlowAlreadyInLibrary.
  ///
  /// In en, this message translates to:
  /// **'Already in your library'**
  String get importFlowAlreadyInLibrary;

  /// No description provided for @importFlowUnsupportedSkipped.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 file not supported} other{{count} files not supported}}'**
  String importFlowUnsupportedSkipped(int count);

  /// No description provided for @importFlowCorruptSkipped.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 file could not be read} other{{count} files could not be read}}'**
  String importFlowCorruptSkipped(int count);

  /// No description provided for @importFlowPlayWhatsNew.
  ///
  /// In en, this message translates to:
  /// **'Play what\'s new'**
  String get importFlowPlayWhatsNew;

  /// No description provided for @downloadInstructions.
  ///
  /// In en, this message translates to:
  /// **'Paste a direct link to an audio or video file — MP3, M4A, AAC, WAV, FLAC, OGG, MP4, WebM.'**
  String get downloadInstructions;

  /// No description provided for @downloadUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://example.com/track.mp3'**
  String get downloadUrlHint;

  /// No description provided for @downloadPasteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get downloadPasteTooltip;

  /// No description provided for @downloadInvalidUrlError.
  ///
  /// In en, this message translates to:
  /// **'Paste a valid link to a media file.'**
  String get downloadInvalidUrlError;

  /// No description provided for @downloadFormatLabel.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get downloadFormatLabel;

  /// No description provided for @downloadFormatBestAvailable.
  ///
  /// In en, this message translates to:
  /// **'Best available audio'**
  String get downloadFormatBestAvailable;

  /// No description provided for @downloadFormatMp3.
  ///
  /// In en, this message translates to:
  /// **'MP3'**
  String get downloadFormatMp3;

  /// No description provided for @downloadAnotherButton.
  ///
  /// In en, this message translates to:
  /// **'Download another'**
  String get downloadAnotherButton;

  /// No description provided for @downloadAudioButton.
  ///
  /// In en, this message translates to:
  /// **'Download Audio'**
  String get downloadAudioButton;

  /// No description provided for @downloadResolvingLink.
  ///
  /// In en, this message translates to:
  /// **'Resolving link…'**
  String get downloadResolvingLink;

  /// No description provided for @downloadDownloadingIndeterminate.
  ///
  /// In en, this message translates to:
  /// **'Downloading…'**
  String get downloadDownloadingIndeterminate;

  /// No description provided for @downloadDownloadingPercent.
  ///
  /// In en, this message translates to:
  /// **'Downloading {percent}%'**
  String downloadDownloadingPercent(int percent);

  /// No description provided for @downloadConverting.
  ///
  /// In en, this message translates to:
  /// **'Converting…'**
  String get downloadConverting;

  /// No description provided for @downloadImporting.
  ///
  /// In en, this message translates to:
  /// **'Importing into your library…'**
  String get downloadImporting;

  /// No description provided for @downloadCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled.'**
  String get downloadCancelled;

  /// No description provided for @downloadQueued.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a free slot…'**
  String get downloadQueued;

  /// No description provided for @downloadRemoveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get downloadRemoveTooltip;

  /// No description provided for @downloadGenericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get downloadGenericError;

  /// No description provided for @downloadAddedToLibrary.
  ///
  /// In en, this message translates to:
  /// **'✓ Added to your library\n{title}'**
  String downloadAddedToLibrary(String title);

  /// No description provided for @downloadNothingNewAdded.
  ///
  /// In en, this message translates to:
  /// **'This link didn\'t add anything new to your library.'**
  String get downloadNothingNewAdded;

  /// No description provided for @downloadHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Download History'**
  String get downloadHistoryTitle;

  /// No description provided for @downloadHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your download history will appear here.'**
  String get downloadHistoryEmpty;

  /// No description provided for @downloadClearHistoryDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear download history?'**
  String get downloadClearHistoryDialogTitle;

  /// No description provided for @downloadClearHistoryDialogBody.
  ///
  /// In en, this message translates to:
  /// **'This only clears the history list — it does not remove any tracks.'**
  String get downloadClearHistoryDialogBody;

  /// No description provided for @downloadSourceDirectLink.
  ///
  /// In en, this message translates to:
  /// **'Direct link'**
  String get downloadSourceDirectLink;

  /// No description provided for @trimMenuLabel.
  ///
  /// In en, this message translates to:
  /// **'Trim'**
  String get trimMenuLabel;

  /// No description provided for @trimTitle.
  ///
  /// In en, this message translates to:
  /// **'Trim audio'**
  String get trimTitle;

  /// No description provided for @trimStartLabel.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get trimStartLabel;

  /// No description provided for @trimEndLabel.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get trimEndLabel;

  /// No description provided for @trimLengthLabel.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get trimLengthLabel;

  /// No description provided for @trimPreviewFromLabel.
  ///
  /// In en, this message translates to:
  /// **'Preview from'**
  String get trimPreviewFromLabel;

  /// No description provided for @trimPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get trimPreview;

  /// No description provided for @trimStopPreview.
  ///
  /// In en, this message translates to:
  /// **'Stop preview'**
  String get trimStopPreview;

  /// No description provided for @trimFadeLabel.
  ///
  /// In en, this message translates to:
  /// **'Fade in / out'**
  String get trimFadeLabel;

  /// No description provided for @trimFadeOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get trimFadeOff;

  /// No description provided for @trimSaveNew.
  ///
  /// In en, this message translates to:
  /// **'Save as new track'**
  String get trimSaveNew;

  /// No description provided for @trimReplaceOriginal.
  ///
  /// In en, this message translates to:
  /// **'Replace original'**
  String get trimReplaceOriginal;

  /// No description provided for @trimSaved.
  ///
  /// In en, this message translates to:
  /// **'Trimmed track saved'**
  String get trimSaved;

  /// No description provided for @trimReplaced.
  ///
  /// In en, this message translates to:
  /// **'Original replaced with the trimmed track'**
  String get trimReplaced;

  /// No description provided for @trimFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not trim this file'**
  String get trimFailed;

  /// No description provided for @trimTooShort.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one second'**
  String get trimTooShort;

  /// No description provided for @trimDuplicate.
  ///
  /// In en, this message translates to:
  /// **'This trimmed track is already in your library'**
  String get trimDuplicate;

  /// No description provided for @trimWorking.
  ///
  /// In en, this message translates to:
  /// **'Trimming…'**
  String get trimWorking;

  /// No description provided for @importVideoButton.
  ///
  /// In en, this message translates to:
  /// **'Import video as MP3'**
  String get importVideoButton;

  /// No description provided for @importVideoConverting.
  ///
  /// In en, this message translates to:
  /// **'Converting video to MP3…'**
  String get importVideoConverting;

  /// No description provided for @importVideoDone.
  ///
  /// In en, this message translates to:
  /// **'Added to your library as MP3'**
  String get importVideoDone;

  /// No description provided for @importVideoFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not extract audio from this video'**
  String get importVideoFailed;

  /// No description provided for @importVideoDuplicate.
  ///
  /// In en, this message translates to:
  /// **'This track is already in your library'**
  String get importVideoDuplicate;

  /// No description provided for @importVideoFromGallery.
  ///
  /// In en, this message translates to:
  /// **'From Photos / Gallery'**
  String get importVideoFromGallery;

  /// No description provided for @importVideoFromFiles.
  ///
  /// In en, this message translates to:
  /// **'From Files'**
  String get importVideoFromFiles;

  /// No description provided for @importVideoNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Name this track'**
  String get importVideoNameTitle;

  /// No description provided for @importVideoNameHint.
  ///
  /// In en, this message translates to:
  /// **'Track name'**
  String get importVideoNameHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'bn',
    'en',
    'es',
    'fr',
    'hi',
    'pt',
    'ru',
    'ur',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'ur':
      return AppLocalizationsUr();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
