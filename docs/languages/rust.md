# Idiomes Rust

> Traduction de `docs/00-philosophy.md` en idiomes Rust. À charger conjointement avec philosophy. Les principes (defaults, exceptions, invariants) vivent dans philosophy — ce doc donne les **formes** Rust.

---

## 1. Préambule

**Vocation** : doc langage pour LLM produisant ou auditant du code Rust dans un projet conforme à philosophy. Pas un tutoriel Rust.

**Sources de vérité** (cf. philosophy §8) : philosophy = principes ; ce doc = formes Rust ; `docs/conventions.md` du projet = seuils contextuels ; utilisateur = métier. Aucun de ces rôles ne se substitue à un autre.

**INVARIANT** — Pas de seuil chiffré inventé dans ce doc (cf. philosophy §9). Les seuils contextuels (taille d'un use-case, nombre de deps qui justifie une bascule, etc.) se capturent dans `docs/conventions.md` du projet, jamais ici.

**INVARIANT** — Interactivité (cf. philosophy §1, §8). Les choix non inférables (modèle d'erreur projet, lib de validation côté frontière, structure d'un concept lourd) se posent à l'utilisateur — pas tranchés par défaut LLM.

**Profil cible** : sustainable solo craft (philosophy §1). Variante "ouvert à contribution" applicable à certains projets — à signaler ponctuellement par l'utilisateur ; elle augmente la surface visible (docs, exemples publics, `CONTRIBUTING.md`) sans bascule enterprise.

**Frontières typiques visées** (oriente axes 5, 7, 10) :
- **Tauri** (frontière prioritaire : domain Rust ↔ frontend JS via commands/events).
- **CLI subprocess** (pattern IPC inter-langage : stdin/stdout JSON, exit codes machine-readable).
- **CLI utilisateur** (interactive ou batch).
- **Backend HTTP** (axum/actix).
- Hors scope : FFI/cdylib, embedded/no_std, WASM. Si un projet sort de ce périmètre, le signaler — ce doc ne le couvre pas.

**Plan** :
- §2-7 : setup, formes fondamentales, concurrence (scindée 8.1/8.2).
- §9-11 : organisation, arbitrages, frontières (scindée 11.1-11.4), smells.

---

## 2. Setup minimal

**Édition** : `edition = "2024"`. MSRV : stable actuelle (1.85+ au moment où ce doc est écrit). Pour un projet existant ou contrainte explicite, MSRV plus basse possible — à inscrire dans `docs/conventions.md`.

**Toolchain** : `rustup`. Un seul `rust-toolchain.toml` à la racine fige la version pour le projet.

```toml
# rust-toolchain.toml
[toolchain]
channel = "stable"
components = ["rustfmt", "clippy"]
```

**Cargo workspace** : par défaut, projet single-crate. Workspace multi-crates dès qu'il y a une vraie séparation de cycle de vie (lib réutilisée + binaire qui la consomme, plusieurs binaires partageant un noyau). Pas par anticipation.

**Lints** : posture dure. À inscrire en haut du `Cargo.toml` (racine ou workspace) :

```toml
[lints.rust]
unsafe_code = "forbid"            # exception : FFI explicite — hors scope ici
missing_debug_implementations = "warn"

[lints.clippy]
all = { level = "warn", priority = -1 }
pedantic = { level = "warn", priority = -1 }
unwrap_used = "deny"              # cf. §6
expect_used = "deny"              # idem ; exception : tests et constantes prouvables
panic = "deny"                    # exception : invariants prouvables à la compilation
todo = "deny"
dbg_macro = "deny"
```

**Formatter** : `rustfmt` avec config par défaut. `rustfmt.toml` minimal — n'ajouter une option que pour résoudre un problème concret.

**Dépendances par défaut** (chacune justifiée, pas réflexe) :
- `serde` + `serde_json` : sérialisation aux frontières.
- `thiserror` : erreurs métier typées (cf. §6).
- `anyhow` : erreurs exceptionnelles, **uniquement dans les binaires** (cf. §6). Jamais dans une lib réutilisée.
- `tokio` : runtime async par défaut (cf. §7). `async-std` est obsolète — ne pas l'utiliser.
- `tracing` + `tracing-subscriber` : logging structuré. `log` (façade) acceptable pour lib simple.

**Validation aux frontières** : pas de lib unique (la communauté n'a pas de SSOT type Zod). **Default assumé** : `serde` désérialise depuis le format brut, puis smart constructors `TryFrom`/`try_new` portent les invariants métier et retournent `Result<Self, ParseError>`. Le type validé devient SSOT (cf. §5). Les libs `validator` et `garde` sont des options pour annotations déclaratives — choix projet à inscrire dans `docs/conventions.md`.

**Conventions de nommage** (suivre RFC 430, ne pas réinventer) :
- Types et traits : `UpperCamelCase`.
- Fonctions, méthodes, variables, modules : `snake_case`.
- Constantes : `SCREAMING_SNAKE_CASE`.
- Fichiers : `snake_case.rs`.
- Préfixes/suffixes interdits : `I` pour traits (`IRepository`), `T` pour types génériques au-delà de `T`/`U`/`E` standard, notation hongroise.

**Convention module** : préférer `mon_module.rs` + dossier `mon_module/` à `mon_module/mod.rs`. Les deux compilent ; la première est l'idiome récent (post-Rust 2018).

**Versioning et dépendances** (cf. `philosophy §11`) :

- **Caret implicite** en Cargo (`x.y.z` est interprété comme `^x.y.z`) — default de l'écosystème, ne pas changer.
- **`Cargo.lock` commité pour les binaires** (apps, services, CLIs, Tauri backend). Pour les libs publiées sur crates.io, conventionnellement **non commité** (le consommateur impose le sien) — à acter dans `docs/conventions.md` du projet selon le profil.
- **CI** : `cargo build --locked` (et `cargo test --locked`). Le lock fait foi, build échoue si le manifeste a divergé sans `cargo update` local préalable.
- **Upgrades manuels** : `cargo outdated` (binaire externe, installé via `cargo install cargo-outdated`) liste ce qui peut bouger. Puis `cargo update` ou `cargo update -p <crate>` pour cibler.
- **`rust-toolchain.toml`** (ci-dessus) : verrouille la toolchain Rust elle-même (canal + composants) — complète le verrouillage des crates.
- **`rust-version`** dans `[package]` : MSRV explicite — utile dès que le projet vise une compat minimale (libs, CI multi-versions). Pour une app solo récente sans contrainte, peut être omis (la toolchain règle déjà la version utilisée).

---

## 3. Forme de la donnée pure (concept du domaine)

**Pattern canonique** : `struct` (ou `enum` si union de variantes), `#[derive(Debug, Clone, PartialEq, ...)]` pour les traits courants, helpers en `impl` bloc dans le **même fichier**. Pas d'orientation OO — un `impl` n'est pas une classe.

**Exemple minimal** (concept `Weight` mesurant un poids corporel) :

```rust
use serde::{Deserialize, Serialize};
use thiserror::Error;

#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
pub struct Weight {
    kg: f64,
}

#[derive(Debug, Error, PartialEq)]
pub enum WeightError {
    #[error("weight must be positive, got {0}")]
    NonPositive(f64),
    #[error("weight {0} exceeds physiological limit")]
    OutOfRange(f64),
}

impl Weight {
    pub fn try_new(kg: f64) -> Result<Self, WeightError> {
        if kg <= 0.0 {
            return Err(WeightError::NonPositive(kg));
        }
        if kg > 700.0 {
            return Err(WeightError::OutOfRange(kg));
        }
        Ok(Self { kg })
    }

    pub fn kg(&self) -> f64 {
        self.kg
    }

    pub fn diff(&self, other: Weight) -> f64 {
        self.kg - other.kg
    }
}
```

**Source de vérité** : le `struct` lui-même est la SSOT. `serde` désérialise vers un type intermédiaire puis `TryFrom` (ou appel explicite à `try_new` côté frontière) porte les invariants. Une déclaration par concept — pas de schéma + type parallèle.

**Variante "donnée brute deserializable" → "donnée validée"** quand la frontière le justifie :

```rust
#[derive(Deserialize)]
pub struct WeightDto {
    pub kg: f64,
}

impl TryFrom<WeightDto> for Weight {
    type Error = WeightError;
    fn try_from(dto: WeightDto) -> Result<Self, Self::Error> {
        Weight::try_new(dto.kg)
    }
}
```

Le DTO est local à la frontière — il vit dans le module qui parse l'entrée externe, pas dans le module du concept.

**Règles dures** :
- Champs privés par défaut, accesseurs explicites quand nécessaire. Pas de `pub` sur les champs d'un type porteur d'invariants.
- Pas de constructeur `pub fn new(...) -> Self` qui bypasse les invariants. Si invariant → `try_new` retournant `Result`. Si trivial → champs publics et pas de constructeur.
- Pas de mutation in-place sur les données du domain partagées entre modules. Méthodes qui transforment retournent un nouveau type (ou `&mut self` réservé aux acteurs, cf. §4).
- Helpers regroupés dans un `impl` bloc dans le **même fichier** que le `struct`. Pas d'`impl` bloc séparé par fichier — c'est la version Rust du namespace déguisé (cf. §11).

**Quand sortir du pattern** :
- Concept trivial : juste le `struct` avec `#[derive(...)]`, pas de `try_new`, pas d'`impl` métier.
- Concept lourd avec état dans le temps → bascule vers acteur (§4).
- Newtype pour brand type : `pub struct UserId(Uuid);` avec `try_new` validateur. Cf. §9 (abstraction nommée).

---

## 4. Forme de la transformation sans état

**Pattern canonique** : `pub fn` libre dans un module. Pas de wrapper.

```rust
// dans src/compression/mod.rs
pub fn compress_image(input: &[u8], quality: u8) -> Result<Vec<u8>, CompressionError> {
    // ...
}
```

**Critère de propriété** (transformation libre vs helper de donnée pure) :
- *Helper de donnée pure* : la fonction est conceptuellement une opération sur **un type** dont le concept est central → `impl` bloc du type (cf. §3).
- *Fonction libre* : la fonction prend plusieurs types non-liés ou transforme entre types → fonction du module.

Exemple : `Weight::diff(&self, other)` est helper. `merge_measurements(a: &[Weight], b: &[Weight]) -> Vec<Weight>` est fonction libre.

**Regroupement** : par module qui correspond au concept domain (cf. §8). Pas de module `utils.rs` ou `helpers.rs` fourre-tout. Si une fonction n'a pas de concept de rattachement clair, c'est un signal qu'elle appartient soit à un concept existant, soit à un nouveau concept à nommer.

**Anti-pattern Rust spécifique** — `impl` bloc sans `self` utilisé comme namespace de fonctions associées :

```rust
// ✗ — pas de self, pas de state, pas d'invariant : c'est un module mal nommé
pub struct PathUtils;
impl PathUtils {
    pub fn normalize(p: &Path) -> PathBuf { /* ... */ }
    pub fn relative(from: &Path, to: &Path) -> PathBuf { /* ... */ }
}
```

```rust
// ✓ — module Rust = namespace natif
// dans src/path/mod.rs
pub fn normalize(p: &Path) -> PathBuf { /* ... */ }
pub fn relative(from: &Path, to: &Path) -> PathBuf { /* ... */ }
```

Renvoi §11 (anti-pattern récurrent).

---

## 5. Forme de l'unité qui tient un état

**Pattern canonique** : `struct` avec champs portant l'état et/ou les dépendances, méthodes via `impl` bloc consommant `&self` ou `&mut self`. Le `struct` est instancié explicitement avec un constructeur `new` (sans `Result` si pas d'invariant de construction ; `try_new -> Result` sinon).

```rust
use std::sync::Arc;
use tokio::sync::Mutex;

pub struct MeasurementService {
    repo: Arc<dyn MeasurementRepo + Send + Sync>,
    cache: Mutex<HashMap<UserId, Vec<Weight>>>,
}

impl MeasurementService {
    pub fn new(repo: Arc<dyn MeasurementRepo + Send + Sync>) -> Self {
        Self { repo, cache: Mutex::new(HashMap::new()) }
    }

    pub async fn record(&self, user: UserId, w: Weight) -> Result<(), ServiceError> {
        // accès au cache + delegation au repo
    }
}
```

**Critères stricts d'introduction d'un acteur** (cf. philosophy §3) :
- Tient un état mutable dans le temps (cache, connexion, progression).
- Reçoit des dépendances injectées à la construction.
- Détient une ressource à libérer (fichier, socket, handle).

Si aucun des trois → ce n'est **pas** un acteur, c'est un module de fonctions libres (§4).

**Instanciation — règle A par défaut** : construction au point d'usage. Dans Tauri : dans `setup` ou via `.manage(...)`. Dans une CLI : dans `main`. Dans un backend HTTP : dans le builder du serveur.

**Bascule A → B vers un composition root** : signaux qui forcent la centralisation — wiring dupliqué entre plusieurs consommateurs, graphe de deps profond, besoin de substitution pour test. Forme minimale : un fichier `src/wiring.rs` ou `src/composition.rs`, instanciations explicites, fonction `build_app(...) -> AppState` exportée. **Pas de framework DI.**

```rust
// src/wiring.rs
pub struct AppState {
    pub measurements: Arc<MeasurementService>,
    pub auth: Arc<AuthService>,
}

pub fn build_app_state(config: &Config) -> Result<AppState, BuildError> {
    let db = SqliteRepo::open(&config.db_path)?;
    let measurements = Arc::new(MeasurementService::new(Arc::new(db)));
    let auth = Arc::new(AuthService::new(/* ... */));
    Ok(AppState { measurements, auth })
}
```

**INVARIANT** — Pas de singleton. Sont prohibés : `lazy_static!` portant un service global, `static MY_SERVICE: OnceCell<...>` exporté, `pub fn instance() -> &'static MyService`. Une instance partagée → composition root + `Arc` passé explicitement.

**Acteur déguisé en namespace** (cf. §4) : un `struct` sans champs avec uniquement des méthodes `&self` ignorant `self` n'est pas un acteur — c'est un module mal nommé. Supprime le `struct`, passe en fonctions libres dans un module.

**Constructeur qui bypass ses propres invariants** (`new` infaillible qui devrait valider) → supprimer le constructeur, revenir à donnée pure (§3) parsée à la frontière (§5 erreurs).

**Visibilité** : champs privés par défaut. `pub` justifié uniquement si le champ est lu en dehors du `impl`. Pour les acteurs, c'est rare — les champs sont des deps internes.

**Lifecycle** : si l'acteur retient une ressource non-RAII (timer custom, tâche tokio spawned détachée), exposer un `shutdown(self) -> Result<(), _>` explicite. Si la ressource est RAII (file handle, connexion DB via une lib qui gère `Drop`), pas besoin de méthode dédiée — `Drop` fait le travail.

---

## 6. Frontières et validation

**INVARIANT** (cf. philosophy §5) — La validation a lieu **une fois**, à la frontière externe. Ce qui circule entre modules internes est déjà parsé et trusté.

**Frontières concrètes en Rust dans le périmètre de ce doc** :
- Commande Tauri (`#[tauri::command]` recevant des args sérialisés depuis JS).
- Stdin / args CLI (clap ou parsing manuel).
- Stdin JSON d'un subprocess.
- Body HTTP (axum extractors, actix `web::Json`).
- Variables d'environnement (`std::env` brut ou via `figment`/`config`).
- Retour d'un client externe (HTTP, DB, autre process) — **le type prétendu par le SDK n'est pas trusté**.
- Désérialisation de fichier (config TOML/JSON/YAML).

**Pattern de parsing à la frontière** — type brut désérialisable + smart constructor :

```rust
// frontière : commande Tauri
#[derive(Deserialize)]
pub struct RecordWeightArgs {
    pub user_id: String,
    pub kg: f64,
}

#[tauri::command]
pub async fn record_weight(
    args: RecordWeightArgs,
    state: tauri::State<'_, AppState>,
) -> Result<(), CommandError> {
    let user = UserId::try_new(&args.user_id)?;     // parse à la frontière
    let weight = Weight::try_new(args.kg)?;         // parse à la frontière
    state.measurements.record(user, weight).await?;  // trusté en interne
    Ok(())
}
```

**Pattern au retour d'un SDK externe** — même un client typé renvoie un type *prétendu*, pas garanti :

```rust
// ✗ — propage un type non vérifié vers le domain
let user: ExternalUser = client.fetch_user(id).await?;
self.repo.insert_external(user).await?;

// ✓ — parse à la frontière
let raw: ExternalUserDto = client.fetch_user(id).await?;
let user: User = User::try_from(raw)?;  // smart constructor porte les invariants
self.repo.insert(user).await?;
```

**Anti-pattern principal** — revalidation interne :

```rust
// ✗ — Weight déjà parsé en amont
pub async fn record(&self, user: UserId, w: Weight) -> Result<(), ServiceError> {
    if w.kg() <= 0.0 {
        return Err(ServiceError::InvalidWeight);
    }
    // ...
}
```

Si tu hésites à revalider en interne, **une frontière a été ratée en amont**. Corrige la frontière, pas le consommateur.

**Brand types via newtype** (philosophy §5 tension 6) : default = primitive nommée. Exception = risque concret de confusion entre deux IDs dans une même fonction.

```rust
// risque concret : signature qui mélange deux IDs primitifs
pub fn transfer(from: Uuid, to: Uuid, amount: u64) { /* ... */ }
//                  ^^^^ swap silencieux possible

// solution : newtype, parsé une fois, plus de confusion
pub struct AccountId(Uuid);
impl AccountId {
    pub fn try_new(s: &str) -> Result<Self, IdError> { /* ... */ }
}
pub fn transfer(from: AccountId, to: AccountId, amount: u64) { /* ... */ }
```

Le passage par `try_new` est **obligatoire** — pas de `AccountId(uuid)` construit hors du smart constructor (champ privé l'empêche).

---

## 7. Erreurs

**Distinction universelle** :
- **Erreur métier attendue** : cas d'échec prévu, dans la signature (`Result<T, E>` avec `E` typé), gérée par le consommateur. Exemple : `WeightError::OutOfRange`, `AuthError::InvalidCredentials`.
- **Erreur exceptionnelle** : bug, état impossible, dépendance morte. Remonte à un handler global. Forme Rust : `panic!` (programmation defensive faillie) ou `anyhow::Error` (chaîne d'erreurs propagée jusqu'à un point central qui log et termine).

Confondre les deux est durable : un échec métier converti en panic perd la possibilité de récupérer ; un bug enveloppé dans un `Result<_, BusinessError>` se fond dans les cas normaux et devient invisible.

**Default communautaire fort** — assumé dans ce doc :
- **Lib** (crate réutilisée) : `thiserror` exclusivement. Une enum d'erreur par module ou par concept, avec variantes explicites. Jamais `anyhow` dans une lib.
- **Bin** (binaire applicatif) : `thiserror` pour erreurs métier remontant depuis le domain ; `anyhow::Error` autorisé **uniquement** au niveau de la couche application (handlers, `main`) pour agréger des erreurs exceptionnelles hétérogènes.

```rust
// erreur métier typée — lib ou domain
#[derive(Debug, Error)]
pub enum MeasurementError {
    #[error("user {0} not found")]
    UserNotFound(UserId),
    #[error("weight validation failed")]
    Weight(#[from] WeightError),
    #[error("storage failure")]
    Storage(#[source] Box<dyn std::error::Error + Send + Sync>),
}
```

```rust
// erreur exceptionnelle agrégée — main / handler global
fn main() -> anyhow::Result<()> {
    let config = Config::load().context("loading config")?;
    let state = build_app_state(&config).context("wiring app state")?;
    run(state)?;
    Ok(())
}
```

**Choix projet** : la frontière exacte entre `thiserror` partout et `thiserror+anyhow` mixte se capture dans `docs/conventions.md`. Variantes acceptables (à confirmer avec l'utilisateur) :
- (a) `thiserror` partout, `anyhow` interdit même dans le bin.
- (b) `thiserror` dans domain et lib, `anyhow` autorisé en `main` et `setup` Tauri uniquement.
- (c) `thiserror` partout sauf scripts/tools où `anyhow` simplifie.

**Anti-patterns** :
- `unwrap()` / `expect()` hors tests ou hors constantes prouvables à la compilation. Si une valeur "ne peut pas être absente", soit l'invariant est prouvé par le type et `unwrap` est légitime sur ce site précis (commenter pourquoi), soit ce n'est pas prouvé et il faut un `Result`.
- `Option<T>` qui mélange "absence légitime" et "échec" — utiliser `Result<Option<T>, E>` ou deux fonctions distinctes.
- `panic!` pour un cas métier (ex: validation utilisateur ratée).
- Erreur sans contexte : `?` qui propage sans `.context("...")` quand l'origine n'est pas explicite à plusieurs niveaux. Utiliser `anyhow::Context` côté bin, `#[source]` / `#[from]` côté lib.
- `catch_unwind` pour avaler un panic — réservé à des cas très spécifiques (FFI hors scope ici, isolation de tâches dans un runtime). En pratique : ne pas l'utiliser.

---

## 8. Concurrence et lifecycle des ressources

### 8.1 Async, runtime, cancellation

**Runtime par défaut** : `tokio`. `async-std` est obsolète. `smol` envisageable pour une CLI minimale single-binary — choix à inscrire dans `docs/conventions.md` si non-tokio.

**INVARIANT** — Pas d'opération async orpheline. Une `JoinHandle` retournée par `tokio::spawn` doit être :
- Stockée dans une struct qui la `await` à `shutdown`, OU
- Liée à un scope (`tokio::task::JoinSet`, `tokio_util::task::TaskTracker`), OU
- Détachée explicitement avec une raison documentée en commentaire (cas rare : tâche fire-and-forget vraiment indépendante).

**Parallélisme idiomatique** pour opérations indépendantes :

```rust
// ✓ — deux requêtes indépendantes en parallèle
let (user, prefs) = tokio::try_join!(
    repo.fetch_user(id),
    repo.fetch_prefs(id),
)?;
```

```rust
// ✗ — sérialisation inutile
let user = repo.fetch_user(id).await?;
let prefs = repo.fetch_prefs(id).await?;
```

**Cancellation** : trois patterns Rust idiomatiques, par ordre de préférence :
1. **Drop natif** : annulation = drop du `Future`. Suffit pour la plupart des cas. Implique de ne pas tenir d'état critique entre deux `.await` sans précaution.
2. **`CancellationToken`** (`tokio_util::sync::CancellationToken`) : token clonable propagé en argument, vérifié via `select!`.
3. **Scope structuré** (`JoinSet`, `TaskTracker`) : annulation = drop du scope.

**Anti-race avec annulation** : quand une opération longue peut être supplantée par une nouvelle (ex: recherche live, requête liée à un input qui change), pattern "vérifier la pertinence avant d'appliquer" :

```rust
// pattern : on annule la précédente avant de lancer la nouvelle
let token = CancellationToken::new();
let previous = std::mem::replace(&mut self.current_search, token.clone());
previous.cancel();

tokio::select! {
    _ = token.cancelled() => {
        // tâche supplantée, sortir sans appliquer le résultat
    }
    result = run_search(query) => {
        self.apply(result);
    }
}
```

**Opérations bloquantes** dans un runtime async : interdites dans une fn `async`. Si nécessaire (parsing CPU-heavy, syscall bloquante sans variante async), `tokio::task::spawn_blocking`.

### 8.2 Ownership, Send/Sync, partage entre tâches

**Règle de partage** : ce qui est passé entre tâches doit être `Send` (et `Sync` si partagé par référence). Le compilateur force déjà cette discipline — la respecter, pas la contourner.

**Partage d'état mutable entre tâches** — pattern par ordre de préférence :
1. **`Arc<T>` immuable** : si la donnée ne mute pas après construction. Cas le plus fréquent et le plus simple.
2. **Message passing** (`tokio::sync::mpsc`, `oneshot`, `broadcast`) : la donnée appartient à un acteur unique, les autres lui envoient des messages. Idiomatique pour les services Tauri qui orchestrent des tâches longues.
3. **`Arc<Mutex<T>>` / `Arc<RwLock<T>>`** (versions tokio pour les locks tenus à travers `.await`, versions std sinon) : à n'utiliser que si message passing serait plus lourd. Lock court, jamais à travers un `.await` lourd.

**INVARIANT** — Pas de `Rc<RefCell<T>>` partagé entre tâches async. `Rc` n'est pas `Send`. Si tu as l'impression d'en avoir besoin pour "porter de l'état partagé", c'est probablement un acteur (§5) déguisé.

**Anti-pattern Rust spécifique** — `Rc<RefCell<T>>` (ou `Arc<Mutex<T>>`) partout comme réflexe pour "porter l'état" :

```rust
// ✗ — réflexe importé d'autres langages
pub struct Counter {
    value: Rc<RefCell<u64>>,
}
impl Counter {
    pub fn incr(&self) { *self.value.borrow_mut() += 1; }
}

// ✓ — &mut self via ownership
pub struct Counter {
    value: u64,
}
impl Counter {
    pub fn incr(&mut self) { self.value += 1; }
}
```

Si plusieurs propriétaires ont *réellement* besoin de muter la même donnée → c'est un acteur (§5) avec `Arc<Mutex<_>>` (ou mieux : un acteur qui owns la donnée + channel mpsc).

**Lifecycle des ressources retenues** par un acteur :
- RAII (le type lib gère son `Drop`) → rien à faire, `Drop` est appelé automatiquement.
- Tâches spawned détachées → `shutdown(self) -> Result<(), _>` qui les `await` proprement (typiquement via `JoinSet` ou `TaskTracker`).

```rust
pub struct BackgroundService {
    tracker: TaskTracker,
    cancel: CancellationToken,
}

impl BackgroundService {
    pub fn new() -> Self {
        Self { tracker: TaskTracker::new(), cancel: CancellationToken::new() }
    }

    pub fn spawn_task<F>(&self, fut: F)
    where F: Future<Output = ()> + Send + 'static {
        let token = self.cancel.clone();
        self.tracker.spawn(async move {
            tokio::select! {
                _ = token.cancelled() => {}
                _ = fut => {}
            }
        });
    }

    pub async fn shutdown(self) {
        self.cancel.cancel();
        self.tracker.close();
        self.tracker.wait().await;
    }
}
```

---

## 9. Organisation physique du code

**Unité physique** : module Rust. Un module = un concept du domaine (philosophy §6). Forme préférée : `mon_concept.rs` + dossier `mon_concept/` pour les sous-modules. La convention `mod.rs` reste valide mais n'est pas préférée.

**Arborescence type** (Tauri + backend HTTP, illustratif) :

```
src/
  main.rs                 # entrée binaire — minimal, délègue à app::run
  wiring.rs               # composition root si nécessaire (cf. §5)
  app.rs                  # bootstrap : load config, build state, run
  app/
    config.rs
  domain/
    measurement.rs        # concept : Weight, MeasurementError, helpers
    measurement/
      repo.rs             # trait MeasurementRepo (port) si justifié (§10)
    user.rs               # concept : UserId, User, helpers
    auth.rs               # concept : Credentials, AuthError, helpers
  infra/                  # implémentations concrètes si swap envisagé (§10)
    sqlite_measurement_repo.rs
  tauri_cmds/             # frontière Tauri — un fichier par groupe de commands
    measurement_cmds.rs
    auth_cmds.rs
  http/                   # frontière backend si applicable
    routes.rs
    handlers/
      measurement.rs
  shared/                 # métier transverse à plusieurs concepts (rare)
    errors.rs
```

**Conventions internes** :
- Un concept = un fichier `concept.rs` à la racine de `domain/`. Sous-modules dans `concept/` si le concept devient lourd (port, sous-types, helpers volumineux).
- Pas de barrel (`pub use ...` réflexe). Réexport uniquement si l'utilisateur du module gagne en lisibilité (ex: `pub use measurement::Weight` dans `domain.rs` pour exposer le type clé).
- `tests/` à la racine du crate : tests d'intégration. Tests unitaires : `#[cfg(test)] mod tests { ... }` **colocalisé** dans le fichier qu'il teste.

**Couches optionnelles** — introduites uniquement sur signal concret (cf. philosophy §5) :
- **`use_cases/` ou `application/`** : créée seulement au premier use-case réel (orchestration de plusieurs deps + appelé depuis plusieurs frontières). Pas par défaut.
- **`infra/`** : séparée seulement si swap d'implémentation envisagé (philosophy §5 tension 3). Sinon, l'implémentation vit dans le module du concept.
- **"Services" horizontaux** : n'existent pas. Soit fonction libre dans le module du concept (§4), soit acteur dans le module du concept (§5).

**`shared/` vs `lib/` (ou `util/`)** :
- `shared/` : métier transverse à plusieurs concepts du domain (ex: type d'erreur partagé, type de tenant). À ne créer qu'avec ≥2 concepts consommateurs réels.
- `util/` ou crate `lib_xxx_util` : utilitaires techniques non-métier (formatage, helpers std étendus). À ne créer que quand le volume justifie.

**Anti-pattern principal** — slicing horizontal :

```
# ✗ — concept Image éparpillé
src/
  entities/
    image.rs
    user.rs
  services/
    image_service.rs
    user_service.rs
  repositories/
    image_repo.rs
    user_repo.rs
```

```
# ✓ — slicing vertical, concept Image cohérent
src/
  domain/
    image.rs            # struct, helpers, erreurs
    image/
      repo.rs           # trait si port justifié
  infra/
    fs_image_repo.rs    # impl concrète, si swap envisagé
```

---

## 10. Idiomes des arbitrages de philosophy §5

Pour chaque tension, la **forme** Rust quand le critère philosophy est rempli. Les critères vivent dans philosophy — ne pas les rejouer ici.

**Repository / port** (philosophy §5 tension 3) :
- *Default (concret)* : pas de trait. Le service tient directement l'implémentation : `pub struct MeasurementService { db: SqlitePool }`.
- *Exception (signal : plusieurs implémentations, mock pour test, swap planifié)* : `trait` + impls. Trait dans `domain/concept/repo.rs`, impls dans `infra/`.

```rust
// domain/measurement/repo.rs
#[async_trait::async_trait]
pub trait MeasurementRepo: Send + Sync {
    async fn record(&self, user: UserId, w: Weight) -> Result<(), RepoError>;
    async fn list(&self, user: UserId) -> Result<Vec<Weight>, RepoError>;
}
```

```rust
// infra/sqlite_measurement_repo.rs
pub struct SqliteMeasurementRepo { pool: SqlitePool }

#[async_trait::async_trait]
impl MeasurementRepo for SqliteMeasurementRepo {
    async fn record(&self, user: UserId, w: Weight) -> Result<(), RepoError> { /* ... */ }
    async fn list(&self, user: UserId) -> Result<Vec<Weight>, RepoError> { /* ... */ }
}
```

Nommage des impls : suffixe par techno (`SqliteMeasurementRepo`, `InMemoryMeasurementRepo`), pas préfixe `I` sur le trait.

**Use-case dédié** (philosophy §5 tension 4) :
- *Default (inline)* : la logique vit dans la frontière (handler Tauri, handler HTTP, fn `main`).
- *Exception (signal : plusieurs entry points partagent l'action, orchestration de plusieurs deps, logique non triviale)* : fonction libre qui prend ses deps en argument. **Pas une struct à une seule méthode.**

```rust
// ✓ — use-case = fonction libre avec deps en arguments
pub async fn import_measurements_from_csv(
    repo: &dyn MeasurementRepo,
    parser: &CsvParser,
    file: &Path,
) -> Result<ImportSummary, ImportError> {
    // orchestration
}
```

```rust
// ✗ — struct cérémonieuse à une méthode
pub struct ImportMeasurementsFromCsvUseCase {
    repo: Arc<dyn MeasurementRepo>,
    parser: Arc<CsvParser>,
}
impl ImportMeasurementsFromCsvUseCase {
    pub async fn execute(&self, file: &Path) -> Result<ImportSummary, ImportError> { /* ... */ }
}
```

**Factory** : presque jamais nécessaire. Le parsing à la frontière (§5) fait le mapping. Cas marginal : `fn create_xxx(deps) -> Xxx` libre, pas struct cérémonieuse.

**Value object / brand type** : default = primitive nommée (`pub struct Weight { kg: f64 }`). Exception (cf. §5) = newtype tuple `pub struct UserId(Uuid)` avec smart constructor.

**Abstraction nommée gratuite** : `type AliasNommé = ...`, `struct Wrapper(T)` quand ça améliore la lisibilité à l'usage. Encouragé. Pas concerné par le filtre du §4 philosophy.

**Anti-pattern adjacent — Builder cérémonieux** :

```rust
// ✗ — 3 champs, pas de validation, builder inutile
ConfigBuilder::new().with_host("...").with_port(8080).with_tls(true).build()

// ✓ — struct literal direct
Config { host: "...".into(), port: 8080, tls: true }
```

Le Builder se justifie pour : nombre élevé de champs optionnels avec defaults non triviaux, validation cross-champs au moment du `build`, types-state pour invariants au compile-time.

---

## 11. Pont domain ↔ frontière

### 11.1 Tauri (frontière prioritaire)

**Pattern de commande** : `#[tauri::command]` async, parse les args à l'entrée, délègue à un acteur dans `tauri::State`, retourne `Result<T, CommandError>` sérialisable.

```rust
#[tauri::command]
pub async fn record_weight(
    args: RecordWeightArgs,
    state: tauri::State<'_, AppState>,
) -> Result<(), CommandError> {
    let user = UserId::try_new(&args.user_id)?;
    let weight = Weight::try_new(args.kg)?;
    state.measurements.record(user, weight).await?;
    Ok(())
}
```

**`CommandError`** : enum `thiserror` distincte de l'erreur domain, qui sérialise vers JS. Implémente `serde::Serialize` manuellement ou via `#[derive(Serialize)]` avec représentation lisible côté JS.

```rust
#[derive(Debug, Error)]
pub enum CommandError {
    #[error("validation: {0}")]
    Validation(String),
    #[error("not found")]
    NotFound,
    #[error("internal error")]
    Internal,  // bug masqué côté JS, loggé côté Rust
}

impl Serialize for CommandError {
    fn serialize<S: serde::Serializer>(&self, ser: S) -> Result<S::Ok, S::Error> {
        // sérialisation contrôlée — pas exposer la chaîne d'erreur interne
        ser.collect_str(&self.to_string())
    }
}
```

**State management** : `app.manage(state)` dans `setup`. `AppState` construit via composition root (§5). Acteurs encapsulés dans `Arc<...>`.

**INVARIANT** — Mutation du domain depuis l'UI : interdite directement. Le JS appelle une commande Rust, qui parse + applique. Pas de "shared state" exposé en lecture-écriture vers JS.

**Events Tauri** : `app.emit_all("measurement-updated", payload)`. Le payload est sérialisé une fois côté Rust, jamais réinterprété en JS comme "donnée du domain mutable".

**Tâches longues côté Tauri** : pattern `spawn` + `emit` pour progression, jamais une commande qui dure (bloque la queue JS).

### 11.2 CLI subprocess (IPC inter-langage)

Pattern distinct : le binaire Rust est consommé par un parent (Node, Python, autre Rust) qui lui envoie des données via stdin et lit le résultat sur stdout. Contraintes :
- **stdin** : un JSON par ligne (NDJSON) ou un JSON unique selon le contrat.
- **stdout** : un JSON par ligne en sortie, jamais de prose mélangée.
- **stderr** : logs humains (debug, trace) — jamais consommé par le parent.
- **exit codes** : `0` succès, codes positifs documentés pour les erreurs métier, `1` ou code dédié pour erreur exceptionnelle.

```rust
fn main() -> ExitCode {
    let stdin = io::stdin().lock();
    for line in stdin.lines() {
        let line = match line {
            Ok(l) => l,
            Err(_) => return ExitCode::from(2),  // erreur exceptionnelle
        };
        match handle_line(&line) {
            Ok(response) => {
                println!("{}", serde_json::to_string(&response).unwrap());
            }
            Err(e) => {
                // erreur métier : code structuré sur stdout
                println!("{}", serde_json::to_string(&error_envelope(&e)).unwrap());
            }
        }
    }
    ExitCode::SUCCESS
}
```

**Contrat JSON explicite** : à inscrire dans `docs/conventions.md` du projet — schéma des messages d'entrée, schéma des messages de sortie, codes d'erreur. Pas inventé par le binaire au coup par coup.

**Logging** : `tracing` avec souscripteur écrivant sur stderr en JSON, ou format humain selon le contrat avec le parent.

### 11.3 CLI utilisateur classique

Pattern : `clap` (derive API par défaut), parsing une fois dans `main`, conversion immédiate en types domain, délégation.

```rust
#[derive(clap::Parser)]
struct Cli {
    #[arg(long)]
    user: String,
    #[arg(long)]
    kg: f64,
}

fn main() -> anyhow::Result<()> {
    let cli = Cli::parse();
    let user = UserId::try_new(&cli.user).context("invalid user id")?;
    let weight = Weight::try_new(cli.kg).context("invalid weight")?;
    // ...
    Ok(())
}
```

Stdout : sortie destinée à l'utilisateur, formatage humain par défaut, option `--json` si lisibilité machine voulue. Stderr : erreurs et logs.

### 11.4 Backend HTTP

Pattern axum (équivalent en actix) : handler async qui extrait via extractors (`Json<Dto>`, `Path<...>`, `State<...>`), parse immédiatement vers types domain, délègue à un acteur, retourne `Result<impl IntoResponse, AppError>`.

```rust
async fn record_weight(
    State(state): State<AppState>,
    Path(user_id): Path<String>,
    Json(dto): Json<RecordWeightDto>,
) -> Result<StatusCode, AppError> {
    let user = UserId::try_new(&user_id)?;
    let weight = Weight::try_new(dto.kg)?;
    state.measurements.record(user, weight).await?;
    Ok(StatusCode::CREATED)
}
```

`AppError` implémente `IntoResponse` pour mapper proprement domain errors → status codes. Jamais de `anyhow::Error` exposé brut sur la frontière HTTP — le client reçoit un code et un message contrôlé.

---

## 12. Smells à éviter (référence rapide)

Index des anti-patterns Rust récurrents. Beaucoup viennent du training data plus ancien que les conventions actuelles.

**`unwrap()` / `expect()` hors tests** — cf. §7. ✗ `let x = parse(s).unwrap();` ✓ `let x = parse(s)?;` ou `let x = parse(s).context("parsing X")?;`.

**`Rc<RefCell<T>>` partagé** — cf. §8.2. Symptôme : état partagé entre tâches async. Solution : `Arc<Mutex<T>>` si vraiment nécessaire, sinon acteur + channel.

**`Box<dyn Trait>` réflexe** — utiliser des génériques quand le trait est monomorphizable. `Box<dyn>` justifié pour : hétérogénéité runtime, réduction du code généré, traits avec des contraintes lourdes.

```rust
// ✗ — réflexe Box<dyn> alors qu'un seul type est utilisé
pub fn process(reader: Box<dyn Read>) { /* ... */ }

// ✓ — générique, monomorphisé
pub fn process<R: Read>(reader: R) { /* ... */ }
```

**`lazy_static!` / `OnceCell` global mutable** — cf. §5. Singleton déguisé. Solution : composition root.

**Trait Builder cérémonieux** — cf. §10. Builder justifié uniquement pour types-state, validation au build, ou nombre élevé de champs optionnels.

**`String` quand `&str` ou `Cow<'_, str>` suffit** à la frontière — allocations inutiles. ✗ `fn check(s: String) -> bool` ✓ `fn check(s: &str) -> bool`. Côté domain, possession (`String`) souvent justifiée — au-delà de la frontière, l'allocation est faite une fois.

**`impl` bloc géant qui simule une classe statique** — cf. §4. ✗ `impl PathUtils { fn ... }`. ✓ module Rust avec fonctions libres.

**Module `services/` à la racine** — slicing horizontal. Cf. §9.

**Tests dans `tests/` au lieu de `#[cfg(test)] mod tests` colocalisé** — pour des tests unitaires liés à un module précis. `tests/` est réservé aux tests d'intégration cross-modules.

**`mod.rs` partout** — convention valide mais ancienne. ✓ `mon_module.rs` + dossier `mon_module/` (cf. §2).

**`failure` crate** — obsolète. ✓ `thiserror` + `anyhow` (cf. §7).

**Factory cérémonieuse autour d'un parsing trivial** — cf. §10. ✗ `WeightFactory::create(kg)`. ✓ `Weight::try_new(kg)`.

**Préfixes/suffixes proscrits** — `IRepository`, `RepositoryImpl`, `TUser`. ✓ `MeasurementRepo` (trait), `SqliteMeasurementRepo` (impl), `User` (type).

**Use-case wrapper trivial** — cf. §10. ✗ `struct GetUserUseCase { repo }` à une méthode. ✓ fonction libre ou inline.

**Couches optionnelles vides "au cas où"** — `application/`, `domain/services/`, `infra/` créés sans concept à y mettre. Cf. §9 et philosophy §4.

**Revalidation interne** — cf. §6. Si tu hésites à revalider, une frontière a été ratée.

---

## 13. Renvois — anti-dilution

- Principes (defaults, exceptions, invariants) → philosophy §4-5.
- Slicing par concept → philosophy §6.
- Trois formes citoyennes → philosophy §3.
- Demander à l'utilisateur → philosophy §8.
- Seuils contextuels → philosophy §9 + `docs/conventions.md` du projet.
- INVARIANTS de ce doc : §2 (pas de seuil chiffré), §5 (pas de singleton), §6 (validation aux frontières une fois), §8.1 (pas d'async orpheline), §8.2 (pas de `Rc<RefCell>` partagé entre tâches), §11.1 (pas de mutation domain depuis UI).
