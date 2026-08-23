$data = Get-Content .\raw_business.json -Raw | ConvertFrom-Json

$data | Add-Member -NotePropertyName "evidence_quality" -NotePropertyValue @{
    revenue_growth = 5
    customers = 4
    profitability = 4
    funding = 3
    sources = 5
} -Force

$data | Add-Member -NotePropertyName "copy_factors" -NotePropertyValue @{
    initial_capital = "medium"
    technical_complexity = "medium"
    operational_complexity = "medium"
    customer_acquisition = "high"
    regulatory_barriers = "low"
    network_effect = "high"
    solo_feasibility = "medium"
} -Force

$data | ConvertTo-Json -Depth 10 | Set-Content -Encoding UTF8 raw_business.json

Write-Host "Passionfroot mis à jour."
