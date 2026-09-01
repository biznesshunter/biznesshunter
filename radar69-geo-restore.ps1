# ============================================================
# RADAR 69 - RESTAURATION GEOGRAPHIE
# ============================================================

$InputFile  = ".\radar64_consolidated.json"
$OutputFile = ".\radar69_geo_restored.json"

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "RADAR 69 - RESTAURATION GEOGRAPHIQUE" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

if (!(Test-Path $InputFile)) {
    Write-Host "ERREUR : fichier introuvable :" -ForegroundColor Red
    Write-Host $InputFile -ForegroundColor Yellow
    exit
}

$data = Get-Content $InputFile -Raw -Encoding UTF8 | ConvertFrom-Json
$data = @($data)

Write-Host "ELEMENTS SOURCE : $($data.Count)"
Write-Host ""

$output = @()

foreach ($item in $data) {

    $countries = @()

    if ($null -ne $item.countries) {
        $countries = @(
            $item.countries |
            Where-Object {
                $null -ne $_ -and
                "$_".Trim() -ne ""
            } |
            Sort-Object -Unique
        )
    }

    $cities = @()

    if ($null -ne $item.cities) {
        $cities = @(
            $item.cities |
            Where-Object {
                $null -ne $_ -and
                "$_".Trim() -ne ""
            } |
            Sort-Object -Unique
        )
    }

    $sources = @()

    if ($null -ne $item.sources) {
        $sources = @(
            $item.sources |
            Where-Object {
                $null -ne $_ -and
                "$_".Trim() -ne ""
            } |
            Sort-Object -Unique
        )
    }

    $urls = @()

    if ($null -ne $item.urls) {
        $urls = @(
            $item.urls |
            Where-Object {
                $null -ne $_ -and
                "$_".Trim() -ne ""
            } |
            Sort-Object -Unique
        )
    }

    $proofScore = 0

    if ($null -ne $item.max_proof_score) {
        try {
            $proofScore = [double]$item.max_proof_score
        }
        catch {}
    }
    elseif ($null -ne $item.proof_score) {
        try {
            $proofScore = [double]$item.proof_score
        }
        catch {}
    }

    $originalScore = 0

    if ($null -ne $item.consolidated_score) {
        try {
            $originalScore = [double]$item.consolidated_score
        }
        catch {}
    }
    elseif ($null -ne $item.final_score) {
        try {
            $originalScore = [double]$item.final_score
        }
        catch {}
    }

    $observationCount = 0

    if ($null -ne $item.observation_count) {
        try {
            $observationCount = [int]$item.observation_count
        }
        catch {}
    }

    $newItem = [ordered]@{

        idea_name = $item.idea_name

        normalized_name = if ($null -ne $item.normalized_name) {
            $item.normalized_name
        }
        else {
            "$($item.idea_name)".ToLower().Trim()
        }

        category = $item.category

        consolidated_score = [Math]::Round($originalScore,1)

        original_score = [Math]::Round($originalScore,1)

        status = $item.status

        confidence = $item.confidence

        evidence_level = $item.evidence_level

        proof_score = [Math]::Round($proofScore,1)

        country_count = $countries.Count

        city_count = $cities.Count

        source_count = $sources.Count

        observation_count = $observationCount

        url_count = $urls.Count

        live_url_count = if ($null -ne $item.live_url_count) {
            $item.live_url_count
        }
        else {
            0
        }

        countries = @($countries)

        cities = @($cities)

        sources = @($sources)

        urls = @($urls)

        geography_proven = (
            $countries.Count -gt 0 -or
            $cities.Count -gt 0
        )

        source_coverage_detected = $false

        coverage_cities_removed = 0

        scoring_version = "RADAR_69"

        economic_status = if ($null -ne $item.economic_status) {
            $item.economic_status
        }
        else {
            "PROXY_ONLY"
        }

        variants_consolidated = if ($null -ne $item.variants_consolidated) {
            $item.variants_consolidated
        }
        else {
            1
        }

        normalization_notes = @(
            if ($countries.Count -eq 0) {
                "Aucun pays explicite dans les données consolidées."
            }

            if ($cities.Count -gt 0) {
                "Villes conservées : aucune suppression géographique automatique."
            }

            if ($proofScore -eq 0) {
                "Aucune preuve quantitative de traction détectée."
            }
        )
    }

    $output += [PSCustomObject]$newItem
}

$output |
    Sort-Object `
        @{Expression="consolidated_score";Descending=$true},
        @{Expression="proof_score";Descending=$true},
        @{Expression="city_count";Descending=$true} |
    ConvertTo-Json -Depth 30 |
    Set-Content $OutputFile -Encoding UTF8

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host "RADAR 69 - TERMINE" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""
Write-Host "ELEMENTS TRAITES : $($output.Count)"
Write-Host "FICHIER GENERE : $OutputFile" -ForegroundColor Yellow
Write-Host ""
