$ideas = @(
"Marketplace de location de shampouineuses pour canapés entre particuliers"
"Marketplace de location de nettoyeurs vapeur entre particuliers"
"Marketplace de location de remorques pour particuliers sans remorque"
"Marketplace de location de nettoyeurs haute pression entre particuliers"
"Marketplace de location de débroussailleuses entre particuliers"
"Marketplace de location de scarificateurs entre particuliers"
"Marketplace de location de taille-haies entre particuliers"
"Marketplace de location de fendeuses à bois entre particuliers"
"Marketplace de location de tentes de réception entre particuliers"
"Réservation en ligne de gardiens de chats à domicile pendant les vacances"
"Réservation en ligne de ménage de sortie de location"
"Réservation en ligne de promeneurs de chiens indépendants dans une ville"
)

$countries = @(
    [PSCustomObject]@{code="FR";name="France";language="fr";currency="EUR"},
    [PSCustomObject]@{code="ES";name="Spain";language="es";currency="EUR"},
    [PSCustomObject]@{code="UK";name="United Kingdom";language="en";currency="GBP"}
)

$o = foreach ($idea in $ideas) {
    foreach ($c in $countries) {
        [PSCustomObject]@{
            idea_name = $idea
            country = $c.code
            country_name = $c.name
            language = $c.language
            currency = $c.currency
            query_business = "$idea $($c.name)"
            query_competitors = "$idea competitors $($c.name)"
            query_marketplace = "$idea marketplace $($c.name)"
            query_price = "$idea price $($c.name)"
            query_demand = "$idea demand $($c.name)"
        }
    }
}

$o | ConvertTo-Json -Depth 10 |
    Set-Content .\radar43_search_queue.json -Encoding UTF8

Write-Host ""
Write-Host "BUSINESSES :" $ideas.Count
Write-Host "COUNTRIES  :" $countries.Count
Write-Host "SEARCHES   :" @($o).Count
Write-Host "OUTPUT     : radar43_search_queue.json"
Write-Host ""

$o | Select-Object -First 12 idea_name,country |
    Format-Table -Wrap -AutoSize
