const { chromium } = require("playwright");
const fs = require("fs");

(async () => {

  const input = JSON.parse(
    fs.readFileSync("./radar50_source_queue.json", "utf8")
      .replace(/^\uFEFF/, "")
  );

  const tests = input.filter(x =>
    x.city &&
    (x.source === "allovoisins" || x.source === "bricolib")
  );

  const browser = await chromium.launch({
    headless: false
  });

  const page = await browser.newPage({
    viewport: { width: 1400, height: 1000 }
  });

  const output = [];

  /*
   * Une seule occurrence par ville/source
   */
  const unique = new Map();

  for (const item of tests) {
    const key = `${item.city}|${item.source}`;

    if (!unique.has(key)) {
      unique.set(key, item);
    }
  }

  const queue = [...unique.values()];

  console.log(`URL RESOLUTION QUEUE : ${queue.length}`);

  for (const item of queue) {

    const query =
      `${item.source} ${item.idea_name} ${item.city}`;

    const googleUrl =
      "https://www.google.com/search?q=" +
      encodeURIComponent(query);

    console.log("");
    console.log(`SEARCH: ${item.city} / ${item.source}`);
    console.log(`QUERY : ${query}`);

    try {

      await page.goto(googleUrl, {
        waitUntil: "domcontentloaded",
        timeout: 30000
      });

      await page.waitForTimeout(2500);

      const links = await page.locator("a").evaluateAll(
        anchors => anchors.map(a => ({
          text: (a.innerText || "").trim(),
          href: a.href || ""
        }))
      );

      let candidates = links.filter(x => {

        if (!x.href) return false;

        if (item.source === "allovoisins") {
          return x.href.includes("allovoisins.com");
        }

        if (item.source === "bricolib") {
          return x.href.includes("bricolib.net");
        }

        return false;
      });

      /*
       * Déduplication
       */
      candidates = candidates.filter(
        (x, index, arr) =>
          arr.findIndex(y => y.href === x.href) === index
      );

      const resolvedUrl =
        candidates.length > 0
          ? candidates[0].href
          : null;

      console.log(
        `  MATCHES: ${candidates.length}`
      );

      console.log(
        `  URL    : ${resolvedUrl || "NONE"}`
      );

      output.push({
        idea_name: item.idea_name,
        country: item.country,
        city: item.city,
        category: item.category,
        source: item.source,
        google_query: query,
        resolved_url: resolvedUrl,
        candidates: candidates.slice(0, 5),
        resolved: !!resolvedUrl,
        resolved_at: new Date().toISOString()
      });

    } catch (err) {

      console.log(
        `  ERROR: ${err.message}`
      );

      output.push({
        idea_name: item.idea_name,
        country: item.country,
        city: item.city,
        category: item.category,
        source: item.source,
        google_query: query,
        resolved_url: null,
        candidates: [],
        resolved: false,
        error: err.message,
        resolved_at: new Date().toISOString()
      });
    }
  }

  fs.writeFileSync(
    "./radar55_resolved_urls.json",
    JSON.stringify(output, null, 2),
    "utf8"
  );

  await browser.close();

  console.log("");
  console.log(
    `URLS RESOLVED : ${output.filter(x => x.resolved).length}`
  );

  console.log(
    `URLS FAILED   : ${output.filter(x => !x.resolved).length}`
  );

  console.log(
    "OUTPUT        : radar55_resolved_urls.json"
  );

})();
