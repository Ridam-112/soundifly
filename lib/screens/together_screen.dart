import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/listening_room_provider.dart';
import '../providers/audio_player_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_network_image.dart';

class TogetherScreen extends StatefulWidget {
  const TogetherScreen({super.key});

  @override
  State<TogetherScreen> createState() => _TogetherScreenState();
}

class _TogetherScreenState extends State<TogetherScreen> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _chatController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomProv = context.watch<ListeningRoomProvider>();
    final player = context.watch<AudioPlayerProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppGradients.primaryOrange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'Listen Together',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.white),
            ),
          ],
        ),
        actions: [
          if (roomProv.isInRoom)
            TextButton.icon(
              icon: const Icon(Icons.exit_to_app_rounded, color: AppColors.error, size: 18),
              label: const Text('Leave', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
              onPressed: () => roomProv.leaveRoom(),
            ),
        ],
      ),
      body: roomProv.isInRoom
          ? _buildActiveRoomView(context, roomProv, player)
          : _buildLobbyView(context, roomProv, player),
    );
  }

  Widget _buildLobbyView(BuildContext context, ListeningRoomProvider roomProv, AudioPlayerProvider player) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Flagship Banner: Couple Mode
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFF881133), Color(0xFF330514), AppColors.bgSurface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: AppColors.heartRed.withValues(alpha: 0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.heartRed.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.heartRed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('FLAGSHIP FEATURE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    const SizedBox(width: 8),
                    const Text('Synchronized 100%', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Couple Mode: Listen with Your Person ❤️',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Create an exclusive 2-person private listening session. Both hear the exact same note at the exact same millisecond with love reactions.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.heartRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.favorite_rounded, size: 20),
                  label: const Text('Start Couple Session', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    final song = player.currentSong;
                    roomProv.createRoom(name: 'Love & Music ❤️', isCoupleMode: true, initialSong: song);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Join Room by Code Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Have an invite code?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 6),
                const Text('Enter the 4-6 digit room code sent by your partner or friend.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        textCapitalization: TextCapitalization.characters,
                        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'e.g. LOVE99 or JAM24',
                          hintStyle: TextStyle(color: AppColors.textMuted, letterSpacing: 1),
                          filled: true,
                          fillColor: AppColors.bgCard,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (_codeController.text.trim().isNotEmpty) {
                          roomProv.joinRoomByCode(_codeController.text.trim());
                        }
                      },
                      child: const Text('Join Room', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Create Friends Jam Session
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.borderLight),
            ),
            tileColor: AppColors.bgCard,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppGradients.primaryOrange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.group_add_rounded, color: Colors.white),
            ),
            title: const Text('Create Friends Jam Session', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: const Text('Open or invite-only queue where everyone can add songs', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondary, size: 14),
            onTap: () {
              roomProv.createRoom(name: 'Soundifly Jam Session', isCoupleMode: false, initialSong: player.currentSong);
            },
          ),

          const SizedBox(height: 24),

          // Public Community Rooms
          const Text('Active Public Rooms', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: roomProv.publicRooms.length,
            itemBuilder: (ctx, i) {
              final room = roomProv.publicRooms[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(room.members.first.avatarUrl),
                  ),
                  title: Text(room.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text(
                    '${room.currentSong?.title ?? "No track"} • ${room.members.length} listening',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.bgCard,
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () => roomProv.joinRoomByCode(room.roomCode),
                    child: const Text('Join'),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildActiveRoomView(BuildContext context, ListeningRoomProvider roomProv, AudioPlayerProvider player) {
    final room = roomProv.currentRoom!;
    final song = player.currentSong ?? room.currentSong;

    return Column(
      children: [
        // Top Room Info Card with Code & Copy
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: room.isCoupleMode ? const Color(0xFF260A14) : AppColors.bgSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: room.isCoupleMode ? AppColors.heartRed.withValues(alpha: 0.6) : AppColors.primary.withValues(alpha: 0.4),
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: room.isCoupleMode ? AppColors.heartRed : AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          room.isCoupleMode ? 'COUPLE SYNC ❤️' : 'JAM SESSION',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(room.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: room.roomCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.primary,
                          content: Text('Room Code ${room.roomCode} copied to clipboard!'),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: [
                          Text(room.roomCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
                          const SizedBox(width: 4),
                          const Icon(Icons.copy_rounded, size: 14, color: Colors.white70),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Members Row
              Row(
                children: [
                  const Text('Listening Together: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(width: 6),
                  ...room.members.map((m) => Container(
                        margin: const EdgeInsets.only(right: 6),
                        child: Tooltip(
                          message: m.name,
                          child: CircleAvatar(
                            radius: 14,
                            backgroundImage: NetworkImage(m.avatarUrl),
                          ),
                        ),
                      )),
                  const Spacer(),
                  const Row(
                    children: [
                      Icon(Icons.wifi_tethering_rounded, color: AppColors.success, size: 16),
                      SizedBox(width: 4),
                      Text('Sync: 24ms', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        // Synchronized Track Display
        if (song != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                AppNetworkImage(
                  url: song.coverUrl,
                  width: 50,
                  height: 50,
                  borderRadius: BorderRadius.circular(10),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('${song.artist} • In Sync', style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(player.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded, color: AppColors.primary, size: 38),
                  onPressed: () => player.togglePlayPause(),
                ),
              ],
            ),
          ),

        const SizedBox(height: 12),

        // Floating Quick Reactions Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['❤️', '🔥', '🥹', '✨', '🎧', '🎶'].map((emoji) {
              return GestureDetector(
                onTap: () => roomProv.sendReaction(emoji),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 12),

        // Live Chat & Activity Stream
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: ListView.builder(
              reverse: false,
              itemCount: room.messages.length,
              itemBuilder: (ctx, idx) {
                final msg = room.messages[idx];
                final isMe = msg.senderName == 'You';

                if (msg.isReaction) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${msg.senderName} reacted ${msg.text}',
                          style: const TextStyle(fontSize: 13, color: AppColors.accentAmber),
                        ),
                      ),
                    ),
                  );
                }

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primary : AppColors.bgCard,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(msg.senderName, style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : AppColors.textSecondary, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(msg.text, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Chat Input Field
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Talk while listening...',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.bgCard,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (txt) {
                    if (txt.trim().isNotEmpty) {
                      roomProv.sendMessage(txt);
                      _chatController.clear();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.send_rounded),
                onPressed: () {
                  if (_chatController.text.trim().isNotEmpty) {
                    roomProv.sendMessage(_chatController.text);
                    _chatController.clear();
                  }
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 80),
      ],
    );
  }
}
