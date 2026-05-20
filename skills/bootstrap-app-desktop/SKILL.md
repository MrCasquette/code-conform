---
name: bootstrap-app-desktop
description: Crée une app desktop aux conventions code-conform — Tauri 2 par défaut (Vite + React 19 + Tailwind v4 + Biome). Mono-window default, IPC commands typées, persistance optionnelle. Bootstrap from scratch — n'audite pas l'existant.
---

# /bootstrap-app-desktop

Skill **bootstrap** : crée from scratch une app desktop opinionée code-conform. Default **Tauri 2** (binaire natif léger, frontend web). Override Electron uniquement sur signal très fort (lib Node-only incontournable côté UI, déjà en prod Electron).

Si le projet existe déjà → sors et propose `/audit-app-desktop`.
Si l'app a un serveur distant compagnon → c'est un projet **cloud** (`/bootstrap-cloud`), pas un desktop pur.

## Pré-requis — SSOT à charger

- `~/.code-conform/docs/architecture/00-philosophy.md` — invariants, posture interactive (§1, §8).
- `~/.code-conform/docs/architecture/typescript.md` — frontière Zod, idiomes TS.
- `~/.code-conform/docs/architecture/rust.md` — côté `src-tauri/`.
- `~/.code-conform/docs/architecture/ui.md` — atomic, tokens, a11y.
- `~/.code-conform/skills/init-design-system/SKILL.md` — générer le DS après squelette.

## Default opinioné (avec justification)

| Couche | Default | Raison |
|---|---|---|
| Runtime | Tauri 2.x | Binaire natif léger, sécurité par défaut (allowlist), updater intégré |
| Frontend | React 19 + Vite | Cohérent avec Plume (ref), `ref` standard prop, écosystème mature |
| Styling | Tailwind v4 via `@tailwindcss/vite` | SSOT `ui.md` |
| State | Zustand | Suffit en mono-window, pas de routing global |
| Persistance locale | `tauri-plugin-store` (JSON) ou `tauri-plugin-sql` (SQLite) | Selon besoin Q3 |
| Linter | Biome | SSOT code-conform |
| Package manager | pnpm ou Bun | Jamais npm/yarn |

**Bascules possibles** :
- Vue 3 si l'utilisateur est Vue-first (signal explicite).
- Svelte 5 si signal explicite + petit périmètre.
- Electron uniquement sur signal contraignant et acté dans `docs/conventions.md`.

## Étape 1 — Détection

Inspecter le dossier cible :

- Vide ou inexistant → bootstrap pur.
- Présence de `package.json` ou `src-tauri/` → sors, propose `/audit-app-desktop`.

## Étape 2 — Cadrage interactif

Pose les questions une par une, attends les réponses. Capture dans `docs/conventions.md`.

**Q1 — Métier de l'app ?**
Une phrase. Sert à orienter persistance, multi-window, plugins.

**Q2 — Framework UI ?**
- React 19 (default code-conform)
- Vue 3 (sur signal)
- Svelte 5 (sur signal)

**Q3 — Persistance locale ?**
- Aucune (app stateless ou config en mémoire)
- `tauri-plugin-store` (JSON, simple, < 1k lignes)
- `tauri-plugin-sql` SQLite (relationnel, requêtes, migrations)
- Filesystem direct (fichiers user, ex: éditeur)

Si SQLite → demander : migrations gérées comment ? (sqlx-cli, migrations embarquées dans le binaire, ou script Rust ad-hoc).

**Q4 — IPC / Commands Rust ?**
- Aucune (app full-front, Tauri = juste packaging)
- Commands ciblées (FS, OS, calculs lourds)

Si commands → tauri-specta pour typer côté TS automatiquement, sinon écriture manuelle des types côté front (frontière Zod en sortie d'`invoke`).

**Q5 — Fenêtrage ?**
- Mono-window (default)
- Multi-window (signal : tray, popup OS, settings séparées)
- Tray-only (background)

**Q6 — Distribution ?**
- Plateformes cibles (macOS / Windows / Linux — préciser combien).
- Updater auto (`tauri-plugin-updater`) on/off.
- Signature (code signing) — différé si non-critique au bootstrap.

## Étape 3 — Génération

Arborescence générée :

```
<projet>/
├─ src/                          # Frontend (web)
│  ├─ components/
│  │  ├─ atoms/
│  │  ├─ molecules/
│  │  ├─ organisms/
│  │  └─ templates/             # Justifié : pas de routing externe, layout porté ici
│  ├─ domain/<concept>/         # Slicing vertical
│  ├─ stores/                    # Zustand
│  ├─ hooks/                     # Hooks transverses non-métier
│  ├─ lib/
│  │  └─ tauri.ts                # invoke<T> wrapper typé + parse Zod
│  ├─ utils/
│  │  └─ index.ts                # cn (clsx + tailwind-merge)
│  ├─ styles/
│  │  └─ app.css                 # @import "tailwindcss" + @theme
│  ├─ App.tsx
│  └─ main.tsx
├─ src-tauri/                    # Backend Rust
│  ├─ src/
│  │  ├─ main.rs
│  │  ├─ lib.rs
│  │  └─ commands/<area>.rs      # IPC commands groupées par domaine
│  ├─ tauri.conf.json
│  ├─ Cargo.toml
│  └─ build.rs
├─ index.html
├─ vite.config.ts                # plugin @tailwindcss/vite
├─ tsconfig.json                 # strict
├─ biome.json
├─ package.json
└─ docs/
   └─ conventions.md             # Décisions du cadrage
```

Étapes :

1. `pnpm create tauri-app` (ou `bun create tauri-app`) avec template Vite + React + TS.
2. Remplacer linter par Biome (`biome.json`), supprimer ESLint/Prettier si scaffold les a posés.
3. Installer Tailwind v4 + plugin Vite (`@tailwindcss/vite`), `@import "tailwindcss";` dans `src/styles/app.css`, `@theme` selon posture choisie.
4. Créer `src/utils/index.ts` avec helper `cn`.
5. Créer `src/lib/tauri.ts` — wrapper `invokeTyped<T>(cmd, payload, schema)` qui parse via Zod la réponse (frontière philosophy §5).
6. Squelette atomic vide + 1 `Button` de référence en `Record<Variant>` (cf. `init-design-system`).
7. Configurer `tauri.conf.json` : allowlist **minimal au strict besoin** Q3-Q4 (jamais `"all": true`), CSP par défaut active.
8. Si SQLite : ajouter `tauri-plugin-sql`, créer `src-tauri/migrations/0001_init.sql`, configurer dans `lib.rs`.
9. Si updater Q6 : ajouter `tauri-plugin-updater`, doc minimal dans `docs/conventions.md` (endpoint, signing).
10. README minimal : `pnpm tauri dev` / `pnpm tauri build`, prérequis Rust toolchain.

## Étape 4 — Capture dans `docs/conventions.md`

Reprendre Q1-Q6 + décisions implicites :
- Stack frontend retenue.
- Persistance choisie + stratégie migrations si SQLite.
- IPC : tauri-specta on/off, où vivent les schémas Zod de retour.
- Fenêtrage cible.
- Plateformes cibles + updater.
- Posture tokens (renvoi DS).

## Étape 5 — Validation visuelle

Lancer `pnpm tauri dev`. Vérifier :
- App se lance, Button visible.
- Pas d'erreur console.
- Type-check OK (`pnpm tsc --noEmit`).
- `cargo check` côté `src-tauri/`.

## Anti-patterns du skill

- ✗ **Activer toute l'allowlist Tauri** ("`all: true`") — viole le principe de moindre privilège, désactive l'avantage sécurité Tauri.
- ✗ **react-router** en mono-window — overhead inutile, navigation = state Zustand suffit.
- ✗ **Electron par défaut** — surfaces d'attaque, taille binaire, RAM. Tauri couvre 95% des besoins.
- ✗ **forwardRef** en React 19 — `ref` est prop standard.
- ✗ **Définir les types IPC manuellement côté front sans frontière Zod** — perte de l'INVARIANT philosophy §5. Soit tauri-specta (codegen), soit Zod en parse de sortie d'`invoke`.
- ✗ **Stocker des secrets dans `tauri.conf.json`** — config publique, signée. Secrets côté Rust uniquement ou via keychain OS (`tauri-plugin-keyring`).
- ✗ **Bypass CSP "pour debug"** — la garder active, ajouter les sources nécessaires explicitement.
- ✗ **Multi-window prématuré** — settings inline en modal/drawer suffit la plupart du temps.

## Out of scope (renvoi)

- **DS détaillé** → chaîner `/init-design-system` après le squelette.
- **App + serveur compagnon** → c'est `/bootstrap-cloud` (le desktop devient une couche du système).
- **Mobile via Tauri Mobile** → mention dans `docs/conventions.md`, mais non couvert v0.1 (beta encore en évolution).
- **CI / release pipeline** → hors v0.1. tauri-action GitHub à ajouter manuellement quand pertinent.
