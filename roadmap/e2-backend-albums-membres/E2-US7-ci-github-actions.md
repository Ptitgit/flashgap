# E2-US7 — CI GitHub Actions (API)

| Champ | Valeur |
| --- | --- |
| **Epic** | [E2 — Backend — albums, membres & reveal schedule](./README.md) |
| **Statut** | `todo` |
| **Dépendances** | E2-US1 |

## User story

En tant que **développeur**, je veux **une CI GitHub Actions sur l'API** afin de **détecter les régressions sans m'en rappeler manuellement**.

## Contexte

Décision **BP5** : CI dès E2, backend seulement. Référence : [décisions techniques](../../docs/decisions-techniques.md).

## Approche TDD (obligatoire)

1. **Rouge** — Faire échouer la CI sur un test volontairement cassé (branche test), puis annuler.
2. **Vert** — Workflow vert sur `main` avec la suite actuelle.
3. **Refactor** — Optimiser caches npm si besoin.

> Ne pas merger tant que le test n'a pas été vu en échec puis en succès pour le comportement ajouté.

## Typage TypeScript (obligatoire)

- Interdiction de `any` (cf. [conventions TypeScript](../../docs/conventions-typescript.md)).
- Contrats via `@flashgap/shared` — [conventions shared](../../docs/conventions-shared.md) (BP1).

## Critères d'acceptation

- [ ] Fichier `.github/workflows/api-ci.yml` sur `push` / `pull_request` vers `main`
- [ ] Jobs : `npm ci` à la racine (workspaces), `npm run lint`, `npm run typecheck` (**shared** + api), `npm test` (Testcontainers — Docker sur le runner)
- [ ] CI verte sur le commit qui merge E2-US7
- [ ] Badge ou mention dans README racine (optionnel)
- [ ] **TDD** : au moins un test écrit ou mis à jour **avant** l'implémentation finale ; cycle rouge → vert → refactor tracé (commit ou description PR)
- [ ] **Linter** : `cd services/api && npm run lint` — inclut ESLint **et** `no-explicit-any` — **0 erreur, 0 warning** sur les fichiers modifiés
- [ ] **Typage** : aucun `any` (eslint `@typescript-eslint/no-explicit-any` + revue) ; `cd services/api && npm run typecheck` — **0 erreur** ; types explicites sur exports publics et contrats API ([conventions TS](../../docs/conventions-typescript.md))
- [ ] **Non-régression** : `cd services/api && npm test` — **100 % des tests passent** (aucun test existant en échec)

## Notes techniques

- GitHub-hosted runners incluent Docker ; Testcontainers fonctionne sans self-hosted en V0.
- Mobile (`apps/mobile`) hors CI jusqu'à décision V1.

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
