$queue = Get-Content .\radar43_search_queue.json -Raw | ConvertFrom-Json

$cities = @{
    FR = @(
        "Paris","Lyon","Marseille","Toulouse","Bordeaux","Nantes",
        "Lille","Montpellier","Strasbourg","Nice","Rennes","Grenoble",
        "Rouen","Toulon","Clermont-Ferrand","Dijon","Angers","Nîmes",
        "Aix-en-Provence","Perpignan"
    )
    ES = @(
        "Madrid","Barcelona","Valencia","Seville","Zaragoza","Málaga",
        "Murcia","Palma","Alicante","Bilbao","A Coruña","Valladolid",
        "Vigo","Gijón","Granada","Tarragona","Córdoba","Alicante",
        "Salamanca","Pamplona"
    )
    UK = @(
        "London","Manchester","Birmingham","Liverpool","Leeds","Bristol",
        "Glasgow","Edinburgh","Cardiff","Sheffield","Nottingham",
        "Newcastle","Leicester","Coventry","Brighton","Southampton",
        "Reading","Oxford","Cambridge","Belfast"
    )
}

$o = foreach ($q in @($queue)) {

    foreach ($city in $cities[$q.country]) {

        [PSCustomObject]@{
            idea_name = $q.idea_name
            country = $q.country
            city = $city

            query_business = "$($q.idea_name) $city"
            query_competitors = "$($q.idea_name) competitors $city"
            query_marketplace = "$($q.idea_name) marketplace $city"
            query_price = "$($q.idea_name) price $city"
            query_demand = "$($q.idea_name) demand $city"
            query_local = "$($q.idea_name) rental $city"
        }
    }
}

$o | ConvertTo-Json -Depth 10 |
    Set-Content .\radar44_city_search_queue.json -Encoding UTF8

Write-Host ""
Write-Host "IDEA/COUNTRY PAIRS :" @($queue).Count
Write-Host "CITY SEARCHES      :" @($o).Count
Write-Host "OUTPUT             : radar44_city_search_queue.json"
Write-Host ""

$o | Select-Object -First 20 idea_name,country,city |
    Format-Table -Wrap -AutoSize
