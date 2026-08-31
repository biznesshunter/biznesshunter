$queue = Get-Content .\radar45_test_queue.json -Raw | ConvertFrom-Json

$results = @()

foreach ($item in @($queue)) {

    $q = [uri]::EscapeDataString(
        "$($item.idea_name) $($item.city) $($item.country)"
    )

    $url = "https://www.google.com/search?q=$q"

    $results += [PSCustomObject]@{
        idea_name = $item.idea_name
        country   = $item.country
        city      = $item.city
        search_url = $url
        status    = "READY_FOR_BROWSER"
    }
}

$results |
    ConvertTo-Json -Depth 5 |
    Set-Content .\radar47_browser_queue.json -Encoding UTF8

Write-Host "BROWSER SEARCHES :" @($results).Count
Write-Host "OUTPUT           : radar47_browser_queue.json"
