const { chromium } = require("playwright");
const fs = require("fs");

(async () => {

  const raw = fs.readFileSync("./radar47_browser_queue.json", "utf8")
    .replace(/^\uFEFF/, "");

  const queue = JSON.parse(raw);

  const browser = await chromium.launch({
    headless: false
  });

  const page = await browser.newPage({
    viewport: { width: 1400, height: 1000 }
  });

  await page.goto(queue[0].search_url, {
    waitUntil: "domcontentloaded",
    timeout: 30000
  });

  await page.waitForTimeout(3000);

  console.log("");
  console.log("PAGE TITLE :", await page.title());
  console.log("URL        :", page.url());

  const info = await page.locator("body").innerText();

  fs.writeFileSync(
    "./radar48_google_debug.txt",
    info,
    "utf8"
  );

  console.log("");
  console.log("BODY TEXT SAVED : radar48_google_debug.txt");
  console.log("BODY LENGTH     :", info.length);

  console.log("");
  console.log("H3 COUNT :", await page.locator("h3").count());
  console.log("LINK COUNT :", await page.locator("a").count());

  await page.screenshot({
    path: "./radar48_google_debug.png",
    fullPage: true
  });

  console.log("SCREENSHOT : radar48_google_debug.png");

  await browser.close();

})();
