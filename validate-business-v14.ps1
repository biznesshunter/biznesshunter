$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "======================================"
Write-Host " BUSINESS VALIDATION V14"
Write-Host " BING REAL WEB EVIDENCE"
Write-Host "======================================"

$inputFile = ".\validation_queue.json"
$outputFile = ".\validation_results_v14.json"

$items = Get-Content $inputFile -Raw | ConvertFrom-Json
$results = @()

function Search-Bing {
    param([string]$Query)

    $encoded = [uri]::EscapeDataString($Query)
    $url = "https://www.bing.com/search?q=$encoded"

    try {
        $r = Invoke-WebRequest `
            -Uri $url `
            -UseBasicParsing `
            -Headers @{
                "User-Agent" = "Mozilla/5.0"
                "Accept-Language" = "en-US,en;q=0.9"
            }

        return $r.Content
    }
    catch {
        Write-Host "  ! REQUEST FAILED"
        return $null
    }
}

function Strip-Html {
    param([string]$Text)

    if (-not $Text) { return "" }

    $Text = $Text -replace '<script.*?</script>', ''
    $Text = $Text -replace '<style.*?</style>', ''
    $Text = $Text -replace '<.*?>', ' '
    $Text = [System.Net.WebUtility]::HtmlDecode($Text)
    $Text = $Text -replace '\s+', ' '

    return $Text.Trim()
}

function Extract-BingResults {
    param(
        [string]$Html,
        [string]$Query
    )

    $results = @()

    if (-not $Html) {
        return $results
    }

    # Find every h2 link
    $pattern = '<h2[^>]*>\s*<a[^>]*href="([^"]+)"[^>]*>(.*?)</a>\s*</h2>'

    $matches = [regex]::Matches(
        $Html,
        $pattern,
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )

    foreach ($m in $matches) {

        $url = [System.Net.WebUtility]::HtmlDecode(
            $m.Groups[1].Value
        )

        $title = Strip-Html $m.Groups[2].Value

        if (
            $url -and
            $title.Length -gt 2 -and
            $url -notmatch "bing.com"
        ) {

            $results += [PSCustomObject]@{
                query = $Query
                title = $title
                url = $url
                source_type = "bing"
            }
        }

        if ($results.Count -ge 5) {
            break
        }
    }

    return $results
}

foreach ($item in $items) {

    $business = [string]$item.business_name_clean
    $identity = [string]$item.name

    Write-Host ""
    Write-Host "======================================"
    Write-Host $business
    Write-Host "======================================"

    $evidence = @()

    $queries = @(
        "`"$business`" revenue",
        "`"$business`" MRR",
        "`"$business`" ARR",
        "`"$business`" customers",
        "`"$business`" users",
        "`"$business`" pricing",
        "`"$business`" paid",
        "`"$business`" Product Hunt",
        "`"$business`" Reddit",
        "`"$business`" Hacker News"
    )

    foreach ($query in $queries) {

        Write-Host ""
        Write-Host "SEARCH: $query"

        $html = Search-Bing $query

        $found = Extract-BingResults `
            -Html $html `
            -Query $query

        foreach ($r in $found) {

            $evidence += $r

            Write-Host "  + $($r.title)"
            Write-Host "    $($r.url)"
        }

        if ($found.Count -eq 0) {
            Write-Host "  - No results extracted"
        }
    }

    $uniqueEvidence = @(
        $evidence |
        Where-Object { $_.url } |
        Group-Object url |
        ForEach-Object { $_.Group[0] }
    )

    $commercialEvidence = @(
        $uniqueEvidence | Where-Object {

            $text = $_.title

            $text -match `
            "revenue|MRR|ARR|customer|user|pricing|paid|sales|income|profit|subscription|monthly|annual|million|thousand"
        }
    )

    $strongEvidence = @(
        $uniqueEvidence | Where-Object {

            $_.title -match `
            "revenue|MRR|ARR|paying customers|paid users|monthly recurring|annual recurring|sales|profit"
        }
    )

    if ($strongEvidence.Count -ge 3) {
        $status = "VALIDATED"
        $proof = "STRONG"
    }
    elseif ($commercialEvidence.Count -ge 2) {
        $status = "PARTIAL"
        $proof = "MONETIZED"
    }
    elseif ($commercialEvidence.Count -ge 1) {
        $status = "PARTIAL"
        $proof = "WEAK"
    }
    else {
        $status = "UNVALIDATED"
        $proof = "NONE"
    }

    $quality = "LOW"

    if ($uniqueEvidence.Count -ge 5) {
        $quality = "MEDIUM"
    }

    if ($uniqueEvidence.Count -ge 10) {
        $quality = "HIGH"
    }

    $results += [PSCustomObject]@{
        name = $identity
        business_name_clean = $business
        validation_version = "V14"
        validation_status = $status
        commercial_proof_level = $proof
        evidence_quality = $quality
        external_evidence_count = $uniqueEvidence.Count
        commercial_evidence_count = $commercialEvidence.Count
        strong_evidence_count = $strongEvidence.Count
        external_evidence = @($uniqueEvidence)
    }

    Write-Host ""
    Write-Host "STATUS: $status"
    Write-Host "EVIDENCE: $($uniqueEvidence.Count)"
    Write-Host "COMMERCIAL: $($commercialEvidence.Count)"
    Write-Host "STRONG: $($strongEvidence.Count)"
}

$results |
    ConvertTo-Json -Depth 20 |
    Set-Content $outputFile -Encoding UTF8

Write-Host ""
Write-Host "======================================"
Write-Host " V14 COMPLETE"
Write-Host "======================================"
Write-Host ""
Write-Host "Output: $outputFile"
