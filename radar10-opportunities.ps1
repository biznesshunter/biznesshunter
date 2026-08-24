$inputFile = ".\radar8_1_copycats.json"
$outputFile = ".\radar10_opportunities.json"

if (!(Test-Path $inputFile)) {
    Write-Host "ERROR: $inputFile not found"
    exit
}

$data = Get-Content $inputFile -Raw | ConvertFrom-Json

$clusters = @{}

foreach ($item in $data) {

    $model = [string]$item.business_model
    $vertical = [string]$item.vertical

    if ($model -eq "OTHER" -and $vertical -eq "OTHER") {
        continue
    }

    $clusterKey = "$model|$vertical"

    if (!$clusters.ContainsKey($clusterKey)) {

        $clusters[$clusterKey] = [PSCustomObject]@{
            cluster_name = "$model / $vertical"
            business_model = $model
            vertical = $vertical

            articles = @()
            companies = @{}
            countries = @{}

            demand_scores = @()
            replication_scores = @()
            capital_risks = @()
            regulatory_risks = @()
        }
    }

    $cluster = $clusters[$clusterKey]

    # =====================================================
    # ARTICLE
    # =====================================================

    $cluster.articles += $item

    # =====================================================
    # COMPANY EXTRACTION
    # =====================================================

    $title = [string]$item.title
    $company = $null

    if ($title -match '(?i)startup\s+([A-Z][A-Za-z0-9&\.-]+)') {
        $company = $matches[1]
    }
    elseif ($title -match '(?i)([A-Z][A-Za-z0-9&\.-]+)\s+(?:launches|raises|enters|opens|partners|unveils|closes|introduces)') {
        $company = $matches[1]
    }

    if (!$company) {
        $company = "UNKNOWN_" + [string]$cluster.articles.Count
    }

    $company = $company.ToLower().Trim()

    if (!$cluster.companies.ContainsKey($company)) {
        $cluster.companies[$company] = $true
    }

    # =====================================================
    # COUNTRY
    # =====================================================

    $lower = $title.ToLower()
    $country = $null

    if ($lower -match 'india|indian|bengaluru|mumbai') {
        $country = "India"
    }
    elseif ($lower -match 'nigeria|nigerian') {
        $country = "Nigeria"
    }
    elseif ($lower -match 'brazil|brazilian') {
        $country = "Brazil"
    }
    elseif ($lower -match 'dubai|uae') {
        $country = "UAE"
    }
    elseif ($lower -match 'uk|britain|british|london') {
        $country = "UK"
    }
    elseif ($lower -match 'germany|german|berlin') {
        $country = "Germany"
    }
    elseif ($lower -match 'canada|canadian') {
        $country = "Canada"
    }
    elseif ($lower -match 'usa|u\.s\.|american|new york|austin|chicago|texas|california') {
        $country = "USA"
    }

    if ($country) {
        $cluster.countries[$country] = $true
    }

    # =====================================================
    # RAW SCORES
    # =====================================================

    $cluster.demand_scores += [int]$item.demand_proof
    $cluster.replication_scores += [int]$item.replication_score
    $cluster.capital_risks += [int]$item.capital_risk
    $cluster.regulatory_risks += [int]$item.regulatory_risk
}

# =========================================================
# SCORE NORMALIZATION FUNCTION
# =========================================================

function Get-AverageScore {
    param($values)

    if ($null -eq $values -or $values.Count -eq 0) {
        return 0
    }

    return [math]::Round(
        ($values | Measure-Object -Average).Average
    )
}

# =========================================================
# CALCULATE RESULTS
# =========================================================

$results = foreach ($cluster in $clusters.Values) {

    $companyCount = $cluster.companies.Keys.Count
    $articleCount = $cluster.articles.Count
    $countryCount = $cluster.countries.Keys.Count

    $avgDemand = Get-AverageScore $cluster.demand_scores
    $avgReplication = Get-AverageScore $cluster.replication_scores
    $avgCapital = Get-AverageScore $cluster.capital_risks
    $avgRegulation = Get-AverageScore $cluster.regulatory_risks

    # =====================================================
    # 1. MARKET VALIDATION
    # =====================================================

    # Companies:
    # 1 company  = faible signal
    # 2 companies = début de validation
    # 5+ = validation forte
    $companyValidation = [math]::Min(100, $companyCount * 20)

    # Articles:
    # limite l'effet des clusters avec énormément d'articles
    $articleValidation = [math]::Min(100, $articleCount * 5)

    # Countries:
    # preuve qu'il ne s'agit pas uniquement d'un phénomène local
    $geographicValidation = [math]::Min(100, $countryCount * 25)

    # Score global de validation du marché
    $marketValidation = [math]::Round(
        ($companyValidation * 0.55) +
        ($articleValidation * 0.20) +
        ($geographicValidation * 0.25)
    )

    # =====================================================
    # 2. DEMAND SIGNAL
    # =====================================================

    # Le moteur actuel produit des scores assez faibles.
    # On les normalise sans les laisser dominer le résultat.
    $demandSignal = [math]::Min(100, $avgDemand * 2)

    # =====================================================
    # 3. SOLO FIT
    # =====================================================

    # Réplicabilité = capacité à reproduire le modèle.
    $replicationScore = $avgReplication

    # Capital faible = meilleur score
    $capitalScore = 100 - $avgCapital

    # Régulation faible = meilleur score
    $regulationScore = 100 - $avgRegulation

    # =====================================================
    # SOLO OPPORTUNITY
    # =====================================================

    $soloOpportunity = [math]::Round(
        ($replicationScore * 0.45) +
        ($capitalScore * 0.25) +
        ($regulationScore * 0.15) +
        ($demandSignal * 0.15)
    )

    # =====================================================
    # 4. MARKET SIZE / TRACTION BONUS
    # =====================================================

    # On donne un bonus à la validation mais sans permettre
    # aux énormes marchés de tout écraser.

    $tractionBonus = 0

    if ($companyCount -ge 5) {
        $tractionBonus += 5
    }

    if ($articleCount -ge 10) {
        $tractionBonus += 5
    }

    if ($countryCount -ge 2) {
        $tractionBonus += 5
    }

    $tractionBonus = [math]::Min(15, $tractionBonus)

    # =====================================================
    # 5. BH SCORE
    # =====================================================

    # Le score final favorise :
    #
    # - marché réellement validé
    # - réplicabilité
    # - faible capital
    # - faible réglementation
    #
    # mais empêche la simple taille du marché de dominer.

    $bhScore = [math]::Round(
        ($marketValidation * 0.35) +
        ($soloOpportunity * 0.50) +
        ($tractionBonus * 1.0)
    )

    $bhScore = [math]::Max(
        0,
        [math]::Min(100, $bhScore)
    )

    # =====================================================
    # 6. PENALTIES
    # =====================================================

    # Une seule entreprise = marché non suffisamment validé
    if ($companyCount -eq 1) {
        $bhScore -= 15
    }

    # Une seule occurrence = signal très faible
    if ($articleCount -eq 1) {
        $bhScore -= 10
    }

    # Aucun pays détecté
    if ($countryCount -eq 0) {
        $bhScore -= 5
    }

    # Très mauvaise réplication
    if ($avgReplication -lt 25) {
        $bhScore -= 10
    }

    # Capital très élevé
    if ($avgCapital -ge 75) {
        $bhScore -= 10
    }

    # Régulation très élevée
    if ($avgRegulation -ge 75) {
        $bhScore -= 10
    }

    $bhScore = [math]::Max(
        0,
        [math]::Min(100, $bhScore)
    )

    # =====================================================
    # 7. OPPORTUNITY CLASS
    # =====================================================

    if (
        $bhScore -ge 75 -and
        $companyCount -ge 3 -and
        $avgReplication -ge 60
    ) {
        $verdict = "STRONG OPPORTUNITY"
    }
    elseif (
        $bhScore -ge 60 -and
        $companyCount -ge 2
    ) {
        $verdict = "PROMISING"
    }
    elseif (
        $bhScore -ge 45
    ) {
        $verdict = "WATCH"
    }
    else {
        $verdict = "LOW"
    }

    # =====================================================
    # 8. SOLO FIT LABEL
    # =====================================================

    if (
        $avgReplication -ge 70 -and
        $avgCapital -le 35 -and
        $avgRegulation -le 35
    ) {
        $soloFit = "EXCELLENT"
    }
    elseif (
        $avgReplication -ge 55 -and
        $avgCapital -le 50
    ) {
        $soloFit = "GOOD"
    }
    elseif (
        $avgReplication -ge 40
    ) {
        $soloFit = "MODERATE"
    }
    else {
        $soloFit = "POOR"
    }

    # =====================================================
    # 9. REASON
    # =====================================================

    $reason = "$companyCount companies / $articleCount articles"

    if ($countryCount -ge 2) {
        $reason += " / multi-country"
    }

    if ($avgReplication -ge 70) {
        $reason += " / highly replicable"
    }

    if ($avgCapital -le 30) {
        $reason += " / low capital"
    }

    if ($avgRegulation -le 30) {
        $reason += " / low regulation"
    }

    if ($avgDemand -ge 20) {
        $reason += " / demand signal"
    }

    # =====================================================
    # RESULT OBJECT
    # =====================================================

    [PSCustomObject]@{

        cluster_name = $cluster.cluster_name

        business_model = $cluster.business_model
        vertical = $cluster.vertical

        # MARKET
        article_count = $articleCount
        company_count = $companyCount
        country_count = $countryCount

        companies = ($cluster.companies.Keys -join ", ")
        countries = ($cluster.countries.Keys -join ", ")

        market_validation = $marketValidation

        # DEMAND
        avg_demand = $avgDemand
        demand_signal = $demandSignal

        # SOLO
        avg_replication = $avgReplication
        avg_capital_risk = $avgCapital
        avg_regulatory_risk = $avgRegulation

        solo_opportunity = $soloOpportunity
        solo_fit = $soloFit

        # FINAL
        traction_bonus = $tractionBonus
        bh_score = $bhScore
        verdict = $verdict

        reason = $reason

        source_articles = $cluster.articles
    }
}

# =========================================================
# SORT + SAVE
# =========================================================

$results =
    $results |
    Sort-Object bh_score -Descending

$results |
    ConvertTo-Json -Depth 10 |
    Set-Content $outputFile -Encoding UTF8

# =========================================================
# DISPLAY
# =========================================================

Write-Host ""
Write-Host "=============================================================="
Write-Host " BIZNESSHUNTER - RADAR 10"
Write-Host " BUSINESS OPPORTUNITY ENGINE"
Write-Host "=============================================================="
Write-Host ""

Write-Host "Articles : $($data.Count)"
Write-Host "Clusters : $($results.Count)"
Write-Host ""

Write-Host "TOP OPPORTUNITIES"
Write-Host "--------------------------------------------------------------"
Write-Host ""

$results |
    Select-Object -First 30 `
        bh_score,
        verdict,
        solo_fit,
        company_count,
        article_count,
        country_count,
        business_model,
        vertical,
        market_validation,
        solo_opportunity,
        avg_replication,
        avg_capital_risk,
        avg_regulatory_risk,
        avg_demand |
    Format-Table -Wrap -AutoSize

Write-Host ""
Write-Host "--------------------------------------------------------------"
Write-Host "OUTPUT : $outputFile"
Write-Host "--------------------------------------------------------------"
Write-Host ""

# =========================================================
# SPECIAL SOLO FILTER
# =========================================================

Write-Host "TOP SOLO OPPORTUNITIES"
Write-Host "--------------------------------------------------------------"
Write-Host ""

$results |
    Where-Object {
        $_.company_count -ge 2 -and
        $_.avg_replication -ge 60 -and
        $_.avg_capital_risk -le 50
    } |
    Select-Object -First 15 `
        bh_score,
        verdict,
        solo_fit,
        business_model,
        vertical,
        company_count,
        article_count,
        avg_replication,
        avg_capital_risk,
        avg_regulatory_risk,
        avg_demand |
    Format-Table -Wrap -AutoSize

Write-Host ""
Write-Host "=============================================================="
Write-Host " RADAR 10 COMPLETE"
Write-Host "=============================================================="
