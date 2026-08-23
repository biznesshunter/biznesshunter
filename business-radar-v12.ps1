$ErrorActionPreference = "Stop"

$data = Get-Content ".\pages_full.json" -Raw | ConvertFrom-Json
$results = @()

foreach ($item in $data) {

    $text = [string]$item.content
    $lower = $text.ToLower()

    # =============================
    # SIGNALS
    # =============================

    $product = 0
    $money = 0
    $customer = 0
    $problem = 0
    $traction = 0
    $solo = 0
    $penalty = 0

    # PRODUIT
    if ($lower -match 'start for free|get started|install|sign up|try it|works with|available') {
        $product += 15
    }

    if ($lower -match 'api|dashboard|console|documentation|docs|cli|app') {
        $product += 5
    }

    # ARGENT
    if ($lower -match '\$\s?[0-9]+\s*/\s*month|\$\s?[0-9]+\s*\/month|€\s?[0-9]+\s*/\s*month|per month') {
        $money += 20
    }

    if ($lower -match 'paid|pricing|subscription|pro plan|starter plan|premium|billing') {
        $money += 5
    }

    # CLIENT
    if ($lower -match 'for solo founders|for teams|for developers|for businesses|for companies|customers|clients|users') {
        $customer += 10
    }

    if ($lower -match 'small teams|startups|agencies|professionals|e-commerce|retail|marketing') {
        $customer += 5
    }

    # PROBLEME
    if ($lower -match 'problem|pain|frustrat|stale|conflict|manual|time-consuming|expensive|difficult|missing|wrong|avoid|prevent') {
        $problem += 10
    }

    if ($lower -match 'save time|reduce cost|automate|increase|improve|stop|eliminate') {
        $problem += 5
    }

    # TRACTION
    if ($lower -match 'customers|users|revenue|mrr|arr|sold|paying|downloads|stars|forks|contributors') {
        $traction += 10
    }

    if ($lower -match 'benchmark|published research|daily|production|used by') {
        $traction += 5
    }

    # SOLO
    if ($lower -match 'saas|api|automation|online|browser|software|cli|python|javascript') {
        $solo += 10
    }

    if ($lower -match 'hardware|warehouse|delivery|manufacturing|physical installation|logistics') {
        $solo -= 10
    }

    # =============================
    # PENALTIES
    # =============================

    # Projet principalement open-source
    if (
        $lower -match 'open source' -and
        $lower -notmatch 'pricing|paid plan|subscription|customers'
    ) {
        $penalty += 20
    }

    # Licence / librairie / composant
    if ($lower -match 'software license|licence|react component|npm package|library') {
        $penalty += 25
    }

    # Projet essentiellement GitHub sans business model
    if (
        $lower -match 'github' -and
        $money -eq 0 -and
        $lower -notmatch 'pricing|subscription'
    ) {
        $penalty += 10
    }

    # =============================
    # CAPS
    # =============================

    $product = [Math]::Min($product,20)
    $money = [Math]::Min($money,25)
    $customer = [Math]::Min($customer,15)
    $problem = [Math]::Min($problem,15)
    $traction = [Math]::Min($traction,15)
    $solo = [Math]::Max(0,[Math]::Min($solo,10))

    # SCORE
    $raw = $product + $money + $customer + $problem + $traction + $solo
    $score = [Math]::Max(0,$raw - $penalty)

    # =============================
    # BUSINESS STATUS
    # =============================

    if ($money -ge 20 -and $customer -ge 10 -and $problem -ge 10) {
        $status = "Business fort"
    }
    elseif ($money -ge 20 -and $customer -ge 5) {
        $status = "Business commercial"
    }
    elseif ($product -ge 15 -and $problem -ge 10) {
        $status = "Business potentiel"
    }
    elseif ($product -ge 10) {
        $status = "Produit"
    }
    else {
        $status = "Signal faible"
    }

    # =============================
    # EVIDENCE
    # =============================

    $evidence = 0

    if ($product -ge 15) { $evidence++ }
    if ($money -ge 20) { $evidence++ }
    if ($customer -ge 10) { $evidence++ }
    if ($problem -ge 10) { $evidence++ }
    if ($traction -ge 10) { $evidence++ }

    if ($evidence -ge 4) {
        $proof = "FORTE"
    }
    elseif ($evidence -ge 3) {
        $proof = "BONNE"
    }
    elseif ($evidence -ge 2) {
        $proof = "MOYENNE"
    }
    else {
        $proof = "FAIBLE"
    }

    $results += [PSCustomObject]@{
        name = $item.name
        url = $item.url
        score = $score
        status = $status
        proof = $proof
        product = $product
        money = $money
        customer = $customer
        problem = $problem
        traction = $traction
        solo = $solo
        penalty = $penalty
    }
}

$results = $results | Sort-Object score -Descending

$results |
    ConvertTo-Json -Depth 5 |
    Set-Content -Encoding UTF8 ".\business_radar_v12.json"

Write-Host ""
Write-Host "=========================================="
Write-Host "BUSINESS RADAR V12"
Write-Host "=========================================="
Write-Host ""
Write-Host "Sources analysées : $($results.Count)"
Write-Host ""

$results |
    Select-Object name,score,status,proof,product,money,customer,problem,traction,solo,penalty |
    Format-Table -AutoSize

Write-Host ""
Write-Host "Résultats : business_radar_v12.json"
