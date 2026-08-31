$data = Get-Content .\radar62_final.json -Raw | ConvertFrom-Json

$results = foreach ($item in @($data)) {

    $score = [double]$item.biznesshunter_score
    $reasons = @()

    # ============================================================
    # DEMANDE
    # ============================================================

    if ($item.demand -ge 200) {
        $score += 5
        $reasons += "demande_forte"
    }
    elseif ($item.demand -lt 50) {
        $score -= 10
        $reasons += "demande_faible"
    }

    # ============================================================
    # SATURATION DU MARCHÉ
    # ============================================================

    if ($item.supply -le 50) {
        $score += 8
        $reasons += "marche_peu_concurrentiel"
    }
    elseif ($item.supply -le 150) {
        $score += 3
        $reasons += "concurrence_moderee"
    }
    elseif ($item.supply -le 300) {
        $score -= 8
        $reasons += "concurrence_forte"
    }
    elseif ($item.supply -le 500) {
        $score -= 18
        $reasons += "marche_tres_concurrentiel"
    }
    else {
        $score -= 25
        $reasons += "marche_sature"
    }

    # ============================================================
    # RAPPORT DEMANDE / OFFRE
    # ============================================================

    if ($item.supply -gt 0) {

        $ratio = [double]$item.demand / [double]$item.supply

        if ($ratio -ge 1.5) {
            $score += 10
            $reasons += "demande_superieure_a_offre"
        }
        elseif ($ratio -ge 1) {
            $score += 5
            $reasons += "demande_proche_de_offre"
        }
        elseif ($ratio -lt 0.5) {
            $score -= 10
            $reasons += "offre_tres_superieure_a_demande"
        }
    }

    # ============================================================
    # PRIX
    # ============================================================

    if ($item.median_price -ge 30) {
        $score += 4
        $reasons += "ticket_interessant"
    }
    elseif ($item.median_price -lt 10) {
        $score -= 4
        $reasons += "ticket_faible"
    }

    # ============================================================
    # GARDE-FOU : MARCHÉ SATURÉ
    # ============================================================

    if ($item.supply -ge 300 -and $item.demand -lt $item.supply) {
        $score -= 10
        $reasons += "saturation_confirmee"
    }

    # ============================================================
    # LIMITES
    # ============================================================

    $score = [math]::Max(0,[math]::Min(100,$score))

    # ============================================================
    # DÉCISION
    # ============================================================

    if ($score -ge 80) {
        $decision = "GO"
    }
    elseif ($score -ge 65) {
        $decision = "TEST"
    }
    elseif ($score -ge 50) {
        $decision = "WATCH"
    }
    else {
        $decision = "REJECT"
    }

    # ============================================================
    # NIVEAU DE CONCURRENCE
    # ============================================================

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

        biznesshunter_score = $item.biznesshunter_score
        final_score = [math]::Round($score,1)
        decision = $decision

        market_score = $item.market_score
        market_verdict = $item.market_verdict

        demand = $item.demand
        supply = $item.supply
        demand_supply_ratio = if ($item.supply -gt 0) {
            [math]::Round(([double]$item.demand / [double]$item.supply),2)
        } else {
            0
        }

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

        score_adjustment = [math]::Round(
            ($score - [double]$item.biznesshunter_score),1
        )

        reasons = @($reasons)
    }
}

$results |
    Sort-Object final_score -Descending |
    ConvertTo-Json -Depth 10 |
    Set-Content .\radar63_final.json -Encoding UTF8

Write-Host ""
Write-Host "RADAR 63 FINAL :" @($results).Count
Write-Host "OUTPUT         : radar63_final.json"
Write-Host ""

$results |
    Sort-Object final_score -Descending |
    Format-Table `
        idea_name,
        city,
        biznesshunter_score,
        final_score,
        decision,
        competition_level `
        -AutoSize
