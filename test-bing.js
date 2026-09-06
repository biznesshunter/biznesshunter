const { chromium } = require("playwright");

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();

  await page.goto(
    "https://www.bing.com/search?q=shampouineuse+Toulouse+AlloVoisins",
    { waitUntil: "domcontentloaded", timeout: 30000 }
  );

  await page.waitForTimeout(3000);

  const links = await page.locator("a").evaluateAll(as =>
    as.map(a => ({
      text: (a.innerText || "").trim(),
      href: a.href
    })).filter(x => x.href)
  );

  console.log("\n=== LIENS BING ===\n");
  links.slice(0, 50).forEach((x, i) =>
    console.log(`[${i}] ${x.text}\n${x.href}\n`)
  );

  await browser.close();
})();

