async function testAZLyrics(artist, song) {
  const aname = artist.toLowerCase().replace(/[^a-z0-9]/g, '');
  const sname = song.toLowerCase().replace(/[^a-z0-9]/g, '');
  const url = `https://www.azlyrics.com/lyrics/${aname}/${sname}.html`;
  console.log('Testing AZLyrics for:', url);

  try {
    const res = await fetch(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      }
    });

    console.log('Status:', res.status);
    if (res.ok) {
      const html = await res.text();
      const marker = '<!-- Usage of azlyrics.com content by any third-party lyrics provider is prohibited by our licensing agreement. Sorry about that. -->';
      const parts = html.split(marker);
      if (parts.length > 1) {
        const lyricPart = parts[1].split('</div>')[0].trim();
        const clean = lyricPart.replace(/<br\s*\/?>/gi, '\n').replace(/<.*?>/g, '').trim();
        console.log('LYRICS FOUND via the-lyrics-api logic:');
        console.log(clean.substring(0, 200));
        return clean;
      }
    }
  } catch (e) {
    console.error('AZLyrics error:', e);
  }
  return null;
}

testAZLyrics('Taylor Swift', 'Blank Space');
