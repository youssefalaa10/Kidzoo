// node tool/prepare_sorting_assets.cjs <sharp-module> <teeth-atlas> <weather-atlas> <laundry-atlas>
// Packs original generated illustrations as transparent, display-sized WebP.
const fs = require('fs');
const sharp = require(process.argv[2]);
const out = 'assets/gen/images/helpers';
const names = [
 ['sad_tooth','tooth','bread','grapes','broccoli','yogurt','tomato','soda','cupcake','lollipop','cake','cereal'],
 ['rain','sun','umbrella','boots','raincoat','rainhat','green_boots','sunhat','sunglasses','sunscreen','fan','ball'],
 ['washer','wardrobe','dirty_yellow_shirt','dirty_green_shorts','dirty_blue_shorts','dirty_pink_shirt','dirty_white_shirt','blue_shorts','white_shirt','green_shorts','yellow_shirt','pink_shirt'],
];
async function split(file, ids) {
 const {data, info:{width,height,channels}}=await sharp(file).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 const seen=new Uint8Array(width*height),queue=new Int32Array(width*height);
 const bounds=ids.map(()=>({l:width,t:height,r:0,b:0}));
 // Locate connected silhouettes rather than cutting fixed tiles through hats,
 // arms or sunglasses that extend slightly beyond the atlas's invisible grid.
 for(let p=0;p<width*height;p++) {
  if(seen[p]||data[p*channels+3]<24) continue;
  let head=0,tail=1,l=width,t=height,r=0,b=0,sx=0,sy=0;queue[0]=p;seen[p]=1;
  while(head<tail){const q=queue[head++],x=q%width,y=Math.floor(q/width);
   l=Math.min(l,x);t=Math.min(t,y);r=Math.max(r,x);b=Math.max(b,y);sx+=x;sy+=y;
   for(const n of [x>0?q-1:-1,x<width-1?q+1:-1,y>0?q-width:-1,y<height-1?q+width:-1])
    if(n>=0&&!seen[n]&&data[n*channels+3]>=24){seen[n]=1;queue[tail++]=n;}
  }
  if(tail<16)continue;
  const i=Math.min(2,Math.floor(sy/tail/(height/3)))*4+Math.min(3,Math.floor(sx/tail/(width/4)));
  const box=bounds[i];box.l=Math.min(box.l,l);box.t=Math.min(box.t,t);box.r=Math.max(box.r,r);box.b=Math.max(box.b,b);
 }
 for(let i=0;i<ids.length;i++){
  const box=bounds[i];if(box.r<=box.l)throw Error(`Missing sprite ${ids[i]}`);
  const left=Math.max(0,box.l-2),top=Math.max(0,box.t-2);
  await sharp(file).extract({left,top,width:Math.min(width-left,box.r-left+3),height:Math.min(height-top,box.b-top+3)})
   .resize(i<2?440:240,i<2?440:240,{fit:'inside',withoutEnlargement:true})
   .webp({quality:91,alphaQuality:100,effort:6}).toFile(`${out}/${ids[i]}.webp`);
 }
}
const tx=(en,ar)=>({en,ar});
function content(){
 for(const theme of ['teeth','weather','laundry']){
  const file=`assets/adventures/activities/helpers_${theme}.json`;
  const pfile=`assets/adventures/packs/helpers_${theme}.json`;
  const spec=JSON.parse(fs.readFileSync(file)),pack=JSON.parse(fs.readFileSync(pfile));
  pack.items.forEach(i=>i.image=i.image.replace(/\.png$/,'.webp'));
  spec.payload.bins.forEach(b=>b.image=b.image.replace(/\.png$/,'.webp'));
  if(theme==='teeth')spec.payload.bins.sort((a)=>a.id==='treat'?-1:1);
  if(theme==='weather'&&!pack.items.some(i=>i.id==='green_boots'))pack.items.splice(4,0,{
   id:'green_boots',image:`${out}/green_boots.webp`,label:tx('Green rain boots','حِذَاءُ مَطَرٍ أَخْضَرُ'),attributes:{destination:'rainy',size:'same'}});
  const order=theme==='laundry'?names[2].slice(2):theme==='teeth'?names[0].slice(2):names[1].slice(2);
  pack.items.sort((a,b)=>order.indexOf(a.id)-order.indexOf(b.id));
  spec.payload.itemsPerRound=10;spec.adaptation={min:10,max:10};
  spec.worksheet={
   prompt:theme==='teeth'?tx('Drag each food to its tooth.','اِسْحَبْ كُلَّ طَعَامٍ إِلَى السِّنِّ المُنَاسِبَةِ.'):
    theme==='weather'?tx('Rain or shine? Sort the pictures.','مَطَرٌ أَمْ شَمْسٌ؟ رَتِّبِ الصُّوَرَ.'):
    tx('Sort the dirty and clean clothes.','رَتِّبِ المَلَابِسَ المُتَّسِخَةَ وَالنَّظِيفَةَ.'),
   retry:tx('Try the other box. You can do it!','جَرِّبِ الصُّنْدُوقَ الآخَرَ. أَنْتَ تَسْتَطِيعُ!'),
   correct:theme==='teeth'?{everyday:tx('An everyday food. Well done!','طَعَامٌ يَوْمِيٌّ. أَحْسَنْتَ!'),treat:tx('A sugary treat. Just sometimes.','حَلْوَى مُحَلَّاةٌ. نَأْكُلُهَا أَحْيَانًا.')}:
    theme==='weather'?{rainy:tx('Ready for a rainy day!','جَاهِزٌ لِيَوْمٍ مُمْطِرٍ!'),sunny:tx('Ready for a sunny day!','جَاهِزٌ لِيَوْمٍ مُشْمِسٍ!')}:
    {dirty:tx('These clothes need washing.','هَذِهِ المَلَابِسُ تَحْتَاجُ إِلَى الغَسِيلِ.'),clean:tx('Clean clothes go in the wardrobe.','المَلَابِسُ النَّظِيفَةُ فِي الخِزَانَةِ.')},
  };
  spec.narration.success=theme==='teeth'?tx('All the foods are sorted! What a happy smile!','رَتَّبْتَ كُلَّ الطَّعَامِ! يَا لَهَا مِنِ ابْتِسَامَةٍ سَعِيدَةٍ!'):
   theme==='weather'?tx('All sorted! You are ready for rain or shine!','رَتَّبْتَ كُلَّ شَيْءٍ! أَنْتَ جَاهِزٌ لِلْمَطَرِ وَالشَّمْسِ!'):
   tx('All sorted! The clean clothes have a tidy home!','رَتَّبْتَ كُلَّ شَيْءٍ! المَلَابِسُ النَّظِيفَةُ فِي مَكَانِهَا!');
  fs.writeFileSync(file,JSON.stringify(spec,null,2)+'\n');
  fs.writeFileSync(pfile,JSON.stringify(pack,null,2)+'\n');
 }
}
function sounds(){
 const rate=22050;
 for(const theme of ['teeth','weather','laundry'])for(const cue of ['pick','retry','left','right','complete']){
  if(cue==='retry'&&theme!=='teeth')continue;
  const duration=cue==='complete'?1.12:cue==='pick'?0.17:cue==='retry'?0.28:0.46;
  const n=Math.floor(rate*duration),wav=Buffer.alloc(44+n*2);
  wav.write('RIFF');wav.writeUInt32LE(36+n*2,4);wav.write('WAVEfmt ',8);wav.writeUInt32LE(16,16);
  wav.writeUInt16LE(1,20);wav.writeUInt16LE(1,22);wav.writeUInt32LE(rate,24);wav.writeUInt32LE(rate*2,28);
  wav.writeUInt16LE(2,32);wav.writeUInt16LE(16,34);wav.write('data',36);wav.writeUInt32LE(n*2,40);
  let seed=91,filtered=0;
  for(let i=0;i<n;i++){
   const t=i/rate,env=Math.sin(Math.PI*i/n)**2;seed=(1664525*seed+1013904223)>>>0;
   const noise=seed/2147483648-1;filtered=.85*filtered+.15*noise;
   const note=(freq,start,len,amp)=>{const u=t-start;return u<0||u>len?0:amp*Math.sin(Math.PI*u/len)**.5*Math.exp(-6*u/len)*(Math.sin(2*Math.PI*freq*u)+.18*Math.sin(2*Math.PI*freq*2*u));};
   let v;
   if(cue==='complete')v=note(theme==='teeth'?523:theme==='weather'?587:659,0,.5,.32)+note(659,.2,.5,.28)+note(784,.4,.6,.27)+note(1047,.64,.48,.24);
   else if(cue==='retry')v=.14*env*filtered; // Gentle paper return; no buzzer.
   else if(theme==='laundry')v=cue==='pick'?.45*env*filtered:
    cue==='left'?note(145,0,.22,.19)+.22*env*filtered:note(420,0,.12,.20)+note(720,.09,.16,.13);
   else if(theme==='weather')v=cue==='pick'?.22*env*filtered+note(390,0,.1,.1):
    cue==='left'?note(840,0,.14,.20)+note(1160,.13,.15,.16)+note(980,.27,.17,.14):.15*env*filtered+note(784,0,.38,.16);
   else v=cue==='pick'?note(620,0,.15,.2):note(784,0,.24,.22)+note(cue==='right'?1175:988,.16,.28,.18);
   wav.writeInt16LE(Math.round(Math.max(-.85,Math.min(.85,v))*32767),44+i*2);
  }
  fs.writeFileSync(cue==='retry'?'assets/audio/sorting_return.wav':`assets/audio/sorting_${theme}_${cue}.wav`,wav);
 }
 // Inspect the old pickup's real RIFF encoding; it is intentionally not mapped
 // to any action in these games. Do not relabel or copy it as new audio.
 const old=fs.readFileSync('assets/audio/boop.wav');
 console.log('Old boop.wav:',old.subarray(0,4).toString(),old.length,'bytes; replaced with original quiet per-game cues.');
}
(async()=>{for(let i=0;i<3;i++)await split(process.argv[i+3],names[i]);content();sounds();
 const bytes=fs.readdirSync(out).filter(n=>n.endsWith('.webp')).reduce((n,f)=>n+fs.statSync(`${out}/${f}`).size,0);
 console.log(`36 transparent WebP sprites: ${bytes} bytes; 13 original action sounds.`);
})();
