import '../models/song.dart';

class ParsedLyrics {
  final bool isSynced;
  final List<LyricLine> lines;
  final String? plainText;
  final String source;
  final bool isInstrumental;

  const ParsedLyrics({
    required this.isSynced,
    required this.lines,
    this.plainText,
    this.source = 'LRCLIB',
    this.isInstrumental = false,
  });

  static const ParsedLyrics empty = ParsedLyrics(isSynced: false, lines: []);
  
  static const ParsedLyrics instrumental = ParsedLyrics(
    isSynced: true,
    isInstrumental: true,
    lines: [LyricLine(timestamp: Duration.zero, text: '♪ Instrumental Track ♪')],
  );

  /// Find the index of the line currently playing at [position]
  int findActiveIndex(Duration position) {
    if (lines.isEmpty) return -1;
    for (int i = lines.length - 1; i >= 0; i--) {
      if (position >= lines[i].timestamp) {
        return i;
      }
    }
    return 0;
  }
}
