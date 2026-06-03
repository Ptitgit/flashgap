# E6 — Mobile — sandbox temporaire & upload fiable

## Objectif

Fichier local jusqu'à upload confirmé puis suppression ; retry réseau.

## Dépendances

E5

## Definition of done (epic)

Upload OK WiFi et 4G ; coupure réseau mid-upload → succès après reprise.

## Tâches

- [E6-US1 — Sandbox temporaire (cache app)](./E6-US1-sandbox-temporaire.md)
- [E6-US2 — États d'envoi visibles (UI)](./E6-US2-etats-envoi-ui.md)
- [E6-US3 — Retry automatique (backoff + NetInfo)](./E6-US3-retry-automatique.md)
- [E6-US4 — Erreurs upload et réseau (comportement)](./E6-US4-erreurs-upload-reseau.md)
- [E6-US5 — Retry manuel sur échec](./E6-US5-retry-manuel.md)
- [E6-US6 — Suppression fichier local après upload](./E6-US6-suppression-post-upload.md)
- [E6-US7 — Message quota atteint](./E6-US7-message-quota-atteint.md)

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

