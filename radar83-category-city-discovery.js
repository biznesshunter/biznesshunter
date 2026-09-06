const {chromium}=require("playwright");
const fs=require("fs");

(async()=>{
  const routes=JSON.parse(fs.readFileSync("./radar82_target_category_routes_clean.json","utf8").replace(/^\uFEFF/, ""));
  const b=await chromium.launch({headless:true});
  const p=await b.newPage();

  const results=[];

  for(const r of routes){
    await p.goto(r.href,{waitUntil:"domcontentloaded",timeout:30000});
    const data=await p.evaluate(()=>({
      url:location.href,
      title:document.title,
      links:[...document.querySelectorAll("a[href]")]
        .map(a=>({text:(a.innerText||"").trim(),href:a.href}))
        .filter(x=>x.text&&x.href.includes("/location-"))
    }));
    results.push({...r,page_url:data.url,page_title:data.title,city_links:[...new Map(data.links.map(x=>[x.href,x])).values()]});
    console.log("OK:",r.text,"=>",data.title,"| villes:",data.links.length);
  }

  fs.writeFileSync("./radar83_category_city_discovery.json",JSON.stringify(results,null,2));
  console.log("\nFICHIER: radar83_category_city_discovery.json");
  await b.close();
})();

