$ErrorActionPreference = "Stop"

$items = Get-Content ".\business_candidates.json" -Raw | ConvertFrom-Json

$results = @()

foreach ($item in $items) {

    if (-not $item.url) {
        continue
    }

    Write-Host "Téléchargement : $($item.name)"

    try {

        $response = Invoke-WebRequest `
            -UseBasicParsing `
            -Uri $item.url `
            -TimeoutSec 30

        $html = [string]$response.Content

        # Nettoyage HTML
        $text = $html `
            -replace '(?is)<script.*?</script>', ' ' `
            -replace '(?is)<style.*?</style>', ' ' `
            -replace '(?is)<noscript.*?</noscript>', ' ' `
            -replace '<[^>]+>', ' ' `
            -replace '&nbsp;', ' ' `
            -replace '&amp;', '&' `
            -replace '&quot;', '"' `
            -replace '&#39;', "'" `
            -replace '\s+', ' '

        $text = $text.Trim()

        $results += [PSCustomObject]@{
            name = [string]$item.name
            url = [string]$item.url
            source = [string]$item.source
            content_length = $text.Length
            content = $text
        }

        Write-Host "  OK : $($text.Length) caractères"
    }
    catch {

        Write-Warning "  ECHEC : $($item.url)"
    }
}

$results |
    ConvertTo-Json -Depth 5 |
    Set-Content -Encoding UTF8 ".\pages_full.json"

Write-Host ""
Write-Host "=========================================="
Write-Host "PAGES FULL RECONSTRUIT"
Write-Host "=========================================="
Write-Host "Pages : $($results.Count)"
Write-Host ""

$results |
    Select-Object name,content_length |
    Format-Table -AutoSize
