---
name: audit-design-system
description: Audit d'un design system existant aux conventions code-conform — diagnostic structuré (tokens, atomic, variants, a11y) + propositions de corrections validées par l'utilisateur. Mode audit philosophy §8 — pas d'auto-modification.
---

# /audit-design-system

Skill **audit** : revue d'un DS déjà posé dans le projet (`src/components/` ou équivalent). Identifie les écarts vs SSOT code-conform, restitue un rapport structuré, propose les corrections par lot avec validation utilisateur. **N'auto-modifie rien sans accord explicite.**

Si le projet n'a pas de DS posé → sors immédiatement et propose `/init-design-system`.

## Pré-requis — SSOT à charger

- `~/.code-conform/docs/architecture/00-philosophy.md` — invariants, mode audit (§8), filtre fondamental (§4).
- `~/.code-conform/docs/architecture/ui.md` — toutes sections, en particulier §3, §4, §5, §8, §10, §11, §13.
- `~/.code-conform/docs/architecture/<langage>.md` — selon stack (typiquement `typescript.md`).
- `docs/conventions.md` du projet s'il existe — les seuils déjà actés y vivent.

## Étape 1 — Détection et cartographie

Inspecter sans modifier. Cartographier en une passe rapide :

- **Framework + version** depuis `package.json` (Next, Nuxt, Vite, Tauri, Svelte…). Tailwind v4 présent ? Plugin (`@tailwindcss/{vite,postcss}`) ? Si Tailwind v3 ou absent → écart majeur à signaler.
- **Localisation du DS** : `src/components/`, `src/ui/`, `src/design-system/`, autre ? Si autre que `src/components/` → écart convention code-conform à signaler.
- **Niveaux atomic présents** : `atoms/`, `molecules/`, `organisms/`, `templates/`, `brand/`, `icons/`. Lister.
- **Inventaire** : nombre de fichiers par niveau (sans les lire tous). `find <ds-root> -name '*.tsx'` ou équivalent par framework.
- **Tokens** : repérer le fichier `@theme` (CSS racine). Lire intégralement. Identifier la posture (A noms-marque / B sémantique / mixte / chaos).
- **Helper `cn`** : présent dans `utils/` ou équivalent ? `clsx + tailwind-merge` utilisés ?
- **Variants** : ouvrir 3-5 atoms représentatifs (Button surtout). Pattern utilisé ? (`Record<Variant>`, `switch/case`, helpers `getXxxStyle` cumulés, `tv`/`cva`, concaténation manuelle).
- **Domaine** : `src/domain/<concept>/` existe ? Slicing vertical ou horizontal ? Organisms métier mélangés à `components/organisms/` ?
- **State** : `src/stores/`, `src/store/`, ou rien ? Zustand ?
- **`docs/conventions.md`** : présent ? Aligné avec les décisions visibles dans le code ?

Annonce la carte à l'utilisateur en 5-8 lignes avant de passer à la grille.

## Étape 2 — Grille d'audit

Audite contre la liste ci-dessous. Pour chaque item : *conforme*, *écart mineur*, *écart majeur*, ou *non applicable*. Justifie par citation de fichier/ligne (`<path>:<line>`).

### A — Setup et tooling (`ui.md` §2)

- [ ] Tailwind v4 (≥ 4.0). v3 = écart majeur.
- [ ] Plugin natif (`@tailwindcss/{vite,postcss}`) cohérent avec le bundler.
- [ ] `@import 'tailwindcss';` unique, pas d'anciennes directives `@tailwind base/components/utilities`.
- [ ] Helper `cn` exporté (`utils/index.ts` ou équivalent), basé sur `clsx + tailwind-merge`.
- [ ] Alias d'import cohérent (`@/` ou `@/src/`), pas mixé.
- [ ] `prettier-plugin-tailwindcss` si Prettier présent.

### B — Tokens (`ui.md` §4)

- [ ] Posture cohérente A *ou* B (pas un mix involontaire) — sauf statuts sémantiques (`error`, `success`, `warning`) qui sont **toujours** sémantiques même en posture A.
- [ ] Aucune valeur visuelle en dur dans les composants (`#FFF`, `bg-blue-500`, `16px` inline). Tout passe par tokens.
- [ ] Tokens en OKLCH (pas hex/rgb sauf charte imposée).
- [ ] Si dark mode actif : `@custom-variant dark` + `.dark` ou `[data-theme=dark]` propres.
- [ ] Pas de palette "au cas où" — chaque token est consommé ≥1 fois (sinon proposer suppression).

### C — Atomic design et organisation (`ui.md` §3, §10)

- [ ] DS transverse dans `src/components/` (pas `src/ui/`).
- [ ] Atoms = primitives non décomposables, **zéro métier**. Anti-pattern : `UserAvatar`, `PriceTag` dans `atoms/`.
- [ ] Molecules = assemblages 2-3 atoms, **zéro métier**.
- [ ] Organisms métier dans `src/domain/<concept>/`, pas dans `components/organisms/`.
- [ ] Pas de slicing horizontal global (`entities/`, `services/`, `repositories/` à la racine du domain — cf. philosophy §6).
- [ ] Niveaux optionnels (`templates`, `brand`, `icons`) justifiés par signal réel, pas par anticipation.
- [ ] Barrels `index.ts` par niveau cohérents (si présents).

### D — Composants (`ui.md` §5, §6, §8, §12)

- [ ] Composant pur (stateless) = forme par défaut. État local au composant pour cas locaux (toggle, hover).
- [ ] Aucune logique métier dans un composant — déléguée aux helpers du concept.
- [ ] **Mutation du domain depuis l'UI interdite** (INVARIANT philosophy §8). `img.status = 'done'` dans un composant = écart majeur.
- [ ] Atoms et molecules : pas de dépendance au store global. Props uniquement.
- [ ] Hooks métier vivent dans `src/domain/<concept>/`, pas dans `src/hooks/`.
- [ ] Props nommées par rôle (`variant`, `intent`, `size`), pas par implémentation (`bg`, `px`).
- [ ] Variants : `Record<Variant, classes>` par défaut. `switch/case` cumulés, helpers `getXxxStyle` chaînés, `tv`/`cva` sans signal réel = écarts à signaler.
- [ ] Cleanup obligatoire sur souscriptions/timers/listeners (`useEffect` return, `onUnmounted`, `$effect` cleanup).
- [ ] React 19 : pas de `forwardRef` (ref est prop standard).

### E — Frontières et validation (`ui.md` §7, philosophy §5 INVARIANT)

- [ ] Parsing Zod (ou équivalent) à l'entrée de page / sous-arbre stateful (frontière externe).
- [ ] Composants intermédiaires ne re-validlent pas — types TS suffisent.
- [ ] Soumission de formulaire = frontière (parse avant d'envoyer au domain).

### F — Erreurs (`ui.md` §9)

- [ ] Erreurs métier (champ invalide) affichées inline, pas en toast.
- [ ] Error boundary présent par zone fonctionnelle critique (au moins racine app).
- [ ] Pas de catch silencieux (`try { ... } catch {}` sans traitement).
- [ ] Trois états explicites pour donnée async : loading, error, success.

### G — Accessibilité (`ui.md` §11)

- [ ] `<button>` pour action, `<a>` pour nav, pas de `<div onClick>` interactif.
- [ ] Tout `<input>` a un `<label htmlFor>` ou `aria-label`. Placeholder seul = écart.
- [ ] Boutons-icône avec `aria-label` obligatoire.
- [ ] `focus-visible` conservé (pas de `outline: none` sans remplacement).
- [ ] Contraste WCAG AA respecté par les tokens (vérifier visuellement les pairs `bg-*` + `text-*`).
- [ ] Composants composés (dialog, menu, listbox, tabs) : utilisation d'une lib headless a11y-aware (Radix, Ariakit, Headless UI, Reka), pas de réinvention.

### H — Smells transverses (`ui.md` §13)

Passer rapidement les 20 entrées du tableau §13. Marquer celles vues dans le code, avec citation.

## Étape 3 — Rapport

Présenter le résultat sous forme structurée, **sans correction encore** :

```
# Audit DS — <projet>

## Carte rapide
- Framework : <…>
- Tailwind : <v4 / v3 / absent>
- DS root : <src/components | src/ui | …>
- Posture tokens : <A / B / mixte / chaos>
- Variants pattern : <Record | switch/case | tv | mixte>
- Atoms : N, Molecules : N, Organisms : N (dont M métier mal placés)

## Écarts majeurs (bloquants)
1. <smell> — <path:line> — <référence ui.md §X>
2. …

## Écarts mineurs (à traiter)
1. …

## Conforme / pas d'action
- <axes A à H sans écart>

## Recommandations hors écart (suggestions)
- <ex: introduire docs/conventions.md, activer Prettier plugin>
```

Cible : rapport lisible en moins de 2 minutes par l'utilisateur. Si un axe ne trouve **rien**, le dire — pas de remplissage pour faire bonne mesure.

## Étape 4 — Correction interactive

**INVARIANT** — Aucune modification de fichier sans accord explicite.

Procéder par **lots cohérents**, pas écart par écart (qui serait épuisant). Lots typiques :

1. **Migration Tailwind v3 → v4** si applicable (changement infra, à faire en premier ou en dernier selon préférence).
2. **Renommage / déplacement structurel** (`src/ui/` → `src/components/`, organisms métier dans `domain/`).
3. **Refactor variants** : passer `switch/case` ou `tv`-sans-besoin vers `Record<Variant>`.
4. **Tokens** : nettoyer mix posture, ajouter statuts sémantiques manquants, retirer tokens non consommés.
5. **a11y** : ajouter `aria-label` manquants, remplacer `<div onClick>` par `<button>`, restaurer `focus-visible`.
6. **Frontières** : supprimer re-validations internes, ajouter parsing manquant en entrée de page.
7. **`docs/conventions.md`** : créer ou compléter avec les choix observés et arbitrés pendant l'audit.

Pour chaque lot :
- Lister les fichiers concernés.
- Montrer diff prévu (1-2 exemples représentatifs si lot volumineux).
- Demander accord (lot complet, sélection, skip).
- Appliquer uniquement après accord.
- Lancer `type-check` après chaque lot ; signaler les erreurs résiduelles.

## Anti-patterns du skill (à NE PAS faire)

- ✗ Modifier des fichiers avant d'avoir présenté le rapport et obtenu l'accord.
- ✗ Inférer le métier depuis les noms (philosophy §8 INVARIANT — *"Lire un nom comme `Order` te donne du vocabulaire de surface, pas le métier réel"*). Ce qui ressemble à un atom métier (`UserAvatar`) peut être légitime si le projet l'a explicitement validé — **demander avant de proposer le déplacement**.
- ✗ Inventer des seuils chiffrés ("trop d'atoms", "fichier trop long") — philosophy §9. Si un seuil influence une décision, demander à l'utilisateur, capturer dans `docs/conventions.md`.
- ✗ Mécaniquement "corriger" vers `tv` parce que c'est dans la doc — `Record<Variant>` reste le default, `tv` ne se justifie que sur signal réel (`ui.md` §8).
- ✗ Tout marquer comme écart pour faire un rapport "riche". Les axes conformes se déclarent conformes.
- ✗ Couvrir le code applicatif au-delà du DS (routes, pages, business logic). Audit DS = scope DS. Pour le reste, renvoyer aux audits par contexte (`/audit-site-vitrine`, etc.).
- ✗ Ré-auditer après chaque lot pour générer un nouveau rapport complet — incrémenter sur place suffit.

## Out of scope (renvoi)

- **Projet sans DS** → `/init-design-system`.
- **Audit projet entier** (routing, archi back, build) → skills `/audit-{site-vitrine,app-desktop,saas,cli}` (BACKLOG).
- **DS partagé multi-projets** (lib DS interne consommée par plusieurs apps) → `/audit-shared-design-system` (BACKLOG).
- **Performance UI / bundle size** → hors scope DS conventions. Sujet propre, à traiter sur signal utilisateur.
