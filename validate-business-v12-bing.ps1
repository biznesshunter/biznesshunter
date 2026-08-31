$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "======================================"
Write-Host " BUSINESS VALIDATION V12"
Write-Host " REAL WEB EVIDENCE COLLECTOR"
Write-Host "======================================"

$inputFile = ".\validation_queue.json"
$outputFile = ".\validation_results_v12.json"

$items = Get-Content $inputFile -Raw | ConvertFrom-Json

$results = @()

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
        "`"$business`" Product Hunt",
        "`"$business`" Reddit",
        "`"$business`" Hacker News"
    )

    foreach ($query in $queries) {

        Write-Host ""
        Write-Host "SEARCH: $query"

        try {

            $encoded = [uri]::EscapeDataString($query)

            $url = "https://www.bing.com/search?q=$encoded"

            $response = Invoke-WebRequest -Uri $url `
                -UseBasicParsing `
                -Headers @{
                    "User-Agent" = "Mozilla/5.0"
                }

            $html = $response.Content

            $matches = [regex]::Matches(
                $html,
                '<a href="/url\?q=(.*?)".*?>(.*?)</a>',
                [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
            )

            $count = 0

            foreach ($match in $matches) {

                if ($count -ge 5) {
                    break
                }

                $foundUrl = [System.Net.WebUtility]::HtmlDecode(
                    $match.Groups[1].Value
                )

                $title = [System.Net.WebUtility]::HtmlDecode(
                    ($match.Groups[2].Value -replace '<.*?>','')
                )

                if (
                    $foundUrl -and
                    $foundUrl -notmatch "google.com" -and
                    $title.Length -gt 2
                ) {

                    $evidence += [PSCustomObject]@{
                        query = $query
                        title = $title
                        url = $foundUrl
                        source_type = "web_search"
                    }

                    Write-Host "  + $title"

                    $count++
                }
            }

        }
        catch {

            Write-Host "  ! Search failed"
        }
    }

    $uniqueEvidence = $evidence |
        Group-Object url |
        ForEach-Object { $_.Group[0] }

    $commercialEvidence = @(
        $uniqueEvidence | Where-Object {
            $_.title -match `
            "revenue|MRR|ARR|customer|user|pricing|paid|sales|income|profit|subscription"
        }
    )

    if ($commercialEvidence.Count -ge 3) {
        $status = "VALIDATED"
        $proof = "STRONG"
    }
    elseif ($commercialEvidence.Count -ge 1) {
        $status = "PARTIAL"
        $proof = "MONETIZED"
    }
    else {
        $status = "UNVALIDATED"
        $proof = "NONE"
    }

    $results += [PSCustomObject]@{
        name = $identity
        business_name_clean = $business
        validation_version = "V12"
        validation_status = $status
        commercial_proof_level = $proof
        evidence_quality = if ($uniqueEvidence.Count -gt 0) { "MEDIUM" } else { "LOW" }
        external_evidence_count = $uniqueEvidence.Count
        commercial_evidence_count = $commercialEvidence.Count
        external_evidence = @($uniqueEvidence)
    }

    Write-Host ""
    Write-Host "STATUS: $status"
    Write-Host "EVIDENCE: $($uniqueEvidence.Count)"
    Write-Host "COMMERCIAL: $($commercialEvidence.Count)"
}

$results |
    ConvertTo-Json -Depth 20 |
    Set-Content $outputFile -Encoding UTF8

Write-Host ""
Write-Host "======================================"
Write-Host " V12 COMPLETE"
Write-Host "======================================"
Write-Host ""
Write-Host "Output: $outputFile"

