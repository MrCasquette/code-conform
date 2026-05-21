# Architecture TypeScript

> Traduit la philosophy (`00-philosophy.md`) en idiomes TypeScript concrets. Charge ce fichier en complément de la philosophy avant toute génération de code TS.

---

## 1. Setup minimal

**Runtime / build** :
- ESM only (`"type": "module"`). Pas de CJS.
- Vite / Next.js / Nuxt / Tauri : tous compatibles ESM par défaut.

**Package manager** : Bun ou pnpm — jamais npm/yarn. Le choix dépend du projet :
- **Bun** : DX et perf supérieures, runtime intégré, idéal pour projets modernes et stack contrôlée.
- **pnpm** : pragmatique, compat large sur CI/prod Linux mainstream, plus mature en environnement contraint.
- **Projet open source** : envisager les deux comme acceptables (lockfile + scripts compatibles).

Demande à l'utilisateur si le contexte n'est pas clair.

**TypeScript strict** : base prête pour TS7 (compatible TS6) :

```json
{
  "compilerOptions": {
    "target": "esnext",
    "module": "nodenext",
    "moduleResolution": "nodenext",
    "strict": true,
    "skipLibCheck": true,
    "verbatimModuleSyntax": true,
    "isolatedModules": true,
    "noUncheckedIndexedAccess": true
  }
}
```

`strict: true` couvre les checks essentiels. `noUncheckedIndexedAccess` force le check des accès `tableau[i]` et `objet[k]` — indispensable pour éviter les `undefined` silencieux. `verbatimModuleSyntax` + `isolatedModules` + `nodenext` : posture moderne ESM et compat tooling natif (TS-go, esbuild, Bun, Vite).

Le `tsconfig` exact reste à adapter au framework cible (ajout `paths`, `jsx`, `lib` selon contexte) — la base ci-dessus est le tronc commun.

**Linter / formatter** : **Biome par défaut**.
- Une seule dépendance, une seule config (`biome.json`), ~10-100× plus rapide qu'ESLint+Prettier.
- Couvre 90% des règles d'usage courant.
- *Exception* : projet Vue/Nuxt si tu tiens à `eslint-plugin-vue` finement, ou règle custom non couverte par Biome. Dans ce cas, ESLint flat config + Prettier.

**Encapsulation `src/`** : tout le code applicatif dans `src/`. Configs, scripts, fixtures restent à la racine. Alias `@/` = `src/`. Standard de fait — pas de débat sauf framework qui impose autrement.

**Validation** : **Zod par défaut** pour tout schéma de donnée. Choix posé et assumé — pas un arbitrage à refaire dans chaque projet. Justifications : maturité, écosystème (`z.infer`, `z.brand`, integrations), connaissance LLM partagée, alignement avec le pattern de §2.

*Exceptions* :
- **Eden/Elysia Treaty** (Bun serveur) : validation built-in, schéma Elysia comme SSOT à la place de Zod.
- **Signal projet fort** : migration vers Valibot (bundle size critique), ArkType (perf parsing), Standard Schema (interop multi-libs), ou autre — à valider avec l'utilisateur avant adoption, capture dans `docs/conventions.md` du projet. Ne pas substituer Zod par préférence personnelle ou nouveauté — un signal concret est requis (bundle, perf mesurée, intégration tierce imposée).
- *Jamais* : `yup`, `joi`, `class-validator` ou autres libs antérieures à Zod — choix figés sans bénéfice mesurable.

**Naming** :
- Fichiers de concept : `Concept.ts`, `Concept.schema.ts`, `Concept.repository.ts`, `Concept.<role>.ts` — PascalCase pour le concept.
- Fichiers utilitaires non-concept : `kebab-case.ts` (`format-date.ts`, `parse-csv.ts`).
- Types : `PascalCase`. Schémas Zod : `PascalCaseSchema` (suffixe explicite).
- Fonctions et variables : `camelCase`. Constantes en module top-level : `UPPER_SNAKE` si vraiment constantes (rare).
- Pas de préfixe `I` pour interfaces. Pas de préfixe `T` pour types. Pas de notation hongroise.

**Typage strict — règle dure** :

- `any` : interdit. Toujours.
- `unknown` : autorisé uniquement à la frontière, et **immédiatement réduit** par un parser (Zod) ou un type guard explicite. Pas de `unknown` qui se promène dans le code interne.
- Cast `as X` : interdit par défaut. Sa présence signale une erreur de design — refactoriser. *Exception structurelle* : `as const` — qui n'est pas un type assertion mais une *const assertion*. Il **restreint** le type (le rend `readonly`, préserve les littéraux) et ne ment jamais au compilateur. Un cast `as X` affirme à TS *"crois-moi, c'est X"* ; `as const` dit *"prends ça au sens strict"*. La règle dure interdit l'affirmation, pas la restriction.
- *Dernier recours documenté* : `@ts-expect-error` avec commentaire de justification, uniquement face à une lib tierce mal typée et non remplaçable. Casse l'objectif strict — à n'utiliser qu'après avoir épuisé les alternatives (typer la lib soi-même, wrapper, remplacement). Jamais `@ts-ignore` (silencieux).

L'autorisation des guards sur `unknown` peut être un cheval de Troie pour réintroduire `any` déguisé. Si tu hésites à valider une donnée, **parse-la** (cf. §5 frontières).

---

## 2. Donnée pure : `type` + helpers + Zod SSOT

**Le pattern central** pour modéliser un concept du domaine en TS :

```ts
// domain/image/Image.schema.ts
import { z } from 'zod'

export const ImageSchema = z.object({
  id: z.string(),
  path: z.string(),
  format: z.enum(['png', 'jpg', 'webp']),
  sizeBytes: z.number().int().nonnegative(),
  status: z.enum(['pending', 'processing', 'done', 'error']),
})

// domain/image/Image.ts
import { z } from 'zod'
import { ImageSchema } from './Image.schema'

export type Image = z.infer<typeof ImageSchema>

export const Image = {
  isPending: (img: Image) => img.status === 'pending',
  isDone: (img: Image) => img.status === 'done',

  toProcessing: (img: Image): Image => ({ ...img, status: 'processing' }),
  toDone: (img: Image): Image => ({ ...img, status: 'done' }),
} as const
```

Pattern : **`type` + `const` object literal + `as const` + declaration merging**. `as const` *restreint* (readonly, types littéraux préservés), il ne ment jamais au compilateur. Conforme à la règle "pas de cast" (cf. §1) — un cast `as X` affirme, `as const` restreint. Compatible TS6 et TS7-proof, tree-shaking-friendly.

**Trois règles dures** :

1. **Le schéma Zod est la SSOT** (Single Source of Truth). Le type s'en déduit via `z.infer`. Jamais l'inverse — pas de type écrit à la main puis "validé" par un schéma Zod aligné manuellement.
2. **Pas d'`interface Props` parallèle au schéma**. C'est la duplication classique : `interface ImageProps { ... }` + `ImageSchema` qui décrivent la même chose. Supprimer l'interface, garder le schéma.
3. **Pas de wrapper class autour du type**. `class Image { constructor(props) { } }` qui ne fait que stocker les props et exposer des getters est une anti-forme. Le type + les helpers du namespace suffisent.

**Pourquoi le pattern declaration merging** : permet d'utiliser `Image` comme type *et* comme conteneur de helpers, dans un import unique. Le type et le const partagent le même nom — TS gère la fusion sans ambiguïté.

```ts
import { Image } from '@/domain/image/Image'

const img: Image = ImageSchema.parse(raw)
if (Image.isPending(img)) {
  const next: Image = Image.toProcessing(img)
}
```

Une seule ligne d'import, lecture naturelle.

**Quand sortir du pattern** :
- Si le concept est trivial (juste un type sans aucun helper), garde juste le type. Pas de const object vide.
- Si le concept devient un acteur (état d'instance, deps injectées), passe à class (cf. §4).
- Si le concept porte des invariants forts qu'on veut imposer à la construction (ex: `Email` avec validation au constructeur), le schéma Zod fait le travail au parsing — pas besoin de class avec constructeur privé.

**Helpers : fonctions pures, jamais de mutation** :

```ts
// ✓ retourne une nouvelle valeur
export const toProcessing = (img: Image): Image => ({ ...img, status: 'processing' })

// ✗ mute l'argument
export const toProcessing = (img: Image): void => { img.status = 'processing' }
```

Le type `Image` est une donnée pure : on transforme, on ne mute pas. La mutation appartient à l'acteur (§4) ou au store UI (§10).

---

## 3. Fonction libre

**Default pour toute transformation sans état ni dépendance injectée.** Une fonction exportée. Pas de wrapper.

```ts
// domain/compression/resolveParams.ts
const QualityMap = { low: 60, medium: 80, high: 95 } as const

export type CompressionPreset = 'low' | 'medium' | 'high'
export type CompressionParams = { quality: number; format: 'png' | 'jpg' | 'webp' }

export function resolveCompressionParams(
  preset: CompressionPreset,
  format: CompressionParams['format'],
): CompressionParams {
  return { quality: QualityMap[preset], format }
}
```

Pas de `class CompressionService { resolveParams() {} }`. Pas de `export const compressionService = { resolveParams }`. Une fonction nommée suffit.

**Quand grouper en const object** (déclaration merging similaire à §2) :

Si tu as plusieurs fonctions liées au même thème *qui ne portent pas de donnée centrale* (sinon elles iraient dans le const du type concerné), un regroupement nominal aide la lisibilité :

```ts
// domain/compression/Compression.ts
export const Compression = {
  resolveParams: (preset: CompressionPreset, format: Format): CompressionParams => { ... },
  estimateSize: (img: Image, params: CompressionParams): number => { ... },
  isSupported: (format: string): format is Format => { ... },
} as const
```

Critère : plusieurs fonctions cohérentes sur un thème, importées souvent ensemble (seuil exact à capturer dans `docs/conventions.md` du projet — cf. `philosophy §9`). Sinon → fonctions exportées séparément.

**Anti-pattern** : `class CompressionService { static resolveParams() { ... } }`. Une class composée uniquement de méthodes statiques est un const object déguisé. Voir §11.

### Modules de domaine — namespace au point d'import (default)

Pour un concept domain (`Page`, `Booking`, `Block`), exporte les fonctions verbe seul côté module et consomme-les avec un namespace **au point d'import** :

```ts
// domain/booking/booking.repository.ts
export async function findAll(): Promise<Booking[]> { ... }
export async function findByRange(start: Date, end: Date): Promise<Booking[]> { ... }
export async function create(input: BookingInput): Promise<Booking> { ... }

// au consommateur
import * as Booking from '@/domain/booking/booking.repository'
const all = await Booking.findAll()
const booking = await Booking.create({ ... })
```

Pourquoi cette forme :

- **Forme native du langage** (cf. `philosophy §3`). Distinct d'une classe statique : pas de `this`, pas de `new`, tree-shaking préservé.
- **Concept métier explicite au call site** (`Booking.create` vs `createBooking`). Cohérent avec slicing vertical par concept (cf. `philosophy §6`).
- **Flexibilité** : le consommateur peut faire `import { findAll }` ponctuellement quand utile (par exemple pour un usage unique au sein d'un module qui consomme déjà 80% des fonctions d'un autre namespace).
- **Pas de re-export technique** : pas de `export * as Booking from './booking.repository'` côté module — légal mais marginal, et empêche les imports sélectifs.

**Default** : verbe seul exporté + `import * as Concept` côté consommateur.

**Bascule possible** (à acter dans `docs/conventions.md` projet, cf. `philosophy §9`) : préfixe verbe + concept (`findHomePage`, `createBooking`) si tu exposes les modules comme **API publique consommée par LLMs ou code généré** (le consommateur n'a pas la connaissance de la structure namespace), ou si tu veux **grepabilité maximale** sur le concept (chaque appel contient le mot complet du concept).

### Convention de verbes — repositories et helpers de persistance

Sémantique stricte, indépendante du choix d'organisation ci-dessus :

- `find*` → `T | null` ou `T | undefined`. La recherche peut échouer, retour nullable explicite. Le consommateur **doit** gérer le cas absent.
- `get*` → `T`. Throw si absent — pour invariants stricts (l'absence est un bug, pas un cas attendu). Rare en repository, fréquent côté config/registry.
- `list*` ou `findAll*` → `T[]`. Collection, peut être vide (`[]`), jamais `null`.
- `create`, `update`, `delete`, `upsert` → mutations CRUD. Retournent typiquement l'entité affectée ou `void` selon contexte.
- `count*` → `number`.

Cette distinction `find` vs `get` est précieuse : `findById(id)` te force à gérer le `null`, `getById(id)` exprime une garantie d'existence. **Pas de mélange dans un même module** — un repository qui mélange `findUser` qui throw et `getOrder` qui retourne null est un bug en germe (les conventions de retour deviennent imprédictibles).

Ne s'applique pas qu'aux repositories : tout helper qui interroge un état lointain (cache, store, API tierce) suit la même convention.

**Distinguer fonction libre et helper de donnée pure** :

- Une fonction qui **opère sur un type du domaine** comme premier argument va dans le const du type (`Image.toProcessing(img)`).
- Une fonction qui **n'a pas de type "central"** (transformation libre, calcul, parsing utilitaire) reste libre, exportée seule ou regroupée par thème.

Le critère est *qui possède la fonction ?* — si un type spécifique la "possède" naturellement, elle vit dans son const ; sinon, elle est libre.

---

## 4. Acteur (`class`)

**Quand utiliser une class** : et seulement quand l'objet *tient quelque chose dans le temps*.

- État d'instance qui évolue (timer, cache, progression, listeners, connexion ouverte).
- ET/OU dépendances injectées à la construction (client DB, client HTTP, bus d'événements).

```ts
// domain/progress/AdaptiveProgress.ts
type Listener = (value: number) => void

export class AdaptiveProgress {
  private current = 0
  private timeoutId: number | null = null
  private listeners: Listener[] = []

  constructor(private readonly stepMs: number) {}

  start(): void {
    const tick = () => {
      this.current = Math.min(85, this.current + 1)
      this.listeners.forEach((l) => l(this.current))
      this.timeoutId = window.setTimeout(tick, this.stepMs)
    }
    tick()
  }

  complete(): void {
    if (this.timeoutId) window.clearTimeout(this.timeoutId)
    this.current = 100
    this.listeners.forEach((l) => l(100))
  }

  onChange(listener: Listener): void {
    this.listeners.push(listener)
  }
}
```

**Instanciation — règle A par défaut** : au point d'usage. Le consommateur (composable, hook, route, action) construit son instance avec les deps qu'il a sous la main. Pas de composition root préventif.

```ts
// usage direct, là où on en a besoin
const progress = new AdaptiveProgress(50)
progress.onChange((v) => console.log(v))
progress.start()
```

**Bascule A → B — STOP et migrer vers un composition root dès qu'un de ces signaux apparaît** :

> Si tu te retrouves à instancier la même class avec le même wiring dans **plusieurs consommateurs**, ne reproduis pas le wiring une fois de plus. Crée `src/composition.ts`, instancie une fois, exporte les instances configurées. Les autres consommateurs importent depuis là.

Signaux déclencheurs :

1. **Wiring dupliqué** : le même `new XxxClass(deps...)` apparaît dans ≥2 consommateurs. C'est le signal le plus fréquent et le plus visible — il bascule à lui seul.
2. **Ressource partagée à protéger** : connexion DB unique, cache stateful global, pool de connexions.
3. **Graphe de deps profond** qui rend la construction au point d'usage illisible (`A` prend `B` qui prend `C`…) — seuil exact à capturer dans `docs/conventions.md` du projet si besoin.
4. **Tests qui doivent substituer un service** (rare avec posture tests-au-besoin, mais signal valide).

Tant qu'aucun de ces signaux n'est présent, A suffit et reste plus lisible. Un seul signal suffit à basculer — n'attends pas que plusieurs s'accumulent.

**Composition root minimal** :

```ts
// src/composition.ts
import { DirectusClient } from '@/infrastructure/directus'
import { PageRepository } from '@/domain/page/Page.repository'

const directus = new DirectusClient({ url: process.env.DIRECTUS_URL! })

export const pageRepo = new PageRepository(directus)
// ... autres instances configurées
```

Pas de framework DI. Pas de container. Un fichier, des `new` explicites, des exports nommés.

**Jamais : singleton exporté** :

```ts
// ✗ INTERDIT
export const progressService = new AdaptiveProgress(50)
```

Le terme "singleton" couvre ici le pattern *export d'instance pré-construite* **et** le pattern POO classique (`getInstance()`). Les deux sont à proscrire pour la même raison : mocking impossible, exécution à l'import (effets de bord), risque de cycles d'import. Si une instance doit être partagée, elle vit dans le composition root, pas dans le fichier de définition.

**Anti-patterns adjacents** — détaillés en §11 (smells) :
- Class full-static (= const object déguisé).
- Constructeur privé contourné par `Object.create()` (= la class n'aurait pas dû exister, repli sur donnée pure §2).

**Visibilité** : `private`/`readonly` sur les champs internes par défaut. Une class qui expose tous ses champs en `public` est probablement une donnée pure mal nommée.

---

## 5. Frontières et validation

**Principe** : on parse une fois, à la frontière. Après, on fait confiance au type.

**Qu'est-ce qu'une frontière** :

- Entrée d'API HTTP (route handler, server action, endpoint).
- Soumission de formulaire utilisateur.
- Lecture d'un fichier (CSV, JSON, source utilisateur).
- Retour d'un client externe (SDK Directus, fetch tiers, base de données sans typage propre).
- Message reçu d'un canal (WebSocket, IPC Tauri, postMessage).

Tout ce qui entre depuis l'extérieur du code TS est *non typé* — peu importe ce que prétend le type inféré du SDK. À l'opposé, ce qui circule entre deux modules internes est déjà parsé et typé : pas besoin de revalider.

**Pattern à la frontière** :

```ts
// app/api/images/route.ts
import { ImageSchema } from '@/domain/image/Image.schema'

export async function POST(req: Request) {
  const raw = await req.json()
  const image = ImageSchema.parse(raw)  // ← frontière. Trust après.

  // ici `image` est typé Image, on n'y revient pas.
  await imageRepository.save(image)
  return Response.json({ ok: true })
}
```

**Pattern au retour d'un SDK externe** :

```ts
// domain/page/Page.repository.ts
import { directus } from '@/infrastructure/directus'
import { PageSchema } from './Page.schema'

export async function findPageBySlug(slug: string) {
  const raw = await directus.request(readItems('pages', { filter: { slug } }))
  return PageSchema.array().parse(raw)
}
```

Le SDK Directus *prétend* renvoyer un type — on ne lui fait pas confiance. Le parsing Zod est la frontière réelle.

**Pas de revalidation en interne** :

```ts
// ✗ inutile : `image` est déjà parsé en amont
function compress(image: Image) {
  ImageSchema.parse(image)  // bruit, double coût, redondant
  ...
}
```

Si tu te retrouves à revalider une donnée qui circule entre deux fonctions internes, le problème est ailleurs : soit la frontière n'est pas parsée correctement en amont, soit le type ne reflète pas la réalité.

**Cas Eden / Elysia Treaty (Bun)** : la validation est built-in côté serveur. Pas besoin d'un schéma Zod parallèle — utiliser le schéma Elysia comme SSOT et inférer le type depuis lui. Même posture qu'avec Zod (frontière unique, trust après), outil différent.

**Brand types — `z.brand`, jamais `as`** :

Default : un `string` ou `number` avec un nom de champ explicite (`userId: string`) suffit. Le brand type n'apparaît que sur signal concret : risque de confusion entre deux IDs/valeurs du même type primitif dans une même fonction.

```ts
// ✓ dérivé du schéma — pas de cast
export const UserIdSchema = z.string().uuid().brand<'UserId'>()
export type UserId = z.infer<typeof UserIdSchema>

// ✗ INTERDIT
const id = rawString as UserId
```

Le brand passe **toujours** par le parsing Zod. Aucun `as` n'est acceptable, même pour un brand.

---

## 6. Erreurs

Choix structurel non tranché par défaut dans cette doc — il dépend du projet (taille, criticité, type d'entry, conventions existantes). Tu n'as **pas autorité** pour imposer un pattern d'erreur seul ; tu poses le vocabulaire, tu lis les signaux du projet, tu demandes à l'utilisateur si besoin (cf. `philosophy §9`).

**Distinguer deux familles d'erreurs**, *toujours* :

- **Erreur métier attendue** : un cas d'échec prévu par le domaine (utilisateur introuvable, mot de passe invalide, quota dépassé, validation Zod échouée à la frontière). Doit être *explicite dans la signature* du producteur, gérée par le consommateur.
- **Erreur exceptionnelle** : bug, panic, état impossible, dépendance indisponible, contrat rompu. N'a pas vocation à être gérée par le caller — remonte jusqu'à un handler global (route, server action, error boundary).

Confondre les deux est la première source de bugs : un `throw` silencieux d'erreur métier crée des chemins d'exécution invisibles ; un `Result<T, E>` enveloppant un bug noie l'anomalie réelle dans du code de gestion.

**Options TS courantes** (à choisir selon le projet, pas par défaut) :

| Option | Erreur métier | Erreur exceptionnelle | Coût |
|---|---|---|---|
| **A — `throw` partout + classes d'erreur** | `throw new UserNotFoundError(...)` | `throw new Error(...)` | Erreur invisible dans la signature ; discipline de doc/types nécessaire pour que le caller sache quoi catch |
| **B — `Result<T, E>` (lib type [neverthrow](https://github.com/supermacro/neverthrow))** | `Result<User, UserNotFoundError>` | `throw` | Verbeux, casse le flow async/await sans helper, ajoute une dep |
| **C — Union discriminée maison** | `User \| { kind: 'not-found' } \| { kind: 'invalid-input', reason: string }` | `throw` | Lisible, sans dep, force le `switch` exhaustif côté caller ; discipline de nommage |
| **D — `T \| Error` (instance native Error)** | `User \| UserNotFoundError` (`instanceof Error`) | `throw` | Léger, sans dep, vérification via `instanceof` ; moins explicite que C sur la nature de l'erreur |

**Default contextuel proposé** (à valider avec l'utilisateur projet par projet, pas appliqué d'office) :

- Routes HTTP / server actions : `throw` + handler global (option A) — le framework gère.
- Logique métier interne avec ≥2 cas d'erreur distincts à gérer : union discriminée (option C) — explicite et exhaustif.
- Logique métier avec un seul cas d'échec : `T | null` ou `T | undefined` selon la sémantique (absence légitime).
- Bug, état impossible, dépendance morte : toujours `throw` (peu importe l'option choisie pour les erreurs métier).

**Ta posture face à un projet sans convention d'erreur établie** :

1. Lis le code existant : repère le pattern dominant. S'il y en a un cohérent, suis-le.
2. Si rien d'établi ou patterns mélangés : énonce la grille A/B/C/D avec leurs trade-offs, propose un default contextuel basé sur le profil du projet, **demande à l'utilisateur** de trancher.
3. Capture le pattern décidé dans `docs/conventions.md` du projet (cf. `philosophy §9`) — formulation type : *"Erreurs métier attendues : union discriminée. Erreurs exceptionnelles : throw. Frontières HTTP : handler global qui re-throw avec status."*
4. À partir de là, applique strictement le pattern décidé.

**Anti-patterns transverses, quel que soit le pattern choisi** :

- `try/catch` qui avale silencieusement (`catch (e) { /* nothing */ }` ou `catch (e) { console.log(e) }` sans relancer).
- `throw new Error('erreur')` sans contexte (message, cause, données pertinentes).
- Erreur métier déguisée en `null`/`undefined` retourné sans distinction du cas "absence légitime" vs "échec".
- Validation Zod dont le `.parse()` est wrappé dans un `try/catch` qui retourne `null` — perte de l'information d'erreur.

---

## 7. Concurrence et lifecycle async

Pour un cycle de vie projet long (cf. `philosophy §1` profil sustainable solo craft), les bugs qui survivent 3 ans sont rarement des bugs de logique — ce sont des **races, des promesses non attendues, des AbortController oubliés**. Cette section pose les règles dures qui les évitent.

### Promesses : pas de promesse orpheline

Toute Promise créée doit avoir un destin tracé : `await` explicite, ou `.then/.catch` complet, ou attachée à un store/runtime qui la gère. Une promesse sans destinataire est une bombe à retardement (erreur silencieuse, race invisible).

```ts
// ✗ promesse orpheline — l'erreur disparaît
function startSync() {
  fetchData().then(updateStore)  // pas d'await, pas de catch
}

// ✓ destin tracé
async function startSync() {
  try {
    const data = await fetchData()
    updateStore(data)
  } catch (e) {
    // gestion explicite cf. §6
  }
}
```

### Parallélisme : `Promise.all` quand indépendant, séquentiel quand dépendant

Boucler avec `await` série une opération parallélisable = perte de perf pour rien.

```ts
// ✗ séquentiel inutile
for (const id of ids) {
  const item = await fetchItem(id)
  results.push(item)
}

// ✓ parallèle quand indépendant
const results = await Promise.all(ids.map(fetchItem))
```

`Promise.allSettled` quand un échec ne doit pas annuler les autres. `Promise.all` quand un échec doit court-circuiter.

### Annulation : `AbortController` obligatoire dès qu'un acteur lance une opération annulable

Un acteur (§4) qui lance une opération asynchrone (fetch, timer, listener, stream) **doit** exposer un moyen d'annuler. Sinon : memory leak, callbacks sur composant démonté, requêtes périmées qui écrasent l'état actuel.

```ts
// ✗ aucune annulation — fuit si le consommateur disparaît
export class DataLoader {
  async load(url: string) {
    const res = await fetch(url)
    this.data = await res.json()
  }
}

// ✓ AbortController propagé
export class DataLoader {
  private controller: AbortController | null = null

  async load(url: string) {
    this.controller?.abort()
    this.controller = new AbortController()
    const res = await fetch(url, { signal: this.controller.signal })
    this.data = await res.json()
  }

  dispose() {
    this.controller?.abort()
  }
}
```

### Race conditions : éviter la mise à jour stale

Si deux opérations async peuvent terminer dans un ordre indéterminé et toucher le même état, la dernière qui termine n'est pas forcément la plus récente.

```ts
// ✗ race — search('ab') peut écraser le résultat de search('abc') si lent
async function search(query: string) {
  const results = await api.search(query)
  store.setResults(results)
}

// ✓ vérification de pertinence avant écriture
let latestQuery = ''
async function search(query: string) {
  latestQuery = query
  const results = await api.search(query)
  if (latestQuery === query) store.setResults(results)
}
```

`AbortController` (cf. ci-dessus) annule la requête précédente — souvent plus propre que la vérification post-hoc.

### Lifecycle d'acteur async : `dispose()` obligatoire si ressources retenues

Un acteur qui retient des ressources async (timer, listener, abonnement, connexion ouverte) doit exposer une méthode de libération. Le consommateur (hook, composable, point d'entrée) appelle `dispose()` au démontage.

```ts
// ✓ acteur disposable
export class AdaptiveProgress {
  private timeoutId: number | null = null

  start() { this.timeoutId = window.setTimeout(...) }
  dispose() { if (this.timeoutId) clearTimeout(this.timeoutId) }
}

// usage React
useEffect(() => {
  const p = new AdaptiveProgress()
  p.start()
  return () => p.dispose()
}, [])
```

Pas de standard imposé sur le nom (`dispose`, `cleanup`, `destroy`, `close`) — convention locale, capturée dans `docs/conventions.md` du projet si besoin.

---

## 8. Organisation des dossiers

> Les notions de *"réellement transverse"* (`shared/`) et *"justifiée"* (couche `infrastructure/`) reposent sur des seuils contextuels — voir `philosophy §9`.

**Slicing vertical par concept** (rappel philosophy §6) — un dossier = un concept, pas un type technique.

```
src/
  domain/
    image/
      Image.ts             ← type + const helpers
      Image.schema.ts      ← schéma Zod
      Image.repository.ts  ← persistance, si justifiée
    entry/
      Entry.ts
      Entry.schema.ts
    shared/                ← uniquement le réellement transverse
  app/                     ← Next.js routes / pages selon framework
  hooks/ | composables/    ← UI stateful (cf. §10)
  lib/                     ← utilitaires non-domain (formatters, fetch wrapper...)
  infrastructure/          ← clients externes (directus, db, tauri bridge)
```

**Conventions de nommage de fichiers** :

- `Concept.ts` — type + const helpers (donnée pure, §2). PascalCase pour le concept.
- `Concept.schema.ts` — schéma Zod, exporté en `ConceptSchema`.
- `Concept.repository.ts` — persistance. Class si deps injectées, fonctions exportées sinon.
- `Concept.<role>.ts` — ajouts au besoin (`Concept.parser.ts`, `Concept.deduplicator.ts`).
- `index.ts` — barrel export *uniquement* si plusieurs fichiers du concept doivent être ré-exportés ensemble. Pas de barrel par défaut.

**Couches optionnelles, à n'introduire que sur signal** :

- `application/` (use-cases) : à ne créer qu'à partir du **premier vrai use-case** (cf. §9). Avant ça, n'existe pas.
- `infrastructure/` : à ne séparer du `domain/` que si plusieurs implémentations coexistent (CSV + DB) OU si le swap est concrètement envisagé. Sinon, le client externe vit dans le repository du concept (`Page.repository.ts` qui appelle directement le SDK).
- `services/` (au sens couche horizontale) : **n'existe pas** dans cette architecture. Ce qui ressemblerait à un "service" est soit une fonction libre (§3), soit un acteur (§4) qui vit dans le dossier de son concept.

**Anti-pattern — slicing horizontal** :

```
✗ src/
  schemas/      ← tous les schémas mélangés
  services/     ← tous les services mélangés
  repositories/ ← toutes les persistances
  utils/        ← tout ce qui ne rentre pas ailleurs
```

Un concept éparpillé sur 4 dossiers, navigation cognitive coûteuse, cohésion conceptuelle perdue. Pas ici.

**`shared/`** : strictement le code utilisé par ≥2 concepts du domaine (types primitifs partagés, helpers d'erreur, utilitaires de date). Si un fichier `shared/X.ts` n'a qu'un consommateur, il appartient à ce consommateur.

**`lib/` vs `shared/`** : `shared/` est *intra-domain* (du métier transverse), `lib/` est *non-domain* (formatters, wrappers techniques, helpers de framework).

---

## 9. Patterns TS pour les arbitrages

Cette section donne les **idiomes TS** des arbitrages décrits dans `philosophy §5`. Les critères de bascule (Default / Exception / signaux déclencheurs) vivent là-bas — ne sont pas répétés ici. Cette section répond uniquement à *"comment écris-je ça en TS quand le critère est rempli ?"*.

**Repository — fonctions par défaut, class si deps injectées**

```ts
// fonctions exportées (default)
import { directus } from '@/infrastructure/directus'
export async function findPageBySlug(slug: string) { ... }
export async function savePage(page: Page) { ... }

// class si deps réelles à la construction
export class PageRepository {
  constructor(private readonly client: DirectusClient) {}
  async findBySlug(slug: string) { ... }
}
```

Jamais `class XxxRepository { static method() {} }` — une class purement statique est un module de fonctions déguisé (cf. §3, §11).

**Use-case dédié — fonction qui prend ses deps en argument**

```ts
// application/use-cases/getLatestMeasurement.ts
export async function getLatestMeasurement(deps: { entryRepo: EntryRepo }) {
  ...
}
```

Pas de `class GetLatestMeasurementUseCase { execute() {} }` à une seule méthode — c'est de la cérémonie. Une fonction nommée suffit.

**Port — `type` de signature, pas `interface IRepo`**

```ts
export type EntryRepository = {
  findInRange: (from: Date, to: Date) => Promise<Entry[]>
  add: (entry: Entry) => Promise<void>
}
```

Pas de préfixe `I`. Implémentations suffixées par techno : `EntryRepositoryDirectus`, `EntryRepositoryInMemory`.

**Factory — presque jamais en TS**

Le parsing Zod *est* le mapping (`Schema.parse(raw)` retourne un type valide). Une Factory qui appelle juste `Schema.parse()` est inutile — appelle Zod directement dans le repository ou le consommateur. Une Factory class avec `private constructor` + `static create()` qui ne fait que construire est de la cérémonie pure (cf. §11).

Cas marginal où une factory survit : assemblage non trivial de deps pour un acteur (§4). Forme : fonction `createXxx(deps)`, pas une class.

**Value Object — non, par défaut**

Pas de `class Title { constructor(value: string) {} getValue() {} }`. Un `string` ou `number` avec nom de champ explicite (`title: string`, `weightKg: number`) suffit. Si confusion réelle entre deux IDs/valeurs primitives → brand type via Zod (cf. §5), jamais wrapper class.

---

## 10. Pont domain ↔ UI

**Forme** : un hook React, un composable Vue, une server action Next sont **toujours** écrits comme des fonctions exportées. Jamais de class.

**Sémantique** : ce sont des fonctions libres particulières — elles peuvent contenir de l'état (`useState`, `ref`), des effets (`useEffect`, `watch`), et utiliser d'autres hooks/composables. Mais l'état n'est **pas** porté par elles : il est délégué au runtime du framework (React reconciliation, Vue reactivity).

**Règle de traduction domain → UI** :

Là où le domain expose une class acteur (§4), l'UI consomme cette class **dans un hook ou composable**, qui prend en charge le cycle de vie React/Vue.

```ts
// hook React qui utilise l'acteur AdaptiveProgress du domain
import { useEffect, useRef, useState } from 'react'
import { AdaptiveProgress } from '@/domain/progress/AdaptiveProgress'

export function useAdaptiveProgress(stepMs: number) {
  const instance = useRef<AdaptiveProgress | null>(null)
  const [progress, setProgress] = useState(0)

  useEffect(() => {
    instance.current = new AdaptiveProgress(stepMs)
    instance.current.onChange(setProgress)
    return () => instance.current?.complete()
  }, [stepMs])

  return {
    progress,
    start: () => instance.current?.start(),
    complete: () => instance.current?.complete(),
  }
}
```

L'acteur du domain garde son rôle (logique pure, testable hors React). Le hook lui donne un *cycle de vie React* sans que le domain ne dépende de React.

**Composable Vue — équivalent direct** : `useXxx()` retourne des `ref`/`reactive` et expose les actions. Même pattern, runtime différent.

**Server action Next / route handler** : forme = fonction exportée. À l'intérieur, c'est de la fonction libre qui orchestre — le pattern frontière (§5) y est central (parser l'entrée, trust ensuite). Use-case (§9) extrait *uniquement* si signal présent.

**Stores (Zustand, Pinia, Redux)** : un store est lui-même un *acteur orchestrateur*, mais porté par le framework. Forme : fonction `create(...)` qui retourne le store. À l'intérieur, on peut composer directement avec les fonctions/repositories du domain ; un use-case dédié n'est pas nécessaire si le store est l'unique consommateur.

```ts
// store qui orchestre — pas de use-case en plus
export const useImageStore = create<ImageStore>((set, get) => ({
  images: [],
  async load() {
    const raw = await imageRepository.findAll()
    set({ images: raw })
  },
  async compress(id: string) {
    const img = get().images.find((i) => i.id === id)
    if (!img) return
    const next = Image.toProcessing(img)
    set({ images: get().images.map((i) => (i.id === id ? next : i)) })
    await compressionService.compress(next)
  },
}))
```

Le store *est* la couche application pour ce flux — pas besoin d'un `compressImageUseCase` parallèle.

**Mutation interdite des données du domain** : un store peut muter *son propre état* (c'est son rôle), mais **jamais** un objet provenant du domain. Les transformations passent toujours par les helpers du concept (`Image.toProcessing(img)`), qui retournent une nouvelle valeur.

```ts
// ✗ INTERDIT — mutation directe d'un objet domain
set((state) => {
  state.images[0].status = 'done'
})

// ✗ INTERDIT — assignation directe d'un champ
const img = get().images[0]
img.status = 'done'

// ✓ — transformation via helper, état immuable
set((state) => ({
  images: state.images.map((i) =>
    i.id === id ? Image.toDone(i) : i
  ),
}))
```

Cette règle s'applique à tout consommateur du domain (hook, composable, server action, route), pas seulement aux stores. Le domain expose des helpers de transformation, jamais de surface mutable.

**Composants** : sortent du périmètre v1 de cette doc (UI/design system → itération suivante). Règle minimale d'ici là : la logique ne vit pas dans le composant — elle est extraite dans un hook/composable, qui appelle le domain.

---

## 11. Smells à éviter

Anti-patterns récurrents et le pattern correct en regard. Si tu en repères un dans du code existant ou si tu es sur le point d'en générer un, **stop**.

**Class wrapper de primitive**
```ts
// ✗
class Title { constructor(private value: string) {} getValue() { return this.value } }
// ✓
type Title = string  // ou champ nommé `title: string` dans le type parent
```

**Class full-static (namespace déguisé)**
```ts
// ✗
class PageRepository {
  static async findBySlug(slug: string) { ... }
  static async save(page: Page) { ... }
}

// ✓ — verbe seul exporté, namespace au point d'import (cf. §3)
// page.repository.ts
export async function findBySlug(slug: string): Promise<Page | null> { ... }
export async function save(page: Page): Promise<Page> { ... }

// au consommateur
import * as Page from '@/domain/page/page.repository'
const page = await Page.findBySlug(slug)
```

**Singleton exporté en bas de fichier de class**
```ts
// ✗
class CompressionService { ... }
export const compressionService = new CompressionService()
// ✓
export class CompressionService { ... }
// instanciation au point d'usage : new CompressionService(deps)
```

**Factory class pour `Schema.parse()`**
```ts
// ✗
class ColorFactory {
  static create(raw: unknown): Color {
    return new Color(ColorSchema.parse(raw))
  }
}
// ✓
const color = ColorSchema.parse(raw)
```

**Constructor privé contourné par `Object.create()`**
```ts
// ✗
class Page {
  private constructor(public props: PageProps) {}
}
function pageFromRaw(raw: unknown): Page {
  const page = Object.create(Page.prototype)
  page.props = PageSchema.parse(raw)
  return page
}
// ✓ — la donnée pure suffit
type Page = z.infer<typeof PageSchema>
const page: Page = PageSchema.parse(raw)
```

**Préfixe `I` sur interface, `T` sur type**
```ts
// ✗
interface IUserRepository { ... }
class UserRepository implements IUserRepository { ... }
// ✓
type UserRepository = { ... }  // si port justifié
class UserRepositoryDirectus implements UserRepository { ... }  // suffixé par techno
```

**Use-case wrapper de 3 lignes**
```ts
// ✗
export class GetUserUseCase {
  constructor(private repo: UserRepo) {}
  execute(id: string) { return this.repo.findById(id) }
}
// ✓ — appel direct
const user = await userRepo.findById(id)
```

**Slicing horizontal dans `src/`**
```
✗ src/schemas/, src/services/, src/repositories/, src/utils/
✓ src/domain/<concept>/<concept>.{ts,schema.ts,repository.ts}
```

**Cast `as` pour échapper au type**
```ts
// ✗
const user = rawData as User
// ✓
const user = UserSchema.parse(rawData)
```

**Revalidation interne d'un type déjà parsé**
```ts
// ✗
function process(image: Image) {
  ImageSchema.parse(image)  // déjà parsé en amont
  ...
}
// ✓
function process(image: Image) { ... }  // trust le type
```

**Couches `application/` ou `infrastructure/` créées vides "au cas où"**
- Si pas de use-case réel → pas de `application/`.
- Si une seule implémentation → pas de séparation `infrastructure/`. Le repository concret vit dans le dossier du concept.
