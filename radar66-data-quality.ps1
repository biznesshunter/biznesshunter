# =====================================================================
# BIZNESSHUNTER — RADAR 66
# DATA QUALITY AUDIT — VERSION CORRIGEE
# =====================================================================
#
# Entree :
#   .\radar56_multicity_raw.json
#
# Sorties :
#   .\radar66_data_quality.json
#   .\radar66_validated_multicity.json
#
# Objectif :
#   Nettoyer et valider les observations produites par Radar 56
#   avant tout calcul de score de marché ou de réplication.
#
# =====================================================================

$ErrorActionPreference = "Stop"

# =====================================================================
# FICHIERS
# =====================================================================

$inputFile = ".\radar56_multicity_raw.json"

$outputAudit = ".\radar66_data_quality.json"

$outputValid = ".\radar66_validated_multicity.json"

# =====================================================================
# VERIFICATION FICHIER
# =====================================================================

if (-not (Test-Path $inputFile)) {

    Write-Host ""
    Write-Host "ERREUR : fichier source introuvable :" `
        $inputFile `
        -ForegroundColor Red

    exit 1
}

# =====================================================================
# FONCTION — NORMALISATION DU TEXTE
# =====================================================================

function Normalize-Text {

    param(
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value) {
        return ""
    }

    $text = [string]$Value

    if ([string]::IsNullOrWhiteSpace($text)) {
        return ""
    }

    $text = $text.ToLowerInvariant()

    # Remplacement des caractères accentués
    $text = $text.Normalize(
        [System.Text.NormalizationForm]::FormD
    )

    $chars = New-Object System.Text.StringBuilder

    foreach ($char in $text.ToCharArray()) {

        $category = [Globalization.CharUnicodeInfo]::GetUnicodeCategory($char)

        if (
            $category -ne
            [Globalization.UnicodeCategory]::NonSpacingMark
        ) {

            [void]$chars.Append($char)
        }
    }

    $text = $chars.ToString()

    $text = $text -replace "[^a-z0-9]+", " "

    $text = $text -replace "\s+", " "

    return $text.Trim()
}

# =====================================================================
# FONCTION — VALEUR UNIQUE
# =====================================================================

function Get-SingleValue {

    param(
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value) {
        return $null
    }

    if ($Value -is [System.Array]) {

        if ($Value.Count -eq 0) {
            return $null
        }

        return $Value[0]
    }

    return $Value
}

# =====================================================================
# FONCTION — NOMBRE
# =====================================================================

function Get-Number {

    param(
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value) {
        return 0
    }

    try {

        if ($Value -is [System.Array]) {

            if ($Value.Count -eq 0) {
                return 0
            }

            $Value = $Value[0]
        }

        $number = [double]$Value

        if ([double]::IsNaN($number)) {
            return 0
        }

        if ([double]::IsInfinity($number)) {
            return 0
        }

        return $number
    }
    catch {

        return 0
    }
}

# =====================================================================
# FONCTION — EXTRACTION D'UN TABLEAU
# =====================================================================

function Convert-ToArray {

    param(
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value) {

        return @()
    }

    if ($Value -is [System.Array]) {

        return @($Value)
    }

    return @($Value)
}

# =====================================================================
# FONCTION — MEDIANE
# =====================================================================

function Get-Median {

    param(
        [object[]]$Values
    )

    $numbers = @(
        $Values |
        ForEach-Object {

            try {

                $number = [double]$_

                if (
                    -not [double]::IsNaN($number) -and
                    -not [double]::IsInfinity($number)
                ) {

                    $number
                }
            }
            catch {
            }
        }
    )

    if ($numbers.Count -eq 0) {
        return 0
    }

    $sorted = @(
        $numbers |
        Sort-Object
    )

    $count = $sorted.Count

    if (($count % 2) -eq 1) {

        return [double]$sorted[
            [math]::Floor($count / 2)
        ]
    }

    $middle1 = [double]$sorted[
        ($count / 2) - 1
    ]

    $middle2 = [double]$sorted[
        ($count / 2)
    ]

    return ($middle1 + $middle2) / 2
}

# =====================================================================
# LECTURE DU JSON
# =====================================================================

Write-Host ""
Write-Host "Lecture du fichier source..." `
    -ForegroundColor Cyan

try {

    $jsonText = Get-Content `
        -Path $inputFile `
        -Raw `
        -Encoding UTF8

    $rawData = $jsonText |
        ConvertFrom-Json
}
catch {

    Write-Host ""
    Write-Host "ERREUR : impossible de lire le JSON." `
        -ForegroundColor Red

    Write-Host $_.Exception.Message `
        -ForegroundColor Red

    exit 1
}

# =====================================================================
# NORMALISATION DES OBSERVATIONS
#
# IMPORTANT :
#
# Radar 56 peut produire :
#
# 1) un vrai tableau d'objets :
#
# [
#   {...},
#   {...}
# ]
#
# OU
#
# 2) un seul objet dont certaines propriétés sont des tableaux :
#
# {
#   city: ["Paris","Lyon",...],
#   source: ["allovoisins","bricolib",...],
#   ...
# }
#
# Cette section transforme les deux formats en observations individuelles.
# =====================================================================

$rows = @()

# =====================================================================
# CAS 1 — TABLEAU NORMAL
# =====================================================================

if ($rawData -is [System.Array]) {

    foreach ($item in @($rawData)) {

        if ($null -ne $item) {

            $rows += $item
        }
    }
}

# =====================================================================
# CAS 2 — OBJET CONTENANT DES TABLEAUX
# =====================================================================

else {

    $properties = @(
        $rawData.PSObject.Properties
    )

    $arrayProperties = @()

    foreach ($property in $properties) {

        $value = $property.Value

        if ($value -is [System.Array]) {

            if ($value.Count -gt 1) {

                $arrayProperties += $property
            }
        }
    }

    # ---------------------------------------------------------------
    # Si plusieurs propriétés sont des tableaux, nous reconstruisons
    # les lignes par position.
    # ---------------------------------------------------------------

    if ($arrayProperties.Count -gt 0) {

        $rowCount = 0

        foreach ($property in $arrayProperties) {

            $count = @(
                $property.Value
            ).Count

            if ($count -gt $rowCount) {

                $rowCount = $count
            }
        }

        for ($i = 0; $i -lt $rowCount; $i++) {

            $newRow = [ordered]@{}

            foreach ($property in $properties) {

                $value = $property.Value

                if ($value -is [System.Array]) {

                    $arrayValue = @($value)

                    if ($i -lt $arrayValue.Count) {

                        $newRow[
                            $property.Name
                        ] = $arrayValue[$i]
                    }
                    else {

                        $newRow[
                            $property.Name
                        ] = $null
                    }
                }
                else {

                    $newRow[
                        $property.Name
                    ] = $value
                }
            }

            $rows += [PSCustomObject]$newRow
        }
    }

    # ---------------------------------------------------------------
    # Sinon l'objet lui-même constitue une observation.
    # ---------------------------------------------------------------

    else {

        $rows += $rawData
    }
}

# =====================================================================
# CONTROLE INITIAL
# =====================================================================

Write-Host ""
Write-Host "OBSERVATIONS RECONSTRUITES :" `
    @($rows).Count `
    -ForegroundColor Cyan

if (@($rows).Count -eq 0) {

    Write-Host ""
    Write-Host "ERREUR : aucune observation exploitable." `
        -ForegroundColor Red

    exit 1
}

# =====================================================================
# VILLES ATTENDUES
# =====================================================================

$knownCities = @(
    "Paris",
    "Lyon",
    "Marseille",
    "Toulouse",
    "Bordeaux",
    "Nantes",
    "Lille",
    "Montpellier",
    "Strasbourg",
    "Nice",
    "Rennes",
    "Grenoble",
    "Rouen",
    "Reims",
    "Toulon",
    "Dijon",
    "Angers",
    "Nîmes",
    "Clermont-Ferrand",
    "Le Havre"
)

$knownCitiesNormalized = @()

foreach ($city in $knownCities) {

    $knownCitiesNormalized += @{
        Original = $city
        Normalized = Normalize-Text $city
    }
}

# =====================================================================
# RESULTATS
# =====================================================================

$results = @()

# =====================================================================
# TRAITEMENT DE CHAQUE OBSERVATION
# =====================================================================

$observationIndex = 0

foreach ($row in @($rows)) {

    $observationIndex++

    # ================================================================
    # VARIABLES
    # ================================================================

    $checks = @()

    $warnings = @()

    $problems = @()

    $hardFailure = $false

    $softFailure = $false

    # ================================================================
    # EXTRACTION
    # ================================================================

    $ideaName = [string](
        Get-SingleValue $row.idea_name
    )

    $country = [string](
        Get-SingleValue $row.country
    )

    $requestedCity = [string](
        Get-SingleValue $row.city
    )

    $category = [string](
        Get-SingleValue $row.category
    )

    $source = [string](
        Get-SingleValue $row.source
    )

    $requestedUrl = [string](
        Get-SingleValue $row.requested_url
    )

    $finalUrl = [string](
        Get-SingleValue $row.final_url
    )

    $pageTitle = [string](
        Get-SingleValue $row.page_title
    )

    $scrapedAt = [string](
        Get-SingleValue $row.scraped_at
    )

    # ================================================================
    # NORMALISATION
    # ================================================================

    $cityNormalized = Normalize-Text $requestedCity

    $titleNormalized = Normalize-Text $pageTitle

    $requestedUrlNormalized = Normalize-Text $requestedUrl

    $finalUrlNormalized = Normalize-Text $finalUrl

    # ================================================================
    # DEMANDE
    # ================================================================

    $demand = Get-Number $row.demand_count

    # ================================================================
    # OFFRE
    # ================================================================

    $supply = Get-Number $row.supply_count

    # ================================================================
    # PRIX
    # ================================================================

    $prices = Convert-ToArray $row.prices

    $validPrices = @()

    foreach ($price in $prices) {

        try {

            $priceNumber = [double]$price

            if (
                $priceNumber -gt 0 -and
                $priceNumber -lt 100000
            ) {

                $validPrices += $priceNumber
            }
        }
        catch {
        }
    }

    $priceCount = @(
        $validPrices
    ).Count

    $medianPrice = Get-Median $validPrices

    # ================================================================
    # CHECK 1 — VILLE
    # ================================================================

    if (
        [string]::IsNullOrWhiteSpace(
            $requestedCity
        )
    ) {

        $problems += "ville_absente"

        $hardFailure = $true
    }
    else {

        $checks += "ville_present"
    }

    # ================================================================
    # CHECK 2 — SOURCE
    # ================================================================

    if (
        [string]::IsNullOrWhiteSpace(
            $source
        )
    ) {

        $problems += "source_absente"

        $hardFailure = $true
    }
    else {

        $checks += "source_present"
    }

    # ================================================================
    # CHECK 3 — IDEE
    # ================================================================

    if (
        [string]::IsNullOrWhiteSpace(
            $ideaName
        )
    ) {

        $problems += "idee_absente"

        $hardFailure = $true
    }
    else {

        $checks += "idee_presente"
    }

    # ================================================================
    # CHECK 4 — URL DEMANDEE
    # ================================================================

    if (
        [string]::IsNullOrWhiteSpace(
            $requestedUrl
        )
    ) {

        $warnings += "url_demandee_absente"

        $softFailure = $true
    }
    else {

        $checks += "requested_url_present"
    }

    # ================================================================
    # CHECK 5 — URL FINALE
    # ================================================================

    if (
        [string]::IsNullOrWhiteSpace(
            $finalUrl
        )
    ) {

        $warnings += "url_finale_absente"

        $softFailure = $true
    }
    else {

        $checks += "final_url_present"
    }

    # ================================================================
    # CHECK 6 — HTTP
    # ================================================================

    $httpStatus = $null

    if ($null -ne $row.http_status) {

        try {

            $httpStatus = [int](
                Get-SingleValue $row.http_status
            )

            if ($httpStatus -eq 200) {

                $checks += "http_200"
            }
            elseif (
                $httpStatus -ge 200 -and
                $httpStatus -lt 400
            ) {

                $warnings += (
                    "http_status_$httpStatus"
                )

                $softFailure = $true
            }
            else {

                $problems += (
                    "http_status_$httpStatus"
                )

                $hardFailure = $true
            }
        }
        catch {

            $warnings += "http_status_invalide"

            $softFailure = $true
        }
    }
    else {

        $warnings += "http_status_absent"

        $softFailure = $true
    }

    # ================================================================
    # CHECK 7 — VILLE DANS URL DEMANDEE
    #
    # IMPORTANT :
    # Ce contrôle reste un avertissement.
    #
    # Une URL peut être géographique sans contenir exactement le nom
    # de la ville.
    # ================================================================

    if (
        -not [string]::IsNullOrWhiteSpace(
            $cityNormalized
        ) -and
        -not [string]::IsNullOrWhiteSpace(
            $requestedUrl
        )
    ) {

        $cityUrlToken = (
            $cityNormalized `
                -replace "\s+", "-"
        )

        $cityUrlToken = (
            $cityUrlToken `
                -replace "[^a-z0-9\-]", ""
        )

        $cityUrlToken2 = (
            $cityNormalized `
                -replace "\s+", ""
        )

        $cityUrlToken2 = (
            $cityUrlToken2 `
                -replace "[^a-z0-9]", ""
        )

        $urlCheck = (
            $requestedUrl.ToLowerInvariant() `
                -replace "%20", "-" `
                -replace "_", "-"
        )

        $urlContainsCity = (
            $urlCheck.Contains(
                $cityUrlToken
            ) -or
            $urlCheck.Contains(
                $cityUrlToken2
            )
        )

        if ($urlContainsCity) {

            $checks += "requested_url_matches_city"
        }
        else {

            $warnings += (
                "ville_non_detectee_dans_url_demande"
            )

            $softFailure = $true
        }
    }

    # ================================================================
    # CHECK 8 — VILLE DANS URL FINALE
    # ================================================================

    if (
        -not [string]::IsNullOrWhiteSpace(
            $cityNormalized
        ) -and
        -not [string]::IsNullOrWhiteSpace(
            $finalUrl
        )
    ) {

        $cityUrlToken = (
            $cityNormalized `
                -replace "\s+", "-"
        )

        $cityUrlToken = (
            $cityUrlToken `
                -replace "[^a-z0-9\-]", ""
        )

        $cityUrlToken2 = (
            $cityNormalized `
                -replace "\s+", ""
        )

        $cityUrlToken2 = (
            $cityUrlToken2 `
                -replace "[^a-z0-9]", ""
        )

        $finalUrlCheck = (
            $finalUrl.ToLowerInvariant() `
                -replace "%20", "-" `
                -replace "_", "-"
        )

        $finalContainsCity = (
            $finalUrlCheck.Contains(
                $cityUrlToken
            ) -or
            $finalUrlCheck.Contains(
                $cityUrlToken2
            )
        )

        if ($finalContainsCity) {

            $checks += "final_url_matches_city"
        }
        else {

            $warnings += (
                "ville_non_detectee_dans_url_finale"
            )

            $softFailure = $true
        }
    }

    # ================================================================
    # CHECK 9 — TITRE DE PAGE
    #
    # C'est le contrôle géographique le plus important.
    # ================================================================

    $titleMatchesRequestedCity = $false

    if (
        -not [string]::IsNullOrWhiteSpace(
            $cityNormalized
        ) -and
        -not [string]::IsNullOrWhiteSpace(
            $titleNormalized
        )
    ) {

        $titleCityNormalized = (
            $titleNormalized `
                -replace "[-_]", " " `
                -replace "\s+", " "
        )

        if (
            $titleCityNormalized.Contains(
                $cityNormalized
            )
        ) {

            $titleMatchesRequestedCity = $true

            $checks += "title_matches_city"
        }
    }

    # ================================================================
    # CHECK 10 — VILLES CONNUES DANS LE TITRE
    # ================================================================

    $citiesDetectedInTitle = @()

    foreach ($knownCityInfo in $knownCitiesNormalized) {

        if (
            $titleNormalized.Contains(
                $knownCityInfo.Normalized
            )
        ) {

            $citiesDetectedInTitle += (
                $knownCityInfo.Original
            )
        }
    }

    $citiesDetectedInTitle = @(
        $citiesDetectedInTitle |
        Sort-Object -Unique
    )

    # ================================================================
    # AUTRES VILLES
    # ================================================================

    $otherCities = @()

    foreach ($detectedCity in $citiesDetectedInTitle) {

        $detectedNormalized = Normalize-Text $detectedCity

        if (
            $detectedNormalized -ne
            $cityNormalized
        ) {

            $otherCities += $detectedCity
        }
    }

    $otherCities = @(
        $otherCities |
        Sort-Object -Unique
    )

    # ================================================================
    # INCOMPATIBILITE DE TITRE
    # ================================================================

    if (
        $otherCities.Count -gt 0 -and
        -not $titleMatchesRequestedCity
    ) {

        $problems += (
            "autre_ville_detectee_dans_titre:" +
            ($otherCities -join ",")
        )

        $hardFailure = $true
    }

    elseif (
        $otherCities.Count -gt 0 -and
        $titleMatchesRequestedCity
    ) {

        # Exemple :
        # "Paris et Lyon"
        #
        # Ce n'est pas forcément une erreur.
        # On signale simplement la présence de plusieurs villes.

        $warnings += (
            "plusieurs_villes_dans_titre:" +
            ($citiesDetectedInTitle -join ",")
        )

        $softFailure = $true
    }

    elseif (
        -not $titleMatchesRequestedCity
    ) {

        $warnings += (
            "ville_non_detectee_dans_titre"
        )

        $softFailure = $true
    }

    # ================================================================
    # CHECK 11 — DEMANDE
    # ================================================================

    if ($demand -lt 0) {

        $problems += "demande_negative"

        $hardFailure = $true
    }

    elseif ($demand -eq 0) {

        $warnings += "demande_non_observee"

        $softFailure = $true
    }

    else {

        $checks += "demand_valid"
    }

    # ================================================================
    # CHECK 12 — OFFRE
    # ================================================================

    if ($supply -lt 0) {

        $problems += "offre_negative"

        $hardFailure = $true
    }

    elseif ($supply -eq 0) {

        $warnings += "offre_non_observee"

        $softFailure = $true
    }

    else {

        $checks += "supply_valid"
    }

    # ================================================================
    # CHECK 13 — PRIX
    # ================================================================

    if ($priceCount -eq 0) {

        $warnings += "aucun_prix_observe"

        $softFailure = $true
    }
    else {

        $checks += "prices_valid"
    }

    # ================================================================
    # CHECK 14 — BODY LENGTH
    # ================================================================

    $bodyLength = 0

    if ($null -ne $row.body_length) {

        try {

            $bodyLength = [int](
                Get-SingleValue $row.body_length
            )

            if ($bodyLength -lt 500) {

                $warnings += (
                    "contenu_page_tres_court"
                )

                $softFailure = $true
            }
            else {

                $checks += "body_length_ok"
            }
        }
        catch {

            $warnings += (
                "body_length_invalide"
            )

            $softFailure = $true
        }
    }
    else {

        $warnings += "body_length_absent"

        $softFailure = $true
    }

    # ================================================================
    # CHECK 15 — URL FINALE IDENTIQUE OU DIFFERENTE
    # ================================================================

    if (
        -not [string]::IsNullOrWhiteSpace(
            $requestedUrl
        ) -and
        -not [string]::IsNullOrWhiteSpace(
            $finalUrl
        )
    ) {

        if (
            $requestedUrl.Trim() -eq
            $finalUrl.Trim()
        ) {

            $checks += "no_redirect"
        }
        else {

            $checks += "redirect_detected"
        }
    }

    # ================================================================
    # SCORE QUALITE
    #
    # Base : 100
    #
    # Erreur critique : -50
    # Avertissement : -5
    # Contrôle positif : +1
    #
    # Le score reste borné entre 0 et 100.
    # ================================================================

    $qualityScore = 100

    if ($hardFailure) {

        $qualityScore -= 50
    }

    $warningPenalty = (
        [math]::Min(
            30,
            $warnings.Count * 5
        )
    )

    $qualityScore -= $warningPenalty

    $positiveBonus = (
        [math]::Min(
            10,
            $checks.Count
        )
    )

    $qualityScore += $positiveBonus

    $qualityScore = [math]::Max(
        0,
        [math]::Min(
            100,
            $qualityScore
        )
    )

    $qualityScore = [math]::Round(
        $qualityScore,
        1
    )

    # ================================================================
    # STATUT
    # ================================================================

    if ($hardFailure) {

        $status = "INVALID"
    }

    elseif ($softFailure) {

        $status = "SUSPECT"
    }

    else {

        $status = "VALID"
    }

    # ================================================================
    # RATIO
    # ================================================================

    $ratio = $null

    if ($supply -gt 0) {

        $ratio = [math]::Round(
            ($demand / $supply),
            2
        )
    }

    # ================================================================
    # RESULTAT
    # ================================================================

    $results += [PSCustomObject]@{

        observation_id = $observationIndex

        idea_name = $ideaName

        country = $country

        city = $requestedCity

        category = $category

        source = $source

        requested_url = $requestedUrl

        final_url = $finalUrl

        page_title = $pageTitle

        http_status = $httpStatus

        demand = $demand

        supply = $supply

        demand_supply_ratio = $ratio

        median_price = [math]::Round(
            $medianPrice,
            2
        )

        price_samples = $priceCount

        body_length = $bodyLength

        quality_score = $qualityScore

        status = $status

        checks = @(
            $checks
        )

        warnings = @(
            $warnings
        )

        problems = @(
            $problems
        )

        cities_detected_in_title = @(
            $citiesDetectedInTitle
        )

        other_cities_in_title = @(
            $otherCities
        )

        title_matches_requested_city =
            $titleMatchesRequestedCity

        scraped_at = $scrapedAt
    }
}

# =====================================================================
# CLASSEMENT
# =====================================================================

$results = @(
    $results |
    Sort-Object `
        quality_score `
        -Descending
)

# =====================================================================
# SAUVEGARDE AUDIT
# =====================================================================

$results |
    ConvertTo-Json `
        -Depth 20 |
    Set-Content `
        -Path $outputAudit `
        -Encoding UTF8

# =====================================================================
# DONNEES VALIDES
# =====================================================================

$validResults = @(
    $results |
    Where-Object {
        $_.status -eq "VALID"
    }
)

$validResults |
    ConvertTo-Json `
        -Depth 20 |
    Set-Content `
        -Path $outputValid `
        -Encoding UTF8

# =====================================================================
# STATISTIQUES
# =====================================================================

$total = @(
    $results
).Count

$valid = @(
    $results |
    Where-Object {
        $_.status -eq "VALID"
    }
).Count

$suspect = @(
    $results |
    Where-Object {
        $_.status -eq "SUSPECT"
    }
).Count

$invalid = @(
    $results |
    Where-Object {
        $_.status -eq "INVALID"
    }
).Count

# =====================================================================
# VILLES UNIQUES
# =====================================================================

$uniqueCities = @(
    $results |
    ForEach-Object {
        $_.city
    } |
    Where-Object {
        -not [string]::IsNullOrWhiteSpace($_)
    } |
    Sort-Object -Unique
)

# =====================================================================
# SOURCES UNIQUES
# =====================================================================

$uniqueSources = @(
    $results |
    ForEach-Object {
        $_.source
    } |
    Where-Object {
        -not [string]::IsNullOrWhiteSpace($_)
    } |
    Sort-Object -Unique
)

# =====================================================================
# GROUPES VILLE / SOURCE
# =====================================================================

$citySourceGroups = @(
    $results |
    Group-Object {
        "{0} | {1}" -f `
            $_.city, `
            $_.source
    }
)

# =====================================================================
# AFFICHAGE PRINCIPAL
# =====================================================================

Write-Host ""
Write-Host "============================================================" `
    -ForegroundColor Cyan

Write-Host "BIZNESSHUNTER RADAR 66 — DATA QUALITY AUDIT" `
    -ForegroundColor Cyan

Write-Host "============================================================" `
    -ForegroundColor Cyan

Write-Host ""

Write-Host "SOURCE :" `
    $inputFile

Write-Host ""

Write-Host "OBSERVATIONS RECONSTRUITES :" `
    $total `
    -ForegroundColor Cyan

Write-Host ""

Write-Host "VALID   :" `
    $valid `
    -ForegroundColor Green

Write-Host "SUSPECT :" `
    $suspect `
    -ForegroundColor Yellow

Write-Host "INVALID :" `
    $invalid `
    -ForegroundColor Red

Write-Host ""

Write-Host "VILLES UNIQUES :" `
    $uniqueCities.Count `
    -ForegroundColor Cyan

Write-Host (
    ($uniqueCities -join ", ")
)

Write-Host ""

Write-Host "SOURCES UNIQUES :" `
    $uniqueSources.Count `
    -ForegroundColor Cyan

Write-Host (
    ($uniqueSources -join ", ")
)

Write-Host ""

Write-Host "GROUPES VILLE / SOURCE :" `
    $citySourceGroups.Count `
    -ForegroundColor Cyan

Write-Host ""

Write-Host "DONNEES UTILISABLES POUR RADAR 67 :" `
    $valid `
    -ForegroundColor Green

Write-Host ""

Write-Host "OUTPUT AUDIT  :" `
    $outputAudit

Write-Host "OUTPUT VALIDE :" `
    $outputValid

# =====================================================================
# TABLEAU PRINCIPAL
# =====================================================================

Write-Host ""
Write-Host "============================================================"
Write-Host "RESULTATS"
Write-Host "============================================================"
Write-Host ""

$results |
    Select-Object `
        observation_id,
        city,
        source,
        demand,
        supply,
        demand_supply_ratio,
        median_price,
        quality_score,
        status |
    Format-Table -AutoSize

# =====================================================================
# CONTROLE PAR VILLE
# =====================================================================

Write-Host ""
Write-Host "============================================================"
Write-Host "CONTROLE PAR VILLE"
Write-Host "============================================================"
Write-Host ""

foreach ($city in $uniqueCities) {

    $cityRows = @(
        $results |
        Where-Object {
            $_.city -eq $city
        }
    )

    $cityValid = @(
        $cityRows |
        Where-Object {
            $_.status -eq "VALID"
        }
    ).Count

    $citySuspect = @(
        $cityRows |
        Where-Object {
            $_.status -eq "SUSPECT"
        }
    ).Count

    $cityInvalid = @(
        $cityRows |
        Where-Object {
            $_.status -eq "INVALID"
        }
    ).Count

    Write-Host (
        "{0,-20} | Total {1,2} | Valid {2,2} | Suspect {3,2} | Invalid {4,2}" -f `
        $city,
        $cityRows.Count,
        $cityValid,
        $citySuspect,
        $cityInvalid
    )
}

# =====================================================================
# ANOMALIES
# =====================================================================

Write-Host ""
Write-Host "============================================================"
Write-Host "ANOMALIES DETECTEES"
Write-Host "============================================================"
Write-Host ""

foreach ($item in $results) {

    if ($item.status -ne "VALID") {

        Write-Host ""

        Write-Host (
            "{0} [{1}] — observation #{2}" -f `
            $item.city,
            $item.source,
            $item.observation_id
        ) `
            -ForegroundColor Yellow

        Write-Host "QUALITE :" `
            $item.quality_score

        Write-Host "STATUT :" `
            $item.status

        Write-Host "TITRE :" `
            $item.page_title

        if (
            @(
                $item.problems
            ).Count -gt 0
        ) {

            Write-Host "PROBLEMES :"

            foreach ($problem in @(
                $item.problems
            )) {

                Write-Host `
                    "  - $problem" `
                    -ForegroundColor Red
            }
        }

        if (
            @(
                $item.warnings
            ).Count -gt 0
        ) {

            Write-Host "AVERTISSEMENTS :"

            foreach ($warning in @(
                $item.warnings
            )) {

                Write-Host `
                    "  - $warning" `
                    -ForegroundColor Yellow
            }
        }
    }
}

# =====================================================================
# CONTROLE DES TITRES PAR VILLE
# =====================================================================

Write-Host ""
Write-Host "============================================================"
Write-Host "CONTROLE GEOGRAPHIQUE DES TITRES"
Write-Host "============================================================"
Write-Host ""

foreach ($item in $results) {

    Write-Host (
        "{0,-20} | {1,-15} | Titre ville = {2}" -f `
        $item.city,
        $item.source,
        $item.title_matches_requested_city
    )
}

# =====================================================================
# CONTROLE SPECIAL — DOUBLONS EXACTS
# =====================================================================

Write-Host ""
Write-Host "============================================================"
Write-Host "CONTROLE DES DOUBLONS"
Write-Host "============================================================"
Write-Host ""

$duplicateGroups = @(
    $results |
    Group-Object {
        "{0}|{1}|{2}" -f `
        $_.city,
        $_.source,
        $_.requested_url
    } |
    Where-Object {
        $_.Count -gt 1
    }
)

if ($duplicateGroups.Count -eq 0) {

    Write-Host `
        "Aucun doublon exact detecte." `
        -ForegroundColor Green
}
else {

    Write-Host `
        "DOUBLONS DETECTES :" `
        -ForegroundColor Red

    foreach ($group in $duplicateGroups) {

        Write-Host ""

        Write-Host (
            "  {0} occurrences : {1}" -f `
            $group.Count,
            $group.Name
        ) `
            -ForegroundColor Red
    }
}

# =====================================================================
# CONTROLE SPECIAL — OBSERVATIONS PAR SOURCE
# =====================================================================

Write-Host ""
Write-Host "============================================================"
Write-Host "OBSERVATIONS PAR SOURCE"
Write-Host "============================================================"
Write-Host ""

$sourceGroups = @(
    $results |
    Group-Object source |
    Sort-Object Name
)

foreach ($group in $sourceGroups) {

    $sourceValid = @(
        $group.Group |
        Where-Object {
            $_.status -eq "VALID"
        }
    ).Count

    $sourceSuspect = @(
        $group.Group |
        Where-Object {
            $_.status -eq "SUSPECT"
        }
    ).Count

    $sourceInvalid = @(
        $group.Group |
        Where-Object {
            $_.status -eq "INVALID"
        }
    ).Count

    Write-Host (
        "{0,-20} | Total {1,2} | Valid {2,2} | Suspect {3,2} | Invalid {4,2}" -f `
        $group.Name,
        $group.Count,
        $sourceValid,
        $sourceSuspect,
        $sourceInvalid
    )
}

# =====================================================================
# CONTROLE FINAL
# =====================================================================

Write-Host ""
Write-Host "============================================================"
Write-Host "CONTROLE FINAL"
Write-Host "============================================================"
Write-Host ""

if ($total -eq 26) {

    Write-Host `
        "OK : 26 observations reconstruites." `
        -ForegroundColor Green
}
else {

    Write-Host (
        "ATTENTION : {0} observations reconstruites au lieu des 26 attendues." -f `
        $total
    ) `
        -ForegroundColor Yellow
}

if ($uniqueCities.Count -ge 13) {

    Write-Host `
        "OK : les observations multivilles sont correctement separees." `
        -ForegroundColor Green
}
else {

    Write-Host `
        "ATTENTION : nombre de villes inferieur aux 13 attendues." `
        -ForegroundColor Yellow
}

if ($valid -gt 0) {

    Write-Host (
        "OK : {0} observations sont utilisables pour Radar 67." -f `
        $valid
    ) `
        -ForegroundColor Green
}
else {

    Write-Host `
        "ATTENTION : aucune observation VALID pour Radar 67." `
        -ForegroundColor Red
}

# =====================================================================
# FIN
# =====================================================================

Write-Host ""
Write-Host "============================================================" `
    -ForegroundColor Cyan

Write-Host "RADAR 66 TERMINE" `
    -ForegroundColor Cyan

Write-Host "============================================================" `
    -ForegroundColor Cyan

Write-Host ""

