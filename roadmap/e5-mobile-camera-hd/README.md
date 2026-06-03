# E5 — Mobile — capture photo HD in-app

## Objectif

Photos prises dans l'app, JPEG 90 %, aucune fuite vers la galerie système.

## Dépendances

E4

## Definition of done (epic)

Capture HD validée sur au moins 1 Android et 1 iOS.

## Tâches

- [E5-US1 — Caméra in-app plein écran](./E5-US1-camera-in-app.md)
- [E5-US2 — JPEG qualité 90 % sans downscale](./E5-US2-jpeg-90-qualite.md)
- [E5-US3 — Pas d'enregistrement dans la galerie système](./E5-US3-pas-de-fuite-galerie.md)
- [E5-US4 — Aperçu après capture (reprendre / envoyer)](./E5-US4-apercu-apres-capture.md)
- [E5-US5 — Orientation et EXIF](./E5-US5-orientation-exif.md)

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

