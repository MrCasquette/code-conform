---
name: bootstrap-site-vitrine
description: Bootstrap d'un site vitrine aux conventions code-conform — Astro (latest) + React 19 islands + Tailwind v4 + i18n natif + CMS optionnel (Directus). Cadrage interactif (i18n, CMS, formulaires). Cas type : site éditorial, présentation, restaurant, association.
---

# /bootstrap-site-vitrine

Skill **bootstrap** : crée from scratch un site vitrine aux conventions code-conform. **Astro (latest) par défaut** — peu de JS shipped, multi-pages natif, islands pour l'interactif. Pour SaaS / app interactive complète, voir `/bootstrap-saas`.

Si le dossier cible n'est pas vide → **stop** et demande confirmation. Le skill suppose un répertoire vierge (ou existant à compléter sur accord explicite).

## Pré-requis — SSOT à charger

- `~/.code-conform/docs/00-philosophy.md` — invariants, slicing vertical, filtre fondamental, posture interactive.
- `~/.code-conform/docs/languages/typescript.md` — Bun/pnpm, Zod, strict TS, conventions naming.
- `~/.code-conform/docs/design/atomic-design.md` — atomic design (`src/components/`), tokens Tailwind v4, `Record<Variant>`, a11y. **Couche archi UI uniquement** — la dimension design pure (brand, palette identitaire, character typographique) est hors scope ce skill, voir `/design-system` à venir.

## Pourquoi Astro (latest) par défaut

Choix posé et assumé (cf. RATIONALE §6 — skills opinionés). Justifications :

- **Build essentiellement statique** (ou hybrid avec adapter Node), 0 JS par défaut sur les routes sans island.
- **MDX intégré** pour contenu rédactionnel.
- **Multi-framework** : islands React/Vue/Svelte cohabitent — adapté au profil "sustainable solo craft" qui n'impose pas une stack frontend unique.
- **i18n natif** Astro (latest) (locales, prefixDefaultLocale, getRelativeLocaleUrl).
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
- Vérifier que Node ≥ 20 est disponible (requirement Astro courant).

Annoncer une phrase de cadrage : *"Je vais créer un site vitrine Astro (latest) + React 19 + Tailwind v4 dans ce répertoire. Quelques décisions à arbitrer."*

## Étape 2 — Questions de cadrage

Le cadrage se déroule en **4 phases internes** à cette étape, avant l'Étape 3 (génération). Posture interactive (philosophy §1 et §8 INVARIANT). **Phasage strict** : récit → acquittement → technique adaptée → récap. Pas de bundle, pas de récap prématuré.

**Hard rule (philosophy §1 INVARIANT bloquant)** : aucune génération de fichier tant qu'une phase n'est pas validée. Si l'utilisateur veut "passer", ré-énonce et signale que ça bloque.

### Phase 1 — Récit du projet (texte libre, bloquante)

**Q1 — Question unique**

Pose **exactement** ceci et attends la réponse :

> Dis m'en plus sur les aspects métier du site que tu veux construire.

Aucune sous-question, aucun bullet, aucune liste d'exemples. La question doit rester nue. C'est l'utilisateur qui structure son récit, pas toi.

**Grille d'écoute interne** (jamais exposée à l'utilisateur)

À la réception, vérifie si tu peux identifier les trois angles principaux. Si oui même partiellement, passe en Phase 2.

1. **De quoi il s'agit** — activité, domaine, contexte, vocabulaire propre.
2. **Pour qui** — qui porte le projet, qui en bénéficie. Distingue si commanditaire ≠ utilisateur final (mais ne relance pas sur cette nuance ; capture comme zone à valider en Phase 2).
3. **Ce que ça doit faire ou permettre** — l'intention concrète, l'action ou la valeur produite.

**Grille d'écoute additionnelle** spécifique site vitrine — rien de plus. Pas de KPI, pas de personas, pas de user stories, pas de critère de succès mesurable.

**Au passage**, capte sans questionner : contraintes légales, stack imposée, références visuelles. Si présent, retiens. Si absent, **reste absent — pas de relance sur ces axes**.

**Hors scope ferme — ne pose JAMAIS ces questions en Phase 1** : budget, délais, planning de livraison. Ce n'est pas avec ça qu'on bootstrap.

**Règle de relance — UNIQUE et restrictive**

- Maximum **une** relance. Pas deux, pas "encore une dernière".
- Relance seulement si **un des trois angles principaux est absent au point de bloquer Phase 2**. Pas si "ce serait mieux d'en savoir plus".
- La relance est **une seule question courte** ciblée sur le manque le plus critique. Pas de liste, pas de bullets, pas plusieurs angles à la fois.
- Après la relance, peu importe la qualité de la réponse : **Phase 2 obligatoire**, avec hypothèse explicite si flou subsiste (l'utilisateur corrigera en Phase 2).

### Phase 2 — Acquittement de compréhension métier (prose courte, bloquante)

Avant tout choix technique, restitue ce que tu as compris du métier en **2-3 phrases de prose libre** — pas de bullets, pas de liste structurée. C'est un acquittement, pas un inventaire.

Format type :

> Si j'ai bien compris : <2-3 phrases reformulant le métier, la cible, l'intention, dans tes mots>. C'est juste ?

Attends confirmation ou correction. **Bloquant.** Si correction, intègre puis re-acquitte (court). Quand l'utilisateur valide, passe en Phase 3.

**Anti-pattern** : transformer cette restitution en liste à puces structurée — c'est une compression mécanique qui déforme le récit. Garde la prose, courte.

### Phase 3 — Technique adaptée (après Phase 2 validée)

À partir du métier acquitté, **annonce d'abord ton inférence**, puis pose en QCM (via `AskUserQuestion` côté Claude Code) les choix qui ne peuvent être inférés.

Format type :

> Vu ce que tu décris, j'infère :
> - Pages probables : <liste émergente, ex: accueil, présentation, formules, contact>
> - Formulaires probables : <inférés du contexte, ex: contact ou réservation>
> - Adapter probable : <Static si contenu pur, Node SSR si formulaires serveur>
>
> Je pose maintenant les choix techniques restants. L'ensemble (inférence + choix) sera ré-ouvert pour validation finale (Phase 4) avant scaffold.

Puis QCM groupé sur les choix structurés. Les options peuvent **varier selon le métier** (ex: ne pas proposer "Static" si le métier implique manifestement un formulaire serveur — propose Node SSR directement avec justification).

**Q-techniques modèles** (à adapter au métier) :

- **Framework des islands interactives** : React 19 (default code-conform) / Vue 3 / Svelte 5 / Aucun (Astro pur).
- **i18n** : Multilingue ? Langues + default. Default proposé : `fr` seul, sinon selon métier.
- **Contenu** : Statique MDX (default ≤ 10 pages immuables) / CMS headless (si client édite — Directus suggestion, ouvrir au choix si signal). Pour le choix CMS, cf. BACKLOG (discussion ouverte sur le caractère arbitraire de Directus default).
- **Adapter de rendu** : Static / Node SSR / Adapter hébergeur. Grille de tri :
  - **Astro Static** (`@astrojs/static`) — contenu fixé au build, formulaires inexistants ou via service tiers (Formspree, mailto), pas de personnalisation par utilisateur.
  - **Astro Node SSR** (`@astrojs/node` standalone) — formulaires traités côté serveur (SMTP, base), CMS rendu à la requête, i18n avec négociation Accept-Language, déploiement Docker. **Pages restent majoritairement statiques**, juste 1-3 routes dynamiques.
  - **Adapter hébergeur** (Vercel, Netlify, Cloudflare) — uniquement si plateforme connue à l'avance. Sinon Node SSR portable.

**Bascule honnête hors scope** : si le métier décrit dépasse une vitrine (app interactive permanente avec sessions/auth, dashboards, multi-rôles, billing récurrent, catalogue produits + panier + paiement, app B2B multi-tenant), **n'essaie pas d'adapter Astro pour ça**. Annonce honnêtement : *"Ce que tu décris dépasse le scope `bootstrap-site-vitrine`. Tu as besoin de <profil détecté>. Skill dédié : `/bootstrap-saas` ou `/bootstrap-ecommerce` (à venir). En attendant je ne génère rien."* Pas de *"je m'adapte"*, pas de *"je débrouille"*.

Critère : *"site avec quelques zones dynamiques"* → vitrine SSR ; *"app interactive avec une zone vitrine accessoire"* → hors scope, bascule.
- **Posture tokens** : A (noms-marque, si charte couleur donnée) / B (sémantique, default sinon). Cf. `atomic-design.md` §4.
- **Linter** : Biome (default) / ESLint+Prettier (sur signal).

### Phase 4 — Récap puis validation

**Pas de récap tant que Phase 3 incomplète.** Quand toutes les réponses techniques sont reçues, présente la synthèse exhaustive et **demande validation explicite** avant Étape 3.

Format type :

> Récap des décisions :
> - Métier : <résumé en 1-2 lignes>
> - Pages : <liste>
> - Formulaires : <liste>
> - Framework islands : <choix>
> - i18n : <choix>
> - Contenu : <choix>
> - Adapter : <choix>
> - Tokens : <choix>
> - Linter : <choix>
>
> Je procède au scaffold sur cette base ?

Attends "oui / valide / go" explicite. Pas de procédure tacite.

### Anti-patterns du cadrage

- ✗ Relancer parce que "plus de contexte serait mieux" (Phase 1).
- ✗ Relancer avec une liste de questions (Phase 1).
- ✗ Exposer la grille d'écoute à l'utilisateur (Phase 1).
- ✗ Demander budget, délais, planning (Phase 1, hors scope ferme).
- ✗ Demander un KPI, des personas, des user stories, des critères de succès mesurables (Phase 1).
- ✗ Demander la stack technique en Phase 1 (réservé à Phase 3).
- ✗ Transformer l'acquittement (Phase 2) en liste à puces structurée.
- ✗ Sauter Phase 2 et passer directement aux choix techniques.
- ✗ Récapituler les choix techniques (Phase 4) avant que tous soient reçus.

## Étape 3 — Génération de la structure

Annonce l'arbo avant exécution. Applique après accord.

### 3.1 Init Astro

```bash
pnpm create astro@latest . --template minimal --typescript strict --no-git
# selon Q2 :
pnpm astro add react   # ou vue, ou svelte, ou rien (Astro pur)
pnpm astro add tailwind   # ou installation manuelle Tailwind v4 si l'add fait v3
pnpm add -D @biomejs/biome
pnpm add -D @astrojs/sitemap
```

Si CMS Directus retenu (Q4=B) : `pnpm add @directus/sdk`.
Si Node SSR retenu (Q5=B) : `pnpm astro add node`.
Si formulaires : `pnpm add zod` + (selon Q2) `react-hook-form` ou `vee-validate` ou équivalent, + `sonner` ou équivalent toaster.
Helper UI : `pnpm add clsx tailwind-merge`.

### 3.2 Configuration Astro (`astro.config.mjs`)

```js
import { defineConfig } from 'astro/config'
import react from '@astrojs/react'      // ou vue / svelte selon Q2
import sitemap from '@astrojs/sitemap'
import tailwindcss from '@tailwindcss/vite'
// + node adapter si SSR (Q5=B)

export default defineConfig({
  site: 'https://example.com', // à remplacer
  integrations: [react(), sitemap()],    // adapter integration selon Q2
  vite: { plugins: [tailwindcss()] },
  // + i18n si Q3 = oui :
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
├── content/                        ← si Q4=A statique : MDX
│   └── config.ts                   ← schémas content collections
├── i18n/                           ← si Q3=oui
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

**Helper `cn`** — `src/utils/index.ts` :

```ts
import clsx, { type ClassValue } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]): string {
  return twMerge(clsx(inputs))
}
```

**`@theme` Tailwind v4** dans `src/styles/globals.css` (`@import "tailwindcss"` en tête). Selon posture tokens Q6 :

- **Posture B (sémantique — default)** : tokens neutres réutilisables.

```css
@import "tailwindcss";

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

  /* Marque (placeholder neutre — à brander via /design-system) */
  --color-primary:      oklch(0.56 0.08 273);
  --color-primary-deep: oklch(0.42 0.10 273);

  /* Sémantique (statuts toujours sémantiques même en posture A) */
  --color-error:   oklch(0.65 0.16 20);
  --color-success: oklch(0.78 0.18 156);
  --color-warning: oklch(0.78 0.14 60);

  /* Rayons */
  --radius-md: 9px;
}
```

- **Posture A (noms-marque)** : remplace les tokens neutres par les noms-marque convenus avec l'utilisateur. **Tokens de statut restent sémantiques** (`error`, `success`, `warning`) — règle dure cf. `atomic-design.md` §4.

Note : ce skill pose un **baseline architectural** avec des valeurs neutres. La direction artistique (palette définitive, typographie character, ambiance) relève du skill `/design-system` à invoquer séparément quand brand mûr.

### 3.5 Button de référence — `Button.astro`

Sur un site vitrine, la majorité des CTA sont statiques (lien ou submit). `.astro` suffit, pas besoin de React :

```astro
---
import { cn } from '@/utils'

type ButtonVariant = 'primary' | 'secondary' | 'outline'

interface Props {
  variant?: ButtonVariant
  href?: string
  class?: string
  disabled?: boolean
}

const { variant = 'primary', href, class: className, disabled } = Astro.props

const BASE =
  'inline-flex items-center justify-center px-6 py-3 rounded-lg font-medium text-sm transition-colors duration-200'

const VARIANT: Record<ButtonVariant, string> = {
  primary: 'bg-primary hover:bg-primary-deep text-white shadow-sm',
  secondary: 'bg-accent hover:bg-accent-deep text-white shadow-sm',
  outline: 'border border-primary text-primary hover:bg-primary/10',
}

const DISABLED = 'bg-rule text-fg-3 cursor-not-allowed'

const cls = cn(BASE, disabled ? DISABLED : VARIANT[variant], className)
---

{href ? (
  <a href={href} class={cls}><slot /></a>
) : (
  <button class={cls} disabled={disabled}><slot /></button>
)}
```

**Pourquoi `cn()` plutôt que concat template string** : `cn()` est défini dans `src/utils/index.ts` (clsx + tailwind-merge) — son rôle est de **fusionner** les classes Tailwind en cassant les conflits (ex: si `className` passé par le parent contient `bg-error`, il écrase proprement `bg-primary` de la variant). La concat template string ne fait pas ça : les deux classes coexistent, Tailwind prend la dernière déclarée dans son output, comportement fragile. Règle : **toujours `cn()` dès qu'un composant peut recevoir des classes par prop**.

Pour les atoms interactifs (formulaires, toaster), créer un `.tsx` React avec island (cf. §3.7).

### 3.6 Layout de base — `BaseLayout.astro`

- `<html lang={Astro.currentLocale}>` si i18n, sinon `lang="fr"`.
- `<head>` : title prop, meta description prop, favicon, fonts (`@font-face` déjà dans globals.css), OpenGraph minimal.
- `<slot />` pour contenu page.
- Footer minimal en bas, header en haut si organism `Header.astro` existe.

### 3.7 Content collections — `src/content.config.ts`

**Règle d'import Zod en projet Astro** :

- **Schémas de content collections** : `import { z } from 'astro/zod'` (Astro 6+). Le `z` exporté par `astro/zod` re-exporte Zod v4 garantie alignée avec celle qu'Astro utilise en interne. Pas besoin d'installer `zod` séparément si c'est la seule utilisation.
- `import { z } from 'astro:content'` est **deprecated** (Astro 6) — ne pas l'utiliser.
- **Zod hors content collections** (formulaires, frontières HTTP/CMS, schémas domain) : `import { z } from 'zod'` direct. Indépendant d'Astro, contrôle de version explicite.

Exemple type pour le métier site vitrine :

```ts
// src/content.config.ts
import { defineCollection } from 'astro:content'
import { z } from 'astro/zod'
import { glob } from 'astro/loaders'

const blog = defineCollection({
  loader: glob({ pattern: '**/*.{md,mdx}', base: './src/content/blog' }),
  schema: z.object({
    title: z.string(),
    description: z.string(),
    publishedAt: z.coerce.date(),
    updatedAt: z.coerce.date().optional(),
    tags: z.array(z.string()).default([]),
    draft: z.boolean().default(false),
  }),
})

const caseStudies = defineCollection({
  loader: glob({ pattern: '**/*.{md,mdx}', base: './src/content/case-studies' }),
  schema: z.object({
    client: z.string(),
    sector: z.string(),
    summary: z.string(),
    publishedAt: z.coerce.date(),
    metrics: z
      .object({
        trafficBefore: z.number().optional(),
        trafficAfter: z.number().optional(),
        timeframeMonths: z.number().optional(),
      })
      .optional(),
    draft: z.boolean().default(false),
  }),
})

export const collections = { blog, caseStudies }
```

Schémas typés à adapter au métier acquitté en Phase 2 — ne pas générer toutes les collections "au cas où". Si V1 n'a qu'un blog, ne déclare que `blog`. Le filtre fondamental s'applique aussi aux content collections.

### 3.8 Islands React (si interactivité)

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

### 3.9 CMS Directus (si Q4=B)

`src/infrastructure/directus.ts` minimal :

```ts
import { createDirectus, rest } from '@directus/sdk'

export const directus = createDirectus(import.meta.env.DIRECTUS_URL)
  .with(rest())
```

Types via `src/domain/<concept>/<Concept>.schema.ts` (Zod SSOT, cf. `typescript.md` §2). Pas de wrapper Repository — `directus.request(readItems(...))` direct dans la page, parse Zod en sortie.

### 3.10 i18n (si Q3=oui)

- `src/pages/[lang]/...` ou structure par locale selon préférence Astro (latest).
- `src/i18n/{fr,en}.json` pour traductions inline.
- Helper `t(key, lang)` simple (philosophy §4 — pas i18next sauf besoin réel).

### 3.11 `docs/conventions.md`

Crée à la racine avec :
- Adapter retenu, langues, posture tokens, CMS oui/non, choix linter.
- Renvoi à `~/.code-conform/docs/00-philosophy.md`, `~/.code-conform/docs/languages/typescript.md`, `~/.code-conform/docs/design/atomic-design.md`.

## Étape 4 — Validation

1. `pnpm dev` — démarre Astro dev server.
2. Type-check : `pnpm astro check`.
3. Build : `pnpm build` (signaler si échec).
4. Annoncer récap en 5 lignes : pages créées, islands éventuelles, prochaines étapes (premiers concepts métier, CMS à connecter, contenus à rédiger).

## Anti-patterns du skill

- ✗ Tout en React (`client:load` partout) — perd l'avantage Astro. Default = .astro statique, .tsx uniquement pour interactivité réelle.
- ✗ **Basculer vers Next/Nuxt par préférence framework**. Arguments non valides : *"je connais mieux React"* (Astro supporte React 19 en islands), *"Next est plus populaire / moderne"* (argument de mode), *"Next a plus d'écosystème"* (vrai mais signal de scope hors-vitrine, donc bascule vers `/bootstrap-saas` ou `/bootstrap-ecommerce` à venir, pas Next "en mode vitrine"). Legit signal = besoin Server Components/Server Actions/streaming SSR pour CE métier précis — mais alors on a quitté le scope vitrine et la bascule de skill est obligatoire (cf. Étape 2 / Phase 3 "Bascule honnête hors scope").
- ✗ Ajouter i18next, react-i18next sur un site bilingue minimal — l'i18n natif Astro + JSON suffit.
- ✗ Créer `src/services/`, `src/repositories/` — slicing horizontal (philosophy §6).
- ✗ Ajouter Storybook/Histoire par défaut. Pour 5-10 pages vitrine, l'inspection visuelle au dev server suffit.
- ✗ Forcer un CMS si statique convient (Markdown + content collections Astro). Filtre fondamental.
- ✗ Templates dans `src/components/templates/` — sur Astro le layout vit dans `src/layouts/`, pas dans atomic.
- ✗ ESLint + Prettier par défaut quand Biome convient. Skill = Biome default.

## Out of scope (renvoi)

- **App SaaS B2B** (multi-tenant, abonnements, dashboards, rôles, billing récurrent) → `/bootstrap-saas` (à venir).
- **E-commerce** (catalogue, panier, checkout, paiement one-shot, gestion commandes/stock) → `/bootstrap-ecommerce` (à venir).
- **Webapp interactive non-saas, non-ecommerce** (outil interne, collab tool, app pro) → pas de skill dédié encore, refuser honnêtement et inviter l'utilisateur à cadrer hors de ce skill.
- **Audit d'un site vitrine existant** → `/audit-site-vitrine`.
- **Direction artistique / brand design** (palette identitaire, typographie character, ambiance) → `/design-system` (à venir) — à invoquer quand brand mûr.
- **CLI** → `/bootstrap-cli`.
- **App desktop** → `/bootstrap-app-desktop` (Tauri).
