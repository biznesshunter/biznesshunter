$html = Invoke-WebRequest -Uri "https://www.bing.com/search?q=%22Edify%20Agent2Creator%20CtrlTool%22" -UseBasicParsing -Headers @{"User-Agent"="Mozilla/5.0"}

[regex]::Matches(
    $html.Content,
    '<h2[^>]*>.*?<a[^>]+href="([^"]+)"[^>]*>(.*?)</a>.*?</h2>',
    [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
    [System.Text.RegularExpressions.RegexOptions]::Singleline
) |
Select-Object -First 10 |
ForEach-Object {
    $title = $_.Groups[2].Value -replace '<[^>]+>',''
    $url = $_.Groups[1].Value

    Write-Host "TITLE: $title"
    Write-Host "URL  : $url"
    Write-Host ""
}
