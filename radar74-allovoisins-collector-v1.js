const { chromium } = require("playwright");
const fs = require("fs");

const INPUT = "./radar73_allovoisins_raw.json";
const OUT = "./radar74_allovoisins_observations.json";

(async () => {
  const items = JSON.parse(fs.readFileSync(INPUT, "utf8").replace(/^\uFEFF/, ""));
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  const observations = [];

  for (let i = 0; i < items.length; i++) {
    const item = items[i];

    console.log(`[${i + 1}/${items.length}] ${item.category} | ${item.city}`);

    try {
      await page.goto(item.resolved_url, {
        waitUntil: "domcontentloaded",
        timeout: 30000
      });

      await page.waitForTimeout(700);

      const cards = await page.locator("body").innerText();

      const lines = cards
        .split("\n")
        .map(x => x.trim())
        .filter(Boolean);

      const cityNorm = String(item.city)
        .normalize("NFD")
        .replace(/[\u0300-\u036f]/g, "")
        .toLowerCase();

      const matches = [];

      for (let j = 0; j < lines.length; j++) {
        const line = lines[j];

        if (
          /shampouineuse|remorque|debroussailleuse|scarificateur|taille-haie|fendeuse|tente|menage|promenade/i.test(line)
        ) {
          const block = lines.slice(Math.max(0, j - 4), Math.min(lines.length, j + 12));

          const text = block.join(" ");

          const prices = [...text.matchAll(/(\d+(?:[.,]\d+)?)\s*€/g)]
            .map(m => Number(m[1].replace(",", ".")));

          const responseMatch = text.match(/(\d+)\s+réponses?/i);
          const dayMatch = text.match(/(\d+)\s+jour/i);

          const hasCity = text
            .normalize("NFD")
            .replace(/[\u0300-\u036f]/g, "")
            .toLowerCase()
            .includes(cityNorm);

          if (prices.length && hasCity) {
            matches.push({
              price_eur: prices[0],
              responses: responseMatch ? Number(responseMatch[1]) : null,
              duration_days: dayMatch ? Number(dayMatch[1]) : null,
              text
            });
          }
        }
      }

      const unique = [];
      const seen = new Set();

      for (const m of matches) {
        const key = `${m.price_eur}|${m.responses}|${m.text.slice(0, 180)}`;
        if (!seen.has(key)) {
          seen.add(key);
          unique.push(m);
        }
      }

      for (const m of unique) {
        observations.push({
          source: "allovoisins",
          category: item.category,
          city: item.city,
          country: item.country,
          resolved_url: item.resolved_url,
          price_eur: m.price_eur,
          responses: m.responses,
          duration_days: m.duration_days,
          text: m.text
        });
      }

      console.log(`  -> ${unique.length} observations`);
    } catch (e) {
      console.log(`  -> ERREUR: ${e.message}`);
    }
  }

  fs.writeFileSync(OUT, JSON.stringify(observations, null, 2), "utf8");

  console.log(`\nTOTAL OBSERVATIONS: ${observations.length}`);
  console.log(`FICHIER: ${OUT}`);

  await browser.close();
})();
