$items = Get-Content .\discovered_businesses.json -Raw | ConvertFrom-Json

$results = foreach ($item in $items) {

    $title = [string]$item.name
    $lower = $title.ToLower()

    $score = 0
    $signals = @()

    # ============================================================
    # V11 — CLASSIFICATION PAR SOURCE / TYPE DE CONTENU
    # ============================================================

    $url = [string]$item.url
    $urlLower = $url.ToLower()

    $isProduct = $false
    $isArticle = $false
    $isResearch = $false
    $isOpenSource = $false
    $isNoise = $false

    # ------------------------------------------------------------
    # 1. RECHERCHE / SCIENCE
    # ------------------------------------------------------------

    $researchPatterns = @(
        "arxiv.org",
        "researchgate",
        "semanticscholar",
        "paper",
        "preprint",
        "science",
        "physics",
        "mathematics"
    )

    foreach ($pattern in $researchPatterns) {
        if ($urlLower.Contains($pattern) -or $lower.Contains($pattern)) {
            $isResearch = $true
            break
        }
    }

    # ------------------------------------------------------------
    # 2. ARTICLES / MÉDIAS
    # ------------------------------------------------------------

    $articleDomains = @(
        "techcrunch.com",
        "utilitydive.com",
        "bbc.com",
        "nytimes.com",
        "autoblog.com",
        "spectrum.ieee.org",
        "lwn.net",
        "substack.com"
    )

    foreach ($domain in $articleDomains) {
        if ($urlLower.Contains($domain)) {
            $isArticle = $true
            break
        }
    }

    # ------------------------------------------------------------
    # 3. OPEN SOURCE / PROJET TECHNIQUE
    # ------------------------------------------------------------

    if ($urlLower.Contains("github.com")) {
        $isOpenSource = $true
    }

    # ------------------------------------------------------------
    # 4. BRUIT / CONTENU NON COMMERCIAL
    # ------------------------------------------------------------

    $noisePatterns = @(
        "youtube.com",
        "youtu.be",
        "twitter.com",
        "x.com",
        "wikipedia.org",
        "facebook.com"
    )

    foreach ($pattern in $noisePatterns) {
        if ($urlLower.Contains($pattern)) {
            $isNoise = $true
            break
        }
    }

    # ------------------------------------------------------------
    # 5. PRODUIT POTENTIEL
    # ------------------------------------------------------------

    $productPatterns = @(
        "apps.microsoft.com",
        "play.google.com",
        "apps.apple.com",
        "producthunt.com",
        "gumroad.com",
        "shopify.com",
        "stripe.com",
        "patreon.com"
    )

    foreach ($pattern in $productPatterns) {
        if ($urlLower.Contains($pattern)) {
            $isProduct = $true
            $signals += "SOURCE:PRODUCT"
            break
        }
    }

    # Site dédié avec une URL qui n'est pas un média,
    # une plateforme de recherche, un réseau social ou GitHub.
    if (
        $url -and
        -not $isArticle -and
        -not $isResearch -and
        -not $isOpenSource -and
        -not $isNoise -and
        $urlLower -match "^https?://"
    ) {
        $isProduct = $true
        $signals += "SOURCE:DEDICATED_SITE"
    }

    # ------------------------------------------------------------
    # 6. SCORE
    # ------------------------------------------------------------

    if ($isResearch) {
        $score -= 10
        $signals += "EXCLUDE:RESEARCH"
    }
    elseif ($isNoise) {
        $score -= 10
        $signals += "EXCLUDE:NOISE"
    }
    elseif ($isArticle) {
        $score -= 8
        $signals += "SOURCE:ARTICLE"
    }
    elseif ($isOpenSource) {
        $score -= 3
        $signals += "SOURCE:OPEN_SOURCE"
    }

    if ($isProduct) {
        $score += 5
        $signals += "PRODUCT_CANDIDATE"
    }

    # ------------------------------------------------------------
    # 7. SIGNATURES BUSINESS
    # ------------------------------------------------------------

    $businessPatterns = @(
        "marketplace",
        "subscription",
        "saas",
        "rental",
        "booking",
        "delivery",
        "membership",
        "directory",
        "bootcamp",
        "course",
        "training",
        "platform",
        "service",
        "social network",
        "software",
        "app",
        "tool",
        "product",
        "creator"
    )

    foreach ($pattern in $businessPatterns) {

        $regex = "(^|[^a-z0-9])" + [regex]::Escape($pattern) + "([^a-z0-9]|$)"

        if ($lower -match $regex) {
            $score += 1
            $signals += "BUSINESS:$pattern"
        }
    }

    # ------------------------------------------------------------
    # 8. MONÉTISATION
    # ------------------------------------------------------------

    $monetizationPatterns = @(
        "paid",
        "pricing",
        "price",
        "subscription",
        "premium",
        "customers",
        "customer",
        "revenue",
        "profit",
        "profitable",
        "sold",
        "sales",
        "funding",
        "raised"
    )

    foreach ($pattern in $monetizationPatterns) {

        $regex = "(^|[^a-z0-9])" + [regex]::Escape($pattern) + "([^a-z0-9]|$)"

        if ($lower -match $regex) {
            $score += 2
            $signals += "MONETIZATION:$pattern"
        }
    }

    # ------------------------------------------------------------
    # 9. SHOW HN
    # ------------------------------------------------------------

    if ($lower -match "^show hn:") {
        $score += 1
        $signals += "SHOW_HN"
    }

    # ------------------------------------------------------------
    # 10. SEUIL
    # ------------------------------------------------------------
    if ($score -ge 1) {

        [PSCustomObject]@{
            name = $title
            url = $item.url
            source = $item.source
            business_score = $score
            signals = ($signals -join ", ")
        }
    }
}

$results |
    Sort-Object business_score -Descending |
    ConvertTo-Json -Depth 5 |
    Set-Content -Encoding UTF8 business_candidates.json

Write-Host ""
Write-Host "BUSINESS CANDIDATES : $($results.Count)"
Write-Host ""

$results |
    Select-Object -First 20 name,business_score,source |
    Format-Table -AutoSize









