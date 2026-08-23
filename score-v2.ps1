$data = Get-Content .\raw_business.json -Raw | ConvertFrom-Json

# PREUVE / 30
$proof = 0

$proof += [Math]::Round(($data.evidence_quality.revenue_growth / 5) * 10)
$proof += [Math]::Round(($data.evidence_quality.customers / 5) * 7)
$proof += [Math]::Round(($data.evidence_quality.profitability / 5) * 5)
$proof += [Math]::Round(($data.evidence_quality.funding / 5) * 3)
$proof += [Math]::Round(($data.evidence_quality.sources / 5) * 5)

$proof = [Math]::Min($proof, 30)

# COPIABILITÉ / 70
$copy = 0

switch ($data.copy_factors.initial_capital) {
    "very_low" { $copy += 15 }
    "low" { $copy += 13 }
    "medium" { $copy += 8 }
    "high" { $copy += 4 }
    "very_high" { $copy += 0 }
}

switch ($data.copy_factors.technical_complexity) {
    "low" { $copy += 10 }
    "medium" { $copy += 7 }
    "high" { $copy += 3 }
    "very_high" { $copy += 0 }
}

switch ($data.copy_factors.operational_complexity) {
    "low" { $copy += 10 }
    "medium" { $copy += 7 }
    "high" { $copy += 3 }
    "very_high" { $copy += 0 }
}

switch ($data.copy_factors.customer_acquisition) {
    "low" { $copy += 10 }
    "medium" { $copy += 7 }
    "high" { $copy += 3 }
}

switch ($data.copy_factors.regulatory_barriers) {
    "none" { $copy += 10 }
    "low" { $copy += 8 }
    "medium" { $copy += 5 }
    "high" { $copy += 2 }
}

switch ($data.copy_factors.network_effect) {
    "none" { $copy += 5 }
    "low" { $copy += 4 }
    "medium" { $copy += 3 }
    "high" { $copy += 1 }
}

switch ($data.copy_factors.solo_feasibility) {
    "very_high" { $copy += 10 }
    "high" { $copy += 8 }
    "medium" { $copy += 5 }
    "low" { $copy += 2 }
    "very_low" { $copy += 0 }
}

$copy = [Math]::Min($copy, 70)

[PSCustomObject]@{
    Business = $data.name
    Proof = $proof
    CopyOpportunity = $copy
    BiznessHunterScore = $proof + $copy
} | Format-List
