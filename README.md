# code-conform

> Source de vérité documentaire + skills opérationnels pour qu'un LLM (Claude Code typiquement) **conforme** le code aux conventions de l'auteur — pas à sa moyenne d'entraînement.

---

## L'idée en une minute

Un LLM peut écrire du code qui marche sans difficulté. Le problème n'est pas là. Le problème est que **ce code ressemble à la moyenne du training set**, pas à ton projet. Sur un cycle long (3+ ans, dev solo, refactor libre), cette dérive coûte cher : maintenance impossible, dette architecturale invisible, perte de contrôle progressive.

`code-conform` pose deux choses :

1. **Une SSOT documentaire** (`docs/`) — invariants racines (`00-philosophy.md`), idiomes par langage (`languages/`), conventions design UI (`design/`). Le LLM la charge en contexte avant chaque génération ou audit.
2. **Des skills opérationnels** (`skills/`) — couples `bootstrap-*` (créer un projet conforme) et `audit-*` (mesurer un projet existant vs la SSOT, proposer des corrections par lot validées).

Le nom dit la fonction : **conformer** le code, à l'init comme à l'audit, à un référentiel cohérent (structure + conventions + logique).

---

## Principes structurants

- **Posture par arbitrages, pas par dogmes** — chaque règle a un *default* + un *déclencheur d'exception*, ou est marquée **INVARIANT** explicite.
- **Profil ciblé : *sustainable solo craft*** — dev solo, cycle long, pas de pression business immédiate. Ni MVP jetable, ni système enterprise.
- **Interactivité obligatoire** — le LLM demande à l'utilisateur sur les choix non inférables (métier, contraintes projet, arbitrages techniques contextuels). Il ne devine pas (cf. `docs/00-philosophy.md` §1, INVARIANT).
- **Pas de docs par lib/framework** — les opinions framework-spécifiques vivent dans les skills par contexte (`bootstrap-site-vitrine`, `bootstrap-app-desktop`…), pas dans des `react.md` / `next.md` qui dériveraient. Les SSOT couvrent les langages et axes transverses (UI, contrats…).

---

## Public

- **`docs/`** est destiné au **LLM**. Ton factuel, dense, actionnable. Pas de pédagogie.
- **`README.md`, `RATIONALE.md`, `BACKLOG.md`** sont pour l'**humain** (toi, moi, collaborateurs).
- **`SKILL.md` dans chaque skill** est lu par le LLM mais reste lisible pour humain (audit possible).

---

## Structure du repo

```
code-conform/
├── README.md                      ← ce fichier (humain)
├── RATIONALE.md                   ← justifications des choix (humain + LLM)
├── BACKLOG.md                     ← état des décisions, roadmap, itérations
├── install.sh                     ← installe docs/ et skills/ dans le home
├── docs/
│   ├── 00-philosophy.md           ← invariants racines, point d'entrée SSOT
│   ├── languages/                 ← idiomes par langage
│   │   ├── typescript.md
│   │   └── rust.md
│   ├── design/                    ← archi UI (+ futur brand-design.md)
│   │   └── atomic-design.md       ← atomic design, tokens structure, composants, a11y
│   └── meta/                      ← règles de production/calibration de la SSOT
└── skills/
    ├── bootstrap-site-vitrine/    ← Astro 5 + React 19 + Tailwind v4
    ├── audit-site-vitrine/
    ├── bootstrap-app-desktop/     ← Tauri 2 + Vite + React 19
    ├── audit-app-desktop/
    ├── bootstrap-cloud/           ← projet multi-couches selfhostable (v0.1 ébauche)
    └── audit-cloud/
```

> **À venir** : skill `/design-system` (direction artistique, brand, palette identitaire, typo character) + doc compagnon `brand-design.md`. Le scope actuel des bootstrap/audit reste **strictement architectural** côté UI — le design pur est délégué.

---

## Installation

`code-conform` n'est pas un package npm/cargo distribué. Tu clones le repo où tu veux, puis lances `./install.sh` qui pose les artefacts dans des chemins canoniques du home.

### Installation initiale

```bash
git clone <url>          # clone où tu veux
cd code-conform
./install.sh
```

Le script auto-détecte sa propre localisation — tu peux cloner le repo n'importe où, même le déplacer après installation (en mode copie, default). Aucune dépendance à un path fixé en dur.

Ce que ça pose :

- `docs/` → `~/.code-conform/docs/` (chemin canonique référencé par les skills).
- `skills/<name>/` → `~/.claude/skills/<name>/` (un dossier par skill — n'écrase pas tes autres skills Claude Code).

**Default = copie** : résilient. Après installation, le repo source peut bouger, être renommé ou supprimé sans casser quoi que ce soit. Un fichier sentinelle `.installed-by-code-conform` est posé dans chaque dossier installé pour reconnaître nos artefacts lors d'updates.

### Mise à jour

```bash
cd <ton/path/vers/code-conform>
git pull           # ou édits locaux
./install.sh       # re-copie, écrase nos installations via la sentinelle
```

Pas besoin de `--force` pour les updates normales — la sentinelle détecte que c'est notre install et écrase proprement.

**Ce que le script touche / ne touche pas** :
- Le script itère **uniquement** sur les skills présents dans le repo (`audit-*`, `bootstrap-*`). Tes autres skills dans `~/.claude/skills/` portent d'autres noms et ne sont **jamais inspectés ni modifiés**.
- Seul cas où un dossier tiers serait sauvegardé : si un skill à toi porte exactement le même nom qu'un des nôtres. Sans la sentinelle, il serait alors préservé en `.bak.<timestamp>` avant qu'on pose le nôtre. Rare par collision fortuite — mais **systématique si tu synchronises `~/.claude/skills/` par un autre mécanisme** (dotfiles, rsync, sauvegarde) : les noms coïncident alors par construction, et chaque réinstallation empile un `.bak`. Dans ce cas, `install.sh` fait autorité sur les skills du repo — garde les copies externes en lecture seule.

### Modes alternatifs

```bash
./install.sh --link       # symlinks (mode dev — édits du repo suivis sans re-run)
./install.sh --force      # force la copie même sans sentinelle (override explicite)
./install.sh --uninstall  # retire ce qui a été posé
./install.sh --help       # détails complets
```

Le mode `--link` est pratique si tu **itères** sur la SSOT ou les skills — chaque édit dans le repo est visible à la prochaine session Claude Code, sans re-run. Mais : si tu déplaces ou supprimes le repo, les liens cassent. Garde-le pour le dev.

### Sur une nouvelle machine

```bash
git clone <url>
cd code-conform && ./install.sh
```

Deux lignes. Aucune dépendance autre que `bash` et `git`. Le seul prérequis est d'avoir Claude Code installé pour utiliser les skills (`~/.claude/skills/` doit exister ou être créable).

---

## Usage

### Démarrer un nouveau projet

Dans une session Claude Code ouverte dans un dossier vide :

```
/bootstrap-site-vitrine     # Astro 5, multi-pages, peu de JS
/bootstrap-app-desktop      # Tauri 2 + Vite + React 19
/bootstrap-cloud            # projet multi-couches selfhostable (v0.1 ébauche)
```

Le skill pose des questions de cadrage (métier, contraintes), charge la SSOT pertinente, génère un squelette conforme et capture les décisions dans `docs/conventions.md` à la racine du projet généré.

### Auditer un projet existant

Dans une session Claude Code ouverte dans le projet à auditer :

```
/audit-site-vitrine
/audit-app-desktop
/audit-cloud
```

Le skill cartographie le projet, applique la grille d'audit, restitue un rapport structuré (écarts majeurs / mineurs / conforme), puis propose des corrections **par lot avec validation utilisateur**. INVARIANT : aucune modification de fichier sans accord explicite.

### Posture des skills

Tous les skills sont **opinionés** sur leur framework par défaut, mais **acceptent le challenge** : si tu as un signal réel pour utiliser autre chose (équipe Symfony, contrainte client, écosystème existant), tu le dis, le LLM capture dans `docs/conventions.md` et adapte. La SSOT ne se substitue pas à ta connaissance du métier.

---

## Lien optionnel avec `~/.claude/CLAUDE.md`

> **`install.sh` ne touche jamais à `~/.claude/CLAUDE.md`.** Cette section décrit une possibilité d'intégration manuelle, à activer ou non selon ta préférence — ce n'est ni une recommandation, ni une étape d'installation.

Tu peux choisir d'ajouter une ligne dans ton `CLAUDE.md` global pour signaler la SSOT au LLM en dehors des invocations de skills :

```markdown
SSOT architecture (si pertinente) : `~/.code-conform/docs/` — philosophy à la racine, langages dans `languages/`, design UI dans `design/`.
```

Trade-off à arbitrer toi-même :

- **Avec mention dans `CLAUDE.md`** : à chaque session, le LLM est conscient que la SSOT existe et la consulte opportunistement quand une décision architecturale se présente. Léger surcoût en attention (pas en tokens si bien formulé).
- **Sans mention** : la SSOT est uniquement chargée à l'invocation explicite d'un skill (`/bootstrap-*`, `/audit-*`). Plus stricte sur le périmètre, le LLM ignore la SSOT hors de ce cadre.

Aucun des deux modes n'est meilleur dans l'absolu — ça dépend si tu veux que tes conventions s'appliquent à toutes tes sessions Claude Code ou uniquement aux sessions explicitement "conformantes".

---

## Maintenance

Projet personnel, pas de processus formel de contribution. Évolutions :

1. Édits dans le repo source.
2. Audit croisé optionnel par LLM neutre (cf. `RATIONALE.md` pour le process éprouvé en v0.1).
3. Validation à l'usage réel (les vraies frictions émergent en sessions de bootstrap/audit, pas en relecture à blanc).
4. Re-installation : `./install.sh`.

`BACKLOG.md` trace les décisions actées, les itérations en cours et les SSOT manquantes.

---

## Pour aller plus loin

- **`RATIONALE.md`** — pourquoi les choix structurels ont été faits ainsi (process de design, alternatives écartées).
- **`docs/00-philosophy.md`** — la racine de la SSOT, point d'entrée du système. Tous les skills la chargent.
- **`BACKLOG.md`** — état actuel, ce qui reste à faire, SSOT manquantes (notamment `go.md` et `contracts.md` pour débloquer pleinement `/audit-cloud`).

---

## Licence et partage

Personnel, à usage libre. Si tu réutilises ou forkes, garde l'esprit du projet : un référentiel **opinionable** plutôt que prescriptif universel. Les conventions ici reflètent un profil *solo craft long-cycle* — adapte-les à ton contexte avant de les imposer mécaniquement à un autre.
