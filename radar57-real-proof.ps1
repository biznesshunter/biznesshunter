$data = Get-Content .\radar53_deduped.json -Raw | ConvertFrom-Json

$result = foreach ($item in $data) {

    $urls = @($item.urls) | Where-Object { $_ -and $_ -match '^https?://' }
    $sources = @($item.sources) | Where-Object { $_ }

    $urlCount = $urls.Count
    $sourceCount = $sources.Count
    $readyCount = [int]$item.ready_count
    $observationCount = [int]$item.observation_count

    # Niveau de preuve
    if ($readyCount -ge 3 -and $sourceCount -ge 2) {
        $proofLevel = "PROVEN_STRONG"
    }
    elseif ($readyCount -ge 1 -and $sourceCount -ge 2) {
        $proofLevel = "PROVEN"
    }
    elseif ($urlCount -ge 1) {
        $proofLevel = "WEAK_PROOF"
    }
    elseif ($sourceCount -ge 2) {
        $proofLevel = "PENDING_VERIFICATION"
    }
    else {
        $proofLevel = "INSUFFICIENT_DATA"
    }

    # Score de preuve indépendant du score business
    $sourceScore = [Math]::Min(30, $sourceCount * 10)
    $observationScore = [Math]::Min(30, $observationCount / 2)
    $readyScore = [Math]::Min(40, $readyCount * 20)

    $proofScore = [Math]::Round(
        [Math]::Min(
            100,
            $sourceScore + $observationScore + $readyScore
        ),
        1
    )

    [PSCustomObject]@{
        idea_name = $item.idea_name
        country = $item.country
        category = $item.category

        observation_count = $observationCount
        source_count = $sourceCount
        city_count = @($item.cities).Count
        url_count = $urlCount
        ready_count = $readyCount
        unsupported_count = [int]$item.unsupported_count

        proof_level = $proofLevel
        proof_score = $proofScore

        sources = $sources
        cities = @($item.cities)
        urls = $urls
    }
}

$result |
    Sort-Object proof_score -Descending |
    ConvertTo-Json -Depth 10 |
    Set-Content .\radar57_real_proof.json -Encoding UTF8

Write-Host ""
Write-Host "========================================="
Write-Host "RADAR 57 - REAL PROOF ENGINE"
Write-Host "========================================="
Write-Host ""
Write-Host "Opportunités analysées : $($result.Count)"
Write-Host ""

$result |
    Group-Object proof_level |
    Select-Object Name,Count |
    Sort-Object Name |
    Format-Table -AutoSize

Write-Host ""
Write-Host "TOP 15"
Write-Host ""

$result |
    Sort-Object proof_score -Descending |
    Select-Object -First 15 `
        idea_name,
        country,
        observation_count,
        source_count,
        city_count,
        url_count,
        ready_count,
        proof_level,
        proof_score |
    Format-Table -AutoSize

Write-Host ""
Write-Host "Fichier créé : radar57_real_proof.json"
Write-Host ""
