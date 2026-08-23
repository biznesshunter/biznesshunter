$inputFile = ".\radar8_1_copycats.json"
$outputFile = ".\radar9_1_clusters.json"

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

    # ============================================
    # ARTICLE
    # ============================================

    $cluster.articles += $item

    # ============================================
    # ENTREPRISE
    # ============================================

    $title = [string]$item.title

    # Tentative d'extraction du nom de l'entreprise
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

    # ============================================
    # PAYS
    # ============================================

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

    # ============================================
    # SCORES
    # ============================================

    $cluster.demand_scores += [int]$item.demand_proof
    $cluster.replication_scores += [int]$item.replication_score
    $cluster.capital_risks += [int]$item.capital_risk
    $cluster.regulatory_risks += [int]$item.regulatory_risk
}

# ============================================
# CALCULATE CLUSTERS
# ============================================

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

    # ============================================
    # VALIDATION SCORE
    # ============================================

    $companyValidation = [math]::Min(100, $companyCount * 20)

    $geographicValidation = [math]::Min(100, $countryCount * 25)

    # Bonus si plusieurs entreprises indépendantes
    $independentSignal = [math]::Min(100, $companyCount * 15)

    # ============================================
    # OPPORTUNITY
    # ============================================

    $opportunity = [math]::Round(
        ($companyValidation * 0.20) +
        ($geographicValidation * 0.15) +
        ($avgDemand * 0.20) +
        ($avgReplication * 0.25) +
        ((100 - $avgCapital) * 0.10) +
        ((100 - $avgRegulation) * 0.10)
    )

    # ============================================
    # VERDICT
    # ============================================

    if (
        $opportunity -ge 70 -and
        $companyCount -ge 3 -and
        $countryCount -ge 2
    ) {
        $verdict = "STRONG OPPORTUNITY"
    }
    elseif (
        $opportunity -ge 55 -and
        $companyCount -ge 2
    ) {
        $verdict = "PROMISING"
    }
    elseif ($opportunity -ge 40) {
        $verdict = "WATCH"
    }
    else {
        $verdict = "LOW"
    }

    $reason = "$companyCount distinct companies / $articleCount articles"

    if ($countryCount -ge 2) {
        $reason += " / multi-country validation"
    }

    if ($avgReplication -ge 70) {
        $reason += " / highly replicable"
    }

    if ($avgDemand -ge 40) {
        $reason += " / demand evidence"
    }

    if ($avgCapital -le 30) {
        $reason += " / relatively low capital"
    }

    if ($avgRegulation -le 30) {
        $reason += " / relatively low regulation"
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

$results |
    Sort-Object opportunity_score -Descending |
    ConvertTo-Json -Depth 10 |
    Set-Content $outputFile -Encoding UTF8

Write-Host ""
Write-Host "========================================"
Write-Host " BiznessHunter - Radar 9.1"
Write-Host " DISTINCT COMPANY CLUSTERING"
Write-Host "========================================"
Write-Host ""

Write-Host "Input  : $inputFile"
Write-Host "Output : $outputFile"
Write-Host ""
Write-Host "Articles : $($data.Count)"
Write-Host "Clusters : $($results.Count)"
Write-Host ""

$results |
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

