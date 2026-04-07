#  Infrastructure Windows Server — ETI 250 personnes

Conception et déploiement d'une infrastructure Windows Server complète pour une ETI de 250 personnes.  
Projet de groupe réalisé à l'**IPSSI Lille** — Semaine du 02 au 06 février 2026.

**Équipe** : Zakari Ghout · Lukas Vachet · Fritzel ADJOVI · Mohamadou Lamine Nael · Tehei Chan

##  Objectifs

Répondre à 6 besoins critiques identifiés :

| Besoin | Solution | Technologie |
|--------|----------|-------------|
| Gestion des identités | Annuaire centralisé | Active Directory Domain Services |
| Attribution automatique d'IP | Serveur DHCP | DHCP Server |
| Résolution de noms | DNS intégré à AD | DNS Server |
| Gestion des mises à jour | Serveur centralisé | WSUS |
| Accès distant | Services Bureau à distance | Remote Desktop Services |
| Sauvegarde et continuité | Sauvegarde planifiée | VEEAM Backup |

##  Architecture

```
                    INTERNET / WAN
                         │
                 ┌───────┴───────┐
                 R1              R2
           192.168.10.252   192.168.10.253
                 └───────┬───────┘
                         │
                    ┌────▼────┐
                    │FIREWALL │
                    │  GW:    │
                    │.10.254  │
                    └────┬────┘
                         │
              ┌──────────┼──────────┐
              │          │          │
         ┌────▼────┐ ┌───▼───┐ ┌───▼────┐
         │ SRV-DC01│ │SRV-HA │ │SRV-DATA│
         │ .10.10  │ │ .10.11│ │ .10.20 │
         │ AD DS   │ │ AD DS │ │  WSUS  │
         │ DNS     │ │ DNS   │ │  VEEAM │
         │ DHCP    │ │ DHCP  │ └────────┘
         └─────────┘ └───────┘
```

## 📋 Plan d'adressage IP

| Élément | Adresse IP | Rôle |
|---------|------------|------|
| Réseau | 192.168.10.0/24 | Réseau principal |
| Passerelle / Firewall | 192.168.10.254 | Routeur/Pare-feu |
| SRV-DC01 | 192.168.10.10 | Contrôleur de domaine principal |
| SRV-HA | 192.168.10.11 | Contrôleur de domaine secondaire |
| SRV-DATA | 192.168.10.20 | WSUS, Fichiers, VEEAM, RDS |
| S1 | 192.168.10.31 | Serveur de stockage |
| S2 | 192.168.10.32 | Serveur de stockage |
| S3 | 192.168.10.33 | Serveur de stockage |
| Plage DHCP clients | 192.168.10.51 – 253 | Postes utilisateurs |

##  Configuration déployée

### Active Directory (SRV-DC01)
- Domaine : `entreprise.local`
- 3 Unités Organisationnelles : `Utilisateurs`, `Groupes`, `Ordinateurs`
- 3 Groupes : `Direction`, `Commercial`, `Support-IT`
- 25+ utilisateurs créés via script PowerShell

### DHCP (SRV-DC01)
- Plage : 192.168.10.51 – 192.168.10.253
- Durée du bail : 8 jours
- Distribution DNS + passerelle automatique

### WSUS (SRV-DATA)
- GPO configurée pour pointer les postes vers WSUS
- Groupes : Pilote, Production
- Approbation manuelle avant déploiement

### VEEAM Backup
- Sauvegarde quotidienne planifiée
- System State + données critiques
- Test de restauration validé 

##  Script PowerShell — Création des utilisateurs

```powershell
# Créer les utilisateurs Active Directory
$users = @(
    @{Name="Geoffroy LELOGEAY"; Group="Direction"},
    @{Name="Sylvie MONROUN"; Group="Commercial"},
    @{Name="Fanny MOREGANT"; Group="Support-IT"}
    # ... 22 autres utilisateurs
)

foreach ($user in $users) {
    $firstName = $user.Name.Split(" ")[0]
    $lastName  = $user.Name.Split(" ")[1]
    $sam       = "$firstName.$lastName".ToLower()
    
    New-ADUser `
        -Name $user.Name `
        -GivenName $firstName `
        -Surname $lastName `
        -SamAccountName $sam `
        -UserPrincipalName "$sam@entreprise.local" `
        -Enabled $true `
        -AccountPassword (ConvertTo-SecureString "Azerty123!" -AsPlainText -Force)
    
    Add-ADGroupMember -Identity $user.Group -Members $sam
}

Write-Host "Utilisateurs créés avec succès !"
Get-ADUser -Filter * | Select-Object Name, Enabled
```

##  Estimation budgétaire

| Poste | Détail | Coût |
|-------|--------|------|
| Serveurs AD (Haute Dispo) | 2x serveurs physiques AD DS + DNS | 6 500 € |
| Serveur Infra | 1x serveur DHCP, WSUS, RDS | 3 200 € |
| Serveurs de Stockage | 3x NAS/SAN | 12 000 € |
| Licences OS | Windows Server 2025 Standard (6 serveurs) | 3 500 € |
| CALs Utilisateur | 250 User CALs | 12 500 € |
| CALs RDS | 50 RDS CALs | 7 500 € |
| **TOTAL** | | **~45 200 €** |

## 👨‍💻 Auteur

**Fritzel ADJOVI** — IPSSI Lille 2025/2026  
[LinkedIn](https://www.linkedin.com/in/fritzel-adjovi-a95203386) · [GitHub](https://github.com/fritzel-adjovi)
