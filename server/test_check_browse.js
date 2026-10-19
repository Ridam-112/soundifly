async function checkBrowseLyrics() {
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
      context: {
        client: {
          clientName: 'WEB_REMIX',
          clientVersion: '1.20240101.01.00',
          hl: 'en',
          gl: 'US'
        }
      },
      browseId: 'MPLYt_sf68wn6dpiY'
    })
  });

  const bData = await bRes.json();
  console.log('bData keys:', Object.keys(bData));
  console.log('contents:', JSON.stringify(bData.contents, null, 2).substring(0, 500));
}

checkBrowseLyrics();
