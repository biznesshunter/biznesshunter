$inputFile = ".\radar9_1_clusters.json"
$outputFile = ".\radar13_opportunities.json"

$data = Get-Content $inputFile -Raw | ConvertFrom-Json

function Get-SubOpportunity {
    param(
        [string]$vertical,
        [string]$text
    )

    $t = $text.ToLower()

    switch ($vertical) {

        "HOME_SERVICES" {

            if ($t -match "cleaning|cleaner|housekeeping|maid|cleaning service") {
                return "Marketplace de ménage à domicile"
            }

            if ($t -match "handyman|home repair|home improvement|maintenance") {
                return "Marketplace de petits travaux et entretien du logement"
            }

            if ($t -match "plumb|electric|hvac|heating|air conditioning") {
                return "Réservation d'artisans du bâtiment à domicile"
            }

            if ($t -match "garden|gardening|lawn|landscap") {
                return "Marketplace de jardinage et entretien extérieur"
            }

            if ($t -match "moving|movers|removal") {
                return "Marketplace de déménagement local"
            }

            return "Marketplace de services à domicile"
        }

        "PET_SERVICES" {

            if ($t -match "dog walk|dog walking|walker") {
                return "Marketplace de promenade de chiens"
            }

            if ($t -match "pet sit|pet sitting|pet sitter") {
                return "Marketplace de garde d'animaux à domicile"
            }

            if ($t -match "groom|grooming") {
                return "Réservation de toilettage pour animaux"
            }

            if ($t -match "veterinary|vet") {
                return "Services vétérinaires à la demande"
            }

            return "Marketplace de garde et soins pour animaux"
        }

        "RENTAL" {

            if ($t -match "fashion|clothing|dress|apparel") {
                return "Location de vêtements et accessoires"
            }

            if ($t -match "furniture|furnish") {
                return "Location de mobilier"
            }

            if ($t -match "tool|equipment|gear") {
                return "Location de matériel et équipements"
            }

            if ($t -match "car rental|vehicle rental|auto rental") {
                return "Location de véhicules entre particuliers"
            }

            if ($t -match "space|room|garage|property") {
                return "Location d'espaces inutilisés"
            }

            return "Marketplace de location entre particuliers"
        }

        "DELIVERY_LOGISTICS" {

            if ($t -match "food delivery|meal delivery|restaurant delivery") {
                return "Livraison de repas ultra-rapide"
            }

            if ($t -match "drone delivery|drone") {
                return "Livraison locale par drone"
            }

            if ($t -match "same.day|instant delivery|on-demand delivery") {
                return "Livraison locale à la demande"
            }

            if ($t -match "grocery|groceries") {
                return "Livraison rapide de courses alimentaires"
            }

            return "Réseau de livraison locale pour commerces"
        }

        "REPAIR" {

            if ($t -match "phone|smartphone|iphone|mobile") {
                return "Réparation de smartphones à la demande"
            }

            if ($t -match "appliance|washing machine|refrigerator|dishwasher") {
                return "Réparation d'électroménager à domicile"
            }

            if ($t -match "electronics|electronic") {
                return "Réparation d'appareils électroniques"
            }

            if ($t -match "shoe|clothing|fashion repair") {
                return "Réparation de vêtements et chaussures"
            }

            if ($t -match "car|auto|vehicle") {
                return "Réparation automobile à la demande"
            }

            return "Marketplace de réparateurs locaux"
        }

        "STORAGE" {

            if ($t -match "garage") {
                return "Location de garages inutilisés comme stockage"
            }

            if ($t -match "room|bedroom|house|home") {
                return "Location de pièces inutilisées comme stockage"
            }

            if ($t -match "peer.to.peer|p2p|unused space|private space") {
                return "Stockage entre particuliers"
            }

            return "Marketplace de stockage local"
        }

        "AUTO_SERVICES" {

            if ($t -match "mobile|doorstep|at.home|on.site") {
                return "Entretien automobile mobile à domicile"
            }

            if ($t -match "oil change|oil service") {
                return "Vidange et entretien automobile mobile"
            }

            if ($t -match "repair|mechanic|maintenance") {
                return "Réservation de réparation automobile"
            }

            return "Marketplace de services automobiles"
        }

        "CHILDCARE" {

            if ($t -match "babysit|babysitter") {
                return "Marketplace de baby-sitting local"
            }

            if ($t -match "nanny") {
                return "Mise en relation avec des nounous locales"
            }

            if ($t -match "daycare|childcare") {
                return "Marketplace de garde d'enfants"
            }

            return "Services de garde d'enfants à la demande"
        }

        default {
            return $null
        }
    }
}

$opportunities = @{}

foreach ($cluster in $data) {

    $vertical = [string]$cluster.vertical

    if (!$cluster.source_articles) {
        continue
    }

    foreach ($article in @($cluster.source_articles)) {

        $title = [string]$article.title

        if ([string]::IsNullOrWhiteSpace($title)) {
            continue
        }

        $sub = Get-SubOpportunity `
            -vertical $vertical `
            -text $title

        if (!$sub) {
            continue
        }

        if (!$opportunities.ContainsKey($sub)) {
            $opportunities[$sub] = [PSCustomObject]@{
                opportunity = $sub
                vertical = $vertical
                articles = @()
                article_count = 0
            }
        }

        $op = $opportunities[$sub]

        $op.articles += [PSCustomObject]@{
            title = $title
            url = $article.url
        }

        $op.article_count++
    }
}

$results = $opportunities.Values |
    Where-Object { $_.article_count -ge 2 } |
    Sort-Object article_count -Descending

$results |
    ConvertTo-Json -Depth 10 |
    Set-Content $outputFile -Encoding UTF8

Write-Host ""
Write-Host "========================================"
Write-Host " BiznessHunter - Radar 13"
Write-Host " SUB-OPPORTUNITY DISCOVERY"
Write-Host "========================================"
Write-Host ""
Write-Host "Input  : $inputFile"
Write-Host "Output : $outputFile"
Write-Host ""
Write-Host "Sub-opportunities : $($results.Count)"
Write-Host ""

$results |
    Select-Object -First 40 opportunity,vertical,article_count |
    Format-Table -AutoSize
