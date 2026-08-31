$registry = @(
    @{
        category = "location_shampouineuse"
        sources = @(
            "allovoisins"
            "bricolib"
            "poppins"
        )
    }

    @{
        category = "location_nettoyeur_vapeur"
        sources = @(
            "allovoisins"
            "bricolib"
        )
    }

    @{
        category = "location_remorque"
        sources = @(
            "allovoisins"
            "bricolib"
        )
    }

    @{
        category = "location_nettoyeur_haute_pression"
        sources = @(
            "allovoisins"
            "bricolib"
        )
    }

    @{
        category = "location_debroussailleuse"
        sources = @(
            "allovoisins"
            "bricolib"
        )
    }

    @{
        category = "location_scarificateur"
        sources = @(
            "allovoisins"
            "bricolib"
        )
    }

    @{
        category = "location_taille_haie"
        sources = @(
            "allovoisins"
            "bricolib"
        )
    }

    @{
        category = "location_fendeuse_bois"
        sources = @(
            "allovoisins"
            "bricolib"
        )
    }

    @{
        category = "location_tente_reception"
        sources = @(
            "allovoisins"
            "bricolib"
        )
    }

    @{
        category = "garde_chat"
        sources = @(
            "rover"
            "pawshake"
            "animalin"
        )
    }

    @{
        category = "menage_sortie_location"
        sources = @(
            "wecasa"
            "allovoisins"
        )
    }

    @{
        category = "promenade_chien"
        sources = @(
            "rover"
            "pawshake"
            "allovoisins"
        )
    }
)

$registry |
    ConvertTo-Json -Depth 10 |
    Set-Content .\radar49_source_registry.json -Encoding UTF8

Write-Host "CATEGORIES :" @($registry).Count
Write-Host "OUTPUT     : radar49_source_registry.json"
