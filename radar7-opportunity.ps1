$inputFile = ".\radar6_new_businesses.json"
$outputFile = ".\radar7_opportunities.json"

$data = Get-Content $inputFile -Raw | ConvertFrom-Json

$results = foreach ($item in $data) {

    $title = [string]$item.title
    $lower = $title.ToLower()

    $newness = [int]$item.newness_score

    $model = 0
    $traction = 0
    $copyability = 0
    $penalty = 0
    $signals = @()

    # ============================================
    # BUSINESS MODEL
    # ============================================

    if ($lower -match 'on-demand|marketplace|platform|app|subscription|rental|delivery|matching') {
        $model += 25
        $signals += "CLEAR_MODEL"
    }

    if ($lower -match 'home services|pet care|vehicle service|repair|lawn care|cleaning|storage|childcare|rental|delivery') {
        $model += 15
        $signals += "LOCAL_SERVICE"
    }

    if ($lower -match 'service|business') {
        $model += 5
    }

    # ============================================
    # TRACTION
    # ============================================

    if ($lower -match 'revenue|users|customers|million|funding|investment|raises|raised|backed|jobs') {
        $traction += 15
        $signals += "TRACTION_SIGNAL"
    }

    if ($lower -match 'first year|200k users|100 jobs|million revenue') {
        $traction += 10
        $signals += "STRONG_TRACTION"
    }

    # ============================================
    # COPYABILITY
    # ============================================

    if ($lower -match 'local|home|pet|repair|lawn|cleaning|storage|rental|delivery|service') {
        $copyability += 25
    }

    if ($lower -match 'marketplace|on-demand|subscription|platform|matching') {
        $copyability += 20
    }

    if ($lower -match 'startup|new business|new venture|launches|launched|officially launches') {
        $copyability += 10
        $signals += "EARLY_STAGE"
    }

    # ============================================
    # NEGATIVE SIGNALS
    # ============================================

    if ($lower -match 'amazon|google|microsoft|apple|ford|usps|chick-fil-a|rover|aramex|uber|frontdoor|porch') {
        $penalty += 30
        $signals += "INCUMBENT"
    }

    if ($lower -match 'opens new location|new location|new headquarters|opens.*office|expands|expansion') {
        $penalty += 25
        $signals += "EXPANSION"
    }

    if ($lower -match 'campaign|spotlight|interview|q&a|talks about|how .* built') {
        $penalty += 25
        $signals += "CONTENT"
    }

    if ($lower -match 'acquires|acquisition|acquired') {
        $penalty += 25
        $signals += "ACQUISITION"
    }

    # ============================================
    # NORMALIZE
    # ============================================

    $copyability = [math]::Min(100, $copyability)

    $rawScore =
        ($newness * 0.40) +
        ($model * 0.30) +
        ($traction * 0.15) +
        ($copyability * 0.15)

    $opportunity = [math]::Round($rawScore - $penalty)

    if ($opportunity -lt 0) {
        $opportunity = 0
    }

    # ============================================
    # VERDICT
    # ============================================

    if ($opportunity -ge 65) {
        $verdict = "HIGH POTENTIAL"
    }
    elseif ($opportunity -ge 50) {
        $verdict = "POTENTIAL"
    }
    elseif ($opportunity -ge 35) {
        $verdict = "WATCH"
    }
    else {
        $verdict = "LOW"
    }

    [PSCustomObject]@{
        title = $title
        url = $item.url
        newness_score = $newness
        model_score = $model
        traction_score = $traction
        copyability = $copyability
        opportunity_score = $opportunity
        verdict = $verdict
        signals = ($signals -join ", ")
    }
}

$results |
    Sort-Object opportunity_score -Descending |
    ConvertTo-Json -Depth 5 |
    Set-Content $outputFile -Encoding UTF8

Write-Host ""
Write-Host "========================================"
Write-Host " BiznessHunter - Opportunity Radar 7 V2"
Write-Host "========================================"
Write-Host ""
Write-Host "Input  : $inputFile"
Write-Host "Output : $outputFile"
Write-Host ""
Write-Host "Results : $($results.Count)"
Write-Host ""

$results |
    Select-Object -First 40 opportunity_score,copyability,verdict,title |
    Format-Table -Wrap -AutoSize
