$businesses = Get-Content .\real_businesses.json -Raw | ConvertFrom-Json

function LevelScore($value) {
    switch ($value) {
        "very_high" { return 0 }
        "high"      { return 2 }
        "medium"    { return 4 }
        "low"       { return 5 }
        "very_low"  { return 0 }
        "none"      { return 5 }
        "very_high" { return 0 }
        "very_low"  { return 0 }
        default     { return 2 }
    }
}

$results = foreach ($data in $businesses) {

    # =========================
    # PROOF / 30
    # =========================

    $proof = 0

    if ($data.traction.revenue_growth_yoy) { $proof += 10 }
    if ($data.traction.customers.Count -ge 3) { $proof += 7 }
    if ($data.traction.profitable -eq $true) { $proof += 5 }
    if ($data.traction.funding_usd -gt 0) { $proof += 3 }
    if ($data.sources.Count -ge 2) { $proof += 5 }

    $proof = [Math]::Min($proof, 30)


    # =========================
    # COPY OPPORTUNITY / 70
    # =========================

    $copy = 0

    # Capital / 15
    switch ($data.copy_factors.initial_capital) {
        "very_low"  { $copy += 15 }
        "low"       { $copy += 13 }
        "medium"    { $copy += 8 }
        "high"      { $copy += 4 }
        "very_high" { $copy += 0 }
    }

    # Technique / 10
    switch ($data.copy_factors.technical_complexity) {
        "low"       { $copy += 10 }
        "medium"    { $copy += 7 }
        "high"      { $copy += 3 }
        "very_high" { $copy += 0 }
    }

    # Opérations / 10
    switch ($data.copy_factors.operational_complexity) {
        "low"       { $copy += 10 }
        "medium"    { $copy += 7 }
        "high"      { $copy += 3 }
        "very_high" { $copy += 0 }
    }

    # Acquisition / 10
    switch ($data.copy_factors.customer_acquisition) {
        "low"       { $copy += 10 }
        "medium"    { $copy += 7 }
        "high"      { $copy += 3 }
    }

    # Réglementation / 10
    switch ($data.copy_factors.regulatory_barriers) {
        "none"      { $copy += 10 }
        "low"       { $copy += 8 }
        "medium"    { $copy += 5 }
        "high"      { $copy += 2 }
    }

    # Network effect / 5
    switch ($data.copy_factors.network_effect) {
        "none"      { $copy += 5 }
        "low"       { $copy += 4 }
        "medium"    { $copy += 3 }
        "high"      { $copy += 1 }
    }

    # Solo feasibility / 10
    switch ($data.copy_factors.solo_feasibility) {
        "very_high" { $copy += 10 }
        "high"      { $copy += 8 }
        "medium"    { $copy += 5 }
        "low"       { $copy += 2 }
        "very_low"  { $copy += 0 }
    }

    $copy = [Math]::Min($copy, 70)

    $score = $proof + $copy

    [PSCustomObject]@{
        Business = $data.name
        Proof = $proof
        CopyOpportunity = $copy
        BiznessHunterScore = $score
    }
}

$results |
    Sort-Object BiznessHunterScore -Descending |
    Format-Table -AutoSize

