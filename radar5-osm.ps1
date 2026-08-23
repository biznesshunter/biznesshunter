$ErrorActionPreference = "Stop"

$input = ".\radar3_businesses.json"
$output = ".\radar5_osm_competition.json"

$businesses = Get-Content $input -Raw | ConvertFrom-Json

$countries = @(
    @{name="France"; lat=46.6; lon=2.2},
    @{name="Spain"; lat=40.4; lon=-3.7},
    @{name="Germany"; lat=51.2; lon=10.4}
)

function Get-Model {
    param([string]$title)

    $t = $title.ToLower()

    if ($t -match "e-bike|ebike") {
        return @{ model="E-bike rental"; tags=@('"amenity"="bicycle_rental"') }
    }

    if ($t -match "vehicle service|vehicle.*repair|repair startup") {
        return @{ model="Vehicle repair"; tags=@('"shop"="car_repair"') }
    }

    if ($t -match "equipment rental") {
        return @{ model="Equipment rental"; tags=@('"shop"="rental"') }
    }

    if ($t -match "grocery delivery|15-minute") {
        return @{ model="Grocery delivery"; tags=@('"shop"="supermarket"') }
    }

    if ($t -match "food delivery robots") {
        return @{ model="Food delivery"; tags=@('"amenity"="fast_food"','"amenity"="restaurant"') }
    }

    if ($t -match "marketplace|local vendors") {
        return @{ model="Local marketplace"; tags=@('"amenity"="marketplace"') }
    }

    if ($t -match "pet care|pet healthcare|pet.*clinic") {
        return @{ model="Pet care"; tags=@('"shop"="pet"','"amenity"="veterinary"') }
    }

    return $null
}

$results = @()

foreach ($business in $businesses) {

    $title = [string]$business.business
    $model = Get-Model $title

    if (-not $model) { continue }

    Write-Host ""
    Write-Host "=========================================="
    Write-Host "RADAR 5 OSM : $($model.model)"
    Write-Host "=========================================="

    foreach ($country in $countries) {

        $parts = @()

        foreach ($tag in $model.tags) {
            $parts += "node(around:150000,$($country.lat),$($country.lon))[$tag];"
            $parts += "way(around:150000,$($country.lat),$($country.lon))[$tag];"
        }

        $query = @"
[out:json][timeout:60];
(
$($parts -join "`n")
);
out center tags;
"@

        $count = 0
        $places = @()

        try {
            $response = Invoke-RestMethod `
                -Uri "https://overpass-api.de/api/interpreter" `
                -Method Post `
                -Body @{data=$query} `
                -Headers @{ "User-Agent"="BiznessHunter/1.0" } `
                -TimeoutSec 90

            $elements = @($response.elements)

            $count = $elements.Count

            foreach ($e in ($elements | Select-Object -First 20)) {
                $name = $e.tags.name

                if ($name) {
                    $places += $name
                }
            }
        }
        catch {
            Write-Host "ERREUR OSM : $($_.Exception.Message)"
        }

        if ($count -eq 0) {
            $competition = "NO OSM SIGNAL"
        }
        elseif ($count -le 10) {
            $competition = "LOW"
        }
        elseif ($count -le 50) {
            $competition = "MEDIUM"
        }
        else {
            $competition = "HIGH"
        }

        Write-Host "$($country.name): $competition ($count)"

        $results += [PSCustomObject]@{
            business=$title
            model=$model.model
            country=$country.name
            osm_count=$count
            competition=$competition
            examples=($places -join " | ")
        }

        Start-Sleep -Seconds 2
    }
}

$results |
    ConvertTo-Json -Depth 8 |
    Set-Content -Encoding UTF8 $output

Write-Host ""
Write-Host "=========================================="
Write-Host "BIZNESSHUNTER — RADAR 5 OSM"
Write-Host "=========================================="
Write-Host ""
Write-Host "Résultats : $output"
