$businesses = Get-Content .\real_businesses.json -Raw | ConvertFrom-Json

foreach ($b in $businesses) {

    $t = $b.traction

    $proofs = @()

    if ($t.mrr_usd -or $t.annual_sales_usd -or $t.revenue_usd) {
        $proofs += "Revenue"
    }

    if ($t.revenue_growth_yoy -or $t.subscriber_growth_yoy) {
        $proofs += "Growth"
    }

    if ($t.customers -or $t.users -or $t.entrepreneurs -or $t.monthly_active_subscribers) {
        $proofs += "Customers/Users"
    }

    if ($t.profitable -eq $true -or $t.profit_usd -or $t.profit_level) {
        $proofs += "Profitability"
    }

    if ($t.funding_usd -or $t.funding_eur -or $t.acquisition_value_eur) {
        $proofs += "Funding/Transaction"
    }

    if ($t.expansion) {
        $proofs += "Expansion"
    }

    [PSCustomObject]@{
        Business = $b.name
        ProofCount = $proofs.Count
        Proofs = ($proofs -join ", ")
    }
}
