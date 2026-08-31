# ================================================================
# BIZNESSHUNTER — RADAR 65
# REPLICATION ENGINE MULTI-OPPORTUNITIES
#
# SOURCE :
#   radar56_multicity_raw.json
#
# OBJECTIF :
#   Transformer les observations source x ville en opportunités
#   consolidées puis calculer leur potentiel de réplication.
# ================================================================

$ErrorActionPreference = "Stop"

$inputFile  = ".\radar56_multicity_raw.json"
$outputFile = ".\radar65_replication.json"

# ================================================================
# CHARGEMENT
# ================================================================

if (-not (Test-Path $inputFile)) {
    Write-Host ""
    Write-Host "ERREUR : fichier source introuvable :" $inputFile -ForegroundColor Red
    exit 1
}

$data = Get-Content $inputFile -Raw | ConvertFrom-Json

$rows = @($data)

if ($rows.Count -eq 0) {
    Write-Host ""
    Write-Host "ERREUR : aucune donnée dans le fichier source." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "SOURCE RADAR 56 :" $rows.Count "observations"

# ================================================================
# NORMALISATION DES VALEURS
# ================================================================

function Get-Number {
    param($Value)

    if ($null -eq $Value) {
        return 0
    }

    try {
        return [double]$Value
    }
    catch {
        return 0
    }
}

function Get-Median {
    param([array]$Values)

    $clean = @(
        $Values |
        ForEach-Object {
            try {
                [double]$_
            }
            catch {}
        } |
        Where-Object { $_ -gt 0 } |
        Sort-Object
    )

    if ($clean.Count -eq 0) {
        return 0
    }

    $middle = [int][math]::Floor($clean.Count / 2)

    if (($clean.Count % 2) -eq 0) {
        return [math]::Round(
            (($clean[$middle - 1] + $clean[$middle]) / 2),
            1
        )
    }
    else {
        return [math]::Round($clean[$middle],1)
    }
}

# ================================================================
# CONSOLIDATION
#
# Une opportunité =
#   même idée + même ville
#
# Les différentes sources sont fusionnées.
# ================================================================

$groups = $rows |
    Group-Object {
        "$($_.idea_name)||$($_.country)||$($_.city)||$($_.category)"
    }

$opportunities = @()

foreach ($group in $groups) {

    $items = @($group.Group)

    $first = $items[0]

    $ideaName = $first.idea_name
    $country  = $first.country
    $city     = $first.city
    $category = $first.category

    # ------------------------------------------------------------
    # SOURCES
    # ------------------------------------------------------------

    $sources = @(
        $items |
        Where-Object { $_.source } |
        Select-Object -ExpandProperty source -Unique
    )

    # ------------------------------------------------------------
    # DEMANDE
    #
    # On prend la meilleure observation disponible par source.
    # On évite donc de compter deux fois une même demande.
    # ------------------------------------------------------------

    $demandValues = @(
        $items |
        ForEach-Object {
            $value = Get-Number $_.demand_count

            if ($value -gt 0) {
                $value
            }
        }
    )

    if ($demandValues.Count -gt 0) {
        $demand = [double]($demandValues | Measure-Object -Maximum).Maximum
    }
    else {
        $demand = 0
    }

    # ------------------------------------------------------------
    # OFFRE
    # ------------------------------------------------------------

    $supplyValues = @(
        $items |
        ForEach-Object {
            $value = Get-Number $_.supply_count

            if ($value -gt 0) {
                $value
            }
        }
    )

    if ($supplyValues.Count -gt 0) {
        $supply = [double]($supplyValues | Measure-Object -Maximum).Maximum
    }
    else {
        $supply = 0
    }

    # ------------------------------------------------------------
    # PRIX
    # ------------------------------------------------------------

    $allPrices = @(
        $items |
        ForEach-Object {
            if ($null -ne $_.prices) {
                @($_.prices)
            }
        } |
        Where-Object {
            (Get-Number $_) -gt 0
        }
    )

    $medianPrice = Get-Median $allPrices

    # ------------------------------------------------------------
    # PREUVE MARCHÉ
    # ------------------------------------------------------------

    $sourceCount = $sources.Count

    $http200Count = @(
        $items |
        Where-Object {
            (Get-Number $_.http_status) -eq 200
        }
    ).Count

    $marketProofScore = 0

    # Plusieurs sources indépendantes
    if ($sourceCount -ge 3) {
        $marketProofScore += 30
    }
    elseif ($sourceCount -eq 2) {
        $marketProofScore += 22
    }
    elseif ($sourceCount -eq 1) {
        $marketProofScore += 12
    }

    # Données accessibles
    if ($http200Count -ge 3) {
        $marketProofScore += 20
    }
    elseif ($http200Count -ge 2) {
        $marketProofScore += 15
    }
    elseif ($http200Count -ge 1) {
        $marketProofScore += 10
    }

    # Demande observée
    if ($demand -ge 200) {
        $marketProofScore += 30
    }
    elseif ($demand -ge 100) {
        $marketProofScore += 22
    }
    elseif ($demand -ge 50) {
        $marketProofScore += 14
    }
    elseif ($demand -gt 0) {
        $marketProofScore += 7
    }

    # Offre observée
    if ($supply -ge 300) {
        $marketProofScore += 20
    }
    elseif ($supply -ge 100) {
        $marketProofScore += 14
    }
    elseif ($supply -gt 0) {
        $marketProofScore += 8
    }

    $marketProofScore = [math]::Min(100,$marketProofScore)

    # ------------------------------------------------------------
    # DEMANDE / OFFRE
    # ------------------------------------------------------------

    if ($supply -gt 0) {
        $ratio = [math]::Round(
            ($demand / $supply),
            2
        )
    }
    else {
        $ratio = 0
    }

    # ------------------------------------------------------------
    # POTENTIEL DE MARCHÉ
    # ------------------------------------------------------------

    $marketScore = 0
    $marketReasons = @()

    if ($demand -ge 200) {
        $marketScore += 30
        $marketReasons += "demande_forte"
    }
    elseif ($demand -ge 100) {
        $marketScore += 22
        $marketReasons += "demande_significative"
    }
    elseif ($demand -ge 50) {
        $marketScore += 14
        $marketReasons += "demande_moderee"
    }
    elseif ($demand -gt 0) {
        $marketScore += 7
        $marketReasons += "demande_faible"
    }
    else {
        $marketReasons += "demande_non_observee"
    }

    # ------------------------------------------------------------
    # CONCURRENCE
    # ------------------------------------------------------------

    if ($supply -eq 0) {

        $competitionLevel = "UNKNOWN"
        $competitionScore = 15
        $marketReasons += "offre_non_observee"

    }
    elseif ($supply -le 50) {

        $competitionLevel = "LOW"
        $competitionScore = 30
        $marketReasons += "offre_faible"

    }
    elseif ($supply -le 150) {

        $competitionLevel = "MODERATE"
        $competitionScore = 24
        $marketReasons += "concurrence_moderee"

    }
    elseif ($supply -le 300) {

        $competitionLevel = "HIGH"
        $competitionScore = 15
        $marketReasons += "concurrence_forte"

    }
    elseif ($supply -le 500) {

        $competitionLevel = "VERY_HIGH"
        $competitionScore = 7
        $marketReasons += "concurrence_tres_forte"

    }
    else {

        $competitionLevel = "EXTREME"
        $competitionScore = 0
        $marketReasons += "marche_tres_concurrentiel"
    }

    $marketScore += $competitionScore

    # ------------------------------------------------------------
    # RAPPORT DEMANDE / OFFRE
    # ------------------------------------------------------------

    $ratioScore = 0

    if ($supply -gt 0) {

        if ($ratio -ge 1.5) {

            $ratioScore = 25
            $marketReasons += "demande_superieure_a_offre"

        }
        elseif ($ratio -ge 1) {

            $ratioScore = 20
            $marketReasons += "demande_proche_de_offre"

        }
        elseif ($ratio -ge 0.75) {

            $ratioScore = 14
            $marketReasons += "equilibre_acceptable"

        }
        elseif ($ratio -ge 0.5) {

            $ratioScore = 7
            $marketReasons += "offre_superieure_a_demande"

        }
        else {

            $ratioScore = 0
            $marketReasons += "offre_tres_superieure_a_demande"
        }
    }

    $marketScore += $ratioScore

    # ------------------------------------------------------------
    # PRIX
    # ------------------------------------------------------------

    if ($medianPrice -ge 30) {

        $marketScore += 15
        $marketReasons += "ticket_eleve"

    }
    elseif ($medianPrice -ge 20) {

        $marketScore += 12
        $marketReasons += "ticket_correct"

    }
    elseif ($medianPrice -ge 10) {

        $marketScore += 7
        $marketReasons += "ticket_modere"

    }
    elseif ($medianPrice -gt 0) {

        $marketScore += 3
        $marketReasons += "ticket_faible"
    }

    $marketScore = [math]::Min(100,$marketScore)

    # ------------------------------------------------------------
    # SCORE DE RÉPLICATION
    #
    # 25 % preuve business
    # 25 % demande
    # 20 % concurrence
    # 20 % équilibre demande/offre
    # 10 % prix
    # ------------------------------------------------------------

    $replicationScore = 0
    $replicationReasons = @()

    # PREUVE BUSINESS / MARCHÉ

    if ($marketProofScore -ge 70) {

        $replicationScore += 25
        $replicationReasons += "preuve_marche_forte"

    }
    elseif ($marketProofScore -ge 50) {

        $replicationScore += 20
        $replicationReasons += "preuve_marche_correcte"

    }
    elseif ($marketProofScore -ge 30) {

        $replicationScore += 13
        $replicationReasons += "preuve_marche_limitee"

    }
    else {

        $replicationScore += 6
        $replicationReasons += "preuve_marche_faible"
    }

    # DEMANDE

    if ($demand -ge 200) {

        $replicationScore += 25
        $replicationReasons += "demande_forte"

    }
    elseif ($demand -ge 100) {

        $replicationScore += 20
        $replicationReasons += "demande_significative"

    }
    elseif ($demand -ge 50) {

        $replicationScore += 12
        $replicationReasons += "demande_moderee"

    }
    elseif ($demand -gt 0) {

        $replicationScore += 6
        $replicationReasons += "demande_faible"

    }
    else {

        $replicationReasons += "aucune_demande_mesuree"
    }

    # CONCURRENCE

    if ($supply -eq 0) {

        $replicationScore += 10
        $replicationReasons += "offre_non_mesuree"

    }
    elseif ($supply -le 50) {

        $replicationScore += 20
        $replicationReasons += "offre_tres_faible"

    }
    elseif ($supply -le 150) {

        $replicationScore += 15
        $replicationReasons += "offre_faible"

    }
    elseif ($supply -le 300) {

        $replicationScore += 9
        $replicationReasons += "offre_importante"

    }
    elseif ($supply -le 500) {

        $replicationScore += 4
        $replicationReasons += "offre_tres_importante"

    }
    else {

        $replicationReasons += "marche_sature"
    }

    # RAPPORT DEMANDE / OFFRE

    if ($supply -gt 0) {

        if ($ratio -ge 1.5) {

            $replicationScore += 20
            $replicationReasons += "demande_superieure_a_offre"

        }
        elseif ($ratio -ge 1) {

            $replicationScore += 16
            $replicationReasons += "demande_equivalente_ou_superieure"

        }
        elseif ($ratio -ge 0.75) {

            $replicationScore += 12
            $replicationReasons += "equilibre_acceptable"

        }
        elseif ($ratio -ge 0.5) {

            $replicationScore += 6
            $replicationReasons += "offre_superieure_a_demande"

        }
        else {

            $replicationReasons += "offre_tres_superieure_a_demande"
        }

    }
    else {

        $replicationScore += 5
        $replicationReasons += "ratio_non_calculable"
    }

    # PRIX

    if ($medianPrice -ge 30) {

        $replicationScore += 10
        $replicationReasons += "prix_tres_interessant"

    }
    elseif ($medianPrice -ge 20) {

        $replicationScore += 8
        $replicationReasons += "prix_interessant"

    }
    elseif ($medianPrice -ge 10) {

        $replicationScore += 5
        $replicationReasons += "prix_correct"

    }
    elseif ($medianPrice -gt 0) {

        $replicationScore += 2
        $replicationReasons += "prix_faible"
    }

    $replicationScore = [math]::Min(100,$replicationScore)

    # ------------------------------------------------------------
    # VERDICT
    # ------------------------------------------------------------

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

    # ------------------------------------------------------------
    # VERDICT MARCHÉ
    # ------------------------------------------------------------

    if ($marketScore -ge 75) {

        $marketVerdict = "STRONG"

    }
    elseif ($marketScore -ge 60) {

        $marketVerdict = "PROMISING"

    }
    elseif ($marketScore -ge 45) {

        $marketVerdict = "MIXED"

    }
    else {

        $marketVerdict = "WEAK"
    }

    # ------------------------------------------------------------
    # OBJECT
    # ------------------------------------------------------------

    $opportunities += [PSCustomObject]@{

        idea_name = $ideaName
        country = $country
        city = $city
        category = $category

        sources = @($sources)
        source_count = $sourceCount

        demand = $demand
        supply = $supply

        demand_supply_ratio = $ratio

        median_price = $medianPrice
        price_samples = $allPrices.Count

        market_proof_score = [math]::Round($marketProofScore,1)
        market_score = [math]::Round($marketScore,1)
        market_verdict = $marketVerdict

        competition_level = $competitionLevel
        competition_score = $competitionScore

        replication_score = [math]::Round($replicationScore,1)
        replication_verdict = $replicationVerdict

        market_reasons = @($marketReasons)
        replication_reasons = @($replicationReasons)
    }
}

# ================================================================
# CLASSEMENT
# ================================================================

$results = @(
    $opportunities |
    Sort-Object `
        replication_score, `
        market_score, `
        demand `
        -Descending
)

# ================================================================
# SAUVEGARDE
# ================================================================

$results |
    ConvertTo-Json -Depth 15 |
    Set-Content $outputFile -Encoding UTF8

# ================================================================
# STATISTIQUES
# ================================================================

$strong = @(
    $results |
    Where-Object {
        $_.replication_verdict -eq "STRONG_REPLICATION"
    }
).Count

$good = @(
    $results |
    Where-Object {
        $_.replication_verdict -eq "GOOD_REPLICATION"
    }
).Count

$possible = @(
    $results |
    Where-Object {
        $_.replication_verdict -eq "POSSIBLE_REPLICATION"
    }
).Count

$poor = @(
    $results |
    Where-Object {
        $_.replication_verdict -eq "POOR_REPLICATION"
    }
).Count

# ================================================================
# AFFICHAGE
# ================================================================

Write-Host ""
Write-Host "============================================================" 
Write-Host "BIZNESSHUNTER RADAR 65 — REPLICATION"
Write-Host "============================================================"
Write-Host ""

Write-Host "OBSERVATIONS RADAR 56 :" $rows.Count
Write-Host "OPPORTUNITES CONSOLIDEES :" $results.Count
Write-Host ""

Write-Host "STRONG REPLICATION :" $strong
Write-Host "GOOD REPLICATION   :" $good
Write-Host "POSSIBLE REPLICATION :" $possible
Write-Host "POOR REPLICATION   :" $poor

Write-Host ""
Write-Host "OUTPUT :" $outputFile
Write-Host ""

# ================================================================
# CLASSEMENT COMPLET
# ================================================================

$rank = 0

foreach ($item in $results) {

    $rank++

    Write-Host (
        "{0,2}. {1} | {2} | Score {3} | {4} | Demande {5} | Offre {6} | Ratio {7}" -f
        $rank,
        $item.city,
        $item.idea_name,
        $item.replication_score,
        $item.replication_verdict,
        $item.demand,
        $item.supply,
        $item.demand_supply_ratio
    )
}

Write-Host ""

# ================================================================
# TABLEAU
# ================================================================

$results |
    Select-Object `
        idea_name,
        country,
        city,
        replication_score,
        replication_verdict,
        market_score,
        demand,
        supply,
        demand_supply_ratio,
        median_price,
        competition_level,
        source_count |
    Format-Table -AutoSize

