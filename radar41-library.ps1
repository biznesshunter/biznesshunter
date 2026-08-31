$x = Get-Content .\radar40_business_library.json -Raw | ConvertFrom-Json

$rules = @{
    "Location de matériel professionnel" = @{capital=20; automation=55; solo=45; passive=60; b2c=20; test=25}
    "Location de food-trucks" = @{capital=5; automation=35; solo=10; passive=25; b2c=70; test=5}
    "Réparation de smartphones à domicile" = @{capital=60; automation=35; solo=55; passive=15; b2c=90; test=40}
    "Location de véhicules de proximité" = @{capital=10; automation=50; solo=20; passive=55; b2c=90; test=5}
    "Entretien de jardins à domicile" = @{capital=55; automation=25; solo=45; passive=15; b2c=90; test=35}
    "Livraison de courses à domicile" = @{capital=45; automation=40; solo=25; passive=10; b2c=90; test=30}
    "Garde de chiens et chats à domicile" = @{capital=85; automation=55; solo=60; passive=25; b2c=90; test=80}
    "Marketplace de location de matériel" = @{capital=80; automation=75; solo=70; passive=75; b2c=90; test=90}
    "Location de matériel pour événements" = @{capital=30; automation=55; solo=40; passive=60; b2c=85; test=25}
    "Location d outils de bricolage" = @{capital=35; automation=60; solo=55; passive=65; b2c=90; test=30}
    "Location de tentes" = @{capital=30; automation=55; solo=40; passive=60; b2c=90; test=25}
    "Location de remorques" = @{capital=20; automation=60; solo=50; passive=70; b2c=90; test=15}
    "Ménage à domicile réservé en ligne" = @{capital=75; automation=55; solo=55; passive=15; b2c=90; test=75}
    "Nettoyage haute pression à domicile" = @{capital=35; automation=35; solo=45; passive=20; b2c=90; test=25}
    "Promenade de chiens à domicile" = @{capital=90; automation=55; solo=70; passive=20; b2c=90; test=90}
}

$o = foreach ($i in @($x)) {
    if (-not $rules.ContainsKey([string]$i.idea_name)) { continue }

    $r = $rules[[string]$i.idea_name]

    $score = [math]::Round(
        ($r.capital * 0.15) +
        ($r.automation * 0.20) +
        ($r.solo * 0.15) +
        ($r.passive * 0.20) +
        ($r.b2c * 0.10) +
        ($r.test * 0.20)
    )

    [PSCustomObject]@{
        rank = 0
        idea_name = [string]$i.idea_name
        score = $score
        source_count = [int]$i.source_count
        market_proof = [int]$i.best_score
        testability = $r.test
        automation = $r.automation
        solo = $r.solo
        passivity = $r.passive
        b2c = $r.b2c
        capital_fit = $r.capital
        verdict = if ($score -ge 70) {"KEEP"} elseif ($score -ge 55) {"WATCH"} else {"REJECT"}
        source = [string]$i.example_source
        url = [string]$i.example_url
    }
}

$o = $o | Sort-Object score -Descending

$n = 1
$o | ForEach-Object {
    $_.rank = $n
    $n++
}

$o | ConvertTo-Json -Depth 5 |
    Set-Content .\radar41_ranked_businesses.json -Encoding UTF8

Write-Host ""
Write-Host "RANKED IDEAS :" @($o).Count
Write-Host ""

$o | Format-Table rank,idea_name,score,market_proof,testability,automation,solo,passivity,verdict -AutoSize
