---
name: audit-site-vitrine
description: Audit d'un site vitrine existant aux conventions code-conform — Astro v5 (ou Next override), atomic, i18n, hydratation islands, performance shipped JS, CMS. Mode audit philosophy §8 — pas d'auto-modification.
---

# /audit-site-vitrine

Skill **audit** : revue d'un site vitrine déjà déployé ou en cours. Diagnostic structuré, propositions de corrections par lots validées. **N'auto-modifie rien sans accord explicite.**

Si le projet est vide → propose `/bootstrap-site-vitrine`. Si c'est un SaaS (auth, dashboard, multi-pages dynamiques) → renvoi vers `/audit-saas`. Si c'est une CLI ou desktop → renvoi correspondant.

## Posture (lire avant tout)

L'audit mesure la **conformité aux conventions code-conform** — pas tous les bugs ou imperfections détectables. La distinction est structurante :

- **Dans la SSOT** (philosophy, atomic-design, typescript) → écart au référentiel, organisé en **3 lots ordonnés par criticité architecturale** (recadrage fondations → refactors transverses → détails ponctuels).
- **Hors SSOT** (sécurité applicative, RGPD, SEO structuré, bugs HTML ponctuels, perfs) → observations signalées dans une section dédiée, **jamais mélangées aux lots SSOT**.

Le rapport n'est pas un menu à la carte. C'est un **plan d'attaque séquentiel** que l'utilisateur peut accepter, ajuster ou désactiver par lot — mais l'ordre est imposé par la dépendance architecturale (les détails ne se traitent pas avant les fondations).

**Anti-pattern signature à éviter (test 1 agay 2026-05-21)** : produire un rapport "audit qualité de code générique" avec des références SSOT plaquées dessus (citations `philosophy §3` sans phrase-clé, écarts SSOT et bugs HTML au même niveau, 18 mineurs en vrac, pas de plan d'attaque). C'est un audit *amélioré*, pas un audit *code-conform*.

## Pré-requis — SSOT à charger

- `~/.code-conform/docs/00-philosophy.md` — invariants, mode audit (§8), filtre fondamental.
- `~/.code-conform/docs/languages/typescript.md` — strict TS, conventions naming.
- `~/.code-conform/docs/design/atomic-design.md` — atomic, tokens structure, a11y, smells. Couvre l'archi UI ; pas la dimension design pure (brand, ambiance).
- `docs/conventions.md` du projet si présent.

## Hard rule — usage de la SSOT (INVARIANT)

Quand tu juges un écart, tu **dois** consulter la section SSOT pertinente **au moment** où tu formules l'écart — pas en lecture inspirationnelle au démarrage. Charger les docs en début de session ≠ les avoir en mémoire au moment du rapport (dilution d'attention en long contexte, cf. `RATIONALE §12`). Le risque est **plus élevé** ici qu'en bootstrap : cartographie + grille A-J + rapport par lots = contexte long, dérive vers training data ("audit générique de qualité de code") au lieu de la SSOT.

Concrètement :
- **`Read` la section ciblée juste avant** de formuler l'écart (ex: `philosophy §3` pour une classe-acteur vs donnée pure, `atomic-design.md §13` pour un smell DS, `typescript.md §1` pour Zod aux frontières).
- **Cite la phrase-clé ou le pattern exact** dans le rapport ("`philosophy §3` : *la classe est réservée à l'acteur avec état/deps*"), pas une reformulation de mémoire.

Anti-patterns :
- ✗ *"Je connais le pattern, j'applique"* → dérive vers audit générique.
- ✗ Citer un numéro de section sans la phrase-clé (`philosophy §3` seul = référence floue, pas opposable).
- ✗ Mélanger écarts SSOT et observations hors SSOT au même niveau → effet "massue indistincte" sur l'utilisateur.

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

Format **imposé**. Trois lots SSOT ordonnés + section hors-SSOT distincte. Pas de hiérarchie "majeurs/mineurs" indistincte.

```
# Audit site vitrine — <projet>

## Carte rapide
- Astro v<…>, adapter <…>, Tailwind v<…>
- Pages : N (dont M i18n localisées)
- Islands : N (dont M client:load suspectes)
- CMS : <Directus | statique | autre>
- DS : <conforme | écarts présents>

## Lot 1 — Recadrage aux conventions code-conform (fondations)

Écarts structurels. À traiter en premier car le reste s'appuie dessus.

Catégories typiques :
- Slicing / archi (`philosophy §6` — vertical par concept métier).
- Formes citoyennes (`philosophy §3` — classe = acteur uniquement, pas wrapper donnée pure).
- Frontière Zod unique (`philosophy §5` INVARIANT — pas de double validation).
- Atomic structure (`atomic-design.md §3` — atoms/molecules/organisms cohérent).

Pour chaque écart : fichier:ligne, **citation SSOT verbatim**, diagnostic en 1-2 phrases, proposition correctrice.

## Lot 2 — Refactors transverses

Écarts qui touchent N endroits. Coût élevé, souvent répétitif, mais mécanique une fois Lot 1 fait.

Catégories typiques :
- Tokens (`atomic-design.md §4` — toute couleur hors `@theme` = écart).
- Hydratation islands (`.tsx` non interactif, `client:load` superflu).
- Validation dupliquée hors frontière (`philosophy §5`).
- Patterns variants non `Record<Variant>` répétés.

## Lot 3 — Détails ponctuels

Feuilles. Peu invasifs, isolés.

Catégories typiques :
- A11y (`atomic-design.md §11` — skip-link, `alt`, hiérarchie heading).
- Conventions HTML (`type="button"`, attributs ARIA manquants).
- Petits bugs ponctuels (`id` doublon, token mort isolé, texte non i18n résiduel).

## Hors SSOT — observations applicatives

**Pas un écart au référentiel.** Bonus de l'audit signalé en transparence — l'utilisateur arbitre indépendamment des lots SSOT.

Catégories typiques : fuites RGPD / data exposure, CSP / security headers, Schema.org / structured data, rate-limit scalabilité, perfs / Core Web Vitals, bugs métier visibles.

## Conforme

Axes du projet qui respectent la SSOT — explicite, court (3-6 bullets).
```

## Étape 4 — Plan d'attaque proposé

**INVARIANT** — aucune modification sans accord explicite.

Le plan suit l'ordre du rapport (Lot 1 → Lot 2 → Lot 3 → Hors-SSOT optionnel). Dépendance architecturale : **les détails ne se traitent pas avant les fondations**. Pas de menu à la carte.

Format proposé à l'utilisateur :

> Voici le plan d'attaque proposé :
>
> **Lot 1 — Recadrage** (N écarts) : <liste résumée>. Impact large, refactor structurel. À faire en premier.
> **Lot 2 — Refactors transverses** (N écarts) : <liste résumée>. À faire après Lot 1 (les refactors s'appuient sur la structure recadrée).
> **Lot 3 — Détails** (N écarts) : <liste résumée>. À faire après Lot 2.
> **Hors-SSOT** (N observations) : <liste résumée>. Optionnel, à arbitrer indépendamment — pas une convention code-conform.
>
> Tu peux : valider tel quel / désactiver un lot entier / sauter au Lot 2 ou 3 si tu sais que les précédents sont déjà faits ou non prioritaires / traiter Hors-SSOT à part. **Tu ne peux pas piocher en désordre dans un même lot** — un lot est cohérent par construction.

Une fois le plan validé, exécuter lot par lot via `AskUserQuestion` (multi-select) sur les fichiers du lot courant. Pour chaque modification proposée : fichier, diff représentatif, accord, application. Compléter `docs/conventions.md` au fil de l'eau pour acter les choix de bascule (ex: DDD Booking assumé vs `philosophy §3` strict).

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
