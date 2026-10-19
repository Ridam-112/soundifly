async function testJioSaavnLyrics() {
  const query = 'Hasimukh Shironamhin';
  const searchUrl = `https://www.jiosaavn.com/api.php?__call=autocomplete.get&_format=json&_marker=0&includeMetaTags=1&query=${encodeURIComponent(query)}`;

  console.log('Testing JioSaavn lyrics search for:', query);
  try {
    const sRes = await fetch(searchUrl, {
      headers: { 'User-Agent': 'Mozilla/5.0' }
    });
    const sData = await sRes.json();
    const songs = sData.songs?.data || [];
    console.log('Songs found on JioSaavn:', songs.length);

    if (songs.length > 0) {
      const songId = songs[0].id;
      console.log('Song title:', songs[0].title, 'Song ID:', songId);

      const lyricsUrl = `https://www.jiosaavn.com/api.php?__call=lyrics.getLyrics&ctx=web6dot0&_format=json&_marker=0&lyrics_id=${songId}`;
      const lRes = await fetch(lyricsUrl, {
        headers: { 'User-Agent': 'Mozilla/5.0' }
      });
      const lData = await lRes.json();
      console.log('JioSaavn lyrics status:', lData.status);
      console.log('JioSaavn lyrics preview:');
      console.log(lData.lyrics?.replace(/<br\s*\/?>/gi, '\n').substring(0, 300));
    }
  } catch (err) {
    console.error('JioSaavn error:', err);
  }
}

testJioSaavnLyrics();
