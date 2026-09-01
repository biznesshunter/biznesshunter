$data = Get-Content .\radar59_proof_classified.json -Raw | ConvertFrom-Json

$result = foreach ($item in @($data)) {

    $observations = [int]$item.observation_count
    $sources      = [int]$item.source_count
    $cities       = [int]$item.city_count
    $urls         = [int]$item.url_count
    $live         = [int]$item.live_url_count

    # =========================================
    # PROOF SCORE
    # =========================================

    $score = 0

    # Source identifiable
    if ($sources -ge 1) {
        $score += 30
    }

    # Plusieurs sources indépendantes
    if ($sources -ge 2) {
        $score += 10
    }

    if ($sources -ge 3) {
        $score += 10
    }

    # URL exploitable
    if ($urls -ge 1) {
        $score += 15
    }

    # URL réellement accessible
    if ($live -ge 1) {
        $score += 20
    }

    # Plusieurs URL réellement accessibles
    if ($live -ge 2) {
        $score += 5
    }

    # Présence géographique
    if ($cities -ge 5) {
        $score += 5
    }

    if ($cities -ge 10) {
        $score += 5
    }

    if ($score -gt 100) {
        $score = 100
    }

    # =========================================
    # PROOF STATUS
    # =========================================

    if ($score -ge 80) {
        $proofStatus = "PROVEN"
    }
    elseif ($score -ge 60) {
        $proofStatus = "STRONG_SUPPORTED"
    }
    elseif ($score -ge 40) {
        $proofStatus = "SUPPORTED"
    }
    elseif ($score -ge 20) {
        $proofStatus = "WEAK"
    }
    else {
        $proofStatus = "UNVERIFIED"
    }

    # =========================================
    # REASON
    # =========================================

    $reasons = @()

    if ($sources -gt 0) {
        $reasons += "$sources source(s)"
    }

    if ($urls -gt 0) {
        $reasons += "$urls URL(s)"
    }

    if ($live -gt 0) {
        $reasons += "$live URL(s) live"
    }

    if ($cities -gt 0) {
        $reasons += "$cities cities"
    }

    $proofReason = $reasons -join " | "

    [PSCustomObject]@{

        idea_name = $item.idea_name
        country   = $item.country
        category  = $item.category

        observation_count = $observations
        source_count      = $sources
        city_count        = $cities

        url_count      = $urls
        live_url_count = $live

        proof_score  = $score
        proof_status = $proofStatus
        proof_reason = $proofReason

        sources = @($item.sources)
        cities  = @($item.cities)
        urls    = @($item.urls)
    }
}

# =========================================
# SAVE
# =========================================

$result |
    Sort-Object proof_score -Descending |
    ConvertTo-Json -Depth 15 |
    Set-Content .\radar60_proof_score.json -Encoding UTF8

# =========================================
# OUTPUT
# =========================================

Write-Host ""
Write-Host "========================================="
Write-Host "RADAR 60 - PROOF SCORE"
Write-Host "========================================="
Write-Host ""

Write-Host "Opportunités : $($result.Count)"
Write-Host ""

Write-Host "STATUT DE PREUVE :"

$result |
    Group-Object proof_status |
    Select-Object Name,Count |
    Sort-Object Name |
    Format-Table -AutoSize

Write-Host ""
Write-Host "TOP 15 PAR SCORE DE PREUVE :"

$result |
    Sort-Object proof_score -Descending |
    Select-Object -First 15 `
        idea_name,
        country,
        proof_score,
        proof_status,
        source_count,
        city_count,
        url_count,
        live_url_count |
    Format-Table -AutoSize

Write-Host ""
Write-Host "PROVEN :"

$result |
    Where-Object proof_status -eq "PROVEN" |
    Sort-Object proof_score -Descending |
    Select-Object `
        idea_name,
        country,
        proof_score,
        source_count,
        city_count,
        live_url_count |
    Format-Table -AutoSize

Write-Host ""
Write-Host "Fichier créé : radar60_proof_score.json"
Write-Host ""
