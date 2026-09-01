$data = Get-Content .\radar57_real_proof.json -Raw | ConvertFrom-Json

$result = foreach ($item in $data) {

    $checks = @()

    foreach ($url in @($item.urls)) {

        if (-not $url) { continue }

        $tmpFile = [System.IO.Path]::GetTempFileName()

        try {

            $headers = & curl.exe `
                -L `
                -I `
                --max-time 15 `
                --connect-timeout 8 `
                -A "Mozilla/5.0" `
                -sS `
                -o NUL `
                -w "%{http_code}|%{url_effective}" `
                "$url" 2>$null

            if ($headers) {

                $parts = $headers -split '\|',2
                $statusCode = 0

                if ($parts[0] -match '^\d+$') {
                    $statusCode = [int]$parts[0]
                }

                $finalUrl = if ($parts.Count -gt 1) {
                    $parts[1]
                } else {
                    $null
                }

                if ($statusCode -ge 200 -and $statusCode -lt 300) {
                    $status = "LIVE"
                }
                elseif ($statusCode -ge 300 -and $statusCode -lt 400) {
                    $status = "REDIRECTED"
                }
                elseif ($statusCode -eq 403 -or $statusCode -eq 429) {
                    $status = "BLOCKED"
                }
                elseif ($statusCode -gt 0) {
                    $status = "HTTP_ERROR"
                }
                else {
                    $status = "NO_RESPONSE"
                }

                $checks += [PSCustomObject]@{
                    url = $url
                    final_url = $finalUrl
                    status_code = $statusCode
                    status = $status
                    error = $null
                }
            }
            else {
                $checks += [PSCustomObject]@{
                    url = $url
                    final_url = $null
                    status_code = $null
                    status = "NO_RESPONSE"
                    error = "curl returned no result"
                }
            }
        }
        catch {
            $checks += [PSCustomObject]@{
                url = $url
                final_url = $null
                status_code = $null
                status = "ERROR"
                error = $_.Exception.Message
            }
        }
        finally {
            if (Test-Path $tmpFile) {
                Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue
            }
        }
    }

    $liveCount = @(
        $checks | Where-Object {
            $_.status -eq "LIVE" -or $_.status -eq "REDIRECTED"
        }
    ).Count

    $blockedCount = @(
        $checks | Where-Object {
            $_.status -eq "BLOCKED"
        }
    ).Count

    $totalUrls = $checks.Count

    if ($totalUrls -eq 0) {
        $urlStatus = "NO_URL"
    }
    elseif ($liveCount -ge 2) {
        $urlStatus = "MULTIPLE_LIVE"
    }
    elseif ($liveCount -eq 1) {
        $urlStatus = "LIVE"
    }
    elseif ($blockedCount -gt 0) {
        $urlStatus = "BLOCKED"
    }
    else {
        $urlStatus = "UNVERIFIED"
    }

    [PSCustomObject]@{
        idea_name = $item.idea_name
        country = $item.country
        category = $item.category

        observation_count = $item.observation_count
        source_count = $item.source_count
        city_count = $item.city_count

        url_count = $totalUrls
        live_url_count = $liveCount
        blocked_url_count = $blockedCount

        url_status = $urlStatus

        http_verified = ($liveCount -gt 0)

        url_checks = $checks

        sources = @($item.sources)
        cities = @($item.cities)
    }
}

$result |
    ConvertTo-Json -Depth 15 |
    Set-Content .\radar58_url_verified.json -Encoding UTF8

Write-Host ""
Write-Host "========================================="
Write-Host "RADAR 58 - URL VERIFICATION"
Write-Host "========================================="
Write-Host ""

Write-Host "Opportunités : $($result.Count)"
Write-Host ""

Write-Host "STATUT DES URL :"

$result |
    Group-Object url_status |
    Select-Object Name,Count |
    Sort-Object Name |
    Format-Table -AutoSize

Write-Host ""

$totalUrls = ($result | ForEach-Object { $_.url_count } | Measure-Object -Sum).Sum
$totalLive = ($result | ForEach-Object { $_.live_url_count } | Measure-Object -Sum).Sum
$totalBlocked = ($result | ForEach-Object { $_.blocked_url_count } | Measure-Object -Sum).Sum

Write-Host "URL TESTÉES  : $totalUrls"
Write-Host "URL VIVANTES : $totalLive"
Write-Host "URL BLOQUÉES : $totalBlocked"

Write-Host ""
Write-Host "RESULTATS :"

$result |
    Where-Object { $_.url_count -gt 0 } |
    Select-Object idea_name,country,url_count,live_url_count,blocked_url_count,url_status |
    Format-Table -AutoSize

Write-Host ""
Write-Host "Fichier créé : radar58_url_verified.json"
Write-Host ""
