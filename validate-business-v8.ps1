$items = Get-Content .\validation_queue.json -Raw | ConvertFrom-Json

foreach ($item in $items) {

    # ============================================================
    # BUSINESS VALIDATION V8
    # Evidence architecture
    # ============================================================

    $item | Add-Member -NotePropertyName "validation_version" -NotePropertyValue "V8" -Force

    # Liste des sources de preuve indépendantes
    $item | Add-Member `
        -NotePropertyName "evidence_sources" `
        -NotePropertyValue @() `
        -Force

    # Nombre de sources indépendantes confirmées
    $item | Add-Member `
        -NotePropertyName "independent_evidence_count" `
        -NotePropertyValue 0 `
        -Force

    # Indicateur global
    $item | Add-Member `
        -NotePropertyName "independent_evidence" `
        -NotePropertyValue $false `
        -Force

    # Qualité globale
    $item | Add-Member `
        -NotePropertyName "evidence_quality" `
        -NotePropertyValue "NONE" `
        -Force

    # Résumé humain
    $item | Add-Member `
        -NotePropertyName "evidence_summary" `
        -NotePropertyValue @() `
        -Force

    # ------------------------------------------------------------
    # SOURCES EXISTANTES
    # ------------------------------------------------------------

    $sources = @()

    if ($item.url_accessible -eq $true) {

        $sources += [PSCustomObject]@{
            type = "PRIMARY"
            url = [string]$item.url
            status = "ACCESSIBLE"
            independent = $false
        }
    }

    # ------------------------------------------------------------
    # POUR L'INSTANT :
    # aucune source externe n'a encore été collectée.
    # ------------------------------------------------------------

    $item.evidence_sources = $sources

    $independentSources = @(
        $sources | Where-Object {
            $_.independent -eq $true
        }
    )

    $item.independent_evidence_count = $independentSources.Count

    if ($item.independent_evidence_count -gt 0) {
        $item.independent_evidence = $true
    }
    else {
        $item.independent_evidence = $false
    }

    # ------------------------------------------------------------
    # EVALUATION
    # ------------------------------------------------------------

    if (
        $item.revenue_evidence -and
        $item.independent_evidence
    ) {

        $item.evidence_quality = "STRONG"
        $item.validation_status = "VALIDATED"
        $item.commercial_proof_level = "REVENUE_PROVEN"

        $item.validation_reason =
            "Revenue evidence confirmed by at least one independent source."

    }
    elseif ($item.revenue_evidence) {

        $item.evidence_quality = "MEDIUM"
        $item.validation_status = "PARTIAL"
        $item.commercial_proof_level = "REVENUE_CLAIMED"

        $item.validation_reason =
            "Revenue claim detected, but independent confirmation is missing."

    }
    elseif (
        $item.monetization_evidence -and
        $item.usage_evidence
    ) {

        $item.evidence_quality = "MEDIUM"
        $item.validation_status = "PARTIAL"
        $item.commercial_proof_level = "TRACTION"

        $item.validation_reason =
            "Monetization and quantified usage detected."

    }
    elseif ($item.monetization_evidence) {

        $item.evidence_quality = "LOW"
        $item.validation_status = "PARTIAL"
        $item.commercial_proof_level = "MONETIZED"

        $item.validation_reason =
            "Commercial offer detected, but commercial traction is not proven."

    }
    elseif ($item.usage_evidence) {

        $item.evidence_quality = "LOW"
        $item.validation_status = "PARTIAL"
        $item.commercial_proof_level = "USAGE"

        $item.validation_reason =
            "Quantified usage detected, but monetization is not proven."

    }
    else {

        $item.evidence_quality = "NONE"
        $item.validation_status = "UNVALIDATED"
        $item.commercial_proof_level = "NONE"

        $item.validation_reason =
            "No sufficiently strong commercial evidence detected."
    }

    # ------------------------------------------------------------
    # CONFIDENCE
    # ------------------------------------------------------------

    $score = 0

    if ($item.monetization_evidence) {
        $score += 20
    }

    if ($item.usage_evidence) {
        $score += 25
    }

    if ($item.revenue_evidence) {
        $score += 30
    }

    if ($item.growth_evidence) {
        $score += 15
    }

    if ($item.review_evidence) {
        $score += 10
    }

    # Une source indépendante apporte une vraie valeur
    if ($item.independent_evidence) {
        $score += 20
    }

    if (-not $item.independent_evidence -and $score -gt 80) {
        $score = 80
    }

    $item.confidence = $score
}

# ============================================================
# SAVE
# ============================================================

$items |
    ConvertTo-Json -Depth 15 |
    Set-Content .\validation_queue.json -Encoding UTF8

# ============================================================
# OUTPUT
# ============================================================

Write-Host ""
Write-Host "======================================"
Write-Host " BUSINESS VALIDATION V8"
Write-Host "======================================"
Write-Host ""

$items |
    Select-Object `
        name,
        validation_status,
        commercial_proof_level,
        evidence_quality,
        independent_evidence_count,
        confidence |
    Format-Table -AutoSize

Write-Host ""
Write-Host "EVIDENCE SOURCES"
Write-Host "----------------"

foreach ($item in $items) {

    Write-Host ""
    Write-Host "===== $($item.name) ====="

    if ($item.evidence_sources.Count -eq 0) {
        Write-Host "No evidence sources."
    }
    else {
        foreach ($source in $item.evidence_sources) {

            Write-Host "[$($source.type)] $($source.status)"
            Write-Host "  $($source.url)"
        }
    }
}
