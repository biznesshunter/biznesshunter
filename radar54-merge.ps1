# TEST
$markets = Get-Content .\radar52_raw_market_data.json -Raw | ConvertFrom-Json
$groups = $markets | Group-Object idea_name, country, city

$results = foreach ($group in $groups) {

    $items = @($group.Group)
    $first = $items[0]

    $allovoisins = $items | Where-Object source -eq "allovoisins" | Select-Object -First 1
    $bricolib = $items | Where-Object source -eq "bricolib" | Select-Object -First 1

    $demand = if ($allovoisins.demand_count) { [double]$allovoisins.demand_count } else { 0 }
    $supply = if ($bricolib.supply_count) { [double]$bricolib.supply_count } else { 0 }

    if ($demand -ge 500) { $demandScore = 30 }
    elseif ($demand -ge 250) { $demandScore = 25 }
    elseif ($demand -ge 100) { $demandScore = 20 }
    elseif ($demand -ge 50) { $demandScore = 15 }
    elseif ($demand -gt 0) { $demandScore = 8 }
    else { $demandScore = 0 }

    if ($demand -gt 0 -and $supply -gt 0) {
        $ratio = [math]::Round($demand / $supply, 3)
    } else {
        $ratio = $null
    }

    if ($ratio -ge 2) { $gapScore = 35 }
    elseif ($ratio -ge 1.5) { $gapScore = 32 }
    elseif ($ratio -ge 1) { $gapScore = 28 }
    elseif ($ratio -ge 0.75) { $gapScore = 20 }
    elseif ($ratio -ge 0.5) { $gapScore = 12 }
    elseif ($ratio -gt 0) { $gapScore = 5 }
    else { $gapScore = 0 }

    $prices = @()
    foreach ($item in $items) {
        if ($item.prices) {
            $prices += @($item.prices | Where-Object {
                $_ -is [int] -or $_ -is [double] -or $_ -is [decimal]
            })
        }
    }

    $medianPrice = $null

    if ($prices.Count -gt 0) {
        $sorted = $prices | Sort-Object
        $middle = [math]::Floor($sorted.Count / 2)

        if ($sorted.Count % 2 -eq 0) {
            $medianPrice = ($sorted[$middle - 1] + $sorted[$middle]) / 2
        } else {
            $medianPrice = $sorted[$middle]
        }
    }

    if ($medianPrice -ge 40) { $priceScore = 20 }
    elseif ($medianPrice -ge 30) { $priceScore = 16 }
    elseif ($medianPrice -ge 20) { $priceScore = 12 }
    elseif ($medianPrice -ge 10) { $priceScore = 8 }
    elseif ($medianPrice -gt 0) { $priceScore = 4 }
    else { $priceScore = 0 }

    $qualitySignals = 0
    if ($demand -gt 0) { $qualitySignals++ }
    if ($supply -gt 0) { $qualitySignals++ }
    if ($prices.Count -ge 5) { $qualitySignals++ }
    if ($items.Count -ge 2) { $qualitySignals++ }

    $qualityScore = switch ($qualitySignals) {
        4 { 15 }
        3 { 11 }
        2 { 7 }
        1 { 3 }
        default { 0 }
    }

    $score = $demandScore + $gapScore + $priceScore + $qualityScore

    if ($score -ge 75) { $verdict = "STRONG" }
    elseif ($score -ge 55) { $verdict = "VALIDATE" }
    elseif ($score -ge 35) { $verdict = "WATCH" }
    else { $verdict = "REJECT" }

    [PSCustomObject]@{
        idea_name = $first.idea_name
        country = $first.country
        city = $first.city
        demand = $demand
        supply = $supply
        demand_supply_ratio = $ratio
        median_price = $medianPrice
        price_samples = $prices.Count
        demand_score = $demandScore
        gap_score = $gapScore
        price_score = $priceScore
        quality_score = $qualityScore
        total_score = $score
        verdict = $verdict
        sources = @($items.source)
    }
}

$results |
    Sort-Object total_score -Descending |
    ConvertTo-Json -Depth 10 |
    Set-Content .\radar54_market_opportunities.json -Encoding UTF8

Write-Host ""
Write-Host "MARKETS MERGED :" @($results).Count
Write-Host ""

$results |
    Sort-Object total_score -Descending |
    Format-Table city,demand,supply,demand_supply_ratio,median_price,total_score,verdict -AutoSize
