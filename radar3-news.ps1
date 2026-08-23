$ErrorActionPreference = "Stop"

$input = ".\news_candidates.json"
$output = ".\radar3_news_candidates.json"

$articles = Get-Content $input -Raw | ConvertFrom-Json
$results = @()

# ============================================================
# RADAR 3 — BUSINESS EMERGENTS PHYSIQUES
# ============================================================

foreach ($article in $articles) {

    $text = (
        ([string]$article.title) + " " +
        ([string]$article.description)
    ) -replace '\s+', ' '

    $lower = $text.ToLower()

    # --------------------------------------------------------
    # REJET SOFTWARE PUR
    # --------------------------------------------------------

    if (
        $lower -match '\b(saas|software|api|developer tool|ai coding|code editor|llm platform|developer platform)\b' -and
        $lower -notmatch '\b(rental|delivery|store|retail|equipment|vehicle|hardware|physical|local service)\b'
    ) {
        continue
    }

    # --------------------------------------------------------
    # BUSINESS PHYSIQUE / SERVICE
    # --------------------------------------------------------

    $physical = 0

    $physicalKeywords = @(
        "rental","renting","rent",
        "equipment","vehicle","car","bike","bicycle",
        "storage","locker","warehouse",
        "delivery","courier","pickup",
        "restaurant","food","catering",
        "hotel","hospitality",
        "cleaning","repair","maintenance",
        "installation","home service",
        "pet care","dog","pet",
        "childcare","babysitting",
        "camping","outdoor",
        "event","events",
        "fitness","gym",
        "laundry",
        "moving",
        "marketplace",
        "local service",
        "physical product",
        "consumer product",
        "retail","store","shop"
    )

    foreach ($keyword in $physicalKeywords) {
        if ($lower -match "\b$([regex]::Escape($keyword))\b") {
            $physical += 4
        }
    }

    $physical = [Math]::Min($physical, 30)

    if ($physical -lt 8) {
        continue
    }

    # --------------------------------------------------------
    # NOUVEAUTÉ
    # --------------------------------------------------------

    $newness = 0

    if ($lower -match '\b(new|newly|launch|launched|launches|opening|opened|founded|created|debut|introduces|introduced|rolls out|starts)\b') {
        $newness += 15
    }

    if ($lower -match '\b(2026|2025)\b') {
        $newness += 10
    }

    if ($lower -match '\b(recently|just|first|early stage|pilot|new market)\b') {
        $newness += 10
    }

    $newness = [Math]::Min($newness, 30)

    # --------------------------------------------------------
    # TRACTION
    # --------------------------------------------------------

    $traction = 0

    if ($lower -match '\b(customers?|users?|members?|orders?|bookings?|sales|revenue|profits?|sold|paying)\b') {
        $traction += 10
    }

    if ($lower -match '\b(growth|grew|growing|demand|traction|popular|successful|record|milestone)\b') {
        $traction += 10
    }

    if ($lower -match '\b(funding|funded|raised|investment|seed|million|investor)\b') {
        $traction += 10
    }

    $traction = [Math]::Min($traction, 30)

    # --------------------------------------------------------
    # GÉOGRAPHIE
    # --------------------------------------------------------

    $geo = 0

    if ($lower -match '\b(city|local|neighborhood|region|county|town|community)\b') {
        $geo += 10
    }

    if ($lower -match '\b(expand|expanding|expansion|second location|new location|new city|new country)\b') {
        $geo += 15
    }

    $geo = [Math]::Min($geo, 25)

    # --------------------------------------------------------
    # MODÈLE RÉPLICABLE
    # --------------------------------------------------------

    $replicable = 0

    if ($lower -match '\b(rental|sharing|marketplace|delivery|subscription|membership|on-demand)\b') {
        $replicable += 15
    }

    if ($lower -match '\b(franchise|replicate|scale|scaling|expansion)\b') {
        $replicable += 10
    }

    $replicable = [Math]::Min($replicable, 25)

    # --------------------------------------------------------
    # SCORE
    # --------------------------------------------------------

    $score =
        $physical +
        $newness +
        $traction +
        $geo +
        $replicable

    $score = [Math]::Min($score,100)

    # --------------------------------------------------------
    # VERDICT
    # --------------------------------------------------------

    if ($score -ge 60) {
        $verdict = "HIGH PRIORITY"
    }
    elseif ($score -ge 40) {
        $verdict = "REVIEW"
    }
    else {
        $verdict = "LOW"
    }

    if ($score -lt 40) {
        continue
    }

    $results += [PSCustomObject]@{
        title = $article.title
        url = $article.link
        description = $article.description
        pubDate = $article.pubDate
        query = $article.query

        score = $score
        verdict = $verdict

        physical = $physical
        newness = $newness
        traction = $traction
        geographic_signal = $geo
        replicable = $replicable
    }
}

$results = @(
    $results |
    Sort-Object title -Unique |
    Sort-Object score -Descending
)

$results |
    ConvertTo-Json -Depth 6 |
    Set-Content -Encoding UTF8 $output

Write-Host ""
Write-Host "=========================================="
Write-Host "BIZNESSHUNTER — RADAR 3 NEWS"
Write-Host "=========================================="
Write-Host ""
Write-Host "Articles analysés : $($articles.Count)"
Write-Host "Candidats retenus : $($results.Count)"
Write-Host ""

$results |
    Select-Object -First 30 title,score,verdict,physical,newness,traction,geographic_signal,replicable |
    Format-Table -Wrap -AutoSize

Write-Host ""
Write-Host "Résultats : $output"
