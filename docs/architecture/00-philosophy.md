# Philosophie d'architecture

> Cadrage pour LLM. À charger en contexte avant toute décision de structure. Les docs `ts/*.md` traduisent ces principes en idiomes TypeScript.

---

## 1. Préambule

Tu connais les patterns (DDD, hexagonal, fonctionnel). Ce doc ne te les apprend pas — il fixe **comment arbitrer entre eux** selon le projet et **ce qu'il faut éviter** par défaut.

**Posture** : pas de dogme. Chaque règle structurante est soit un *default* assorti d'un *déclencheur d'exception*, soit un **invariant**. Un invariant est une règle sans exception par construction — sa violation invalide le résultat. Les invariants sont explicitement marqués `**INVARIANT**` dans le doc. Confondre invariant et default est une faute.

**Deux biais opposés à éviter** : sur-ingénierie (pattern réflexe sans besoin observé) ET sous-ingénierie (domaine complexe aplati). Cible : *structure minimale qui porte la complexité réelle du métier*.

**Profil de projet visé — *sustainable solo craft*** : dev solo, cycle de vie long, maintenance par l'auteur, pas de pression business, refactor libre toléré, outillage soigné mais pas industriel. Ni MVP jetable ni système enterprise.

Conséquences : tests émergent au besoin, doc minimale (README + commentaires sur le *pourquoi*), pas de couches préventives, basiques sécurité/perf toujours et l'avancé sur signal.

*Variante "ouvert à contribution"* : adapte la surface visible (lisibilité critique, README, `CONTRIBUTING.md`), sans bascule enterprise. *Variante "hors profil"* (lib publique critique, équipe, contraintes business) : à signaler par l'utilisateur, adapte alors la posture.

**INVARIANT** — Interactivité obligatoire **et bloquante** : ne devine pas le métier ni les besoins techniques non inférables. Pose la question **et attends la réponse** avant d'écrire, scaffolder ou générer quoi que ce soit. Annoncer *"je continue, tu me préciseras après"* viole cet invariant — c'est une rationalisation, pas une initiative. Une question structurante non répondue **bloque** la suite. Voir §8 pour le détail des modes.

**Plan** :
- §2-3 : penser un nouveau projet (matière, vocabulaire).
- §4-5 : filtres en continu.
- §6-7 : structuration.
- §8 : quand demander (modes bootstrap / audit).
- §9 : seuils non chiffrés — règle dure.

---

## 2. Identifier la complexité métier avant tout

**Le piège** : recevoir un prompt, ouvrir un éditeur, scaffolder une arbo "propre" sans avoir cartographié où vit la complexité. C'est ainsi qu'on accouche de wrappers triviaux ou, à l'inverse, qu'on sous-dimensionne un domaine qui en aurait eu besoin.

**Avant tout choix technique, comprendre le métier.** Pas paraphraser le prompt — interroger l'utilisateur quand le prompt est ambigu ou incomplet.

**Questions à poser** (sélectionne celles qui s'appliquent, pas un interrogatoire) :

- **Acteurs** : un seul type d'utilisateur ou plusieurs rôles différenciés ?
- **Actions métier centrales** : les 3-5 actions qui ont du sens *pour l'utilisateur final*, pas pour le développeur.
- **Données centrales** : une entité dominante, ou plusieurs concepts en interaction ?
- **Invariants** : règles qui ne doivent jamais être violées (justifient ou non une validation stricte aux frontières).
- **Transformations critiques** : où vit le calcul réel — c'est là que la logique mérite d'être soignée.
- **Frontières** : qui parle à qui (UI ↔ API ↔ DB ↔ source externe). Une seule ou plusieurs ?
- **Évolution attendue** : multi-source ? Changement de persistance prévu ? Multi-tenant ? Sans cette info, impossible d'arbitrer port vs concret (§5).

**Quatre patterns typiques de localisation de la complexité** — ils orientent la structure :

- Complexité concentrée dans **une transformation** (ex: pipeline de compression média) → soigne le service/fonction central, le reste reste plat.
- Complexité dans les **invariants des données** (ex: domaine typé strictement avec règles métier) → soigne schémas et frontières, actions inline.
- Complexité dans **l'orchestration de plusieurs sources/règles** (ex: import multi-format avec dédoublonnage et persist) → c'est là qu'un use-case se justifie (§5).
- Complexité **distribuée et faible** (ex: vitrine CRUD-ish) → minimal, pas de couches, appels directs.

Si le prompt initial ne te permet pas de répondre à au moins 3-4 de ces questions, **demande** avant de structurer quoi que ce soit.

---

## 3. Trois formes citoyennes

Toute unité de code dans un projet relève d'une de ces trois formes. Choisir la bonne forme est plus important que choisir le bon "pattern".

**Donnée pure** — une structure de valeurs et les transformations qui s'y appliquent. Pas d'identité, pas d'état dans le temps : deux instances avec les mêmes champs sont équivalentes. Forme typique : une représentation de donnée validée + un groupement de fonctions helpers qui prennent ce type en argument. La forme concrète (schéma+type, struct+derive, struct+tags…) est traitée dans le doc langage. C'est la forme par défaut pour modéliser le domaine.

**Fonction libre** — une transformation isolée, sans état, sans dépendance qu'on lui injecte. Prend des entrées, retourne un résultat, ne se rappelle de rien entre deux appels. Forme typique : une fonction exportée. Pas besoin de la wrapper dans une class ou un objet "service" si elle n'a ni état ni dépendance réelle.

**Acteur** — un objet qui *tient quelque chose dans le temps* : un état interne qui évolue (timer, cache, progression, connexion ouverte) et/ou des dépendances qui lui sont passées à la construction (client DB, client HTTP, bus d'événements). Forme typique : une classe instanciée explicitement là où on l'utilise. C'est la seule forme qui justifie réellement l'usage d'une class.

**Critère de choix simple** :

- Pas d'état, pas de dep injectée → **fonction libre** ou **donnée pure** (selon que tu modélises une transformation ou une structure).
- État interne mutable OU dépendances injectées → **acteur**.

**À ne pas confondre** : avoir des "méthodes" qui transforment une donnée n'en fait pas un acteur. `Image.resize(img, w, h)` qui retourne une nouvelle image est une fonction sur une donnée pure, pas un acteur. L'acteur, c'est ce qui *retient* quelque chose entre deux appels.

**Anti-pattern récurrent** : la class qui n'a ni état d'instance ni dépendance injectée — uniquement des méthodes statiques. C'est un namespace déguisé. Utilise la forme native (namespace, module de fonctions) du langage à la place.

---

## 4. Le filtre fondamental

> Plusieurs formulations de cette section et des suivantes (*"concret et daté"*, *"horizon court"*, *"non triviale"*, etc.) sont des seuils volontairement non chiffrés. **Tu n'as pas autorité pour les chiffrer seul** — voir §9.

Avant d'ajouter une couche, une abstraction, un wrapper, un port, un use-case, une factory, une interface — passe par ce filtre :

> *Est-ce que je résous un problème **observé** dans ce projet, ou **attendu** de manière concrète et datée ? Ou est-ce que je copie un pattern parce que c'est ce qu'on "doit faire" ?*

Trois niveaux de justification, par ordre de force :

1. **Observé** : le besoin existe déjà dans le code (duplication réelle, point de friction concret, test impossible sans cette abstraction). Justification forte, applique. ✓ *"même logique de filtrage répétée dans 3 routes"* / ✗ *"on aura sans doute besoin d'un filtre générique"*.
2. **Attendu** : un changement précis est annoncé — présent dans BACKLOG, roadmap, ticket actif, ou conversation de cadrage en cours. Justification valable si l'horizon est court et concret. ✓ *"swap de persistance documenté dans la roadmap, en cours d'arbitrage"* / ✗ *"on basculera peut-être un jour vers une autre DB"*.
3. **Hypothétique** : "on pourrait un jour avoir besoin de…", "au cas où on voudrait…", "c'est mieux pour l'évolution". Justification refusée par défaut. Émerge au besoin.

**Corollaire** : la première implémentation d'un concept reste minimale. La seconde occurrence (duplication réelle) déclenche la factorisation. Pas avant.

**Inversion saine** : si tu hésites à ajouter une abstraction, demande-toi *quel test concret deviendrait possible*, *quelle duplication concrète disparaîtrait*, *quel changement annoncé deviendrait moins coûteux*. Pas de réponse tangible → pas d'abstraction.

**Cas limite** : certaines abstractions sont "gratuites" (un schéma de validation, un type nommé) et apportent de la lisibilité sans coût structurel. Celles-ci ne tombent pas sous ce filtre — elles relèvent du nommage, pas de l'architecture.

---

## 5. Tensions à arbitrer

Six tensions récurrentes. Chacune a un *default* — applicable en l'absence d'info contraire — et un *déclencheur d'exception*.

**Anticiper le changement vs émerger au besoin**
- *Coûts* : anticiper tôt → abstractions creuses, code mort. Émerger tard → refactor douloureux.
- *Default* : émerger. Première occurrence reste minimale ; duplication réelle déclenche la factorisation.
- *Exception* : changement annoncé, daté, concret (cf. §4 "Attendu"). ✓ *"multi-source CSV+API spec'é dans le BACKLOG ce trimestre"* / ✗ *"on pourrait vouloir d'autres sources un jour"*.

**Cohésion par concept vs découplage par couche technique**
- *Coûts* : cohésion → un concept évolue dans son conteneur, simple. Découplage horizontal → un concept éparpillé sur N dossiers, navigation coûteuse.
- *Default* : cohésion par concept (cf. §6).
- *Exception* : élément réellement transverse (logger, config, erreurs partagées) — alors conteneur partagé dédié.

**Port (interface) vs implémentation concrète**
- *Coûts* : port → swap et mock possibles, surface doublée. Concret → direct et lisible, soudé à une techno.
- *Default* : concret.
- *Exception* : plusieurs implémentations attendues, OU mock indispensable pour test, OU swap concrètement envisagé. La quantification précise (combien ? sous quel horizon ?) se discute avec l'utilisateur et se capture dans `docs/conventions.md` du projet (cf. §9). ✓ *"source CSV pour V1, DB pour V2 dans la roadmap"* / ✗ *"on pourrait switcher de DB plus tard"*.

**Use-case dédié vs action inline**
- *Coûts* : use-case → isole une action complexe, réutilisable. Inline → action vit dans le consommateur, zéro indirection.
- *Default* : inline.
- *Exception* : plusieurs entry points partagent l'action, OU orchestration de plusieurs deps réelles, OU logique non triviale. La quantification précise (combien d'entry points ? combien de deps ? quelle taille = "non triviale" ?) se discute avec l'utilisateur et se capture dans `docs/conventions.md` du projet (cf. §9). ✓ *"mensuration récupérée depuis Dashboard ET Mensurations page"* / ✗ *"un jour on pourrait l'appeler ailleurs"*.

**Validation aux frontières** — **INVARIANT**
- ✓ *Parser aux frontières externes (API, formulaires, fichiers, retours de clients tiers), trusté en interne.*
- ✗ *Revalider chaque entrée en interne par "sécurité supplémentaire".*
- *Règle dure* : ce qui circule entre deux modules internes est déjà typé et parsé. Pas de revalidation.
- *Coûts évités* : revalidation à chaque couche = double coût sans gain ; absence de validation aux frontières = corruption silencieuse.
- *Pas d'exception* : si tu hésites à revalider, c'est qu'une frontière a été oubliée en amont — corrige la frontière, pas le consommateur.

**Abstraction nommée vs primitive nommée**
- *Coûts* : abstraction (wrapper, brand type) → sécurité de typage, coût syntaxique. Primitive nommée → simple, suffit dans 90% des cas.
- *Default* : primitive nommée (`userId: string`, `weightKg: number`).
- *Exception* : risque concret de confusion entre deux IDs/valeurs du même type primitif dans une même fonction — alors brand type dérivé du schéma (jamais via cast).

---

## 6. Slicing par concept métier

**Principe** : un dossier = un concept du domaine, pas un type technique. Tout ce qui décrit, transforme, persiste ou expose un concept vit ensemble.

**À éviter** — slicing horizontal par couche technique :

```
domain/
  entities/        ← Image, Entry, Page, Order…
  services/        ← tous les services mélangés
  repositories/    ← toutes les persistances mélangées
  factories/       ← toutes les factories mélangées
```

Chaque concept est éparpillé sur 4 dossiers. Pour comprendre `Image`, il faut ouvrir 4 fichiers dans 4 endroits. La cohésion conceptuelle est sacrifiée à une cohésion technique sans valeur.

**À privilégier** — slicing vertical par concept : un conteneur par concept du domaine. Tout ce qui touche un concept (sa donnée, ses transformations, sa persistance, ses ports si applicable) vit dans son conteneur. Ouvrir le conteneur d'un concept = avoir tout sous la main. Ajouter un concept = créer un conteneur, pas modifier plusieurs dossiers transverses.

**La forme physique** (dossier+fichiers, module, package, crate, namespace…) et **la convention de nommage** sont définies dans le doc langage. Réfère-toi à ce doc — qui structure et hiérarchise selon le paradigme du langage utilisé — avant de poser une arborescence.

**Conséquences universelles** :
- Pas de regroupement global par type technique (`services/`, `repositories/`, `factories/`, `entities/` à la racine du domaine).
- Le conteneur "transverse" (souvent nommé `shared/` ou équivalent) n'accueille **que** ce qui est réellement consommé par plusieurs concepts. Pas de "ça pourrait servir ailleurs".
- Un élément transverse avec un seul consommateur appartient à ce consommateur, pas au conteneur partagé.

**Granularité** : un concept = ce que l'utilisateur final nomme spontanément (`Image`, `Mensuration`, `Page`, `Compression`). Pas un détail technique (`ImageMetadata`, `ImageBuffer`) — ceux-ci vivent à l'intérieur du dossier du concept parent.

---

## 7. Conventions plurielles selon le concept

**Il n'existe pas une convention unique pour tous les concepts d'un projet.** Chaque concept choisit sa forme selon son poids réel dans le domaine.

Un concept dont la complexité se réduit à une structure de données et quelques transformations triviales ne mérite pas la même cérémonie qu'un concept porteur d'invariants forts, de transitions d'état, d'orchestration ou de persistance complexe. Appliquer une convention uniforme à tous les concepts d'un projet, par souci de symétrie ou de "propreté", produit soit du boilerplate vide pour les concepts légers, soit du sous-dimensionnement pour les concepts lourds.

**Règle** : pour chaque concept, demande-toi *quel est le poids réel de ce concept dans le métier* avant d'appliquer une forme. La forme doit suivre la complexité, pas la précéder.

**Conséquence pour les LLM** : ne génère pas un concept par template figé répété N fois. Évalue chaque concept indépendamment. Deux concepts du même projet peuvent légitimement avoir des structures de fichiers très différentes — c'est le signe que l'arbitrage a été fait, pas une incohérence.

**Cohérence vs uniformité** : la cohérence d'un projet vient de l'application cohérente du *raisonnement d'arbitrage*, pas de l'application mécanique de la même structure partout. Un projet peut être parfaitement cohérent en ayant un concept en 1 fichier, un autre en 4, et un troisième porté par une class avec deps injectées.

---

## 8. Quand demander à l'utilisateur

**Principe** : tu ne décides pas seul des choix qui dépendent d'une intention que tu ne peux pas inférer. Demander n'est pas un signe d'incompétence — c'est la condition pour ne pas produire du code qui rate la cible.

**Trois sources de vérité, jamais confondues** :

| Source | Rôle | Localisation |
|---|---|---|
| **Architecture** | Comment construire | Ces docs (philosophy + langage) |
| **Conventions projet** | Décisions contextuelles d'un projet précis (seuils, choix locaux) | `docs/conventions.md` à la racine du projet (cf. §9) |
| **Métier** | Quoi construire et pourquoi | L'utilisateur lui-même |

**INVARIANT** — Le métier ne s'infère jamais. Ni depuis le code existant, ni depuis les noms de fichiers, ni depuis les commentaires, ni depuis le BACKLOG. Toute question métier se pose à l'utilisateur. Lire un nom comme `Order` ou `Patient` te donne du vocabulaire de surface, pas le métier réel — qui le manipule, dans quelles règles, sous quels invariants. Demande.

**Deux modes opératoires** :

- **Mode bootstrap (création from scratch)** — pas de code à inférer. Tu appliques les invariants, instancies les defaults, **demandes** sur les choix contextuels (techno, métier, persistance, périmètre). Tu ne devines rien sur ce qui n'est pas dit.
- **Mode audit (revue d'un projet existant)** — du code existe, possiblement en écart avec les conventions (c'est précisément le motif de l'audit). Inférer depuis ce code est piégé : reproduire les écarts au lieu de les corriger. Compare le code aux sources de vérité (architecture + conventions projet), identifie les écarts, **demande validation** avant correction.

Ces deux modes correspondent aux skills de cadrage (`bootstrap-*`, `audit-*`). Le doc n'a pas à les connaître, mais ta posture doit basculer selon le mode.

**Toujours demander, sur le métier**, quand le prompt initial laisse ouverts :

- Le **vocabulaire du domaine** : nom des concepts centraux, granularité, traduction d'un terme métier flou ("article", "produit", "item" ne se valent pas).
- Les **acteurs et leurs rôles** : utilisateur unique vs rôles différenciés, permissions, scopes.
- Les **invariants non négociables** : règles que le métier refuse de voir violées, même temporairement.
- La **frontière de responsabilité** : ce qui est dans le périmètre vs ce qui en sort (ex: "l'app *gère* l'import ou se contente d'*afficher* ce qui est importé ailleurs ?").
- Les **scénarios d'usage réels** : qui fait quoi dans quelle situation — quand le prompt décrit une feature en abstrait sans cas concret.

**Toujours demander, sur la technique**, avant tout choix non inférable :

- **Persistance cible** et son évolution probable (mémoire, fichier, IndexedDB, SQLite, DB serveur, API tierce).
- **Multiplicité de sources** prévue (une seule source unique, ou plusieurs en parallèle / dans le temps).
- **Swap d'implémentation** envisagé concrètement (justifie ou non un port, cf. §5).
- **Frontières externes** : quelles entrées sont vraiment des frontières dans ce projet (API, formulaires, fichiers, retours DB tiers) — pour ne pas valider partout par réflexe.
- **Périmètre d'usage du code** : front uniquement, back uniquement, partagé.

**Ne pas faire** :

- Demander pour la forme. Si tu peux inférer raisonnablement, infère et annonce ton inférence ("je pars du principe que X — corrige si non").
- Poser un interrogatoire de 15 questions. Pose les 3-5 qui débloquent vraiment la décision en cours.
- Proposer des choix techniques pré-mâchés sans avoir clarifié le métier. L'ordre est : métier d'abord, technique ensuite.
- **Procéder malgré une question non-répondue.** Si tu as posé une question structurante (métier, périmètre, choix non inférable) et qu'elle n'a pas reçu de réponse, tu **ne génères pas** — pas de scaffold, pas de correction, pas de fichier écrit. Annoncer *"je commence, tu me diras après"* viole l'INVARIANT §1. La bonne réaction : ré-énoncer la question, signaler qu'elle bloque, attendre. Si l'utilisateur veut "passer", c'est un signal — pas un go silencieux.

**Forme** : pose tes questions groupées et hiérarchisées (la plus bloquante d'abord), avec ton hypothèse par défaut quand tu en as une. L'utilisateur peut alors valider en bloc plutôt que de répondre à chacune séparément.

---

## 9. Seuils contextuels — tu n'as pas autorité pour les fixer seul

Plusieurs arbitrages dans ce document reposent sur des seuils volontairement non chiffrés : *"horizon court"*, *"logique non triviale"*, *"réellement transverse"*, *"changement concret"*, *"duplication réelle"*. Cette absence de chiffres est délibérée.

**Pourquoi pas de seuils universels** : ces seuils dépendent du projet — taille du codebase, nature du domaine, posture de maintenance, présence d'une roadmap, contraintes business. Un seuil pertinent pour une CLI personnelle de 2k lignes est absurde pour un SaaS multi-tenant de 80k lignes. Inventer des chiffres dans une doc générique reviendrait à substituer un dogme à un autre.

**Ta posture face à un seuil flou** :

1. **INVARIANT — Ne fixe pas de seuil unilatéralement.** Tu n'as pas autorité. Inventer un chiffre "raisonnable" et l'appliquer comme s'il était la règle est une faute, pas une initiative.

2. **Infère depuis les signaux du projet** :
   - Taille du codebase (le doc langage donne la commande de mesure adaptée).
   - Présence d'une roadmap, d'un BACKLOG, d'issues ouvertes.
   - Conventions déjà visibles dans le code existant (si projet en cours).
   - Énoncés de l'utilisateur sur l'évolution attendue, le périmètre, les contraintes.

3. **Demande à l'utilisateur** dès que le seuil influence une décision structurelle (création d'une couche, d'un port, d'un use-case dédié, d'un dossier `shared/`, d'une factorisation). Format : énonce ta lecture, propose 1-2 seuils candidats avec leurs implications, laisse l'utilisateur trancher.

4. **Capture les seuils décidés dans un fichier projet** — pas dans ces docs (qui doivent rester génériques). Convention proposée : `docs/conventions.md` à la racine du projet, qui consigne les seuils projet-spécifiques (ex: *"use-case dédié à partir de 3 deps OU 25 lignes utiles"*, *"port créé seulement si ≥2 implémentations attendues sous 3 mois"*). Ce fichier devient lui-même contexte chargeable pour les sessions futures.

5. **Réfère-toi aux seuils projet** une fois capturés. S'ils n'existent pas encore, retour à l'étape 3 (demander).

**Cas particulier — premier projet de l'utilisateur ou utilisateur explicitement sans préférence** : propose un seuil de départ *contextualisé* (basé sur la taille et la nature du projet observées), annonce-le comme provisoire, et invite à l'inscrire dans `docs/conventions.md` une fois validé à l'usage.

**Ce que cette règle empêche** : l'application mécanique de seuils d'un projet à l'autre, l'illusion d'une norme universelle, le glissement vers le dogme. Ce qu'elle permet : une discipline cohérente *à l'intérieur* d'un projet, une variation justifiée *entre* projets.

## 10. Arbitrage du langage par runtime — INVARIANT

Cette section répond à une question que les sections précédentes ne tranchent pas : *à runtime donné, quel langage retenir ?* Sans règle explicite, le choix dériverait des préférences ad-hoc ou des templates par défaut des outils, ce qui dilue la cohérence d'un projet à l'autre.

**Principe** : à runtime donné, retenir le langage **typé statiquement strict** disponible, sauf signal contraire acté dans `docs/conventions.md` du projet.

| Runtime / contexte | Langage par défaut | Bascule autorisée sur signal |
|---|---|---|
| JS runtime (Node, Bun, Deno, navigateur, Tauri frontend, web/service workers) | **TypeScript strict** (`strict: true`) | JavaScript pur uniquement si lib ESM mono-fichier triviale ou contrainte legacy équipe acté |
| Binaire natif perf-critique, sécurité mémoire, FFI, embarqué, Tauri backend | **Rust** | Go si serveur HTTP+DB pèse plus que la sécurité mémoire ; C/C++ uniquement legacy ou interop précise |
| Serveur HTTP backend "productivité" | **TypeScript** (Node/Bun + Hono/Elysia/Fastify) | Go pour single-binary + perf ; Rust pour sécurité forte ou besoin natif ; PHP/Python sur signal écosystème ou équipe explicite |
| Scripts d'orchestration courts (CI, devops local) | TypeScript si le projet est déjà TS, sinon Bash ou Make | Python si pipeline data ou écosystème déjà en place |
| Pipeline data / ML / scripting scientifique | Python | TypeScript uniquement si le projet est full-TS et le pipeline reste trivial |

**Critère de tri quand plusieurs langages typés sont éligibles** : entre deux candidats équivalents pour le contexte (ex: Go vs Rust pour un serveur HTTP), le choix descend au métier et à l'équipe, jamais au goût isolé du LLM. La règle générique pose le seuil "typage statique strict obligatoire", elle n'arbitre pas entre deux choix qui le satisfont — c'est à l'utilisateur (cf. §8).

**Pourquoi cette règle est INVARIANT** : le but n'est pas de privilégier un langage par esthétique mais de **pousser les erreurs structurelles à la compilation**, là où elles coûtent le moins cher à corriger. JS pur sur un projet non-trivial reporte ces erreurs au runtime, en production, dans le bureau de l'utilisateur. C'est la même logique que la frontière de validation (§5) : faire payer la rigueur en amont pour ne pas la payer en aval, multipliée.

**Bascule acceptable** : le signal doit être un fait concret (équipe en place sur une stack, lib externe sans équivalent, contrainte runtime), pas une préférence. La capture se fait dans `docs/conventions.md` (cf. §9) avec langage retenu, raison, portée.

**Cas particuliers** :

- **Projet de l'utilisateur sans préférence exprimée** : appliquer le default. Le silence n'est pas un signal de bascule.
- **Projet déjà existant dans un langage non-default** : ne propose **pas** la réécriture comme correction. C'est un signal acté de fait par l'existence du projet — capture-le dans `conventions.md` et applique les conventions de ce langage. Réécriture = sujet propre, jamais un lot d'audit (cf. §8).
- **Mix de langages dans un même projet** (cas cloud / monorepo) : chaque couche applique la règle indépendamment. Le mix est sain s'il découle de critères runtime distincts (serveur Go pour single-binary + web TS pour UI = légitime).

**Ce que cette règle empêche** : démarrer un Nuxt en JS pur "pour aller plus vite", choisir un langage par goût personnel en l'absence de signal, contredire silencieusement la SSOT en se basant sur le template par défaut d'un outil. Ce qu'elle permet : un default explicite et défendable, des bascules justifiées et tracées.
