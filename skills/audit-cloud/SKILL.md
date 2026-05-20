---
name: audit-cloud
description: Audit d'un projet cloud (selfhostable) — détecte les couches présentes (serveur/web/desktop/worker/DB), audite chacune via SSOT, et surtout signale les incohérences inter-couches (contrats dupliqués, auth divergente, types non synchronisés). Mode audit philosophy §8 — pas d'auto-modification.
---

# /audit-cloud

Skill **audit** : revue d'un projet cloud selfhostable existant. Approche **système** : détecte les couches, audite chacune par renvoi aux SSOT/skills spécifiques, **et signale les incohérences inter-couches** que les audits par couche isolée manqueraient.

Si le projet n'a qu'une seule couche → renvoi à l'audit correspondant (`/audit-site-vitrine`, `/audit-app-desktop`).
Si le projet est vide → `/bootstrap-cloud`.

> ⚠️ **v0.1 ébauche** — la grille couvre les axes principaux ; certaines SSOT par langage manquent encore (`go.md`, `php.md`). Pour les couches dans ces langages, l'audit reste partiel et signale au lieu de prescrire.

## Pré-requis — SSOT à charger

- `~/.code-conform/docs/architecture/00-philosophy.md` — mode audit (§8), invariants.
- `~/.code-conform/docs/architecture/typescript.md`, `rust.md` — selon couches détectées.
- `~/.code-conform/docs/architecture/ui.md` — pour couches client.
- `~/.code-conform/skills/audit-design-system/SKILL.md` — DS sur clients web/desktop.
- `~/.code-conform/skills/audit-site-vitrine/SKILL.md`, `audit-app-desktop/SKILL.md` — sous-audits par couche.
- `docs/conventions.md` du projet si présent.

## Étape 1 — Cartographie système

Inspecter sans modifier. Détecter les couches **réellement** présentes :

```
Indices de détection :
- Serveur :  Cargo.toml + src/main.rs / go.mod + main.go / package.json + (Hono/Elysia/Fastify) / composer.json (Laravel/Symfony)
- Web :      package.json avec react/vue/svelte + vite ou next ou nuxt ou astro
- Desktop :  src-tauri/ ou package electron
- Mobile :   gen/android, gen/apple (Tauri Mobile), ou React Native, ou Flutter
- Worker :   dossier worker/, ou commands cron dans le serveur
- DB :       migrations/, schema.sql, compose.dev.yaml service postgres/mysql/sqlite
- Cache/queue : compose service redis/nats/rabbitmq
- Search :   compose service meilisearch/typesense/elasticsearch
- Vector :   compose service qdrant, ou pgvector extension
```

Restituer la **carte système** en 5-10 lignes :

```
Projet : <nom>
Couches détectées :
- Serveur : <langage + framework + version>
- Client web : <stack>
- Client desktop : <Tauri | aucun>
- Worker : <même langage que serveur | aucun>
- DB : <type + migrations versionnées ? oui/non>
- Services annexes : <redis, meilisearch, …>
Tooling monorepo : <pnpm | Cargo | Makefile + dossiers | mix>
Contrat inter-couches : <OpenAPI codegen | tRPC | packages TS partagé | manuel dupliqué (RED FLAG)>
Auth : <où vit-elle ?>
Déploiement : <compose.dev only | + compose.prod | autre>
```

## Étape 2 — Grille d'audit système

### A — Topologie monorepo

- [ ] Tooling monorepo cohérent avec stacks présentes (cf. `bootstrap-cloud` Q5).
- [ ] Couches dans des dossiers clairs au top-level (`server/`, `web/`, `worker/`, `desktop/`).
- [ ] Pas de couches mélangées dans un même dossier (`src/` racine qui contient server + web = écart majeur, sauf signal acté).
- [ ] `Makefile` racine ou équivalent (`justfile`, `Taskfile.yaml`) qui orchestre `dev`, `build`, `test`, `migrate`.
- [ ] `README.md` racine documente la topologie en 10 lignes max.

### B — Couche serveur (renvoi langage doc)

- [ ] Langage cohérent avec le métier (perf-critique → Go/Rust ; productivité dev pur → Node/TS ; legacy équipe → PHP).
- [ ] Framework HTTP idiomatique (pas de réinvention).
- [ ] Endpoint `/health` ou `/readyz`.
- [ ] Logs structurés (JSON ou tracing) — pas de `println`/`console.log` en prod.
- [ ] Configuration via env (12-factor), validée au démarrage.
- [ ] Migrations DB versionnées et appliquées par le serveur ou un binaire dédié — pas "à la main".
- [ ] Tests d'intégration sur endpoints clés (pas obligatoire en v0.1 mais signaler si absent).

### C — Couche web (renvoi `audit-site-vitrine` ou `audit-saas`)

Appliquer le sous-audit approprié selon profil :
- Pages mixtes statiques + îlots → `/audit-site-vitrine`.
- App dynamique post-login → `/audit-saas` (à venir).

Spécifique au contexte cloud :
- [ ] Le client consomme les contrats générés (cf. axe F), pas des types manuels.
- [ ] Pas de duplication des règles de validation entre serveur et client (Zod / OpenAPI = SSOT).

### D — Couche desktop (renvoi `audit-app-desktop`)

Si présent → appliquer sous-audit complet. Spécifique contexte cloud :
- [ ] Le client desktop consomme les mêmes contrats que le web (pas de divergence).
- [ ] Auth alignée avec la stratégie centrale (cf. axe G).

### E — Persistance et migrations

- [ ] Migrations versionnées (numérotation + nom explicite).
- [ ] Un seul système de migration (pas Prisma + sqlc + brut mélangés).
- [ ] Pas de migration "destructive" sans procédure documentée (drop column, rename).
- [ ] Seed dev séparé des migrations prod (`db/seeds/` ou équivalent).
- [ ] Backup strategy documentée (au moins une ligne dans `docs/conventions.md`).

### F — Contrats inter-couches (CRITIQUE INVARIANT philosophy §5)

- [ ] **Un seul SSOT** pour les types/validation traversant les couches :
  - OpenAPI 3.1 + codegen TS, **ou**
  - Package TS partagé avec Zod (full-JS uniquement), **ou**
  - tRPC (full-JS, RPC pur), **ou**
  - proto + codegen.
- [ ] Codegen automatisé (`make contracts` ou pré-commit ou CI) — pas "régénérer à la main quand on y pense".
- [ ] **RED FLAG** : DTO copiés manuellement entre serveur et client = écart majeur, premier lot de correction.
- [ ] Frontière Zod côté client en sortie d'appel API (parse de la réponse) si codegen ne pose pas déjà la garantie runtime.

### G — Auth transverse

- [ ] Une seule stratégie auth dans le projet (pas session côté web + JWT côté desktop sans raison).
- [ ] Source de vérité côté serveur — clients consomment des tokens/sessions, ne les valident pas indépendamment.
- [ ] Refresh / révocation documentée.
- [ ] Secrets de signature (JWT) dans env, pas en dur.
- [ ] CORS configuré explicitement si clients distincts du serveur (pas `*` en prod).

### H — Déploiement et sécurité runtime

- [ ] `compose.dev.yaml` lance la stack complète en local (`docker compose up` → tout fonctionne).
- [ ] `.env.example` exhaustif, `.env` réel **gitignored**.
- [ ] Aucun secret en dur dans le code (`grep` rapide sur tokens probables).
- [ ] Dockerfiles multi-stage (build → runtime minimal).
- [ ] Healthchecks dans compose (`healthcheck:` par service).
- [ ] Reverse proxy si exposé (Caddy/Traefik/Nginx) — non obligatoire mais signaler si exposé direct.
- [ ] Volumes persistants déclarés pour DB et fichiers user.

### I — DX (Developer Experience)

- [ ] `make dev` (ou équivalent) lance toute la stack en une commande.
- [ ] `make test` exécute tests pertinents par couche.
- [ ] Logs lisibles en dev (pas tout en JSON compact obligatoire).
- [ ] Hot reload côté web et serveur si possible (air pour Go, cargo-watch pour Rust, vite pour web).
- [ ] Documentation README "first 10 minutes" : clone → make dev → app accessible.

### J — `docs/conventions.md`

- [ ] Présent à la racine du projet.
- [ ] Documente : couches actives, stacks retenues, choix de contrat, stratégie auth, stratégie migrations, contraintes de déploiement.
- [ ] Justifie les écarts vs default code-conform (ex: "PHP retenu car équipe Symfony", "Pas de pnpm workspace car Rust+Go").

## Étape 3 — Rapport

```
# Audit cloud — <projet>

## Carte système
[5-10 lignes carte couches + tooling + contrat + auth + deploy]

## Écarts inter-couches (priorité haute)
1. <contrat dupliqué manuellement, types serveur ≠ client> — fichiers
2. <auth divergente entre web et desktop>
...

## Écarts par couche
### Serveur
1. ...
### Web
1. ...
### Desktop
1. ...

## Écarts transverses (déploiement, secrets, DX)
1. ...

## Conforme
- ...

## Suggestions hors écart
- ...
```

## Étape 4 — Correction interactive

**INVARIANT** — aucune modification sans accord explicite.

Ordre de lots **important** (inter-couches d'abord, puis par couche) :

1. **Contrat unifié** — si DTO dupliqués, poser le codegen (OpenAPI + script) avant toute autre correction. Premier lot car débloque tout le reste.
2. **Auth alignée** — si divergence, choisir la stratégie unique, refactor clients pour consommer.
3. **Migrations versionnées** — si à la main, poser un système (sqlc, Atlas, Prisma migrate, sqlx-migrate selon langage serveur).
4. **Secrets / `.env`** — sortir tout secret en dur, créer `.env.example` propre.
5. **Topologie / monorepo** — réorganisation si couches mélangées dans un même dossier.
6. **Sous-audit DS** — chaîner `/audit-design-system` sur `web/components/`.
7. **Sous-audit web / desktop** — chaîner les skills par couche.
8. **DX `Makefile`** — poser cibles standard.
9. **`docs/conventions.md`** — créer ou compléter.

Pour chaque lot : fichiers concernés, diff représentatif, accord, application, type-check post-lot.

## Anti-patterns du skill

- ✗ Auto-modification sans accord.
- ✗ Auditer chaque couche en silo en ignorant les incohérences inter-couches — c'est l'inverse de la raison d'être de ce skill.
- ✗ Imposer une stack (ex: "réécris ton PHP en Node") — l'utilisateur a un signal, respecter et capturer dans `conventions.md`.
- ✗ Recommander Kubernetes si compose suffit.
- ✗ Recommander GraphQL "par défaut".
- ✗ Inventer un seuil "trop de services" — philosophy §9.
- ✗ Auditer la qualité du code business interne au-delà des frontières (frontière, contrat, auth) — c'est le rôle des linters et des audits par couche.
- ✗ Demander de tout réécrire en monorepo Turbo si Makefile + dossiers fonctionnent.

## Out of scope (renvoi)

- **DS isolé** → `/audit-design-system`.
- **Couche web isolée** → `/audit-site-vitrine` ou `/audit-saas`.
- **Couche desktop isolée** → `/audit-app-desktop`.
- **CI/CD pipeline** → sujet propre.
- **Observabilité fine** → sujet propre.
- **Performance fine** (profiling, latence p99) → signal utilisateur requis.
- **Sécurité offensive / pentest** → hors scope, sujet spécialisé.

## SSOT manquantes (à produire pour audit complet)

- `docs/architecture/go.md` — pour audits couche serveur Go.
- `docs/architecture/php.md` — pour audits couche serveur PHP.
- `docs/architecture/python.md` — si Python cible.
- `docs/architecture/contracts.md` (méta) — OpenAPI vs proto vs TS partagé, conventions codegen.
- `docs/architecture/database.md` (éventuel) — conventions migrations, naming SQL, choix PG/SQLite par contexte.

À traquer dans `BACKLOG.md`.
