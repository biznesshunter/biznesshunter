const {chromium}=require("playwright");

(async()=>{
  const b=await chromium.launch({headless:true});
  const p=await b.newPage();

  const pages=[
    ["outillage","https://www.allovoisins.com/r/0/11/0/0/location-vente/Outillage"],
    ["remorque","https://www.allovoisins.com/r/0/79/0/0/location-vente/Remorque-accessoires-auto"],
    ["jardin","https://www.allovoisins.com/r/0/94/0/0/location-vente/Jardin-jardin-potager"],
    ["animaux","https://www.allovoisins.com/r/0/183/0/0/service/Animaux"]
  ];

  for(const [name,url] of pages){
    await p.goto(url,{waitUntil:"domcontentloaded",timeout:30000});

    const links=await p.evaluate(()=>[...document.querySelectorAll("a[href]")]
      .map(a=>({text:(a.innerText||"").trim(),href:a.href}))
      .filter(x=>/\/(location-|service\/)/.test(x.href))
      .filter(x=>x.text)
    );

    const unique=[...new Map(links.map(x=>[x.href,x])).values()];

    console.log("\n### "+name.toUpperCase()+" — "+unique.length);
    console.log(JSON.stringify(unique,null,2));
  }

  await b.close();
})();
