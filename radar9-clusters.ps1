$inputFile = ".\radar8_1_copycats.json"
$outputFile = ".\radar9_clusters.json"

if (!(Test-Path $inputFile)) {
    Write-Host "ERROR: $inputFile not found"
    exit
}

$data = Get-Content $inputFile -Raw | ConvertFrom-Json

# ============================================================
# RADAR 9 - OPPORTUNITY CLUSTERING
# ============================================================

$clusters = @{}

foreach ($item in $data) {

    $model = [string]$item.business_model
    $vertical = [string]$item.vertical

    if ($model -eq "OTHER" -and $vertical -eq "OTHER") {
        continue
    }

    # Clé du cluster
    $clusterKey = "$model|$vertical"

    if (!$clusters.ContainsKey($clusterKey)) {

        $clusters[$clusterKey] = [PSCustomObject]@{
            cluster_name = "$model / $vertical"
            business_model = $model
            vertical = $vertical
            articles = @()
            company_count = 0
            countries_detected = @()
            demand_score = 0
            replication_score = 0
            capital_risk = 0
            regulatory_risk = 0
        }
    }

    $cluster = $clusters[$clusterKey]

    # Ajouter l'article
    $cluster.articles += [PSCustomObject]@{
        title = $item.title
        url = $item.url
        copycat_score = [int]$item.copycat_score
        demand_proof = [int]$item.demand_proof
    }

    # Agrégation
    $cluster.company_count++

    if ([int]$item.demand_proof -gt $cluster.demand_score) {
        $cluster.demand_score = [int]$item.demand_proof
    }

    if ([int]$item.replication_score -gt $cluster.replication_score) {
        $cluster.replication_score = [int]$item.replication_score
    }

    if ([int]$item.capital_risk -gt $cluster.capital_risk) {
        $cluster.capital_risk = [int]$item.capital_risk
    }

    if ([int]$item.regulatory_risk -gt $cluster.regulatory_risk) {
        $cluster.regulatory_risk = [int]$item.regulatory_risk
    }

    # Détection grossière des pays dans le titre
    $titleLower = ([string]$item.title).ToLower()

    $country = $null

    if ($titleLower -match 'india|indian|bengaluru|mumbai') {
        $country = "India"
    }
    elseif ($titleLower -match 'nigeria|nigerian') {
        $country = "Nigeria"
    }
    elseif ($titleLower -match 'brazil|brazilian') {
        $country = "Brazil"
    }
    elseif ($titleLower -match 'dubai') {
        $country = "UAE"
    }
    elseif ($titleLower -match 'uk|britain|british|london') {
        $country = "UK"
    }
    elseif ($titleLower -match 'germany|german|berlin') {
        $country = "Germany"
    }
    elseif ($titleLower -match 'canada|canadian') {
        $country = "Canada"
    }
    elseif ($titleLower -match 'usa|u\.s\.|american|new york|austin|chicago|texas|california') {
        $country = "USA"
    }

    if ($country -and $cluster.countries_detected -notcontains $country) {
        $cluster.countries_detected += $country
    }
}

# ============================================================
# CALCULATE CLUSTER OPPORTUNITY
# ============================================================

$results = foreach ($cluster in $clusters.Values) {

    $companyScore = [math]::Min(100, $cluster.company_count * 15)

    $geographicScore = [math]::Min(100, $cluster.countries_detected.Count * 20)

    $demandScore = $cluster.demand_score

    $replicationScore = $cluster.replication_score

    $capitalScore = 100 - $cluster.capital_risk

    $regulatoryScore = 100 - $cluster.regulatory_risk

    $opportunity = [math]::Round(
        ($companyScore * 0.20) +
        ($geographicScore * 0.15) +
        ($demandScore * 0.20) +
        ($replicationScore * 0.25) +
        ($capitalScore * 0.10) +
        ($regulatoryScore * 0.10)
    )

    if (
        $opportunity -ge 70 -and
        $cluster.company_count -ge 2
    ) {
        $verdict = "STRONG OPPORTUNITY"
    }
    elseif (
        $opportunity -ge 55 -and
        $cluster.company_count -ge 2
    ) {
        $verdict = "PROMISING"
    }
    elseif ($opportunity -ge 40) {
        $verdict = "WATCH"
    }
    else {
        $verdict = "LOW"
    }

    $reason = "$($cluster.company_count) detected signals"

    if ($cluster.countries_detected.Count -ge 2) {
        $reason += " / multi-country validation"
    }

    if ($replicationScore -ge 70) {
        $reason += " / highly replicable"
    }

    if ($demandScore -ge 40) {
        $reason += " / demand evidence"
    }

    if ($capitalScore -ge 70) {
        $reason += " / relatively low capital"
    }

    if ($regulatoryScore -ge 70) {
        $reason += " / relatively low regulation"
    }

    [PSCustomObject]@{
        cluster_name = $cluster.cluster_name
        business_model = $cluster.business_model
        vertical = $cluster.vertical

        company_count = $cluster.company_count
        countries_detected = ($cluster.countries_detected -join ", ")

        demand_score = $demandScore
        replication_score = $replicationScore

        capital_risk = $cluster.capital_risk
        regulatory_risk = $cluster.regulatory_risk

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
Write-Host " BiznessHunter - Radar 9"
Write-Host " OPPORTUNITY CLUSTERING"
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
        countries_detected,
        business_model,
        vertical,
        replication_score,
        demand_score,
        reason |
    Format-Table -Wrap -AutoSize

