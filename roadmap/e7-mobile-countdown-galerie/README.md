# E7 — Mobile — countdown, reveal & galerie

## Objectif

UX avant/après reveal ; grille photos HD après l'heure.

## Dépendances

E6

## Definition of done (epic)

Galerie fluide 20–50 photos test ; verrouillage avant reveal sur 2 devices.

## Tâches

- [E7-US1 — Countdown avant reveal](./E7-US1-countdown-reveal.md)
- [E7-US2 — Galerie verrouillée avant reveal](./E7-US2-galerie-verrouillee.md)
- [E7-US3 — Grille photos après reveal](./E7-US3-grille-photos-hd.md)
- [E7-US4 — Déverrouillage automatique au reveal](./E7-US4-deverrouillage-auto-reveal.md)
- [E7-US5 — Vue plein écran HD](./E7-US5-plein-ecran-hd.md)
- [E7-US6 — Badge pseudo par photo](./E7-US6-badge-pseudo.md)

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

