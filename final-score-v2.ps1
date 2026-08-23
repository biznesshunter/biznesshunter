$items = Get-Content .\evidence-v4.json -Raw | ConvertFrom-Json

$results = @()

foreach ($item in $items) {

    $text = (
        ($item.name + " " + (($item.evidence | ForEach-Object { $_.value }) -join " "))
    ).ToLower()

    # =========================
    # CAPITAL NÉCESSAIRE /10
    # =========================

    $capital = 10

    if ($text -match "space|satellite|rocket|aircraft|robot|battery|factory|manufacturing") {
        $capital = 2
    }
    elseif ($text -match "vehicle|hardware|medical|biotech") {
        $capital = 4
    }
    elseif ($text -match "marketplace|platform|network") {
        $capital = 7
    }
    elseif ($text -match "software|saas|tool|app|ai") {
        $capital = 10
    }

    # =========================
    # SOLO /10
    # =========================

    $solo = 10

    if ($text -match "space|satellite|rocket|aircraft|robot|factory|manufacturing") {
        $solo = 2
    }
    elseif ($text -match "vehicle|hardware|medical|biotech") {
        $solo = 4
    }
    elseif ($text -match "marketplace|platform|network") {
        $solo = 6
    }
    elseif ($text -match "service|agency|consulting") {
        $solo = 8
    }

    # =========================
    # COMPLEXITÉ /10
    # =========================

    $complexity = 10

    if ($text -match "space|satellite|rocket|aircraft|robot|factory|manufacturing") {
        $complexity = 2
    }
    elseif ($text -match "vehicle|hardware|medical|biotech") {
        $complexity = 4
    }
    elseif ($text -match "marketplace|platform|network") {
        $complexity = 6
    }
    elseif ($text -match "service|agency|consulting") {
        $complexity = 8
    }

    # =========================
    # BARRIÈRES
    # =========================

    $barrier = 0

    if ($text -match "patent|patented|exclusive|proprietary") {
        $barrier += 3
    }

    if ($text -match "regulation|regulated|license|licence|medical|financial") {
        $barrier += 3
    }

    if ($text -match "network effect|network effects") {
        $barrier += 3
    }

    if ($text -match "manufacturing|factory|supply chain") {
        $barrier += 2
    }

    # =========================
    # COPY OPPORTUNITY /40
    # =========================

    $copy = $capital + $solo + $complexity - $barrier

    $copy = [Math]::Max(0,[Math]::Min($copy,40))

    # =========================
    # SCORE FINAL
    # =========================

    $score = $item.proof + $copy

    $score = [Math]::Min($score,100)

    $results += [PSCustomObject]@{
        name = $item.name
        proof = $item.proof
        capital = $capital
        solo = $solo
        complexity = $complexity
        barriers = $barrier
        copy_opportunity = $copy
        BiznessHunterScore = $score
    }
}

$results =
    $results |
    Sort-Object BiznessHunterScore -Descending

$results |
    ConvertTo-Json -Depth 6 |
    Set-Content -Encoding UTF8 biznesshunter-results-v2.json

$results |
    Format-Table name,proof,capital,solo,complexity,barriers,copy_opportunity,BiznessHunterScore -AutoSize
