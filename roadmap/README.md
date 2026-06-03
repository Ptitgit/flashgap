# Roadmap V0 — Flashgap

Roadmap dérivée du [cadrage produit](../docs/cadrage-flashgap-like.md).

**Objectif V0** : application fonctionnelle pour 1–3 testeurs — flux **capture HD → upload → countdown → reveal → galerie** sur Android et iOS.

## Ordre recommandé

```
E1 → E2 → E3 → E4 → E5 → E6 → E7 → E9
              └→ E8 (en parallèle après E5)
```

## Epics

| Epic | Titre | Tâches | Dépend de |
| --- | --- | ---: | --- |
| [E1](./e1-infrastructure-vps/README.md) | Infrastructure & déploiement VPS | 5 | — |
| [E2](./e2-backend-albums-membres/README.md) | Backend — albums, membres & reveal schedule | 7 | E1 |
| [E3](./e3-backend-upload-reveal/README.md) | Backend — upload photos, reveal gate & quotas | 8 | E2 |
| [E4](./e4-mobile-onboarding/README.md) | Mobile — projet Expo, join album & session | 5 | E3 |
| [E5](./e5-mobile-camera-hd/README.md) | Mobile — capture photo HD in-app | 5 | E4 |
| [E6](./e6-mobile-upload-fiable/README.md) | Mobile — sandbox temporaire & upload fiable | 7 | E5 |
| [E7](./e7-mobile-countdown-galerie/README.md) | Mobile — countdown, reveal & galerie | 6 | E6 |
| [E8](./e8-builds-distribution/README.md) | Builds & distribution V0 (Android + iOS) | 3 | E5 |
| [E9](./e9-validation-e2e/README.md) | Validation bout en bout & opérations V0 | 4 | E7, E8 |
| **Total** | | **50** | |

Décisions techniques : [docs/decisions-techniques.md](../docs/decisions-techniques.md).  
Types partagés : [docs/conventions-shared.md](../docs/conventions-shared.md).  
Gestion des erreurs : [docs/conventions-erreurs.md](../docs/conventions-erreurs.md).

## Critères globaux « V0 utilisable »

Quand toutes les tâches sont en `done` :

1. Installation app (APK Android et/ou iOS Xcode)
2. Join album (code 6 car. + pseudo)
3. Capture HD in-app, sans copie galerie
4. Upload avec retry, quota 100 respecté
5. Countdown + galerie verrouillée avant `reveal_at`
6. Galerie HD de tous les membres après reveal
7. Purge album possible après test


## Standards qualité (TDD, linter, typage, non-régression)

**Chaque tâche** de la roadmap suit les mêmes règles (détaillées dans son fichier `.md`) :

1. **TDD** — Écrire ou mettre à jour le test **avant** l'implémentation ; valider le cycle rouge → vert → refactor.
2. **Linter** — Commande documentée dans l'epic ; **0 erreur, 0 warning** sur les fichiers modifiés.
3. **Non-régression** — Suite de tests du périmètre **100 % verte** ; rejouer les tests des epics précédents si fichiers partagés touchés.
4. **Typage** — TypeScript `strict` ; **jamais `any`** ; `npm run typecheck` vert. Voir [conventions TypeScript](../docs/conventions-typescript.md).
5. **Erreurs** — Codes API stables, pas de fuite stack ; mobile via `ApiResult<T>`. Voir [conventions erreurs](../docs/conventions-erreurs.md).

Aucune tâche n'est `done` sans ces **cinq** gates (selon périmètre), en plus des critères fonctionnels.


### Commandes par périmètre

| Périmètre | Linter | Typecheck | Tests |
| --- | --- | --- | --- |
| Shared (`packages/shared`) | `npm run lint` | `npm run typecheck` | `npm test` (si présent) |
| API (`services/api`) | `npm run lint` (ESLint + Prettier + `no-explicit-any`) | `npm run typecheck` | `npm test` (Testcontainers) |
| Mobile (`apps/mobile`) | `npm run lint` (incl. `no-explicit-any`) | `npm run typecheck` | `npm test` |
| Infra (`infra/`, scripts) | `shellcheck`, `docker compose config` | N/A si pas de TS | Scripts smoke versionnés |
| Validation E9 | Les deux + `no-explicit-any` | API + mobile | Tout le monorepo |

> Dès **E2-US1** : monorepo + `packages/shared` (`@flashgap/shared`), puis API et mobile. Voir [conventions-shared.md](../docs/conventions-shared.md).

> Configurer `lint`, `format`, `typecheck`, `test`, **Husky** et **CI API** (E2-US7). Voir [AGENTS.md](../AGENTS.md) et [decisions-techniques.md](../docs/decisions-techniques.md).

## Statuts suggérés

`todo` → `in_progress` → `done` | `blocked`
