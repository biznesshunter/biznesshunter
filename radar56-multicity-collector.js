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

  function normalizeText(text) {
    return String(text)
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "")
      .toLowerCase()
      .trim();
  }

  const output = [];

  for (const city of cities) {

    const slug = city
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "")
      .toLowerCase()
      .replace(/\s+/g, "-");

    const sources = [

      {
        source: "allovoisins",
        url:
          `https://www.allovoisins.com/r/199/2/66035/0/location-Shampouineuse-${city}`
      },

      {
        source: "bricolib",
        url:
          `https://bricolib.net/location-shampouineuse/${slug}`
      }

    ];

    for (const item of sources) {

      console.log("");
      console.log(`COLLECT: ${city} / ${item.source}`);
      console.log(`URL    : ${item.url}`);

      try {

        const response = await page.goto(item.url, {
          waitUntil: "domcontentloaded",
          timeout: 30000
        });

        await page.waitForTimeout(1500);

        const finalUrl = page.url();
        const title = await page.title();
        const body = await page.locator("body").innerText();

        const result = {
          idea_name:
            "Marketplace de location de shampouineuses pour canapés entre particuliers",

          country: "FR",
          city,
          category: "location_shampouineuse",

          source: item.source,

          requested_url: item.url,
          final_url: finalUrl,

          http_status:
            response ? response.status() : null,

          page_title: title,
          body_length: body.length,

          demand_count: 0,
          supply_count: 0,
          prices: [],
          response_count: [],

          scraped_at: new Date().toISOString()
        };

        /*
         * ALLOVOISINS
         */

        if (item.source === "allovoisins") {

          /*
           * VALIDATION GEOGRAPHIQUE
           *
           * AlloVoisins peut retourner une page Paris
           * même lorsque l'URL demandée concerne une autre ville.
           */

          const expectedCity =
            normalizeText(city);

          const titleCityMatch =
            title.match(
              /Location de Shampouineuse à (.+?) \(/i
            );

          const servedCity =
            titleCityMatch
              ? normalizeText(titleCityMatch[1])
              : "";

          const cityIsValid =
            servedCity === expectedCity;

          console.log(
            `  GEO CHECK : demande=${city} / servie=${servedCity || "INCONNUE"} / valid=${cityIsValid}`
          );

          if (!cityIsValid) {

            console.log(
              "  DONNEES ALLOVOISINS REJETEES : MAUVAISE VILLE"
            );

            result.demand_count = 0;
            result.prices = [];
            result.response_count = [];

          } else {

            const demandMatch =
              body.match(
                /([\d\s]+)\s+demandes similaires/i
              );

            if (demandMatch) {
              result.demand_count =
                Number(
                  demandMatch[1].replace(/\s/g, "")
                );
            }

            result.prices =
              [...body.matchAll(
                /(\d+(?:[.,]\d+)?)€/g
              )]
              .map(x =>
                Number(
                  x[1].replace(",", ".")
                )
              );

            result.response_count =
              [...body.matchAll(
                /(\d+)\s+réponses?/gi
              )]
              .map(x => Number(x[1]));
          }
        }
        /*
         * BRICOLIB
         */

        if (item.source === "bricolib") {

          const supplyMatch =
            body.match(
              /([\d\s]+)\s+résultats/i
            );

          if (supplyMatch) {
            result.supply_count =
              Number(
                supplyMatch[1].replace(/\s/g, "")
              );
          }

          result.prices =
            [...body.matchAll(
              /(\d+(?:[.,]\d+)?)\s*€\s*\/\s*jour/gi
            )]
            .map(x =>
              Number(
                x[1].replace(",", ".")
              )
            );
        }

        output.push(result);

        console.log(
          `  HTTP   : ${result.http_status}`
        );

        console.log(
          `  BODY   : ${result.body_length}`
        );

        console.log(
          `  DEMAND : ${result.demand_count}`
        );

        console.log(
          `  SUPPLY : ${result.supply_count}`
        );

        console.log(
          `  PRICES : ${result.prices.length}`
        );

      } catch (err) {

        console.log(
          `  ERROR: ${err.message}`
        );

        output.push({
          idea_name:
            "Marketplace de location de shampouineuses pour canapés entre particuliers",

          country: "FR",
          city,
          category: "location_shampouineuse",

          source: item.source,

          requested_url: item.url,
          final_url: null,

          http_status: null,
          page_title: null,
          body_length: 0,

          demand_count: 0,
          supply_count: 0,
          prices: [],
          response_count: [],

          error: err.message,

          scraped_at: new Date().toISOString()
        });
      }
    }
  }


  function extractPricesBricolib(body) {

    const lines = body
      .split(/\r?\n/)
      .map(x => x.trim())
      .filter(Boolean);

    const prices = [];

    for (const line of lines) {

      const match = line.match(
        /(\d+(?:[.,]\d+)?)\s*€\s*\/\s*jour/i
      );

      if (!match) continue;

      if (/à partir de/i.test(line)) continue;

      const price = Number(
        match[1].replace(",", ".")
      );

      if (Number.isFinite(price)) {
        prices.push(price);
      }
    }

    return prices;
  }
  fs.writeFileSync(
    "./radar56_multicity_raw.json",
    JSON.stringify(output, null, 2),
    "utf8"
  );

  await browser.close();

  console.log("");
  console.log(
    `COLLECTIONS COMPLETED : ${output.length}`
  );

  console.log(
    `SUCCESS               : ${
      output.filter(
        x => x.http_status === 200
      ).length
    }`
  );

  console.log(
    `ERRORS                : ${
      output.filter(
        x => x.error
      ).length
    }`
  );

  console.log(
    "OUTPUT                : radar56_multicity_raw.json"
  );

})();



