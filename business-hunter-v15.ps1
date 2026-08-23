$ErrorActionPreference = "Stop"

# ==========================================
# BUSINESS HUNTER V15
# Evidence-based opportunity scoring
# ==========================================

$items = Get-Content ".\pages_full.json" -Raw | ConvertFrom-Json
$results = @()

function HasAny($text, $patterns) {
    foreach ($p in $patterns) {
        if ($text -match $p) { return $true }
    }
    return $false
}

foreach ($item in $items) {

    $name = [string]$item.name
    $content = [string]$item.content
    $text = ($name + " " + $content).ToLower()

    # ==========================================
    # 1. PROBLEM EVIDENCE
    # ==========================================

    $problem = 0

    if (HasAny $text @(
        "problem",
        "pain",
        "challenge",
        "failure",
        "difficult",
        "hard to",
        "can't",
        "cannot",
        "missing",
        "stale",
        "wrong",
        "manual",
        "error",
        "issue",
        "friction",
        "waste",
        "slow"
    )) {
        $problem += 25
    }

    if (HasAny $text @(
        "built from the failure",
        "problem is",
        "the problem",
        "why",
        "need",
        "customers",
        "teams",
        "developers"
    )) {
        $problem += 15
    }

    $problem = [Math]::Min(40,$problem)

    # ==========================================
    # 2. CUSTOMER
    # ==========================================

    $customer = 0

    if (HasAny $text @(
        "customer",
        "customers",
        "teams",
        "companies",
        "business",
        "developers",
        "engineers",
        "founders",
        "professionals",
        "enterprise",
        "users"
    )) {
        $customer += 20
    }

    if (HasAny $text @(
        "for solo",
        "for teams",
        "for companies",
        "built for",
        "designed for",
        "target"
    )) {
        $customer += 15
    }

    $customer = [Math]::Min(35,$customer)

    # ==========================================
    # 3. MONEY / WILLINGNESS TO PAY
    # ==========================================

    $money = 0

    if ($text -match '\$[0-9]+|\€[0-9]+|[0-9]+\s*(usd|eur|€|\$)') {
        $money += 30
    }

    if (HasAny $text @(
        "pricing",
        "price",
        "paid",
        "subscription",
        "monthly",
        "annual",
        "per month",
        "plan",
        "pro plan",
        "starter plan",
        "enterprise"
    )) {
        $money += 25
    }

    if (HasAny $text @(
        "start for free",
        "free to try",
        "popular",
        "most popular",
        "grow with you"
    )) {
        $money += 10
    }

    $money = [Math]::Min(50,$money)

    # ==========================================
    # 4. REAL PRODUCT EVIDENCE
    # ==========================================

    $product = 0

    if (HasAny $text @(
        "pricing",
        "features",
        "documentation",
        "install",
        "github",
        "api",
        "dashboard",
        "login",
        "signup",
        "get started",
        "download"
    )) {
        $product += 25
    }

    if (HasAny $text @(
        "how it works",
        "quick start",
        "installation",
        "integration",
        "workflow"
    )) {
        $product += 15
    }

    if (HasAny $text @(
        "works",
        "used",
        "production",
        "daily",
        "live"
    )) {
        $product += 10
    }

    $product = [Math]::Min(50,$product)

    # ==========================================
    # 5. TRACTION / VALIDATION
    # ==========================================

    $traction = 0

    if (HasAny $text @(
        "customers",
        "users",
        "companies",
        "teams",
        "production",
        "daily",
        "used by"
    )) {
        $traction += 20
    }

    if ($text -match "stars|forks|downloads|benchmark|published|research") {
        $traction += 10
    }

    if ($text -match "\b[0-9]+\s*(users|customers|teams|companies|stars|downloads)") {
        $traction += 20
    }

    $traction = [Math]::Min(40,$traction)

    # ==========================================
    # 6. COPYABILITY
    # ==========================================

    $copyability = 0

    if (HasAny $text @(
        "github",
        "open source",
        "api",
        "cli",
        "browser",
        "web",
        "url",
        "upload",
        "generate",
        "report",
        "dashboard"
    )) {
        $copyability += 30
    }

    if (HasAny $text @(
        "simple",
        "quick",
        "one click",
        "few minutes",
        "single"
    )) {
        $copyability += 15
    }

    if ($text -notmatch "hardware|patent|manufacturing|logistics|marketplace") {
        $copyability += 15
    }

    $copyability = [Math]::Min(60,$copyability)

    # ==========================================
    # 7. SOLO FEASIBILITY
    # ==========================================

    $solo = 0

    if (HasAny $text @(
        "api",
        "browser",
        "web",
        "cli",
        "automatic",
        "automatically",
        "automation",
        "generate"
    )) {
        $solo += 25
    }

    if ($text -notmatch "hardware|warehouse|delivery|manufacturing|physical location") {
        $solo += 15
    }

    if ($text -match "free|open source|github") {
        $solo += 10
    }

    $solo = [Math]::Min(50,$solo)

    # ==========================================
    # 8. COMMERCIAL OPPORTUNITY
    # ==========================================

    $commercial = [Math]::Round(
        ($problem * 0.30) +
        ($customer * 0.20) +
        ($money * 0.30) +
        ($traction * 0.20)
    )

    $commercial = [Math]::Min(100,$commercial)

    # ==========================================
    # 9. FINAL SCORE
    # ==========================================

    $score = [Math]::Round(
        ($commercial * 0.40) +
        ($copyability * 0.25) +
        ($solo * 0.20) +
        ($product * 0.15)
    )

    $score = [Math]::Min(100,[Math]::Max(0,$score))

    # ==========================================
    # 10. OPPORTUNITY TYPE
    # ==========================================

    if ($money -ge 30 -and $copyability -ge 35 -and $solo -ge 30) {
        $type = "COPYABLE BUSINESS"
    }
    elseif ($commercial -ge 50 -and $copyability -ge 30) {
        $type = "NICHE OPPORTUNITY"
    }
    elseif ($product -ge 30 -and $copyability -ge 30) {
        $type = "PRODUCT SIGNAL"
    }
    else {
        $type = "WEAK SIGNAL"
    }

    # ==========================================
    # 11. GENERIC COPY ANGLE
    # ==========================================

    if ($type -eq "COPYABLE BUSINESS") {

        $angle = "Reproduire le mécanisme commercial avec une niche plus étroite"

        $mvp = "Landing page + entrée utilisateur + fonction centrale + résultat immédiat"

    }
    elseif ($type -eq "NICHE OPPORTUNITY") {

        $angle = "Prendre le problème validé et cibler un segment beaucoup plus précis"

        $mvp = "Une seule fonctionnalité destinée à une niche clairement définie"

    }
    elseif ($type -eq "PRODUCT SIGNAL") {

        $angle = "Extraire la fonctionnalité la plus utile et supprimer le reste"

        $mvp = "Micro-produit centré sur la fonctionnalité principale"

    }
    else {

        $angle = "Pas encore assez de preuves pour justifier une copie"

        $mvp = "Ne pas construire avant d'obtenir davantage de preuves"

    }

    # ==========================================
    # 12. VERDICT
    # ==========================================

    if ($score -ge 70) {
        $verdict = "A TESTER"
    }
    elseif ($score -ge 55) {
        $verdict = "A ETUDIER"
    }
    elseif ($score -ge 40) {
        $verdict = "SURVEILLER"
    }
    else {
        $verdict = "IGNORER"
    }

    # ==========================================
    # RESULT
    # ==========================================

    $results += [PSCustomObject]@{
        source = $name

        opportunity_score = $score

        problem = $problem
        customer = $customer
        money = $money
        product = $product
        traction = $traction
        copyability = $copyability
        solo_feasibility = $solo

        commercial_opportunity = $commercial

        type = $type

        copy_angle = $angle
        mvp = $mvp

        verdict = $verdict
    }
}

# ==========================================
# SORT + SAVE
# ==========================================

$results = $results |
    Sort-Object opportunity_score -Descending

$results |
    ConvertTo-Json -Depth 8 |
    Set-Content -Encoding UTF8 ".\business_opportunities_v15.json"

# ==========================================
# DISPLAY
# ==========================================

Write-Host ""
Write-Host "=========================================="
Write-Host "BUSINESS HUNTER V15"
Write-Host "=========================================="
Write-Host ""
Write-Host "Sources analysées : $($items.Count)"
Write-Host ""

$results |
    Select-Object `
        source,
        opportunity_score,
        commercial_opportunity,
        problem,
        customer,
        money,
        copyability,
        solo_feasibility,
        verdict |
    Format-Table -AutoSize

Write-Host ""
Write-Host "Résultats : business_opportunities_v15.json"
