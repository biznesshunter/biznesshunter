$pages = Get-Content .\pages_test.json -Raw | ConvertFrom-Json

$results = @()

foreach ($page in $pages) {

    $text = [string]$page.content_preview

    $category = "Other"

    if ($text -match "rental|rent|lease|sharing") {
        $category = "Rental / Sharing"
    }
    elseif ($text -match "marketplace|buyers|sellers|connect") {
        $category = "Marketplace"
    }
    elseif ($text -match "service|agency|consulting") {
        $category = "Service"
    }
    elseif ($text -match "course|training|education|bootcamp") {
        $category = "Education"
    }
    elseif ($text -match "subscription|monthly|per month|pricing") {
        $category = "Subscription / SaaS"
    }
    elseif ($text -match "software|developer|API|AI-powered|tool") {
        $category = "Software / AI"
    }
    elseif ($text -match "product|shop|store|shipping") {
        $category = "Physical / E-commerce"
    }

    $pricing = "Unknown"

    if ($text -match "pricing|price|free trial|start for free|free") {
        $pricing = "Pricing signal detected"
    }

    $results += [PSCustomObject]@{
        name = $page.name
        url = $page.url
        category = $category
        pricing_signal = $pricing
        content_length = $page.content_length
    }
}

$results |
    ConvertTo-Json -Depth 5 |
    Set-Content -Encoding UTF8 analyzed_businesses.json

$results |
    Format-Table name,category,pricing_signal -AutoSize
