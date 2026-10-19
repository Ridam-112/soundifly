async function testSuggestions() {
  const url = 'https://music.youtube.com/youtubei/v1/music/get_search_suggestions?prettyPrint=false';
  const body = {
    context: {
      client: {
        clientName: 'WEB_REMIX',
        clientVersion: '1.20240101.01.00',
        hl: 'en',
        gl: 'US'
      }
    },
    input: 'shironamhin'
  };

  const res = await fetch(url, {
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
  const contents = data.contents?.[0]?.searchSuggestionsSectionRenderer?.contents || [];
  const suggestions = contents.map(c => {
    const runs = c.searchSuggestionRenderer?.suggestion?.runs || [];
    return runs.map(r => r.text).join('');
  });
  console.log('Suggestions:', suggestions);
}

testSuggestions();
