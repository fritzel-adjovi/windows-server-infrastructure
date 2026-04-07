# ============================================
# Script : create_ad_users.ps1
# Auteur : Fritzel ADJOVI — IPSSI Lille
# Description : Création des utilisateurs AD
#   pour l'infrastructure ETI 250 personnes
# ============================================

# Vérifier que le module AD est disponible
Import-Module ActiveDirectory -ErrorAction Stop

# Domaine cible
$domain = "entreprise.local"
$ouPath = "OU=Utilisateurs,DC=entreprise,DC=local"
$defaultPassword = ConvertTo-SecureString "Azerty123!" -AsPlainText -Force

# Liste des utilisateurs à créer
$users = @(
    @{ Name="Geoffroy LELOGEAY";  Group="Direction"   },
    @{ Name="Sylvie MONROUN";     Group="Commercial"  },
    @{ Name="Fanny MOREGANT";     Group="Commercial"  },
    @{ Name="Christian VACHARD";  Group="Support-IT"  },
    @{ Name="Victor POUPARD";     Group="Direction"   },
    @{ Name="Rajanee COOPAN";     Group="Commercial"  },
    @{ Name="Franck GERVAIS";     Group="Support-IT"  },
    @{ Name="Alain BOUQUET";      Group="Direction"   },
    @{ Name="Claudy PERRAULT";    Group="Commercial"  },
    @{ Name="Anne VARAK";         Group="Support-IT"  },
    @{ Name="Francois MARINGER";  Group="Direction"   },
    @{ Name="Soyana TRIDANT";     Group="Commercial"  },
    @{ Name="Benjamin BARTHELEMY";Group="Support-IT"  },
    @{ Name="Nadjime YOUSSOUF";   Group="Commercial"  },
    @{ Name="Caroline LEFEVRE";   Group="Support-IT"  },
    @{ Name="Aurelien PIERY";     Group="Direction"   },
    @{ Name="Amandine PIERY";     Group="Commercial"  },
    @{ Name="Laurence BACCOUS";   Group="Support-IT"  },
    @{ Name="Benjamin TELLO";     Group="Commercial"  },
    @{ Name="Gervais KMAKARA";    Group="Support-IT"  },
    @{ Name="Emerick MONIN";      Group="Direction"   }
)

Write-Host "=== Création des utilisateurs Active Directory ===" -ForegroundColor Cyan
Write-Host "Domaine : $domain" -ForegroundColor Yellow
Write-Host ""

$created = 0
$errors  = 0

foreach ($user in $users) {
    $parts     = $user.Name -split " "
    $firstName = $parts[0]
    $lastName  = $parts[1]
    $sam       = "$firstName.$lastName".ToLower()
    $upn       = "$sam@$domain"

    try {
        # Vérifier si l'utilisateur existe déjà
        if (Get-ADUser -Filter {SamAccountName -eq $sam} -ErrorAction SilentlyContinue) {
            Write-Host "  [SKIP] $($user.Name) — existe déjà" -ForegroundColor Yellow
            continue
        }

        # Créer l'utilisateur
        New-ADUser `
            -Name            $user.Name `
            -GivenName       $firstName `
            -Surname         $lastName `
            -SamAccountName  $sam `
            -UserPrincipalName $upn `
            -Path            $ouPath `
            -Enabled         $true `
            -AccountPassword $defaultPassword `
            -ChangePasswordAtLogon $true

        # Ajouter au groupe
        Add-ADGroupMember -Identity $user.Group -Members $sam

        Write-Host "  [OK] $($user.Name) → Groupe: $($user.Group)" -ForegroundColor Green
        $created++
    }
    catch {
        Write-Host "  [ERR] $($user.Name) — $($_.Exception.Message)" -ForegroundColor Red
        $errors++
    }
}

Write-Host ""
Write-Host "=== Résultat ===" -ForegroundColor Cyan
Write-Host "Créés  : $created" -ForegroundColor Green
Write-Host "Erreurs: $errors"  -ForegroundColor Red
Write-Host ""

# Afficher la liste des utilisateurs créés
Write-Host "=== Liste des utilisateurs AD ===" -ForegroundColor Cyan
Get-ADUser -Filter * -SearchBase $ouPath | Select-Object Name, Enabled | Sort-Object Name | Format-Table -AutoSize
