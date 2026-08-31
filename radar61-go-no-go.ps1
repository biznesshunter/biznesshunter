$data = Get-Content .\radar60_opportunity_cards.json -Raw |
    ConvertFrom-Json

$results = foreach ($item in @($data)) {

    $goScore = [double]$item.validation_score

    # Forte concurrence
    if ($item.existing_supply -ge 300) {
        $goScore -= 10
    }
    elseif ($item.existing_supply -ge 150) {
        $goScore -= 5
    }

    # Demande insuffisante
    if ($item.market_demand -lt 50) {
        $goScore -= 10
    }

    # Test peu coûteux
    if ($item.test_cost_eur -le 100) {
        $goScore += 5
    }

    if ($goScore -ge 75) {
        $decision = "GO"
    }
    elseif ($goScore -ge 60) {
        $decision = "TEST"
    }
    else {
        $decision = "NO-GO"
    }

    [PSCustomObject]@{
        idea_name = $item.idea_name
        country = $item.country
        city = $item.city

        validation_score = $item.validation_score
        go_score = $goScore
        decision = $decision

        market_demand = $item.market_demand
        existing_supply = $item.existing_supply
        median_price = $item.median_price

        test_cost_eur = $item.test_cost_eur
        customer = $item.customer
        business_model = $item.business_model
        revenue_model = $item.revenue_model

        market_proof = $item.market_proof
        main_risk = $item.main_risk
        validation_test = $item.validation_test
        replication_strategy = $item.replication_strategy

        sources = @($item.sources)
    }
}

$results |
    Sort-Object go_score -Descending |
    ConvertTo-Json -Depth 10 |
    Set-Content .\radar61_go_no_go.json -Encoding UTF8

Write-Host ""
Write-Host "DECISIONS :" @($results).Count
Write-Host "OUTPUT    : radar61_go_no_go.json"
Write-Host ""

$results |
    Format-Table `
        idea_name,
        city,
        validation_score,
        go_score,
        decision `
        -AutoSize

