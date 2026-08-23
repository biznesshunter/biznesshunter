$inputFile = ".\radar13_opportunities.json"
$outputFile = ".\radar14_niches.json"

$data = Get-Content $inputFile -Raw | ConvertFrom-Json

# Mots trop génériques à ignorer
$stopWords = @(
    "startup","startups","company","companies","business","platform",
    "marketplace","service","services","app","apps","online","local",
    "new","launch","launches","raises","raise","million","funding",
    "funded","backed","based","technology","tech","market","markets",
    "customers","customer","users","user","businesses","company",
    "announces","announced","partner","partners","partnership",
    "growth","growing","revenue","industry","industry","solution",
    "solutions","future","global","world","worldwide","digital",
    "delivery","startup","startup's","platforms"
)

function Get-Words {
    param([string]$text)

    $text = $text.ToLower()

    # Garder uniquement les mots alphabétiques de 4+ caractères
    $words = [regex]::Matches($text, "\b[a-z]{4,}\b") |
        ForEach-Object { $_.Value } |
        Where-Object { $stopWords -notcontains $_ }

    return $words
}

$results = @()

foreach ($cluster in $data) {

    if (!$cluster.articles) {
        continue
    }

    $wordCounts = @{}
    $articleWords = @{}

    foreach ($article in @($cluster.articles)) {

        $title = [string]$article.title

        if ([string]::IsNullOrWhiteSpace($title)) {
            continue
        }

        $words = Get-Words $title

        foreach ($word in $words) {

            if (!$wordCounts.ContainsKey($word)) {
                $wordCounts[$word] = 0
            }

            $wordCounts[$word]++
        }
    }

    # Garder les termes apparaissant dans au moins 2 articles
    $topWords = $wordCounts.GetEnumerator() |
        Where-Object { $_.Value -ge 2 } |
        Sort-Object Value -Descending |
        Select-Object -First 8

    if ($topWords.Count -eq 0) {
        continue
    }

    $keywords = @($topWords | ForEach-Object { $_.Name })

    # Construire un titre de niche à partir des signaux dominants
    $vertical = [string]$cluster.vertical
    $base = [string]$cluster.opportunity

    $niche = "$base : " + ($keywords -join ", ")

    $results += [PSCustomObject]@{
        parent_opportunity = $base
        vertical = $vertical
        article_count = [int]$cluster.article_count
        keywords = ($keywords -join ", ")
        niche_signal = $niche
    }
}

$results |
    Sort-Object article_count -Descending |
    ConvertTo-Json -Depth 10 |
    Set-Content $outputFile -Encoding UTF8

Write-Host ""
Write-Host "========================================"
Write-Host " BiznessHunter - Radar 14"
Write-Host " AUTOMATIC NICHE DISCOVERY"
Write-Host "========================================"
Write-Host ""
Write-Host "Input  : $inputFile"
Write-Host "Output : $outputFile"
Write-Host ""
Write-Host "Niches detected : $($results.Count)"
Write-Host ""

$results |
    Select-Object -First 30 parent_opportunity,article_count,keywords |
    Format-Table -Wrap -AutoSize
