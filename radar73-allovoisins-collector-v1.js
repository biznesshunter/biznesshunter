const { chromium } = require("playwright");
const fs = require("fs");

const QUEUE = "./radar51_source_test_queue.json";
const OUT = "./radar73_allovoisins_raw.json";

(async () => {
  const raw = fs.readFileSync(QUEUE, "utf8").replace(/^\uFEFF/, "");
  const queue = JSON.parse(raw).filter(x => x.source === "allovoisins");

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  const results = [];

  const categories = [...new Set(queue.map(x => x.category))];

  for (const category of categories) {
    const sample = queue.find(x => x.category === category);
    const slug = String(category)
      .replace(/^location_/, "")
      .replace(/_/g, "-");

    const baseUrl = `https://www.allovoisins.com/r/199/2/0/0/location-${slug}`;

    console.log(`\nCATÉGORIE: ${category}`);
    console.log(`URL: ${baseUrl}`);

    try {
      await page.goto(baseUrl, {
        waitUntil: "domcontentloaded",
        timeout: 30000
      });

      await page.waitForTimeout(1000);

      const links = await page.locator("a").evaluateAll(as =>
        as.map(a => ({
          href: a.href,
          text: String(a.innerText || "").replace(/\s+/g, " ").trim()
        }))
      );

      const cityLinks = links.filter(x =>
        /\/location-[^/]+-/i.test(x.href) &&
        x.text
      );

      for (const item of queue.filter(x => x.category === category)) {
        const match = cityLinks.find(x =>
          x.text.toLowerCase().includes(String(item.city).toLowerCase())
        );

        if (!match) {
          console.log(`  ${item.city}: NON TROUVÉ`);
          continue;
        }

        console.log(`  ${item.city}: OK`);

        results.push({
          ...item,
          resolved_url: match.href,
          resolved_text: match.text,
          status: "RESOLVED"
        });
      }
    } catch (e) {
      console.log(`ERREUR: ${e.message}`);
    }
  }

  fs.writeFileSync(OUT, JSON.stringify(results, null, 2), "utf8");

  console.log(`\nTERMINÉ: ${results.length} URLs résolues`);
  console.log(`FICHIER: ${OUT}`);

  await browser.close();
})();
