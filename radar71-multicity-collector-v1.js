const { chromium } = require("playwright");
const fs = require("fs");

const queue = JSON.parse(
  fs.readFileSync("./radar51_source_test_queue.json", "utf8").replace(/^\uFEFF/, "")
);

const cities = [...new Set(queue.map(x => x.city))];

const sleep = ms => new Promise(r => setTimeout(r, ms));

function slugify(text) {
  return text
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}

function normalize(text) {
  return String(text || "")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .trim();
}

function buildUrl(item) {
  const city = slugify(item.city);

  if (item.source === "allovoisins") {
    const map = {
      location_shampouineuse: `https://www.allovoisins.com/r/199/2/66035/0/location-Shampouineuse-${item.city}`,
      location_nettoyeur_vapeur: `https://www.allovoisins.com/r/199/2/66035/0/location-Nettoyeur-vapeur-${item.city}`,
      location_remorque: `https://www.allovoisins.com/r/199/2/66035/0/location-Remorque-${item.city}`,
      location_nettoyeur_haute_pression: `https://www.allovoisins.com/r/199/2/66035/0/location-Nettoyeur-haute-pression-${item.city}`,
      location_debroussailleuse: `https://www.allovoisins.com/r/199/2/66035/0/location-Debroussailleuse-${item.city}`,
      location_scarificateur: `https://www.allovoisins.com/r/199/2/66035/0/location-Scarificateur-${item.city}`,
      location_taille_haie: `https://www.allovoisins.com/r/199/2/66035/0/location-Taille-haie-${item.city}`,
      location_fendeuse_bois: `https://www.allovoisins.com/r/199/2/66035/0/location-Fendeuse-${item.city}`,
      location_tente_reception: `https://www.allovoisins.com/r/199/2/66035/0/location-Tente-${item.city}`,
      menage_sortie_location: `https://www.allovoisins.com/r/199/2/66035/0/menage-${item.city}`,
      promenade_chien: `https://www.allovoisins.com/r/199/2/66035/0/promenade-chien-${item.city}`
    };

    return map[item.category] || null;
  }

  if (item.source === "bricolib") {
    const map = {
      location_shampouineuse: "location-shampouineuse",
      location_nettoyeur_vapeur: "location-nettoyeur-vapeur",
      location_remorque: "location-remorque",
      location_nettoyeur_haute_pression: "location-nettoyeur-haute-pression",
      location_debroussailleuse: "location-debroussailleuse",
      location_scarificateur: "location-scarificateur",
      location_taille_haie: "location-taille-haie",
      location_fendeuse_bois: "location-fendeuse-bois",
      location_tente_reception: "location-tente-reception"
    };

    return map[item.category]
      ? `https://bricolib.net/${map[item.category]}/${city}`
      : null;
  }

  return null;
}

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();

  const results = [];

  for (const item of queue) {
    const requestedUrl = buildUrl(item);

    console.log(
      `\nTEST : ${item.category} | ${item.city} | ${item.source}`
    );

    if (!requestedUrl) {
      results.push({
        ...item,
        requested_url: null,
        final_url: null,
        http_status: null,
        page_title: "",
        body_length: 0,
        status: "UNSUPPORTED",
        scraped_at: new Date().toISOString()
      });

      console.log("UNSUPPORTED");
      continue;
    }

    try {
      const response = await page.goto(requestedUrl, {
        waitUntil: "domcontentloaded",
        timeout: 30000
      });

      await sleep(1500);

      const title = await page.title();
      const body = await page.locator("body").innerText().catch(() => "");

      results.push({
        ...item,
        requested_url: requestedUrl,
        final_url: page.url(),
        http_status: response ? response.status() : null,
        page_title: title,
        body_length: body.length,
        status:
          response && response.ok() ? "HTTP_OK" : "HTTP_ERROR",
        scraped_at: new Date().toISOString()
      });

      console.log(
        `HTTP ${response ? response.status() : "?"} | ${title} | ${body.length} caractères`
      );
    } catch (error) {
      results.push({
        ...item,
        requested_url: requestedUrl,
        final_url: page.url(),
        http_status: null,
        page_title: "",
        body_length: 0,
        status: "ERROR",
        error: error.message,
        scraped_at: new Date().toISOString()
      });

      console.log(`ERROR : ${error.message}`);
    }
  }

  fs.writeFileSync(
    "./radar71_raw.json",
    JSON.stringify(results, null, 2),
    "utf8"
  );

  await browser.close();

  console.log("\n=================================");
  console.log(`TESTS : ${results.length}`);
  console.log(
    `OK : ${results.filter(x => x.status === "HTTP_OK").length}`
  );
  console.log(
    `UNSUPPORTED : ${results.filter(x => x.status === "UNSUPPORTED").length}`
  );
  console.log(
    `ERRORS : ${results.filter(x => x.status === "ERROR").length}`
  );
  console.log("OUTPUT : radar71_raw.json");
  console.log("=================================");
})();
