# BACKLOG — code-conform

État au 2026-05-15. Suit le travail post-relecture croisée v0.1 (LLM avec contexte + agent neutre + revue auteur).

---

## Corrections immédiates

- [x] **Artefact "namespace" dans le titre §2 du `typescript.md`** — renommé en `type + helpers + Zod SSOT` (2026-05-15).

---

## Questions ouvertes — à arbitrer après les premiers tests réels (ancrage 2026-05-20)

Bloc à traiter après usage réel des skills `/bootstrap-site-vitrine`, `/bootstrap-app-desktop`, `/bootstrap-cloud` et leurs audits. Cf. `RATIONALE.md §11` et `§12` pour le contexte complet.

- [ ] **Sélectivité du chargement SSOT** — actuellement les `SKILL.md` listent tous les docs à charger "d'emblée" (Pré-requis). Pour `bootstrap-cloud` notamment, le LLM ne peut pas savoir avant Q2-Q3 quelles couches/langages seront actifs. Refactor possible : palier "d'emblée" (philosophy) vs "sur déclencheur" (typescript/rust/ui selon cadrage). À décider après observation du comportement réel (le LLM suit-il les conditions, ou charge-t-il tout par prudence ?).

- [ ] **Dilution d'attention en long contexte** — risque réel sur les audits longs (cartographie + grille A-J + corrections par lots sur 50+ fichiers). Leviers possibles non testés : re-citation verbatim, re-Read aux checkpoints critiques, découpage en sous-sessions. **Reconnaissance honnête** : les instructions anti-dilution écrites dans SKILL.md peuvent elles-mêmes être diluées — la discipline pourrait devoir venir de l'utilisateur. À mesurer en usage réel.

- [ ] **Re-Read effectif** — le LLM respecte-t-il une instruction "re-Read cette section avant le lot N" dans SKILL.md ? À observer.

- [ ] **Comportement bundle vs séparé** — la question install-time bundling (cf. `RATIONALE.md §11`) sera à reconsidérer si la sélectivité ne se vérifie pas en pratique. Le 2-dir model est gardé par défaut, à ré-arbitrer après tests.

- [ ] **Choix du CMS dans `bootstrap-site-vitrine`** — Directus est actuellement imposé comme default sans le justifier ouvertement (cohérence avec `~/.claude/CLAUDE.md` global de l'auteur, mais arbitraire pour un lecteur externe). Trois options à arbitrer : (a) garder Directus default explicite avec justification, même statut que Tauri/Astro ; (b) en faire une question ouverte avec Directus suggestion ; (c) lister 2-3 CMS courants (Directus, Strapi, Sanity, Payload) avec critères de choix. Première remontée d'usage réel — 2026-05-20.

- [x] **Posture interactive non-opposable** (résolu 2026-05-20) — première friction d'usage réel : le LLM a identifié que des questions métier manquaient, l'a annoncé, **puis a continué quand même** en disant *"je scaffold, tu me diras après"*. Cause racine : l'INVARIANT §1 *"pose la question avant d'écrire"* laissait la marge de rationaliser. Correction posée : §1 renforcé en "interactivité **bloquante**" + anti-pattern explicite nommé dans §8 *"Ne pas faire"* + hard rule en début d'Étape 2 de chaque bootstrap skill. À ré-observer en prochaine session.

Méthode d'observation : noter au fil des sessions les **frictions concrètes** (ce que le LLM a chargé vs ce dont il avait besoin, où il a dérivé en fin de session, où l'utilisateur a dû rappeler à l'ordre). Pas de mesure synthétique en avance — signaux qualitatifs d'abord.

---

## Itérations v0.2 — toutes traitées (2026-05-15)

1. [x] **Seuils flous → méta-instruction** — *décision révisée* : pas de seuils chiffrés universels (substituerait un dogme à un autre). Posture : nouvelle `philosophy §9` qui instruit le LLM à reconnaître les seuils, les inférer du projet, demander à l'utilisateur, capturer la décision dans `docs/conventions.md` du projet. Renvois ajoutés dans `phil §4` et `ts §6, §7`.

2. [x] **Redondance `philosophy §5` ↔ `typescript §7`** — `phil §5` reste *concept et tensions abstraites*. `ts §8` (ex-§7) refondu en *idiomes TS purs* (code des patterns, sans répéter Default/Exception). Renvoi explicite à `philosophy §5` pour les critères de bascule.

3. [x] **"Interface Props parallèle au schéma Zod" réduit de 3 à 2 occurrences** — retiré du `ts §10 smells` (anciennement §9), conservé dans `phil §2` (concept) et `ts §2` (règle dure idiomatique).

4. [x] **Section Erreurs ajoutée** (`ts §6`, méta-instruction) — *décision révisée* : pas de tranche A/B/C/D imposée. La doc pose le vocabulaire (métier vs exceptionnelle), liste les 4 options TS courantes avec trade-offs, propose un default contextuel par type d'entry, instruit à demander à l'utilisateur et capturer le pattern décidé dans `docs/conventions.md` du projet.

5. [x] **Signal A→B visible** (`ts §4`) — bloc reformulé en encart explicite *"STOP et migrer dès qu'un de ces signaux apparaît"*, signal "wiring dupliqué" placé en #1, exemple de composition root minimal ajouté.

6. [x] **Mutation interdite domain dans store** (`ts §9`, ex-§8) — exemples ✗/✓ ajoutés. Règle élargie à tout consommateur du domain (hook, composable, server action, route), pas seulement aux stores.

---

## Jalon stratégique — Skills actionnables post-SSOT complète

**Posture validée** : la doc dense reste **SSOT documentaire** (référence consultable, source de vérité pour arbitrages). L'**outil actionnable** sera des skills dédiés, calibrés par contexte d'usage.

**Découplage** :
- La SSOT évolue par raffinement (v0.2, v0.3, …).
- Les skills consomment la SSOT et sont opinionés selon le métier visé.
- Les skills peuvent imposer des choix absolus (`pas de couche application/`, `pas de port`) parce que leur contexte est connu — ce que la SSOT ne peut pas se permettre.

**Slug = `<verbe>-<contexte-métier>`**, le métier étant le vrai différenciateur des arbitrages.

**Deux familles de verbes** :

- **`bootstrap`** — création from scratch d'un nouveau projet aux conventions code-conform.
- **`audit`** — revue d'un projet existant : diagnostic + propositions de corrections discutées avec validation utilisateur (mode interactif type B). Pas d'auto-modification.

Skills cibles initiaux :

- [x] `/bootstrap-site-vitrine` / `/audit-site-vitrine` — créés v0.1 (2026-05-16). Adossés à un projet de référence site vitrine (Astro 5 + React 19 islands + Tailwind v4 + i18n natif + Directus + Biome). Bootstrap 254 lignes, audit 176 lignes. Default Astro, override Next sur signal réel (SSR partout, Server Components) — bascule vers `/bootstrap-saas` dans ce cas. Cadrage interactif (métier, i18n, CMS vs statique, adapter). Non testé en usage réel.
- [x] `/bootstrap-app-desktop` / `/audit-app-desktop` — créés v0.1 (2026-05-20). Tauri 2 default (Vite + React 19 + Tailwind v4 + Biome). Adossés à un projet de référence UI tool Tauri React. Bootstrap couvre Q1-Q6 (métier, framework UI, persistance store/SQLite/FS, IPC + tauri-specta, fenêtrage, distribution). Audit met sécurité (allowlist, CSP) en lot prioritaire. Non testé en usage réel.
- [x] `/bootstrap-cloud` / `/audit-cloud` — **ébauche v0.1** (2026-05-20). Pensé comme système monorepo (pas somme de skills). Cadrage Q1-Q7 (métier, couches actives, stack par couche avec contraintes croisées, contrats, tooling monorepo, auth, déploiement). Audit met l'accent sur incohérences **inter-couches** (contrat dupliqué, auth divergente, types non synchronisés). Refs : projet cloud multi-tech (Rust+Go+web+Docker), projet client Tauri d'un serveur compagnon, projet SPA Vite (en dev). Skills nominalement utilisables mais **bloqués sur SSOT manquantes** (voir Roadmap ci-dessous) — l'audit reste partiel pour PHP/Go/Python tant que les `<langage>.md` ne sont pas posées.
- [ ] `/bootstrap-saas` / `/audit-saas` — Next App Router ou Nuxt selon stack JS/Vue préférée, à demander à l'utilisateur.
- [ ] `/bootstrap-cli` / `/audit-cli` — langage selon (TS, Rust, Go), pas de framework lourd.
- [x] `/init-design-system` — créé v0.1 (2026-05-16). `skills/init-design-system/SKILL.md`, 256 lignes. Bootstrap uniquement. Cadre interactif sur posture tokens A/B, framework détecté, niveaux atomic optionnels. Génère structure minimale (atoms/molecules/organisms vides + `Button` de référence en `Record<Variant>`), `@theme` Tailwind v4, helper `cn`, capture décisions dans `docs/conventions.md` du projet. Non testé en usage réel — itérer à la première session.
- [x] `/audit-design-system` — créé v0.1 (2026-05-16). `skills/audit-design-system/SKILL.md`, 172 lignes. Pendant audit de init. Grille d'audit en 8 axes (A setup → H smells), rapport structuré, correction interactive par lots avec validation utilisateur. INVARIANT : aucune modification sans accord explicite. Non testé en usage réel.

**Topologie installation** (validée) :
- Repo de travail : `~/dev/perso/code-conform/` (ou ailleurs selon préférence).
- Installation via `./install.sh` à la racine (créé 2026-05-20, défauts inversés 2026-05-20) :
  - **Default = copie** (résilient — repo source peut bouger/disparaître sans casser l'install).
  - `--force` pour update propre (écrase sans backup).
  - `--link` pour mode dev (symlinks, édits du repo suivis live).
  - `--uninstall` pour retirer.
  - Sentinelle `.installed-by-code-conform` posée dans chaque dossier installé → reconnaît ce qui est à nous lors d'un re-run (overwrite propre) ; les dossiers tiers sont sauvegardés en `.bak.<ts>`.
  - `docs/` → `~/.code-conform/docs/`.
  - `skills/<name>/` → `~/.claude/skills/<name>/` (un dossier par skill).
- Les skills réfèrent à `~/.code-conform/docs/architecture/*` (path canonique, indépendant du repo source).
- **Avantages** : repo peut bouger / disparaître sans casser l'installation. Update = re-lancer `./install.sh`.
- Pas de publication, pas de packaging plugin, 100% local et privé.

**Décisions de design des skills** (validées) :
- Skills **opinionés** sur le framework par défaut, avec **challenge possible** par l'utilisateur sur signal réel.
- **Pas de docs framework par framework** (next.md, tauri.md, etc.) — obsolescence rapide, coût de maintenance. Les choix vivent dans les skills, plus faciles à mettre à jour.
- Skills posent leur opinion + justification dans `SKILL.md`. Utilisateur peut challenger, le LLM répond depuis les arguments du skill.

**Pré-requis** : SSOT consolidée sur tous les langages/contextes ciblés (cf. roadmap ci-dessous) avant de créer les skills, sinon ils consomment du vide.

**Cas en backlog** (à explorer plus tard, hors V1 skills) :
- [ ] `/bootstrap-shared-design-system` — design system partagé entre projets (cas typique : lib DS interne consommée par plusieurs apps) : repo référence Histoire/Storybook + injection dans projets consommateurs.
- [ ] `/audit-self-hosted` (envisageable) — projet multi-tech client/serveur (Go + Rust + web + Docker + DB). Trop hétérogène pour bootstrap, mais auditable contre les conventions par sous-section.
- [ ] `/bootstrap-ecommerce` — selon besoin (Next + Stripe, custom, etc.). Pas prioritaire en V1.

---

## Roadmap SSOT — extensions à venir

- [x] `docs/architecture/rust.md` — créé et calibré v1.0 (2026-05-16)
- [x] `docs/architecture/ui.md` — créé v1.0 (2026-05-16). Doc unique : Atomic Design + conventions composants + tokens + design system. Cross-framework (React/Vue/Svelte). Conventions ancrées sur deux projets de référence (un projet Next brand fort monothème, un projet UI tool Tauri/Vite avec tokens sémantiques). Postures tokens A/B explicites, `Record<Variant>` par défaut.
- [x] `docs/meta/ui.md` — **abandonné** (2026-05-16). Pas de méta dédié : `docs/meta/language.md` a joué ce rôle pour la production de `ui.md` (dérivée fonctionnelle du squelette langage avec adaptations documentées dans le préambule du doc).
- [ ] `docs/architecture/monorepo.md` — si besoin réel émerge (workspaces pnpm/Bun, partage de packages domain)
- [ ] **`docs/architecture/go.md`** — débloquerait `/audit-cloud` sur couche serveur Go. Priorité haute.
- [ ] **`docs/architecture/contracts.md`** (méta) — OpenAPI vs proto vs package TS partagé, conventions codegen. Débloquerait l'axe F de `/audit-cloud` qui est le plus critique (INVARIANT philosophy §5).
- [ ] `docs/architecture/php.md` — si projet PHP cible dans la roadmap selfhost.
- [ ] `docs/architecture/python.md` — si projet Python cible.
- [ ] `docs/architecture/database.md` (éventuel) — conventions migrations + naming SQL + arbitrage PG/SQLite par contexte. Optionnel si les langages serveurs couvrent déjà la partie persistance.
- [x] `BRIEFING.md` supprimé (2026-05-16) — philosophy devenue SSOT racine autosuffisante
- [x] **`philosophy §10` ajouté** (2026-05-20) — arbitrage langage par runtime. INVARIANT : typage statique strict obligatoire à runtime donné, JS pur banni sauf signal. Tableau runtime → langage default + bascules autorisées. Comble le trou "comment décider Nuxt=TS et pas JS" qui vivait jusqu'ici uniquement dans `~/.claude/CLAUDE.md` global (préférence personnelle, pas SSOT).

---

## Harmonisation finale (à faire en toute fin de cycle)

- [x] **Réconcilier `~/.claude/CLAUDE.md` global avec code-conform** (2026-05-16) — stratégie *résumé aligné + renvoi*. CLAUDE.md (56 lignes) ouvre par un renvoi explicite à `~/.code-conform/docs/` (philosophy + langage + ui). Sections Architecture / Code Quality réécrites en cohérence : trois formes citoyennes (classe = acteur uniquement), `Record<Variant>` pour variants, seuils chiffrés (`< 20 lignes`, `< 200 lignes`) retirés au profit d'indicateurs, DRY reformulé en "factoriser sur duplication réelle (≥2 occurrences)". Préférences techno + workflow + commit interdictions conservés.

---

## Notes de méthode

- Ne pas refondre la SSOT avant la prochaine session d'usage réel — itérer en l'utilisant produira des signaux plus fiables que des relectures à blanc.
- Quand un LLM (Claude Code en pratique) commet une bourde sur l'un des 6 points v0.2, marquer ici la bourde + le contexte → ça oriente la priorité de l'itération.
- Le verdict "pas prêt sans itération" de l'agent neutre est trop sévère : la doc est utilisable à 85%, le manquant émerge mieux à l'usage.
