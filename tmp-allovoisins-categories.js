const {chromium}=require("playwright");
(async()=>{
  const b=await chromium.launch({headless:true});
  const p=await b.newPage();
  await p.goto("https://www.allovoisins.com/r/-1/0/0/0/location-vente",{waitUntil:"domcontentloaded",timeout:30000});
  const r=await p.locator("a[href]").evaluateAll(as=>as.map(a=>({text:(a.innerText||"").trim(),href:a.href})).filter(x=>/allovoisins\.com\/r\/\d+\/\d+\/\d+\/0\/location-/i.test(x.href)));
  const out=[...new Map(r.map(x=>[x.href,x])).values()];
  console.log(JSON.stringify(out,null,2));
  await b.close();
})();
