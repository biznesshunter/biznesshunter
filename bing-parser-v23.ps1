function Decode-BingUrl {
    param([string]$Url)

    try {
        if (-not $Url) {
            return ""
        }

        $Url = [System.Net.WebUtility]::HtmlDecode($Url)

        if ($Url -notmatch '[?&]u=([^&]+)') {
            return $Url
        }

        $encoded = $Matches[1]

        if ($encoded.StartsWith("a1")) {
            $encoded = $encoded.Substring(2)
        }

        $encoded = $encoded -replace '-', '+'
        $encoded = $encoded -replace '_', '/'

        while (($encoded.Length % 4) -ne 0) {
            $encoded += "="
        }

        $bytes = [Convert]::FromBase64String($encoded)
        $decoded = [System.Text.Encoding]::UTF8.GetString($bytes)

        $decoded = [System.Net.WebUtility]::UrlDecode($decoded)

        if ($decoded -match '^https?://') {
            return $decoded
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

    $blocks = [regex]::Matches(
        $Html,
        '<li[^>]+class="[^"]*\bb_algo\b[^"]*"[\s\S]*?</li>',
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    )

    $rank = 0

    foreach ($blockMatch in $blocks) {

        $block = $blockMatch.Value

        $linkMatch = [regex]::Match(
            $block,
            '<h2[^>]*>[\s\S]*?<a[^>]+href="([^"]+)"[^>]*>([\s\S]*?)</a>',
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        )

        if (-not $linkMatch.Success) {
            continue
        }

        $rank++

        $rawUrl = $linkMatch.Groups[1].Value

        $title = [System.Net.WebUtility]::HtmlDecode(
            [regex]::Replace(
                $linkMatch.Groups[2].Value,
                '<[^>]+>',
                ''
            )
        ).Trim()

        $url = Decode-BingUrl -Url $rawUrl

        $captionMatch = [regex]::Match(
            $block,
            '<p[^>]+class="[^"]*b_lineclamp[^"]*"[^>]*>([\s\S]*?)</p>',
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        )

        $snippet = ""

        if ($captionMatch.Success) {
            $snippet = [System.Net.WebUtility]::HtmlDecode(
                [regex]::Replace(
                    $captionMatch.Groups[1].Value,
                    '<[^>]+>',
                    ''
                )
            ).Trim()
        }

        $results += [PSCustomObject]@{
            rank    = $rank
            title   = $title
            url     = $url
            snippet = $snippet
            query   = $Query
        }
    }

    return $results
}

