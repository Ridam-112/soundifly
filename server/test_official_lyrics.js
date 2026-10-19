async function testOfficialLyrics() {
  const videoId = 'NJAv_7lHUIU'; // Kesariya
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
  const lyricsTab = tabs?.find(t => t.tabRenderer?.title?.runs?.[0]?.text?.toLowerCase() === 'lyrics');
  const browseId = lyricsTab?.tabRenderer?.endpoint?.browseEndpoint?.browseId;
  console.log('BrowseId for Kesariya:', browseId);

  if (browseId) {
    const bRes = await fetch('https://music.youtube.com/youtubei/v1/browse?prettyPrint=false', {
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
    const runs = bData.contents?.sectionListRenderer?.contents?.[0]?.musicDescriptionShelfRenderer?.description?.runs;
    console.log('Official lyrics preview:', runs?.[0]?.text?.substring(0, 150));
  }
}

testOfficialLyrics();
