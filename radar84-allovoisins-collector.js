const {chromium}=require("playwright");
const fs=require("fs");

(async()=>{
  const data=JSON.parse(fs.readFileSync("./radar83_category_city_discovery.json","utf8").replace(/^\uFEFF/,""));
  const b=await chromium.launch({headless:true});
  const p=await b.newPage();
  const out=[];

  for(const cat of data){
    for(const city of cat.city_links){
      try{await p.goto(city.href,{waitUntil:"commit",timeout:30000}).catch(()=>{})}catch(e){console.log("SKIP:",city.href);continue;}
      await p.waitForLoadState("domcontentloaded",{timeout:10000}).catch(()=>{}); let page; try{page=await p.evaluate(()=>({url:location.href,title:document.title,text:document.body?.innerText||""}))}catch(e){console.log("EVAL SKIP:",city.href);continue;}

      const wanted=cat.text.toLowerCase().split(" / ")[0].trim().normalize("NFD").replace(/[\u0300-\u036f]/g,"");
      const valid=page.title.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g,"").includes(wanted);

      if(valid) out.push({...city,category:cat.text,family:cat.family,title:page.title,text:page.text});
    }
    console.log("OK:",cat.text,"| total:",out.length);
  }

  fs.writeFileSync("./radar84_allovoisins_validated.json",JSON.stringify(out,null,2));
  console.log("TOTAL:",out.length);
  console.log("FICHIER: radar84_allovoisins_validated.json");
  await b.close();
})();






