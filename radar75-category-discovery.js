const {chromium}=require("playwright");
(async()=>{
 const b=await chromium.launch({headless:true});
 const p=await b.newPage();
 await p.goto("https://www.allovoisins.com/r/-1/0/0/0/location-vente",{waitUntil:"domcontentloaded",timeout:30000});

 const links=await p.locator('a[href*="/location-"]').evaluateAll(as =>
   as.map(a=>({
     text:(a.innerText||"").trim().replace(/\s+/g," "),
     href:a.href
   }))
   .filter(x=>x.text && /\/location-[^/]+/i.test(x.href))
 );

 const targets=/remorque|nettoyeur|débroussailleuse|scarificateur|taille-haie|fendeur|shampouineuse|tente/i;

 const out=links
   .filter(x=>targets.test(x.text))
   .filter((x,i,a)=>a.findIndex(y=>y.href===x.href)===i);

 require("fs").writeFileSync(
   "./radar75_allovoisins_category_links.json",
   JSON.stringify(out,null,2),
   "utf8"
 );

 console.log("LIENS:",out.length);
 console.log(JSON.stringify(out,null,2));

 await b.close();
})();
