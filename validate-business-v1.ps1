$items = Get-Content .\validation_queue.json -Raw | ConvertFrom-Json

foreach ($item in $items) {

    $text = (
        [string]$item.name + " " +
        [string]$item.url + " " +
        [string]$item.signals
    ).ToLower()

    $proof = @()

    # MONÉTISATION EXPLICITE
    if ($text -match '\$\d+|€\d+|pricing|subscription|paid|premium|buy|purchase|price') {
        $proof += "MONETIZATION"
    }

    # PLATEFORME COMMERCIALE
    if ($text -match 'apps.microsoft.com|play.google.com|apps.apple.com|gumroad.com|patreon.com') {
        $proof += "COMMERCIAL_PLATFORM"
    }

    # MARKETPLACE / VENTE
    if ($text -match 'marketplace|booking|rental|directory') {
        $proof += "TRANSACTION_MODEL"
    }

    # TRACTION MENTIONNÉE
    if ($text -match 'customers|customer|users|downloads|revenue|sales|sold|mrr|arr|funding|raised') {
        $proof += "TRACTION_MENTION"
    }

    # BUSINESS MODEL
    if ($text -match 'subscription|saas') {
        $item.business_model = "SUBSCRIPTION"
    }
    elseif ($text -match 'marketplace') {
        $item.business_model = "MARKETPLACE"
    }
    elseif ($text -match 'rental') {
        $item.business_model = "RENTAL"
    }
    elseif ($text -match 'booking') {
        $item.business_model = "BOOKING"
    }
    elseif ($text -match '\$\d+|€\d+|paid|pricing|premium') {
        $item.business_model = "PAID_PRODUCT"
    }
    elseif ($text -match 'free tool|free online tools') {
        $item.business_model = "FREE_TOOL"
    }
    else {
        $item.business_model = "UNKNOWN"
    }

    $item.commercial_proof = $proof

    if ($proof.Count -eq 0) {
        $item.commercial_proof_level = "NONE"
        $item.validation_status = "UNVALIDATED"
        $item.confidence = 0
    }
    elseif ($proof -contains "TRACTION_MENTION") {
        $item.commercial_proof_level = "TRACTION"
        $item.validation_status = "PARTIAL"
        $item.confidence = 60
    }
    elseif ($proof -contains "MONETIZATION" -or $proof -contains "COMMERCIAL_PLATFORM") {
        $item.commercial_proof_level = "MONETIZED"
        $item.validation_status = "PARTIAL"
        $item.confidence = 30
    }
    else {
        $item.commercial_proof_level = "WEAK"
        $item.validation_status = "PARTIAL"
        $item.confidence = 20
    }
}

$items |
    ConvertTo-Json -Depth 10 |
    Set-Content .\validation_queue.json -Encoding UTF8

$items |
    Select-Object name,business_model,commercial_proof,commercial_proof_level,validation_status,confidence |
    Format-Table -AutoSize
