$businesses = Get-Content .\real_businesses.json -Raw | ConvertFrom-Json

foreach ($b in $businesses) {

    $t = $b.traction
    $proofCount = 0

    if ($t.mrr_usd -or $t.annual_sales_usd -or $t.revenue_usd) {
        $proofCount++
    }

    if ($t.revenue_growth_yoy -or $t.subscriber_growth_yoy) {
        $proofCount++
    }

    if ($t.customers -or $t.users -or $t.entrepreneurs -or $t.monthly_active_subscribers) {
        $proofCount++
    }

    if ($t.profitable -eq $true -or $t.profit_usd -or $t.profit_level) {
        $proofCount++
    }

    if ($t.funding_usd -or $t.funding_eur -or $t.acquisition_value_eur) {
        $proofCount++
    }

    if ($t.expansion -and $t.expansion.Count -gt 0) {
        $proofCount++
    }

    if ($proofCount -ge 3 -and $b.sources.Count -ge 2) {
        $status = "READY"
    }
    else {
        $status = "INSUFFICIENT_DATA"
    }

    [PSCustomObject]@{
        Business = $b.name
        Proofs = $proofCount
        Sources = $b.sources.Count
        Status = $status
    }
}
