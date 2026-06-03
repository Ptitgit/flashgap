# E3 — Backend — upload photos, reveal gate & quotas

## Objectif

Recevoir des JPEG HD, stockage privé MinIO, blocage avant `reveal_at`, URLs signées après reveal.

## Dépendances

E2

## Definition of done (epic)

Critères de sortie V0.2 : upload 5 Mo OK, gate avant reveal, URLs signées, quota 100/membre.

## Tâches

- [E3-US1 — Upload photo JPEG (multipart)](./E3-US1-upload-multipart.md)
- [E3-US2 — Écriture MinIO par album/membre](./E3-US2-stockage-minio.md)
- [E3-US3 — Quota 100 photos par membre](./E3-US3-quota-100-photos.md)
- [E3-US4 — Reveal gate (photos invisibles avant reveal)](./E3-US4-reveal-gate.md)
- [E3-US5 — Liste photos et URLs signées après reveal](./E3-US5-urls-signees.md)
- [E3-US6 — Rate limiting uploads](./E3-US6-rate-limiting.md)
- [E3-US7 — Observabilité (pino + métriques)](./E3-US7-observabilite-pino.md)
- [E3-US8 — Validation flux upload (curl / script)](./E3-US8-validation-curl-upload.md)

## Quality gates (TDD, linter, non-régression)

Chaque tâche de cet epic impose :

| Gate | Commande / règle |
| --- | --- |
| **Linter** | `cd services/api && npm run lint` |
| **Tests** | `cd services/api && npm test` |
| **TDD** | Test rouge → vert → refactor avant de marquer la tâche `done` |
| **Typage** | Pas de `any` ; `npm run typecheck` vert (toujours (package API)) |
| **Non-régression** | Suite complète verte ; ne pas supprimer de tests sans justification |

[Voir standards globaux](../README.md#standards-qualité-tdd-linter-typage-non-régression)

