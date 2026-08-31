const fs = require("fs");

const urls = [
  {
    city: "Paris",
    url: "https://www.allovoisins.com/r/199/2/66035/0/location-Shampouineuse-Paris"
  },
  {
    city: "Marseille",
    url: "https://www.allovoisins.com/r/199/2/66035/0/location-Shampouineuse-Marseille"
  },
  {
    city: "Toulouse",
    url: "https://www.allovoisins.com/r/199/2/66035/0/location-Shampouineuse-Toulouse"
  }
];

async function fetchPage(url) {
  const response = await fetch(url, {
    headers: {
      "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/151.0 Safari/537.36",
      "Accept":
        "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
      "Accept-Language": "fr-FR,fr;q=0.9,en;q=0.8"
    }
  });

  const body = await response.text();

  return {
    status: response.status,
    headers: response.headers,
    body
  };
}

function countOccurrences(text, needle) {
  return text.split(needle).length - 1;
}

function extractAround(text, marker, radius = 1200) {
  const index = text.indexOf(marker);

  if (index === -1) {
    return null;
  }

  const start = Math.max(0, index - radius);
  const end = Math.min(text.length, index + marker.length + radius);

  return text.substring(start, end);
}

function decodeHtml(text) {
  return text
    .replace(/&quot;/g, '"')
    .replace(/&#039;/g, "'")
    .replace(/&apos;/g, "'")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">");
}

function inspectCity(city, result) {
  const { body, status, headers } = result;

  console.log("");
  console.log("========================================");
  console.log(`CITY : ${city}`);
  console.log(`HTTP : ${status}`);
  console.log(`BODY : ${body.length} characters`);
  console.log("========================================");

  console.log("");
  console.log("--- RESPONSE HEADERS ---");

  console.log("content-type :", headers.get("content-type") || "");
  console.log("location     :", headers.get("location") || "");

  console.log("");
  console.log("--- CITY COUNTS ---");

  const cityNames = [
    "Paris",
    "Marseille",
    "Toulouse",
    "Lyon",
    "Bordeaux",
    "Nantes",
    "Lille",
    "Montpellier",
    "Nice",
    "Strasbourg",
    "Rennes",
    "Grenoble"
  ];

  for (const name of cityNames) {
    const count = countOccurrences(body, name);

    if (count > 0) {
      console.log(`${name.padEnd(20)} : ${count}`);
    }
  }

  console.log("");
  console.log("--- LOCATION / DATA MARKERS ---");

  const markers = [
    "cityId",
    "city_id",
    "cityID",
    "postalCode",
    "postal_code",
    "locationId",
    "location_id",
    "locationID",
    "departmentId",
    "department_id",
    "regionId",
    "region_id",
    "latitude",
    "longitude",
    "lat",
    "lng",
    "geo",
    "geolocation",
    "location",
    "city",
    "postal",
    "address"
  ];

  for (const marker of markers) {
    const count = countOccurrences(body, marker);

    if (count > 0) {
      console.log(`${marker.padEnd(20)} : ${count}`);
    }
  }

  console.log("");
  console.log("--- REQUEST / API MARKERS ---");

  const requestMarkers = [
    "askings",
    "asking",
    "request",
    "requests",
    "demand",
    "demands",
    "annonce",
    "annonces",
    "listing",
    "listings",
    "search",
    "results",
    "result",
    "api/",
    "/api/",
    "graphql",
    "ajax",
    "fetch(",
    "axios",
    "XMLHttpRequest"
  ];

  for (const marker of requestMarkers) {
    const count = countOccurrences(body, marker);

    if (count > 0) {
      console.log(`${marker.padEnd(20)} : ${count}`);
    }
  }

  console.log("");
  console.log("--- SCRIPT TAGS ---");

  const scripts =
    body.match(/<script[^>]*>([\s\S]*?)<\/script>/gi) || [];

  console.log(`SCRIPT BLOCKS : ${scripts.length}`);

  let interestingScripts = 0;

  scripts.forEach((script, index) => {
    const interesting =
      /city|asking|location|postal|latitude|longitude|api|graphql|annonce|request|search|result/i.test(
        script
      );

    if (!interesting) {
      return;
    }

    interestingScripts++;

    console.log("");
    console.log("----------------------------------------");
    console.log(`SCRIPT ${index}`);
    console.log("----------------------------------------");

    console.log(script.substring(0, 5000));
  });

  console.log("");
  console.log("INTERESTING SCRIPTS :", interestingScripts);

  console.log("");
  console.log("--- IMPORTANT CONTEXT ---");

  const contextMarkers = [
    "cityId",
    "postalCode",
    "locationId",
    "latitude",
    "longitude",
    "askings",
    "asking",
    "/api/",
    "graphql",
    "annonce",
    "location",
    "near_you",
    "nearYou",
    "searchItem",
    "data-id"
  ];

  for (const marker of contextMarkers) {
    const context = extractAround(body, marker);

    if (context) {
      console.log("");
      console.log(`### CONTEXT AROUND "${marker}" ###`);
      console.log(context);
    }
  }

  console.log("");
  console.log("--- JSON-LD ---");

  const jsonLdBlocks =
    body.match(
      /<script[^>]*type=["']application\/ld\+json["'][^>]*>[\s\S]*?<\/script>/gi
    ) || [];

  console.log(`JSON-LD BLOCKS : ${jsonLdBlocks.length}`);

  for (const block of jsonLdBlocks) {
    console.log("");
    console.log(block.substring(0, 10000));
  }

  console.log("");
  console.log("--- NEXT DATA ---");

  const nextDataMatch = body.match(
    /<script[^>]*id=["']__NEXT_DATA__["'][^>]*>([\s\S]*?)<\/script>/i
  );

  if (nextDataMatch) {
    console.log(
      decodeHtml(nextDataMatch[1]).substring(0, 20000)
    );
  } else {
    console.log("NO __NEXT_DATA__");
  }

  console.log("");
  console.log("--- URLS FOUND IN HTML ---");

  const urlsFound =
    body.match(/https?:\/\/[^"'<>\\\s]+/gi) || [];

  const uniqueUrls = [...new Set(urlsFound)];

  console.log(`URLS FOUND : ${uniqueUrls.length}`);

  uniqueUrls
    .filter((url) =>
      /api|search|location|asking|annonce|request|graphql|ajax|city/i.test(
        url
      )
    )
    .slice(0, 200)
    .forEach((url) => {
      console.log(url);
    });

  console.log("");
  console.log("--- NEAR YOU ARTICLES ---");

  const articles =
    body.match(
      /<article[^>]*class=["'][^"']*nearYou__searchItem[^"']*["'][\s\S]*?<\/article>/gi
    ) || [];

  console.log(`ARTICLES FOUND : ${articles.length}`);

  articles.slice(0, 20).forEach((article, index) => {
    console.log("");
    console.log(`### ARTICLE ${index + 1} ###`);
    console.log(article.substring(0, 8000));
  });

  console.log("");
  console.log("--- DATA-ID VALUES ---");

  const dataIds = [
    ...new Set(
      [...body.matchAll(/data-id=["']([^"']+)["']/gi)].map(
        (match) => match[1]
      )
    )
  ];

  console.log(`DATA-ID COUNT : ${dataIds.length}`);

  dataIds.slice(0, 100).forEach((id) => {
    console.log(id);
  });

  console.log("");
  console.log("--- LAT / LNG VALUES ---");

  const coordinates = [
    ...body.matchAll(
      /(?:latitude|lat)["'\s:=]+["']?(-?\d+(?:\.\d+)?)[^0-9]+(?:longitude|lng)["'\s:=]+["']?(-?\d+(?:\.\d+)?)/gi
    )
  ];

  coordinates.slice(0, 50).forEach((match) => {
    console.log(`LAT=${match[1]} LNG=${match[2]}`);
  });

  console.log("");
  console.log("--- POSTAL CODES ---");

  const postalCodes = [
    ...new Set(
      [...body.matchAll(/\b\d{5}\b/g)].map((match) => match[0])
    )
  ];

  postalCodes.slice(0, 100).forEach((postal) => {
    console.log(postal);
  });

  console.log("");
  console.log("--- API / AJAX URL CONTEXT ---");

  const apiRegex =
    /(?:https?:\/\/[^"'\\\s]+|["'`](?:\/|[^"'`]*)(?:api|ajax|graphql|search|asking|near_you)[^"'`]*["'`])/gi;

  const apiMatches = [...new Set(body.match(apiRegex) || [])];

  apiMatches.slice(0, 200).forEach((url) => {
    console.log(url);
  });

  console.log("");
  console.log("--- RAW HTML BEGINNING ---");

  console.log(body.substring(0, 5000));

  console.log("");
  console.log("--- RAW HTML END ---");

  console.log(
    body.substring(Math.max(0, body.length - 5000))
  );
}

async function main() {
  console.log("========================================");
  console.log("RADAR57 - ALLOVOISINS DEBUG");
  console.log("========================================");

  for (const item of urls) {
    try {
      console.log("");
      console.log(`Fetching ${item.city}...`);

      const result = await fetchPage(item.url);

      inspectCity(item.city, result);
    } catch (error) {
      console.error("");
      console.error("ERROR");
      console.error("CITY :", item.city);
      console.error("MESSAGE :", error.message);
    }
  }

  console.log("");
  console.log("========================================");
  console.log("DIAGNOSTIC FINISHED");
  console.log("========================================");
}

main();
