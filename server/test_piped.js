async function testPiped() {
  const instances = [
    'https://api.piped.private.coffee',
    'https://pipedapi.tokhmi.xyz',
    'https://pipedapi.kavin.rocks',
    'https://invidious.nerdvpn.de/api/v1',
  ];

  for (const inst of instances) {
    try {
      console.log('Testing instance:', inst);
      const isInv = inst.includes('invidious');
      const url = isInv ? `${inst}/videos/60M4NlUuSD0` : `${inst}/streams/60M4NlUuSD0`;
      const res = await fetch(url, { headers: { 'User-Agent': 'Mozilla/5.0' }, signal: AbortSignal.timeout(5000) });
      if (res.ok) {
        const data = await res.json();
        console.log('Success with:', inst);
        if (data.audioStreams && data.audioStreams.length > 0) {
          console.log('Piped audio stream URL found:', data.audioStreams[0].url.substring(0, 80));
          return;
        } else if (data.adaptiveFormats) {
          const audio = data.adaptiveFormats.find(f => f.type && f.type.startsWith('audio'));
          if (audio) {
            console.log('Invidious audio stream found:', audio.url.substring(0, 80));
            return;
          }
        }
      } else {
        console.log('Status not ok:', res.status);
      }
    } catch (e) {
      console.log('Failed instance:', inst, e.message);
    }
  }
}

testPiped();
