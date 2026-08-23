$inputFile = ".\radar7_deduplicated.json"
$outputFile = ".\radar8_1_copycats.json"

if (!(Test-Path $inputFile)) {
    Write-Host "ERROR: $inputFile not found"
    exit
}

$data = Get-Content $inputFile -Raw | ConvertFrom-Json

$results = foreach ($item in $data) {

    $title = [string]$item.title
    $lower = $title.ToLower()

    # ============================================================
    # BASE
    # ============================================================

    $model = "OTHER"
    $vertical = "OTHER"
    $marketType = "OTHER"

    $modelScore = 0
    $replication = 0
    $capitalRisk = 0
    $regulatoryRisk = 0
    $demandProof = 0

    $signals = @()

    # ============================================================
    # BUSINESS MODEL
    # ============================================================

    if ($lower -match 'marketplace|matching|connects.*customers|platform.*connect|platform.*providers') {
        $model = "MARKETPLACE"
        $modelScore = 25
        $signals += "MARKETPLACE"
    }
    elseif ($lower -match 'subscription|membership|monthly|recurring') {
        $model = "SUBSCRIPTION"
        $modelScore = 24
        $signals += "RECURRING_REVENUE"
    }
    elseif ($lower -match 'on-demand|instant|same-day|24/7') {
        $model = "ON_DEMAND"
        $modelScore = 23
        $signals += "ON_DEMAND"
    }
    elseif ($lower -match 'rental|renting|rents') {
        $model = "RENTAL"
        $modelScore = 22
        $signals += "RENTAL"
    }
    elseif ($lower -match 'delivery|delivery service|deliveries') {
        $model = "DELIVERY"
        $modelScore = 20
        $signals += "DELIVERY"
    }
    elseif ($lower -match 'app|software|saas') {
        $model = "SOFTWARE"
        $modelScore = 18
        $signals += "SOFTWARE"
    }

    # ============================================================
    # VERTICAL
    # ============================================================

    if ($lower -match 'home services|home maintenance|house cleaning|cleaning service|lawn care|handyman') {
        $vertical = "HOME_SERVICES"
        $signals += "HOME_SERVICES"
    }
    elseif ($lower -match 'pet care|pet tech|pet service|pets|dog walking|pet sitting|veterinary') {
        $vertical = "PET_SERVICES"
        $signals += "PET_SERVICES"
    }
    elseif ($lower -match 'vehicle service|auto repair|car repair|automotive|vehicle repair|automobile aftermarket') {
        $vertical = "AUTO_SERVICES"
        $signals += "AUTO_SERVICES"
    }
    elseif ($lower -match 'storage|self storage|cold storage') {
        $vertical = "STORAGE"
        $signals += "STORAGE"
    }
    elseif ($lower -match 'delivery|logistics|courier|last-mile') {
        $vertical = "DELIVERY_LOGISTICS"
        $signals += "DELIVERY_LOGISTICS"
    }
    elseif ($lower -match 'rental|renting|vacation rental|apartment rental|property rental') {
        $vertical = "RENTAL"
        $signals += "RENTAL_VERTICAL"
    }
    elseif ($lower -match 'fashion rental|clothing rental|wardrobe') {
        $vertical = "FASHION_RENTAL"
        $signals += "FASHION"
    }
    elseif ($lower -match 'childcare|child care|babysitting') {
        $vertical = "CHILDCARE"
        $signals += "CHILDCARE"
    }
    elseif ($lower -match 'repair|repair service|phone repair|tech repair') {
        $vertical = "REPAIR"
        $signals += "REPAIR"
    }

    # ============================================================
    # MARKET TYPE
    # ============================================================

    if ($lower -match 'local|city|neighborhood|community|home services|pet care|lawn care|cleaning|repair') {
        $marketType = "LOCAL_B2C"
        $signals += "LOCAL_MARKET"
    }
    elseif ($lower -match 'marketplace|platform|ecommerce|online marketplace') {
        $marketType = "PLATFORM"
        $signals += "PLATFORM_MARKET"
    }
    elseif ($lower -match 'enterprise|businesses|business customers|b2b') {
        $marketType = "B2B"
        $signals += "B2B"
    }

    # ============================================================
    # REPLICATION
    # ============================================================

    if ($model -in @("MARKETPLACE","ON_DEMAND","SUBSCRIPTION","RENTAL","DELIVERY")) {
        $replication += 30
    }

    if ($vertical -in @(
        "HOME_SERVICES",
        "PET_SERVICES",
        "AUTO_SERVICES",
        "STORAGE",
        "REPAIR",
        "FASHION_RENTAL"
    )) {
        $replication += 30
    }

    if ($marketType -eq "LOCAL_B2C") {
        $replication += 25
    }

    if ($lower -match 'india|indian|nigeria|africa|dubai|qatar|bengaluru|mumbai|brazil|brazilian|uk|europe') {
        $replication += 10
        $signals += "FOREIGN_PROOF"
    }

    $replication = [math]::Min(100,$replication)

    # ============================================================
    # CAPITAL RISK
    # ============================================================

    if ($lower -match 'drone|robotaxi|robot|hardware|manufacturing|factory|fleet|vehicle fleet') {
        $capitalRisk += 60
        $signals += "HIGH_CAPITAL"
    }

    if ($lower -match 'clinic|warehouse|facility|headquarters|physical location') {
        $capitalRisk += 25
        $signals += "PHYSICAL_INFRASTRUCTURE"
    }

    $capitalRisk = [math]::Min(100,$capitalRisk)

    # ============================================================
    # REGULATORY RISK
    # ============================================================

    if ($lower -match 'healthcare|medical|veterinary|finance|trading|insurance|banking') {
        $regulatoryRisk += 50
        $signals += "REGULATED"
    }

    if ($lower -match 'drone|robotaxi|childcare') {
        $regulatoryRisk += 30
        $signals += "REGULATION"
    }

    $regulatoryRisk = [math]::Min(100,$regulatoryRisk)

    # ============================================================
    # DEMAND PROOF
    # ============================================================

    if ($lower -match 'revenue|customers|users|million revenue|registered.*revenue') {
        $demandProof += 40
        $signals += "CUSTOMER_PROOF"
    }

    if ($lower -match '2m rides|million users|million customers|growth|grew|first year') {
        $demandProof += 25
        $signals += "TRACTION"
    }

    if ($lower -match 'funding|investment|raises|raised|backed|round') {
        $demandProof += 10
        $signals += "INVESTOR_SIGNAL"
    }

    $demandProof = [math]::Min(100,$demandProof)

    # ============================================================
    # COPYCAT SCORE
    # ============================================================

    $copycat = [math]::Round(
        ($modelScore * 0.20) +
        ($replication * 0.25) +
        ($demandProof * 0.20) +
        ((100 - $capitalRisk) * 0.15) +
        ((100 - $regulatoryRisk) * 0.10) +
        ($(if ($marketType -eq "LOCAL_B2C") { 100 } else { 50 }) * 0.10)
    )

    # ============================================================
    # VERDICT
    # ============================================================

    if (
        $copycat -ge 65 -and
        $replication -ge 50 -and
        $capitalRisk -le 40
    ) {
        $verdict = "COPYCAT CANDIDATE"
    }
    elseif ($copycat -ge 55) {
        $verdict = "PROMISING"
    }
    elseif ($copycat -ge 40) {
        $verdict = "WATCH"
    }
    else {
        $verdict = "LOW"
    }

    # ============================================================
    # REASON
    # ============================================================

    $reason = "$model / $vertical"

    if ($replication -ge 50) {
        $reason += " / highly replicable"
    }

    if ($demandProof -ge 40) {
        $reason += " / demand evidence"
    }

    if ($capitalRisk -le 20) {
        $reason += " / low capital"
    }

    if ($regulatoryRisk -le 20) {
        $reason += " / low regulation"
    }

    [PSCustomObject]@{
        title = $title
        url = $item.url

        business_model = $model
        vertical = $vertical
        market_type = $marketType

        model_score = $modelScore
        replication_score = $replication
        demand_proof = $demandProof

        capital_risk = $capitalRisk
        regulatory_risk = $regulatoryRisk

        copycat_score = $copycat
        verdict = $verdict

        reason = $reason
        signals = ($signals -join ", ")
    }
}

$results |
    Sort-Object copycat_score -Descending |
    ConvertTo-Json -Depth 10 |
    Set-Content $outputFile -Encoding UTF8

Write-Host ""
Write-Host "========================================"
Write-Host " BiznessHunter - Radar 8.1"
Write-Host " COPYCAT ENGINE"
Write-Host "========================================"
Write-Host ""
Write-Host "Input  : $inputFile"
Write-Host "Output : $outputFile"
Write-Host ""
Write-Host "Results : $($results.Count)"
Write-Host ""

$results |
    Select-Object -First 40 copycat_score,verdict,business_model,vertical,replication_score,demand_proof,title |
    Format-Table -Wrap -AutoSize
