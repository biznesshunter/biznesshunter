# =========================================
# RADAR 66 - DATA PIPELINE DIAGNOSTIC
# =========================================

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "RADAR 66 - DATA PIPELINE DIAGNOSTIC" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# =========================================
# FIND JSON FILES
# =========================================

$files = @(
    Get-ChildItem -Path . -Filter "*.json" -File |
    Sort-Object LastWriteTime -Descending
)

Write-Host "FICHIERS JSON TROUVES : $($files.Count)" -ForegroundColor Yellow
Write-Host ""

foreach ($f in $files) {
    Write-Host ("{0,-45} {1,12} octets  {2}" -f `
        $f.Name,
        $f.Length,
        $f.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss"))
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "ANALYSE DES STRUCTURES" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# =========================================
# HELPERS
# =========================================

function Get-ArrayCount {
    param($Value)

    if ($null -eq $Value) {
        return 0
    }

    if ($Value -is [System.Array]) {
        return @($Value).Count
    }

    return 1
}

function Get-PropertyValue {
    param(
        $Object,
        [string[]]$Names
    )

    foreach ($name in $Names) {
        $property = $Object.PSObject.Properties[$name]

        if ($null -ne $property) {
            return $property.Value
        }
    }

    return $null
}

# =========================================
# ANALYZE EACH JSON
# =========================================

foreach ($file in $files) {

    Write-Host ""
    Write-Host "-----------------------------------------" -ForegroundColor DarkCyan
    Write-Host $file.Name -ForegroundColor Green
    Write-Host "-----------------------------------------" -ForegroundColor DarkCyan

    try {
        $raw = Get-Content $file.FullName -Raw
        $json = $raw | ConvertFrom-Json
    }
    catch {
        Write-Host "ERREUR JSON : $($_.Exception.Message)" -ForegroundColor Red
        continue
    }

    # -------------------------------------
    # ROOT TYPE
    # -------------------------------------

    if ($json -is [System.Array]) {
        $rootCount = @($json).Count
        Write-Host "RACINE : TABLEAU"
        Write-Host "ELEMENTS : $rootCount"
        $items = @($json)
    }
    else {
        Write-Host "RACINE : OBJET"

        $props = @(
            $json.PSObject.Properties.Name
        )

        Write-Host "PROPRIETES : $($props -join ', ')"

        $candidateProperties = @(
            "items",
            "results",
            "opportunities",
            "data",
            "businesses",
            "candidates",
            "records",
            "observations"
        )

        $items = @()

        foreach ($propertyName in $candidateProperties) {

            $property = $json.PSObject.Properties[$propertyName]

            if ($null -ne $property) {

                $candidate = @($property.Value)

                if ($candidate.Count -gt 0) {

                    Write-Host "COLLECTION DETECTEE : $propertyName" -ForegroundColor Yellow
                    Write-Host "ELEMENTS : $($candidate.Count)"

                    $items = $candidate
                    break
                }
            }
        }

        if ($items.Count -eq 0) {
            $items = @($json)
        }
    }

    if ($items.Count -eq 0) {
        Write-Host "AUCUNE DONNEE EXPLOITABLE." -ForegroundColor Red
        continue
    }

    # =====================================
    # SAMPLE STRUCTURE
    # =====================================

    $first = $items[0]

    Write-Host ""
    Write-Host "PROPRIETES DU PREMIER ELEMENT :" -ForegroundColor Yellow

    $first.PSObject.Properties.Name |
        Sort-Object |
        ForEach-Object {
            Write-Host "  $_"
        }

    # =====================================
    # FIELD DISCOVERY
    # =====================================

    $fieldNames = @(
        "idea_name",
        "normalized_name",
        "category",
        "country",
        "countries",
        "city",
        "cities",
        "source",
        "sources",
        "url",
        "urls",
        "live_url",
        "live_urls",
        "observation_count",
        "url_count",
        "live_url_count",
        "proof_score",
        "max_proof_score",
        "evidence_component",
        "max_evidence_component"
    )

    Write-Host ""
    Write-Host "PRESENCE DES CHAMPS :" -ForegroundColor Yellow

    foreach ($field in $fieldNames) {

        $count = 0

        foreach ($item in $items) {

            if ($null -ne $item.PSObject.Properties[$field]) {
                $count++
            }
        }

        if ($count -gt 0) {
            Write-Host ("  {0,-30} {1,6} / {2}" -f `
                $field,
                $count,
                $items.Count)
        }
    }

    # =====================================
    # COUNTRIES
    # =====================================

    $allCountries = @()

    foreach ($item in $items) {

        foreach ($field in @("country","countries")) {

            $value = Get-PropertyValue $item @($field)

            if ($null -ne $value) {

                if ($value -is [System.Array]) {
                    $allCountries += @($value)
                }
                else {
                    $allCountries += "$value"
                }
            }
        }
    }

    $allCountries = @(
        $allCountries |
        ForEach-Object {
            "$_".Trim()
        } |
        Where-Object {
            $_ -ne ""
        } |
        Sort-Object -Unique
    )

    Write-Host ""
    Write-Host "PAYS :" -ForegroundColor Yellow
    Write-Host "  Valeurs uniques : $($allCountries.Count)"

    if ($allCountries.Count -gt 0) {
        $allCountries |
            Select-Object -First 30 |
            ForEach-Object {
                Write-Host "    $_"
            }
    }
    else {
        Write-Host "  !!! AUCUN PAYS DETECTE !!!" -ForegroundColor Red
    }

    # =====================================
    # CITIES
    # =====================================

    $allCities = @()

    foreach ($item in $items) {

        foreach ($field in @("city","cities")) {

            $value = Get-PropertyValue $item @($field)

            if ($null -ne $value) {

                if ($value -is [System.Array]) {
                    $allCities += @($value)
                }
                else {
                    $allCities += "$value"
                }
            }
        }
    }

    $allCities = @(
        $allCities |
        ForEach-Object {
            "$_".Trim()
        } |
        Where-Object {
            $_ -ne ""
        } |
        Sort-Object -Unique
    )

    Write-Host ""
    Write-Host "VILLES :" -ForegroundColor Yellow
    Write-Host "  Valeurs uniques : $($allCities.Count)"

    if ($allCities.Count -gt 0) {
        $allCities |
            Select-Object -First 30 |
            ForEach-Object {
                Write-Host "    $_"
            }
    }
    else {
        Write-Host "  AUCUNE VILLE DETECTEE" -ForegroundColor Red
    }

    # =====================================
    # URLS
    # =====================================

    $allUrls = @()

    foreach ($item in $items) {

        foreach ($field in @("url","urls","live_url","live_urls")) {

            $value = Get-PropertyValue $item @($field)

            if ($null -ne $value) {

                if ($value -is [System.Array]) {
                    $allUrls += @($value)
                }
                else {
                    $allUrls += "$value"
                }
            }
        }
    }

    $allUrls = @(
        $allUrls |
        ForEach-Object {
            "$_".Trim()
        } |
        Where-Object {
            $_ -ne ""
        } |
        Sort-Object -Unique
    )

    Write-Host ""
    Write-Host "URLS :" -ForegroundColor Yellow
    Write-Host "  Valeurs uniques : $($allUrls.Count)"

    if ($allUrls.Count -gt 0) {
        $allUrls |
            Select-Object -First 20 |
            ForEach-Object {
                Write-Host "    $_"
            }
    }
    else {
        Write-Host "  !!! AUCUNE URL DETECTEE !!!" -ForegroundColor Red
    }

    # =====================================
    # SOURCES
    # =====================================

    $allSources = @()

    foreach ($item in $items) {

        foreach ($field in @("source","sources")) {

            $value = Get-PropertyValue $item @($field)

            if ($null -ne $value) {

                if ($value -is [System.Array]) {
                    $allSources += @($value)
                }
                else {
                    $allSources += "$value"
                }
            }
        }
    }

    $allSources = @(
        $allSources |
        ForEach-Object {
            "$_".Trim()
        } |
        Where-Object {
            $_ -ne ""
        } |
        Sort-Object -Unique
    )

    Write-Host ""
    Write-Host "SOURCES :" -ForegroundColor Yellow
    Write-Host "  Valeurs uniques : $($allSources.Count)"

    $allSources |
        Select-Object -First 30 |
        ForEach-Object {
            Write-Host "    $_"
        }

    # =====================================
    # SCORE DISTRIBUTION
    # =====================================

    $scoreFields = @(
        "final_score",
        "best_individual_score",
        "consolidated_score",
        "proof_score",
        "max_proof_score",
        "evidence_component",
        "max_evidence_component"
    )

    Write-Host ""
    Write-Host "CHAMPS DE SCORE :" -ForegroundColor Yellow

    foreach ($field in $scoreFields) {

        $values = @()

        foreach ($item in $items) {

            $property = $item.PSObject.Properties[$field]

            if ($null -ne $property) {

                try {
                    $values += [int]$property.Value
                }
                catch {}
            }
        }

        if ($values.Count -gt 0) {

            Write-Host ("  {0,-30} count={1}, min={2}, max={3}" -f `
                $field,
                $values.Count,
                ($values | Measure-Object -Minimum).Minimum,
                ($values | Measure-Object -Maximum).Maximum)
        }
    }

    # =====================================
    # FIRST 5 RECORDS
    # =====================================

    Write-Host ""
    Write-Host "APERÇU DES 5 PREMIERS ELEMENTS :" -ForegroundColor Yellow

    $items |
        Select-Object -First 5 |
        ForEach-Object {

            Write-Host ""
            Write-Host "--------------------------------"

            foreach ($field in @(
                "idea_name",
                "category",
                "country",
                "countries",
                "city",
                "cities",
                "source",
                "sources",
                "url",
                "urls",
                "live_url",
                "live_urls",
                "observation_count",
                "url_count",
                "live_url_count",
                "final_score",
                "best_individual_score",
                "consolidated_score",
                "proof_score",
                "max_proof_score",
                "evidence_component",
                "max_evidence_component"
            )) {

                $property = $_.PSObject.Properties[$field]

                if ($null -ne $property) {

                    $value = $property.Value

                    if ($value -is [System.Array]) {
                        $display = (@($value) -join " | ")
                    }
                    else {
                        $display = "$value"
                    }

                    if ($display.Length -gt 300) {
                        $display = $display.Substring(0,300) + "..."
                    }

                    Write-Host ("{0,-28}: {1}" -f $field,$display)
                }
            }
        }
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host "RADAR 66 - DIAGNOSTIC TERMINE" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""
Write-Host "AUCUN FICHIER N'A ETE MODIFIE." -ForegroundColor Cyan
Write-Host ""
