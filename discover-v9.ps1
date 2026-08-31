$ErrorActionPreference = "SilentlyContinue"

Write-Host ""
Write-Host "=========================================="
Write-Host "BUSINESS RADAR V9"
Write-Host "=========================================="
Write-Host ""

$pages = Get-Content ".\pages_full.json" -Raw | ConvertFrom-Json
$results = @()

# Expressions indiquant une vraie preuve commerciale
$proofPatterns = @(
    '(?i)(\$|€|£)\s?\d[\d,.]*\s?(million|m|k|thousand)?\s?(in\s+)?(revenue|sales|arr|mrr)',
    '(?i)\d[\d,.]*\s?(million|m|k|thousand)?\s?(customers|users|subscribers|members)',
    '(?i)\d[\d,.]*\s?(orders|bookings|downloads|transactions|clients)',
    '(?i)(revenue|sales|arr|mrr)\s+(of|reached|hit|grew|generated)',
    '(?i)(sold|generated|made)\s+(\$|€|£)?\s?\d[\d,.]*',
    '(?i)(paying|paid)\s+(customers|users|members|subscribers)',
    '(?i)(customers|users|members|subscribers).{0,80}(pay|paid|revenue)',
    '(?i)(price|pricing).{0,80}(\$|€|£)\s?\d',
    '(?i)(monthly|annual)\s+(revenue|sales|subscription)',
    '(?i)(booked|booking).{0,60}(\$|€|£|\d)'
)

# Business models réels
$modelPatterns = [ordered]@{
    "Rental / Sharing" = '(?i)\b(rent|rental|renting|lease|leasing|shared|sharing|borrow)\b'
    "Marketplace" = '(?i)\b(marketplace|peer-to-peer|buyers and sellers|connects buyers|connects sellers)\b'
    "Local Service" = '(?i)\b(cleaning|repair|maintenance|installation|moving|gardening|plumbing|car wash|home service|delivery service)\b'
    "Education" = '(?i)\b(course|courses|training|bootcamp|classes|tutoring|education program|workshop)\b'
    "E-commerce / Product" = '(?i)\b(product|store|shop|e-commerce|ecommerce|sold online|physical product|consumer product)\b'
    "Food / Hospitality" = '(?i)\b(restaurant|food delivery|catering|hotel|hospitality|meal|cafe)\b'
    "Travel" = '(?i)\b(travel|tour|tours|trip|booking accommodation|vacation rental)\b'
    "Consumer Service" = '(?i)\b(fitness|beauty|pet care|dog walking|childcare|babysitting)\b'
    "Agency / Service" = '(?i)\b(agency|consulting|consultancy|service business|done-for-you)\b'
    "Software / AI" = '(?i)\b(saas|software|api|app|platform|ai tool|developer tool)\b'
}

# Signaux qui rendent la copie difficile
$hardPatterns = @(
    '(?i)\b(rocket|satellite|semiconductor|chip|nuclear|aircraft|biotech|clinical trial)\b',
    '(?i)\b(factory|manufacturing plant|laboratory|lab equipment)\b',
    '(?i)\b(defense contract|government contract)\b',
    '(?i)\b(million.{0,20}(funding|investment|raised))\b'
)

foreach ($page in $pages) {

    if (-not $page.content) {
        continue
    }

    $combined = "$($page.name) $($page.content)"`r`n    $clean = $combined -replace '\s+', ' '

    # --------------------------------------------
    # PREUVES
    # --------------------------------------------

    $proofs = @()

    foreach ($pattern in $proofPatterns) {

        $matches = [regex]::Matches(
            $clean,
            $pattern,
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        )

        foreach ($match in $matches) {

            $proof = $match.Value.Trim()

            if ($proof.Length -gt 5 -and $proof.Length -lt 180) {
                $proofs += $proof
            }
        }
    }

    $proofs = @(
        $proofs |
        Select-Object -Unique |
        Select-Object -First 5
    )

    # Aucune preuve = pas d'opportunité
    if ($proofs.Count -eq 0) {
        continue
    }

    # --------------------------------------------
    # MODELE
    # --------------------------------------------

    $models = @()

    foreach ($entry in $modelPatterns.GetEnumerator()) {

        if ($clean -match $entry.Value) {
            $models += $entry.Key
        }
    }

    $models = @($models | Select-Object -Unique)

    if ($models.Count -eq 0) {
        continue
    }

    # --------------------------------------------
    # TYPE
    # --------------------------------------------

    if ($models -contains "Software / AI" -and $models.Count -eq 1) {
        $type = "Software"
    }
    else {
        $type = "Non-software"
    }

    # --------------------------------------------
    # DIFFICULTE
    # --------------------------------------------

    $hardHits = @()

    foreach ($pattern in $hardPatterns) {

        if ($clean -match $pattern) {
            $hardHits += $pattern
        }
    }

    if ($hardHits.Count -eq 0) {
        $difficulty = "Low"
    }
    elseif ($hardHits.Count -eq 1) {
        $difficulty = "Medium"
    }
    else {
        $difficulty = "High"
    }

    # --------------------------------------------
    # SCORE
    # --------------------------------------------

    $score = 0

    # preuves
    $score += [Math]::Min($proofs.Count * 15, 45)

    # modèle économique
    $score += 15

    # non-software
    if ($type -eq "Non-software") {
        $score += 15
    }

    # simplicité
    if ($difficulty -eq "Low") {
        $score += 15
    }
    elseif ($difficulty -eq "Medium") {
        $score += 7
    }
    else {
        $score -= 15
    }

    # --------------------------------------------
    # RESULTAT
    # --------------------------------------------

    $results += [PSCustomObject]@{
        name = $page.name
        url = $page.url
        source = $page.source
        score = $score
        type = $type
        model = ($models -join ", ")
        difficulty = $difficulty
        evidence_count = $proofs.Count
        evidence = ($proofs -join " || ")
    }
}

$results = @(
    $results |
    Sort-Object score -Descending
)

$results |
    ConvertTo-Json -Depth 6 |
    Set-Content -Encoding UTF8 ".\business_radar_v9.json"

Write-Host ""
Write-Host "CANDIDATS AVEC PREUVES REELLES : $($results.Count)"
Write-Host ""

$results |
    Select-Object -First 20 name,score,type,model,difficulty,evidence_count |
    Format-Table -AutoSize

Write-Host ""
Write-Host "Résultats : business_radar_v9.json"


