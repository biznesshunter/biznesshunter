$x = Get-Content .\radar8_models.json -Raw | ConvertFrom-Json
$o = @()

$patterns = @(
    @{p='pressure washer|power washer'; n='Location de nettoyeurs haute pression'},
    @{p='tool rental|rent tools|tool hire'; n='Location d outils de bricolage'},
    @{p='equipment rental|equipment hire'; n='Location de matériel professionnel'},
    @{p='party equipment|event equipment|party rental'; n='Location de matériel pour événements'},
    @{p='tent rental|tent hire'; n='Location de tentes'},
    @{p='food truck rental|food-truck rental'; n='Location de food-trucks'},
    @{p='trailer rental|trailer hire'; n='Location de remorques'},
    @{p='car rental|vehicle rental|van rental'; n='Location de véhicules de proximité'},
    @{p='dog walking|dog walker'; n='Promenade de chiens à domicile'},
    @{p='pet sitting|pet sitter|dog sitting|cat sitting'; n='Garde de chiens et chats à domicile'},
    @{p='mobile phone repair|phone repair|smartphone repair'; n='Réparation de smartphones à domicile'},
    @{p='mobile car wash|car wash at home|mobile detailing'; n='Lavage automobile à domicile'},
    @{p='bin cleaning|wheelie bin cleaning'; n='Nettoyage de poubelles à domicile'},
    @{p='house cleaning|home cleaning|cleaning service'; n='Ménage à domicile réservé en ligne'},
    @{p='grocery delivery|food delivery'; n='Livraison de courses à domicile'},
    @{p='local delivery|last mile delivery'; n='Livraison locale pour commerces'},
    @{p='laundry pickup|laundry delivery'; n='Collecte et livraison de linge'},
    @{p='mattress cleaning|sofa cleaning|carpet cleaning'; n='Nettoyage de matelas, canapés et tapis à domicile'},
    @{p='pool cleaning|pool maintenance'; n='Entretien de piscines à domicile'},
    @{p='lawn care|garden maintenance|yard maintenance'; n='Entretien de jardins à domicile'},
    @{p='pressure washing|power washing'; n='Nettoyage haute pression à domicile'},
    @{p='mobile mechanic|mechanic at home'; n='Mécanique automobile à domicile'},
    @{p='mobile bike repair|bike repair at home'; n='Réparation de vélos à domicile'},
    @{p='mobile pet grooming|pet grooming at home'; n='Toilettage d animaux à domicile'},
    @{p='mobile barber|barber at home'; n='Coiffure à domicile sur réservation'},
    @{p='meal prep subscription|meal delivery subscription'; n='Abonnement de repas préparés livrés'},
    @{p='subscription maintenance|maintenance subscription'; n='Abonnement de maintenance domestique'},
    @{p='AI for dentists|AI for lawyers|AI for accountants|AI for real estate'; n='Service IA spécialisé pour une profession précise'},
    @{p='rental marketplace|equipment marketplace'; n='Marketplace de location de matériel'},
    @{p='local marketplace for small businesses|local marketplace for vendors'; n='Marketplace locale pour petits commerçants'}
)

foreach ($i in @($x)) {
    $title = [string]$i.title
    if ([string]::IsNullOrWhiteSpace($title)) { continue }

    foreach ($z in $patterns) {
        if ($title -match $z.p) {
            $o += [PSCustomObject]@{
                idea_name = $z.n
                source_title = $title
                source_url = [string]$i.url
                opportunity_score = [int]$i.opportunity_score
                transferability = [int]$i.transferability
                simplicity = [int]$i.simplicity
                demand_proof = [int]$i.demand_proof
                source_score = [int]$i.opportunity_score
            }
        }
    }
}

$g = $o |
    Group-Object idea_name |
    ForEach-Object {
        $best = $_.Group | Sort-Object source_score -Descending | Select-Object -First 1
        [PSCustomObject]@{
            idea_name = $_.Name
            source_count = $_.Count
            best_score = $best.source_score
            transferability = $best.transferability
            simplicity = $best.simplicity
            demand_proof = $best.demand_proof
            example_source = $best.source_title
            example_url = $best.source_url
        }
    }

$g = $g |
    Where-Object { $_.source_count -ge 1 } |
    Sort-Object @{Expression='best_score';Descending=$true}, @{Expression='source_count';Descending=$true}

$g | ConvertTo-Json -Depth 5 |
    Set-Content .\radar40_business_library.json -Encoding UTF8

Write-Host ""
Write-Host "RAW SIGNALS :" @($x).Count
Write-Host "CONCRETE IDEAS :" @($g).Count
Write-Host "OUTPUT : radar40_business_library.json"
Write-Host ""

$g | Format-Table idea_name,source_count,best_score,transferability,simplicity -AutoSize
