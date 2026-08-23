# ==========================================
# BUSINESS HUNTER V16
# Compatible Windows PowerShell 5.1
# ==========================================

$ErrorActionPreference = "Stop"

$InputFile  = ".\business_opportunities_v15.json"
$OutputFile = ".\business_opportunities_v16.json"

Write-Host ""
Write-Host "=========================================="
Write-Host "BUSINESS HUNTER V16"
Write-Host "=========================================="
Write-Host ""

if (-not (Test-Path $InputFile)) {
    Write-Host "ERREUR : $InputFile introuvable." -ForegroundColor Red
    exit 1
}

$data = Get-Content $InputFile -Raw | ConvertFrom-Json
$data = @($data)

$results = @()

foreach ($item in $data) {

    $source = [string]$item.source

    # --------------------------------------
    # Valeurs sécurisées
    # --------------------------------------

    $originalScore = 0
    $commercial = 0
    $problem = 0
    $customer = 0
    $copyability = 0
    $simplicity = 0

    if ($null -ne $item.opportunity_score) {
        $originalScore = [int]$item.opportunity_score
    }

    if ($null -ne $item.commercial_opportunity) {
        $commercial = [int]$item.commercial_opportunity
    }

    if ($null -ne $item.problem) {
        $problem = [int]$item.problem
    }

    if ($null -ne $item.customer) {
        $customer = [int]$item.customer
    }

    if ($null -ne $item.copyability) {
        $copyability = [int]$item.copyability
    }

    if ($null -ne $item.simplicity) {
        $simplicity = [int]$item.simplicity
    }

    # --------------------------------------
    # FILTRE D'ÉLIGIBILITÉ
    # --------------------------------------

    $reasons = @()

    if ($originalScore -lt 20) {
        $reasons += "Signal business trop faible"
    }

    if ($commercial -lt 10) {
        $reasons += "Opportunité commerciale faible"
    }

    if ($problem -lt 10) {
        $reasons += "Problème insuffisamment démontré"
    }

    if ($customer -lt 10) {
        $reasons += "Client cible insuffisamment identifiable"
    }

    # --------------------------------------
    # RISQUE TECHNIQUE
    # --------------------------------------

    $technicalRisk = $false

    $technicalKeywords = @(
        "infrastructure",
        "developer tool",
        "coding agents",
        "React",
        "SDK",
        "API",
        "framework",
        "compiler",
        "visual UI testing"
    )

    foreach ($keyword in $technicalKeywords) {
        if ($source -match [regex]::Escape($keyword)) {
            $technicalRisk = $true
            break
        }
    }

    if ($technicalRisk) {
        $reasons += "Forte dépendance à une expertise technique"
    }

    # --------------------------------------
    # SCORE DEMANDE
    # --------------------------------------

    $demandScore = [Math]::Min(
        25,
        [Math]::Round(($problem / 40) * 25)
    )

    # --------------------------------------
    # SCORE PREUVE
    # --------------------------------------

    $proofScore = [Math]::Min(
        20,
        [Math]::Round(($originalScore / 100) * 20)
    )

    # --------------------------------------
    # COPYABILITÉ
    # --------------------------------------

    if ($copyability -gt 0) {

        $copyScore = [Math]::Min(
            20,
            [Math]::Round(($copyability / 100) * 20)
        )

    } else {

        $copyScore = 10
    }

    # --------------------------------------
    # SIMPLICITÉ
    # --------------------------------------

    if ($simplicity -gt 0) {

        $simpleScore = [Math]::Min(
            15,
            [Math]::Round(($simplicity / 100) * 15)
        )

    } else {

        $simpleScore = 7
    }

    # --------------------------------------
    # AUTOMATISATION
    # --------------------------------------

    $automationScore = 8

    if ($technicalRisk) {
        $automationScore = 5
    }

    # --------------------------------------
    # CAPITAL
    # --------------------------------------

    $capitalScore = 8

    if ($technicalRisk) {
        $capitalScore = 5
    }

    # --------------------------------------
    # SCORE FINAL
    # --------------------------------------

    $score =
        $demandScore +
        $proofScore +
        $copyScore +
        $simpleScore +
        $automationScore +
        $capitalScore

    # --------------------------------------
    # CONFIDENCE
    # --------------------------------------

    $confidence = "MOYENNE"

    if (
        ($originalScore -ge 70) -and
        ($commercial -ge 25) -and
        ($problem -ge 30)
    ) {
        $confidence = "FORTE"
    }

    if (
        ($originalScore -lt 40) -or
        ($problem -lt 20)
    ) {
        $confidence = "FAIBLE"
    }

    # --------------------------------------
    # VERDICT
    # --------------------------------------

    if ($reasons.Count -ge 3) {

        $status = "REJECTED"
        $verdict = "REJETER"

    }
    elseif ($score -ge 75) {

        $status = "OPPORTUNITY"
        $verdict = "GO"

    }
    elseif ($score -ge 60) {

        $status = "WATCH"
        $verdict = "A SURVEILLER"

    }
    else {

        $status = "REJECTED"
        $verdict = "REJETER"
    }

    # --------------------------------------
    # CONCEPT COPYCAT
    # --------------------------------------

    $copycat = ""

    if ($source -match "Active Source of Truth") {

        $copycat = "Version simplifiée de gestion et synchronisation de connaissances pour petites équipes utilisant des agents IA."

    }
    elseif ($source -match "Lens AI") {

        $copycat = "Service simple d'audit et de maintenance SEO et structured data pour petites entreprises."

    }
    elseif ($source -match "LayoutLens") {

        $copycat = "Service automatisé de contrôle visuel de sites web pour petites agences et indépendants."

    }
    elseif ($source -match "CtrlTool") {

        $copycat = "Micro-outil utilitaire ultra-ciblé résolvant un problème fréquent."

    }
    elseif ($source -match "Agent2Creator") {

        $copycat = "Service de niche utilisant les agents IA pour automatiser une tâche précise."

    }
    else {

        $copycat = "Identifier la fonction commerciale principale puis construire une version beaucoup plus étroite et simple."
    }

    # --------------------------------------
    # OBJET FINAL
    # --------------------------------------

    $results += [PSCustomObject]@{

        source = $source

        status = $status

        verdict = $verdict

        opportunity_score = $score

        confidence = $confidence

        demand = $demandScore

        proof = $proofScore

        copyability = $copyScore

        simplicity = $simpleScore

        automation = $automationScore

        capital = $capitalScore

        commercial_opportunity = $commercial

        problem = $problem

        customer = $customer

        copycat_concept = $copycat

        rejection_reasons = @($reasons)
    }
}

# ------------------------------------------
# TRI
# ------------------------------------------

$results = $results |
    Sort-Object `
        @{Expression={
            if ($_.status -eq "OPPORTUNITY") {
                0
            }
            elseif ($_.status -eq "WATCH") {
                1
            }
            else {
                2
            }
        }}, `
        @{Expression={$_.opportunity_score};Descending=$true}

# ------------------------------------------
# EXPORT JSON
# ------------------------------------------

$results |
    ConvertTo-Json -Depth 6 |
    Set-Content $OutputFile -Encoding UTF8

# ------------------------------------------
# AFFICHAGE
# ------------------------------------------

Write-Host "Sources analysees : $($results.Count)"
Write-Host ""

$results |
    Select-Object `
        source,
        status,
        verdict,
        opportunity_score,
        confidence,
        demand,
        proof,
        copyability,
        simplicity,
        automation,
        capital |
    Format-Table -AutoSize

Write-Host ""
Write-Host "=========================================="
Write-Host "TOP OPPORTUNITES"
Write-Host "=========================================="
Write-Host ""

$results |
    Where-Object {$_.status -eq "OPPORTUNITY"} |
    Select-Object `
        source,
        opportunity_score,
        confidence,
        copycat_concept |
    Format-List

Write-Host ""
Write-Host "Resultats : $OutputFile"
Write-Host ""
