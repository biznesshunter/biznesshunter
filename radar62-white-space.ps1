$data = Get-Content .\radar61_go_no_go.json -Raw | ConvertFrom-Json

$results = foreach ($item in @($data)) {

    $whiteSpaceScore = 0
    $reasons = @()

    # DEMANDE RÉELLE
    if ($item.market_demand -ge 200) {
        $whiteSpaceScore += 20
        $reasons += "demande_forte"
    }
    elseif ($item.market_demand -ge 100) {
        $whiteSpaceScore += 15
        $reasons += "demande_significative"
    }
    elseif ($item.market_demand -gt 0) {
        $whiteSpaceScore += 8
    }

    # OFFRE
    if ($item.existing_supply -le 50) {
        $whiteSpaceScore += 25
        $reasons += "offre_faible"
    }
    elseif ($item.existing_supply -le 150) {
        $whiteSpaceScore += 18
        $reasons += "offre_moderee"
    }
    elseif ($item.existing_supply -le 300) {
        $whiteSpaceScore += 10
        $reasons += "offre_importante"
    }
    else {
        $whiteSpaceScore += 3
        $reasons += "offre_tres_importante"
    }

    # GAP
    if ($item.market_demand -gt 0 -and $item.existing_supply -gt 0) {

        $ratio = [double]$item.market_demand / [double]$item.existing_supply

        if ($ratio -ge 1.5) {
            $whiteSpaceScore += 25
            $reasons += "gap_fort"
        }
        elseif ($ratio -ge 1) {
            $whiteSpaceScore += 20
            $reasons += "gap_favorable"
        }
        elseif ($ratio -ge 0.75) {
            $whiteSpaceScore += 12
        }
        elseif ($ratio -ge 0.5) {
            $whiteSpaceScore += 6
        }
    }

    # PRIX
    if ($item.median_price -ge 30) {
        $whiteSpaceScore += 10
        $reasons += "ticket_interessant"
    }
    elseif ($item.median_price -ge 20) {
        $whiteSpaceScore += 7
    }
    elseif ($item.median_price -gt 0) {
        $whiteSpaceScore += 3
    }

    # POTENTIEL DE DIFFÉRENCIATION
    if ($item.existing_supply -ge 300) {
        $whiteSpaceScore -= 10
        $reasons += "forte_concurrence"
    }

    if ($whiteSpaceScore -ge 70) {
        $verdict = "STRONG_WHITE_SPACE"
    }
    elseif ($whiteSpaceScore -ge 50) {
        $verdict = "POSSIBLE_WHITE_SPACE"
    }
    elseif ($whiteSpaceScore -ge 30) {
        $verdict = "WEAK_WHITE_SPACE"
    }
    else {
        $verdict = "NO_WHITE_SPACE"
    }

    [PSCustomObject]@{
        idea_name = $item.idea_name
        country = $item.country
        city = $item.city

        validation_score = $item.validation_score
        decision = $item.decision

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

        go_score = $item.go_score
        white_space_score = $whiteSpaceScore
        verdict = $verdict
        reasons = @($reasons)
    }
}

$results |
    Sort-Object white_space_score -Descending |
    ConvertTo-Json -Depth 10 |
    Set-Content .\radar62_white_space.json -Encoding UTF8

Write-Host ""
Write-Host "WHITE SPACE ANALYSIS :" @($results).Count
Write-Host "OUTPUT               : radar62_white_space.json"
Write-Host ""

$results |
    Sort-Object white_space_score -Descending |
    Format-Table idea_name,city,white_space_score,verdict -AutoSize


