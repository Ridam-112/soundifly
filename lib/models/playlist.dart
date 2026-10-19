import 'song.dart';

enum PlaylistVisibility {
  public,
  private,
  collaborative,
}

class Playlist {
  final String id;
  final String title;
  final String description;
  final String coverUrl;
  final String ownerName;
  final String ownerId;
  final PlaylistVisibility visibility;
  final List<Song> songs;
  final bool isLikedFolder;
  final DateTime createdAt;
  final List<String> collaboratorNames;

  Playlist({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.ownerName,
    required this.ownerId,
    this.visibility = PlaylistVisibility.public,
    List<Song>? songs,
    this.isLikedFolder = false,
    DateTime? createdAt,
    this.collaboratorNames = const [],
  })  : songs = songs ?? [],
        createdAt = createdAt ?? DateTime.now();

  int get trackCount => songs.length;

  bool get isPublic => visibility == PlaylistVisibility.public;
  bool get isPrivate => visibility == PlaylistVisibility.private;

  Duration get totalDuration {
    return songs.fold(
      Duration.zero,
      (previous, song) => previous + song.duration,
    );
  }

  String get formattedTotalDuration {
    final mins = totalDuration.inMinutes;
    if (mins > 60) {
      final hrs = mins ~/ 60;
      final remMins = mins % 60;
      return '${hrs}h ${remMins}m';
    }
    return '$mins min';
  }

  factory Playlist.fromMap(
    Map<String, dynamic> map, {
    List<Song> songs = const [],
    String currentUserId = '',
    String currentUserName = 'You',
  }) {
    final ownerId = map['user_id']?.toString() ?? 'u_current';
    final isPublic = map['is_public'] as bool? ?? false;
    final isOwner = currentUserId.isNotEmpty && ownerId == currentUserId;

    return Playlist(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Untitled Playlist',
      description: map['description']?.toString() ?? '',
      coverUrl: map['cover_url']?.toString() ??
          'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600&auto=format&fit=crop&q=80',
      ownerName: isOwner ? currentUserName : 'Soundifly User',
      ownerId: ownerId,
      visibility: isPublic ? PlaylistVisibility.public : PlaylistVisibility.private,
      songs: songs,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': ownerId,
      'title': title,
      'description': description,
      'cover_url': coverUrl,
      'is_public': isPublic,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Playlist copyWith({
    String? title,
    String? description,
    String? coverUrl,
    PlaylistVisibility? visibility,
    List<Song>? songs,
    List<String>? collaboratorNames,
  }) {
    return Playlist(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      ownerName: ownerName,
      ownerId: ownerId,
      visibility: visibility ?? this.visibility,
      songs: songs ?? List.from(this.songs),
      isLikedFolder: isLikedFolder,
      createdAt: createdAt,
      collaboratorNames: collaboratorNames ?? this.collaboratorNames,
    );
  }
}
