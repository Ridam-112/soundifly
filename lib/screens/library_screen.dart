import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/playlist_provider.dart';
import '../models/playlist.dart';
import '../theme/app_theme.dart';
import 'playlist_detail_screen.dart';
import 'liked_songs_screen.dart';
import 'listening_history_screen.dart';
import '../widgets/app_network_image.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playlistProv = context.watch<PlaylistProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Your Library',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.white),
            tooltip: 'Listening History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ListeningHistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary, size: 28),
            tooltip: 'Create Playlist',
            onPressed: () => _showCreatePlaylistDialog(context, playlistProv),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'Playlists'),
            Tab(text: 'Artists'),
            Tab(text: 'Albums'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Playlists Tab
          _buildPlaylistsTab(context, playlistProv),

          // Artists Tab
          _buildArtistsTab(context),

          // Albums Tab
          _buildAlbumsTab(context),
        ],
      ),
    );
  }

  Widget _buildPlaylistsTab(BuildContext context, PlaylistProvider playlistProv) {
    final playlists = playlistProv.playlists;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: playlists.length + 1, // +1 for "Create Playlist" action card
      itemBuilder: (ctx, idx) {
        if (idx == 0) {
          // Action button: Create Playlist Card
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              tileColor: AppColors.bgSurface,
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: AppGradients.primaryOrange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
              ),
              title: const Text('Create New Playlist', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              subtitle: const Text('Public or Private with cloud sync', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              onTap: () => _showCreatePlaylistDialog(context, playlistProv),
            ),
          );
        }

        final playlist = playlists[idx - 1];

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: AppNetworkImage(
              url: playlist.coverUrl,
              width: 52,
              height: 52,
              borderRadius: BorderRadius.circular(10),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    playlist.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                if (playlist.visibility == PlaylistVisibility.collaborative)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.heartRed.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.heartRed, width: 0.8),
                    ),
                    child: const Text('Collab 👥', style: TextStyle(fontSize: 10, color: AppColors.heartRed, fontWeight: FontWeight.bold)),
                  )
                else if (playlist.visibility == PlaylistVisibility.private)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Private 🔒', style: TextStyle(fontSize: 10, color: Colors.white70)),
                  ),
              ],
            ),
            subtitle: Text(
              '${playlist.songs.length} songs • ${playlist.ownerName}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondary, size: 14),
            onTap: () {
              if (playlist.isLikedFolder) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LikedSongsScreen()),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlist: playlist)),
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildArtistsTab(BuildContext context) {
    final artists = [
      {'name': 'Shironamhin', 'followers': '1.2M', 'image': 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=200&auto=format&fit=crop&q=80'},
      {'name': 'Tahsan', 'followers': '980K', 'image': 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=200&auto=format&fit=crop&q=80'},
      {'name': 'Aether & Luna', 'followers': '650K', 'image': 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=200&auto=format&fit=crop&q=80'},
      {'name': 'Maya Lin', 'followers': '430K', 'image': 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=200&auto=format&fit=crop&q=80'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: artists.length,
      itemBuilder: (ctx, i) {
        final a = artists[i];
        return ListTile(
          leading: CircleAvatar(
            radius: 26,
            backgroundImage: NetworkImage(a['image']!),
          ),
          title: Text(a['name']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          subtitle: Text('${a['followers']} monthly listeners', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          trailing: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () {},
            child: const Text('Follow'),
          ),
        );
      },
    );
  }

  Widget _buildAlbumsTab(BuildContext context) {
    return const Center(
      child: Text('Saved albums will appear here', style: TextStyle(color: AppColors.textSecondary)),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, PlaylistProvider playlistProv) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final collabEmailCtrl = TextEditingController();
    PlaylistVisibility selectedVisibility = PlaylistVisibility.public;
    String? emailError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create New Playlist',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.white),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Playlist Name',
                    labelStyle: const TextStyle(color: AppColors.primary),
                    hintText: 'e.g. Late Night Drives',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.bgSurface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.bgSurface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Visibility & Privacy:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),

                // Custom Selectable Visibility Cards
                _buildVisibilityOption(
                  title: 'Public',
                  subtitle: 'Anyone on Soundifly can search and listen',
                  isSelected: selectedVisibility == PlaylistVisibility.public,
                  color: AppColors.primary,
                  onTap: () => setModalState(() => selectedVisibility = PlaylistVisibility.public),
                ),
                const SizedBox(height: 8),
                _buildVisibilityOption(
                  title: 'Private 🔒',
                  subtitle: 'Only visible and accessible to you',
                  isSelected: selectedVisibility == PlaylistVisibility.private,
                  color: AppColors.primary,
                  onTap: () => setModalState(() => selectedVisibility = PlaylistVisibility.private),
                ),
                const SizedBox(height: 8),
                _buildVisibilityOption(
                  title: 'Collaborative 👥 (With Friends/Partner)',
                  subtitle: 'Invited friends can add, reorder, and remove songs',
                  isSelected: selectedVisibility == PlaylistVisibility.collaborative,
                  color: AppColors.heartRed,
                  onTap: () => setModalState(() => selectedVisibility = PlaylistVisibility.collaborative),
                ),

                // Collaborator Email Input Field
                if (selectedVisibility == PlaylistVisibility.collaborative) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.heartRed.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.heartRed.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.people_alt_rounded, color: AppColors.heartRed, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Collaborator Invitation',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Enter the email address your partner or friend uses to log into Soundifly.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: collabEmailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          onChanged: (_) {
                            if (emailError != null) {
                              setModalState(() => emailError = null);
                            }
                          },
                          decoration: InputDecoration(
                            labelText: "Partner's Soundifly Email *",
                            labelStyle: const TextStyle(color: AppColors.heartRed, fontSize: 13),
                            hintText: 'e.g. partner@gmail.com',
                            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                            prefixIcon: const Icon(Icons.alternate_email_rounded, color: AppColors.heartRed, size: 18),
                            errorText: emailError,
                            filled: true,
                            fillColor: AppColors.bgSurface,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedVisibility == PlaylistVisibility.collaborative
                          ? AppColors.heartRed
                          : AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      if (selectedVisibility == PlaylistVisibility.collaborative) {
                        final email = collabEmailCtrl.text.trim();
                        if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
                          setModalState(() {
                            emailError = 'Please enter a valid Soundifly user email';
                          });
                          return;
                        }
                      }

                      final p = playlistProv.createPlaylist(
                        title: titleCtrl.text,
                        description: descCtrl.text,
                        visibility: selectedVisibility,
                        collaboratorEmail: selectedVisibility == PlaylistVisibility.collaborative
                            ? collabEmailCtrl.text.trim()
                            : null,
                      );
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlist: p)),
                      );
                    },
                    child: const Text('Create Playlist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVisibilityOption({
    required String title,
    required String subtitle,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.borderLight,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: isSelected ? color : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.textSecondary, fontSize: 14)),
                  Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
