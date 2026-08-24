$inputFile = ".\radar15_business_concepts.json"
$outputFile = ".\radar16_client_opportunities.json"

if (!(Test-Path $inputFile)) {
    Write-Host "ERROR: $inputFile not found"
    exit
}

$data = Get-Content $inputFile -Raw | ConvertFrom-Json

function Get-NicheExpansion {
    param(
        [string]$angle,
        [string]$vertical,
        [string]$model
    )

    $key = "$angle|$vertical"

    switch -Wildcard ($key) {

        "Recurring maintenance|HOME_SERVICES" {
            return @{
                niche = "Maintenance préventive pour propriétaires de logements locatifs"
                customer = "Propriétaires de locations courte ou moyenne durée"
                problem = "Petites interventions récurrentes dispersées entre plusieurs prestataires"
                solution = "Abonnement regroupant inspections, petites réparations, entretien et interventions préventives"
                wedge = "Maintenance récurrente plutôt que marketplace généraliste"
                revenue = "Abonnement mensuel + marge sur interventions"
                automation = "Élevée"
                startup = "Faible à moyenne"
            }
        }

        "Urgent / same-day|HOME_SERVICES" {
            return @{
                niche = "Interventions domestiques standardisées sous 24 heures"
                customer = "Particuliers confrontés à une panne ou un problème domestique non critique"
                problem = "Difficulté à obtenir rapidement un professionnel avec prix et disponibilité clairs"
                solution = "Catalogue limité de prestations standardisées avec créneau garanti"
                wedge = "24h + prix fixe + disponibilité"
                revenue = "Commission + frais de réservation"
                automation = "Élevée"
                startup = "Faible"
            }
        }

        "Property turnover|HOME_SERVICES" {
            return @{
                niche = "Remise en état entre deux locataires"
                customer = "Bailleurs, gestionnaires locatifs et propriétaires de locations courte durée"
                problem = "Coordination de nettoyage, petites réparations, contrôle et préparation du logement"
                solution = "Pack de turnover avec checklist et coordination centralisée"
                wedge = "Un workflow complet plutôt que plusieurs services séparés"
                revenue = "Marge par turnover + abonnement professionnel"
                automation = "Élevée"
                startup = "Faible à moyenne"
            }
        }

        "Specialized care|PET_SERVICES" {
            return @{
                niche = "Services spécialisés pour animaux âgés ou nécessitant une prise en charge particulière"
                customer = "Propriétaires d'animaux avec besoins spécifiques"
                problem = "Difficulté à identifier des prestataires adaptés et disponibles"
                solution = "Réseau spécialisé avec profils vérifiés et réservation"
                wedge = "Segment animalier précis plutôt que garde d'animaux généraliste"
                revenue = "Commission + abonnement premium"
                automation = "Moyenne à élevée"
                startup = "Faible"
            }
        }

        "Pet recurring services|PET_SERVICES" {
            return @{
                niche = "Abonnement de services récurrents pour propriétaires d'animaux"
                customer = "Propriétaires utilisant régulièrement plusieurs services"
                problem = "Réservations répétitives et manque de continuité"
                solution = "Forfait mensuel regroupant plusieurs prestations"
                wedge = "Récurrence + fidélisation"
                revenue = "Abonnement mensuel + commission"
                automation = "Élevée"
                startup = "Faible"
            }
        }

        "Pet emergency|PET_SERVICES" {
            return @{
                niche = "Mise en relation rapide avec des services animaliers disponibles en urgence"
                customer = "Propriétaires confrontés à un besoin ponctuel non médical"
                problem = "Difficulté à trouver rapidement une solution fiable"
                solution = "Réseau de prestataires avec disponibilité en temps réel"
                wedge = "Disponibilité immédiate"
                revenue = "Commission + frais de service"
                automation = "Élevée"
                startup = "Faible à moyenne"
            }
        }

        "Rare-use equipment|RENTAL" {
            return @{
                niche = "Location locale d'équipements coûteux utilisés moins de quelques fois par an"
                customer = "Particuliers et micro-entreprises"
                problem = "Achat peu rentable pour un usage occasionnel"
                solution = "Marketplace spécialisée sur une seule catégorie d'équipement"
                wedge = "Une catégorie + une zone géographique"
                revenue = "Commission + assurance/frais de service"
                automation = "Élevée"
                startup = "Faible"
            }
        }

        "Professional equipment|RENTAL" {
            return @{
                niche = "Location flexible de matériel professionnel pour artisans"
                customer = "Artisans et petites entreprises"
                problem = "Besoin ponctuel de matériel coûteux sans volonté d'achat"
                solution = "Location courte durée avec disponibilité locale"
                wedge = "Professionnels + matériel spécialisé"
                revenue = "Commission sur location"
                automation = "Élevée"
                startup = "Faible à moyenne"
            }
        }

        "Event equipment|RENTAL" {
            return @{
                niche = "Location locale d'équipements événementiels spécialisés"
                customer = "Particuliers et petites entreprises"
                problem = "Équipement coûteux utilisé quelques fois par an"
                solution = "Catalogue local avec réservation et retrait/livraison"
                wedge = "Verticalisation événementielle"
                revenue = "Commission + livraison"
                automation = "Élevée"
                startup = "Faible"
            }
        }

        "B2B local repair|REPAIR" {
            return @{
                niche = "Réparation prioritaire d'équipements critiques pour petits commerces"
                customer = "Restaurants, commerces et petites entreprises"
                problem = "Une panne peut interrompre immédiatement l'activité"
                solution = "Réseau de réparateurs avec SLA et priorité"
                wedge = "Temps de résolution plutôt que simple mise en relation"
                revenue = "Abonnement + frais d'intervention"
                automation = "Élevée"
                startup = "Faible à moyenne"
            }
        }

        "Mobile repair|REPAIR" {
            return @{
                niche = "Réparation mobile d'équipements simples et standardisables"
                customer = "Particuliers et petites entreprises"
                problem = "Déplacement inutile vers un atelier"
                solution = "Technicien mobile réservé avec prix forfaitaire"
                wedge = "À domicile + prix fixe"
                revenue = "Marge sur intervention"
                automation = "Élevée"
                startup = "Moyenne"
            }
        }

        "Micro-storage|STORAGE" {
            return @{
                niche = "Stockage de très petits volumes à proximité du domicile"
                customer = "Particuliers ayant besoin de quelques cartons à quelques m3"
                problem = "Les box classiques sont souvent trop grands et trop chers"
                solution = "Réservation d'espace réellement utilisé"
                wedge = "Micro-volume + proximité"
                revenue = "Commission mensuelle"
                automation = "Très élevée"
                startup = "Faible"
            }
        }

        "Specialized delivery|DELIVERY_LOGISTICS" {
            return @{
                niche = "Livraison spécialisée pour une catégorie nécessitant des contraintes particulières"
                customer = "Commerces et professionnels d'une verticale précise"
                problem = "Les opérateurs généralistes ne sont pas adaptés à certaines contraintes"
                solution = "Réseau spécialisé avec procédures et créneaux adaptés"
                wedge = "Verticalisation logistique"
                revenue = "Commission par livraison"
                automation = "Élevée"
                startup = "Moyenne"
            }
        }

        "Scheduled delivery|DELIVERY_LOGISTICS" {
            return @{
                niche = "Livraison planifiée de produits volumineux pour commerces indépendants"
                customer = "Commerces vendant meubles, électroménager ou produits volumineux"
                problem = "Les petits commerçants ne peuvent pas maintenir leur propre flotte"
                solution = "Réseau local de livreurs avec réservation planifiée"
                wedge = "Planification + petits commerces"
                revenue = "Commission par livraison"
                automation = "Élevée"
                startup = "Moyenne"
            }
        }

        "Local business delivery|DELIVERY_LOGISTICS" {
            return @{
                niche = "Logistique externalisée pour petits commerces locaux"
                customer = "Commerces indépendants"
                problem = "Besoin de livraison sans volume suffisant pour négocier avec les grands opérateurs"
                solution = "Réseau mutualisé de livraison locale"
                wedge = "Mutualisation"
                revenue = "Commission + abonnement commerçant"
                automation = "Élevée"
                startup = "Moyenne"
            }
        }

        default {
            return @{
                niche = "Niche spécialisée dans $vertical"
                customer = "Clients ayant un besoin spécifique dans ce marché"
                problem = "Les solutions généralistes répondent imparfaitement à un besoin précis"
                solution = "Offre verticale avec workflow spécialisé"
                wedge = "Spécialisation"
                revenue = "Commission, abonnement ou marge"
                automation = "Élevée"
                startup = "Faible à moyenne"
            }
        }
    }
}

$results = foreach ($item in $data) {

    $profile = Get-NicheExpansion `
        -angle ([string]$item.angle) `
        -vertical ([string]$item.vertical) `
        -model ([string]$item.business_model)

    $marketProof = [int]$item.market_proof
    $replication = [int]$item.replication
    $competition = [int]$item.competition
    $accessibility = [int]$item.accessibility

    $companies = [int]$item.company_count
    $articles = [int]$item.article_count
    $countries = [int]$item.country_count

    # ============================================================
    # MARKET EVIDENCE
    # ============================================================

    $evidenceScore = [math]::Min(100,
        ($companies * 1.5) +
        ($articles * 0.7) +
        ($countries * 8)
    )

    # ============================================================
    # BUSINESS QUALITY
    # ============================================================

    $businessQuality = (
        $marketProof * 0.30 +
        $replication * 0.20 +
        $accessibility * 0.20 +
        ((100 - $competition) * 0.20) +
        $evidenceScore * 0.10
    )

    # ============================================================
    # CLIENT VALUE
    # ============================================================

    # On pénalise les idées trop générales et les marchés saturés.
    $specificityBonus = 0

    if ($profile.niche.Length -ge 45) {
        $specificityBonus += 5
    }

    if ($profile.wedge.Length -ge 20) {
        $specificityBonus += 5
    }

    if ($companies -ge 5) {
        $specificityBonus += 5
    }

    $clientScore = [math]::Round(
        [math]::Min(100,
            $businessQuality + $specificityBonus
        )
    )

    # ============================================================
    # CONFIDENCE
    # ============================================================

    if ($companies -ge 15 -and $articles -ge 20 -and $countries -ge 2) {
        $confidence = "VERY HIGH"
    }
    elseif ($companies -ge 8 -and $articles -ge 10) {
        $confidence = "HIGH"
    }
    elseif ($companies -ge 3 -and $articles -ge 5) {
        $confidence = "MEDIUM"
    }
    else {
        $confidence = "LOW"
    }

    # ============================================================
    # VERDICT
    # ============================================================

    if ($clientScore -ge 78 -and $confidence -in @("VERY HIGH","HIGH")) {
        $verdict = "CLIENT-READY"
        $action = "PRESENT"
    }
    elseif ($clientScore -ge 68) {
        $verdict = "STRONG"
        $action = "DEEP VALIDATE"
    }
    elseif ($clientScore -ge 55) {
        $verdict = "PROMISING"
        $action = "VALIDATE"
    }
    elseif ($clientScore -ge 45) {
        $verdict = "WATCH"
        $action = "MONITOR"
    }
    else {
        $verdict = "REJECT"
        $action = "IGNORE"
    }

    # ============================================================
    # CLIENT PROFILE
    # ============================================================

    $clientProfile = switch ([string]$item.vertical) {
        "HOME_SERVICES" { "B2C / propriétaires / gestionnaires" }
        "PET_SERVICES" { "B2C / propriétaires d'animaux" }
        "REPAIR" { "B2B / B2C" }
        "STORAGE" { "B2C / micro-entreprises" }
        "RENTAL" { "B2C / petites entreprises" }
        "DELIVERY_LOGISTICS" { "B2B local" }
        "AUTO_SERVICES" { "B2C / propriétaires de véhicules" }
        "CHILDCARE" { "B2C / familles" }
        default { "B2C / B2B selon niche" }
    }

    # ============================================================
    # OUTPUT
    # ============================================================

    [PSCustomObject]@{

        opportunity_score = $clientScore
        verdict = $verdict
        action = $action
        confidence = $confidence

        idea_name = $profile.niche

        target_customer = $profile.customer
        customer_profile = $clientProfile

        problem = $profile.problem
        solution = $profile.solution

        differentiation = $profile.wedge

        monetization = $profile.revenue

        automation_level = $profile.automation
        startup_complexity = $profile.startup

        market_proof = $marketProof
        replication = $replication
        accessibility = $accessibility
        competition = $competition

        evidence_score = [math]::Round($evidenceScore)

        company_count = $companies
        article_count = $articles
        country_count = $countries

        evidence = "$companies companies / $articles articles / $countries countries"

        source_angle = $item.angle
        source_vertical = $item.vertical
        source_model = $item.business_model
    }
}

$results = $results |
    Sort-Object opportunity_score -Descending

$results |
    ConvertTo-Json -Depth 10 |
    Set-Content $outputFile -Encoding UTF8

Write-Host ""
Write-Host "=============================================================="
Write-Host " BIZNESSHUNTER - RADAR 16"
Write-Host " CLIENT OPPORTUNITY SPECIFICATION ENGINE"
Write-Host "=============================================================="
Write-Host ""
Write-Host "Input    : $inputFile"
Write-Host "Output   : $outputFile"
Write-Host "Ideas    : $($results.Count)"
Write-Host ""

Write-Host "TOP CLIENT OPPORTUNITIES"
Write-Host "--------------------------------------------------------------"
Write-Host ""

$results |
    Select-Object -First 20 `
        opportunity_score,
        verdict,
        action,
        confidence,
        idea_name,
        target_customer,
        monetization,
        automation_level,
        startup_complexity |
    Format-Table -Wrap -AutoSize

Write-Host ""
Write-Host "=============================================================="
Write-Host " RADAR 16 COMPLETE"
Write-Host "=============================================================="
