$markets = Get-Content .\radar54_market_opportunities.json -Raw |
    ConvertFrom-Json

$results = foreach ($market in @($markets)) {

    # ==========================================
    # 1. PREUVE DE MARCHE / 20
    # ==========================================

    if ($market.demand -ge 500) {
        $marketProof = 20
    }
    elseif ($market.demand -ge 250) {
        $marketProof = 17
    }
    elseif ($market.demand -ge 100) {
        $marketProof = 14
    }
    elseif ($market.demand -ge 50) {
        $marketProof = 10
    }
    elseif ($market.demand -gt 0) {
        $marketProof = 6
    }
    else {
        $marketProof = 0
    }


    # ==========================================
    # 2. PREUVE BUSINESS / 15
    # ==========================================

    $businessProof = 0

    if ($market.demand -gt 0) {
        $businessProof += 4
    }

    if ($market.supply -gt 0) {
        $businessProof += 3
    }

    if ($market.price_samples -ge 50) {
        $businessProof += 4
    }
    elseif ($market.price_samples -ge 20) {
        $businessProof += 3
    }
    elseif ($market.price_samples -ge 5) {
        $businessProof += 2
    }

    if (@($market.sources).Count -ge 2) {
        $businessProof += 4
    }
    elseif (@($market.sources).Count -eq 1) {
        $businessProof += 2
    }

    if ($businessProof -gt 15) {
        $businessProof = 15
    }


    # ==========================================
    # 3. CONCURRENCE / 5
    #
    # Plus l'offre existante est importante,
    # plus il est difficile d'entrer.
    # ==========================================

    if ($market.supply -eq 0) {
        $competitionScore = 5
    }
    elseif ($market.supply -lt 50) {
        $competitionScore = 4
    }
    elseif ($market.supply -lt 150) {
        $competitionScore = 3
    }
    elseif ($market.supply -lt 300) {
        $competitionScore = 2
    }
    else {
        $competitionScore = 1
    }


    # ==========================================
    # 4. CLASSIFICATION METIER
    # ==========================================

    $name = $market.idea_name.ToLower()


    # ==========================================
    # CAPITAL / 10
    # ==========================================

    if (
        $name -match "marketplace" -or
        $name -match "réservation" -or
        $name -match "reservation"
    ) {
        $capitalScore = 9
    }
    elseif (
        $name -match "service" -and
        $name -notmatch "domicile"
    ) {
        $capitalScore = 6
    }
    else {
        $capitalScore = 3
    }


    # ==========================================
    # HOME BASED / 10
    # ==========================================

    if (
        $name -match "marketplace" -or
        $name -match "réservation" -or
        $name -match "reservation"
    ) {
        $homeBasedScore = 10
    }
    elseif ($name -match "à domicile" -or $name -match "a domicile") {
        $homeBasedScore = 4
    }
    else {
        $homeBasedScore = 3
    }


    # ==========================================
    # AUTOMATISATION / 10
    # ==========================================

    if ($name -match "marketplace") {
        $automationScore = 10
    }
    elseif (
        $name -match "réservation" -or
        $name -match "reservation"
    ) {
        $automationScore = 9
    }
    elseif ($name -match "location") {
        $automationScore = 8
    }
    elseif ($name -match "ménage" -or $name -match "menage") {
        $automationScore = 5
    }
    elseif ($name -match "garde" -or $name -match "promenade") {
        $automationScore = 5
    }
    else {
        $automationScore = 4
    }


    # ==========================================
    # PRESENCE HUMAINE / 10
    #
    # 10 = très peu de présence
    # ==========================================

    if ($name -match "marketplace") {
        $humanPresenceScore = 10
    }
    elseif (
        $name -match "location"
    ) {
        $humanPresenceScore = 8
    }
    elseif (
        $name -match "réservation" -or
        $name -match "reservation"
    ) {
        $humanPresenceScore = 7
    }
    elseif (
        $name -match "garde" -or
        $name -match "promenade"
    ) {
        $humanPresenceScore = 3
    }
    elseif (
        $name -match "ménage" -or
        $name -match "menage" -or
        $name -match "jardin"
    ) {
        $humanPresenceScore = 2
    }
    else {
        $humanPresenceScore = 4
    }


    # ==========================================
    # REPLICATION GEOGRAPHIQUE / 10
    # ==========================================

    if ($name -match "marketplace") {
        $replicationScore = 10
    }
    elseif (
        $name -match "réservation" -or
        $name -match "reservation"
    ) {
        $replicationScore = 9
    }
    elseif ($name -match "location") {
        $replicationScore = 8
    }
    elseif (
        $name -match "garde" -or
        $name -match "promenade"
    ) {
        $replicationScore = 6
    }
    else {
        $replicationScore = 5
    }


    # ==========================================
    # SCORE FINAL / 100
    # ==========================================

    $biznessHunterScore =
        $marketProof +
        $businessProof +
        $competitionScore +
        $capitalScore +
        $homeBasedScore +
        $automationScore +
        $humanPresenceScore +
        $replicationScore


    # ==========================================
    # VERDICT
    # ==========================================

    if ($biznessHunterScore -ge 80) {
        $verdict = "STRONG_REPLICATION"
    }
    elseif ($biznessHunterScore -ge 65) {
        $verdict = "PROMISING"
    }
    elseif ($biznessHunterScore -ge 50) {
        $verdict = "WATCH"
    }
    else {
        $verdict = "REJECT"
    }


    # ==========================================
    # OUTPUT
    # ==========================================

    [PSCustomObject]@{
        idea_name = $market.idea_name
        country = $market.country
        city = $market.city

        market_score = $market.total_score
        market_verdict = $market.verdict

        demand = $market.demand
        supply = $market.supply
        median_price = $market.median_price
        price_samples = $market.price_samples

        market_proof_score = $marketProof
        business_proof_score = $businessProof
        competition_score = $competitionScore

        capital_score = $capitalScore
        home_based_score = $homeBasedScore
        automation_score = $automationScore
        human_presence_score = $humanPresenceScore
        geographic_replication_score = $replicationScore

        biznesshunter_score = $biznessHunterScore
        verdict = $verdict

        sources = @($market.sources)
    }
}


$results |
    Sort-Object biznesshunter_score -Descending |
    ConvertTo-Json -Depth 10 |
    Set-Content .\radar58_qualified_opportunities.json -Encoding UTF8


Write-Host ""
Write-Host "QUALIFIED OPPORTUNITIES :" @($results).Count
Write-Host "OUTPUT                   : radar58_qualified_opportunities.json"
Write-Host ""


$results |
    Sort-Object biznesshunter_score -Descending |
    Format-Table `
        idea_name,
        city,
        market_score,
        biznesshunter_score,
        verdict `
        -AutoSize
