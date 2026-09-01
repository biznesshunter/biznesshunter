$data = Get-Content .\radar53_deduped.json -Raw | ConvertFrom-Json

$result = foreach ($item in $data) {

    $proofSources = @()

    foreach ($source in @($item.sources)) {
        if ($source) {
            $proofSources += [string]$source
        }
    }

    [PSCustomObject]@{
        idea_name       = $item.idea_name
        country         = $item.country
        category        = $item.category
        observation_count = [int]$item.observation_count
        source_count    = $proofSources.Count
        sources         = $proofSources
        cities          = @($item.cities)
        urls            = @($item.urls)
        ready_count     = [int]$item.ready_count
        unsupported_count = [int]$item.unsupported_count
        proof_status    = if ([int]$item.ready_count -gt 0) {
            "PROVEN"
        } else {
            "PENDING_VERIFICATION"
        }
    }
}

$result |
    ConvertTo-Json -Depth 10 |
    Set-Content .\radar56_verification_queue.json -Encoding UTF8

Write-Host ""
Write-Host "RADAR 56 - VERIFICATION QUEUE"
Write-Host "Opportunités : $($result.Count)"
Write-Host ""

$result |
    Group-Object proof_status |
    Select-Object Name,Count |
    Format-Table -AutoSize

Write-Host ""
Write-Host "TOP A VERIFIER :"

$result |
    Sort-Object observation_count -Descending |
    Select-Object -First 15 idea_name,country,category,observation_count,source_count,ready_count,proof_status |
    Format-Table -AutoSize

Write-Host ""
Write-Host "Fichier créé : radar56_verification_queue.json"
