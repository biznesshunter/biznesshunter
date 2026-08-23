$ErrorActionPreference = "Stop"

$headers = @{
    "User-Agent" = "BiznessHunter/1.0"
}

$results = @()

# -------------------------
# Hacker News
# -------------------------

try {
    $stories = Invoke-RestMethod `
        -Uri "https://hacker-news.firebaseio.com/v0/newstories.json" `
        -Headers $headers `
        -TimeoutSec 20

    foreach ($id in ($stories | Select-Object -First 50)) {

        try {
            $story = Invoke-RestMethod `
                -Uri "https://hacker-news.firebaseio.com/v0/item/$id.json" `
                -Headers $headers `
                -TimeoutSec 10

            if ($story.type -eq "story" -and $story.title) {
                $results += [PSCustomObject]@{
                    name = $story.title
                    url = $story.url
                    discovered_at = (Get-Date).ToString("yyyy-MM-dd")
                    source = "Hacker News"
                }
            }
        }
        catch {
            # On ignore les histoires individuelles défaillantes
        }
    }
}
catch {
    Write-Warning "Hacker News inaccessible : $($_.Exception.Message)"
}

# -------------------------
# TechCrunch RSS
# -------------------------

try {
    $response = Invoke-WebRequest -UseBasicParsing `
        -Uri "https://techcrunch.com/feed/" `
        -Headers $headers `
        -TimeoutSec 20

    [xml]$xml = $response.Content

    foreach ($item in $xml.SelectNodes("//item")) {

        if ($item.title) {
            $results += [PSCustomObject]@{
                name = [string]$item.title
                url = [string]$item.link
                discovered_at = (Get-Date).ToString("yyyy-MM-dd")
                source = "TechCrunch"
            }
        }
    }
}
catch {
    Write-Warning "TechCrunch inaccessible : $($_.Exception.Message)"
}

# -------------------------
# Sauvegarde
# -------------------------

$results =
    $results |
    Where-Object { $_.name } |
    Sort-Object name -Unique

$results |
    ConvertTo-Json -Depth 5 |
    Set-Content -Encoding UTF8 discovered_businesses.json

Write-Host ""
Write-Host "Candidats détectés : $($results.Count)"
Write-Host ""

$results |
    Select-Object -First 10 name,source |
    Format-Table -AutoSize

