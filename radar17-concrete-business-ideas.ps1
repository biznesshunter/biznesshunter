$inputFile  = ".\radar16_client_opportunities.json"
$outputFile = ".\radar17_concrete_business_ideas.json"

if (!(Test-Path $inputFile)) {
    Write-Host "ERROR: $inputFile not found"
    exit 1
}

$data = Get-Content $inputFile -Raw | ConvertFrom-Json

# ============================================================
# BIZNESSHUNTER - RADAR 17
# CONCRETE BUSINESS IDEA ENGINE
#
# OBJECTIVE:
# Transform broad opportunity clusters into specific,
# testable and client-ready business concepts.
#
# RULE:
# A category is NOT an idea.
# A marketplace is NOT an idea.
# "Specialized service" is NOT an idea.
# ============================================================

function New-Concept {
    param(
        [string]$name,
        [string]$customer,
        [string]$problem,
        [string]$trigger,
        [string]$offer,
        [string]$mechanism,
        [string]$monetization,
        [string]$wedge,
        [string]$mvp,
        [string]$acquisition,
        [string]$geographic_angle
    )

    return [PSCustomObject]@{
        idea_name          = $name
        target_customer    = $customer
        problem            = $problem
        buying_trigger     = $trigger
        concrete_offer     = $offer
        business_mechanism = $mechanism
        monetization       = $monetization
        differentiation    = $wedge
        mvp                = $mvp
        acquisition        = $acquisition
        geographic_angle   = $geographic_angle
    }
}

function Get-ConcreteConcepts {
    param(
        [string]$vertical,
        [string]$businessModel,
        [string]$ideaName
    )

    $key = "$businessModel|$vertical"

    switch ($key) {

        # ====================================================
        # HOME SERVICES
        # ====================================================

        "OTHER|HOME_SERVICES" {
            return @(

                (New-Concept `
                    "Remise en état express entre deux locataires" `
                    "Propriétaires bailleurs et gestionnaires de 1 à 20 logements" `
                    "Entre deux locataires, plusieurs petits travaux doivent être coordonnés avant la prochaine entrée." `
                    "Départ d'un locataire avec moins de 7 jours avant la prochaine entrée" `
                    "Pack fixe comprenant nettoyage, petites réparations, évacuation des encombrants et photos de contrôle." `
                    "Un seul interlocuteur coordonne les prestataires et livre le logement prêt à relouer." `
                    "Forfait par logement avec options supplémentaires." `
                    "Promesse de délai + pack standardisé + preuve photo avant/après." `
                    "Landing page locale + 3 packs tarifaires + réservation manuelle des premières interventions." `
                    "Agences immobilières, conciergeries et groupes locaux de propriétaires." `
                    "Commencer dans une ville où le parc locatif et les locations courte durée sont importants."
                )

                (New-Concept `
                    "Inspection pré-location avec rapport photo sous 24h" `
                    "Propriétaires et agences immobilières" `
                    "Les propriétaires ont besoin de vérifier rapidement l'état d'un logement avant ou après une location." `
                    "État des lieux, changement de locataire ou doute sur l'état du bien" `
                    "Visite standardisée avec checklist, photos horodatées et rapport PDF envoyé le jour même." `
                    "Un intervenant local réalise une inspection standardisée sans nécessiter la présence du propriétaire." `
                    "Forfait fixe par inspection." `
                    "Rapport rapide + format standard + réservation en ligne." `
                    "Créer un formulaire de réservation et sous-traiter les premières visites à des indépendants locaux." `
                    "Prospection directe auprès d'agences et propriétaires." `
                    "Déploiement ville par ville autour des zones à forte densité locative."
                )

                (New-Concept `
                    "Pack entretien saisonnier pour résidences secondaires" `
                    "Propriétaires de résidences secondaires" `
                    "Les propriétaires absents doivent coordonner plusieurs petites interventions avant leur arrivée." `
                    "Retour du propriétaire après plusieurs semaines ou mois d'absence" `
                    "Pack comprenant contrôle du logement, ventilation, nettoyage, relevé des anomalies et petites interventions." `
                    "Visite récurrente avec checklist et compte-rendu photo." `
                    "Abonnement trimestriel ou mensuel." `
                    "Un seul abonnement remplace plusieurs interventions ponctuelles." `
                    "Vendre un premier pack à des propriétaires d'une même zone touristique." `
                    "Groupes immobiliers locaux, forums de propriétaires, agences." `
                    "Particulièrement adapté aux zones touristiques et littorales."
                )
            )
        }

        "ON_DEMAND|HOME_SERVICES" {
            return @(

                (New-Concept `
                    "Intervention domestique standardisée sous 24 heures" `
                    "Particuliers ayant une petite panne domestique urgente" `
                    "Les particuliers ne savent pas quel professionnel contacter pour une petite intervention et attendent souvent plusieurs jours." `
                    "Petite panne ou problème domestique ne nécessitant pas un chantier important" `
                    "Catalogue de prestations à prix fixe : robinet, chasse d'eau, serrure, fixation, petit dépannage électrique non complexe." `
                    "Le client choisit une prestation précise et obtient un créneau sous 24h." `
                    "Prix fixe par intervention + supplément urgence." `
                    "Catalogue très limité + prix affiché + délai garanti." `
                    "Commencer avec 5 prestations très standardisées dans une seule ville." `
                    "Google local, SEO sur requêtes urgentes et partenariats avec agences." `
                    "Modèle très dépendant de la densité locale de prestataires disponibles."
                )

                (New-Concept `
                    "Montage de meubles à domicile réservé en créneau court" `
                    "Particuliers achetant régulièrement du mobilier en kit" `
                    "Le montage de meubles prend du temps et les clients cherchent souvent quelqu'un uniquement pour cette tâche." `
                    "Livraison récente d'un meuble nécessitant montage" `
                    "Réservation d'un créneau de 60, 90 ou 120 minutes avec prix affiché selon la taille du meuble." `
                    "Intervenants locaux affectés automatiquement selon disponibilité et distance." `
                    "Forfait par durée ou catégorie de meuble." `
                    "Prix connu avant réservation + créneaux courts + intervention rapide." `
                    "Landing page + formulaire + réseau de monteurs indépendants." `
                    "SEO local et partenariats avec déménageurs / magasins." `
                    "Commencer dans une agglomération dense."
                )
            )
        }

        # ====================================================
        # PET SERVICES
        # ====================================================

        "OTHER|PET_SERVICES" {
            return @(

                (New-Concept `
                    "Visites à domicile pour animaux âgés" `
                    "Propriétaires de chiens et chats âgés" `
                    "Les animaux âgés nécessitent davantage de surveillance mais leurs propriétaires travaillent ou s'absentent." `
                    "Absence du propriétaire pendant plusieurs heures ou plusieurs jours" `
                    "Visites standardisées à domicile : alimentation, promenade courte, observation et compte-rendu photo." `
                    "Intervenants formés à la prise en charge des animaux âgés avec protocole de visite." `
                    "Forfait par visite + abonnement hebdomadaire." `
                    "Niche claire + continuité du même intervenant + compte-rendu systématique." `
                    "Commencer avec un petit réseau de pet sitters dans une ville." `
                    "Vétérinaires, associations, groupes locaux de propriétaires d'animaux." `
                    "Fort potentiel dans les zones urbaines à forte population de propriétaires d'animaux."
                )

                (New-Concept `
                    "Promenade courte pour chiens âgés ou à mobilité réduite" `
                    "Propriétaires de chiens âgés" `
                    "Les promenades classiques sont parfois trop longues ou trop physiques pour certains chiens âgés." `
                    "Chien nécessitant une sortie mais incapable de suivre une promenade classique" `
                    "Promenades de 15 à 30 minutes avec rythme adapté et compte-rendu." `
                    "Réseau de promeneurs sélectionnés selon la capacité à gérer les chiens âgés." `
                    "Forfait par promenade + abonnement." `
                    "Ultra-spécialisation sur une population canine précise." `
                    "Tester avec quelques promeneurs et une zone géographique limitée." `
                    "Vétérinaires, toiletteurs, groupes Facebook locaux." `
                    "À lancer d'abord dans une zone urbaine dense."
                )

                (New-Concept `
                    "Transport accompagné d'animaux vers le vétérinaire" `
                    "Propriétaires âgés, actifs ou sans véhicule" `
                    "Certains propriétaires ont du mal à transporter leur animal jusqu'au vétérinaire." `
                    "Rendez-vous vétérinaire lorsque le propriétaire ne peut pas assurer le transport" `
                    "Transport aller-retour avec prise en charge de l'animal et confirmation du rendez-vous." `
                    "Réseau de chauffeurs/pet sitters locaux avec créneaux réservables." `
                    "Forfait aller-retour + distance supplémentaire." `
                    "Service précis plutôt que pet sitting généraliste." `
                    "Commencer manuellement avec 2 à 5 intervenants." `
                    "Partenariats directs avec cabinets vétérinaires." `
                    "Très dépendant de la réglementation locale et de l'assurance."
                )
            )
        }

        # ====================================================
        # REPAIR
        # ====================================================

        "OTHER|REPAIR" {
            return @(

                (New-Concept `
                    "Réparation mobile de petits appareils électroménagers" `
                    "Particuliers possédant lave-linge, lave-vaisselle ou sèche-linge" `
                    "Le déplacement jusqu'au réparateur est pénible et le client veut savoir rapidement si la réparation vaut le coût." `
                    "Panne d'un appareil électroménager courant" `
                    "Diagnostic à domicile avec forfait diagnostic puis devis immédiat pour les réparations simples." `
                    "Technicien mobile équipé pour les pannes courantes." `
                    "Forfait diagnostic + marge sur réparation + pièces." `
                    "Déplacement à domicile + prix du diagnostic affiché + réparation immédiate quand possible." `
                    "Commencer avec une seule catégorie d'appareil et une zone locale." `
                    "SEO local sur les requêtes panne + partenariats avec magasins d'électroménager." `
                    "Nécessite de vérifier assurance, qualification et réglementation."
                )

                (New-Concept `
                    "Contrat de réparation prioritaire pour petits commerces" `
                    "Restaurants, cafés, salons et petits commerces dépendants de leurs équipements" `
                    "Une panne d'un équipement critique peut provoquer une perte de chiffre d'affaires immédiate." `
                    "Panne d'un équipement indispensable à l'activité" `
                    "Abonnement donnant accès à un réseau de réparateurs avec délai d'intervention prioritaire." `
                    "Centralisation des demandes et dispatch du réparateur disponible." `
                    "Abonnement mensuel + intervention facturée." `
                    "SLA de délai + priorité d'intervention + historique des équipements." `
                    "Commencer avec un seul type d'équipement et 10 commerces pilotes." `
                    "Prospection directe auprès des commerces locaux." `
                    "Le modèle devient intéressant lorsqu'une densité locale suffisante est atteinte."
                )
            )
        }

        # ====================================================
        # STORAGE
        # ====================================================

        "OTHER|STORAGE" {
            return @(

                (New-Concept `
                    "Stockage de 1 à 3 m³ chez des commerçants locaux" `
                    "Particuliers ayant quelques cartons ou objets à stocker" `
                    "Les box traditionnels imposent souvent une taille minimale trop importante." `
                    "Déménagement, travaux ou manque temporaire d'espace" `
                    "Petits espaces sécurisés facturés au volume réellement utilisé." `
                    "Des commerces ou entreprises mettent à disposition des espaces inutilisés." `
                    "Abonnement mensuel au mètre cube." `
                    "Paiement au volume + proximité + flexibilité." `
                    "Tester avec 3 à 5 espaces partenaires et quelques clients dans une ville." `
                    "SEO local + partenariats avec déménageurs." `
                    "La densité d'espaces partenaires est le facteur clé."
                )
            )
        }

        # ====================================================
        # RENTAL
        # ====================================================

        "RENTAL|RENTAL" {
            return @(

                (New-Concept `
                    "Location locale de nettoyeurs haute pression professionnels" `
                    "Particuliers ayant besoin d'un nettoyage ponctuel" `
                    "Acheter un nettoyeur haute pression performant pour une utilisation occasionnelle est coûteux et encombrant." `
                    "Nettoyage d'une terrasse, façade, véhicule ou clôture" `
                    "Location à la journée avec machine professionnelle, accessoires et retrait/livraison locale." `
                    "Inventaire local de machines appartenant à des particuliers ou professionnels." `
                    "Prix journalier + assurance + livraison optionnelle." `
                    "Équipement précis + usage occasionnel + disponibilité locale." `
                    "Commencer avec 5 à 10 machines dans une zone géographique." `
                    "SEO local + annonces ciblées + partenariats avec magasins de bricolage." `
                    "Exemple de verticale à tester avant d'élargir à d'autres équipements."
                )

                (New-Concept `
                    "Location de matériel événementiel pour petites fêtes privées" `
                    "Particuliers organisant anniversaires, mariages ou événements privés" `
                    "Acheter tables, éclairage, sono ou équipements spécifiques pour un événement unique est peu rentable." `
                    "Organisation d'un événement de 20 à 100 personnes" `
                    "Packs prêts à réserver : éclairage, mobilier, sonorisation ou décoration." `
                    "Catalogue local avec retrait ou livraison." `
                    "Location par événement + livraison." `
                    "Packs simples plutôt que catalogue de centaines d'objets." `
                    "Tester 3 packs dans une ville." `
                    "Instagram local, Google, organisateurs d'événements." `
                    "Potentiel plus élevé dans les zones touristiques et urbaines."
                )
            )
        }

        # ====================================================
        # DELIVERY
        # ====================================================

        "DELIVERY|DELIVERY_LOGISTICS" {
            return @(

                (New-Concept `
                    "Livraison planifiée de meubles pour magasins indépendants" `
                    "Petits magasins de mobilier sans flotte de livraison" `
                    "Les magasins vendent des produits volumineux mais ne veulent pas gérer leur propre flotte." `
                    "Vente d'un meuble nécessitant livraison locale" `
                    "Livraison réservée par créneau avec suivi et confirmation au client." `
                    "Réseau de chauffeurs indépendants mutualisé entre plusieurs magasins." `
                    "Prix par livraison selon distance et volume." `
                    "Créneaux planifiés + mutualisation de plusieurs magasins." `
                    "Signer 5 magasins dans une même zone avant de développer la technologie." `
                    "Prospection directe des magasins de mobilier." `
                    "La densité commerciale locale est déterminante."
                )
            )
        }

        # ====================================================
        # AUTO
        # ====================================================

        "OTHER|AUTO_SERVICES" {
            return @(

                (New-Concept `
                    "Remplacement mobile de batterie automobile" `
                    "Conducteurs confrontés à une batterie déchargée ou défaillante" `
                    "Une batterie défaillante immobilise le véhicule et nécessite souvent un déplacement ou une assistance." `
                    "Véhicule qui ne démarre plus à domicile ou sur le lieu de travail" `
                    "Diagnostic simple, fourniture et remplacement de batterie directement sur place." `
                    "Technicien mobile avec stock limité de batteries courantes." `
                    "Prix de remplacement + déplacement." `
                    "Intervention à domicile + prix annoncé + disponibilité rapide." `
                    "Tester avec un technicien et un stock réduit." `
                    "SEO local + partenariats garages et dépanneurs." `
                    "Vérifier réglementation, assurance et gestion du stock."
                )
            )
        }

        # ====================================================
        # CHILDCARE
        # ====================================================

        "OTHER|CHILDCARE" {
            return @(

                (New-Concept `
                    "Garde ponctuelle après fermeture de crèche" `
                    "Parents travaillant en horaires décalés" `
                    "Les horaires des structures classiques ne couvrent pas certains besoins professionnels." `
                    "Fin de journée de travail après fermeture de la structure habituelle" `
                    "Réservation de gardes ponctuelles sur des créneaux précisément définis." `
                    "Réseau d'intervenants vérifiés disponibles sur des créneaux courts." `
                    "Commission par réservation." `
                    "Créneaux spécifiques plutôt que garde générale." `
                    "Tester une zone et quelques intervenants avant toute plateforme complète." `
                    "Entreprises locales, groupes de parents et partenariats avec structures." `
                    "Très dépendant de la réglementation et des exigences de vérification."
                )
            )
        }

        # ====================================================
        # SOFTWARE
        # ====================================================

        "SOFTWARE|OTHER" {
            return @(

                (New-Concept `
                    "Relance automatique des devis non signés pour artisans" `
                    "Artisans et petites entreprises de services" `
                    "Des devis envoyés restent sans réponse et nécessitent des relances manuelles." `
                    "Devis envoyé depuis moins de 30 jours sans réponse du prospect" `
                    "Envoi automatique de relances personnalisées avec suivi des réponses." `
                    "Connexion à l'email et automatisation d'un seul workflow commercial." `
                    "Abonnement mensuel par entreprise." `
                    "Un seul problème : récupérer les devis oubliés." `
                    "MVP avec import CSV + séquences email avant intégration complète." `
                    "Prospection directe auprès d'artisans." `
                    "Peut être vendu dans plusieurs pays si le workflow reste simple."
                )
            )
        }

        default {
            return @()
        }
    }
}

# ============================================================
# GENERATION
# ============================================================

$results = @()

foreach ($item in $data) {

    $vertical = [string]$item.vertical
    $businessModel = [string]$item.business_model
    $sourceIdea = [string]$item.idea_name

    $concepts = Get-ConcreteConcepts `
        -vertical $vertical `
        -businessModel $businessModel `
        -ideaName $sourceIdea

    foreach ($concept in $concepts) {

        # ----------------------------------------------------
        # BASE EVIDENCE
        # ----------------------------------------------------

        $companyCount = [int]$item.company_count
        $articleCount = [int]$item.article_count
        $countryCount = [int]$item.country_count

        $marketProof = [int]$item.market_proof
        $replication = [int]$item.replication
        $competition = [int]$item.competition

        # ----------------------------------------------------
        # SPECIFICITY SCORE
        # ----------------------------------------------------

        $specificity = 0

        if ($concept.target_customer.Length -ge 35) { $specificity += 20 }
        if ($concept.problem.Length -ge 60) { $specificity += 20 }
        if ($concept.concrete_offer.Length -ge 60) { $specificity += 20 }
        if ($concept.buying_trigger.Length -ge 35) { $specificity += 15 }
        if ($concept.monetization.Length -ge 25) { $specificity += 10 }
        if ($concept.mvp.Length -ge 45) { $specificity += 15 }

        $specificity = [math]::Min(100,$specificity)

        # ----------------------------------------------------
        # EVIDENCE SCORE
        # ----------------------------------------------------

        $evidence = [math]::Min(
            100,
            ($companyCount * 1.5) +
            ($articleCount * 0.7) +
            ($countryCount * 8)
        )

        # ----------------------------------------------------
        # BUSINESS QUALITY
        # ----------------------------------------------------

        $recurrence = 0

        if (
            $concept.monetization -match "abonnement" -or
            $concept.name -match "maintenance|entretien|contrat|abonnement|récurrent"
        ) {
            $recurrence = 90
        }
        else {
            $recurrence = 55
        }

        $execution = (
            $replication * 0.35 +
            (100 - $competition) * 0.30 +
            $specificity * 0.35
        )

        # ----------------------------------------------------
        # FINAL CONCEPT SCORE
        # ----------------------------------------------------

        $score = (
            $marketProof * 0.25 +
            $evidence * 0.20 +
            $specificity * 0.25 +
            $execution * 0.15 +
            $recurrence * 0.15
        )

        $score = [math]::Round([math]::Min(100,$score))

        # ----------------------------------------------------
        # VERDICT
        # ----------------------------------------------------

        if ($score -ge 80) {
            $verdict = "HIGH POTENTIAL"
            $action = "DEEP VALIDATE"
        }
        elseif ($score -ge 70) {
            $verdict = "PROMISING"
            $action = "VALIDATE"
        }
        elseif ($score -ge 60) {
            $verdict = "WATCH"
            $action = "MONITOR"
        }
        else {
            $verdict = "REJECT"
            $action = "IGNORE"
        }

        # ----------------------------------------------------
        # ANTI-GENERIC FILTER
        # ----------------------------------------------------

        $generic = $false

        $genericPatterns = @(
            "niche spécialisée",
            "service spécialisé",
            "services spécialisés",
            "marketplace verticale",
            "plateforme verticale",
            "solution spécialisée",
            "vertical marketplace",
            "specialized service",
            "specialized marketplace",
            "micro-saas vertical",
            "catégorie précise",
            "besoin spécifique"
        )

        foreach ($pattern in $genericPatterns) {
            if ($concept.idea_name -match [regex]::Escape($pattern)) {
                $generic = $true
            }
        }

        if ($concept.concrete_offer.Length -lt 50) {
            $generic = $true
        }

        if ($concept.problem.Length -lt 50) {
            $generic = $true
        }

        if ($concept.target_customer.Length -lt 25) {
            $generic = $true
        }

        if ($generic) {
            continue
        }

        # ----------------------------------------------------
        # FINAL OBJECT
        # ----------------------------------------------------

        $results += [PSCustomObject]@{

            concept_score = $score
            verdict = $verdict
            action = $action

            idea_name = $concept.idea_name

            target_customer = $concept.target_customer
            problem = $concept.problem
            buying_trigger = $concept.buying_trigger

            concrete_offer = $concept.concrete_offer
            business_mechanism = $concept.business_mechanism

            monetization = $concept.monetization
            differentiation = $concept.differentiation

            mvp = $concept.mvp
            acquisition = $concept.acquisition

            geographic_angle = $concept.geographic_angle

            specificity_score = $specificity
            market_proof = $marketProof
            replication = $replication
            competition = $competition

            company_count = $companyCount
            article_count = $articleCount
            country_count = $countryCount

            evidence = "$companyCount companies / $articleCount articles / $countryCount countries"

            source_idea = $sourceIdea
            source_cluster = "$businessModel / $vertical"
        }
    }
}

# ============================================================
# DEDUPLICATION
# ============================================================

$results = $results |
    Sort-Object concept_score -Descending |
    Group-Object idea_name |
    ForEach-Object {
        $_.Group | Select-Object -First 1
    }

# ============================================================
# OUTPUT
# ============================================================

$results |
    Sort-Object concept_score -Descending |
    ConvertTo-Json -Depth 10 |
    Set-Content $outputFile -Encoding UTF8

# ============================================================
# DISPLAY
# ============================================================

Write-Host ""
Write-Host "=============================================================="
Write-Host " BIZNESSHUNTER - RADAR 17"
Write-Host " CONCRETE BUSINESS IDEA ENGINE"
Write-Host "=============================================================="
Write-Host ""

Write-Host "Input    : $inputFile"
Write-Host "Output   : $outputFile"
Write-Host "Concepts : $($results.Count)"
Write-Host ""

Write-Host "TOP CONCRETE BUSINESS IDEAS"
Write-Host "--------------------------------------------------------------"
Write-Host ""

$results |
    Select-Object -First 20 `
        concept_score,
        verdict,
        action,
        idea_name,
        target_customer,
        specificity_score,
        market_proof,
        company_count,
        article_count |
    Format-Table -Wrap -AutoSize

Write-Host ""
Write-Host "=============================================================="
Write-Host " RADAR 17 COMPLETE"
Write-Host "=============================================================="
Write-Host ""

Write-Host "ANTI-GENERIC RULE : ENABLED"
Write-Host "Every idea must specify:"
Write-Host " - exact customer"
Write-Host " - concrete problem"
Write-Host " - buying trigger"
Write-Host " - concrete offer"
Write-Host " - monetization"
Write-Host " - MVP"
Write-Host " - acquisition"
Write-Host ""

