async function testPlayer() {
  const url = 'https://www.youtube.com/youtubei/v1/player?prettyPrint=false';
  const body = {
    context: {
      client: {
        clientName: 'ANDROID',
        clientVersion: '19.09.37',
        androidSdkVersion: 30,
        hl: 'en',
        gl: 'US'
      }
    },
    videoId: 'NJAv_7lHUIU'
  };

  try {
    const res = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'com.google.android.youtube/19.09.37 (Linux; U; Android 11) gzip'
      },
      body: JSON.stringify(body)
    });

    console.log('Player status:', res.status);
    const data = await res.json();
    console.log('playabilityStatus:', data.playabilityStatus?.status);

    const formats = data.streamingData?.adaptiveFormats || [];
    console.log('Adaptive formats count:', formats.length);
    const audioFormats = formats.filter(f => f.mimeType && f.mimeType.includes('audio'));
    console.log('Audio formats count:', audioFormats.length);

    if (audioFormats.length > 0) {
      const best = audioFormats[0];
      console.log('Best audio format:');
      console.log('Mime:', best.mimeType);
      console.log('Bitrate:', best.bitrate);
      console.log('Has direct URL:', !!best.url);
      if (best.url) {
        console.log('URL preview:', best.url.substring(0, 100));
        // Test if URL is accessible
        const head = await fetch(best.url, { method: 'HEAD' });
        console.log('Stream HEAD status:', head.status, head.headers.get('content-type'), head.headers.get('content-length'));
      }
    }
  } catch (err) {
    console.error('Player error:', err);
  }
}

testPlayer();
