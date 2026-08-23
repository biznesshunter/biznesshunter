$ErrorActionPreference = "SilentlyContinue"

$headers = @{
    "User-Agent" = "BiznessHunter/1.0"
}

$results = @()

# =========================
# HACKER NEWS
# =========================

try {
    $stories = Invoke-RestMethod `
        -Uri "https://hacker-news.firebaseio.com/v0/newstories.json" `
        -Headers $headers `
        -TimeoutSec 20

    foreach ($id in ($stories | Select-Object -First 50)) {

        try {
            $story = Invoke-RestMethod `
                -Uri "https://hacker-news.firebaseio.com/v0/item/$id.json" `
                -Headers $headers `
                -TimeoutSec 10

            if ($story.type -eq "story" -and $story.title) {

                $results += [PSCustomObject]@{
                    name = [string]$story.title
                    url = [string]$story.url
                    source = "Hacker News"
                    discovered_at = (Get-Date).ToString("yyyy-MM-dd")
                }
            }
        }
        catch {}
    }
}
catch {}

# =========================
# TECHCRUNCH
# =========================

try {
    $response = Invoke-WebRequest `
        -UseBasicParsing `
        -Uri "https://techcrunch.com/feed/" `
        -Headers $headers `
        -TimeoutSec 20

    [xml]$xml = $response.Content

    foreach ($item in $xml.SelectNodes("//item")) {

        if ($item.title) {

            $results += [PSCustomObject]@{
                name = [string]$item.title
                url = [string]$item.link
                source = "TechCrunch"
                discovered_at = (Get-Date).ToString("yyyy-MM-dd")
            }
        }
    }
}
catch {}

# =========================
# MOTS BUSINESS
# =========================

$businessKeywords = @(
    "startup",
    "business",
    "company",
    "marketplace",
    "rental",
    "rent",
    "sharing",
    "subscription",
    "membership",
    "delivery",
    "commerce",
    "shop",
    "store",
    "product",
    "platform",
    "agency",
    "creator",
    "education",
    "course",
    "local",
    "restaurant",
    "food",
    "home",
    "cleaning",
    "repair",
    "storage",
    "parking",
    "vehicle",
    "car",
    "bike",
    "equipment",
    "space",
    "property",
    "fitness",
    "pet",
    "travel",
    "fashion",
    "beauty",
    "childcare",
    "construction",
    "moving",
    "laundry",
    "photography",
    "events",
    "micro-saas",
    "saas",
    "app",
    "software",
    "tool",
    "ai"
)

$candidates = @()

foreach ($item in $results) {

    $text = $item.name.ToLower()
    $matchCount = 0

    foreach ($keyword in $businessKeywords) {
        if ($text.Contains($keyword)) {
            $matchCount++
        }
    }

    if ($matchCount -ge 1) {

        $candidates += [PSCustomObject]@{
            name = $item.name
            url = $item.url
            source = $item.source
            discovered_at = $item.discovered_at
            keyword_matches = $matchCount
        }
    }
}

$candidates = @(
    $candidates |
    Sort-Object name -Unique |
    Sort-Object keyword_matches -Descending
)

$candidates |
    ConvertTo-Json -Depth 5 |
    Set-Content -Encoding UTF8 business_candidates_v2.json

Write-Host ""
Write-Host "BUSINESS RADAR V2"
Write-Host ""
Write-Host "Sources récupérées : $($results.Count)"
Write-Host "Business candidates : $($candidates.Count)"
Write-Host ""

$candidates |
    Select-Object -First 30 name,keyword_matches,source |
    Format-Table -AutoSize
