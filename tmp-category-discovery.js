const {chromium}=require("playwright");
(async()=>{
  const b=await chromium.launch({headless:true});
  const p=await b.newPage();
  for(const q of ["Remorque","Nettoyeur haute pression","Débroussailleuse","Promenade chien"]){
    await p.goto("https://www.allovoisins.com",{waitUntil:"domcontentloaded",timeout:30000});
    const input=p.locator('input[placeholder*="Que recherchez"],input[name*="search"],input[type="search"]').first();
    if(await input.count()){
      await input.fill(q);
      await p.waitForTimeout(1000);
    }
    console.log("\n### "+q);
    console.log((await p.locator("body").innerText()).slice(0,2500));
  }
  await b.close();
})();
