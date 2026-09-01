# RADAR 64 - OPPORTUNITY CONSOLIDATION
$ErrorActionPreference = "Stop"

$inputFile = ".\radar63_evidence_metrics.json"
$outputFile = ".\radar64_consolidated.json"

if (-not (Test-Path $inputFile)) {
    Write-Host "ERREUR : fichier introuvable : $inputFile" -ForegroundColor Red
    exit 1
}

# =========================================
# LOAD
# =========================================

$raw = Get-Content $inputFile -Raw -Encoding UTF8
$json = $raw | ConvertFrom-Json

# Supporte tableau JSON ou objet unique
if ($json -is [System.Array]) {
    $data = @($json)
}
elseif ($json.idea_name) {
    $data = @($json)
}
else {
    $data = @()

    foreach ($p in $json.PSObject.Properties) {
        if ($p.Value -is [System.Array]) {
            if ($p.Value.Count -gt 0 -and $p.Value[0].idea_name) {
                $data = @($p.Value)
                break
            }
        }
    }
}

if ($data.Count -eq 0) {
    Write-Host "ERREUR : aucune opportunité détectée." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "RADAR 64 - OPPORTUNITY CONSOLIDATION" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Entrées : $($data.Count)"
Write-Host ""

# =========================================
# HELPERS
# =========================================

function To-Int($v) {
    if ($null -eq $v -or "$v" -eq "") {
        return 0
    }

    try {
        return [int]$v
    }
    catch {
        return 0
    }
}

function Get-Array($v) {
    if ($null -eq $v) {
        return @()
    }

    if ($v -is [System.Array]) {
        return @(
            $v |
            Where-Object {
                $null -ne $_ -and "$_".Trim() -ne ""
            }
        )
    }

    if ("$v".Trim() -ne "") {
        return @($v)
    }

    return @()
}

function Normalize-Name([string]$name) {

    if (-not $name) {
        return ""
    }

    $n = $name.ToLowerInvariant().Trim()

    $n = $n -replace '\s+', ' '

    $n = $n -replace '\s+(fr|uk|es)$', ''

    $n = $n.Trim(' ','.',',',';',':','-')

    return $n
}

# =========================================
# GROUP
# =========================================

$groups = @{}

foreach ($item in $data) {

    if (-not $item.idea_name) {
        continue
    }

    $key = Normalize-Name $item.idea_name

    if (-not $groups.ContainsKey($key)) {
        $groups[$key] = New-Object System.Collections.ArrayList
    }

    [void]$groups[$key].Add($item)
}

Write-Host "Opportunités uniques : $($groups.Count)"
Write-Host ""

# =========================================
# CONSOLIDATION
# =========================================

$result = New-Object System.Collections.ArrayList

foreach ($key in $groups.Keys) {

    $items = @($groups[$key])

    # =====================================
    # REPRESENTATIVE
    # =====================================

    $representative = $items |
        Sort-Object @{Expression={ To-Int $_.final_score };Descending=$true} |
        Select-Object -First 1

    $ideaName = $representative.idea_name
    $category = $representative.category

    # =====================================
    # COUNTRIES
    # =====================================

    $countries = @(
        $items |
        ForEach-Object {
            Get-Array $_.countries
            if ($_.country) {
                $_.country
            }
        } |
        Where-Object { "$_".Trim() -ne "" } |
        Sort-Object -Unique
    )

    # =====================================
    # SOURCES
    # =====================================

    $sources = @(
        $items |
        ForEach-Object {
            Get-Array $_.sources
        } |
        Where-Object { "$_".Trim() -ne "" } |
        Sort-Object -Unique
    )

    # =====================================
    # CITIES
    # =====================================

    $cities = @(
        $items |
        ForEach-Object {
            Get-Array $_.cities
        } |
        Where-Object { "$_".Trim() -ne "" } |
        Sort-Object -Unique
    )

    # =====================================
    # URLS
    # =====================================

    $urls = @(
        $items |
        ForEach-Object {
            Get-Array $_.urls
        } |
        Where-Object { "$_".Trim() -ne "" } |
        Sort-Object -Unique
    )

    # =====================================
    # NUMERIC METRICS
    # =====================================

    $observationCount = 0
    $urlCount = 0
    $liveUrlCount = 0
    $bestFinalScore = 0
    $maxEvidence = 0
    $maxProof = 0

    foreach ($item in $items) {

        $observationCount += To-Int $item.observation_count
        $urlCount += To-Int $item.url_count
        $liveUrlCount += To-Int $item.live_url_count

        $score = To-Int $item.final_score
        $evidence = To-Int $item.evidence_component
        $proof = To-Int $item.max_proof_score

        if ($score -gt $bestFinalScore) {
            $bestFinalScore = $score
        }

        if ($evidence -gt $maxEvidence) {
            $maxEvidence = $evidence
        }

        if ($proof -gt $maxProof) {
            $maxProof = $proof
        }
    }

    # =====================================
    # COUNTS
    # =====================================

    $countryCount = @($countries).Count
    $sourceCount = @($sources).Count
    $cityCount = @($cities).Count

    # =====================================
    # EVIDENCE
    # =====================================

    if (
        $liveUrlCount -ge 2 -and
        $sourceCount -ge 3 -and
        $countryCount -ge 3 -and
        $cityCount -ge 15
    ) {
        $evidenceLevel = "VERY_STRONG"
    }
    elseif (
        $liveUrlCount -ge 1 -and
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
        $liveUrlCount -ge 1
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
    # SCORE
    # =====================================

    $consolidatedScore = $bestFinalScore

    if ($countryCount -ge 3) {
        $consolidatedScore += 5
    }
    elseif ($countryCount -ge 2) {
        $consolidatedScore += 3
    }

    if ($sourceCount -ge 3) {
        $consolidatedScore += 4
    }
    elseif ($sourceCount -ge 2) {
        $consolidatedScore += 2
    }

    if ($cityCount -ge 20) {
        $consolidatedScore += 4
    }
    elseif ($cityCount -ge 10) {
        $consolidatedScore += 2
    }

    if ($liveUrlCount -ge 2) {
        $consolidatedScore += 4
    }
    elseif ($liveUrlCount -eq 1) {
        $consolidatedScore += 2
    }

    if ($consolidatedScore -gt 100) {
        $consolidatedScore = 100
    }

    # =====================================
    # STATUS
    # =====================================

    if (
        $consolidatedScore -ge 90 -and
        $confidence -eq "HIGH"
    ) {
        $status = "TOP_OPPORTUNITY"
    }
    elseif ($consolidatedScore -ge 80) {
        $status = "STRONG_OPPORTUNITY"
    }
    elseif ($consolidatedScore -ge 70) {
        $status = "PROMISING"
    }
    elseif ($consolidatedScore -ge 60) {
        $status = "WATCHLIST"
    }
    else {
        $status = "REJECT"
    }

    # =====================================
    # OUTPUT
    # =====================================

    [void]$result.Add(
        [PSCustomObject]@{
            idea_name = $ideaName
            normalized_name = $key
            category = $category

            consolidated_score = [int]$consolidatedScore
            best_individual_score = [int]$bestFinalScore

            status = $status
            confidence = $confidence
            evidence_level = $evidenceLevel

            country_count = [int]$countryCount
            source_count = [int]$sourceCount
            city_count = [int]$cityCount

            observation_count = [int]$observationCount

            url_count = [int]$urlCount
            live_url_count = [int]$liveUrlCount

            max_evidence_component = [int]$maxEvidence
            max_proof_score = [int]$maxProof

            countries = @($countries)
            sources = @($sources)
            cities = @($cities)
            urls = @($urls)

            variants_consolidated = [int]$items.Count

            scoring_version = "RADAR_64"
        }
    )
}

# =========================================
# SORT
# =========================================

$result = @(
    $result |
    Sort-Object `
        @{Expression="consolidated_score";Descending=$true},
        @{Expression="city_count";Descending=$true},
        @{Expression="source_count";Descending=$true}
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
Write-Host "RADAR 64 - RESULTAT" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""

Write-Host "ENTREES : $($data.Count)"
Write-Host "OPPORTUNITES CONSOLIDEES : $($result.Count)" -ForegroundColor Green
Write-Host ""

Write-Host "STATUT :" -ForegroundColor Yellow

$result |
    Group-Object status |
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

Write-Host "PREUVE :" -ForegroundColor Yellow

$result |
    Group-Object evidence_level |
    Select-Object Name,Count |
    Sort-Object Name |
    Format-Table -AutoSize

Write-Host ""

Write-Host "TOP OPPORTUNITES :" -ForegroundColor Green
Write-Host ""

$result |
    Select-Object -First 15 `
        idea_name,
        consolidated_score,
        status,
        confidence,
        evidence_level,
        country_count,
        source_count,
        city_count,
        observation_count,
        live_url_count |
    Format-Table -AutoSize

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Fichier créé : $outputFile" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
