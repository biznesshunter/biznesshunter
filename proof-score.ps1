$data = Get-Content .\evidence-test.json -Raw | ConvertFrom-Json

$proof = 0

foreach ($e in $data.evidence) {
    $proof += $e.quality
}

$proof = [Math]::Min($proof, 30)

[PSCustomObject]@{
    Business = $data.name
    Proof = $proof
    EvidenceCount = $data.evidence.Count
}
