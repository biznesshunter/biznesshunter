$inputFile  = ".\radar16_final_opportunities.json"
$outputFile = ".\biznesshunter_final.json"

$data = Get-Content $inputFile -Raw | ConvertFrom-Json

$groups = @(
    @{
        name = "Marketplace de services à domicile"
        keywords = @("services à domicile","petits travaux","entretien du logement")
    },
    @{
        name = "Plateforme de services automobiles à la demande"
        keywords = @("automobile","réparation automobile","entretien automobile")
    },
    @{
        name = "Marketplace de services pour animaux"
        keywords = @("animaux","vétérinaires")
    },
    @{
        name = "Marketplace de stockage local"
        keywords = @("stockage")
    },
    @{
        name = "Marketplace de location entre particuliers"
        keywords = @("location entre particuliers","matériel et équipements","véhicules entre particuliers")
    },
    @{
        name = "Marketplace de réparation locale"
        keywords = @("réparateurs locaux","réparation de smartphones")
    },
    @{
        name = "Marketplace de garde d'enfants"
        keywords = @("garde d'enfants")
    }
)

$results = @()

foreach ($group in $groups) {

    $matches = @(
        foreach ($item in $data) {

            $found = $false

            foreach ($keyword in $group.keywords) {
                if ($item.opportunity -like "*$keyword*") {
                    $found = $true
                }
            }

            if ($found) {
                $item
            }
        }
    )

    if ($matches.Count -eq 0) {
        continue
    }

    $best = $matches |
        Sort-Object gap_score -Descending |
        Select-Object -First 1

    $totalCompanies = (
        $matches |
        Measure-Object company_count -Sum
    ).Sum

    $totalArticles = (
        $matches |
        Measure-Object article_count -Sum
    ).Sum

    $maxReplication = (
        $matches |
        Measure-Object replication -Maximum
    ).Maximum

    $maxCompetition = (
        $matches |
        Measure-Object competition_gap -Maximum
    ).Maximum

    $maxGeo = (
        $matches |
        Measure-Object geographic_gap -Maximum
    ).Maximum

    $finalScore = [math]::Round(
        ($best.gap_score * 0.50) +
        ($maxReplication * 0.20) +
        ($maxCompetition * 0.15) +
        ($maxGeo * 0.15)
    )

    if ($finalScore -ge 70) {
        $verdict = "HIGH GAP"
    }
    elseif ($finalScore -ge 60) {
        $verdict = "PROMISING GAP"
    }
    elseif ($finalScore -ge 50) {
        $verdict = "WATCH"
    }
    else {
        $verdict = "LOW"
    }

    $results += [PSCustomObject]@{
        opportunity     = $group.name
        gap_score       = $finalScore
        verdict         = $verdict

        company_count   = $totalCompanies
        article_count   = $totalArticles

        replication     = $maxReplication
        competition_gap = $maxCompetition
        geographic_gap  = $maxGeo

        source_niches   = ($matches.opportunity -join " | ")

        best_signal     = $best.opportunity
    }
}

$results =
    $results |
    Sort-Object gap_score -Descending

$results |
    ConvertTo-Json -Depth 10 |
    Set-Content $outputFile -Encoding UTF8

Write-Host ""
Write-Host "========================================"
Write-Host " BiznessHunter - Radar 17"
Write-Host " FINAL CONSOLIDATION"
Write-Host "========================================"
Write-Host ""
Write-Host "Final opportunities : $($results.Count)"
Write-Host ""

$results |
    Select-Object gap_score,verdict,opportunity,company_count,article_count,replication,competition_gap,geographic_gap |
    Format-Table -Wrap -AutoSize
