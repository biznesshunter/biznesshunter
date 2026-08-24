$inputFile = ".\radar12_final_opportunities.json"
$outputFile = ".\radar13_ideas.json"

if (!(Test-Path $inputFile)) {
    Write-Host "ERROR: $inputFile not found"
    exit
}

$data = Get-Content $inputFile -Raw | ConvertFrom-Json

Write-Host ""
Write-Host "=============================================================="
Write-Host " BIZNESSHUNTER - RADAR 13"
Write-Host " OPPORTUNITY -> CONCRETE IDEA ENGINE"
Write-Host "=============================================================="
Write-Host ""

$ideas = @()

foreach ($cluster in $data) {

    # ----------------------------------------------------------
    # IGNORE WEAK SIGNALS
    # ----------------------------------------------------------

    if ([int]$cluster.final_score -lt 50) {
        continue
    }

    $model = [string]$cluster.business_model
    $vertical = [string]$cluster.vertical

    $companies = [string]$cluster.company_count
    $articles = [string]$cluster.article_count
    $countries = [string]$cluster.country_count

    $soloFit = [string]$cluster.solo_fit

    $replication = 0
    $capital = 50
    $regulation = 50
    $marketProof = 0

    if ($cluster.PSObject.Properties.Name -contains "avg_replication") {
        $replication = [int]$cluster.avg_replication
    }

    if ($cluster.PSObject.Properties.Name -contains "avg_capital_risk") {
        $capital = [int]$cluster.avg_capital_risk
    }

    if ($cluster.PSObject.Properties.Name -contains "avg_regulatory_risk") {
        $regulation = [int]$cluster.avg_regulatory_risk
    }

    if ($cluster.PSObject.Properties.Name -contains "market_proof") {
        $marketProof = [int]$cluster.market_proof
    }

    # ----------------------------------------------------------
    # GENERIC IDEA GENERATION
    # ----------------------------------------------------------

    $ideaName = ""
    $problem = ""
    $customer = ""
    $mechanism = ""
    $launchModel = ""

    switch ($vertical) {

        "HOME_SERVICES" {

            if ($model -eq "ON_DEMAND") {
                $ideaName = "On-demand local home service marketplace"
                $problem = "Customers struggle to find reliable professionals for small household jobs quickly."
                $customer = "Consumers needing occasional home services"
                $mechanism = "Connect customers with vetted local providers through a simple booking platform."
                $launchModel = "Start with one service and one geographic area."
            }
            elseif ($model -eq "SUBSCRIPTION") {
                $ideaName = "Recurring home maintenance service"
                $problem = "Households postpone recurring maintenance because providers are fragmented."
                $customer = "Homeowners and renters"
                $mechanism = "Bundle recurring maintenance tasks into a predictable subscription."
                $launchModel = "Start with a narrow recurring service."
            }
            else {
                $ideaName = "Specialized home service platform"
                $problem = "Customers have difficulty comparing and booking reliable local services."
                $customer = "Consumers"
                $mechanism = "Aggregate and simplify discovery, comparison and booking."
                $launchModel = "Start locally with a narrow service category."
            }
        }

        "PET_SERVICES" {

            $ideaName = "Specialized pet service platform"
            $problem = "Pet owners have difficulty finding trusted and convenient services."
            $customer = "Pet owners"
            $mechanism = "Aggregate trusted providers around a specific recurring pet need."
            $launchModel = "Start with one pet service and one geographic market."
        }

        "REPAIR" {

            $ideaName = "Specialized repair marketplace"
            $problem = "Consumers struggle to identify trustworthy repair professionals and obtain transparent pricing."
            $customer = "Consumers and small businesses"
            $mechanism = "Match repair demand with qualified local providers."
            $launchModel = "Start with one repair category and one city."
        }

        "RENTAL" {

            $ideaName = "Niche rental marketplace"
            $problem = "People need temporary access to products they do not want to purchase."
            $customer = "Consumers and small businesses"
            $mechanism = "Enable local rental of underused assets."
            $launchModel = "Focus on one highly specific rental category."
        }

        "STORAGE" {

            $ideaName = "Distributed storage marketplace"
            $problem = "Unused storage capacity exists while customers need flexible low-cost storage."
            $customer = "Consumers and small businesses"
            $mechanism = "Connect people with unused storage space."
            $launchModel = "Start with one city and one storage use case."
        }

        "DELIVERY_LOGISTICS" {

            $ideaName = "Niche local delivery service"
            $problem = "Traditional delivery services are expensive or poorly adapted to specific local needs."
            $customer = "Consumers and small businesses"
            $mechanism = "Offer a focused delivery workflow for a specific underserved use case."
            $launchModel = "Target one niche before expanding."
        }

        "AUTO_SERVICES" {

            $ideaName = "Specialized automotive service platform"
            $problem = "Vehicle owners struggle to compare, schedule and trust local automotive services."
            $customer = "Vehicle owners"
            $mechanism = "Simplify discovery and booking for a specific automotive need."
            $launchModel = "Start with one service category."
        }

        "CHILDCARE" {

            $ideaName = "Specialized childcare coordination platform"
            $problem = "Parents struggle to find suitable childcare matching precise schedules and needs."
            $customer = "Parents"
            $mechanism = "Improve matching between families and childcare providers."
            $launchModel = "Focus on a specific childcare niche."
        }

        default {

            $ideaName = "Specialized $vertical opportunity"
            $problem = "Existing providers and customers face fragmentation in this market."
            $customer = "Consumers or businesses in the target vertical"
            $mechanism = "Build a focused service around an underserved workflow."
            $launchModel = "Start with a narrow niche and geographic market."
        }
    }

    # ----------------------------------------------------------
    # MARKET VALIDATION SCORE
    # ----------------------------------------------------------

    $companyScore = [math]::Min(100, ([int]$companies * 4))
    $articleScore = [math]::Min(100, ([int]$articles * 2))
    $countryScore = [math]::Min(100, ([int]$countries * 20))

    $marketValidation = [math]::Round(
        ($companyScore * 0.45) +
        ($articleScore * 0.25) +
        ($countryScore * 0.30)
    )

    # ----------------------------------------------------------
    # REPLICATION SCORE
    # ----------------------------------------------------------

    $replicationScore = $replication

    if ($replicationScore -eq 0) {

        if ($soloFit -eq "EXCELLENT") {
            $replicationScore = 75
        }
        elseif ($soloFit -eq "GOOD") {
            $replicationScore = 60
        }
        else {
            $replicationScore = 40
        }
    }

    # ----------------------------------------------------------
    # ACCESSIBILITY
    # ----------------------------------------------------------

    $accessibility = [math]::Round(
        ((100 - $capital) * 0.55) +
        ((100 - $regulation) * 0.45)
    )

    # ----------------------------------------------------------
    # COMPETITION PENALTY
    #
    # Many companies validate demand but also indicate
    # stronger competition.
    # ----------------------------------------------------------

    $competitionPenalty = 0

    if ([int]$companies -ge 100) {
        $competitionPenalty = 30
    }
    elseif ([int]$companies -ge 50) {
        $competitionPenalty = 20
    }
    elseif ([int]$companies -ge 20) {
        $competitionPenalty = 12
    }
    elseif ([int]$companies -ge 10) {
        $competitionPenalty = 6
    }

    # ----------------------------------------------------------
    # OPPORTUNITY SCORE
    #
    # IMPORTANT:
    # This score is intrinsic to the opportunity.
    # It does NOT depend on a specific user's profile.
    # ----------------------------------------------------------

    $opportunityScore = [math]::Round(
        ($marketValidation * 0.35) +
        ($replicationScore * 0.25) +
        ($accessibility * 0.25) +
        ([int]$cluster.final_score * 0.15) -
        $competitionPenalty
    )

    $opportunityScore = [math]::Max(0, [math]::Min(100, $opportunityScore))

    # ----------------------------------------------------------
    # VERDICT
    # ----------------------------------------------------------

    if ($opportunityScore -ge 75) {
        $verdict = "HIGH POTENTIAL"
        $action = "INVESTIGATE"
    }
    elseif ($opportunityScore -ge 65) {
        $verdict = "PROMISING"
        $action = "VALIDATE"
    }
    elseif ($opportunityScore -ge 50) {
        $verdict = "WATCH"
        $action = "MONITOR"
    }
    else {
        $verdict = "LOW"
        $action = "IGNORE"
    }

    # ----------------------------------------------------------
    # EVIDENCE LEVEL
    # ----------------------------------------------------------

    if (
        [int]$companies -ge 10 -and
        [int]$countries -ge 2
    ) {
        $evidence = "STRONG"
    }
    elseif (
        [int]$companies -ge 5 -and
        [int]$articles -ge 5
    ) {
        $evidence = "MODERATE"
    }
    else {
        $evidence = "WEAK"
    }

    # ----------------------------------------------------------
    # IDEA OBJECT
    # ----------------------------------------------------------

    $ideas += [PSCustomObject]@{

        idea_name = $ideaName

        opportunity_score = $opportunityScore

        verdict = $verdict

        recommended_action = $action

        evidence_level = $evidence

        market_validation = $marketValidation

        replication_score = $replicationScore

        accessibility_score = $accessibility

        competition_penalty = $competitionPenalty

        business_model = $model

        vertical = $vertical

        customer = $customer

        problem = $problem

        mechanism = $mechanism

        launch_model = $launchModel

        company_count = [int]$companies

        article_count = [int]$articles

        country_count = [int]$countries

        solo_fit = $soloFit

        source_cluster_score = [int]$cluster.final_score

        capital_risk = $capital

        regulatory_risk = $regulation

        source_cluster = $cluster
    }
}

# --------------------------------------------------------------
# SORT
# --------------------------------------------------------------

$ideas = $ideas |
    Sort-Object opportunity_score -Descending

# --------------------------------------------------------------
# EXPORT
# --------------------------------------------------------------

$ideas |
    ConvertTo-Json -Depth 15 |
    Set-Content $outputFile -Encoding UTF8

# --------------------------------------------------------------
# DISPLAY
# --------------------------------------------------------------

Write-Host ""
Write-Host "=============================================================="
Write-Host " TOP CONCRETE OPPORTUNITIES"
Write-Host "=============================================================="
Write-Host ""

$ideas |
    Select-Object -First 30 `
        opportunity_score,
        verdict,
        evidence_level,
        business_model,
        vertical,
        company_count,
        article_count,
        country_count,
        market_validation,
        replication_score,
        accessibility_score,
        idea_name |
    Format-Table -Wrap -AutoSize

Write-Host ""
Write-Host "=============================================================="
Write-Host " TOP HIGH-POTENTIAL IDEAS"
Write-Host "=============================================================="
Write-Host ""

$ideas |
    Where-Object { $_.verdict -eq "HIGH POTENTIAL" } |
    Select-Object -First 10 `
        opportunity_score,
        idea_name,
        business_model,
        vertical,
        market_validation,
        replication_score,
        evidence_level |
    Format-Table -Wrap -AutoSize

Write-Host ""
Write-Host "=============================================================="
Write-Host " OUTPUT : $outputFile"
Write-Host " IDEAS  : $($ideas.Count)"
Write-Host "=============================================================="
Write-Host ""
