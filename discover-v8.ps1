$ErrorActionPreference = "SilentlyContinue"

Write-Host ""
Write-Host "=========================================="
Write-Host "BUSINESS RADAR V8"
Write-Host "=========================================="
Write-Host ""

# ============================================================
# 1. Charger les pages déjà récupérées
# ============================================================

if (-not (Test-Path ".\pages_full.json")) {
    Write-Host "ERREUR : pages_full.json introuvable."
    exit
}

$pages = Get-Content ".\pages_full.json" -Raw | ConvertFrom-Json

$candidates = @()

# ============================================================
# 2. Signaux POSITIFS : existence d'un vrai business
# ============================================================

$businessSignals = @(
    "customers",
    "customer",
    "users",
    "revenue",
    "sales",
    "sold",
    "orders",
    "bookings",
    "subscribers",
    "subscription",
    "membership",
    "pricing",
    "price",
    "paid",
    "pay",
    "launched",
    "launch",
    "business",
    "company",
    "service",
    "marketplace",
    "rental",
    "rent",
    "booking",
    "delivery",
    "cleaning",
    "repair",
    "installation",
    "storage",
    "education",
    "course",
    "training",
    "fitness",
    "food",
    "restaurant",
    "hospitality",
    "travel",
    "pet",
    "childcare",
    "resale",
    "commerce",
    "store",
    "product",
    "equipment",
    "home",
    "vehicle",
    "creator",
    "agency",
    "franchise",
    "on-demand"
)

# ============================================================
# 3. Signaux de PREUVE
# ============================================================

$proofSignals = @(
    "revenue",
    "customers",
    "users",
    "sales",
    "orders",
    "subscribers",
    "mrr",
    "arr",
    "million",
    "thousand",
    "paid",
    "sold",
    "bookings",
    "gmv",
    "profit"
)

# ============================================================
# 4. Signaux de business NON-SOFTWARE
# ============================================================

$nonSoftwareSignals = @(
    "rental",
    "rent",
    "sharing",
    "marketplace",
    "booking",
    "delivery",
    "cleaning",
    "repair",
    "installation",
    "storage",
    "property",
    "real estate",
    "education",
    "training",
    "fitness",
    "food",
    "restaurant",
    "travel",
    "hospitality",
    "beauty",
    "pet",
    "childcare",
    "resale",
    "store",
    "shop",
    "product",
    "consumer",
    "home",
    "vehicle",
    "bike",
    "equipment",
    "event",
    "service",
    "agency",
    "franchise"
)

# ============================================================
# 5. Signaux indiquant que ce n'est PAS une opportunité
# ============================================================

$badSignals = @(
    "research paper",
    "research study",
    "scientific",
    "laboratory",
    "lab research",
    "arxiv",
    "physics",
    "chemistry",
    "biology",
    "medical research",
    "clinical trial",
    "chip architecture",
    "semiconductor",
    "satellite",
    "spacecraft",
    "rocket",
    "defense contract",
    "government contract",
    "tariff",
    "lawsuit",
    "investigation",
    "privacy lawsuit",
    "ai safety",
    "benchmark",
    "programming language",
    "operating system",
    "kernel",
    "conference",
    "ticket",
    "political",
    "politics",
    "review",
    "iphone review",
    "smartphone review"
)

# ============================================================
# 6. Signaux de CAPITAL / difficulté élevée
# ============================================================

$capitalSignals = @(
    "million dollar",
    "millions",
    "manufacturing plant",
    "factory",
    "warehouse",
    "satellite",
    "spacecraft",
    "rocket",
    "medical device",
    "clinical",
    "hardware startup",
    "robotics",
    "battery manufacturing",
    "semiconductor",
    "chip",
    "defense",
    "aviation",
    "autonomous vehicle"
)

# ============================================================
# 7. Analyse
# ============================================================

foreach ($page in $pages) {

    $text = ""

    if ($page.content) {
        $text = [string]$page.content
    }

    if ([string]::IsNullOrWhiteSpace($text)) {
        continue
    }

    $text = $text.ToLower()

    $businessHits = @()
    $proofHits = @()
    $nonSoftwareHits = @()
    $badHits = @()
    $capitalHits = @()

    foreach ($signal in $businessSignals) {
        if ($text -match [regex]::Escape($signal)) {
            $businessHits += $signal
        }
    }

    foreach ($signal in $proofSignals) {
        if ($text -match [regex]::Escape($signal)) {
            $proofHits += $signal
        }
    }

    foreach ($signal in $nonSoftwareSignals) {
        if ($text -match [regex]::Escape($signal)) {
            $nonSoftwareHits += $signal
        }
    }

    foreach ($signal in $badSignals) {
        if ($text -match [regex]::Escape($signal)) {
            $badHits += $signal
        }
    }

    foreach ($signal in $capitalSignals) {
        if ($text -match [regex]::Escape($signal)) {
            $capitalHits += $signal
        }
    }

    # --------------------------------------------------------
    # Catégorie
    # --------------------------------------------------------

    if ($nonSoftwareHits.Count -gt 0) {
        $type = "Non-software"
    }
    else {
        $type = "Software"
    }

    if ($text -match "rental|rent|lease|leasing") {
        $category = "Rental"
    }
    elseif ($text -match "marketplace|sharing|peer.to.peer") {
        $category = "Marketplace"
    }
    elseif ($text -match "education|course|training|bootcamp") {
        $category = "Education"
    }
    elseif ($text -match "delivery|courier|on.demand") {
        $category = "Delivery"
    }
    elseif ($text -match "cleaning|repair|installation|maintenance") {
        $category = "Local Service"
    }
    elseif ($text -match "store|shop|commerce|product|resale") {
        $category = "E-commerce / Product"
    }
    elseif ($text -match "fitness|beauty|pet|childcare") {
        $category = "Consumer Service"
    }
    elseif ($text -match "travel|hotel|hospitality|booking") {
        $category = "Travel / Hospitality"
    }
    elseif ($text -match "software|saas|api|app|platform|ai") {
        $category = "Software / AI"
    }
    else {
        $category = "Other"
    }

    # --------------------------------------------------------
    # Score
    # --------------------------------------------------------

    $score = 0

    # Existence d'un business
    $score += [Math]::Min($businessHits.Count * 2, 20)

    # Preuves économiques
    $score += [Math]::Min($proofHits.Count * 4, 20)

    # Non-software : important pour notre objectif
    if ($type -eq "Non-software") {
        $score += 12
    }

    # Présence de prix
    if ($text -match "\$[0-9]+|€[0-9]+|£[0-9]+|price|pricing") {
        $score += 5
    }

    # Signaux de copie potentielle
    if ($text -match "service|marketplace|rental|booking|subscription|delivery|store|course|training|agency|resale") {
        $score += 8
    }

    # Pénalité contenu non-business
    $score -= [Math]::Min($badHits.Count * 8, 30)

    # Pénalité capital
    $score -= [Math]::Min($capitalHits.Count * 5, 20)

    # --------------------------------------------------------
    # Ne garder que les vrais candidats
    # --------------------------------------------------------

    if ($businessHits.Count -lt 2) {
        continue
    }

    if ($proofHits.Count -eq 0) {
        continue
    }

    if ($score -lt 15) {
        continue
    }

    $candidates += [PSCustomObject]@{
        name = $page.name
        url = $page.url
        source = $page.source
        business_score = $score
        type = $type
        category = $category
        business_signals = ($businessHits | Select-Object -Unique) -join ", "
        proof_signals = ($proofHits | Select-Object -Unique) -join ", "
        capital_signals = ($capitalHits | Select-Object -Unique) -join ", "
    }
}

# ============================================================
# 8. Trier
# ============================================================

$candidates = @(
    $candidates |
    Sort-Object business_score -Descending
)

# ============================================================
# 9. Sauvegarde
# ============================================================

$candidates |
    ConvertTo-Json -Depth 5 |
    Set-Content -Encoding UTF8 ".\business_candidates_v8.json"

# ============================================================
# 10. Affichage
# ============================================================

Write-Host ""
Write-Host "Candidats réellement exploitables : $($candidates.Count)"
Write-Host ""

$candidates |
    Select-Object -First 20 name,business_score,type,category |
    Format-Table -AutoSize

Write-Host ""
Write-Host "Résultats : business_candidates_v8.json"
