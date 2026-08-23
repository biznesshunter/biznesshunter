$data = Get-Content .\raw_business.json -Raw | ConvertFrom-Json

# ==========================================
# BIZNESSHUNTER V1
# Target: solo entrepreneur / limited capital
# ==========================================

# 1. TRACTION / 30
$traction = 0

if ($data.traction.revenue_growth_yoy) {
    $traction += 10
}

if ($data.traction.customers.Count -ge 3) {
    $traction += 7
}

if ($data.traction.profitable -eq $true) {
    $traction += 5
}

if ($data.traction.funding_usd -gt 0) {
    $traction += 3
}

if ($data.sources.Count -ge 2) {
    $traction += 5
}

$traction = [Math]::Min($traction, 30)


# 2. ADAPTABILITE / 20
$adaptability = 0

if ($data.business_model -match "SaaS|Marketplace|Subscription") {
    $adaptability += 8
}

if ($data.category -notmatch "Hardware|Infrastructure") {
    $adaptability += 5
}

if ($data.traction.team_size -le 30) {
    $adaptability += 4
}

if ($data.business_model -match "transaction|subscription") {
    $adaptability += 3
}

$adaptability = [Math]::Min($adaptability, 20)


# 3. CAPITAL NECESSAIRE / 15
$capital = 0

if ($data.category -notmatch "Hardware") {
    $capital += 5
}

if ($data.category -notmatch "Infrastructure") {
    $capital += 4
}

if ($data.business_model -match "SaaS|Subscription|Marketplace") {
    $capital += 4
}

if ($data.traction.team_size -le 10) {
    $capital += 2
}

$capital = [Math]::Min($capital, 15)


# 4. SOLO-FRIENDLY / 15
$solo = 0

if ($data.traction.team_size -le 10) {
    $solo += 7
}

if ($data.category -notmatch "Hardware|Infrastructure") {
    $solo += 4
}

if ($data.business_model -match "SaaS|Subscription|Marketplace") {
    $solo += 4
}

$solo = [Math]::Min($solo, 15)


# 5. COMPLEXITE / 10
$complexity = 0

if ($data.traction.team_size -le 10) {
    $complexity += 5
}

if ($data.category -notmatch "Hardware") {
    $complexity += 3
}

if ($data.category -notmatch "Infrastructure") {
    $complexity += 2
}

$complexity = [Math]::Min($complexity, 10)


# 6. TIMING / 10
$timing = 0

if ($data.signals.Count -ge 3) {
    $timing += 4
}

if ($data.traction.revenue_growth_yoy) {
    $timing += 3
}

if ($data.traction.expansion.Count -ge 1) {
    $timing += 3
}

$timing = [Math]::Min($timing, 10)


# SCORE FINAL
$score = $traction +
         $adaptability +
         $capital +
         $solo +
         $complexity +
         $timing


[PSCustomObject]@{
    Business = $data.name
    Traction = $traction
    Adaptability = $adaptability
    Capital = $capital
    SoloFriendly = $solo
    Complexity = $complexity
    Timing = $timing
    BiznessHunterScore = $score
} | Format-List
