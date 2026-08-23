$ErrorActionPreference = "Stop"

$items = Get-Content ".\business_radar_v12.json" -Raw | ConvertFrom-Json
$results = @()

foreach ($item in $items) {

    $name = [string]$item.name
    $status = [string]$item.status

    $copy = 0
    $simplicity = 0
    $automation = 0
    $capital = 0
    $market = 0

    # =============================
    # COPYABILITY
    # =============================

    if ($item.product -ge 15) { $copy += 15 }
    if ($item.problem -ge 10) { $copy += 10 }
    if ($item.customer -ge 10) { $copy += 10 }

    # =============================
    # SIMPLICITY
    # =============================

    if ($item.money -eq 0) { $simplicity += 10 }
    elseif ($item.money -le 5) { $simplicity += 7 }
    else { $simplicity += 3 }

    if ($item.solo -ge 8) { $simplicity += 10 }
    elseif ($item.solo -ge 5) { $simplicity += 6 }

    # =============================
    # AUTOMATION
    # =============================

    if ($item.solo -ge 8) { $automation += 15 }
    elseif ($item.solo -ge 5) { $automation += 10 }
    else { $automation += 4 }

    # =============================
    # CAPITAL
    # =============================

    if ($item.solo -ge 8) { $capital += 15 }
    elseif ($item.solo -ge 5) { $capital += 10 }
    else { $capital += 5 }

    # =============================
    # MARKET GAP
    # =============================

    # Les problèmes très spécialisés offrent
    # généralement davantage de possibilités
    # de déclinaison locale/niche.
    if ($item.problem -ge 15) { $market += 15 }
    elseif ($item.problem -ge 10) { $market += 10 }
    elseif ($item.problem -ge 5) { $market += 5 }

    # =============================
    # PENALITES
    # =============================

    $penalty = 0

    if ($item.penalty -ge 20) {
        $penalty += 15
    }

    if ($item.traction -ge 10 -and $item.money -eq 0) {
        $penalty += 5
    }

    # =============================
    # COPY SCORE
    # =============================

    $copyScore = $copy +
                 $simplicity +
                 $automation +
                 $capital +
                 $market -
                 $penalty

    $copyScore = [Math]::Max(0,[Math]::Min(100,$copyScore))

    # =============================
    # ANGLE DE COPIE
    # =============================

    if ($name -match "LayoutLens") {

        $angle = "Mini-audit automatique de landing pages : URL → capture → détection de problèmes visuels/conversion"

        $mvp = "Une URL entrée par l'utilisateur, analyse de la page, 5 contrôles fixes, rapport simple"

    }
    elseif ($name -match "Lens AI") {

        $angle = "Version ultra-simple du knowledge layer pour une niche précise"

        $mvp = "Une niche + import de documents/site + réponses contrôlées + page publique"

    }
    elseif ($name -match "Active Source of Truth|Meetless") {

        $angle = "Mémoire décisionnelle simplifiée pour un seul outil de coding agent"

        $mvp = "Capture de décisions + validation humaine + fichier de contexte automatiquement mis à jour"

    }
    elseif ($name -match "CtrlTool") {

        $angle = "Micro-outil spécialisé au lieu d'une bibliothèque généraliste"

        $mvp = "Une seule catégorie de 10–20 outils réellement utiles avec SEO"

    }
    elseif ($name -match "Agent2Creator") {

        $angle = "Service automatisé de création/publication de contenu pour agents"

        $mvp = "Prompt → vidéo courte → publication automatique sur une destination"

    }
    elseif ($name -match "Nice Licence") {

        $angle = "Service autour de la conformité/licence plutôt que créer une nouvelle licence"

        $mvp = "Analyse d'un dépôt GitHub et génération d'un rapport de compatibilité"

    }
    else {

        $angle = "Niche spécialisée dérivée du produit original"

        $mvp = "Version minimale répondant à un seul cas d'usage"

    }

    # =============================
    # VERDICT
    # =============================

    if ($copyScore -ge 75) {
        $verdict = "A TESTER"
    }
    elseif ($copyScore -ge 60) {
        $verdict = "A ETUDIER"
    }
    elseif ($copyScore -ge 45) {
        $verdict = "SURVEILLER"
    }
    else {
        $verdict = "IGNORER"
    }

    $results += [PSCustomObject]@{
        source = $name
        original_score = $item.score
        copy_score = $copyScore
        simplicity = $simplicity
        automation = $automation
        capital = $capital
        market_gap = $market
        copy_angle = $angle
        mvp = $mvp
        verdict = $verdict
    }
}

$results = $results | Sort-Object copy_score -Descending

$results |
    ConvertTo-Json -Depth 6 |
    Set-Content -Encoding UTF8 ".\business_opportunities_v13.json"

Write-Host ""
Write-Host "=========================================="
Write-Host "BUSINESS HUNTER V13"
Write-Host "=========================================="
Write-Host ""
Write-Host "Opportunités générées : $($results.Count)"
Write-Host ""

$results |
    Select-Object source,original_score,copy_score,simplicity,automation,capital,market_gap,verdict |
    Format-Table -AutoSize

Write-Host ""
Write-Host "Résultats : business_opportunities_v13.json"
