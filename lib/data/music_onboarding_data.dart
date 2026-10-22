import 'package:flutter/material.dart';

class MusicLanguage {
  final String id;
  final String name;
  final String nativeName;
  final List<Color> gradient;
  final IconData icon;

  const MusicLanguage({
    required this.id,
    required this.name,
    required this.nativeName,
    required this.gradient,
    this.icon = Icons.music_note_rounded,
  });
}

class MusicGenreMood {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final List<Color> gradient;
  final IconData icon;

  const MusicGenreMood({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.gradient,
    this.icon = Icons.music_note_rounded,
  });
}

enum ArtistType {
  singer,
  playbackArtist,
  singerSongwriter,
  band,
  composer,
  producer,
}

class OnboardingArtist {
  final String id;
  final String name;
  final List<String> languages;
  final String genre;
  final String imageUrl;
  final ArtistType artistType;
  final int popularityScore;
  final bool isVerifiedImage;
  final String imageSource;
  final String? providerId;

  const OnboardingArtist({
    required this.id,
    required this.name,
    this.languages = const ['Universal'],
    required this.genre,
    required this.imageUrl,
    this.artistType = ArtistType.singer,
    this.popularityScore = 1000,
    this.isVerifiedImage = true,
    this.imageSource = 'Verified Official CDN',
    this.providerId,
  });

  /// Backward compatible single language getter
  String get language => languages.isNotEmpty ? languages.first : 'Universal';

  String get artistTypeDisplay {
    switch (artistType) {
      case ArtistType.playbackArtist:
        return 'Playback Artist';
      case ArtistType.singerSongwriter:
        return 'Singer-Songwriter';
      case ArtistType.band:
        return 'Band / Group';
      case ArtistType.composer:
        return 'Music Director';
      case ArtistType.producer:
        return 'Producer';
      case ArtistType.singer:
        return 'Singer';
    }
  }

  bool matchesLanguage(String lang) {
    final target = lang.trim().toLowerCase();
    return languages.any((l) => l.trim().toLowerCase() == target);
  }

  bool matchesQuery(String query) {
    final clean = query.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
    if (clean.isEmpty) return true;

    final lowerName = name.toLowerCase();
    if (lowerName.contains(clean)) return true;

    // Check if every token in query matches the artist name or metadata
    final words = clean.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.length > 1) {
      final allWordsMatch = words.every((w) =>
          lowerName.contains(w) ||
          genre.toLowerCase().contains(w) ||
          languages.any((l) => l.toLowerCase().contains(w)));
      if (allWordsMatch) return true;
    }

    return genre.toLowerCase().contains(clean) ||
        languages.any((l) => l.toLowerCase().contains(clean)) ||
        artistTypeDisplay.toLowerCase().contains(clean);
  }
}

class MusicOnboardingData {
  /// The 14 supported regional Indian and international languages
  static const List<MusicLanguage> availableLanguages = [
    MusicLanguage(
      id: 'bengali',
      name: 'Bengali',
      nativeName: 'বাংলা',
      gradient: [Color(0xFFE65100), Color(0xFFFF8F00)],
      icon: Icons.album_rounded,
    ),
    MusicLanguage(
      id: 'hindi',
      name: 'Hindi',
      nativeName: 'हिंदी',
      gradient: [Color(0xFFC2185B), Color(0xFFFF4081)],
      icon: Icons.graphic_eq_rounded,
    ),
    MusicLanguage(
      id: 'english',
      name: 'English',
      nativeName: 'Global',
      gradient: [Color(0xFF1976D2), Color(0xFF42A5F5)],
      icon: Icons.public_rounded,
    ),
    MusicLanguage(
      id: 'punjabi',
      name: 'Punjabi',
      nativeName: 'ਪੰਜਾਬੀ',
      gradient: [Color(0xFFF57C00), Color(0xFFFFB74D)],
      icon: Icons.speaker_group_rounded,
    ),
    MusicLanguage(
      id: 'tamil',
      name: 'Tamil',
      nativeName: 'தமிழ்',
      gradient: [Color(0xFF7B1FA2), Color(0xFFBA68C8)],
      icon: Icons.radio_rounded,
    ),
    MusicLanguage(
      id: 'telugu',
      name: 'Telugu',
      nativeName: 'తెలుగు',
      gradient: [Color(0xFF388E3C), Color(0xFF81C784)],
      icon: Icons.audiotrack_rounded,
    ),
    MusicLanguage(
      id: 'malayalam',
      name: 'Malayalam',
      nativeName: 'മലയാളം',
      gradient: [Color(0xFF00796B), Color(0xFF4DB6AC)],
      icon: Icons.waves_rounded,
    ),
    MusicLanguage(
      id: 'kannada',
      name: 'Kannada',
      nativeName: 'ಕನ್ನಡ',
      gradient: [Color(0xFFD32F2F), Color(0xFFEF5350)],
      icon: Icons.music_video_rounded,
    ),
    MusicLanguage(
      id: 'marathi',
      name: 'Marathi',
      nativeName: 'मराठी',
      gradient: [Color(0xFF5D4037), Color(0xFF8D6E63)],
      icon: Icons.queue_music_rounded,
    ),
    MusicLanguage(
      id: 'urdu',
      name: 'Urdu',
      nativeName: 'اردو',
      gradient: [Color(0xFF455A64), Color(0xFF78909C)],
      icon: Icons.library_music_rounded,
    ),
    MusicLanguage(
      id: 'assamese',
      name: 'Assamese',
      nativeName: 'অসমীয়া',
      gradient: [Color(0xFF0097A7), Color(0xFF4DD0E1)],
      icon: Icons.mic_external_on_rounded,
    ),
    MusicLanguage(
      id: 'odia',
      name: 'Odia',
      nativeName: 'ଓଡ଼ିଆ',
      gradient: [Color(0xFF512DA8), Color(0xFF7E57C2)],
      icon: Icons.headset_rounded,
    ),
    MusicLanguage(
      id: 'bhojpuri',
      name: 'Bhojpuri',
      nativeName: 'भोजपुरी',
      gradient: [Color(0xFFE64A19), Color(0xFFFF7043)],
      icon: Icons.festival_rounded,
    ),
    MusicLanguage(
      id: 'gujarati',
      name: 'Gujarati',
      nativeName: 'ગુજરાતી',
      gradient: [Color(0xFF00897B), Color(0xFF26A69A)],
      icon: Icons.celebration_rounded,
    ),
  ];

  /// Supported mood and genre collections for personalization
  static const List<MusicGenreMood> availableGenres = [
    MusicGenreMood(
      id: 'romantic',
      name: 'Romantic',
      emoji: '❤️',
      description: 'Love anthems, acoustic duets & ballads',
      gradient: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
      icon: Icons.favorite_rounded,
    ),
    MusicGenreMood(
      id: 'sad',
      name: 'Sad & Melancholy',
      emoji: '🌧️',
      description: 'Heartbreak, deep thoughts & rainy vibes',
      gradient: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
      icon: Icons.water_drop_rounded,
    ),
    MusicGenreMood(
      id: 'chill',
      name: 'Chill & Lo-Fi',
      emoji: '☕',
      description: 'Late night relax, ambient beats & calm',
      gradient: [Color(0xFF2E3192), Color(0xFF1BFFFF)],
      icon: Icons.nights_stay_rounded,
    ),
    MusicGenreMood(
      id: 'indie',
      name: 'Indie & Acoustic',
      emoji: '🎸',
      description: 'Singer-songwriters & underground sounds',
      gradient: [Color(0xFFF37335), Color(0xFFFDC830)],
      icon: Icons.music_note_rounded,
    ),
    MusicGenreMood(
      id: 'classical',
      name: 'Classical',
      emoji: '🎻',
      description: 'Indian classical, Rabindra Sangeet & timeless art',
      gradient: [Color(0xFF8A2387), Color(0xFFE94057)],
      icon: Icons.album_rounded,
    ),
    MusicGenreMood(
      id: 'devotional',
      name: 'Devotional & Spiritual',
      emoji: '🪔',
      description: 'Bhajans, Sufi, Kirtan & uplifting prayers',
      gradient: [Color(0xFFF7971E), Color(0xFFFFD200)],
      icon: Icons.spa_rounded,
    ),
    MusicGenreMood(
      id: 'hiphop',
      name: 'Hip-Hop & Rap',
      emoji: '🎤',
      description: 'Desi hip-hop, beats, rhymes & bars',
      gradient: [Color(0xFF11998E), Color(0xFF38EF7D)],
      icon: Icons.mic_rounded,
    ),
    MusicGenreMood(
      id: 'pop',
      name: 'Pop & Dance',
      emoji: '✨',
      description: 'Viral hits, chart toppers & upbeat hooks',
      gradient: [Color(0xFFFF0844), Color(0xFFFFB199)],
      icon: Icons.star_rounded,
    ),
    MusicGenreMood(
      id: 'rock',
      name: 'Rock & Metal',
      emoji: '⚡',
      description: 'Bengali rock, alternative guitars & power',
      gradient: [Color(0xFF434343), Color(0xFF212121)],
      icon: Icons.electric_bolt_rounded,
    ),
    MusicGenreMood(
      id: 'workout',
      name: 'Workout & Energy',
      emoji: '🔥',
      description: 'High BPM, gym motivation & party anthems',
      gradient: [Color(0xFFF857A6), Color(0xFFFF5858)],
      icon: Icons.fitness_center_rounded,
    ),
    MusicGenreMood(
      id: 'focus',
      name: 'Focus & Study',
      emoji: '🧠',
      description: 'Deep work, study rhythms & no-distraction flow',
      gradient: [Color(0xFF2193B0), Color(0xFF6DD5ED)],
      icon: Icons.lightbulb_rounded,
    ),
  ];

  static List<OnboardingArtist> get artists => curatedArtists;

  /// Comprehensive catalogue of real, verified singers with official CDN portraits
  static const List<OnboardingArtist> curatedArtists = [
    // --- Hindi / Bollywood ---
    OnboardingArtist(
      id: 'art_arijit',
      name: 'Arijit Singh',
      languages: ['Hindi', 'Bengali'],
      genre: 'Romantic & Bollywood',
      artistType: ArtistType.playbackArtist,
      popularityScore: 35000,
      imageUrl: 'https://c.saavncdn.com/artists/Arijit_Singh_004_20241118063717_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_shreya',
      name: 'Shreya Ghoshal',
      languages: ['Hindi', 'Bengali', 'Tamil', 'Telugu', 'Kannada', 'Malayalam', 'Marathi'],
      genre: 'Classical & Melody',
      artistType: ArtistType.playbackArtist,
      popularityScore: 28000,
      imageUrl: 'https://c.saavncdn.com/artists/Shreya_Ghoshal_007_20241101074144_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_sonu',
      name: 'Sonu Nigam',
      languages: ['Hindi', 'Kannada', 'Bengali'],
      genre: 'Melody & Pop',
      artistType: ArtistType.playbackArtist,
      popularityScore: 18000,
      imageUrl: 'https://c.saavncdn.com/artists/Sonu_Nigam_003_20260813182013_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_sunidhi',
      name: 'Sunidhi Chauhan',
      languages: ['Hindi', 'Punjabi', 'Tamil', 'Bengali'],
      genre: 'Power Pop & Bollywood',
      artistType: ArtistType.playbackArtist,
      popularityScore: 16000,
      imageUrl: 'https://c.saavncdn.com/artists/Sunidhi_Chauhan_005_20250515061617_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_kishore',
      name: 'Kishore Kumar',
      languages: ['Hindi', 'Bengali'],
      genre: 'Timeless Golden Classics',
      artistType: ArtistType.playbackArtist,
      popularityScore: 22000,
      imageUrl: 'https://c.saavncdn.com/artists/Kishore_Kumar_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_lata',
      name: 'Lata Mangeshkar',
      languages: ['Hindi', 'Bengali', 'Marathi'],
      genre: 'Nightingale of India',
      artistType: ArtistType.playbackArtist,
      popularityScore: 21000,
      imageUrl: 'https://c.saavncdn.com/artists/Lata_Mangeshkar_004_20230623105323_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_rafi',
      name: 'Mohammed Rafi',
      languages: ['Hindi', 'Urdu', 'Punjabi'],
      genre: 'Evergreen Soul & Ghazals',
      artistType: ArtistType.playbackArtist,
      popularityScore: 19500,
      imageUrl: 'https://c.saavncdn.com/artists/Mohammed_Rafi_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_kk',
      name: 'KK (Krishnakumar)',
      languages: ['Hindi', 'Tamil', 'Telugu', 'Bengali'],
      genre: 'Nostalgic Rock & Romance',
      artistType: ArtistType.playbackArtist,
      popularityScore: 24000,
      imageUrl: 'https://c.saavncdn.com/artists/KK_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_atif',
      name: 'Atif Aslam',
      languages: ['Hindi', 'Urdu'],
      genre: 'Sufi Rock & Ballads',
      artistType: ArtistType.singerSongwriter,
      popularityScore: 26000,
      imageUrl: 'https://cdn-images.dzcdn.net/images/artist/0ea90444148fff9c11d77f06a344724e/500x500-000000-80-0-0.jpg',
      imageSource: 'Deezer Official CDN',
    ),
    OnboardingArtist(
      id: 'art_jubin',
      name: 'Jubin Nautiyal',
      languages: ['Hindi'],
      genre: 'Devotional & Love Ballads',
      artistType: ArtistType.playbackArtist,
      popularityScore: 17500,
      imageUrl: 'https://c.saavncdn.com/artists/Jubin_Nautiyal_003_20231130204020_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_armaan',
      name: 'Armaan Malik',
      languages: ['Hindi', 'Telugu', 'English', 'Bengali'],
      genre: 'Pop Romance & Global Collabs',
      artistType: ArtistType.singerSongwriter,
      popularityScore: 15500,
      imageUrl: 'https://c.saavncdn.com/artists/Armaan_Malik_006_20260813132832_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_vishal',
      name: 'Vishal Mishra',
      languages: ['Hindi'],
      genre: 'Soulful Contemporary',
      artistType: ArtistType.composer,
      popularityScore: 14500,
      imageUrl: 'https://c.saavncdn.com/artists/Vishal_Mishra_005_20251120085316_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_sachet',
      name: 'Sachet Tandon',
      languages: ['Hindi'],
      genre: 'Intense Romantic Melodies',
      artistType: ArtistType.composer,
      popularityScore: 12000,
      imageUrl: 'https://c.saavncdn.com/artists/Sachet_Tandon_20191129105330_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_neha',
      name: 'Neha Kakkar',
      languages: ['Hindi', 'Punjabi'],
      genre: 'Party Hits & Dance Pop',
      artistType: ArtistType.playbackArtist,
      popularityScore: 13000,
      imageUrl: 'https://c.saavncdn.com/artists/Neha_Kakkar_007_20241212115832_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_mohit',
      name: 'Mohit Chauhan',
      languages: ['Hindi'],
      genre: 'Folk Romance & Rock',
      artistType: ArtistType.singerSongwriter,
      popularityScore: 14000,
      imageUrl: 'https://c.saavncdn.com/artists/Mohit_Chauhan_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_alka',
      name: 'Alka Yagnik',
      languages: ['Hindi', 'Bengali'],
      genre: '90s Romantic Melodies',
      artistType: ArtistType.playbackArtist,
      popularityScore: 16500,
      imageUrl: 'https://c.saavncdn.com/artists/Alka_Yagnik_002_20220314192930_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_kumarsanu',
      name: 'Kumar Sanu',
      languages: ['Hindi', 'Bengali'],
      genre: 'Golden Era Romance',
      artistType: ArtistType.playbackArtist,
      popularityScore: 19000,
      imageUrl: 'https://c.saavncdn.com/artists/Kumar_Sanu_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_arrahman',
      name: 'A.R. Rahman',
      languages: ['Tamil', 'Hindi', 'Telugu'],
      genre: 'Maestro Symphony & World Music',
      artistType: ArtistType.composer,
      popularityScore: 32000,
      imageUrl: 'https://c.saavncdn.com/artists/AR_Rahman_002_20210120084455_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_badshah',
      name: 'Badshah',
      languages: ['Hindi', 'Punjabi'],
      genre: 'Commercial Hip-Hop & Party',
      artistType: ArtistType.producer,
      popularityScore: 16000,
      imageUrl: 'https://c.saavncdn.com/artists/Badshah_006_20241118064015_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),

    // --- Independent / Contemporary ---
    OnboardingArtist(
      id: 'art_anuv',
      name: 'Anuv Jain',
      languages: ['Hindi'],
      genre: 'Acoustic Indie & Poetry',
      artistType: ArtistType.singerSongwriter,
      popularityScore: 23000,
      imageUrl: 'https://c.saavncdn.com/artists/Anuv_Jain_001_20231206073013_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_prateek',
      name: 'Prateek Kuhad',
      languages: ['Hindi', 'English'],
      genre: 'Indie Folk & Acoustic',
      artistType: ArtistType.singerSongwriter,
      popularityScore: 18500,
      imageUrl: 'https://c.saavncdn.com/artists/Prateek_Kuhad_006_20260515064251_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_mitraz',
      name: 'Mitraz',
      languages: ['Hindi'],
      genre: 'Chill Pop & Lo-Fi Dream',
      artistType: ArtistType.band,
      popularityScore: 17000,
      imageUrl: 'https://c.saavncdn.com/artists/Mitraz_000_20221004124159_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_localtrain',
      name: 'The Local Train',
      languages: ['Hindi'],
      genre: 'Hindi Rock & Anthems',
      artistType: ArtistType.band,
      popularityScore: 16500,
      imageUrl: 'https://c.saavncdn.com/artists/The_Local_Train_004_20251031175921_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_whenchaimettoast',
      name: 'When Chai Met Toast',
      languages: ['English', 'Hindi'],
      genre: 'Acoustic Folk-Pop & Joy',
      artistType: ArtistType.band,
      popularityScore: 14000,
      imageUrl: 'https://c.saavncdn.com/artists/When_Chai_Met_Toast_000_20231207113242_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_jasleen',
      name: 'Jasleen Royal',
      languages: ['Hindi', 'Punjabi'],
      genre: 'Indie Pop & Sweet Romance',
      artistType: ArtistType.singerSongwriter,
      popularityScore: 15000,
      imageUrl: 'https://c.saavncdn.com/artists/Jasleen_Royal_002_20230615091108_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_adityarikhari',
      name: 'Aditya Rikhari',
      languages: ['Hindi'],
      genre: 'Raw Emotion & Acoustic Pop',
      artistType: ArtistType.singerSongwriter,
      popularityScore: 15500,
      imageUrl: 'https://c.saavncdn.com/artists/Aditya_Rikhari_001_20240227101823_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_yellowdiary',
      name: 'The Yellow Diary',
      languages: ['Hindi'],
      genre: 'Alt-Rock & Electronic Poetry',
      artistType: ArtistType.band,
      popularityScore: 13500,
      imageUrl: 'https://c.saavncdn.com/artists/The_Yellow_Diary_20180504084639_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),

    // --- Bengali ---
    OnboardingArtist(
      id: 'art_anupam',
      name: 'Anupam Roy',
      languages: ['Bengali', 'Hindi'],
      genre: 'Contemporary Acoustic & Folk',
      artistType: ArtistType.singerSongwriter,
      popularityScore: 21000,
      imageUrl: 'https://c.saavncdn.com/artists/Anupam_Roy_002_20230217064344_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_rupam',
      name: 'Rupam Islam (Fossils)',
      languages: ['Bengali'],
      genre: 'Bangla Rock & Revolutionary',
      artistType: ArtistType.singerSongwriter,
      popularityScore: 20000,
      imageUrl: 'https://c.saavncdn.com/artists/Rupam_Islam_004_20200822043703_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_nachiketa',
      name: 'Nachiketa Chakraborty',
      languages: ['Bengali'],
      genre: 'Jeebonmukhi Gaan & Ballads',
      artistType: ArtistType.singerSongwriter,
      popularityScore: 16000,
      imageUrl: 'https://c.saavncdn.com/artists/Nachiketa_Chakraborty_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_anindya',
      name: 'Anindya Chatterjee',
      languages: ['Bengali'],
      genre: 'Urban Folk & Chandrabindoo',
      artistType: ArtistType.singerSongwriter,
      popularityScore: 13500,
      imageUrl: 'https://c.saavncdn.com/artists/Anindya_Chatterjee_003_20231215104230_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_iman',
      name: 'Iman Chakraborty',
      languages: ['Bengali'],
      genre: 'Rabindrasangeet & Folk',
      artistType: ArtistType.playbackArtist,
      popularityScore: 15000,
      imageUrl: 'https://c.saavncdn.com/artists/Iman_Chakraborty_002_20230810113824_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_lagnajita',
      name: 'Lagnajita Chakraborty',
      languages: ['Bengali'],
      genre: 'Romantic Film & Indie',
      artistType: ArtistType.playbackArtist,
      popularityScore: 14000,
      imageUrl: 'https://c.saavncdn.com/artists/Lagnajita_Chakraborty_001_20211029080517_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_somlata',
      name: 'Somlata Acharyya Chowdhury',
      languages: ['Bengali'],
      genre: 'Acoustic Fusion & Rock Rabindra',
      artistType: ArtistType.playbackArtist,
      popularityScore: 13000,
      imageUrl: 'https://c.saavncdn.com/artists/Somlata_Acharyya_Chowdhury_001_20211029080517_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_hemanta',
      name: 'Hemanta Mukherjee',
      languages: ['Bengali', 'Hindi'],
      genre: 'Golden Era Baritone Legend',
      artistType: ArtistType.playbackArtist,
      popularityScore: 18000,
      imageUrl: 'https://c.saavncdn.com/artists/Hemanta_Mukherjee_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_mannadey',
      name: 'Manna Dey',
      languages: ['Bengali', 'Hindi'],
      genre: 'Classical Maestro & Melodies',
      artistType: ArtistType.playbackArtist,
      popularityScore: 17500,
      imageUrl: 'https://c.saavncdn.com/artists/Manna_Dey_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_sandhyamukherjee',
      name: 'Sandhya Mukherjee',
      languages: ['Bengali', 'Hindi'],
      genre: 'Classical & Romantic Bengali Film',
      artistType: ArtistType.playbackArtist,
      popularityScore: 15000,
      imageUrl: 'https://c.saavncdn.com/artists/Sandhya_Mukherjee_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_shaan',
      name: 'Shaan',
      languages: ['Bengali', 'Hindi'],
      genre: 'Melodious Pop & Film',
      artistType: ArtistType.playbackArtist,
      popularityScore: 16500,
      imageUrl: 'https://c.saavncdn.com/artists/Shaan_004_20260813133132_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),

    // --- Punjabi ---
    OnboardingArtist(
      id: 'art_diljit',
      name: 'Diljit Dosanjh',
      languages: ['Punjabi', 'Hindi'],
      genre: 'Global Punjabi Wave & Folk',
      artistType: ArtistType.singer,
      popularityScore: 34000,
      imageUrl: 'https://c.saavncdn.com/artists/Diljit_Dosanjh_005_20231025073054_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_karanaujla',
      name: 'Karan Aujla',
      languages: ['Punjabi'],
      genre: 'Contemporary Punjabi Rap & Folk',
      artistType: ArtistType.singerSongwriter,
      popularityScore: 31000,
      imageUrl: 'https://c.saavncdn.com/artists/Karan_Aujla_005_20241018073836_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_apdhillon',
      name: 'AP Dhillon',
      languages: ['Punjabi'],
      genre: 'Synthwave & Punjabi Pop',
      artistType: ArtistType.singerSongwriter,
      popularityScore: 27000,
      imageUrl: 'https://c.saavncdn.com/artists/AP_Dhillon_004_20231011112613_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_sidhu',
      name: 'Sidhu Moose Wala',
      languages: ['Punjabi'],
      genre: 'Desi Hip Hop & Gangsta Rap',
      artistType: ArtistType.singerSongwriter,
      popularityScore: 33000,
      imageUrl: 'https://c.saavncdn.com/artists/Sidhu_Moose_Wala_004_20230609071424_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_shubh',
      name: 'Shubh',
      languages: ['Punjabi'],
      genre: 'Trap & Modern Punjabi',
      artistType: ArtistType.singerSongwriter,
      popularityScore: 25000,
      imageUrl: 'https://c.saavncdn.com/artists/Shubh_000_20230519104037_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_amrindergill',
      name: 'Amrinder Gill',
      languages: ['Punjabi'],
      genre: 'Soulful Punjabi Melodies',
      artistType: ArtistType.playbackArtist,
      popularityScore: 18000,
      imageUrl: 'https://c.saavncdn.com/artists/Amrinder_Gill_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_gurdasmaan',
      name: 'Gurdas Maan',
      languages: ['Punjabi'],
      genre: 'Living Legend of Punjabi Folk',
      artistType: ArtistType.singerSongwriter,
      popularityScore: 20000,
      imageUrl: 'https://c.saavncdn.com/artists/Gurdas_Maan_003_20230919102120_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_bpraak',
      name: 'B Praak',
      languages: ['Punjabi', 'Hindi'],
      genre: 'Heartbreak & Orchestral Pop',
      artistType: ArtistType.composer,
      popularityScore: 24000,
      imageUrl: 'https://c.saavncdn.com/artists/B_Praak_004_20231128120401_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),

    // --- Tamil ---
    OnboardingArtist(
      id: 'art_anirudh',
      name: 'Anirudh Ravichander',
      languages: ['Tamil', 'Telugu', 'Hindi'],
      genre: 'Viral Anthems & Electronic',
      artistType: ArtistType.composer,
      popularityScore: 33000,
      imageUrl: 'https://c.saavncdn.com/artists/Anirudh_Ravichander_003_20260121134149_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_sidsriram',
      name: 'Sid Sriram',
      languages: ['Tamil', 'Telugu', 'Malayalam'],
      genre: 'Carnatic Soul & Contemporary R&B',
      artistType: ArtistType.playbackArtist,
      popularityScore: 29000,
      imageUrl: 'https://c.saavncdn.com/artists/Sid_Sriram_003_20260121134149_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_yuvan',
      name: 'Yuvan Shankar Raja',
      languages: ['Tamil', 'Telugu'],
      genre: 'Youth Melodies & Drug Songs',
      artistType: ArtistType.composer,
      popularityScore: 22000,
      imageUrl: 'https://c.saavncdn.com/artists/Yuvan_Shankar_Raja_003_20230228105414_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_ilaiyaraaja',
      name: 'Ilaiyaraaja',
      languages: ['Tamil', 'Telugu', 'Malayalam'],
      genre: 'Isaignani & Symphonic Folk',
      artistType: ArtistType.composer,
      popularityScore: 25000,
      imageUrl: 'https://c.saavncdn.com/artists/Ilaiyaraaja_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_spb',
      name: 'S. P. Balasubrahmanyam',
      languages: ['Tamil', 'Telugu', 'Kannada', 'Hindi'],
      genre: 'Voice of South Indian Cinema',
      artistType: ArtistType.playbackArtist,
      popularityScore: 28000,
      imageUrl: 'https://c.saavncdn.com/artists/SP_Balasubrahmanyam_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_dhee',
      name: 'Dhee',
      languages: ['Tamil'],
      genre: 'Indie Soul & Enjoy Enjaami',
      artistType: ArtistType.singerSongwriter,
      popularityScore: 16000,
      imageUrl: 'https://c.saavncdn.com/artists/Dhee_003_20211029080517_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),

    // --- Telugu ---
    OnboardingArtist(
      id: 'art_anuragkulkarni',
      name: 'Anurag Kulkarni',
      languages: ['Telugu'],
      genre: 'Romantic Telugu Melodies',
      artistType: ArtistType.playbackArtist,
      popularityScore: 19000,
      imageUrl: 'https://c.saavncdn.com/artists/Anurag_Kulkarni_003_20240508103358_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_rammiriyala',
      name: 'Ram Miriyala',
      languages: ['Telugu'],
      genre: 'Indie Folk & High Energy Hits',
      artistType: ArtistType.singerSongwriter,
      popularityScore: 18000,
      imageUrl: 'https://c.saavncdn.com/artists/Ram_Miriyala_001_20231206073013_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_mangli',
      name: 'Mangli',
      languages: ['Telugu', 'Kannada'],
      genre: 'Traditional Folk & Electrifying Beats',
      artistType: ArtistType.singer,
      popularityScore: 18500,
      imageUrl: 'https://c.saavncdn.com/artists/Mangli_003_20240521123429_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_dsp',
      name: 'Devi Sri Prasad',
      languages: ['Telugu', 'Tamil'],
      genre: 'Rockstar DSP Dance Numbers',
      artistType: ArtistType.composer,
      popularityScore: 23000,
      imageUrl: 'https://c.saavncdn.com/artists/Devi_Sri_Prasad_002_20230615091108_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_thamans',
      name: 'Thaman S',
      languages: ['Telugu', 'Tamil'],
      genre: 'Sensational Mass Beats & Bass',
      artistType: ArtistType.composer,
      popularityScore: 22500,
      imageUrl: 'https://c.saavncdn.com/artists/Thaman_S_003_20230228105414_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),

    // --- Malayalam ---
    OnboardingArtist(
      id: 'art_yesudas',
      name: 'K. J. Yesudas',
      languages: ['Malayalam', 'Tamil', 'Telugu', 'Hindi'],
      genre: 'Celestial Voice & Carnatic',
      artistType: ArtistType.playbackArtist,
      popularityScore: 24000,
      imageUrl: 'https://c.saavncdn.com/artists/KJ_Yesudas_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_kschithra',
      name: 'K. S. Chithra',
      languages: ['Malayalam', 'Tamil', 'Telugu', 'Hindi', 'Kannada'],
      genre: 'Little Nightingale of South',
      artistType: ArtistType.playbackArtist,
      popularityScore: 23000,
      imageUrl: 'https://c.saavncdn.com/artists/K_S_Chithra_002_20190906071921_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_vineeth',
      name: 'Vineeth Sreenivasan',
      languages: ['Malayalam'],
      genre: 'Youthful Nostalgia & Romance',
      artistType: ArtistType.playbackArtist,
      popularityScore: 17000,
      imageUrl: 'https://c.saavncdn.com/artists/Vineeth_Sreenivasan_003_20240508103358_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_sushinshyam',
      name: 'Sushin Shyam',
      languages: ['Malayalam'],
      genre: 'Modern Malayalam Synth & Scores',
      artistType: ArtistType.composer,
      popularityScore: 19000,
      imageUrl: 'https://c.saavncdn.com/artists/Sushin_Shyam_002_20250707125538_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),

    // --- Kannada ---
    OnboardingArtist(
      id: 'art_vijayprakash',
      name: 'Vijay Prakash',
      languages: ['Kannada', 'Tamil', 'Telugu', 'Hindi'],
      genre: 'Dynamic Classical & Film Hits',
      artistType: ArtistType.playbackArtist,
      popularityScore: 18000,
      imageUrl: 'https://c.saavncdn.com/artists/Vijay_Prakash_007_20250225123208_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_sanjithhegde',
      name: 'Sanjith Hegde',
      languages: ['Kannada', 'Tamil', 'Telugu'],
      genre: 'Indie Jazz & Neo-Soul Pop',
      artistType: ArtistType.singerSongwriter,
      popularityScore: 17500,
      imageUrl: 'https://c.saavncdn.com/artists/Sanjith_Hegde_002_20230413072406_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_raghudixit',
      name: 'Raghu Dixit',
      languages: ['Kannada', 'Hindi', 'English'],
      genre: 'Indian Folk Rock & World Grooves',
      artistType: ArtistType.singerSongwriter,
      popularityScore: 16000,
      imageUrl: 'https://c.saavncdn.com/artists/Raghu_Dixit_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),

    // --- Marathi ---
    OnboardingArtist(
      id: 'art_ajayatul',
      name: 'Ajay-Atul',
      languages: ['Marathi', 'Hindi'],
      genre: 'Grand Orchestral Folk & Energy',
      artistType: ArtistType.composer,
      popularityScore: 22000,
      imageUrl: 'https://c.saavncdn.com/artists/Ajay_Atul_003_20230228105414_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_swapnil',
      name: 'Swapnil Bandodkar',
      languages: ['Marathi'],
      genre: 'Romantic Marathi Bhavgeet',
      artistType: ArtistType.playbackArtist,
      popularityScore: 14000,
      imageUrl: 'https://c.saavncdn.com/artists/Swapnil_Bandodkar_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_belashende',
      name: 'Bela Shende',
      languages: ['Marathi', 'Hindi'],
      genre: 'Natya Sangeet & Film Melodies',
      artistType: ArtistType.playbackArtist,
      popularityScore: 13500,
      imageUrl: 'https://c.saavncdn.com/artists/Bela_Shende_003_20240129070549_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_avadhoot',
      name: 'Avadhoot Gupte',
      languages: ['Marathi'],
      genre: 'Marathi Pop & Energetic Rock',
      artistType: ArtistType.singerSongwriter,
      popularityScore: 14500,
      imageUrl: 'https://c.saavncdn.com/artists/Avadhoot_Gupte_003_20250227062254_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),

    // --- Urdu ---
    OnboardingArtist(
      id: 'art_rahat',
      name: 'Rahat Fateh Ali Khan',
      languages: ['Urdu', 'Hindi'],
      genre: 'Sufiana Qawwali & Soul',
      artistType: ArtistType.playbackArtist,
      popularityScore: 27000,
      imageUrl: 'https://cdn-images.dzcdn.net/images/artist/8263c6e6e75baf8387ad258459021f78/500x500-000000-80-0-0.jpg',
      imageSource: 'Deezer Official CDN',
    ),
    OnboardingArtist(
      id: 'art_nusrat',
      name: 'Nusrat Fateh Ali Khan',
      languages: ['Urdu', 'Punjabi'],
      genre: 'Shahenshah-e-Qawwali',
      artistType: ArtistType.singer,
      popularityScore: 30000,
      imageUrl: 'https://cdn-images.dzcdn.net/images/artist/49ca85b1d9a02da437cdd62c5476553d/500x500-000000-80-0-0.jpg',
      imageSource: 'Deezer Official CDN',
    ),
    OnboardingArtist(
      id: 'art_alizafar',
      name: 'Ali Zafar',
      languages: ['Urdu', 'Hindi'],
      genre: 'Pop Rock & Romantic Ghazals',
      artistType: ArtistType.singerSongwriter,
      popularityScore: 19000,
      imageUrl: 'https://cdn-images.dzcdn.net/images/artist/fde549c8fddd86a032833ab21830c4cb/500x500-000000-80-0-0.jpg',
      imageSource: 'Deezer Official CDN',
    ),
    OnboardingArtist(
      id: 'art_asimazhar',
      name: 'Asim Azhar',
      languages: ['Urdu'],
      genre: 'Urban Pop & Coke Studio Ballads',
      artistType: ArtistType.singerSongwriter,
      popularityScore: 18500,
      imageUrl: 'https://cdn-images.dzcdn.net/images/artist/52a08f78d491088013cf8b68a13ae8b9/500x500-000000-80-0-0.jpg',
      imageSource: 'Deezer Official CDN',
    ),

    // --- Assamese ---
    OnboardingArtist(
      id: 'art_zubeen',
      name: 'Zubeen Garg',
      languages: ['Assamese', 'Bengali', 'Hindi'],
      genre: 'Assamese Modern Folk & Rock',
      artistType: ArtistType.singerSongwriter,
      popularityScore: 23000,
      imageUrl: 'https://c.saavncdn.com/artists/Zubeen_Garg_003_20201020081952_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_papon',
      name: 'Papon',
      languages: ['Assamese', 'Hindi', 'Bengali'],
      genre: 'Assamese Bihu Folk Fusion',
      artistType: ArtistType.singerSongwriter,
      popularityScore: 21500,
      imageUrl: 'https://c.saavncdn.com/artists/Papon_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_bhupenhazarika',
      name: 'Bhupen Hazarika',
      languages: ['Assamese', 'Bengali', 'Hindi'],
      genre: 'Legendary Cultural Bard',
      artistType: ArtistType.singerSongwriter,
      popularityScore: 19000,
      imageUrl: 'https://c.saavncdn.com/artists/Bhupen_Hazarika_003_20230608123944_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),

    // --- Odia ---
    OnboardingArtist(
      id: 'art_humanesagar',
      name: 'Humane Sagar',
      languages: ['Odia'],
      genre: 'Modern Odia Melodies & Film Pop',
      artistType: ArtistType.playbackArtist,
      popularityScore: 20000,
      imageUrl: 'https://c.saavncdn.com/artists/Humane_Sagar_002_20240521123429_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_asimapanda',
      name: 'Asima Panda',
      languages: ['Odia'],
      genre: 'Odia Dance Beats & Folk Pop',
      artistType: ArtistType.playbackArtist,
      popularityScore: 17000,
      imageUrl: 'https://c.saavncdn.com/artists/Aseema_Panda_004_20250619094741_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),

    // --- Bhojpuri ---
    OnboardingArtist(
      id: 'art_pawansingh',
      name: 'Pawan Singh',
      languages: ['Bhojpuri'],
      genre: 'Bhojpuri Superstar Melodies',
      artistType: ArtistType.playbackArtist,
      popularityScore: 28000,
      imageUrl: 'https://c.saavncdn.com/artists/Pawan_Singh_003_20241119074737_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_khesarilal',
      name: 'Khesari Lal Yadav',
      languages: ['Bhojpuri'],
      genre: 'Bhojpuri High-Energy Beats',
      artistType: ArtistType.playbackArtist,
      popularityScore: 26000,
      imageUrl: 'https://c.saavncdn.com/artists/Khesari_Lal_Yadav_004_20241119074533_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_shilpiraj',
      name: 'Shilpi Raj',
      languages: ['Bhojpuri'],
      genre: 'Folk Duets & Modern Hits',
      artistType: ArtistType.playbackArtist,
      popularityScore: 22000,
      imageUrl: 'https://c.saavncdn.com/artists/Shilpi_Raj_003_20250310065400_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),

    // --- Gujarati ---
    OnboardingArtist(
      id: 'art_sachinjigar',
      name: 'Sachin-Jigar',
      languages: ['Gujarati', 'Hindi'],
      genre: 'Urban Gujarati Folk & Bollywood',
      artistType: ArtistType.composer,
      popularityScore: 22500,
      imageUrl: 'https://c.saavncdn.com/artists/Sachin_Jigar_003_20251222093820_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_adityagadhvi',
      name: 'Aditya Gadhvi',
      languages: ['Gujarati', 'Hindi'],
      genre: 'Coke Studio Khalasi & Charani Sahitya',
      artistType: ArtistType.singerSongwriter,
      popularityScore: 25000,
      imageUrl: 'https://c.saavncdn.com/artists/Aditya_Gadhvi_004_20260902060949_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_jigardan',
      name: 'Jigardan Gadhavi',
      languages: ['Gujarati'],
      genre: 'Romantic Gujarati Melodies',
      artistType: ArtistType.singerSongwriter,
      popularityScore: 18000,
      imageUrl: 'https://c.saavncdn.com/artists/Jigardan_Gadhavi_001_20200918061750_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_geetarabari',
      name: 'Geeta Rabari',
      languages: ['Gujarati'],
      genre: 'Authentic Folk & Garba Beats',
      artistType: ArtistType.singer,
      popularityScore: 19500,
      imageUrl: 'https://c.saavncdn.com/artists/Geeta_Rabari_20191129080213_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_kinjaldave',
      name: 'Kinjal Dave',
      languages: ['Gujarati'],
      genre: 'Garba Queen & Modern Gujarati Pop',
      artistType: ArtistType.singer,
      popularityScore: 18500,
      imageUrl: 'https://c.saavncdn.com/artists/Kinjal_Dave_003_20241217095517_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),

    // --- English / International ---
    OnboardingArtist(
      id: 'art_theweeknd',
      name: 'The Weeknd',
      languages: ['English'],
      genre: 'Synth-Pop & Alternative R&B',
      artistType: ArtistType.singerSongwriter,
      popularityScore: 40000,
      imageUrl: 'https://cdn-images.dzcdn.net/images/artist/581693b4724a7fcfa754455101e13a44/500x500-000000-80-0-0.jpg',
      imageSource: 'Deezer Official CDN',
    ),
    OnboardingArtist(
      id: 'art_taylorswift',
      name: 'Taylor Swift',
      languages: ['English'],
      genre: 'Pop Anthems & Storytelling',
      artistType: ArtistType.singerSongwriter,
      popularityScore: 39000,
      imageUrl: 'https://cdn-images.dzcdn.net/images/artist/cc2495870fe1a792ad0cdb05501ad5ec/500x500-000000-80-0-0.jpg',
      imageSource: 'Deezer Official CDN',
    ),
    OnboardingArtist(
      id: 'art_edsheeran',
      name: 'Ed Sheeran',
      languages: ['English'],
      genre: 'Acoustic Pop & Global Anthems',
      artistType: ArtistType.singerSongwriter,
      popularityScore: 38000,
      imageUrl: 'https://cdn-images.dzcdn.net/images/artist/d6bb84390641d8ae9118228d9544e53d/500x500-000000-80-0-0.jpg',
      imageSource: 'Deezer Official CDN',
    ),
    OnboardingArtist(
      id: 'art_coldplay',
      name: 'Coldplay',
      languages: ['English'],
      genre: 'Stadium Rock & Euphoria',
      artistType: ArtistType.band,
      popularityScore: 37000,
      imageUrl: 'https://cdn-images.dzcdn.net/images/artist/3087954bca22f306324912e5ac8375c3/500x500-000000-80-0-0.jpg',
      imageSource: 'Deezer Official CDN',
    ),
    OnboardingArtist(
      id: 'art_billie',
      name: 'Billie Eilish',
      languages: ['English'],
      genre: 'Alt-Pop & Haunting Melodies',
      artistType: ArtistType.singerSongwriter,
      popularityScore: 36000,
      imageUrl: 'https://cdn-images.dzcdn.net/images/artist/8eab1a9a644889aabaca1e193e05f984/500x500-000000-80-0-0.jpg',
      imageSource: 'Deezer Official CDN',
    ),
    OnboardingArtist(
      id: 'art_drake',
      name: 'Drake',
      languages: ['English'],
      genre: 'Hip-Hop & Melodic Rap',
      artistType: ArtistType.singer,
      popularityScore: 35000,
      imageUrl: 'https://c.saavncdn.com/artists/Drake_006_20260520062317_500x500.jpg',
      imageSource: 'JioSaavn Official CDN',
    ),
    OnboardingArtist(
      id: 'art_dualipa',
      name: 'Dua Lipa',
      languages: ['English'],
      genre: 'Future Nostalgia Dance-Pop',
      artistType: ArtistType.singer,
      popularityScore: 33000,
      imageUrl: 'https://cdn-images.dzcdn.net/images/artist/9ba2e6ee96bb8c2794eb8e3052865969/500x500-000000-80-0-0.jpg',
      imageSource: 'Deezer Official CDN',
    ),
    OnboardingArtist(
      id: 'art_imaginedragons',
      name: 'Imagine Dragons',
      languages: ['English'],
      genre: 'Electrifying Arena Rock',
      artistType: ArtistType.band,
      popularityScore: 34000,
      imageUrl: 'https://cdn-images.dzcdn.net/images/artist/ee523be945b0857fd211ff1be545db48/500x500-000000-80-0-0.jpg',
      imageSource: 'Deezer Official CDN',
    ),
    OnboardingArtist(
      id: 'art_postmalone',
      name: 'Post Malone',
      languages: ['English'],
      genre: 'Hip-Hop, Rock & Melodic Pop',
      artistType: ArtistType.singerSongwriter,
      popularityScore: 32000,
      imageUrl: 'https://cdn-images.dzcdn.net/images/artist/8ec3ddc160da30cfbf44053d5a498b3c/500x500-000000-80-0-0.jpg',
      imageSource: 'Deezer Official CDN',
    ),
  ];

  /// Get artists matching selected languages with popularity ranking
  static List<OnboardingArtist> getArtistsForLanguages(List<String> selectedLanguageNames) {
    if (selectedLanguageNames.isEmpty) {
      final list = List<OnboardingArtist>.from(curatedArtists);
      list.sort((a, b) => b.popularityScore.compareTo(a.popularityScore));
      return list;
    }

    final normalized = selectedLanguageNames.map((e) => e.trim().toLowerCase()).toSet();

    // Matching artists whose languages intersect with user's selection
    final matching = curatedArtists.where((a) {
      return a.languages.any((l) => normalized.contains(l.toLowerCase()));
    }).toList();
    matching.sort((a, b) => b.popularityScore.compareTo(a.popularityScore));

    // Other artists from remaining languages sorted by popularity
    final remaining = curatedArtists.where((a) {
      return !a.languages.any((l) => normalized.contains(l.toLowerCase()));
    }).toList();
    remaining.sort((a, b) => b.popularityScore.compareTo(a.popularityScore));

    return [...matching, ...remaining];
  }
}
