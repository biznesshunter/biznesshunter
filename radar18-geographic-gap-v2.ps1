$inputFile = ".\radar17_concrete_business_ideas.json"
$outputFile = ".\radar18_geographic_gaps_v2.json"

if (!(Test-Path $inputFile)) {
    Write-Host "ERROR: $inputFile not found"
    exit 1
}

$data = Get-Content $inputFile -Raw | ConvertFrom-Json

$results = foreach ($item in $data) {

    $marketProof = [int]$item.market_proof
    $replication = [int]$item.replication
    $accessibility = [int]$item.accessibility
    $competition = [int]$item.competition
    $companies = [int]$item.company_count
    $articles = [int]$item.article_count
    $countries = [int]$item.country_count

    # Geographic gap = bonus, never a hard filter
    $geographicGap = 0

    if ($countries -ge 3) {
        $geographicGap += 30
    }
    elseif ($countries -ge 2) {
        $geographicGap += 20
    }
    elseif ($countries -ge 1) {
        $geographicGap += 10
    }

    if ($competition -le 30) {
        $geographicGap += 40
    }
    elseif ($competition -le 50) {
        $geographicGap += 30
    }
    elseif ($competition -le 70) {
        $geographicGap += 15
    }

    if ($companies -ge 15) {
        $geographicGap += 20
    }
    elseif ($companies -ge 8) {
        $geographicGap += 15
    }
    elseif ($companies -ge 3) {
        $geographicGap += 10
    }

    $geographicGap = [math]::Min(100, $geographicGap)

    # Evidence
    $evidence = 0

    if ($marketProof -ge 80) {
        $evidence += 45
    }
    elseif ($marketProof -ge 60) {
        $evidence += 35
    }
    elseif ($marketProof -ge 40) {
        $evidence += 25
    }

    if ($companies -ge 20) {
        $evidence += 30
    }
    elseif ($companies -ge 10) {
        $evidence += 20
    }
    elseif ($companies -ge 5) {
        $evidence += 15
    }

    if ($articles -ge 30) {
        $evidence += 25
    }
    elseif ($articles -ge 15) {
        $evidence += 20
    }
    elseif ($articles -ge 5) {
        $evidence += 10
    }

    $evidence = [math]::Min(100, $evidence)

    # Final score
    $score = [math]::Round(
        ($marketProof * 0.30) +
        ($replication * 0.25) +
        ($geographicGap * 0.15) +
        ($accessibility * 0.15) +
        ((100 - $competition) * 0.10) +
        ($evidence * 0.05)
    )

    if ($score -ge 80) {
        $verdict = "HIGH POTENTIAL"
        $action = "DEEP VALIDATE"
    }
    elseif ($score -ge 70) {
        $verdict = "PROMISING"
        $action = "VALIDATE"
    }
    elseif ($score -ge 60) {
        $verdict = "WATCH"
        $action = "MONITOR"
    }
    else {
        $verdict = "LOW"
        $action = "REJECT"
    }

    if ($geographicGap -ge 70) {
        $gapVerdict = "STRONG GAP"
    }
    elseif ($geographicGap -ge 45) {
        $gapVerdict = "PARTIAL GAP"
    }
    elseif ($geographicGap -ge 25) {
        $gapVerdict = "WEAK GAP"
    }
    else {
        $gapVerdict = "UNKNOWN"
    }

    [PSCustomObject]@{
        idea_name = $item.idea_name
        vertical = $item.vertical
        business_model = $item.business_model
        replication_score = $score
        verdict = $verdict
        action = $action
        evidence_score = $evidence
        geographic_gap_score = $geographicGap
        geographic_gap = $gapVerdict
        market_proof = $marketProof
        replication = $replication
        accessibility = $accessibility
        competition = $competition
        company_count = $companies
        article_count = $articles
        country_count = $countries
        target_customer = $item.target_customer
        problem = $item.problem
        offer = $item.offer
        monetization = $item.monetization
        mvp = $item.mvp
        acquisition = $item.acquisition
    }
}

$results = $results |
    Sort-Object replication_score -Descending

$results |
    ConvertTo-Json -Depth 10 |
    Set-Content $outputFile -Encoding UTF8

Write-Host ""
Write-Host "=============================================================="
Write-Host " BIZNESSHUNTER - RADAR 18 V2"
Write-Host " REPLICATION + GEOGRAPHIC GAP ENGINE"
Write-Host "=============================================================="
Write-Host ""
Write-Host "Input  : $inputFile"
Write-Host "Output : $outputFile"
Write-Host "Ideas  : $($results.Count)"
Write-Host ""
Write-Host "TOP REPLICATION OPPORTUNITIES"
Write-Host "--------------------------------------------------------------"
Write-Host ""

$results |
    Select-Object -First 20 `
        replication_score,
        verdict,
        action,
        geographic_gap,
        idea_name,
        company_count,
        article_count,
        country_count |
    Format-Table -Wrap -AutoSize

Write-Host ""
Write-Host "=============================================================="
Write-Host " RADAR 18 V2 COMPLETE"
Write-Host "=============================================================="
