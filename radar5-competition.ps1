$ErrorActionPreference = "Stop"

$input = ".\radar3_businesses.json"
$output = ".\radar5_competition.json"

$businesses = Get-Content $input -Raw | ConvertFrom-Json

$countries = @(
    @{name="France"; lang="fr-FR"; gl="FR"},
    @{name="Spain"; lang="es-ES"; gl="ES"},
    @{name="Germany"; lang="de-DE"; gl="DE"}
)

function Get-Queries {
    param([string]$title)

    $t = $title.ToLower()

    if ($t -match "e-bike|ebike") {
        return @("e-bike rental","electric bike rental","e-bike sharing")
    }
    elseif ($t -match "vehicle service|vehicle.*repair|repair startup") {
        return @("mobile car repair","mobile vehicle repair","car repair at home")
    }
    elseif ($t -match "equipment rental") {
        return @("equipment rental","tool rental","professional equipment rental")
    }
    elseif ($t -match "grocery delivery|15-minute") {
        return @("rapid grocery delivery","15 minute grocery delivery","quick grocery delivery")
    }
    elseif ($t -match "food delivery robots") {
        return @("food delivery robots","delivery robots","robot food delivery")
    }
    elseif ($t -match "marketplace|local vendors") {
        return @("local physical marketplace","local vendor marketplace","artisan marketplace")
    }
    elseif ($t -match "pet care|pet healthcare|pet.*clinic") {
        return @("pet care service","pet clinic","pet healthcare")
    }

    return @()
}

$results = @()

foreach ($business in $businesses) {

    $title = [string]$business.business
    $queries = Get-Queries $title

    Write-Host ""
    Write-Host "=========================================="
    Write-Host "RADAR 5 : $title"
    Write-Host "=========================================="

    foreach ($country in $countries) {

        $competitors = @()

        foreach ($q in $queries) {

            $query = "$q $($country.name)"
            Write-Host "Recherche : $query"

            $encoded = [uri]::EscapeDataString($query)
            $url = "https://www.google.com/search?q=$encoded&hl=$($country.lang)"

            try {
                $html = (Invoke-WebRequest `
                    -Uri $url `
                    -UseBasicParsing `
                    -TimeoutSec 15).Content

                $matches = [regex]::Matches(
                    $html,
                    '(?i)<h3[^>]*>(.*?)</h3>'
                )

                foreach ($m in $matches) {
                    $name = ($m.Groups[1].Value -replace '<.*?>','').Trim()

                    if ($name.Length -gt 2) {
                        $competitors += $name
                    }
                }
            }
            catch {}
        }

        $competitors = @(
            $competitors |
            Select-Object -Unique |
            Select-Object -First 20
        )

        $count = $competitors.Count

        if ($count -eq 0) {
            $presence = "NO COMPETITORS FOUND"
        }
        elseif ($count -le 3) {
            $presence = "LOW"
        }
        elseif ($count -le 8) {
            $presence = "MEDIUM"
        }
        else {
            $presence = "HIGH"
        }

        Write-Host "$($country.name): $presence ($count)"

        $results += [PSCustomObject]@{
            business = $title
            country = $country.name
            competitor_count = $count
            competition = $presence
            competitors = $competitors
        }
    }
}

$results |
    ConvertTo-Json -Depth 8 |
    Set-Content -Encoding UTF8 $output

Write-Host ""
Write-Host "=========================================="
Write-Host "BIZNESSHUNTER — RADAR 5"
Write-Host "REAL COMPETITION SCAN"
Write-Host "=========================================="
Write-Host ""
Write-Host "Résultats : $output"
