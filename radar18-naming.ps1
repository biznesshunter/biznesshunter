Write-Host ""
Write-Host "========================================"
Write-Host " BiznessHunter - Radar 18"
Write-Host " SOURCE-BACKED OPPORTUNITY TITLES"
Write-Host "========================================"
Write-Host ""

$input = ".\radar17_opportunities.json"
$output = ".\radar18_opportunities.json"

$data = Get-Content $input -Raw | ConvertFrom-Json

$result = foreach ($x in $data) {

    $title = $x.opportunity

    switch -Regex ($title) {
        "services à domicile" {
            $title = "Réservation à la demande de services domestiques locaux"
            break
        }

        "petits travaux" {
            $title = "Marketplace de petits travaux domestiques réservables en ligne"
            break
        }

        "services automobiles" {
            $title = "Réservation en ligne de services automobiles locaux"
            break
        }

        "réparation locale" {
            $title = "Marketplace de réparateurs locaux avec réservation en ligne"
            break
        }

        "services pour animaux" {
            $title = "Marketplace locale de garde, promenade et soins pour animaux"
            break
        }

        "stockage local" {
            $title = "Marketplace de stockage chez des particuliers"
            break
        }

        "location entre particuliers" {
            $title = "Marketplace de location d'équipements entre particuliers"
            break
        }

        "garde d'enfants" {
            $title = "Marketplace locale de garde d'enfants à la demande"
            break
        }
    }

    [PSCustomObject]@{
        opportunity       = $title
        original_category = $x.opportunity
        gap_score         = $x.gap_score
        verdict           = $x.verdict
        company_count     = $x.company_count
        article_count     = $x.article_count
        replication       = $x.replication
        competition_gap   = $x.competition_gap
        geographic_gap    = $x.geographic_gap
    }
}

$result | ConvertTo-Json -Depth 10 | Set-Content $output -Encoding UTF8

Write-Host "Opportunities :" $result.Count
Write-Host ""

$result |
    Sort-Object gap_score -Descending |
    Format-Table opportunity,gap_score,company_count,article_count,replication -AutoSize

Write-Host ""
Write-Host "Output :" $output
