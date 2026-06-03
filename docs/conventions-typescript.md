# Conventions TypeScript — Flashgap

Règle absolue du projet : **tout est typé, `any` est interdit**.

## Principes

1. **`strict: true`** dans chaque `tsconfig.json` (hériter de la base racine si monorepo).
2. **Interdiction de `any`** — ni explicite ni implicite contourné (`as any`, `@ts-ignore` pour masquer un `any`).
3. **`unknown` + garde de type** pour toute donnée externe (JSON API, `AsyncStorage`, params route).
4. **Contrats API** : Zod + types dans `packages/shared` (`@flashgap/shared`), importés par API et mobile — cf. [conventions-shared.md](conventions-shared.md) et BP1.
5. **`npm run typecheck`** (`tsc --noEmit`) obligatoire avant de marquer une tâche `done`.

## `tsconfig` minimal (référence)

```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "forceConsistentCasingInFileNames": true,
    "skipLibCheck": true
  }
}
```

## ESLint (obligatoire dès le premier package TS)

- `@typescript-eslint/no-explicit-any`: `error`
- `@typescript-eslint/no-unsafe-assignment`: `error`
- `@typescript-eslint/no-unsafe-member-access`: `error`
- `@typescript-eslint/no-unsafe-call`: `error`
- `@typescript-eslint/no-unsafe-return`: `error`

Le script `npm run lint` doit inclure ESLint **et** échouer sur toute utilisation de `any`.

## Alternatives à `any`

| Situation | Utiliser |
| --- | --- |
| JSON non validé | `unknown` + schéma Zod / type guard |
| Erreur catch | `unknown` + `instanceof Error` |
| Objet dynamique | `Record<string, unknown>` ou interface précise |
| Générique lib tierce | Paramètre générique contraint ou wrapper typé |
| Mock test | `jest.Mocked<T>`, `satisfies`, types dédiés |

## Exceptions

Aucune exception pour `any` en production. En test, préférer des factories typées ; si un cast est indispensable, `as unknown as T` avec justification en commentaire **et** type guard de test — jamais `as any`.

## Commandes

| Package | Typecheck |
| --- | --- |
| Shared | `cd packages/shared && npm run typecheck` |
| API | `cd services/api && npm run typecheck` |
| Mobile | `cd apps/mobile && npm run typecheck` |
| Racine | `npm run typecheck` (workspaces — recommandé) |

`lint` peut enchaîner `typecheck` : `"lint": "eslint . && tsc --noEmit"`.
