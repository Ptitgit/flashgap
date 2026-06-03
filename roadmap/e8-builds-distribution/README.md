# E8 — Builds & distribution V0 (Android + iOS)

## Objectif

Livrables installables pour 1–3 testeurs sans CI.

## Dépendances

E5

## Definition of done (epic)

APK + build iOS installés chez au moins 2 testeurs.

## Tâches

- [E8-US1 — Build APK Android](./E8-US1-apk-android.md)
- [E8-US2 — Build iOS via Xcode (Personal Team)](./E8-US2-build-ios-xcode.md)
- [E8-US3 — Runbook installation testeur](./E8-US3-runbook-installation-testeur.md)

## Quality gates (TDD, linter, non-régression)

Chaque tâche de cet epic impose :

| Gate | Commande / règle |
| --- | --- |
| **Linter** | `npm run lint` dans chaque package touché (`services/api`, `apps/mobile`) |
| **Tests** | `npm test` dans chaque package touché ; build dry-run documenté si pas de tests build |
| **TDD** | Test rouge → vert → refactor avant de marquer la tâche `done` |
| **Typage** | Pas de `any` ; `npm run typecheck` vert (toujours si code modifié) |
| **Non-régression** | Suite complète verte ; ne pas supprimer de tests sans justification |

[Voir standards globaux](../README.md#standards-qualité-tdd-linter-typage-non-régression)

