# E4 — Mobile — projet Expo, join album & session

## Objectif

App en dev build, écran code + pseudo, session album/membre persistante.

## Dépendances

E3

## Definition of done (epic)

Join fonctionnel sur device réel contre API HTTPS.

## Tâches

- [E4-US1 — Initialiser projet Expo (dev build)](./E4-US1-init-expo-dev-build.md)
- [E4-US2 — Client API et erreurs typées](./E4-US2-client-api-erreurs.md)
- [E4-US3 — Écran join (code + pseudo)](./E4-US3-ecran-join.md)
- [E4-US4 — Session persistante (album / membre)](./E4-US4-session-persistante.md)
- [E4-US5 — Configuration URL API par environnement](./E4-US5-config-api-url.md)

## Quality gates (TDD, linter, non-régression)

Chaque tâche de cet epic impose :

| Gate | Commande / règle |
| --- | --- |
| **Linter** | `cd apps/mobile && npm run lint` |
| **Tests** | `cd apps/mobile && npm test` |
| **TDD** | Test rouge → vert → refactor avant de marquer la tâche `done` |
| **Typage** | Pas de `any` ; `npm run typecheck` vert (toujours (package mobile)) |
| **Non-régression** | Suite complète verte ; ne pas supprimer de tests sans justification |

[Voir standards globaux](../README.md#standards-qualité-tdd-linter-typage-non-régression)

