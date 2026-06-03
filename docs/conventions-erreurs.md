# Conventions — gestion des erreurs

Complète [decisions-techniques.md](decisions-techniques.md) (BP13) et [conventions-api.md](conventions-api.md).

Objectif : erreurs **prévisibles**, **typées**, **sans fuite** (stack, secrets), UX mobile **compréhensible** en soirée (réseau instable).

---

## 1. Modèle commun (API ↔ mobile)

### Enveloppe JSON d'erreur (API)

Toute réponse d'erreur HTTP (`4xx`, `5xx`) :

```json
{
  "error": "Message lisible pour l'utilisateur ou le client",
  "code": "MACHINE_READABLE_CODE",
  "details": {}
}
```

| Champ | Type | Règles |
| --- | --- | --- |
| `error` | `string` | Message court ; pas de stack trace |
| `code` | `string` | Stable, `SCREAMING_SNAKE_CASE` ; le mobile s'en sert pour l'i18n / le comportement |
| `details` | `object` | Optionnel ; ex. erreurs Zod `{ field, message }[]` pour `400` |

Type et schéma : `ErrorResponseSchema` / `ErrorResponse` dans `@flashgap/shared` (import API + mobile).

### Codes métier V0 (liste initiale)

| `code` | HTTP | Usage |
| --- | --- | --- |
| `VALIDATION_ERROR` | 400 | Body/query invalide (Zod) |
| `ALBUM_NOT_FOUND` | 404 | Code album inconnu |
| `MEMBER_NOT_FOUND` | 404 | Membre inconnu |
| `UNAUTHORIZED` | 401 | Token absent ou invalide |
| `FORBIDDEN` | 403 | Reveal gate, mauvais secret organisateur |
| `PSEUDO_TAKEN` | 409 | Pseudo déjà pris |
| `QUOTA_EXCEEDED` | 429 ou 403 | 100 photos / membre |
| `RATE_LIMITED` | 429 | Trop d'uploads (BP8) |
| `PAYLOAD_TOO_LARGE` | 413 | JPEG trop gros |
| `UNSUPPORTED_MEDIA` | 415 | Pas JPEG |
| `INTERNAL_ERROR` | 500 | Erreur non gérée |

Nouveau cas métier → **ajouter le code** ici + test + type mobile avant merge.

---

## 2. Backend (Fastify)

### Hiérarchie d'erreurs (classes typées)

```ts
// Exemple de forme — pas de any sur cause
abstract class AppError extends Error {
  abstract readonly statusCode: number;
  abstract readonly code: string;
  readonly details?: Record<string, unknown>;
}
```

- Erreurs **métier** : `throw new QuotaExceededError()` → handler → JSON + bon HTTP.
- Erreurs **inattendues** : catch global → log complet (pino) + réponse `500` + `INTERNAL_ERROR` **sans** détail interne.

### Handler global

- Un seul `setErrorHandler` Fastify.
- `AppError` → réponse structurée.
- `ZodError` → `400` + `VALIDATION_ERROR` + `details.issues`.
- Autre `Error` → log `err` + `requestId` ; client reçoit message générique.

### Règles

| Faire | Ne pas faire |
| --- | --- |
| `throw` des erreurs typées dans les services | `reply.send({ error: 'oops' })` dispersé |
| Logger cause + `requestId` côté serveur | Renvoyer `err.message` SQL/MinIO au client |
| Mapper MinIO/DB vers codes métier | Exposer clés S3 ou requêtes SQL |
| Tester chaque code avec supertest | Tester uniquement le `500` |

### Lien observabilité (BP7)

- Chaque `5xx` : log niveau `error` + `uploads_error_total` si upload.
- Chaque `4xx` métier attendu : log niveau `warn` ou `info` (pas d'alerte).

---

## 3. Mobile (Expo)

### Client HTTP typé

```ts
type ApiResult<T> =
  | { ok: true; data: T }
  | { ok: false; error: ApiErrorResponse };

// ApiErrorResponse = même forme que l'enveloppe API
```

- `fetch` / client central : parse JSON ; si `!response.ok` → `ok: false` avec `code` typé (union string littérale alignée sur le tableau ci-dessus).
- **Jamais** `catch (e: any)` — `unknown` + garde.

### Messages utilisateur

| Source | UX |
| --- | --- |
| `NETWORK_ERROR` (local) | « Pas de réseau — photo en attente d'envoi » |
| `RATE_LIMITED` / `QUOTA_EXCEEDED` | Message explicite + pas de retry inutile |
| `UNAUTHORIZED` | Proposer de rejoindre l'album à nouveau |
| `VALIDATION_ERROR` | Message générique ou champ si `details` |
| `INTERNAL_ERROR` | « Problème serveur — réessaie dans un instant » |

Mapper `code` → string UI dans `src/errors/user-messages.ts` (une fonction, exhaustive `switch` sur l'union des codes).

### Upload / file d'attente (E6)

| État | Cause typique |
| --- | --- |
| `failed` + retry auto | `NETWORK_ERROR`, `5xx`, timeout |
| `failed` + pas de retry | `QUOTA_EXCEEDED`, `UNAUTHORIZED`, `415` |
| `failed` + retry manuel | après épuisement backoff |

Conserver le **`clientUploadId`** sur retry (idempotence).

### Erreurs caméra / permissions

- Permission refusée : écran dédié avec lien paramètres (pas de crash).
- Échec capture : message + bouton reprendre ; log dev seulement.

### Ce qui est reporté V2 (cadrage)

- Error Boundary React globale avancée.
- Crash reporting (Sentry, etc.).

---

## 4. Tests (TDD)

### API

- Par endpoint critique : au moins un test `4xx` avec `{ code }` attendu.
- Test handler global : erreur inconnue → `500` + pas de stack dans le body.

### Mobile

- Tests unitaires du parser : body JSON erreur → `ApiResult` `ok: false`.
- Tests queue upload : `QUOTA_EXCEEDED` ne relance pas indéfiniment.

---

## 5. Checklist PR

- [ ] Nouveau `code` documenté dans ce fichier
- [ ] Schéma Zod réponse erreur (si variante `details`)
- [ ] Schéma + type mis à jour dans `@flashgap/shared`
- [ ] Message utilisateur ajouté dans `user-messages.ts`
- [ ] Test rouge → vert pour le nouveau cas
