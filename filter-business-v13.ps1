$items = Get-Content .\discovered_businesses.json -Raw | ConvertFrom-Json

$results = foreach ($item in $items) {

    $title = [string]$item.name
    $lower = $title.ToLower()

    $score = 0
    $signals = @()

    # ============================================================
    # V12 — CLASSIFICATION CONSERVATRICE
    # ============================================================

    $url = [string]$item.url
    $urlLower = $url.ToLower()

    $isProduct = $false
    $isArticle = $false
    $isResearch = $false
    $isOpenSource = $false
    $isNoise = $false

    # 1. EXCLUSIONS FORTES
    $excludePatterns = @(
        "vulnerability",
        "remote code execution",
        "chip architectures",
        "chip architecture",
        "physics",
        "mathematic",
        "mathematics",
        "neutron star",
        "thermal cloak",
        "blade runner",
        "formal verification",
        "trait solver",
        "censorship",
        "collision probe",
        "space tech",
        "military",
        "defense"
    )

    foreach ($pattern in $excludePatterns) {
        if ($lower.Contains($pattern)) {
            $isNoise = $true
            $signals += "EXCLUDE:$pattern"
            break
        }
    }

    # 2. RECHERCHE
    $researchDomains = @(
        "arxiv.org",
        "researchgate.net",
        "semanticscholar.org"
    )

    foreach ($domain in $researchDomains) {
        if ($urlLower.Contains($domain)) {
            $isResearch = $true
            $signals += "SOURCE:RESEARCH"
            break
        }
    }

    # 3. ARTICLES / MÉDIAS
    $articleDomains = @(
        "techcrunch.com",
        "utilitydive.com",
        "bbc.com",
        "nytimes.com",
        "autoblog.com",
        "spectrum.ieee.org",
        "lwn.net"
    )

    foreach ($domain in $articleDomains) {
        if ($urlLower.Contains($domain)) {
            $isArticle = $true
            $signals += "SOURCE:ARTICLE"
            break
        }
    }

    # 4. BRUIT
    $noiseDomains = @(
        "youtube.com",
        "youtu.be",
        "twitter.com",
        "x.com",
        "wikipedia.org",
        "facebook.com"
    )

    foreach ($domain in $noiseDomains) {
        if ($urlLower.Contains($domain)) {
            $isNoise = $true
            $signals += "SOURCE:NOISE"
            break
        }
    }

    # 5. OPEN SOURCE
    if ($urlLower.Contains("github.com")) {
        $isOpenSource = $true
        $signals += "SOURCE:GITHUB"
    }

    # 6. SOURCES QUI PROUVENT UN PRODUIT
    $productDomains = @(
        "apps.microsoft.com",
        "play.google.com",
        "apps.apple.com",
        "producthunt.com",
        "gumroad.com",
        "patreon.com"
    )

    foreach ($domain in $productDomains) {
        if ($urlLower.Contains($domain)) {
            $isProduct = $true
            $signals += "PRODUCT:PLATFORM"
            break
        }
    }

    # 7. SHOW HN
    if ($lower -match "^show hn:") {

        $signals += "SHOW_HN"

        if (
            $lower.Contains("social network") -or
            $lower.Contains("viewer") -or
            $lower.Contains("visual ui testing") -or
            $lower.Contains("online tools") -or
            $lower.Contains("generate your") -or
            $lower.Contains("video social")
        ) {
            $isProduct = $true
            $signals += "PRODUCT:SHOW_HN"
        }
    }

    # 8. PRODUITS EXPLICITES
    #
    # Important : un mot comme "software" ou "app" dans le titre
    # ne suffit PAS à identifier un produit.
    #
    # On ne considère ici comme produit explicite que :
    # - une plateforme de vente/distribution connue
    # - certains termes très explicites dans le titre
    # - un SHOW HN décrivant clairement un produit

    $productPatterns = @(
        "saas",
        "marketplace",
        "subscription",
        "rental",
        "booking",
        "directory",
        "online tools",
        "social network",
        "video editor",
        "viewer",
        "platform",
        "product"
    )

    foreach ($pattern in $productPatterns) {

        $regex = "(^|[^a-z0-9])" + [regex]::Escape($pattern) + "([^a-z0-9]|$)"

        if ($lower -match $regex) {
            $isProduct = $true
            $signals += "PRODUCT:$pattern"
        }
    }

    # "app" et "software" seuls sont volontairement exclus :
    # ils créent trop de faux positifs sur les articles.
    # Un prix explicite dans le titre est en revanche un bon signal.
    if ($lower -match '\$\d+') {
        $isProduct = $true
        $signals += "PRODUCT:PRICE_IN_TITLE"
    }
    # 9. UN ARTICLE N'EST PAS UN PRODUIT
    if ($isArticle) {
        $isProduct = $false
    }

    # 10. UNE RECHERCHE N'EST PAS UN PRODUIT
    if ($isResearch) {
        $isProduct = $false
    }

    # 11. SCORE
    if ($isNoise) {
        $score -= 10
    }

    if ($isResearch) {
        $score -= 10
    }

    if ($isArticle) {
        $score -= 8
    }

    if ($isOpenSource) {
        $score -= 2
    }

    if ($isProduct) {
        $score += 5
        $signals += "PRODUCT_CANDIDATE"
    }

    # 12. MONÉTISATION
    $monetizationPatterns = @(
        "paid",
        "pricing",
        "price",
        "premium",
        "subscription",
        "customers",
        "revenue",
        "profit",
        "profitable",
        "sales",
        "sold",
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











