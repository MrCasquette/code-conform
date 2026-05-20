---
name: init-design-system
description: Bootstrap d'un design system in-app aux conventions code-conform — atomic design + tokens Tailwind v4 + premier atom de référence. Cadre interactif (posture tokens, framework). N'audite pas l'existant ; pour ça, voir /audit-design-system.
---

# /init-design-system

Skill **bootstrap** : pose la structure DS dans un projet (vierge ou sans DS existant) aux conventions code-conform. Pas un audit — si le projet a déjà un `src/components/{atoms,molecules,organisms}/`, sors immédiatement et propose `/audit-design-system` (à venir).

## Pré-requis — SSOT à charger

Avant toute génération, charge en contexte :

- `~/.code-conform/docs/architecture/00-philosophy.md` — invariants (interactivité, slicing vertical, filtre fondamental).
- `~/.code-conform/docs/architecture/ui.md` — atomic design, postures tokens A/B, pattern `Record<Variant>`, Tailwind v4 `@theme`.
- `~/.code-conform/docs/architecture/<langage>.md` — selon langage cible (typiquement `typescript.md`).

Si l'un de ces docs est absent, **arrête** et demande à l'utilisateur de réinstaller code-conform (`./install.sh`).

## Étape 1 — Détection contexte

Inspecter le projet courant **sans modifier**, pour orienter le cadrage :

- `package.json` → framework (Next, Nuxt, Vite, SvelteKit, Tauri…), version React/Vue/Svelte, présence Tailwind v4 (`@tailwindcss/{vite,postcss}` ≥ 4), gestionnaire (Bun, pnpm).
- Présence `src/components/`, `src/ui/`, `src/design-system/` → si l'un existe et contient déjà des fichiers (atoms/molecules/organisms), **stop** : ce n'est pas un bootstrap. Propose `/audit-design-system`.
- Présence d'un `@theme` dans un CSS racine (`app.css`, `globals.css`, `index.css`) → si présent et non trivial, **stop** : DS partiellement posé. Demande validation avant de continuer.
- `docs/conventions.md` → s'il existe, lis-le pour respecter les seuils/choix déjà capturés.
- Alias d'import (`tsconfig.json` paths, `vite.config`) → `@/` ou `@/src/`.

Annonce à l'utilisateur ce que tu as détecté en une phrase, puis enchaîne les questions de cadrage.

## Étape 2 — Questions de cadrage

Posture code-conform (philosophy §1 et §8 INVARIANT) : ne devine pas les choix non inférables. Pose 3-5 questions groupées, avec ton hypothèse par défaut quand pertinent. L'utilisateur valide en bloc.

**Hard rule (philosophy §1 INVARIANT bloquant)** : toutes les questions doivent recevoir réponse avant Étape 3. **Aucun fichier ne s'écrit tant qu'une question reste ouverte**. Pas de *"je pose le squelette, tu choisiras la posture tokens après"*.

**Q1 — Posture tokens couleurs** (cf. `ui.md` §4)
- (A) **Noms-marque directs** — palette identitaire (ex: `marsala`, `cream`, `gold`). Monothème.
- (B) **Tokens sémantiques** — vocabulaire d'usage (`bg`, `surface`, `fg`, `rule`, `primary`). Multi-thème / dark natif / palette neutre.
- Default proposé : selon le contexte détecté (brand-driven site → A ; UI tool / app → B ; *indécis* → demande explicitement).

**Q2 — Si posture A** : nom des couleurs identitaires et valeurs (ou charte fournie). Suggère 3-6 couleurs max au démarrage.
**Q2 — Si posture B** : confirmer palette de départ (defaults : `bg`, `surface`, `surface-2`, `fg`, `fg-2`, `rule`, `primary`, `primary-deep`). Dark mode prévu ? (oui/non/plus tard).

**Q3 — Niveaux atomic optionnels** (cf. `ui.md` §3) — par défaut **aucun**. Activer si signal :
- `templates/` : oui si Vite SPA / Tauri / framework sans layout natif.
- `brand/` : oui si logo/signature distincts à isoler.
- `icons/` : oui si volume d'icônes prévu (≥10).

**Q4 — `docs/conventions.md`** : skill propose de le créer/mettre à jour à la racine du projet pour capturer les décisions actées. Confirmer.

**Q5 — Variants** : confirmer pattern `Record<Variant, classes>` par défaut (`ui.md` §5, §8). `tailwind-variants` uniquement si l'utilisateur signale besoin (`compoundVariants`, slots, ≥3 axes). Pas par anticipation.

## Étape 3 — Génération de la structure

Toutes les actions modifient le système de fichiers. **Annonce l'arbo avant exécution**, demande validation, puis applique.

### 3.1 Dépendances

Ajouter au `package.json` (via `bun add` ou `pnpm add` selon détection) :
- `clsx`, `tailwind-merge`.
- `tailwindcss@^4` + plugin selon framework :
  - Vite/SvelteKit/Tauri → `@tailwindcss/vite`
  - Next/PostCSS → `@tailwindcss/postcss` + `postcss`, `autoprefixer`
- `prettier-plugin-tailwindcss` (devDep) si Prettier déjà présent.
- **Ne pas** ajouter `tailwind-variants` / `cva` à ce stade — sur signal seulement.

### 3.2 Arborescence (default minimal)

```
src/
├── components/
│   ├── atoms/
│   │   ├── Button.tsx           ← atom de référence (cf. 3.4)
│   │   └── index.ts             ← barrel
│   ├── molecules/
│   │   └── index.ts             ← vide, prêt
│   └── organisms/
│       └── index.ts             ← vide, prêt
├── utils/
│   └── index.ts                 ← export cn (cf. 3.3)
└── styles/                      ← ou app/ (Next), selon framework
    └── app.css                  ← @import tailwindcss + @theme
```

Ajoute `templates/`, `brand/`, `icons/` **uniquement** si activés Q3.

Ne pose **pas** `src/domain/`, `src/stores/`, `src/hooks/`, `src/lib/` — ces dossiers émergent au besoin (philosophy §4), pas du fait d'un bootstrap DS.

### 3.3 Helper `cn`

`src/utils/index.ts` :

```ts
import clsx, { type ClassValue } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]): string {
  return twMerge(clsx(inputs))
}
```

### 3.4 Atom de référence — `Button`

Pose **un seul** atom de démonstration en pattern `Record<Variant, classes>` (cf. `ui.md` §5). Sert de modèle pour les atoms futurs. Pas Card, pas Input, pas Dialog — émergeront au besoin.

```tsx
import { cn } from '@/utils' // ou '@/src/utils' selon alias

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

**Adaptation par framework** :
- Vue 3 → `<script setup lang="ts">` + `defineProps`, `withDefaults`, slots par défaut.
- Svelte 5 → `let { variant = 'primary', size = 'md', children, ...rest } = $props()` + snippets.

Si posture A retenue (Q1), remplace `bg-primary`/`text-fg-2`/`border-rule` par les noms-marque correspondants choisis Q2 (ex: `bg-marsala`, `text-cream`).

### 3.5 `@theme` Tailwind v4

Fichier CSS racine (`styles/app.css`, `app/globals.css`, `src/index.css` selon framework) :

**Posture B (defaults)** :

```css
@import 'tailwindcss';

@theme {
  /* Surfaces */
  --color-bg:        oklch(0.21 0.02 272);
  --color-surface:   oklch(0.255 0.022 272);
  --color-surface-2: oklch(0.3 0.025 272);

  /* Encres */
  --color-fg:   oklch(0.97 0.01 272);
  --color-fg-2: oklch(0.82 0.012 272);
  --color-fg-3: oklch(0.62 0.015 272);

  /* Filets */
  --color-rule:   oklch(0.32 0.02 272);
  --color-rule-2: oklch(0.4 0.022 272);

  /* Marque */
  --color-primary:      oklch(0.56 0.08 273);
  --color-primary-deep: oklch(0.42 0.10 273);

  /* Sémantique */
  --color-error:   oklch(0.65 0.16 20);
  --color-success: oklch(0.78 0.18 156);
  --color-warning: oklch(0.78 0.14 60);

  /* Rayons */
  --radius-md: 9px;
}
```

Si dark mode demandé Q2 :

```css
@custom-variant dark (&:where(.dark, .dark *));

@layer theme {
  .dark {
    --color-bg:      oklch(0.15 0.02 272);
    --color-surface: oklch(0.19 0.022 272);
    /* … redéfinir les sémantiques qui changent … */
  }
}
```

**Posture A** : palette de noms-marque selon Q2 + tokens sémantiques courts pour statuts (`--color-error`, etc. — règle dure transversale `ui.md` §4).

### 3.6 `docs/conventions.md`

Créer / mettre à jour à la racine du projet. Format minimal :

```md
# Conventions projet

> Décisions contextuelles capturées au bootstrap DS. Ce fichier est chargé en contexte par les sessions futures.

## Design system

- **Posture tokens** : <A noms-marque | B sémantique> — décidée le <date>.
- **Palette identitaire** : <liste si A>.
- **Dark mode** : <prévu | non prévu>.
- **Niveaux atomic activés** : atoms, molecules, organisms<, templates, brand, icons selon Q3>.
- **Pattern variants** : Record<Variant, classes>. Bascule tv si compoundVariants/slots/≥3 axes (cf. ui.md §8).
- **Alias d'import** : `<@/...>`.
```

## Étape 4 — Validation post-bootstrap

Une fois la structure générée :

1. Lance le type-check (`pnpm type-check` ou `bun run type-check`) pour vérifier que `Button` compile.
2. Lance le build si rapide (Next/Vite dev server à démarrer manuellement par l'utilisateur — ne pas le lancer toi-même, c'est interactif).
3. Annonce un récap en 5 lignes max : ce qui a été créé, où, prochaines étapes suggérées (premiers concepts métier dans `src/domain/<concept>/`, atoms supplémentaires sur signal réel).

## Anti-patterns du skill (à NE PAS faire)

- ✗ Générer 10+ atoms d'avance (`Input`, `Card`, `Modal`, `Tooltip`…) — viole philosophy §4. Un atom de démo suffit.
- ✗ Imposer une palette colorée sans demander — viole interactivité.
- ✗ Adopter `tailwind-variants` / `cva` par défaut — viole `ui.md` §8 (sans signal réel).
- ✗ Créer `src/ui/` ou `src/design-system/` — convention code-conform = `src/components/`.
- ✗ Créer `src/domain/` ou `src/stores/` "au cas où" — émergence au besoin.
- ✗ Charger sans frontmatter Zod pour valider quoi que ce soit ici — pas de frontière externe dans un bootstrap DS.
- ✗ Forcer le dark mode si non demandé — capture la décision, applique seulement si confirmé.
- ✗ Recopier les principes de `ui.md` dans `docs/conventions.md` — ne capturer **que** les choix contextuels du projet.

## Out of scope (renvoi)

- **DS existant à auditer** → `/audit-design-system` (à venir, BACKLOG).
- **DS partagé multi-projets** (lib DS interne consommée par plusieurs apps) → `/bootstrap-shared-design-system` (BACKLOG).
- **Bootstrap projet complet** (routing, layouts, première page) → skills `/bootstrap-{site-vitrine,app-desktop,saas,cli}` (BACKLOG). `/init-design-system` est transverse, à composer avec eux.
