async function testBangla() {
  const searchUrl = `https://lrclib.net/api/search?q=${encodeURIComponent('Hasimukh Shironamhin')}`;
  const res = await fetch(searchUrl, {
    headers: { 'User-Agent': 'Soundifly Music App v1.0.0' }
  });
  const list = await res.json();
  console.log('Bangla matches:', list.length);
  if (list.length > 0) {
    const item = list[0];
    console.log('Found:', item.trackName, item.artistName);
    console.log('Synced:', !!item.syncedLyrics);
    console.log('Plain:', !!item.plainLyrics);
    if (item.plainLyrics) {
      console.log(item.plainLyrics.split('\n').slice(0, 4).join('\n'));
    }
  }
}

testBangla();
