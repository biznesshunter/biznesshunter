$x = Get-Content ".\radar8_models.json" -Raw | ConvertFrom-Json

$library = @()

foreach ($item in @($x)) {

    $title = [string]$item.title
    if ([string]::IsNullOrWhiteSpace($title)) { continue }

    $clean = $title -replace '\?\?','' -replace '\s+',' '
    $clean = $clean.Trim()

    $idea = $null

    if ($clean -match '(?i)pressure washer|pressure washing') {
        $idea = "Location de nettoyeurs haute pression aux particuliers"
    }
    elseif ($clean -match '(?i)tool rental|equipment rental') {
        $idea = "Location de matériel et outils aux particuliers et artisans"
    }
    elseif ($clean -match '(?i)food truck rental') {
        $idea = "Location de food-trucks aux entrepreneurs"
    }
    elseif ($clean -match '(?i)local marketplace') {
        $idea = "Marketplace locale pour petits commerçants"
    }
    elseif ($clean -match '(?i)delivery') {
        $idea = "Service de livraison locale pour commerces indépendants"
    }

    if ($null -eq $idea) { continue }

    $library += [PSCustomObject]@{
        business_name = $idea
        source_title = $clean
        source_url = $item.url
        score = $item.opportunity_score
        business_model = $item.business_model
    }
}

$groups = $library | Group-Object business_name

$final = foreach ($group in $groups) {

    $items = @($group.Group)

    [PSCustomObject]@{
        business_name = $group.Name
        source_count = $items.Count
        best_score = ($items.score | Measure-Object -Maximum).Maximum
        sources = @(
            $items | ForEach-Object {
                [PSCustomObject]@{
                    title = $_.source_title
                    url = $_.source_url
                }
            }
        )
    }
}

$final |
    Sort-Object best_score -Descending |
    ConvertTo-Json -Depth 6 |
    Set-Content ".\radar37_business_library.json" -Encoding UTF8

Write-Host ""
Write-Host "Source signals :" @($x).Count
Write-Host "Concrete ideas :" @($final).Count
Write-Host "Output         : radar37_business_library.json"
