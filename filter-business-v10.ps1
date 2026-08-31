$items = Get-Content .\discovered_businesses.json -Raw | ConvertFrom-Json

$results = foreach ($item in $items) {

    $title = [string]$item.name
    $lower = $title.ToLower()

    $score = 0
    $signals = @()

    # ============================================================
    # V10 — IDENTIFICATION DU TYPE DE CONTENU
    # ============================================================

    $isBusiness = $false
    $isArticle = $false
    $isResearch = $false
    $isTechnical = $false

    # ------------------------------------------------------------
    # 1. ARTICLES / CONTENU ÉDITORIAL
    # ------------------------------------------------------------

    $articlePatterns = @(
        "how ",
        "why ",
        "what ",
        "the ",
        "a ",
        "an ",
        "guide",
        "review",
        "risks of",
        "most popular",
        "software engineering in",
        "treat ai like",
        "you don't have to",
        "reportedly",
        "is training",
        "is cutting",
        "approves",
        "partners with",
        "hands over",
        "reaches",
        "becomes",
        "raised",
        "raising",
        "expands"
    )

    foreach ($pattern in $articlePatterns) {
        if ($lower.StartsWith($pattern) -or $lower.Contains(" $pattern")) {
            $isArticle = $true
            break
        }
    }

    # ------------------------------------------------------------
    # 2. RECHERCHE / SCIENCE
    # ------------------------------------------------------------

    $researchPatterns = @(
        "arxiv.org",
        "research",
        "paper",
        "inference",
        "architecture",
        "physics",
        "mathematics",
        "mathematic",
        "formal verification",
        "neutron star",
        "chip architecture"
    )

    foreach ($pattern in $researchPatterns) {
        if ($lower.Contains($pattern)) {
            $isResearch = $true
            break
        }
    }

    # ------------------------------------------------------------
    # 3. TECHNIQUE PUR
    # ------------------------------------------------------------

    $technicalPatterns = @(
        "github.com",
        "rust",
        "react",
        "mcp",
        "cli",
        "coding agent",
        "developer",
        "software engineering",
        "open source",
        "fossil-scm"
    )

    foreach ($pattern in $technicalPatterns) {
        if ($lower.Contains($pattern)) {
            $isTechnical = $true
            break
        }
    }

    # ------------------------------------------------------------
    # 4. SIGNALS DE BUSINESS RÉEL
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
        "product"
    )

    foreach ($pattern in $businessPatterns) {

        # Recherche par mot entier pour éviter les faux positifs
        $regex = "(^|[^a-z0-9])" + [regex]::Escape($pattern) + "([^a-z0-9]|$)"

        if ($lower -match $regex) {
            $isBusiness = $true
            $signals += "BUSINESS:$pattern"
        }
    }

    # ------------------------------------------------------------
    # 5. SIGNAL EXPLICITE DE MONÉTISATION
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
        "sales"
    )

    foreach ($pattern in $monetizationPatterns) {

        $regex = "(^|[^a-z0-9])" + [regex]::Escape($pattern) + "([^a-z0-9]|$)"

        if ($lower -match $regex) {
            $score += 2
            $signals += "MONETIZATION:$pattern"
        }
    }

    # ------------------------------------------------------------
    # 6. SHOW HN = produit existant mais pas forcément business
    # ------------------------------------------------------------

    if ($lower -match "^show hn:") {
        $score += 1
        $signals += "SHOW_HN"
    }

    # ------------------------------------------------------------
    # 7. EXCLUSIONS FORTES
    # ------------------------------------------------------------

    if ($isResearch) {
        $score -= 10
        $signals += "EXCLUDE:RESEARCH"
    }

    if ($isArticle -and -not $isBusiness) {
        $score -= 10
        $signals += "EXCLUDE:ARTICLE"
    }

    if ($isTechnical -and -not $isBusiness) {
        $score -= 6
        $signals += "EXCLUDE:TECHNICAL"
    }

    # ------------------------------------------------------------
    # 8. BUSINESS IDENTIFIABLE
    # ------------------------------------------------------------

    if ($isBusiness) {
        $score += 4
        $signals += "IDENTIFIABLE_BUSINESS"
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








