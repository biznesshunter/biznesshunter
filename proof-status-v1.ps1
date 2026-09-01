$data = Get-Content .\radar52_source_pilot.json -Raw | ConvertFrom-Json

$result = foreach ($item in $data) {

    $status = [string]$item.status
    $url = [string]$item.url

    if ($status -eq "READY" -and $url) {
        $proof_status = "PROVEN"
    }
    elseif ($status -eq "UNSUPPORTED") {
        $proof_status = "PENDING"
    }
    elseif (-not $url) {
        $proof_status = "NOT_FOUND"
    }
    else {
        $proof_status = "PENDING"
    }

    [PSCustomObject]@{
        idea_name = $item.idea_name
        country   = $item.country
        city      = $item.city
        category  = $item.category
        source    = $item.source
        url       = if ($url) { $url } else { $null }
        status    = $status
        proof_status = $proof_status
    }
}

$result |
    ConvertTo-Json -Depth 10 |
    Set-Content .\radar55_proof_status.json -Encoding UTF8

Write-Host ""
Write-Host "RADAR 55 - PROOF STATUS"
Write-Host "Observations : $($result.Count)"
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
    Select-Object -First 20 idea_name,country,city,source,url |
    Format-Table -AutoSize

Write-Host ""
Write-Host "Fichier créé : radar55_proof_status.json"
