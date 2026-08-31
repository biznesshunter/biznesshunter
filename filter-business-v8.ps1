$items = Get-Content .\discovered_businesses.json -Raw | ConvertFrom-Json

$results = foreach ($item in $items) {

    $title = [string]$item.name
    $lower = $title.ToLower()

    $score = 0
    $signals = @()

    # Signal de lancement
    if ($lower -match "^show hn:") {
        $score += 2
        $signals += "SHOW_HN"
    }

    # Signaux business
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
        "market",
        "creator",
        "social network"
    )

    foreach ($word in $businessWords) {
        if ($lower.Contains($word)) {
            $score += 1
            $signals += $word
        }
    }

    # Signaux techniques : légère pénalité seulement
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
        }
    }

    # Signaux fortement défavorables
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
        "collision probe"
    )

    foreach ($word in $negativeWords) {
        if ($lower.Contains($word)) {
            $score -= 4
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






