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

Stack locale **Postgres + MinIO + API + Caddy** (`infra/docker-compose.yml`). Seuls les ports **80/443** (Caddy) sont publiés sur l’hôte ; l’API, Postgres et MinIO restent sur le réseau Docker interne.

```bash
cp infra/.env.example infra/.env
# éditer les mots de passe si besoin

cd infra
docker compose --env-file .env up -d --build
docker compose ps
curl -kfsS --resolve "localhost:${HTTPS_PORT:-443}:127.0.0.1" \
  "https://localhost:${HTTPS_PORT:-443}/health"
```

Smoke versionné :

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

## HTTPS via Caddy (E1-US4)

**Caddy** termine TLS et reverse-proxy vers `api:3000`. En local (`PUBLIC_HOSTNAME=localhost`), certificats **internes** (`tls internal`) ; en prod, renseigner le **domaine** et `ACME_EMAIL` pour Let's Encrypt automatique. HTTP redirige vers HTTPS.

Variables (`.env.example`) :

- `PUBLIC_HOSTNAME` — ex. `api.flashgap.example` (prod) ou `localhost` (dev)
- `ACME_EMAIL` — contact Let's Encrypt (prod)
- `HTTP_PORT` / `HTTPS_PORT` — mapping hôte (défaut 80/443)

Vérification :

```bash
infra/tests/unit/caddy-reverse-proxy.test.sh
infra/tests/e2e/https-reverse-proxy.sh   # nécessite Docker
```

Sur le VPS : DNS `A`/`AAAA` vers l’IP, ports 80/443 ouverts (UFW E1-US1), puis `PUBLIC_HOSTNAME` = FQDN réel dans `infra/.env`.

## Déploiement (E1-US5)

### Premier déploiement (VPS neuf)

Sur le serveur, en tant qu’utilisateur **`deploy`** (après [provisionnement](#provisionnement-e1-us1)) :

```bash
git clone https://github.com/Ptitgit/flashgap.git
cd flashgap/infra
cp .env.example .env
# éditer .env : mots de passe, PUBLIC_HOSTNAME (FQDN prod), ACME_EMAIL

docker compose --env-file .env up -d --build
docker compose ps
curl -fsS "https://${PUBLIC_HOSTNAME}/health"
```

Ou via le script versionné (depuis la racine du dépôt cloné) :

```bash
infra/scripts/deploy.sh
```

### Redéploiement (après changement de code)

```bash
cd flashgap
git pull
cd infra
docker compose --env-file .env up -d --build
```

Équivalent en une commande :

```bash
infra/scripts/deploy.sh
```

Le script exécute `git pull` à la racine du dépôt puis `docker compose up -d --build` dans `infra/`.

### Logs API

```bash
cd flashgap/infra
docker compose logs -f api
```

Ou :

```bash
infra/scripts/deploy.sh logs
infra/scripts/deploy.sh logs api
```

### Tests déploiement (TDD)

```bash
infra/tests/unit/deploy.test.sh
infra/scripts/deploy.sh --dry-run
infra/scripts/deploy.sh logs --dry-run
```

