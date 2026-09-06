const {chromium}=require("playwright");

(async()=>{
 const b=await chromium.launch({headless:true});
 const p=await b.newPage();

 await p.goto("https://www.allovoisins.com/r/-1/0/0/0/location-vente",{waitUntil:"domcontentloaded",timeout:30000});

 const links=await p.locator('a[href*="/location-"]').evaluateAll(as =>
   as.map(a=>({text:(a.innerText||"").trim(),href:a.href}))
    .filter(x=>x.text)
 );

 const targets=/remorque|nettoyeur|débroussailleuse|scarificateur|taille-haie|fendeur|shampouineuse|tente/i;

 const out=links.filter(x=>targets.test(x.text));

 console.log(JSON.stringify(out,null,2));

 await b.close();
})();
