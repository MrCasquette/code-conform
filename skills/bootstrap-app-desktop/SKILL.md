---
name: bootstrap-app-desktop
description: Crée une app desktop aux conventions code-conform — Tauri 2 par défaut (Vite + React 19 + Tailwind v4 + Biome). Mono-window default, IPC commands typées, persistance optionnelle. Bootstrap from scratch — n'audite pas l'existant.
---

# /bootstrap-app-desktop

Skill **bootstrap** : crée from scratch une app desktop opinionée code-conform. Default **Tauri 2** (binaire natif léger, frontend web). Override Electron uniquement sur signal très fort (lib Node-only incontournable côté UI, déjà en prod Electron).

Si le projet existe déjà → sors et propose `/audit-app-desktop`.
Si l'app a un serveur distant compagnon → c'est un projet **cloud** (`/bootstrap-cloud`), pas un desktop pur.

## Pré-requis — SSOT à charger

- `~/.code-conform/docs/00-philosophy.md` — invariants, posture interactive (§1, §8).
- `~/.code-conform/docs/languages/typescript.md` — frontière Zod, idiomes TS.
- `~/.code-conform/docs/languages/rust.md` — côté `src-tauri/`.
- `~/.code-conform/docs/design/atomic-design.md` — atomic, tokens structure, a11y. **Couche archi UI uniquement** — la dimension design pure (brand, palette, typographie character) est hors scope ce skill, voir `/design-system` à venir.

## Hard rule — usage de la SSOT (INVARIANT)

Quand tu écris du code couvert par la SSOT, tu **dois** consulter la section pertinente **au moment** d'écrire — pas en lecture inspirationnelle au démarrage. Charger les docs en début de session ≠ les avoir en mémoire au moment d'écrire 200 messages plus tard (dilution d'attention en long contexte, cf. `RATIONALE §12`).

Concrètement :
- **`Read` la section ciblée juste avant** de générer le fichier concerné (ex: `atomic-design.md §5` pour un composant, `§4` pour les tokens, `typescript.md §2` pour un schéma Zod, `rust.md` pour les commands Rust).
- **Cite la phrase-clé ou le pattern exact** dans ton message ("j'applique le pattern `Record<Variant, classes>` de §5"), pas une reformulation de mémoire.

Anti-patterns :
- ✗ *"Je connais le pattern, je l'applique"* → dérive vers training data, pas vers SSOT.
- ✗ Reformulation de mémoire → deviation invisible.
- ✗ Charger la SSOT au démarrage puis ne plus la rouvrir → dilution garantie en fin de session.

La SSOT est un **référentiel à consulter au moment d'écrire**, pas une lecture inspirationnelle.

## Default opinioné (avec justification)

| Couche | Default | Raison |
|---|---|---|
| Runtime | Tauri 2.x | Binaire natif léger, sécurité par défaut (allowlist), updater intégré |
| Frontend | React 19 + Vite | `ref` standard prop, écosystème mature, cohérent avec ref UI tool Tauri |
| Styling | Tailwind v4 via `@tailwindcss/vite` | SSOT `atomic-design.md` |
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

Le cadrage se déroule en **4 phases internes** à cette étape, avant l'Étape 3 (génération). **Phasage strict** (philosophy §8 INVARIANT) : récit → acquittement → technique adaptée → récap. Pas de bundle, pas de récap prématuré. Capture chaque décision dans `docs/conventions.md` au fil de l'eau.

**Hard rule (philosophy §1 INVARIANT bloquant)** : aucune génération de fichier tant qu'une phase n'est pas validée. Pas de *"je scaffold, tu me diras après"* — violation, pas initiative.

### Phase 1 — Récit du projet (texte libre, bloquante)

**Q1 — Question unique**

Pose **exactement** ceci et attends la réponse :

> Dis m'en plus sur les aspects métier de l'app desktop que tu veux construire.

Aucune sous-question, aucun bullet, aucune liste d'exemples. La question doit rester nue.

**Grille d'écoute interne** (jamais exposée à l'utilisateur)

À la réception, vérifie les trois angles principaux. Si oui même partiellement, passe en Phase 2.

1. **De quoi il s'agit** — type d'app, domaine, vocabulaire propre.
2. **Pour qui** — utilisateur final ; distingue commanditaire ≠ utilisateur si pertinent (sans relancer).
3. **Ce que ça doit faire ou permettre** — l'intention concrète.

**Grille d'écoute additionnelle** spécifique app desktop :
- OS cibles si évoqués naturellement.
- Manipulation de fichiers locaux / données utilisateur sensibles.
- Mode d'usage : continu / ponctuel / arrière-plan / tray.

**Au passage**, capte sans questionner : OS imposé, distribution attendue, références (apps existantes). Si absent, **reste absent — pas de relance**.

**Hors scope ferme — ne pose JAMAIS ces questions en Phase 1** : budget, délais, planning de livraison.

**Règle de relance — UNIQUE et restrictive**

- Maximum **une** relance. Pas deux.
- Seulement si un angle principal est absent au point de bloquer Phase 2.
- Une seule question courte, ciblée sur le manque le plus critique. Pas de liste.
- Après la relance, peu importe la réponse : **Phase 2 obligatoire** avec hypothèse explicite si flou subsiste.

### Phase 2 — Acquittement de compréhension métier (prose courte, bloquante)

Restitue ce que tu as compris en **2-3 phrases de prose libre** — pas de bullets, pas de liste.

Format type :

> Si j'ai bien compris : <2-3 phrases reformulant l'app, son usage, son intention>. C'est juste ?

Attends confirmation ou correction. **Bloquant.** Si correction, intègre puis re-acquitte (court). Quand validé, passe en Phase 3.

**Anti-pattern** : transformer cette restitution en liste à puces structurée.

### Phase 3 — Technique adaptée (après Phase 2 validée)

Annonce d'abord ton inférence depuis le métier acquitté, puis pose en QCM (`AskUserQuestion`) les choix non inférables.

Format type :

> Vu ce que tu décris, j'infère :
> - Persistance probable : <ex: SQLite si relations, store JSON si config simple, FS si éditeur de fichiers>
> - Fenêtrage probable : <mono-window dans 90% des cas>
> - IPC probable : <commands ciblées si besoins natifs, sinon aucune>
> - Plateformes probables : <macOS+Linux si solo, +Windows si distribution large>
>
> Je pose maintenant les choix techniques restants. L'ensemble (inférence + choix) sera ré-ouvert pour validation finale (Phase 4) avant scaffold.

**Q-techniques modèles** (à adapter au métier) :

- **Framework UI** : React 19 (default code-conform) / Vue 3 / Svelte 5.
- **Persistance locale** : Aucune / `tauri-plugin-store` (JSON) / `tauri-plugin-sql` SQLite / Filesystem direct. Si SQLite : stratégie migrations (sqlx-cli / embedded / script Rust).
- **IPC / Commands Rust** : Aucune / Commands ciblées. Si commands : tauri-specta (codegen) ou Zod en sortie d'`invoke` (frontière philosophy §5).
- **Fenêtrage** : Mono-window (default) / Multi-window (sur signal : tray, settings) / Tray-only.
- **Distribution** : Plateformes cibles + updater on/off + code signing (différable).

### Phase 4 — Récap puis validation

**Pas de récap tant que Phase 3 incomplète.** Quand tout est répondu, présente la synthèse exhaustive et demande validation explicite avant Étape 3.

### Anti-patterns du cadrage

- ✗ Relancer parce que "plus de contexte serait mieux" (Phase 1).
- ✗ Relancer avec une liste de questions (Phase 1).
- ✗ Exposer la grille d'écoute à l'utilisateur (Phase 1).
- ✗ Demander budget, délais, planning (Phase 1, hors scope ferme).
- ✗ Demander un KPI, des personas, des user stories (Phase 1).
- ✗ Demander la stack technique en Phase 1 (réservé à Phase 3).
- ✗ Transformer l'acquittement (Phase 2) en liste à puces structurée.
- ✗ Sauter Phase 2 et passer directement aux choix techniques.
- ✗ Récapituler les choix techniques (Phase 4) avant que tous soient reçus.

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
6. Squelette atomic vide + 1 `Button` de référence en `Record<Variant>` (cf. `atomic-design.md` §5 et §8 pour le pattern complet).
7. Configurer `tauri.conf.json` : allowlist **minimal au strict besoin** Q3-Q4 (jamais `"all": true`), CSP par défaut active.
8. Si SQLite : ajouter `tauri-plugin-sql`, créer `src-tauri/migrations/0001_init.sql`, configurer dans `lib.rs`.
9. Si updater Q6 : ajouter `tauri-plugin-updater`, doc minimal dans `docs/conventions.md` (endpoint, signing).
10. README minimal : `pnpm tauri dev` / `pnpm tauri build`, prérequis Rust toolchain.

### Recettes DS de base (inline, baseline architectural)

Le skill pose un baseline neutre. La direction artistique (palette définitive, typographie character) relève de `/design-system` à invoquer plus tard quand brand mûr.

**Helper `cn`** — `src/utils/index.ts` :

```ts
import clsx, { type ClassValue } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]): string {
  return twMerge(clsx(inputs))
}
```

**`@theme` Tailwind v4** — `src/styles/app.css` :

```css
@import "tailwindcss";

@theme {
  --color-bg:        oklch(0.21 0.02 272);
  --color-surface:   oklch(0.255 0.022 272);
  --color-surface-2: oklch(0.3 0.025 272);

  --color-fg:   oklch(0.97 0.01 272);
  --color-fg-2: oklch(0.82 0.012 272);
  --color-fg-3: oklch(0.62 0.015 272);

  --color-rule:   oklch(0.32 0.02 272);
  --color-rule-2: oklch(0.4 0.022 272);

  --color-primary:      oklch(0.56 0.08 273);
  --color-primary-deep: oklch(0.42 0.10 273);

  /* Statuts toujours sémantiques (cf. atomic-design.md §4) */
  --color-error:   oklch(0.65 0.16 20);
  --color-success: oklch(0.78 0.18 156);
  --color-warning: oklch(0.78 0.14 60);

  --radius-md: 9px;
}
```

**Button de référence** — `src/components/atoms/Button.tsx` :

```tsx
import { cn } from '@/utils'

export type ButtonVariant = 'primary' | 'ghost' | 'destructive'
export type ButtonSize = 'sm' | 'md' | 'lg'

type ButtonProps = React.ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: ButtonVariant
  size?: ButtonSize
  isLoading?: boolean
}

const BASE =
  'inline-flex items-center justify-center gap-2 font-semibold transition-colors focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed'

const VARIANT: Record<ButtonVariant, string> = {
  primary: 'bg-primary text-white hover:bg-primary-deep',
  ghost: 'bg-surface text-fg-2 border border-rule hover:border-rule-2',
  destructive: 'bg-transparent text-error border border-error/40 hover:bg-error/10',
}

const SIZE: Record<ButtonSize, string> = {
  sm: 'h-8 px-3 text-sm rounded-md',
  md: 'h-10 px-4 text-base rounded-md',
  lg: 'h-12 px-6 text-lg rounded-md',
}

export function Button({
  variant = 'primary',
  size = 'md',
  isLoading,
  className,
  children,
  ...rest
}: ButtonProps) {
  return (
    <button
      type="button"
      disabled={isLoading || rest.disabled}
      className={cn(BASE, VARIANT[variant], SIZE[size], className)}
      {...rest}
    >
      {children}
    </button>
  )
}
```

→ Pour Vue 3 / Svelte 5 : appliquer la même structure (variants en `Record`, base + variant + size composés via cn) — voir `atomic-design.md` §5 pour les équivalents par framework.

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

- **Direction artistique / brand design** (palette identitaire, typographie character, ambiance) → `/design-system` (à venir) — quand brand mûr.
- **App + serveur compagnon** → c'est `/bootstrap-cloud` (le desktop devient une couche du système).
- **Mobile via Tauri Mobile** → mention dans `docs/conventions.md`, mais non couvert v0.1 (beta encore en évolution).
- **CI / release pipeline** → hors v0.1. tauri-action GitHub à ajouter manuellement quand pertinent.
