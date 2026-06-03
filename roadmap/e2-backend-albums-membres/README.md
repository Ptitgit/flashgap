# E2 — Backend — albums, membres & reveal schedule

## Objectif

CRUD album, join par code à 6 caractères, gestion de `reveal_at` par l'organisateur.

## Dépendances

E1

## Definition of done (epic)

Critères de sortie V0.1 du cadrage : `POST /albums`, `POST /join`, `reveal_at` modifiable, HTTPS.

## Tâches

- [E2-US1 — Schéma Postgres (albums, members, photos)](./E2-US1-schema-postgres.md)
- [E2-US2 — Erreurs API cohérentes](./E2-US2-erreurs-api-coherentes.md)
- [E2-US3 — Créer un album (POST /albums)](./E2-US3-creer-album.md)
- [E2-US4 — Rejoindre un album (POST /albums/:code/join)](./E2-US4-rejoindre-album.md)
- [E2-US5 — Modifier l'heure de reveal](./E2-US5-modifier-reveal-at.md)
- [E2-US6 — Collection HTTP de test](./E2-US6-collection-http.md)
- [E2-US7 — CI GitHub Actions (API)](./E2-US7-ci-github-actions.md)

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

