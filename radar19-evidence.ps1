Write-Host ""
Write-Host "========================================"
Write-Host " BiznessHunter - Radar 19 FIX v4"
Write-Host " EXPLICIT OPPORTUNITY -> CLUSTER MAP"
Write-Host "========================================"
Write-Host ""

$opportunities = Get-Content .\radar18_concrete_business_ideas.json -Raw | ConvertFrom-Json
$clusters = Get-Content .\radar9_1_clusters.json -Raw | ConvertFrom-Json

Write-Host "Opportunities : $($opportunities.Count)"
Write-Host "Clusters      : $($clusters.Count)"
Write-Host ""

# Mapping explicite : opportunité -> cluster source exact
$map = @{
    "Dépannage domestique garanti sous 24h pour petites interventions" = "ON_DEMAND / HOME_SERVICES"
    "Montage de meubles à domicile en moins de 48h" = "ON_DEMAND / HOME_SERVICES"
    "Inspection mensuelle des logements locatifs pour petits bailleurs" = "MAINTENANCE / PROPERTY"
    "Location locale de nettoyeurs haute pression professionnels" = "RENTAL / RENTAL"
    "Location de matériel professionnel aux artisans pour besoins ponctuels" = "RENTAL / RENTAL"
    "Location de packs lumière et son pour anniversaires de 30 à 100 personnes" = "RENTAL / EVENT_SERVICES"
    "Transport d'animaux vers le vétérinaire pour propriétaires sans véhicule" = "ON_DEMAND / PET_SERVICES"
    "Visites à domicile pour chiens âgés pendant les journées de travail" = "ON_DEMAND / PET_SERVICES"
    "Livraison planifiée de meubles pour magasins indépendants" = "ON_DEMAND / DELIVERY"
    "Pack remise en état entre deux locations en 72h" = "MAINTENANCE / PROPERTY"
    "Garde ponctuelle de sortie de crèche pour parents aux horaires décalés" = "ON_DEMAND / CHILDCARE"
    "Promenade courte pour chiens âgés ou à mobilité réduite" = "ON_DEMAND / PET_SERVICES"
    "Stockage de 1 à 3 m³ chez des commerçants disposant d'espace inutilisé" = "MARKETPLACE / STORAGE"
    "Réparation prioritaire des équipements de cuisine pour petits restaurants" = "ON_DEMAND / REPAIR"
    "Réparation mobile de petits électroménagers à domicile" = "ON_DEMAND / REPAIR"
    "Remplacement mobile de batterie automobile à domicile" = "ON_DEMAND / AUTO_SERVICES"
}

$result = @()

foreach ($opp in $opportunities) {

    $name = $opp.idea_name
    $category = $opp.original_category

    $expectedCluster = $map[$name]

    $matches = @(
        $clusters | Where-Object {
            $_.cluster_name -eq $expectedCluster
        }
    )

    $companies = @()
    $countries = @()
    $articles = @()
    $signals = @()

    foreach ($cluster in $matches) {

        if ($cluster.companies) {
            $companies += ($cluster.companies -split ",")
        }

        if ($cluster.countries) {
            $countries += ($cluster.countries -split ",")
        }

        if ($cluster.source_articles) {

            foreach ($article in $cluster.source_articles) {

                if ($article.title) {

                    $articles += [PSCustomObject]@{
                        title = $article.title
                        url   = $article.url
                    }

                    if ($article.signals) {
                        $signals += ($article.signals -split ",")
                    }
                }
            }
        }
    }

    $companies = @(
        $companies |
        ForEach-Object { $_.ToString().Trim() } |
        Where-Object { $_ } |
        Sort-Object -Unique
    )

    $countries = @(
        $countries |
        ForEach-Object { $_.ToString().Trim() } |
        Where-Object { $_ } |
        Sort-Object -Unique
    )

    $signals = @(
        $signals |
        ForEach-Object { $_.ToString().Trim() } |
        Where-Object { $_ } |
        Sort-Object -Unique
    )

    $articles = @(
        $articles |
        Where-Object { $_.title } |
        Sort-Object title -Unique
    )

    $result += [PSCustomObject]@{

        opportunity       = $name
        original_category = $category

        source_cluster    = $expectedCluster

        gap_score         = $opp.gap_score
        verdict            = $opp.verdict

        company_count     = $companies.Count
        companies         = @($companies | Select-Object -First 20)

        country_count     = $countries.Count
        countries         = @($countries)

        article_count     = $articles.Count
        source_articles   = @($articles | Select-Object -First 20)

        replication       = $opp.replication
        competition_gap   = $opp.competition_gap
        geographic_gap    = $opp.geographic_gap

        signals           = @($signals)

        evidence_status   = if ($matches.Count -gt 0) {
            "SOURCE_MATCH"
        } else {
            "NO_SOURCE_MATCH"
        }
    }
}

$result |
    ConvertTo-Json -Depth 15 |
    Set-Content .\radar19_evidence.json -Encoding UTF8

Write-Host ""
Write-Host "Output : .\radar19_evidence.json"
Write-Host ""

$result |
    Select-Object opportunity,source_cluster,gap_score,company_count,country_count,article_count,evidence_status |
    Format-Table -AutoSize

Write-Host ""
Write-Host "Evidence generated : $($result.Count)"

$missing = @(
    $result | Where-Object {
        $_.evidence_status -eq "NO_SOURCE_MATCH"
    }
)

Write-Host ""
Write-Host "Missing source matches : $($missing.Count)"

if ($missing.Count -gt 0) {
    Write-Host ""
    $missing | Select-Object opportunity,source_cluster | Format-Table -AutoSize
}



