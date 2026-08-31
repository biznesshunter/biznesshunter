$x = Get-Content ".\radar8_models.json" -Raw | ConvertFrom-Json
$ideas = @()

foreach ($item in @($x)) {

    $t = [string]$item.title
    if ([string]::IsNullOrWhiteSpace($t)) { continue }

    $t = $t -replace '\?\?','' -replace '\s+',' '
    $t = $t.Trim()

    if ($t -match '(?i)how to|scam|charged|donation|eviction|shutters|closure|celebrates|uncertain|obituary|lawsuit|arrested|crime|warning|best |tips |guide|review of|predictions|forecast') {
        continue
    }

    $idea = $null
    $category = $null

    if ($t -match '(?i)pressure washer') {
        $idea = "Location de nettoyeurs haute pression aux particuliers"
        $category = "RENTAL"
    }
    elseif ($t -match '(?i)tool rental') {
        $idea = "Location d'outils de bricolage aux particuliers"
        $category = "RENTAL"
    }
    elseif ($t -match '(?i)equipment rental') {
        $idea = "Location de matériel professionnel aux artisans"
        $category = "RENTAL"
    }
    elseif ($t -match '(?i)car rental|vehicle rental') {
        $idea = "Location de véhicules de proximité"
        $category = "RENTAL"
    }
    elseif ($t -match '(?i)food truck rental') {
        $idea = "Location de food-trucks pour événements"
        $category = "RENTAL"
    }
    elseif ($t -match '(?i)party rental|event rental') {
        $idea = "Location de matériel pour fêtes et événements"
        $category = "RENTAL"
    }
    elseif ($t -match '(?i)tent rental') {
        $idea = "Location de tentes pour événements"
        $category = "RENTAL"
    }
    elseif ($t -match '(?i)camera rental') {
        $idea = "Location de matériel vidéo aux créateurs"
        $category = "RENTAL"
    }
    elseif ($t -match '(?i)local marketplace') {
        $idea = "Marketplace locale pour petits commerçants"
        $category = "MARKETPLACE"
    }
    elseif ($t -match '(?i)food marketplace') {
        $idea = "Marketplace locale de produits alimentaires"
        $category = "MARKETPLACE"
    }
    elseif ($t -match '(?i)service marketplace') {
        $idea = "Marketplace locale de services à domicile"
        $category = "MARKETPLACE"
    }
    elseif ($t -match '(?i)rental marketplace') {
        $idea = "Marketplace locale de location entre particuliers"
        $category = "MARKETPLACE"
    }
    elseif ($t -match '(?i)cleaning service|cleaning startup|house cleaning') {
        $idea = "Service de ménage à domicile réservé en ligne"
        $category = "HOME_SERVICES"
    }
    elseif ($t -match '(?i)furniture assembly') {
        $idea = "Montage de meubles à domicile sur réservation"
        $category = "HOME_SERVICES"
    }
    elseif ($t -match '(?i)handyman|home repair') {
        $idea = "Service de petites réparations à domicile"
        $category = "HOME_SERVICES"
    }
    elseif ($t -match '(?i)mobile repair') {
        $idea = "Service de réparation mobile à domicile"
        $category = "HOME_SERVICES"
    }
    elseif ($t -match '(?i)dog walking|dog walker') {
        $idea = "Promenade de chiens réservée en ligne"
        $category = "PETS"
    }
    elseif ($t -match '(?i)pet sitting|pet care') {
        $idea = "Garde de chiens et chats à domicile"
        $category = "PETS"
    }
    elseif ($t -match '(?i)pet transportation|pet taxi') {
        $idea = "Transport d'animaux vers vétérinaires"
        $category = "PETS"
    }
    elseif ($t -match '(?i)local delivery|same.day delivery') {
        $idea = "Service de livraison locale pour commerces"
        $category = "DELIVERY"
    }
    elseif ($t -match '(?i)grocery delivery') {
        $idea = "Livraison de courses locales"
        $category = "DELIVERY"
    }
    elseif ($t -match '(?i)restaurant delivery') {
        $idea = "Service de livraison pour restaurants indépendants"
        $category = "DELIVERY"
    }
    elseif ($t -match '(?i)SaaS|software platform') {
        $idea = "Logiciel spécialisé pour une tâche métier précise"
        $category = "SOFTWARE"
    }
    elseif ($t -match '(?i)AI platform|AI startup') {
        $idea = "Service IA spécialisé pour un métier de niche"
        $category = "AI"
    }
    elseif ($t -match '(?i)subscription service|subscription business') {
        $idea = "Service spécialisé vendu par abonnement mensuel"
        $category = "SUBSCRIPTION"
    }

    if ($null -eq $idea) { continue }

    $ideas += [PSCustomObject]@{
        business_name = $idea
        category = $category
        source_title = $t
        source_url = $item.url
        original_score = $item.opportunity_score
    }
}

$final = @(
    $ideas |
    Group-Object business_name |
    ForEach-Object {
        $items = @($_.Group)

        [PSCustomObject]@{
            business_name = $_.Name
            category = $items[0].category
            source_count = $items.Count
            best_source_score = ($items.original_score | Measure-Object -Maximum).Maximum
            average_source_score = [math]::Round((($items.original_score | Measure-Object -Average).Average),1)
            sources = @($items | Select-Object source_title,source_url,original_score)
        }
    }
) | Sort-Object source_count -Descending

$final |
    ConvertTo-Json -Depth 7 |
    Set-Content ".\radar38_business_library.json" -Encoding UTF8

Write-Host ""
Write-Host "RAW SIGNALS      :" @($x).Count
Write-Host "EXTRACTED SIGNALS:" @($ideas).Count
Write-Host "UNIQUE BUSINESSES:" @($final).Count
Write-Host ""

$final |
    Select-Object -First 30 business_name,source_count,best_source_score |
    Format-Table -Wrap -AutoSize
