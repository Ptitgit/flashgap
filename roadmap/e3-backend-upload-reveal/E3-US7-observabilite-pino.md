# E3-US7 — Observabilité (pino + métriques)

| Champ | Valeur |
| --- | --- |
| **Epic** | [E3 — Backend — upload photos, reveal gate & quotas](./README.md) |
| **Statut** | `todo` |
| **Dépendances** | E3-US1 |

## User story

En tant que **développeur**, je veux **des logs structurés et des métriques basiques** afin de **diagnostiquer les échecs d'upload pendant une soirée**.

## Contexte

Décision **BP7**. [conventions API](../../docs/conventions-api.md).

## Approche TDD (obligatoire)

1. **Rouge** — Test : requête upload génère log/métrique attendu (spy ou endpoint `/metrics`).
2. **Vert** — pino + compteurs branchés sur succès/échec upload.
3. **Refactor** — Redacter pseudo / token des logs.

> Ne pas merger tant que le test n'a pas été vu en échec puis en succès pour le comportement ajouté.

## Typage TypeScript (obligatoire)

- Interdiction de `any` (cf. [conventions TypeScript](../../docs/conventions-typescript.md)).
- Contrats via `@flashgap/shared` — [conventions shared](../../docs/conventions-shared.md) (BP1).

## Critères d'acceptation

- [ ] Logger **pino** ; JSON en `production`, pretty en `development`
- [ ] `requestId` sur chaque requête (propagé dans les logs)
- [ ] Métriques : `uploads_success_total`, `uploads_error_total`, `rate_limit_hits_total`
- [ ] Aucun secret, token complet ni donnée photo dans les logs
- [ ] **TDD** : au moins un test écrit ou mis à jour **avant** l'implémentation finale ; cycle rouge → vert → refactor tracé (commit ou description PR)
- [ ] **Linter** : `cd services/api && npm run lint` — inclut ESLint **et** `no-explicit-any` — **0 erreur, 0 warning** sur les fichiers modifiés
- [ ] **Typage** : aucun `any` (eslint `@typescript-eslint/no-explicit-any` + revue) ; `cd services/api && npm run typecheck` — **0 erreur** ; types explicites sur exports publics et contrats API ([conventions TS](../../docs/conventions-typescript.md))
- [ ] **Non-régression** : `cd services/api && npm test` — **100 % des tests passent** (aucun test existant en échec)

## Notes techniques

- Exposition `/metrics` (Prometheus) optionnelle en V0 ; minimum : compteurs testables en mémoire.

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
