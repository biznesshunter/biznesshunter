const {chromium}=require("playwright");
(async()=>{
  const b=await chromium.launch({headless:true});
  const p=await b.newPage();
  await p.goto("https://www.allovoisins.com/r/199/2/0/0/location-Shampouineuse",{waitUntil:"domcontentloaded",timeout:30000});
  const links=await p.locator("a").evaluateAll(as=>as.map(a=>({text:(a.innerText||"").trim(),href:a.href})).filter(x=>x.href.includes("location-")));
  console.log(JSON.stringify([...new Map(links.map(x=>[x.href,x])).values()],null,2));
  await b.close();
})();
