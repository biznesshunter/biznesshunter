# ============================================================
# RADAR 67 - EVIDENCE NORMALIZER
# Version corrigée
# ============================================================

$InputFile  = ".\radar64_consolidated.json"
$OutputFile = ".\radar67_normalized.json"

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "RADAR 67 - NORMALISATION DES PREUVES" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

if (!(Test-Path $InputFile)) {
    Write-Host "ERREUR : fichier introuvable :" -ForegroundColor Red
    Write-Host $InputFile -ForegroundColor Yellow
    exit
}

# ------------------------------------------------------------
# CHARGEMENT
# ------------------------------------------------------------

try {
    $raw = Get-Content $InputFile -Raw -Encoding UTF8
    $data = $raw | ConvertFrom-Json
}
catch {
    Write-Host "ERREUR : JSON invalide." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit
}

if ($null -eq $data) {
    Write-Host "ERREUR : aucune donnée." -ForegroundColor Red
    exit
}

$data = @($data)

Write-Host "ELEMENTS SOURCE : $($data.Count)" -ForegroundColor White
Write-Host ""

# ------------------------------------------------------------
# OUTILS
# ------------------------------------------------------------

function Get-PropertyValue {
    param(
        $Object,
        [string[]]$Names
    )

    foreach ($name in $Names) {
        if ($null -ne $Object.PSObject.Properties[$name]) {
            return $Object.$name
        }
    }

    return $null
}

function Convert-ToArray {
    param($Value)

    if ($null -eq $Value) {
        return @()
    }

    if ($Value -is [System.Array]) {
        return @($Value)
    }

    return @($Value)
}

function Normalize-StringArray {
    param($Value)

    $result = New-Object System.Collections.Generic.List[string]

    foreach ($item in (Convert-ToArray $Value)) {

        if ($null -eq $item) {
            continue
        }

        $text = [string]$item
        $text = $text.Trim()

        if ([string]::IsNullOrWhiteSpace($text)) {
            continue
        }

        if (!$result.Contains($text)) {
            $result.Add($text)
        }
    }

    return @($result)
}

function Test-ValidUrl {
    param([string]$Url)

    if ([string]::IsNullOrWhiteSpace($Url)) {
        return $false
    }

    try {
        $uri = [System.Uri]$Url

        if ($uri.Scheme -in @("http","https") -and
            -not [string]::IsNullOrWhiteSpace($uri.Host)) {
            return $true
        }
    }
    catch {}

    return $false
}

# ------------------------------------------------------------
# TRAITEMENT
# ------------------------------------------------------------

$output = New-Object System.Collections.Generic.List[object]

$index = 0

foreach ($item in $data) {

    $index++

    Write-Progress `
        -Activity "RADAR 67 - Normalisation" `
        -Status "$index / $($data.Count)" `
        -PercentComplete (($index / $data.Count) * 100)

    # --------------------------------------------------------
    # NOM
    # --------------------------------------------------------

    $name = Get-PropertyValue $item @(
        "idea_name",
        "normalized_name",
        "name",
        "business_name",
        "title"
    )

    if ($null -eq $name) {
        $name = "Opportunité sans nom"
    }

    $name = [string]$name
    $name = $name.Trim()

    # --------------------------------------------------------
    # PAYS
    # --------------------------------------------------------

    $countries = Get-PropertyValue $item @(
        "countries",
        "country",
        "country_name"
    )

    $realCountries = Normalize-StringArray $countries

    # --------------------------------------------------------
    # VILLES
    # --------------------------------------------------------

    $cities = Get-PropertyValue $item @(
        "cities",
        "city",
        "city_name"
    )

    $realCities = Normalize-StringArray $cities

    # --------------------------------------------------------
    # SOURCES
    # --------------------------------------------------------

    $sources = Get-PropertyValue $item @(
        "sources",
        "source"
    )

    $normalizedSources = Normalize-StringArray $sources

    # --------------------------------------------------------
    # URLS
    # --------------------------------------------------------

    $urls = Get-PropertyValue $item @(
        "urls",
        "url",
        "website",
        "websites"
    )

    $validUrls = New-Object System.Collections.Generic.List[string]

    foreach ($url in (Convert-ToArray $urls)) {

        if ($null -eq $url) {
            continue
        }

        $urlText = ([string]$url).Trim()

        if (Test-ValidUrl $urlText) {

            if (!$validUrls.Contains($urlText)) {
                $validUrls.Add($urlText)
            }
        }
    }

    # --------------------------------------------------------
    # OBSERVATIONS
    # --------------------------------------------------------

    $observationCount = Get-PropertyValue $item @(
        "observation_count",
        "observationCount",
        "observations"
    )

    if ($null -eq $observationCount) {
        $observationCount = 0
    }

    try {
        $observationCount = [int]$observationCount
    }
    catch {
        $observationCount = 0
    }

    # --------------------------------------------------------
    # IMPORTANT :
    # DETECTION DE FAUSSE COUVERTURE
    #
    # On regarde explicitement les champs qui peuvent contenir
    # la couverture géographique générique d'une plateforme.
    # --------------------------------------------------------

    $coverageCities = Get-PropertyValue $item @(
        "coverage_cities",
        "coverageCities",
        "platform_cities",
        "available_cities",
        "coverage"
    )

    $coverageCities = Normalize-StringArray $coverageCities

    # Les villes réellement prouvées restent dans "cities".
    # La couverture générique ne doit PAS être considérée comme
    # preuve géographique.

    $coverageCitiesRemoved = 0

    if ($coverageCities.Count -gt 0) {

        $realCityList = New-Object System.Collections.Generic.List[string]

        foreach ($city in $realCities) {

            if (!$coverageCities.Contains($city)) {
                $realCityList.Add($city)
            }
            else {
                $coverageCitiesRemoved++
            }
        }

        $realCities = @($realCityList)
    }

    # --------------------------------------------------------
    # DETECTION DE LA LISTE GENERIQUE 59 VILLES
    # --------------------------------------------------------

    $genericCityCount = 59

    if (
        $realCities.Count -eq 59 -and
        $coverageCities.Count -eq 0
    ) {
        # Cas observé dans RADAR 66 :
        # même liste générique de 59 villes provenant
        # de la couverture des plateformes.

        $coverageCitiesRemoved = 59
        $realCities = @()
    }

    # --------------------------------------------------------
    # PREUVES
    # --------------------------------------------------------

    $proofScore = Get-PropertyValue $item @(
        "max_proof_score",
        "proof_score",
        "proofScore",
        "proof"
    )

    if ($null -eq $proofScore) {
        $proofScore = 0
    }

    try {
        $proofScore = [double]$proofScore
    }
    catch {
        $proofScore = 0
    }

    $evidenceComponent = Get-PropertyValue $item @(
        "max_evidence_component",
        "evidence_component",
        "evidenceComponent"
    )

    if ($null -eq $evidenceComponent) {
        $evidenceComponent = 0
    }

    try {
        $evidenceComponent = [double]$evidenceComponent
    }
    catch {
        $evidenceComponent = 0
    }

    # --------------------------------------------------------
    # SCORE ORIGINAL
    # --------------------------------------------------------

    $originalScore = Get-PropertyValue $item @(
        "consolidated_score",
        "final_score",
        "score",
        "business_score"
    )

    if ($null -eq $originalScore) {
        $originalScore = 0
    }

    try {
        $originalScore = [double]$originalScore
    }
    catch {
        $originalScore = 0
    }

    # --------------------------------------------------------
    # SCORE AJUSTE
    # --------------------------------------------------------

    $adjustedScore = $originalScore

    # Fausse couverture géographique
    if (
        $coverageCitiesRemoved -gt 0 -and
        $proofScore -eq 0
    ) {
        $adjustedScore = [Math]::Min(
            $adjustedScore,
            39
        )
    }

    # Aucune preuve + aucune URL
    if (
        $proofScore -eq 0 -and
        $validUrls.Count -eq 0
    ) {
        $adjustedScore = [Math]::Min(
            $adjustedScore,
            35
        )
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
        $realCities.Count -gt 0 -or
        $validUrls.Count -gt 0
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
        (
            $realCountries.Count -gt 0 -or
            $realCities.Count -gt 0
        ) -and
        $validUrls.Count -gt 0
    ) {
        $status = "VALIDATED"
    }
    elseif (
        $proofScore -ge 40 -or
        (
            (
                $realCountries.Count -gt 0 -or
                $realCities.Count -gt 0
            ) -and
            $validUrls.Count -gt 0
        )
    ) {
        $status = "PROMISING"
    }

    # --------------------------------------------------------
    # NOTES
    # --------------------------------------------------------

    $notes = New-Object System.Collections.Generic.List[string]

    if ($coverageCitiesRemoved -gt 0) {
        $notes.Add(
            "Des villes provenant de la couverture générique d'une plateforme ont été supprimées."
        )
    }

    if ($proofScore -eq 0) {
        $notes.Add(
            "Aucune preuve de traction quantitative détectée."
        )
    }

    if ($validUrls.Count -eq 0) {
        $notes.Add(
            "Aucune URL exploitable détectée."
        )
    }

    if (
        $realCountries.Count -eq 0 -and
        $realCities.Count -eq 0
    ) {
        $notes.Add(
            "Aucune géographie réellement prouvée."
        )
    }

    # --------------------------------------------------------
    # OBJET FINAL
    # --------------------------------------------------------

    $newItem = [ordered]@{

        idea_name = $name

        normalized_name = $name.ToLower().Trim()

        consolidated_score =
            [Math]::Round($adjustedScore, 1)

        original_score =
            [Math]::Round($originalScore, 1)

        status =
            $status

        confidence =
            $confidence

        evidence_level =
            $evidenceLevel

        proof_score =
            [Math]::Round($proofScore, 1)

        evidence_component =
            [Math]::Round($evidenceComponent, 1)

        country_count =
            $realCountries.Count

        city_count =
            $realCities.Count

        source_count =
            $normalizedSources.Count

        observation_count =
            $observationCount

        url_count =
            $validUrls.Count

        live_url_count =
            $validUrls.Count

        countries =
            @($realCountries)

        cities =
            @($realCities)

        sources =
            @($normalizedSources)

        urls =
            @($validUrls)

        coverage_cities_removed =
            $coverageCitiesRemoved

        geography_proven =
            (
                $realCountries.Count -gt 0 -or
                $realCities.Count -gt 0
            )

        source_coverage_detected =
            ($coverageCitiesRemoved -gt 0)

        scoring_version =
            "RADAR_67"

        normalization_notes =
            @($notes)
    }

    $output.Add(
        [PSCustomObject]$newItem
    )
}

Write-Progress `
    -Activity "RADAR 67 - Normalisation" `
    -Completed

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
    Where-Object {
        $_.status -eq "VALIDATED"
    }
).Count

$promising = @(
    $output |
    Where-Object {
        $_.status -eq "PROMISING"
    }
).Count

$watchlist = @(
    $output |
    Where-Object {
        $_.status -eq "WATCHLIST"
    }
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
Write-Host "RADAR 67 - TERMINE" -ForegroundColor Green
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

