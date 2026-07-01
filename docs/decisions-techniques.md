# Décisions techniques — bonnes pratiques

Registre complémentaire au [cadrage produit](cadrage-flashgap-like.md).  
**Validé le 2026-06-02** (questionnaire bonnes pratiques).

| # | Sujet | Choix retenu |
| --- | --- | --- |
| BP1 | Contrats API & types | Package **`@flashgap/shared`** (monorepo) : schémas **Zod** + types `z.infer` importés par **API** et **mobile** — voir [conventions-shared.md](conventions-shared.md) |
| BP2 | Auth membre post-join | **Token signé** (JWT ou opaque) retourné au join, header `Authorization` |
| BP3 | Formatage | **Prettier** + ESLint (`eslint-config-prettier`) |
| BP4 | Pre-commit | **Husky** : lint + typecheck + **tests rapides** à chaque commit |
| BP5 | CI GitHub Actions | **Dès E2** — backend seulement (`lint` + `test`) |
| BP6 | Tests intégration | **Testcontainers** (Postgres + MinIO) dans `npm test` |
| BP7 | Observabilité V0 | **Logs structurés** (pino) + **métriques basiques** (uploads OK/KO, erreurs) |
| BP8 | Rate limiting | **Dès V0.2 / E3** — par membre + par IP |
| BP9 | Sauvegardes | **Pas de backup** (risque accepté, inchangé vs cadrage Q12) |
| BP10 | iOS ~12 iPhones | **Trancher en E9** — pas d'engagement TestFlight avant fin V0 |
| BP11 | Environnements | **dev local** + **prod** (VPS unique, pas de staging) |
| BP12 | Idempotence upload | Header **`X-Client-Upload-Id`** (UUID) — déduplication serveur |
| BP13 | Gestion des erreurs | Enveloppe JSON `{ error, code, details? }` ; erreurs typées API ; client mobile `ApiResult<T>` ; mapping UX par `code` — voir [conventions-erreurs.md](conventions-erreurs.md) |

## Implications par brique

### API (`services/api`)

- Schémas Zod et types dans `packages/shared` ; l'API valide avec `safeParse` (pas de schémas dupliqués dans `services/api`).
- `POST /albums/:code/join` → `{ memberId, token, ... }`.
- Middleware `Authorization: Bearer <token>` sur routes protégées (upload, etc.).
- Upload : accepter `X-Client-Upload-Id` ; contrainte unique `(member_id, client_upload_id)`.
- Rate limit : middleware (ex. `@fastify/rate-limit`) sur `POST .../photos`.
- Logs : pino JSON ; requestId ; compteurs uploads (prom-client ou équivalent léger).
- Erreurs : classes `AppError` + handler global ; codes métier stables ; jamais de stack dans les réponses.

### Tooling (dès E2)

- Prettier + ESLint + Husky + lint-staged.
- GitHub Actions : workflow `api-ci.yml` sur push/PR (lint, typecheck, test avec Testcontainers).
- Testcontainers dans la suite de tests (pas de mocks seuls pour les parcours critiques DB/MinIO).

### Mobile (`apps/mobile`)

- Stocker le **token** membre en SecureStore après join.
- Générer un **UUID v4** par tentative d'upload (`clientUploadId`).
- Import des types et schémas depuis `@flashgap/shared` uniquement (pas de `src/api/types/` dupliqués).
- Client HTTP : `ApiResult<T>` ; `src/errors/user-messages.ts` ; pas de retry sur `QUOTA_EXCEEDED` / `UNAUTHORIZED`.

### Infra

- Deux configs : `.env.development` (local / docker) et `.env.production` (VPS).
- Pas d'environnement staging intermédiaire.
- **Reverse proxy prod** : nginx sur l'hôte (VPS partagé, ex. otrom.fr) ; overlay Caddy réservé au dev local ou VPS dédié (`deploy.sh --with-caddy`).

### Hors scope V0 (inchangé)

- OpenAPI comme source de vérité → non retenu pour V0 (Zod dans `shared` suffit).
- Backup / snapshot VPS → non retenu.

## Prochaines mises à jour roadmap

- E2-US1 : monorepo workspaces, `packages/shared`, Husky, Prettier, CI, Testcontainers.
- E2-US2 : modèle d'erreurs API (avant ou en parallèle des endpoints métier).
- E2-US4 (join) : token membre au join.
- E3 : rate limit, idempotence, pino + métriques.
- E4-US2 : client API + erreurs typées.
- E6 : mapping erreurs upload / réseau.
- E9-US3 : décision iOS inchangée (checklist explicite).
