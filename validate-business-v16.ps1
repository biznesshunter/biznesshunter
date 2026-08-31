$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "======================================"
Write-Host " BUSINESS VALIDATION V16"
Write-Host " BING REDIRECT DECODER"
Write-Host "======================================"

$inputFile = ".\validation_queue.json"
$outputFile = ".\validation_results_v16.json"

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
                "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
                "Accept-Language" = "en-US,en;q=0.9"
            }

        return $r.Content
    }
    catch {
        Write-Host "  ! REQUEST FAILED"
        return $null
    }
}

function Decode-BingUrl {
    param([string]$Url)

    try {

        if ($Url -notmatch '[?&]u=([^&]+)') {
            return $Url
        }

        $encoded = $Matches[1]

        # HTML decode
        $encoded = [System.Net.WebUtility]::HtmlDecode($encoded)

        # Bing uses URL-safe Base64
        $encoded = $encoded -replace '-', '+'
        $encoded = $encoded -replace '_', '/'

        while (($encoded.Length % 4) -ne 0) {
            $encoded += "="
        }

        $bytes = [Convert]::FromBase64String($encoded)
        $decoded = [System.Text.Encoding]::UTF8.GetString($bytes)

        # Bing prefixes the encoded destination with a1
        if ($decoded.StartsWith("a1")) {
            $decoded = $decoded.Substring(2)
        }

        # Sometimes the decoded value itself is base64
        if ($decoded -match '^https?://') {
            return $decoded
        }

        try {
            $bytes2 = [Convert]::FromBase64String(
                ($decoded + ("=" * ((4 - ($decoded.Length % 4)) % 4)))
            )

            $decoded2 = [System.Text.Encoding]::UTF8.GetString($bytes2)

            if ($decoded2 -match '^https?://') {
                return $decoded2
            }
        }
        catch {}

        return $decoded
    }
    catch {
        return $Url
    }
}

function Strip-Html {
    param([string]$Text)

    if (-not $Text) {
        return ""
    }

    $Text = $Text -replace '<script[\s\S]*?</script>', ''
    $Text = $Text -replace '<style[\s\S]*?</style>', ''
    $Text = $Text -replace '<[^>]+>', ' '
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

    # Find h2 elements and associated links
    $pattern = '<h2[^>]*>[\s\S]*?<a[^>]+href="([^"]+)"[^>]*>([\s\S]*?)</a>[\s\S]*?</h2>'

    $matches = [regex]::Matches(
        $Html,
        $pattern,
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )

    foreach ($m in $matches) {

        $rawUrl = [System.Net.WebUtility]::HtmlDecode(
            $m.Groups[1].Value
        )

        $url = Decode-BingUrl $rawUrl

        $title = Strip-Html $m.Groups[2].Value

        if ($url -and $title.Length -gt 2 -and $url -notmatch '^https?://www\.bing\.com/' -and $title -notmatch 'pizza|camping|minecraft|tiktok|microsoft|chennai|edupool|skindex|baidu|知乎') {

            $results += [PSCustomObject]@{
                query = $Query
                title = $title
                url = $url
                source_type = "bing"
            }

            Write-Host "  + $title"
            Write-Host "    $url"
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
        validation_version = "V16"
        validation_status = $status
        commercial_proof_level = $proof
        evidence_quality = $quality
        external_evidence_count = $uniqueEvidence.Count
        commercial_evidence_count = $commercialEvidence.Count
        strong_evidence_count = $strongEvidence.Count
        external_evidence = @($uniqueEvidence)
    }

    Write-Host ""
    Write-Host "--------------------------------------"
    Write-Host "STATUS: $status"
    Write-Host "EVIDENCE: $($uniqueEvidence.Count)"
    Write-Host "COMMERCIAL: $($commercialEvidence.Count)"
    Write-Host "STRONG: $($strongEvidence.Count)"
    Write-Host "--------------------------------------"
}

$results |
    ConvertTo-Json -Depth 20 |
    Set-Content $outputFile -Encoding UTF8

Write-Host ""
Write-Host "======================================"
Write-Host " V16 COMPLETE"
Write-Host "======================================"
Write-Host ""
Write-Host "Output: $outputFile"



