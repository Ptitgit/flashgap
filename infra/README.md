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

## Prochaine tâche

[E1-US2 — Docker Compose](../roadmap/e1-infrastructure-vps/E1-US2-docker-compose.md)
