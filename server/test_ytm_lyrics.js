async function testYtmLyrics() {
  const videoId = '60M4NlUuSD0'; // Shironamhin Hashimukh
  console.log('Testing YouTube Music native lyrics for:', videoId);

  // Step 1: get_watch_playlist / next endpoint
  const nextUrl = 'https://music.youtube.com/youtubei/v1/next?prettyPrint=false';
  const body = {
    context: {
      client: {
        clientName: 'WEB_REMIX',
        clientVersion: '1.20240101.01.00',
        hl: 'en',
        gl: 'US'
      }
    },
    videoId: videoId
  };

  try {
    const res = await fetch(nextUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
        'Origin': 'https://music.youtube.com',
        'Referer': 'https://music.youtube.com/'
      },
      body: JSON.stringify(body)
    });

    const data = await res.json();
    const tabs = data.contents?.singleColumnMusicWatchNextResultsRenderer?.tabbedRenderer?.watchNextTabbedResultsRenderer?.tabs;
    console.log('Tabs available:', tabs ? tabs.length : 0);

    const lyricsTab = tabs?.find(t => t.tabRenderer?.title?.runs?.[0]?.text?.toLowerCase() === 'lyrics' || t.tabRenderer?.endpoint?.browseEndpoint?.browseId);
    const browseId = lyricsTab?.tabRenderer?.endpoint?.browseEndpoint?.browseId;
    console.log('Lyrics browseId:', browseId);

    if (browseId) {
      // Step 2: fetch lyrics browse endpoint
      const browseUrl = 'https://music.youtube.com/youtubei/v1/browse?prettyPrint=false';
      const bRes = await fetch(browseUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
          'Origin': 'https://music.youtube.com',
          'Referer': 'https://music.youtube.com/'
        },
        body: JSON.stringify({
          context: body.context,
          browseId: browseId
        })
      });

      const bData = await bRes.json();
      const lyricsText = bData.contents?.sectionListRenderer?.contents?.[0]?.musicDescriptionShelfRenderer?.description?.runs?.[0]?.text;
      console.log('YOUTUBE MUSIC NATIVE LYRICS FOUND:');
      console.log(lyricsText?.substring(0, 200));
    }
  } catch (err) {
    console.error('YTM lyrics error:', err);
  }
}

testYtmLyrics();
