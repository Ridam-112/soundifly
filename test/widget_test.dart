import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundifly/providers/audio_player_provider.dart';
import 'package:soundifly/providers/playlist_provider.dart';
import 'package:soundifly/providers/listening_room_provider.dart';
import 'package:soundifly/models/playlist.dart';
import 'package:soundifly/data/mock_data.dart';

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
      expect(prov.isSongLiked(song.id), true);
      prov.toggleLikeSong(song);
      expect(prov.isSongLiked(song.id), false);
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

    test('AudioPlayerProvider queue and shuffle logic works', () {
      final player = AudioPlayerProvider();
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
    });
  });
}
