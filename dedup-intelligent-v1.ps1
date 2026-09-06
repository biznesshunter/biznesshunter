$data = Get-Content .\radar56_multicity_raw.json -Raw | ConvertFrom-Json

$deduped = $data |
    Group-Object { "$($_.idea_name)|$($_.country)|$($_.category)" } |
    ForEach-Object {

        $rows = $_.Group

        [PSCustomObject]@{
            idea_name = $rows[0].idea_name
            country = $rows[0].country
            category = $rows[0].category

            cities = @(
                $rows |
                Where-Object { $_.city } |
                Select-Object -ExpandProperty city -Unique
            )

            sources = @(
                $rows |
                Where-Object { $_.source } |
                Select-Object -ExpandProperty source -Unique
            )

            urls = @(
                $rows |
                Where-Object { $_.url } |
                Select-Object -ExpandProperty url -Unique
            )

            observation_count = $rows.Count

            statuses = @(
                $rows |
                Group-Object status |
                ForEach-Object {
                    [PSCustomObject]@{
                        status = $_.Name
                        count = $_.Count
                    }
                }
            )

            ready_count = @(
                $rows | Where-Object { $_.http_status -eq 200 -and $_.final_url -match "^https?://" }
            ).Count

            unsupported_count = @(
                $rows | Where-Object { $_.http_status -ne 200 }
            ).Count
        }
    }

$deduped |
    ConvertTo-Json -Depth 10 |
    Set-Content .\radar53_deduped.json -Encoding UTF8

Write-Host "Observations initiales : $($data.Count)"
Write-Host "Opportunités uniques : $($deduped.Count)"
Write-Host "Fichier créé : radar53_deduped.json"


