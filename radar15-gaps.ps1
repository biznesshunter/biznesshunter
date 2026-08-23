# RADAR 15 - GAP OPPORTUNITY ENGINE

$inputFile = ".\radar14_niches.json"
$outputFile = ".\radar15_gap_opportunities.json"

$data = Get-Content $inputFile -Raw | ConvertFrom-Json

$results = foreach ($item in $data) {

    $articles = [int]$item.article_count

    # -----------------------------
    # MARKET PROOF
    # -----------------------------
    $marketProof = [math]::Min(100, $articles * 2)

    # -----------------------------
    # COPYCAT FEASIBILITY
    # -----------------------------
    $keywords = ([string]$item.keywords).ToLower()

    $replication = 50

    if ($keywords -match "marketplace|platform|rental|on-demand|subscription") {
        $replication += 15
    }

    if ($keywords -match "mobile|local|delivery|repair|service") {
        $replication += 10
    }

    if ($keywords -match "drone|veterinary|construction|facility|equipment") {
        $replication -= 15
    }

    $replication = [math]::Max(0,[math]::Min(100,$replication))

    # -----------------------------
    # NICHE GAP
    # -----------------------------
    if ($articles -le 5) {
        $nicheGap = 85
    }
    elseif ($articles -le 10) {
        $nicheGap = 75
    }
    elseif ($articles -le 20) {
        $nicheGap = 65
    }
    elseif ($articles -le 40) {
        $nicheGap = 50
    }
    else {
        $nicheGap = 35
    }

    # -----------------------------
    # GEOGRAPHIC GAP
    # -----------------------------
    # Proxy temporaire basé sur la quantité
    # de validation disponible.
    #
    # Radar 16 pourra remplacer ceci
    # par une vraie analyse pays -> pays.

    if ($articles -ge 50) {
        $geographicGap = 70
    }
    elseif ($articles -ge 20) {
        $geographicGap = 60
    }
    elseif ($articles -ge 10) {
        $geographicGap = 50
    }
    else {
        $geographicGap = 40
    }

    # -----------------------------
    # COMPETITION GAP
    # -----------------------------
    # Plus le modèle est documenté,
    # plus la concurrence potentielle
    # est supposée forte.

    $competitionGap = 100 - $marketProof

    # -----------------------------
    # GAP SCORE
    # -----------------------------
    $gapScore = [math]::Round(
        ($marketProof * 0.20) +
        ($geographicGap * 0.20) +
        ($competitionGap * 0.20) +
        ($nicheGap * 0.15) +
        ($replication * 0.25)
    )

    # -----------------------------
    # VERDICT
    # -----------------------------

    if ($gapScore -ge 75) {
        $verdict = "HIGH GAP"
    }
    elseif ($gapScore -ge 65) {
        $verdict = "GOOD GAP"
    }
    elseif ($gapScore -ge 55) {
        $verdict = "MODERATE GAP"
    }
    elseif ($gapScore -ge 45) {
        $verdict = "LOW GAP"
    }
    else {
        $verdict = "NO CLEAR GAP"
    }

    # -----------------------------
    # EXPLANATION
    # -----------------------------

    $why = @()

    if ($marketProof -ge 60) {
        $why += "strong market validation"
    }

    if ($geographicGap -ge 60) {
        $why += "potential geographic expansion gap"
    }

    if ($competitionGap -ge 60) {
        $why += "limited market saturation signal"
    }

    if ($nicheGap -ge 60) {
        $why += "narrow niche with relatively few signals"
    }

    if ($replication -ge 70) {
        $why += "high copycat feasibility"
    }

    if ($why.Count -eq 0) {
        $whyText = "weak or inconclusive gap signals"
    }
    else {
        $whyText = $why -join " / "
    }

    [PSCustomObject]@{

        opportunity = $item.parent_opportunity

        vertical = $item.vertical

        article_count = $articles

        keywords = $item.keywords

        market_proof = $marketProof

        geographic_gap = $geographicGap

        competition_gap = $competitionGap

        niche_gap = $nicheGap

        replication_score = $replication

        gap_score = $gapScore

        verdict = $verdict

        confidence = [math]::Round(
            ($marketProof * 0.35) +
            ($replication * 0.25) +
            ($nicheGap * 0.20) +
            ($geographicGap * 0.20)
        )

        why_gap = $whyText
    }
}

$results |
    Sort-Object gap_score -Descending |
    ConvertTo-Json -Depth 10 |
    Set-Content $outputFile -Encoding UTF8

Write-Host ""
Write-Host "========================================"
Write-Host " BiznessHunter - Radar 15"
Write-Host " GAP OPPORTUNITY ENGINE"
Write-Host "========================================"
Write-Host ""

Write-Host "Input  : $inputFile"
Write-Host "Output : $outputFile"
Write-Host ""

Write-Host "Niches analyzed : $($data.Count)"
Write-Host ""

$results |
    Select-Object -First 25 `
        gap_score,
        verdict,
        confidence,
        opportunity,
        article_count,
        market_proof,
        geographic_gap,
        competition_gap,
        niche_gap,
        replication_score |
    Format-Table -Wrap -AutoSize
