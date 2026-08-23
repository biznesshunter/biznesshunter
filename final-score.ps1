$items = Get-Content .\evidence-v4.json -Raw | ConvertFrom-Json

$results = @()

foreach ($item in $items) {

    $text = $item.name.ToLower()

    # Capital nécessaire
    $capital = 10

    if ($text -match "hardware|robot|space|satellite|battery|vehicle") {
        $capital = 2
    }
    elseif ($text -match "marketplace|platform") {
        $capital = 7
    }
    elseif ($text -match "service|agency") {
        $capital = 9
    }
    elseif ($text -match "tool|software|ai|saas|app") {
        $capital = 10
    }

    # Faisabilité solo
    $solo = 10

    if ($text -match "hardware|robot|space|satellite|vehicle") {
        $solo = 2
    }
    elseif ($text -match "marketplace|platform") {
        $solo = 6
    }
    elseif ($text -match "service|agency") {
        $solo = 8
    }

    # Complexité
    $complexity = 10

    if ($text -match "hardware|robot|space|satellite|battery|vehicle") {
        $complexity = 2
    }
    elseif ($text -match "marketplace|platform") {
        $complexity = 6
    }

    $copy = $capital + $solo + $complexity

    $score = $item.proof + $copy

    if ($score -gt 100) {
        $score = 100
    }

    $results += [PSCustomObject]@{
        name = $item.name
        proof = $item.proof
        copy_opportunity = $copy
        BiznessHunterScore = $score
    }
}

$results |
    Sort-Object BiznessHunterScore -Descending |
    ConvertTo-Json -Depth 5 |
    Set-Content -Encoding UTF8 biznesshunter-results.json

$results |
    Sort-Object BiznessHunterScore -Descending |
    Format-Table -AutoSize
