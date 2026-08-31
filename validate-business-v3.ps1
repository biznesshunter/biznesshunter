$items = Get-Content .\validation_queue.json -Raw | ConvertFrom-Json

foreach ($item in $items) {

    try {
        $response = Invoke-WebRequest -Uri $item.url -UseBasicParsing -TimeoutSec 15

        $item | Add-Member -NotePropertyName "url_accessible" -NotePropertyValue $true -Force
        $item | Add-Member -NotePropertyName "http_status" -NotePropertyValue ([int]$response.StatusCode) -Force
        $item | Add-Member -NotePropertyName "page_title" -NotePropertyValue $response.BaseResponse.ResponseUri.AbsoluteUri -Force

        Write-Host "OK  $($item.name)"
    }
    catch {
        $item | Add-Member -NotePropertyName "url_accessible" -NotePropertyValue $false -Force
        $item | Add-Member -NotePropertyName "http_status" -NotePropertyValue $null -Force
        $item | Add-Member -NotePropertyName "page_title" -NotePropertyValue $null -Force

        Write-Host "ERR $($item.name)"
    }
}

$items |
    ConvertTo-Json -Depth 10 |
    Set-Content .\validation_queue.json -Encoding UTF8

$items |
    Select-Object name,url_accessible,http_status,page_title |
    Format-Table -AutoSize
