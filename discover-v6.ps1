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
                    name = [string]$item.title
                    url = [string]$item.link
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

# ==========================================
# BUSINESS SIGNALS
# ==========================================

$businessSignals = @{
    "Rental / Sharing" = @(
        "rental","rent","renting","shared","sharing",
        "lease","leasing","storage","locker","parking",
        "workspace","coworking","equipment rental",
        "car rental","bike rental","tool rental"
    )

    "Marketplace" = @(
        "marketplace","platform connecting","connects buyers",
        "connects sellers","peer-to-peer","p2p",
        "two-sided marketplace","booking platform",
        "classifieds","resale marketplace"
    )

    "Local Service" = @(
        "service","services","cleaning","repair","maintenance",
        "installation","delivery","moving","landscaping",
        "home care","pet care","childcare","handyman",
        "on-demand","concierge"
    )

    "E-commerce / Product" = @(
        "product","products","store","shop","commerce",
        "consumer brand","direct-to-consumer","d2c",
        "retail","sells","selling","launches",
        "smartwatch","device","hardware"
    )

    "Food / Beverage" = @(
        "restaurant","food","meal","meals","delivery",
        "bakery","coffee","catering","kitchen",
        "grocery","groceries"
    )

    "Travel / Hospitality" = @(
        "hotel","hospitality","travel","tourism",
        "vacation rental","holiday rental","guest",
        "accommodation","booking","stay"
    )

    "Education" = @(
        "education","course","courses","training",
        "bootcamp","learning","school","tutoring",
        "classes","academy"
    )

    "Health / Fitness" = @(
        "fitness","gym","wellness","therapy",
        "clinic","health service","personal training"
    )

    "Property / Real Estate" = @(
        "real estate","property","properties",
        "housing","homes","homebuilder",
        "property management"
    )

    "Mobility" = @(
        "car","cars","vehicle","vehicles","bike",
        "bicycle","scooter","mobility","transport",
        "parking","fleet"
    )

    "Pet" = @(
        "pet","pets","dog","dogs","cat","cats",
        "pet care","pet sitting"
    )

    "Subscription" = @(
        "subscription","subscriptions",
        "membership","memberships","recurring"
    )

    "Software / AI" = @(
        "saas","software","api","platform",
        "ai startup","artificial intelligence",
        "machine learning","llm","developer tool",
        "app","application"
    )
}

# ==========================================
# FALSE POSITIVE SIGNALS
# ==========================================

$excludeSignals = @(
    "research paper",
    "arxiv",
    "physics",
    "biology research",
    "medical research",
    "climate research",
    "academic",
    "scientific",
    "programming language",
    "security vulnerability",
    "cve-",
    "benchmark",
    "conference ticket",
    "lawsuit",
    "investigation",
    "tariff",
    "politics",
    "movie",
    "film",
    "blade runner",
    "music",
    "album",
    "celebrity",
    "opinion",
    "obituary"
)

# ==========================================
# BUSINESS CONTEXT SIGNALS
# ==========================================

$strongBusinessSignals = @(
    "startup",
    "company",
    "business",
    "customers",
    "users",
    "revenue",
    "sales",
    "raised",
    "funding",
    "million",
    "launches",
    "launched",
    "growing",
    "expands",
    "expansion",
    "market",
    "customers",
    "founder"
)

$candidates = @()

foreach ($item in $items) {

    $text = $item.name.ToLower()

    $categories = @()
    $excluded = @()
    $strongSignals = @()

    foreach ($category in $businessSignals.Keys) {

        foreach ($signal in $businessSignals[$category]) {

            if ($text -match [regex]::Escape($signal)) {

                if ($categories -notcontains $category) {
                    $categories += $category
                }
            }
        }
    }

    foreach ($signal in $excludeSignals) {

        if ($text -match [regex]::Escape($signal)) {
            $excluded += $signal
        }
    }

    foreach ($signal in $strongBusinessSignals) {

        if ($text -match [regex]::Escape($signal)) {
            $strongSignals += $signal
        }
    }

    # Aucun signal business
    if ($categories.Count -eq 0) {
        continue
    }

    # Un seul signal faible + exclusion = bruit
    if ($excluded.Count -gt 0 -and $strongSignals.Count -eq 0) {
        continue
    }

    $score = 0

    # Diversité des signaux business
    $score += [Math]::Min($categories.Count * 5, 20)

    # Contexte business
    $score += [Math]::Min($strongSignals.Count * 3, 15)

    # Preuve économique explicite
    if ($text -match "revenue|customers|users|sales|profit|mrr|arr") {
        $score += 10
    }

    # Funding / traction
    if ($text -match "raised|funding|million|billion|expands|expansion") {
        $score += 5
    }

    # Bonus pour les catégories non-software
    $nonSoftwareCategories = @(
        "Rental / Sharing",
        "Marketplace",
        "Local Service",
        "E-commerce / Product",
        "Food / Beverage",
        "Travel / Hospitality",
        "Education",
        "Health / Fitness",
        "Property / Real Estate",
        "Mobility",
        "Pet"
    )

    $isNonSoftware = $false

    foreach ($category in $categories) {
        if ($nonSoftwareCategories -contains $category) {
            $isNonSoftware = $true
        }
    }

    if ($isNonSoftware) {
        $score += 10
    }

    # Catégorie dominante
    $primaryCategory = $categories[0]

    if ($categories -contains "Software / AI" -and $categories.Count -gt 1) {
        $primaryCategory = ($categories | Where-Object {
            $_ -ne "Software / AI"
        })[0]
    }

    $type = if ($isNonSoftware) {
        "Non-software"
    } else {
        "Software"
    }

    $candidates += [PSCustomObject]@{
        name = $item.name
        url = $item.url
        source = $item.source
        business_score = $score
        category = $primaryCategory
        categories = ($categories | Select-Object -Unique) -join ", "
        type = $type
    }
}

$candidates = @(
    $candidates |
    Sort-Object @{Expression="business_score";Descending=$true}
)

$candidates |
    ConvertTo-Json -Depth 6 |
    Set-Content -Encoding UTF8 .\business_candidates_v6.json

Write-Host ""
Write-Host "=========================================="
Write-Host "BUSINESS RADAR V6"
Write-Host "=========================================="
Write-Host ""
Write-Host "Sources récupérées : $($items.Count)"
Write-Host "Business candidates : $($candidates.Count)"
Write-Host ""

$candidates |
    Select-Object -First 30 name,business_score,type,category |
    Format-Table -AutoSize
