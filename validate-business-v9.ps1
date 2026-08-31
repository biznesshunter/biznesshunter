$items = Get-Content .\validation_queue.json -Raw | ConvertFrom-Json

foreach ($item in $items) {

    $item | Add-Member -NotePropertyName "validation_version" -NotePropertyValue "V9" -Force
    $item | Add-Member -NotePropertyName "evidence_sources" -NotePropertyValue @() -Force
    $item | Add-Member -NotePropertyName "independent_evidence_count" -NotePropertyValue 0 -Force
    $item | Add-Member -NotePropertyName "independent_evidence" -NotePropertyValue $false -Force
    $item | Add-Member -NotePropertyName "evidence_quality" -NotePropertyValue "NONE" -Force

    $sources = @()

    # SOURCE PRIMAIRE
    if ($item.url_accessible -eq $true -and $item.url) {
        $sources += [PSCustomObject]@{
            type = "PRIMARY"
            url = [string]$item.url
            independent = $false
            status = "ACCESSIBLE"
        }
    }

    # SOURCES DÉJÀ PRÉSENTES DANS LES DONNÉES
    if ($item.page_content) {

        $page = [string]$item.page_content

        if ($page -match 'product hunt') {
            $sources += [PSCustomObject]@{
                type = "PRODUCT_HUNT"
                url = ""
                independent = $true
                status = "DETECTED"
            }
        }

        if ($page -match 'reddit') {
            $sources += [PSCustomObject]@{
                type = "REDDIT"
                url = ""
                independent = $true
                status = "DETECTED"
            }
        }

        if ($page -match 'hacker news|show hn') {
            $sources += [PSCustomObject]@{
                type = "HACKER_NEWS"
                url = ""
                independent = $true
                status = "DETECTED"
            }
        }

        if ($page -match 'github') {
            $sources += [PSCustomObject]@{
                type = "GITHUB"
                url = ""
                independent = $true
                status = "DETECTED"
            }
        }
    }

    $item.evidence_sources = $sources

    $independent = @(
        $sources | Where-Object {
            $_.independent -eq $true
        }
    )

    $item.independent_evidence_count = $independent.Count
    $item.independent_evidence = ($independent.Count -gt 0)

    # QUALITÉ
    if ($item.independent_evidence_count -ge 2) {
        $item.evidence_quality = "STRONG"
    }
    elseif ($item.independent_evidence_count -eq 1) {
        $item.evidence_quality = "MEDIUM"
    }
    else {
        $item.evidence_quality = "LOW"
    }
}

$items |
    ConvertTo-Json -Depth 15 |
    Set-Content .\validation_queue.json -Encoding UTF8

Write-Host ""
Write-Host "=============================="
Write-Host " BUSINESS VALIDATION V9"
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
