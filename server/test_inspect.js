async function inspectItems() {
  const url = 'https://music.youtube.com/youtubei/v1/search?prettyPrint=false';
  const body = {
    context: {
      client: {
        clientName: 'WEB_REMIX',
        clientVersion: '1.20240101.01.00',
        hl: 'en',
        gl: 'US'
      }
    },
    query: 'Arijit Singh Kesariya',
    params: 'EgWKAQIIAWoKEAoQCRADEAQQBQ%3D%3D' // songs filter
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

  const data = await res.json();
  const section = data.contents?.tabbedSearchResultsRenderer?.tabs?.[0]?.tabRenderer?.content?.sectionListRenderer?.contents?.[0];
  const items = section?.musicShelfRenderer?.contents || [];
  console.log('Total songs found:', items.length);

  if (items.length > 0) {
    const item = items[0].musicResponsiveListItemRenderer;
    const title = item.flexColumns[0]?.musicResponsiveListItemFlexColumnRenderer?.title?.runs?.[0]?.text;
    const artist = item.flexColumns[1]?.musicResponsiveListItemFlexColumnRenderer?.title?.runs?.[0]?.text;
    const thumbnails = item.thumbnail?.musicThumbnailRenderer?.thumbnail?.thumbnails;
    const thumb = thumbnails?.[thumbnails.length - 1]?.url;
    const videoId = item.playlistItemData?.videoId;
    console.log({ title, artist, thumb, videoId });
  }
}

inspectItems();
