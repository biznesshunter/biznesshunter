Write-Host ""
Write-Host "========================================"
Write-Host " BiznessHunter - Radar 30"
Write-Host " CLIENT FIT"
Write-Host "========================================"
Write-Host ""

$raw = Get-Content .\radar29_opportunities.json -Raw | ConvertFrom-Json
$items = @($raw)

Write-Host "Input opportunities : $($items.Count)"
Write-Host ""

function Clamp-Score {
    param([double]$Value)

    if ($Value -lt 0) { return 0 }
    if ($Value -gt 100) { return 100 }

    return [math]::Round($Value)
}

function Get-ClientFitScore {
    param($item)

    $text = @(
        $item.opportunity
        $item.category
        $item.source_cluster
        $item.why
        $item.signals
    ) -join " "

    $text = $text.ToLower()

    # ----------------------------------------
    # 1. DEMAND / PROBLEM INTENSITY
    # ----------------------------------------

    $demand = 50

    $highDemand = @(
        "urgent",
        "réparation",
        "dépannage",
        "intervention",
        "à domicile",
        "à la demande",
        "location",
        "besoin",
        "ponctuel",
        "24h",
        "48h",
        "garanti",
        "professionnel"
    )

    foreach ($keyword in $highDemand) {
        if ($text -like "*$keyword*") {
            $demand += 4
        }
    }

    # ----------------------------------------
    # 2. MARKET PROOF
    # ----------------------------------------

    $proof = [double]$item.proof_score

    # ----------------------------------------
    # 3. EASE OF EXPLAINING THE OPPORTUNITY
    # ----------------------------------------

    $clarity = 50

    $clear = @(
        "location",
        "réparation",
        "dépannage",
        "livraison",
        "transport",
        "montage",
        "nettoyage",
        "stockage",
        "garde",
        "service",
        "réservation"
    )

    foreach ($keyword in $clear) {
        if ($text -like "*$keyword*") {
            $clarity += 5
        }
    }

    # ----------------------------------------
    # 4. CUSTOMER WILLINGNESS TO PAY
    # ----------------------------------------

    $willingness = [double]$item.willingness_to_pay

    # ----------------------------------------
    # 5. REPLICATION POTENTIAL
    # ----------------------------------------

    $replication = 50

    if ($item.company_count -ge 10) {
        $replication += 15
    }
    elseif ($item.company_count -ge 5) {
        $replication += 10
    }
    elseif ($item.company_count -ge 2) {
        $replication += 5
    }

    if ($item.article_count -ge 20) {
        $replication += 15
    }
    elseif ($item.article_count -ge 10) {
        $replication += 10
    }
    elseif ($item.article_count -ge 5) {
        $replication += 5
    }

    # ----------------------------------------
    # FINAL CLIENT FIT
    # ----------------------------------------

    $clientFit = (
        ($proof * 0.30) +
        ($demand * 0.20) +
        ($willingness * 0.20) +
        ($replication * 0.15) +
        ($clarity * 0.15)
    )

    $clientFit = Clamp-Score $clientFit

    # ----------------------------------------
    # CLIENT VERDICT
    # ----------------------------------------

    if (
        $clientFit -ge 75 -and
        $proof -ge 60
    ) {
        $clientVerdict = "TOP OPPORTUNITY"
    }
    elseif (
        $clientFit -ge 60 -and
        $proof -ge 50
    ) {
        $clientVerdict = "STRONG"
    }
    elseif (
        $clientFit -ge 45
    ) {
        $clientVerdict = "PROMISING"
    }
    else {
        $clientVerdict = "WEAK"
    }

    [PSCustomObject]@{
        rank                = $item.rank
        opportunity         = $item.opportunity

        client_fit_score    = $clientFit
        client_verdict      = $clientVerdict

        proof_score         = $proof
        demand_score        = Clamp-Score $demand
        willingness_to_pay  = $willingness
        replication_score   = Clamp-Score $replication
        clarity_score       = Clamp-Score $clarity

        opportunity_score   = $item.opportunity_score
        original_verdict    = $item.verdict

        company_count       = $item.company_count
        article_count       = $item.article_count
        confidence          = $item.confidence

        why                 = $item.why
        source_articles     = @($item.source_articles)
        signals             = @($item.signals)
    }
}

$feed = @(
    $items |
    ForEach-Object {
        Get-ClientFitScore $_
    } |
    Sort-Object client_fit_score -Descending
)

for ($i = 0; $i -lt $feed.Count; $i++) {
    $feed[$i].rank = $i + 1
}

$feed |
    ConvertTo-Json -Depth 20 |
    Set-Content .\radar30_client_opportunities.json -Encoding UTF8

Write-Host ""
Write-Host "Output : .\radar30_client_opportunities.json"
Write-Host ""

$feed |
    Select-Object rank,opportunity,client_fit_score,client_verdict,proof_score,demand_score,willingness_to_pay |
    Format-Table -AutoSize

Write-Host ""
Write-Host "========================================"
Write-Host " Radar 30 completed"
Write-Host "========================================"
