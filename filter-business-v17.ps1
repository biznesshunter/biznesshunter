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
    #
    # SHOW HN = preuve qu'un projet existe.
    # Mais ce n'est PAS une preuve de business.
    #
    # On ne donne le statut produit que si le titre décrit
    # explicitement une offre utilisable par un utilisateur.

    if ($lower -match "^show hn:") {

        $signals += "SHOW_HN"

        $showHNProductPatterns = @(
            "social network",
            "online tools",
            "viewer",
            "video editor",
            "visual ui testing",
            "generate your",
            "platform",
            "service",
            "marketplace",
            "saas",
            "subscription"
        )

        foreach ($pattern in $showHNProductPatterns) {

            if ($lower.Contains($pattern)) {
                $isProduct = $true
                $signals += "PRODUCT:SHOW_HN:$pattern"
                break
            }
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


    # 12. CLASSIFICATION BUSINESS
    #
    # Objectif :
    # distinguer un vrai produit/business d'un simple projet technique.
    #
    # Le type sera utilisé ensuite par le moteur BiznessHunter.

    $businessType = "UNKNOWN"

    # 12.1 PRODUIT PAYANT EXPLICITE
    if (
        $lower -match '\$\d+' -or
        $lower.Contains("paid") -or
        $lower.Contains("pricing") -or
        $lower.Contains("subscription")
    ) {
        $businessType = "PAID_PRODUCT"
    }

    # 12.2 COMPOSANT / OUTIL POUR DÉVELOPPEURS
    if (
        $lower.Contains("component") -or
        $lower.Contains("library") -or
        $lower.Contains("sdk") -or
        $lower.Contains("mcp/cli") -or
        $lower.Contains("cli")
    ) {
        $businessType = "DEVELOPER_COMPONENT"
    }

    # 12.3 OPEN SOURCE
    if ($isOpenSource) {
        $businessType = "OPEN_SOURCE"
    }

    # 12.4 OUTIL GRATUIT
    if (
        $lower.Contains("free online tools") -or
        $lower.Contains("free tools") -or
        $lower.Contains("free tool")
    ) {
        $businessType = "FREE_TOOL"
    }

    # 12.5 RÉSEAU SOCIAL / PLATEFORME
    if (
        $lower.Contains("social network") -or
        $lower.Contains("marketplace")
    ) {
        $businessType = "SOCIAL_PLATFORM"
    }

    # 12.6 PRODUIT PAYANT PRIORITAIRE
    # Le prix explicite doit rester prioritaire sauf si
    # le candidat est clairement un composant développeur.
    if (
        $lower -match '\$\d+' -and
        $businessType -ne "DEVELOPER_COMPONENT"
    ) {
        $businessType = "PAID_PRODUCT"
    }

    # 12.7 SCORE DE BASE
    #
    # On arrête de donner automatiquement +3/+5 à tout produit.
    # Le type de business détermine maintenant la valeur du candidat.

    switch ($businessType) {

        "PAID_PRODUCT" {
            $score += 8
            $signals += "BUSINESS_TYPE:PAID_PRODUCT"
        }

        "FREE_TOOL" {
            $score += 1
            $signals += "BUSINESS_TYPE:FREE_TOOL"
        }

        "SOCIAL_PLATFORM" {
            $score += 2
            $signals += "BUSINESS_TYPE:SOCIAL_PLATFORM"
        }

        "OPEN_SOURCE" {
            $score -= 3
            $signals += "BUSINESS_TYPE:OPEN_SOURCE"
        }

        "DEVELOPER_COMPONENT" {
            $score -= 5
            $signals += "BUSINESS_TYPE:DEVELOPER_COMPONENT"
        }

        default {
            $score -= 2
            $signals += "BUSINESS_TYPE:UNKNOWN"
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














