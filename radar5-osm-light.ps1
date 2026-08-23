$ErrorActionPreference = "Stop"

$input = ".\radar4_model_gaps.json"
$output = ".\radar5_osm_light.json"

$models = @(
    @{name="Vehicle repair"; tags=@("shop=car_repair")},
    @{name="E-bike rental"; tags=@("amenity=bicycle_rental")},
    @{name="Equipment rental"; tags=@("shop=tool_rental")},
    @{name="Grocery delivery"; tags=@("shop=supermarket")},
    @{name="Food delivery"; tags=@("amenity=fast_food")},
    @{name="Local marketplace"; tags=@("amenity=marketplace")}
)

$countries = @(
    @{name="France"; area="France"},
    @{name="Spain"; area="Spain"},
    @{name="Germany"; area="Germany"}
)

$headers = @{
    "User-Agent" = "BiznessHunter/1.0 research"
}

$results = @()

foreach ($model in $models) {

    Write-Host ""
    Write-Host "=========================================="
    Write-Host "RADAR 5 LIGHT : $($model.name)"
    Write-Host "=========================================="

    foreach ($country in $countries) {

        $queryParts = @()

        foreach ($tag in $model.tags) {
            $parts = $tag -split "="
            $queryParts += '["' + $parts[0] + '"="' + $parts[1] + '"]'
        }

        $filter = ($queryParts -join ";")

        $query = @"
[out:json][timeout:20];
area["name"="$($country.area)"]["boundary"="administrative"]->.a;
(
  nwr$filter(area.a);
);
out count;
"@

        $encoded = [uri]::EscapeDataString($query)
        $url = "https://overpass-api.de/api/interpreter?data=$encoded"

        try {
            $response = Invoke-RestMethod `
                -Uri $url `
                -Headers $headers `
                -TimeoutSec 25

            $count = [int]$response.elements[0].tags.total

            if ($count -ge 100) {
                $level = "HIGH"
            }
            elseif ($count -ge 20) {
                $level = "MEDIUM"
            }
            elseif ($count -gt 0) {
                $level = "LOW"
            }
            else {
                $level = "NONE"
            }

            Write-Host "$($country.name): $level ($count)"

            $results += [PSCustomObject]@{
                model=$model.name
                country=$country.name
                count=$count
                level=$level
            }

        }
        catch {
            Write-Host "$($country.name): ERROR / SKIPPED"
        }

        Start-Sleep -Seconds 3
    }
}

$results |
    ConvertTo-Json -Depth 5 |
    Set-Content -Encoding UTF8 $output

Write-Host ""
Write-Host "=========================================="
Write-Host "RADAR 5 LIGHT — TERMINÉ"
Write-Host "=========================================="
Write-Host ""
Write-Host "Résultats : $output"
