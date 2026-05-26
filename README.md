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
├── docs/
│   └── main.pdf
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
- (CI/CD) GitHub Actions runner token (si configuration automatique souhaitée)

## 6.1) Accès administrateur — VPN uniquement
⚠️ **SSH sur port 22 n'est accessible QUE via VPN Point-to-Site (OpenVPN + Entra ID).**
- Aucune règle DNAT du firewall n'expose le SSH à Internet
- L'accès administrateur passe obligatoirement par le tunnel VPN
- Depuis la VM, toutes les communications sortantes passent par le firewall (filtrage Azure Firewall)

## 6.2) Déploiement applicatif
La VM déploie automatiquement lors du premier démarrage (cloud-init):
- **OWASP Juice Shop** (Docker) sur port local `127.0.0.1:3000` (localhost uniquement), exposé via Nginx → App Gateway.
  - Source unique de vérité: `cloud-init` (lors du déploiement Terraform).
  - Workflow GitHub Actions (`.github/workflows/deploy.yml`) redéploie le container sur le runner self-hosted (le workflow a été corrigé pour effectuer proprement le pull, le run et le health-check).
  - **GitHub Actions Runner** (optionnel) — installé par le `cloud-init` **seulement si** `runner_token` est fourni; sinon l'installation est ignorée et le runner n'est pas configuré.

**⚠️ Important**: Juice Shop n'est jamais directement accessible depuis Internet. L'accès passe obligatoirement par:
1. App Gateway (pour les utilisateurs publics via Firewall)
2. Nginx reverse proxy (pour les requêtes locales)

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
- runner_url (default: github.com/Aym3nGharbi/pfa-infrastructure)
- runner_token (sensitive, optionnel - pour auto-configuration du runner)
- vpn_client_address_pool (default: 172.16.0.0/24 - plage VPN P2S)
- appgateway_domain_name (default: appgw.pfa.local - DNS pour certificat TLS)
- appgateway_pfx_path (optionnel - chemin vers certificat PFX personnalisé)
- appgateway_pfx_password (sensitive, optionnel - mot de passe du PFX)
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

# Configuration VPN P2S et domaine
vpn_client_address_pool = "172.16.0.0/24"
appgateway_domain_name  = "appgw.pfa.local"

tags = {
  project     = "pfa"
  environment = "dev"
  managed_by  = "terraform"
}
```

### Configuration HTTPS (optionnel)
Pour activer HTTPS avec un certificat TLS sur Application Gateway:

- Option simple (local PFX): générez un PFX et fournissez `appgateway_pfx_path` + `appgateway_pfx_password` dans `terraform.tfvars`. L'`Application Gateway` acceptera alors le PFX localement.
- Option recommandée (conforme au rapport): fournissez `appgateway_pfx_path` et `appgateway_pfx_password` dans `terraform.tfvars`; durant l'exécution, le module `keyvault` importera automatiquement le PFX dans le `Key Vault` (secret Base64). L'`Application Gateway` utilisera prioritairement le secret Key Vault si disponible, sinon tombera en back‑up sur le PFX local.

Exemple (générer un PFX auto-signé et l'utiliser pour la présentation) :

```powershell
.\scripts\gen_appgw_pfx.ps1 -DnsName "appgw.pfa.local"

# Puis dans terraform.tfvars:
appgateway_pfx_path     = "path/to/certificate.pfx"
appgateway_pfx_password = "votre-mot-de-passe-pfx"
```

Ne jamais versionner de secret en clair.
Exporter le mot de passe admin avant l'`apply` :

```powershell
$env:TF_VAR_admin_password="VotreMotDePasseFort!"
```

Remarque : si `appgateway_pfx_path` n'est pas fourni, l'`Application Gateway` restera en HTTP (configuration par défaut pour présentation locale).

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
- Commiter `.terraform.lock.hcl`:
  - ce fichier verrouille les versions exactes des providers
  - il garantit des plans/apply reproductibles entre machines et CI
- Garder un `.gitignore` propre
- Revue avant push (`git status`, `git diff`)

## 15) Auteurs
- Projet PFA - Infrastructure Azure Terraform
- Mainteneur repository: Aym3nGharbi

## 16) Rapport principal (PDF)
Le rapport principal du projet est versionné ici:
- `docs/main.pdf`

Utilisation recommandée:
- Considérer `docs/main.pdf` comme la référence documentaire fonctionnelle du projet
- Garder le `README.md` comme référence technique exécutable (déploiement, exploitation, troubleshooting)
- Mettre à jour les deux (README + PDF) à chaque évolution importante de l'architecture

## 17) Sommaire du rapport principal (alignement avec `main.pdf`)
Le PDF principal est structuré comme suit:
- Introduction générale
- Chapitre 1: Fondations théoriques et objectifs du projet
- Chapitre 2: Conception de l'architecture et structure Terraform
- Chapitre 3: Déploiement, orchestration et mise en production
- Chapitre 4: Sécurité opérationnelle: Firewall et observabilité
- Chapitre 5: Tests d'attaque: manuel et automatisé
- Conclusion générale
- Bibliographie
- Appendices

Sous-thèmes clés explicitement présents dans le rapport:
- Contexte, motivation, contraintes et objectifs
- Comparaison architecture initiale vs architecture finale
- Justification des couches de sécurité (WAF, Firewall, NSG)
- Preuves de déploiement Terraform et CI/CD
- Domaine, DNS et certificat TLS
- Validation opérationnelle et monitoring
- Scénarios de tests offensifs manuels (XSS, SQLi)
- Scénarios automatisés (scan, SQLi, fuzzing)

## 18) Correspondance rapport ↔ implémentation
Pour faciliter la lecture du code en parallèle du rapport:
- Chapitre 2 (architecture/structure Terraform):
  - `main.tf`
  - `modules/networking/`
  - `modules/firewall/`
  - `modules/appgateway/`
  - `modules/vpn/`
  - `modules/vm/`
  - `modules/cosmosdb/`
  - `modules/keyvault/`
- Chapitre 3 (déploiement/CI-CD/TLS):
  - `.github/workflows/deploy.yml` (pipeline auto-hébergé pour redéployer Juice Shop)
  - `scripts/install_github_runner.sh` (installation runner GitHub)
  - `scripts/gen_appgw_pfx.ps1` (génération certificat TLS auto-signé, paramétrable avec `-DnsName`)
  - variables TLS dans `variables.tf`: `appgateway_pfx_path`, `appgateway_pfx_password`, `appgateway_domain_name`
- Chapitre 4 (sécurité opérationnelle et observabilité):
  - règles firewall dans `modules/firewall/main.tf`
  - règles NSG et routage dans `modules/networking/main.tf`
- Chapitre 5 (tests offensifs):
  - résultats et preuves consolidés dans `docs/main.pdf`
