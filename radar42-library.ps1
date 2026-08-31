$x = Get-Content .\radar41_ranked_businesses.json -Raw | ConvertFrom-Json

$ideas = @(
    @{
        idea_name="Marketplace de location de nettoyeurs haute pression entre particuliers"
        source_model="Marketplace de location de matériel"
        customer="Particuliers propriétaires"
        offer="Mise en relation locale pour louer un nettoyeur haute pression inutilisé"
        transaction="Location à la journée"
        test_cost=50
        automation=85
        solo=80
        passivity=80
        b2c=95
        monthly_potential=80
        proof=70
    },
    @{
        idea_name="Marketplace de location de débroussailleuses entre particuliers"
        source_model="Marketplace de location de matériel"
        customer="Particuliers avec jardin"
        offer="Location locale de débroussailleuses appartenant à des particuliers"
        transaction="Location à la journée ou au week-end"
        test_cost=50
        automation=85
        solo=80
        passivity=80
        b2c=95
        monthly_potential=80
        proof=70
    },
    @{
        idea_name="Marketplace de location de scarificateurs entre particuliers"
        source_model="Marketplace de location de matériel"
        customer="Particuliers avec pelouse"
        offer="Location locale de scarificateurs inutilisés"
        transaction="Location saisonnière à la journée"
        test_cost=50
        automation=85
        solo=85
        passivity=85
        b2c=95
        monthly_potential=70
        proof=65
    },
    @{
        idea_name="Marketplace de location de shampouineuses pour canapés entre particuliers"
        source_model="Marketplace de location de matériel"
        customer="Particuliers"
        offer="Location locale de shampouineuses détenues par des particuliers"
        transaction="Location à la journée"
        test_cost=50
        automation=90
        solo=85
        passivity=85
        b2c=95
        monthly_potential=85
        proof=75
    },
    @{
        idea_name="Marketplace de location de fendeuses à bois entre particuliers"
        source_model="Marketplace de location de matériel"
        customer="Propriétaires utilisant du bois de chauffage"
        offer="Location locale de fendeuses à bois"
        transaction="Location à la journée ou au week-end"
        test_cost=50
        automation=80
        solo=80
        passivity=80
        b2c=90
        monthly_potential=75
        proof=65
    },
    @{
        idea_name="Marketplace de location de nettoyeurs vapeur entre particuliers"
        source_model="Marketplace de location de matériel"
        customer="Particuliers"
        offer="Location locale de nettoyeurs vapeur"
        transaction="Location courte durée"
        test_cost=50
        automation=90
        solo=85
        passivity=85
        b2c=95
        monthly_potential=80
        proof=70
    },
    @{
        idea_name="Réservation en ligne de promeneurs de chiens indépendants dans une ville"
        source_model="Promenade de chiens à domicile"
        customer="Propriétaires de chiens"
        offer="Réservation automatisée de promenades auprès de promeneurs indépendants"
        transaction="Commission sur chaque promenade"
        test_cost=50
        automation=80
        solo=70
        passivity=45
        b2c=95
        monthly_potential=75
        proof=80
    },
    @{
        idea_name="Réservation en ligne de gardiens de chats à domicile pendant les vacances"
        source_model="Garde de chiens et chats à domicile"
        customer="Propriétaires de chats"
        offer="Réservation de visites à domicile pendant les absences"
        transaction="Commission sur chaque réservation"
        test_cost=50
        automation=80
        solo=75
        passivity=50
        b2c=95
        monthly_potential=85
        proof=85
    },
    @{
        idea_name="Réservation en ligne de ménage de sortie de location"
        source_model="Ménage à domicile réservé en ligne"
        customer="Locataires et propriétaires"
        offer="Réservation instantanée d'un ménage de fin de location"
        transaction="Commission par intervention"
        test_cost=75
        automation=75
        solo=65
        passivity=35
        b2c=95
        monthly_potential=85
        proof=85
    },
    @{
        idea_name="Marketplace de location de taille-haies entre particuliers"
        source_model="Location d'outils de bricolage"
        customer="Particuliers avec jardin"
        offer="Location locale de taille-haies"
        transaction="Location à la journée"
        test_cost=50
        automation=85
        solo=80
        passivity=80
        b2c=95
        monthly_potential=75
        proof=65
    },
    @{
        idea_name="Marketplace de location de remorques pour particuliers sans remorque"
        source_model="Location de remorques"
        customer="Particuliers"
        offer="Réservation locale de remorques appartenant à des particuliers"
        transaction="Location à la journée ou au week-end"
        test_cost=50
        automation=85
        solo=80
        passivity=80
        b2c=95
        monthly_potential=85
        proof=80
    },
    @{
        idea_name="Marketplace de location de tentes de réception entre particuliers"
        source_model="Location de tentes"
        customer="Particuliers organisant des événements"
        offer="Location locale de tentes de réception inutilisées"
        transaction="Location au week-end"
        test_cost=50
        automation=80
        solo=75
        passivity=75
        b2c=90
        monthly_potential=70
        proof=65
    }
)

$o = foreach ($i in $ideas) {

    $score = [math]::Round(
        ($i.test_cost * 0.10) +
        ($i.automation * 0.20) +
        ($i.solo * 0.15) +
        ($i.passivity * 0.20) +
        ($i.b2c * 0.10) +
        ($i.monthly_potential * 0.15) +
        ($i.proof * 0.10)
    )

    $verdict =
        if ($score -ge 80) {"STRONG"}
        elseif ($score -ge 70) {"VALIDATE"}
        elseif ($score -ge 60) {"WATCH"}
        else {"REJECT"}

    [PSCustomObject]@{
        idea_name=$i.idea_name
        source_model=$i.source_model
        customer=$i.customer
        offer=$i.offer
        transaction=$i.transaction
        score=$score
        test_cost=$i.test_cost
        automation=$i.automation
        solo=$i.solo
        passivity=$i.passivity
        b2c=$i.b2c
        monthly_potential=$i.monthly_potential
        proof=$i.proof
        verdict=$verdict
    }
}

$o = $o | Sort-Object score -Descending

$n=1
$o | ForEach-Object {
    $_ | Add-Member -NotePropertyName rank -NotePropertyValue $n -Force
    $n++
}

$o | Select-Object rank,idea_name,score,verdict,test_cost,automation,solo,passivity,monthly_potential,proof,customer,transaction |
    ConvertTo-Json -Depth 6 |
    Set-Content .\radar42_concrete_businesses.json -Encoding UTF8

Write-Host ""
Write-Host "CONCRETE BUSINESSES :" @($o).Count
Write-Host ""

$o | Format-Table rank,idea_name,score,verdict,test_cost,automation,solo,passivity,monthly_potential -AutoSize
