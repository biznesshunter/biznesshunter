function Search-Bing {
    param([string]$Query)

    try {
        if (-not $Query) {
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
