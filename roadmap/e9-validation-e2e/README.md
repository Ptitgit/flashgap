# E9 — Validation bout en bout & opérations V0

## Objectif

Démo filmable, purge album, décisions V1 documentées.

## Dépendances

E7, E8

## Definition of done (epic)

Application utilisable de bout en bout par des testeurs non-dev.

## Tâches

- [E9-US1 — Scénario test multi-appareils](./E9-US1-test-multi-appareils.md)
- [E9-US2 — Script purge album](./E9-US2-script-purge-album.md)
- [E9-US3 — Documenter go/no-go V1 (Q10, Q12)](./E9-US3-go-nogo-v1.md)
- [E9-US4 — Checklist sortie V0](./E9-US4-checklist-sortie-v0.md)

## Quality gates (TDD, linter, non-régression)

Chaque tâche de cet epic impose :

| Gate | Commande / règle |
| --- | --- |
| **Linter** | `npm run lint` à la racine ou dans chaque workspace (`services/api`, `apps/mobile`) |
| **Tests** | `npm test` complet (API + mobile) + checklist manuelle E2E |
| **TDD** | Test rouge → vert → refactor avant de marquer la tâche `done` |
| **Typage** | Pas de `any` ; `npm run typecheck` vert (toujours) |
| **Non-régression** | Suite complète verte ; ne pas supprimer de tests sans justification |

[Voir standards globaux](../README.md#standards-qualité-tdd-linter-typage-non-régression)

