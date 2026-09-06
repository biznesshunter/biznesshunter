const fs=require("fs");
const s=fs.readFileSync("./radar76_allovoisins_categories.json","utf8");

for(const x of ["199","466","490","4930","691"]){
  const i=s.indexOf('"id": '+x);
  console.log("\n### "+x+" position="+i);
  console.log(i>=0?s.slice(i,i+500):"INTROUVABLE");
}
