# ==============================================
# BUSINESS VALIDATION V25-B
# Bing Organic Results
# ==============================================

$ErrorActionPreference = "Continue"

$data = @()

function Search-Bing {
    param([string]$Query)

    try {
        if ([string]::IsNullOrWhiteSpace($Query)) {
            return $null
        }

        $encoded = [System.Uri]::EscapeDataString($Query)

        $response = Invoke-WebRequest `
            -Uri "https://www.bing.com/search?q=$encoded&setlang=en-us&cc=us&count=10" `
            -UseBasicParsing `
            -Headers @{
                "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/151.0 Safari/537.36"
                "Accept-Language" = "en-US,en;q=0.9"
            }

        if (-not $response -or -not $response.Content) {
            return $null
        }

        return $response.Content
    }
    catch {
        Write-Host "BING ERROR: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Strip-Html {
    param([string]$Text)

    if (-not $Text) {
        return ""
    }

    $Text = $Text -replace '<script[\s\S]*?</script>', ' '
    $Text = $Text -replace '<style[\s\S]*?</style>', ' '
    $Text = $Text -replace '<[^>]+>', ' '
    $Text = [System.Net.WebUtility]::HtmlDecode($Text)
    $Text = $Text -replace '\s+', ' '

    return $Text.Trim()
}

function Decode-BingUrl {
    param([string]$Url)

    if (-not $Url) {
        return ""
    }

    try {
        $Url = [System.Net.WebUtility]::HtmlDecode($Url)

        if ($Url -match '[?&]u=([^&]+)') {
            $encoded = $Matches[1]
            $encoded = $encoded -replace '-', '+'
            $encoded = $encoded -replace '_', '/'

            while (($encoded.Length % 4) -ne 0) {
                $encoded += "="
            }

            try {
                $bytes = [Convert]::FromBase64String($encoded)
                $decoded = [System.Text.Encoding]::UTF8.GetString($bytes)

                if ($decoded.StartsWith("a1")) {
                    $decoded = $decoded.Substring(2)
                }

                if ($decoded -match '^https?://') {
                    return $decoded
                }
            }
            catch {}
        }

        return $Url
    }
    catch {
        return $Url
    }
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

    $blocks = [regex]::Matches(
        $Html,
        '<li[^>]+class="[^"]*\bb_algo\b[^"]*"[\s\S]*?</li>',
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    )

    foreach ($block in $blocks) {

        $htmlBlock = $block.Value

        $linkMatch = [regex]::Match(
            $htmlBlock,
            '<h2[^>]*>[\s\S]*?<a[^>]+href="([^"]+)"[^>]*>([\s\S]*?)</a>',
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        )

        if (-not $linkMatch.Success) {
            continue
        }

        $url = Decode-BingUrl $linkMatch.Groups[1].Value
        $title = Strip-Html $linkMatch.Groups[2].Value

        $snippetMatch = [regex]::Match(
            $htmlBlock,
            '<p[^>]*>([\s\S]*?)</p>',
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        )

        $snippet = ""

        if ($snippetMatch.Success) {
            $snippet = Strip-Html $snippetMatch.Groups[1].Value
        }

        if ($title -and $url) {
            $results += [PSCustomObject]@{
                query = $Query
                title = $title
                url = $url
                snippet = $snippet
                source_type = "bing_organic"
            }
        }
    }

    return $results
}

function Get-BusinessIdentityTokens {
    param(
        [string]$Name
    )

    if ([string]::IsNullOrWhiteSpace($Name)) {
        return @()
    }

    $clean = $Name.ToLower()
    $clean = $clean -replace '\([^)]*\)', ' '
    $clean = $clean -replace '\$[0-9]+(\.[0-9]+)?', ' '
    $clean = $clean -replace '[^a-z0-9]+', ' '

    $stopWords = @(
        'show','hn','the','a','an','and','for','with','from','to','of',
        'in','on','free','online','tools','tool','developers','developer',
        'everyday','tasks','video','social','network','members','ai','agents'
    )

    $tokens = @(
        $clean -split '\s+' |
        Where-Object {
            $_.Length -ge 3 -and
            $_ -notin $stopWords
        }
    )

    return $tokens
}

function Test-BusinessIdentity {
    param(
        [string]$BusinessName,
        [string]$Title,
        [string]$Snippet,
        [string]$Url
    )

    $tokens = @(Get-BusinessIdentityTokens $BusinessName)

    if ($tokens.Count -eq 0) {
        return $false
    }

    $text = "$Title $Snippet $Url".ToLower()
    $matched = 0

    foreach ($token in $tokens) {
        if ($text -match [regex]::Escape($token)) {
            $matched++
        }
    }

    if ($tokens.Count -eq 1) {
        $token = $tokens[0]

        if ($Title.ToLower() -match [regex]::Escape($token)) {
            return $true
        }

        if ($Url.ToLower() -match [regex]::Escape($token)) {
            return $true
        }

        return $false
    }

    $threshold = [math]::Ceiling($tokens.Count * 0.5)

    return ($matched -ge $threshold)
}
function Is-CommercialEvidence {
    param(
        [string]$Title,
        [string]$Snippet,
        [string]$Query
    )

    $text = "$Title $Snippet $Query".ToLower()

    $patterns = @(
        'pricing',
        'price',
        'paid',
        'subscription',
        'subscribe',
        'customers',
        'customer',
        'users',
        'revenue',
        'mrr',
        'arr',
        'sales',
        'buy',
        'cost',
        'plans',
        'plan',
        'product hunt',
        'reviews',
        'review',
        'marketplace',
        'booking',
        'order',
        'download',
        'business',
        'company',
        'startup'
    )

    foreach ($pattern in $patterns) {
        if ($text -match [regex]::Escape($pattern)) {
            return $true
        }
    }

    return $false
}

function Is-StrongEvidence {
    param(
        [string]$Title,
        [string]$Snippet
    )

    $text = "$Title $Snippet".ToLower()

    $strongPatterns = @(
        'revenue',
        'mrr',
        'arr',
        'customers',
        'customer',
        'paid users',
        'paying users',
        'pricing',
        'subscription',
        'sales',
        'product hunt',
        'case study'
    )

    foreach ($pattern in $strongPatterns) {
        if ($text -match [regex]::Escape($pattern)) {
            return $true
        }
    }

    return $false
}

# ==============================================
# LOAD QUEUE
# ==============================================

$inputFile = ".\validation_queue.json"

if (-not (Test-Path $inputFile)) {
    Write-Host "ERREUR : validation_queue.json introuvable." -ForegroundColor Red
    exit
}

try {
    $queue = Get-Content $inputFile -Raw | ConvertFrom-Json
}
catch {
    Write-Host "ERREUR : impossible de lire validation_queue.json" -ForegroundColor Red
    exit
}

foreach ($item in $queue) {

    $name = ""

    if ($item.name) {
        $name = [string]$item.name
    }
    elseif ($item.title) {
        $name = [string]$item.title
    }
    elseif ($item.business_name) {
        $name = [string]$item.business_name
    }

    if ([string]::IsNullOrWhiteSpace($name)) {
        continue
    }

    Write-Host ""
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host $name -ForegroundColor White
    Write-Host "======================================" -ForegroundColor Cyan

    $queries = @(
        "`"$name`"",
        "`"$name`" revenue",
        "`"$name`" MRR",
        "`"$name`" ARR",
        "`"$name`" customers",
        "`"$name`" users",
        "`"$name`" pricing",
        "`"$name`" paid",
        "`"$name`" Product Hunt",
        "`"$name`" Reddit",
        "`"$name`" Hacker News"
    )

    $allResults = @()

    foreach ($query in $queries) {

        Write-Host "SEARCH: $query"

        $html = Search-Bing $query

        if (-not $html) {
            Write-Host "  REQUEST FAILED" -ForegroundColor Red
            continue
        }

        $found = Extract-BingResults `
            -Html $html `
            -Query $query

        foreach ($r in $found) {
            $allResults += $r
        }
    }

    # Deduplicate URLs
    $uniqueResults = @(
        $allResults |
        Group-Object url |
        ForEach-Object {
            $_.Group | Select-Object -First 1
        }
    )

    $commercialResults = @(
        $uniqueResults |
        Where-Object {
            Is-CommercialEvidence `
                -Title $_.title `
                -Snippet $_.snippet `
                -Query $_.query
        }
    )

    $strongResults = @(
        $commercialResults |
        Where-Object {
            Is-StrongEvidence `
                -Title $_.title `
                -Snippet $_.snippet
        }
    )

    $totalResults = $uniqueResults.Count
    $commercialCount = $commercialResults.Count
    $strongCount = $strongResults.Count

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

    if ($searchHealth -eq "VALID_DATA" -and $totalResults -ge 1) {
        $validationSafe = $true
    }
    else {
        $validationSafe = $false
    }

    if ($strongCount -ge 3) {
        $qualityLevel = "HIGH"
    }
    elseif ($commercialCount -ge 2) {
        $qualityLevel = "MEDIUM"
    }
    else {
        $qualityLevel = "LOW"
    }

    $result = [PSCustomObject]@{
        name = $name
        validation_status = $validationStatus
        commercial_proof_level = $proofLevel
        search_health = $searchHealth
        validation_safe = $validationSafe
        data_quality_level = $qualityLevel
        external_evidence_count = $totalResults
        commercial_evidence_count = $commercialCount
        strong_evidence_count = $strongCount
        evidence = $commercialResults
    }

    $data += $result

    Write-Host ""
    Write-Host "RESULTS ACCEPTED : $totalResults"
    Write-Host "COMMERCIAL       : $commercialCount"
    Write-Host "STRONG           : $strongCount"
    Write-Host "QUALITY          : $qualityLevel"
    Write-Host "SEARCH HEALTH    : $searchHealth"
    Write-Host "STATUS           : $validationStatus"
    Write-Host "SAFE             : $validationSafe"
}

# ==============================================
# SUMMARY
# ==============================================

$validData = @(
    $data | Where-Object {
        $_.search_health -eq "VALID_DATA"
    }
).Count

$insufficient = @(
    $data | Where-Object {
        $_.search_health -eq "INSUFFICIENT_DATA"
    }
).Count

$validated = @(
    $data | Where-Object {
        $_.validation_status -eq "VALIDATED"
    }
).Count

$partial = @(
    $data | Where-Object {
        $_.validation_status -eq "PARTIAL"
    }
).Count

$unvalidated = @(
    $data | Where-Object {
        $_.validation_status -eq "UNVALIDATED"
    }
).Count

$outputFile = ".\validation_results_v25-B.json"

$data |
    ConvertTo-Json -Depth 10 |
    Set-Content $outputFile -Encoding UTF8

Write-Host ""
Write-Host "======================================" -ForegroundColor Green
Write-Host " V25-B COMPLETE" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""
Write-Host "VALID DATA       : $validData"
Write-Host "INSUFFICIENT     : $insufficient"
Write-Host "VALIDATED        : $validated"
Write-Host "PARTIAL          : $partial"
Write-Host "UNVALIDATED      : $unvalidated"
Write-Host ""
Write-Host "Output: $outputFile" -ForegroundColor Cyan


