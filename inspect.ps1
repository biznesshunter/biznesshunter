$items = Get-Content .\discovered_businesses.json -Raw | ConvertFrom-Json

$items |
    Select-Object name,url,source |
    Format-List
