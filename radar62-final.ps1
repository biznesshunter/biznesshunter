$data = Get-Content .\radar58*.json -Raw | ConvertFrom-Json

$results = foreach ($item in @($data)) {

    $baseScore = [double]$item.biznesshunter_score
    $adjustment = 0
    $reasons = @()

    if ($item.demand -ge 200) {
        $adjustment += 5
        $reasons += "demande_forte"
    }
    elseif ($item.demand -ge 100) {
        $adjustment += 2
        $reasons += "demande_significative"
    }
    elseif ($item.demand -lt 50) {
        $adjustment -= 10
        $reasons += "demande_faible"
    }

    if ($item.supply -le 50) {
        $adjustment += 8
        $reasons += "offre_faible"
    }
    elseif ($item.supply -le 150) {
        $adjustment += 4
        $reasons += "offre_moderee"
    }
    elseif ($item.supply -le 300) {
        $adjustment -= 3
        $reasons += "concurrence_importante"
    }
    elseif ($item.supply -le 500) {
        $adjustment -= 8
        $reasons += "concurrence_tres_forte"
    }
    else {
        $adjustment -= 12
        $reasons += "concurrence_extreme"
    }

    if ($item.median_price -ge 30) {
        $adjustment += 4
        $reasons += "ticket_interessant"
    }
    elseif ($item.median_price -ge 20) {
        $adjustment += 2
        $reasons += "ticket_correct"
    }
    elseif ($item.median_price -lt 10) {
        $adjustment -= 4
        $reasons += "ticket_faible"
    }

    if ($item.supply -gt 0) {
        $ratio = [double]$item.demand / [double]$item.supply

        if ($ratio -ge 1.5) {
            $adjustment += 10
            $reasons += "demande_superieure_a_offre"
        }
        elseif ($ratio -ge 1) {
            $adjustment += 5
            $reasons += "demande_proche_de_offre"
        }
        elseif ($ratio -lt 0.5) {
            $adjustment -= 5
            $reasons += "offre_tres_superieure_a_demande"
        }
    }

    $finalScore = $baseScore + $adjustment
    $finalScore = [math]::Max(0,[math]::Min(100,$finalScore))

    if ($finalScore -ge 80) {
        $decision = "GO"
    }
    elseif ($finalScore -ge 65) {
        $decision = "TEST"
    }
    elseif ($finalScore -ge 50) {
        $decision = "WATCH"
    }
    else {
        $decision = "REJECT"
    }

    if ($item.supply -le 50) {
        $competitionLevel = "LOW"
    }
    elseif ($item.supply -le 150) {
        $competitionLevel = "MODERATE"
    }
    elseif ($item.supply -le 300) {
        $competitionLevel = "HIGH"
    }
    elseif ($item.supply -le 500) {
        $competitionLevel = "VERY_HIGH"
    }
    else {
        $competitionLevel = "EXTREME"
    }

    [PSCustomObject]@{
        idea_name = $item.idea_name
        country = $item.country
        city = $item.city
        biznesshunter_score = $baseScore
        final_score = [math]::Round($finalScore,1)
        decision = $decision
        market_score = $item.market_score
        market_verdict = $item.market_verdict
        demand = $item.demand
        supply = $item.supply
        median_price = $item.median_price
        price_samples = $item.price_samples
        market_proof_score = $item.market_proof_score
        business_proof_score = $item.business_proof_score
        competition_score = $item.competition_score
        capital_score = $item.capital_score
        home_based_score = $item.home_based_score
        automation_score = $item.automation_score
        human_presence_score = $item.human_presence_score
        geographic_replication_score = $item.geographic_replication_score
        competition_level = $competitionLevel
        sources = @($item.sources)
        adjustment = $adjustment
        reasons = @($reasons)
    }
}

$results |
    Sort-Object final_score -Descending |
    ConvertTo-Json -Depth 10 |
    Set-Content .\radar62_final.json -Encoding UTF8

Write-Host ""
Write-Host "FINAL BIZNESSHUNTER RADAR :" @($results).Count
Write-Host "OUTPUT                     : radar62_final.json"
Write-Host ""

$results |
    Sort-Object final_score -Descending |
    Format-Table idea_name,city,biznesshunter_score,final_score,decision,competition_level -AutoSize
