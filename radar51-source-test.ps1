$queue = ConvertFrom-Json (Get-Content .\radar50_source_queue.json -Raw)

$tests = New-Object System.Collections.Generic.List[object]

$seen = @{}

foreach ($item in $queue) {

    $key = "{0}|{1}|{2}|{3}" -f `
        $item.idea_name,
        $item.country,
        $item.city,
        $item.source

    if ($seen.ContainsKey($key)) {
        continue
    }

    $seen[$key] = $true

    $tests.Add([PSCustomObject]@{
        idea_name = [string]$item.idea_name
        country   = [string]$item.country
        city      = [string]$item.city
        category  = [string]$item.category
        source    = [string]$item.source
    })
}

$tests |
    ConvertTo-Json -Depth 10 |
    Set-Content .\radar51_source_test_queue.json -Encoding UTF8

Write-Host ""
Write-Host "SOURCE QUEUE :" $queue.Count
Write-Host "UNIQUE TESTS :" $tests.Count
Write-Host "OUTPUT       : radar51_source_test_queue.json"
Write-Host ""

$tests |
    Group-Object source |
    Select-Object Name,Count |
    Sort-Object Name |
    Format-Table -AutoSize
