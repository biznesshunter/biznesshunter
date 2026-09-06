const {chromium}=require("playwright");
const fs=require("fs");

(async()=>{
  const b=await chromium.launch({headless:true});
  const p=await b.newPage();

  await p.goto("https://www.allovoisins.com/r/-1/0/0/0/location-vente",
    {waitUntil:"domcontentloaded",timeout:30000});

  const result=await p.evaluate(()=>{
    const s=[...document.scripts].find(x=>
      (x.textContent||"").includes("var all_categories")
    );

    if(!s) throw new Error("REGISTRE INTROUVABLE");

    const t=s.textContent;
    const start=t.indexOf('var all_categories = JSON.parse("')+
      'var all_categories = JSON.parse("'.length;
    const end=t.indexOf('");',start);
    const raw=t.slice(start,end);

    const out=[];
    const re=/\\?"category_id\\?":(\d+).*?\\?"name\\?":\\?"([^"]*?)\\?".*?\\?"parent_category\\?":(null|\d+).*?\\?"slug\\?":\\?"([^"]*?)\\?".*?\\?"link\\?":\\?"([^"]*?)\\?"/g;

    let m;
    while((m=re.exec(raw))){
      out.push({
        id:Number(m[1]),
        name:m[2],
        parent:m[3]==="null"?null:Number(m[3]),
        slug:m[4],
        link:m[5]
      });
    }

    return out;
  });

  fs.writeFileSync(
    "./radar76_allovoisins_categories.json",
    JSON.stringify(result,null,2),
    "utf8"
  );

  const targets=/remorque|nettoyeur|débroussailleuse|scarificateur|taille.?haie|fendeur|shampouineuse|tente|promenade|ménage/i;
  const found=result.filter(x=>targets.test(x.name));

  console.log("TOTAL CATEGORIES:",result.length);
  console.log("CIBLES:",found.length);
  console.log(JSON.stringify(found,null,2));

  await b.close();
})();
