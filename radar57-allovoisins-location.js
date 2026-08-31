const { chromium } = require("playwright");

(async () => {

  const browser = await chromium.launch({
    headless: false
  });

  const page = await browser.newPage({
    viewport: { width: 1400, height: 1000 }
  });

  const urls = [
    "https://www.allovoisins.com/r/199/2/66035/0/location-Shampouineuse-Lyon",
    "https://www.allovoisins.com/r/199/2/66035/0/location-Shampouineuse-Toulouse",
    "https://www.allovoisins.com/r/199/2/66035/0/location-Shampouineuse-Marseille"
  ];

  for (const url of urls) {

    console.log("");
    console.log("========================================");
    console.log("TEST URL:");
    console.log(url);

    await page.goto(url, {
      waitUntil: "domcontentloaded",
      timeout: 30000
    });

    await page.waitForTimeout(2000);

    console.log("");
    console.log("FINAL URL :", page.url());
    console.log("TITLE     :", await page.title());

    const links = await page.locator("a").evaluateAll(els =>
      els.map(a => ({
        text: (a.innerText || "").trim(),
        href: a.href
      }))
      .filter(x =>
        x.text ||
        x.href.includes("allovoisins")
      )
      .slice(0, 100)
    );

    console.log("");
    console.log("LINKS:");
    console.log(JSON.stringify(links, null, 2));

    const html = await page.content();

    console.log("");
    console.log("HTML LENGTH :", html.length);

    const locationSnippets = [
      "Lyon",
      "Toulouse",
      "Marseille",
      "Paris",
      "75016",
      "69000",
      "31000",
      "13000"
    ];

    console.log("");
    console.log("LOCATION OCCURRENCES:");

    for (const term of locationSnippets) {
      const count =
        (html.match(
          new RegExp(term, "gi")
        ) || []).length;

      console.log(
        `${term.padEnd(12)} : ${count}`
      );
    }
  }

  await browser.close();

})();
