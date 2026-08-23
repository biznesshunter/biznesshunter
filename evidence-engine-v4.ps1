$items = Get-Content .\pages_full.json -Raw | ConvertFrom-Json
$results = @()

foreach ($item in $items) {

    $text = $item.content
    $evidence = @()

    # --- REVENUS ---
    $patterns = @(
        '(?i)\$[\d,.]+\s*[KMB]?\s*(?:MRR|ARR|revenue|sales)',
        '(?i)(?:revenue|sales|turnover)[^.!?]{0,100}\$[\d,.]+\s*[KMB]?',
        '(?i)\$[\d,.]+\s*[KMB]?\s*(?:per month|monthly|annually|per year)'
    )

    foreach ($p in $patterns) {
        foreach ($m in [regex]::Matches($text,$p)) {
            $evidence += [PSCustomObject]@{
                type="revenue"
                value=$m.Value.Trim()
                source=$item.url
                quality=5
            }
        }
    }

    # --- CLIENTS / USERS ---
    $patterns = @(
        '(?i)[\d,.]+\s*[KMB]?\+?\s*(?:customers|users|clients|members)',
        '(?i)(?:customers|users|clients|members)[^.!?]{0,60}[\d,.]+\s*[KMB]?\+?'
    )

    foreach ($p in $patterns) {
        foreach ($m in [regex]::Matches($text,$p)) {
            $evidence += [PSCustomObject]@{
                type="customers"
                value=$m.Value.Trim()
                source=$item.url
                quality=5
            }
        }
    }

    # --- FINANCEMENT ---
    $patterns = @(
        '(?i)raised[^.!?]{0,80}\$[\d,.]+\s*[KMB]?',
        '(?i)funding[^.!?]{0,80}\$[\d,.]+\s*[KMB]?',
        '(?i)\$[\d,.]+\s*[KMB]?\s*(?:funding|round|seed|series)'
    )

    foreach ($p in $patterns) {
        foreach ($m in [regex]::Matches($text,$p)) {
            $evidence += [PSCustomObject]@{
                type="funding"
                value=$m.Value.Trim()
                source=$item.url
                quality=5
            }
        }
    }

    # --- CROISSANCE ---
    $patterns = @(
        '(?i)[\d,.]+\s*%\s*(?:growth|increase|YoY|year-over-year)',
        '(?i)(?:grew|grown|growing)[^.!?]{0,40}[\d,.]+\s*%'
    )

    foreach ($p in $patterns) {
        foreach ($m in [regex]::Matches($text,$p)) {
            $evidence += [PSCustomObject]@{
                type="growth"
                value=$m.Value.Trim()
                source=$item.url
                quality=5
            }
        }
    }

    # --- ÉQUIPE ---
    $patterns = @(
        '(?i)team[^.!?]{0,40}\b\d+\b',
        '(?i)\b\d+\+?\s*(?:employees|people|team members)'
    )

    foreach ($p in $patterns) {
        foreach ($m in [regex]::Matches($text,$p)) {
            $evidence += [PSCustomObject]@{
                type="team"
                value=$m.Value.Trim()
                source=$item.url
                quality=3
            }
        }
    }

    $evidence = @($evidence | Sort-Object type,value -Unique)

    $proof = ($evidence | Measure-Object quality -Sum).Sum
    if (-not $proof) { $proof=0 }
    $proof=[Math]::Min($proof,30)

    $results += [PSCustomObject]@{
        name=$item.name
        url=$item.url
        proof=$proof
        evidence_count=$evidence.Count
        evidence=$evidence
    }
}

$results |
    ConvertTo-Json -Depth 8 |
    Set-Content -Encoding UTF8 evidence-v4.json

$results |
    Select-Object name,proof,evidence_count |
    Format-Table -AutoSize
