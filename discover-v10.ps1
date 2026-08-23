$pages = Get-Content ".\pages_full.json" -Raw | ConvertFrom-Json
$results = @()

foreach ($page in $pages) {

    if (-not $page.content) { continue }

    $text = ([string]$page.content) -replace '\s+', ' '

    # Découpage en phrases
    $sentences = $text -split '(?<=[.!?])\s+'

    $evidence = @()

    foreach ($sentence in $sentences) {

        $s = $sentence.Trim()

        if ($s.Length -lt 10 -or $s.Length -gt 500) {
            continue
        }

        # Une phrase intéressante contient à la fois
        # un nombre et un signal business.
        $hasNumber = $s -match '(?i)(\$|€|£|\d[\d,.]*\s?(k|m|million|thousand|million)?\b)'
        
        $hasBusiness = $s -match '(?i)\b(
            revenue|
            sales|
            customers?|
            users?|
            subscribers?|
            members?|
            bookings?|
            orders?|
            downloads?|
            paying|
            paid|
            pricing|
            priced|
            subscription|
            monthly|
            annual|
            per month|
            per year|
            profit|
            funding|
            raised|
            investment|
            valuation|
            growth|
            grew|
            sold
        )\b'

        if ($hasNumber -and $hasBusiness) {
            $evidence += $s
        }
    }

    $evidence = @(
        $evidence |
        Select-Object -Unique |
        Select-Object -First 5
    )

    if ($evidence.Count -eq 0) {
        continue
    }

    # Identifier grossièrement le modèle
    $model = "Other"

    if ($text -match '(?i)\b(rental|rent|lease|sharing)\b') {
        $model = "Rental / Sharing"
    }
    elseif ($text -match '(?i)\bmarketplace\b') {
        $model = "Marketplace"
    }
    elseif ($text -match '(?i)\b(course|bootcamp|training|classes|education)\b') {
        $model = "Education"
    }
    elseif ($text -match '(?i)\b(agency|consulting|service business)\b') {
        $model = "Service"
    }
    elseif ($text -match '(?i)\b(store|shop|ecommerce|e-commerce|physical product)\b') {
        $model = "Product / E-commerce"
    }
    elseif ($text -match '(?i)\b(restaurant|catering|food delivery|hotel)\b') {
        $model = "Food / Hospitality"
    }
    elseif ($text -match '(?i)\b(saas|software|api|developer tool)\b') {
        $model = "Software"
    }

    $score = 0

    $score += [Math]::Min($evidence.Count * 20, 60)

    if ($model -ne "Software") {
        $score += 20
    }

    if ($text -match '(?i)\b(solo|small team|one person|bootstrapped|without funding)\b') {
        $score += 10
    }

    $results += [PSCustomObject]@{
        name = $page.name
        url = $page.url
        source = $page.source
        score = $score
        model = $model
        evidence_count = $evidence.Count
        evidence = ($evidence -join " || ")
    }
}

$results = @(
    $results | Sort-Object score -Descending
)

$results |
    ConvertTo-Json -Depth 6 |
    Set-Content -Encoding UTF8 ".\business_radar_v10.json"

Write-Host ""
Write-Host "=========================================="
Write-Host "BUSINESS RADAR V10"
Write-Host "=========================================="
Write-Host ""
Write-Host "Candidats avec preuves : $($results.Count)"
Write-Host ""

$results |
    Select-Object -First 20 name,score,model,evidence_count |
    Format-Table -AutoSize

Write-Host ""
Write-Host "Résultats : business_radar_v10.json"
