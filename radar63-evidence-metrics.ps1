# =========================================
# RADAR 63 - EVIDENCE METRICS
# =========================================

$ErrorActionPreference = "Stop"

$inputFile = ".\radar60_proof_score.json"

if (-not (Test-Path $inputFile)) {
    Write-Host "ERREUR : $inputFile introuvable." -ForegroundColor Red
    exit 1
}

# =========================================
# LOAD JSON CORRECTLY
# =========================================

$raw = Get-Content $inputFile -Raw | ConvertFrom-Json

# Le fichier peut être :
# 1. un tableau direct
# 2. un objet contenant les opportunités

if ($raw -is [System.Array]) {
    $data = @($raw)
}
elseif ($raw.opportunities) {
    $data = @($raw.opportunities)
}
elseif ($raw.results) {
    $data = @($raw.results)
}
elseif ($raw.data) {
    $data = @($raw.data)
}
else {
    # Détection automatique d'un objet contenant
    # plusieurs propriétés de type opportunité
    $candidateProperties = @(
        "items",
        "records",
        "results",
        "opportunities",
        "ideas"
    )

    $found = $false

    foreach ($property in $candidateProperties) {
        if ($null -ne $raw.$property) {
            $data = @($raw.$property)
            $found = $true
            break
        }
    }

    if (-not $found) {
        # Si l'objet possède directement idea_name,
        # c'est une seule opportunité.
        if ($raw.idea_name) {
            $data = @($raw)
        }
        else {
            Write-Host ""
            Write-Host "ERREUR : structure JSON inconnue." -ForegroundColor Red
            Write-Host "Propriétés trouvées :" -ForegroundColor Yellow
            $raw.PSObject.Properties.Name
            exit 1
        }
    }
}

Write-Host ""
Write-Host "DONNEES CHARGEES : $($data.Count)"

# =========================================
# HELPERS
# =========================================

function Get-Int {
    param($Value)

    if ($null -eq $Value -or $Value -eq "") {
        return 0
    }

    try {
        return [int]$Value
    }
    catch {
        return 0
    }
}

function Clamp {
    param(
        [double]$Value,
        [double]$Min,
        [double]$Max
    )

    if ($Value -lt $Min) { return $Min }
    if ($Value -gt $Max) { return $Max }

    return $Value
}

# =========================================
# PROCESS
# =========================================

$result = foreach ($item in $data) {

    $ideaName = [string]$item.idea_name
    $category = [string]$item.category

    if (-not $ideaName) {
        continue
    }

    $observations = Get-Int $item.observation_count
    $sources = Get-Int $item.source_count
    $countries = Get-Int $item.country_count
    $cities = Get-Int $item.city_count
    $urls = Get-Int $item.url_count
    $liveUrls = Get-Int $item.live_url_count
    $proof = Get-Int $item.proof_score

    # =========================================
    # EVIDENCE /25
    # =========================================

    $evidence = 0

    if ($proof -ge 100) {
        $evidence += 10
    }
    elseif ($proof -ge 75) {
        $evidence += 8
    }
    elseif ($proof -ge 65) {
        $evidence += 6
    }
    elseif ($proof -ge 50) {
        $evidence += 4
    }
    elseif ($proof -gt 0) {
        $evidence += 2
    }

    if ($sources -ge 3) {
        $evidence += 5
    }
    elseif ($sources -ge 2) {
        $evidence += 3
    }
    elseif ($sources -eq 1) {
        $evidence += 1
    }

    if ($cities -ge 20) {
        $evidence += 5
    }
    elseif ($cities -ge 10) {
        $evidence += 3
    }
    elseif ($cities -ge 5) {
        $evidence += 2
    }
    elseif ($cities -gt 0) {
        $evidence += 1
    }

    if ($liveUrls -ge 2) {
        $evidence += 5
    }
    elseif ($liveUrls -eq 1) {
        $evidence += 3
    }

    $evidence = [int](Clamp $evidence 0 25)

    # =========================================
    # DEMAND /20
    # =========================================

    $demand = 0

    if ($observations -ge 100) {
        $demand += 8
    }
    elseif ($observations -ge 75) {
        $demand += 7
    }
    elseif ($observations -ge 50) {
        $demand += 6
    }
    elseif ($observations -ge 40) {
        $demand += 5
    }
    elseif ($observations -ge 25) {
        $demand += 3
    }
    elseif ($observations -gt 0) {
        $demand += 1
    }

    if ($cities -ge 20) {
        $demand += 5
    }
    elseif ($cities -ge 10) {
        $demand += 3
    }
    elseif ($cities -ge 5) {
        $demand += 2
    }

    if ($sources -ge 3) {
        $demand += 4
    }
    elseif ($sources -ge 2) {
        $demand += 3
    }
    elseif ($sources -eq 1) {
        $demand += 1
    }

    if ($liveUrls -ge 2) {
        $demand += 3
    }
    elseif ($liveUrls -eq 1) {
        $demand += 2
    }

    $demand = [int](Clamp $demand 0 20)

    # =========================================
    # REPLICATION /20
    # =========================================

    $replication = 0

    if ($countries -ge 3) {
        $replication += 7
    }
    elseif ($countries -ge 2) {
        $replication += 5
    }
    elseif ($countries -eq 1) {
        $replication += 3
    }

    if ($cities -ge 20) {
        $replication += 5
    }
    elseif ($cities -ge 10) {
        $replication += 3
    }
    elseif ($cities -ge 5) {
        $replication += 2
    }

    if ($sources -ge 3) {
        $replication += 4
    }
    elseif ($sources -ge 2) {
        $replication += 3
    }
    elseif ($sources -eq 1) {
        $replication += 1
    }

    if ($liveUrls -ge 2) {
        $replication += 4
    }
    elseif ($liveUrls -eq 1) {
        $replication += 2
    }

    $replication = [int](Clamp $replication 0 20)

    # =========================================
    # SOLO /15
    # =========================================

    $solo = 0

    if ($category -match "location") {
        $solo += 5
    }
    elseif ($category -match "reservation") {
        $solo += 4
    }
    else {
        $solo += 3
    }

    if ($category -match "location|reservation") {
        $solo += 4
    }
    else {
        $solo += 2
    }

    if ($sources -ge 3 -and $cities -ge 15) {
        $solo += 4
    }
    elseif ($sources -ge 2 -and $cities -ge 10) {
        $solo += 3
    }
    else {
        $solo += 2
    }

    if ($liveUrls -ge 1) {
        $solo += 2
    }

    $solo = [int](Clamp $solo 0 15)

    # =========================================
    # AUTOMATION /10
    # =========================================

    $automation = 0

    if ($category -match "location|reservation") {
        $automation += 4
    }
    else {
        $automation += 2
    }

    if ($category -match "location|reservation") {
        $automation += 3
    }
    else {
        $automation += 1
    }

    if ($sources -ge 3) {
        $automation += 2
    }
    elseif ($sources -ge 2) {
        $automation += 1
    }

    if ($liveUrls -ge 1) {
        $automation += 1
    }

    $automation = [int](Clamp $automation 0 10)

    # =========================================
    # ECONOMIC PROXY /10
    # =========================================

    $economic = 0

    if ($category -match "location") {
        $economic += 4
    }
    elseif ($category -match "reservation") {
        $economic += 3
    }
    else {
        $economic += 2
    }

    if ($cities -ge 20) {
        $economic += 3
    }
    elseif ($cities -ge 10) {
        $economic += 2
    }
    elseif ($cities -ge 5) {
        $economic += 1
    }

    if ($sources -ge 3) {
        $economic += 2
    }
    elseif ($sources -ge 2) {
        $economic += 1
    }

    if ($liveUrls -ge 1) {
        $economic += 1
    }

    $economic = [int](Clamp $economic 0 10)

    # =========================================
    # FINAL SCORE
    # =========================================

    $finalScore =
        $evidence +
        $demand +
        $replication +
        $solo +
        $automation +
        $economic

    $finalScore = [int](Clamp $finalScore 0 100)

    # =========================================
    # CONFIDENCE
    # =========================================

    if (
        $sources -ge 3 -and
        $countries -ge 3 -and
        $cities -ge 15 -and
        $liveUrls -ge 1
    ) {
        $confidence = "HIGH"
    }
    elseif (
        $sources -ge 2 -and
        $countries -ge 2
    ) {
        $confidence = "MEDIUM"
    }
    else {
        $confidence = "LOW"
    }

    # =========================================
    # STATUS
    # =========================================

    if ($finalScore -ge 90 -and $confidence -eq "HIGH") {
        $status = "TOP_OPPORTUNITY"
    }
    elseif ($finalScore -ge 80) {
        $status = "STRONG_OPPORTUNITY"
    }
    elseif ($finalScore -ge 70) {
        $status = "PROMISING"
    }
    elseif ($finalScore -ge 60) {
        $status = "WATCHLIST"
    }
    else {
        $status = "REJECT"
    }

    [PSCustomObject]@{
        idea_name = $ideaName
        category = $category

        final_score = $finalScore
        status = $status
        confidence = $confidence

        evidence_component = $evidence
        demand_component = $demand
        replication_component = $replication
        solo_component = $solo
        automation_component = $automation
        economic_proxy_component = $economic

        observation_count = $observations
        source_count = $sources
        country_count = $countries
        city_count = $cities
        url_count = $urls
        live_url_count = $liveUrls

        countries = @($item.countries)
        sources = @($item.sources)
        cities = @($item.cities)

        scoring_version = "RADAR_63"
        economic_status = "PROXY_ONLY"
    }
}

# =========================================
# SAVE
# =========================================

$result = @(
    $result |
    Sort-Object final_score -Descending
)

$result |
    ConvertTo-Json -Depth 20 |
    Set-Content .\radar63_evidence_metrics.json -Encoding UTF8

# =========================================
# DISPLAY
# =========================================

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "RADAR 63 - EVIDENCE METRICS" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Opportunités : $($result.Count)"
Write-Host ""

Write-Host "STATUT :" -ForegroundColor Yellow

$result |
    Group-Object status |
    Select-Object Name,Count |
    Sort-Object Name |
    Format-Table -AutoSize

Write-Host ""
Write-Host "TOP OPPORTUNITÉS :" -ForegroundColor Green
Write-Host ""

$result |
    Select-Object -First 15 `
        idea_name,
        final_score,
        status,
        confidence,
        evidence_component,
        demand_component,
        replication_component,
        solo_component,
        automation_component,
        economic_proxy_component |
    Format-Table -AutoSize

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Fichier créé : radar63_evidence_metrics.json" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
