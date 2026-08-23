$inputFile = ".\radar10_final_opportunities.json"
$sourceFile = ".\radar9_1_clusters.json"
$outputFile = ".\radar11_opportunities_enriched.json"

$data = Get-Content $inputFile -Raw | ConvertFrom-Json
$source = Get-Content $sourceFile -Raw | ConvertFrom-Json

$results = foreach ($item in $data) {

    # Cherche le cluster correspondant
    $match = $source | Where-Object {
        $_.business_model -eq $item.business_model -and
        $_.vertical -eq $item.vertical
    } | Select-Object -First 1

    $demand = 0
    $replication = [int]$item.replication
    $companyCount = [int]$item.company_count
    $countryCount = [int]$item.country_count

    if ($match) {
        $demand = [int]$match.avg_demand

        if ($replication -eq 0) {
            $replication = [int]$match.avg_replication
        }

        if ($companyCount -eq 0) {
            $companyCount = [int]$match.company_count
        }

        if ($countryCount -eq 0) {
            $countryCount = [int]$match.country_count
        }
    }

    [PSCustomObject]@{
        opportunity = $item.opportunity
        description = $item.description
        why_now = $item.why_now
        launch_strategy = $item.launch_strategy
        target_customer = $item.target_customer
        difficulty = $item.difficulty

        score = [int]$item.score
        verdict = $item.verdict
        confidence = [int]$item.confidence

        company_count = $companyCount
        country_count = $countryCount
        replication = $replication
        demand = $demand

        business_model = $item.business_model
        vertical = $item.vertical
    }
}

$results |
    Sort-Object score -Descending |
    ConvertTo-Json -Depth 10 |
    Set-Content $outputFile -Encoding UTF8

Write-Host ""
Write-Host "========================================"
Write-Host " BiznessHunter - Radar 11 FIX"
Write-Host "========================================"
Write-Host ""
Write-Host "Opportunities : $($results.Count)"
Write-Host ""

$results |
    Select-Object score,opportunity,company_count,country_count,replication,demand |
    Format-Table -AutoSize
