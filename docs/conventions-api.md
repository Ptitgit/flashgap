# Conventions API — Flashgap

Complète [decisions-techniques.md](decisions-techniques.md) (BP1, BP2, BP8, BP12) et [conventions-shared.md](conventions-shared.md).

## Validation (Zod)

- Schémas dans **`@flashgap/shared`** ; l'API importe et appelle `safeParse` sur body, query, params.
- Réponses JSON : schémas Zod + types `z.infer` exportés depuis `shared`.
- Erreurs : enveloppe et codes — voir [conventions-erreurs.md](conventions-erreurs.md).
- Erreurs 400 : `VALIDATION_ERROR` + `details` (sans fuite de stack).

Le mobile importe les **mêmes types** depuis `@flashgap/shared` (pas de duplication locale).

## Auth membre

| Étape | Comportement |
| --- | --- |
| Join | `POST /albums/:code/join` → `{ memberId, albumId, pseudo, token, expiresAt? }` |
| Upload / routes membre | `Authorization: Bearer <token>` |
| Organisateur | `X-Organizer-Secret` ou équivalent sur `PATCH /albums/:id/reveal` |

Token : JWT signé (HS256, secret env) ou token opaque stocké en DB — choix d'implémentation, documenté dans le README API.

## Upload

| Header | Obligatoire | Rôle |
| --- | --- | --- |
| `Authorization` | Oui | Token membre |
| `X-Client-Upload-Id` | Oui | UUID v4 — idempotence |
| `Content-Type` | Oui | `image/jpeg` |

Contrainte DB : `UNIQUE (member_id, client_upload_id)`. Rejeu même id → `200` avec la même `{ photoId }` (pas de doublon).

## Rate limiting (E3)

- `POST /albums/:albumId/photos` : limite par **membre** et par **IP** (seuils dans `.env`, ex. 30 req / 10 min / membre).
- Réponse `429` avec `Retry-After` si possible.

## Observabilité

- Logger : **pino** (JSON en prod).
- Chaque requête : `requestId` (header `X-Request-Id` ou généré).
- Métriques minimales : `uploads_success_total`, `uploads_error_total`, `rate_limit_hits_total` (prom-client ou compteurs exposés sur `/metrics` protégé ou logs périodiques en V0).

## Environnements

| Env | Usage |
| --- | --- |
| `development` | Machine locale + Docker Compose |
| `production` | VPS unique |

Pas de staging. Fichiers : `.env.development`, `.env.production` (jamais commités) ; `.env.example` versionné.
