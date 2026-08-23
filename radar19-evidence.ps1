Write-Host ""
Write-Host "========================================"
Write-Host " BiznessHunter - Radar 19 FIX v4"
Write-Host " EXPLICIT OPPORTUNITY -> CLUSTER MAP"
Write-Host "========================================"
Write-Host ""

$opportunities = Get-Content .\radar18_opportunities.json -Raw | ConvertFrom-Json
$clusters = Get-Content .\radar9_1_clusters.json -Raw | ConvertFrom-Json

Write-Host "Opportunities : $($opportunities.Count)"
Write-Host "Clusters      : $($clusters.Count)"
Write-Host ""

# Mapping explicite : opportunité -> cluster source exact
$map = @{
    "Réservation à la demande de services domestiques locaux" = "ON_DEMAND / HOME_SERVICES"
    "Marketplace de petits travaux domestiques réservables en ligne" = "MARKETPLACE / HOME_SERVICES"

    "Entretien automobile mobile à domicile" = "ON_DEMAND / AUTO_SERVICES"
    "Réservation de réparation automobile" = "ON_DEMAND / AUTO_SERVICES"
    "Réservation en ligne de services automobiles locaux" = "ON_DEMAND / AUTO_SERVICES"
    "Réparation automobile à la demande" = "ON_DEMAND / AUTO_SERVICES"

    "Marketplace de garde et soins pour animaux" = "MARKETPLACE / PET_SERVICES"
    "Services vétérinaires à la demande" = "ON_DEMAND / PET_SERVICES"

    "Marketplace de stockage chez des particuliers" = "MARKETPLACE / STORAGE"

    "Marketplace de réparateurs locaux" = "MARKETPLACE / REPAIR"
    "Réparation de smartphones à la demande" = "ON_DEMAND / REPAIR"

    "Location de matériel et équipements" = "RENTAL / RENTAL"
    "Marketplace de location d'équipements entre particuliers" = "MARKETPLACE / RENTAL"
    "Location de véhicules entre particuliers" = "RENTAL / RENTAL"

    "Marketplace locale de garde d'enfants à la demande" = "ON_DEMAND / CHILDCARE"
}

$result = @()

foreach ($opp in $opportunities) {

    $name = $opp.opportunity
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
