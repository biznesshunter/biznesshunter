const { chromium } = require("playwright");
const fs = require("fs");

(async () => {

  const cities = [
    "Paris",
    "Lyon",
    "Marseille",
    "Toulouse",
    "Bordeaux",
    "Nantes",
    "Lille",
    "Montpellier",
    "Strasbourg",
    "Nice",
    "Rennes",
    "Grenoble",
    "Rouen"
  ];

  const browser = await chromium.launch({
    headless: false
  });

  const page = await browser.newPage({
    viewport: { width: 1400, height: 1000 }
  });

  const output = [];

  for (const city of cities) {

    const slug = city
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "")
      .toLowerCase()
      .replace(/\s+/g, "-");

    const tests = [

      {
        source: "allovoisins",
        url: `https://www.allovoisins.com/r/199/2/66035/0/location-Shampouineuse-${city}`
      },

      {
        source: "bricolib",
        url: `https://bricolib.net/location-shampouineuse/${slug}`
      }

    ];

    for (const test of tests) {

      console.log("");
      console.log(`TEST: ${test.source} / ${city}`);
      console.log(`URL : ${test.url}`);

      try {

        const response = await page.goto(test.url, {
          waitUntil: "domcontentloaded",
          timeout: 30000
        });

        await page.waitForTimeout(1500);

        const finalUrl = page.url();
        const title = await page.title();

        const body = await page.locator("body").innerText();

        const status = response
          ? response.status()
          : null;

        console.log(`  HTTP : ${status}`);
        console.log(`  FINAL: ${finalUrl}`);
        console.log(`  BODY : ${body.length}`);

        output.push({
          city,
          source: test.source,
          requested_url: test.url,
          final_url: finalUrl,
          http_status: status,
          title,
          body_length: body.length,
          accessible: body.length > 500,
          tested_at: new Date().toISOString()
        });

      } catch (err) {

        console.log(
          `  ERROR: ${err.message}`
        );

        output.push({
          city,
          source: test.source,
          requested_url: test.url,
          final_url: null,
          http_status: null,
          title: null,
          body_length: 0,
          accessible: false,
          error: err.message,
          tested_at: new Date().toISOString()
        });
      }
    }
  }

  fs.writeFileSync(
    "./radar55_direct_url_test.json",
    JSON.stringify(output, null, 2),
    "utf8"
  );

  await browser.close();

  console.log("");
  console.log(
    `TESTS COMPLETED : ${output.length}`
  );

  console.log(
    `ACCESSIBLE      : ${output.filter(x => x.accessible).length}`
  );

  console.log(
    `INACCESSIBLE    : ${output.filter(x => !x.accessible).length}`
  );

  console.log(
    "OUTPUT          : radar55_direct_url_test.json"
  );

})();
