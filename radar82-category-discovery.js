const {chromium}=require("playwright");
const fs=require("fs");

(async()=>{
  const b=await chromium.launch({headless:true});
  const p=await b.newPage();

  const families=[
    ["outillage","https://www.allovoisins.com/r/0/11/0/0/location-vente/Outillage"],
    ["remorque","https://www.allovoisins.com/r/0/79/0/0/location-vente/Remorque-accessoires-auto"],
    ["jardin","https://www.allovoisins.com/r/0/10/0/0/location-vente/Materiel-de-jardin"],
    ["animaux","https://www.allovoisins.com/r/0/183/0/0/service/Animaux"]
  ];

  const targets=[
    "shampouineuse","nettoyeur vapeur","remorque auto",
    "fendeur de bûches","nettoyeur haute pression","débroussailleuse",
    "scarificateur","taille haie","tente réception",
    "garde chien","garde chat","promenade chien","ménage sortie location"
  ];

  const out=[];

  for(const [family,url] of families){
    await p.goto(url,{waitUntil:"domcontentloaded",timeout:30000});

    const links=await p.evaluate(()=>[...document.querySelectorAll("a[href]")]
      .map(a=>({text:(a.innerText||"").trim(),href:a.href}))
      .filter(x=>x.text&&x.href)
    );

    const unique=[...new Map(links.map(x=>[x.href,x])).values()];

    for(const x of unique){
      const s=x.text.toLowerCase();
      if(targets.some(t=>s.includes(t))){
        out.push({...x,family});
      }
    }
  }

  const clean=[...new Map(out.map(x=>[x.href,x])).values()];
  fs.writeFileSync("./radar82_target_category_routes.json",JSON.stringify(clean,null,2));

  console.log("TARGETS TROUVÉS:",clean.length);
  console.log(JSON.stringify(clean,null,2));

  await b.close();
})();
