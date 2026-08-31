$items = Get-Content .\validation_queue.json -Raw | ConvertFrom-Json

foreach ($item in $items) {

    if (-not $item.url_accessible) {
        continue
    }

    try {
        $response = Invoke-WebRequest -Uri $item.url -UseBasicParsing -TimeoutSec 20

        $html = [string]$response.Content
        $text = [System.Net.WebUtility]::HtmlDecode($html)
        $text = $text -replace '<script[\s\S]*?</script>', ' '
        $text = $text -replace '<style[\s\S]*?</style>', ' '
        $text = $text -replace '<[^>]+>', ' '
        $text = $text -replace '\s+', ' '
        $text = $text.ToLower()

        $item | Add-Member -NotePropertyName "page_content" -NotePropertyValue $text -Force

        Write-Host "OK  $($item.name) — $($text.Length) chars"
    }
    catch {
        $item | Add-Member -NotePropertyName "page_content" -NotePropertyValue $null -Force

        Write-Host "ERR $($item.name)"
    }
}

$items |
    ConvertTo-Json -Depth 10 |
    Set-Content .\validation_queue.json -Encoding UTF8

$items |
    Select-Object name,@{N="content_length";E={ if ($_.page_content) { $_.page_content.Length } else { 0 } }} |
    Format-Table -AutoSize
