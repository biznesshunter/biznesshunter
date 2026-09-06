const { chromium } = require("playwright");
const fs = require("fs");

const INPUT = "./radar51_source_test_queue.json";
const OUTPUT = "./radar72_resolved_urls.json";

const DOMAIN_MAP = {
  allovoisins: "allovoisins.com",
  bricolib: "bricolib.net",
  poppins: "poppins.co",
  rover: "rover.com",
  pawshake: "pawshake.fr",
  animalin: "animalin.fr",
  wecasa: "wecasa.fr"
};

function cleanText(s) {
  return String(s || "")
    .replace(/\s+/g, " ")
    .trim();
}

function decodeBingUrl(href) {
  try {
    const u = new URL(href);

    // Bing redirect : /ck/a?...&u=a1BASE64
    const encoded = u.searchParams.get("u");

    if (!encoded) return null;

    let value = encoded;

    if (value.startsWith("a1")) {
      value = value.slice(2);
    }

    value = value.replace(/-/g, "+").replace(/_/g, "/");

    while (value.length % 4 !== 0) {
      value += "=";
    }

    const decoded = Buffer.from(value, "base64").toString("utf8");

    if (/^https?:\/\//i.test(decoded)) {
      return decoded;
    }

    // Certains résultats sont doublement encodés
    const decoded2 = decodeURIComponent(decoded);

    if (/^https?:\/\//i.test(decoded2)) {
      return decoded2;
    }

    return null;
  } catch {
    return null;
  }
}

function isTargetDomain(url, domain) {
  try {
    const host = new URL(url).hostname.toLowerCase();
    return host === domain || host.endsWith("." + domain);
  } catch {
    return false;
  }
}

function normalizeUrl(url) {
  try {
    const u = new URL(url);
    u.hash = "";
    return u.toString();
  } catch {
    return url;
  }
}

(async () => {
  const raw = fs
    .readFileSync(INPUT, "utf8")
    .replace(/^\uFEFF/, "");

  let queue = JSON.parse(raw); queue = queue.slice(0, 12);

  const seen = new Set();
  const items = [];

  for (const item of queue) {
    const key = [
      item.idea_name,
      item.country,
      item.city,
      String(item.category || "").replace(/^location_/, "").replace(/_/g, " "),
      item.source
    ]
      .map(x => String(x || "").toLowerCase().trim())
      .join("|");

    if (!seen.has(key)) {
      seen.add(key);
      items.push(item);
    }
  }

  console.log(`QUEUE UNIQUE : ${items.length}`);

  let browser = await chromium.launch({
    headless: false
  });

  const context = await browser.newContext({
    locale: "fr-FR",
    userAgent:
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/131 Safari/537.36"
  });

  let page = await context.newPage();

  const results = [];

  for (let i = 0; i < items.length; i++) { if (page.isClosed()) { console.log("REDEMARRAGE NAVIGATEUR"); await browser.close().catch(() => {}); browser = await chromium.launch({ headless: false }); page = await browser.newPage(); }
    const item = items[i];

    const source = String(item.source || "").toLowerCase();
    const domain = DOMAIN_MAP[source];

    console.log(
      `\n[${i + 1}/${items.length}] ${source} | ${item.category} | ${item.city}`
    );

    if (!domain) {
      console.log("SOURCE NON SUPPORTÉE");
      results.push({
        ...item,
        resolved_url: null,
        resolver_status: "UNSUPPORTED_SOURCE"
      });
      continue;
    }

    const query = [
      source === "allovoisins" ? "AlloVoisins" : source,
      String(item.category || "").replace(/^location_/, "").replace(/_/g, " "),
      item.city
    ]
      .filter(Boolean)
      .join(" ");

    const searchUrl =
      "https://www.bing.com/search?q=" +
      encodeURIComponent(query);

    try {
      await page.goto(searchUrl, {
        waitUntil: "domcontentloaded",
        timeout: 30000
      });

      await page.waitForTimeout(2000);

      const anchors = await page.locator("li.b_algo").evaluateAll(as =>
        as.map(a => ({
          href: a.querySelector("h2 a")?.href || "",
          text: String(a.innerText || "").replace(/\s+/g, " ").trim()
        }))
      );

      const candidates = [];

      for (const a of anchors) {
        if (!a.href) continue;

        let realUrl = null;

        // URL Bing redirect
        if (
          a.href.includes("bing.com/ck/a") ||
          a.href.includes("bing.com/aclick")
        ) {
          realUrl = decodeBingUrl(a.href);
        }

        // URL directe éventuelle
        if (!realUrl && isTargetDomain(a.href, domain)) {
          realUrl = a.href;
        }

        if (!realUrl) continue;

        realUrl = normalizeUrl(realUrl);

        if (!isTargetDomain(realUrl, domain)) continue;

        candidates.push({
          url: realUrl,
          text: a.text
        });
      }

      const unique = [
        ...new Map(candidates.map(x => [x.url, x])).values()
      ];

      console.log(`CANDIDATS ${domain} : ${unique.length}`);

      if (unique.length === 0) {
        console.log("AUCUNE URL SOURCE TROUVÉE");

        results.push({
          ...item,
          search_query: query,
          resolved_url: null,
          resolver_status: "NO_SOURCE_RESULT"
        });

        continue;
      }

      const cityNorm = String(item.city || "").toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "");
const categoryNorm = String(item.category || "").replace(/^location_/, "").replace(/_/g, " ").toLowerCase();

const ranked = unique.map(x => {
  const haystack = `${x.url} ${x.text}`.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "");

  let score = 0;

  if (haystack.includes(cityNorm)) score += 10;
  if (haystack.includes(categoryNorm)) score += 5;

  // Favorise les pages profondes plutôt que la homepage
  try {
    const path = new URL(x.url).pathname;
    if (path !== "/" && path.length > 10) score += 3;
  } catch {}

  return { ...x, score };
}).sort((a, b) => b.score - a.score);

const validRanked = ranked.filter(x => { const h = `${x.url} ${x.text}`.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, ""); return h.includes(cityNorm) && h.includes(categoryNorm); }); const selected = validRanked[0] || null;

      if (!selected) { console.log("AUCUNE URL LOCALE VALIDE"); results.push({ ...item, search_query: query, resolved_url: null, resolver_status: "NO_LOCAL_MATCH" }); continue; } console.log("URL :", selected.url);
      console.log("TEXTE :", selected.text);

      results.push({
        ...item,
        search_query: query,
        resolved_url: selected.url,
        resolved_title: selected.text,
        resolver_status: "RESOLVED"
      });
    } catch (err) {
      console.log("ERREUR :", err.message);

      results.push({
        ...item,
        search_query: query,
        resolved_url: null,
        resolver_status: "ERROR",
        resolver_error: err.message
      });
    }
  }

  await browser.close();

  fs.writeFileSync(
    OUTPUT,
    JSON.stringify(results, null, 2),
    "utf8"
  );

  const resolved = results.filter(
    x => x.resolver_status === "RESOLVED"
  ).length;

  console.log("\n==============================");
  console.log("RADAR72 TERMINÉ");
  console.log("==============================");
  console.log(`TOTAL       : ${results.length}`);
  console.log(`RESOLVED    : ${resolved}`);
  console.log(
    `NON RÉSOLUS : ${results.length - resolved}`
  );
  console.log(`OUTPUT      : ${OUTPUT}`);
})();











