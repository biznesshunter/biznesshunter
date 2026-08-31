$items = Get-Content .\validation_queue.json -Raw | ConvertFrom-Json

foreach ($item in $items) {

    $text = [string]$item.page_content

    $signals = @()

    if ($text -match '\$\s?\d+|\€\s?\d+|pricing|price|paid|premium|subscription|subscribe|pro plan|buy now|purchase') {
        $signals += "MONETIZATION"
    }

    if ($text -match 'customer|customers|user|users|download|downloads|install|installs|member|members') {
        $signals += "USAGE"
    }

    if (
        $text -match '\$\s?\d+(\.\d+)?\s?(k|m)?\s?(mrr|arr|revenue)' -or
        $text -match '(monthly recurring revenue|annual recurring revenue|net revenue|net profit|profit margin)' -or
        $text -match '(revenue|mrr|arr)\s*(of|:|=)\s*\$?\d+'
    ) {
        $signals += "REVENUE"
    }

    if ($text -match 'growth|grew|growing|increase|increased|growth rate') {
        $signals += "GROWTH"
    }

    if ($text -match 'testimonial|testimonials|review|reviews|rating|ratings') {
        $signals += "REVIEWS"
    }

    if ($text -match 'advertising|advertisement|ads|affiliate') {
        $signals += "ADVERTISING"
    }

    if ($text -match 'api|developer|developers|sdk|cli') {
        $signals += "DEVELOPER"
    }

    $item | Add-Member -NotePropertyName "page_evidence" -NotePropertyValue $signals -Force

    if ($signals -contains "REVENUE") {
        $item.validation_status = "PARTIAL"
        $item.commercial_proof_level = "REVENUE"
    }
    elseif (
        ($signals -contains "USAGE") -and
        ($signals -contains "REVIEWS")
    ) {
        $item.validation_status = "PARTIAL"
        $item.commercial_proof_level = "TRACTION"
    }
    elseif ($signals -contains "MONETIZATION") {
        $item.validation_status = "PARTIAL"
        $item.commercial_proof_level = "MONETIZED"
    }
    elseif ($signals.Count -gt 0) {
        $item.validation_status = "PARTIAL"
        $item.commercial_proof_level = "WEAK"
    }
    else {
        $item.validation_status = "UNVALIDATED"
        $item.commercial_proof_level = "NONE"
    }
}

$items |
    ConvertTo-Json -Depth 10 |
    Set-Content .\validation_queue.json -Encoding UTF8

$items |
    Select-Object name,validation_status,commercial_proof_level,page_evidence |
    Format-Table -AutoSize



