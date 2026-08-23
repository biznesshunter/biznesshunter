$inputFile = ".\radar7_deduplicated.json"
$outputFile = ".\radar8_models.json"

if (!(Test-Path $inputFile)) {
    Write-Host "ERROR: $inputFile not found"
    exit
}

$data = Get-Content $inputFile -Raw | ConvertFrom-Json

$results = foreach ($item in $data) {

    $title = [string]$item.title
    $lower = $title.ToLower()

    $model = "OTHER"
    $modelScore = 0
    $transferability = 0
    $simplicity = 0
    $capitalRisk = 0
    $regulatoryRisk = 0
    $signals = @()

    # ============================================
    # 1. BUSINESS MODEL
    # ============================================

    if ($lower -match 'marketplace|matching|connects.*customers|platform.*connect') {
        $model = "MARKETPLACE"
        $modelScore = 25
        $signals += "MARKETPLACE"
    }
    elseif ($lower -match 'subscription|membership|monthly') {
        $model = "SUBSCRIPTION"
        $modelScore = 25
        $signals += "RECURRING_REVENUE"
    }
    elseif ($lower -match 'on-demand|instant|same-day|delivery') {
        $model = "ON_DEMAND_SERVICE"
        $modelScore = 22
        $signals += "ON_DEMAND"
    }
    elseif ($lower -match 'rental|renting|rents') {
        $model = "RENTAL"
        $modelScore = 22
        $signals += "RENTAL"
    }
    elseif ($lower -match 'home services|home maintenance|cleaning|lawn care|repair service') {
        $model = "LOCAL_SERVICE"
        $modelScore = 22
        $signals += "LOCAL_SERVICE"
    }
    elseif ($lower -match 'app|software|saas|platform') {
        $model = "SOFTWARE_PLATFORM"
        $modelScore = 18
        $signals += "SOFTWARE"
    }

    # ============================================
    # 2. TRANSFERABILITY
    # ============================================

    if ($lower -match 'home services|pet care|repair|cleaning|lawn care|storage|rental|delivery|marketplace') {
        $transferability += 35
        $signals += "GEOGRAPHICALLY_TRANSFERABLE"
    }

    if ($lower -match 'local|city|neighborhood|community') {
        $transferability += 20
        $signals += "LOCAL_REPLICATION"
    }

    if ($lower -match 'india|indian|china|chinese|dubai|qatar|africa|nigeria|bengaluru|mumbai') {
        $transferability += 10
        $signals += "FOREIGN_MARKET_PROOF"
    }

    $transferability = [math]::Min(100,$transferability)

    # ============================================
    # 3. SIMPLICITY
    # ============================================

    if ($lower -match 'marketplace|matching|on-demand|subscription|service|rental') {
        $simplicity += 30
    }

    if ($lower -match 'local|home|pet|repair|cleaning|lawn|storage') {
        $simplicity += 25
    }

    # ============================================
    # 4. CAPITAL RISK
    # ============================================

    if ($lower -match 'drone|robotaxi|robot|hardware|battery|vehicle fleet|manufacturing') {
        $capitalRisk += 50
        $signals += "CAPITAL_INTENSIVE"
    }

    if ($lower -match 'clinic|warehouse|headquarters|facility|fleet') {
        $capitalRisk += 25
        $signals += "INFRASTRUCTURE_REQUIRED"
    }

    $capitalRisk = [math]::Min(100,$capitalRisk)

    # ============================================
    # 5. REGULATORY RISK
    # ============================================

    if ($lower -match 'healthcare|medical|health|finance|trading|insurance|drone|robotaxi') {
        $regulatoryRisk += 45
        $signals += "REGULATED"
    }

    if ($lower -match 'food delivery|restaurant delivery|childcare') {
        $regulatoryRisk += 15
    }

    $regulatoryRisk = [math]::Min(100,$regulatoryRisk)

    # ============================================
    # 6. PROOF OF DEMAND
    # ============================================

    $proof = 0

    if ($lower -match 'revenue|users|customers|million|funding|investment|raises|raised|backed') {
        $proof += 25
        $signals += "DEMAND_SIGNAL"
    }

    if ($lower -match 'first year|200k users|100 jobs|growth|grew') {
        $proof += 20
        $signals += "STRONG_DEMAND_SIGNAL"
    }

    $proof = [math]::Min(100,$proof)

    # ============================================
    # 7. OVERALL OPPORTUNITY
    # ============================================

    $opportunity = [math]::Round(
        ($modelScore * 0.20) +
        ($transferability * 0.25) +
        ($simplicity * 0.20) +
        ((100 - $capitalRisk) * 0.15) +
        ((100 - $regulatoryRisk) * 0.10) +
        ($proof * 0.10)
    )

    # ============================================
    # 8. VERDICT
    # ============================================

    if ($opportunity -ge 70) {
        $verdict = "STRONG OPPORTUNITY"
    }
    elseif ($opportunity -ge 55) {
        $verdict = "PROMISING"
    }
    elseif ($opportunity -ge 40) {
        $verdict = "WATCH"
    }
    else {
        $verdict = "WEAK"
    }

    [PSCustomObject]@{
        title = $title
        url = $item.url

        business_model = $model
        model_score = $modelScore

        transferability = $transferability
        simplicity = $simplicity

        capital_risk = $capitalRisk
        regulatory_risk = $regulatoryRisk

        demand_proof = $proof

        opportunity_score = $opportunity
        verdict = $verdict

        signals = ($signals -join ", ")
    }
}

$results |
    Sort-Object opportunity_score -Descending |
    ConvertTo-Json -Depth 10 |
    Set-Content $outputFile -Encoding UTF8

Write-Host ""
Write-Host "========================================"
Write-Host " BiznessHunter - Radar 8"
Write-Host " Business Model Extraction"
Write-Host "========================================"
Write-Host ""
Write-Host "Input  : $inputFile"
Write-Host "Output : $outputFile"
Write-Host ""
Write-Host "Results : $($results.Count)"
Write-Host ""

$results |
    Select-Object -First 40 opportunity_score,business_model,transferability,simplicity,capital_risk,regulatory_risk,verdict,title |
    Format-Table -Wrap -AutoSize
