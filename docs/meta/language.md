# Méta-langage — règles de production et de calibration des docs `<langage>.md`

> Ce document est le **miroir** des docs `docs/architecture/<langage>.md` (existants ou à créer). Il ne t'apprend pas à écrire du code dans un langage — il te dit **comment doit être écrit un doc langage**, et te donne la grille pour le **calibrer** ou le **produire from scratch**.

---

## 1. Préambule

**Vocation** : ce méta-doc sert deux moments distincts, avec le **même contenu** :
- **Production from scratch** d'un doc langage qui n'existe pas encore (Rust, Go, Elixir…). Le rédacteur (LLM) consulte ce méta avant de cartographier le langage cible et de poser le squelette.
- **Calibration** d'un doc langage existant (ex: `typescript.md`). L'auditeur applique la grille (§9), repère les écarts, corrige.

**Public** : LLM (toi) qui édite, audite, ou crée un doc langage. Pas un humain qui apprend l'architecture ou un langage.

**Périmètre** : ce doc ne couvre pas le doc philosophique (`docs/architecture/00-philosophy.md`) — voir `docs/meta/00-philosophy.md`. Le **contrat de densité, l'effet dilution et les smells de doc** sont volontairement **dupliqués** entre les deux méta-docs (la vérité doit être présente là où elle est attendue, pas centralisée et diluée).

**Profil de projet visé** : ce méta-doc ne prescrit aucun profil — il prescrit qu'un profil soit posé en amont (dans le doc philosophy chargé conjointement). Le profil de référence pour ce repo (sustainable solo craft) est posé dans `docs/architecture/00-philosophy.md` §1.

**Limite assumée — piège miroir** : ce méta-doc partage par construction les biais cognitifs de l'auteur des docs langage qu'il audite ou cadre. Il vérifie et oriente ce qu'il sait reconnaître, pas ce qu'il aurait dû exiger. Pour un audit plus exigeant, soumettre le doc audité à un LLM frais — qui n'a écrit ni le philosophy ni les docs langage ni ce méta — en lui donnant `docs/architecture/00-philosophy.md` et en lui demandant de produire ses propres sondes, puis comparer.

**Pré-requis stricts de chargement** :

- **Mode production from scratch** (création d'un nouveau doc langage) : ce méta seul est **insuffisant**. Charger conjointement `docs/architecture/00-philosophy.md`. Sans philosophy, le doc produit aura systématiquement les angles morts suivants : profil cible jamais nommé, INVARIANTS hérités de philosophy non marqués (interactivité obligatoire, métier ne s'infère pas, pas de seuil chiffré unilatéral), triade des sources de vérité (architecture / conventions projet / utilisateur) non posée explicitement, renvois `cf. philosophy §X` potentiellement hallucinés. Si tu ne disposes pas de `philosophy.md`, **demande-le à l'utilisateur avant de rédiger** — ne devine pas son contenu.

- **Mode calibration** (audit d'un doc langage existant) : ce méta seul peut suffire pour les vérifications mécaniques (greps, présence des axes, conformité au contrat de densité). Pour les vérifications de cohérence avec philosophy (INVARIANTS, triade, renvois croisés), chargement de `philosophy.md` recommandé.

---

## 2. Contrat de densité

Quatre règles pour décider quand expliciter, quand renvoyer, quand chiffrer dans un doc langage.

- **Règle 1 — Correcteur de prior LLM** → exemple ✗/✓ obligatoire. *Critique pour les docs langage* : les anti-patterns sont souvent très langage-spécifiques (Repository static en TS, `Rc<RefCell>` partout en Rust, héritage profond en Java, IIFE pour scoper en JS legacy…). Le LLM rédacteur d'un projet régénère ces anti-patterns par défaut depuis son training data — sans ✗/✓ explicite il les reproduit.
- **Règle 2 — Désambiguisable par renvoi vers une SSOT** → 1 phrase + renvoi. SSOT possibles : `philosophy` (pour les principes — *jamais* les rejouer dans le doc langage), `docs/conventions.md` du projet (pour les seuils contextuels), ou utilisateur (pour les choix contextuels non couverts par les docs). Sinon, structure et exemples obligatoires.
- **Règle 3 — Seuil flou** → exemple qualitatif ✗/✓, jamais chiffré. *Exception* : chiffrages techniques objectifs (taille de contexte LLM, version minimale supportée d'un runtime, paliers d'API publics figés par la communauté du langage).
- **Règle 4 — Justification du default** → ½ ligne max. *Exception* : sur les tensions à arbitrer qui ont une forme idiomatique non triviale dans le langage, les coûts/conséquences sont fonctionnels (outil d'arbitrage pour les cas non prévus), pas justificatifs.

---

## 3. Effet dilution

Le LLM retient mieux le **début** et la **fin** d'un document. Le milieu peut être noyé. Le risque n'est pas la longueur seule — c'est la **surcharge de règles** dans une section unique.

- Préambule court (≤25 lignes), pas pédagogique.
- Sections numérotées, autonomes (lisibles isolément).
- Règles dures en début de section.
- Aucune section au-delà de ~60-70 lignes sans découpage (un doc langage peut tolérer des sections plus longues qu'un philosophy parce que les exemples de code prennent de la place ; mais au-delà du seuil, scinder).
- Renvois croisés explicites (`cf. §X`, `cf. philosophy §X`).
- Récap final autorisé **s'il sert d'anti-dilution du milieu** (pas un résumé esthétique).
- Densité optimale : ~400-700 lignes par doc langage (selon richesse du paradigme). Au-delà de ~1000 : scinder par sujet, jamais en deux moitiés du même doc.

---

## 4. Smells de doc langage

Anti-patterns rédactionnels à reconnaître et éviter. Les trois plus pernicieux (spécifiques aux docs langage) ont un ✗/✓ explicite ; les autres sont des références nominales — leur reconnaissance s'infère du doc audité.

**Rejouer un principe philosophy au lieu d'y renvoyer** — *correcteur de prior, exemple obligatoire*

```
✗ "Default : émerger. Première occurrence reste minimale ; duplication réelle déclenche la factorisation."
  (re-énonce le principe de philosophy §5 dans le doc langage)

✓ "Pattern d'émergence : la factorisation se déclenche selon les critères de philosophy §5 tension 1.
   Forme TS de la factorisation : extraction en fonction libre dans le module du concept."
  (renvoie au principe, traduit en idiome)
```

**Exemple de code qui ne compile pas / n'est pas runnable** — *correcteur de prior, exemple obligatoire*

```
✗ Bloc de code avec imports manquants, syntaxe inventée, ou API ancienne ne compilant plus.
✓ Bloc de code minimal mais autonome (imports inclus, version cible respectée), copiable et compilable tel quel dans un projet bootstrap.
```

**Comparaison gratuite avec d'autres langages** — *correcteur de prior, exemple obligatoire*

```
✗ "Contrairement à Python où on utilise des dataclasses, en TS on préfère le pattern type+const…"
  (le lecteur n'a pas besoin de connaître Python pour comprendre)

✓ "En TS, le pattern par défaut pour un concept du domaine est type+const object literal+as const+declaration merging."
  (énoncé direct sans détour comparatif)
```

**Autres smells** — index nominal :

- Doc monolithique sans plan ou sans table des axes.
- Redondance non fonctionnelle entre sections.
- Anti-pattern historique du langage non listé (un LLM peut le régénérer depuis son training data).
- Justification en prose qui dilue l'instruction.
- Renvoi vers fichier ou section inexistante.
- Surcharge de règles dans une section unique.
- Inversion de la posture interactive (le doc tranche unilatéralement un choix qui doit revenir à l'utilisateur projet).
- Cérémonie d'audit ou de scaffolding ajoutée au doc langage (ces préoccupations vivent dans les skills, pas dans le doc).

---

## 5. Cadrage avant rédaction — questions sur le langage cible

Avant d'ouvrir le doc à produire, cartographier le langage selon les axes qui orientent la structure. Si une question n'a pas de réponse claire, la poser à l'utilisateur — ne pas inférer.

**Paradigme dominant**
- Le langage privilégie-t-il un paradigme (fonctionnel pur, OO classique, multi-paradigme, procédural systèmes, logique, dataflow) ?
- La modélisation d'un "concept du domaine" passe-t-elle naturellement par : structure + fonctions, classe avec méthodes, type algébrique, enum tagged, protocole/trait/interface, acteur message-passing ?
- Quelle est la forme *par défaut* qu'un développeur expérimenté du langage utilise spontanément pour cette modélisation ?

**Système de types**
- Statique fort, statique faible, dynamique, gradual, dépendant ?
- Inférence locale, inférence globale, annotations obligatoires ?
- Sum types natifs, pattern matching exhaustif, generics, traits/typeclasses/protocols ?
- Garanties sur la nullabilité, l'immuabilité, l'absence de pointeurs nuls ?

**Modèle d'erreur natif**
- Exceptions, valeurs de retour (Result/Option/Either), codes d'erreur, panics, conditions, signaux ?
- Idiome dominant ou plusieurs en compétition dans la communauté actuelle ?

**Modèle de concurrence**
- Threads OS, async/await, coroutines/green threads, acteurs, CSP, callbacks, single-thread event loop, structured concurrency ?
- Mutabilité partagée explicite (locks) ou interdite par construction (ownership) ?

**Gestion mémoire et ressources**
- GC, refcount, ownership/borrowing, manuelle, RAII ?
- Comment se libère naturellement une ressource (timer, connexion, handle) — destructor implicite, `defer`, context manager, dispose manuel ?

**Écosystème et outillage**
- Gestionnaire de paquets standard ou plusieurs en concurrence ?
- Build system natif ou multiple ?
- Linter/formatter standard de fait ?
- Test runner standard ?
- Lib de validation/parsing dominante pour les frontières externes ?

**Frontières d'usage typiques**
- À quels contextes métier ce langage est-il majoritairement appliqué (services backend, CLI, embarqué, calcul scientifique, scripts, frontend, mobile, jeu, systèmes critiques) ? Le doc reflète les usages réels, pas tous les usages possibles.
- Plusieurs frontières structurelles distinctes (UI ↔ domain, serveur ↔ client) existent-elles, ou une seule ?

**Anti-patterns historiques du langage**
- Quels patterns "anciens" la communauté a abandonnés mais qu'un LLM peut régénérer (training data plus ancien que les conventions actuelles) ?
- Quelles libs/styles sont obsolètes mais encore présents dans les exemples publics ?

**Conséquence pour la structure du doc** : si une section ci-dessous ne correspond à aucun concept natif du langage, **fusionne, renomme ou supprime-la**. Inversement, si le langage impose une section spécifique non listée (ex: ownership/lifetimes, FFI, macro-system, build conditionals), **ajoute-la**. La structure suit le langage, pas l'inverse.

---

## 6. Chapitrage attendu du doc langage

Onze axes à couvrir. Tous ne donnent pas nécessairement une section dédiée — selon le langage, certains se fondent, d'autres se subdivisent. Le **contenu attendu** prime sur le découpage.

| # | Axe | Universel ? |
|---|---|---|
| 1 | Setup minimal | Oui |
| 2 | Forme de la donnée pure (concept du domaine) | Oui |
| 3 | Forme de la transformation sans état | Oui |
| 4 | Forme de l'unité qui tient un état dans le temps | Conditionnel (si le langage la distingue) |
| 5 | Frontières et validation | Oui |
| 6 | Erreurs | Oui |
| 7 | Concurrence et lifecycle des ressources | Conditionnel (selon modèle natif) |
| 8 | Organisation physique du code | Oui |
| 9 | Idiomes des arbitrages de philosophy §5 | Oui |
| 10 | Pont domain ↔ frontière d'usage typique | Conditionnel (selon usages typiques) |
| 11 | Smells à éviter | Oui |

---

## 7. Spécification axe par axe

Pour chaque axe : **Objectif** (ce que doit délivrer la section dans le doc langage), **Contenu attendu** (matière à couvrir), **Questions à se poser** (pour adapter au langage cible).

### Axe 1 — Setup minimal

**Objectif** : poser le tronc commun de tooling et de configuration, figer les choix non négociables pour éviter de rejouer les mêmes arbitrages dans chaque projet.

**Contenu attendu** :
- Runtime / version cible (minimale supportée, justifiée par les features utilisées). Compilateurs/runtimes alternatifs s'il y en a — lequel par défaut.
- Gestionnaire de dépendances par défaut + critères de bascule si plusieurs sont viables. Lister ceux à *ne pas* utiliser.
- Configuration compilateur/interpréteur : flags/options dures, bloc minimal copiable, chaque flag justifié.
- Build system : si pluriel, choisir et justifier.
- Linter / formatter : choix par défaut + exception explicite si cas légitime.
- Encapsulation racine code applicatif (`src/`, `lib/`, `pkg/`…) et convention d'alias d'import.
- Lib de validation/parsing aux frontières : **choix assumé non rejoué dans chaque projet** + critères d'exception + libs antérieures à éviter.
- Conventions de nommage : casse pour types, fonctions, fichiers, constantes, modules. Suivre la convention dominante de la communauté. Préfixes/suffixes interdits (notation hongroise, `I`/`T`…).
- Règles dures de typage / sûreté : interdit toujours / autorisé uniquement aux frontières / interdit par défaut avec exception structurelle nommée. Pour chaque échappatoire : règle et raison.

**Questions à se poser** :
- Version minimale qui garantit les features utilisées ?
- Tooling qui *signale* la posture moderne ?
- Lib de validation qui sert de SSOT pour modéliser un concept ?
- Piège #1 d'un LLM générant du code dans ce langage (import obsolète, syntaxe ancienne) ?

### Axe 2 — Forme de la donnée pure

**Objectif** : donner *le* pattern par lequel un concept du domaine est modélisé. Forme canonique, exemple, règles dures contre les dérives.

**Contenu attendu** :
- Pattern canonique : forme native du langage pour "structure de valeurs + transformations".
- Exemple complet d'un concept simple (entité avec quelques champs + 2-3 helpers) — autonome, copiable.
- Source de vérité : si lib de validation, expliciter qui est la SSOT (schéma ou type). Une seule direction. Pas de double déclaration.
- Règles dures (2 à 4) qui interdisent les dérives : pas de duplication schéma/type manuel, pas de wrapper class vide, pas de mutation in-place, pas d'invariants au constructeur si le parsing aux frontières fait le travail.
- Forme du regroupement helpers : trancher *une* forme canonique idiomatique du langage. Anti-pattern : namespace déguisé en class statique (traduction dans les idiomes).
- Quand sortir du pattern : trivial (juste le type) / bascule vers acteur (axe 4) / cas spécifiques au langage.

**Questions à se poser** :
- Forme qu'un développeur expérimenté du langage utiliserait spontanément ?
- Plusieurs formes équivalentes ? → choisir la plus lisible à l'import.
- Immutabilité native ou à imposer par convention ?

### Axe 3 — Forme de la transformation sans état

**Objectif** : poser la forme minimale pour une fonction libre, défendre cette minimalité contre la tentation de la wrapper.

**Contenu attendu** :
- Forme par défaut (la plus dépouillée du langage) : fonction exportée, fonction libre, méthode statique d'objet compagnon…
- Critère de regroupement (quand grouper en module/namespace, quand garder séparé) — qualitatif, pas chiffré, renvoi à `docs/conventions.md` si seuil émerge.
- Distinction transformation libre ↔ helper de donnée pure : critère de propriété (*"qui possède la fonction ?"*).
- Anti-pattern principal du langage : forme qui *ressemble* à une fonction libre mais ne l'est pas (class statique, objet utility, singleton de fonctions). Renvoi à l'axe 11.

**Questions à se poser** :
- Fonction libre est-elle naturelle ou cérémonieuse dans ce langage ?
- Forme qui évite à la fois la dispersion et l'accumulation hétéroclite ?
- Si langage strictement OO sans fonctions libres : comment traduire (méthodes statiques d'objet compagnon nommé) ?

### Axe 4 — Forme de l'unité qui tient un état

**Objectif** : encadrer strictement quand introduire une unité stateful. Forme dépend du langage ; posture universelle : on n'introduit cette forme qu'avec justification.

**Contenu attendu** :
- Forme canonique : forme native pour unité retenant un état et/ou recevant des dépendances à la construction.
- Critères stricts d'utilisation (état interne mutable, dépendances injectées, ressource retenue). Pas de wrapper autour d'une structure (c'est l'axe 2).
- Instanciation — règle A par défaut : construction au point d'usage.
- Bascule A → B vers un composition root : signaux qui forcent la centralisation (wiring dupliqué entre ≥ plusieurs consommateurs, ressource partagée à protéger, graphe de deps profond, besoin de substitution pour test). Forme minimale du composition root : un fichier, instanciations explicites, exports nommés, pas de framework DI.
- **INVARIANT** — pas de singleton sous quelque forme que ce soit (export d'instance pré-construite, `getInstance()`). Si une instance doit être partagée → composition root.
- Unité stateful déguisée en namespace : si pas d'état d'instance ni de dépendances injectées, ce n'est pas un acteur — c'est un module mal nommé.
- Constructeur qui bypass ses propres invariants → forme à supprimer, repli sur donnée pure (axe 2) + parsing frontières (axe 5).
- Visibilité : règles par défaut sur l'encapsulation, justification quand on expose.
- Lifecycle : si l'unité retient une ressource, exposer un point de libération. Forme et nom idiomatiques.

**Questions à se poser** :
- Le langage force-t-il les classes (Java-like) ou les rend optionnelles ? Si forcées, insister sur la distinction "vraie unité stateful" vs "namespace déguisé".
- Alternatives à la classe pour porter un état (closures, types avec méthodes, acteurs natifs) ?
- Libération de ressource : implicite (RAII, GC + finalizers) ou explicite (dispose, defer, context manager) ?

### Axe 5 — Frontières et validation

**Objectif** : poser comme **INVARIANT** (cf. philosophy §5) que la validation a lieu une fois, à la frontière externe, et que ce qui circule en interne est trusté.

**Contenu attendu** :
- Définition opérationnelle d'une frontière dans ce langage et ses usages typiques : liste explicite (endpoint HTTP, soumission formulaire, lecture fichier, retour client externe, message IPC/WebSocket, args CLI, variables d'environnement, désérialisation).
- Pattern de parsing à la frontière : exemple de code avec la lib de validation choisie (axe 1).
- Pattern au retour d'un SDK/client externe : *le type prétendu n'est pas trusté*. Parser explicitement. Le SDK n'est pas la frontière, le parsing l'est.
- Anti-pattern principal : revalidation interne d'une donnée déjà parsée. Exemple ✗ clair. Si tu hésites à revalider, une frontière a été ratée en amont — corrige la frontière.
- Types nominaux / brand types : default (primitive nommée par champ explicite suffit dans 90% des cas), exception (risque concret de confusion entre deux IDs primitifs dans une même fonction). Passage par parsing obligatoire — pas de cast unsafe.
- Cas particulier : si le langage / framework offre une validation built-in qui peut servir de SSOT (alternative à la lib axe 1), expliciter (utiliser la built-in comme SSOT, pas en parallèle).

**Questions à se poser** :
- *Vraies* frontières des usages typiques (pas toutes celles théoriquement possibles) ?
- Le système de types permet-il de *prouver* qu'une donnée est passée par la frontière (types nominaux, branded) ?
- Comment éviter la double validation tout en gardant la sûreté ?

### Axe 6 — Erreurs

**Objectif** : poser la distinction métier/exceptionnel, lister les options idiomatiques du langage avec trade-offs, **ne pas trancher un pattern par défaut** sauf consensus communautaire fort — la décision se fait projet par projet et se capture dans `docs/conventions.md`.

**Contenu attendu** :
- Distinction universelle :
  - **Erreur métier attendue** : cas d'échec prévu, explicite dans la signature, gérée par le consommateur.
  - **Erreur exceptionnelle** : bug, état impossible, dépendance morte. Remonte à un handler global.
- Pourquoi la distinction est critique : confondre les deux = bugs durables. Échec métier silencieux → chemins invisibles. Bug enveloppé dans Result → anomalie noyée.
- Tableau des options idiomatiques du langage : 2 à 5 options avec, pour chacune : forme métier, forme exceptionnelle, coût/trade-off.
- Default contextuel proposé par type de site (entrée externe, logique interne, bug) — **à valider avec l'utilisateur projet par projet**. Pas un pattern unique imposé.
- Posture face à un projet sans convention : (i) lire l'existant, (ii) si rien, énoncer la grille et **demander à l'utilisateur**, (iii) capturer dans `docs/conventions.md`, (iv) appliquer strictement ensuite.
- Anti-patterns transverses : catch silencieux, erreur exceptionnelle déguisée en absence (`null` sans distinction "absence légitime" vs "échec"), erreur métier déguisée en panique, erreur sans contexte.

**Questions à se poser** :
- Le langage impose-t-il un seul pattern ou en laisse-t-il plusieurs en compétition ?
- Si imposé : décrire comment l'utiliser correctement, pas comment choisir.
- Consensus communautaire récent (lib type Result devenue standard, abandon des exceptions checked) ?

### Axe 7 — Concurrence et lifecycle des ressources

**Objectif** : poser les règles dures qui évitent les bugs *qui survivent des années* — races, ressources non libérées, opérations non annulées, fuites mémoire. Section conditionnelle au modèle natif.

**Contenu attendu (modulé selon le modèle de concurrence)** :

- **Async/await ou équivalent** : pas d'opération asynchrone orpheline, parallélisme idiomatique pour opérations indépendantes, annulation native (cancellation token, AbortController, scope-based, structured concurrency), pattern anti-race (vérification de pertinence, annulation de la précédente).
- **Ownership / borrowing** : règles sur partage entre tâches, propagation d'annulation idiomatique.
- **Single-threaded event loop** : règles sur opérations bloquantes (éviter, isoler), gestion backpressure si streams.
- **Threads OS classiques** : synchronisation (locks, channels, atomics), passage de données entre threads.
- **Acteurs natifs** : forme de lifecycle (spawn, supervision, shutdown).
- **Lifecycle des ressources retenues** (universel à la section) : une unité (axe 4) qui retient une ressource expose un point de libération. Forme et nom idiomatiques.
- **Si le langage n'a essentiellement aucun de ces sujets** (synchrone simple sans I/O concurrent dans les usages typiques) : section très courte ou fusionnée dans axe 4.

**Questions à se poser** :
- Bug de concurrence #1 qu'un développeur expérimenté évite par réflexe et qu'un LLM produit naïvement ?
- Le système de types / compilateur empêche-t-il certaines classes de bugs (ownership empêche data races, async coloring force le tracking) ? Ce qui est *gratuit* vs *à discipline*.
- Forme la plus lisible d'annulation propre — locale (try/finally), structurée (scope), explicite (token) ?

### Axe 8 — Organisation physique du code

**Objectif** : matérialiser le slicing vertical par concept (philosophy §6) dans les conventions de dossiers/modules/packages/crates du langage.

**Contenu attendu** :
- Unité physique du langage : nommer ce qui sert de "conteneur de concept". Adapter le vocabulaire (pas "dossiers" si le langage organise en modules sans hiérarchie de fichiers stricte).
- Arborescence type : exemple commenté avec racine applicative, dossier `domain/` (ou équivalent) avec 2-3 concepts, conteneur transverse (`shared/` ou équivalent), couches optionnelles.
- Conventions de nommage par rôle (donnée pure, schéma, repository, parseur spécialisé). Barrel/réexport uniquement justifié, pas par défaut.
- Couches optionnelles, à n'introduire que sur signal :
  - Couche use-cases / application : créée seulement au premier use-case réel.
  - Couche infrastructure : séparée seulement si plusieurs implémentations OU swap envisagé.
  - **Couche services au sens horizontal : n'existe pas**. Soit fonction libre (axe 3), soit unité stateful (axe 4) — dans le dossier de son concept.
- Anti-pattern principal — slicing horizontal : exemple ✗ avec dossiers par type technique.
- Distinction `shared/` (intra-domain) vs `lib/` (non-domain) : `shared/` pour métier transverse à plusieurs concepts, `lib/` pour utilitaires techniques non-métier.

**Questions à se poser** :
- Unité d'organisation la plus naturelle dans ce langage ?
- Imports/visibilités permettent-ils le slicing vertical, ou forcent-ils un slicing horizontal ?
- Granularité de fichier favorisée par la communauté (un fichier = un concept, ou un fichier = un module multi-concepts) ?

### Axe 9 — Idiomes des arbitrages de philosophy §5

**Objectif** : pour chaque tension de philosophy §5, donner la **forme idiomatique** dans le langage *quand le critère est rempli*. Les critères vivent dans philosophy — ne pas les rejouer.

**Contenu attendu** : pour chaque arbitrage qui a une traduction idiomatique non triviale :
- Forme par défaut (default philosophy) : code minimal.
- Forme d'exception (signal déclencheur présent) : code avec la cérémonie justifiée.
- Anti-pattern adjacent : la forme qui *ressemble* à l'exception mais sans signal réel (renvoi axe 11).

Exemples typiques :
- **Repository concept** : forme par défaut (fonctions du module), forme avec deps (unité stateful), interdiction "classe-namespace" déguisée.
- **Use-case dédié** : forme par défaut (inline), forme dédiée (fonction qui prend ses deps en argument, pas classe à une méthode).
- **Port** : forme idiomatique (alias de type, trait, protocole), nommage des implémentations (suffixe par techno, pas préfixe).
- **Factory** : presque jamais nécessaire si le parsing aux frontières fait le mapping. Cas marginal : fonction `createXxx(deps)`, pas cérémonie de classe.
- **Value object** : non par défaut. Champ nommé + primitive. Brand type via la lib de validation si confusion réelle.
- **Abstraction nommée gratuite** : alias de type nommé, schéma de validation — du nommage, pas de l'architecture. Encouragée si elle ajoute de la lisibilité.

**Questions à se poser** :
- Forme la plus *bas-cérémonie* du langage pour chaque pattern → baseline.
- Pattern qu'un développeur expérimenté utilise *seulement quand forcé* → forme d'exception.
- Pattern syntaxiquement séduisant du langage qui produit de la cérémonie sans valeur → neutraliser explicitement.

### Axe 10 — Pont domain ↔ frontière d'usage typique

**Objectif** : poser comment le domain (concepts purs, fonctions libres, unités stateful) se connecte à la frontière d'usage typique du langage. Section conditionnelle aux usages typiques.

**Contenu attendu (modulé)** :
- **Frontière UI** : pont fonctionnel (hook, composable, callback), jamais classe — délègue l'état au runtime du framework. Store stateful global s'il existe : posture vis-à-vis du domain. **INVARIANT** — mutation interdite des données du domain depuis l'UI. Transformations via helpers du concept (axe 2). L'UI mute son propre état, jamais celui du domain.
- **Frontière HTTP/serveur** : forme du handler de route, posture frontière (parser à l'entrée, trust ensuite), use-case extrait seulement sur signal.
- **Frontière CLI** : parsing d'arguments comme frontière, mapping vers le domain.
- **Frontière FFI / interop** : pattern de mapping des types externes vers les types du domain.
- **Plusieurs frontières typiques** : sous-sections par frontière.
- **Frontière unique** : section courte, focalisée.
- **Contextes hétérogènes sans frontière dominante** : poser le principe abstrait, renvoyer aux conventions projet.

**Questions à se poser** :
- 1 à 3 frontières qui couvrent 80% des projets dans ce langage ? Ne traiter que celles-là.
- Piège récurrent à cette frontière (logique métier dans le composant UI, parsing dispersé, mutation depuis le contrôleur) ?
- Forme du pont = convention communautaire ou choix à faire ?

### Axe 11 — Smells à éviter

**Objectif** : catalogue d'anti-patterns récurrents *spécifiques au langage*, avec le pattern correct en regard. Référence rapide pour un développeur ou un LLM qui s'apprête à générer une forme.

**Contenu attendu** : 8 à 15 anti-patterns, chacun avec : nom court, exemple ✗ minimal mais reconnaissable, exemple ✓ correspondant, raison brève si pas évidente.

Catégories typiques (adapter selon le langage) :
- Wrapper inutile autour d'un type primitif.
- Unité stateful déguisée en namespace (classe statique, objet utility) — traduction concrète dans le langage.
- Singleton sous toutes ses formes.
- Factory cérémonieuse autour d'un parsing trivial.
- Contournement d'invariants via mécanismes d'évasion (constructeur bypassé, cast unsafe).
- Préfixes/suffixes de nommage proscrits (hongroise, `I`, `T`).
- Use-case wrapper trivial.
- Slicing horizontal dans la racine applicative.
- Cast / escape hatch pour échapper à la validation.
- Revalidation interne d'une donnée déjà parsée.
- Couches optionnelles vides "au cas où".
- Anti-patterns historiques du langage (cf. cadrage initial axe 1 / §5 méta).

**Questions à se poser** :
- Anti-pattern qui génère le plus de bugs dans la communauté du langage ?
- Pattern qu'un LLM produit par réflexe (héritage training data) plus dans l'idiome actuel ?
- Pattern syntaxiquement "propre" mais sémantiquement à éviter (feature séduisante qui produit du couplage caché) ?

---

## 8. Méta-règles de rédaction

Règles transverses qui s'appliquent à toute section du doc langage, en complément du contrat de densité (§2).

**Vocabulaire** : utiliser le vocabulaire de philosophy (*donnée pure*, *fonction libre*, *acteur*, *frontière*, *port*, *use-case*, *concept du domaine*, *concept transverse*) — ne pas réinventer un vocabulaire parallèle. Si un terme du langage a une nuance, l'expliciter en regard du terme philosophy.

**Renvois à la philosophy** : quand un arbitrage est traité dans philosophy, **renvoyer** (ex: *"cf. philosophy §5"*) plutôt que recopier.

**Renvois à `docs/conventions.md`** : quand un seuil influence une décision structurelle, expliciter qu'il se capture dans les conventions du projet — **jamais** dans le doc langage.

**Posture interactive** (philosophy §1 invariant) : quand le doc présente plusieurs options sans default communautaire fort (typiquement axe 6 erreurs, parfois axe 1 setup), expliciter que le choix se fait avec l'utilisateur projet par projet — pas par préférence du LLM.

**Cohérence sans uniformité** : deux concepts d'un même projet peuvent légitimement avoir des structures différentes (philosophy §7). Le doc langage ne doit pas imposer une structure unique pour tout concept — il donne les formes, le poids du concept dicte laquelle s'applique.

**Marquage des invariants** : tout principe sans exception par construction est marqué `**INVARIANT**` (cohérent avec philosophy §1). Confondre invariant et default est une faute.

---

## 9. Grille d'audit d'un doc langage existant

Pour le mode calibration. Vérifie. Cite la section qui répond, ou note l'écart. Cette grille teste des propriétés exhibées par le doc, pas des contenus à comparer mot pour mot avec les axes §7.

**Préambule et identité**
- [ ] Vocation du doc explicitée (qui le lit, dans quel mode).
- [ ] Renvoi explicite à `philosophy` pour les principes (pas de rejeu).
- [ ] Renvoi explicite à `docs/conventions.md` du projet pour les seuils contextuels.

**Présence des axes universels**
- [ ] Setup minimal (axe 1) avec choix tooling assumés.
- [ ] Forme donnée pure (axe 2) avec pattern canonique + exemple + règles dures.
- [ ] Forme fonction libre (axe 3).
- [ ] Forme acteur (axe 4) avec critères stricts + interdit singleton.
- [ ] Frontières et validation (axe 5) avec **INVARIANT** marqué.
- [ ] Erreurs (axe 6) sans tranchage unilatéral, posture interactive sur le choix de pattern.
- [ ] Organisation (axe 8) avec slicing vertical et anti-pattern horizontal.
- [ ] Idiomes des arbitrages (axe 9).
- [ ] Smells (axe 11) avec ✗/✓ pour les anti-patterns importants.

**Traitement des axes conditionnels**
- [ ] Concurrence (axe 7) traitée si le langage a un modèle concurrent, ou fusionnée/raccourcie avec mention si non.
- [ ] Pont domain↔frontière (axe 10) traité selon les frontières typiques du langage, ou traité abstraitement si contextes hétérogènes.

**Absence des anti-attendus**
- [ ] Aucun rejeu de principe philosophy (smell §4 méta).
- [ ] Aucun exemple de code non compilable / imports manquants.
- [ ] Aucune comparaison gratuite avec d'autres langages.
- [ ] Aucun seuil chiffré sur décision contextuelle (sauf chiffrage technique objectif : version runtime, taille contexte LLM).
- [ ] Aucune cérémonie d'audit ou de scaffolding (ces préoccupations vivent dans les skills).

**Conformité au contrat de densité (§2)**
- [ ] Règle 1 appliquée : anti-patterns langage-spécifiques ont ✗/✓ (axes 2, 3, 4, 11 notamment).
- [ ] Règle 2 appliquée : renvois vers philosophy / conventions projet / utilisateur.
- [ ] Règle 3 appliquée : pas de chiffres sur seuils contextuels.
- [ ] Règle 4 appliquée : justifications compactes (sauf coûts fonctionnels d'arbitrage).
- [ ] Pas de redondance non fonctionnelle.

**Conformité à l'effet dilution (§3)**
- [ ] Préambule ≤25 lignes.
- [ ] Aucune section >60-70 lignes sans découpage.
- [ ] Renvois croisés `cf. axe X` ou `cf. philosophy §X` présents.

**Smells de doc langage (§4)** : juger en lecture du doc audité — pas de checklist mécanique ici.

**Sondes complémentaires (jugement requis)**
- [ ] **Test fonctionnel production** — un LLM frais lisant uniquement ce doc langage + `philosophy` peut-il bootstraper un projet simple cohérent ? Identifier sans ambiguïté : (a) le pattern de donnée pure à utiliser, (b) quand introduire une unité stateful, (c) comment parser à une frontière, (d) où placer les fichiers.
- [ ] **Test fonctionnel calibration** — un LLM frais auditant un projet existant avec ce doc en main détecte-t-il les écarts évidents (singleton exporté, slicing horizontal, revalidation interne) ?
- [ ] **Auto-test miroir** — pour chaque item de cette grille, demande-toi : *teste-t-il une propriété réelle, ou la conformité à mes intuitions ?* Tout item suspect → requalifier ou enrichir d'un test fonctionnel.

---

## 10. Checklist finale avant publication d'un doc langage

Pour le mode production. À passer avant de considérer un nouveau doc langage comme livrable v1.

- [ ] Toute section répond à *"comment ce principe philosophy se concrétise dans ce langage ?"*, pas à *"que sait-on de ce sujet en général dans ce langage ?"*.
- [ ] Aucun seuil chiffré n'a été inventé (sauf si convention communautaire forte du langage, ou chiffrage technique objectif). Tous les seuils contextuels renvoient à `docs/conventions.md`.
- [ ] Les anti-patterns historiques du langage (training data plus ancien que l'idiome actuel) sont explicitement listés en axe 11.
- [ ] La distinction default / exception / **INVARIANT** est respectée — un invariant n'est jamais présenté comme un default.
- [ ] Le vocabulaire de philosophy est repris tel quel, pas reformulé.
- [ ] Aucune section ne duplique philosophy — partout des renvois.
- [ ] Les axes conditionnels (7 concurrence, 10 frontières d'usage) ont été soit traités avec le contenu pertinent au langage, soit explicitement fusionnés/raccourcis/supprimés avec mention de la raison.
- [ ] Chaque pattern principal a un exemple court, autonome, compilable.
- [ ] Aucun *"à mon avis"*, *"je pense que"*, *"il vaut mieux"* — soit c'est un default justifié, soit c'est un choix à faire avec l'utilisateur.
- [ ] Le doc passe la grille d'audit §9 — au moins les items universels.
