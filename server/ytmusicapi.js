/**
 * JavaScript implementation of sigma67/ytmusicapi (https://github.com/sigma67/ytmusicapi)
 * Directly implements YouTube Music Innertube API protocols used by sigma67/ytmusicapi.
 */

const YTM_BASE_URL = 'https://music.youtube.com/youtubei/v1';

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
    gl: 'IN'
  }
};

// Exact search param filters from sigma67/ytmusicapi
export const YTM_FILTER_PARAMS = {
  songs: 'EgWKAQIIAWoKEAoQCRADEAQQBQ%3D%3D',
  videos: 'EgWKAQIICWoKEAoQCRADEAQQBQ%3D%3D',
  albums: 'EgWKAQIBAWoKEAoQCRADEAQQBQ%3D%3D',
  artists: 'EgWKAQIgAWoKEAoQCRADEAQQBQ%3D%3D',
  playlists: 'EgWKAQIQAWoKEAoQCRADEAQQBQ%3D%3D'
};

function cleanText(text) {
  if (!text) return '';
  return text
    .replace(/&quot;/g, '"')
    .replace(/&#039;/g, "'")
    .replace(/&amp;/g, '&')
    .trim();
}

/**
 * Searches YouTube Music following sigma67/ytmusicapi specification
 * @param {string} query Search text
 * @param {'songs'|'videos'|'albums'|'artists'|null} filter Category filter (null = all)
 */
export async function search(query, filter = 'songs') {
  if (!query || !query.trim()) return [];

  const body = {
    context: YTM_CONTEXT,
    query: query.trim()
  };

  if (filter && YTM_FILTER_PARAMS[filter]) {
    body.params = YTM_FILTER_PARAMS[filter];
  }

  try {
    const res = await fetch(`${YTM_BASE_URL}/search?prettyPrint=false`, {
      method: 'POST',
      headers: YTM_HEADERS,
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(6000)
    });

    if (!res.ok) return [];
    const data = await res.json();
    const tabs = data.contents?.tabbedSearchResultsRenderer?.tabs || [];
    const contents = tabs[0]?.tabRenderer?.content?.sectionListRenderer?.contents || [];

    const results = [];

    for (const sec of contents) {
      // 1. Top Result Card (musicCardShelfRenderer)
      if (sec.musicCardShelfRenderer) {
        const card = sec.musicCardShelfRenderer;
        const title = cleanText(card.title?.runs?.[0]?.text);
        const subtitleRuns = card.subtitle?.runs || [];
        const artist = cleanText(subtitleRuns[2]?.text || subtitleRuns[0]?.text || 'Artist');
        const videoId = card.onTap?.watchEndpoint?.videoId || 
                        card.buttons?.[0]?.buttonRenderer?.command?.watchEndpoint?.videoId;
        const thumbs = card.thumbnail?.musicThumbnailRenderer?.thumbnail?.thumbnails || [];
        const thumb = thumbs.length > 0 ? thumbs[thumbs.length - 1].url : '';

        if (title && videoId) {
          results.push({
            id: videoId,
            title,
            artist,
            album: 'Top Result',
            coverUrl: thumb,
            durationSeconds: 210,
            durationFormatted: '3:30',
            source: 'ytmusicapi (Top Result)'
          });
        }
      }

      // 2. Filtered Shelf (musicShelfRenderer)
      if (sec.musicShelfRenderer) {
        const items = sec.musicShelfRenderer.contents || [];
        for (const item of items) {
          const parsed = parseMusicListItem(item.musicResponsiveListItemRenderer);
          if (parsed) results.push(parsed);
        }
      }

      // 3. Section items (itemSectionRenderer)
      if (sec.itemSectionRenderer) {
        const items = sec.itemSectionRenderer.contents || [];
        for (const item of items) {
          const parsed = parseMusicListItem(item.musicResponsiveListItemRenderer);
          if (parsed) results.push(parsed);
        }
      }
    }

    return results;
  } catch (err) {
    console.error('[ytmusicapi] search error:', err.message);
    return [];
  }
}

function parseMusicListItem(r) {
  if (!r) return null;

  const title = cleanText(r.flexColumns?.[0]?.musicResponsiveListItemFlexColumnRenderer?.text?.runs?.[0]?.text);
  if (!title) return null;

  const flex1Runs = r.flexColumns?.[1]?.musicResponsiveListItemFlexColumnRenderer?.text?.runs || [];
  const artist = cleanText(flex1Runs[0]?.text || 'Various Artists');

  let album = 'Single';
  let durationStr = '3:30';

  for (let i = 1; i < flex1Runs.length; i++) {
    const text = flex1Runs[i].text?.trim() || '';
    if (text === '•' || !text) continue;
    if (/^\d+:\d+$/.test(text)) {
      durationStr = text;
    } else if (text.length > 1) {
      album = cleanText(text);
    }
  }

  const videoId = r.playlistItemData?.videoId || 
                  r.flexColumns?.[0]?.musicResponsiveListItemFlexColumnRenderer?.text?.runs?.[0]?.navigationEndpoint?.watchEndpoint?.videoId;
  if (!videoId) return null;

  const thumbs = r.thumbnail?.musicThumbnailRenderer?.thumbnail?.thumbnails || [];
  const thumb = thumbs.length > 0 ? thumbs[thumbs.length - 1].url : '';

  const durParts = durationStr.split(':').map(Number);
  const durationSeconds = durParts.length === 2 ? durParts[0] * 60 + durParts[1] : 210;

  return {
    id: videoId,
    title,
    artist,
    album,
    coverUrl: thumb,
    durationSeconds,
    durationFormatted: durationStr,
    source: 'ytmusicapi'
  };
}

/**
 * Searches artists on YouTube Music following ytmusicapi
 */
export async function searchArtists(query) {
  if (!query || !query.trim()) return [];

  try {
    const res = await fetch(`${YTM_BASE_URL}/search?prettyPrint=false`, {
      method: 'POST',
      headers: YTM_HEADERS,
      body: JSON.stringify({
        context: YTM_CONTEXT,
        query: query.trim(),
        params: YTM_FILTER_PARAMS.artists
      }),
      signal: AbortSignal.timeout(5000)
    });

    if (!res.ok) return [];
    const data = await res.json();
    const section = data.contents?.tabbedSearchResultsRenderer?.tabs?.[0]?.tabRenderer?.content?.sectionListRenderer?.contents?.[0];
    const items = section?.musicShelfRenderer?.contents || [];

    return items.map(item => {
      const r = item.musicResponsiveListItemRenderer;
      if (!r) return null;

      const name = cleanText(r.flexColumns?.[0]?.musicResponsiveListItemFlexColumnRenderer?.text?.runs?.[0]?.text);
      if (!name) return null;

      const subtitleRuns = r.flexColumns?.[1]?.musicResponsiveListItemFlexColumnRenderer?.text?.runs || [];
      const subtitle = subtitleRuns.map(run => run.text).join('');

      const browseId = r.navigationEndpoint?.browseEndpoint?.browseId || 
                       r.flexColumns?.[0]?.musicResponsiveListItemFlexColumnRenderer?.text?.runs?.[0]?.navigationEndpoint?.browseEndpoint?.browseId ||
                       `ytm_${name.hashCode}`;

      const thumbs = r.thumbnail?.musicThumbnailRenderer?.thumbnail?.thumbnails || [];
      const thumb = thumbs.length > 0 ? thumbs[thumbs.length - 1].url : '';

      return {
        id: `ytm_${browseId}`,
        name,
        imageUrl: thumb,
        popularity: 5000,
        artistType: subtitle.includes('Artist') ? 'Verified Artist' : 'Artist',
        imageSource: 'YouTube Music Official CDN'
      };
    }).filter(Boolean);
  } catch (e) {
    return [];
  }
}

/**
 * Gets up next / radio related tracks for autoplay
 */
export async function getWatchPlaylist(videoId) {
  if (!videoId) return [];

  try {
    const res = await fetch(`${YTM_BASE_URL}/next?prettyPrint=false`, {
      method: 'POST',
      headers: YTM_HEADERS,
      body: JSON.stringify({
        context: YTM_CONTEXT,
        videoId: videoId,
        isAudioOnly: true
      }),
      signal: AbortSignal.timeout(5000)
    });

    if (!res.ok) return [];
    const data = await res.json();
    const tabs = data.contents?.singleColumnMusicWatchNextResultsRenderer?.tabbedRenderer?.watchNextTabbedResultsRenderer?.tabs || [];
    const queueRenderer = tabs[0]?.tabRenderer?.content?.musicQueueRenderer;
    const items = queueRenderer?.content?.playlistPanelRenderer?.contents || [];

    const tracks = [];
    for (const item of items) {
      const r = item.playlistPanelVideoRenderer;
      if (!r || !r.videoId) continue;

      const title = cleanText(r.title?.runs?.[0]?.text);
      const artist = cleanText(r.longBylineText?.runs?.[0]?.text || 'Various Artists');
      const durationStr = r.lengthText?.runs?.[0]?.text || '3:30';
      const thumbs = r.thumbnail?.thumbnails || [];
      const thumb = thumbs.length > 0 ? thumbs[thumbs.length - 1].url : '';

      const durParts = durationStr.split(':').map(Number);
      const durationSeconds = durParts.length === 2 ? durParts[0] * 60 + durParts[1] : 210;

      tracks.push({
        id: r.videoId,
        title,
        artist,
        album: 'YouTube Music Radio',
        coverUrl: thumb,
        durationSeconds,
        durationFormatted: durationStr,
        source: 'ytmusicapi Radio'
      });
    }

    return tracks;
  } catch (e) {
    return [];
  }
}
