const fs=require("fs");
const d=JSON.parse(fs.readFileSync("./radar84_allovoisins_validated.json","utf8").replace(/^\uFEFF/,""));
const out=[];

for(const page of d){
  const lines=page.text.split(/\r?\n/).map(x=>x.trim()).filter(Boolean);
  for(let i=0;i<lines.length;i++){
    if(!/^(Aujourd'hui|Hier|\d{1,2}:\d{2})/.test(lines[i])) continue;

    const date=lines[i];
    const price=lines[i+1]||"";
    const name=lines[i+2]||"";
    const rating=lines[i+3]||"";
    const title=lines[i+4]||"";
    const quote=lines[i+5]||"";
    const city=lines[i+6]||"";
    const duration=lines[i+7]||"";
    const responses=(lines[i+8]||"").match(/(\d+)\s+réponse/)?.[1]||null;

    if(!/^(Aujourd'hui|Hier|\d{1,2}:\d{2})/.test(date)) continue;
    if(!/(€|Non rémunéré)/.test(price)) continue;
    if(!title.toLowerCase().includes(page.category.split(" / ")[0].toLowerCase().split(" ")[0])) continue;

    out.push({
      category:page.category,
      family:page.family,
      source:"allovoisins",
      date,
      price,
      name,
      rating,
      title,
      quote,
      city,
      duration,
      responses:responses?Number(responses):0,
      page_url:page.href
    });
  }
}

fs.writeFileSync("./radar85_allovoisins_observations.json",JSON.stringify(out,null,2));
console.log("OBSERVATIONS:",out.length);
console.log("CATEGORIES:",[...new Set(out.map(x=>x.category))]);
console.log("PRIX:",out.filter(x=>x.price.includes("€")).length);
console.log("REPONSES:",out.filter(x=>x.responses>0).length);
console.log("FICHIER: radar85_allovoisins_observations.json");
