$inputFile = ".\radar11_opportunities_enriched.json"
$sourceFile = ".\radar9_1_clusters.json"
$outputFile = ".\radar12_opportunities.json"

$data = Get-Content $inputFile -Raw | ConvertFrom-Json
$sources = Get-Content $sourceFile -Raw | ConvertFrom-Json

# ============================================================
# RADAR 12 - SOURCE DRIVEN OPPORTUNITY TITLES
# ============================================================

function Get-OpportunityTitle {
    param(
        [string]$model,
        [string]$vertical,
        [array]$articles
    )

    $text = (($articles | ForEach-Object { $_.title }) -join " ").ToLower()

    # HOME SERVICES
    if ($vertical -eq "HOME_SERVICES") {

        if ($text -match "cleaning|cleaner|housekeeping|maid") {
            return "Réservation de services de ménage à domicile"
        }

        if ($text -match "maintenance|handyman|home repair|home improvement") {
            return "Réservation à la demande de petits travaux et entretien du logement"
        }

        if ($text -match "plumb|electric|hvac|heating|air conditioning") {
            return "Mise en relation instantanée avec des artisans du logement"
        }

        return "Réservation à la demande de services à domicile"
    }

    # PET SERVICES
    if ($vertical -eq "PET_SERVICES") {

        if ($text -match "dog walk|dog walking|walker") {
            return "Marketplace locale de promenade de chiens"
        }

        if ($text -match "pet sit|pet sitting|boarding") {
            return "Garde d'animaux entre particuliers avec réservation locale"
        }

        return "Marketplace locale de garde et soins pour animaux"
    }

    # RENTAL
    if ($vertical -eq "RENTAL") {

        if ($text -match "fashion|clothing|dress|apparel") {
            return "Location de vêtements et accessoires plutôt que leur achat"
        }

        if ($text -match "furniture|furnish") {
            return "Location de mobilier pour particuliers et logements"
        }

        if ($text -match "equipment|tool|gear") {
            return "Location locale de matériel et équipements entre particuliers"
        }

        if ($text -match "space|property|storage|room|garage") {
            return "Location d'espaces inutilisés entre particuliers"
        }

        return "Location entre particuliers d'objets et équipements peu utilisés"
    }

    # DELIVERY
    if ($vertical -eq "DELIVERY_LOGISTICS") {

        if ($text -match "food|restaurant|meal") {
            return "Livraison ultra-rapide de repas dans les zones urbaines"
        }

        if ($text -match "drone") {
            return "Livraison locale automatisée par drone"
        }

        if ($text -match "same.day|instant|on.demand") {
            return "Réseau de livraison locale à la demande pour commerces"
        }

        return "Réseau de livraison locale pour commerces sans flotte"
    }

    # REPAIR
    if ($vertical -eq "REPAIR") {

        if ($text -match "phone|smartphone|mobile") {
            return "Réparation de smartphones avec réservation locale"
        }

        if ($text -match "appliance|washing machine|refrigerator") {
            return "Réparation d'électroménager à domicile"
        }

        if ($text -match "car|auto|vehicle") {
            return "Réparation automobile avec intervention locale"
        }

        return "Réservation en ligne de réparateurs locaux"
    }

    # STORAGE
    if ($vertical -eq "STORAGE") {

        if ($text -match "garage") {
            return "Transformer les garages inutilisés en stockage local à louer"
        }

        if ($text -match "peer.to.peer|marketplace|unused space|private space") {
            return "Stockage entre particuliers dans les espaces inutilisés"
        }

        return "Location d'espaces privés inutilisés comme stockage local"
    }

    # AUTO
    if ($vertical -eq "AUTO_SERVICES") {

        if ($text -match "mobile|doorstep|at.home|on.site") {
            return "Entretien automobile mobile directement chez le client"
        }

        if ($text -match "repair|maintenance|mechanic") {
            return "Réservation locale d'entretien et réparation automobile"
        }

        return "Services automobiles locaux réservables en ligne"
    }

    # CHILDCARE
    if ($vertical -eq "CHILDCARE") {

        if ($text -match "babysit|babysitter|childcare|nanny") {
            return "Mise en relation parents-baby-sitters avec réservation locale"
        }

        return "Marketplace locale de garde d'enfants"
    }

    # FALLBACK
    return $null
}

$results = foreach ($item in $data) {

    # Recherche du cluster correspondant
    $cluster = $sources |
        Where-Object {
            $_.business_model -eq $item.business_model -and
            $_.vertical -eq $item.vertical
        } |
        Select-Object -First 1

    $articles = @()

    if ($cluster -and $cluster.source_articles) {
        $articles = @($cluster.source_articles)
    }
    elseif ($cluster -and $cluster.articles) {
        $articles = @($cluster.articles)
    }

    $newTitle = Get-OpportunityTitle `
        -model $item.business_model `
        -vertical $item.vertical `
        -articles $articles

    if (!$newTitle) {
        $newTitle = $item.opportunity
    }

    [PSCustomObject]@{
        opportunity = $newTitle
        description = $item.description
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
        source_articles = $articles
    }
}

$results |
    Sort-Object score -Descending |
    ConvertTo-Json -Depth 15 |
    Set-Content $outputFile -Encoding UTF8

Write-Host ""
Write-Host "========================================"
Write-Host " BiznessHunter - Radar 12"
Write-Host " SOURCE DRIVEN OPPORTUNITIES"
Write-Host "========================================"
Write-Host ""
Write-Host "Input  : $inputFile"
Write-Host "Sources: $sourceFile"
Write-Host "Output : $outputFile"
Write-Host ""
Write-Host "Opportunities : $($results.Count)"
Write-Host ""

$results |
    Select-Object score,opportunity,company_count,country_count,demand,replication |
    Format-Table -AutoSize
