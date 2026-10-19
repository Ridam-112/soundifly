async function checkFlex() {
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
    params: 'EgWKAQIIAWoKEAoQCRADEAQQBQ%3D%3D'
  };

  const res = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
      'Origin': 'https://music.youtube.com',
      'Referer': 'https://music.youtube.com/'
    },
    body: JSON.stringify(body)
  });

  const data = await res.json();
  const section = data.contents?.tabbedSearchResultsRenderer?.tabs?.[0]?.tabRenderer?.content?.sectionListRenderer?.contents?.[0];
  const item = section?.musicShelfRenderer?.contents?.[0]?.musicResponsiveListItemRenderer;
  console.log('Flex 0:', JSON.stringify(item?.flexColumns?.[0], null, 2));
  console.log('Flex 1:', JSON.stringify(item?.flexColumns?.[1], null, 2));
}

checkFlex();
