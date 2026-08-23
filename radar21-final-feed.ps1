Write-Host ""
Write-Host "========================================"
Write-Host " BiznessHunter - Radar 21"
Write-Host " FINAL OPPORTUNITY FEED"
Write-Host "========================================"
Write-Host ""

$raw = Get-Content .\radar20_final_opportunities.json -Raw | ConvertFrom-Json
$items = @($raw)

Write-Host "Final opportunities : $($items.Count)"
Write-Host ""

$feed = @()
$rank = 1

foreach ($item in $items) {

    $action = switch ($item.verdict) {
        "HIGH GAP" {
            "INVESTIGATE NOW"
        }
        "PROMISING GAP" {
            "INVESTIGATE"
        }
        "WATCH" {
            "MONITOR"
        }
        "LOW" {
            "LOW PRIORITY"
        }
        default {
            "NEED MORE EVIDENCE"
        }
    }

    $proofLevel = if ($item.company_count -ge 5 -and $item.article_count -ge 5) {
        "STRONG"
    }
    elseif ($item.company_count -ge 2 -or $item.article_count -ge 2) {
        "MODERATE"
    }
    elseif ($item.company_count -ge 1 -or $item.article_count -ge 1) {
        "WEAK"
    }
    else {
        "NONE"
    }

    $feed += [PSCustomObject]@{
        rank              = $rank
        opportunity       = $item.opportunity
        category          = $item.original_category
        source_cluster    = $item.source_cluster

        final_score       = $item.final_score
        verdict           = $item.verdict
        action            = $action
        confidence        = $item.confidence

        gap_score         = $item.gap_score
        replication       = $item.replication
        competition_gap   = $item.competition_gap
        geographic_gap    = $item.geographic_gap

        market_proof      = $item.market_proof
        geographic_proof  = $item.geographic_proof
        proof_level       = $proofLevel

        company_count     = $item.company_count
        country_count     = $item.country_count
        article_count     = $item.article_count

        companies         = @($item.companies)
        countries         = @($item.countries)

        why               = $item.why

        source_articles   = @($item.source_articles)
        signals           = @($item.signals)

        evidence_status   = $item.evidence_status
    }

    $rank++
}

$feed |
    ConvertTo-Json -Depth 20 |
    Set-Content .\radar21_final_feed.json -Encoding UTF8

Write-Host "Output : .\radar21_final_feed.json"
Write-Host ""

$feed |
    Select-Object rank,opportunity,final_score,verdict,action,confidence,proof_level |
    Format-Table -AutoSize

Write-Host ""
Write-Host "========================================"
Write-Host " Radar 21 completed"
Write-Host "========================================"
