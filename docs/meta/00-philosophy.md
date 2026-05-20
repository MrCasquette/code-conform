# Méta-philosophie — règles de production et de calibration

> Ce document est le **miroir** de `docs/architecture/00-philosophy.md`. Il ne te dit pas comment coder ou comment arbitrer dans un projet — il te dit **comment doit être écrit le doc philosophy lui-même**, et te donne la grille pour le **calibrer** (vérifier qu'il respecte ses propres règles).

---

## 1. Préambule

**Vocation** : ce méta-doc sert à deux moments distincts :
- **Calibration** d'un doc philosophy existant : appliquer la grille (§7), repérer les écarts, corriger.
- **Cadrage** lors d'une édition substantielle de philosophy : avant de modifier, relire **§2 (contrat de densité), §3 (effet dilution), §5 (attendus structurants)** pour ne pas dériver.

**Public** : LLM (toi) qui édite, audit, ou crée un doc philosophy. Pas un humain qui apprend l'archi.

**Périmètre** : ce doc ne couvre pas les docs langage (`<langage>.md`) — voir `docs/meta/language.md`. Le contrat de densité, l'effet dilution et les smells de doc sont volontairement **dupliqués** entre les deux méta-docs (la vérité doit être présente là où elle est attendue, pas centralisée et diluée).

**Profil de projet visé** : ce méta-doc ne prescrit aucun profil utilisateur particulier — il prescrit qu'**un profil soit posé** dans le doc philosophy audité. Le profil de référence pour ce repo (sustainable solo craft) est posé dans `docs/architecture/00-philosophy.md` §1, pas ici. Pour un philosophy destiné à un autre profil (équipe, MVP, enterprise…), ce méta reste applicable.

**Limite assumée — piège miroir** : ce méta-doc partage par construction les biais cognitifs de l'auteur du doc philosophy qu'il audite (les deux ont été conçus dans la même conversation). Il vérifie ce qu'il sait reconnaître, pas ce qu'il aurait dû exiger. Pour un audit plus exigeant, soumettre le doc audité à un LLM frais — qui n'a écrit ni le philosophy ni ce méta — en lui demandant de produire ses propres sondes à partir du doc audité seul, puis comparer.

---

## 2. Contrat de densité

Quatre règles pour décider quand expliciter, quand renvoyer, quand chiffrer.

- **Règle 1 — Correcteur de prior LLM** → exemple ✗/✓ obligatoire. Sans contre-exemple, le LLM ne reconnaît pas son propre réflexe.
- **Règle 2 — Désambiguisable par renvoi vers une SSOT** → 1 phrase + renvoi. SSOT possibles : autre doc/section de la SSOT documentaire (architecture), `docs/conventions.md` du projet (conventions projet), ou **utilisateur** (métier, ou décision contextuelle non couverte par les docs). Sinon, structure et exemples obligatoires dans ce doc.
- **Règle 3 — Seuil flou** → exemple qualitatif ✗/✓, jamais chiffré. *Exception* : chiffrages techniques sur le LLM lui-même (taille de contexte, longueur cible d'un doc) autorisés — ce ne sont pas des seuils projet.
- **Règle 4 — Justification du default** → ½ ligne max. *Exception* : sur les tensions à arbitrer, les coûts des deux côtés sont fonctionnels (outil d'arbitrage pour les cas non prévus), pas justificatifs.

---

## 3. Effet dilution

Le LLM retient mieux le **début** et la **fin** d'un document. Le milieu peut être noyé. Le risque n'est pas la longueur seule — c'est la **surcharge de règles** qui perd le lecteur.

- Préambule court (≤25 lignes), pas pédagogique.
- Sections numérotées, autonomes (lisibles isolément).
- Règles dures en début de section.
- Aucune section au-delà de ~50-60 lignes sans découpage.
- Renvois croisés explicites (`cf. §X`).
- Récap final autorisé **s'il sert d'anti-dilution du milieu** (pas un résumé esthétique).
- Densité optimale : ~150-300 lignes par doc. Au-delà de ~500 : refonte ou scission.

---

## 4. Smells de doc

Anti-patterns rédactionnels à reconnaître et éviter. Les trois plus pernicieux ont un ✗/✓ explicite (correcteur de prior, cf. §2 règle 1) ; les autres sont des références nominales — leur reconnaissance s'infère du doc audité.

**Dogme déguisé en arbitrage** — *correcteur de prior, exemple obligatoire*

```
✗ "Default : valider aux frontières. Exception : aucune par défaut. Si tu veux faire autrement, justifie."
✓ "Validation aux frontières — invariant. Pas d'exception : ce qui circule en interne est typé et trusté." 
   (présenté explicitement comme invariant, pas comme arbitrage déguisé)
```

**Exemple chiffré sur seuil flou** — *correcteur de prior, exemple obligatoire*

```
✗ "Crée un use-case si la logique dépasse 20 lignes ou orchestre 3 dépendances."
✓ "Crée un use-case si la logique est non triviale (cf. §9 — pose la question à l'utilisateur si le seuil influence la décision ; capture-le dans `docs/conventions.md` du projet)."
```

**Idiome langage qui fuit dans le doc agnostique** — *correcteur de prior, exemple obligatoire*

```
✗ "Forme typique : un schéma + un type dérivé via z.infer + un namespace de helpers."
✓ "Forme typique : une représentation de donnée validée + un groupement de helpers. La forme concrète (schéma+type, struct+derive, struct+tags…) est traitée dans le doc langage."
```

**Autres smells** — index nominal, à reconnaître en lecture :

- Doc monolithique sans plan.
- Redondance non fonctionnelle entre sections.
- Justification en prose qui dilue l'instruction.
- Renvoi vers fichier inexistant ou non nommé.
- Surcharge de règles dans une section unique.
- Conclusion verbeuse non fonctionnelle.

---

## 5. Attendus structurants

> **Parti pris épistémologique** : ces attendus sont formulés comme **propriétés à exhiber** par le doc philosophy, pas comme **contenus à inclure** mot pour mot. Le rédacteur garde la main sur la matière (formulation, exemples, ordre des sections, métaphores) ; ce méta contraint le *comment* (posture, distinctions tenues, propriétés démontrables), pas le *quoi*. Un doc qui exhibe une propriété sous une forme imprévue passe — un doc qui coche les contenus mécaniquement sans les exhiber échoue.

Un doc philosophy doit poser une **posture d'arbitrage** explicite (jamais dogmatique) : chaque règle structurante est exprimée comme un *default* assorti d'un *déclencheur d'exception*. Les règles qui n'admettent pas d'exception par construction sont des **invariants** et doivent être marquées comme telles (cf. §4 smell "dogme déguisé").

Le **vocabulaire** est universel et agnostique de tout langage. Le doc installe un **vocabulaire structurant des unités de code** (formes citoyennes — donnée pure, fonction libre, acteur — ou équivalent) avec un critère de tri lisible.

Un **filtre fondamental** renverse la charge de la preuve sur l'abstraction : par défaut, ne pas abstraire ; abstraire si un besoin observé ou attendu (concret, daté) le justifie.

Les **tensions récurrentes** d'arbitrage sont énoncées avec leurs coûts des deux côtés (outil d'inférence pour les cas non prévus, pas justification décorative).

Le **principe d'organisation par concept métier** (slicing vertical, vocabulaire de l'utilisateur final) est posé.

Une **cartographie de la complexité** est installée : le doc pose explicitement que la structure d'un projet suit où vit la complexité, pas l'inverse. Plusieurs catégories distinctes (au moins 3-4, sans recouvrement) doivent être nommées et opposables, pour que le LLM lecteur puisse diagnostiquer un projet avant de structurer. La liste exacte des catégories est laissée au rédacteur.

Les **trois sources de vérité** sont distinguées explicitement : architecture (docs SSOT), conventions projet (`docs/conventions.md`), métier (utilisateur uniquement — jamais inférence depuis le code, le BACKLOG ou un nom de fichier).

Une **posture interactive** est cadrée : quand demander à l'utilisateur, sur quels sujets (métier ET technique), avec une distinction claire des deux modes opératoires (bootstrap from scratch / audit d'existant).

Une **gestion explicite des seuils flous** est posée : règle dure interdisant au LLM de chiffrer seul + mécanisme de capture nommé (`docs/conventions.md` du projet ou équivalent).

Un **profil de projet visé** est posé en préambule (le doc dit pour qui il est calibré).

---

## 6. Anti-attendus

Un doc philosophy ne contient ni syntaxe ni convention de nommage spécifique à un langage (pas d'extension de fichier, pas de mots-clés réservés). Aucune mention d'une lib particulière (Zod, serde, Drizzle, etc.). Aucune commande shell d'un écosystème (`pnpm`, `cargo`, `find`…).

Aucun chiffrage sur des seuils projet (lignes de code, mois, nombre de dépendances…) — seuls les chiffrages techniques objectifs sur le LLM lui-même (taille de contexte, longueur cible d'un doc) sont autorisés.

Aucun renvoi vers un nom de système ou de produit non défini comme fichier (préférer `ces docs`, `le projet`, ou un nom de fichier explicite).

Aucune liste de patterns à appliquer mécaniquement (DDD, Clean Architecture, etc.). Les patterns ne sont matière du doc qu'à travers les tensions qu'ils résolvent ou créent.

Aucune section *"tests/logging/perf/sécurité obligatoires"* — ces sujets émergent au besoin selon le profil.

**Anti-attendus de posture** :
- **Pas de ton militant** — le doc ne défend pas une école d'architecture contre une autre.
- **Pas de moralisation** — un default a une raison contextuelle, pas une vertu intrinsèque. Pas de *"bonne pratique"* présentée comme telle.
- **Pas de surcharge de prudence** — un invariant n'a pas besoin d'être assorti de garde-fous rhétoriques (*"sauf si exception légitime…"*) ; il est invariant par construction.

---

## 7. Grille d'audit

Vérifie. Cite la section qui répond, ou note l'écart. Cette grille teste des propriétés exhibées par le doc, pas des contenus à comparer mot pour mot avec §5/§6.

**Présence des attendus (cf. §5)**
- [ ] Profil de projet visé posé en préambule.
- [ ] Posture d'arbitrage tenue (chaque règle structurante = default + déclencheur, ou invariant marqué comme tel).
- [ ] Vocabulaire structurant des unités de code défini avec critère de tri.
- [ ] Filtre fondamental posé.
- [ ] Tensions énoncées avec coûts des deux côtés.
- [ ] Principe d'organisation par concept métier.
- [ ] Trois sources de vérité distinguées (architecture/conventions projet/utilisateur).
- [ ] Posture interactive cadrée (métier ET technique, modes bootstrap ET audit).
- [ ] Distinction invariant vs default tenue dans la formulation des règles.
- [ ] Gestion des seuils contextuels + mécanisme de capture nommé.

**Absence des anti-attendus (cf. §6)**
- [ ] Aucune mention de langage, lib, framework, extension de fichier, commande shell (smoke test : `grep -iE 'zod|serde|pydantic|drizzle|directus|\.ts|\.rs|pnpm|cargo'` retourne vide ou justifié — un hit dans un exemple illustratif explicite n'est pas une violation, juger l'intention).
- [ ] Aucun chiffrage sur seuils projet (smoke test : `grep -E '[0-9]+ (mois|lignes|jours|deps)'` vide ou contenu dans un exemple explicitement projet-spécifique).
- [ ] Aucune liste de patterns à appliquer mécaniquement.
- [ ] Aucune section *"tests/logging/perf obligatoires"*.

**Conformité au contrat de densité (cf. §2)**
- [ ] Règle 1 appliquée : anti-patterns/correcteurs de prior ont des exemples ✗/✓.
- [ ] Règle 2 appliquée : renvois explicites vers SSOT au lieu de redire.
- [ ] Règle 3 appliquée : seuils flous illustrés en qualitatif, jamais chiffrés.
- [ ] Règle 4 appliquée : justifications compactes.
- [ ] Pas de redondance non fonctionnelle entre sections.

**Conformité à l'effet dilution (cf. §3)**
- [ ] Préambule ≤25 lignes.
- [ ] Aucune section >50-60 lignes sans découpage.
- [ ] Récap final absent ou intentionnellement anti-dilution.
- [ ] Renvois croisés `cf. §X` présents.

**Smells (cf. §4)** : juger en lecture du doc audité — pas de checklist mécanique ici.

**Sondes complémentaires (jugement requis)**
- [ ] **Test fonctionnel** — un LLM frais lisant le doc audité (sans contexte de sa rédaction) peut-il identifier sans ambiguïté : (a) le profil cible, (b) trois règles dures, (c) la distinction modes bootstrap/audit ? Si non, le doc ne porte pas sa posture.
- [ ] **Auto-test miroir** — pour chaque item de cette grille, demande-toi : *teste-t-il une propriété réelle, ou la conformité à mes intuitions ?* Tout item suspect → requalifier ou enrichir d'un test fonctionnel.
