$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "======================================"
Write-Host " BUSINESS VALIDATION V18"
Write-Host " BING URL DECODER + DATA QUALITY"
Write-Host "======================================"

$inputFile = ".\validation_queue.json"
$outputFile = ".\validation_results_v18.json"

# --------------------------------------------
# LOAD
# --------------------------------------------

try {
    $items = @(Get-Content $inputFile -Raw | ConvertFrom-Json)
}
catch {
    Write-Host "ERROR: Unable to read validation_queue.json" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

$data = @()

# --------------------------------------------
# SEARCH BING
# --------------------------------------------

function Search-Bing {
    param([string]$Query)

    $encoded = [uri]::EscapeDataString($Query)
    $url = "https://www.bing.com/search?q=$encoded&count=10"

    try {
        $r = Invoke-WebRequest `
            -Uri $url `
            -UseBasicParsing `
            -Headers @{
                "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/151.0.0.0 Safari/537.36"
                "Accept-Language" = "en-US,en;q=0.9"
                "Accept" = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
            } `
            -TimeoutSec 20

        return $r.Content
    }
    catch {
        Write-Host "  ! REQUEST FAILED: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# --------------------------------------------
# HTML DECODE
# --------------------------------------------

function Decode-Html {
    param([string]$Text)

    if (-not $Text) {
        return ""
    }

    return [System.Net.WebUtility]::HtmlDecode($Text)
}

# --------------------------------------------
# URL DECODE
# --------------------------------------------

function Decode-UrlRepeated {
    param([string]$Value)

    if (-not $Value) {
        return ""
    }

    $result = $Value

    for ($i = 0; $i -lt 3; $i++) {
        try {
            $decoded = [System.Uri]::UnescapeDataString($result)

            if ($decoded -eq $result) {
                break
            }

            $result = $decoded
        }
        catch {
            break
        }
    }

    return $result
}

# --------------------------------------------
# BING BASE64 DECODER
# --------------------------------------------

function Decode-BingBase64 {
    param([string]$Value)

    if (-not $Value) {
        return $null
    }

    try {

        $value = Decode-UrlRepeated $Value
        $value = Decode-Html $value

        # Bing commonly prefixes encoded URLs with a1
        if ($value.StartsWith("a1")) {
            $value = $value.Substring(2)
        }

        # Sometimes the value contains extra parameters
        if ($value -match '^([^&]+)') {
            $value = $Matches[1]
        }

        # URL-safe Base64 -> normal Base64
        $value = $value.Replace("-", "+").Replace("_", "/")

        while (($value.Length % 4) -ne 0) {
            $value += "="
        }

        $bytes = [Convert]::FromBase64String($value)

        # UTF8 first
        $decoded = [System.Text.Encoding]::UTF8.GetString($bytes)

        if ($decoded -match '^https?://') {
            return $decoded
        }

        # UTF16 fallback
        try {
            $decoded16 = [System.Text.Encoding]::Unicode.GetString($bytes)

            if ($decoded16 -match '^https?://') {
                return $decoded16
            }
        }
        catch {}

        # Sometimes Bing encodes another layer
        try {

            $second = $decoded

            if ($second.StartsWith("a1")) {
                $second = $second.Substring(2)
            }

            $second = $second.Replace("-", "+").Replace("_", "/")

            while (($second.Length % 4) -ne 0) {
                $second += "="
            }

            $bytes2 = [Convert]::FromBase64String($second)
            $decoded2 = [System.Text.Encoding]::UTF8.GetString($bytes2)

            if ($decoded2 -match '^https?://') {
                return $decoded2
            }
        }
        catch {}

        return $null
    }
    catch {
        return $null
    }
}

# --------------------------------------------
# BING URL DECODER
# --------------------------------------------

function Decode-BingUrl {
    param([string]$RawUrl)

    if (-not $RawUrl) {
        return $null
    }

    $url = Decode-Html $RawUrl
    $url = Decode-UrlRepeated $url

    # Already a direct URL
    if ($url -match '^https?://(?!www\.bing\.com/)') {
        return $url
    }

    # Bing redirect: /ck/a?...&u=...
    if ($url -match '[?&]u=([^&]+)') {

        $u = $Matches[1]

        $decoded = Decode-BingBase64 $u

        if ($decoded -and $decoded -match '^https?://') {
            return $decoded
        }

        # Sometimes u itself is simply URL encoded
        $direct = Decode-UrlRepeated $u

        if ($direct -match '^https?://') {
            return $direct
        }
    }

    # Alternative Bing redirect format
    if ($url -match '[?&]url=([^&]+)') {

        $target = Decode-UrlRepeated $Matches[1]

        if ($target -match '^https?://') {
            return $target
        }
    }

    return $null
}

# --------------------------------------------
# STRIP HTML
# --------------------------------------------

function Strip-Html {
    param([string]$Text)

    if (-not $Text) {
        return ""
    }

    $Text = $Text -replace '<script[\s\S]*?</script>', ''
    $Text = $Text -replace '<style[\s\S]*?</style>', ''
    $Text = $Text -replace '<[^>]+>', ' '
    $Text = Decode-Html $Text
    $Text = $Text -replace '\s+', ' '

    return $Text.Trim()
}

# --------------------------------------------
# EXTRACT BING RESULTS
# --------------------------------------------

function Extract-BingResults {
    param(
        [string]$Html,
        [string]$Query
    )

    $results = @()

    if (-not $Html) {
        return $results
    }

    # Bing result blocks
    $pattern = '<h2[^>]*>[\s\S]*?<a[^>]+href=["'']([^"'']+)["''][^>]*>([\s\S]*?)</a>[\s\S]*?</h2>'

    $matches = [regex]::Matches(
        $Html,
        $pattern,
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )

    foreach ($m in $matches) {

        $rawUrl = Decode-Html $m.Groups[1].Value
        $title = Strip-Html $m.Groups[2].Value

        if (-not $title -or $title.Length -lt 3) {
            continue
        }

        # Decode Bing destination
        $url = Decode-BingUrl $rawUrl

        # Skip obvious Bing/internal results
        if ($title -match '^(Images|Videos|Maps|News|Shopping)$') {
            continue
        }

        # If no valid destination, do NOT store garbage
        if (-not $url) {
            Write-Host "  ? $title" -ForegroundColor Yellow
            Write-Host "    Bing URL could not be decoded" -ForegroundColor DarkYellow
            continue
        }

        # Reject obvious non-web garbage
        if ($url -notmatch '^https?://') {
            continue
        }

        # Reject Bing internal URLs
        if ($url -match '^https?://(www\.)?bing\.com/') {
            continue
        }

        # Reject obvious junk results
        if (
            $title -match 'pizza|minecraft|tiktok|chennai|edupool|skindex|baidu|知乎'
        ) {
            continue
        }

        $results += [PSCustomObject]@{
            query = $Query
            title = $title
            url = $url
            source_type = "bing"
        }

        Write-Host "  + $title" -ForegroundColor Green
        Write-Host "    $url" -ForegroundColor DarkGray

        if ($results.Count -ge 5) {
            break
        }
    }

    return @($results)
}

# --------------------------------------------
# RELEVANCE SCORE
# --------------------------------------------

function Get-RelevanceScore {
    param(
        [string]$Title,
        [string]$Query,
        [string]$Business
    )

    $score = 0

    $text = "$Title $Query".ToLower()
    $businessLower = $Business.ToLower()

    if ($Title.ToLower().Contains($businessLower)) {
        $score += 5
    }

    if ($text -match 'revenue|mrr|arr|customer|customers|user|users|pricing|paid|sales|income|profit') {
        $score += 3
    }

    if ($text -match 'product hunt|reddit|hacker news') {
        $score += 2
    }

    if ($text -match 'amazon|facebook|youtube|google maps|wikipedia|stack overflow') {
        $score -= 5
    }

    if ($score -lt 0) {
        $score = 0
    }

    if ($score -gt 10) {
        $score = 10
    }

    return $score
}

# --------------------------------------------
# PROCESS BUSINESSES
# --------------------------------------------

foreach ($item in $items) {

    $business = [string]$item.business_name_clean
    $identity = [string]$item.name

    Write-Host ""
    Write-Host "======================================"
    Write-Host $business
    Write-Host "======================================" -ForegroundColor Cyan

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
        Write-Host "SEARCH: $query" -ForegroundColor Cyan

        $html = Search-Bing $query

        $found = Extract-BingResults `
            -Html $html `
            -Query $query

        foreach ($r in $found) {
            $evidence += $r
        }

        if ($found.Count -eq 0) {
            Write-Host "  - No usable results" -ForegroundColor DarkYellow
        }
    }

    # ----------------------------------------
    # UNIQUE RESULTS
    # ----------------------------------------

    $uniqueResults = @(
        $evidence |
        Where-Object {
            $_.url -and
            $_.url -match '^https?://'
        } |
        Group-Object url |
        ForEach-Object {
            $_.Group[0]
        }
    )

    # ----------------------------------------
    # SCORE RESULTS
    # ----------------------------------------

    foreach ($result in $uniqueResults) {

        $result | Add-Member `
            -NotePropertyName "relevance_score" `
            -NotePropertyValue (
                Get-RelevanceScore `
                    -Title $result.title `
                    -Query $result.query `
                    -Business $business
            ) `
            -Force
    }

    # ----------------------------------------
    # CLASSIFICATION
    # ----------------------------------------

    foreach ($result in $uniqueResults) {

        $score = [int]$result.relevance_score
        $title = [string]$result.title

        if ($score -ge 6) {
            $classification = "RELEVANT"
        }
        elseif ($score -ge 3) {
            $classification = "POSSIBLY_RELEVANT"
        }
        else {
            $classification = "IRRELEVANT"
        }

        $result | Add-Member `
            -NotePropertyName "classification" `
            -NotePropertyValue $classification `
            -Force
    }

    # ----------------------------------------
    # COUNTS
    # ----------------------------------------

    $totalResults = @($evidence).Count

    $validTitles = @(
        $evidence |
        Where-Object {
            $_.title -and $_.title.Length -gt 2
        }
    ).Count

    $validUrls = @(
        $evidence |
        Where-Object {
            $_.url -and $_.url -match '^https?://'
        }
    ).Count

    $corruptedResults = $totalResults - $validUrls

    $relevantResults = @(
        $uniqueResults |
        Where-Object {
            $_.classification -eq "RELEVANT"
        }
    ).Count

    $possiblyRelevantResults = @(
        $uniqueResults |
        Where-Object {
            $_.classification -eq "POSSIBLY_RELEVANT"
        }
    ).Count

    $irrelevantResults = @(
        $uniqueResults |
        Where-Object {
            $_.classification -eq "IRRELEVANT"
        }
    ).Count

    # ----------------------------------------
    # COMMERCIAL EVIDENCE
    # ----------------------------------------

    $commercialEvidence = @(
        $uniqueResults |
        Where-Object {

            $text = [string]$_.title

            $text -match `
            'revenue|MRR|ARR|customer|customers|user|users|pricing|paid|sales|income|profit|subscription|monthly|annual|million|thousand'
        }
    )

    $strongEvidence = @(
        $uniqueResults |
        Where-Object {

            $text = [string]$_.title

            $text -match `
            'revenue|MRR|ARR|paying customers|paid users|monthly recurring|annual recurring|sales|profit'
        }
    )

    $usableEvidence = @(
        $uniqueResults |
        Where-Object {
            $_.classification -in @(
                "RELEVANT",
                "POSSIBLY_RELEVANT"
            )
        }
    ).Count

    # ----------------------------------------
    # QUALITY RATIO
    # ----------------------------------------

    if ($uniqueResults.Count -gt 0) {
        $qualityRatio = [math]::Round(
            ($usableEvidence / $uniqueResults.Count) * 100,
            0
        )
    }
    else {
        $qualityRatio = 0
    }

    # ----------------------------------------
    # DATA QUALITY LEVEL
    # ----------------------------------------

    $qualityLevel = "LOW"

    if ($qualityRatio -ge 70 -and $uniqueResults.Count -ge 5) {
        $qualityLevel = "HIGH"
    }
    elseif ($qualityRatio -ge 30 -and $uniqueResults.Count -ge 3) {
        $qualityLevel = "MEDIUM"
    }

    # ----------------------------------------
    # SEARCH HEALTH
    # ----------------------------------------

    if ($validUrls -eq 0) {
        $searchHealth = "SEARCH_ERROR"
    }
    elseif ($uniqueResults.Count -lt 3) {
        $searchHealth = "INSUFFICIENT_DATA"
    }
    else {
        $searchHealth = "VALID_DATA"
    }

    # ----------------------------------------
    # VALIDATION STATUS
    # ----------------------------------------

    if (
        $strongEvidence.Count -ge 3 -and
        $searchHealth -eq "VALID_DATA"
    ) {
        $validationStatus = "VALIDATED"
        $proofLevel = "STRONG"
    }
    elseif (
        $commercialEvidence.Count -ge 2 -and
        $searchHealth -eq "VALID_DATA"
    ) {
        $validationStatus = "PARTIAL"
        $proofLevel = "MONETIZED"
    }
    elseif (
        $commercialEvidence.Count -ge 1 -and
        $searchHealth -eq "VALID_DATA"
    ) {
        $validationStatus = "PARTIAL"
        $proofLevel = "WEAK"
    }
    else {
        $validationStatus = "UNVALIDATED"
        $proofLevel = "NONE"
    }

    # ----------------------------------------
    # VALIDATION SAFETY
    # ----------------------------------------

    $validationSafe = $false

    if (
        $searchHealth -eq "VALID_DATA" -and
        $usableEvidence -ge 1
    ) {
        $validationSafe = $true
    }

    # ----------------------------------------
    # STORE V18 DATA
    # ----------------------------------------

    $item | Add-Member `
        -NotePropertyName "validation_version" `
        -NotePropertyValue "V18" `
        -Force

    $item | Add-Member `
        -NotePropertyName "validation_status" `
        -NotePropertyValue $validationStatus `
        -Force

    $item | Add-Member `
        -NotePropertyName "commercial_proof_level" `
        -NotePropertyValue $proofLevel `
        -Force

    $item | Add-Member `
        -NotePropertyName "data_quality_level" `
        -NotePropertyValue $qualityLevel `
        -Force

    $item | Add-Member `
        -NotePropertyName "search_health" `
        -NotePropertyValue $searchHealth `
        -Force

    $item | Add-Member `
        -NotePropertyName "validation_safe" `
        -NotePropertyValue $validationSafe `
        -Force

    $item | Add-Member `
        -NotePropertyName "total_results_checked" `
        -NotePropertyValue $totalResults `
        -Force

    $item | Add-Member `
        -NotePropertyName "valid_titles" `
        -NotePropertyValue $validTitles `
        -Force

    $item | Add-Member `
        -NotePropertyName "valid_urls" `
        -NotePropertyValue $validUrls `
        -Force

    $item | Add-Member `
        -NotePropertyName "corrupted_results" `
        -NotePropertyValue $corruptedResults `
        -Force

    $item | Add-Member `
        -NotePropertyName "relevant_results" `
        -NotePropertyValue $relevantResults `
        -Force

    $item | Add-Member `
        -NotePropertyName "possibly_relevant_results" `
        -NotePropertyValue $possiblyRelevantResults `
        -Force

    $item | Add-Member `
        -NotePropertyName "irrelevant_results" `
        -NotePropertyValue $irrelevantResults `
        -Force

    $item | Add-Member `
        -NotePropertyName "usable_evidence" `
        -NotePropertyValue $usableEvidence `
        -Force

    $item | Add-Member `
        -NotePropertyName "usable_evidence_ratio" `
        -NotePropertyValue $qualityRatio `
        -Force

    $item | Add-Member `
        -NotePropertyName "quality_results" `
        -NotePropertyValue $uniqueResults `
        -Force

    $data += $item

    # ----------------------------------------
    # DISPLAY
    # ----------------------------------------

    Write-Host ""
    Write-Host "RESULTS CHECKED      : $totalResults" -ForegroundColor Gray
    Write-Host "VALID TITLES         : $validTitles" -ForegroundColor Gray
    Write-Host "VALID URLS           : $validUrls" -ForegroundColor Gray
    Write-Host "CORRUPTED            : $corruptedResults" -ForegroundColor $(if ($corruptedResults -gt 0) {"Red"} else {"Gray"})
    Write-Host "RELEVANT             : $relevantResults" -ForegroundColor $(if ($relevantResults -gt 0) {"Green"} else {"Gray"})
    Write-Host "POSSIBLY RELEVANT    : $possiblyRelevantResults" -ForegroundColor Yellow
    Write-Host "IRRELEVANT           : $irrelevantResults" -ForegroundColor Gray
    Write-Host "USABLE EVIDENCE      : $usableEvidence" -ForegroundColor $(if ($usableEvidence -gt 0) {"Green"} else {"Red"})
    Write-Host "QUALITY RATIO        : $qualityRatio%" -ForegroundColor $(if ($qualityRatio -ge 30) {"Green"} else {"Yellow"})
    Write-Host "QUALITY LEVEL        : $qualityLevel" -ForegroundColor $(if ($qualityLevel -eq "HIGH") {"Green"} elseif ($qualityLevel -eq "MEDIUM") {"Yellow"} else {"Red"})
    Write-Host "SEARCH HEALTH        : $searchHealth" -ForegroundColor $(if ($searchHealth -eq "VALID_DATA") {"Green"} elseif ($searchHealth -eq "INSUFFICIENT_DATA") {"Yellow"} else {"Red"})
    Write-Host "VALIDATION SAFE      : $validationSafe" -ForegroundColor $(if ($validationSafe) {"Green"} else {"Red"})
    Write-Host ""

    # ----------------------------------------
    # TOP RESULTS
    # ----------------------------------------

    if ($uniqueResults.Count -gt 0) {

        Write-Host "TOP RESULTS:" -ForegroundColor Cyan

        $uniqueResults |
            Sort-Object relevance_score -Descending |
            Select-Object -First 10 |
            ForEach-Object {

                $marker = "+"

                if ($_.classification -eq "IRRELEVANT") {
                    $marker = "-"
                }
                elseif ($_.classification -eq "POSSIBLY_RELEVANT") {
                    $marker = "?"
                }

                Write-Host `
                    "  [$marker] [$($_.relevance_score)/10] $($_.title)" `
                    -ForegroundColor DarkGray
            }

        Write-Host ""
    }
}

# --------------------------------------------
# SAVE
# --------------------------------------------

try {

    $data |
        ConvertTo-Json -Depth 30 |
        Set-Content $outputFile -Encoding UTF8

}
catch {

    Write-Host "ERROR: Unable to save output file." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# --------------------------------------------
# FINAL SUMMARY
# --------------------------------------------

$searchErrors = @(
    $data |
    Where-Object {
        $_.search_health -eq "SEARCH_ERROR"
    }
).Count

$insufficient = @(
    $data |
    Where-Object {
        $_.search_health -eq "INSUFFICIENT_DATA"
    }
).Count

$validData = @(
    $data |
    Where-Object {
        $_.search_health -eq "VALID_DATA"
    }
).Count

$validated = @(
    $data |
    Where-Object {
        $_.validation_status -eq "VALIDATED"
    }
).Count

$partial = @(
    $data |
    Where-Object {
        $_.validation_status -eq "PARTIAL"
    }
).Count

Write-Host "======================================" -ForegroundColor Cyan
Write-Host " V18 COMPLETE" -ForegroundColor Green
Write-Host "======================================"
Write-Host ""
Write-Host "VALID DATA       : $validData" -ForegroundColor Green
Write-Host "INSUFFICIENT     : $insufficient" -ForegroundColor Yellow
Write-Host "SEARCH ERROR     : $searchErrors" -ForegroundColor Red
Write-Host "VALIDATED        : $validated" -ForegroundColor Green
Write-Host "PARTIAL          : $partial" -ForegroundColor Yellow
Write-Host ""
Write-Host "Output: $outputFile" -ForegroundColor Yellow
Write-Host ""

