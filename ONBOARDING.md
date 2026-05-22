# ONBOARDING — code-conform

> Lecture prioritaire pour toute nouvelle instance LLM (et utilisateur humain qui revient après une pause). À maintenir à chaque pause significative. État à `<date du commit>`.

## 1. Le projet en une minute

**`code-conform`** = SSOT documentaire (`docs/`) + skills opérationnels Claude Code (`bootstrap-*`, `audit-*`) pour qu'un LLM **conforme** le code aux conventions de l'auteur — pas à sa moyenne d'entraînement.

**Profil cible** : *sustainable solo craft* (dev solo, cycle long 3+ ans, refactor libre toléré, ni MVP jetable ni enterprise).

**Idée centrale** : sur un cycle long, le LLM dérive vers la "moyenne du training set" et coûte cher en maintenance. La SSOT est consultée **au moment d'écrire** (hard rule INVARIANT dans chaque skill), pas en lecture inspirationnelle au démarrage.

## 2. Posture (INVARIANTS)

- **`philosophy §1` bloquant** : interactivité obligatoire — demander avant deviner sur les choix non inférables.
- **`philosophy §8` phasage strict** : métier → technique. Pas de bundling.
- **`philosophy §9`** : les seuils contextuels se capturent dans `docs/conventions.md` du projet, pas dans la SSOT.
- **`philosophy §11`** : lockfile commité, caret default, CI frozen-install, upgrades volontaires (latest stable).
- **`philosophy §12`** : consultation de la doc officielle (Context7 MCP / WebFetch) avant d'écrire — anti-training-data drift.
- **Audit honnête (`philosophy §8`)** : si conforme, dire "conforme". Ne pas forcer la trouvaille.
- **Pas catégorique sur arbitrages non couverts par SSOT** (cf. `memory/user_methode_validation_llm.md` — l'utilisateur croise plusieurs Claudes).

## 3. Ordre de lecture obligatoire

1. **Ce fichier** (`ONBOARDING.md`).
2. **`README.md`** — vue d'ensemble humaine.
3. **`BACKLOG.md`** — état détaillé. **En particulier le bloc *"État de calibration des skills"* en tête** — c'est l'état réel des skills à jour.
4. **`RATIONALE.md`** §9bis, §9ter, §11, §12 — principes de design méta acquis.
5. **`~/.claude/projects/.../memory/MEMORY.md`** — feedbacks utilisateur persistants (audit ≠ bootstrap, namespace TS, validation croisée LLM, UI/domain).
6. **SSOT (`docs/`)** : consultable au moment d'écrire, **pas en lecture inspirationnelle**. C'est une hard rule INVARIANT chargée par chaque skill.

## 4. État courant des skills

| Skill | Version | État |
|---|---|---|
| `bootstrap-site-vitrine` | v0.2 | Calibré 3 sessions réelles (restaurant, wedding, agence SEO). Stable. |
| `audit-site-vitrine` | v0.4 | Calibré 3 sessions agay (re-audit fresh confirmé utile, 5 trous identifiés en passage 3). Levier A (re-dérivation indépendante checklist) ajouté. |
| `bootstrap-app-desktop` | v0.2 | Alignement interactif porté préventivement. Non testé condition réelle. |
| `audit-app-desktop` | v0.4 | Refonte alignée audit-site-vitrine v0.4. Spécificité Tauri (sécurité allowlist/CSP = Lot 1 fondations). Non testé condition réelle. |
| `bootstrap-cloud` | v0.1 ébauche | Bloqué SSOT manquantes (`go.md`, `contracts.md`). |
| `audit-cloud` | v0.1 ébauche | Idem. |

## 5. Frictions chaudes (à traquer au prochain audit/usage)

- **Convergence du re-audit fresh** — il a fallu 3 passages pour révéler tous les écarts agay. v0.4 doit réduire à 2 (levier A). À mesurer.
- **Tenue du levier A en pratique** — le sub-agent fresh re-dérive-t-il une checklist différente capturant les axes oubliés ? À observer.
- **Comportement spot-check** — le LLM principal respecte-t-il la règle "≤4 fichiers + déclaration explicite", ou déborde-t-il ?
- **Calibration `audit-app-desktop`** — non testé en condition réelle. À éprouver sur un vrai projet Tauri quand signal.

## 6. Frictions froides (à explorer si signal)

- **Contraction SSOT** — 2090+ lignes, à surveiller si dilution attribuable mesurée en usage réel. Critère de déclenchement explicite dans BACKLOG.
- **`/audit-applicatif`** — skill séparé hors SSOT (sécurité applicative, RGPD, perfs, SEO structuré). À créer **uniquement** si la section *Hors-SSOT* des `audit-*` se révèle insuffisante en pratique.
- **`/bootstrap-saas`, `/bootstrap-ecommerce`** — meta-framework à cadrer au moment de l'écriture, pas figer.
- **`/design-system`** — skill transform UI + brand. SSOT compagnon `brand-design.md` à créer.

## 7. Méthode d'itération

1. Édit local dans le repo.
2. `git add .` + `git commit -m "<message>"` + `git push`.
3. `./install.sh` — copie `docs/` → `~/.code-conform/docs/` et `skills/<name>/` → `~/.claude/skills/<name>/`. Sentinelle + prune orphelins.
4. Effectif à la **prochaine session Claude Code** (les skills sont chargés au démarrage de session).

**Cycle de calibration d'un skill** :
1. Lancer le skill sur un projet réel (vierge pour bootstrap, existant pour audit).
2. Noter les frictions **sans intervenir** (observation pure).
3. Corriger le skill — édit + commit + push + `./install.sh`.
4. **Re-tester dans une session neuve** (jamais auto-validation par la session qui a appliqué).
5. Acter en BACKLOG.

**Pour les audits critiques** : 2 re-audits fresh successifs jusqu'à convergence (0 nouvelle trouvaille). 1 ne suffit pas — confirmé empiriquement sur agay.

## 8. Posture personnelle utilisateur (memory snapshot)

- **Validation croisée LLM** : sur les arbitrages importants non couverts par SSOT, l'utilisateur croise plusieurs Claudes (avec/sans contexte). Ne pas être trop catégorique.
- **Audit ≠ bootstrap** pour l'interactivité : audit = mesure de conformité, pas découverte métier. Pas de phase d'écoute large.
- **Namespace TS** via `import * as Concept` = forme native conforme `philosophy §3`, distinct d'une classe statique.
- **UI strictement séparée du domain** : tous les composants UI dans `components/<atoms|molecules|organisms>/`, `domain/<concept>/` sans JSX (types, schémas, helpers, repository, api, stores, hooks métier uniquement).
- **Modules de domaine** : verbe seul exporté + `import * as Concept` au consommateur. Convention verbes : `find*` → `T | null`, `get*` → `T` (throw), `list*` → `T[]`, `create/update/delete` → mutations throw jamais nullable.
- **Réponses concises**, **français**, **pas de mention IA dans les commits** (ni "Co-Authored-By Claude" ni emoji robot).

## 9. Préférences techniques globales

- **Package manager** : Bun ou pnpm — jamais npm/yarn.
- **Langage** : TypeScript strict default. Rust pour `src-tauri/` et binaires natifs perf-critiques.
- **Validation** : Zod SSOT. Exception : Elysia Treaty.
- **API client** : Directus SDK default. Exception : Elysia (Eden Treaty).
- **Styling** : Tailwind v4 CSS-first via `@theme`. Pas de `tailwind.config.js`.
- **Linter** : Biome default. ESLint+Prettier uniquement sur signal Vue/Nuxt.

## 10. Quand demander vs deviner

- **SSOT couvre** → applique avec citation verbatim de la phrase-clé.
- **Seuil contextuel non couvert** → demander, acter dans `docs/conventions.md` du projet.
- **Arbitrage philosophique légitime** (default vs bascule contextuelle assumée) → demander avant de proposer le refactor.
- **Hors scope du skill invoqué** → annoncer honnêtement *"ce skill ne couvre pas ton besoin"* + nommer le skill dédié si existant + sinon refuser. **Pas de *"je m'adapte"*, pas de *"je débrouille"*.**

## 11. Pièges connus à éviter

- ✗ Liste d'axes pré-câblée dans les skills `audit-*` — la SSOT évolue, la checklist se dérive à chaque run depuis la SSOT chargée.
- ✗ LLM principal qui Read le code applicatif en profondeur dans `audit-*` — c'est la responsabilité du sub-agent. Spot-check toléré uniquement si ≤4 fichiers et déclaration explicite.
- ✗ Auto-validation passe finale dans la session qui a appliqué — biais structurel. La passe finale doit être faite par un sub-agent fresh + complétée par un re-audit fresh dans session neuve.
- ✗ Forcer la trouvaille pour "remplir" un axe d'audit — si conforme, dire conforme.
- ✗ Filtrer silencieusement un finding du sub-agent — miroir de l'anti-remplissage.
- ✗ Mélanger écarts SSOT et observations hors-SSOT au même niveau dans un rapport d'audit.
- ✗ Composants `.tsx`/`.vue`/`.svelte`/`.astro` dans `src/domain/<concept>/` — anti-pattern depuis 2026-05-22 (cf. `atomic-design.md §10`).
- ✗ Coder de mémoire contre un framework/lib — vérifier la doc officielle de la version cible (Context7 MCP / WebFetch).
