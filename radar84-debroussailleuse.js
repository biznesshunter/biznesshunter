const {chromium}=require("playwright");
const fs=require("fs");

(async()=>{
  const d=JSON.parse(fs.readFileSync("./radar83_category_city_discovery.json","utf8").replace(/^\uFEFF/,""));
  const cat=d.find(x=>x.href.includes("/location-Debroussailleuse"));
  const b=await chromium.launch({headless:true});
  const p=await b.newPage();
  const out=[];

  for(const city of cat.city_links){
    if(!city.href.match(/\/r\/4930\/11\/\d+\/0\/location-Debroussailleuse-/)) continue;

    await p.goto(city.href,{waitUntil:"commit",timeout:30000}).catch(()=>{});
    await p.waitForLoadState("domcontentloaded",{timeout:10000}).catch(()=>{});

    try{
      const page=await p.evaluate(()=>({
        url:location.href,
        title:document.title,
        text:document.body?.innerText||""
      }));

      const valid=page.url.includes("/location-Debroussailleuse-");

      if(valid){
        out.push({
          ...city,
          category:"Débroussailleuse",
          family:cat.family,
          source:"allovoisins",
          title:page.title,
          text:page.text
        });
      }
    }catch(e){}
  }

  fs.writeFileSync("./radar84_debroussailleuse_validated.json",JSON.stringify(out,null,2));
  console.log("DEBROUSSAILLEUSE:",out.length);
  console.log("FICHIER: radar84_debroussailleuse_validated.json");
  await b.close();
})();
