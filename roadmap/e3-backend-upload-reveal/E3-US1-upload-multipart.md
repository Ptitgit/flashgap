# E3-US1 — Upload photo JPEG (multipart)

| Champ | Valeur |
| --- | --- |
| **Epic** | [E3 — Backend — upload photos, reveal gate & quotas](./README.md) |
| **Statut** | `todo` |
| **Dépendances** | E2 |

## User story

En tant qu'**invité**, je veux **uploader une photo JPEG** afin de **la partager dans l'album**.

## Contexte

Cette tâche fait partie de la **V0 Flashgap**. Référence : [cadrage produit](../../docs/cadrage-flashgap-like.md).

## Approche TDD (obligatoire)

1. **Rouge** — Écrire ou mettre à jour un test qui échoue et exprime le comportement attendu.
2. **Vert** — Implémenter le minimum pour faire passer le test.
3. **Refactor** — Nettoyer sans changer le comportement ; relancer lint + tests.

Couvrir par tests : upload multipart, reveal gate (avant/après `reveal_at`), quota, URLs signées — avant d'implémenter la logique.

> Ne pas merger tant que le test n'a pas été vu en échec puis en succès pour le comportement ajouté.

## Typage TypeScript (obligatoire)

- Interdiction de `any` (cf. [conventions TypeScript](../../docs/conventions-typescript.md)).
- `strict: true` ; hériter de [`tsconfig.base.json`](../../tsconfig.base.json) à la création des packages.
- Données externes typées via `unknown` + validation (Zod ou guards).
- Contrats via `@flashgap/shared` — [conventions shared](../../docs/conventions-shared.md) (BP1).

## Critères d'acceptation

- [ ] `POST /albums/:albumId/photos` multipart champ `file` ; body validé (Zod où applicable)
- [ ] `Authorization: Bearer <token>` membre (cf. E2-US4)
- [ ] Header **`X-Client-Upload-Id`** (UUID v4) obligatoire — rejeu même id → `200` + même `photoId` (idempotence, BP12)
- [ ] `Content-Type: image/jpeg` ; taille max configurable (ex. 15 Mo)
- [ ] Réponse `{ photoId, objectKey }` en 201 (ou 200 si idempotent)
- [ ] **TDD** : au moins un test écrit ou mis à jour **avant** l'implémentation finale ; cycle rouge → vert → refactor tracé (commit ou description PR)
- [ ] **Linter** : `cd services/api && npm run lint` — inclut ESLint **et** `no-explicit-any` — **0 erreur, 0 warning** sur les fichiers modifiés
- [ ] **Typage** : aucun `any` (eslint `@typescript-eslint/no-explicit-any` + revue) ; `cd services/api && npm run typecheck` — **0 erreur** ; types explicites sur exports publics et contrats API ([conventions TS](../../docs/conventions-typescript.md))
- [ ] **Non-régression** : `cd services/api && npm test` — **100 % des tests passent** (aucun test existant en échec)


## Notes techniques

_Aucune._

## Anti-régression

- [ ] Exécuter la **suite de tests complète** du périmètre (voir commandes ci-dessous) : tous les tests passent
- [ ] Vérifier qu'**aucun test existant** n'a été supprimé ou contourné sans justification documentée
- [ ] Rejouer les tests des **tâches / epics précédents** impactés par les fichiers modifiés
- [ ] `npm run typecheck` vert ; grep / ESLint confirme **aucun** `any` ni `as any` introduit
- [ ] Conserver ou étendre la couverture des **invariants produit** (caméra in-app, pas de galerie système, reveal gate, quota 100)

## Definition of done

- [ ] Tous les critères d'acceptation fonctionnels cochés
- [ ] Critères **TDD**, **linter**, **typage** et **non-régression** cochés
- [ ] Code review (ou auto-review) confirme l'absence de régression sur le périmètre touché
- [ ] **Typage** : `typecheck` vert, zéro `any`, conventions TS respectées
- [ ] Invariants produit respectés (cf. [cadrage](../../docs/cadrage-flashgap-like.md) section 1)
