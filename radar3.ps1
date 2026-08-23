$ErrorActionPreference = "Stop"

$input = ".\pages_full.json"
$output = ".\radar3_candidates.json"

$data = Get-Content $input -Raw | ConvertFrom-Json
$results = @()

foreach ($item in $data) {

    if (-not $item.content) { continue }

    $text = ([string]$item.content) -replace '\s+', ' '
    $lower = $text.ToLower()

    # ============================================================
    # RADAR 3 — EARLY PHYSICAL BUSINESS
    # ============================================================

    $score = 0
    $physical = 0
    $newness = 0
    $traction = 0
    $replicable = 0
    $smallCapital = 0
    $geo = 0
    $softwarePenalty = 0

    # ------------------------------------------------------------
    # 1. BUSINESS PHYSIQUE
    # ------------------------------------------------------------

    if ($lower -match '\b(rental|renting|rent|sharing|delivery|pickup|warehouse|store|shop|retail|equipment|device|product|goods|vehicle|bike|car|food|restaurant|hotel|home service|cleaning|repair|installation|pets|pet care|childcare|event|outdoor|camping|storage|locker|parcel|package)\b') {
        $physical += 20
    }

    if ($lower -match '\b(hardware|physical product|consumer product|inventory|fleet|equipment|facility|location|local service)\b') {
        $physical += 15
    }

    # ------------------------------------------------------------
    # 2. NOUVEAUTÉ
    # ------------------------------------------------------------

    if ($lower -match '\b(launched|launches|launch|founded|founded in 2026|founded in 2025|new startup|new company|new business|recently launched|just launched|this year|last year|early stage|seed stage)\b') {
        $newness += 20
    }

    if ($lower -match '\b(2026|2025)\b') {
        $newness += 10
    }

    if ($lower -match '\b(less than 1 year|under a year|months old|six months|9 months|12 months)\b') {
        $newness += 10
    }

    # ------------------------------------------------------------
    # 3. TRACTION PRÉCOCE
    # ------------------------------------------------------------

    if ($lower -match '\b(customers?|users?|members?|orders?|bookings?|sales|revenue|arr|mrr|sold|paying|downloads|gmv|transactions)\b') {
        $traction += 15
    }

    if ($lower -match '\b(growth|grew|growing|doubled|tripled|rapid growth|record growth|traction|demand)\b') {
        $traction += 15
    }

    if ($lower -match '\b(raised|funding|seed|investment|million|m€|\$[0-9]+m)\b') {
        $traction += 10
    }

    # ------------------------------------------------------------
    # 4. RÉPLICABILITÉ
    # ------------------------------------------------------------

    if ($lower -match '\b(marketplace|platform|network|subscription|rental|sharing|on-demand|delivery|service)\b') {
        $replicable += 15
    }

    if ($lower -match '\b(expand|expansion|new market|new city|new country|international|scale|scaling)\b') {
        $replicable += 10
    }

    # ------------------------------------------------------------
    # 5. PETIT CAPITAL
    # ------------------------------------------------------------

    if ($lower -match '\b(bootstrapped|low cost|low-cost|small investment|small capital|start small|lean|without funding|profitable without|asset-light)\b') {
        $smallCapital += 20
    }

    if ($lower -match '\b(less than \$?1000|under \$?1000|under €?1000|less than €?1000|few hundred|hundreds of dollars|low startup cost)\b') {
        $smallCapital += 20
    }

    # ------------------------------------------------------------
    # 6. SIGNAL GÉOGRAPHIQUE
    # ------------------------------------------------------------

    if ($lower -match '\b(only in|currently available in|currently operates in|based in|launched in|available in one|available only|one city|single city|local market)\b') {
        $geo += 20
    }

    if ($lower -match '\b(expanding to|plans to expand|next market|next country|international expansion)\b') {
        $geo += 15
    }

    # ------------------------------------------------------------
    # 7. PÉNALITÉ SOFTWARE
    # ------------------------------------------------------------

    if ($lower -match '\b(saas|software|api|developer tool|coding|programming|cloud platform|ai agent|llm|machine learning|browser extension|chrome extension)\b') {
        $softwarePenalty += 25
    }

    # Software pur = élimination quasi automatique
    if (
        $lower -match '\b(saas|software|api|developer tool)\b' -and
        $lower -notmatch '\b(hardware|physical product|device|equipment|rental|delivery|store|retail)\b'
    ) {
        $softwarePenalty += 30
    }

    # ------------------------------------------------------------
    # CAPS
    # ------------------------------------------------------------

    $physical    = [Math]::Min($physical, 35)
    $newness     = [Math]::Min($newness, 40)
    $traction    = [Math]::Min($traction, 40)
    $replicable  = [Math]::Min($replicable, 25)
    $smallCapital = [Math]::Min($smallCapital, 40)
    $geo         = [Math]::Min($geo, 35)

    # ------------------------------------------------------------
    # SCORE FINAL
    # ------------------------------------------------------------

    $score =
        $physical +
        $newness +
        $traction +
        $replicable +
        $smallCapital +
        $geo -
        $softwarePenalty

    $score = [Math]::Max(0, [Math]::Min($score, 100))

    # ------------------------------------------------------------
    # VERDICT
    # ------------------------------------------------------------

    if (
        $score -ge 70 -and
        $physical -ge 20 -and
        $newness -ge 20 -and
        $traction -ge 20
    ) {
        $verdict = "EARLY GAP CANDIDATE"
    }
    elseif ($score -ge 50) {
        $verdict = "WATCH"
    }
    else {
        $verdict = "REJECT"
    }

    if ($physical -lt 15) {
        $verdict = "REJECT — TOO SOFTWARE"
    }

    $results += [PSCustomObject]@{
        name = $item.name
        url = $item.url
        source = $item.source

        radar = "RADAR 3"
        verdict = $verdict
        score = $score

        physical = $physical
        newness = $newness
        traction = $traction
        replicable = $replicable
        small_capital = $smallCapital
        geographic_signal = $geo
        software_penalty = $softwarePenalty
    }
}

$results = @(
    $results |
    Where-Object { $_.verdict -ne "REJECT" } |
    Sort-Object score -Descending
)

$results |
    ConvertTo-Json -Depth 6 |
    Set-Content -Encoding UTF8 $output

Write-Host ""
Write-Host "=========================================="
Write-Host "BIZNESSHUNTER — RADAR 3"
Write-Host "EARLY PHYSICAL BUSINESS"
Write-Host "=========================================="
Write-Host ""
Write-Host "Candidats retenus : $($results.Count)"
Write-Host ""

$results |
    Select-Object name,score,verdict,physical,newness,traction,replicable,small_capital,geographic_signal |
    Format-Table -AutoSize

Write-Host ""
Write-Host "Résultats : $output"
