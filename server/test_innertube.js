async function testInnertube() {
  const url = 'https://music.youtube.com/youtubei/v1/search?prettyPrint=false';
  const body = {
    context: {
      client: {
        clientName: 'WEB_REMIX',
        clientVersion: '1.20240101.01.00',
        hl: 'en',
        gl: 'US'
      }
    },
    query: 'Arijit Singh',
    params: 'EgWKAQIIAWoKEAoQCRADEAQQBQ%3D%3D' // filter for songs
  };

  try {
    const res = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Origin': 'https://music.youtube.com',
        'Referer': 'https://music.youtube.com/'
      },
      body: JSON.stringify(body)
    });

    console.log('Status:', res.status);
    if (res.ok) {
      const data = await res.json();
      console.log('Innertube response received! Keys:', Object.keys(data));
      const contents = data.contents?.tabbedSearchResultsRenderer?.tabs?.[0]?.tabRenderer?.content?.sectionListRenderer?.contents;
      console.log('Sections found:', contents ? contents.length : 0);
    }
  } catch (err) {
    console.error('Fetch err:', err);
  }
}

testInnertube();
