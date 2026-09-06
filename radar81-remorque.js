const {chromium}=require("playwright");
(async()=>{
  const b=await chromium.launch({headless:true});
  const p=await b.newPage();
  await p.goto("https://www.allovoisins.com/r/0/79/0/0/location-vente/Remorque-accessoires-auto",{waitUntil:"domcontentloaded",timeout:30000});
  const links=await p.evaluate(()=>[...document.querySelectorAll("a[href]")]
    .map(a=>({text:(a.innerText||"").trim(),href:a.href}))
    .filter(x=>x.href.includes("/location-")&&x.text));
  console.log(JSON.stringify(links,null,2));
  await b.close();
})();
