$x = Get-Content .\radar38_business_library.json -Raw | ConvertFrom-Json
$o = @()
foreach ($i in @($x)) {
if ([string]::IsNullOrWhiteSpace($i.business_name)) { continue }
$n = [string]$i.business_name
if ($n.Length -lt 15) { continue }
if ($n -match '^(Service|Location|Marketplace|Logiciel|Garde|Promenade|Livraison) (IA|de|pour|locale|spécialisé|spécialisée|à domicile|de matériel|de véhicules|de chiens|de courses|d outils)') { continue }
$o += [PSCustomObject]@{
idea_name = $n
source_count = [int]$i.source_count
best_source_score = [int]$i.best_source_score
}
}
$o = $o | Sort-Object source_count -Descending | Select-Object -Unique idea_name
$o | ConvertTo-Json -Depth 5 | Set-Content .\radar39_business_library.json -Encoding UTF8
Write-Host "IDEAS :" @($o).Count
Write-Host "OUTPUT: radar39_business_library.json"
$o | Select-Object -First 50 | Format-Table -AutoSize
