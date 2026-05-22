---
name: audit-site-vitrine
description: Audit d'un site vitrine existant aux conventions code-conform — Astro (latest) + atomic + i18n + hydratation islands + CMS optionnel. Boucle axe par axe avec sub-agent ciblé. Mode audit philosophy §8 — pas d'auto-modification.
---

# /audit-site-vitrine

Skill **audit** : revue d'un site vitrine déjà déployé ou en cours. **N'auto-modifie rien sans accord explicite.**

Si le projet est vide → propose `/bootstrap-site-vitrine`. Si c'est un SaaS (auth, dashboard, multi-pages dynamiques) → renvoi vers `/audit-saas`. Si c'est une CLI ou desktop → renvoi correspondant.

## Posture (lire avant tout)

L'audit mesure la **conformité aux conventions code-conform** — pas tous les bugs ou imperfections détectables. La distinction est structurante :

- **Dans la SSOT** (philosophy, atomic-design, typescript) → écart au référentiel, organisé en **lots ordonnés par criticité architecturale** (recadrage fondations → refactors transverses → détails ponctuels).
- **Hors SSOT** (sécurité applicative, RGPD, SEO structuré, bugs HTML ponctuels, perfs) → observations signalées dans une section dédiée, **jamais mélangées aux lots SSOT**.

**Pattern de travail (INVARIANT)** : l'audit ne se fait **pas en une passe globale**. Le LLM principal n'inspecte **pas** le projet directement en profondeur — il dérive sa propre checklist d'axes depuis la SSOT chargée, puis pour chaque axe **délègue le scan à un sub-agent ciblé**. Cela évite la dilution d'attention en long contexte (cf. `RATIONALE §12`) qui fait manquer des écarts en audit-en-bloc — friction observée et documentée sur le test 2 agay (2026-05-22).

**Anti-pattern signature à éviter** : produire un rapport "audit qualité de code générique" avec des références SSOT plaquées dessus (citations `philosophy §3` sans phrase-clé, écarts SSOT et bugs HTML au même niveau, plan d'attaque absent). C'est un audit *amélioré*, pas un audit *code-conform*.

## Pré-requis — SSOT à charger

- `~/.code-conform/docs/00-philosophy.md` — invariants, mode audit (§8), filtre fondamental.
- `~/.code-conform/docs/languages/typescript.md` — strict TS, conventions naming, modules domaine.
- `~/.code-conform/docs/design/atomic-design.md` — atomic, tokens structure, a11y, smells. Couvre l'archi UI ; pas la dimension design pure (brand, ambiance).
- `docs/conventions.md` du projet si présent.

## Hard rule — usage de la SSOT (INVARIANT)

Quand tu juges un écart, tu **dois** consulter la section SSOT pertinente **au moment** où tu formules l'écart — pas en lecture inspirationnelle au démarrage. Charger les docs en début de session ≠ les avoir en mémoire au moment du rapport (dilution d'attention en long contexte, cf. `RATIONALE §12`). Le risque est **plus élevé** ici qu'en bootstrap : contexte multi-axes pluri-passes, dérive vers training data ("audit générique de qualité de code") au lieu de la SSOT.

Concrètement :

- **`Read` la section ciblée juste avant** de formuler l'écart (ex: `philosophy §3` pour une classe-acteur vs donnée pure, `atomic-design.md §13` pour un smell DS, `typescript.md §1` pour Zod aux frontières).
- **Cite la phrase-clé ou le pattern exact** dans le rapport ("`philosophy §3` : *la classe est réservée à l'acteur avec état/deps*"), pas une reformulation de mémoire.

Anti-patterns :

- ✗ *"Je connais le pattern, j'applique"* → dérive vers audit générique.
- ✗ Citer un numéro de section sans la phrase-clé (`philosophy §3` seul = référence floue, pas opposable).
- ✗ Mélanger écarts SSOT et observations hors SSOT au même niveau → effet "massue indistincte" sur l'utilisateur.

## Étape 1 — Préparation et checklist dérivée

**Lecture surface uniquement** : `package.json`, `astro.config.*`, structure top-level (`src/`, contenu de `src/components/` au niveau dossier), `docs/conventions.md` du projet. **Pas de Read en profondeur** du code applicatif — c'est le sub-agent qui s'en chargera, axe par axe.

À partir de la SSOT chargée et du projet observé en surface, **dérive ta propre checklist d'axes à auditer**. Ne suis pas une liste pré-câblée — elle dérive de la SSOT effective et évolue avec elle.

**Critère d'ordonnancement** :

> Du plus structurant au plus ponctuel. Un écart sur l'axe N+1 ne doit pas devenir caduque si l'axe N est corrigé d'abord.
>
> - **Fondations** : tout ce qui touche au squelette du projet (slicing, formes citoyennes, frontières, structure atomic). Un refactor ici déplace tout le reste.
> - **Transverses** : ce qui apparaît à N endroits cohérents (tokens, duplications de logique, conventions de variants, hydratation islands, versioning). Mécanique après les fondations.
> - **Détails** : feuilles isolées (a11y ponctuelle, conventions HTML, petits bugs). Indépendants entre eux.
>
> Identifie les axes en parcourant la SSOT chargée — **INVARIANTS d'abord**, règles dures ensuite, conventions au-delà. Couvre tout ce qui est applicable au type de projet audité, rien d'inventé hors SSOT.

Annonce à l'utilisateur :

- **Carte rapide** en 5-8 lignes (stack, versions, taille du projet — depuis la lecture surface).
- **Liste des axes** à auditer dans l'ordre, courte (titre + section SSOT cible). Pas de findings encore — la boucle commence à l'Étape 2.

## Étape 2 — Boucle par axe

**Pour chaque axe** dans l'ordre établi à l'Étape 1, exécuter la séquence suivante. **Un axe à la fois.** Pas de parallélisation.

1. **Briefing du sub-agent** : section SSOT pertinente à charger + pattern précis à chercher dans tout le projet. Le briefing doit être ciblé, sans déborder vers d'autres axes. Exemple type :
   > *"Charge `philosophy §3` + `typescript.md §3`. Cherche dans `src/` toutes les classes qui ne contiennent que des méthodes statiques (`class X { static ... }`) sans état d'instance ni dépendance injectée. Pour chaque occurrence, rapporte fichier:ligne, le code concerné, et le verdict de conformité. Ne propose pas de correction. Findings factuels uniquement."*

2. **Délégation** via le mécanisme d'agent (sub-task / Explore agent selon contexte). Le sub-agent retourne ses findings sur cet axe **uniquement**.

3. **Plan ciblé à l'utilisateur** : N écarts sur cet axe, **citation SSOT verbatim** par écart, proposition de correction.

4. **Validation utilisateur** sur le plan de cet axe.

5. **Corrections par écart** (un à la fois dans l'axe, pas tous en parallèle) : fichier, diff représentatif, accord, application. Si un écart révèle un **arbitrage philosophique légitime** (default SSOT vs bascule contextuelle assumée), pose la question à l'utilisateur avant de proposer le refactor — capture la bascule dans `docs/conventions.md` du projet (cf. `philosophy §9`).

6. **Mise à jour de `docs/conventions.md` du projet** si bascule actée pour cet axe.

7. **Passage à l'axe suivant**.

**INVARIANT** — aucune modification sans accord explicite. Le sub-agent **ne modifie rien** non plus — il rapporte uniquement.

## Étape 3 — Validation finale globale

Une fois tous les axes traités, déléguer une **passe globale** à un sub-agent qui vérifie :

- Pas de régression introduite par les corrections successives (incohérence entre Lot 1 et Lot 2/3, type cassé, build qui ne passe plus).
- Cohérence d'ensemble (aucun axe applicable laissé de côté, observations hors-SSOT consolidées en mention factuelle finale).

Si findings → mini-boucle ciblée sur ces écarts. Si rien → **rapport final court** (3-6 lignes : axes traités, écarts corrigés, observations hors-SSOT restantes en mention factuelle, état de `docs/conventions.md`).

## Anti-patterns du skill

- ✗ Auto-modification sans accord (ni LLM principal, ni sub-agent).
- ✗ Audit global en bloc avant de découper en axes — perte d'attention garantie, écarts manqués.
- ✗ Liste d'axes pré-câblée dans le skill — la SSOT évolue, la checklist se dérive à chaque run.
- ✗ Traiter plusieurs écarts d'un axe en parallèle dans la phase de correction — un écart peut en invalider un autre.
- ✗ LLM principal qui Read le code applicatif en profondeur — c'est la responsabilité du sub-agent. Le principal reste sur SSOT + posture + orchestration.
- ✗ Proposer Next.js comme remplacement par préférence — Astro reste sauf signal réel (cf. `bootstrap-site-vitrine`).
- ✗ Inventer un seuil "trop d'islands" — demander à l'utilisateur si le seuil influence une décision (`philosophy §9`).
- ✗ Mécaniquement remplacer `.tsx` par `.astro` — certains composants interactifs **doivent** rester React (forms complexes, datepicker, toaster).
- ✗ Recommander Storybook/Histoire sur un site 5 pages — l'inspection au dev server suffit (filtre fondamental).
- ✗ Auditer le contenu rédactionnel (orthographe, ton) — hors scope, c'est du métier.

## Out of scope (renvoi)

- **Projet sans Astro** (CRA, Vite SPA pure) → demander la raison ; si signal absent, proposer rebootstrap via `/bootstrap-site-vitrine`.
- **Direction artistique / brand design** (palette identitaire, typo character, ambiance) → `/design-system` (à venir).
- **App interactive permanente** → `/audit-saas`.
- **Performance fine** (Core Web Vitals, Lighthouse score) → hors scope conventions ; signal utilisateur requis.
