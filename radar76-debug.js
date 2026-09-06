const {chromium}=require("playwright");

(async()=>{
  const b=await chromium.launch({headless:true});
  const p=await b.newPage();

  await p.goto(
    "https://www.allovoisins.com/r/-1/0/0/0/location-vente",
    {waitUntil:"domcontentloaded",timeout:30000}
  );

  const x=await p.evaluate(()=>{
    const s=[...document.scripts]
      .find(x=>(x.textContent||"").includes("var all_categories"));

    const t=s.textContent;
    const i=t.indexOf("category_id");

    return {
      position:i,
      extrait:i>=0?t.slice(i-20,i+500):"INTROUVABLE"
    };
  });

  console.log("POSITION:",x.position);
  console.log(x.extrait);

  await b.close();
})();
