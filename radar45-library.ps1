$x = Get-Content .\radar44_city_search_queue.json -Raw | ConvertFrom-Json

$tests = @($x) | Select-Object -First 10

$tests | ConvertTo-Json -Depth 5 | Set-Content .\radar45_test_queue.json -Encoding UTF8

Write-Host "TEST SEARCHES :" @($tests).Count
Write-Host "OUTPUT        : radar45_test_queue.json"
$tests | Format-Table idea_name,country,city -AutoSize
