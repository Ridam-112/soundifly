function parseLrc(lrcText) {
  const lines = lrcText.split('\n');
  const result = [];
  const regex = /\[(\d{2}):(\d{2}(?:\.\d+)?)\](.*)/;

  for (const line of lines) {
    const match = line.match(regex);
    if (match) {
      const minutes = parseInt(match[1], 10);
      const seconds = parseFloat(match[2]);
      const totalSeconds = Math.floor(minutes * 60 + seconds);
      const text = match[3].trim();
      if (text.length > 0) {
        result.push({ seconds: totalSeconds, text });
      }
    }
  }
  return result;
}

const sample = `
[00:09.44] मुझको इतना बताए कोई
[00:19.02] कैसे तुझसे दिल ना लगाए कोई?
[00:29.91] रब्बा ने तुझको बनाने में
`;

console.log(parseLrc(sample));
