$items = Get-Content .\business_candidates.json -Raw | ConvertFrom-Json

$results = @()

foreach ($item in $items) {

    if (-not $item.url) {
        continue
    }

    try {
        $page = Invoke-WebRequest `
            -UseBasicParsing `
            -Uri $item.url `
            -TimeoutSec 20

        $text = $page.Content `
            -replace '<script[\s\S]*?</script>', ' ' `
            -replace '<style[\s\S]*?</style>', ' ' `
            -replace '<[^>]+>', ' ' `
            -replace '\s+', ' '

        $text = $text.Trim()

        $results += [PSCustomObject]@{
            name = $item.name
            url = $item.url
            source = $item.source
            content_length = $text.Length
            content = $text
        }

        Write-Host "OK : $($item.name) [$($text.Length) caractères]"
    }
    catch {
        Write-Warning "Échec : $($item.name)"
    }
}

$results |
    ConvertTo-Json -Depth 5 |
    Set-Content -Encoding UTF8 pages_full.json
