$queue = ConvertFrom-Json (Get-Content .\radar44_city_search_queue.json -Raw)

$registry = ConvertFrom-Json (Get-Content .\radar49_source_registry.json -Raw)

function Get-Category($idea) {

    if ($idea -match "shampouineuse") { return "location_shampouineuse" }
    if ($idea -match "nettoyeur vapeur") { return "location_nettoyeur_vapeur" }
    if ($idea -match "remorque") { return "location_remorque" }
    if ($idea -match "nettoyeur.*haute pression") { return "location_nettoyeur_haute_pression" }
    if ($idea -match "débroussailleuse") { return "location_debroussailleuse" }
    if ($idea -match "scarificateur") { return "location_scarificateur" }
    if ($idea -match "taille-haie") { return "location_taille_haie" }
    if ($idea -match "fendeuse") { return "location_fendeuse_bois" }
    if ($idea -match "tente") { return "location_tente_reception" }
    if ($idea -match "gardiens.*chats|garde.*chat") { return "garde_chat" }
    if ($idea -match "ménage.*sortie|sortie.*location") { return "menage_sortie_location" }
    if ($idea -match "promeneurs.*chiens|promenade.*chien") { return "promenade_chien" }

    return $null
}

$output = New-Object System.Collections.Generic.List[object]

foreach ($item in $queue) {

    $category = Get-Category $item.idea_name

    if ([string]::IsNullOrWhiteSpace($category)) {
        continue
    }

    $entry = $null

    foreach ($r in $registry) {
        if ($r.category -eq $category) {
            $entry = $r
            break
        }
    }

    if ($null -eq $entry) {
        continue
    }

    foreach ($source in $entry.sources) {

        $output.Add([PSCustomObject]@{
            idea_name = [string]$item.idea_name
            country   = [string]$item.country
            city      = [string]$item.city
            category  = [string]$category
            source    = [string]$source
        })
    }
}

$output |
    ConvertTo-Json -Depth 10 |
    Set-Content .\radar50_source_queue.json -Encoding UTF8

Write-Host ""
Write-Host "CITY QUEUE   :" @($queue).Count
Write-Host "SOURCE QUEUE :" $output.Count
Write-Host "OUTPUT       : radar50_source_queue.json"
Write-Host ""

$output |
    Select-Object -First 10 idea_name,country,city,category,source |
    Format-Table -AutoSize
