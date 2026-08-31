$data = Get-Content .\radar58_qualified_opportunities.json -Raw |
    ConvertFrom-Json

$results = foreach ($item in @($data)) {

    $score = 0

    # DEMANDE
    if ($item.demand -ge 500) {
        $score += 20
    }
    elseif ($item.demand -ge 250) {
        $score += 17
    }
    elseif ($item.demand -ge 100) {
        $score += 14
    }
    elseif ($item.demand -gt 0) {
        $score += 8
    }

    # TRANSACTIONS / PRIX
    if ($item.price_samples -ge 50) {
        $score += 15
    }
    elseif ($item.price_samples -ge 20) {
        $score += 12
    }
    elseif ($item.price_samples -ge 5) {
        $score += 8
    }

    # PREUVE MULTI-SOURCE
    if (@($item.sources).Count -ge 2) {
        $score += 15
    }
    else {
        $score += 7
    }

    # FAIBLE CAPITAL
    $score += $item.capital_score

    # AUTOMATISATION
    $score += $item.automation_score

    # PRESENCE HUMAINE
    $score += $item.human_presence_score

    # REPLICATION
    $score += $item.geographic_replication_score

    # PÉNALITÉ CONCURRENCE
    if ($item.supply -ge 500) {
        $score -= 15
    }
    elseif ($item.supply -ge 300) {
        $score -= 10
    }
    elseif ($item.supply -ge 150) {
        $score -= 5
    }

    if ($score -ge 80) {
        $verdict = "STRONG"
    }
    elseif ($score -ge 65) {
        $verdict = "VALIDATE"
    }
    elseif ($score -ge 50) {
        $verdict = "WATCH"
    }
    else {
        $verdict = "REJECT"
    }

    [PSCustomObject]@{
        idea_name = $item.idea_name
        country = $item.country
        city = $item.city
        demand = $item.demand
        supply = $item.supply
        median_price = $item.median_price
        biznesshunter_score = $item.biznesshunter_score
        validation_score = $score
        verdict = $verdict
        sources = @($item.sources)
    }
}

$results |
    Sort-Object validation_score -Descending |
    ConvertTo-Json -Depth 10 |
    Set-Content .\radar59_validated_opportunities.json -Encoding UTF8

Write-Host ""
Write-Host "VALIDATED OPPORTUNITIES :" @($results).Count
Write-Host "OUTPUT                  : radar59_validated_opportunities.json"
Write-Host ""

$results |
    Sort-Object validation_score -Descending |
    Format-Table `
        idea_name,
        city,
        biznesshunter_score,
        validation_score,
        verdict `
        -AutoSize
