$inputFile = ".\radar13_ideas_v2.json"
$outputFile = ".\radar14_concrete_ideas.json"

if (!(Test-Path $inputFile)) {
    Write-Host "ERROR: $inputFile not found"
    exit
}

$data = Get-Content $inputFile -Raw | ConvertFrom-Json

function Get-IdeaProfile {
    param(
        [string]$model,
        [string]$vertical,
        [int]$marketProof,
        [int]$replication,
        [int]$accessibility,
        [int]$competition
    )

    $key = "$model|$vertical"

    switch ($key) {

        "ON_DEMAND|HOME_SERVICES" {
            return @{
                idea = "Service de ménage / entretien ultra-spécialisé réservé aux besoins ponctuels urgents"
                customer = "Particuliers ayant besoin d'une intervention rapide"
                problem = "Les plateformes généralistes proposent une offre large mais ne sont pas optimisées pour les demandes urgentes ou très spécifiques"
                mechanism = "Réservation instantanée d'une prestation standardisée avec créneaux courts"
                monetization = "Commission par intervention + frais de réservation"
                wedge = "Urgence + spécialisation + réservation simple"
                existing_pattern = "On-demand home services"
            }
        }

        "OTHER|HOME_SERVICES" {
            return @{
                idea = "Plateforme verticale de services domestiques pour une tâche précise et récurrente"
                customer = "Ménages / propriétaires"
                problem = "Les services domestiques sont fragmentés et les clients doivent rechercher séparément chaque prestataire"
                mechanism = "Centraliser une seule catégorie de besoin avec réservation, prix et prestataires vérifiés"
                monetization = "Commission sur chaque prestation"
                wedge = "Verticalisation d'un besoin précis plutôt qu'une marketplace généraliste"
                existing_pattern = "Vertical home-services marketplace"
            }
        }

        "OTHER|PET_SERVICES" {
            return @{
                idea = "Service spécialisé pour un besoin récurrent des propriétaires d'animaux"
                customer = "Propriétaires d'animaux"
                problem = "Les propriétaires doivent trouver séparément des prestataires fiables pour des besoins spécialisés"
                mechanism = "Service verticalisé avec réservation et prestataires vérifiés"
                monetization = "Commission + abonnement premium éventuel"
                wedge = "Spécialisation sur un besoin précis du propriétaire"
                existing_pattern = "Vertical pet-services marketplace"
            }
        }

        "OTHER|REPAIR" {
            return @{
                idea = "Marketplace spécialisée de réparation pour un type précis d'objet ou d'équipement"
                customer = "Particuliers et petites entreprises"
                problem = "Trouver rapidement un réparateur compétent reste difficile pour les objets ou équipements spécifiques"
                mechanism = "Matching client-réparateur avec devis, disponibilité et spécialisation"
                monetization = "Commission sur réparation ou frais de mise en relation"
                wedge = "Une catégorie de réparation précise plutôt qu'une marketplace généraliste"
                existing_pattern = "Specialized repair marketplace"
            }
        }

        "OTHER|STORAGE" {
            return @{
                idea = "Réseau de stockage spécialisé utilisant des espaces sous-utilisés"
                customer = "Particuliers et petites entreprises"
                problem = "Le stockage classique est cher et souvent surdimensionné pour de petits besoins"
                mechanism = "Réserver au mètre cube / casier / espace inutilisé chez des particuliers ou entreprises"
                monetization = "Commission mensuelle sur le stockage"
                wedge = "Petits volumes + proximité + flexibilité"
                existing_pattern = "Distributed storage marketplace"
            }
        }

        "DELIVERY|DELIVERY_LOGISTICS" {
            return @{
                idea = "Livraison locale spécialisée pour une catégorie de besoins mal servie par les acteurs généralistes"
                customer = "Commerçants locaux et consommateurs"
                problem = "Les petits commerces ont besoin de livraisons flexibles sans supporter une logistique dédiée"
                mechanism = "Mise en relation automatisée entre commerces et livreurs locaux"
                monetization = "Commission par livraison"
                wedge = "Verticale locale précise + tournées optimisées"
                existing_pattern = "Local delivery network"
            }
        }

        "RENTAL|RENTAL" {
            return @{
                idea = "Marketplace de location verticale pour un objet coûteux mais utilisé rarement"
                customer = "Particuliers et petites entreprises"
                problem = "Acheter certains équipements coûte cher alors qu'ils sont utilisés occasionnellement"
                mechanism = "Location locale entre propriétaires et utilisateurs"
                monetization = "Commission sur chaque location"
                wedge = "Une catégorie d'équipement précise + proximité"
                existing_pattern = "Peer-to-peer rental marketplace"
            }
        }

        "MARKETPLACE|OTHER" {
            return @{
                idea = "Marketplace verticale reliant une catégorie précise de clients à une catégorie précise de fournisseurs"
                customer = "Acheteurs d'un besoin spécifique"
                problem = "Les marketplaces généralistes créent trop de bruit et rendent la sélection difficile"
                mechanism = "Catalogue spécialisé avec fournisseurs vérifiés et matching"
                monetization = "Commission ou abonnement fournisseur"
                wedge = "Verticalisation extrême"
                existing_pattern = "Vertical marketplace"
            }
        }

        "OTHER|AUTO_SERVICES" {
            return @{
                idea = "Service automobile spécialisé à domicile pour une opération simple et standardisable"
                customer = "Propriétaires de véhicules"
                problem = "Certaines interventions automobiles nécessitent un déplacement inutile vers un garage"
                mechanism = "Réservation d'un technicien mobile avec prix fixe"
                monetization = "Marge sur prestation ou commission"
                wedge = "Mobile + prix transparent + intervention rapide"
                existing_pattern = "Mobile auto-services"
            }
        }

        "OTHER|CHILDCARE" {
            return @{
                idea = "Service de garde spécialisé pour un besoin ponctuel difficile à couvrir"
                customer = "Parents"
                problem = "Les solutions traditionnelles sont peu flexibles pour les besoins ponctuels"
                mechanism = "Matching entre parents et intervenants vérifiés pour des créneaux spécifiques"
                monetization = "Commission ou abonnement"
                wedge = "Besoin précis + réservation flexible"
                existing_pattern = "Specialized childcare marketplace"
            }
        }

        "SOFTWARE|OTHER" {
            return @{
                idea = "Micro-SaaS vertical automatisant une tâche administrative répétitive dans un métier précis"
                customer = "Indépendants et petites entreprises"
                problem = "Une tâche récurrente reste gérée manuellement faute d'outil spécialisé"
                mechanism = "Automatiser un workflow unique plutôt que construire un logiciel complet"
                monetization = "Abonnement mensuel"
                wedge = "Un seul problème métier très précis"
                existing_pattern = "Vertical micro-SaaS"
            }
        }

        default {
            return @{
                idea = "Service verticalisé autour d'un besoin récurrent clairement identifié"
                customer = "Consommateurs ou petites entreprises"
                problem = "Un besoin récurrent reste mal servi par les solutions généralistes"
                mechanism = "Créer une offre spécialisée avec acquisition et exécution standardisées"
                monetization = "Commission, abonnement ou marge sur prestation"
                wedge = "Niche précise plutôt que marché généraliste"
                existing_pattern = "Vertical niche business"
            }
        }
    }
}

$results = foreach ($item in $data) {

    $model = [string]$item.business_model
    $vertical = [string]$item.vertical

    $marketProof = [int]$item.market_proof_score
    $replication = [int]$item.replication_score
    $accessibility = [int]$item.accessibility_score
    $competition = [int]$item.competition_score

    $companyCount = [int]$item.company_count
    $articleCount = [int]$item.relevant_article_count
    $countryCount = [int]$item.country_count

    $profile = Get-IdeaProfile `
        -model $model `
        -vertical $vertical `
        -marketProof $marketProof `
        -replication $replication `
        -accessibility $accessibility `
        -competition $competition

    # ============================================
    # CLIENT-WORTHY SCORE
    # ============================================

    $evidence = [math]::Min(100,
        ($companyCount * 1.5) +
        ($articleCount * 0.7) +
        ($countryCount * 8)
    )

    $market = $marketProof

    $execution = (
        $replication * 0.35 +
        $accessibility * 0.35 +
        ((100 - $competition) * 0.30)
    )

    $clientValue = (
        $market * 0.30 +
        $evidence * 0.25 +
        $execution * 0.25 +
        $replication * 0.20
    )

    $clientValue = [math]::Round([math]::Min(100,$clientValue))

    # ============================================
    # CONFIDENCE
    # ============================================

    if ($companyCount -ge 15 -and $articleCount -ge 20 -and $countryCount -ge 2) {
        $confidence = "VERY HIGH"
    }
    elseif ($companyCount -ge 8 -and $articleCount -ge 10) {
        $confidence = "HIGH"
    }
    elseif ($companyCount -ge 3 -and $articleCount -ge 5) {
        $confidence = "MEDIUM"
    }
    else {
        $confidence = "LOW"
    }

    # ============================================
    # VERDICT
    # ============================================

    if ($clientValue -ge 75 -and $confidence -in @("VERY HIGH","HIGH")) {
        $verdict = "CLIENT-WORTHY"
        $action = "SHOW TO CLIENT"
    }
    elseif ($clientValue -ge 65) {
        $verdict = "PROMISING"
        $action = "VALIDATE"
    }
    elseif ($clientValue -ge 50) {
        $verdict = "WATCH"
        $action = "MONITOR"
    }
    else {
        $verdict = "REJECT"
        $action = "IGNORE"
    }

    # ============================================
    # DIFFERENTIATION
    # ============================================

    if ($competition -le 40) {
        $competitionLevel = "LOW"
    }
    elseif ($competition -le 65) {
        $competitionLevel = "MEDIUM"
    }
    else {
        $competitionLevel = "HIGH"
    }

    # ============================================
    # IDEA QUALITY
    # ============================================

    $ideaQuality = 0

    if ($marketProof -ge 70) { $ideaQuality += 25 }
    if ($replication -ge 60) { $ideaQuality += 20 }
    if ($accessibility -ge 70) { $ideaQuality += 20 }
    if ($competition -le 60) { $ideaQuality += 15 }
    if ($companyCount -ge 5) { $ideaQuality += 10 }
    if ($countryCount -ge 2) { $ideaQuality += 10 }

    [PSCustomObject]@{
        idea_name = $profile.idea
        vertical = $vertical
        business_model = $model

        verdict = $verdict
        action = $action
        client_worthy_score = $clientValue
        idea_quality_score = $ideaQuality
        confidence = $confidence

        customer = $profile.customer
        problem = $profile.problem
        mechanism = $profile.mechanism
        monetization = $profile.monetization
        differentiation = $profile.wedge

        market_proof = $marketProof
        replication = $replication
        accessibility = $accessibility
        competition = $competition
        competition_level = $competitionLevel

        company_count = $companyCount
        article_count = $articleCount
        country_count = $countryCount

        evidence = "$companyCount companies / $articleCount relevant articles / $countryCount countries"

        existing_pattern = $profile.existing_pattern

        source_cluster = "$model / $vertical"
    }
}

$results = $results |
    Sort-Object client_worthy_score -Descending

$results |
    ConvertTo-Json -Depth 10 |
    Set-Content $outputFile -Encoding UTF8

Write-Host ""
Write-Host "=============================================================="
Write-Host " BIZNESSHUNTER - RADAR 14"
Write-Host " CLIENT-WORTHY IDEA ENGINE"
Write-Host "=============================================================="
Write-Host ""
Write-Host "Input    : $inputFile"
Write-Host "Output   : $outputFile"
Write-Host "Ideas    : $($results.Count)"
Write-Host ""

Write-Host "TOP CLIENT-WORTHY IDEAS"
Write-Host "--------------------------------------------------------------"
Write-Host ""

$results |
    Select-Object -First 20 `
        client_worthy_score,
        verdict,
        action,
        confidence,
        idea_name,
        business_model,
        vertical,
        company_count,
        article_count,
        country_count,
        market_proof,
        replication,
        competition |
    Format-Table -Wrap -AutoSize

Write-Host ""
Write-Host "=============================================================="
Write-Host " RADAR 14 COMPLETE"
Write-Host "=============================================================="
