$items = Get-Content .\validation_queue.json -Raw | ConvertFrom-Json

foreach ($item in $items) {

    $name = [string]$item.name

    # Nettoyage du titre pour obtenir le nom du business
    $business = $name `
        -replace '^show hn:\s*','' `
        -replace '\s*[-–—]\s*.*$','' `
        -replace '\s*\(.*\)$',''

    $business = $business.Trim()

    $queries = @(
        "`"$business`" revenue",
        "`"$business`" MRR",
        "`"$business`" ARR",
        "`"$business`" users",
        "`"$business`" customers",
        "`"$business`" reviews",
        "`"$business`" traction",
        "`"$business`" funding",
        "`"$business`" Product Hunt",
        "`"$business`" Reddit",
        "`"$business`" Hacker News"
    )

    $item | Add-Member `
        -NotePropertyName "validation_version" `
        -NotePropertyValue "V10" `
        -Force

    $item | Add-Member `
        -NotePropertyName "business_name_clean" `
        -NotePropertyValue $business `
        -Force

    $item | Add-Member `
        -NotePropertyName "evidence_queries" `
        -NotePropertyValue $queries `
        -Force
}

$items |
    ConvertTo-Json -Depth 20 |
    Set-Content .\validation_queue.json -Encoding UTF8

Write-Host ""
Write-Host "======================================"
Write-Host " BUSINESS VALIDATION V10"
Write-Host "======================================"

foreach ($item in $items) {

    Write-Host ""
    Write-Host "===== $($item.business_name_clean) ====="

    foreach ($query in $item.evidence_queries) {
        Write-Host "  $query"
    }
}
