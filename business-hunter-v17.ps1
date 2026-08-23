# ==========================================
# BUSINESS HUNTER V17
# FILTRE FINAL BIZNESSHUNTER
# ==========================================

$ErrorActionPreference = "Stop"

$InputFile  = ".\business_opportunities_v15.json"
$OutputFile = ".\business_opportunities_v17.json"

$data = @(Get-Content $InputFile -Raw | ConvertFrom-Json)
$results = @()

foreach ($item in $data) {

    $source = [string]$item.source

    $original = 0
    $commercial = 0
    $problem = 0
    $customer = 0

    if ($null -ne $item.opportunity_score) {
        $original = [int]$item.opportunity_score
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

    # ======================================
    # PROFIL BIZNESSHUNTER
    # ======================================

    $proof = [Math]::Min(20,[Math]::Round($original / 5))

    $demand = [Math]::Min(20,[Math]::Round($problem / 2))

    $customerScore = [Math]::Min(10,[Math]::Round($customer / 4))

    $commercialScore = [Math]::Min(15,[Math]::Round($commercial / 2))

    # ======================================
    # COPYABILITÉ
    # ======================================

    $copy = 15

    if ($source -match "coding agents|React|SDK|API|framework|compiler") {
        $copy = 5
    }

    if ($source -match "video social network") {
        $copy = 8
    }

    if ($source -match "Licence") {
        $copy = 10
    }

    # ======================================
    # SIMPLICITÉ
    # ======================================

    $simplicity = 10

    if ($source -match "LayoutLens") {
        $simplicity = 7
    }

    if ($source -match "Active Source") {
        $simplicity = 5
    }

    if ($source -match "Agent2Creator") {
        $simplicity = 7
    }

    # ======================================
    # AUTOMATISATION
    # ======================================

    $automation = 10

    # ======================================
    # CAPITAL
    # ======================================

    $capital = 10

    # ======================================
    # SCORE FINAL
    # ======================================

    $score =
        $proof +
        $demand +
        $customerScore +
        $commercialScore +
        $copy +
        $simplicity +
        $automation +
        $capital

    if ($score -gt 100) {
        $score = 100
    }

    # ======================================
    # FILTRES DURS
    # ======================================

    $hardReject = $false
    $rejectReason = @()

    if ($original -lt 20) {
        $hardReject = $true
        $rejectReason += "preuve insuffisante"
    }

    if ($problem -lt 10) {
        $hardReject = $true
        $rejectReason += "problème faible"
    }

    if ($commercial -lt 10) {
        $hardReject = $true
        $rejectReason += "potentiel commercial faible"
    }

    if ($copy -le 5) {
        $hardReject = $true
        $rejectReason += "trop technique à copier"
    }

    # ======================================
    # VERDICT
    # ======================================

    if ($hardReject) {
        $status = "REJECTED"
        $verdict = "REJETER"
    }
    elseif ($score -ge 75) {
        $status = "ELIGIBLE"
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

    # ======================================
    # PREUVE
    # ======================================

    if ($original -ge 70) {
        $proofLevel = "FORTE"
    }
    elseif ($original -ge 40) {
        $proofLevel = "MOYENNE"
    }
    else {
        $proofLevel = "FAIBLE"
    }

    # ======================================
    # COPYCAT
    # ======================================

    if ($source -match "Lens AI") {
        $copycat = "Audit SEO et données structurées automatisé pour PME"
        $customerType = "PME / indépendants"
        $money = "abonnement mensuel"
    }
    elseif ($source -match "Active Source") {
        $copycat = "Base de connaissances simple pour petites équipes utilisant l'IA"
        $customerType = "petites entreprises"
        $money = "abonnement"
    }
    elseif ($source -match "LayoutLens") {
        $copycat = "Contrôle automatique de sites web pour agences et freelances"
        $customerType = "agences web"
        $money = "abonnement / service"
    }
    elseif ($source -match "Agent2Creator") {
        $copycat = "Micro-service automatisé utilisant des agents IA"
        $customerType = "créateurs / indépendants"
        $money = "abonnement"
    }
    elseif ($source -match "CtrlTool") {
        $copycat = "Micro-outil utilitaire ultra-spécifique"
        $customerType = "B2C / professionnels"
        $money = "freemium / abonnement"
    }
    elseif ($source -match "Nice Licence") {
        $copycat = "Service simplifié autour d'un besoin juridique précis"
        $customerType = "indépendants / PME"
        $money = "paiement à l'usage"
    }
    else {
        $copycat = "Micro-business dérivé du besoin identifié"
        $customerType = "à déterminer"
        $money = "à déterminer"
    }

    $results += [PSCustomObject]@{
        source = $source
        status = $status
        verdict = $verdict
        opportunity_score = $score
        proof = $proofLevel
        demand = $demand
        customer = $customerScore
        commercial = $commercialScore
        copyability = $copy
        simplicity = $simplicity
        automation = $automation
        capital = $capital
        copycat_business = $copycat
        target_customer = $customerType
        monetization = $money
        rejection_reason = ($rejectReason -join "; ")
    }
}

$results = $results |
    Sort-Object `
        @{Expression={
            if ($_.status -eq "ELIGIBLE") {0}
            elseif ($_.status -eq "WATCH") {1}
            else {2}
        }}, `
        @{Expression={$_.opportunity_score};Descending=$true}

$results |
    ConvertTo-Json -Depth 6 |
    Set-Content $OutputFile -Encoding UTF8

Write-Host ""
Write-Host "=========================================="
Write-Host "BUSINESS HUNTER V17"
Write-Host "=========================================="
Write-Host ""

$results |
    Select-Object source,status,verdict,opportunity_score,proof,copyability,simplicity,automation,capital |
    Format-Table -AutoSize

Write-Host ""
Write-Host "=========================================="
Write-Host "BUSINESS ELIGIBLES"
Write-Host "=========================================="
Write-Host ""

$results |
    Where-Object {$_.status -eq "ELIGIBLE"} |
    Select-Object source,opportunity_score,copycat_business,target_customer,monetization |
    Format-List

Write-Host ""
Write-Host "Resultats : $OutputFile"
