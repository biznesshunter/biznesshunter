$items = Get-Content .\pages_full.json -Raw | ConvertFrom-Json

$results = @()

foreach ($item in $items) {

    $text = $item.content

    $evidence = @()

    # REVENUE / MRR / ARR
    $patterns = @(
        '(?i)(\$[\d,.]+[KMB]?\s*(?:MRR|ARR|revenue|monthly revenue|annual revenue))',
        '(?i)((?:revenue|sales|turnover)[^.\n]{0,80}\$[\d,.]+[KMB]?)',
        '(?i)(\$[\d,.]+[KMB]?\s+(?:in revenue|revenue))'
    )

    foreach ($pattern in $patterns) {
        $matches = [regex]::Matches($text, $pattern)

        foreach ($match in $matches) {
            $value = $match.Value.Trim()

            $evidence += [PSCustomObject]@{
                type = "revenue"
                value = $value
                source = $item.url
                quality = 5
            }
        }
    }

    # CUSTOMERS / USERS
    $patterns = @(
        '(?i)([\d,.]+[KMB]?\+?\s+(?:customers|users|clients|members))',
        '(?i)((?:serving|served|used by)\s+[\d,.]+[KMB]?\+?)'
    )

    foreach ($pattern in $patterns) {
        $matches = [regex]::Matches($text, $pattern)

        foreach ($match in $matches) {
            $value = $match.Value.Trim()

            $evidence += [PSCustomObject]@{
                type = "customers"
                value = $value
                source = $item.url
                quality = 5
            }
        }
    }

    # FUNDING
    $patterns = @(
        '(?i)(raised\s+\$[\d,.]+[KMB]?)',
        '(?i)(funding\s+(?:of|round)?\s*\$[\d,.]+[KMB]?)',
        '(?i)(\$\d[\d,.]*[KMB]?\s+(?:seed|series [A-Z]|funding))'
    )

    foreach ($pattern in $patterns) {
        $matches = [regex]::Matches($text, $pattern)

        foreach ($match in $matches) {
            $value = $match.Value.Trim()

            $evidence += [PSCustomObject]@{
                type = "funding"
                value = $value
                source = $item.url
                quality = 5
            }
        }
    }

    # GROWTH
    $patterns = @(
        '(?i)([\d,.]+%\s+(?:growth|increase))',
        '(?i)((?:grew|grown|growing)\s+[\d,.]+%)',
        '(?i)([\d,.]+%\s+(?:YoY|year-over-year))'
    )

    foreach ($pattern in $patterns) {
        $matches = [regex]::Matches($text, $pattern)

        foreach ($match in $matches) {
            $value = $match.Value.Trim()

            $evidence += [PSCustomObject]@{
                type = "growth"
                value = $value
                source = $item.url
                quality = 5
            }
        }
    }

    # TEAM
    $patterns = @(
        '(?i)(team\s+of\s+\d+)',
        '(?i)(\d+\+?\s+(?:employees|people|team members))'
    )

    foreach ($pattern in $patterns) {
        $matches = [regex]::Matches($text, $pattern)

        foreach ($match in $matches) {
            $value = $match.Value.Trim()

            $evidence += [PSCustomObject]@{
                type = "team"
                value = $value
                source = $item.url
                quality = 3
            }
        }
    }

    # Déduplication
    $evidence = $evidence |
        Sort-Object type,value -Unique

    # Score plafonné à 30
    $proof = ($evidence | Measure-Object -Property quality -Sum).Sum

    if (-not $proof) {
        $proof = 0
    }

    $proof = [Math]::Min($proof,30)

    $results += [PSCustomObject]@{
        name = $item.name
        url = $item.url
        proof = $proof
        evidence_count = @($evidence).Count
        evidence = @($evidence)
    }
}

$results |
    ConvertTo-Json -Depth 8 |
    Set-Content -Encoding UTF8 evidence-v3.json

$results |
    Select-Object name,proof,evidence_count |
    Format-Table -AutoSize

Write-Host ""
Write-Host "Evidence Engine V3 terminé."
Write-Host "Résultats : evidence-v3.json"
