# Rationale — choix de conception de code-conform

> Justifications des choix structurels du système. Pour les principes d'architecture eux-mêmes, voir `docs/architecture/00-philosophy.md`. Ce document explique **pourquoi** code-conform est conçu comme il est, et **quelles alternatives ont été écartées**.

---

## 1. Pourquoi code-conform existe

Le problème originel : un LLM assistant produit du code qui marche, mais qui **ne ressemble pas** à l'auteur du projet. Conséquences à 6 mois / 1 an / 3 ans :
- Maintenance par l'auteur devient coûteuse (style étranger, abstractions inattendues).
- Dette architecturale invisible s'accumule (patterns enterprise dans un projet solo).
- Perte progressive du contrôle du projet par son auteur.

Le LLM, par défaut, dérive vers la **moyenne de son training data** — code "enterprise propre" avec DDD, Value Objects, Repository, Factory, hiérarchies de classes. Pour un dev solo en cycle long, cette moyenne est **toxique** : trop de cérémonie, trop d'indirections, trop d'abstractions sans nécessité.

code-conform pose un **garde-fou** : un contexte documentaire stable, chargé par le LLM avant chaque génération, qui le ramène vers les conventions de l'auteur — pas vers sa moyenne.

---

## 2. Pourquoi une SSOT documentaire (et pas des prompts inline)

**Alternatives écartées** :

- *Prompts détaillés à chaque invocation* — répétition coûteuse, dérive à chaque session, pas de versioning.
- *`CLAUDE.md` global avec toutes les règles* — devient illisible au-delà de 200 lignes, dilution massive, pas de structuration thématique.
- *Templates de code partagés* — trop figés, ne capturent pas les arbitrages, deviennent obsolètes vite.

**Choix retenu** : SSOT documentaire structurée par préoccupation (philosophie, langage, UI…), chargée sélectivement par les skills selon le contexte projet.

**Avantages** :
- Versionnée Git, modifiable par itérations contrôlées.
- Structurée par thème, lisible en navigation par §.
- Réutilisable d'un projet à l'autre sans réécriture.
- Calibrable par audit externe (cf. §8).

---

## 3. Pourquoi des méta-docs (`docs/meta/`)

Le pattern : pour chaque doc structurant de la SSOT (`philosophy.md`, `<langage>.md`), un méta-doc miroir (`meta/00-philosophy.md`, `meta/language.md`) pose les **règles de production et de calibration** du doc cible.

**Pourquoi ce pattern** : la création d'un doc SSOT par un LLM est elle-même un processus à cadrer. Sans cadre, le LLM produit des docs verbeux, redondants, ou dogmatiques (le piège qu'on cherchait à éviter pour le code). Les méta-docs sont aux docs SSOT ce que les docs SSOT sont au code généré.

**Le piège miroir — risque reconnu et assumé** : un méta-doc écrit par un LLM qui a aussi écrit le doc qu'il audite va valider ce qu'il a voulu y mettre, pas ce qu'il aurait dû exiger. Le système est conçu en sachant que la calibration finale nécessite un **LLM externe sans contexte** pour casser le miroir. Ce pattern a été éprouvé plusieurs fois pendant la conception (cf. §8).

---

## 4. Pourquoi pas de docs framework (Next.md, Tauri.md, Vue.md…)

**Trois raisons** :

- **Obsolescence rapide** : Next 14 → 15 → 16 en 18 mois, Nuxt 3 → 4, Tauri 1 → 2. Une doc figée serait périmée avant d'être utile.
- **Coût** : N frameworks × M langages = matrice ingérable.
- **Dispersion** : 70% du contenu serait commun avec les docs langage existantes (slicing vertical, frontières, parsing) — déjà couvert.

**Choix retenu** : les choix de framework vivent dans les **skills**, qui sont :
- Plus faciles à mettre à jour qu'une doc.
- Opinionés par contexte métier (skill = un type de projet).
- Capable de proposer un default + override sur signal utilisateur.

Exemple : `/bootstrap-site-vitrine` impose Astro par défaut (build static, faible JS, MDX). Override Next si l'utilisateur signale un besoin SSR fort. Le raisonnement vit dans le skill, pas dans une doc à part.

---

## 5. Pourquoi l'installation est indépendante du repo source

**Tension** : besoin de stabilité de référence (les skills doivent pointer quelque part de fiable) ↔ besoin de mobilité du repo (déplacement, refactor, suppression).

**Alternatives écartées** :

- *Path fixe imposé au repo* — fragile : déplacement du repo casse les skills.
- *Symlink `~/.claude/code-conform` → repo* — résout la cohérence, mais si le repo est supprimé, le symlink pointe dans le vide.
- *Plugin Claude Code packagé (npm/git public)* — propre, mais nécessite packaging + publication, et le projet est volontairement personnel/privé.
- *Git submodule* — fonctionne mais complexifie la chaîne (submodule ajoute une indirection à comprendre).

**Choix retenu** : script `./install.sh` à la racine du repo qui **copie** docs et skills dans des emplacements stables :
- `docs/` → `~/.code-conform/docs/`
- `skills/` → `~/.claude/skills/`

**Conséquences** :
- Le repo peut bouger, être renommé, ou supprimé : l'installation continue de marcher.
- Update = relancer `./install.sh`. Manuel mais maîtrisé (pas de propagation magique).
- Pas de publication, pas de packaging, 100% local et privé.
- Migration vers un vrai plugin Claude Code reste facile si besoin un jour.

**Choix du path `~/.code-conform/` (vs `~/.claude/code-conform/`)** : indépendance de Claude. Si Claude Code est réinstallé ou nettoyé, l'installation code-conform n'est pas impactée.

---

## 6. Pourquoi des skills opinionés (vs interactifs systématiques)

**Tension** : posture interactive (philosophy §1, INVARIANT) ↔ utilisabilité concrète d'un skill.

Un skill 100% interactif qui demande tout à l'utilisateur au démarrage est lourd et reproduit le problème originel (utilisateur doit fournir tout le contexte chaque fois).

**Choix retenu** : skills **opinionés par défaut**, avec **challenge possible** sur signal utilisateur.

- Le skill propose un default fort (ex: Astro pour site vitrine) avec justification dans son `SKILL.md`.
- L'utilisateur peut challenger (*"je veux Next"*) — le LLM répond depuis les arguments du skill.
- Les questions interactives portent sur ce qui **ne peut pas être inféré** : métier, scope, conventions projet, choix contextuels non couverts par le default.

C'est cohérent avec la posture philosophy §8 : *inférer-et-annoncer si signal observable, demander si décision irréversible ou non inférable*.

---

## 7. Le profil "sustainable solo craft"

Posture revendiquée dans `philosophy §1`. La littérature dev oppose souvent deux profils :
- **MVP jetable** : ship fast, dette assumée, code à réécrire.
- **Système enterprise** : équipes, audit, rétrocompatibilité, conventions exhaustives.

Aucun des deux ne décrit la cible code-conform, qui est un **tiers-espace** :
- Dev solo, cycle de vie long (3+ ans envisagés).
- Maintenance par l'auteur lui-même.
- Pas de pression business (ni SLA, ni KPI commerciaux).
- Refactor libre toléré (pas de rétrocompatibilité forcée).
- Outillage soigné mais pas industriel.

**Conséquences architecturales** qui dérivent du profil (et qui transparaissent dans toutes les docs) :
- Tests émergent au besoin, pas par règle.
- Doc minimale (README + commentaires sur le *pourquoi*).
- Pas de couches préventives ("au cas où").
- Basiques sécurité/perf toujours, l'avancé sur signal.

Variante "ouvert à contribution" : adapte la surface visible (lisibilité critique, CONTRIBUTING) sans bascule enterprise.

---

## 8. Process éprouvé de production des docs

Le système a été conçu de manière itérative, avec un pattern récurrent qui s'est révélé efficace :

1. **Production** d'un doc par LLM (avec contexte).
2. **Audit par LLM externe sans contexte**, à qui on donne uniquement le doc et son méta (s'il existe). Le LLM externe applique la grille de calibration sans avoir les biais de production.
3. **Discussion** entre l'utilisateur, le LLM producteur, et le LLM auditeur. Les écarts identifiés sont triés (vrais trous vs faux positifs).
4. **Correction** ciblée des écarts confirmés.
5. **Re-audit** si refonte significative.

**Pourquoi ce pattern** : le LLM producteur a tendance à valider par familiarité ce qu'il a produit. Un LLM externe sans contexte voit ce qui **est**, pas ce qui **devait être**. C'est le seul mécanisme robuste contre le piège miroir.

**Cas notables** :
- Calibration de `philosophy.md` post-méta : 3 audits successifs (LLM neutre + LLM avec contexte + auto-audit).
- Production de `rust.md` from scratch : test du dispositif par production via LLM neutre lisant uniquement `philosophy` + `meta/language`.
- Détection et correction du piège miroir sur le méta initial.

---

## 9. Alternatives globales écartées

| Alternative | Raison de l'écart |
|---|---|
| Plugin Claude Code packagé public (npm) | Projet personnel, pas de volonté de partager publiquement |
| Doc unique monolithique (~800 lignes tout-en-un) | Dilution, contradictions internes, illusion de dogme — éprouvé négativement sur une version antérieure |
| Doc par framework (Next, Tauri, etc.) | Obsolescence rapide, coût de maintenance, dispersion |
| Symlink repo → `~/.claude/code-conform` | Cohérence mais pas de résilience à suppression du repo |
| Embedded BRIEFING.md à la racine | Devenait obsolète, polluait avec décisions anciennes, philosophy l'a remplacé |
| Slicing horizontal (`entities/`, `services/`, `repositories/`) | Anti-pattern central — un concept éparpillé sur 4 dossiers, navigation cognitive coûteuse |
| Class wrapper systématique pour primitives (Value Objects) | Bruit visuel sans safety nette — typage primitif nommé suffit |
| Singleton exporté global | Test impossible, effets de bord à l'import, risque de cycles |
| Couches préventives `application/` ou `infrastructure/` créées vides | Smell explicite — créer au premier besoin réel |
| Doc framework par framework | Obsolescence rapide, choix mieux portés par skills |

Ces alternatives sont écartées par **conception**, pas par hasard. Les réintroduire dans un projet utilisant code-conform signale soit un cas exceptionnel à documenter, soit une dérive à corriger.

---

## 10. Limites et zones non-traitées

Reconnaissance honnête des angles qui ne sont **pas** couverts par le système actuel :

- **Tests** : posture "émergent au besoin" actée, mais pas de doc dédié sur le pattern (où placer, comment nommer, quelle granularité). À écrire si le besoin émerge.
- **Performance / observabilité** : pas de doc. La posture solo craft dit "basiques toujours, avancé sur signal" — applicable mais peu cadré.
- **Sécurité applicative** : idem.
- **Monorepo** : pas de doc. Si un projet le justifie un jour.
- **Self-hosted multi-tech** (cas type macrodio : Go + Rust + web + Docker + DB) : trop hétérogène pour un bootstrap unique. Audit possible par sous-section.

Ces zones sont actées dans `BACKLOG.md` comme à explorer si le besoin se présente. Pas de création préventive (cohérent avec le filtre fondamental philosophy §4).

---

## 11. Pourquoi SKILL.md et docs SSOT restent des fichiers séparés (vs bundle)

**Question soulevée en itération** : si un skill instruit le chargement de ses docs SSOT dès l'invocation, pourquoi ne pas bundle SKILL.md + docs nécessaires en un fichier unique ? Le runtime semble identique après chargement.

**Modèle initial erroné (à corriger)** : "skill en mémoire forte, doc actionnable à la demande". Faux. Le découpage mémoire/actionnable se joue ailleurs.

**Modèle réel** — trois niveaux, pas deux :

1. **Frontmatter du skill** (`name`, `description`) — chargé au démarrage de session Claude Code dans la liste des skills disponibles. Toujours présent, faible coût. C'est la vraie "mémoire forte".
2. **Corps du SKILL.md** (~250 lignes typique) — chargé à l'invocation du skill. Procédural : étapes, questions, formats de sortie.
3. **Docs SSOT** — chargées sélectivement à l'invocation, selon ce que le SKILL.md instruit. Déclaratives : règles, invariants, idiomes.

Après chargement, niveaux 2 et 3 sont **également** en contexte. D'où la question légitime du bundle.

**Quatre raisons concrètes de garder séparé** :

1. **Anti-duplication (SSOT réelle)** — `philosophy.md` est chargée par 8 skills. Bundler la dupliquerait 8 fois. Une correction = 8 endroits à mettre à jour, garantie de dérive. La "S" de SSOT s'effondre.

2. **Chargement sélectif (théorique, à valider en usage)** — l'intention est que `/bootstrap-cloud` charge `typescript.md` *uniquement* si une couche TS est active, `rust.md` *uniquement* si Rust. Si le LLM suit effectivement ces instructions du SKILL.md, le bundle perdrait plusieurs milliers de tokens sur les skills polyglottes. Réserve honnête : on n'a pas encore mesuré ce comportement en sessions réelles. Le LLM pourrait charger tout par prudence, ou ignorer les conditions. À confirmer par les premiers tests.

3. **Réutilisabilité hors skill** — la SSOT est consultable depuis d'autres contextes (mention optionnelle dans `~/.claude/CLAUDE.md`, audit ad-hoc, futurs skills). Inliner = enfermer dans un contexte.

4. **Versioning indépendant** — la SSOT évolue (philosophy v0.2 → v0.3) sans toucher aux skills. Une amélioration de doc se propage à tous les consommateurs sans refactor en cascade.

**Ce que le bundle économiserait** : 2-3 `Read` calls par invocation (négligeable, pas de coût token, juste un peu de latence). **Ce qu'il perdrait** : tout ce qui précède.

**Conclusion (provisoire, à reconfirmer après usage réel)** : la séparation est justifiée principalement par anti-duplication et réutilisabilité. Le bénéfice "chargement sélectif" est l'argument le plus fort mais reste théorique tant qu'on n'a pas observé le comportement LLM en sessions réelles. Si en pratique le LLM charge systématiquement toute la SSOT à l'invocation d'un skill (sans suivre les conditions du SKILL.md), l'argument tombe — il restera anti-duplication et SSOT consultable, qui suffisent à eux seuls à justifier la séparation pour les skills polyglottes, mais pas forcément pour les skills mono-langage stables.

**À ré-arbitrer après les premières sessions de bootstrap/audit en usage réel.**

---

## 12. Dilution d'attention en long contexte — problème ouvert

**Constat empirique** : sur Claude (et LLMs longs-contextes en général), le contenu lu tôt dans une session voit son **attention effective décroître** à mesure que le contexte grossit. Un doc chargé à 0k tokens reste techniquement présent à 100k tokens, mais le LLM peut commencer à dériver vers ses biais de training plutôt que vers les conventions de la SSOT.

**Risque par skill** :

- **Bootstrap** (typique : 10-30 messages utilisateur, tool calls mixés) → contexte généralement gérable, SSOT lue récemment, faible risque.
- **Audit** (cartographie + grille A-J + citations fichiers + corrections par lots) → **risque élevé**. Sur un projet 50+ fichiers, on peut dépasser 100k tokens, et la grille audit a besoin que la SSOT garde du poids jusqu'au dernier lot.

**Leviers identifiés (non testés)** :

1. **Lazy loading** (palier "d'emblée" vs "sur déclencheur" dans SKILL.md) — réduit le volume initial. *Mais ne traite pas la dilution une fois chargé.*
2. **Re-citation verbatim** — forcer le LLM à citer les phrases-clés textuellement plutôt que mémoriser flou. *Coût marginal.*
3. **Re-Read aux checkpoints** — re-charger une section pertinente avant un lot critique. *Coût d'un Read, ramène le contenu en récent.*
4. **Découpage en sous-sessions** — sur audit lourd, cartographie en session 1, corrections lot par lot en session N. *Contexte frais à chaque fois, au prix de la fluidité utilisateur.*

**Limite méta importante (reconnaissance honnête)** : ces leviers vivent dans `SKILL.md`, qui est lui-même chargé en contexte. Une instruction *"re-Read cette section avant ce lot"* écrite dans SKILL.md peut **elle-même être diluée** en fin de session longue. Autrement dit, les mécanismes anti-dilution ne sont pas immunes au phénomène qu'ils visent.

Conséquence : la **discipline d'attention pourrait devoir venir de l'utilisateur** (rappels explicites, segmentation manuelle des audits) plutôt que du skill. Cette dépendance utilisateur **affaiblit l'autonomie** revendiquée du projet — c'est un coût à acter honnêtement, pas à camoufler.

**Décision** : on **ne refactor rien à l'aveugle**. Les premiers tests réels donneront le signal — à partir de quel volume la dilution mord, si les leviers en SKILL.md tiennent, si l'utilisateur peut/doit compenser. La décision sur la stratégie d'atténuation se prendra avec données, pas en spéculation.

**À traquer** : itération dédiée dans `BACKLOG.md`.

**Corollaire pour le `CLAUDE.md` global** : si l'utilisateur choisit d'y signaler la SSOT (cf. README "Lien optionnel"), le LLM la consulte *opportunistement* quand une décision pertinente survient. Pas de chargement systématique à chaque session — sinon coût en tokens prohibitif pour des sessions qui n'en ont pas besoin. C'est cohérent avec le principe de chargement sélectif déjà appliqué dans les skills.
