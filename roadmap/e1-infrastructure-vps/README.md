# E1 — Infrastructure & déploiement VPS

## Objectif

Environnement EU prêt à recevoir l'API, Postgres et MinIO, accessible en HTTPS.

## Dépendances

Aucune

## Definition of done (epic)

`curl https://<host>/flashgap/health` OK (nginx sur VPS partagé) ou `curl https://<host>/health` (Caddy en dev / VPS dédié) ; Postgres et MinIO joignables depuis le conteneur API.

## Tâches

- [E1-US1 — Provisionner le VPS (région EU)](./E1-US1-provisionner-vps.md)
- [E1-US2 — Docker Compose (Postgres, MinIO, API)](./E1-US2-docker-compose.md)
- [E1-US3 — MinIO — bucket privé](./E1-US3-minio-bucket-prive.md)
- [E1-US4 — HTTPS via reverse proxy](./E1-US4-https-reverse-proxy.md)
- [E1-US5 — Script et doc de déploiement](./E1-US5-script-deploiement.md)
- [E1-US6 — Webhook GitHub pour déploiement auto](./E1-US6-webhook-deploy-github.md)

## Quality gates (TDD, linter, non-régression)

Chaque tâche de cet epic impose :

| Gate | Commande / règle |
| --- | --- |
| **Linter** | `npm run lint` dans `services/api` si le code API existe ; sinon `shellcheck` sur les scripts shell et validation `docker compose config` |
| **Tests** | `npm test` dans `services/api` si présent ; sinon script smoke (`curl /health`, `docker compose ps`) versionné dans `scripts/` ou `infra/` |
| **TDD** | Test rouge → vert → refactor avant de marquer la tâche `done` |
| **Typage** | Pas de `any` ; `npm run typecheck` vert (si fichiers `.ts` touchés) |
| **Non-régression** | Suite complète verte ; ne pas supprimer de tests sans justification |

[Voir standards globaux](../README.md#standards-qualité-tdd-linter-typage-non-régression)

