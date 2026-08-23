$ErrorActionPreference = "SilentlyContinue"

$headers = @{
    "User-Agent" = "BiznessHunter/1.0"
}

$results = @()

# =========================
# SOURCES
# =========================

$urls = @(
    "https://news.ycombinator.com/rss",
    "https://techcrunch.com/feed/"
)

foreach ($feed in $urls) {

    try {

        $response = Invoke-WebRequest `
            -UseBasicParsing `
            -Uri $feed `
            -Headers $headers `
            -TimeoutSec 20

        [xml]$xml = $response.Content

        foreach ($item in $xml.SelectNodes("//item")) {

            $title = [string]$item.title
            $url   = [string]$item.link

            if ($title) {

                $results += [PSCustomObject]@{
                    name   = $title
                    url    = $url
                    source = if ($feed -match "ycombinator") {"Hacker News"} else {"TechCrunch"}
                }
            }
        }
    }
    catch {}
}

# =========================
# BUSINESS SIGNALS
# =========================

$positive = @(
    "rental","rent","sharing","marketplace","booking",
    "subscription","membership","service","agency",
    "local","delivery","cleaning","repair","installation",
    "storage","property","real estate","education",
    "training","fitness","food","restaurant","commerce",
    "store","shop","product","consumer","home",
    "vehicle","car","bike","equipment","event",
    "travel","hospitality","beauty","pet","childcare",
    "franchise","platform","creator","resale","used",
    "leasing","on-demand","community"
)

$negative = @(
    "research paper","arxiv","algorithm","programming language",
    "developer tool","open source library","github repository",
    "chip architecture","quantum","physics","climate",
    "medical research","security vulnerability","cybersecurity",
    "iphone review","smartphone review","technical paper",
    "ai safety","machine learning benchmark"
)

$candidates = @()

foreach ($item in $results) {

    $text = $item.name.ToLower()
    $score = 0

    foreach ($word in $positive) {
        if ($text -match [regex]::Escape($word)) {
            $score++
        }
    }

    foreach ($word in $negative) {
        if ($text -match [regex]::Escape($word)) {
            $score -= 2
        }
    }

    # Signaux très forts
    if ($text -match "raised \$|funding|revenue|customers|users|launched|business|company|startup") {
        $score += 2
    }

    # On élimine le bruit
    if ($score -ge 2) {

        $candidates += [PSCustomObject]@{
            name = $item.name
            url = $item.url
            source = $item.source
            business_score = $score
        }
    }
}

$candidates = $candidates |
    Sort-Object -Property business_score -Descending | Sort-Object name -Unique

$candidates |
    ConvertTo-Json -Depth 5 |
    Set-Content -Encoding UTF8 business_candidates_v3.json

Write-Host ""
Write-Host "=========================================="
Write-Host "BUSINESS RADAR V3"
Write-Host "=========================================="
Write-Host ""
Write-Host "Sources récupérées : $($results.Count)"
Write-Host "Business candidates : $($candidates.Count)"
Write-Host ""

$candidates |
    Select-Object -First 30 name,business_score,source |
    Format-Table -AutoSize

