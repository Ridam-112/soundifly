import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/listening_room.dart';
import '../models/song.dart';
import '../data/mock_data.dart';
import 'audio_player_provider.dart';

class ListeningRoomProvider extends ChangeNotifier {
  ListeningRoom? _currentRoom;
  final List<ListeningRoom> _publicRooms = [];
  Timer? _partnerSimulationTimer;
  AudioPlayerProvider? _audioPlayer;

  ListeningRoomProvider() {
    _initSampleRooms();
  }

  void attachAudioPlayer(AudioPlayerProvider player) {
    _audioPlayer = player;
    _audioPlayer!.onPlaybackStateChanged = (song, isPlaying, position) {
      if (_currentRoom != null && isHost) {
        syncHostPlayback(song, isPlaying, position);
      }
    };
  }

  ListeningRoom? get currentRoom => _currentRoom;
  List<ListeningRoom> get publicRooms => _publicRooms;
  bool get isInRoom => _currentRoom != null;
  bool get isHost => _currentRoom?.hostId == 'u_current';

  void _initSampleRooms() {
    _publicRooms.addAll([
      ListeningRoom(
        id: 'r_couple_demo',
        roomCode: 'LOVE99',
        name: 'Couple Chill & Late Night ✨',
        hostId: 'u_partner',
        hostName: 'Premika',
        isCoupleMode: true,
        currentSong: MockData.allSongs[4],
        isPlaying: true,
        playbackPosition: const Duration(seconds: 45),
        members: [
          RoomMember(
            id: 'u_partner',
            name: 'Premika ❤️',
            avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80',
            isHost: true,
            joinedAt: DateTime.now().subtract(const Duration(minutes: 10)),
          ),
        ],
        sharedQueue: [MockData.allSongs[4], MockData.allSongs[1]],
      ),
      ListeningRoom(
        id: 'r_lofi_cafe',
        roomCode: 'LOFI24',
        name: 'Midnight Study & Lo-Fi Session',
        hostId: 'u_host2',
        hostName: 'Siam Beats',
        isCoupleMode: false,
        currentSong: MockData.allSongs[2],
        isPlaying: true,
        playbackPosition: const Duration(seconds: 80),
        members: [
          RoomMember(
            id: 'u_host2',
            name: 'Siam Beats',
            avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&auto=format&fit=crop&q=80',
            isHost: true,
            joinedAt: DateTime.now().subtract(const Duration(minutes: 25)),
          ),
          RoomMember(
            id: 'u_guest1',
            name: 'Farhan',
            avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&auto=format&fit=crop&q=80',
            joinedAt: DateTime.now().subtract(const Duration(minutes: 5)),
          ),
        ],
        sharedQueue: [MockData.allSongs[2], MockData.allSongs[0]],
      ),
    ]);
  }

  ListeningRoom createRoom({
    required String name,
    bool isCoupleMode = false,
    Song? initialSong,
  }) {
    final song = initialSong ?? MockData.allSongs.first;
    final code = isCoupleMode 
        ? 'LOVE${Random().nextInt(90) + 10}'
        : 'JAM${Random().nextInt(900) + 100}';

    final room = ListeningRoom(
      id: 'r_${const Uuid().v4().substring(0, 8)}',
      roomCode: code,
      name: name.trim().isEmpty ? (isCoupleMode ? 'My Couple Room ❤️' : 'Soundifly Jam Session') : name,
      hostId: 'u_current',
      hostName: 'You',
      isCoupleMode: isCoupleMode,
      currentSong: song,
      isPlaying: true,
      playbackPosition: Duration.zero,
      members: [
        RoomMember(
          id: 'u_current',
          name: 'You (Host)',
          avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200&auto=format&fit=crop&q=80',
          isHost: true,
          joinedAt: DateTime.now(),
        ),
      ],
      sharedQueue: [song],
      messages: [
        RoomMessage(
          id: 'm1',
          senderName: 'System',
          text: isCoupleMode 
              ? 'Welcome to Couple Mode ❤️ Share the code $code with your partner to listen together in sync!'
              : 'Listening Room created! Share code $code with friends.',
          timestamp: DateTime.now(),
        ),
      ],
    );

    _currentRoom = room;
    notifyListeners();

    // Start playing initial track
    _audioPlayer?.playSong(song);

    // Simulate partner activity in Couple Mode
    if (isCoupleMode) {
      _startCoupleSimulation();
    }

    return room;
  }

  bool joinRoomByCode(String code) {
    final formatted = code.trim().toUpperCase();
    final found = _publicRooms.firstWhere(
      (r) => r.roomCode == formatted,
      orElse: () => ListeningRoom(
        id: 'r_mock_joined',
        roomCode: formatted,
        name: 'Private Room #$formatted',
        hostId: 'u_remote_host',
        hostName: 'Friend',
        isCoupleMode: formatted.startsWith('LOVE'),
        currentSong: MockData.allSongs[1],
        isPlaying: true,
        playbackPosition: const Duration(seconds: 15),
        members: [
          RoomMember(
            id: 'u_remote_host',
            name: formatted.startsWith('LOVE') ? 'Premika ❤️' : 'Friend',
            avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80',
            isHost: true,
            joinedAt: DateTime.now().subtract(const Duration(minutes: 5)),
          ),
        ],
        sharedQueue: [MockData.allSongs[1], MockData.allSongs[4]],
      ),
    );

    final updatedMembers = List<RoomMember>.from(found.members);
    if (!updatedMembers.any((m) => m.id == 'u_current')) {
      updatedMembers.add(
        RoomMember(
          id: 'u_current',
          name: 'You',
          avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200&auto=format&fit=crop&q=80',
          joinedAt: DateTime.now(),
        ),
      );
    }

    _currentRoom = found.copyWith(members: updatedMembers);
    notifyListeners();

    if (_currentRoom?.currentSong != null && _audioPlayer != null) {
      _audioPlayer!.syncFromRemote(
        song: _currentRoom!.currentSong!,
        isPlaying: _currentRoom!.isPlaying,
        position: _currentRoom!.playbackPosition,
      );
    }

    if (_currentRoom!.isCoupleMode) {
      _startCoupleSimulation();
    }

    return true;
  }

  void leaveRoom() {
    _partnerSimulationTimer?.cancel();
    _currentRoom = null;
    notifyListeners();
  }

  void syncHostPlayback(Song? song, bool isPlaying, Duration position) {
    if (_currentRoom == null) return;
    _currentRoom = _currentRoom!.copyWith(
      currentSong: song,
      isPlaying: isPlaying,
      playbackPosition: position,
    );
    notifyListeners();
  }

  void sendReaction(String emoji) {
    if (_currentRoom == null) return;

    final msg = RoomMessage(
      id: const Uuid().v4(),
      senderName: 'You',
      text: emoji,
      timestamp: DateTime.now(),
      isReaction: true,
      reactionEmoji: emoji,
    );

    final updatedMessages = List<RoomMessage>.from(_currentRoom!.messages)..add(msg);
    _currentRoom = _currentRoom!.copyWith(messages: updatedMessages);
    notifyListeners();
  }

  void sendMessage(String text) {
    if (_currentRoom == null || text.trim().isEmpty) return;

    final msg = RoomMessage(
      id: const Uuid().v4(),
      senderName: 'You',
      text: text.trim(),
      timestamp: DateTime.now(),
    );

    final updatedMessages = List<RoomMessage>.from(_currentRoom!.messages)..add(msg);
    _currentRoom = _currentRoom!.copyWith(messages: updatedMessages);
    notifyListeners();
  }

  void addToSharedQueue(Song song) {
    if (_currentRoom == null) return;
    final updatedQueue = List<Song>.from(_currentRoom!.sharedQueue)..add(song);
    _currentRoom = _currentRoom!.copyWith(sharedQueue: updatedQueue);
    notifyListeners();
  }

  void _startCoupleSimulation() {
    _partnerSimulationTimer?.cancel();
    // Simulate real-time reaction / message from partner after 6-12 seconds
    _partnerSimulationTimer = Timer.periodic(const Duration(seconds: 14), (timer) {
      if (_currentRoom == null || !_currentRoom!.isCoupleMode) {
        timer.cancel();
        return;
      }

      final partnerReactions = ['❤️', '🔥', '🥹', '✨', '🎶'];
      final partnerChats = [
        'Eita amar onek pochonder gaan! 🥰',
        'Together forever listening ❤️',
        'Next song ta ami add korlam!',
        'Aro beshi gaan shuni cholo!',
      ];

      final isEmoji = Random().nextBool();
      final msg = RoomMessage(
        id: const Uuid().v4(),
        senderName: 'Premika ❤️',
        text: isEmoji 
            ? partnerReactions[Random().nextInt(partnerReactions.length)]
            : partnerChats[Random().nextInt(partnerChats.length)],
        timestamp: DateTime.now(),
        isReaction: isEmoji,
        reactionEmoji: isEmoji ? partnerReactions[Random().nextInt(partnerReactions.length)] : null,
      );

      final updated = List<RoomMessage>.from(_currentRoom!.messages)..add(msg);
      _currentRoom = _currentRoom!.copyWith(messages: updated);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _partnerSimulationTimer?.cancel();
    super.dispose();
  }
}
