$inputFile  = ".\radar16_client_opportunities.json"
$outputFile = ".\radar17_concrete_business_ideas.json"

if (!(Test-Path $inputFile)) {
    Write-Host "ERROR: $inputFile not found"
    exit 1
}

$data = Get-Content $inputFile -Raw | ConvertFrom-Json

# ============================================================
# BIZNESSHUNTER - RADAR 17 V2
# CONCRETE BUSINESS IDEA ENGINE
#
# IMPORTANT:
# Radar 17 ne dépend PAS uniquement de business_model/vertical.
# Il analyse aussi directement idea_name.
#
# OBJECTIF:
# Une opportunité abstraite -> plusieurs business précis.
#
# INTERDIT:
# - "marketplace verticale"
# - "service spécialisé"
# - "plateforme pour un besoin précis"
# - "niche dans..."
#
# OBLIGATOIRE:
# - client précis
# - problème précis
# - déclencheur d'achat
# - offre concrète
# - modèle économique
# - MVP
# - acquisition
# - angle géographique
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
        [string]$geo
    )

    [PSCustomObject]@{
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
        geographic_angle   = $geo
    }
}

function Get-ConcreteIdeas {
    param(
        [string]$sourceIdea,
        [string]$vertical,
        [string]$model
    )

    $text = (
        $sourceIdea + " " +
        $vertical + " " +
        $model
    ).ToLower()

    $ideas = @()

    # ========================================================
    # HOME SERVICES
    # ========================================================

    if ($text -match "24.?h|24 heures|urgent|urgence|domestique") {

        $ideas += New-Concept `
            "Dépannage domestique garanti sous 24h pour petites interventions" `
            "Propriétaires et locataires confrontés à une petite panne domestique" `
            "Les plateformes classiques mélangent gros chantiers et petites interventions, ce qui rend les petits dépannages difficiles à obtenir rapidement." `
            "Robinet qui fuit, chasse d'eau bloquée, serrure, fixation ou petite réparation nécessitant une intervention rapide" `
            "Catalogue de 8 à 12 interventions à prix fixe avec créneau garanti sous 24h." `
            "Le client sélectionne le problème, voit le prix, choisit un créneau et reçoit un intervenant local." `
            "Forfait fixe par intervention + supplément urgence." `
            "Promesse de délai + catalogue limité + prix affiché avant réservation." `
            "Landing page locale + formulaire de réservation + 3 à 5 intervenants indépendants." `
            "SEO local sur les recherches de dépannage urgent + Google Ads local." `
            "Commencer dans une seule agglomération où l'offre d'intervenants est suffisamment dense."

        $ideas += New-Concept `
            "Montage de meubles à domicile en moins de 48h" `
            "Acheteurs de meubles en kit et nouveaux occupants" `
            "Le client vient d'acheter un meuble mais ne veut pas consacrer plusieurs heures à son montage." `
            "Livraison récente d'un meuble nécessitant montage" `
            "Réservation d'un monteur avec forfait selon meuble : lit, armoire, bureau, cuisine ou meuble TV." `
            "Matching entre demande et monteur local disponible." `
            "Forfait par type de meuble + déplacement." `
            "Catalogue très limité + prix fixe + délai court." `
            "Formulaire web avec 10 catégories de meubles et paiement manuel au départ." `
            "SEO local + partenariats déménageurs + annonces locales." `
            "Lancement dans une ville dense avant extension."

    }

    # ========================================================
    # MAINTENANCE / PROPERTY
    # ========================================================

    if ($text -match "maintenance|préventive|preventive|logement locatif") {

        $ideas += New-Concept `
            "Inspection mensuelle des logements locatifs pour petits bailleurs" `
            "Propriétaires possédant 1 à 10 logements en location" `
            "Les petites anomalies passent inaperçues jusqu'à devenir des réparations coûteuses." `
            "Propriétaire vivant loin du logement ou ne pouvant pas effectuer régulièrement des visites" `
            "Visite mensuelle ou trimestrielle avec checklist de 30 points, photos et signalement des anomalies." `
            "Un intervenant local réalise une inspection standardisée et envoie un rapport." `
            "Abonnement mensuel par logement." `
            "Prévention + rapport photo + historique du logement." `
            "Google Form + paiement récurrent + rapport PDF automatisé." `
            "Prospection directe auprès de petits bailleurs et agences." `
            "Particulièrement pertinent dans les villes avec beaucoup de résidences secondaires ou bailleurs éloignés."

        $ideas += New-Concept `
            "Pack remise en état entre deux locations en 72h" `
            "Bailleurs, agences et conciergeries" `
            "Entre deux occupants, plusieurs petites tâches doivent être coordonnées rapidement." `
            "Départ d'un locataire avec prochaine entrée déjà programmée" `
            "Forfait comprenant nettoyage, petites réparations, évacuation d'objets et contrôle photo." `
            "Un seul interlocuteur coordonne plusieurs prestataires." `
            "Forfait par logement + options." `
            "Délai garanti + prix forfaitaire + rapport avant/après." `
            "Une page web, trois forfaits et quelques prestataires sous-traitants." `
            "Prospection directe auprès d'agences et conciergeries." `
            "Prioriser les marchés avec forte rotation locative."

    }

    # ========================================================
    # PETS
    # ========================================================

    if ($text -match "animal|animaux|pet|chien|chat|vétérinaire|veterinaire") {

        $ideas += New-Concept `
            "Visites à domicile pour chiens âgés pendant les journées de travail" `
            "Propriétaires actifs de chiens âgés" `
            "Les chiens âgés supportent mal certaines longues absences et nécessitent des sorties adaptées." `
            "Propriétaire absent 6 à 10 heures pendant une journée de travail" `
            "Visite de 30 minutes : sortie courte, eau, alimentation si nécessaire et photo envoyée au propriétaire." `
            "Réseau de pet sitters sélectionnés pour ce type d'animal." `
            "Forfait par visite + abonnement hebdomadaire." `
            "Spécialisation chien âgé + même intervenant + compte-rendu systématique." `
            "Une ville, cinq pet sitters et réservation manuelle." `
            "Vétérinaires, toiletteurs, groupes locaux de propriétaires." `
            "Déploiement ville par ville selon densité de propriétaires."

        $ideas += New-Concept `
            "Transport d'animaux vers le vétérinaire pour propriétaires sans véhicule" `
            "Propriétaires âgés, actifs ou sans voiture" `
            "Certains propriétaires ne peuvent pas transporter leur animal lors d'un rendez-vous vétérinaire." `
            "Rendez-vous vétérinaire confirmé sans possibilité de transport" `
            "Prise en charge à domicile, transport vers le cabinet puis retour de l'animal." `
            "Réservation d'un transporteur local disponible sur créneau." `
            "Forfait aller-retour + distance." `
            "Service extrêmement précis avec réservation à l'avance." `
            "MVP manuel avec 2 à 3 transporteurs partenaires." `
            "Partenariats directs avec vétérinaires." `
            "À tester dans une agglomération avec forte densité de cabinets."

        $ideas += New-Concept `
            "Promenade courte pour chiens âgés ou à mobilité réduite" `
            "Propriétaires de chiens seniors" `
            "Les promenades classiques sont trop longues ou trop physiques pour certains chiens." `
            "Chien nécessitant une sortie quotidienne adaptée" `
            "Promenade de 15 à 30 minutes avec rythme adapté et compte-rendu." `
            "Pet sitter sélectionné pour ce profil d'animal." `
            "Forfait par promenade + abonnement." `
            "Durée courte + spécialisation + continuité du promeneur." `
            "Landing page + calendrier + quelques promeneurs." `
            "Vétérinaires, toiletteurs et communautés locales." `
            "Commencer dans une zone urbaine dense."

    }

    # ========================================================
    # RENTAL
    # ========================================================

    if ($text -match "location|équipement|equipement|événement|evenement|matériel professionnel|rarement") {

        $ideas += New-Concept `
            "Location locale de nettoyeurs haute pression professionnels" `
            "Particuliers utilisant ce matériel moins de quelques fois par an" `
            "Acheter une machine professionnelle pour nettoyer une terrasse ou façade est coûteux et encombrant." `
            "Nettoyage ponctuel d'une terrasse, façade, voiture ou clôture" `
            "Location 24h d'un nettoyeur haute pression professionnel avec accessoires." `
            "Inventaire local de machines appartenant à des particuliers ou professionnels." `
            "Tarif journalier + caution + livraison optionnelle." `
            "Une seule catégorie d'équipement avec disponibilité locale." `
            "Commencer avec 5 à 10 machines dans une ville." `
            "SEO local + petites annonces + partenariats bricolage." `
            "Tester une ville avant de créer un réseau national."

        $ideas += New-Concept `
            "Location de packs lumière et son pour anniversaires de 30 à 100 personnes" `
            "Particuliers organisant des fêtes privées" `
            "Acheter du matériel audio et lumineux pour une seule soirée est peu rentable." `
            "Anniversaire, soirée privée ou petite réception" `
            "Packs prêts à réserver comprenant enceinte, micros, éclairage et câbles." `
            "Catalogue réduit de packs standardisés avec retrait ou livraison." `
            "Forfait par événement + livraison." `
            "Pack complet plutôt que location d'éléments séparés." `
            "Trois packs et quelques équipements en stock." `
            "Instagram local + SEO + partenariats avec salles." `
            "Cibler les zones urbaines et touristiques."

        $ideas += New-Concept `
            "Location de matériel professionnel aux artisans pour besoins ponctuels" `
            "Artisans utilisant rarement certains équipements coûteux" `
            "Certains équipements professionnels sont trop chers pour être achetés lorsqu'ils ne sont utilisés que quelques fois par mois." `
            "Chantier nécessitant ponctuellement une machine spécifique" `
            "Réservation locale d'équipements professionnels avec retrait le jour même." `
            "Inventaire d'équipements appartenant à des professionnels partenaires." `
            "Location journalière + assurance." `
            "Disponibilité rapide + proximité + équipement précis." `
            "Commencer par une seule catégorie de matériel." `
            "Prospection directe auprès d'artisans." `
            "Fonctionne mieux dans les zones avec forte concentration artisanale."

    }

    # ========================================================
    # REPAIR
    # ========================================================

    if ($text -match "réparation|reparation|repair|panne|équipement critique|equipement critique") {

        $ideas += New-Concept `
            "Réparation prioritaire des équipements de cuisine pour petits restaurants" `
            "Restaurants indépendants et snacks" `
            "Une panne de frigo, lave-vaisselle ou équipement de cuisson peut bloquer une partie de l'activité." `
            "Panne d'un équipement essentiel pendant les heures d'activité" `
            "Accès prioritaire à un réseau de réparateurs avec engagement de prise en charge rapide." `
            "Le commerçant appelle un numéro unique et le système affecte le réparateur disponible." `
            "Abonnement mensuel + facturation de l'intervention." `
            "SLA + priorité + historique des équipements." `
            "Dix restaurants pilotes et dispatch manuel." `
            "Prospection directe auprès des restaurateurs." `
            "Lancer dans une zone concentrant restaurants et réparateurs."

        $ideas += New-Concept `
            "Réparation mobile de petits électroménagers à domicile" `
            "Particuliers possédant lave-linge ou lave-vaisselle" `
            "Transporter un appareil lourd jusqu'à un réparateur est difficile." `
            "Panne d'un appareil électroménager courant" `
            "Diagnostic à domicile avec réparation immédiate des pannes simples." `
            "Technicien mobile avec stock de pièces courantes." `
            "Forfait diagnostic + pièces + main-d'œuvre." `
            "Déplacement à domicile + prix du diagnostic connu." `
            "Un technicien + une zone géographique + trois modèles d'appareils." `
            "SEO local et partenariats avec vendeurs d'électroménager." `
            "Commencer dans une agglomération dense."

    }

    # ========================================================
    # STORAGE
    # ========================================================

    if ($text -match "stockage|storage|petits volumes|très petits volumes|petit volume") {

        $ideas += New-Concept `
            "Stockage de 1 à 3 m³ chez des commerçants disposant d'espace inutilisé" `
            "Particuliers ayant quelques cartons à stocker pendant 1 à 12 mois" `
            "Les box traditionnels imposent souvent une taille minimale trop importante." `
            "Déménagement, travaux, séparation de logement ou manque temporaire d'espace" `
            "Réservation d'un espace de 1, 2 ou 3 m³ dans un local partenaire." `
            "Commerçants et entreprises louent leurs espaces inutilisés via la plateforme." `
            "Abonnement mensuel au volume." `
            "Paiement au volume réel + proximité." `
            "Trouver trois partenaires et gérer les premières réservations manuellement." `
            "SEO local + déménageurs + agences immobilières." `
            "Commencer dans une ville où les loyers de stockage sont élevés."

    }

    # ========================================================
    # DELIVERY
    # ========================================================

    if ($text -match "livraison|logistique|delivery|produits volumineux|commerces") {

        $ideas += New-Concept `
            "Livraison planifiée de meubles pour magasins indépendants" `
            "Petits magasins de mobilier sans flotte de livraison" `
            "Les magasins vendent des produits volumineux mais ne peuvent pas rentabiliser une flotte permanente." `
            "Vente d'un meuble nécessitant livraison locale" `
            "Livraison réservée par créneau avec suivi et confirmation client." `
            "Réseau mutualisé de chauffeurs locaux utilisé par plusieurs magasins." `
            "Prix par livraison selon distance et volume." `
            "Créneaux planifiés + mutualisation." `
            "Signer cinq magasins avant de développer un logiciel." `
            "Prospection directe des magasins de mobilier." `
            "La densité de magasins partenaires détermine la rentabilité."

    }

    # ========================================================
    # AUTO
    # ========================================================

    if ($text -match "auto|automobile|véhicule|vehicule|batterie") {

        $ideas += New-Concept `
            "Remplacement mobile de batterie automobile à domicile" `
            "Conducteurs dont le véhicule ne démarre plus" `
            "Une batterie déchargée ou usée immobilise le véhicule et oblige souvent à appeler une assistance." `
            "Véhicule qui ne démarre plus à domicile ou sur le lieu de travail" `
            "Diagnostic, fourniture et remplacement de batterie directement sur place." `
            "Technicien mobile avec stock limité de références courantes." `
            "Prix batterie + remplacement + déplacement." `
            "Intervention mobile + prix transparent + disponibilité rapide." `
            "Un technicien et une zone locale." `
            "SEO local sur panne batterie + partenariats garages." `
            "Vérifier assurance, réglementation et gestion du stock."

    }

    # ========================================================
    # CHILDCARE
    # ========================================================

    if ($text -match "garde|enfant|childcare|parents|crèche|creche") {

        $ideas += New-Concept `
            "Garde ponctuelle de sortie de crèche pour parents aux horaires décalés" `
            "Parents terminant leur travail après la fermeture de la crèche" `
            "Les horaires des structures classiques ne couvrent pas certains horaires professionnels." `
            "Parent terminant son travail après l'heure de fermeture" `
            "Garde de 1 à 3 heures entre fermeture de la structure et retour du parent." `
            "Intervenants vérifiés affectés à des créneaux réguliers." `
            "Commission par garde ou abonnement." `
            "Créneau très précis plutôt que garde d'enfants généraliste." `
            "Pilote manuel avec quelques familles et intervenants." `
            "Prospection locale + entreprises employant des horaires décalés." `
            "Nécessite une validation juridique et réglementaire approfondie."

    }

    # ========================================================
    # SOFTWARE
    # ========================================================

    if ($text -match "logiciel|software|micro-saas|saas|administrative|administratif") {

        $ideas += New-Concept `
            "Relance automatique des devis non signés pour artisans" `
            "Artisans envoyant régulièrement des devis" `
            "Des devis restent sans réponse parce que les relances sont oubliées ou faites trop tard." `
            "Devis envoyé depuis 3 à 30 jours sans réponse" `
            "Le logiciel détecte les devis sans réponse et envoie automatiquement une séquence de relance." `
            "Import des devis ou connexion à la messagerie puis automatisation des relances." `
            "Abonnement mensuel de 19 à 49 euros." `
            "Un seul workflow commercial au lieu d'un ERP complet." `
            "MVP avec import CSV + email avant toute intégration complexe." `
            "Prospection directe auprès d'artisans et petites entreprises." `
            "Peut être vendu internationalement avec adaptation linguistique."

    }

    return $ideas
}

# ============================================================
# PROCESS
# ============================================================

$results = @()

Write-Host ""
Write-Host "Reading Radar 16..."
Write-Host "Input objects: $($data.Count)"
Write-Host ""

foreach ($item in $data) {

    $ideaName = [string]$item.idea_name
    $vertical = [string]$item.vertical
    $model = [string]$item.business_model

    $ideas = Get-ConcreteIdeas `
        -sourceIdea $ideaName `
        -vertical $vertical `
        -model $model

    foreach ($idea in $ideas) {

        $marketProof = 0
        $competition = 50
        $replication = 50
        $companyCount = 0
        $articleCount = 0
        $countryCount = 0

        if ($null -ne $item.market_proof) {
            $marketProof = [int]$item.market_proof
        }
        elseif ($null -ne $item.market_proof_score) {
            $marketProof = [int]$item.market_proof_score
        }

        if ($null -ne $item.competition) {
            $competition = [int]$item.competition
        }

        if ($null -ne $item.replication) {
            $replication = [int]$item.replication
        }

        if ($null -ne $item.company_count) {
            $companyCount = [int]$item.company_count
        }

        if ($null -ne $item.article_count) {
            $articleCount = [int]$item.article_count
        }

        if ($null -ne $item.country_count) {
            $countryCount = [int]$item.country_count
        }

        # ----------------------------------------------------
        # SPECIFICITY
        # ----------------------------------------------------

        $specificity = 0

        if ($idea.idea_name.Length -ge 35) { $specificity += 15 }
        if ($idea.target_customer.Length -ge 40) { $specificity += 15 }
        if ($idea.problem.Length -ge 70) { $specificity += 15 }
        if ($idea.buying_trigger.Length -ge 40) { $specificity += 15 }
        if ($idea.concrete_offer.Length -ge 70) { $specificity += 15 }
        if ($idea.monetization.Length -ge 30) { $specificity += 10 }
        if ($idea.mvp.Length -ge 45) { $specificity += 10 }
        if ($idea.acquisition.Length -ge 35) { $specificity += 5 }

        $specificity = [math]::Min(100,$specificity)

        # ----------------------------------------------------
        # EVIDENCE
        # ----------------------------------------------------

        $evidence = [math]::Min(
            100,
            ($companyCount * 1.5) +
            ($articleCount * 0.7) +
            ($countryCount * 8)
        )

        if ($evidence -eq 0) {
            $evidence = $marketProof
        }

        # ----------------------------------------------------
        # GEOGRAPHIC GAP
        # ----------------------------------------------------

        $geo = $idea.geographic_angle

        $geoScore = 60

        if ($geo -match "ville|zone|local|ville|agglomération|région|densité") {
            $geoScore = 80
        }

        # If Radar 16 contains geographic information, preserve it.
        if ($null -ne $item.geographic_gap) {
            $geo = "$($item.geographic_gap) | $geo"
            $geoScore = 90
        }

        if ($null -ne $item.geographic_angle) {
            $geo = "$($item.geographic_angle) | $geo"
            $geoScore = 90
        }

        # ----------------------------------------------------
        # FINAL SCORE
        # ----------------------------------------------------

        $score = (
            $marketProof * 0.25 +
            $evidence * 0.15 +
            $specificity * 0.30 +
            $geoScore * 0.10 +
            $replication * 0.10 +
            ((100 - $competition) * 0.10)
        )

        $score = [math]::Round([math]::Min(100,$score))

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

        $results += [PSCustomObject]@{
            concept_score = $score
            verdict = $verdict
            action = $action

            idea_name = $idea.idea_name

            target_customer = $idea.target_customer
            problem = $idea.problem
            buying_trigger = $idea.buying_trigger
            concrete_offer = $idea.concrete_offer
            business_mechanism = $idea.business_mechanism

            monetization = $idea.monetization
            differentiation = $idea.differentiation

            mvp = $idea.mvp
            acquisition = $idea.acquisition
            geographic_angle = $geo

            specificity_score = $specificity
            geographic_score = $geoScore

            market_proof = $marketProof
            replication = $replication
            competition = $competition

            company_count = $companyCount
            article_count = $articleCount
            country_count = $countryCount

            evidence = "$companyCount companies / $articleCount articles / $countryCount countries"

            source_opportunity = $ideaName
            source_vertical = $vertical
            source_business_model = $model
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
Write-Host " BIZNESSHUNTER - RADAR 17 V2"
Write-Host " CONCRETE BUSINESS IDEA ENGINE"
Write-Host "=============================================================="
Write-Host ""

Write-Host "Input    : $inputFile"
Write-Host "Output   : $outputFile"
Write-Host "Ideas    : $($results.Count)"
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
        geographic_score,
        market_proof |
    Format-Table -Wrap -AutoSize

Write-Host ""
Write-Host "=============================================================="
Write-Host " RADAR 17 V2 COMPLETE"
Write-Host "=============================================================="
Write-Host ""
Write-Host "ANTI-GENERIC ENGINE : ENABLED"
Write-Host "GEOGRAPHIC GAP      : ENABLED"
Write-Host "CONCRETE OFFER      : ENABLED"
Write-Host "BUYING TRIGGER      : ENABLED"
Write-Host "MVP                 : ENABLED"
Write-Host "ACQUISITION         : ENABLED"
Write-Host ""

