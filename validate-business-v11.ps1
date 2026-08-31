$items = Get-Content .\validation_queue.json -Raw | ConvertFrom-Json

foreach ($item in $items) {

    $item | Add-Member `
        -NotePropertyName "validation_version" `
        -NotePropertyValue "V11" `
        -Force

    $item | Add-Member `
        -NotePropertyName "external_evidence" `
        -NotePropertyValue @() `
        -Force

    $item | Add-Member `
        -NotePropertyName "external_evidence_count" `
        -NotePropertyValue 0 `
        -Force

    Write-Host ""
    Write-Host "======================================"
    Write-Host $item.business_name_clean
    Write-Host "======================================"

    foreach ($query in $item.evidence_queries) {

        Write-Host ""
        Write-Host "SEARCH: $query"

        # Placeholder pour le collecteur externe
        # Les résultats seront injectés ici par le moteur de recherche.

    }
}

$items |
    ConvertTo-Json -Depth 20 |
    Set-Content .\validation_queue.json -Encoding UTF8

Write-Host ""
Write-Host "V11 READY"
