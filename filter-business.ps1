$items = Get-Content .\discovered_businesses.json -Raw | ConvertFrom-Json

$results = foreach ($item in $items) {

    $title = [string]$item.name
    $lower = $title.ToLower()

    $score = 0
    $signals = @()

    # Très fort signal
    if ($lower -match "^show hn:") {
        $score += 5
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
        "revenue",
        "business",
        "bootcamp",
        "tool"
    )

    foreach ($word in $businessWords) {
        if ($lower.Contains($word)) {
            $score += 1
            $signals += $word
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
        "review",
        "lawsuit",
        "privacy",
        "encryption",
        "obsolet",
        "physics",
        "mathematic"
    )

    foreach ($word in $negativeWords) {
        if ($lower.Contains($word)) {
            $score -= 4
        }
    }

    if ($score -ge 3) {

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
