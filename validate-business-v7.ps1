$items = Get-Content .\validation_queue.json -Raw | ConvertFrom-Json

foreach ($item in $items) {

    # ============================================================
    # BUSINESS VALIDATION V7
    # ============================================================

    $name = ([string]$item.name).ToLower()
    $url = ([string]$item.url).ToLower()
    $page = ([string]$item.page_content).ToLower()
    $signalsText = ([string]($item.signals -join " ")).ToLower()

    # On combine toutes les informations disponibles
    $text = "$name $url $page $signalsText"

    # ------------------------------------------------------------
    # INITIALISATION
    # ------------------------------------------------------------

    $item | Add-Member -NotePropertyName "validation_version" -NotePropertyValue "V7" -Force
    $item | Add-Member -NotePropertyName "monetization_evidence" -NotePropertyValue $false -Force
    $item | Add-Member -NotePropertyName "usage_evidence" -NotePropertyValue $false -Force
    $item | Add-Member -NotePropertyName "revenue_evidence" -NotePropertyValue $false -Force
    $item | Add-Member -NotePropertyName "growth_evidence" -NotePropertyValue $false -Force
    $item | Add-Member -NotePropertyName "review_evidence" -NotePropertyValue $false -Force
    $item | Add-Member -NotePropertyName "independent_evidence" -NotePropertyValue $false -Force
    $item | Add-Member -NotePropertyName "evidence_quality" -NotePropertyValue "NONE" -Force
    $item | Add-Member -NotePropertyName "validation_reason" -NotePropertyValue "" -Force
    $item | Add-Member -NotePropertyName "evidence_summary" -NotePropertyValue @() -Force

    $evidence = @()

    # ------------------------------------------------------------
    # MONETIZATION
    # ------------------------------------------------------------

    if (
        $text -match '\$\s?\d+(\.\d+)?' -or
        $text -match '€\s?\d+(\.\d+)?' -or
        $text -match '£\s?\d+(\.\d+)?' -or
        $text -match 'pricing' -or
        $text -match 'paid plan' -or
        $text -match 'subscription' -or
        $text -match 'subscribe' -or
        $text -match 'premium plan' -or
        $text -match 'pro plan' -or
        $text -match 'buy now' -or
        $text -match 'purchase' -or
        $text -match 'paid version' -or
        $text -match 'one[- ]time purchase' -or
        $text -match 'one[- ]time payment'
    ) {
        $item.monetization_evidence = $true
        $evidence += "MONETIZATION"
    }

    # ------------------------------------------------------------
    # USAGE / TRACTION
    # Seulement si quantifié
    # ------------------------------------------------------------

    if (
        $text -match '\d+\s+(users|customers|members|downloads|installs)' -or
        $text -match '\d+[kKmM]\+?\s+(users|customers|members|downloads|installs)' -or
        $text -match '(users|customers|members|downloads|installs)\s*:\s*\d+' -or
        $text -match '(over|more than)\s+\d+\s+(users|customers|downloads|installs)'
    ) {
        $item.usage_evidence = $true
        $evidence += "QUANTIFIED_USAGE"
    }

    # ------------------------------------------------------------
    # REVENUE
    # Preuve explicite et chiffrée uniquement
    # ------------------------------------------------------------

    if (
        $text -match '\$\s?\d+(\.\d+)?\s?(k|m)?\s*(mrr|arr|revenue)' -or
        $text -match '(mrr|arr|revenue)\s*(of|:|=)\s*\$?\d+' -or
        $text -match '(monthly recurring revenue|annual recurring revenue)' -or
        $text -match 'revenue of \$' -or
        $text -match 'generated \$\d+' -or
        $text -match 'made \$\d+' -or
        $text -match 'annual revenue of \$' -or
        $text -match 'revenue\s+\$[\d,.]+'
    ) {
        $item.revenue_evidence = $true
        $evidence += "QUANTIFIED_REVENUE"
    }

    # ------------------------------------------------------------
    # CROISSANCE
    # ------------------------------------------------------------

    if (
        $text -match '\d+%\s+(growth|increase)' -or
        $text -match 'grew by \d+%' -or
        $text -match 'grew \d+%' -or
        $text -match 'growth of \d+%' -or
        $text -match 'increased by \d+%'
    ) {
        $item.growth_evidence = $true
        $evidence += "QUANTIFIED_GROWTH"
    }

    # ------------------------------------------------------------
    # REVIEWS / TESTIMONIALS
    # ------------------------------------------------------------

    if (
        $text -match 'customer reviews' -or
        $text -match 'reviews from customers' -or
        $text -match 'testimonials' -or
        $text -match 'customer testimonial' -or
        $text -match 'rated \d+(\.\d+)?'
    ) {
        $item.review_evidence = $true
        $evidence += "REVIEWS"
    }

    # ------------------------------------------------------------
    # PREUVE INDÉPENDANTE
    # Toujours FALSE à ce stade.
    # Elle sera apportée par une vraie source externe.
    # ------------------------------------------------------------

    $item.independent_evidence = $false

    # ------------------------------------------------------------
    # STOCKAGE DES PREUVES
    # ------------------------------------------------------------

    $item.evidence_summary = $evidence

    # ------------------------------------------------------------
    # CLASSIFICATION
    # ------------------------------------------------------------

    if ($item.revenue_evidence -and $item.independent_evidence) {

        $item.evidence_quality = "STRONG"
        $item.validation_status = "VALIDATED"
        $item.commercial_proof_level = "REVENUE_PROVEN"

        $item.validation_reason =
            "Quantified revenue evidence supported by independent evidence."

    }
    elseif ($item.revenue_evidence) {

        $item.evidence_quality = "MEDIUM"
        $item.validation_status = "PARTIAL"
        $item.commercial_proof_level = "REVENUE_CLAIMED"

        $item.validation_reason =
            "Quantified revenue claim detected, but independent validation is missing."

    }
    elseif ($item.monetization_evidence -and $item.usage_evidence) {

        $item.evidence_quality = "MEDIUM"
        $item.validation_status = "PARTIAL"
        $item.commercial_proof_level = "TRACTION"

        $item.validation_reason =
            "Commercial monetization and quantified usage detected."

    }
    elseif ($item.monetization_evidence) {

        $item.evidence_quality = "LOW"
        $item.validation_status = "PARTIAL"
        $item.commercial_proof_level = "MONETIZED"

        $item.validation_reason =
            "A commercial offer or price is visible, but traction or revenue is not proven."

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
    # CONFIDENCE SCORE
    # ------------------------------------------------------------

    $score = 0

    if ($item.monetization_evidence) { $score += 20 }
    if ($item.usage_evidence) { $score += 25 }
    if ($item.revenue_evidence) { $score += 30 }
    if ($item.growth_evidence) { $score += 15 }
    if ($item.review_evidence) { $score += 10 }
    if ($item.independent_evidence) { $score += 20 }

    # Sans preuve indépendante, on plafonne.
    if (-not $item.independent_evidence -and $score -gt 80) {
        $score = 80
    }

    $item.confidence = $score
}

# ================================================================
# SAUVEGARDE
# ================================================================

$items |
    ConvertTo-Json -Depth 10 |
    Set-Content .\validation_queue.json -Encoding UTF8

# ================================================================
# AFFICHAGE
# ================================================================

Write-Host ""
Write-Host "======================================"
Write-Host " BUSINESS VALIDATION V7"
Write-Host "======================================"
Write-Host ""

$items |
    Select-Object `
        name,
        validation_status,
        commercial_proof_level,
        evidence_quality,
        monetization_evidence,
        usage_evidence,
        revenue_evidence,
        growth_evidence,
        confidence |
    Format-Table -AutoSize

Write-Host ""
Write-Host "EVIDENCE DETAILS"
Write-Host "----------------"

foreach ($item in $items) {

    Write-Host ""
    Write-Host $item.name
    Write-Host "  LEVEL      : $($item.commercial_proof_level)"
    Write-Host "  QUALITY    : $($item.evidence_quality)"
    Write-Host "  CONFIDENCE : $($item.confidence)"
    Write-Host "  EVIDENCE   : $($item.evidence_summary -join ', ')"
    Write-Host "  REASON     : $($item.validation_reason)"
}
