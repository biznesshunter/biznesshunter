const {chromium}=require("playwright");

(async()=>{
  const b=await chromium.launch({headless:true});
  const p=await b.newPage();

  await p.goto(
    "https://www.allovoisins.com/r/0/11/0/0/location-vente/Outillage",
    {waitUntil:"domcontentloaded",timeout:30000}
  );

  const links=await p.evaluate(()=>[...document.querySelectorAll("a[href]")]
    .map(a=>({text:(a.innerText||"").trim(),href:a.href}))
    .filter(x=>/\/location-[^/]+$/.test(x.href))
  );

  const unique=[...new Map(links.map(x=>[x.href,x])).values()];

  console.log("TOTAL:",unique.length);
  console.log(JSON.stringify(unique,null,2));

  await b.close();
})();
