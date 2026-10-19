import pkg from 'youtube-sr';
const YouTube = pkg.default || pkg;

async function test() {
  try {
    const results = await YouTube.search('Shironamhin Hasimukh', { limit: 5, type: 'video' });
    console.log('Search count:', results.length);
    if (results.length > 0) {
      const v = results[0];
      console.log('Title:', v.title);
      console.log('Channel:', v.channel ? v.channel.name : 'N/A');
      console.log('Duration:', v.durationFormatted);
      console.log('Thumbnail:', v.thumbnail ? v.thumbnail.url : 'N/A');
      console.log('ID:', v.id);
    }

    const suggestions = await YouTube.getSuggestions('Arijit');
    console.log('Suggestions:', suggestions);
  } catch (err) {
    console.error('Error:', err);
  }
}

test();
