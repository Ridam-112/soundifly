import 'song.dart';

class RoomMember {
  final String id;
  final String name;
  final String avatarUrl;
  final bool isHost;
  final DateTime joinedAt;

  const RoomMember({
    required this.id,
    required this.name,
    required this.avatarUrl,
    this.isHost = false,
    required this.joinedAt,
  });
}

class RoomMessage {
  final String id;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isReaction;
  final String? reactionEmoji;

  const RoomMessage({
    required this.id,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.isReaction = false,
    this.reactionEmoji,
  });
}

class ListeningRoom {
  final String id;
  final String roomCode;
  final String name;
  final String hostId;
  final String hostName;
  final bool isCoupleMode;
  final Song? currentSong;
  final bool isPlaying;
  final Duration playbackPosition;
  final List<RoomMember> members;
  final List<Song> sharedQueue;
  final List<RoomMessage> messages;

  const ListeningRoom({
    required this.id,
    required this.roomCode,
    required this.name,
    required this.hostId,
    required this.hostName,
    this.isCoupleMode = false,
    this.currentSong,
    this.isPlaying = false,
    this.playbackPosition = Duration.zero,
    this.members = const [],
    this.sharedQueue = const [],
    this.messages = const [],
  });

  ListeningRoom copyWith({
    String? name,
    Song? currentSong,
    bool? isPlaying,
    Duration? playbackPosition,
    List<RoomMember>? members,
    List<Song>? sharedQueue,
    List<RoomMessage>? messages,
  }) {
    return ListeningRoom(
      id: id,
      roomCode: roomCode,
      name: name ?? this.name,
      hostId: hostId,
      hostName: hostName,
      isCoupleMode: isCoupleMode,
      currentSong: currentSong ?? this.currentSong,
      isPlaying: isPlaying ?? this.isPlaying,
      playbackPosition: playbackPosition ?? this.playbackPosition,
      members: members ?? this.members,
      sharedQueue: sharedQueue ?? this.sharedQueue,
      messages: messages ?? this.messages,
    );
  }
}
