$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "======================================"
Write-Host " BUSINESS VALIDATION V19"
Write-Host " STRICT RELEVANCE + BING"
Write-Host "======================================"
Write-Host ""

$inputFile = ".\validation_queue.json"
$outputFile = ".\validation_results_v19.json"

if (-not (Test-Path $inputFile)) {
    Write-Host "ERROR: $inputFile introuvable." -ForegroundColor Red
    exit 1
}

$items = Get-Content $inputFile -Raw | ConvertFrom-Json
$data = @()

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
        Write-Host "  ! REQUEST FAILED" -ForegroundColor Red
        return $null
    }
}

function Decode-BingUrl {
    param([string]$Url)

    try {
        if ($Url -notmatch '[?&]u=([^&]+)') {
            return $Url
        }

        $encoded = [System.Net.WebUtility]::HtmlDecode($Matches[1])
        $encoded = $encoded -replace '-', '+'
        $encoded = $encoded -replace '_', '/'

        while (($encoded.Length % 4) -ne 0) {
            $encoded += "="
        }

        $bytes = [Convert]::FromBase64String($encoded)
        $decoded = [System.Text.Encoding]::UTF8.GetString($bytes)

        if ($decoded.StartsWith("a1")) {
            $decoded = $decoded.Substring(2)
        }

        if ($decoded -match '^https?://') {
            return $decoded
        }

        return $Url
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

    $pattern = '<h2[^>]*>[\s\S]*?<a[^>]+href="([^"]+)"[^>]*>([\s\S]*?)</a>[\s\S]*?</h2>'

    $matches = [regex]::Matches(
        $Html,
        $pattern,
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )

    foreach ($m in $matches) {

        $rawUrl = [System.Net.WebUtility]::HtmlDecode($m.Groups[1].Value)
        $url = Decode-BingUrl $rawUrl
        $title = Strip-Html $m.Groups[2].Value

        if (
            $url -and
            $title.Length -gt 2 -and
            $url -match '^https?://' -and
            $url -notmatch '^https?://www\.bing\.com/'
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

function Normalize-Name {
    param([string]$Text)

    if (-not $Text) {
        return ""
    }

    $Text = $Text.ToLower()
    $Text = $Text -replace '[^a-z0-9]+', ' '
    $Text = $Text -replace '\s+', ' '

    return $Text.Trim()
}

function Get-RelevanceScore {
    param(
        [string]$Business,
        [string]$Title,
        [string]$Url
    )

    $businessNorm = Normalize-Name $Business
    $titleNorm = Normalize-Name $Title

    $businessWords = @(
        $businessNorm.Split(" ") |
        Where-Object {
            $_.Length -ge 3 -and
            $_ -notmatch '^(the|and|for|with|app|www|com|io|ai)$'
        }
    )

    if ($businessWords.Count -eq 0) {
        return 0
    }

    $matched = 0

    foreach ($word in $businessWords) {
        if ($titleNorm -match "(^|\s)$([regex]::Escape($word))(\s|$)") {
            $matched++
        }
    }

    $ratio = $matched / $businessWords.Count

    if ($businessWords.Count -ge 2 -and $ratio -lt 0.50) {
        return 0
    }

    if ($businessWords.Count -eq 1 -and $matched -eq 0) {
        return 0
    }

    if ($titleNorm -like "*$businessNorm*") {
        return 10
    }

    if ($ratio -ge 0.80) {
        return 9
    }

    if ($ratio -ge 0.50) {
        return 6
    }

    return 0
}

function Is-CommercialEvidence {
    param(
        [string]$Title,
        [string]$Query
    )

    $text = "$Title $Query"

    return (
        $text -match `
        "revenue|MRR|ARR|customers|customer|users|user|pricing|price|paid|sales|income|profit|subscription|monthly recurring|annual recurring|funding|raised|million|thousand|paying"
    )
}

foreach ($item in $items) {

    $business = [string]$item.business_name_clean
    $identity = [string]$item.name

    if (-not $business) {
        $business = $identity
    }

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
        $found = Extract-BingResults -Html $html -Query $query

        foreach ($r in $found) {

            $score = Get-RelevanceScore `
                -Business $business `
                -Title $r.title `
                -Url $r.url

            $r | Add-Member `
                -NotePropertyName "relevance_score" `
                -NotePropertyValue $score `
                -Force

            if ($score -ge 6) {

                $r | Add-Member `
                    -NotePropertyName "classification" `
                    -NotePropertyValue "RELEVANT" `
                    -Force

                $evidence += $r

                Write-Host "  + RELEVANT [$score/10] $($r.title)" -ForegroundColor Green
            }
            else {

                Write-Host "  - REJECTED [$score/10] $($r.title)" -ForegroundColor DarkGray
            }
        }
    }

    $uniqueEvidence = @(
        $evidence |
        Where-Object { $_.url } |
        Group-Object url |
        ForEach-Object { $_.Group[0] }
    )

    $commercialEvidence = @(
        $uniqueEvidence |
        Where-Object {
            Is-CommercialEvidence -Title $_.title -Query $_.query
        }
    )

    $strongEvidence = @(
        $uniqueEvidence |
        Where-Object {
            $_.title -match `
            "revenue|MRR|ARR|paying customers|paid users|monthly recurring|annual recurring|sales|profit"
        }
    )

    $totalResults = $uniqueEvidence.Count
    $commercialCount = $commercialEvidence.Count
    $strongCount = $strongEvidence.Count

    if ($totalResults -eq 0) {
        $searchHealth = "INSUFFICIENT_DATA"
    }
    else {
        $searchHealth = "VALID_DATA"
    }

    if ($strongCount -ge 3 -and $searchHealth -eq "VALID_DATA") {
        $validationStatus = "VALIDATED"
        $proofLevel = "STRONG"
    }
    elseif ($commercialCount -ge 2 -and $searchHealth -eq "VALID_DATA") {
        $validationStatus = "PARTIAL"
        $proofLevel = "MONETIZED"
    }
    elseif ($commercialCount -ge 1 -and $searchHealth -eq "VALID_DATA") {
        $validationStatus = "PARTIAL"
        $proofLevel = "WEAK"
    }
    else {
        $validationStatus = "UNVALIDATED"
        $proofLevel = "NONE"
    }

    $validationSafe = (
        $searchHealth -eq "VALID_DATA" -and
        $totalResults -ge 1
    )

    $qualityLevel = "LOW"

    if ($totalResults -ge 3) {
        $qualityLevel = "MEDIUM"
    }

    if ($totalResults -ge 6) {
        $qualityLevel = "HIGH"
    }

    $item | Add-Member -NotePropertyName "validation_version" -NotePropertyValue "V19" -Force
    $item | Add-Member -NotePropertyName "validation_status" -NotePropertyValue $validationStatus -Force
    $item | Add-Member -NotePropertyName "commercial_proof_level" -NotePropertyValue $proofLevel -Force
    $item | Add-Member -NotePropertyName "search_health" -NotePropertyValue $searchHealth -Force
    $item | Add-Member -NotePropertyName "validation_safe" -NotePropertyValue $validationSafe -Force
    $item | Add-Member -NotePropertyName "data_quality_level" -NotePropertyValue $qualityLevel -Force
    $item | Add-Member -NotePropertyName "external_evidence_count" -NotePropertyValue $totalResults -Force
    $item | Add-Member -NotePropertyName "commercial_evidence_count" -NotePropertyValue $commercialCount -Force
    $item | Add-Member -NotePropertyName "strong_evidence_count" -NotePropertyValue $strongCount -Force
    $item | Add-Member -NotePropertyName "external_evidence" -NotePropertyValue @($uniqueEvidence) -Force

    $data += $item

    Write-Host ""
    Write-Host "RESULTS ACCEPTED : $totalResults"
    Write-Host "COMMERCIAL       : $commercialCount"
    Write-Host "STRONG           : $strongCount"
    Write-Host "QUALITY          : $qualityLevel"
    Write-Host "SEARCH HEALTH    : $searchHealth"
    Write-Host "STATUS           : $validationStatus"
    Write-Host "SAFE             : $validationSafe"
}

$data |
    ConvertTo-Json -Depth 30 |
    Set-Content $outputFile -Encoding UTF8

$validData = @($data | Where-Object { $_.search_health -eq "VALID_DATA" }).Count
$insufficient = @($data | Where-Object { $_.search_health -eq "INSUFFICIENT_DATA" }).Count
$validated = @($data | Where-Object { $_.validation_status -eq "VALIDATED" }).Count
$partial = @($data | Where-Object { $_.validation_status -eq "PARTIAL" }).Count
$unvalidated = @($data | Where-Object { $_.validation_status -eq "UNVALIDATED" }).Count

Write-Host ""
Write-Host "======================================"
Write-Host " V19 COMPLETE"
Write-Host "======================================"
Write-Host ""
Write-Host "VALID DATA       : $validData"
Write-Host "INSUFFICIENT     : $insufficient"
Write-Host "VALIDATED        : $validated"
Write-Host "PARTIAL          : $partial"
Write-Host "UNVALIDATED      : $unvalidated"
Write-Host ""
Write-Host "Output: $outputFile" -ForegroundColor Yellow
Write-Host ""

