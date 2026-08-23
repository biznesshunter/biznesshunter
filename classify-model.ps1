$items = Get-Content .\business_candidates.json -Raw | ConvertFrom-Json

$results = foreach ($item in $items) {

    $text = $item.name.ToLower()

    $category = "Other"

    if ($text -match "rental|rent|share|pool|space") {
        $category = "Rental / Sharing"
    }
    elseif ($text -match "marketplace|platform") {
        $category = "Marketplace"
    }
    elseif ($text -match "service|agency|consult") {
        $category = "Service"
    }
    elseif ($text -match "store|shop|commerce|product") {
        $category = "E-commerce / Product"
    }
    elseif ($text -match "subscription|membership") {
        $category = "Subscription"
    }
    elseif ($text -match "course|education|bootcamp|training") {
        $category = "Education"
    }
    elseif ($text -match "saas|software|tool|app|ai") {
        $category = "Software / AI"
    }

    [PSCustomObject]@{
        name = $item.name
        url = $item.url
        source = $item.source
        category = $category
        business_score = $item.business_score
    }
}

$results |
    ConvertTo-Json -Depth 5 |
    Set-Content -Encoding UTF8 classified_businesses.json

$results |
    Format-Table name,category,business_score -AutoSize
