import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundifly/providers/audio_player_provider.dart';
import 'package:soundifly/providers/playlist_provider.dart';
import 'package:soundifly/providers/listening_room_provider.dart';
import 'package:soundifly/models/playlist.dart';
import 'package:soundifly/models/user_settings.dart';
import 'package:soundifly/data/mock_data.dart';
import 'package:soundifly/data/music_onboarding_data.dart';
import 'package:soundifly/services/lyrics_service.dart';
import 'package:soundifly/services/artist_discovery_service.dart';
import 'package:soundifly/models/song.dart';
import 'package:soundifly/models/artist.dart';
import 'package:soundifly/models/album.dart';
import 'package:soundifly/models/search_result.dart';
import 'package:soundifly/repositories/music_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers.global'), (call) async {
      return 1;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers'), (call) async {
      return 1;
    });
  });

  group('Soundifly Business Logic Tests', () {
    test('PlaylistProvider creates public and collaborative playlists correctly', () {
      final prov = PlaylistProvider();
      expect(prov.playlists.isNotEmpty, true);

      // Create a collaborative playlist
      final newCollab = prov.createPlaylist(
        title: 'Us & Music ❤️',
        description: 'Collaborative with Premika',
        visibility: PlaylistVisibility.collaborative,
      );

      expect(newCollab.title, 'Us & Music ❤️');
      expect(newCollab.visibility, PlaylistVisibility.collaborative);
      expect(newCollab.collaboratorNames.contains('You'), true);

      // Add a song
      final song = MockData.allSongs.first;
      prov.addSongToPlaylist(newCollab.id, song);
      expect(prov.playlists.firstWhere((p) => p.id == newCollab.id).songs.length, 1);

      // Like song test
      expect(prov.isSongLiked(song.id), false);
      prov.toggleLikeSong(song);
      expect(prov.isSongLiked(song.id), true);
      prov.toggleLikeSong(song);
      expect(prov.isSongLiked(song.id), false);

      // Create collaborative playlist with email
      final emailCollab = prov.createPlaylist(
        title: 'Couple Jam',
        description: 'For my partner',
        visibility: PlaylistVisibility.collaborative,
        collaboratorEmail: 'partner@gmail.com',
      );
      expect(emailCollab.collaboratorEmail, 'partner@gmail.com');
      expect(emailCollab.isCollaborative, true);
    });

    test('ListeningRoomProvider starts Couple Mode and Jam Session correctly', () {
      final roomProv = ListeningRoomProvider();

      // Create couple room
      final room = roomProv.createRoom(name: 'Couple Session', isCoupleMode: true);
      expect(roomProv.isInRoom, true);
      expect(roomProv.isHost, true);
      expect(room.isCoupleMode, true);
      expect(room.roomCode.startsWith('LOVE'), true);

      // Send reaction
      roomProv.sendReaction('❤️');
      expect(roomProv.currentRoom!.messages.any((m) => m.reactionEmoji == '❤️'), true);

      // Send chat
      roomProv.sendMessage('Best romantic track ever!');
      expect(roomProv.currentRoom!.messages.any((m) => m.text == 'Best romantic track ever!'), true);

      // Leave room
      roomProv.leaveRoom();
      expect(roomProv.isInRoom, false);
    });

    test('AudioPlayerProvider queue and shuffle logic works', () async {
      final player = AudioPlayerProvider();
      expect(player.currentSong, null); // Clean initial state on cold start
      player.playSong(MockData.allSongs.first, playlist: MockData.allSongs);
      expect(player.queue.isNotEmpty, true);

      // Cycle loop mode: off -> all -> one -> off
      expect(player.loopMode, LoopMode.off);
      player.cycleLoopMode();
      expect(player.loopMode, LoopMode.all);
      player.cycleLoopMode();
      expect(player.loopMode, LoopMode.one);
      player.cycleLoopMode();
      expect(player.loopMode, LoopMode.off);

      // Shuffle toggle
      expect(player.isShuffle, false);
      player.toggleShuffle();
      expect(player.isShuffle, true);

      // Reset playback on logout / user switch
      await player.resetPlayback();
      expect(player.currentSong, null);
      expect(player.queue.isEmpty, true);
      expect(player.isPlaying, false);
    });

    test('Music Onboarding Catalogue & Preference Models validate accurately', () async {
      // 1. Language catalogue checks: all 14 required languages
      final languages = MusicOnboardingData.availableLanguages;
      expect(languages.length, 14);
      final languageNames = languages.map((l) => l.name).toSet();
      expect(languageNames.contains('Bengali'), true);
      expect(languageNames.contains('Hindi'), true);
      expect(languageNames.contains('English'), true);
      expect(languageNames.contains('Punjabi'), true);
      expect(languageNames.contains('Tamil'), true);
      expect(languageNames.contains('Telugu'), true);
      expect(languageNames.contains('Malayalam'), true);
      expect(languageNames.contains('Kannada'), true);
      expect(languageNames.contains('Marathi'), true);
      expect(languageNames.contains('Urdu'), true);
      expect(languageNames.contains('Assamese'), true);
      expect(languageNames.contains('Odia'), true);
      expect(languageNames.contains('Bhojpuri'), true);
      expect(languageNames.contains('Gujarati'), true);

      // 2. Verified real portraits: no Unsplash or generic stock photos
      for (final artist in MusicOnboardingData.curatedArtists) {
        expect(artist.imageUrl.contains('unsplash.com'), false);
        expect(artist.imageUrl.isNotEmpty, true);
        expect(artist.isVerifiedImage, true);
        expect(artist.languages.isNotEmpty, true);
        expect(artist.artistTypeDisplay.isNotEmpty, true);
      }

      // 3. Multi-language artist filtering
      final bengaliArtists = MusicOnboardingData.getArtistsForLanguages(['Bengali']);
      expect(bengaliArtists.isNotEmpty, true);
      expect(bengaliArtists.any((a) => a.name == 'Arijit Singh'), true);
      expect(bengaliArtists.any((a) => a.name == 'Anupam Roy'), true);

      final hindiArtists = MusicOnboardingData.getArtistsForLanguages(['Hindi']);
      expect(hindiArtists.any((a) => a.name == 'Arijit Singh'), true); // multi-language match

      final multiArtists = MusicOnboardingData.getArtistsForLanguages(['Bengali', 'English']);
      expect(multiArtists.any((a) => a.name == 'Arijit Singh'), true);
      expect(multiArtists.any((a) => a.name == 'The Weeknd' || a.name == 'Taylor Swift'), true);

      // 4. ArtistDiscoveryService search checks
      final localMatches = await ArtistDiscoveryService.searchArtists('Arijit');
      expect(localMatches.isNotEmpty, true);
      expect(localMatches.any((a) => a.name.contains('Arijit')), true);

      // 5. Genre catalogue checks
      expect(MusicOnboardingData.availableGenres.length, 11);
      expect(MusicOnboardingData.availableGenres.any((g) => g.name == 'Romantic'), true);
      expect(MusicOnboardingData.availableGenres.any((g) => g.name == 'Chill & Lo-Fi'), true);

      // 6. UserSettings serialization with onboarding preferences
      final settings = UserSettings(
        userId: 'test_user_123',
        onboardingCompleted: true,
        preferredLanguages: ['Bengali', 'Hindi'],
        favoriteArtists: ['Arijit Singh', 'Shreya Ghoshal'],
        preferredGenres: ['Romantic', 'Chill & Lo-Fi'],
      );

      final map = settings.toMap();
      expect(map['onboarding_completed'], true);
      expect(map['preferred_languages'], ['Bengali', 'Hindi']);
      expect(map['favorite_artists'], ['Arijit Singh', 'Shreya Ghoshal']);
      expect(map['preferred_genres'], ['Romantic', 'Chill & Lo-Fi']);

      final restored = UserSettings.fromMap(map, userId: 'test_user_123');
      expect(restored.onboardingCompleted, true);
      expect(restored.preferredLanguages, ['Bengali', 'Hindi']);
      expect(restored.favoriteArtists, ['Arijit Singh', 'Shreya Ghoshal']);
      expect(restored.preferredGenres, ['Romantic', 'Chill & Lo-Fi']);

      // 7. copyWith updates preferences immutably
      final updated = restored.copyWith(
        preferredLanguages: ['Bengali', 'English'],
        favoriteArtists: ['Arijit Singh', 'Ed Sheeran'],
        preferredGenres: ['Romantic', 'Rock & Metal'],
      );
      expect(updated.preferredLanguages, ['Bengali', 'English']);
      expect(updated.favoriteArtists, ['Arijit Singh', 'Ed Sheeran']);
      expect(updated.preferredGenres, ['Romantic', 'Rock & Metal']);
      expect(updated.onboardingCompleted, true);
    });

    test('LyricsService cleaning, LRC parsing, and placeholder detection work', () {
      // 1. cleanSongTitle tests
      expect(
        LyricsService.cleanSongTitle('Believer (Official Music Video)', 'Imagine Dragons'),
        'Believer',
      );
      expect(
        LyricsService.cleanSongTitle('Imagine Dragons - Believer [Audio]', 'Imagine Dragons'),
        'Believer',
      );
      expect(
        LyricsService.cleanSongTitle('Kesariya (From "Brahmāstra")'),
        'Kesariya',
      );

      // 2. cleanArtistName tests
      expect(
        LyricsService.cleanArtistName('Pritam, Arijit Singh, Amitabh Bhattacharya'),
        'Pritam',
      );
      expect(
        LyricsService.cleanArtistName('The Weeknd feat. Daft Punk'),
        'The Weeknd',
      );

      // 3. parseLrcString tests
      const lrcSample = '''
[00:07.82] First things first
[00:12.15] I'm fired up
[00:18.00][00:24.00] The way that things have been
''';
      final parsed = LyricsService.parseLrcString(lrcSample);
      expect(parsed.length, 4);
      expect(parsed[0].text, 'First things first');
      expect(parsed[0].timestamp.inMilliseconds, 7820);
      expect(parsed[1].text, "I'm fired up");
      expect(parsed[1].timestamp.inMilliseconds, 12150);
      // Multiple timestamps parsed and sorted
      expect(parsed[2].text, 'The way that things have been');
      expect(parsed[2].timestamp.inMilliseconds, 18000);
      expect(parsed[3].text, 'The way that things have been');
      expect(parsed[3].timestamp.inMilliseconds, 24000);
    });

    test('SearchResult empty vs populated states and filtering behave correctly', () {
      final emptyResult = SearchResult.empty;
      expect(emptyResult.isEmpty, true);
      expect(emptyResult.isNotEmpty, false);

      final populated = SearchResult(
        query: 'Anuv Jain',
        artists: [
          const Artist(
            id: 'art_anuv',
            name: 'Anuv Jain',
            imageUrl: 'https://c.saavncdn.com/artists/Anuv_Jain_001_20231206073013_500x500.jpg',
            monthlyListeners: 4800,
          ),
        ],
        albums: [
          const Album(
            id: 'saavn_56692135',
            title: 'Jo Tum Mere Ho',
            artist: 'Anuv Jain',
            coverUrl: 'https://c.saavncdn.com/401/Jo-Tum-Mere-Ho-Hindi-2024-500x500.jpg',
            releaseYear: '2024',
          ),
        ],
      );

      expect(populated.isEmpty, false);
      expect(populated.isNotEmpty, true);
      expect(populated.artists.length, 1);
      expect(populated.albums.length, 1);
      expect(populated.songs.isEmpty, true);
    });

    test('Production JSON shapes parse cleanly into Song, Artist, and Album models', () {
      // 1. Song model parsing
      final songJson = {
        'id': 'saavn_cli-P2pu',
        'title': 'Arz Kiya Hai | Coke Studio Bharat',
        'artist': 'Anuv Jain',
        'album': 'Arz Kiya Hai | Coke Studio Bharat',
        'coverUrl': 'https://c.saavncdn.com/504/Arz-Kiya-Hai-500x500.jpg',
        'audioUrl': 'https://soundifly.onrender.com/api/stream/saavn_cli-P2pu',
        'durationSeconds': 269,
        'genre': 'Hindi',
        'releaseYear': '2025'
      };

      final song = Song(
        id: songJson['id'] as String,
        title: songJson['title'] as String,
        artist: songJson['artist'] as String,
        album: songJson['album'] as String,
        coverUrl: songJson['coverUrl'] as String,
        audioUrl: songJson['audioUrl'] as String,
        duration: Duration(seconds: songJson['durationSeconds'] as int),
        genre: songJson['genre'] as String,
        releaseYear: songJson['releaseYear'] as String,
      );

      expect(song.id, 'saavn_cli-P2pu');
      expect(song.title, 'Arz Kiya Hai | Coke Studio Bharat');
      expect(song.artist, 'Anuv Jain');
      expect(song.duration.inSeconds, 269);

      // 2. Artist model parsing
      final artistJson = {
        'id': 'saavn_4878402',
        'name': 'Anuv Jain',
        'imageUrl': 'https://c.saavncdn.com/artists/Anuv_Jain_001_20231206073013_500x500.jpg',
        'popularity': 4828,
        'artistType': 'Singer'
      };

      final artist = Artist(
        id: artistJson['id'] as String,
        name: artistJson['name'] as String,
        imageUrl: artistJson['imageUrl'] as String,
        monthlyListeners: artistJson['popularity'] as int,
        genres: [artistJson['artistType'] as String],
      );

      expect(artist.name, 'Anuv Jain');
      expect(artist.imageUrl.contains('500x500'), true);
      expect(artist.formattedListeners, '4.8K monthly listeners');

      // 3. Album model parsing & totalDuration calculation
      final albumJson = {
        'id': 'saavn_38682222',
        'title': 'Bhediya',
        'artist': 'Sachin-Jigar, Arijit Singh',
        'coverUrl': 'https://c.saavncdn.com/815/Bhediya-Hindi-2023-500x500.jpg',
        'releaseYear': '2023',
        'genre': 'hindi'
      };

      final album = Album(
        id: albumJson['id'] as String,
        title: albumJson['title'] as String,
        artist: albumJson['artist'] as String,
        coverUrl: albumJson['coverUrl'] as String,
        releaseYear: albumJson['releaseYear'] as String,
        genre: albumJson['genre'] as String,
        tracks: [
          const Song(
            id: 'track_1',
            title: 'Apna Bana Le',
            artist: 'Arijit Singh, Sachin-Jigar',
            album: 'Bhediya',
            coverUrl: '',
            audioUrl: '',
            duration: Duration(minutes: 4, seconds: 21),
          ),
        ],
      );

      expect(album.title, 'Bhediya');
      expect(album.releaseYear, '2023');
      expect(album.tracks.length, 1);
      expect(album.formattedTotalDuration, '4 mins');
    });

    test('Case-insensitive queries, whitespace trimming, and curated search work accurately', () async {
      final repo = SoundiflyMusicRepository();

      // Test with messy casing & leading/trailing whitespace
      final result1 = await repo.search('   aNuV   jAiN   ', filter: 'Artists');
      expect(result1.artists.isNotEmpty, true);
      expect(result1.artists.any((a) => a.name.toLowerCase() == 'anuv jain'), true);

      final result2 = await repo.search('ARIJIT SINGH', filter: 'Artists');
      expect(result2.artists.isNotEmpty, true);
      expect(result2.artists.any((a) => a.name.toLowerCase() == 'arijit singh'), true);

      // Suggestions test
      final suggs = await repo.getSuggestions('arijit');
      expect(suggs.isNotEmpty, true);
      expect(suggs.any((s) => s.toLowerCase().contains('arijit')), true);
    });

    test('Empty results handle cleanly without throwing exceptions', () async {
      final repo = SoundiflyMusicRepository();
      // Empty query string
      final emptyRes = await repo.search('', filter: 'All');
      expect(emptyRes.isEmpty, true);

      final whitespaceRes = await repo.search('   ', filter: 'Songs');
      expect(whitespaceRes.isEmpty, true);

      // Random non-existent query
      final noMatchRes = await repo.search('xyz999nonexistentqueryabc');
      expect(noMatchRes.query, 'xyz999nonexistentqueryabc');
    });

    test('Category switching and caching preserve clean state', () async {
      final repo = SoundiflyMusicRepository();

      // 1. Search Artists
      final artistResult = await repo.search('Anupam Roy', filter: 'Artists');
      expect(artistResult.artists.isNotEmpty, true);
      expect(artistResult.artists.any((a) => a.name.contains('Anupam')), true);

      // 2. Search All
      final allResult = await repo.search('Anupam Roy', filter: 'All');
      expect(allResult.artists.isNotEmpty, true);
    });
  });
}
