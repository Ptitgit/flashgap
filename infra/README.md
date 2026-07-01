# Infra Flashgap V0

Hébergement **tout sur VPS** (région **EU**), ~20 Go disque — voir [cadrage](../docs/cadrage-flashgap-like.md) Q6/Q7.

## Hébergeur (à confirmer en prod)

| Fournisseur | Région EU | Notes V0 |
| --- | --- | --- |
| **Hetzner** (défaut doc) | `eu-central` (Falkenstein/Nuremberg) | CX22 ou équivalent, ≥ 20 Go |
| Scaleway | `fr-par` / `nl-ams` | DEV1-S |
| OVHcloud | `GRA` / `SBG` | VPS Essential |

Créer une instance **Ubuntu 24.04 LTS**, clé SSH root au provisionnement.

## Inventaire (remplir après provision)

| Champ | Valeur |
| --- | --- |
| **Hébergeur** | _ex. Hetzner_ |
| **Région** | _ex. eu-central_ |
| **Hostname public** | _ex. api.flashgap.example_ |
| **IP publique** | _ex. 203.0.113.50_ |
| **DNS** | _A/AAAA vers IP publique (optionnel V0)_ |

Copier `host.env.example` → `host.env` et renseigner les valeurs réelles.

## Provisionnement (E1-US1)

### 1. Créer le VPS

- OS : **Ubuntu 24.04 LTS**
- Disque : **≥ 20 Go**
- Région : **EU**
- Associer votre clé SSH publique à l’utilisateur `root` (console hébergeur)

### 2. Bootstrap sur le serveur

Depuis votre machine (remplacer l’IP et la clé) :

```bash
export FLASHGAP_DEPLOY_SSH_PUBKEY="$(cat ~/.ssh/id_ed25519.pub)"
export FLASHGAP_SSH_RESTRICT_IP="<votre-ip-fixe-ou-vpn>"
ssh root@<ip-publique> 'bash -s' < infra/scripts/provision-vps.sh
# (équivalent Docker e2e : docker exec -i … bash -s < infra/scripts/provision-vps.sh)
```

Le script :

- met à jour le système (`unattended-upgrades` installé) ;
- crée l’utilisateur **`deploy`** (non-root) avec sudo limité (docker, ufw) ;
- impose **SSH par clé** (`PasswordAuthentication no`) ;
- configure **UFW** : 80/443 ouverts, 22 restreint à `FLASHGAP_SSH_RESTRICT_IP`.

### 3. Smoke test

```bash
cp infra/host.env.example infra/host.env
# éditer host.env

infra/scripts/smoke-vps-provision.sh
```

## Tests (TDD)

```bash
infra/tests/run-tests.sh
```

- **Unitaires** : `infra/tests/unit/checks.test.sh` (sans VPS)
- **E2E Docker** : valide `provision-vps.sh` dans Ubuntu 24.04 (`FLASHGAP_PROVISION_SKIP_UPGRADE=1` — pas de `apt upgrade`, réservé au test local)
- **Smoke distant** : nécessite `infra/host.env` et un VPS provisionné (avec upgrade complet, sans `SKIP_UPGRADE`)

## Docker Compose (E1-US2)

Stack **Postgres + MinIO + API** (`infra/docker-compose.yml`). Postgres et MinIO restent sur le réseau Docker interne.

**Prod VPS** (défaut) : overlay `docker-compose.nginx-vps.yml` — API sur `127.0.0.1:3010`, **nginx** sur l’hôte termine TLS (80/443).

**Dev local avec TLS** (optionnel) : ajouter `docker-compose.caddy.yml` (Caddy sur 80/443, certificats internes en local).

```bash
cp infra/.env.example infra/.env
# éditer les mots de passe si besoin

cd infra
# Dev local HTTPS :
docker compose -f docker-compose.yml -f docker-compose.caddy.yml --env-file .env up -d --build
curl -kfsS --resolve "localhost:${HTTPS_PORT:-443}:127.0.0.1" \
  "https://localhost:${HTTPS_PORT:-443}/health"
```

Smoke versionné (Caddy overlay) :

```bash
infra/scripts/smoke-compose-stack.sh
```

API (Fastify) : `services/api` — `npm test`, `npm run lint`, `npm run typecheck`.

## MinIO bucket privé (E1-US3)

Au démarrage, le service **`minio-init`** crée le bucket `${MINIO_BUCKET}` (défaut `flashgap-photos`) et applique une politique **deny** sur l’accès anonyme (`mc anonymous set none`). Les credentials restent dans `.env` ; la console MinIO (port 9001) n’est **pas** publiée sur l’hôte.

Variables ajoutées dans `.env.example` :

- `MINIO_BUCKET` — nom du bucket S3-compatible (prépare la migration Scaleway V2)

Vérification :

```bash
infra/tests/unit/minio-bucket.test.sh
infra/tests/e2e/minio-bucket-private.sh   # nécessite Docker
```

## HTTPS — nginx (prod) / Caddy (dev optionnel)

### Prod VPS (défaut)

**nginx** sur l’hôte (déjà en place sur otrom.fr) reverse-proxy vers l’API Docker (`127.0.0.1:3010`).

1. Déployer : `./scripts/deploy.sh`
2. Inclure le snippet `infra/scripts/nginx-flashgap.conf` dans le vhost HTTPS existant
3. URL API : `https://otrom.fr/flashgap/` (ex. `/flashgap/health`)

Variables utiles (`.env`) :

- `FLASHGAP_API_HOST_PORT` — port hôte (défaut `3010`, évite 3000–3002 PM2)

### Dev local — Caddy (optionnel)

Overlay `docker-compose.caddy.yml` : TLS local (`tls internal`) ou Let's Encrypt si `PUBLIC_HOSTNAME` + `ACME_EMAIL` sont renseignés.

Variables (`.env.example`) :

- `PUBLIC_HOSTNAME` — `localhost` (dev) ou FQDN (VPS dédié avec `--with-caddy`)
- `ACME_EMAIL` — contact Let's Encrypt
- `HTTP_PORT` / `HTTPS_PORT` — mapping hôte (défaut 80/443)

Vérification :

```bash
infra/tests/unit/nginx-vps.test.sh
infra/tests/unit/caddy-reverse-proxy.test.sh   # overlay Caddy
infra/tests/e2e/https-reverse-proxy.sh       # nécessite Docker
```

## Déploiement (E1-US5)

### Premier déploiement (VPS)

Sur le serveur, en tant que **`deploy`** (après [provisionnement](#provisionnement-e1-us1)) :

```bash
git clone https://github.com/Ptitgit/flashgap.git
cd flashgap/infra
cp .env.example .env
# éditer .env : mots de passe, FLASHGAP_API_HOST_PORT si besoin

./scripts/deploy.sh --skip-git-pull
```

Puis **nginx** (root) : copier `scripts/nginx-flashgap.conf` dans `/etc/nginx/snippets/` et l’inclure dans le vhost HTTPS (voir commentaires dans le fichier).

Vérifier : `curl -fsS "https://otrom.fr/flashgap/health"`

### Redéploiement (après changement de code)

Depuis `flashgap/infra` sur le VPS :

```bash
git pull
./scripts/deploy.sh --skip-git-pull
```

Équivalent manuel :

```bash
docker compose -f docker-compose.yml -f docker-compose.nginx-vps.yml --env-file .env up -d --build
```

### Logs API

```bash
cd infra
docker compose --env-file .env logs -f api
```

Smoke local (stack déjà up) : `infra/scripts/smoke-compose-stack.sh`.

## Webhook GitHub — déploiement auto (E1-US6)

Déclenche `git pull` + `deploy.sh` à chaque **push sur `main`** (ex. après merge d'une PR).

### 1. Secret et service sur le VPS

Dans `infra/.env` :

```bash
FLASHGAP_GITHUB_WEBHOOK_SECRET=<secret-long-aleatoire>
FLASHGAP_WEBHOOK_PORT=9876
```

Installer le listener (utilisateur `deploy`) :

```bash
sudo cp infra/systemd/flashgap-deploy-webhook.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now flashgap-deploy-webhook
```

### 2. nginx

Inclure `infra/scripts/nginx-flashgap-deploy-hook.conf` dans le vhost HTTPS (à côté du snippet API).

URL publique : `https://otrom.fr/flashgap-deploy-hook`

### 3. Webhook GitHub

Repo → **Settings → Webhooks → Add webhook** :

| Champ | Valeur |
| --- | --- |
| **Payload URL** | `https://otrom.fr/flashgap-deploy-hook` |
| **Content type** | `application/json` |
| **Secret** | même valeur que `FLASHGAP_GITHUB_WEBHOOK_SECRET` |
| **Events** | *Just the push event* |

Seuls les push vers `refs/heads/main` lancent le deploy (`flock` évite les déploiements concurrents).

> **Prod** : webhook actif sur `https://otrom.fr/flashgap-deploy-hook` (vérifié 2026-07-01).

Test local (sans VPS) :

```bash
infra/tests/unit/github-webhook.test.sh
infra/tests/e2e/github-deploy-webhook.sh
```

Variables (`.env.example`) :

- `FLASHGAP_GITHUB_WEBHOOK_SECRET` — secret partagé avec GitHub
- `FLASHGAP_WEBHOOK_PORT` — port local du listener (défaut `9876`)

## Epic suivant

[E2 — Backend albums & membres](../roadmap/e2-backend-albums-membres/README.md)
