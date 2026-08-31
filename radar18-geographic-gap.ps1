$inputFile  = ".\radar17_concrete_business_ideas.json"
$gapFile    = ".\radar16-final-gaps.json"
$outputFile = ".\radar18_geographic_gaps.json"

if (!(Test-Path $inputFile)) {
    Write-Host "ERROR: $inputFile not found"
    exit 1
}

$data = Get-Content $inputFile -Raw | ConvertFrom-Json

$gaps = $null
if (Test-Path $gapFile) {
    $gaps = Get-Content $gapFile -Raw | ConvertFrom-Json
}

function Get-Prop {
    param($obj, [string[]]$names)

    foreach ($name in $names) {
        $p = $obj.PSObject.Properties |
            Where-Object { $_.Name -ieq $name } |
            Select-Object -First 1

        if ($p) {
            return $p.Value
        }
    }

    return $null
}

function Get-Int {
    param($value)

    $n = 0
    if ([int]::TryParse(([string]$value), [ref]$n)) {
        return $n
    }

    return 0
}

function Get-GapProfile {
    param($item)

    $vertical = [string](Get-Prop $item @(
        "vertical"
    ))

    $model = [string](Get-Prop $item @(
        "business_model"
    ))

    $country = [string](Get-Prop $item @(
        "target_country",
        "country",
        "market"
    ))

    $sourceCountry = [string](Get-Prop $item @(
        "source_country",
        "origin_country"
    ))

    $companyCount = Get-Int (Get-Prop $item @(
        "company_count",
        "companies"
    ))

    $marketProof = Get-Int (Get-Prop $item @(
        "market_proof",
        "market_proof_score",
        "evidence_score"
    ))

    $competition = Get-Int (Get-Prop $item @(
        "competition",
        "competition_score",
        "competition_score_target"
    ))

    return @{
        vertical       = $vertical
        model          = $model
        country        = $country
        sourceCountry  = $sourceCountry
        companyCount   = $companyCount
        marketProof    = $marketProof
        competition    = $competition
    }
}

$results = foreach ($item in $data) {

    $profile = Get-GapProfile $item

    # ------------------------------------------------------------
    # SOURCE PROOF
    # ------------------------------------------------------------

    $sourceProof = 0

    if ($profile.marketProof -ge 80) {
        $sourceProof += 35
    }
    elseif ($profile.marketProof -ge 60) {
        $sourceProof += 25
    }
    elseif ($profile.marketProof -ge 40) {
        $sourceProof += 15
    }

    if ($profile.companyCount -ge 20) {
        $sourceProof += 35
    }
    elseif ($profile.companyCount -ge 10) {
        $sourceProof += 25
    }
    elseif ($profile.companyCount -ge 5) {
        $sourceProof += 15
    }
    elseif ($profile.companyCount -ge 2) {
        $sourceProof += 8
    }

    # ------------------------------------------------------------
    # TARGET COMPETITION
    # Lower competition = stronger geographic gap
    # ------------------------------------------------------------

    $competitionScore = 50

    if ($profile.competition -gt 0) {
        $competitionScore = 100 - $profile.competition
    }

    # ------------------------------------------------------------
    # GEOGRAPHIC GAP
    # ------------------------------------------------------------

    $geographicGap = [math]::Round(
        ($sourceProof * 0.45) +
        ($competitionScore * 0.55)
    )

    # ------------------------------------------------------------
    # FALSE GAP PROTECTION
    # ------------------------------------------------------------

    $falseGapRisk = 0

    if ($sourceProof -lt 35) {
        $falseGapRisk += 30
    }

    if ($profile.competition -ge 70) {
        $falseGapRisk += 45
    }

    if ($profile.companyCount -lt 3) {
        $falseGapRisk += 20
    }

    if ($falseGapRisk -ge 60) {
        $gapVerdict = "FALSE GAP"
    }
    elseif ($geographicGap -ge 75) {
        $gapVerdict = "STRONG GAP"
    }
    elseif ($geographicGap -ge 60) {
        $gapVerdict = "PARTIAL GAP"
    }
    elseif ($geographicGap -ge 45) {
        $gapVerdict = "WEAK GAP"
    }
    else {
        $gapVerdict = "NO CLEAR GAP"
    }

    # ------------------------------------------------------------
    # REPLICATION
    # ------------------------------------------------------------

    $replication = Get-Int (Get-Prop $item @(
        "replication",
        "replication_score"
    ))

    if ($replication -eq 0) {
        $replication = 50
    }

    # ------------------------------------------------------------
    # HOME FIT
    # ------------------------------------------------------------

    $homeFit = 50

    $ideaName = [string](Get-Prop $item @(
        "idea_name",
        "name",
        "concept"
    ))

    $text = "$ideaName $vertical $model".ToLower()

    $homeKeywords = @(
        "home",
        "domicile",
        "mobile",
        "inspection",
        "storage",
        "rental",
        "repair",
        "service",
        "visite",
        "montage",
        "nettoyage",
        "promenade"
    )

    foreach ($keyword in $homeKeywords) {
        if ($text -like "*$keyword*") {
            $homeFit += 5
        }
    }

    $homeFit = [math]::Min(100,$homeFit)

    # ------------------------------------------------------------
    # FINAL REPLICATION OPPORTUNITY
    # ------------------------------------------------------------

    $replicationOpportunity = [math]::Round(
        ($geographicGap * 0.40) +
        ($sourceProof * 0.20) +
        ($replication * 0.20) +
        ($homeFit * 0.20)
    )

    if ($gapVerdict -eq "FALSE GAP") {
        $replicationOpportunity = [math]::Min(
            $replicationOpportunity,
            45
        )
    }

    if ($replicationOpportunity -ge 75) {
        $action = "DEEP VALIDATE"
    }
    elseif ($replicationOpportunity -ge 60) {
        $action = "VALIDATE"
    }
    elseif ($replicationOpportunity -ge 45) {
        $action = "MONITOR"
    }
    else {
        $action = "REJECT"
    }

    # ------------------------------------------------------------
    # EXPLANATION
    # ------------------------------------------------------------

    if ($gapVerdict -eq "STRONG GAP") {
        $thesis = "Business proven elsewhere with limited competition in the target market and credible replication potential."
    }
    elseif ($gapVerdict -eq "PARTIAL GAP") {
        $thesis = "Business proven elsewhere with some target-market competition; differentiation is required."
    }
    elseif ($gapVerdict -eq "FALSE GAP") {
        $thesis = "The apparent gap is not reliable enough because evidence or market conditions are insufficient."
    }
    else {
        $thesis = "Current evidence does not establish a sufficiently attractive geographic replication gap."
    }

    [PSCustomObject]@{

        idea_name = $ideaName

        vertical = $vertical
        business_model = $model

        source_country = $profile.sourceCountry
        target_country = $profile.country

        geographic_gap_score = $geographicGap
        geographic_gap_verdict = $gapVerdict

        source_proof_score = $sourceProof
        target_competition_score = $competitionScore

        replication_score = $replication
        home_based_score = $homeFit

        false_gap_risk = $falseGapRisk

        replication_opportunity_score = $replicationOpportunity

        action = $action

        thesis = $thesis

        company_count = $profile.companyCount
        market_proof = $profile.marketProof
        competition = $profile.competition

        evidence_quality = if ($sourceProof -ge 70) {
            "STRONG"
        }
        elseif ($sourceProof -ge 45) {
            "MODERATE"
        }
        else {
            "WEAK"
        }
    }
}

$results = $results |
    Sort-Object replication_opportunity_score -Descending

$results |
    ConvertTo-Json -Depth 10 |
    Set-Content $outputFile -Encoding UTF8

Write-Host ""
Write-Host "=============================================================="
Write-Host " BIZNESSHUNTER - RADAR 18"
Write-Host " GEOGRAPHIC GAP ENGINE"
Write-Host "=============================================================="
Write-Host ""
Write-Host "Input    : $inputFile"
Write-Host "Gap data : $gapFile"
Write-Host "Output   : $outputFile"
Write-Host "Ideas    : $($results.Count)"
Write-Host ""

Write-Host "TOP GEOGRAPHIC REPLICATION OPPORTUNITIES"
Write-Host "--------------------------------------------------------------"
Write-Host ""

$results |
    Select-Object -First 20 `
        replication_opportunity_score,
        geographic_gap_verdict,
        action,
        idea_name,
        source_country,
        target_country,
        geographic_gap_score,
        source_proof_score,
        target_competition_score,
        replication_score,
        home_based_score |
    Format-Table -Wrap -AutoSize

Write-Host ""
Write-Host "=============================================================="
Write-Host " RADAR 18 COMPLETE"
Write-Host "=============================================================="
