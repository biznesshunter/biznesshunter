$tests = Get-Content .\radar51_source_test_queue.json -Raw |
    ConvertFrom-Json

$output = foreach ($item in @($tests)) {

    $source = [string]$item.source
    $category = [string]$item.category
    $city = [string]$item.city

    $url = $null
    $status = "UNSUPPORTED"

    # ==============================
    # ALLOVOISINS
    # ==============================
    if ($source -eq "allovoisins") {

        if ($category -eq "location_shampouineuse" -and $city -eq "Paris") {
            $url = "https://www.allovoisins.com/r/199/2/66035/0/location-Shampouineuse-Paris"
            $status = "READY"
        }
    }

    # ==============================
    # BRICOLIB
    # ==============================
    elseif ($source -eq "bricolib") {

        if ($category -eq "location_shampouineuse" -and $city -eq "Paris") {
            $url = "https://bricolib.net/location-shampouineuse/paris-75020"
            $status = "READY"
        }
    }

    # ==============================
    # POPPINS
    # ==============================
    elseif ($source -eq "poppins") {

        $url = $null
        $status = "UNSUPPORTED"
    }

    [PSCustomObject]@{
        idea_name = $item.idea_name
        country   = $item.country
        city      = $item.city
        category  = $item.category
        source    = $source
        url       = $url
        status    = $status
    }
}

$output |
    ConvertTo-Json -Depth 10 |
    Set-Content .\radar52_source_pilot.json -Encoding UTF8

Write-Host ""
Write-Host "PILOT SOURCES :" @($output).Count
Write-Host "READY         :" @($output | Where-Object status -eq "READY").Count
Write-Host "UNSUPPORTED   :" @($output | Where-Object status -eq "UNSUPPORTED").Count
Write-Host "OUTPUT        : radar52_source_pilot.json"
Write-Host ""

$output |
    Format-Table idea_name,city,category,source,status,url -AutoSize
