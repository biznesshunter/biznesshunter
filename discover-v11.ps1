$ErrorActionPreference = "SilentlyContinue"

Write-Host ""
Write-Host "=========================================="
Write-Host "BUSINESS RADAR V11"
Write-Host "=========================================="
Write-Host ""

$pages = Get-Content ".\pages_full.json" -Raw | ConvertFrom-Json
$results = @()

# ============================================================
# 1. VRAIES PREUVES DE TRACTION COMMERCIALE
# ============================================================

$tractionPatterns = @(
    '(?i)\d[\d,.]*\s?(million|m|k|thousand)?\s+(customers|users|subscribers|members)',
    '(?i)\d[\d,.]*\s+(orders|bookings|downloads|transactions|clients)',
    '(?i)(\$|€|£)\s?\d[\d,.]*\s?(million|m|k|thousand)?\s+(in\s+)?(revenue|sales|arr|mrr)',
    '(?i)(revenue|sales|arr|mrr)\s+(of|reached|hit|grew|generated)',
    '(?i)(sold|generated|made)\s+(\$|€|£)?\s?\d[\d,.]*',
    '(?i)(paying|paid)\s+(customers|users|members|subscribers)',
    '(?i)(customers|users|members|subscribers).{0,80}(pay|paid|revenue)',
    '(?i)(monthly|annual)\s+(revenue|sales|subscription)',
    '(?i)(booked|booking).{0,60}(\$|€|£|\d)'
)

# ============================================================
# 2. SIGNAUX COMMERCIAUX
# ============================================================

$commercialPatterns = @(
    '(?i)\(\$[\d,.]+\s+(once|month|year)\)',
    '(?i)\(\€[\d,.]+\s+(once|month|year)\)',
    '(?i)\(\£[\d,.]+\s+(once|month|year)\)',
    '(?i)(price|pricing).{0,80}(\$|€|£)\s?\d',
    '(?i)(subscription|subscribe|paid plan|premium plan)',
    '(?i)(pro plan|business plan|enterprise plan)'
)

# ============================================================
# 3. MODELES ECONOMIQUES
# ============================================================

$modelPatterns = [ordered]@{

    "Software / AI" = '(?i)\b(software|saas|api|app|platform|ai tool|developer tool|video editor|nle|online tool|web app)\b'

    "Marketplace" = '(?i)\b(marketplace|peer-to-peer|buyers and sellers|connects buyers|connects sellers)\b'

    "Rental / Sharing" = '(?i)\b(rent|rental|renting|lease|leasing|shared|sharing|borrow)\b'

    "Local Service" = '(?i)\b(cleaning|repair|maintenance|installation|moving|gardening|plumbing|car wash|home service|delivery service)\b'

    "Education" = '(?i)\b(course|courses|training|bootcamp|classes|tutoring|education program|workshop)\b'

    "E-commerce / Product" = '(?i)\b(store|shop|e-commerce|ecommerce|sold online|physical product|consumer product)\b'

    "Food / Hospitality" = '(?i)\b(restaurant|food delivery|catering|hotel|hospitality|meal|cafe)\b'

    "Travel" = '(?i)\b(travel|tour|tours|trip|booking accommodation|vacation rental)\b'

    "Consumer Service" = '(?i)\b(fitness|beauty|pet care|dog walking|childcare|babysitting)\b'

    "Agency / Service" = '(?i)\b(agency|consulting|consultancy|service business|done-for-you)\b'
}

# ============================================================
# 4. DIFFICULTE
# ============================================================

$hardPatterns = @(
    '(?i)\b(rocket|satellite|semiconductor|chip|nuclear|aircraft|biotech|clinical trial)\b',
    '(?i)\b(factory|manufacturing plant|laboratory|lab equipment)\b',
    '(?i)\b(defense contract|government contract)\b',
    '(?i)\b(million.{0,20}(funding|investment|raised))\b'
)

# ============================================================
# 5. ANALYSE
# ============================================================

foreach ($page in $pages) {

    if (-not $page.content) {
        continue
    }

    # IMPORTANT :
    # titre + contenu
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
    # SIGNAUX COMMERCIAUX
    # ========================================================

    $commercial = @()

    foreach ($pattern in $commercialPatterns) {

        $matches = [regex]::Matches(
            $clean,
            $pattern,
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        )

        foreach ($match in $matches) {

            $value = $match.Value.Trim()

            if ($value.Length -gt 3 -and $value.Length -lt 180) {
                $commercial += $value
            }
        }
    }

    $commercial = @(
        $commercial |
        Select-Object -Unique |
        Select-Object -First 5
    )

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

    # ========================================================
    # PRIORITE SOFTWARE
    # ========================================================

    # Si un logiciel est clairement identifié,
    # on ne le transforme PAS en e-commerce simplement
    # parce que le mot "product" apparaît.

    if ($models -contains "Software / AI") {

        $models = @(
            "Software / AI"
        )
    }

    if ($models.Count -eq 0) {

        Write-Host "MODELE : aucun"
        continue
    }

    # ========================================================
    # TYPE
    # ========================================================

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
    # SCORE
    # ========================================================

    $score = 0

    # --------------------------------------------------------
    # TRACTION
    # --------------------------------------------------------

    if ($traction.Count -gt 0) {

        $score += [Math]::Min($traction.Count * 20, 60)
    }

    # --------------------------------------------------------
    # MODELE
    # --------------------------------------------------------

    $score += 10

    # --------------------------------------------------------
    # SIMPLICITE
    # --------------------------------------------------------

    if ($difficulty -eq "Low") {

        $score += 15
    }
    elseif ($difficulty -eq "Medium") {

        $score += 7
    }
    else {

        $score -= 15
    }

    # --------------------------------------------------------
    # SIGNAL COMMERCIAL
    # --------------------------------------------------------

    if ($commercial.Count -gt 0) {

        $score += 5
    }

    # --------------------------------------------------------
    # PLAFOND SI AUCUNE TRACTION
    # --------------------------------------------------------

    # Un prix seul ne peut jamais produire
    # une opportunité "forte".

    if ($traction.Count -eq 0) {

        $score = [Math]::Min($score, 30)
    }

    # ========================================================
    # AFFICHAGE
    # ========================================================

    Write-Host "TRACTION : $($traction.Count)"

    if ($traction.Count -gt 0) {
        Write-Host "  $($traction -join ' || ')"
    }

    Write-Host "COMMERCIAL : $($commercial.Count)"

    if ($commercial.Count -gt 0) {
        Write-Host "  $($commercial -join ' || ')"
    }

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

        traction_count = $traction.Count

        traction = ($traction -join " || ")

        commercial_signal_count = $commercial.Count

        commercial_signals = ($commercial -join " || ")
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
    Set-Content -Encoding UTF8 ".\business_radar_v11.json"

# ============================================================
# RESULTAT FINAL
# ============================================================

Write-Host ""
Write-Host "=========================================="
Write-Host "RESULTAT FINAL V11"
Write-Host "=========================================="
Write-Host ""

Write-Host "CANDIDATS ANALYSES : $($results.Count)"
Write-Host ""

$results |
    Select-Object -First 20 name,score,type,model,difficulty,traction_count |
    Format-Table -AutoSize

Write-Host ""
Write-Host "Résultats : business_radar_v11.json"
