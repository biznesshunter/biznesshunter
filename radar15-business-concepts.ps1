$inputFile = ".\radar14_concrete_ideas.json"
$outputFile = ".\radar15_business_concepts.json"

if (!(Test-Path $inputFile)) {
    Write-Host "ERROR: $inputFile not found"
    exit
}

$data = Get-Content $inputFile -Raw | ConvertFrom-Json

# ============================================================
# BIZNESSHUNTER RADAR 15
# BUSINESS CONCEPT ENGINE
# ============================================================

function Get-ConceptVariants {
    param(
        [string]$vertical,
        [string]$model
    )

    $key = "$model|$vertical"

    switch ($key) {

        "OTHER|HOME_SERVICES" {
            return @(
                @{
                    angle="Urgent / same-day"
                    target="Propriétaires ayant besoin d'une intervention domestique sous 24-48h"
                    problem="Les plateformes généralistes privilégient le volume mais gèrent mal les demandes urgentes et standardisées."
                    offer="Service spécialisé avec prix affiché, disponibilité locale et réservation rapide."
                    wedge="Urgence + prix fixe + zone géographique"
                },
                @{
                    angle="Property turnover"
                    target="Propriétaires, bailleurs et gestionnaires entre deux occupants"
                    problem="Les remises en état nécessitent plusieurs prestataires et génèrent beaucoup de coordination."
                    offer="Pack standardisé de remise en état avec réservation centralisée."
                    wedge="Un workflow précis plutôt qu'un catalogue de services"
                },
                @{
                    angle="Recurring maintenance"
                    target="Propriétaires souhaitant externaliser l'entretien régulier de leur logement"
                    problem="L'entretien récurrent est fragmenté entre de nombreux intervenants."
                    offer="Abonnement de maintenance domestique avec prestations standardisées."
                    wedge="Récurrence + abonnement + simplicité"
                }
            )
        }

        "OTHER|PET_SERVICES" {
            return @(
                @{
                    angle="Pet emergency"
                    target="Propriétaires confrontés à un besoin ponctuel urgent"
                    problem="Trouver rapidement une solution fiable pour un animal est difficile lorsque le besoin survient au dernier moment."
                    offer="Réseau local de prestataires disponibles rapidement."
                    wedge="Disponibilité immédiate + confiance"
                },
                @{
                    angle="Specialized care"
                    target="Propriétaires d'animaux nécessitant des soins ou services spécialisés"
                    problem="Les besoins spécifiques sont difficiles à trouver sur les plateformes généralistes."
                    offer="Plateforme verticale regroupant uniquement les spécialistes d'un besoin précis."
                    wedge="Spécialisation forte"
                },
                @{
                    angle="Pet recurring services"
                    target="Propriétaires utilisant régulièrement des services pour leur animal"
                    problem="Les prestations récurrentes nécessitent des réservations répétitives et manquent de continuité."
                    offer="Abonnement regroupant plusieurs prestations récurrentes."
                    wedge="Récurrence + fidélisation"
                }
            )
        }

        "OTHER|REPAIR" {
            return @(
                @{
                    angle="High-value equipment"
                    target="Propriétaires d'équipements coûteux"
                    problem="Remplacer un équipement coûteux est souvent plus simple que trouver rapidement le bon réparateur."
                    offer="Réseau spécialisé avec diagnostic et devis standardisé."
                    wedge="Équipement à forte valeur"
                },
                @{
                    angle="Mobile repair"
                    target="Particuliers et petites entreprises"
                    problem="Le déplacement vers un atelier représente une friction importante pour certaines réparations."
                    offer="Réparation à domicile ou sur site avec créneaux réservables."
                    wedge="Mobile + prix transparent"
                },
                @{
                    angle="B2B local repair"
                    target="Petites entreprises dépendantes de leurs équipements"
                    problem="Une panne peut provoquer une perte d'exploitation disproportionnée."
                    offer="Service de réparation prioritaire avec SLA et intervention rapide."
                    wedge="Urgence B2B + abonnement"
                }
            )
        }

        "OTHER|STORAGE" {
            return @(
                @{
                    angle="Micro-storage"
                    target="Particuliers ayant besoin de quelques mètres cubes seulement"
                    problem="Les box traditionnels sont souvent surdimensionnés pour les petits volumes."
                    offer="Réservation d'espaces au volume réellement nécessaire."
                    wedge="Petit volume + paiement flexible"
                },
                @{
                    angle="Local distributed storage"
                    target="Habitants de zones où le self-storage est peu dense"
                    problem="Le stockage professionnel peut être éloigné du domicile."
                    offer="Réseau d'espaces disponibles chez des entreprises ou propriétaires."
                    wedge="Proximité + actifs sous-utilisés"
                },
                @{
                    angle="Business storage"
                    target="Indépendants, artisans et petits e-commerçants"
                    problem="Les petites entreprises ont besoin de stockage sans engagement sur un grand local."
                    offer="Stockage flexible avec réception et récupération des marchandises."
                    wedge="B2B + flexibilité"
                }
            )
        }

        "DELIVERY|DELIVERY_LOGISTICS" {
            return @(
                @{
                    angle="Local business delivery"
                    target="Commerces indépendants"
                    problem="Les petits commerces veulent proposer la livraison sans construire leur propre logistique."
                    offer="Réseau local de livraison à la demande."
                    wedge="Indépendants + zone locale"
                },
                @{
                    angle="Scheduled delivery"
                    target="Commerces vendant des produits volumineux"
                    problem="La livraison de produits volumineux est coûteuse et difficile à organiser."
                    offer="Tournées locales mutualisées avec créneaux planifiés."
                    wedge="Mutualisation logistique"
                },
                @{
                    angle="Specialized delivery"
                    target="Une verticale nécessitant des contraintes particulières"
                    problem="Les réseaux généralistes ne sont pas optimisés pour certaines catégories de produits."
                    offer="Réseau spécialisé avec procédures adaptées."
                    wedge="Verticalisation logistique"
                }
            )
        }

        "RENTAL|RENTAL" {
            return @(
                @{
                    angle="Rare-use equipment"
                    target="Particuliers utilisant rarement des équipements coûteux"
                    problem="L'achat d'équipements utilisés quelques fois par an est peu rentable."
                    offer="Location locale simple entre propriétaires et utilisateurs."
                    wedge="Usage occasionnel + proximité"
                },
                @{
                    angle="Professional equipment"
                    target="Artisans et petites entreprises"
                    problem="Certains équipements professionnels sont trop coûteux à acheter pour des besoins ponctuels."
                    offer="Location courte durée d'équipements spécialisés."
                    wedge="B2B + disponibilité locale"
                },
                @{
                    angle="Event equipment"
                    target="Particuliers et petites entreprises organisant des événements"
                    problem="Le matériel événementiel est coûteux et rarement utilisé."
                    offer="Catalogue local avec réservation et livraison optionnelle."
                    wedge="Pack événementiel"
                }
            )
        }

        "MARKETPLACE|OTHER" {
            return @(
                @{
                    angle="Vertical supplier marketplace"
                    target="Acheteurs professionnels d'une catégorie précise"
                    problem="Les marketplaces généralistes rendent difficile l'identification des fournisseurs réellement spécialisés."
                    offer="Annuaire transactionnel vertical avec fournisseurs vérifiés."
                    wedge="Expertise verticale"
                },
                @{
                    angle="Verified specialists"
                    target="Clients recherchant des prestataires à forte expertise"
                    problem="Le prix et les avis généralistes ne permettent pas toujours d'identifier le meilleur spécialiste."
                    offer="Matching basé sur compétences, spécialisation et disponibilité."
                    wedge="Qualification plutôt que volume"
                },
                @{
                    angle="Local niche marketplace"
                    target="Clients d'un marché géographique précis"
                    problem="Une offre locale fragmentée reste difficile à découvrir."
                    offer="Marketplace hyperlocale spécialisée."
                    wedge="Densité locale"
                }
            )
        }

        "OTHER|AUTO_SERVICES" {
            return @(
                @{
                    angle="Mobile maintenance"
                    target="Propriétaires de véhicules"
                    problem="Certaines opérations simples nécessitent inutilement un déplacement en garage."
                    offer="Intervention mobile à prix forfaitaire."
                    wedge="Mobile + prix fixe"
                },
                @{
                    angle="Fleet maintenance"
                    target="Petites flottes professionnelles"
                    problem="Les véhicules immobilisés génèrent des coûts et du temps perdu."
                    offer="Maintenance mobile planifiée directement sur site."
                    wedge="B2B + réduction d'immobilisation"
                },
                @{
                    angle="Convenience auto"
                    target="Conducteurs recherchant un service pratique"
                    problem="La principale friction de certains services automobiles est le temps nécessaire pour se déplacer."
                    offer="Réservation d'un technicien directement chez le client."
                    wedge="Convenience"
                }
            )
        }

        "OTHER|CHILDCARE" {
            return @(
                @{
                    angle="Last-minute childcare"
                    target="Parents ayant besoin d'une garde ponctuelle"
                    problem="Les solutions habituelles sont difficiles à mobiliser à court terme."
                    offer="Matching rapide avec intervenants vérifiés."
                    wedge="Dernière minute"
                },
                @{
                    angle="Specialized childcare"
                    target="Familles ayant des besoins particuliers"
                    problem="Les solutions généralistes couvrent mal certaines situations spécifiques."
                    offer="Réseau spécialisé par besoin."
                    wedge="Expertise spécialisée"
                },
                @{
                    angle="Backup childcare"
                    target="Parents actifs"
                    problem="Une absence imprévue du mode de garde habituel crée une rupture immédiate."
                    offer="Service de garde de secours accessible à la demande."
                    wedge="Backup care"
                }
            )
        }

        "SOFTWARE|OTHER" {
            return @(
                @{
                    angle="Single workflow"
                    target="Indépendants d'un métier précis"
                    problem="Une tâche administrative répétitive consomme du temps sans justifier un logiciel complet."
                    offer="Micro-SaaS automatisant un seul workflow."
                    wedge="Ultra-spécialisation"
                },
                @{
                    angle="Compliance workflow"
                    target="Petites entreprises soumises à des obligations récurrentes"
                    problem="Les obligations administratives sont souvent suivies manuellement."
                    offer="Automatisation du workflow et alertes."
                    wedge="Réduction du risque administratif"
                },
                @{
                    angle="Back-office automation"
                    target="TPE avec faible maturité numérique"
                    problem="Des tâches répétitives restent réalisées manuellement."
                    offer="Outil extrêmement simple automatisant une opération précise."
                    wedge="Simplicité radicale"
                }
            )
        }

        default {
            return @(
                @{
                    angle="Niche verticale"
                    target="Clients ayant un besoin précis"
                    problem="Les solutions généralistes répondent imparfaitement à un besoin spécialisé."
                    offer="Service ou plateforme spécialisée."
                    wedge="Verticalisation"
                },
                @{
                    angle="Hyperlocal"
                    target="Clients d'une zone géographique précise"
                    problem="L'offre locale est fragmentée."
                    offer="Service spécialisé hyperlocal."
                    wedge="Densité locale"
                },
                @{
                    angle="B2B spécialisé"
                    target="Petites entreprises"
                    problem="Les solutions existantes sont trop généralistes."
                    offer="Solution spécialisée pour un workflow précis."
                    wedge="B2B vertical"
                }
            )
        }
    }
}

$concepts = @()

foreach ($item in $data) {

    $variants = Get-ConceptVariants `
        -vertical ([string]$item.vertical) `
        -model ([string]$item.business_model)

    foreach ($variant in $variants) {

        $market = [int]$item.market_proof
        $replication = [int]$item.replication
        $accessibility = [int]$item.accessibility
        $competition = [int]$item.competition

        # ====================================================
        # CONCEPT QUALITY
        # ====================================================

        $specificity = 82
        $pain = [math]::Round(($market * 0.65) + ($specificity * 0.35))

        $execution = [math]::Round(
            ($replication * 0.30) +
            ($accessibility * 0.40) +
            ((100 - $competition) * 0.30)
        )

        $businessValue = [math]::Round(
            ($market * 0.25) +
            ($pain * 0.20) +
            ($execution * 0.20) +
            ($specificity * 0.15) +
            ($replication * 0.20)
        )

        # Bonus pour une niche claire
        if ($variant.angle -match "B2B|Urgent|Mobile|Specialized|Micro|Recurring|Backup|Rare-use") {
            $businessValue += 3
        }

        # Penalize overcrowded horizontal categories
        if ($competition -ge 75) {
            $businessValue -= 6
        }

        $businessValue = [math]::Min(100,[math]::Max(0,$businessValue))

        if ($businessValue -ge 80) {
            $verdict = "HIGH POTENTIAL"
            $action = "DEEP VALIDATE"
        }
        elseif ($businessValue -ge 70) {
            $verdict = "PROMISING"
            $action = "VALIDATE"
        }
        elseif ($businessValue -ge 60) {
            $verdict = "WATCH"
            $action = "COLLECT EVIDENCE"
        }
        else {
            $verdict = "WEAK"
            $action = "DISCARD"
        }

        # ====================================================
        # CLIENT THESIS
        # ====================================================

        $thesis = "$($variant.target). $($variant.problem) La proposition consiste à $($variant.offer.ToLower())."

        $concepts += [PSCustomObject]@{
            concept_score = $businessValue
            verdict = $verdict
            action = $action

            idea_name = "$($variant.angle) — $($item.vertical)"
            angle = $variant.angle

            vertical = [string]$item.vertical
            business_model = [string]$item.business_model

            target_customer = $variant.target
            problem = $variant.problem
            solution = $variant.offer
            differentiation = $variant.wedge

            business_thesis = $thesis

            monetization = if ($item.business_model -eq "RENTAL") {
                "Commission sur transaction + services additionnels"
            }
            elseif ($item.business_model -eq "MARKETPLACE") {
                "Commission transactionnelle ou abonnement fournisseur"
            }
            elseif ($item.business_model -eq "DELIVERY") {
                "Commission par livraison + frais de service"
            }
            elseif ($item.business_model -eq "SOFTWARE") {
                "Abonnement mensuel"
            }
            elseif ($item.business_model -eq "ON_DEMAND") {
                "Commission ou marge sur prestation"
            }
            else {
                "Commission, abonnement ou marge selon le modèle"
            }

            market_proof = $market
            replication = $replication
            accessibility = $accessibility
            competition = $competition

            source_company_count = [int]$item.company_count
            source_article_count = [int]$item.article_count
            source_country_count = [int]$item.country_count

            evidence_quality = if (
                $item.company_count -ge 15 -and
                $item.article_count -ge 20 -and
                $item.country_count -ge 2
            ) {"VERY HIGH"}
            elseif ($item.company_count -ge 8) {"HIGH"}
            elseif ($item.company_count -ge 3) {"MEDIUM"}
            else {"LOW"}

            source_cluster = "$($item.business_model) / $($item.vertical)"
        }
    }
}

$concepts = $concepts |
    Sort-Object concept_score -Descending

$concepts |
    ConvertTo-Json -Depth 10 |
    Set-Content $outputFile -Encoding UTF8

# ============================================================
# OUTPUT
# ============================================================

Write-Host ""
Write-Host "=============================================================="
Write-Host " BIZNESSHUNTER - RADAR 15"
Write-Host " BUSINESS CONCEPT ENGINE"
Write-Host "=============================================================="
Write-Host ""
Write-Host "Input    : $inputFile"
Write-Host "Output   : $outputFile"
Write-Host "Concepts  : $($concepts.Count)"
Write-Host ""

Write-Host "TOP BUSINESS CONCEPTS"
Write-Host "--------------------------------------------------------------"
Write-Host ""

$concepts |
    Select-Object -First 15 `
        concept_score,
        verdict,
        action,
        angle,
        vertical,
        business_model,
        target_customer,
        market_proof,
        replication,
        competition |
    Format-Table -Wrap -AutoSize

Write-Host ""
Write-Host "=============================================================="
Write-Host " TOP 10 CLIENT-READY CONCEPTS"
Write-Host "=============================================================="
Write-Host ""

$i = 1

foreach ($c in ($concepts | Where-Object {$_.verdict -in @("HIGH POTENTIAL","PROMISING")} | Select-Object -First 10)) {

    Write-Host ""
    Write-Host "[$i] $($c.concept_score)/100 | $($c.verdict)"
    Write-Host "--------------------------------------------------------------"
    Write-Host "IDEA       : $($c.idea_name)"
    Write-Host "CUSTOMER   : $($c.target_customer)"
    Write-Host "PROBLEM    : $($c.problem)"
    Write-Host "SOLUTION   : $($c.solution)"
    Write-Host "DIFFERENCE : $($c.differentiation)"
    Write-Host "MONETIZE   : $($c.monetization)"
    Write-Host "THESIS     : $($c.business_thesis)"
    Write-Host "EVIDENCE   : $($c.source_company_count) companies / $($c.source_article_count) articles / $($c.source_country_count) countries"
    Write-Host ""

    $i++
}

Write-Host ""
Write-Host "=============================================================="
Write-Host " RADAR 15 COMPLETE"
Write-Host "=============================================================="
