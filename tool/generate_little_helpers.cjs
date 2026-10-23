// Original vector artwork, rasterized for the existing Image.asset pipeline.
// Run: node tool/generate_little_helpers.cjs <path-to-sharp>
const fs = require('fs');
const sharp = require(process.argv[2]);
const dir = 'assets/gen/images/helpers';
fs.mkdirSync(dir, {recursive:true});
const face = '<circle cx="83" cy="113" r="5" fill="#29364d"/><circle cx="117" cy="113" r="5" fill="#29364d"/><path d="M90 128 Q100 139 110 128" fill="none" stroke="#29364d" stroke-width="4"/><ellipse cx="72" cy="125" rx="8" ry="5" fill="#ff9ca9"/><ellipse cx="128" cy="125" rx="8" ry="5" fill="#ff9ca9"/>';
const shape = (d,c) => `<path d="${d}" fill="${c}" stroke="#35445c" stroke-width="4" stroke-linejoin="round"/>`;
const shirt = c => shape('M64 48 L83 40 Q100 57 117 40 L136 48 L166 78 L143 101 L132 88 L136 165 L64 165 L68 88 L57 101 L34 78 Z',c);
const shorts = c => shape('M56 65 L144 65 L153 157 L108 157 L100 113 L92 157 L47 157 Z',c)+'<path d="M60 79 H140 M96 80 L91 100 M104 80 L109 100" stroke="#35445c" stroke-width="4" fill="none"/>';
const dirt = '<g fill="#936239"><ellipse cx="72" cy="138" rx="15" ry="11"/><circle cx="59" cy="126" r="7"/><circle cx="86" cy="149" r="6"/><ellipse cx="126" cy="100" rx="12" ry="9"/><circle cx="136" cy="88" r="5"/></g>';
const art={
 bread:shape('M55 76 C32 66 39 35 66 35 H134 C161 35 168 66 145 76 V164 H55 Z','#d59a5a')+shape('M65 76 C46 61 53 47 72 47 H128 C147 47 154 61 135 76 V152 H65 Z','#ffe1a0'),
 grapes:'<path d="M100 55 Q95 24 126 28" fill="none" stroke="#607c38" stroke-width="7"/><path d="M103 53 L65 29 L69 61 Z" fill="#79bd51"/>'+[[77,73],[111,69],[136,88],[91,100],[117,119],[80,128],[102,151]].map(([x,y])=>`<circle cx="${x}" cy="${y}" r="23" fill="#a375ce" stroke="#594077" stroke-width="4"/>`).join(''),
 broccoli:'<path d="M82 94 L85 168 H116 L121 94" fill="#95ce69" stroke="#35445c" stroke-width="4"/>'+[[63,79],[92,57],[129,66],[146,89],[104,91]].map(([x,y])=>`<circle cx="${x}" cy="${y}" r="29" fill="#61ab54" stroke="#35445c" stroke-width="4"/>`).join(''),
 yogurt:shape('M55 65 H145 L132 167 H68 Z','#b4e4ed')+'<ellipse cx="100" cy="65" rx="47" ry="15" fill="#fff" stroke="#35445c" stroke-width="4"/><ellipse cx="100" cy="65" rx="36" ry="8" fill="#f4adc6"/><path d="M120 64 L143 30" stroke="#7585a0" stroke-width="10" stroke-linecap="round"/>',
 tomato:'<circle cx="100" cy="109" r="62" fill="#ff6c65" stroke="#35445c" stroke-width="4"/>'+shape('M100 62 L76 38 L96 43 L107 25 L112 46 L137 42 L119 63 Z','#65aa55'),
 soda:shape('M64 45 H136 V164 Q100 180 64 164 Z','#f66a73')+'<ellipse cx="100" cy="45" rx="36" ry="10" fill="#d8e4ec" stroke="#35445c" stroke-width="4"/><path d="M68 86 Q100 64 133 79" stroke="white" stroke-width="13" fill="none"/>',
 cupcake:shape('M57 105 H143 L131 169 H69 Z','#d3a16d')+shape('M51 102 Q40 80 61 74 Q63 49 86 54 Q106 23 122 57 Q151 54 150 83 Q168 108 139 111 H63 Z','#ffe0a5')+'<circle cx="103" cy="45" r="12" fill="#f36f83"/>',
 lollipop:'<path d="M100 98 V179" stroke="#be9976" stroke-width="12" stroke-linecap="round"/><circle cx="100" cy="80" r="49" fill="#ff9fc2" stroke="#35445c" stroke-width="4"/><path d="M74 81 C66 40 134 39 131 79 S85 112 88 79 S115 64 109 80" fill="none" stroke="#df658e" stroke-width="7"/>',
 cake:shape('M44 103 L133 43 L158 152 L44 168 Z','#e6b274')+shape('M44 103 L133 43 L146 81 L44 132 Z','#f8a4b9')+'<path d="M48 150 L153 130" stroke="#fff0b9" stroke-width="13"/>',
 cereal:shape('M55 38 H133 L154 55 V168 H55 Z','#f6be55')+'<path d="M133 39 V168 M55 59 H133 L154 55" fill="none" stroke="#35445c" stroke-width="4"/><ellipse cx="95" cy="151" rx="28" ry="12" fill="#c1e8ef"/>',
 umbrella:shape('M24 100 Q100 -25 176 100 Q153 84 131 100 Q111 84 90 100 Q67 84 47 100 Q35 91 24 100 Z','#ff7b8e')+'<path d="M100 99 V153 Q100 181 77 169" fill="none" stroke="#35445c" stroke-width="8" stroke-linecap="round"/>',
 boots:shape('M70 42 H132 V133 H149 Q170 166 143 171 H50 Q34 148 70 131 Z','#ffc94e')+'<path d="M49 163 H150 M76 55 H125" stroke="#d69737" stroke-width="6"/>',
 raincoat:shirt('#73c4ed')+shape('M68 65 Q65 7 100 24 Q139 14 133 65 Z','#73c4ed')+'<path d="M100 68 V162" stroke="#397da5" stroke-width="4"/>',
 rainhat:shape('M55 104 Q57 38 100 36 Q147 38 146 104 Z','#af8ada')+shape('M25 107 Q95 79 174 107 L158 127 H42 Z','#bfa1e7'),
 sunhat:shape('M57 107 Q59 44 100 43 Q142 44 143 107 Z','#f6aacd')+'<ellipse cx="100" cy="116" rx="78" ry="25" fill="#f6aacd" stroke="#35445c" stroke-width="4"/><path d="M60 96 Q100 113 140 96" stroke="#ffcf67" stroke-width="13"/>',
 sunglasses:shape('M27 79 Q52 66 89 80 L83 125 Q54 146 32 123 Z','#46516a')+shape('M111 80 Q145 66 173 79 L168 123 Q144 146 117 125 Z','#46516a')+'<path d="M88 87 Q100 78 113 87" fill="none" stroke="#35445c" stroke-width="8"/>',
 sunscreen:shape('M62 37 H138 L128 151 H72 Z','#ffba50')+'<rect x="73" y="149" width="54" height="26" rx="5" fill="#f6f9fc" stroke="#35445c" stroke-width="4"/><circle cx="100" cy="79" r="20" fill="#fff3a6"/>',
 fan:shape('M100 171 L24 83 Q95 -1 176 83 Z','#fff1d0')+'<path d="M100 171 L50 65 M100 171 L78 49 M100 171 L107 47 M100 171 L135 60 M100 171 L158 79" stroke="#ba8b62" stroke-width="4"/>',
 ball:'<circle cx="100" cy="100" r="72" fill="#7dcdf1" stroke="#35445c" stroke-width="4"/>'+shape('M100 29 Q38 86 100 172 Q168 97 100 29 Z','#ff7d85')+'<path d="M48 51 Q118 103 48 149 M151 50 Q90 100 151 150" fill="none" stroke="#ffdf74" stroke-width="20"/>',
 tooth:shape('M41 82 Q31 21 79 34 Q100 41 121 34 Q170 20 159 82 L140 159 Q125 188 112 143 Q100 117 88 143 Q75 188 60 159 Z','#d8f4f5'),
 rain:'<path d="M46 103 C5 99 20 53 49 60 C47 20 102 11 117 47 C152 21 184 59 164 78 C196 115 147 122 127 109 Z" fill="#b6c5da" stroke="#35445c" stroke-width="4"/><path d="M57 139 L49 155 M99 139 L91 155 M141 139 L133 155" stroke="#62beef" stroke-width="12" stroke-linecap="round"/>',
 sun:'<g stroke="#ffbf41" stroke-width="9" stroke-linecap="round">'+[0,45,90,135,180,225,270,315].map(a=>`<path d="M100 20 V9" transform="rotate(${a} 100 100)"/>`).join('')+'</g><circle cx="100" cy="100" r="62" fill="#ffdb61" stroke="#edb53e" stroke-width="4"/>',
 washer:shape('M39 27 H161 V179 H39 Z','#e6f1fa')+'<circle cx="100" cy="115" r="46" fill="#8ecde4" stroke="#53617c" stroke-width="8"/><path d="M60 122 Q83 105 102 126 T142 122" stroke="#d0f5fa" stroke-width="10" fill="none"/><circle cx="143" cy="48" r="10" fill="#b1c4d9"/>',
 wardrobe:shape('M30 31 H170 V177 H30 Z','#dca56f')+'<path d="M100 35 V174 M39 142 H163" stroke="#875b3f" stroke-width="5"/><path d="M61 66 H139" stroke="#875b3f" stroke-width="5"/>'+shape('M72 75 L86 69 L100 80 L114 69 L128 75 L141 94 L127 107 L120 98 V133 H80 V98 L73 107 L59 94 Z','#89ca8a')
};
const jobs=[];
function save(id,body,smile=false){const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 200 200"><ellipse cx="100" cy="181" rx="69" ry="8" fill="#dce7ef" opacity=".5"/>${body}${smile?face:''}</svg>`;jobs.push(sharp(Buffer.from(svg)).png().toFile(`${dir}/${id}.png`));}
for(const [id,body] of Object.entries(art)) save(id,body,['bread','grapes','yogurt','tomato','soda','cupcake','cereal','tooth','sun'].includes(id));
save('sad_tooth',art.tooth+dirt+'<circle cx="81" cy="98" r="5"/><circle cx="119" cy="98" r="5"/><path d="M86 128 Q100 110 114 128" fill="none" stroke="#35445c" stroke-width="4"/>');
for(const [id,c,kind] of [['yellow_shirt','#ffcf63','shirt'],['green_shorts','#96ce7a','shorts'],['blue_shorts','#71b8ed','shorts'],['pink_shirt','#f8a4c4','shirt'],['white_shirt','#f8fafc','shirt']]) { const body=kind==='shirt'?shirt(c):shorts(c); save(id,body);save('dirty_'+id,body+dirt); }
const arabic = {
 'حط الأكل اليومي عند السنة السعيدة، والحلويات عند السنة التانية.':'ضَعِ الطَّعَامَ اليَوْمِيَّ عِنْدَ السِّنِّ السَّعِيدَةِ، وَالحَلْوَى عِنْدَ السِّنِّ الأُخْرَى.',
 'الدنيا بتمطر ولا مشمسة؟ حط كل حاجة في مكانها.':'هَلِ اليَوْمُ مُمْطِرٌ أَمْ مُشْمِسٌ؟ ضَعْ كُلَّ شَيْءٍ فِي مَكَانِهِ.',
 'الهدوم المتسخة في الغسالة. والهدوم النظيفة في الدولاب.':'ضَعِ المَلَابِسَ المُتَّسِخَةَ فِي الغَسَّالَةِ، وَالنَّظِيفَةَ فِي الخِزَانَةِ.',
 'بص على الصورة. مكانها فين؟':'اُنْظُرْ إِلَى الصُّورَةِ. أَيْنَ مَكَانُهَا؟',
 'جرب الصورة اللي بتنور.':'جَرِّبِ الصُّورَةَ المُضِيئَةَ.',
 'ده مكانها. جرب إنت!':'هَذَا مَكَانُهَا. جَرِّبْ أَنْتَ!',
 'رتبت كل حاجة! برافو يا بطل!':'رَتَّبْتَ كُلَّ شَيْءٍ! أَحْسَنْتَ يَا بَطَلُ!',
 'أكل يومي':'طَعَامٌ يَوْمِيٌّ','حلويات':'حَلْوَى','عيش':'خُبْزٌ','عنب':'عِنَبٌ','بروكلي':'بُرُوكْلِي','زبادي سادة':'زَبَادِي سَادَةٌ','طماطم':'طَمَاطِمُ',
 'مشروب غازي':'مَشْرُوبٌ غَازِيٌّ','كب كيك':'كَعْكَةٌ صَغِيرَةٌ','مصاصة':'حَلْوَى عَلَى عَصًا','كيك':'كَعْكٌ','حبوب محلاة':'حُبُوبٌ مُحَلَّاةٌ',
 'يوم ممطر':'يَوْمٌ مُمْطِرٌ','يوم مشمس':'يَوْمٌ مُشْمِسٌ','شمسية المطر':'مِظَلَّةُ المَطَرِ','جزمة المطر':'حِذَاءُ المَطَرِ','معطف المطر':'مِعْطَفُ المَطَرِ','قبعة المطر':'قُبَّعَةُ المَطَرِ',
 'قبعة الشمس':'قُبَّعَةُ الشَّمْسِ','نظارة شمس':'نَظَّارَةٌ شَمْسِيَّةٌ','واقي الشمس':'وَاقِي الشَّمْسِ','مروحة يد':'مِرْوَحَةٌ يَدَوِيَّةٌ','كرة الشاطئ':'كُرَةُ الشَّاطِئِ',
 'محتاج غسيل':'يَحْتَاجُ إِلَى الغَسِيلِ','نظيف وجاهز':'نَظِيفٌ وَجَاهِزٌ',
};
const tx=(en,ar)=>({en,ar:arabic[ar] ?? ar
 .replace('تيشيرت أصفر','قَمِيصٌ أَصْفَرُ').replace('شورت أخضر','سِرْوَالٌ أَخْضَرُ')
 .replace('شورت أزرق','سِرْوَالٌ أَزْرَقُ').replace('تيشيرت وردي','قَمِيصٌ وَرْدِيٌّ')
 .replace('تيشيرت أبيض','قَمِيصٌ أَبْيَضُ').replace('متسخ','مُتَّسِخٌ').replace('نظيف','نَظِيفٌ')});
const groups=[
 ['teeth','Happy teeth','أسنان سعيدة','Put everyday foods by the happy tooth. Put sugary treats by the other tooth.','حط الأكل اليومي عند السنة السعيدة، والحلويات عند السنة التانية.',[['everyday','tooth','Everyday foods','أكل يومي'],['treat','sad_tooth','Sugary treats','حلويات']], [ ['bread','Bread','عيش',0],['grapes','Grapes','عنب',0],['broccoli','Broccoli','بروكلي',0],['yogurt','Plain yogurt','زبادي سادة',0],['tomato','Tomato','طماطم',0],['soda','Soda','مشروب غازي',1],['cupcake','Cupcake','كب كيك',1],['lollipop','Lollipop','مصاصة',1],['cake','Cake','كيك',1],['cereal','Sugary cereal','حبوب محلاة',1]]],
 ['weather','Weather helpers','أصحاب الطقس','Is it rainy or sunny? Put each thing where we use it.','الدنيا بتمطر ولا مشمسة؟ حط كل حاجة في مكانها.',[['rainy','rain','Rainy day','يوم ممطر'],['sunny','sun','Sunny day','يوم مشمس']], [['umbrella','Umbrella','شمسية المطر',0],['boots','Rain boots','جزمة المطر',0],['raincoat','Raincoat','معطف المطر',0],['rainhat','Rain hat','قبعة المطر',0],['sunhat','Sun hat','قبعة الشمس',1],['sunglasses','Sunglasses','نظارة شمس',1],['sunscreen','Sunscreen','واقي الشمس',1],['fan','Fan','مروحة يد',1],['ball','Beach ball','كرة الشاطئ',1]]],
 ['laundry','Laundry helpers','أصحاب الغسيل','Dirty clothes go to the washer. Clean clothes go to the wardrobe.','الهدوم المتسخة في الغسالة. والهدوم النظيفة في الدولاب.',[['dirty','washer','Needs washing','محتاج غسيل'],['clean','wardrobe','Clean and ready','نظيف وجاهز']], [['yellow_shirt','Yellow shirt','تيشيرت أصفر'],['green_shorts','Green shorts','شورت أخضر'],['blue_shorts','Blue shorts','شورت أزرق'],['pink_shirt','Pink shirt','تيشيرت وردي'],['white_shirt','White shirt','تيشيرت أبيض']].flatMap(([id,en,ar])=>[[`dirty_${id}`,`Dirty ${en.toLowerCase()}`,`${ar} متسخ`,0],[id,`Clean ${en.toLowerCase()}`,`${ar} نظيف`,1]])]
];
for(const [id,en,ar,prompt,aprompt,bins,items] of groups){
 const pack={packId:`helpers_${id}`,items:items.map(([key,label,arabic,index])=>({id:key,image:`${dir}/${key}.png`,label:tx(label,arabic),attributes:{destination:bins[index][0],size:'same'}}))};
 fs.writeFileSync(`assets/adventures/packs/helpers_${id}.json`,JSON.stringify(pack,null,2)+'\n');
 const spec={schemaVersion:1,instanceId:`helpers.${id}`,engineId:'sorting',locales:['en','ar'],presentation:{accent:'#4AC49A'},narration:{prompt:tx(prompt,aprompt),hint1:tx('Look at the picture. Where does it belong?','بص على الصورة. مكانها فين؟'),hint2:tx('Try the glowing picture.','جرب الصورة اللي بتنور.'),model:tx('Here is its home. Now you try!','ده مكانها. جرب إنت!'),success:tx('You sorted everything! Great helping!','رتبت كل حاجة! برافو يا بطل!')},payload:{activeAttribute:'destination',heldConstant:['size'],itemsRef:`packs/helpers_${id}`,itemsPerRound:items.length,roundCount:1,bins:bins.map(([key,image,label,arabic])=>({id:key,value:key,image:`${dir}/${image}.png`,label:tx(label,arabic)}))},support:{allowTapToSelect:true,scaffolding:'errorless'},adaptation:{min:items.length,max:items.length}};
 fs.writeFileSync(`assets/adventures/activities/helpers_${id}.json`,JSON.stringify(spec,null,2)+'\n');
}
Promise.all(jobs).then(()=>console.log(`Created ${jobs.length} original illustrations and three bilingual activities.`));

// Short, quiet original Foley-like effects. Seeded noise makes regeneration exact.
for(const [theme,seconds] of [['teeth',0.48],['weather',0.55],['laundry',0.42]]) {
 const rate=22050,n=Math.floor(rate*seconds),wav=Buffer.alloc(44+n*2);
 wav.write('RIFF');wav.writeUInt32LE(36+n*2,4);wav.write('WAVEfmt ',8);
 wav.writeUInt32LE(16,16);wav.writeUInt16LE(1,20);wav.writeUInt16LE(1,22);
 wav.writeUInt32LE(rate,24);wav.writeUInt32LE(rate*2,28);wav.writeUInt16LE(2,32);wav.writeUInt16LE(16,34);wav.write('data',36);wav.writeUInt32LE(n*2,40);
 let seed=72,filtered=0;
 for(let i=0;i<n;i++){
  const t=i/rate,env=Math.sin(Math.PI*i/n)**2;
  seed=(1664525*seed+1013904223)>>>0;
  const noise=seed/2147483648-1; filtered=0.8*filtered+0.2*noise;
  const value=theme==='teeth' ? 0.15*env*(Math.sin(2*Math.PI*880*t)+0.5*Math.sin(2*Math.PI*1320*t))
    : theme==='weather' ? 0.32*env*noise*(0.4+0.6*Math.sin(2*Math.PI*17*t)**8)
    : 0.7*env*filtered*(0.5+0.5*Math.sin(2*Math.PI*11*t));
  wav.writeInt16LE(Math.round(value*32767),44+i*2);
 }
 fs.writeFileSync(`assets/audio/helpers_${theme}.wav`,wav);
}
