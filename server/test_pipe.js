import https from 'https';

async function testFetchStream() {
  const videoUrl = 'https://rr2---sn-ci5gup-jj0ee.googlevideo.com/videoplayback?expire=1791993976&ei=GFTParfoIefKssUPk6qC6Ak&ip=2401%3A4900%3A1c01%3A957d%3A7500%3A71f5%3A8d2f%3A3a21&id=o-AKidKklXWi2Ky3BWLa3EsOtTyIidllY79VxauNkB0F-M&itag=251&source=youtube&requiressl=yes&xpc=EgVo2aDSNQ%3D%3D&cps=441&met=1791972376%2C&mh=DJ&mm=31%2C29&mn=sn-ci5gup-jj0ee%2Csn-h5576nee&ms=au%2Crdu&mv=m&mvi=2&pl=48&rms=au%2Cau&gcr=in&initcwndbps=1940250&bui=AWzQHwrm83Nb_AR-yW2oyOegLIBItmJvB8wBP4g3rpEmVGopZ8K7Y7D4pr6V9tmZEPc1QYnn_EaYFUPU&spc=mpRQ_8m0j639iQzge5qxkVehV0I4wAh8BM5ZzS-U8RNMJ8QLWWEP1B3qlVHI&vprv=1&svpuc=1&mime=audio%2Fwebm&rqh=1&gir=yes&clen=6384639&dur=356.581&lmt=1759625765305835&mt=1791971822&fvip=2&keepalive=yes&fexp=51565116%2C52184231&c=VISIONOS&txp=1432534&sparams=expire%2Cei%2Cip%2Cid%2Citag%2Csource%2Crequiressl%2Cxpc%2Cgcr%2Cbui%2Cspc%2Cvprv%2Csvpuc%2Cmime%2Crqh%2Cgir%2Cclen%2Cdur%2Clmt&sig=AE0s2JYwRQIgAvLBon-9kyN1vZ_xhFffhhny1pprWwJlnC3wRNm7yEgCIQCxt4ZLkHUKxzx73XxyIrsSBr8bQECcYv7vvuftsi3Nig%3D%3D&lsparams=cps%2Cmet%2Cmh%2Cmm%2Cmn%2Cms%2Cmv%2Cmvi%2Cpl%2Crms%2Cinitcwndbps&lsig=APaTxxMwRgIhANQt5Zx57XFo7I63jasG7z4bXTNlN0nuH_FoKBGc4n8EAiEA2npTLzVFZRkgP4qhd7PBpJHYtgYgxX42_MuvAg7EIXk%3D';

  const req = https.get(videoUrl, (res) => {
    console.log('Status:', res.statusCode);
    console.log('Headers:', res.headers['content-type'], res.headers['content-length']);
    res.destroy();
  });

  req.on('error', (e) => console.error('Error:', e));
}

testFetchStream();
