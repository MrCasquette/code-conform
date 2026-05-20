---
name: bootstrap-site-vitrine
description: Bootstrap d'un site vitrine aux conventions code-conform — Astro v5 + React 19 islands + Tailwind v4 + i18n natif + CMS optionnel (Directus). Cadrage interactif (i18n, CMS, formulaires). Cas type : site éditorial, présentation, restaurant, association.
---

# /bootstrap-site-vitrine

Skill **bootstrap** : crée from scratch un site vitrine aux conventions code-conform. **Astro v5 par défaut** — peu de JS shipped, multi-pages natif, islands pour l'interactif. Pour SaaS / app interactive complète, voir `/bootstrap-saas`.

Si le dossier cible n'est pas vide → **stop** et demande confirmation. Le skill suppose un répertoire vierge (ou existant à compléter sur accord explicite).

## Pré-requis — SSOT à charger

- `~/.code-conform/docs/architecture/00-philosophy.md` — invariants, slicing vertical, filtre fondamental, posture interactive.
- `~/.code-conform/docs/architecture/typescript.md` — Bun/pnpm, Zod, strict TS, conventions naming.
- `~/.code-conform/docs/architecture/ui.md` — atomic design (`src/components/`), tokens Tailwind v4, `Record<Variant>`, a11y.
- `~/.code-conform/skills/init-design-system/SKILL.md` — étapes 3.x (helper `cn`, `@theme`, Button de référence) à composer ici.

## Pourquoi Astro v5 par défaut

Choix posé et assumé (cf. RATIONALE §6 — skills opinionés). Justifications :

- **Build essentiellement statique** (ou hybrid avec adapter Node), 0 JS par défaut sur les routes sans island.
- **MDX intégré** pour contenu rédactionnel.
- **Multi-framework** : islands React/Vue/Svelte cohabitent — adapté au profil "sustainable solo craft" qui n'impose pas une stack frontend unique.
- **i18n natif** Astro 5 (locales, prefixDefaultLocale, getRelativeLocaleUrl).
- **Pages = fichiers**, routing simple, pas de framework de routing à apprendre.

**Override Next.js** uniquement si signal réel :
- SSR fort sur toutes les routes (pages très dynamiques avec auth, dashboards).
- Server Actions / Server Components au cœur de l'expérience.
- Stack JS exclusive et besoin de React Server Components partout.

Ce cas tombe dans `/bootstrap-saas`. Le skill challenge l'utilisateur : *"Décris ton site en 2 lignes. Si la dynamique est marginale (formulaires, soumission ponctuelle, contenu CMS lu), Astro reste. Si l'app est une UI interactive permanente avec sessions/auth, on bascule vers /bootstrap-saas."*

## Étape 1 — Détection / contexte

Avant de générer :

- Vérifier que le répertoire est vide (sinon stop + demander).
- Détecter le gestionnaire préféré (pnpm défaut, Bun si l'utilisateur signale).
- Vérifier que Node ≥ 20 est disponible (Astro 5 requirement).

Annoncer une phrase de cadrage : *"Je vais créer un site vitrine Astro 5 + React 19 + Tailwind v4 dans ce répertoire. Quelques décisions à arbitrer."*

## Étape 2 — Questions de cadrage

Posture interactive (philosophy §8 INVARIANT). Pose les questions groupées avec hypothèse par défaut.

**Q1 — Métier du site** (philosophy §2)
- En 2 lignes max : qui est l'utilisateur final, que vient-il faire, sur combien de pages clés ?
- Demander aussi : présence d'un formulaire (contact, réservation, devis) ? Combien ?

**Q2 — i18n**
- Multilingue ? Si oui : langues + langue par défaut. Default proposé : `fr` seul, ou `fr + en` si signal international.

**Q3 — Contenu : statique ou CMS**
- (A) **Statique** — contenu en Markdown/MDX dans `src/content/`. Default pour ≤ 10 pages quasi-immuables.
- (B) **CMS headless** — contenu géré dans Directus (ou autre). Recommandé si le client/utilisateur final édite. Sinon écarté (philosophy §4 — pas d'abstraction "au cas où").

**Q4 — Adapter de rendu**
- (A) **Static** (`@astrojs/static` — default Astro) si contenu = statique pur, pas de soumission de formulaire serveur.
- (B) **Node SSR** (`@astrojs/node` mode standalone) si formulaires côté serveur, i18n avec négociation Accept-Language, CMS rendu à la requête, ou Docker.
- (C) Adapter hébergeur (Vercel, Netlify, Cloudflare) uniquement si plateforme connue. Sinon Node SSR portable.

**Q5 — Posture tokens** (cf. `ui.md` §4) : A (noms-marque) ou B (sémantique). Brand fort attendu sur un site vitrine ; default A si charte couleur connue, sinon B générique.

**Q6 — Linter/formatter** — Biome par défaut (cf. agay), ESLint+Prettier si signal contraire (lib custom, équipe imposée).

## Étape 3 — Génération de la structure

Annonce l'arbo avant exécution. Applique après accord.

### 3.1 Init Astro

```bash
pnpm create astro@latest . --template minimal --typescript strict --no-git
pnpm astro add react
pnpm astro add tailwind   # ou installation manuelle Tailwind v4 si l'add fait v3
pnpm add -D @biomejs/biome
pnpm add -D @astrojs/sitemap
```

Si CMS Directus retenu : `pnpm add @directus/sdk`.
Si Node SSR retenu : `pnpm astro add node`.
Si formulaires : `pnpm add zod react-hook-form sonner`.
Helper UI : `pnpm add clsx tailwind-merge`.

### 3.2 Configuration Astro (`astro.config.mjs`)

```js
import { defineConfig } from 'astro/config'
import react from '@astrojs/react'
import sitemap from '@astrojs/sitemap'
import tailwindcss from '@tailwindcss/vite'
// + node adapter si SSR

export default defineConfig({
  site: 'https://example.com', // à remplacer
  integrations: [react(), sitemap()],
  vite: { plugins: [tailwindcss()] },
  // + i18n si Q2 = oui :
  i18n: {
    defaultLocale: 'fr',
    locales: ['fr', 'en'],
    routing: { prefixDefaultLocale: false },
  },
})
```

### 3.3 Arborescence cible

```
src/
├── components/
│   ├── atoms/
│   │   ├── Button.astro            ← atom statique de référence
│   │   └── index.ts                ← barrel des exports .tsx (.astro non barrellables)
│   ├── molecules/
│   └── organisms/
├── layouts/
│   └── BaseLayout.astro            ← layout principal (head, html lang, slot)
├── pages/
│   ├── index.astro
│   └── (autres pages clés selon Q1)
├── content/                        ← si Q3=A statique : MDX
│   └── config.ts                   ← schémas content collections
├── i18n/                           ← si Q2=oui
│   ├── fr.json
│   └── en.json
├── domain/                         ← si CMS / formulaires nécessitent du schéma
├── infrastructure/                 ← si CMS : client Directus + auth
│   └── directus.ts
├── styles/
│   └── globals.css                 ← @import tailwindcss + @theme
└── utils/
    └── index.ts                    ← export cn (clsx + tailwind-merge)
```

### 3.4 Helper `cn` + `@theme`

Reprendre les recettes de `init-design-system` (§3.3 et §3.5) selon posture Q5.

### 3.5 Button de référence — `Button.astro`

Sur un site vitrine, la majorité des CTA sont statiques (lien ou submit). `.astro` suffit, pas besoin de React :

```astro
---
type ButtonVariant = 'primary' | 'secondary' | 'outline'

interface Props {
  variant?: ButtonVariant
  href?: string
  class?: string
  disabled?: boolean
}

const { variant = 'primary', href, class: className, disabled } = Astro.props

const VARIANT: Record<ButtonVariant, string> = {
  primary: 'bg-primary hover:bg-primary-dark text-white shadow-sm',
  secondary: 'bg-accent hover:bg-accent-dark text-white shadow-sm',
  outline: 'border border-primary text-primary hover:bg-primary-light',
}

const DISABLED = 'bg-border text-text-secondary/50 cursor-not-allowed'
const BASE = 'inline-flex items-center justify-center px-6 py-3 rounded-lg font-medium text-sm transition-colors duration-200'
const cls = `${BASE} ${disabled ? DISABLED : VARIANT[variant]} ${className ?? ''}`
---

{href ? (
  <a href={href} class={cls}><slot /></a>
) : (
  <button class={cls} disabled={disabled}><slot /></button>
)}
```

Pour les atoms interactifs (formulaires, toaster), créer un `.tsx` React avec island (cf. §3.7).

### 3.6 Layout de base — `BaseLayout.astro`

- `<html lang={Astro.currentLocale}>` si i18n, sinon `lang="fr"`.
- `<head>` : title prop, meta description prop, favicon, fonts (`@font-face` déjà dans globals.css), OpenGraph minimal.
- `<slot />` pour contenu page.
- Footer minimal en bas, header en haut si organism `Header.astro` existe.

### 3.7 Islands React (si interactivité)

Pour formulaire de contact :
- `src/components/molecules/ContactForm.tsx` (React + react-hook-form + Zod + Sonner toast).
- Consommé depuis `src/pages/contact.astro` avec `client:load` ou `client:visible` (préférer `client:visible` si below-the-fold).

```astro
---
import ContactForm from '@/components/molecules/ContactForm'
---
<BaseLayout title="Contact">
  <ContactForm client:visible />
</BaseLayout>
```

**Règle dure** : hydratation parcimonieuse. Tout en `client:load` = perd l'avantage Astro. Audit ensuite avec `/audit-site-vitrine`.

### 3.8 CMS Directus (si Q3=B)

`src/infrastructure/directus.ts` minimal :

```ts
import { createDirectus, rest } from '@directus/sdk'

export const directus = createDirectus(import.meta.env.DIRECTUS_URL)
  .with(rest())
```

Types via `src/domain/<concept>/<Concept>.schema.ts` (Zod SSOT, cf. `typescript.md` §2). Pas de wrapper Repository — `directus.request(readItems(...))` direct dans la page, parse Zod en sortie.

### 3.9 i18n (si Q2=oui)

- `src/pages/[lang]/...` ou structure par locale selon préférence Astro 5.
- `src/i18n/{fr,en}.json` pour traductions inline.
- Helper `t(key, lang)` simple (philosophy §4 — pas i18next sauf besoin réel).

### 3.10 `docs/conventions.md`

Crée à la racine avec :
- Adapter retenu, langues, posture tokens, CMS oui/non, choix linter.
- Renvoi à `~/.code-conform/docs/architecture/{philosophy,typescript,ui}.md`.

## Étape 4 — Validation

1. `pnpm dev` — démarre Astro dev server.
2. Type-check : `pnpm astro check`.
3. Build : `pnpm build` (signaler si échec).
4. Annoncer récap en 5 lignes : pages créées, islands éventuelles, prochaines étapes (premiers concepts métier, CMS à connecter, contenus à rédiger).

## Anti-patterns du skill

- ✗ Tout en React (`client:load` partout) — perd l'avantage Astro. Default = .astro statique, .tsx uniquement pour interactivité réelle.
- ✗ Forcer Next.js pour un cas vitrine. Si l'utilisateur insiste, demander signal concret (SSR partout ? Server Components ? Stack JS imposée ?) — sinon Astro reste.
- ✗ Ajouter i18next, react-i18next sur un site bilingue minimal — l'i18n natif Astro + JSON suffit.
- ✗ Créer `src/services/`, `src/repositories/` — slicing horizontal (philosophy §6).
- ✗ Ajouter Storybook/Histoire par défaut. Pour 5-10 pages vitrine, l'inspection visuelle au dev server suffit.
- ✗ Forcer un CMS si statique convient (Markdown + content collections Astro). Filtre fondamental.
- ✗ Templates dans `src/components/templates/` — sur Astro le layout vit dans `src/layouts/`, pas dans atomic.
- ✗ ESLint + Prettier par défaut quand Biome convient. Skill = Biome default.

## Out of scope (renvoi)

- **Application interactive complète** (auth, dashboards, multi-rôles) → `/bootstrap-saas`.
- **Audit d'un site vitrine existant** → `/audit-site-vitrine`.
- **Design system isolé** (in-app, hors bootstrap projet) → `/init-design-system` à appeler après `/bootstrap-site-vitrine` si refonte DS.
- **CLI** → `/bootstrap-cli`.
- **App desktop** → `/bootstrap-app-desktop` (Tauri).
