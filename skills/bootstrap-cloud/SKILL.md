---
name: bootstrap-cloud
description: Bootstrap d'un projet cloud (selfhostable) pensé comme un monorepo système — serveur + clients (web/desktop/mobile) + DB + worker + contrats. Cadrage interactif des couches et stacks avec contraintes croisées. Ébauche v0.1.
---

# /bootstrap-cloud

Skill **bootstrap** : crée from scratch un projet **cloud selfhostable** (style Navidrome, Mealie, mais sur tes conventions). Pense le projet comme un **système monorepo** dont les couches sont **co-décidées**, pas une somme de skills indépendants collés.

Si le projet existe → sors et propose `/audit-cloud`.
Si le projet est une simple app desktop sans serveur → `/bootstrap-app-desktop`.
Si c'est un site vitrine sans backend custom → `/bootstrap-site-vitrine`.

> ⚠️ **v0.1 ébauche** — l'arborescence et les choix de stack ne sont pas exhaustifs. Itérer à l'usage. Les SSOT par langage (`go.md`, `php.md`, `python.md`) ne sont pas encore toutes posées : si une stack est choisie sans SSOT correspondante, capturer dans `docs/conventions.md` et l'utilisateur sera consulté pour les arbitrages détaillés.

## Pré-requis — SSOT à charger

- `~/.code-conform/docs/00-philosophy.md` — invariants, posture interactive (§1, §8), filtre fondamental (§4).
- `~/.code-conform/docs/languages/typescript.md` — si JS/TS dans le système.
- `~/.code-conform/docs/languages/rust.md` — si Rust dans le système.
- `~/.code-conform/docs/design/atomic-design.md` — si client web et/ou desktop.
- Skills compagnons (chaînables après ébauche) : `/bootstrap-app-desktop` (sous-bootstrap si couche desktop active). Direction artistique : `/design-system` (à venir).

## Philosophie du skill

Un projet cloud selfhostable **n'a pas** de stack par défaut universelle. Le default code-conform (TS partout) reste **legitime mais non imposé**. Le skill **arbitre** entre couches avec contraintes croisées, **ne décide pas seul**.

Trois principes :

1. **Couches co-décidées** — le choix d'une couche contraint les autres (ex: serveur Go → contrat OpenAPI codegen, pas Zod partagé).
2. **Monorepo réel ou structuré** — pnpm/Cargo workspace si stack homogène, sinon dossiers + Makefile racine. Pas de monorepo tool dogmatique.
3. **Une SSOT pour les types inter-couches** — soit OpenAPI/proto (codegen), soit package TS partagé (si full-JS). Jamais de duplication manuelle.

## Étape 1 — Détection

- Dossier vide ou contenant seulement `.git`, `README.md` → bootstrap pur.
- Présence de `package.json` racine, `Cargo.toml`, `go.mod`, sous-dossiers `server/` ou `web/` → sors, propose `/audit-cloud`.

## Étape 2 — Cadrage interactif

Cadrage en **phasage strict** (philosophy §8 INVARIANT) : métier → technique adaptée → récap → génération. Pas de bundle, pas de récap prématuré. Particulièrement critique ici où une question non répondue compromet la cohérence système. Capture chaque décision dans `docs/conventions.md` au fil de l'eau.

**Hard rule (philosophy §1 INVARIANT bloquant)** : aucune génération de fichier tant qu'une question reste ouverte. Pas de *"je commence le squelette, tu me diras après"*.

### Phase 1 — Métier (texte libre, bloquante, ne pose aucune autre question pendant ce temps)

**Q1 — Description métier (pure)**

Pose **uniquement** cette question et attends la réponse. Aucun QCM technique en parallèle, aucune mention d'artefacts techniques (couches, stack, contrats, déploiement).

Format type :

> Décris l'app cloud en 3-5 phrases :
> - Quel problème elle résout, pour qui ?
> - Comment les utilisateurs interagissent (web seulement ? + mobile ? + desktop ? + API publique ?) — *côté usage, pas côté technique*.
> - Quel type de données manipule-t-elle (média lourd, contenu textuel, données relationnelles, événements temps réel) ?
> - Volume attendu (utilisateurs concurrents, taille DB) si tu as une idée.
> - Inspirations (apps existantes type Navidrome, Mealie, etc.) — optionnel.
>
> Pas besoin de parler stack, framework, monorepo — je déduirai en phase 2 et te ferai valider.

### Phase 2 — Technique adaptée (après Phase 1 close)

Annonce d'abord ton inférence depuis le métier, puis pose les questions en QCM (`AskUserQuestion`) groupé par batch cohérent (couches, stack, contrats, déploiement).

Format type :

> Vu ce que tu décris, j'infère :
> - Couches probables : <ex: serveur HTTP + web + DB ; ajout worker si data-heavy ; ajout client desktop si signal>
> - Stack serveur probable : <ex: Node si CRUD productif ; Go/Rust si perf critique ; PHP si écosystème équipe>
> - DB probable : <ex: PostgreSQL si relations ; SQLite si selfhost mono-process ; pgvector si IA>
> - Contrat inter-couches : <inféré depuis combinaison stack>
>
> Confirme ou ajuste avant que je pose les choix non inférables.

**Q-techniques modèles** (à adapter au métier, ne propose pas tout systématiquement) :

### Q2 — Couches actives ?

Présenter le menu, l'utilisateur coche :

- [ ] **Serveur HTTP** (presque toujours oui)
- [ ] **Client web** (UI dans navigateur)
- [ ] **Client desktop** (Tauri — sous-bootstrap chaînable)
- [ ] **Client mobile** (Tauri Mobile / autre — typiquement reporté)
- [ ] **Worker / job runner** (tâches async, cron)
- [ ] **Base de données** (presque toujours oui — préciser type Q4)
- [ ] **Cache / queue** (Redis, NATS — signal réel requis)
- [ ] **Search engine** (Meilisearch, Typesense — signal réel)
- [ ] **Vector DB** (Qdrant, pgvector — signal IA/embeddings)

### Q3 — Stack par couche (contraintes croisées)

Pour chaque couche cochée :

**Serveur** :
- Node + Hono / Elysia / Fastify (default code-conform si pas de contrainte forte)
- Go + chi / echo (perf, single-binary friendly)
- Rust + axum (sécurité forte, perf, courbe longue)
- PHP + Laravel / Symfony (signal explicite, écosystème legacy)
- Autre (Python/Django, Elixir/Phoenix…) → demander la justification

**Client web** :
- React 19 + Vite (SPA) ou Next 15 (SSR si signal)
- Vue 3 + Vite ou Nuxt 4 si Vue-first
- Astro si pages mixtes statiques + îlots interactifs
- Pas de framework JS si site quasi-statique → renvoi `/bootstrap-site-vitrine`

**Client desktop/mobile** :
- Tauri (default code-conform) — chaîner `/bootstrap-app-desktop` comme sous-step ou différer.

**Base de données** :
- PostgreSQL (default selfhost, relations + JSONB + extensions pgvector si IA)
- SQLite (selfhost mono-process, fichier unique, backup trivial)
- MySQL/MariaDB (sur signal écosystème)
- Qdrant ou pgvector (vector dédié vs intégré PG)

**Worker** :
- Typiquement même langage que le serveur (partage des types/schémas).
- Exception : Go worker + Node serveur si CPU-bound côté worker uniquement.

### Q4 — Contrats inter-couches

Critère décisif : **codegen ou manuel ? jamais dupliqué.**

| Combinaison | Contrat recommandé |
|---|---|
| Serveur Node + Web/Desktop TS | Package TS partagé (`packages/contracts/`) avec Zod SSOT, ou tRPC si full Node + RPC pur |
| Serveur Go + Web/Desktop TS | OpenAPI 3.1 (codegen TS via openapi-typescript / orval / hey-api) |
| Serveur Rust + Web/Desktop TS | OpenAPI 3.1 (utoipa côté Rust) ou tauri-specta si client Tauri |
| Serveur PHP + Web TS | OpenAPI 3.1 (codegen) |

INVARIANT : **pas de DTO copié-collé entre couches**. Si l'utilisateur résiste au codegen, capter le signal dans `conventions.md` avec justification claire.

### Q5 — Tooling monorepo

| Stacks présentes | Tooling |
|---|---|
| Tout JS/TS | `pnpm workspaces` (ou `bun workspaces`). Turbo optionnel si plusieurs apps à builder en parallèle. |
| Tout Rust | Cargo workspace |
| Tout Go | go.work (Go workspaces) |
| Hétérogène (ex: Rust + Go + JS web) | Pas de monorepo tool global. Dossiers `server/`, `web/`, `worker/` + `Makefile` racine pour orchestrer (`make dev`, `make build`). |

### Q6 — Auth transverse

- Où vit-elle ? (côté serveur uniquement, pas dans les clients sauf consommation token)
- Stratégie : session cookie HttpOnly, JWT, OAuth provider (signal réel), passkeys.
- À capturer dans `conventions.md` — l'audit vérifiera la cohérence (pas d'auth dupliquée).

### Q7 — Déploiement

- **compose.dev.yaml** pour dev local (default).
- **Prod** : single-host Docker Compose (selfhost typique) ou multi-host (signal).
- Pas de Kubernetes par défaut (overhead injustifié pour selfhost).
- Secrets : `.env` versionné en `.env.example` uniquement, `.env` réel `.gitignore`.

### Phase 3 — Récap puis validation

**Pas de récap tant que les Q couches/stack/contrats/déploiement ne sont pas toutes répondues.** Présente la synthèse exhaustive (couches actives + stack par couche + contrat inter-couches + monorepo tooling + auth + déploiement) et demande validation explicite avant Étape 3.

## Étape 3 — Génération

Arborescence générée (les sections sans couche active sont omises) :

```
<projet>/
├─ server/                  # Couche serveur (langage Q3)
│  ├─ src/ ou main.go ou Cargo.toml + src/
│  ├─ migrations/           # SQL versionnées (si DB relationnelle ici)
│  └─ README.md
├─ web/                     # Couche client web
│  └─ (structure /bootstrap-site-vitrine ou /bootstrap-saas selon Q1)
├─ desktop/                 # Optionnel — structure /bootstrap-app-desktop
├─ worker/                  # Optionnel
├─ contracts/               # Source de contrat
│  ├─ openapi.yaml          # ou .proto, ou packages TS partagé
│  └─ codegen.config.*      # Configuration codegen
├─ db/
│  ├─ migrations/           # Si DB partagée entre server + worker
│  └─ README.md             # Stratégie migration
├─ deploy/
│  ├─ Dockerfile.server
│  ├─ Dockerfile.worker
│  └─ compose.prod.yaml     # Si signal
├─ compose.dev.yaml         # Dev local : DB + services
├─ Makefile                 # make dev / make build / make test / make migrate
├─ .env.example
├─ .gitignore
├─ README.md
└─ docs/
   └─ conventions.md        # Décisions Q1-Q7 explicites
```

Étapes de génération :

1. Créer les dossiers de couches actives uniquement.
2. Initialiser chaque couche avec sa SSOT (chaîner `/bootstrap-site-vitrine` pour `web/`, `/bootstrap-app-desktop` pour `desktop/` si signal — ou différer).
3. Poser le contrat (`contracts/openapi.yaml` minimal avec 1 endpoint health, ou `packages/contracts/` avec un schéma Zod si full-TS).
4. Configurer codegen (script `make contracts` ou équivalent).
5. `compose.dev.yaml` avec DB + services applicatifs.
6. `Makefile` racine avec cibles standard : `dev`, `build`, `test`, `migrate`, `contracts`, `lint`.
7. `.env.example` avec toutes les variables documentées.
8. `docs/conventions.md` complet : Q1-Q7, contraintes croisées appliquées, anti-patterns à éviter sur ce projet.
9. README racine : topologie, comment lancer en dev, comment déployer en prod.

## Étape 4 — Validation

- `make dev` lance la stack (DB + services).
- Smoke test : un endpoint `/health` répond.
- Si contrat codegen : `make contracts` régénère sans erreur, les types côté client correspondent.
- Type-check passe partout (`tsc --noEmit`, `cargo check`, `go vet`).

## Anti-patterns du skill

- ✗ **Imposer TS partout** par préférence — la SSOT code-conform est multi-langage. Le serveur peut très bien être Go ou Rust selon métier.
- ✗ **Imposer GraphQL** — REST + OpenAPI couvre 90% des selfhost, GraphQL ajoute de la complexité injustifiée hors UI très read-heavy.
- ✗ **Recommander Kubernetes** — selfhost = compose dans 95% des cas.
- ✗ **DTO dupliqués manuellement** entre couches (INVARIANT philosophy §5).
- ✗ **pnpm workspace forcé** sur stack hétérogène — Makefile + dossiers simples suffisent.
- ✗ **Sur-architecturer le worker** dès le départ — un endpoint `/cron` ou un binaire CLI lancé par systemd suffit souvent.
- ✗ **Auth dupliquée** entre couches — une seule source, les clients consomment.
- ✗ **Stocker secrets dans le repo** (même chiffrés sans signal sops/age).
- ✗ **Générer toutes les couches "au cas où"** — seules les couches Q2 cochées.

## Out of scope (renvoi)

- **Direction artistique / brand design** sur les couches client → `/design-system` (à venir) à invoquer quand brand mûr.
- **CI/CD pipeline** → hors v0.1. À ajouter en itération (GitHub Actions, Forgejo Runner pour selfhost).
- **Observabilité fine** (tracing distribué, métriques Prometheus) → signal réel requis, hors default.
- **Multi-tenancy** → hors v0.1, à acter explicitement dans `conventions.md` si besoin émerge.

## SSOT manquantes (à produire avant usage réel)

Pour que ce skill soit utilisable à 100%, il faudra produire (selon stacks choisies) :
- `docs/languages/go.md` si Go fréquent côté serveur.
- `docs/languages/php.md` si PHP cible.
- `docs/languages/python.md` si Python cible.
- `docs/contracts.md` (méta) : OpenAPI vs proto vs package TS partagé, conventions de codegen.

À traquer dans BACKLOG.md.
