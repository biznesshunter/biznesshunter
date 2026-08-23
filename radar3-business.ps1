$ErrorActionPreference = "Stop"

$input = ".\radar3_news_candidates.json"
$output = ".\radar3_businesses.json"

$data = Get-Content $input -Raw | ConvertFrom-Json
$results = @()

foreach ($item in $data) {

    $text = (
        ([string]$item.title) + " " +
        ([string]$item.description)
    ) -replace '\s+', ' '

    $lower = $text.ToLower()

    # ============================================================
    # NOVEL BUSINESS FILTER
    # ============================================================

    $novelty = 0
    $traction = 0
    $physical = 0
    $replicable = 0
    $geo = 0
    $establishedPenalty = 0

    # ------------------------------------------------------------
    # PHYSICAL
    # ------------------------------------------------------------

    if ($lower -match '\b(rental|renting|sharing|marketplace|delivery|equipment|vehicle|bike|storage|locker|food delivery|home service|pet care|childcare|repair|cleaning|camping|outdoor|event rental|physical product|retail)\b') {
        $physical += 20
    }

    if ($lower -match '\b(local service|on-demand|subscription|membership)\b') {
        $physical += 10
    }

    # ------------------------------------------------------------
    # NEW BUSINESS / NEW MODEL
    # ------------------------------------------------------------

    if ($lower -match '\b(startup|new startup|new company|founded|launches|launched|launch|new service|new platform|new marketplace|new business|introduces|introduced|debut)\b') {
        $novelty += 20
    }

    if ($lower -match '\b(2026|2025|this year|recently|just launched|first year|first months)\b') {
        $novelty += 10
    }

    # ------------------------------------------------------------
    # TRACTION
    # ------------------------------------------------------------

    if ($lower -match '\b(revenue|sales|customers?|users?|orders?|bookings?|members?|downloads?|transactions?|gmv)\b') {
        $traction += 15
    }

    if ($lower -match '\b(growth|growing|grew|traction|demand|expanding|expansion|raised|funding|funded|investment)\b') {
        $traction += 15
    }

    # ------------------------------------------------------------
    # REPLICABLE MODEL
    # ------------------------------------------------------------

    if ($lower -match '\b(rental|marketplace|sharing|delivery|on-demand|subscription|membership)\b') {
        $replicable += 20
    }

    if ($lower -match '\b(expand|expansion|new market|new city|new country|international)\b') {
        $replicable += 10
    }

    # ------------------------------------------------------------
    # GEOGRAPHIC SIGNAL
    # ------------------------------------------------------------

    if ($lower -match '\b(only in|currently operates in|currently available in|local market|one city|single city|first city)\b') {
        $geo += 20
    }

    if ($lower -match '\b(expanding to|plans to expand|next market|next city|next country)\b') {
        $geo += 15
    }

    # ------------------------------------------------------------
    # ESTABLISHED BUSINESS PENALTIES
    # ------------------------------------------------------------

    if ($lower -match '\b(record revenue|record sales|largest|leading|global leader|world''s largest|since 19|since 20(0|1|2)[0-9])\b') {
        $establishedPenalty += 20
    }

    if ($lower -match '\b(opens new store|opens new location|new store|new location|second location|third location|expands its store|existing business)\b') {
        $establishedPenalty += 20
    }

    if ($lower -match '\b(united rentals|realtor\.com|starlink)\b') {
        $establishedPenalty += 40
    }

    # ------------------------------------------------------------
    # SCORE
    # ------------------------------------------------------------

    $score =
        $physical +
        $novelty +
        $traction +
        $replicable +
        $geo -
        $establishedPenalty

    $score = [Math]::Max(0,[Math]::Min($score,100))

    # ------------------------------------------------------------
    # FILTER
    # ------------------------------------------------------------

    if ($physical -lt 15) { continue }
    if ($novelty -lt 15) { continue }
    if ($score -lt 45) { continue }

    if ($establishedPenalty -ge 30) {
        continue
    }

    $results += [PSCustomObject]@{
        business = $item.title
        url = $item.url
        description = $item.description
        date = $item.pubDate
        source_query = $item.query

        score = $score

        physical = $physical
        novelty = $novelty
        traction = $traction
        replicable = $replicable
        geographic_signal = $geo
        established_penalty = $establishedPenalty
    }
}

$results = @(
    $results |
    Sort-Object business -Unique |
    Sort-Object score -Descending
)

$results |
    ConvertTo-Json -Depth 6 |
    Set-Content -Encoding UTF8 $output

Write-Host ""
Write-Host "=========================================="
Write-Host "BIZNESSHUNTER — BUSINESS DISCOVERY"
Write-Host "=========================================="
Write-Host ""
Write-Host "Candidats business : $($results.Count)"
Write-Host ""

$results |
    Select-Object business,score,physical,novelty,traction,replicable,geographic_signal |
    Format-Table -Wrap -AutoSize

Write-Host ""
Write-Host "Résultats : $output"
