$ErrorActionPreference = "Stop"

# ==========================================
# BUSINESS HUNTER V14
# Generic opportunity detector
# ==========================================

$items = Get-Content ".\pages_full.json" -Raw | ConvertFrom-Json

$results = @()

foreach ($item in $items) {

    $name = [string]$item.name
    $content = [string]$item.content
    $text = ($name + " " + $content).ToLower()

    # ------------------------------------------
    # SIGNALS
    # ------------------------------------------

    $problem = 0
    $customer = 0
    $money = 0
    $traction = 0
    $product = 0
    $automation = 0
    $simplicity = 0
    $copyability = 0

    # Problem signals
    $problem += ([regex]::Matches($text,
        "problem|pain|challenge|failure|hard|difficult|missing|stale|wrong|slow|manual|error|bug|issue|need"
    )).Count * 2

    # Customer signals
    $customer += ([regex]::Matches($text,
        "customer|developer|team|company|business|user|founder|engineer|agency|professional|enterprise"
    )).Count

    # Money / monetization
    $money += ([regex]::Matches($text,
        "\$[0-9]+|€[0-9]+|price|pricing|paid|payment|subscription|month|monthly|annual|plan|pro plan|starter|free forever"
    )).Count * 4

    # Traction
    $traction += ([regex]::Matches($text,
        "customer|users|download|star|fork|benchmark|published|production|used by|teams|companies|daily"
    )).Count

    # Product maturity
    $product += ([regex]::Matches($text,
        "pricing|features|documentation|install|github|api|integration|dashboard|login|signup|start for free|download"
    )).Count * 2

    # Automation
    $automation += ([regex]::Matches($text,
        "automatic|automatically|automation|api|batch|async|cli|integration|agent|workflow|scheduled"
    )).Count * 2

    # Simplicity
    $simplicity += ([regex]::Matches($text,
        "simple|quick|few minutes|one click|single|lightweight|free|browser|url|upload|generate"
    )).Count * 2

    # Copyability
    $copyability += ([regex]::Matches($text,
        "open source|github|api|cli|web|browser|url|upload|generate|report|dashboard|automation"
    )).Count * 2

    # ------------------------------------------
    # NORMALISATION
    # ------------------------------------------

    $problem = [Math]::Min(100, $problem)
    $customer = [Math]::Min(100, $customer)
    $money = [Math]::Min(100, $money)
    $traction = [Math]::Min(100, $traction)
    $product = [Math]::Min(100, $product)
    $automation = [Math]::Min(100, $automation)
    $simplicity = [Math]::Min(100, $simplicity)
    $copyability = [Math]::Min(100, $copyability)

    # ------------------------------------------
    # COMMERCIAL OPPORTUNITY
    # ------------------------------------------

    $commercial = (
        ($problem * 0.30) +
        ($customer * 0.15) +
        ($money * 0.25) +
        ($traction * 0.15) +
        ($product * 0.15)
    )

    $commercial = [Math]::Round($commercial)

    # ------------------------------------------
    # OPPORTUNITY SCORE
    # ------------------------------------------

    $score = (
        ($commercial * 0.35) +
        ($copyability * 0.20) +
        ($simplicity * 0.15) +
        ($automation * 0.15) +
        ($money * 0.15)
    )

    $score = [Math]::Round($score)
    $score = [Math]::Min(100,[Math]::Max(0,$score))

    # ------------------------------------------
    # GENERIC COPY ANGLE
    # ------------------------------------------

    if ($automation -ge 60 -and $simplicity -ge 60) {

        $angle = "Créer une version plus simple et fortement automatisée du service"

    }
    elseif ($product -ge 60 -and $money -ge 40) {

        $angle = "Cibler une niche précise avec une version spécialisée du produit"

    }
    elseif ($problem -ge 50 -and $money -ge 30) {

        $angle = "Résoudre le même problème avec un produit beaucoup plus étroit"

    }
    elseif ($copyability -ge 60) {

        $angle = "Extraire une fonctionnalité rentable du produit"

    }
    else {

        $angle = "Transformer le signal en micro-produit spécialisé"

    }

    # ------------------------------------------
    # MVP GENERIQUE
    # ------------------------------------------

    if ($automation -ge 60) {

        $mvp = "Entrée utilisateur → traitement automatique → résultat exploitable"

    }
    elseif ($product -ge 60) {

        $mvp = "Landing page + formulaire + traitement principal + résultat"

    }
    else {

        $mvp = "Une seule fonctionnalité principale avec interface minimale"

    }

    # ------------------------------------------
    # VERDICT
    # ------------------------------------------

    if ($score -ge 75) {
        $verdict = "A TESTER"
    }
    elseif ($score -ge 60) {
        $verdict = "A ETUDIER"
    }
    elseif ($score -ge 45) {
        $verdict = "SURVEILLER"
    }
    else {
        $verdict = "IGNORER"
    }

    $results += [PSCustomObject]@{
        source = $name
        commercial_opportunity = $commercial
        problem = $problem
        customer = $customer
        money = $money
        traction = $traction
        product = $product
        copyability = $copyability
        simplicity = $simplicity
        automation = $automation
        opportunity_score = $score
        copy_angle = $angle
        mvp = $mvp
        verdict = $verdict
    }
}

# ------------------------------------------
# SORT
# ------------------------------------------

$results = $results |
    Sort-Object opportunity_score -Descending

$results |
    ConvertTo-Json -Depth 6 |
    Set-Content -Encoding UTF8 ".\business_opportunities_v14.json"

# ------------------------------------------
# DISPLAY
# ------------------------------------------

Write-Host ""
Write-Host "=========================================="
Write-Host "BUSINESS HUNTER V14"
Write-Host "=========================================="
Write-Host ""
Write-Host "Sources analysées : $($items.Count)"
Write-Host ""

$results |
    Select-Object `
        source,
        opportunity_score,
        commercial_opportunity,
        copyability,
        simplicity,
        automation,
        money,
        verdict |
    Format-Table -AutoSize

Write-Host ""
Write-Host "Résultats : business_opportunities_v14.json"
