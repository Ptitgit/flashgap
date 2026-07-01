# E1-US6 — Webhook GitHub pour déploiement auto

| Champ | Valeur |
| --- | --- |
| **Epic** | [E1 — Infrastructure & déploiement VPS](./README.md) |
| **Statut** | `done` |
| **Dépendances** | [E1-US5 — Script et doc de déploiement](./E1-US5-script-deploiement.md) |

## User story

En tant que **développeur**, je veux **un webhook GitHub sur push `main`** afin de **redéployer l'API automatiquement après merge**, sans SSH manuel depuis le VPS.

## Contexte

Cette tâche fait partie de la **V0 Flashgap**. Référence : [cadrage produit](../../docs/cadrage-flashgap-like.md).

Permet le flux : merge sur `main` → GitHub POST → nginx (`/flashgap-deploy-hook`) → listener local → `git pull` + `deploy.sh`.

## Approche TDD (obligatoire)

1. **Rouge** — Tests unitaires signature HMAC et filtre `refs/heads/main`.
2. **Vert** — Scripts `github-webhook.sh`, `github-deploy-hook.sh`, serveur Python stdlib, snippet nginx.
3. **Refactor** — shellcheck, doc README.

## Critères d'acceptation

- [x] Vérification `X-Hub-Signature-256` (secret dans `infra/.env`)
- [x] Déclenchement deploy uniquement sur `push` vers `refs/heads/main`
- [x] Listener local `127.0.0.1:9876` + snippet nginx `location = /flashgap-deploy-hook`
- [x] `flock` anti-concurrence sur le deploy
- [x] README : config webhook GitHub (URL, secret, event `push`)
- [x] **TDD** : tests unitaires `github-webhook.test.sh` rouge → vert
- [x] **Linter** : shellcheck sur scripts shell — **0 erreur, 0 warning**
- [x] **Non-régression** : `infra/tests/run-tests.sh` vert

## Notes techniques

- Secret : `FLASHGAP_GITHUB_WEBHOOK_SECRET` dans `infra/.env`
- URL publique : `https://otrom.fr/flashgap-deploy-hook`
- Service systemd exemple : `infra/systemd/flashgap-deploy-webhook.service`
- Le webhook appelle `deploy.sh --skip-git-pull` après `git pull --ff-only origin main`

## Anti-régression

- [x] Suite `infra/tests/run-tests.sh` complète
- [x] Tests E1-US5 (deploy) inchangés et verts

## Definition of done

- [x] Tous les critères d'acceptation cochés
- [x] Statut `done`
