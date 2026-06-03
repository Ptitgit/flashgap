# E2-US1 — Schéma Postgres (albums, members, photos)

| Champ | Valeur |
| --- | --- |
| **Epic** | [E2 — Backend — albums, membres & reveal schedule](./README.md) |
| **Statut** | `todo` |
| **Dépendances** | E1 |

## User story

En tant que **développeur**, je veux **un schéma Postgres** afin de **modéliser albums, membres et photos**.

## Contexte

Cette tâche fait partie de la **V0 Flashgap**. Référence : [cadrage produit](../../docs/cadrage-flashgap-like.md).

## Approche TDD (obligatoire)

1. **Rouge** — Écrire ou mettre à jour un test qui échoue et exprime le comportement attendu.
2. **Vert** — Implémenter le minimum pour faire passer le test.
3. **Refactor** — Nettoyer sans changer le comportement ; relancer lint + tests.

Écrire d'abord les tests d'intégration ou unitaires des endpoints / repositories (rouge), implémenter (vert), refactorer.

> Ne pas merger tant que le test n'a pas été vu en échec puis en succès pour le comportement ajouté.

## Typage TypeScript (obligatoire)

- Interdiction de `any` (cf. [conventions TypeScript](../../docs/conventions-typescript.md)).
- `strict: true` ; hériter de [`tsconfig.base.json`](../../tsconfig.base.json) à la création des packages.
- Données externes typées via `unknown` + validation (Zod ou guards).
- Contrats via `@flashgap/shared` — [conventions shared](../../docs/conventions-shared.md) (BP1).

## Critères d'acceptation

- [ ] Monorepo npm/pnpm **workspaces** à la racine (`packages/*`, `services/*`, `apps/*`)
- [ ] Package **`packages/shared`** (`@flashgap/shared`) : Zod, `tsconfig` strict, export `index.ts`
- [ ] Package `services/api` initialisé : `tsconfig` étend [`tsconfig.base.json`](../../tsconfig.base.json), ESLint + **Prettier**, scripts `lint`, `format`, `typecheck`, `test`
- [ ] **Husky** + lint-staged : pre-commit exécute lint + typecheck + tests (cf. BP4)
- [ ] **Testcontainers** : harness de test démarre Postgres (+ MinIO si besoin migrations) — au moins un test d'exemple vert
- [ ] **Zod** dans `packages/shared` (pas dans `services/api`) ; schémas domaine `Album` / `Member` / `Photo` exportés
- [ ] `services/api` dépend de `@flashgap/shared` (`workspace:*`)
- [ ] `.env.example` avec variables `development` / `production` documentées (BP11)
- [ ] Types/domain models pour `Album`, `Member`, `Photo` (pas de lignes DB non typées)
- [ ] Table `albums` : `id`, `code` (6 car. unique), `reveal_at`, `organizer_secret` (ou équivalent), `created_at`
- [ ] Table `members` : `id`, `album_id`, `pseudo`, `created_at`
- [ ] Table `photos` : `id`, `member_id`, `object_key`, `size_bytes`, `client_upload_id`, `created_at` ; **UNIQUE** `(member_id, client_upload_id)`
- [ ] Migrations versionnées (une seule stack ORM/query builder)
- [ ] Index sur `albums.code` et `photos.member_id`
- [ ] **TDD** : au moins un test écrit ou mis à jour **avant** l'implémentation finale ; cycle rouge → vert → refactor tracé (commit ou description PR)
- [ ] **Linter** : `cd services/api && npm run lint` — inclut ESLint **et** `no-explicit-any` — **0 erreur, 0 warning** sur les fichiers modifiés
- [ ] **Typage** : aucun `any` (eslint `@typescript-eslint/no-explicit-any` + revue) ; `cd services/api && npm run typecheck` — **0 erreur** ; types explicites sur exports publics et contrats API ([conventions TS](../../docs/conventions-typescript.md))
- [ ] **Non-régression** : `cd services/api && npm test` — **100 % des tests passent** (aucun test existant en échec)


## Notes techniques

- Le champ `photos` peut rester vide jusqu'à E3 ; prévoir la FK dès E2.

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
