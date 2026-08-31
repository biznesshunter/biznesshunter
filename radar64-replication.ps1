$data = Get-Content .\radar63_final.json -Raw | ConvertFrom-Json

$results = foreach ($item in @($data)) {

    $replicationScore = 0
    $reasons = @()

    # ============================================================
    # PREUVE DU BUSINESS
    # ============================================================

    if ($item.biznesshunter_score -ge 75) {
        $replicationScore += 25
        $reasons += "business_fortement_prouve"
    }
    elseif ($item.biznesshunter_score -ge 60) {
        $replicationScore += 18
        $reasons += "business_prouve"
    }
    else {
        $replicationScore += 10
    }

    # ============================================================
    # DEMANDE
    # ============================================================

    if ($item.demand -ge 200) {
        $replicationScore += 25
        $reasons += "demande_forte"
    }
    elseif ($item.demand -ge 100) {
        $replicationScore += 18
        $reasons += "demande_significative"
    }
    elseif ($item.demand -ge 50) {
        $replicationScore += 10
        $reasons += "demande_moderee"
    }
    else {
        $replicationScore += 3
        $reasons += "demande_faible"
    }

    # ============================================================
    # ESPACE CONCURRENTIEL
    # ============================================================

    if ($item.supply -le 50) {
        $replicationScore += 25
        $reasons += "offre_tres_faible"
    }
    elseif ($item.supply -le 150) {
        $replicationScore += 20
        $reasons += "offre_faible"
    }
    elseif ($item.supply -le 300) {
        $replicationScore += 10
        $reasons += "offre_importante"
    }
    elseif ($item.supply -le 500) {
        $replicationScore += 3
        $reasons += "offre_tres_importante"
    }
    else {
        $replicationScore += 0
        $reasons += "marche_sature"
    }

    # ============================================================
    # RAPPORT DEMANDE / OFFRE
    # ============================================================

    if ($item.supply -gt 0) {

        $ratio = [double]$item.demand / [double]$item.supply

        if ($ratio -ge 1.5) {
            $replicationScore += 20
            $reasons += "demande_superieure_a_offre"
        }
        elseif ($ratio -ge 1) {
            $replicationScore += 15
            $reasons += "demande_equivalente_ou_superieure"
        }
        elseif ($ratio -ge 0.75) {
            $replicationScore += 10
            $reasons += "equilibre_acceptable"
        }
        elseif ($ratio -ge 0.5) {
            $replicationScore += 5
            $reasons += "offre_superieure_a_demande"
        }
        else {
            $replicationScore += 0
            $reasons += "offre_tres_superieure_a_demande"
        }
    }

    # ============================================================
    # PRIX
    # ============================================================

    if ($item.median_price -ge 30) {
        $replicationScore += 5
        $reasons += "prix_interessant"
    }
    elseif ($item.median_price -ge 20) {
        $replicationScore += 3
        $reasons += "prix_correct"
    }

    # ============================================================
    # SCORE FINAL
    # ============================================================

    $replicationScore = [math]::Min(100,$replicationScore)

    if ($replicationScore -ge 80) {
        $replicationVerdict = "STRONG_REPLICATION"
    }
    elseif ($replicationScore -ge 65) {
        $replicationVerdict = "GOOD_REPLICATION"
    }
    elseif ($replicationScore -ge 50) {
        $replicationVerdict = "POSSIBLE_REPLICATION"
    }
    else {
        $replicationVerdict = "POOR_REPLICATION"
    }

    # ============================================================
    # SORTIE
    # ============================================================

    [PSCustomObject]@{
        idea_name = $item.idea_name
        country = $item.country
        city = $item.city

        biznesshunter_score = $item.biznesshunter_score
        final_score = $item.final_score
        decision = $item.decision

        replication_score = $replicationScore
        replication_verdict = $replicationVerdict

        demand = $item.demand
        supply = $item.supply

        demand_supply_ratio = if ($item.supply -gt 0) {
            [math]::Round(
                ([double]$item.demand / [double]$item.supply),
                2
            )
        }
        else {
            0
        }

        median_price = $item.median_price
        competition_level = $item.competition_level

        market_score = $item.market_score
        market_proof_score = $item.market_proof_score
        business_proof_score = $item.business_proof_score

        capital_score = $item.capital_score
        home_based_score = $item.home_based_score
        automation_score = $item.automation_score
        human_presence_score = $item.human_presence_score
        geographic_replication_score = $item.geographic_replication_score

        sources = @($item.sources)

        reasons = @($reasons)
    }
}

$results |
    Sort-Object replication_score -Descending |
    ConvertTo-Json -Depth 10 |
    Set-Content .\radar64_replication.json -Encoding UTF8

Write-Host ""
Write-Host "RADAR 64 REPLICATION :" @($results).Count
Write-Host "OUTPUT                : radar64_replication.json"
Write-Host ""

$results |
    Sort-Object replication_score -Descending |
    Format-Table `
        idea_name,
        city,
        replication_score,
        replication_verdict,
        demand,
        supply `
        -AutoSize
