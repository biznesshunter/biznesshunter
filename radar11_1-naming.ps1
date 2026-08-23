$inputFile = ".\radar11_opportunities_enriched.json"
$outputFile = ".\radar11_1_named_opportunities.json"

$data = Get-Content $inputFile -Raw | ConvertFrom-Json

$names = @{
    "ON_DEMAND|HOME_SERVICES" = @{
        title = "On-demand home services marketplace"
        description = "Book trusted local professionals for urgent and everyday home services."
    }

    "OTHER|HOME_SERVICES" = @{
        title = "Local home maintenance & services platform"
        description = "Connect households with trusted local professionals for recurring home needs."
    }

    "OTHER|PET_SERVICES" = @{
        title = "Local dog walking & pet-sitting marketplace"
        description = "Connect pet owners with local walkers, sitters and pet-care providers."
    }

    "RENTAL|RENTAL" = @{
        title = "Peer-to-peer rental for underused assets"
        description = "Let people rent underused equipment, objects or spaces from others nearby."
    }

    "DELIVERY|DELIVERY_LOGISTICS" = @{
        title = "Local same-day delivery network"
        description = "Connect local businesses and consumers with independent delivery providers."
    }

    "OTHER|REPAIR" = @{
        title = "Local repair booking marketplace"
        description = "Help consumers find and book trusted local repair professionals."
    }

    "OTHER|STORAGE" = @{
        title = "Peer-to-peer garage & room storage"
        description = "Turn unused garages, rooms and private spaces into local storage capacity."
    }

    "ON_DEMAND|AUTO_SERVICES" = @{
        title = "Mobile car maintenance at your doorstep"
        description = "Bring routine vehicle maintenance and selected repairs directly to customers."
    }

    "OTHER|AUTO_SERVICES" = @{
        title = "Local car-service booking platform"
        description = "Connect vehicle owners with local mechanics and automotive service providers."
    }

    "MARKETPLACE|OTHER" = @{
        title = "Niche local marketplace"
        description = "A focused marketplace connecting local customers with specialized providers."
    }

    "RENTAL|OTHER" = @{
        title = "Niche local rental marketplace"
        description = "Build a focused rental marketplace around one underserved category."
    }

    "SUBSCRIPTION|HOME_SERVICES" = @{
        title = "Monthly home maintenance subscription"
        description = "Offer households recurring home maintenance through a simple monthly plan."
    }

    "OTHER|CHILDCARE" = @{
        title = "Local childcare services marketplace"
        description = "Connect families with trusted local childcare providers."
    }
}

$results = foreach ($item in $data) {

    $key = "$($item.business_model)|$($item.vertical)"

    if ($names.ContainsKey($key)) {
        $name = $names[$key]
        $title = $name.title
        $description = $name.description
    }
    else {
        $title = $item.opportunity
        $description = $item.description
    }

    [PSCustomObject]@{
        opportunity = $title
        description = $description
        why_now = $item.why_now
        launch_strategy = $item.launch_strategy
        target_customer = $item.target_customer
        difficulty = $item.difficulty
        score = $item.score
        verdict = $item.verdict
        confidence = $item.confidence
        company_count = $item.company_count
        country_count = $item.country_count
        replication = $item.replication
        demand = $item.demand
        business_model = $item.business_model
        vertical = $item.vertical
    }
}

$results |
    Sort-Object score -Descending |
    ConvertTo-Json -Depth 10 |
    Set-Content $outputFile -Encoding UTF8

Write-Host ""
Write-Host "========================================"
Write-Host " BiznessHunter - Radar 11.1"
Write-Host " OPPORTUNITY NAMING"
Write-Host "========================================"
Write-Host ""
Write-Host "Input  : $inputFile"
Write-Host "Output : $outputFile"
Write-Host ""
Write-Host "Opportunities : $($results.Count)"
Write-Host ""

$results |
    Select-Object score,opportunity,business_model,vertical,demand,replication |
    Format-Table -AutoSize
