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
# BUSINESS CATEGORIES
# ==========================================

$signals = @{
    "Rental / Sharing" = @(
        "rental","renting","lease","leasing","shared",
        "sharing","peer-to-peer","p2p","storage",
        "locker","parking","workspace","coworking",
        "equipment rental","tool rental","vehicle rental"
    )

    "Marketplace" = @(
        "marketplace","booking platform","connects buyers",
        "connects sellers","buyers and sellers",
        "peer-to-peer marketplace","resale marketplace",
        "platform for sellers","platform for buyers"
    )

    "Local Service" = @(
        "cleaning","repair","maintenance","installation",
        "delivery service","moving service","handyman",
        "landscaping","home care","pet care",
        "childcare","concierge","on-demand service",
        "property management"
    )

    "Product / E-commerce" = @(
        "consumer product","consumer brand","direct-to-consumer",
        "d2c","retail","store","shop","product launch",
        "physical product","device","hardware","sells",
        "selling","brand"
    )

    "Food / Hospitality" = @(
        "restaurant","food business","meal delivery",
        "bakery","coffee shop","catering","grocery",
        "hotel","hospitality","accommodation",
        "vacation rental","holiday rental"
    )

    "Education" = @(
        "course","courses","training","bootcamp",
        "tutoring","academy","classes","education",
        "learning platform","school"
    )

    "Health / Fitness" = @(
        "gym","fitness","wellness","personal training",
        "therapy service","clinic","health service"
    )

    "Mobility" = @(
        "car rental","bike rental","vehicle",
        "vehicles","fleet","parking","scooter",
        "bicycle","mobility service","transport"
    )

    "Pet" = @(
        "pet sitting","dog walking","pet care",
        "dog daycare","pet service"
    )

    "Subscription" = @(
        "subscription","membership","recurring",
        "monthly membership","monthly subscription"
    )

    "Software / AI" = @(
        "saas","software","api","developer tool",
        "ai startup","ai-powered","artificial intelligence",
        "machine learning","llm","app","application"
    )
}

# ==========================================
# POSITIVE BUSINESS SIGNALS
# ==========================================

$tractionSignals = @(
    "customers",
    "users",
    "revenue",
    "sales",
    "profit",
    "mrr",
    "arr",
    "orders",
    "bookings",
    "members",
    "stores",
    "locations",
    "launched",
    "launches",
    "growing",
    "growth",
    "expands",
    "expansion",
    "demand",
    "popular",
    "sold",
    "selling"
)

$capitalSignals = @(
    "raised $",
    "raised €",
    "raised £",
    "funding",
    "million",
    "billion",
    "venture capital",
    "series a",
    "series b",
    "series c"
)

# ==========================================
# NEGATIVE SIGNALS
# ==========================================

$negativeSignals = @(
    "research paper",
    "arxiv",
    "academic",
    "scientific paper",
    "physics",
    "biology research",
    "medical research",
    "climate research",
    "programming language",
    "security vulnerability",
    "cve-",
    "benchmark",
    "conference ticket",
    "lawsuit",
    "investigation",
    "tariff",
    "politics",
    "election",
    "obituary",
    "movie",
    "film",
    "blade runner",
    "album",
    "music review",
    "product review",
    "review:",
    "review –",
    "review -"
)

# ==========================================
# HIGH CAPITAL / HARD COPY SIGNALS
# ==========================================

$hardCopySignals = @(
    "rocket",
    "satellite",
    "spacecraft",
    "nuclear",
    "chip manufacturing",
    "semiconductor fab",
    "battery manufacturing",
    "military",
    "defense contractor",
    "clinical trial",
    "drug discovery",
    "biotech",
    "data center",
    "aircraft",
    "automotive manufacturing",
    "factory"
)

$candidates = @()

foreach ($item in $items) {

    $text = $item.name.ToLower()

    $categories = @()
    $traction = @()
    $negative = @()
    $hardCopy = @()

    foreach ($category in $signals.Keys) {
        foreach ($signal in $signals[$category]) {
            if ($text -match [regex]::Escape($signal)) {
                if ($categories -notcontains $category) {
                    $categories += $category
                }
            }
        }
    }

    foreach ($signal in $tractionSignals) {
        if ($text -match [regex]::Escape($signal)) {
            $traction += $signal
        }
    }

    foreach ($signal in $negativeSignals) {
        if ($text -match [regex]::Escape($signal)) {
            $negative += $signal
        }
    }

    foreach ($signal in $hardCopySignals) {
        if ($text -match [regex]::Escape($signal)) {
            $hardCopy += $signal
        }
    }

    # Pas de modèle business
    if ($categories.Count -eq 0) {
        continue
    }

    # Article manifestement non-business
    if ($negative.Count -ge 2) {
        continue
    }

    # Les articles purement journalistiques sans traction sont faibles
    if ($negative.Count -gt 0 -and $traction.Count -eq 0) {
        continue
    }

    $score = 0

    # Diversité business
    $score += [Math]::Min($categories.Count * 6, 24)

    # Traction
    $score += [Math]::Min($traction.Count * 3, 15)

    # Signaux économiques
    if ($text -match "revenue|sales|profit|customers|users|orders|bookings|members") {
        $score += 10
    }

    # Croissance / expansion
    if ($text -match "growth|growing|expands|expansion|demand|popular") {
        $score += 5
    }

    # Capital : intéressant comme preuve de marché,
    # mais pas forcément intéressant comme copie
    if ($text -match "raised|funding|million|billion") {
        $score += 3
    }

    # Malus forte intensité capitalistique
    if ($hardCopy.Count -gt 0) {
        $score -= [Math]::Min($hardCopy.Count * 5, 15)
    }

    # Bonus aux modèles potentiellement copiables seul
    $soloCategories = @(
        "Local Service",
        "Rental / Sharing",
        "Marketplace",
        "Product / E-commerce",
        "Education",
        "Pet",
        "Subscription"
    )

    foreach ($category in $categories) {
        if ($soloCategories -contains $category) {
            $score += 5
            break
        }
    }

    # Software reste accepté mais sans bonus spécial
    $type = if ($categories -contains "Software / AI") {
        if ($categories.Count -gt 1) {
            "Hybrid"
        } else {
            "Software"
        }
    } else {
        "Non-software"
    }

    # Catégorie principale
    $primary = $categories[0]

    if ($categories.Count -gt 1) {

        foreach ($preferred in @(
            "Marketplace",
            "Rental / Sharing",
            "Local Service",
            "Product / E-commerce",
            "Education",
            "Food / Hospitality",
            "Mobility",
            "Pet",
            "Subscription",
            "Software / AI"
        )) {
            if ($categories -contains $preferred) {
                $primary = $preferred
                break
            }
        }
    }

    # Score minimum
    if ($score -lt 8) {
        continue
    }

    $candidates += [PSCustomObject]@{
        name = $item.name
        url = $item.url
        source = $item.source
        business_score = $score
        type = $type
        category = $primary
        categories = ($categories | Select-Object -Unique) -join ", "
        traction_signals = ($traction | Select-Object -Unique) -join ", "
        capital_signals = if ($text -match "raised|funding|million|billion") {
            "Yes"
        } else {
            "No"
        }
        copy_difficulty = if ($hardCopy.Count -gt 0) {
            "High"
        } else {
            "Normal"
        }
    }
}

$candidates = @(
    $candidates |
    Sort-Object -Property @{Expression="business_score";Descending=$true}
)

$candidates |
    ConvertTo-Json -Depth 6 |
    Set-Content -Encoding UTF8 .\business_candidates_v7.json

Write-Host ""
Write-Host "=========================================="
Write-Host "BUSINESS RADAR V7"
Write-Host "=========================================="
Write-Host ""
Write-Host "Sources récupérées : $($items.Count)"
Write-Host "Business candidates : $($candidates.Count)"
Write-Host ""

$candidates |
    Select-Object -First 30 name,business_score,type,category,copy_difficulty |
    Format-Table -AutoSize
