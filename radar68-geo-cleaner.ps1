# ============================================================
# RADAR 68 - CORRECTION GEOGRAPHIE
# ============================================================

$InputFile  = ".\radar64_consolidated.json"
$OutputFile = ".\radar68_geo_clean.json"

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "RADAR 68 - NETTOYAGE GEOGRAPHIQUE" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

if (!(Test-Path $InputFile)) {
    Write-Host "ERREUR : fichier introuvable :" -ForegroundColor Red
    Write-Host $InputFile -ForegroundColor Yellow
    exit
}

$raw = Get-Content $InputFile -Raw -Encoding UTF8

try {
    $data = $raw | ConvertFrom-Json
}
catch {
    Write-Host "ERREUR : JSON invalide." -ForegroundColor Red
    exit
}

$data = @($data)

Write-Host "ELEMENTS SOURCE : $($data.Count)"
Write-Host ""

# ------------------------------------------------------------
# LISTE DES VILLES DE COUVERTURE GENERIQUE
# ------------------------------------------------------------

$genericCoverageCities = @(
    "A Coruña",
    "Aix-en-Provence",
    "Alicante",
    "Angers",
    "Barcelona",
    "Belfast",
    "Bilbao",
    "Birmingham",
    "Bordeaux",
    "Brighton",
    "Bristol",
    "Cambridge",
    "Cardiff",
    "Clermont-Ferrand",
    "Córdoba",
    "Coventry",
    "Dijon",
    "Edinburgh",
    "Gijón",
    "Glasgow",
    "Granada",
    "Grenoble",
    "Leeds",
    "Leicester",
    "Liverpool",
    "London",
    "Lyon",
    "Madrid",
    "Málaga",
    "Manchester",
    "Marseille",
    "Montpellier",
    "Murcia",
    "Nantes",
    "Newcastle",
    "Nice",
    "Nîmes",
    "Nottingham",
    "Oxford",
    "Palma",
    "Pamplona",
    "Paris",
    "Perpignan",
    "Reading",
    "Rennes",
    "Rouen",
    "Salamanca",
    "Seville",
    "Sheffield",
    "Southampton",
    "Strasbourg",
    "Tarragona",
    "Toulon",
    "Toulouse",
    "Valencia",
    "Valladolid",
    "Vigo",
    "Zaragoza"
)

# ------------------------------------------------------------
# TRAITEMENT
# ------------------------------------------------------------

$output = @()

foreach ($item in $data) {

    $cities = @()

    if ($null -ne $item.cities) {
        $cities = @($item.cities)
    }

    $countries = @()

    if ($null -ne $item.countries) {
        $countries = @(
            $item.countries |
            Where-Object {
                $_ -ne $null -and
                "$_".Trim() -ne ""
            }
        )
    }

    # --------------------------------------------------------
    # DETECTION DES VILLES GENERIQUES
    # --------------------------------------------------------

    $cleanCities = @(
        $cities |
        Where-Object {
            $genericCoverageCities -notcontains "$_"
        }
    )

    $removedCities = @(
        $cities |
        Where-Object {
            $genericCoverageCities -contains "$_"
        }
    )

    # --------------------------------------------------------
    # IMPORTANT
    #
    # Si aucun pays réel n'est prouvé et que les villes
    # correspondent à la couverture générique, on considère
    # ces villes comme NON PREUVES.
    # --------------------------------------------------------

    $realCountries = @($countries)

    if ($realCountries.Count -eq 0) {
        $realCities = @($cleanCities)
    }
    else {
        $realCities = @($cleanCities)
    }

    # --------------------------------------------------------
    # URL
    # --------------------------------------------------------

    $urls = @()

    if ($null -ne $item.urls) {
        $urls = @(
            $item.urls |
            Where-Object {
                $_ -ne $null -and
                "$_".Trim() -ne ""
            }
        )
    }

    # --------------------------------------------------------
    # PROOF SCORE
    # --------------------------------------------------------

    $proofScore = 0

    if ($null -ne $item.max_proof_score) {
        try {
            $proofScore = [double]$item.max_proof_score
        }
        catch {
            $proofScore = 0
        }
    }
    elseif ($null -ne $item.proof_score) {
        try {
            $proofScore = [double]$item.proof_score
        }
        catch {
            $proofScore = 0
        }
    }

    # --------------------------------------------------------
    # SCORE ORIGINAL
    # --------------------------------------------------------

    $originalScore = 0

    if ($null -ne $item.consolidated_score) {
        try {
            $originalScore = [double]$item.consolidated_score
        }
        catch {
            $originalScore = 0
        }
    }
    elseif ($null -ne $item.final_score) {
        try {
            $originalScore = [double]$item.final_score
        }
        catch {
            $originalScore = 0
        }
    }

    # --------------------------------------------------------
    # SCORE CORRIGE
    # --------------------------------------------------------

    $adjustedScore = $originalScore

    # Si toutes les villes étaient des villes de couverture
    # et qu'aucun pays n'est prouvé :
    if (
        $removedCities.Count -gt 0 -and
        $realCountries.Count -eq 0
    ) {
        $adjustedScore = [Math]::Min($adjustedScore, 39)
    }

    # Aucun pays + aucune ville réellement prouvée
    if (
        $realCountries.Count -eq 0 -and
        $realCities.Count -eq 0
    ) {
        $adjustedScore = [Math]::Min($adjustedScore, 35)
    }

    # Aucun score de preuve
    if ($proofScore -eq 0) {
        $adjustedScore = [Math]::Min($adjustedScore, 35)
    }

    # --------------------------------------------------------
    # CONFIANCE
    # --------------------------------------------------------

    $confidence = "LOW"
    $evidenceLevel = "WEAK"

    if (
        $proofScore -ge 70 -and
        (
            $realCountries.Count -gt 0 -or
            $realCities.Count -gt 0
        )
    ) {
        $confidence = "HIGH"
        $evidenceLevel = "STRONG"
    }
    elseif (
        $proofScore -ge 40 -or
        $realCountries.Count -gt 0 -or
        $realCities.Count -gt 0
    ) {
        $confidence = "MEDIUM"
        $evidenceLevel = "MODERATE"
    }

    # --------------------------------------------------------
    # STATUS
    # --------------------------------------------------------

    $status = "WATCHLIST"

    if (
        $proofScore -ge 70 -and
        $realCountries.Count -gt 0 -and
        $urls.Count -gt 0
    ) {
        $status = "VALIDATED"
    }
    elseif (
        $proofScore -ge 40 -or
        (
            $realCountries.Count -gt 0 -and
            $urls.Count -gt 0
        )
    ) {
        $status = "PROMISING"
    }

    # --------------------------------------------------------
    # OBSERVATIONS
    # --------------------------------------------------------

    $observationCount = 0

    if ($null -ne $item.observation_count) {
        try {
            $observationCount = [int]$item.observation_count
        }
        catch {
            $observationCount = 0
        }
    }

    # --------------------------------------------------------
    # SOURCES
    # --------------------------------------------------------

    $sources = @()

    if ($null -ne $item.sources) {
        $sources = @(
            $item.sources |
            Where-Object {
                $_ -ne $null -and
                "$_".Trim() -ne ""
            } |
            ForEach-Object {
                "$_".Trim().ToLower()
            } |
            Sort-Object -Unique
        )
    }

    # --------------------------------------------------------
    # OBJET FINAL
    # --------------------------------------------------------

    $newItem = [ordered]@{

        idea_name = $item.idea_name

        normalized_name = if ($null -ne $item.normalized_name) {
            $item.normalized_name
        }
        else {
            "$($item.idea_name)".ToLower().Trim()
        }

        category = $item.category

        consolidated_score = [Math]::Round($adjustedScore, 1)

        original_score = [Math]::Round($originalScore, 1)

        status = $status

        confidence = $confidence

        evidence_level = $evidenceLevel

        proof_score = [Math]::Round($proofScore, 1)

        country_count = $realCountries.Count

        city_count = $realCities.Count

        source_count = $sources.Count

        observation_count = $observationCount

        url_count = $urls.Count

        live_url_count = if ($null -ne $item.live_url_count) {
            $item.live_url_count
        }
        else {
            0
        }

        countries = @($realCountries)

        cities = @($realCities)

        sources = @($sources)

        urls = @($urls)

        coverage_cities_removed = $removedCities.Count

        coverage_cities = @($removedCities)

        geography_proven = (
            $realCountries.Count -gt 0 -or
            $realCities.Count -gt 0
        )

        source_coverage_detected = (
            $removedCities.Count -gt 0
        )

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

        scoring_version = "RADAR_68"

        normalization_notes = @(
            if ($removedCities.Count -gt 0) {
                "Villes correspondant à une couverture générique supprimées."
            }

            if ($realCountries.Count -eq 0) {
                "Aucun pays réellement prouvé dans les données sources."
            }

            if ($realCities.Count -eq 0) {
                "Aucune ville réellement prouvée après nettoyage."
            }

            if ($proofScore -eq 0) {
                "Aucune preuve quantitative de traction détectée."
            }

            if ($urls.Count -eq 0) {
                "Aucune URL exploitable détectée."
            }
        )
    }

    $output += [PSCustomObject]$newItem
}

# ------------------------------------------------------------
# TRI
# ------------------------------------------------------------

$output = @(
    $output |
    Sort-Object `
        @{Expression="consolidated_score";Descending=$true},
        @{Expression="proof_score";Descending=$true},
        @{Expression="country_count";Descending=$true}
)

# ------------------------------------------------------------
# EXPORT
# ------------------------------------------------------------

$output |
    ConvertTo-Json -Depth 30 |
    Set-Content $OutputFile -Encoding UTF8

# ------------------------------------------------------------
# STATISTIQUES
# ------------------------------------------------------------

$validated = @(
    $output |
    Where-Object { $_.status -eq "VALIDATED" }
).Count

$promising = @(
    $output |
    Where-Object { $_.status -eq "PROMISING" }
).Count

$watchlist = @(
    $output |
    Where-Object { $_.status -eq "WATCHLIST" }
).Count

$fakeGeo = @(
    $output |
    Where-Object {
        $_.coverage_cities_removed -gt 0
    }
).Count

$realGeo = @(
    $output |
    Where-Object {
        $_.geography_proven -eq $true
    }
).Count

# ------------------------------------------------------------
# RESULTAT
# ------------------------------------------------------------

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host "RADAR 68 - TERMINE" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""

Write-Host "ELEMENTS TRAITES : $($output.Count)"
Write-Host "VALIDATED        : $validated"
Write-Host "PROMISING        : $promising"
Write-Host "WATCHLIST        : $watchlist"
Write-Host ""

Write-Host "GEOGRAPHIE REELLE : $realGeo"
Write-Host "FAUSSE COUVERTURE : $fakeGeo"
Write-Host ""

Write-Host "FICHIER GENERE :" -ForegroundColor Cyan
Write-Host $OutputFile -ForegroundColor Yellow
Write-Host ""

Write-Host "SOURCE INTACTE." -ForegroundColor Green
Write-Host ""
