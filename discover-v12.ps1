$ErrorActionPreference = "SilentlyContinue"

Write-Host ""
Write-Host "=========================================="
Write-Host "BUSINESS RADAR V12"
Write-Host "=========================================="
Write-Host ""

$pages = Get-Content ".\pages_full.json" -Raw | ConvertFrom-Json
$results = @()

# ============================================================
# PREUVES DE TRACTION
# ============================================================

$tractionPatterns = @(
    '(?i)\b\d[\d,.]*\s*(million|m|k|thousand)?\s*(customers|users|subscribers|members)\b',
    '(?i)\b\d[\d,.]*\s*(million|m|k|thousand)?\s*(orders|bookings|downloads|transactions|clients)\b',
    '(?i)\b\d[\d,.]*\s*(million|m|k|thousand)?\s*(views|visits|users|signups|installs)\b',
    '(?i)\b(more than|over|over\s+)\s*\d[\d,.]*\s*(customers|users|members|subscribers|downloads|orders)\b',
    '(?i)\b(revenue|sales|arr|mrr)\s+(of|reached|hit|grew|generated)\b',
    '(?i)\b(\$|€|£)\s?\d[\d,.]*\s*(million|m|k|thousand)?\s*(revenue|sales|arr|mrr)\b',
    '(?i)\b(sold|generated|made)\s+(\$|€|£)?\s?\d[\d,.]*\b',
    '(?i)\b(paying|paid)\s+(customers|users|members|subscribers)\b'
)

# ============================================================
# PREUVES DE MONETISATION
# ============================================================

$monetizationPatterns = @(
    '(?i)\(\s*(\$|€|£)\s?[\d,.]+\s+(once|month|year)\s*\)',
    '(?i)(\$|€|£)\s?[\d,.]+\s*/\s*(month|year|mo|yr)\b',
    '(?i)(\$|€|£)\s?[\d,.]+\s+(once|month|year)\b',
    '(?i)\b(price|pricing|plans?|subscription|subscriptions)\b.{0,100}(\$|€|£)\s?[\d,.]+',
    '(?i)\b(free|paid|premium|pro|business|enterprise)\s+(plan|tier|version)\b',
    '(?i)\b(buy|purchase|subscribe|upgrade)\b.{0,80}(\$|€|£)\s?[\d,.]+'
)

# ============================================================
# PREUVES DE PRODUIT
# ============================================================

$productPatterns = @(
    '(?i)\b(download|install|use|create|generate|edit|build|publish|upload|export)\b',
    '(?i)\b(tool|tools|software|app|application|platform|service|product)\b',
    '(?i)\b(available|launched|launch|release|released|live)\b',
    '(?i)\b(version|v\d+|beta|public beta|open beta)\b',
    '(?i)\b(users?|customers?|members?|agents?)\b',
    '(?i)\bAPI\b',
    '(?i)\bwebsite\b'
)

# ============================================================
# MODELES ECONOMIQUES
# ============================================================

$modelPatterns = [ordered]@{

    "Software / AI" = '(?i)\b(saas|software|api|app|application|platform|ai tool|developer tool|video editor|nle|online tool|web app)\b'

    "Marketplace" = '(?i)\b(marketplace|peer-to-peer|buyers and sellers|connects buyers|connects sellers)\b'

    "Local Service" = '(?i)\b(cleaning|repair|maintenance|installation|moving|gardening|plumbing|car wash|home service|delivery service)\b'

    "Education" = '(?i)\b(course|courses|training|bootcamp|classes|tutoring|education program|workshop)\b'

    "E-commerce / Product" = '(?i)\b(e-commerce|ecommerce|online store|online shop|physical product|consumer product|product)\b'

    "Food / Hospitality" = '(?i)\b(restaurant|food delivery|catering|hotel|hospitality|meal|cafe)\b'

    "Travel" = '(?i)\b(travel|tour|tours|trip|booking accommodation|vacation rental)\b'

    "Consumer Service" = '(?i)\b(fitness|beauty|pet care|dog walking|childcare|babysitting)\b'

    "Agency / Service" = '(?i)\b(agency|consulting|consultancy|service business|done-for-you)\b'

    "Rental / Sharing" = '(?i)\b(rent|rental|renting|lease|leasing|shared|sharing|borrow)\b'
}

# ============================================================
# DIFFICULTE
# ============================================================

$hardPatterns = @(
    '(?i)\b(rocket|satellite|semiconductor|chip|nuclear|aircraft|biotech|clinical trial)\b',
    '(?i)\b(factory|manufacturing plant|laboratory|lab equipment)\b',
    '(?i)\b(defense contract|government contract)\b'
)

# ============================================================
# ANALYSE
# ============================================================

foreach ($page in $pages) {

    if (-not $page.content) {
        continue
    }

    $combined = "$($page.name) $($page.content)"
    $clean = $combined -replace '\s+', ' '

    Write-Host ""
    Write-Host "------------------------------------------"
    Write-Host $page.name
    Write-Host "------------------------------------------"

    # ========================================================
    # TRACTION
    # ========================================================

    $traction = @()

    foreach ($pattern in $tractionPatterns) {

        $matches = [regex]::Matches(
            $clean,
            $pattern,
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        )

        foreach ($match in $matches) {

            $value = $match.Value.Trim()

            if ($value.Length -gt 5 -and $value.Length -lt 180) {
                $traction += $value
            }
        }
    }

    $traction = @(
        $traction |
        Select-Object -Unique |
        Select-Object -First 5
    )

    # ========================================================
    # MONETISATION
    # ========================================================

    $monetization = @()

    foreach ($pattern in $monetizationPatterns) {

        $matches = [regex]::Matches(
            $clean,
            $pattern,
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        )

        foreach ($match in $matches) {

            $value = $match.Value.Trim()

            if ($value.Length -gt 3 -and $value.Length -lt 180) {
                $monetization += $value
            }
        }
    }

    $monetization = @(
        $monetization |
        Select-Object -Unique |
        Select-Object -First 5
    )

    # ========================================================
    # PRODUIT
    # ========================================================

    $product = @()

    foreach ($pattern in $productPatterns) {

        if ($clean -match $pattern) {

            $product += $pattern
        }
    }

    $product_count = $product.Count

    # ========================================================
    # MODELE
    # ========================================================

    $models = @()

    foreach ($entry in $modelPatterns.GetEnumerator()) {

        if ($clean -match $entry.Value) {
            $models += $entry.Key
        }
    }

    $models = @(
        $models |
        Select-Object -Unique
    )

    if ($models.Count -eq 0) {

        Write-Host "MODELE : aucun"
        Write-Host "TRACTION : $($traction.Count)"
        Write-Host "MONETISATION : $($monetization.Count)"
        Write-Host "PRODUIT : $product_count"

        continue
    }

    # Priorité au logiciel lorsqu'il est clairement identifié

    if ($models -contains "Software / AI") {

        $models = @(
            "Software / AI"
        )
    }

    if ($models -contains "Software / AI") {
        $type = "Software"
    }
    else {
        $type = "Non-software"
    }

    # ========================================================
    # DIFFICULTE
    # ========================================================

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

    # ========================================================
    # SCORE V12
    # ========================================================

    $score = 0

    # --------------------------------------------------------
    # TRACTION
    # --------------------------------------------------------

    if ($traction.Count -gt 0) {

        $score += [Math]::Min($traction.Count * 20, 50)
    }

    # --------------------------------------------------------
    # MONETISATION
    # --------------------------------------------------------

    if ($monetization.Count -gt 0) {

        $score += [Math]::Min($monetization.Count * 10, 20)
    }

    # --------------------------------------------------------
    # PRODUIT
    # --------------------------------------------------------

    if ($product_count -gt 0) {

        $score += 10
    }

    # --------------------------------------------------------
    # MODELE
    # --------------------------------------------------------

    $score += 10

    # --------------------------------------------------------
    # SIMPLICITE
    # --------------------------------------------------------

    if ($difficulty -eq "Low") {

        $score += 10
    }
    elseif ($difficulty -eq "Medium") {

        $score += 5
    }
    else {

        $score -= 10
    }

    # --------------------------------------------------------
    # PLAFOND
    # --------------------------------------------------------

    # Pas de traction ET pas de monétisation :
    # on ne veut pas présenter cela comme une opportunité forte.

    if ($traction.Count -eq 0 -and $monetization.Count -eq 0) {

        $score = [Math]::Min($score, 40)
    }

    # ========================================================
    # AFFICHAGE
    # ========================================================

    Write-Host "TRACTION : $($traction.Count)"

    if ($traction.Count -gt 0) {
        Write-Host "  $($traction -join ' || ')"
    }

    Write-Host "MONETISATION : $($monetization.Count)"

    if ($monetization.Count -gt 0) {
        Write-Host "  $($monetization -join ' || ')"
    }

    Write-Host "PRODUIT : $product_count"
    Write-Host "MODELE : $($models -join ', ')"
    Write-Host "TYPE : $type"
    Write-Host "DIFFICULTE : $difficulty"
    Write-Host "SCORE : $score"

    # ========================================================
    # RESULTAT
    # ========================================================

    $results += [PSCustomObject]@{

        name = $page.name

        url = $page.url

        source = $page.source

        score = $score

        type = $type

        model = ($models -join ", ")

        difficulty = $difficulty

        product_signal_count = $product_count

        traction_count = $traction.Count

        traction = ($traction -join " || ")

        monetization_count = $monetization.Count

        monetization = ($monetization -join " || ")
    }
}

# ============================================================
# TRI
# ============================================================

$results = @(
    $results |
    Sort-Object score -Descending
)

# ============================================================
# SAUVEGARDE
# ============================================================

$results |
    ConvertTo-Json -Depth 6 |
    Set-Content -Encoding UTF8 ".\business_radar_v12.json"

# ============================================================
# RESULTAT FINAL
# ============================================================

Write-Host ""
Write-Host "=========================================="
Write-Host "RESULTAT FINAL V12"
Write-Host "=========================================="
Write-Host ""

Write-Host "CANDIDATS ANALYSES : $($results.Count)"
Write-Host ""

$results |
    Select-Object -First 20 name,score,type,model,difficulty,product_signal_count,traction_count,monetization_count |
    Format-Table -AutoSize

Write-Host ""
Write-Host "Résultats : business_radar_v12.json"
