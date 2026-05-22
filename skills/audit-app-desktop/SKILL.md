---
name: audit-app-desktop
description: Audit d'une app desktop Tauri (ou Electron) aux conventions code-conform — sécurité allowlist/CSP comme convention de moindre privilège, IPC typé, atomic, persistance locale. Boucle par axe avec sub-agent ciblé. Mode audit philosophy §8 — pas d'auto-modification.
---

# /audit-app-desktop

Skill **audit** : revue d'une app desktop existante. Tauri prioritaire (Electron toléré sur signal acté). **N'auto-modifie rien sans accord explicite.**

Si l'app communique avec un serveur compagnon développé en parallèle → renvoi `/audit-cloud` (audit système complet).
Si le projet est vide → `/bootstrap-app-desktop`.
Si c'est un SPA web sans `src-tauri/` → `/audit-site-vitrine` ou `/audit-saas` selon profil.

## Posture (lire avant tout)

L'audit mesure la **conformité aux conventions code-conform** — pas tous les bugs ou imperfections détectables. La distinction est structurante :

- **Dans la SSOT** (philosophy, atomic-design, typescript, rust) → écart au référentiel, organisé en **lots ordonnés par criticité architecturale** (recadrage fondations → refactors transverses → détails ponctuels). **Spécificité app desktop** : la sécurité Tauri (allowlist au minimum nécessaire, CSP active, scopes FS bornés) est une **convention code-conform de moindre privilège** (cf. `bootstrap-app-desktop`) — elle vit en **Lot 1 fondations**, pas en hors-SSOT.
- **Hors SSOT** (cold start performance, code signing publique, polish cross-platform, bugs ponctuels métier) → observations signalées dans une section dédiée, **jamais mélangées aux lots SSOT**.

**Pattern de travail (INVARIANT)** : l'audit ne se fait **pas en une passe globale**. Le LLM principal n'inspecte **pas** le projet directement en profondeur — il dérive sa propre checklist d'axes depuis la SSOT chargée, puis pour chaque axe **délègue le scan à un sub-agent ciblé**. Cela évite la dilution d'attention en long contexte (cf. `RATIONALE §12`) qui fait manquer des écarts en audit-en-bloc.

**Anti-pattern signature à éviter** : produire un rapport "audit qualité de code générique" avec des références SSOT plaquées dessus (citations `philosophy §3` sans phrase-clé, écarts SSOT et bugs ponctuels au même niveau, plan d'attaque absent). C'est un audit *amélioré*, pas un audit *code-conform*.

**Audit honnête (anti-remplissage)** — cf. `philosophy §8` : si un axe est conforme, **dis-le explicitement** ("conforme") et passe au suivant. Ne force pas la trouvaille pour "remplir" l'axe. Un axe sans écart est un signal positif, pas un audit raté. Cette consigne s'applique au LLM principal **et** doit être passée explicitement au briefing de chaque sub-agent.

## Pré-requis — SSOT à charger

- `~/.code-conform/docs/00-philosophy.md` — invariants, mode audit (§8), filtre fondamental.
- `~/.code-conform/docs/languages/typescript.md` — strict TS, frontière, conventions naming, modules domaine.
- `~/.code-conform/docs/languages/rust.md` — côté `src-tauri/`.
- `~/.code-conform/docs/design/atomic-design.md` — atomic, tokens structure, a11y, smells. Couvre l'archi UI ; pas la dimension design pure (brand, ambiance).
- `docs/conventions.md` du projet si présent.

## Hard rule — usage de la SSOT (INVARIANT)

Quand tu juges un écart, tu **dois** consulter la section SSOT pertinente **au moment** où tu formules l'écart — pas en lecture inspirationnelle au démarrage. Charger les docs en début de session ≠ les avoir en mémoire au moment du rapport (dilution d'attention en long contexte, cf. `RATIONALE §12`). Le risque est **plus élevé** ici qu'en bootstrap : contexte multi-axes pluri-passes, dérive vers training data ("audit générique de qualité de code") au lieu de la SSOT.

Concrètement :

- **`Read` la section ciblée juste avant** de formuler l'écart (ex: `philosophy §3` pour une classe-acteur vs donnée pure, `atomic-design.md §13` pour un smell DS, `philosophy §5` pour la frontière IPC, `rust.md` pour les commands Rust).
- **Cite la phrase-clé ou le pattern exact** dans le rapport ("`philosophy §3` : *la classe est réservée à l'acteur avec état/deps*"), pas une reformulation de mémoire.

Anti-patterns :

- ✗ *"Je connais le pattern, j'applique"* → dérive vers audit générique.
- ✗ Citer un numéro de section sans la phrase-clé (`philosophy §3` seul = référence floue, pas opposable).
- ✗ Mélanger écarts SSOT et observations hors SSOT au même niveau → effet "massue indistincte" sur l'utilisateur.

## Étape 1 — Préparation et checklist dérivée

**Lecture surface uniquement** : `package.json`, `src-tauri/Cargo.toml`, `src-tauri/tauri.conf.json`, structure top-level (`src/`, `src-tauri/src/`), `docs/conventions.md` du projet. **Pas de Read en profondeur** du code applicatif — c'est le sub-agent qui s'en chargera, axe par axe.

À partir de la SSOT chargée et du projet observé en surface, **dérive ta propre checklist d'axes à auditer**. Ne suis pas une liste pré-câblée — elle dérive de la SSOT effective et évolue avec elle.

**Critère d'ordonnancement** :

> Du plus structurant au plus ponctuel. Un écart sur l'axe N+1 ne doit pas devenir caduque si l'axe N est corrigé d'abord.
>
> - **Fondations** : tout ce qui touche au squelette du projet (slicing, formes citoyennes, frontières IPC, **sécurité Tauri allowlist/CSP**, structure atomic). Un refactor ici déplace tout le reste.
> - **Transverses** : ce qui apparaît à N endroits cohérents (tokens, conventions de variants, namespace au point d'import, idiomes Rust dans `src-tauri/`, versioning, persistance locale). Mécanique après les fondations.
> - **Détails** : feuilles isolées (a11y, conventions HTML, raccourcis OS, petits bugs). Indépendants entre eux.
>
> Identifie les axes en parcourant la SSOT chargée — **INVARIANTS d'abord** (sécurité Tauri, frontière Zod IPC, posture interactive), règles dures ensuite, conventions au-delà. Couvre tout ce qui est applicable au type de projet audité, rien d'inventé hors SSOT.

Annonce à l'utilisateur :

- **Carte rapide** en 5-8 lignes (Tauri version, frontend stack, persistance, fenêtrage, plateformes cibles — depuis la lecture surface).
- **Liste des axes** à auditer dans l'ordre, courte (titre + section SSOT cible). Pas de findings encore — la boucle commence à l'Étape 2.

## Étape 2 — Boucle par axe

**Pour chaque axe** dans l'ordre établi à l'Étape 1, exécuter la séquence suivante. **Un axe à la fois.** Pas de parallélisation.

1. **Briefing du sub-agent** : section SSOT pertinente à charger + pattern précis à chercher dans tout le projet. Le briefing doit être ciblé, sans déborder vers d'autres axes, et inclure la posture d'audit honnête. Exemple type :
   > *"Charge `philosophy §5` INVARIANT + le wrapper IPC dans `bootstrap-app-desktop` SKILL.md §3.5. Cherche dans `src/` toutes les invocations `invoke(...)` qui ne passent pas par le wrapper centralisé `src/lib/tauri.ts` ou qui castent le retour via `as T` au lieu de parser via Zod / `tauri-specta`. Pour chaque occurrence, rapporte fichier:ligne, le code concerné, et le verdict de conformité. **Si aucun écart : retourne 'conforme' explicitement. Ne force pas la trouvaille pour 'remplir' la mission.** Ne propose pas de correction. Findings factuels uniquement."*

2. **Délégation** via le mécanisme d'agent (sub-task / Explore agent selon contexte). Le sub-agent retourne ses findings sur cet axe **uniquement**.

3. **Reporting honnête au plan ciblé** : remonter **intégralement** les findings du sub-agent — y compris points borderline, contradictions avec `conventions.md`, observations à arbitrer. **Pas de filtrage silencieux pour "clore proprement" l'axe.** Si tu mets un point de côté (à traiter à un autre axe par exemple), déclare-le explicitement avec raison. Miroir de l'anti-remplissage : ne force pas la trouvaille **et** ne masque pas une trouvaille du sub-agent.

4. **Plan ciblé à l'utilisateur** : N écarts sur cet axe, **citation SSOT verbatim** par écart, proposition de correction.

5. **Validation utilisateur** sur le plan de cet axe.

6. **Corrections par écart** (un à la fois dans l'axe, pas tous en parallèle) : fichier, diff représentatif, accord, application. Si un écart révèle un **arbitrage philosophique légitime** (default SSOT vs bascule contextuelle assumée), pose la question à l'utilisateur avant de proposer le refactor — capture la bascule dans `docs/conventions.md` du projet (cf. `philosophy §9`).

7. **Mise à jour de `docs/conventions.md` du projet** si bascule actée pour cet axe.

8. **Passage à l'axe suivant**.

**INVARIANT** — aucune modification sans accord explicite. Le sub-agent **ne modifie rien** non plus — il rapporte uniquement.

## Étape 3 — Validation finale globale

Deux passes à déléguer à **des sub-agents fresh distincts** (contexte zéro chacun) — l'objectif est d'attaquer l'angle mort de la session principale par un regard indépendant. Le coût supplémentaire (2 sub-agents) est marginal vs le risque de trous structurels manqués.

**Passe 1 — Re-dérivation indépendante de la checklist** : un sub-agent fresh charge la SSOT (philosophy + typescript + rust + atomic-design + `docs/conventions.md` du projet) et **dérive sa propre checklist d'axes applicables** au projet, **sans connaître ceux que la session a traités**. Il retourne sa liste. Tu compares ensuite à la liste des axes traités par la session. Si écart → relance la boucle Étape 2 sur les axes manqués. C'est le **levier anti-checklist-incomplète** : la dérivation d'axes n'est pas reproductible entre sessions, un second regard indépendant capture les axes oubliés.

**Passe 2 — Régression + vérification point par point** : un autre sub-agent fresh vérifie :

- **Point par point que chaque correction appliquée est effectivement présente** dans le code (pas juste l'absence de régression — la passe finale en session courante est biaisée). Sortie type matrice "N/N appliqués par axe".
- Aucune régression introduite par les corrections successives : `pnpm tsc --noEmit`, `pnpm lint`, `cargo check` côté `src-tauri/`, build du framework, aucun import cassé, aucune référence aux anciens chemins.
- Cohérence d'ensemble (observations hors-SSOT consolidées en mention factuelle finale).

Si findings → mini-boucle ciblée. Si rien → **rapport final court** (3-6 lignes : axes traités, corrections appliquées, observations hors-SSOT restantes, état de `docs/conventions.md`).

**Reconnaissance honnête** : ces deux passes réduisent le risque de trous mais ne le suppriment pas. La méthode complète reste *audit → corrections → re-audit fresh dans une session neuve* — particulièrement pour les projets critiques. 2 re-audits fresh successifs jusqu'à convergence (0 nouvelle trouvaille) est la garantie réelle.

## Anti-patterns du skill

- ✗ Auto-modification sans accord (ni LLM principal, ni sub-agent).
- ✗ Audit global en bloc avant de découper en axes — perte d'attention garantie, écarts manqués.
- ✗ Liste d'axes pré-câblée dans le skill — la SSOT évolue, la checklist se dérive à chaque run.
- ✗ Traiter plusieurs écarts d'un axe en parallèle dans la phase de correction — un écart peut en invalider un autre.
- ✗ LLM principal qui Read le code applicatif en profondeur — c'est la responsabilité du sub-agent. Le principal reste sur SSOT + posture + orchestration. **Spot-check ciblé toléré** uniquement si scope ≤4 fichiers, déclaration explicite de transgression (*"je vérifie un point que le sub-agent a écarté trop vite"*), et raison concrète (sous-livraison sub-agent, faux positif suspect à confirmer). Sinon → redéléguer un sub-agent ciblé.
- ✗ **Forcer la trouvaille pour "remplir" un axe** — si l'axe est conforme, dire "conforme" explicitement et passer. Biais LLM "il faut produire des findings sinon j'ai raté ma mission" — exactement ce qu'il faut résister (cf. `philosophy §8`).
- ✗ **Filtrer silencieusement un finding du sub-agent** pour "clore proprement" l'axe. Miroir de l'anti-remplissage : ne pas forcer la trouvaille **et** ne pas masquer une trouvaille. Remonter intégralement, déclarer explicitement ce qui est mis de côté avec raison.
- ✗ Recommander la migration Electron→Tauri **sans signal** — si Electron est documenté et choisi dans `conventions.md`, respecter.
- ✗ Recommander un router en mono-window "au cas où" — overhead inutile.
- ✗ Demander de "tout typer" l'IPC manuellement sans considérer `tauri-specta` (codegen depuis Rust).
- ✗ Auditer la business logic métier au-delà des frontières IPC et DS.
- ✗ Inventer un seuil "trop de commands" ou "trop de fenêtres" — `philosophy §9`, demander à l'utilisateur si le seuil influence une décision.
- ✗ Sortir la sécurité Tauri (allowlist/CSP) en *hors-SSOT* — c'est une convention de moindre privilège acquise par `bootstrap-app-desktop`, donc Lot 1 fondations.

## Out of scope (renvoi)

- **Site vitrine éditorial** (présentation, restaurant, association — peu de JS, contenu majoritairement statique) → `/audit-site-vitrine`.
- **App + serveur compagnon** développé en parallèle (le desktop n'est qu'une couche d'un système plus large) → `/audit-cloud`.
- **Web SPA pure sans `src-tauri/`** → `/audit-site-vitrine` ou `/audit-saas` selon profil.
- **Direction artistique / brand design** (palette identitaire, typo character, ambiance) → `/design-system` (à venir).
- **CI/CD release pipeline** → hors scope conventions, sujet propre.
- **Performance binaire / cold start** → hors scope, signal utilisateur requis.
- **Code signing macOS/Windows distribution publique** → mention factuelle hors-SSOT, à arbitrer indépendamment.
