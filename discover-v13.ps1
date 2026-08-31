$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=========================================="
Write-Host "BUSINESS RADAR V13"
Write-Host "=========================================="
Write-Host ""

$pages = Get-Content ".\pages_full.json" -Raw | ConvertFrom-Json
$results = @()

# ============================================================
# TRACTION
# ============================================================

$tractionPatterns = @(
    '(?i)\b\d[\d,.]*\s*(million|m|k|thousand)?\s*(customers|users|subscribers|members|clients)\b',
    '(?i)\b\d[\d,.]*\s*(million|m|k|thousand)?\s*(downloads|orders|bookings|transactions|sales)\b',
    '(?i)\b\d[\d,.]*\s*(active|paying)\s*(users|customers|members|subscribers)\b',
    '(?i)\b(over|more than|above)\s+\d[\d,.]*\s*(customers|users|downloads|orders|bookings)\b',
    '(?i)\bused by\s+\d[\d,.]*\b',
    '(?i)\bserves\s+\d[\d,.]*\s*(customers|users|clients|businesses)\b',
    '(?i)\b\d[\d,.]*\s*(people|companies|businesses)\s+(use|using|have used)\b',
    '(?i)\b\d[\d,.]*\s*(users|customers|members|subscribers)\s+(use|using|pay|paying)\b'
)

# ============================================================
# MONETISATION
# ============================================================

$monetizationPatterns = @(
    '(?i)(\$|€|£)\s?\d[\d,.]*\s*(once|one[- ]time|month|monthly|year|annual|per month|per year)',
    '(?i)\b\d[\d,.]*\s*(USD|EUR|GBP)\s*(once|monthly|annually|per month|per year)\b',
    '(?i)\b(price|pricing|priced)\b.{0,80}(\$|€|£)\s?\d',
    '(?i)\b(subscription|subscriptions)\b.{0,80}(\$|€|£)\s?\d',
    '(?i)\b(paid|paying)\s+(customers|users|members|subscribers)\b',
    '(?i)\b(revenue|sales|arr|mrr)\b',
    '(?i)\b(generated|made|earned|reached|hit)\b.{0,50}(\$|€|£)\s?\d',
    '(?i)(\$|€|£)\s?\d[\d,.]*\s*(million|m|k)?\s*(revenue|sales|arr|mrr)',
    '(?i)\bfree\s+and\s+(paid|premium)\b',
    '(?i)\b(freemium|premium plan|pro plan|paid plan)\b'
)

# ============================================================
# PRODUIT / BUSINESS
# ============================================================

$productPatterns = @(
    '(?i)\btool\b',
    '(?i)\bsoftware\b',
    '(?i)\bapp\b',
    '(?i)\bplatform\b',
    '(?i)\bservice\b',
    '(?i)\bproduct\b',
    '(?i)\bmarketplace\b',
    '(?i)\bsubscription\b',
    '(?i)\bsaas\b',
    '(?i)\bapi\b',
    '(?i)\bcourse\b',
    '(?i)\bstore\b',
    '(?i)\bshop\b',
    '(?i)\bextension\b',
    '(?i)\bplugin\b',
    '(?i)\bwebsite\b',
    '(?i)\bonline\b'
)

# ============================================================
# MODELES ECONOMIQUES
# ============================================================

$modelPatterns = [ordered]@{
    "Software / AI" = '(?i)\b(saas|software|api|app|platform|ai tool|developer tool|video editor|nle|extension|plugin|online tool|online tools|web tool|web tools|utility|utilities|generator|generators|converter|converters|calculator|calculators|formatter|formatters|validator|validators|decoder|decoders|encoder|encoders|builder|builders|checker|checkers)\b'
    "Marketplace" = '(?i)\b(marketplace|peer-to-peer|buyers and sellers|connects buyers|connects sellers)\b'
    "Rental / Sharing" = '(?i)\b(rent|rental|renting|lease|leasing|shared|sharing|borrow)\b'
    "Local Service" = '(?i)\b(cleaning|repair|maintenance|installation|moving|gardening|plumbing|car wash|home service|delivery service)\b'
    "Education" = '(?i)\b(course|courses|training|bootcamp|classes|tutoring|education program|workshop)\b'
    "E-commerce / Product" = '(?i)\b(e-commerce|ecommerce|online store|online shop|physical product|consumer product|sold online)\b'
    "Food / Hospitality" = '(?i)\b(restaurant|food delivery|catering|hotel|hospitality|meal|cafe)\b'
    "Travel" = '(?i)\b(travel|tour|tours|trip|booking accommodation|vacation rental)\b'
    "Consumer Service" = '(?i)\b(fitness|beauty|pet care|dog walking|childcare|babysitting)\b'
    "Agency / Service" = '(?i)\b(agency|consulting|consultancy|service business|done-for-you)\b'
}

# ============================================================
# DIFFICULTE
# ============================================================

$hardPatterns = @(
    '(?i)\b(rocket|satellite|semiconductor|chip|nuclear|aircraft|biotech|clinical trial)\b',
    '(?i)\b(factory|manufacturing plant|laboratory|lab equipment)\b',
    '(?i)\b(defense contract|government contract)\b',
    '(?i)\b(hardware manufacturing|industrial production)\b'
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

    # ========================================================
    # PRIORITE SOFTWARE
    # ========================================================

    if ($models -contains "Software / AI") {

        $models = @(
            "Software / AI"
        )
    }

    if ($models.Count -eq 0) {

    Write-Host "MODELE : aucun"
    Write-Host "TRACTION : $($traction.Count)"
    Write-Host "MONETISATION : $($monetization.Count)"
    Write-Host "PRODUIT : $product_count"
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

    # TRACTION : 0-50
    if ($traction.Count -gt 0) {
        $score += [Math]::Min($traction.Count * 20, 50)
    }

    # MONETISATION : 0-20
    if ($monetization.Count -gt 0) {
        $score += [Math]::Min($monetization.Count * 10, 20)
    }

    # PRODUIT : 0-10
    if ($product_count -gt 0) {
        $score += 10
    }

    # MODELE : 10
    $score += 10

    # DIFFICULTE : 10
    if ($difficulty -eq "Low") {
        $score += 10
    }
    elseif ($difficulty -eq "Medium") {
        $score += 5
    }
    else {
        $score -= 10
    }

    # ========================================================
    # PLAFOND
    # ========================================================

    # Sans traction ni monétisation :
    # maximum 30.
    if ($traction.Count -eq 0 -and $monetization.Count -eq 0) {
        $score = [Math]::Min($score, 30)
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
    Set-Content -Encoding UTF8 ".\business_radar_v13.json"

# ============================================================
# RESULTAT FINAL
# ============================================================

Write-Host ""
Write-Host "=========================================="
Write-Host "RESULTAT FINAL V13"
Write-Host "=========================================="
Write-Host ""

Write-Host "CANDIDATS ANALYSES : $($results.Count)"
Write-Host ""

$results |
    Select-Object -First 20 name,score,type,model,difficulty,product_signal_count,traction_count,monetization_count |
    Format-Table -AutoSize

Write-Host ""
Write-Host "Résultats : business_radar_v13.json"






