$ErrorActionPreference = "SilentlyContinue"

$headers = @{
    "User-Agent" = "BiznessHunter/1.0"
}

$feeds = @(
    "https://news.ycombinator.com/rss",
    "https://techcrunch.com/feed/"
)

$items = @()

foreach ($feed in $feeds) {
    try {
        $response = Invoke-WebRequest `
            -UseBasicParsing `
            -Uri $feed `
            -Headers $headers `
            -TimeoutSec 20

        [xml]$xml = $response.Content

        foreach ($item in $xml.SelectNodes("//item")) {

            if ($item.title) {
                $items += [PSCustomObject]@{
                    name   = [string]$item.title
                    url    = [string]$item.link
                    source = if ($feed -match "ycombinator") {
                        "Hacker News"
                    } else {
                        "TechCrunch"
                    }
                }
            }
        }
    }
    catch {}
}

$positive = @(
    "rental","rent","sharing","marketplace","booking",
    "subscription","membership","service","agency",
    "local business","local service","delivery",
    "cleaning","repair","installation","storage",
    "property","real estate","education","training",
    "fitness","food","restaurant","commerce","store",
    "shop","product","consumer","home","vehicle",
    "car","bike","equipment","event","travel",
    "hospitality","beauty","pet","childcare",
    "franchise","platform","creator","resale",
    "used","leasing","on-demand","community",
    "customers","revenue","sales","profit",
    "users","paid","pricing","business model"
)

$negative = @(
    "research paper","arxiv","algorithm",
    "programming language","developer tool",
    "open source library","github repository",
    "chip architecture","quantum","physics",
    "climate research","medical research",
    "security vulnerability","technical paper",
    "ai safety","machine learning benchmark"
)

$candidates = @()

foreach ($item in $items) {

    $content = ""

    # =========================
    # RÉCUPÉRATION DE LA PAGE
    # =========================

    if ($item.url) {
        try {

            $page = Invoke-WebRequest `
                -UseBasicParsing `
                -Uri $item.url `
                -Headers $headers `
                -TimeoutSec 15

            $content = $page.Content

            $content = $content `
                -replace '<script[\s\S]*?</script>', ' ' `
                -replace '<style[\s\S]*?</style>', ' ' `
                -replace '<[^>]+>', ' ' `
                -replace '\s+', ' '

        }
        catch {}
    }

    $text = (
        $item.name + " " + $content
    ).ToLower()

    $score = 0
    $matched = @()

    foreach ($word in $positive) {

        if ($text -match [regex]::Escape($word)) {

            $score++
            $matched += $word
        }
    }

    foreach ($word in $negative) {

        if ($text -match [regex]::Escape($word)) {
            $score -= 2
        }
    }

    # Preuve économique forte
    if ($text -match "\$[0-9]+") {
        $score += 2
    }

    if ($text -match "[0-9]+%") {
        $score += 1
    }

    if ($text -match "customers|users|revenue|sales|profit|funding") {
        $score += 2
    }

    # =========================
    # SEUIL
    # =========================

    if ($score -ge 4) {

        $candidates += [PSCustomObject]@{
            name = $item.name
            url = $item.url
            source = $item.source
            business_score = $score
            matched_signals = ($matched | Select-Object -Unique) -join ", "
        }
    }
}

$candidates = $candidates |
    Sort-Object business_score -Descending

$candidates |
    ConvertTo-Json -Depth 5 |
    Set-Content -Encoding UTF8 business_candidates_v4.json

Write-Host ""
Write-Host "=========================================="
Write-Host "BUSINESS RADAR V4"
Write-Host "=========================================="
Write-Host ""
Write-Host "Sources récupérées : $($items.Count)"
Write-Host "Business candidates : $($candidates.Count)"
Write-Host ""

$candidates |
    Select-Object -First 30 name,business_score,matched_signals,source |
    Format-Table -AutoSize
