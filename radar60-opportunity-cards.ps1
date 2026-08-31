$data = Get-Content .\radar59_validated_opportunities.json -Raw |
    ConvertFrom-Json

$results = foreach ($item in @($data)) {

    $testCost = 50

    $model = "Marketplace local de location entre particuliers"

    $whyNow = "Demande réelle détectée sur AlloVoisins et offre existante sur Bricolib."

    $customer = "Particuliers ayant besoin de nettoyer canapés, tapis, matelas ou sièges de voiture."

    $revenue = "Commission sur chaque location."

    $test = "Créer une landing page locale, publier quelques annonces ciblées et mesurer les demandes avant de développer une marketplace complète."

    $risk = "Le marché est déjà concurrentiel : une offre existante importante est présente à Paris."

    $replication = "Reproduire le modèle dans d'autres villes françaises où une demande existe mais où l'offre locale est moins dense."

    [PSCustomObject]@{
        idea_name = $item.idea_name
        country = $item.country
        city = $item.city

        validation_score = $item.validation_score
        verdict = $item.verdict

        market_demand = $item.demand
        existing_supply = $item.supply
        median_price = $item.median_price

        customer = $customer
        business_model = $model
        revenue_model = $revenue

        test_cost_eur = $testCost
        validation_test = $test

        market_proof = $whyNow
        main_risk = $risk
        replication_strategy = $replication

        sources = @($item.sources)
    }
}

$results |
    ConvertTo-Json -Depth 10 |
    Set-Content .\radar60_opportunity_cards.json -Encoding UTF8

Write-Host ""
Write-Host "OPPORTUNITY CARDS :" @($results).Count
Write-Host "OUTPUT             : radar60_opportunity_cards.json"
Write-Host ""

$results |
    Format-Table `
        idea_name,
        city,
        validation_score,
        verdict,
        test_cost_eur `
        -AutoSize
