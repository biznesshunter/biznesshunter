$data = Get-Content .\radar52_raw_market_data.json -Raw |
    ConvertFrom-Json

$results = foreach ($item in @($data)) {

    $demand = if ($item.demand_count) {
        [double]$item.demand_count
    } else { 0 }

    $supply = if ($item.supply_count) {
        [double]$item.supply_count
    } else { 0 }

    $prices = @($item.prices | Where-Object {
        $_ -is [int] -or $_ -is [double] -or $_ -is [decimal]
    })

    $medianPrice = $null

    if ($prices.Count -gt 0) {
        $sorted = $prices | Sort-Object
        $middle = [math]::Floor($sorted.Count / 2)

        if ($sorted.Count % 2 -eq 0) {
            $medianPrice = (
                $sorted[$middle - 1] +
                $sorted[$middle]
            ) / 2
        }
        else {
            $medianPrice = $sorted[$middle]
        }
    }

    $ratio = $null

    if ($demand -gt 0 -and $supply -gt 0) {
        $ratio = [math]::Round(
            $demand / $supply,
            3
        )
    }

    # -----------------------------
    # DEMAND SCORE / 30
    # -----------------------------

    if ($demand -ge 500) {
        $demandScore = 30
    }
    elseif ($demand -ge 250) {
        $demandScore = 25
    }
    elseif ($demand -ge 100) {
        $demandScore = 20
    }
    elseif ($demand -ge 50) {
        $demandScore = 15
    }
    elseif ($demand -gt 0) {
        $demandScore = 8
    }
    else {
        $demandScore = 0
    }

    # -----------------------------
    # COMPETITION SCORE / 30
    # Plus le ratio demande/offre
    # est élevé, mieux c'est.
    # -----------------------------

    if ($ratio -ge 2) {
        $competitionScore = 30
    }
    elseif ($ratio -ge 1) {
        $competitionScore = 24
    }
    elseif ($ratio -ge 0.5) {
        $competitionScore = 18
    }
    elseif ($ratio -ge 0.25) {
        $competitionScore = 10
    }
    elseif ($ratio -gt 0) {
        $competitionScore = 5
    }
    else {
        $competitionScore = 0
    }

    # -----------------------------
    # PRICE SCORE / 20
    # -----------------------------

    if ($medianPrice -ge 40) {
        $priceScore = 20
    }
    elseif ($medianPrice -ge 30) {
        $priceScore = 16
    }
    elseif ($medianPrice -ge 20) {
        $priceScore = 12
    }
    elseif ($medianPrice -ge 10) {
        $priceScore = 8
    }
    elseif ($medianPrice -gt 0) {
        $priceScore = 4
    }
    else {
        $priceScore = 0
    }

    # -----------------------------
    # DATA QUALITY / 20
    # -----------------------------

    $qualitySignals = 0

    if ($demand -gt 0) { $qualitySignals++ }
    if ($supply -gt 0) { $qualitySignals++ }
    if ($prices.Count -ge 5) { $qualitySignals++ }
    if ($item.url) { $qualitySignals++ }

    $qualityScore = switch ($qualitySignals) {
        4 { 20 }
        3 { 15 }
        2 { 10 }
        1 { 5 }
        default { 0 }
    }

    $score =
        $demandScore +
        $competitionScore +
        $priceScore +
        $qualityScore

    if ($score -ge 75) {
        $verdict = "STRONG"
    }
    elseif ($score -ge 55) {
        $verdict = "VALIDATE"
    }
    elseif ($score -ge 35) {
        $verdict = "WATCH"
    }
    else {
        $verdict = "REJECT"
    }

    [PSCustomObject]@{
        idea_name          = $item.idea_name
        country            = $item.country
        city               = $item.city
        source             = $item.source

        demand             = $demand
        supply             = $supply
        demand_supply_ratio = $ratio

        median_price       = $medianPrice
        price_samples      = $prices.Count

        demand_score       = $demandScore
        competition_score  = $competitionScore
        price_score        = $priceScore
        quality_score      = $qualityScore

        total_score        = $score
        verdict             = $verdict

        source_url         = $item.url
        scraped_at         = $item.scraped_at
    }
}

$results |
    Sort-Object total_score -Descending |
    ConvertTo-Json -Depth 10 |
    Set-Content .\radar53_scored_opportunities.json -Encoding UTF8

Write-Host ""
Write-Host "SCORED RECORDS :" @($results).Count
Write-Host "OUTPUT         : radar53_scored_opportunities.json"
Write-Host ""

$results |
    Sort-Object total_score -Descending |
    Format-Table `
        city,
        source,
        demand,
        supply,
        demand_supply_ratio,
        median_price,
        total_score,
        verdict `
        -AutoSize
