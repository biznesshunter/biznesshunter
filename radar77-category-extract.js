const {chromium}=require("playwright");
const fs=require("fs");

(async()=>{
  const b=await chromium.launch({headless:true});
  const p=await b.newPage();

  await p.goto("https://www.allovoisins.com/r/-1/0/0/0/location-vente",
    {waitUntil:"domcontentloaded",timeout:30000});

  const rows=await p.evaluate(()=>{
    const s=[...document.scripts].find(x=>
      (x.textContent||"").includes("var all_categories = JSON.parse")
    );
    if(!s) throw new Error("REGISTRE INTROUVABLE");

    const t=s.textContent;
    const marker="var all_categories = ";
    const start=t.indexOf(marker)+marker.length;
    const end=t.indexOf(";",start);

    const registry=eval(t.slice(start,end));
    const rows=[];

    function walk(obj,parent=null){
      if(!obj || typeof obj!=="object") return;

      for(const c of Object.values(obj)){
        if(!c || typeof c!=="object") continue;

        if(c.category_id){
          rows.push({
            id:Number(c.category_id),
            name:c.name||null,
            parent:c.parent_category??parent,
            slug:c.slug||null,
            link:c.link||null
          });
        }

        if(c.children) walk(c.children,c.category_id||parent);
      }
    }

    walk(registry);
    return rows;
  });

  fs.writeFileSync(
    "./radar77_allovoisins_categories.json",
    JSON.stringify(rows,null,2),
    "utf8"
  );

  const ids=[199,466,490,4930,691,79,185,186];
  console.log("TOTAL:",rows.length);
  console.log(JSON.stringify(rows.filter(x=>ids.includes(x.id)),null,2));

  await b.close();
})();
