# E4-US2 — Client API et erreurs typées

| Champ | Valeur |
| --- | --- |
| **Epic** | [E4 — Mobile — projet Expo, join album & session](./README.md) |
| **Statut** | `todo` |
| **Dépendances** | E2-US2, E4-US1 |

## User story

En tant que **développeur mobile**, je veux **un client HTTP qui retourne des erreurs typées** afin d'**afficher des messages clairs et gérer le retry correctement**.

## Contexte

Décision **BP13**. [conventions-erreurs.md](../../docs/conventions-erreurs.md) §3. Prérequis pour E4-US3 (écran join).

## Approche TDD (obligatoire)

1. **Rouge** — Tests : JSON erreur API → `ApiResult` `{ ok: false, error: { code: 'QUOTA_EXCEEDED', ... } }` ; hors-ligne → `NETWORK_ERROR`.
2. **Vert** — `apiClient`, types, `getUserMessage(code)`.
3. **Refactor** — Un seul point d'appel pour toutes les requêtes.

> Ne pas merger tant que le test n'a pas été vu en échec puis en succès pour le comportement ajouté.

## Typage TypeScript (obligatoire)

- Interdiction de `any` (cf. [conventions TypeScript](../../docs/conventions-typescript.md)).
- Types et `ApiErrorCode` importés depuis `@flashgap/shared` (BP1).

## Critères d'acceptation

- [ ] `src/api/client.ts` : `request<T>(...): Promise<ApiResult<T>>`
- [ ] `apps/mobile` dépend de `@flashgap/shared` ; `ErrorResponse` importé depuis shared (pas de fichier local dupliqué)
- [ ] `src/errors/user-messages.ts` : `getUserMessage(code)` — `switch` exhaustif
- [ ] `NETWORK_ERROR` local si fetch échoue / timeout (pas de réponse HTTP)
- [ ] `Authorization: Bearer` injecté quand token en session (stub OK avant E4-US4)
- [ ] Tests unitaires parser + au moins 3 codes métier
- [ ] **TDD** : au moins un test écrit ou mis à jour **avant** l'implémentation finale ; cycle rouge → vert → refactor tracé (commit ou description PR)
- [ ] **Linter** : `cd apps/mobile && npm run lint` — inclut ESLint **et** `no-explicit-any` — **0 erreur, 0 warning** sur les fichiers modifiés
- [ ] **Typage** : aucun `any` (eslint `@typescript-eslint/no-explicit-any` + revue) ; `cd apps/mobile && npm run typecheck` — **0 erreur** ; types explicites sur exports publics et contrats API ([conventions TS](../../docs/conventions-typescript.md))
- [ ] **Non-régression** : `cd apps/mobile && npm test` — **100 % des tests passent** (aucun test existant en échec)

## Notes techniques

- E4-US3 (join) et E6 (upload) consomment ce client — pas de `fetch` nu dans les écrans.

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
