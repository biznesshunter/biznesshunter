$items = Get-Content .\business_candidates.json -Raw | ConvertFrom-Json

$results = foreach ($item in $items) {

    [PSCustomObject]@{
        name = $item.name
        url = $item.url
        source = $item.source
        business_score = $item.business_score
        signals = $item.signals

        validation_status = "PENDING"

        business_model = $null

        commercial_proof = @()
        commercial_proof_level = "NONE"

        traction_signal = $null
        growth_signal = $null
        revenue_signal = $null
        external_validation = $null

        replication_cost = $null
        automation_score = $null
        replication_score = $null
        market_fit_score = $null

        confidence = 0
    }
}

$results |
    ConvertTo-Json -Depth 10 |
    Set-Content .\validation_queue.json -Encoding UTF8

Write-Host ""
Write-Host "VALIDATION QUEUE : $($results.Count)"
Write-Host ""

$results |
    Select-Object name,validation_status,commercial_proof_level,confidence |
    Format-Table -AutoSize
