import express from 'express';
import cors from 'cors';
import { exec } from 'child_process';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import https from 'https';
import http from 'http';
import { fetchTheLyricsApi } from './the_lyrics_api.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ytdlpExe = path.join(__dirname, 'yt-dlp.exe');
const ytdlpPath = fs.existsSync(ytdlpExe) ? ytdlpExe : 'yt-dlp';

const app = express();
const PORT = process.env.PORT || 3001;

function getBaseUrl(req) {
  const proto = req.headers['x-forwarded-proto'] || req.protocol || 'http';
  const host = req.get('host');
  return `${proto}://${host}`;
}

app.use(cors());
app.use(express.json());

// Health check & welcome route
app.get('/', (req, res) => {
  res.json({
    status: 'online',
    service: 'Soundifly Music API Engine',
    version: '1.0.0',
    message: 'Soundifly Backend is running smoothly 🚀',
    endpoints: [
      '/api/trending',
      '/api/search?q={query}',
      '/api/lyrics?title={title}',
      '/api/stream/{videoId}'
    ]
  });
});

app.get('/health', (req, res) => {
  res.status(200).send('OK');
});

// YouTube Music Innertube Client Configuration
const YTM_SEARCH_URL = 'https://music.youtube.com/youtubei/v1/search?prettyPrint=false';
const YTM_SUGGESTIONS_URL = 'https://music.youtube.com/youtubei/v1/music/get_search_suggestions?prettyPrint=false';

const YTM_HEADERS = {
  'Content-Type': 'application/json',
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  'Origin': 'https://music.youtube.com',
  'Referer': 'https://music.youtube.com/'
};

const YTM_CONTEXT = {
  client: {
    clientName: 'WEB_REMIX',
    clientVersion: '1.20240101.01.00',
    hl: 'en',
    gl: 'US'
  }
};

// In-memory cache for audio direct URLs
const streamCache = new Map();

function getYtDlpBin() {
  if (fs.existsSync('/usr/local/bin/yt-dlp')) return '/usr/local/bin/yt-dlp';
  if (fs.existsSync(ytdlpExe)) return ytdlpExe;
  return 'yt-dlp';
}

function getDirectStreamUrl(videoId) {
  return new Promise((resolve, reject) => {
    if (streamCache.has(videoId)) {
      const cached = streamCache.get(videoId);
      if (Date.now() - cached.timestamp < 1000 * 60 * 60 * 4) {
        return resolve(cached.url);
      }
    }

    const videoUrl = `https://www.youtube.com/watch?v=${videoId}`;
    const bin = getYtDlpBin();
    // Use android player client to bypass YouTube datacenter IP blocking
    const cmd = `"${bin}" --no-warnings --extractor-args "youtube:player_client=android,web" --force-ipv4 -g -f "ba[ext=m4a]/ba/b" "${videoUrl}"`;

    exec(cmd, { timeout: 25000 }, (error, stdout, stderr) => {
      if (error || !stdout.trim()) {
        console.error('yt-dlp extract error for videoId', videoId, 'stderr:', stderr, 'err:', error);
        // Fallback: try standard format
        const fallbackCmd = `"${bin}" -g -f "ba/b" "${videoUrl}"`;
        exec(fallbackCmd, { timeout: 20000 }, (fErr, fOut, fStderr) => {
          if (fErr || !fOut.trim()) {
            return reject(new Error(stderr || fStderr || error?.message || 'Extraction failed'));
          }
          const streamUrl = fOut.trim().split('\n')[0].trim();
          streamCache.set(videoId, { url: streamUrl, timestamp: Date.now() });
          resolve(streamUrl);
        });
        return;
      }

      const streamUrl = stdout.trim().split('\n')[0].trim();
      streamCache.set(videoId, { url: streamUrl, timestamp: Date.now() });
      resolve(streamUrl);
    });
  });
}

// Diagnostic endpoint to check yt-dlp on cloud instance
app.get('/api/debug-stream/:videoId', (req, res) => {
  const videoId = req.params.videoId;
  const videoUrl = `https://www.youtube.com/watch?v=${videoId}`;
  const bin = getYtDlpBin();
  const cmd = `"${bin}" --no-warnings --extractor-args "youtube:player_client=android,web" --force-ipv4 -g -f "ba[ext=m4a]/ba/b" "${videoUrl}"`;

  exec(cmd, { timeout: 25000 }, (error, stdout, stderr) => {
    res.json({
      bin,
      binExists: fs.existsSync(bin),
      cmd,
      error: error ? error.message : null,
      stdout: stdout ? stdout.trim() : null,
      stderr: stderr ? stderr.trim() : null
    });
  });
});

// 1. YouTube Music Live Search
app.get('/api/search', async (req, res) => {
  const query = req.query.q;
  if (!query) {
    return res.status(400).json({ error: 'Missing query parameter q' });
  }

  try {
    const response = await fetch(YTM_SEARCH_URL, {
      method: 'POST',
      headers: YTM_HEADERS,
      body: JSON.stringify({
        context: YTM_CONTEXT,
        query: query,
        params: 'EgWKAQIIAWoKEAoQCRADEAQQBQ%3D%3D' // Filter exclusively for Songs
      })
    });

    if (!response.ok) {
      throw new Error(`YouTube Music responded with status ${response.status}`);
    }

    const data = await response.json();
    const section = data.contents?.tabbedSearchResultsRenderer?.tabs?.[0]?.tabRenderer?.content?.sectionListRenderer?.contents?.[0];
    const items = section?.musicShelfRenderer?.contents || [];

    const songs = items.map(item => {
      const r = item.musicResponsiveListItemRenderer;
      if (!r) return null;

      const title = r.flexColumns?.[0]?.musicResponsiveListItemFlexColumnRenderer?.text?.runs?.[0]?.text || 'Unknown Title';
      const flex1Runs = r.flexColumns?.[1]?.musicResponsiveListItemFlexColumnRenderer?.text?.runs || [];
      const artist = flex1Runs[0]?.text || 'Various Artists';
      
      let album = 'Single';
      let durationStr = '3:30';

      for (let i = 1; i < flex1Runs.length; i++) {
        const text = flex1Runs[i].text.trim();
        if (text === '•') continue;
        if (/^\d+:\d+$/.test(text)) {
          durationStr = text;
        } else if (text.length > 1) {
          album = text;
        }
      }

      const videoId = r.playlistItemData?.videoId || 
                      r.flexColumns?.[0]?.musicResponsiveListItemFlexColumnRenderer?.text?.runs?.[0]?.navigationEndpoint?.watchEndpoint?.videoId;

      if (!videoId) return null;

      const thumbs = r.thumbnail?.musicThumbnailRenderer?.thumbnail?.thumbnails || [];
      const thumb = thumbs.length > 0 ? thumbs[thumbs.length - 1].url : 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&auto=format&fit=crop&q=80';

      const durParts = durationStr.split(':').map(Number);
      const durationSeconds = durParts.length === 2 ? durParts[0] * 60 + durParts[1] : (durParts.length === 3 ? durParts[0] * 3600 + durParts[1] * 60 + durParts[2] : 210);

      return {
        id: videoId,
        title,
        artist,
        album,
        coverUrl: `${getBaseUrl(req)}/api/image-proxy?url=${encodeURIComponent(thumb)}`,
        audioUrl: `${getBaseUrl(req)}/api/stream/${videoId}`,
        durationSeconds,
        durationFormatted: durationStr,
        genre: 'YouTube Music'
      };
    }).filter(Boolean);

    res.json(songs);
  } catch (err) {
    console.error('Search error:', err);
    res.status(500).json({ error: err.message });
  }
});

// 2. YouTube Music Search Suggestions
app.get('/api/suggestions', async (req, res) => {
  const query = req.query.q;
  if (!query) return res.json([]);

  try {
    const response = await fetch(YTM_SUGGESTIONS_URL, {
      method: 'POST',
      headers: YTM_HEADERS,
      body: JSON.stringify({
        context: YTM_CONTEXT,
        input: query
      })
    });

    if (!response.ok) return res.json([]);

    const data = await response.json();
    const contents = data.contents?.[0]?.searchSuggestionsSectionRenderer?.contents || [];
    const suggestions = contents.map(c => {
      const runs = c.searchSuggestionRenderer?.suggestion?.runs || [];
      return runs.map(r => r.text).join('');
    }).filter(Boolean);

    res.json(suggestions);
  } catch (err) {
    console.error('Suggestions error:', err);
    res.json([]);
  }
});

// 3. YouTube Music Trending Tracks
app.get('/api/trending', async (req, res) => {
  try {
    const response = await fetch(YTM_SEARCH_URL, {
      method: 'POST',
      headers: YTM_HEADERS,
      body: JSON.stringify({
        context: YTM_CONTEXT,
        query: 'Trending Hits 2026 Bangladesh Global',
        params: 'EgWKAQIIAWoKEAoQCRADEAQQBQ%3D%3D'
      })
    });

    const data = await response.json();
    const section = data.contents?.tabbedSearchResultsRenderer?.tabs?.[0]?.tabRenderer?.content?.sectionListRenderer?.contents?.[0];
    const items = section?.musicShelfRenderer?.contents || [];

    const songs = items.slice(0, 15).map(item => {
      const r = item.musicResponsiveListItemRenderer;
      if (!r) return null;

      const title = r.flexColumns?.[0]?.musicResponsiveListItemFlexColumnRenderer?.text?.runs?.[0]?.text || 'Trending Song';
      const flex1Runs = r.flexColumns?.[1]?.musicResponsiveListItemFlexColumnRenderer?.text?.runs || [];
      const artist = flex1Runs[0]?.text || 'Popular Artist';
      
      let durationStr = '3:45';
      for (let i = 1; i < flex1Runs.length; i++) {
        const text = flex1Runs[i].text.trim();
        if (/^\d+:\d+$/.test(text)) durationStr = text;
      }

      const videoId = r.playlistItemData?.videoId || 
                      r.flexColumns?.[0]?.musicResponsiveListItemFlexColumnRenderer?.text?.runs?.[0]?.navigationEndpoint?.watchEndpoint?.videoId;

      if (!videoId) return null;

      const thumbs = r.thumbnail?.musicThumbnailRenderer?.thumbnail?.thumbnails || [];
      const thumb = thumbs.length > 0 ? thumbs[thumbs.length - 1].url : 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=600&auto=format&fit=crop&q=80';

      const durParts = durationStr.split(':').map(Number);
      const durationSeconds = durParts.length === 2 ? durParts[0] * 60 + durParts[1] : 210;

      return {
        id: videoId,
        title,
        artist,
        album: 'Trending Now',
        coverUrl: `${getBaseUrl(req)}/api/image-proxy?url=${encodeURIComponent(thumb)}`,
        audioUrl: `${getBaseUrl(req)}/api/stream/${videoId}`,
        durationSeconds,
        durationFormatted: durationStr,
        genre: 'Top Trending'
      };
    }).filter(Boolean);

    res.json(songs);
  } catch (err) {
    console.error('Trending error:', err);
    res.status(500).json({ error: err.message });
  }
});

// 4. IMAGE PROXY FOR FLUTTER WEB CORS COMPATIBILITY
app.get('/api/image-proxy', (req, res) => {
  const imageUrl = req.query.url;
  if (!imageUrl) return res.status(400).send('Missing url parameter');

  try {
    const parsed = new URL(imageUrl);
    const client = parsed.protocol === 'https:' ? https : http;

    const proxyReq = client.get(imageUrl, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': 'https://music.youtube.com/'
      }
    }, (proxyRes) => {
      res.setHeader('Access-Control-Allow-Origin', '*');
      res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
      res.setHeader('Cache-Control', 'public, max-age=604800'); // 7 days cache
      if (proxyRes.headers['content-type']) {
        res.setHeader('Content-Type', proxyRes.headers['content-type']);
      }
      proxyRes.pipe(res);
    });

    proxyReq.on('error', (err) => {
      console.error('Image proxy error:', err.message);
      if (!res.headersSent) res.status(502).send('Error loading image');
    });
  } catch (e) {
    res.status(400).send('Invalid image URL');
  }
});

// 4. REAL-TIME AUDIO PROXY (Solves CORS and stream buffering in Chrome!)
app.get('/api/stream/:videoId', async (req, res) => {
  const videoId = req.params.videoId;
  if (!videoId || videoId === 'undefined') {
    return res.status(400).send('Invalid videoId');
  }

  try {
    const directUrl = await getDirectStreamUrl(videoId);
    const clientRange = req.headers.range;

    const options = {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
      }
    };

    if (clientRange) {
      options.headers['Range'] = clientRange;
    }

    const proxyReq = https.get(directUrl, options, (proxyRes) => {
      // Forward HTTP status (200 or 206 Partial Content)
      res.status(proxyRes.statusCode || 200);

      // Set CORS and streaming headers
      res.setHeader('Access-Control-Allow-Origin', '*');
      res.setHeader('Access-Control-Allow-Methods', 'GET, HEAD, OPTIONS');
      res.setHeader('Access-Control-Allow-Headers', 'Range');
      res.setHeader('Accept-Ranges', 'bytes');

      if (proxyRes.headers['content-type']) {
        res.setHeader('Content-Type', proxyRes.headers['content-type']);
      } else {
        res.setHeader('Content-Type', 'audio/mp4');
      }

      if (proxyRes.headers['content-length']) {
        res.setHeader('Content-Length', proxyRes.headers['content-length']);
      }
      if (proxyRes.headers['content-range']) {
        res.setHeader('Content-Range', proxyRes.headers['content-range']);
      }

      proxyRes.pipe(res);
    });

    proxyReq.on('error', (err) => {
      console.error('Proxy error:', err);
      if (!res.headersSent) {
        res.status(500).send('Streaming error');
      }
    });

    req.on('close', () => {
      proxyReq.destroy();
    });

  } catch (err) {
    console.error('Stream extraction failed:', err);
    res.status(500).send('Failed to stream audio');
  }
});

// Helper function to parse LRC time-synced lyrics
function parseLrc(lrcText) {
  const lines = lrcText.split('\n');
  const result = [];
  const regex = /\[(\d{2}):(\d{2}(?:\.\d+)?)\](.*)/;

  for (const line of lines) {
    const match = line.match(regex);
    if (match) {
      const minutes = parseInt(match[1], 10);
      const seconds = parseFloat(match[2]);
      const totalSeconds = Math.floor(minutes * 60 + seconds);
      const text = match[3].trim();
      if (text.length > 0) {
        result.push({ seconds: totalSeconds, text });
      }
    }
  }
  return result;
}

// 5. SYNCHRONIZED LYRICS API (LRCLIB + Dynamic Search)
app.get('/api/lyrics', async (req, res) => {
  const { title, artist, duration } = req.query;
  if (!title) {
    return res.json({ synced: false, lines: [] });
  }

  // Clean title: remove " (From ...)", " (Official Video)", " [Audio]", " ft. ...", etc.
  const cleanTitle = title
    .replace(/\(.*?\)/g, '')
    .replace(/\[.*?\]/g, '')
    .replace(/feat\..*/i, '')
    .replace(/ft\..*/i, '')
    .replace(/official.*/i, '')
    .trim();

  const cleanArtist = (artist || '')
    .replace(/feat\..*/i, '')
    .replace(/ft\..*/i, '')
    .split(',')[0]
    .split('&')[0]
    .trim();

  try {
    let data = null;

    // 1. Try exact match from LRCLIB
    try {
      let lrclibUrl = `https://lrclib.net/api/get?track_name=${encodeURIComponent(cleanTitle)}&artist_name=${encodeURIComponent(cleanArtist)}`;
      if (duration) lrclibUrl += `&duration=${duration}`;

      const response = await fetch(lrclibUrl, {
        headers: { 'User-Agent': 'Soundifly Music App v1.0.0 (https://soundifly.app)' }
      });
      if (response.ok) {
        data = await response.json();
      }
    } catch (e) {
      // Continue to search fallback
    }

    // 2. If exact match not found, try search
    if (!data || (!data.syncedLyrics && !data.plainLyrics)) {
      try {
        const searchUrl = `https://lrclib.net/api/search?q=${encodeURIComponent(cleanTitle + ' ' + cleanArtist)}`;
        const sRes = await fetch(searchUrl, {
          headers: { 'User-Agent': 'Soundifly Music App v1.0.0' }
        });
        if (sRes.ok) {
          const list = await sRes.json();
          if (list && list.length > 0) {
            data = list[0];
          }
        }
      } catch (e) {
        // Fallback
      }
    }

    // If synced lyrics found, parse and return timestamps
    if (data && data.syncedLyrics) {
      const parsed = parseLrc(data.syncedLyrics);
      if (parsed.length > 0) {
        return res.json({ synced: true, lines: parsed });
      }
    }

    // If plain lyrics found, distribute timestamps evenly across song duration
    if (data && data.plainLyrics) {
      const rawLines = data.plainLyrics.split('\n').map(l => l.trim()).filter(Boolean);
      const totalDur = parseInt(duration, 10) || 210;
      const step = rawLines.length > 0 ? Math.max(3, Math.floor(totalDur / rawLines.length)) : 5;
      const lines = rawLines.map((text, idx) => ({
        seconds: Math.min(idx * step, totalDur - 4),
        text
      }));
      return res.json({ synced: false, lines });
    }

    // 3. Fallback to radioactive11/the-lyrics-api
    const apiLyrics = await fetchTheLyricsApi(cleanArtist, cleanTitle, 'eng');
    if (apiLyrics && apiLyrics.length > 0) {
      const rawLines = apiLyrics.split('\n').map(l => l.trim()).filter(Boolean);
      const totalDur = parseInt(duration, 10) || 210;
      const step = rawLines.length > 0 ? Math.max(3, Math.floor(totalDur / rawLines.length)) : 5;
      const lines = rawLines.map((text, idx) => ({
        seconds: Math.min(idx * step, totalDur - 4),
        text
      }));
      return res.json({ synced: false, lines, source: 'the-lyrics-api' });
    }

    // Fallback friendly message with song metadata
    res.json({
      synced: false,
      lines: [
        { seconds: 4, text: `♪ Now Playing: ${title} ♪` },
        { seconds: 12, text: `Artist: ${artist || 'Various Artists'}` },
        { seconds: 24, text: "Lyrics synced with Soundifly Real-Time Engine" },
        { seconds: 40, text: "Enjoy the music together with friends ❤️" }
      ]
    });
  } catch (err) {
    console.error('Lyrics error:', err);
    res.json({ synced: false, lines: [] });
  }
});

app.listen(PORT, () => {
  console.log(`🚀 Soundifly YouTube Music API Server running at http://localhost:${PORT}`);
});
