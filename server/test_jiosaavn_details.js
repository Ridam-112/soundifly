async function testDetails() {
  const songId = 't5yMuIxP';
  const url = `https://www.jiosaavn.com/api.php?__call=song.getDetails&pids=${songId}&_format=json`;
  const res = await fetch(url);
  const data = await res.json();
  console.log('Details for t5yMuIxP:', Object.keys(data[songId]));
  console.log('has_lyrics:', data[songId]?.has_lyrics);
}

testDetails();
