$items = Get-Content .\discovered_businesses.json -Raw | ConvertFrom-Json

$results = foreach ($item in $items) {

    $title = [string]$item.name
    $lower = $title.ToLower()

    $score = 0
    $signals = @()

    # ============================================================
    # V9 — BUSINESSHUNTER QUALIFICATION
    # ============================================================

    # ------------------------------------------------------------
    # 1. Signal de produit / business
    # ------------------------------------------------------------
    $businessWords = @(
        "startup",
        "company",
        "marketplace",
        "platform",
        "service",
        "rental",
        "subscription",
        "saas",
        "customers",
        "customer",
        "revenue",
        "business",
        "bootcamp",
        "tool",
        "paid",
        "pricing",
        "price",
        "premium",
        "pro",
        "users",
        "booking",
        "delivery",
        "membership",
        "course",
        "training",
        "directory",
        "app",
        "software",
        "product",
        "sell",
        "selling",
        "commerce",
        "store",
        "marketplace",
        "creator",
        "social network"
    )

    foreach ($word in $businessWords) {
        if ($lower.Contains($word)) {
            $score += 2
            $signals += "BUSINESS:$word"
        }
    }

    # ------------------------------------------------------------
    # 2. Preuves de monétisation / traction
    # ------------------------------------------------------------
    $tractionWords = @(
        "revenue",
        "customers",
        "customer",
        "paid",
        "pricing",
        "price",
        "subscription",
        "users",
        "sales",
        "sold",
        "profit",
        "profitable",
        "funding",
        "raised",
        "million",
        "acquired",
        "acquisition",
        "growth",
        "growing"
    )

    foreach ($word in $tractionWords) {
        if ($lower.Contains($word)) {
            $score += 2
            $signals += "TRACTION:$word"
        }
    }

    # ------------------------------------------------------------
    # 3. Modèles particulièrement intéressants pour BiznessHunter
    # ------------------------------------------------------------
    $replicationWords = @(
        "directory",
        "marketplace",
        "booking",
        "rental",
        "subscription",
        "membership",
        "course",
        "training",
        "service",
        "software",
        "saas",
        "tool",
        "delivery",
        "creator",
        "social network",
        "online",
        "app"
    )

    foreach ($word in $replicationWords) {
        if ($lower.Contains($word)) {
            $score += 1
            $signals += "REPLICABLE:$word"
        }
    }

    # ------------------------------------------------------------
    # 4. Show HN = signal intéressant mais pas preuve de business
    # ------------------------------------------------------------
    if ($lower -match "^show hn:") {
        $score += 1
        $signals += "SHOW_HN"
    }

    # ------------------------------------------------------------
    # 5. Technique = petite pénalité
    # ------------------------------------------------------------
    $technicalWords = @(
        "developer",
        "coding agent",
        "mcp",
        "cli",
        "rust",
        "react",
        "github",
        "json-ld",
        "open source"
    )

    foreach ($word in $technicalWords) {
        if ($lower.Contains($word)) {
            $score -= 1
            $signals += "TECH:$word"
        }
    }

    # ------------------------------------------------------------
    # 6. Faux positifs / sujets peu exploitables
    # ------------------------------------------------------------
    $negativeWords = @(
        "vulnerability",
        "research",
        "paper",
        "chip architectures",
        "military",
        "defense",
        "satellite",
        "space tech",
        "lawsuit",
        "encryption",
        "physics",
        "mathematic",
        "mathematics",
        "neutron stars",
        "formal verification",
        "censorship",
        "collision probe",
        "review",
        "cutting jobs",
        "layoffs",
        "reportedly",
        "risks of",
        "guide",
        "how to",
        "most popular",
        "video"
    )

    foreach ($word in $negativeWords) {
        if ($lower.Contains($word)) {
            $score -= 5
            $signals += "NEGATIVE:$word"
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







