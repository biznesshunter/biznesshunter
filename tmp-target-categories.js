const {chromium}=require("playwright");
(async()=>{
 const b=await chromium.launch({headless:true});
 const p=await b.newPage();
 await p.goto("https://www.allovoisins.com/r/-1/0/0/0/location-vente",{waitUntil:"domcontentloaded",timeout:30000});
 const h=await p.content();

 const targets=["remorque","nettoyeur","débrou","scarificateur","taille","fendeur","tente","shampouineuse"];

 for(const t of targets){
   console.log("\n### "+t.toUpperCase());
   const re=new RegExp(`"category_id":(\\d+),"name":"([^"]*${t}[^"]*)"[\\s\\S]{0,300}?"slug":"([^"]+)"[\\s\\S]{0,300}?"link":"([^"]+)"`,"gi");
   let m;
   while((m=re.exec(h))!==null){
     console.log(JSON.stringify({category_id:+m[1],name:m[2],slug:m[3],link:m[4].replace(/\\\\\//g,"/")}));
   }
 }
 await b.close();
})();
