$data = Get-Content .\radar58_url_verified.json -Raw | ConvertFrom-Json

$result = foreach ($item in $data) {

    $live = [int]$item.live_url_count
    $urls = [int]$item.url_count
    $sources = @($item.sources | Where-Object { $_ })
    $sourceCount = $sources.Count

    if ($live -ge 2) {
        $proofStatus = "PROVEN"
        $proofLevel = 3
        $proofReason = "Multiple live URLs"
    }
    elseif ($live -eq 1) {
        $proofStatus = "PROVEN"
        $proofLevel = 3
        $proofReason = "Live URL verified"
    }
    elseif ($urls -gt 0 -and $sourceCount -gt 0) {
        $proofStatus = "SUPPORTED"
        $proofLevel = 2
        $proofReason = "Known source and URL, but HTTP verification unavailable"
    }
    elseif ($sourceCount -gt 0) {
        $proofStatus = "SUPPORTED"
        $proofLevel = 2
        $proofReason = "Known source identified"
    }
    else {
        $proofStatus = "UNVERIFIED"
        $proofLevel = 1
        $proofReason = "No exploitable source proof"
    }

    [PSCustomObject]@{
        idea_name          = $item.idea_name
        country            = $item.country
        category           = $item.category

        observation_count  = [int]$item.observation_count
        source_count       = $sourceCount
        city_count         = [int]$item.city_count

        url_count          = $urls
        live_url_count     = $live

        proof_status       = $proofStatus
        proof_level        = $proofLevel
        proof_reason       = $proofReason

        sources            = $sources
        cities             = @($item.cities)
        urls               = @($item.url_checks.url)
    }
}

$result |
    ConvertTo-Json -Depth 15 |
    Set-Content .\radar59_proof_classified.json -Encoding UTF8

Write-Host ""
Write-Host "========================================="
Write-Host "RADAR 59 - PROOF CLASSIFIER"
Write-Host "========================================="
Write-Host ""

Write-Host "Opportunités : $($result.Count)"
Write-Host ""

$result |
    Group-Object proof_status |
    Select-Object Name,Count |
    Sort-Object Name |
    Format-Table -AutoSize

Write-Host ""
Write-Host "PROVEN :"

$result |
    Where-Object proof_status -eq "PROVEN" |
    Sort-Object observation_count -Descending |
    Select-Object -First 20 idea_name,country,observation_count,source_count,live_url_count |
    Format-Table -AutoSize

Write-Host ""
Write-Host "SUPPORTED :"

$result |
    Where-Object proof_status -eq "SUPPORTED" |
    Sort-Object observation_count -Descending |
    Select-Object -First 20 idea_name,country,observation_count,source_count,url_count |
    Format-Table -AutoSize

Write-Host ""
Write-Host "Fichier créé : radar59_proof_classified.json"
Write-Host ""
