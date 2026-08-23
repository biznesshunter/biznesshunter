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

$businessModels = @(
    "rental",
    "rent",
    "sharing",
    "marketplace",
    "booking",
    "subscription",
    "membership",
    "service",
    "agency",
    "delivery",
    "cleaning",
    "repair",
    "installation",
    "storage",
    "property",
    "real estate",
    "education",
    "training",
    "fitness",
    "food",
    "restaurant",
    "commerce",
    "store",
    "shop",
    "product",
    "consumer",
    "home",
    "vehicle",
    "bike",
    "equipment",
    "event",
    "travel",
    "hospitality",
    "beauty",
    "pet",
    "childcare",
    "resale",
    "leasing",
    "franchise",
    "on-demand"
)

$softwareSignals = @(
    "saas",
    "software",
    "api",
    "developer tool",
    "github",
    "open source",
    "machine learning",
    "llm"
)

$excludeSignals = @(
    "research paper",
    "arxiv",
    "programming language",
    "chip architecture",
    "physics",
    "climate research",
    "medical research",
    "security vulnerability",
    "ai safety",
    "benchmark",
    "tariff",
    "lawsuit",
    "investigation",
    "conference ticket",
    "politics",
    "review"
)

$candidates = @()

foreach ($item in $items) {

    $text = $item.name.ToLower()

    $models = @()
    $software = @()
    $excluded = @()

    foreach ($signal in $businessModels) {

        if ($text -match [regex]::Escape($signal)) {
            $models += $signal
        }
    }

    foreach ($signal in $softwareSignals) {

        if ($text -match [regex]::Escape($signal)) {
            $software += $signal
        }
    }

    foreach ($signal in $excludeSignals) {

        if ($text -match [regex]::Escape($signal)) {
            $excluded += $signal
        }
    }

    # Aucun modèle économique détecté
    if ($models.Count -eq 0) {
        continue
    }

    # Trop de signaux indiquant que ce n'est pas un business
    if ($excluded.Count -ge 2) {
        continue
    }

    $score = 0

    # Modèle économique
    $score += $models.Count * 5

    # Bonus non-software
    if ($software.Count -eq 0) {
        $score += 10
    }

    # Bonus software mais pas dominant
    if ($software.Count -gt 0) {
        $score += 2
    }

    # Signaux économiques
    if ($text -match "revenue|customers|users|sales|profit") {
        $score += 5
    }

    if ($text -match "funding|raised|million|mrr|arr") {
        $score += 3
    }

    $candidates += [PSCustomObject]@{
        name = $item.name
        url = $item.url
        source = $item.source
        business_score = $score
        model = ($models | Select-Object -Unique) -join ", "
        type = if ($software.Count -gt 0) {
            "Software"
        } else {
            "Non-software"
        }
    }
}

$candidates = @(
    $candidates |
    Sort-Object business_score -Descending
)

$candidates |
    ConvertTo-Json -Depth 5 |
    Set-Content -Encoding UTF8 business_candidates_v5.json

Write-Host ""
Write-Host "=========================================="
Write-Host "BUSINESS RADAR V5"
Write-Host "=========================================="
Write-Host ""
Write-Host "Sources récupérées : $($items.Count)"
Write-Host "Business candidates : $($candidates.Count)"
Write-Host ""

$candidates |
    Select-Object -First 30 name,business_score,type,model |
    Format-Table -AutoSize
