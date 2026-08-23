$ErrorActionPreference = "Stop"

$input = ".\radar3_businesses.json"
$output = ".\radar4_model_gaps.json"

$businesses = Get-Content $input -Raw | ConvertFrom-Json

$countries = @(
    @{code="FR"; name="France"; lang="fr-FR"; gl="FR"; queries=@(
        "location vélo électrique",
        "location vélo électrique abonnement",
        "vélos électriques libre service",
        "service réparation automobile à domicile",
        "location matériel professionnel",
        "livraison courses rapide",
        "livraison courses 15 minutes",
        "robots livraison nourriture",
        "marketplace commerçants locaux",
        "service soins animaux"
    )},
    @{code="ES"; name="Spain"; lang="es-ES"; gl="ES"; queries=@(
        "alquiler bicicleta eléctrica",
        "bicicleta eléctrica alquiler suscripción",
        "bicicletas eléctricas compartidas",
        "reparación coche a domicilio",
        "alquiler maquinaria profesional",
        "entrega supermercado rápida",
        "entrega comida robots",
        "marketplace comercio local",
        "servicio cuidado mascotas"
    )},
    @{code="DE"; name="Germany"; lang="de-DE"; gl="DE"; queries=@(
        "E-Bike Vermietung",
        "E-Bike Sharing",
        "Autoreparatur vor Ort",
        "Gerätevermietung",
        "Lebensmittel Lieferung schnell",
        "Lieferroboter Essen",
        "lokaler Marktplatz",
        "Tierpflege Service"
    )}
)

function Get-Model {
    param([string]$title)

    $t = $title.ToLower()

    if ($t -match "e-bike|ebike|bike rental|bike sharing") {
        return @{
            model="E-bike rental / sharing"
            keywords=@(
                "e-bike rental",
                "e-bike sharing",
                "electric bike rental",
                "bike rental subscription"
            )
        }
    }

    if ($t -match "grocery delivery|15-minute|grocery.*delivery") {
        return @{
            model="Rapid grocery delivery"
            keywords=@(
                "rapid grocery delivery",
                "15 minute grocery delivery",
                "quick grocery delivery",
                "online grocery delivery"
            )
        }
    }

    if ($t -match "vehicle service|vehicle.*repair|car.*repair|repair startup") {
        return @{
            model="Mobile vehicle repair / service"
            keywords=@(
                "mobile car repair",
                "mobile vehicle repair",
                "car repair at home",
                "on demand vehicle repair"
            )
        }
    }

    if ($t -match "equipment rental|rental program") {
        return @{
            model="Equipment rental"
            keywords=@(
                "equipment rental",
                "tool rental",
                "equipment rental service",
                "professional equipment rental"
            )
        }
    }

    if ($t -match "food delivery robots|delivery robots") {
        return @{
            model="Food delivery robots"
            keywords=@(
                "food delivery robots",
                "delivery robot service",
                "robot food delivery"
            )
        }
    }

    if ($t -match "marketplace|local vendors|retail.*marketplace") {
        return @{
            model="Local physical marketplace"
            keywords=@(
                "local marketplace",
                "physical marketplace",
                "marketplace local vendors",
                "vendor marketplace"
            )
        }
    }

    if ($t -match "pet care|pet healthcare|pet.*clinic") {
        return @{
            model="Pet care service"
            keywords=@(
                "pet care service",
                "pet healthcare",
                "pet clinic",
                "pet care startup"
            )
    }
    }

    return @{
        model="Unknown"
        keywords=@($title)
    }
}

$results = @()

foreach ($business in $businesses) {

    $title = [string]$business.business
    $modelInfo = Get-Model $title

    Write-Host ""
    Write-Host "=========================================="
    Write-Host "RADAR 4 : $($modelInfo.model)"
    Write-Host "=========================================="

    $countryResults = @()

    foreach ($country in $countries) {

        $hits = 0
        $examples = @()
        $queriesUsed = @()

        foreach ($keyword in $modelInfo.keywords) {

            $query = "$keyword $($country.name)"
            $queriesUsed += $query

            Write-Host "Recherche : $query"

            $encoded = [uri]::EscapeDataString($query)

            $url = "https://news.google.com/rss/search?q=$encoded&hl=$($country.lang)&gl=$($country.gl)&ceid=$($country.gl):en"

            try {

                [xml]$rss = Invoke-WebRequest `
                    -Uri $url `
                    -UseBasicParsing `
                    -TimeoutSec 15

                $items = @($rss.rss.channel.item)

                $hits += $items.Count

                foreach ($item in ($items | Select-Object -First 3)) {
                    $examples += [string]$item.title
                }

            }
            catch {
            }
        }

        $examples = @(
            $examples |
            Select-Object -Unique |
            Select-Object -First 5
        )

        if ($hits -ge 20) {
            $presence = "STRONG"
        }
        elseif ($hits -ge 8) {
            $presence = "MODERATE"
        }
        elseif ($hits -ge 2) {
            $presence = "WEAK"
        }
        else {
            $presence = "NO SIGNAL"
        }

        Write-Host "$($country.name): $presence ($hits)"

        $countryResults += [PSCustomObject]@{
            country=$country.name
            code=$country.code
            hits=$hits
            presence=$presence
            examples=($examples -join " || ")
        }
    }

    $strong = @($countryResults | Where-Object {$_.presence -eq "STRONG"}).Count
    $moderate = @($countryResults | Where-Object {$_.presence -eq "MODERATE"}).Count
    $weak = @($countryResults | Where-Object {$_.presence -eq "WEAK"}).Count
    $none = @($countryResults | Where-Object {$_.presence -eq "NO SIGNAL"}).Count

    # SCORE DE GAP
    $gap = 0

    # Modèle très présent ailleurs mais faible ici = signal intéressant
    if ($strong -ge 2 -and $none -ge 1) {
        $gap += 40
    }
    elseif ($strong -ge 1 -and $none -ge 1) {
        $gap += 30
    }
    elseif ($moderate -ge 2 -and $none -ge 1) {
        $gap += 20
    }

    # Signal de traction provenant du radar précédent
    $traction = 0
    if ($business.PSObject.Properties.Name -contains "traction") {
        $traction = [int]$business.traction
    }

    if ($traction -ge 20) {
        $gap += 20
    }
    elseif ($traction -ge 10) {
        $gap += 10
    }

    # Réplicabilité
    $replicable = 0
    if ($business.PSObject.Properties.Name -contains "replicable") {
        $replicable = [int]$business.replicable
    }

    if ($replicable -ge 20) {
        $gap += 20
    }
    elseif ($replicable -ge 10) {
        $gap += 10
    }

    $gap = [Math]::Min($gap,100)

    if ($gap -ge 70) {
        $verdict = "HIGH POTENTIAL GAP"
    }
    elseif ($gap -ge 50) {
        $verdict = "PROMISING GAP"
    }
    elseif ($gap -ge 30) {
        $verdict = "WATCH"
    }
    else {
        $verdict = "WEAK"
    }

    $results += [PSCustomObject]@{
        business=$title
        model=$modelInfo.model
        gap_score=$gap
        verdict=$verdict
        strong_markets=$strong
        moderate_markets=$moderate
        weak_markets=$weak
        no_signal_markets=$none
        countries=$countryResults
    }
}

$results = @(
    $results | Sort-Object gap_score -Descending
)

$results |
    ConvertTo-Json -Depth 10 |
    Set-Content -Encoding UTF8 $output

Write-Host ""
Write-Host "=========================================="
Write-Host "BIZNESSHUNTER — RADAR 4"
Write-Host "MODEL / GEOGRAPHIC GAP"
Write-Host "=========================================="
Write-Host ""
Write-Host "Business analysés : $($results.Count)"
Write-Host ""

$results |
    Select-Object business,model,gap_score,verdict,strong_markets,moderate_markets,no_signal_markets |
    Format-Table -AutoSize

Write-Host ""
Write-Host "Résultats : $output"


