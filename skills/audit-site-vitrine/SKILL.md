---
name: audit-site-vitrine
description: Audit d'un site vitrine existant aux conventions code-conform — Astro v5 (ou Next override), atomic, i18n, hydratation islands, performance shipped JS, CMS. Mode audit philosophy §8 — pas d'auto-modification.
---

# /audit-site-vitrine

Skill **audit** : revue d'un site vitrine déjà déployé ou en cours. Diagnostic structuré, propositions de corrections par lots validées. **N'auto-modifie rien sans accord explicite.**

Si le projet est vide → propose `/bootstrap-site-vitrine`. Si c'est un SaaS (auth, dashboard, multi-pages dynamiques) → renvoi vers `/audit-saas`. Si c'est une CLI ou desktop → renvoi correspondant.

## Pré-requis — SSOT à charger

- `~/.code-conform/docs/00-philosophy.md` — invariants, mode audit (§8), filtre fondamental.
- `~/.code-conform/docs/languages/typescript.md` — strict TS, conventions naming.
- `~/.code-conform/docs/design/atomic-design.md` — atomic, tokens structure, a11y, smells. Couvre l'archi UI ; pas la dimension design pure (brand, ambiance).
- `docs/conventions.md` du projet si présent.

## Étape 1 — Cartographie

Inspecter sans modifier :

- **Framework + version** depuis `package.json` (Astro 5 ? Next ? Autre ?). Si autre que Astro v5 → signaler comme écart contextuel, demander la raison (signal réel ou choix par défaut).
- **Adapter Astro** : `@astrojs/static`, `@astrojs/node`, hébergeur (Vercel/Netlify/Cloudflare). Cohérent avec usage (formulaires serveur → SSR) ?
- **Tailwind v4 + plugin Vite** (`@tailwindcss/vite`) ? Si Tailwind v3 → écart majeur.
- **Linter** : Biome (default code-conform) ou ESLint+Prettier ?
- **i18n** : intégration native Astro (`i18n` config) ou lib externe (i18next) ? Si externe sans besoin réel → écart.
- **CMS** : `@directus/sdk` ? Autre ? Aucun (statique pur) ?
- **DS** : appliquer la grille DS de `atomic-design.md` (§3 atomic, §4 tokens, §5 composants, §11 a11y, §13 smells) sur `src/components/`.
- **Pages** : `src/pages/` — combien, routing par fichier, présence `[...lang]` ou `[lang]` pour i18n.
- **Layouts** : `src/layouts/` (Astro idiomatique). Si layouts dans `src/components/templates/` → écart.
- **Islands** : compter les `.tsx` consommés depuis `.astro` et leurs directives `client:*`. Repérer hydratation excessive.

Annonce la carte en 5-8 lignes.

## Étape 2 — Grille d'audit

### A — Astro et configuration

- [ ] Astro ≥ 5 (sinon migration à proposer).
- [ ] `astro.config.mjs` minimal et lisible — pas de surcharge.
- [ ] `site` renseigné (sitemap, OpenGraph dépendent).
- [ ] `@astrojs/sitemap` activé si site public indexable.
- [ ] Adapter choisi cohérent avec usage (static si pas de serveur nécessaire, Node si SSR / formulaires).
- [ ] Configuration i18n native Astro utilisée si site multilingue — pas i18next sans signal.

### B — Hydratation et performance JS

- [ ] **Default = `.astro` statique** pour atoms / molecules / organisms non interactifs. Tout en `.tsx` = écart majeur (perte de l'avantage Astro).
- [ ] Islands `.tsx` uniquement sur composants réellement interactifs (formulaires, toaster, widget date).
- [ ] Directives `client:*` graduées :
  - `client:load` réservé à l'interactif au-dessus du fold.
  - `client:visible` ou `client:idle` pour le reste.
  - `client:media` pour responsive-only.
- [ ] Pas de `client:load` sur tout — signaler chaque cas.
- [ ] Hydration JS shipped < 50KB sur page d'accueil idéalement (sans audit Lighthouse formel, repérer les imports lourds).

### C — DS atomic (depuis `atomic-design.md`)

Appliquer la grille DS complète sur `src/components/`. Ajout spécifique site vitrine :

- [ ] Atoms statiques en `.astro`, atoms interactifs en `.tsx`. Mix cohérent et justifié.
- [ ] `Button.astro` : variants en `Record<Variant, classes>`, slot par défaut pour children.
- [ ] Layouts dans `src/layouts/`, pas dans `components/templates/`.

### D — Tokens et thème

- [ ] `@theme` dans CSS racine, cohérent (posture A ou B explicite).
- [ ] Tokens utilisés réellement (chaque token a au moins un consommateur).
- [ ] Couleurs en OKLCH ou hex selon charte (cohérence interne).
- [ ] Statuts sémantiques (`error`, `success`) présents même en posture A.

### E — Contenu (statique vs CMS)

- [ ] Si contenu statique : `src/content/` avec content collections + `config.ts` typé (Zod-like). Pas de markdown ad-hoc dispersé.
- [ ] Si CMS : `src/infrastructure/directus.ts` minimal, `src/domain/<concept>/` avec schéma Zod SSOT, parse en sortie de SDK.
- [ ] Pas de wrapper Repository inutile autour du SDK (philosophy §5 — concret par défaut).
- [ ] Variables d'environnement nommées explicites (`DIRECTUS_URL`, etc.), pas de secret en dur.

### F — i18n (si multilingue)

- [ ] Native Astro (`i18n` config + `Astro.currentLocale`). i18next/react-i18next écarté sauf besoin réel.
- [ ] Traductions en JSON par locale ou dans content collections — pas dispersées.
- [ ] `<html lang>` correct sur chaque page.
- [ ] URLs cohérentes (`prefixDefaultLocale` cohérent avec stratégie SEO).
- [ ] Sitemap multilingue généré (`@astrojs/sitemap` avec config i18n).

### G — Formulaires (si présents)

- [ ] Validation Zod (SSOT cf. `typescript.md`).
- [ ] Frontière côté serveur si SSR : action endpoint qui parse Zod avant de traiter.
- [ ] Pas de double validation (philosophy §5 INVARIANT).
- [ ] react-hook-form + Sonner si formulaires complexes ; minimal sinon.
- [ ] Anti-spam basique (honeypot, rate-limit côté serveur) — signaler absence.
- [ ] Accessibilité : `<label htmlFor>`, messages d'erreur reliés via `aria-describedby` (`atomic-design.md` §11).

### H — SEO et métadonnées

- [ ] `title` + `description` uniques par page.
- [ ] OpenGraph / Twitter Card minimum (image, titre, description).
- [ ] `<link rel="canonical">` si i18n / variations.
- [ ] Sitemap généré, `robots.txt` cohérent.
- [ ] Structured data (`Schema.org`) sur pages clés (organisation, article, événement, restaurant…) si pertinent.

### I — Accessibilité (renvoi `atomic-design.md` §11)

Re-passer la checklist a11y de `atomic-design.md`. Spécifique vitrine :

- [ ] Hiérarchie heading correcte par page (`<h1>` unique, structure logique).
- [ ] Images : `alt` non vide, ou `alt=""` explicite pour décoratif.
- [ ] Navigation clavier : skip-link en début de body (`<a href="#main">Aller au contenu</a>`).
- [ ] `prefers-reduced-motion` respecté si animations.

### J — Build et déploiement

- [ ] `pnpm build` réussit sans warning suspect.
- [ ] Pas d'env var sensible exposée dans le bundle client (`import.meta.env.PUBLIC_*` seulement).
- [ ] Si Docker : Dockerfile multi-stage (build → runtime minimal).
- [ ] Adapter SSR : `node:standalone` pour autonomie, ou hébergeur si plateforme connue.

## Étape 3 — Rapport

```
# Audit site vitrine — <projet>

## Carte rapide
- Astro v<…>, adapter <…>, Tailwind v<…>
- Pages : N (dont M i18n localisées)
- Islands : N (dont M client:load suspectes)
- CMS : <Directus | statique | autre>
- DS : <conforme | écarts mineurs | écarts majeurs>

## Écarts majeurs
1. ...
## Écarts mineurs
1. ...
## Conforme
- <axes sans action>
## Suggestions hors écart
- ...
```

## Étape 4 — Correction interactive

**INVARIANT** — aucune modification sans accord explicite.

Lots typiques pour un site vitrine :

1. **Migration Astro v<n> → v5** si applicable.
2. **Dégradation hydratation** : convertir `client:load` superflus en `client:visible` ou `client:idle`. Convertir composants `.tsx` non interactifs en `.astro`.
3. **Tailwind v3 → v4** si applicable (cf. lot DS audit).
4. **DS archi** : corrections issues de l'axe C (atomic, tokens structure, variants, a11y) — traiter par lots si volumineux.
5. **i18n** : remplacer i18next par Astro natif si signal absent ; cohérence des URL/sitemap.
6. **Formulaires** : factoriser validation Zod, brancher Sonner, ajouter anti-spam minimal.
7. **SEO** : compléter meta, canonical, sitemap, structured data.
8. **a11y** : skip-link, hiérarchie heading, `alt`.
9. **`docs/conventions.md`** : créer ou compléter.

Pour chaque lot : lister fichiers concernés, montrer diff représentatif, demander accord, appliquer.

## Anti-patterns du skill

- ✗ Auto-modification sans accord.
- ✗ Proposer Next.js comme remplacement par préférence — Astro reste sauf signal réel (cf. `bootstrap-site-vitrine`).
- ✗ Inventer un seuil "trop d'islands" — demander à l'utilisateur si le seuil influence une décision (philosophy §9).
- ✗ Mécaniquement remplacer `.tsx` par `.astro` — certains composants interactifs **doivent** rester React (forms complexes, datepicker, toaster).
- ✗ Recommander Storybook/Histoire sur un site 5 pages — l'inspection au dev server suffit (filtre fondamental).
- ✗ Auditer le contenu rédactionnel (orthographe, ton) — hors scope, c'est du métier.

## Out of scope (renvoi)

- **Projet sans Astro** (CRA, Vite SPA pure) → demander la raison ; si signal absent, proposer rebootstrap via `/bootstrap-site-vitrine`.
- **Direction artistique / brand design** (palette identitaire, typo character, ambiance) → `/design-system` (à venir).
- **App interactive permanente** → `/audit-saas`.
- **Performance fine** (Core Web Vitals, Lighthouse score) → hors scope conventions ; signal utilisateur requis.
