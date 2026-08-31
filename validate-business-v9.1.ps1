$items = Get-Content .\validation_queue.json -Raw | ConvertFrom-Json

foreach ($item in $items) {

    $name = [string]$item.name
    $url  = [string]$item.url
    $page = ([string]$item.page_content).ToLower()

    $item | Add-Member -NotePropertyName "validation_version" -NotePropertyValue "V9.1" -Force
    $item | Add-Member -NotePropertyName "evidence_sources" -NotePropertyValue @() -Force
    $item | Add-Member -NotePropertyName "independent_evidence_count" -NotePropertyValue 0 -Force
    $item | Add-Member -NotePropertyName "independent_evidence" -NotePropertyValue $false -Force
    $item | Add-Member -NotePropertyName "evidence_quality" -NotePropertyValue "NONE" -Force

    $sources = @()

    # SOURCE PRIMAIRE UNIQUEMENT
    if ($item.url_accessible -eq $true -and $url) {
        $sources += [PSCustomObject]@{
            type = "PRIMARY"
            url = $url
            independent = $false
            status = "ACCESSIBLE"
        }
    }

    # IMPORTANT :
    # On NE considère PAS les mentions "Reddit", "Show HN",
    # "GitHub", etc. présentes dans la page primaire
    # comme des preuves indépendantes.
    #
    # Les preuves indépendantes seront ajoutées par le collecteur
    # externe dans une prochaine étape.

    $item.evidence_sources = $sources

    $independentSources = @(
        $sources | Where-Object {
            $_.independent -eq $true
        }
    )

    $item.independent_evidence_count = $independentSources.Count
    $item.independent_evidence = ($independentSources.Count -gt 0)

    # QUALITÉ
    if ($item.independent_evidence_count -ge 2) {
        $item.evidence_quality = "STRONG"
    }
    elseif ($item.independent_evidence_count -eq 1) {
        $item.evidence_quality = "MEDIUM"
    }
    elseif ($sources.Count -gt 0) {
        $item.evidence_quality = "LOW"
    }
    else {
        $item.evidence_quality = "NONE"
    }
}

$items |
    ConvertTo-Json -Depth 15 |
    Set-Content .\validation_queue.json -Encoding UTF8

Write-Host ""
Write-Host "=============================="
Write-Host " BUSINESS VALIDATION V9.1"
Write-Host "=============================="
Write-Host ""

$items |
    Select-Object `
        name,
        validation_status,
        commercial_proof_level,
        evidence_quality,
        independent_evidence_count |
    Format-Table -AutoSize
