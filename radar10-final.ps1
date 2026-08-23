$inputFile = ".\radar9_1_clusters.json"
$outputFile = ".\radar10_final_opportunities.json"

if (!(Test-Path $inputFile)) {
    Write-Host "ERROR: $inputFile not found"
    exit
}

$data = Get-Content $inputFile -Raw | ConvertFrom-Json

$results = foreach ($item in $data) {

    $score = [int]$item.opportunity_score
    $companies = [int]$item.company_count
    $articles = [int]$item.article_count
    $countries = [int]$item.country_count
    $replication = [int]$item.avg_replication
    $demand = [int]$item.avg_demand

    # Ignore weak clusters
    if ($companies -lt 2) {
        continue
    }

    if ($score -lt 50) {
        continue
    }

    $model = [string]$item.business_model
    $vertical = [string]$item.vertical

    # ============================================================
    # OPPORTUNITY NAME
    # ============================================================

    switch ($vertical) {

        "HOME_SERVICES" {
            if ($model -eq "ON_DEMAND") {
                $opportunity = "On-demand home services marketplace"
            }
            elseif ($model -eq "SUBSCRIPTION") {
                $opportunity = "Subscription-based home maintenance service"
            }
            elseif ($model -eq "MARKETPLACE") {
                $opportunity = "Local home services marketplace"
            }
            else {
                $opportunity = "Local home services platform"
            }
        }

        "PET_SERVICES" {
            if ($model -eq "SUBSCRIPTION") {
                $opportunity = "Subscription pet care service"
            }
            elseif ($model -eq "ON_DEMAND") {
                $opportunity = "On-demand pet care service"
            }
            else {
                $opportunity = "Local pet services platform"
            }
        }

        "AUTO_SERVICES" {
            if ($model -eq "ON_DEMAND") {
                $opportunity = "On-demand vehicle repair and maintenance"
            }
            else {
                $opportunity = "Local automotive services platform"
            }
        }

        "REPAIR" {
            if ($model -eq "ON_DEMAND") {
                $opportunity = "On-demand repair service"
            }
            else {
                $opportunity = "Local repair marketplace"
            }
        }

        "STORAGE" {
            if ($model -eq "RENTAL") {
                $opportunity = "Local storage rental marketplace"
            }
            else {
                $opportunity = "Local storage platform"
            }
        }

        "DELIVERY_LOGISTICS" {
            if ($model -eq "ON_DEMAND") {
                $opportunity = "On-demand local delivery service"
            }
            elseif ($model -eq "DELIVERY") {
                $opportunity = "Local delivery network"
            }
            else {
                $opportunity = "Local logistics platform"
            }
        }

        "RENTAL" {
            $opportunity = "Local rental marketplace"
        }

        default {
            $opportunity = "$model / $vertical business model"
        }
    }

    # ============================================================
    # CONFIDENCE
    # ============================================================

    $confidence = 40

    if ($companies -ge 5)  { $confidence += 10 }
    if ($companies -ge 10) { $confidence += 10 }
    if ($countries -ge 2) { $confidence += 10 }
    if ($countries -ge 4) { $confidence += 10 }
    if ($replication -ge 70) { $confidence += 10 }
    if ($demand -ge 20) { $confidence += 10 }

    $confidence = [math]::Min(100,$confidence)

    # ============================================================
    # VERDICT
    # ============================================================

    if ($score -ge 70 -and $confidence -ge 70) {
        $verdict = "HIGH POTENTIAL"
    }
    elseif ($score -ge 60 -and $confidence -ge 60) {
        $verdict = "STRONG"
    }
    elseif ($score -ge 50) {
        $verdict = "PROMISING"
    }
    else {
        $verdict = "WATCH"
    }

    # ============================================================
    # WHY NOW
    # ============================================================

    $whyNow = "$companies distinct companies detected across $articles articles"

    if ($countries -ge 2) {
        $whyNow += " / validated across $countries countries"
    }

    if ($replication -ge 70) {
        $whyNow += " / highly replicable model"
    }

    if ($demand -ge 20) {
        $whyNow += " / strong demand signals"
    }

    # ============================================================
    # TARGET MARKET
    # ============================================================

    $targetMarket = "France / Spain / other underserved European markets"

    # ============================================================
    # BUSINESS MODEL
    # ============================================================

    if ($model -eq "OTHER") {
        $businessModel = "Service / platform"
    }
    else {
        $businessModel = $model
    }

    # ============================================================
    # FINAL OBJECT
    # ============================================================

    [PSCustomObject]@{

        opportunity = $opportunity

        score = $score

        verdict = $verdict

        confidence = $confidence

        business_model = $businessModel

        vertical = $vertical

        target_market = $targetMarket

        company_count = $companies

        article_count = $articles

        country_count = $countries

        replication = $replication

        demand_signal = $demand

        capital_risk = [int]$item.avg_capital_risk

        regulatory_risk = [int]$item.avg_regulatory_risk

        why_now = $whyNow

        source_cluster = "$model / $vertical"
    }
}

# ============================================================
# SORT
# ============================================================

$results = $results |
    Sort-Object score,confidence -Descending

# ============================================================
# SAVE
# ============================================================

$results |
    ConvertTo-Json -Depth 10 |
    Set-Content $outputFile -Encoding UTF8

# ============================================================
# DISPLAY
# ============================================================

Write-Host ""
Write-Host "========================================"
Write-Host " BiznessHunter - Radar 10"
Write-Host " FINAL OPPORTUNITIES"
Write-Host "========================================"
Write-Host ""

Write-Host "Input  : $inputFile"
Write-Host "Output : $outputFile"
Write-Host ""
Write-Host "Final opportunities : $($results.Count)"
Write-Host ""

$results |
    Select-Object -First 20 `
        score,
        verdict,
        confidence,
        opportunity,
        company_count,
        country_count,
        replication |
    Format-Table -Wrap -AutoSize
