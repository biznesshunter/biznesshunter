$items = Get-Content .\business_candidates.json -Raw | ConvertFrom-Json

$items | Select-Object -First 3 | ForEach-Object {

    Write-Host ""
    Write-Host "=========================================="
    Write-Host $_.name
    Write-Host $_.url
    Write-Host "=========================================="

    if (-not $_.url) {
        Write-Warning "Pas d'URL"
        return
    }

    try {
        $page = Invoke-WebRequest `
            -UseBasicParsing `
            -Uri $_.url `
            -TimeoutSec 20

        Write-Host "OK - contenu récupéré : $($page.Content.Length) caractères"
    }
    catch {
        Write-Warning "Échec : $($_.Exception.Message)"
    }
}
