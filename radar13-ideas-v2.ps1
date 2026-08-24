$inputFile = ".\radar12_final_opportunities.json"
$outputFile = ".\radar13_ideas_v2.json"

if (!(Test-Path $inputFile)) {
    Write-Host "ERROR: $inputFile not found"
    exit
}

$data = Get-Content $inputFile -Raw | ConvertFrom-Json

Write-Host ""
Write-Host "=============================================================="
Write-Host " BIZNESSHUNTER - RADAR 13 V2"
Write-Host " EVIDENCE-BASED OPPORTUNITY DISCOVERY ENGINE"
Write-Host "=============================================================="
Write-Host ""

$ideas = @()

# ==============================================================
# HELPERS
# ==============================================================

function Get-IntValue {
    param(
        $Object,
        [string]$Property,
        [int]$Default = 0
    )

    if ($null -eq $Object) {
        return $Default
    }

    if ($Object.PSObject.Properties.Name -contains $Property) {
        try {
            return [int]$Object.$Property
        }
        catch {
            return $Default
        }
    }

    return $Default
}

function Normalize-Text {
    param([string]$Text)

    if (!$Text) {
        return ""
    }

    $t = $Text.ToLower()

    $t = $t -replace '[^\p{L}\p{N}\s]', ' '
    $t = $t -replace '\s+', ' '

    return $t.Trim()
}

function Get-Pattern {
    param(
        [string]$Text,
        [string]$Vertical,
        [string]$Model
    )

    $t = Normalize-Text $Text

    # ----------------------------------------------------------
    # HOME SERVICES
    # ----------------------------------------------------------

    if ($Vertical -eq "HOME_SERVICES") {

        if ($t -match 'clean|cleaning|housekeeping|maid|home cleaning') {
            return "home_cleaning"
        }

        if ($t -match 'laundry|wash|ironing') {
            return "laundry"
        }

        if ($t -match 'handyman|maintenance|plumb|electric|repair|fix') {
            return "home_maintenance"
        }

        if ($t -match 'beauty|hair|nail|massage|wellness') {
            return "beauty_wellness_at_home"
        }

        if ($t -match 'pest|insect|mosquito|termite') {
            return "pest_control"
        }

        if ($t -match 'moving|removal|relocation') {
            return "moving"
        }

        if ($t -match 'garden|lawn|landscap') {
            return "gardening"
        }

        if ($t -match 'elder|senior|care') {
            return "elder_home_support"
        }

        if ($t -match 'pet') {
            return "pet_home_service"
        }

        return "home_service_general"
    }

    # ----------------------------------------------------------
    # PET SERVICES
    # ----------------------------------------------------------

    if ($Vertical -eq "PET_SERVICES") {

        if ($t -match 'walk|walking|dog walking') {
            return "dog_walking"
        }

        if ($t -match 'groom|grooming') {
            return "pet_grooming"
        }

        if ($t -match 'sit|sitting|boarding|daycare') {
            return "pet_sitting"
        }

        if ($t -match 'vet|veterinary|health') {
            return "pet_health"
        }

        if ($t -match 'food|nutrition|meal') {
            return "pet_food"
        }

        if ($t -match 'training|trainer|behavio') {
            return "pet_training"
        }

        if ($t -match 'insurance') {
            return "pet_insurance"
        }

        return "pet_services_general"
    }

    # ----------------------------------------------------------
    # REPAIR
    # ----------------------------------------------------------

    if ($Vertical -eq "REPAIR") {

        if ($t -match 'phone|smartphone|iphone|mobile') {
            return "phone_repair"
        }

        if ($t -match 'computer|laptop|macbook|pc') {
            return "computer_repair"
        }

        if ($t -match 'car|auto|vehicle') {
            return "automotive_repair"
        }

        if ($t -match 'appliance|washing machine|fridge|refrigerator|oven') {
            return "appliance_repair"
        }

        if ($t -match 'bike|bicycle|cycling') {
            return "bike_repair"
        }

        if ($t -match 'shoe|clothing|garment') {
            return "clothing_repair"
        }

        return "repair_general"
    }

    # ----------------------------------------------------------
    # RENTAL
    # ----------------------------------------------------------

    if ($Vertical -eq "RENTAL") {

        if ($t -match 'tool|equipment|machinery') {
            return "equipment_rental"
        }

        if ($t -match 'car|vehicle|van') {
            return "vehicle_rental"
        }

        if ($t -match 'event|party|wedding') {
            return "event_rental"
        }

        if ($t -match 'baby|child|stroller|crib') {
            return "baby_equipment_rental"
        }

        if ($t -match 'fashion|dress|clothing') {
            return "fashion_rental"
        }

        if ($t -match 'sports|ski|bike|surf') {
            return "sports_rental"
        }

        if ($t -match 'camera|photo|photography') {
            return "camera_equipment_rental"
        }

        return "rental_general"
    }

    # ----------------------------------------------------------
    # STORAGE
    # ----------------------------------------------------------

    if ($Vertical -eq "STORAGE") {

        if ($t -match 'self storage|storage unit|locker') {
            return "self_storage"
        }

        if ($t -match 'peer|unused space|space sharing|marketplace') {
            return "peer_storage"
        }

        if ($t -match 'vehicle|car|rv|boat') {
            return "vehicle_storage"
        }

        if ($t -match 'business|commercial') {
            return "business_storage"
        }

        return "storage_general"
    }

    # ----------------------------------------------------------
    # DELIVERY
    # ----------------------------------------------------------

    if ($Vertical -eq "DELIVERY_LOGISTICS") {

        if ($t -match 'food|restaurant|meal') {
            return "food_delivery"
        }

        if ($t -match 'grocery|supermarket|shopping') {
            return "grocery_delivery"
        }

        if ($t -match 'parcel|package|last mile|courier') {
            return "last_mile_delivery"
        }

        if ($t -match 'medical|medicine|pharmacy') {
            return "medical_delivery"
        }

        if ($t -match 'same day|instant|on demand') {
            return "instant_delivery"
        }

        if ($t -match 'business|b2b|merchant') {
            return "b2b_delivery"
        }

        return "delivery_general"
    }

    # ----------------------------------------------------------
    # AUTO SERVICES
    # ----------------------------------------------------------

    if ($Vertical -eq "AUTO_SERVICES") {

        if ($t -match 'wash|car wash|detailing') {
            return "mobile_car_care"
        }

        if ($t -match 'maintenance|service|mechanic') {
            return "auto_maintenance"
        }

        if ($t -match 'repair') {
            return "auto_repair"
        }

        if ($t -match 'inspection|diagnostic') {
            return "vehicle_diagnostics"
        }

        if ($t -match 'parking') {
            return "parking"
        }

        return "auto_services_general"
    }

    # ----------------------------------------------------------
    # CHILDCARE
    # ----------------------------------------------------------

    if ($Vertical -eq "CHILDCARE") {

        if ($t -match 'babysit|babysitting') {
            return "babysitting"
        }

        if ($t -match 'daycare|childcare') {
            return "childcare"
        }

        if ($t -match 'after school|school') {
            return "after_school"
        }

        if ($t -match 'nanny') {
            return "nanny"
        }

        return "childcare_general"
    }

    # ----------------------------------------------------------
    # FALLBACK
    # ----------------------------------------------------------

    return ($Vertical + "_" + $Model).ToLower()
}

function Get-IdeaName {
    param(
        [string]$Pattern,
        [string]$Vertical
    )

    switch ($Pattern) {

        "home_cleaning" {
            return "Specialized on-demand home cleaning"
        }

        "laundry" {
            return "Local on-demand laundry service"
        }

        "home_maintenance" {
            return "On-demand home maintenance network"
        }

        "beauty_wellness_at_home" {
            return "At-home beauty and wellness booking"
        }

        "pest_control" {
            return "On-demand pest control marketplace"
        }

        "moving" {
            return "Flexible local moving service"
        }

        "gardening" {
            return "On-demand gardening marketplace"
        }

        "elder_home_support" {
            return "Local home support for seniors"
        }

        "dog_walking" {
            return "Specialized dog walking platform"
        }

        "pet_grooming" {
            return "Local pet grooming marketplace"
        }

        "pet_sitting" {
            return "Trusted pet sitting network"
        }

        "pet_health" {
            return "Specialized pet health service"
        }

        "pet_food" {
            return "Specialized pet food service"
        }

        "pet_training" {
            return "Pet training marketplace"
        }

        "phone_repair" {
            return "Local smartphone repair marketplace"
        }

        "computer_repair" {
            return "Local computer repair network"
        }

        "automotive_repair" {
            return "Specialized automotive repair marketplace"
        }

        "appliance_repair" {
            return "Home appliance repair marketplace"
        }

        "bike_repair" {
            return "Mobile bicycle repair service"
        }

        "clothing_repair" {
            return "Local clothing repair network"
        }

        "equipment_rental" {
            return "Niche local equipment rental marketplace"
        }

        "vehicle_rental" {
            return "Specialized local vehicle rental"
        }

        "event_rental" {
            return "Niche event equipment rental"
        }

        "baby_equipment_rental" {
            return "Baby equipment rental marketplace"
        }

        "fashion_rental" {
            return "Specialized fashion rental"
        }

        "sports_rental" {
            return "Niche sports equipment rental"
        }

        "camera_equipment_rental" {
            return "Local camera equipment rental"
        }

        "peer_storage" {
            return "Peer-to-peer storage marketplace"
        }

        "vehicle_storage" {
            return "Vehicle storage marketplace"
        }

        "business_storage" {
            return "Flexible business storage marketplace"
        }

        "medical_delivery" {
            return "Specialized medical delivery service"
        }

        "b2b_delivery" {
            return "Niche B2B local delivery network"
        }

        "last_mile_delivery" {
            return "Specialized last-mile delivery"
        }

        "mobile_car_care" {
            return "Mobile car care service"
        }

        "auto_maintenance" {
            return "Automotive maintenance booking platform"
        }

        "vehicle_diagnostics" {
            return "Vehicle diagnostics service"
        }

        "parking" {
            return "Specialized parking marketplace"
        }

        "babysitting" {
            return "Specialized babysitting marketplace"
        }

        "after_school" {
            return "After-school childcare coordination"
        }

        "nanny" {
            return "Specialized nanny marketplace"
        }

        default {
            return "Specialized $Vertical opportunity"
        }
    }
}

function Get-PatternProblem {
    param([string]$Pattern)

    switch ($Pattern) {

        "home_cleaning" {
            return "Customers struggle to find reliable cleaners with convenient availability."
        }

        "laundry" {
            return "Customers need convenient laundry help without committing to a traditional provider."
        }

        "home_maintenance" {
            return "Small household jobs are fragmented across many local providers."
        }

        "beauty_wellness_at_home" {
            return "Customers want convenient services without travelling to a salon or studio."
        }

        "pest_control" {
            return "Customers need fast access to trustworthy pest-control providers."
        }

        "dog_walking" {
            return "Pet owners need reliable recurring dog-walking availability."
        }

        "pet_grooming" {
            return "Pet owners struggle to find convenient grooming appointments."
        }

        "pet_sitting" {
            return "Pet owners need trusted care when they are away."
        }

        "phone_repair" {
            return "Consumers need trustworthy repairs with transparent pricing and fast turnaround."
        }

        "computer_repair" {
            return "Consumers and small businesses need convenient local technical repair."
        }

        "appliance_repair" {
            return "Finding trustworthy appliance repair technicians is fragmented."
        }

        "bike_repair" {
            return "Cyclists need convenient repairs without transporting their bicycle."
        }

        "equipment_rental" {
            return "Customers need expensive or rarely used equipment temporarily."
        }

        "event_rental" {
            return "Event organizers need temporary access to equipment without purchasing it."
        }

        "baby_equipment_rental" {
            return "Families need baby equipment temporarily without buying it."
        }

        "sports_rental" {
            return "Customers want temporary access to expensive sports equipment."
        }

        "camera_equipment_rental" {
            return "Creators need professional equipment without owning it."
        }

        "peer_storage" {
            return "Unused private storage capacity exists while nearby customers need affordable space."
        }

        "vehicle_storage" {
            return "Vehicle owners need flexible storage when residential space is limited."
        }

        "medical_delivery" {
            return "Healthcare-related deliveries require reliable local logistics."
        }

        "b2b_delivery" {
            return "Small businesses often lack efficient local delivery infrastructure."
        }

        "mobile_car_care" {
            return "Vehicle owners want maintenance and cleaning without visiting a garage."
        }

        "parking" {
            return "Drivers need convenient access to underused parking capacity."
        }

        default {
            return "The market appears fragmented around a recurring customer need."
        }
    }
}

function Get-Mechanism {
    param([string]$Pattern)

    switch ($Pattern) {

        "home_cleaning" {
            return "Aggregate vetted local providers and simplify booking."
        }

        "laundry" {
            return "Coordinate pickup, processing and delivery through a lightweight local network."
        }

        "home_maintenance" {
            return "Match small jobs with available local professionals."
        }

        "beauty_wellness_at_home" {
            return "Enable consumers to book verified professionals at home."
        }

        "dog_walking" {
            return "Match recurring walking demand with trusted local walkers."
        }

        "pet_grooming" {
            return "Aggregate groomers and simplify appointment discovery."
        }

        "pet_sitting" {
            return "Match pet owners with verified sitters and manage bookings."
        }

        "phone_repair" {
            return "Compare, book and coordinate repairs with local specialists."
        }

        "computer_repair" {
            return "Connect customers with local technicians."
        }

        "appliance_repair" {
            return "Match appliance problems with available technicians."
        }

        "bike_repair" {
            return "Bring repair directly to the customer."
        }

        "equipment_rental" {
            return "Aggregate underused equipment and facilitate local rentals."
        }

        "event_rental" {
            return "Connect event demand with underused local equipment."
        }

        "baby_equipment_rental" {
            return "Provide temporary local access to baby equipment."
        }

        "sports_rental" {
            return "Aggregate local equipment and enable short-term rentals."
        }

        "camera_equipment_rental" {
            return "Enable creators to access equipment locally for short periods."
        }

        "peer_storage" {
            return "Connect unused storage capacity with local demand."
        }

        "vehicle_storage" {
            return "Match unused private or commercial space with vehicle owners."
        }

        "medical_delivery" {
            return "Coordinate specialized local delivery requirements."
        }

        "b2b_delivery" {
            return "Provide focused delivery infrastructure for small merchants."
        }

        "mobile_car_care" {
            return "Send service providers directly to vehicle owners."
        }

        "parking" {
            return "Aggregate underused parking capacity and match it with demand."
        }

        default {
            return "Create a focused marketplace or service around the identified need."
        }
    }
}

# ==============================================================
# PROCESS CLUSTERS
# ==============================================================

foreach ($cluster in $data) {

    $finalScore = Get-IntValue $cluster "final_score"

    if ($finalScore -lt 50) {
        continue
    }

    $vertical = [string]$cluster.vertical
    $model = [string]$cluster.business_model

    $companyCount = Get-IntValue $cluster "company_count"
    $articleCount = Get-IntValue $cluster "article_count"
    $countryCount = Get-IntValue $cluster "country_count"

    $replication = Get-IntValue $cluster "avg_replication"
    $capital = Get-IntValue $cluster "avg_capital_risk" 50
    $regulation = Get-IntValue $cluster "avg_regulatory_risk" 50

    # ----------------------------------------------------------
    # COLLECT SOURCE ARTICLES
    # ----------------------------------------------------------

    $patternCounts = @{}
    $patternArticles = @{}
    $patternCompanies = @{}

    $articles = @()

    if ($cluster.PSObject.Properties.Name -contains "source_articles") {
        $articles = @($cluster.source_articles)
    }

    foreach ($article in $articles) {

        $title = [string]$article.title

        if (!$title) {
            continue
        }

        $pattern = Get-Pattern `
            -Text $title `
            -Vertical $vertical `
            -Model $model

        if (!$patternCounts.ContainsKey($pattern)) {
            $patternCounts[$pattern] = 0
            $patternArticles[$pattern] = @()
            $patternCompanies[$pattern] = @()
        }

        $patternCounts[$pattern]++

        $patternArticles[$pattern] += $title

        if ($article.PSObject.Properties.Name -contains "company") {
            if ($article.company) {
                $patternCompanies[$pattern] += [string]$article.company
            }
        }
    }

    # ----------------------------------------------------------
    # FALLBACK
    # ----------------------------------------------------------

    if ($patternCounts.Count -eq 0) {

        $pattern = ($vertical + "_" + $model).ToLower()

        $patternCounts[$pattern] = $articleCount
        $patternArticles[$pattern] = @()
        $patternCompanies[$pattern] = @()
    }

    # ----------------------------------------------------------
    # CREATE SUB-NICHE IDEAS
    # ----------------------------------------------------------

    foreach ($pattern in $patternCounts.Keys) {

        $signalArticles = [int]$patternCounts[$pattern]

        # Ignore microscopic patterns unless cluster is extremely strong.
        if (
            $signalArticles -lt 2 -and
            $finalScore -lt 70
        ) {
            continue
        }

        $ideaName = Get-IdeaName `
            -Pattern $pattern `
            -Vertical $vertical

        $problem = Get-PatternProblem $pattern
        $mechanism = Get-Mechanism $pattern

        # ------------------------------------------------------
        # SIGNAL SHARE
        # ------------------------------------------------------

        $signalShare = 0

        if ($articleCount -gt 0) {
            $signalShare = [math]::Round(
                ($signalArticles / $articleCount) * 100
            )
        }

        # ------------------------------------------------------
        # MARKET PROOF
        #
        # Evidence combines:
        # companies + articles + countries + cluster score.
        # ------------------------------------------------------

        $companyEvidence = [math]::Min(100, $companyCount * 5)
        $articleEvidence = [math]::Min(100, $articleCount * 2)
        $countryEvidence = [math]::Min(100, $countryCount * 25)

        $marketProof = [math]::Round(
            ($companyEvidence * 0.35) +
            ($articleEvidence * 0.20) +
            ($countryEvidence * 0.20) +
            ($finalScore * 0.25)
        )

        # ------------------------------------------------------
        # NICHE SIGNAL
        #
        # A concentrated recurring pattern is useful.
        # But extremely dominant patterns can indicate generic
        # markets rather than differentiated niches.
        # ------------------------------------------------------

        if ($signalShare -ge 70) {
            $nicheSignal = 60
        }
        elseif ($signalShare -ge 40) {
            $nicheSignal = 80
        }
        elseif ($signalShare -ge 20) {
            $nicheSignal = 90
        }
        elseif ($signalShare -ge 10) {
            $nicheSignal = 75
        }
        else {
            $nicheSignal = 50
        }

        # ------------------------------------------------------
        # ACCESSIBILITY
        # ------------------------------------------------------

        $accessibility = [math]::Round(
            ((100 - $capital) * 0.55) +
            ((100 - $regulation) * 0.45)
        )

        # ------------------------------------------------------
        # REPLICATION
        # ------------------------------------------------------

        if ($replication -le 0) {
            $replication = 50
        }

        # ------------------------------------------------------
        # COMPETITION
        #
        # Competition is not automatically negative.
        # We treat it as a market maturity indicator and only
        # penalize extreme concentration.
        # ------------------------------------------------------

        if ($companyCount -ge 100) {
            $competitionPressure = 85
        }
        elseif ($companyCount -ge 50) {
            $competitionPressure = 70
        }
        elseif ($companyCount -ge 20) {
            $competitionPressure = 55
        }
        elseif ($companyCount -ge 10) {
            $competitionPressure = 40
        }
        elseif ($companyCount -ge 5) {
            $competitionPressure = 25
        }
        else {
            $competitionPressure = 10
        }

        # ------------------------------------------------------
        # MARKET MATURITY
        # ------------------------------------------------------

        if (
            $companyCount -ge 10 -and
            $countryCount -ge 2
        ) {
            $maturity = "PROVEN"
        }
        elseif (
            $companyCount -ge 5 -or
            $articleCount -ge 10
        ) {
            $maturity = "EMERGING"
        }
        else {
            $maturity = "EARLY"
        }

        # ------------------------------------------------------
        # OPPORTUNITY SCORE
        #
        # No user-specific information.
        # ------------------------------------------------------

        $score = [math]::Round(
            ($marketProof * 0.30) +
            ($nicheSignal * 0.20) +
            ($replication * 0.20) +
            ($accessibility * 0.20) +
            ($finalScore * 0.10)
        )

        # Controlled competition adjustment.
        if ($competitionPressure -ge 85) {
            $score -= 8
        }
        elseif ($competitionPressure -ge 70) {
            $score -= 4
        }

        $score = [math]::Max(0, [math]::Min(100, $score))

        # ------------------------------------------------------
        # VERDICT
        # ------------------------------------------------------

        if ($score -ge 75) {
            $verdict = "HIGH POTENTIAL"
            $action = "DEEP VALIDATION"
        }
        elseif ($score -ge 65) {
            $verdict = "PROMISING"
            $action = "VALIDATE"
        }
        elseif ($score -ge 50) {
            $verdict = "WATCH"
            $action = "MONITOR"
        }
        else {
            $verdict = "LOW"
            $action = "IGNORE"
        }

        # ------------------------------------------------------
        # CONFIDENCE
        # ------------------------------------------------------

        if (
            $signalArticles -ge 5 -and
            $companyCount -ge 5 -and
            $countryCount -ge 2
        ) {
            $confidence = "HIGH"
        }
        elseif (
            $signalArticles -ge 3 -and
            $companyCount -ge 3
        ) {
            $confidence = "MEDIUM"
        }
        else {
            $confidence = "LOW"
        }

        # ------------------------------------------------------
        # ENTRY STRATEGY
        # ------------------------------------------------------

        if ($companyCount -ge 50) {
            $entryStrategy =
                "Do not compete horizontally. Enter through a narrow customer segment, geography, workflow or service specialization."
        }
        elseif ($companyCount -ge 10) {
            $entryStrategy =
                "Enter through a differentiated niche rather than reproducing the broad market."
        }
        else {
            $entryStrategy =
                "Validate the core demand first, then expand once repeatable demand is demonstrated."
        }

        # ------------------------------------------------------
        # CUSTOMER
        # ------------------------------------------------------

        switch ($vertical) {

            "HOME_SERVICES" {
                $customer = "Households / consumers"
            }

            "PET_SERVICES" {
                $customer = "Pet owners"
            }

            "REPAIR" {
                $customer = "Consumers and small businesses"
            }

            "RENTAL" {
                $customer = "Consumers and small businesses"
            }

            "STORAGE" {
                $customer = "Consumers and small businesses"
            }

            "DELIVERY_LOGISTICS" {
                $customer = "Consumers and local businesses"
            }

            "AUTO_SERVICES" {
                $customer = "Vehicle owners"
            }

            "CHILDCARE" {
                $customer = "Parents and families"
            }

            default {
                $customer = "Customers in the identified vertical"
            }
        }

        # ------------------------------------------------------
        # EVIDENCE SUMMARY
        # ------------------------------------------------------

        $evidenceSummary =
            "$companyCount companies, $articleCount articles, $countryCount countries; " +
            "$signalArticles relevant source signals for this sub-niche."

        # ------------------------------------------------------
        # IDEA OBJECT
        # ------------------------------------------------------

        $ideas += [PSCustomObject]@{

            idea_name = $ideaName

            opportunity_score = $score

            verdict = $verdict

            recommended_action = $action

            confidence = $confidence

            maturity = $maturity

            niche_pattern = $pattern

            business_model = $model

            vertical = $vertical

            customer = $customer

            problem = $problem

            mechanism = $mechanism

            entry_strategy = $entryStrategy

            market_proof_score = $marketProof

            niche_signal_score = $nicheSignal

            replication_score = $replication

            accessibility_score = $accessibility

            competition_pressure = $competitionPressure

            signal_share = $signalShare

            relevant_article_count = $signalArticles

            company_count = $companyCount

            article_count = $articleCount

            country_count = $countryCount

            capital_risk = $capital

            regulatory_risk = $regulation

            evidence_summary = $evidenceSummary

            source_titles = ($patternArticles[$pattern] | Select-Object -First 10)

            source_companies = (
                $patternCompanies[$pattern] |
                Where-Object { $_ } |
                Select-Object -Unique |
                Select-Object -First 20
            )
        }
    }
}

# ==============================================================
# DEDUPLICATION
# ==============================================================

$uniqueIdeas = @{}

foreach ($idea in $ideas) {

    $key = (
        $idea.niche_pattern +
        "|" +
        $idea.business_model +
        "|" +
        $idea.vertical
    )

    if (!$uniqueIdeas.ContainsKey($key)) {
        $uniqueIdeas[$key] = $idea
    }
    else {
        if (
            [int]$idea.opportunity_score -gt
            [int]$uniqueIdeas[$key].opportunity_score
        ) {
            $uniqueIdeas[$key] = $idea
        }
    }
}

$ideas = $uniqueIdeas.Values |
    Sort-Object opportunity_score -Descending

# ==============================================================
# EXPORT
# ==============================================================

$ideas |
    ConvertTo-Json -Depth 15 |
    Set-Content $outputFile -Encoding UTF8

# ==============================================================
# DISPLAY
# ==============================================================

Write-Host ""
Write-Host "=============================================================="
Write-Host " TOP OPPORTUNITY IDEAS"
Write-Host "=============================================================="
Write-Host ""

$ideas |
    Select-Object -First 30 `
        opportunity_score,
        verdict,
        confidence,
        maturity,
        business_model,
        vertical,
        relevant_article_count,
        company_count,
        country_count,
        market_proof_score,
        niche_signal_score,
        replication_score,
        accessibility_score,
        idea_name |
    Format-Table -Wrap -AutoSize

Write-Host ""
Write-Host "=============================================================="
Write-Host " HIGH POTENTIAL"
Write-Host "=============================================================="
Write-Host ""

$ideas |
    Where-Object {
        $_.verdict -eq "HIGH POTENTIAL"
    } |
    Select-Object `
        opportunity_score,
        confidence,
        idea_name,
        niche_pattern,
        market_proof_score,
        replication_score,
        accessibility_score,
        competition_pressure |
    Format-Table -Wrap -AutoSize

Write-Host ""
Write-Host "=============================================================="
Write-Host " OPPORTUNITY THESIS"
Write-Host "=============================================================="
Write-Host ""

$ideas |
    Select-Object -First 10 |
    ForEach-Object {

        Write-Host ""
        Write-Host "--------------------------------------------------------------"
        Write-Host "$($_.idea_name) [$($_.opportunity_score)/100]"
        Write-Host "--------------------------------------------------------------"

        Write-Host "Verdict       : $($_.verdict)"
        Write-Host "Confidence    : $($_.confidence)"
        Write-Host "Maturity      : $($_.maturity)"
        Write-Host "Pattern       : $($_.niche_pattern)"
        Write-Host ""
        Write-Host "Customer      : $($_.customer)"
        Write-Host "Problem       : $($_.problem)"
        Write-Host "Mechanism     : $($_.mechanism)"
        Write-Host ""
        Write-Host "Market proof  : $($_.market_proof_score)/100"
        Write-Host "Niche signal  : $($_.niche_signal_score)/100"
        Write-Host "Replication   : $($_.replication_score)/100"
        Write-Host "Accessibility : $($_.accessibility_score)/100"
        Write-Host "Competition   : $($_.competition_pressure)/100"
        Write-Host ""
        Write-Host "Entry strategy:"
        Write-Host "$($_.entry_strategy)"
        Write-Host ""
        Write-Host "Evidence:"
        Write-Host "$($_.evidence_summary)"
    }

Write-Host ""
Write-Host "=============================================================="
Write-Host " OUTPUT : $outputFile"
Write-Host " IDEAS  : $($ideas.Count)"
Write-Host "=============================================================="
Write-Host ""
