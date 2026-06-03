# Conventions — package partagé `@flashgap/shared`

Décision **BP1** : une lib interne du monorepo expose **schémas Zod** et **types TypeScript** consommés par l’API et le mobile.

## Structure cible

```
flashgap/
├── package.json              # workspaces
├── packages/
│   └── shared/
│       ├── package.json        # name: "@flashgap/shared"
│       ├── tsconfig.json       # extends ../../tsconfig.base.json
│       └── src/
│           ├── index.ts        # réexport public
│           ├── schemas/        # Zod (source de vérité)
│           │   ├── album.ts
│           │   ├── member.ts
│           │   ├── photo.ts
│           │   └── errors.ts
│           └── types/          # z.infer ou alias explicites
├── services/
│   └── api/                    # dependency: @flashgap/shared
└── apps/
    └── mobile/                 # dependency: @flashgap/shared
```

## Règles

1. **Zod dans `packages/shared` uniquement** — pas de schéma dupliqué dans `services/api` ou `apps/mobile`.
2. **Types dérivés** — `export type JoinAlbumResponse = z.infer<typeof JoinAlbumResponseSchema>` dans `shared`, importés partout.
3. **Pas de code runtime lourd dans shared** — pas de Fastify, pas de React ; Zod + types + constantes (codes erreur, limites) seulement.
4. **Versioning** — packages internes en `workspace:*` (pnpm/npm/yarn workspaces).
5. **Mobile** — Metro / Expo doit résoudre le workspace (config `watchFolders` / `transpilePackages` si nécessaire).

## Workspaces (racine)

```json
{
  "private": true,
  "workspaces": ["packages/*", "services/*", "apps/*"]
}
```

Scripts racine recommandés : `npm run typecheck`, `npm run lint`, `npm test` (orchestrent les packages).

## Flux d’ajout d’un endpoint

1. Ajouter / modifier le schéma Zod dans `packages/shared/src/schemas/`.
2. Exporter le type depuis `packages/shared/src/index.ts`.
3. API : `safeParse` avec le schéma importé ; handler typé avec `z.infer`.
4. Mobile : client HTTP typé avec le même type de réponse.
5. Test : au moins un test côté API ; test parser côté mobile si logique client.

## Ce qui reste hors de `shared`

- Logique métier, repositories, accès DB, MinIO.
- Composants UI, hooks React Native, `expo-camera`.
- Config Fastify, middlewares, variables d’environnement serveur.

## Checklist PR

- [ ] Schéma + type exportés depuis `@flashgap/shared`
- [ ] Aucune redéfinition du même contrat dans api ou mobile
- [ ] `npm run typecheck` vert à la racine (ou dans chaque package touché)
