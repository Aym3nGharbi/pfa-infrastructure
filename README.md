# PFA Infrastructure Azure (Terraform)

## 1) Objectif du projet
Ce projet provisionne une infrastructure Azure sécurisée et modulaire pour un PFA, avec Terraform.

Le déploiement inclut:
- Un réseau segmenté (subnets dédiés)
- Une VM applicative Ubuntu
- Un Application Gateway WAF v2 en frontal
- Un Azure Firewall Standard pour filtrage et DNAT
- Un accès administrateur VPN Point-to-Site (OpenVPN + Microsoft Entra ID)
- Un Azure Cosmos DB privé (accès réseau restreint)
- Un Azure Key Vault avec policy d'accès VM
- Un pipeline GitHub Actions (self-hosted runner) pour déployer OWASP Juice Shop

## 2) Stack technique
- Infrastructure as Code: Terraform >= 1.0
- Provider: hashicorp/azurerm (~> 3.0)
- Cloud: Microsoft Azure
- VM OS: Ubuntu
- Reverse proxy: Nginx
- Application de démo: OWASP Juice Shop (Docker)
- CI/CD: GitHub Actions (runner auto-hébergé)

## 3) Architecture (vue logique)

```text
Internet
  |
  +--> Azure Firewall Public IP (DNAT 80/443 -> App Gateway private IP)
  |          |
  |          +--> Application Gateway WAF v2 (public + private frontend)
  |                        |
  |                        +--> VM subnet (10.0.3.0/24) -> OWASP Juice Shop:3000
  |
  +--> (admin) VPN P2S OpenVPN/Entra ID -> GatewaySubnet -> accès SSH VM (22)

Data subnet (10.0.4.0/24)
  +--> Azure Cosmos DB (public disabled, VNet filter enabled)

Key Vault
  +--> policy "Get/List" pour l'identité managée de la VM
```

## 4) Structure du repository

```text
.
├── .github/workflows/
│   └── deploy.yml
├── modules/
│   ├── appgateway/
│   ├── cosmosdb/
│   ├── firewall/
│   ├── keyvault/
│   ├── networking/
│   ├── vm/
│   └── vpn/
├── scripts/
│   ├── gen_appgw_pfx.ps1
│   └── install_github_runner.sh
├── main.tf
├── variables.tf
├── outputs.tf
└── terraform.tfvars
```

## 5) Modules Terraform
- networking: VNet, subnets, NSG, route table web
- firewall: Azure Firewall Standard, NAT rules, network/app rules
- vpn: Virtual Network Gateway (VpnGw1), P2S OpenVPN + Entra ID
- vm: Linux VM, cloud-init (Docker/Nginx), identité managée
- appgateway: WAF policy + App Gateway WAF v2 + backend VM
- cosmosdb: compte Cosmos DB avec accès réseau privé/VNet
- keyvault: Key Vault + access policy VM

## 6) Prérequis
- Terraform installé
- Azure CLI installé et connecté
- Droits suffisants sur la subscription Azure
- (Optionnel HTTPS App Gateway) fichier PFX + mot de passe
- (CI/CD) machine VM configurée avec Docker et GitHub runner

## 7) Variables principales
Variables définies dans `variables.tf`:
- subscription_id (sensitive)
- prefix (default: pfa)
- location (default: francecentral)
- zone (default: 3)
- vm_size (default: Standard_B2als_v2)
- admin_username (default: azureuser)
- admin_password (sensitive, obligatoire)
- app_port (default: 3000)
- appgateway_pfx_path (optionnel)
- appgateway_pfx_password (sensitive, optionnel)
- tags (map)

## 8) Configuration locale recommandée
Exemple minimal dans `terraform.tfvars`:

```hcl
subscription_id = "<azure-subscription-id>"
prefix          = "pfa"
location        = "francecentral"
zone            = "3"

admin_username = "azureuser"
vm_size        = "Standard_B2als_v2"
app_port       = 3000

tags = {
  project     = "pfa"
  environment = "dev"
  managed_by  = "terraform"
}
```

Ne jamais versionner de secret en clair.
Exporter le mot de passe admin avant l'apply:

```powershell
$env:TF_VAR_admin_password="VotreMotDePasseFort!"
```

## 9) Déploiement Terraform
Depuis la racine du projet:

```powershell
terraform init
terraform validate
terraform plan -out tfplan
terraform apply -auto-approve
```

Sorties utiles (`outputs.tf`):
- resource_group_name
- vm_private_ip
- vm_name
- appgateway_public_ip
- vpn_public_ip
- cosmosdb_endpoint
- keyvault_uri

## 10) Destruction (optimisation coûts)

```powershell
terraform destroy -auto-approve -var "admin_password=<temp-value>"
```

Pourquoi `-var` ici: `admin_password` est une variable obligatoire du root module, même pour destroy.

## 11) CI/CD GitHub Actions
Workflow: `.github/workflows/deploy.yml`

Déclencheurs:
- push sur `main`
- `workflow_dispatch`

Comportement:
- pull image `bkimminich/juice-shop:latest`
- recréation container `juice-shop`
- publication locale `3000:3000`
- health check via `curl http://127.0.0.1:3000`

Pré-requis runner:
- runner GitHub enregistré sur la VM
- Docker opérationnel

## 12) Sécurité implémentée
- Segmentation réseau par subnets dédiés
- NSG stricts (deny-all inbound en fin de règles)
- Accès SSH autorisé uniquement depuis plage VPN P2S
- WAF en mode Prevention (OWASP + BotManager + règles custom)
- DNAT contrôlé au niveau Azure Firewall
- Route web subnet vers firewall
- Cosmos DB avec `public_network_access_enabled = false`
- Key Vault avec purge protection activée

## 13) Dépannage rapide
- Erreur `No value for required variable admin_password`
  - Fournir `TF_VAR_admin_password` ou `-var` sur la commande
- Backend App Gateway unhealthy
  - Vérifier NSG web subnet, port app (3000), container Docker up
- VPN non connectable après recréation infra
  - Regénérer et réimporter le package VPN client
- SSH host key mismatch après destroy/recreate
  - Nettoyer `known_hosts` local

## 14) Bonnes pratiques Git
- Ne pas committer:
  - `.terraform/`
  - `terraform.tfstate*`
  - `tfplan`
  - certificats/pfx temporaires
- Garder un `.gitignore` propre
- Revue avant push (`git status`, `git diff`)

## 15) Auteurs
- Projet PFA - Infrastructure Azure Terraform
- Mainteneur repository: Aym3nGharbi
