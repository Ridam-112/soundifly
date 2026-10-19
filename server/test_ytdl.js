import ytdl from '@distube/ytdl-core';

async function test() {
  try {
    const videoId = '60M4NlUuSD0';
    console.log('Fetching info for:', videoId);
    const info = await ytdl.getInfo(videoId);
    const format = ytdl.chooseFormat(info.formats, { quality: 'highestaudio', filter: 'audioonly' });
    console.log('Success! Audio URL found:');
    console.log(format.url ? format.url.substring(0, 100) : 'no url');
  } catch (e) {
    console.error('ytdl error:', e);
  }
}

test();
