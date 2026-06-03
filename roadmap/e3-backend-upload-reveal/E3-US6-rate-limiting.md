# E3-US6 — Rate limiting uploads

| Champ | Valeur |
| --- | --- |
| **Epic** | [E3 — Backend — upload photos, reveal gate & quotas](./README.md) |
| **Statut** | `todo` |
| **Dépendances** | E3-US1 |

## User story

En tant que **système**, je veux **limiter le débit des uploads** afin de **protéger le VPS et le réseau de la soirée**.

## Contexte

Décision **BP8** : rate limit dès V0.2 / E3. Complète le quota 100 photos/membre. [conventions API](../../docs/conventions-api.md).

## Approche TDD (obligatoire)

1. **Rouge** — Test : N+1 uploads rapides → `429`.
2. **Vert** — Middleware rate limit sur `POST .../photos`.
3. **Refactor** — Seuils via variables d'environnement.

> Ne pas merger tant que le test n'a pas été vu en échec puis en succès pour le comportement ajouté.

## Typage TypeScript (obligatoire)

- Interdiction de `any` (cf. [conventions TypeScript](../../docs/conventions-typescript.md)).
- Contrats via `@flashgap/shared` — [conventions shared](../../docs/conventions-shared.md) (BP1).

## Critères d'acceptation

- [ ] Limite par **membre** (token) configurable (`RATE_LIMIT_MEMBER`)
- [ ] Limite par **IP** configurable (`RATE_LIMIT_IP`)
- [ ] `POST /albums/:albumId/photos` retourne `429` quand dépassé ; corps JSON explicite
- [ ] Tests Testcontainers ou intégration simulant rafale d'uploads
- [ ] Compteur métrique `rate_limit_hits_total` incrémenté (cf. E3-US7)
- [ ] **TDD** : au moins un test écrit ou mis à jour **avant** l'implémentation finale ; cycle rouge → vert → refactor tracé (commit ou description PR)
- [ ] **Linter** : `cd services/api && npm run lint` — inclut ESLint **et** `no-explicit-any` — **0 erreur, 0 warning** sur les fichiers modifiés
- [ ] **Typage** : aucun `any` (eslint `@typescript-eslint/no-explicit-any` + revue) ; `cd services/api && npm run typecheck` — **0 erreur** ; types explicites sur exports publics et contrats API ([conventions TS](../../docs/conventions-typescript.md))
- [ ] **Non-régression** : `cd services/api && npm test` — **100 % des tests passent** (aucun test existant en échec)

## Notes techniques

- Ex. `@fastify/rate-limit` avec clé dérivée du `memberId` et de `request.ip`.

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
