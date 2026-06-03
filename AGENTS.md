# AGENTS.md — Flashgap

Instructions pour tout agent ou développeur sur ce dépôt.

## TypeScript

- **Tout le code applicatif est en TypeScript strictement typé.**
- **Ne jamais utiliser `any`** (ni `as any`, ni désactiver la règle ESLint).
- Suivre [docs/conventions-typescript.md](docs/conventions-typescript.md).
- Hériter de [tsconfig.base.json](tsconfig.base.json) pour chaque package (`packages/shared`, `services/api`, `apps/mobile`).
- Contrats API : **`@flashgap/shared`** (Zod + types) — [docs/conventions-shared.md](docs/conventions-shared.md). Ne pas dupliquer les types entre API et mobile.
- Avant de terminer une tâche : `npm run lint` et `npm run typecheck` au vert (0 erreur, 0 warning).

## Qualité (roadmap)

Chaque tâche dans [roadmap/](roadmap/) impose **TDD**, **linter**, **typecheck**, **non-régression** et **pas de `any`**. Voir [roadmap/README.md](roadmap/README.md#standards-qualité).

Pour exécuter la **prochaine tâche** `todo` de bout en bout : skill **`flashgap-roadmap-task`** (`.cursor/skills/flashgap-roadmap-task/SKILL.md`).

- **Prettier** + ESLint ; **Husky** (lint + typecheck + tests) à chaque commit.
- **CI GitHub Actions** (API) dès E2 : lint, typecheck, tests avec **Testcontainers**.
- Validation & types partagés : **`@flashgap/shared`** — [docs/conventions-shared.md](docs/conventions-shared.md), [docs/conventions-api.md](docs/conventions-api.md).
- Erreurs : enveloppe `{ error, code, details? }`, `ApiResult<T>` mobile — [docs/conventions-erreurs.md](docs/conventions-erreurs.md) (BP13).

## Décisions techniques

Registre : [docs/decisions-techniques.md](docs/decisions-techniques.md) (auth token, idempotence upload, rate limit, observabilité, env dev/prod, etc.).

## Produit

Cadrage et invariants : [docs/cadrage-flashgap-like.md](docs/cadrage-flashgap-like.md).

## Périmètre

- Mobile : Expo dev build + `expo-camera` (pas Expo Go en prod).
- Backend : Fastify + Postgres + MinIO sur VPS.
- Environnements : **dev local** + **prod** (VPS unique).
- CI API dès E2 ; CI mobile optionnelle avant V1.
