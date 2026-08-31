const { chromium } = require("playwright");
const fs = require("fs");

(async () => {

  const url =
    "https://www.allovoisins.com/r/199/2/66035/0/location-Shampouineuse-Lyon";

  const browser = await chromium.launch({
    headless: false
  });

  const page = await browser.newPage({
    viewport: { width: 1400, height: 1000 }
  });

  console.log("");
  console.log("URL TEST:");
  console.log(url);

  const response = await page.goto(url, {
    waitUntil: "domcontentloaded",
    timeout: 30000
  });

  await page.waitForTimeout(2500);

  const finalUrl = page.url();
  const title = await page.title();
  const body = await page.locator("body").innerText();

  console.log("");
  console.log("HTTP STATUS :", response ? response.status() : null);
  console.log("FINAL URL   :", finalUrl);
  console.log("TITLE       :", title);
  console.log("BODY LENGTH :", body.length);

  console.log("");
  console.log("========== BODY PREVIEW ==========");
  console.log(body.slice(0, 2500));
  console.log("==================================");

  const cityMatches = [
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
  ].map(city => ({
    city,
    occurrences:
      (body.match(
        new RegExp(city, "gi")
      ) || []).length
  }));

  console.log("");
  console.log("CITY OCCURRENCES:");
  console.table(cityMatches);

  fs.writeFileSync(
    "./radar56_allovoisins_debug.txt",
    [
      `HTTP STATUS: ${response ? response.status() : null}`,
      `FINAL URL: ${finalUrl}`,
      `TITLE: ${title}`,
      `BODY LENGTH: ${body.length}`,
      "",
      "CITY OCCURRENCES:",
      JSON.stringify(cityMatches, null, 2),
      "",
      "BODY:",
      body
    ].join("\n"),
    "utf8"
  );

  await page.screenshot({
    path: "./radar56_allovoisins_debug.png",
    fullPage: true
  });

  console.log("");
  console.log(
    "TEXT SAVED : radar56_allovoisins_debug.txt"
  );

  console.log(
    "SCREENSHOT : radar56_allovoisins_debug.png"
  );

  await browser.close();

})();
