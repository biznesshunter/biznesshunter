$inputFile = ".\radar17_concrete_business_ideas.json"
$outputFile = ".\radar18_concrete_business_ideas.json"

$data = ConvertFrom-Json -InputObject (Get-Content $inputFile -Raw)
$data = @($data)

Write-Host ""
Write-Host "========================================"
Write-Host " BiznessHunter - Radar 18"
Write-Host " CONCRETE BUSINESS IDEAS"
Write-Host "========================================"
Write-Host ""

Write-Host "Input ideas :" $data.Count

$result = @(
    foreach ($item in $data) {
        [PSCustomObject]@{
            concept_score      = $item.concept_score
            verdict            = $item.verdict
            action             = $item.action
            idea_name          = $item.idea_name
            target_customer    = $item.target_customer
            problem            = $item.problem
            buying_trigger     = $item.buying_trigger
            concrete_offer     = $item.concrete_offer
            business_mechanism = $item.business_mechanism
            monetization      = $item.monetization
            differentiation   = $item.differentiation
            mvp                = $item.mvp
            acquisition        = $item.acquisition
            geographic_angle  = $item.geographic_angle
            specificity_score = $item.specificity_score
            geographic_score  = $item.geographic_score
            market_proof      = $item.market_proof
            replication       = $item.replication
            competition       = $item.competition
            company_count     = $item.company_count
            article_count     = $item.article_count
            country_count     = $item.country_count
            evidence          = $item.evidence
            source_opportunity = $item.source_opportunity
        }
    }
)

$result | ConvertTo-Json -Depth 10 | Set-Content $outputFile -Encoding UTF8

Write-Host "Output ideas :" @($result).Count
Write-Host ""
Write-Host "Output :" $outputFile
