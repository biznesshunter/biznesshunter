$html = Invoke-WebRequest `
    -Uri "https://www.bing.com/search?q=Edify&setlang=en-us&cc=us&count=10" `
    -UseBasicParsing `
    -Headers @{
        "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/151.0 Safari/537.36"
        "Accept-Language" = "en-US,en;q=0.9"
    }

$pattern = '<li class="b_algo"[\s\S]*?<h2[^>]*>\s*<a[^>]+href="([^"]+)"[^>]*>([\s\S]*?)</a>'

$matches = [regex]::Matches(
    $html.Content,
    $pattern,
    [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
    [System.Text.RegularExpressions.RegexOptions]::Singleline
)

Write-Host ""
Write-Host "RESULTS FOUND: $($matches.Count)" -ForegroundColor Cyan
Write-Host ""

$matches | Select-Object -First 10 | ForEach-Object {

    $title = $_.Groups[2].Value -replace '<[^>]+>', ''
    $title = [System.Net.WebUtility]::HtmlDecode($title)
    $title = $title -replace '\s+', ' '
    $title = $title.Trim()

    $url = [System.Net.WebUtility]::HtmlDecode($_.Groups[1].Value)

    Write-Host "TITLE: $title" -ForegroundColor Green
    Write-Host "URL  : $url" -ForegroundColor DarkGray
    Write-Host ""
}
