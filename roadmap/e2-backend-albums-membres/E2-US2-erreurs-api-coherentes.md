# E2-US2 — Erreurs API cohérentes

| Champ | Valeur |
| --- | --- |
| **Epic** | [E2 — Backend — albums, membres & reveal schedule](./README.md) |
| **Statut** | `todo` |
| **Dépendances** | E2-US1 (recommandé avant E2-US3 à E2-US6, ou en premier après US1) |

## User story

En tant que **développeur**, je veux **un système d'erreurs API cohérent et typé** afin que **le mobile et les tests puissent réagir de façon prévisible**.

## Contexte

Décision **BP13**. Spécification complète : [conventions-erreurs.md](../../docs/conventions-erreurs.md).  
Cette tâche pose le **socle** avant d'implémenter les endpoints métier (E2-US3+).

## Approche TDD (obligatoire)

1. **Rouge** — Tests supertest : erreur Zod → `400` + `VALIDATION_ERROR` ; `AppError` → bon HTTP + `code` ; erreur inconnue → `500` sans stack dans le body.
2. **Vert** — Handler global + classes d'erreur + schéma Zod de l'enveloppe.
3. **Refactor** — Factoriser les `throw` dans les futurs services.

> Ne pas merger tant que le test n'a pas été vu en échec puis en succès pour le comportement ajouté.

## Typage TypeScript (obligatoire)

- Interdiction de `any` (cf. [conventions TypeScript](../../docs/conventions-typescript.md)).
- `ErrorResponseSchema` / `ApiErrorCode` dans `@flashgap/shared` (BP1).
- `AppError` côté API ; enveloppe JSON alignée sur le schéma shared.

## Critères d'acceptation

- [ ] Enveloppe JSON `{ error, code, details? }` sur toutes les réponses `4xx` / `5xx`
- [ ] Schéma Zod `ErrorResponseSchema` + type `ErrorResponse` + union `ApiErrorCode` dans **`@flashgap/shared`**
- [ ] Hiérarchie `AppError` (sous-classes ou factory typées) avec `statusCode` + `code`
- [ ] `setErrorHandler` global Fastify : `AppError`, `ZodError`, fallback `500` + `INTERNAL_ERROR`
- [ ] **Aucune** stack trace ni message SQL/MinIO dans les réponses client
- [ ] Logs pino : erreur complète + `requestId` côté serveur uniquement
- [ ] Codes V0 documentés dans [conventions-erreurs.md](../../docs/conventions-erreurs.md) (au moins la liste initiale)
- [ ] Tests : `400` validation, `404` exemple, `500` erreur inconnue (body sans stack)
- [ ] **TDD** : au moins un test écrit ou mis à jour **avant** l'implémentation finale ; cycle rouge → vert → refactor tracé (commit ou description PR)
- [ ] **Linter** : `cd services/api && npm run lint` — inclut ESLint **et** `no-explicit-any` — **0 erreur, 0 warning** sur les fichiers modifiés
- [ ] **Typage** : aucun `any` (eslint `@typescript-eslint/no-explicit-any` + revue) ; `cd services/api && npm run typecheck` — **0 erreur** ; types explicites sur exports publics et contrats API ([conventions TS](../../docs/conventions-typescript.md))
- [ ] **Non-régression** : `cd services/api && npm test` — **100 % des tests passent** (aucun test existant en échec)

## Notes techniques

- Placer le code dans `src/errors/` (classes, handler, codes).
- Les endpoints E2-US3+ doivent **uniquement** `throw` des `AppError` (pas de `reply.code(400).send(...)` ad hoc).

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
