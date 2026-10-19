
/**
 * Implementation of radioactive11/the-lyrics-api
 * Supports querying an external running FastAPI instance (http://localhost:8000/lyrics)
 * or runs the exact scraping engine natively in Node.js.
 */
export async function fetchTheLyricsApi(artist, song, lang = 'eng') {
  // 1. Try external running instance of the-lyrics-api (if user launched it via uvicorn)
  try {
    const localFastApi = 'http://localhost:8000/lyrics';
    const localRes = await fetch(localFastApi, {
      method: 'GET',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ artist, song, lang }),
      signal: AbortSignal.timeout(1200)
    });
    if (localRes.ok) {
      const data = await localRes.json();
      if (data && data.lyrics && data.lyrics.trim().length > 0) {
        return data.lyrics.trim();
      }
    }
  } catch (e) {
    // External instance not active, proceed to native engine
  }

  // 2. Native Implementation of radioactive11/the-lyrics-api (English via AZLyrics)
  const cleanArtist = artist.toLowerCase().replace(/[^a-z0-9]/g, '');
  const cleanSong = song.toLowerCase().replace(/[^a-z0-9]/g, '');

  if (cleanArtist && cleanSong) {
    try {
      const azUrl = `https://www.azlyrics.com/lyrics/${cleanArtist}/${cleanSong}.html`;
      const res = await fetch(azUrl, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        },
        signal: AbortSignal.timeout(4000)
      });

      if (res.ok) {
        const html = await res.text();
        const marker = '<!-- Usage of azlyrics.com content by any third-party lyrics provider is prohibited by our licensing agreement. Sorry about that. -->';
        const parts = html.split(marker);
        if (parts.length > 1) {
          const lyricPart = parts[1].split('</div>')[0].trim();
          const clean = lyricPart
            .replace(/<br\s*\/?>/gi, '\n')
            .replace(/&quot;/g, '"')
            .replace(/&#39;/g, "'")
            .replace(/&amp;/g, '&')
            .replace(/<.*?>/g, '')
            .trim();
          if (clean.length > 0) return clean;
        }
      }
    } catch (err) {
      // Continue to next fallback
    }
  }

  return null;
}
