# E6-US4 — Erreurs upload et réseau (comportement)

| Champ | Valeur |
| --- | --- |
| **Epic** | [E6 — Mobile — sandbox temporaire & upload fiable](./README.md) |
| **Statut** | `todo` |
| **Dépendances** | E4-US2, E6-US3, E6-US2 |

## User story

En tant qu'**invité**, je veux **des messages clairs et un retry intelligent** quand un upload échoue **afin de** ne pas perdre de photos sans comprendre pourquoi.

## Contexte

Décision **BP13** — couche UX au-dessus de la queue E6-US3. [conventions-erreurs.md](../../docs/conventions-erreurs.md) §3 (upload).

## Approche TDD (obligatoire)

1. **Rouge** — Tests : `QUOTA_EXCEEDED` → pas de retry auto ; `NETWORK_ERROR` → retry ; `RATE_LIMITED` → backoff respecte `Retry-After` si présent.
2. **Vert** — `classifyUploadError(result)` + branchement queue.
3. **Refactor** — Centraliser la logique (un module `upload-error-policy.ts`).

> Ne pas merger tant que le test n'a pas été vu en échec puis en succès pour le comportement ajouté.

## Typage TypeScript (obligatoire)

- Interdiction de `any` (cf. [conventions TypeScript](../../docs/conventions-typescript.md)).
- Contrats via `@flashgap/shared` — [conventions shared](../../docs/conventions-shared.md) (BP1).

## Critères d'acceptation

- [ ] Politique retry documentée dans le code (tableau code → retry oui/non)
- [ ] UI : message via `getUserMessage(code)` sur échec définitif
- [ ] `QUOTA_EXCEEDED`, `UNAUTHORIZED`, `UNSUPPORTED_MEDIA` : **pas** de retry automatique
- [ ] `NETWORK_ERROR`, `INTERNAL_ERROR`, `RATE_LIMITED` : retry selon E6-US3
- [ ] Conserver le même `clientUploadId` sur tous les retries
- [ ] Tests unitaires de la politique (au moins 5 cas)
- [ ] **TDD** : au moins un test écrit ou mis à jour **avant** l'implémentation finale ; cycle rouge → vert → refactor tracé (commit ou description PR)
- [ ] **Linter** : `cd apps/mobile && npm run lint` — inclut ESLint **et** `no-explicit-any` — **0 erreur, 0 warning** sur les fichiers modifiés
- [ ] **Typage** : aucun `any` (eslint `@typescript-eslint/no-explicit-any` + revue) ; `cd apps/mobile && npm run typecheck` — **0 erreur** ; types explicites sur exports publics et contrats API ([conventions TS](../../docs/conventions-typescript.md))
- [ ] **Non-régression** : `cd apps/mobile && npm test` — **100 % des tests passent** (aucun test existant en échec)

## Notes techniques

- Complète E6-US7 (affichage quota) — ne pas dupliquer les messages.

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
