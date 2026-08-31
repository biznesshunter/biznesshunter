$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "======================================"
Write-Host " BUSINESS VALIDATION V13"
Write-Host " BING WEB EVIDENCE COLLECTOR"
Write-Host "======================================"

$inputFile = ".\validation_queue.json"
$outputFile = ".\validation_results_v13.json"

$items = Get-Content $inputFile -Raw | ConvertFrom-Json
$results = @()

function Search-Bing {
    param(
        [string]$Query
    )

    $encoded = [uri]::EscapeDataString($Query)
    $url = "https://www.bing.com/search?q=$encoded"

    try {
        $response = Invoke-WebRequest `
            -Uri $url `
            -UseBasicParsing `
            -Headers @{
                "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
                "Accept-Language" = "en-US,en;q=0.9"
            }

        return $response.Content
    }
    catch {
        Write-Host "  ! Bing request failed: $($_.Exception.Message)"
        return $null
    }
}

function Extract-BingResults {
    param(
        [string]$Html,
        [string]$Query
    )

    $found = @()

    if (-not $Html) {
        return $found
    }

    # Bing result blocks
    $blocks = [regex]::Matches(
        $Html,
        '<li class="b_algo".*?</li>',
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )

    foreach ($block in $blocks) {

        $text = $block.Value

        $linkMatch = [regex]::Match(
            $text,
            '<a[^>]+href="([^"]+)"[^>]*>(.*?)</a>',
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
            [System.Text.RegularExpressions.RegexOptions]::Singleline
        )

        if (-not $linkMatch.Success) {
            continue
        }

        $foundUrl = [System.Net.WebUtility]::HtmlDecode(
            $linkMatch.Groups[1].Value
        )

        $title = [System.Net.WebUtility]::HtmlDecode(
            ($linkMatch.Groups[2].Value -replace '<.*?>','')
        )

        $snippetMatch = [regex]::Match(
            $text,
            '<p[^>]*>(.*?)</p>',
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
            [System.Text.RegularExpressions.RegexOptions]::Singleline
        )

        $snippet = ""

        if ($snippetMatch.Success) {
            $snippet = [System.Net.WebUtility]::HtmlDecode(
                ($snippetMatch.Groups[1].Value -replace '<.*?>','')
            )
        }

        if (
            $foundUrl -and
            $title.Length -gt 2 -and
            $foundUrl -notmatch "bing.com"
        ) {

            $found += [PSCustomObject]@{
                query = $Query
                title = $title.Trim()
                url = $foundUrl.Trim()
                snippet = $snippet.Trim()
                source_type = "bing"
            }
        }

        if ($found.Count -ge 5) {
            break
        }
    }

    return $found
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

        $html = Search-Bing -Query $query

        if ($html) {

            $found = Extract-BingResults `
                -Html $html `
                -Query $query

            foreach ($result in $found) {

                $evidence += $result

                Write-Host "  + $($result.title)"
                Write-Host "    $($result.url)"
            }

            if ($found.Count -eq 0) {
                Write-Host "  - No results extracted"
            }
        }
    }

    # Deduplicate URLs
    $uniqueEvidence = @(
        $evidence |
        Where-Object { $_.url } |
        Group-Object url |
        ForEach-Object { $_.Group[0] }
    )

    # Commercial signals
    $commercialEvidence = @(
        $uniqueEvidence | Where-Object {

            $text = (
                $_.title + " " +
                $_.snippet
            )

            $text -match `
            "revenue|MRR|ARR|customers|customer|users|user|pricing|paid|sales|income|profit|subscription|monthly|annual|million|thousand"
        }
    )

    # Strong proof signals
    $strongEvidence = @(
        $uniqueEvidence | Where-Object {

            $text = (
                $_.title + " " +
                $_.snippet
            )

            $text -match `
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
        validation_version = "V13"
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
Write-Host " V13 COMPLETE"
Write-Host "======================================"
Write-Host ""
Write-Host "Output: $outputFile"
