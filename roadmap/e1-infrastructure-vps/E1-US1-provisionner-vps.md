# E1-US1 — Provisionner le VPS (région EU)

| Champ | Valeur |
| --- | --- |
| **Epic** | [E1 — Infrastructure & déploiement VPS](./README.md) |
| **Statut** | `todo` |
| **Dépendances** | Aucune |

## User story

En tant que **développeur**, je veux **provisionner le VPS en région EU** afin de **héberger les données photos en conformité avec le cadrage**.

## Contexte

Cette tâche fait partie de la **V0 Flashgap**. Référence : [cadrage produit](../../docs/cadrage-flashgap-like.md).

## Approche TDD (obligatoire)

1. **Rouge** — Écrire ou mettre à jour un test qui échoue et exprime le comportement attendu.
2. **Vert** — Implémenter le minimum pour faire passer le test.
3. **Refactor** — Nettoyer sans changer le comportement ; relancer lint + tests.

Écrire d'abord le test/smoke qui échoue (ex. healthcheck, validation compose), puis provisionner/configurer jusqu'au vert.

> Ne pas merger tant que le test n'a pas été vu en échec puis en succès pour le comportement ajouté.

## Typage TypeScript (obligatoire)

- Interdiction de `any` (cf. [conventions TypeScript](../../docs/conventions-typescript.md)).
- `strict: true` ; hériter de [`tsconfig.base.json`](../../tsconfig.base.json) à la création des packages.
- Données externes typées via `unknown` + validation (Zod ou guards).
- Contrats via `@flashgap/shared` — [conventions shared](../../docs/conventions-shared.md) (BP1).

## Critères d'acceptation

- [ ] OS à jour (Ubuntu LTS ou équivalent)
- [ ] Utilisateur `deploy` non-root avec sudo limité
- [ ] SSH par clé uniquement (mot de passe désactivé)
- [ ] Firewall : port 22 restreint (IP fixe ou VPN), 80 et 443 ouverts
- [ ] Hostname, IP publique et éventuellement DNS documentés dans le README infra
- [ ] **TDD** : au moins un test écrit ou mis à jour **avant** l'implémentation finale ; cycle rouge → vert → refactor tracé (commit ou description PR)
- [ ] **Linter** : `npm run lint` dans `services/api` si le code API existe ; sinon `shellcheck` sur les scripts shell et validation `docker compose config` — inclut ESLint **et** `no-explicit-any` — **0 erreur, 0 warning** sur les fichiers modifiés
- [ ] **Typage** : aucun `any` (eslint `@typescript-eslint/no-explicit-any` + revue) ; `npm run typecheck` dans `services/api` si du TS est ajouté ; sinon N/A (scripts shell uniquement) — **0 erreur** ; types explicites sur exports publics et contrats API ([conventions TS](../../docs/conventions-typescript.md))
- [ ] **Non-régression** : `npm test` dans `services/api` si présent ; sinon script smoke (`curl /health`, `docker compose ps`) versionné dans `scripts/` ou `infra/` — **100 % des tests passent** (aucun test existant en échec)


## Notes techniques

- Confirmer hébergeur et région EU avant démarrage (cf. cadrage Q6).
- Prévoir ~20 Go disque pour mono-événement V0.

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
