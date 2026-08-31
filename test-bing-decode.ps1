$u = "a1aHR0cHM6Ly93ZWIud2VjaGF0LmNvbS8_bGFuZz16aF9UVw"

$encoded = $u.Substring(2)
$encoded = $encoded.Replace("-", "+").Replace("_", "/")
$encoded += "=" * ((4 - ($encoded.Length % 4)) % 4)

$decoded = [System.Text.Encoding]::UTF8.GetString(
    [Convert]::FromBase64String($encoded)
)

Write-Host ""
Write-Host "DESTINATION:" -ForegroundColor Green
Write-Host $decoded
