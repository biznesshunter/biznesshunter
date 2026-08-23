$pages = Get-Content .\pages_test.json -Raw | ConvertFrom-Json

$allResults = @()

foreach ($page in $pages) {

    $text = [string]$page.content_preview

    $evidence = @()

    function Add-Evidence {
        param(
            [string]$Type,
            [string]$Value,
            [int]$Quality,
            [string]$Context
        )

        $script:evidence += [PSCustomObject]@{
            type     = $Type
            value    = $Value
            quality  = $Quality
            context  = $Context
            source   = $page.url
        }
    }

    # --------------------------------------------------
    # REVENUE
    # --------------------------------------------------

    $patterns = @(
        '\$[\d,.]+[KMB]?\s*(MRR|ARR|revenue|in revenue)',
        '[\d,.]+[KMB]?\s*(MRR|ARR|revenue)',
        'revenue.{0,40}\$[\d,.]+[KMB]?',
        '\$[\d,.]+[KMB]?.{0,20}(revenue|MRR|ARR)'
    )

    foreach ($pattern in $patterns) {
        foreach ($match in [regex]::Matches($text, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
            Add-Evidence `
                -Type "Revenue" `
                -Value $match.Value `
                -Quality 5 `
                -Context $match.Value
        }
    }

    # --------------------------------------------------
    # CUSTOMERS / USERS
    # --------------------------------------------------

    $patterns = @(
        '[\d,.]+[KMB]?\+?\s*(customers|clients|users|members)',
        '(customers|clients|users|members).{0,30}[\d,.]+[KMB]?\+?'
    )

    foreach ($pattern in $patterns) {
        foreach ($match in [regex]::Matches($text, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
            Add-Evidence `
                -Type "Customers/Users" `
                -Value $match.Value `
                -Quality 5 `
                -Context $match.Value
        }
    }

    # --------------------------------------------------
    # FUNDING
    # --------------------------------------------------

    $patterns = @(
        'raised\s+\$[\d,.]+[KMB]?',
        'funding\s+(of\s+)?\$[\d,.]+[KMB]?',
        '\$[\d,.]+[KMB]?\s+(in\s+)?funding',
        'investment\s+(of\s+)?\$[\d,.]+[KMB]?'
    )

    foreach ($pattern in $patterns) {
        foreach ($match in [regex]::Matches($text, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
            Add-Evidence `
                -Type "Funding" `
                -Value $match.Value `
                -Quality 5 `
                -Context $match.Value
        }
    }

    # --------------------------------------------------
    # GROWTH
    # --------------------------------------------------

    $patterns = @(
        '[\d,.]+%\s*(growth|increase|increase in revenue)',
        '(grew|grown|growing).{0,40}[\d,.]+%',
        '[\d,.]+%\s*(YoY|year.over.year|month.over.month)',
        '(doubled|tripled|10x|5x|3x|2x)'
    )

    foreach ($pattern in $patterns) {
        foreach ($match in [regex]::Matches($text, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
            Add-Evidence `
                -Type "Growth" `
                -Value $match.Value `
                -Quality 4 `
                -Context $match.Value
        }
    }

    # --------------------------------------------------
    # TEAM
    # --------------------------------------------------

    $patterns = @(
        '[\d,.]+\+?\s*(employees|people|team members|staff)',
        'team of\s+[\d,.]+',
        '[\d,.]+\s*person\s+team'
    )

    foreach ($pattern in $patterns) {
        foreach ($match in [regex]::Matches($text, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
            Add-Evidence `
                -Type "Team" `
                -Value $match.Value `
                -Quality 3 `
                -Context $match.Value
        }
    }

    # --------------------------------------------------
    # PROFITABILITY
    # --------------------------------------------------

    $patterns = @(
        'profitable',
        'profitability',
        'cash.?flow positive',
        'bootstrapped',
        'self.?funded'
    )

    foreach ($pattern in $patterns) {
        foreach ($match in [regex]::Matches($text, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
            Add-Evidence `
                -Type "Profitability" `
                -Value $match.Value `
                -Quality 4 `
                -Context $match.Value
        }
    }

    # --------------------------------------------------
    # OTHER NUMERIC SIGNALS
    # --------------------------------------------------

    $patterns = @(
        '[\d,.]+[KMB]?\+?\s*(downloads|installs)',
        '[\d,.]+[KMB]?\+?\s*(orders|sales)',
        '[\d,.]+[KMB]?\+?\s*(companies|businesses)',
        '[\d,.]+[KMB]?\+?\s*(projects|websites)'
    )

    foreach ($pattern in $patterns) {
        foreach ($match in [regex]::Matches($text, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
            Add-Evidence `
                -Type "Other Traction" `
                -Value $match.Value `
                -Quality 3 `
                -Context $match.Value
        }
    }

    # --------------------------------------------------
    # DEDUPLICATION
    # --------------------------------------------------

    $uniqueEvidence = @(
        $evidence |
        Sort-Object type,value -Unique
    )

    $proof = 0

    foreach ($e in $uniqueEvidence) {
        $proof += $e.quality
    }

    $proof = [Math]::Min($proof, 30)

    $allResults += [PSCustomObject]@{
        name           = $page.name
        url            = $page.url
        proof          = $proof
        evidence_count = $uniqueEvidence.Count
        evidence       = $uniqueEvidence
    }
}

# --------------------------------------------------
# SAVE
# --------------------------------------------------

$allResults |
    ConvertTo-Json -Depth 10 |
    Set-Content -Encoding UTF8 evidence-v2.json

# --------------------------------------------------
# DISPLAY
# --------------------------------------------------

$allResults |
    Select-Object name,proof,evidence_count |
    Format-Table -AutoSize

Write-Host ""
Write-Host "Evidence engine V2 terminé."
Write-Host "Résultats : evidence-v2.json"
