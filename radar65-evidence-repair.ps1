# =========================================
# RADAR 65 - EVIDENCE DATA REPAIR
# =========================================

$ErrorActionPreference = "Stop"

$inputFile  = ".\radar64_consolidated.json"
$outputFile = ".\radar65_evidence_repaired.json"

if (-not (Test-Path $inputFile)) {
    Write-Host "ERREUR : $inputFile introuvable." -ForegroundColor Red
    exit 1
}

# =========================================
# HELPERS
# =========================================

function To-Int {
    param($Value)

    if ($null -eq $Value -or "$Value".Trim() -eq "") {
        return 0
    }

    try {
        return [int]$Value
    }
    catch {
        return 0
    }
}

function To-Array {
    param($Value)

    if ($null -eq $Value) {
        return @()
    }

    if ($Value -is [System.Array]) {
        return @(
            $Value |
            ForEach-Object {
                if ($null -ne $_ -and "$_".Trim() -ne "") {
                    "$_".Trim()
                }
            }
        )
    }

    $text = "$Value".Trim()

    if ($text -eq "") {
        return @()
    }

    if ($text.StartsWith("[") -and $text.EndsWith("]")) {
        try {
            $parsed = $text | ConvertFrom-Json

            if ($parsed -is [System.Array]) {
                return @(
                    $parsed |
                    ForEach-Object {
                        if ($null -ne $_ -and "$_".Trim() -ne "") {
                            "$_".Trim()
                        }
                    }
                )
            }
        }
        catch {
        }
    }

    return @($text)
}

function Unique-Array {
    param($Value)

    return @(
        To-Array $Value |
        ForEach-Object {
            "$_".Trim()
        } |
        Where-Object {
            $_ -ne ""
        } |
        Sort-Object -Unique
    )
}

# =========================================
# LOAD
# =========================================

$data = @(Get-Content $inputFile -Raw | ConvertFrom-Json)

# =========================================
# STRUCTURE SAFETY
# =========================================

if ($data.Count -eq 1) {

    $single = $data[0]

    $possibleArrayProperties = @(
        "items",
        "results",
        "opportunities",
        "data"
    )

    foreach ($property in $possibleArrayProperties) {

        if ($null -ne $single.PSObject.Properties[$property]) {

            $candidate = @($single.$property)

            if ($candidate.Count -gt 0) {
                $data = $candidate
                break
            }
        }
    }
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "RADAR 65 - EVIDENCE DATA REPAIR" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "SOURCE : $inputFile"
Write-Host "ENTREES : $($data.Count)"
Write-Host ""

# =========================================
# RESULT
# =========================================

$result = New-Object System.Collections.ArrayList

foreach ($item in $data) {

    $ideaName = "$($item.idea_name)".Trim()
    $category = "$($item.category)".Trim()

    if ($ideaName -eq "") {
        continue
    }

    # =====================================
    # ARRAYS
    # =====================================

    $countries = Unique-Array $item.countries
    $sources   = Unique-Array $item.sources
    $cities    = Unique-Array $item.cities
    $urls      = Unique-Array $item.urls

    # =====================================
    # METRICS
    # =====================================

    $observations = To-Int $item.observation_count
    $urlCount     = To-Int $item.url_count
    $liveUrls     = To-Int $item.live_url_count

    $bestScore    = To-Int $item.best_individual_score
    $maxProof     = To-Int $item.max_proof_score
    $maxEvidence  = To-Int $item.max_evidence_component

    # =====================================
    # URL COHERENCE
    # =====================================

    if ($urls.Count -gt $urlCount) {
        $urlCount = $urls.Count
    }

    if ($liveUrls -lt 0) {
        $liveUrls = 0
    }

    if ($urlCount -gt 0 -and $liveUrls -gt $urlCount) {
        $liveUrls = $urlCount
    }

    # =====================================
    # OBSERVATION FALLBACK
    # =====================================

    if ($observations -le 0) {

        $observations = 1

        if ($cities.Count -gt $observations) {
            $observations = $cities.Count
        }

        if ($sources.Count -gt $observations) {
            $observations = $sources.Count
        }
    }

    # =====================================
    # COUNTS
    # =====================================

    $countryCount = [int]$countries.Count
    $sourceCount  = [int]$sources.Count
    $cityCount    = [int]$cities.Count

    # =====================================
    # EVIDENCE LEVEL
    # =====================================

    if (
        $liveUrls -ge 2 -and
        $sourceCount -ge 3 -and
        $countryCount -ge 3 -and
        $cityCount -ge 15
    ) {
        $evidenceLevel = "VERY_STRONG"
    }
    elseif (
        $liveUrls -ge 1 -and
        $sourceCount -ge 3 -and
        $countryCount -ge 3
    ) {
        $evidenceLevel = "STRONG"
    }
    elseif (
        $sourceCount -ge 2 -and
        $countryCount -ge 2
    ) {
        $evidenceLevel = "MODERATE"
    }
    elseif ($sourceCount -ge 1) {
        $evidenceLevel = "WEAK"
    }
    else {
        $evidenceLevel = "NONE"
    }

    # =====================================
    # CONFIDENCE
    # =====================================

    if (
        $sourceCount -ge 3 -and
        $countryCount -ge 3 -and
        $cityCount -ge 15 -and
        $liveUrls -ge 1
    ) {
        $confidence = "HIGH"
    }
    elseif (
        $sourceCount -ge 2 -and
        $countryCount -ge 2
    ) {
        $confidence = "MEDIUM"
    }
    else {
        $confidence = "LOW"
    }

    # =====================================
    # EVIDENCE QUALITY
    # =====================================

    $qualityPoints = 0

    if ($observations -ge 10) {
        $qualityPoints += 2
    }
    elseif ($observations -ge 5) {
        $qualityPoints += 1
    }

    if ($sourceCount -ge 3) {
        $qualityPoints += 2
    }
    elseif ($sourceCount -ge 2) {
        $qualityPoints += 1
    }

    if ($countryCount -ge 3) {
        $qualityPoints += 2
    }
    elseif ($countryCount -ge 2) {
        $qualityPoints += 1
    }

    if ($cityCount -ge 15) {
        $qualityPoints += 2
    }
    elseif ($cityCount -ge 5) {
        $qualityPoints += 1
    }

    if ($liveUrls -ge 2) {
        $qualityPoints += 2
    }
    elseif ($liveUrls -ge 1) {
        $qualityPoints += 1
    }

    if ($qualityPoints -ge 8) {
        $evidenceQuality = "EXCELLENT"
    }
    elseif ($qualityPoints -ge 6) {
        $evidenceQuality = "GOOD"
    }
    elseif ($qualityPoints -ge 4) {
        $evidenceQuality = "FAIR"
    }
    elseif ($qualityPoints -ge 2) {
        $evidenceQuality = "WEAK"
    }
    else {
        $evidenceQuality = "NONE"
    }

    # =====================================
    # OUTPUT
    # =====================================

    [void]$result.Add(
        [PSCustomObject]@{

            idea_name = $ideaName

            normalized_name = "$($item.normalized_name)"

            category = $category

            best_individual_score = [int]$bestScore

            confidence = $confidence

            evidence_level = $evidenceLevel

            evidence_quality = $evidenceQuality

            evidence_quality_points = [int]$qualityPoints

            observation_count = [int]$observations

            source_count = [int]$sourceCount

            country_count = [int]$countryCount

            city_count = [int]$cityCount

            url_count = [int]$urlCount

            live_url_count = [int]$liveUrls

            max_evidence_component = [int]$maxEvidence

            max_proof_score = [int]$maxProof

            countries = @($countries)

            sources = @($sources)

            cities = @($cities)

            urls = @($urls)

            variants_consolidated = To-Int $item.variants_consolidated

            scoring_version = "RADAR_65"

            evidence_status = "REPAIRED"
        }
    )
}

# =========================================
# SORT
# =========================================

$result = @(
    $result |
    Sort-Object `
        @{Expression="best_individual_score";Descending=$true},
        @{Expression="country_count";Descending=$true},
        @{Expression="source_count";Descending=$true},
        @{Expression="city_count";Descending=$true}
)

# =========================================
# SAVE
# =========================================

$result |
    ConvertTo-Json -Depth 20 |
    Set-Content $outputFile -Encoding UTF8

# =========================================
# DISPLAY
# =========================================

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host "RADAR 65 - RESULTAT" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""

Write-Host "OPPORTUNITES : $($result.Count)"
Write-Host ""

Write-Host "QUALITE DES PREUVES :" -ForegroundColor Yellow

$result |
    Group-Object evidence_quality |
    Select-Object Name,Count |
    Sort-Object Name |
    Format-Table -AutoSize

Write-Host ""

Write-Host "NIVEAU DE PREUVE :" -ForegroundColor Yellow

$result |
    Group-Object evidence_level |
    Select-Object Name,Count |
    Sort-Object Name |
    Format-Table -AutoSize

Write-Host ""

Write-Host "CONFIANCE :" -ForegroundColor Yellow

$result |
    Group-Object confidence |
    Select-Object Name,Count |
    Sort-Object Name |
    Format-Table -AutoSize

Write-Host ""

Write-Host "TOP OPPORTUNITES :" -ForegroundColor Green
Write-Host ""

$result |
    Select-Object -First 15 `
        idea_name,
        best_individual_score,
        confidence,
        evidence_level,
        evidence_quality,
        evidence_quality_points,
        country_count,
        source_count,
        city_count,
        observation_count,
        url_count,
        live_url_count |
    Format-Table -AutoSize

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Fichier créé : $outputFile" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

