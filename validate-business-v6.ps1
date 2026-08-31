$items = Get-Content .\validation_queue.json -Raw | ConvertFrom-Json

foreach ($item in $items) {

    $text = [string]$item.page_content
    $text = $text.ToLower()

    $item | Add-Member -NotePropertyName "validation_version" -NotePropertyValue "V6" -Force
    $item | Add-Member -NotePropertyName "monetization_evidence" -NotePropertyValue $false -Force
    $item | Add-Member -NotePropertyName "usage_evidence" -NotePropertyValue $false -Force
    $item | Add-Member -NotePropertyName "revenue_evidence" -NotePropertyValue $false -Force
    $item | Add-Member -NotePropertyName "growth_evidence" -NotePropertyValue $false -Force
    $item | Add-Member -NotePropertyName "review_evidence" -NotePropertyValue $false -Force
    $item | Add-Member -NotePropertyName "independent_evidence" -NotePropertyValue $false -Force
    $item | Add-Member -NotePropertyName "evidence_quality" -NotePropertyValue "NONE" -Force
    $item | Add-Member -NotePropertyName "validation_reason" -NotePropertyValue "" -Force

    # MONETIZATION
    if (
        $text -match '\$\s?\d+(\.\d+)?' -or
        $text -match '€\s?\d+(\.\d+)?' -or
        $text -match 'pricing' -or
        $text -match 'paid plan' -or
        $text -match 'subscription' -or
        $text -match 'subscribe' -or
        $text -match 'premium plan' -or
        $text -match 'pro plan' -or
        $text -match 'buy now' -or
        $text -match 'purchase'
    ) {
        $item.monetization_evidence = $true
    }

    # QUANTIFIED USAGE ONLY
    if (
        $text -match '\d+\s+(users|customers|members|downloads|installs)' -or
        $text -match '(users|customers|members|downloads|installs)\s*:\s*\d+' -or
        $text -match '\d+[kKmM]\+?\s+(users|customers|downloads|installs)'
    ) {
        $item.usage_evidence = $true
    }

    # EXPLICIT REVENUE
    if (
        $text -match '\$\s?\d+(\.\d+)?\s?(k|m)?\s*(mrr|arr|revenue)' -or
        $text -match '(mrr|arr|revenue)\s*(of|:|=)\s*\$?\d+' -or
        $text -match 'monthly recurring revenue' -or
        $text -match 'annual recurring revenue' -or
        $text -match 'revenue of \$' -or
        $text -match 'generated \$\d+' -or
        $text -match 'made \$\d+' -or
        $text -match 'annual revenue'
    ) {
        $item.revenue_evidence = $true
    }

    # QUANTIFIED GROWTH
    if (
        $text -match '\d+%\s+(growth|increase)' -or
        $text -match 'grew by \d+%' -or
        $text -match 'grew \d+%' -or
        $text -match 'growth of \d+%' -or
        $text -match 'increased by \d+%'
    ) {
        $item.growth_evidence = $true
    }

    # REVIEWS
    if (
        $text -match 'customer reviews' -or
        $text -match 'reviews from customers' -or
        $text -match 'testimonials' -or
        $text -match 'customer testimonial' -or
        $text -match 'rated \d+(\.\d+)?'
    ) {
        $item.review_evidence = $true
    }

    # NO INDEPENDENT VALIDATION YET
    $item.independent_evidence = $false

    # VALIDATION LEVEL
    if ($item.revenue_evidence -and $item.independent_evidence) {

        $item.evidence_quality = "STRONG"
        $item.validation_status = "VALIDATED"
        $item.commercial_proof_level = "REVENUE_PROVEN"
        $item.validation_reason = "Revenue evidence supported by independent evidence."

    }
    elseif ($item.revenue_evidence) {

        $item.evidence_quality = "MEDIUM"
        $item.validation_status = "PARTIAL"
        $item.commercial_proof_level = "REVENUE_CLAIMED"
        $item.validation_reason = "Revenue signal found, but no independent validation."

    }
    elseif ($item.monetization_evidence -and $item.usage_evidence) {

        $item.evidence_quality = "MEDIUM"
        $item.validation_status = "PARTIAL"
        $item.commercial_proof_level = "TRACTION"
        $item.validation_reason = "Commercial monetization and quantified usage detected."

    }
    elseif ($item.monetization_evidence) {

        $item.evidence_quality = "LOW"
        $item.validation_status = "PARTIAL"
        $item.commercial_proof_level = "MONETIZED"
        $item.validation_reason = "Commercial offer detected, but traction or revenue is not proven."

    }
    elseif ($item.usage_evidence) {

        $item.evidence_quality = "LOW"
        $item.validation_status = "PARTIAL"
        $item.commercial_proof_level = "USAGE"
        $item.validation_reason = "Quantified usage detected, but monetization is not proven."

    }
    else {

        $item.evidence_quality = "NONE"
        $item.validation_status = "UNVALIDATED"
        $item.commercial_proof_level = "NONE"
        $item.validation_reason = "No sufficiently strong commercial evidence detected."
    }

    # CONFIDENCE
    $score = 0

    if ($item.monetization_evidence) { $score += 20 }
    if ($item.usage_evidence) { $score += 25 }
    if ($item.revenue_evidence) { $score += 30 }
    if ($item.growth_evidence) { $score += 15 }
    if ($item.review_evidence) { $score += 10 }
    if ($item.independent_evidence) { $score += 20 }

    if (-not $item.independent_evidence -and $score -gt 80) {
        $score = 80
    }

    $item.confidence = $score
}

$items |
    ConvertTo-Json -Depth 10 |
    Set-Content .\validation_queue.json -Encoding UTF8

Write-Host ""
Write-Host "=============================="
Write-Host " BUSINESS VALIDATION V6"
Write-Host "=============================="
Write-Host ""

$items |
    Select-Object name,validation_status,commercial_proof_level,evidence_quality,monetization_evidence,usage_evidence,revenue_evidence,growth_evidence,confidence |
    Format-Table -AutoSize

Write-Host ""
