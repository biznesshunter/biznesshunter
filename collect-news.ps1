$ErrorActionPreference = "Stop"

$queries = @(
    "new rental business",
    "new rental startup",
    "new equipment rental",
    "new sharing business",
    "new local service startup",
    "new physical marketplace",
    "new delivery service startup",
    "new storage business",
    "new home service startup",
    "new pet service startup",
    "new outdoor business",
    "new childcare business",
    "new repair service startup",
    "new local marketplace",
    "new consumer service startup"
)

$results = @()

foreach ($query in $queries) {

    Write-Host "Recherche : $query"

    $encoded = [uri]::EscapeDataString($query)
    $url = "https://news.google.com/rss/search?q=$encoded&hl=en-US&gl=US&ceid=US:en"

    try {
        [xml]$rss = Invoke-WebRequest `
            -Uri $url `
            -UseBasicParsing `
            -TimeoutSec 20

        foreach ($item in $rss.rss.channel.item) {
            $results += [PSCustomObject]@{
                title       = [string]$item.title
                link        = [string]$item.link
                description = [string]$item.description
                pubDate     = [string]$item.pubDate
                query       = $query
            }
        }
    }
    catch {
        Write-Warning "Erreur pour : $query"
    }
}

$results = @(
    $results | Sort-Object title,link -Unique
)

$results |
    ConvertTo-Json -Depth 5 |
    Set-Content -Encoding UTF8 ".\news_candidates.json"

Write-Host ""
Write-Host "=========================================="
Write-Host "BIZNESSHUNTER — NEWS COLLECTOR"
Write-Host "=========================================="
Write-Host ""
Write-Host "Articles collectés : $($results.Count)"
Write-Host ""
Write-Host "Résultats : news_candidates.json"
