$inputFile = ".\radar7_opportunities.json"
$outputFile = ".\radar7_deduplicated.json"

if (!(Test-Path $inputFile)) {
    Write-Host "ERROR: $inputFile not found"
    exit
}

$data = Get-Content $inputFile -Raw | ConvertFrom-Json

$seen = @{}
$results = @()

foreach ($item in $data) {

    $title = [string]$item.title

    # Nettoyage du titre
    $key = $title.ToLower()

    # Supprimer les noms de médias fréquents après " - "
    $key = $key -replace '\s+-\s+.*$',''

    # Supprimer caractères spéciaux
    $key = $key -replace '[^a-z0-9 ]',' '

    # Normaliser espaces
    $key = $key -replace '\s+',' '
    $key = $key.Trim()

    # Mots peu utiles
    $stopWords = @(
        "startup",
        "company",
        "business",
        "launches",
        "launch",
        "launched",
        "new",
        "startup",
        "the",
        "this",
        "how",
        "why"
    )

    foreach ($word in $stopWords) {
        $key = $key -replace "\b$word\b",''
    }

    $key = $key -replace '\s+',' '
    $key = $key.Trim()

    # Si clé déjà rencontrée
    if ($seen.ContainsKey($key)) {

        # Garder le meilleur score
        $existingIndex = $seen[$key]

        if ($item.opportunity_score -gt $results[$existingIndex].opportunity_score) {
            $results[$existingIndex] = $item
        }

    }
    else {

        $seen[$key] = $results.Count
        $results += $item
    }
}

$results |
    Sort-Object opportunity_score -Descending |
    ConvertTo-Json -Depth 10 |
    Set-Content $outputFile -Encoding UTF8

Write-Host ""
Write-Host "========================================"
Write-Host " BiznessHunter - Deduplication"
Write-Host "========================================"
Write-Host ""
Write-Host "Input  : $inputFile"
Write-Host "Output : $outputFile"
Write-Host ""
Write-Host "Before : $($data.Count)"
Write-Host "After  : $($results.Count)"
Write-Host ""
Write-Host "Removed : $($data.Count - $results.Count)"
Write-Host ""

$results |
    Select-Object -First 30 opportunity_score,newness_score,copyability,verdict,title |
    Format-Table -Wrap -AutoSize
