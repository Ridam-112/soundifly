async function testWebRemix() {
  const url = 'https://music.youtube.com/youtubei/v1/player?prettyPrint=false';
  const body = {
    context: {
      client: {
        clientName: 'WEB_REMIX',
        clientVersion: '1.20240101.01.00',
        hl: 'en',
        gl: 'US'
      }
    },
    videoId: 'NJAv_7lHUIU'
  };

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

  console.log('WebRemix status:', res.status);
  const data = await res.json();
  console.log('playabilityStatus:', data.playabilityStatus?.status);
  const formats = data.streamingData?.adaptiveFormats || [];
  const audio = formats.filter(f => f.mimeType && f.mimeType.includes('audio'));
  console.log('Audio formats:', audio.length);
  if (audio.length > 0) {
    console.log('Has URL:', !!audio[0].url);
    console.log('Has signatureCipher:', !!audio[0].signatureCipher);
    if (audio[0].url) {
      console.log('DIRECT URL:', audio[0].url.substring(0, 100));
    }
  }
}

testWebRemix();
