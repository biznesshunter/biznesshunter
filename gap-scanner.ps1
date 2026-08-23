$ErrorActionPreference = "Stop"

$input = ".\radar3_businesses.json"
$output = ".\geographic_gaps.json"

$businesses = Get-Content $input -Raw | ConvertFrom-Json

$countries = @(
    @{code="FR"; name="France"; lang="fr-FR"; geo="FR"},
    @{code="ES"; name="Spain"; lang="es-ES"; geo="ES"},
    @{code="DE"; name="Germany"; lang="de-DE"; geo="DE"},
    @{code="IT"; name="Italy"; lang="it-IT"; geo="IT"},
    @{code="GB"; name="United Kingdom"; lang="en-GB"; geo="GB"},
    @{code="CA"; name="Canada"; lang="en-CA"; geo="CA"},
    @{code="AU"; name="Australia"; lang="en-AU"; geo="AU"},
    @{code="JP"; name="Japan"; lang="en-US"; geo="JP"},
    @{code="SG"; name="Singapore"; lang="en-US"; geo="SG"},
    @{code="IN"; name="India"; lang="en-IN"; geo="IN"}
)

$results = @()

foreach ($business in $businesses) {

    $title = [string]$business.business

    # Extraire un nom court approximatif
    $name = $title `
        -replace '(?i)^this on-demand vehicle service and repair startup.*','vehicle service repair startup' `
        -replace '(?i)^indian e-bike rental startup.*','Yulu' `
        -replace '(?i)^alpha controls.*','Alpha Controls equipment rental' `
        -replace '(?i)^15-minute grocery delivery startup.*','Tiggy' `
        -replace '(?i)^avride.*','Avride food delivery robots' `
        -replace '(?i)^historic dayton arcade.*','Dayton Arcade marketplace' `
        -replace '(?i)^shop the obx marketplace.*','OBX marketplace' `
        -replace '(?i)^local shop owners rebuild.*','Painted Tree marketplace' `
        -replace '(?i)^pet care startup supertails.*','Supertails'

    $name = $name.Trim()

    Write-Host ""
    Write-Host "=========================================="
    Write-Host "SCAN : $name"
    Write-Host "=========================================="

    $countryResults = @()

    foreach ($country in $countries) {

        $query = '"' + $name + '" ' + $country.name
        $encoded = [uri]::EscapeDataString($query)

        $url = "https://news.google.com/rss/search?q=$encoded&hl=$($country.lang)&gl=$($country.geo)&ceid=$($country.geo):en"

        $count = 0
        $examples = @()

        try {

            [xml]$rss = Invoke-WebRequest `
                -Uri $url `
                -UseBasicParsing `
                -TimeoutSec 15

            $items = @($rss.rss.channel.item)

            $count = $items.Count

            foreach ($item in ($items | Select-Object -First 3)) {
                $examples += [string]$item.title
            }

        }
        catch {
            $count = 0
        }

        if ($count -gt 0) {
            $status = "SIGNAL"
        }
        else {
            $status = "NO NEWS SIGNAL"
        }

        Write-Host "$($country.name): $status ($count)"

        $countryResults += [PSCustomObject]@{
            country = $country.name
            code = $country.code
            result_count = $count
            status = $status
            examples = ($examples -join " || ")
        }
    }

    $signals = @(
        $countryResults |
        Where-Object { $_.result_count -gt 0 }
    ).Count

    $noSignal = @(
        $countryResults |
        Where-Object { $_.result_count -eq 0 }
    ).Count

    # Plus le business est visible dans peu de marchés,
    # plus le signal d'arbitrage géographique est intéressant.
    $gapScore = 0

    if ($signals -le 2) {
        $gapScore += 40
    }
    elseif ($signals -le 4) {
        $gapScore += 25
    }
    elseif ($signals -le 6) {
        $gapScore += 10
    }

    if ($noSignal -ge 6) {
        $gapScore += 30
    }
    elseif ($noSignal -ge 4) {
        $gapScore += 20
    }

    if ([int]$business.traction -ge 20) {
        $gapScore += 20
    }

    if ([int]$business.replicable -ge 15) {
        $gapScore += 10
    }

    $gapScore = [Math]::Min($gapScore,100)

    $results += [PSCustomObject]@{
        business = $name
        original_title = $title
        source_url = $business.url

        gap_score = $gapScore

        markets_with_signal = $signals
        markets_without_signal = $noSignal

        countries = $countryResults
    }
}

$results = @(
    $results | Sort-Object gap_score -Descending
)

$results |
    ConvertTo-Json -Depth 8 |
    Set-Content -Encoding UTF8 $output

Write-Host ""
Write-Host "=========================================="
Write-Host "BIZNESSHUNTER — GEOGRAPHIC GAP SCANNER"
Write-Host "=========================================="
Write-Host ""
Write-Host "Business analysés : $($results.Count)"
Write-Host ""

foreach ($r in $results) {

    Write-Host "$($r.business) : GAP $($r.gap_score)/100"
    Write-Host "  Signal : $($r.markets_with_signal) marchés"
    Write-Host "  Sans signal : $($r.markets_without_signal) marchés"
    Write-Host ""
}

Write-Host "Résultats : $output"
