async function testIOS() {
  const url = 'https://www.youtube.com/youtubei/v1/player?prettyPrint=false';
  const body = {
    context: {
      client: {
        clientName: 'IOS',
        clientVersion: '19.29.1',
        deviceModel: 'iPhone16,2',
        userAgent: 'com.google.ios.youtube/19.29.1 (iPhone16,2; U; CPU iOS 17_5_1 like Mac OS X; en_US)',
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
      'User-Agent': 'com.google.ios.youtube/19.29.1 (iPhone16,2; U; CPU iOS 17_5_1 like Mac OS X; en_US)'
    },
    body: JSON.stringify(body)
  });

  console.log('IOS Status:', res.status);
  const data = await res.json();
  console.log('playabilityStatus:', data.playabilityStatus?.status);
  const formats = data.streamingData?.adaptiveFormats || [];
  const audio = formats.filter(f => f.mimeType && f.mimeType.includes('audio'));
  console.log('Audio formats:', audio.length);
  if (audio.length > 0 && audio[0].url) {
    console.log('DIRECT AUDIO URL FOUND!', audio[0].url.substring(0, 80));
  }
}

testIOS();
