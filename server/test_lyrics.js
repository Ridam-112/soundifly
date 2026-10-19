async function testLyrics() {
  const track = 'Kesariya';
  const artist = 'Arijit Singh';
  const url = `https://lrclib.net/api/get?artist_name=${encodeURIComponent(artist)}&track_name=${encodeURIComponent(track)}`;

  console.log('Fetching lyrics from LRCLIB for:', track, artist);
  try {
    const res = await fetch(url, {
      headers: { 'User-Agent': 'Soundifly Music App v1.0.0 (https://github.com/soundifly)' }
    });

    console.log('Status:', res.status);
    if (res.ok) {
      const data = await res.json();
      console.log('Title:', data.trackName);
      console.log('Artist:', data.artistName);
      console.log('Has synced lyrics:', !!data.syncedLyrics);
      if (data.syncedLyrics) {
        console.log('First 3 lines of synced lyrics:');
        console.log(data.syncedLyrics.split('\n').slice(0, 5).join('\n'));
      }
    } else {
      console.log('Direct get failed, testing search fallback...');
      const searchUrl = `https://lrclib.net/api/search?q=${encodeURIComponent(track + ' ' + artist)}`;
      const sRes = await fetch(searchUrl, {
        headers: { 'User-Agent': 'Soundifly Music App v1.0.0' }
      });
      const list = await sRes.json();
      console.log('Search matches:', list.length);
      if (list.length > 0) {
        console.log('Found synced:', !!list[0].syncedLyrics);
        if (list[0].syncedLyrics) {
          console.log(list[0].syncedLyrics.split('\n').slice(0, 5).join('\n'));
        }
      }
    }
  } catch (e) {
    console.error('Error fetching lyrics:', e);
  }
}

testLyrics();
