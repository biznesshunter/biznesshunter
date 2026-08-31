$items = Get-Content .\validation_queue.json -Raw | ConvertFrom-Json

foreach ($item in $items) {

    $item | Add-Member -NotePropertyName "price_evidence" -NotePropertyValue $false -Force
    $item | Add-Member -NotePropertyName "platform_evidence" -NotePropertyValue $false -Force
    $item | Add-Member -NotePropertyName "customer_evidence" -NotePropertyValue $false -Force
    $item | Add-Member -NotePropertyName "revenue_evidence" -NotePropertyValue $false -Force
    $item | Add-Member -NotePropertyName "growth_evidence" -NotePropertyValue $false -Force
    $item | Add-Member -NotePropertyName "independent_evidence" -NotePropertyValue $false -Force

    $text = (
        [string]$item.name + " " +
        [string]$item.url + " " +
        [string]$item.signals
    ).ToLower()

    if ($text -match '\$\d+|€\d+|price|pricing') {
        $item.price_evidence = $true
    }

    if ($text -match 'apps.microsoft.com|play.google.com|apps.apple.com|gumroad.com|patreon.com') {
        $item.platform_evidence = $true
    }

    if ($text -match 'customers|customer|users|downloads') {
        $item.customer_evidence = $true
    }

    if ($text -match 'revenue|mrr|arr|sales|sold') {
        $item.revenue_evidence = $true
    }

    if ($text -match 'growth|grew|growing|increase|increased') {
        $item.growth_evidence = $true
    }

    $evidenceCount = @(
        $item.price_evidence
        $item.platform_evidence
        $item.customer_evidence
        $item.revenue_evidence
        $item.growth_evidence
        $item.independent_evidence
    ) | Where-Object { $_ -eq $true } | Measure-Object | Select-Object -ExpandProperty Count

    if ($item.revenue_evidence -and $item.customer_evidence) {
        $item.commercial_proof_level = "REVENUE"
        $item.validation_status = "PARTIAL"
        $item.confidence = 70
    }
    elseif ($item.customer_evidence -or $item.growth_evidence) {
        $item.commercial_proof_level = "TRACTION"
        $item.validation_status = "PARTIAL"
        $item.confidence = 55
    }
    elseif ($item.price_evidence -and $item.platform_evidence) {
        $item.commercial_proof_level = "MONETIZED"
        $item.validation_status = "PARTIAL"
        $item.confidence = 30
    }
    elseif ($evidenceCount -gt 0) {
        $item.commercial_proof_level = "WEAK"
        $item.validation_status = "PARTIAL"
        $item.confidence = 15
    }
    else {
        $item.commercial_proof_level = "NONE"
        $item.validation_status = "UNVALIDATED"
        $item.confidence = 0
    }
}

$items |
    ConvertTo-Json -Depth 10 |
    Set-Content .\validation_queue.json -Encoding UTF8

$items |
    Select-Object name,commercial_proof_level,price_evidence,platform_evidence,customer_evidence,revenue_evidence,growth_evidence,confidence |
    Format-Table -AutoSize
