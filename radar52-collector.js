const { chromium } = require("playwright");
const fs = require("fs");

(async () => {

  const tests = JSON.parse(
    fs.readFileSync("./radar52_source_pilot.json", "utf8")
      .replace(/^\uFEFF/, "")
  );

  const browser = await chromium.launch({
    headless: false
  });

  const page = await browser.newPage({
    viewport: { width: 1400, height: 1000 }
  });

  const output = [];

  for (const item of tests) {

    if (item.status !== "READY") {
      continue;
    }

    console.log("");
    console.log(`SOURCE: ${item.source}`);
    console.log(`URL   : ${item.url}`);

    try {

      await page.goto(item.url, {
        waitUntil: "domcontentloaded",
        timeout: 30000
      });

      await page.waitForTimeout(2000);

      const title = await page.title();

      const body = await page.locator("body").innerText();

      const result = {
        idea_name: item.idea_name,
        country: item.country,
        city: item.city,
        category: item.category,
        source: item.source,
        url: item.url,
        page_title: title,
        body_length: body.length,
        scraped_at: new Date().toISOString()
      };

      /*
       * ALLovoisins
       */
      if (item.source === "allovoisins") {

        const match = body.match(
          /([\d\s]+)\s+demandes similaires/i
        );

        result.demand_count = match
          ? Number(match[1].replace(/\s/g, ""))
          : null;

        result.prices = [
          ...body.matchAll(/(\d+(?:[.,]\d+)?)€/g)
        ]
        .map(x => Number(x[1].replace(",", ".")));

        result.response_count =
          [...body.matchAll(/(\d+)\s+réponses?/gi)]
          .map(x => Number(x[1]));

      }

      /*
       * BRICOLIB
       */
      if (item.source === "bricolib") {

        const resultsMatch =
          body.match(/([\d\s]+)\s+résultats/i);

        result.supply_count = resultsMatch
          ? Number(resultsMatch[1].replace(/\s/g, ""))
          : null;

        result.prices = [
          ...body.matchAll(
            /(\d+(?:[.,]\d+)?)\s*€\s*\/\s*jour/gi
          )
        ]
        .map(x => Number(x[1].replace(",", ".")));

      }

      result.sample_text = body.slice(0, 5000);

      output.push(result);

      console.log("  STATUS : OK");

      if (result.demand_count !== undefined) {
        console.log(
          `  DEMAND : ${result.demand_count}`
        );
      }

      if (result.supply_count !== undefined) {
        console.log(
          `  SUPPLY : ${result.supply_count}`
        );
      }

      console.log(
        `  PRICES : ${result.prices.length}`
      );

    } catch (err) {

      console.log(`  ERROR : ${err.message}`);

      output.push({
        ...item,
        status: "ERROR",
        error: err.message,
        scraped_at: new Date().toISOString()
      });
    }
  }

  fs.writeFileSync(
    "./radar52_raw_market_data.json",
    JSON.stringify(output, null, 2),
    "utf8"
  );

  await browser.close();

  console.log("");
  console.log(
    `COLLECTIONS COMPLETED : ${output.length}`
  );

  console.log(
    "OUTPUT                : radar52_raw_market_data.json"
  );

})();
