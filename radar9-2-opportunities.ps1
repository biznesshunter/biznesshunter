$inputFile = ".\radar8_1_copycats.json"
$outputFile = ".\radar9_2_opportunities.json"

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

    $cluster.articles += $item

    # ============================
    # COMPANY
    # ============================

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

    # ============================
    # COUNTRY
    # ============================

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

    # ============================
    # SCORES
    # ============================

    $cluster.demand_scores += [int]$item.demand_proof
    $cluster.replication_scores += [int]$item.replication_score
    $cluster.capital_risks += [int]$item.capital_risk
    $cluster.regulatory_risks += [int]$item.regulatory_risk
}

# ============================================================
# CALCULATE
# ============================================================

$results = foreach ($cluster in $clusters.Values) {

    $companyCount = $cluster.companies.Keys.Count
    $articleCount = $cluster.articles.Count
    $countryCount = $cluster.countries.Keys.Count

    $avgDemand = if ($cluster.demand_scores.Count -gt 0) {
        [math]::Round(($cluster.demand_scores | Measure-Object -Average).Average)
    } else { 0 }

    $avgReplication = if ($cluster.replication_scores.Count -gt 0) {
        [math]::Round(($cluster.replication_scores | Measure-Object -Average).Average)
    } else { 0 }

    $avgCapital = if ($cluster.capital_risks.Count -gt 0) {
        [math]::Round(($cluster.capital_risks | Measure-Object -Average).Average)
    } else { 0 }

    $avgRegulation = if ($cluster.regulatory_risks.Count -gt 0) {
        [math]::Round(($cluster.regulatory_risks | Measure-Object -Average).Average)
    } else { 0 }

    # ========================================================
    # VALIDATION
    # ========================================================

    # Plusieurs entreprises = validation forte
    $companyValidation = [math]::Min(100, $companyCount * 15)

    # Plusieurs pays = signal de transférabilité
    $geographicValidation = [math]::Min(100, $countryCount * 30)

    # Plusieurs articles = traction médiatique / activité
    $articleValidation = [math]::Min(100, $articleCount * 5)

    # ========================================================
    # DEMAND NORMALIZATION
    # ========================================================

    # Le moteur amont produit actuellement des scores de demande
    # très faibles. On évite donc qu'ils écrasent complètement
    # les autres signaux.
    $demandAdjusted = [math]::Min(100, ($avgDemand * 2))

    # ========================================================
    # OPPORTUNITY SCORE
    # ========================================================

    $opportunity = [math]::Round(
        ($companyValidation * 0.30) +
        ($geographicValidation * 0.15) +
        ($articleValidation * 0.10) +
        ($demandAdjusted * 0.10) +
        ($avgReplication * 0.20) +
        ((100 - $avgCapital) * 0.10) +
        ((100 - $avgRegulation) * 0.05)
    )

    # ========================================================
    # PENALTIES
    # ========================================================

    # Une seule entreprise = pas encore un vrai marché validé
    if ($companyCount -eq 1) {
        $opportunity -= 15
    }

    # Un seul article = signal très faible
    if ($articleCount -eq 1) {
        $opportunity -= 10
    }

    # Aucun pays détecté = validation géographique faible
    if ($countryCount -eq 0) {
        $opportunity -= 5
    }

    $opportunity = [math]::Max(0, [math]::Min(100, $opportunity))

    # ========================================================
    # VERDICT
    # ========================================================

    if (
        $opportunity -ge 75 -and
        $companyCount -ge 4 -and
        $articleCount -ge 5
    ) {
        $verdict = "STRONG OPPORTUNITY"
    }
    elseif (
        $opportunity -ge 60 -and
        $companyCount -ge 3
    ) {
        $verdict = "PROMISING"
    }
    elseif (
        $opportunity -ge 45 -and
        $companyCount -ge 2
    ) {
        $verdict = "WATCH"
    }
    else {
        $verdict = "LOW"
    }

    # ========================================================
    # REASON
    # ========================================================

    $reason = "$companyCount companies / $articleCount articles"

    if ($countryCount -ge 2) {
        $reason += " / multi-country validation"
    }

    if ($avgReplication -ge 70) {
        $reason += " / highly replicable"
    }

    if ($avgDemand -ge 20) {
        $reason += " / demand signal"
    }

    if ($avgCapital -le 30) {
        $reason += " / low capital"
    }

    if ($avgRegulation -le 30) {
        $reason += " / low regulation"
    }

    [PSCustomObject]@{

        cluster_name = $cluster.cluster_name

        business_model = $cluster.business_model
        vertical = $cluster.vertical

        article_count = $articleCount
        company_count = $companyCount
        companies = ($cluster.companies.Keys -join ", ")

        country_count = $countryCount
        countries = ($cluster.countries.Keys -join ", ")

        avg_demand = $avgDemand
        avg_replication = $avgReplication
        avg_capital_risk = $avgCapital
        avg_regulatory_risk = $avgRegulation

        opportunity_score = $opportunity
        verdict = $verdict
        reason = $reason

        source_articles = $cluster.articles
    }
}

# ============================================================
# OUTPUT
# ============================================================

$results |
    Sort-Object opportunity_score -Descending |
    ConvertTo-Json -Depth 10 |
    Set-Content $outputFile -Encoding UTF8

Write-Host ""
Write-Host "=============================================="
Write-Host " BIZNESSHUNTER - RADAR 9.2"
Write-Host " OPPORTUNITY CLUSTER ENGINE"
Write-Host "=============================================="
Write-Host ""

Write-Host "Articles : $($data.Count)"
Write-Host "Clusters : $($results.Count)"
Write-Host ""

$results |
    Sort-Object opportunity_score -Descending |
    Select-Object -First 30 `
        opportunity_score,
        verdict,
        company_count,
        article_count,
        country_count,
        business_model,
        vertical,
        avg_replication,
        avg_demand,
        reason |
    Format-Table -Wrap -AutoSize

Write-Host ""
Write-Host "Output : $outputFile"
Write-Host ""
