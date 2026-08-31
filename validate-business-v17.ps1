# ============================================
# BUSINESS VALIDATION V17
# BING RESULTS - TITLES ONLY
# ============================================

$ErrorActionPreference = "SilentlyContinue"

$inputFile = ".\validation_results_v16.json"
$outputFile = ".\validation_results_v17.json"

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host " BUSINESS VALIDATION V17" -ForegroundColor Cyan
Write-Host " IGNORE BROKEN BING SNIPPETS" -ForegroundColor Yellow
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

$data = Get-Content $inputFile -Raw | ConvertFrom-Json

foreach ($item in $data) {

    Write-Host "======================================" -ForegroundColor DarkGray
    Write-Host $item.name -ForegroundColor White
    Write-Host "======================================" -ForegroundColor DarkGray

    $allResults = @()

    if ($item.evidence) {
        $allResults += $item.evidence
    }

    if ($item.searches) {
        foreach ($search in $item.searches) {
            if ($search.results) {
                $allResults += $search.results
            }
        }
    }

    $cleanResults = @()

    foreach ($r in $allResults) {

        $title = ""

        if ($r.title) {
            $title = [string]$r.title
        }
        elseif ($r.name) {
            $title = [string]$r.name
        }

        # Ignore corrupted extracted snippets
        $title = $title.Trim()

        if (
            $title -and
            $title -notmatch "kV.{0,10}GG3" -and
            $title -notmatch "No results extracted"
        ) {

            $cleanResults += [PSCustomObject]@{
                title = $title
                url   = if ($r.url) { [string]$r.url } else { "" }
            }
        }
    }

    # Deduplicate titles
    $unique = $cleanResults |
        Group-Object title |
        ForEach-Object { $_.Group[0] }

    $commercialKeywords = @(
        "pricing",
        "price",
        "plans",
        "subscription",
        "customers",
        "users",
        "revenue",
        "MRR",
        "ARR",
        "paid",
        "billing",
        "product hunt",
        "startup",
        "software",
        "app",
        "platform",
        "SaaS"
    )

    $commercial = 0

    foreach ($r in $unique) {

        foreach ($keyword in $commercialKeywords) {

            if ($r.title -match [regex]::Escape($keyword)) {
                $commercial++
                break
            }
        }
    }

    $strong = 0

    if ($commercial -ge 3) {
        $strong = 1
    }

    $status = "UNVALIDATED"

    if ($commercial -ge 3) {
        $status = "PARTIAL"
    }

    if ($commercial -ge 5) {
        $status = "VALIDATED"
    }

    $item | Add-Member -NotePropertyName "validation_version" -NotePropertyValue "V17" -Force
    $item | Add-Member -NotePropertyName "clean_evidence" -NotePropertyValue $unique.Count -Force
    $item | Add-Member -NotePropertyName "commercial_signals" -NotePropertyValue $commercial -Force
    $item | Add-Member -NotePropertyName "strong_signal" -NotePropertyValue $strong -Force
    $item | Add-Member -NotePropertyName "validation_status" -NotePropertyValue $status -Force
    $item | Add-Member -NotePropertyName "clean_results" -NotePropertyValue $unique -Force

    Write-Host ""
    Write-Host "CLEAN EVIDENCE : $($unique.Count)" -ForegroundColor Gray
    Write-Host "COMMERCIAL     : $commercial" -ForegroundColor $(if ($commercial -gt 0) {"Green"} else {"Red"})
    Write-Host "STRONG         : $strong" -ForegroundColor $(if ($strong -gt 0) {"Green"} else {"Gray"})
    Write-Host "STATUS         : $status" -ForegroundColor $(if ($status -eq "VALIDATED") {"Green"} elseif ($status -eq "PARTIAL") {"Yellow"} else {"Red"})
    Write-Host ""

    $unique | Select-Object -First 10 | ForEach-Object {
        Write-Host "  + $($_.title)" -ForegroundColor DarkGray
    }

    Write-Host ""
}

$data | ConvertTo-Json -Depth 20 | Set-Content $outputFile -Encoding UTF8

Write-Host "======================================" -ForegroundColor Cyan
Write-Host " V17 COMPLETE" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Output: $outputFile" -ForegroundColor Yellow
Write-Host ""
