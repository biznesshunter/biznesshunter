$data = Get-Content .\radar53_deduped.json -Raw | ConvertFrom-Json

$result = foreach ($item in $data) {

    $observations = [int]$item.observation_count
    $sources = @($item.sources).Count
    $cities = @($item.cities).Count
    $urls = @($item.urls).Count
    $ready = [int]$item.ready_count
    $unsupported = [int]$item.unsupported_count

    $volumeScore = [Math]::Min(25, $observations / 2)
    $sourceScore = [Math]::Min(20, $sources * 6.67)
    $cityScore = [Math]::Min(20, $cities / 2)
    $urlScore = [Math]::Min(15, $urls)
    $readyScore = [Math]::Min(15, $ready * 5)

    $unsupportedRatio = 0
    if ($observations -gt 0) {
        $unsupportedRatio = $unsupported / $observations
    }

    $unsupportedPenalty = [Math]::Round($unsupportedRatio * 20, 2)

    $rawScore =
        $volumeScore +
        $sourceScore +
        $cityScore +
        $urlScore +
        $readyScore -
        $unsupportedPenalty

    $proofScore = [Math]::Max(0, [Math]::Min(100, [Math]::Round($rawScore, 1)))

    [PSCustomObject]@{
        idea_name = $item.idea_name
        country = $item.country
        category = $item.category
        observation_count = $observations
        source_count = $sources
        city_count = $cities
        url_count = $urls
        ready_count = $ready
        unsupported_count = $unsupported
        volume_score = [Math]::Round($volumeScore, 1)
        source_score = [Math]::Round($sourceScore, 1)
        city_score = [Math]::Round($cityScore, 1)
        url_score = [Math]::Round($urlScore, 1)
        ready_score = [Math]::Round($readyScore, 1)
        unsupported_penalty = $unsupportedPenalty
        proof_score = $proofScore
    }
}

$result |
    Sort-Object proof_score -Descending |
    ConvertTo-Json -Depth 5 |
    Set-Content .\radar54_proof_scored.json -Encoding UTF8

Write-Host ""
Write-Host "Observations analysées : $($data.Count)"
Write-Host "Fichier créé : radar54_proof_scored.json"
Write-Host ""

$result |
    Sort-Object proof_score -Descending |
    Select-Object -First 15 idea_name,country,observation_count,source_count,city_count,url_count,ready_count,proof_score |
    Format-Table -AutoSize
