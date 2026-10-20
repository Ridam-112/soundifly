import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/song.dart';
import '../models/lyrics_model.dart';
import '../theme/app_theme.dart';
import 'app_network_image.dart';

enum ShareCardMode { song, lyrics }

class ShareCardColorTheme {
  final String name;
  final List<Color> colors;
  final Color textColor;
  final Alignment begin;
  final Alignment end;

  const ShareCardColorTheme({
    required this.name,
    required this.colors,
    this.textColor = Colors.white,
    this.begin = Alignment.topCenter,
    this.end = Alignment.bottomCenter,
  });
}

class SongShareModal extends StatefulWidget {
  final Song song;
  final ParsedLyrics lyrics;
  final int activeLyricIndex;
  final ShareCardMode initialMode;

  const SongShareModal({
    super.key,
    required this.song,
    required this.lyrics,
    this.activeLyricIndex = 0,
    this.initialMode = ShareCardMode.lyrics,
  });

  static void show(
    BuildContext context, {
    required Song song,
    required ParsedLyrics lyrics,
    int activeLyricIndex = 0,
    ShareCardMode initialMode = ShareCardMode.lyrics,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SongShareModal(
        song: song,
        lyrics: lyrics,
        activeLyricIndex: activeLyricIndex,
        initialMode: initialMode,
      ),
    );
  }

  @override
  State<SongShareModal> createState() => _SongShareModalState();
}

class _SongShareModalState extends State<SongShareModal> {
  late ShareCardMode _currentMode;
  late int _selectedColorIndex;
  late List<String> _selectedLyricLines;

  static const List<ShareCardColorTheme> _themes = [
    ShareCardColorTheme(
      name: 'Crimson',
      colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
    ),
    ShareCardColorTheme(
      name: 'Ruby Burgundy',
      colors: [Color(0xFF881337), Color(0xFF4C0519)],
    ),
    ShareCardColorTheme(
      name: 'Charcoal Black',
      colors: [Color(0xFF27272A), Color(0xFF09090B)],
    ),
    ShareCardColorTheme(
      name: 'Soundifly Neon Orange',
      colors: [AppColors.primary, AppColors.accentAmber],
    ),
    ShareCardColorTheme(
      name: 'Deep Purple',
      colors: [Color(0xFF6B21A8), Color(0xFF3B0764)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    final hasLyrics = widget.lyrics.lines.isNotEmpty;
    _currentMode = (hasLyrics && widget.initialMode == ShareCardMode.lyrics)
        ? ShareCardMode.lyrics
        : ShareCardMode.song;
    _selectedColorIndex = 0;

    _initSelectedLyrics();
  }

  void _initSelectedLyrics() {
    if (widget.lyrics.lines.isNotEmpty) {
      final startIndex = widget.activeLyricIndex.clamp(0, widget.lyrics.lines.length - 1);
      final count = (widget.lyrics.lines.length - startIndex).clamp(1, 4);
      _selectedLyricLines = widget.lyrics.lines
          .sublist(startIndex, startIndex + count)
          .map((l) => l.text)
          .where((t) => t.isNotEmpty)
          .toList();

      if (_selectedLyricLines.isEmpty) {
        _selectedLyricLines = [widget.lyrics.lines.first.text];
      }
    } else {
      _selectedLyricLines = ['♪ Playing ${widget.song.title} ♪'];
    }
  }

  String _buildShareMessage() {
    final song = widget.song;
    const webUrl = 'https://soundifly.onrender.com';

    if (_currentMode == ShareCardMode.lyrics && _selectedLyricLines.isNotEmpty) {
      final lyricsText = _selectedLyricLines.join('\n');
      return '"$lyricsText"\n\n🎵 ${song.title} - ${song.artist}\nListen now on Soundifly: $webUrl';
    } else {
      return '🎵 Listening to "${song.title}" by ${song.artist} on Soundifly!\nListen now: $webUrl';
    }
  }

  Future<void> _shareToWhatsApp() async {
    final message = _buildShareMessage();
    final whatsappUri = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(message)}');
    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        await SharePlus.instance.share(ShareParams(text: message));
      }
    } catch (_) {
      await SharePlus.instance.share(ShareParams(text: message));
    }
  }

  Future<void> _shareToSMS() async {
    final message = _buildShareMessage();
    final smsUri = Uri.parse('sms:?body=${Uri.encodeComponent(message)}');
    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        await SharePlus.instance.share(ShareParams(text: message));
      }
    } catch (_) {
      await SharePlus.instance.share(ShareParams(text: message));
    }
  }

  Future<void> _copyLink(BuildContext context) async {
    final message = _buildShareMessage();
    await Clipboard.setData(ClipboardData(text: message));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20),
              SizedBox(width: 8),
              Text('Song share details copied to clipboard!'),
            ],
          ),
          backgroundColor: AppColors.bgCard,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _shareGeneral() async {
    final message = _buildShareMessage();
    await SharePlus.instance.share(ShareParams(
      text: message,
      subject: '${widget.song.title} on Soundifly',
    ));
  }

  void _showEditLyricsDialog() {
    if (widget.lyrics.lines.isEmpty) return;

    final allLines = widget.lyrics.lines.map((l) => l.text).toList();
    final tempSelected = List<String>.from(_selectedLyricLines);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Lyric Lines',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            if (tempSelected.isNotEmpty) {
                              _selectedLyricLines = tempSelected;
                            }
                          });
                          Navigator.pop(ctx);
                        },
                        child: const Text('Done', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Text(
                    'Tap up to 5 lines to display on your share card',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: allLines.length,
                      itemBuilder: (context, idx) {
                        final line = allLines[idx];
                        final isChosen = tempSelected.contains(line);
                        return ListTile(
                          dense: true,
                          title: Text(
                            line,
                            style: TextStyle(
                              color: isChosen ? AppColors.primary : Colors.white70,
                              fontWeight: isChosen ? FontWeight.bold : FontWeight.normal,
                              fontSize: 15,
                            ),
                          ),
                          trailing: isChosen
                              ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                              : const Icon(Icons.circle_outlined, color: Colors.white30),
                          onTap: () {
                            setModalState(() {
                              if (isChosen) {
                                tempSelected.remove(line);
                              } else {
                                if (tempSelected.length < 5) {
                                  tempSelected.add(line);
                                }
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _themes[_selectedColorIndex];
    final song = widget.song;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.92,
      decoration: const BoxDecoration(
        color: Color(0xFF141416),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Header Text
          Text(
            'Playing from Artist ${song.artist.split(',').first.trim()}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          // The Spotify-Style Share Card
          Expanded(
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: MediaQuery.of(context).size.width * 0.82,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: theme.colors,
                    begin: theme.begin,
                    end: theme.end,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colors.first.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: _currentMode == ShareCardMode.lyrics
                      ? _buildLyricsCardContent(song)
                      : _buildSongCardContent(song),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Toggle Buttons: [Song] [Lyrics]
          Container(
            height: 42,
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: const Color(0xFF242428),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentMode = ShareCardMode.song;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: _currentMode == ShareCardMode.song
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Song',
                        style: TextStyle(
                          color: _currentMode == ShareCardMode.song
                              ? Colors.black
                              : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentMode = ShareCardMode.lyrics;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: _currentMode == ShareCardMode.lyrics
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Lyrics',
                        style: TextStyle(
                          color: _currentMode == ShareCardMode.lyrics
                              ? Colors.black
                              : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Action Row / Color Palette
          if (_currentMode == ShareCardMode.lyrics)
            // "Edit lyrics" button
            InkWell(
              onTap: _showEditLyricsDialog,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF242428),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.edit_outlined, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Edit lyrics',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            // Color theme picker circles
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_themes.length, (idx) {
                final isSelected = _selectedColorIndex == idx;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColorIndex = idx;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: _themes[idx].colors),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.white24,
                        width: isSelected ? 3 : 1.5,
                      ),
                    ),
                  ),
                );
              }),
            ),

          const SizedBox(height: 20),

          // Share Channels Icons Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildShareTargetItem(
                  icon: Icons.link_rounded,
                  label: 'Copy link',
                  bgColor: const Color(0xFF2C2C30),
                  iconColor: Colors.white,
                  onTap: () => _copyLink(context),
                ),
                _buildShareTargetItem(
                  icon: Icons.chat_rounded,
                  label: 'WhatsApp',
                  bgColor: const Color(0xFF25D366),
                  iconColor: Colors.white,
                  onTap: _shareToWhatsApp,
                ),
                _buildShareTargetItem(
                  icon: Icons.camera_alt_rounded,
                  label: 'Stories',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFF77737)],
                  ),
                  iconColor: Colors.white,
                  onTap: _shareGeneral,
                ),
                _buildShareTargetItem(
                  icon: Icons.sms_rounded,
                  label: 'SMS',
                  bgColor: const Color(0xFF2C2C30),
                  iconColor: Colors.white,
                  onTap: _shareToSMS,
                ),
                _buildShareTargetItem(
                  icon: Icons.share_rounded,
                  label: 'More',
                  bgColor: const Color(0xFF2C2C30),
                  iconColor: Colors.white,
                  onTap: _shareGeneral,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLyricsCardContent(Song song) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Song & Artist row
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: AppNetworkImage(
                    url: song.coverUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Song • ${song.artist}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Spacer(),

          // Centered Bold Lyrics
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _selectedLyricLines.map((line) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  line,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              );
            }).toList(),
          ),

          const Spacer(),

          // Soundifly Brand Logo Row
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                padding: const EdgeInsets.all(3),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.graphic_eq_rounded, size: 14, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Soundifly',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSongCardContent(Song song) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Large Album Art
          Expanded(
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: AppNetworkImage(
                    url: song.coverUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title & Artist
          Text(
            song.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            song.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 16),

          // Soundifly Brand Logo Row
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                padding: const EdgeInsets.all(3),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.graphic_eq_rounded, size: 14, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Soundifly',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShareTargetItem({
    required IconData icon,
    required String label,
    Color? bgColor,
    Gradient? gradient,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor,
              gradient: gradient,
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
