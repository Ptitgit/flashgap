---
name: flashgap-roadmap-task
description: >-
  Execute the next Flashgap V0 roadmap task end-to-end: one git branch per
  task, pick todo task, review and improve it, TDD (red-green-refactor),
  implement, run quality gates, mark done. Use when the user asks to do the next
  roadmap task, continue the roadmap, implement US/Epic tasks, or run
  flashgap-roadmap-task.
---

# Flashgap — prochaine tâche roadmap

Workflow **une tâche à la fois** pour [roadmap/](../../roadmap/). Respecter [AGENTS.md](../../AGENTS.md) et les docs `docs/conventions-*.md`.

## 0. Trouver la tâche

```bash
python3 .cursor/skills/flashgap-roadmap-task/scripts/next-task.py
```

- Sortie : chemin relatif (ex. `roadmap/e2-backend-albums-membres/E2-US1-schema-postgres.md`)
- Si `in_progress` : reprendre cette tâche (ne pas en prendre une autre)
- Si `NO_TASK` : toutes les tâches sont `done` ou `blocked` — stop et résumer

Ordre des epics : E1 → E2 → E3 → E4 → E5 → **E8** → E6 → E7 → E9 (cf. [roadmap/README.md](../../roadmap/README.md)).

## 1. Lire et cadrer

1. Lire le fichier tâche **en entier** + README de l’epic.
2. Lire les dépendances (`**Dépendances**`) : si une US prérequise n’est pas `done`, **ne pas coder** — indiquer le bloqueur.
3. Passer le statut à `in_progress` dans le tableau :

   `| **Statut** | `in_progress` |`

## 1b. Branche Git (obligatoire — une branche par tâche)

**Avant tout code ou test**, créer une branche dédiée à cette US uniquement.

### Nom de branche

Format : `task/<ID-minuscule>-<slug-court>`

Exemples :

- `E2-US1` → `task/e2-us1-schema-postgres`
- `E4-US2` → `task/e4-us2-client-api-erreurs`

Le slug reprend le nom du fichier tâche sans le préfixe `E*-US*`.

### Commandes

```bash
git fetch origin
git checkout main
git pull origin main
git checkout -b task/e2-us1-schema-postgres
```

(Adapter `main` si la branche par défaut est `master`.)

### Règles

| Règle | Détail |
| --- | --- |
| **Une US = une branche** | Ne jamais cumuler deux tâches roadmap sur la même branche |
| **Pas de commit sur `main`** | Tout le travail TDD + implémentation se fait sur la branche `task/...` |
| **Reprise `in_progress`** | Si la tâche est déjà `in_progress`, retrouver ou recréer la branche `task/...` correspondante ; ne pas en ouvrir une autre |
| **Fin de tâche** | Commit(s) sur la branche ; rappeler à l’utilisateur le nom de branche pour PR / merge (ne pas merger sans demande explicite) |
| **Changements roadmap** | Mise à jour du `.md` tâche (`in_progress` / `done`) : commit sur la **même** branche `task/...` |

### Message de commit suggéré

```
task(E2-US1): schéma Postgres et package shared

EOF
```

Préfixe `task(<ID>):` + résumé court orienté « pourquoi ».

## 2. Challenger la tâche (court)

Avant tout code, noter à l’utilisateur (3–8 lignes max) :

- Ambiguïtés ou critères manquants
- Proposition d’**amélioration** du `.md` si ça évite un malentendu (scope, tests, edge cases)

**Règles :**

- Amélioration **petite et dans le périmètre** → mettre à jour le fichier tâche, puis continuer.
- Changement **hors scope / nouvelle US** → proposer une nouvelle tâche roadmap ; ne pas l’implémenter sans accord.
- Si infra pure (E1-US1 VPS) sans code repo : adapter TDD (script smoke versionné, checklist) — pas bloquer.

## 3. TDD — rouge

1. Identifier le package : `packages/shared`, `services/api`, `apps/mobile`, `infra/`.
2. **Écrire d’abord** le(s) test(s) ou smoke test qui échoue(nt).
3. Lancer les tests → **confirmer l’échec** (rouge documenté en une phrase).
4. Pas de `any` ; types depuis `@flashgap/shared` si contrat API.

Commandes typiques (depuis la racine du monorepo, quand les packages existent) :

```bash
npm test
npm run typecheck
npm run lint
```

## 4. Implémenter — vert

1. Code minimal pour faire passer les tests.
2. Refactor si besoin ; relancer tests + lint + typecheck.
3. Remplir **tous** les critères d’acceptation de la tâche (fonctionnels + TDD + linter + typage + non-régression).

## 5. Valider les gates

| Gate | Action |
| --- | --- |
| TDD | Tests verts ; rouge puis vert démontré |
| Linter | `npm run lint` — 0 erreur, 0 warning sur fichiers touchés |
| Typecheck | `npm run typecheck` — 0 erreur ; pas de `any` |
| Non-régression | Suite du périmètre 100 % verte |
| Erreurs | Codes / `ApiResult` selon [conventions-erreurs.md](../../docs/conventions-erreurs.md) |

Tâches **infra sans TS** : `shellcheck`, `docker compose config`, script smoke documenté.

## 6. Clôturer la tâche

Dans le fichier `.md` de la tâche :

1. `| **Statut** | `done` |`
2. Cocher **tous** les `- [ ]` des sections :
   - Critères d’acceptation (y compris TDD, linter, typage, non-régression)
   - Anti-régression (si présente)
   - Definition of done

Message final à l’utilisateur :

- ID tâche (ex. E2-US3)
- **Branche Git** (ex. `task/e2-us3-creer-album`) et rappel PR / merge si besoin
- Résumé 2–3 phrases de ce qui a été livré
- Commandes exécutées
- Lien vers la **prochaine** tâche (`next-task.py`)

**Ne pas** enchaîner la tâche suivante sauf demande explicite (« enchaîne », « continue », « next »).

## Anti-patterns

- Travailler sur `main` / `master` sans branche `task/...`
- Réutiliser une branche pour une autre US
- Sauter le rouge TDD
- Marquer `done` avec tests rouges ou lint en échec
- Dupliquer des types hors `@flashgap/shared`
- Implémenter plusieurs US dans une seule passe sans validation intermédiaire
- Merger ou push sans demande explicite de l’utilisateur
- Commit : autorisé sur la branche `task/...` en fin de tâche (ou si l’utilisateur le demande) ; jamais de commit sur `main` pour le code de l’US

## Références projet

| Sujet | Fichier |
| --- | --- |
| Cadrage produit | [docs/cadrage-flashgap-like.md](../../docs/cadrage-flashgap-like.md) |
| Décisions BP | [docs/decisions-techniques.md](../../docs/decisions-techniques.md) |
| Shared / Zod | [docs/conventions-shared.md](../../docs/conventions-shared.md) |
| Erreurs | [docs/conventions-erreurs.md](../../docs/conventions-erreurs.md) |
| TypeScript | [docs/conventions-typescript.md](../../docs/conventions-typescript.md) |
