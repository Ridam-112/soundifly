import playdl from 'play-dl';

async function testAudio() {
  try {
    const videoId = '60M4NlUuSD0';
    console.log('Fetching stream for video:', videoId);
    const stream = await playdl.stream(`https://www.youtube.com/watch?v=${videoId}`);
    console.log('Stream type:', stream.type);
    console.log('Stream url exists:', !!stream.url);
  } catch (e) {
    console.error('play-dl error:', e);
  }
}

testAudio();
