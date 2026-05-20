# Architecture UI

> Traduit la philosophy (`00-philosophy.md`) en idiomes UI **cross-framework** (React, Vue, Svelte). Couvre atomic design, design system, conventions composants et tokens. Charge ce fichier en complément de la philosophy avant toute génération de code UI, et conjointement au doc langage du framework cible (typiquement `typescript.md`).

---

## 1. Préambule

**Statut** : ce doc n'est pas un doc langage à proprement parler — il décrit une **dérivée fonctionnelle** transverse, cible privilégiée du skill `/init-design-system`. Il suit le squelette d'un doc langage (cf. `docs/meta/language.md`) avec adaptations : axes propres au domaine UI substitués aux axes inadaptés.

**Vocation** : poser les invariants et defaults de l'UI quel que soit le framework — la traduction par framework reste dans les skills de bootstrap (`/bootstrap-site-vitrine`, `/bootstrap-app-desktop`…) et le doc langage chargé.

**Public** : LLM qui génère, audite ou refactorise du code UI. Pas un humain qui apprend l'atomic design ou Tailwind.

**Périmètre** :
- **Couvre** : hiérarchie composants (atomic design), conventions de props/slots/variants, tokens et theming, organisation physique d'un design system, frontière UI ↔ domain, accessibilité.
- **Ne couvre pas** : choix du framework (skill), syntaxe d'un framework spécifique (doc langage + skill), routing/SSR/build (skill), animations complexes hors Tailwind (cas par cas).

**Cross-framework** : les exemples de code emploient React par défaut (le plus présent en training data, donc le plus utile comme correcteur de prior). Quand un idiome diverge significativement, la note `→ Vue` / `→ Svelte` donne la forme équivalente. Pour les principes structurants (atomic design, tokens, frontière), aucune divergence : le pattern est universel, seule la syntaxe change.

**Profil de projet visé** : *sustainable solo craft* (cf. philosophy §1). Conséquence concrète : atomic design **comme grille de lecture**, jamais comme cérémonie. Un projet solo n'a pas besoin de 50 atoms — il a besoin des 5-8 qui couvrent son métier. La hiérarchie sert à arbitrer où placer une UI, pas à remplir des cases.

**INVARIANT — mutation du domain depuis l'UI interdite** (cf. philosophy §8, `typescript.md` §10). Reformulé ici pour visibilité : l'UI consomme des données du domain, jamais ne les mute en place. Les transformations passent par les helpers du concept.

---

## 2. Setup minimal

**Styling — Tailwind CSS v4 par défaut** :
- Choix posé et assumé — pas un arbitrage à refaire dans chaque projet.
- Couvre 90% des besoins (layout, spacing, typographie, états, responsive, dark mode).
- **Config CSS-first** : plus de `tailwind.config.{js,ts}`. Les tokens vivent dans un fichier CSS via `@theme` (cf. §4), Tailwind génère les utilities à partir de là.
- **Intégration** : plugin natif selon l'outil — `@tailwindcss/vite` pour Vite (recommandé), `@tailwindcss/postcss` pour les chaînes PostCSS, CLI standalone si pas de build. Engine v4 (Oxide) ~5-10× plus rapide que v3.
- **Import unique** dans la feuille de style racine : `@import "tailwindcss";` (remplace les anciennes directives `@tailwind base/components/utilities`).
- *Exception* : animations complexes / effets visuels avancés (3D, canvas, transitions multi-étapes orchestrées) → CSS dédié ou lib animation (Motion, GSAP). Tailwind reste pour le statique.
- *Exception structurelle* : Vue/Nuxt avec scoped styles si la communauté du projet penche fortement de ce côté — Tailwind reste compatible, c'est un choix à valider.
- *Jamais par défaut* : CSS-in-JS runtime (styled-components, Emotion runtime) — coût bundle et runtime non justifié pour le profil cible. CSS Modules acceptable si Tailwind écarté pour raison concrète.
- *Jamais* : version v3 ou antérieure pour un nouveau projet. Si tu génères du code pour un projet legacy v3, signale explicitement la divergence et propose la migration.

**Variants — `tailwind-variants` ou `cva`** : pour gérer les variantes d'un composant (taille, intent, état). Choix selon framework et lib disponible. Pas de concaténation manuelle de `className` (cf. §11).

**Merge de classes — `cn` / `clsx` + `tailwind-merge`** : helper standard pour combiner classes conditionnelles et résoudre les conflits Tailwind (`p-2` + `p-4` → `p-4`). Un seul helper exporté à la racine du DS (`lib/cn.ts`).

**Variants — pattern `Record<Variant, classes>` par défaut** : une map littérale typée qui projette chaque variant vers ses classes Tailwind. Sans dépendance, types inférés, lisible. Pas de chaînes de `switch/case` ni de helpers `getXxxStyle` cumulés (cf. §13 smells).

```tsx
const VARIANT: Record<ButtonVariant, string> = {
  primary: 'bg-primary text-white hover:bg-primary-deep',
  ghost: 'bg-surface text-fg-2 border border-rule hover:border-rule-2',
  destructive: 'bg-transparent text-error border border-error/40 hover:bg-error/10',
}
```

Bascule vers **`tailwind-variants` (`tv`)** sur signal réel : variants combinatoires avec `compoundVariants` (`primary + disabled = opacity-50` exprimé déclarativement), `slots` pour compound components, ≥3 axes croisés (intent × size × tone). Pas par anticipation — émergence au besoin (philosophy §4).

`clsx` + `tailwind-merge` (déjà dans `cn`) reste la couche d'assemblage : `cn(BASE, VARIANT[variant], SIZE[size], className)`.

**Atelier de composants** : pas de convention forte. Storybook/Histoire si le projet justifie ; pages dédiées `/_dev/components` (ou route équivalente) si volume réduit. À discuter avec l'utilisateur — philosophy §4.

**Validation des props venant d'une frontière** : la lib de validation choisie au niveau langage (Zod en TS) reste la SSOT pour parser ce qui arrive à un composant depuis une frontière externe (URL params, formulaire, API). Les props internes (composant → composant) sont typées, pas re-parsées (cf. §7 et philosophy §5 invariant frontière).

**Encapsulation et alias** : tout le code applicatif dans `src/`. Composants partagés dans `src/components/`. Alias projet : `@/` → `src/` (Vite, configurable) ou `@/src/` → racine (Next courant). À fixer en début de projet, pas à mixer.

**Naming** :
- Composants : `PascalCase` (`Button`, `SearchField`, `Card`).
- Fichiers de composant : `PascalCase.{tsx,vue,svelte}` selon framework.
- Stores / hooks : `camelCase.ts` (`useDrawer.ts`, `imageStore.ts`).
- Helpers utils : `kebab-case.ts` ou `camelCase.ts` selon le langage — voir doc langage.
- Tokens : `kebab-case` dans `@theme` (`primary-deep`, `surface-2`, `rule`) — pas de notation hongroise (`clr-`, `sp-`).
- Props : `camelCase` (`isLoading`, `onSubmit`, `variant`).
- Variants : noms métier-orientés (`intent="danger"`, `size="sm"`), pas implémentation-orientés (`bg="red"`, `px="8"`).

---

## 3. Atomic design — la hiérarchie

**Principe** : organiser les composants par **niveau de composition**, pas par feature. Un atom seul a peu de valeur ; assemblé, il forme une molecule ; assemblées, des organisms ; etc.

**Les trois niveaux universels** :

- **Atom** — primitive non décomposable utile : `Button`, `Input`, `Label`, `Badge`, `Spinner`, `Avatar`, `Switch`, `Tooltip`. Pas de logique métier. Reçoit ses données via props, propage les events. Réutilisable dans n'importe quel contexte.
- **Molecule** — assemblage minimal de 2-3 atoms avec un rôle fonctionnel unitaire : `SearchField` (Input + Button), `FormField` (Label + Input + ErrorMessage), `ImagePreview`. Toujours réutilisable, pas spécifique à un concept métier.
- **Organism** — composition de molecules et/ou atoms portant une **section identifiable** d'UI : `Header`, `Footer`, `DropZone`, `ImageList`, `LoginForm`. Peut être lié à un concept métier (cf. §10 slicing). C'est ici que la cohérence visuelle d'une fonctionnalité se joue.

**Niveaux optionnels — à introduire sur signal réel** :

- **Template** — mise en page sans contenu réel (grille colonne+sidebar, layout dashboard). **Default : pas de niveau template.** Le layout est typiquement porté par le framework (Next `app/layout.tsx`, Nuxt `layouts/`, SvelteKit `+layout.svelte`). *Introduire* `components/templates/` quand : le framework ne porte pas le layout (Vite SPA, Tauri), ou un layout est partagé entre projets dans un DS commun.
- **Page** — instance concrète branchée au routing. **N'existe pas dans `components/`** : vit dans la couche route du framework (`app/`, `pages/`, `routes/`).
- **Brand** — assets identitaires (logo, signature, illustrations de marque). Niveau `components/brand/` quand le projet a une identité visuelle distincte à isoler des atoms génériques.
- **Icons** — sortir les icônes d'`atoms/` quand le volume le justifie (≥ une dizaine d'icônes). `components/icons/` dédié, un fichier par icône ou un `Icon.tsx` paramétré selon préférence.

**Critère de placement** :
- *Réutilisable n'importe où, pas de métier* → atom ou molecule.
- *Réutilisable mais lié à un concept métier* → organism dans le slice du concept (cf. §10).
- *Composition spatiale sans données, framework ne la porte pas* → template (optionnel).
- *Identité de marque, séparation visuelle voulue* → brand (optionnel).
- *Volume d'icônes important* → icons (optionnel).
- *Branche données + layout + organisms* → page (dans la couche route du framework).

**Anti-dogmes** :
- **Pas de quota** : un projet peut vivre avec 5 atoms et 2 organisms — c'est sain si le métier l'exige. Ne pas créer un atom "au cas où" (cf. philosophy §4).
- **Pas de promotion mécanique** : une molecule utilisée une seule fois reste là où elle vit. Promotion vers `ui/` partagé sur signal d'usage réel (≥2 consommateurs), cf. philosophy §6.
- **La hiérarchie est descriptive, pas prescriptive** : un composant qui ne tient pas dans une case n'est pas un bug — c'est probablement un *organism métier* qui appartient à son slice. Force la case = trahit le métier.

```
✗ components/atoms/Button.tsx, components/atoms/UserAvatar.tsx, components/atoms/PriceTag.tsx
  (UserAvatar et PriceTag sont métier — pas des atoms)
✓ components/atoms/Button.tsx
  domain/user/UserAvatar.tsx
  domain/product/PriceTag.tsx
```

**Barrels par niveau** : `components/atoms/index.ts` réexportant les composants du niveau est une convention saine — consommateur écrit `import { Button, Badge } from '@/components/atoms'`. À adopter si plusieurs composants par niveau ; superflu pour 1-2 fichiers.

**Granularité d'un atom** : ce que l'utilisateur final perçoit comme **un seul élément cliquable/lisible**. Une `Card` complète est un organism, son `CardTitle` n'est pas un atom dédié — c'est un élément de la card, modélisé par compound component ou slot (cf. §8).

---

## 4. Tokens et design system

**Principe** : les valeurs visuelles (couleurs, espacements, typographie, rayons, ombres, durées, courbes) ne vivent **jamais en dur** dans un composant. Elles sont nommées une fois (token), référencées partout.

**Deux postures possibles selon contexte projet — à arbitrer explicitement** :

**Posture A — Noms-marque directs** (default pour brand fort, identité visuelle distincte, monothème).

```
@theme {
  --color-marsala: oklch(0.47 0.13 21);
  --color-cream:   oklch(0.95 0.01 61);
  --color-gold:    oklch(0.52 0.12 79);
}

<button class="bg-marsala text-cream">
```

Le token *est* l'identité. Pas de couche sémantique abstraite — la marque est le vocabulaire. Plus lisible (`bg-marsala` ne demande pas de résolution mentale), zéro indirection. Convient aux sites éditoriaux, e-commerce, projets brand-driven.

**Posture B — Tokens sémantiques** (default pour UI tool, dashboard, multi-thème, dark mode natif, white-label).

```
@theme {
  --color-bg:        oklch(0.21 0.02 272);
  --color-surface:   oklch(0.255 0.022 272);
  --color-surface-2: oklch(0.3 0.025 272);
  --color-fg:        oklch(0.97 0.01 272);
  --color-fg-2:      oklch(0.82 0.012 272);
  --color-rule:      oklch(0.32 0.02 272);
  --color-primary:   oklch(0.56 0.08 273);
}

<button class="bg-primary text-fg">
<div class="bg-surface border border-rule">
```

Vocabulaire d'usage (`surface`, `fg`, `rule`, `primary`), pas d'identité couleur. Bascule de thème = redéfinition des sémantiques pour un selector (`.dark`, `[data-theme=…]`). Convient aux outils, IDE-likes, apps avec dark mode obligatoire.

**Critère de bascule A → B** :
- Une des conditions suivantes → posture B : dark mode natif obligatoire, multi-thème (≥2 thèmes au catalogue), white-label / rebrand prévu, palette neutre sans identité distinctive.
- Sinon → posture A.
- *Indécis* → demander à l'utilisateur (cf. philosophy §8), capturer le choix dans `docs/conventions.md`.

**Règle dure transversale** : statuts universels (`success`, `warning`, `error`, `info`) gagnent **toujours** un nom sémantique court (`--color-error`, `text-error`), même en posture A. Sinon `bg-cherry` peut être à la fois la marque et l'erreur — conflit sémantique. Les statuts ne sont pas de la marque.

```
✗ <span className="text-red-500">Erreur</span>  (primitif)
✗ <span className="text-cherry">Erreur</span>   (couleur de marque)
✓ <span className="text-error">Erreur</span>    (sémantique statut)
```

**Implémentation — `@theme` de Tailwind v4 comme SSOT** :

En v4, les tokens **sont** des CSS variables nativement. Tu déclares dans `@theme`, Tailwind émet la CSS variable au runtime *et* génère l'utility associée. Pas de couche d'indirection à maintenir. La déclaration et l'utility sont produites d'un seul jet.

**Theming multi-thème (uniquement posture B)** — l'idiome v4 pour basculer un set de tokens :

```css
@custom-variant dark (&:where(.dark, .dark *));

@layer theme {
  .dark {
    --color-bg:      oklch(0.15 0.02 272);
    --color-surface: oklch(0.19 0.022 272);
    --color-fg:      oklch(0.97 0.01 272);
  }
}
```

La classe `.dark` (ou attribut `data-theme="dark"`) sur `<html>` rebascule les sémantiques. Aucun re-render JS, support natif `prefers-color-scheme` via une media query équivalente si tu préfères l'auto. Inutile en posture A (monothème).

**Échelles à poser** : couleurs (selon posture), espacement (échelle géométrique, pas linéaire), typographie (font-family, font-size, line-height, font-weight), rayons (none → full), ombres (élévation, pas effet), durées et courbes (motion).

**OKLCH plutôt que hex/rgb** : v4 utilise OKLCH par défaut pour la palette interne — gamut plus large (P3), interpolation perceptuelle correcte. Suivre ce default pour les tokens projet, sauf contrainte spécifique (charte fournie en hex à respecter à l'identique).

**Pas de tokens hypothétiques** : on pose les tokens nécessaires aux composants existants ou planifiés (BACKLOG). Pas de palette complète "au cas où" — émerge au besoin (philosophy §4).

**Aliases compat / migration** : si une posture A migre vers B (ou réciproquement), des `--color-old: var(--color-new)` peuvent maintenir la compat le temps de la refonte. Marqués explicitement *Aliases compat (anciens tokens)*, à supprimer une fois la migration finie. Pas d'aliases permanents.

**Référence cross-framework** : `@theme` de Tailwind v4 reste framework-agnostique — c'est du CSS pur. Pour un projet qui exporte ses tokens vers d'autres consommateurs (mobile, Figma), une couche Style Dictionary ou Tokens Studio peut être ajoutée — choix à valider avec l'utilisateur, capture dans `docs/conventions.md`.

---

## 5. Composants : forme par défaut

**Le composant pur** (équivalent UI de la donnée pure côté domain) :
- Reçoit ses données via props.
- Retourne une description d'UI.
- Pas d'état interne hors UI locale (focus, hover, controlled input quand délégué).
- Pas d'effet de bord à l'import ou au render.

**Forme React (default)** :

```tsx
type ButtonVariant = 'primary' | 'ghost' | 'destructive'
type ButtonSize = 'sm' | 'md' | 'lg'

type ButtonProps = React.ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: ButtonVariant
  size?: ButtonSize
  isLoading?: boolean
  children: React.ReactNode
}

const BASE =
  'inline-flex items-center justify-center gap-2 font-semibold transition-colors focus-visible:ring-2 focus-visible:ring-primary disabled:opacity-50 disabled:cursor-not-allowed'

const VARIANT: Record<ButtonVariant, string> = {
  primary: 'bg-primary text-white hover:bg-primary-deep',
  ghost: 'bg-surface text-fg-2 border border-rule hover:border-rule-2',
  destructive: 'bg-transparent text-error border border-error/40 hover:bg-error/10',
}

const SIZE: Record<ButtonSize, string> = {
  sm: 'h-8 px-3 text-sm rounded-md',
  md: 'h-10 px-4 text-base rounded-md',
  lg: 'h-12 px-6 text-lg rounded-md',
}

export function Button({
  variant = 'primary',
  size = 'md',
  isLoading,
  className,
  children,
  ...rest
}: ButtonProps) {
  return (
    <button
      type="button"
      disabled={isLoading || rest.disabled}
      className={cn(BASE, VARIANT[variant], SIZE[size], className)}
      {...rest}
    >
      {isLoading ? <Spinner /> : children}
    </button>
  )
}
```

→ **Vue 3** : `<script setup>` avec `defineProps` typé, `withDefaults` pour defaults.
→ **Svelte 5** : runes (`$props`, `$state` quand stateful) + slots/snippets.

**Trois règles dures** :

1. **Une seule responsabilité visuelle** par composant. Si tu hésites sur le nom, le composant fait probablement trop.
2. **Pas de logique métier dans le composant**. Calcul, dérivation, transformation = helpers du concept (cf. `typescript.md` §2). Le composant orchestre l'affichage, point.
3. **Props nommées par rôle, pas par implémentation**. `<Card padded>` plutôt que `<Card p="16">`. `<Button intent="danger">` plutôt que `<Button color="red">`.

**Variants** : pattern `Record<Variant, classes>` (cf. §2 et §8 pour critère de bascule vers `tv`).

**Composition over props inflation** : quand un composant accumule des props pour gérer des cas variés, basculer vers la composition (children, slots, compound components) — cf. §8.

---

## 6. Composants stateful — équivalent de l'acteur

**Quand un composant tient un état** : input non contrôlé, dialog ouvert/fermé, tooltip visible, formulaire en cours de saisie, sélection multiple, animation en cours. C'est l'équivalent UI de l'**acteur** (philosophy §3) : quelque chose retenu dans le temps.

**Forme par défaut — état local au composant** :

```tsx
export function Disclosure({ title, children }: DisclosureProps) {
  const [isOpen, setIsOpen] = useState(false)
  return (
    <div>
      <button onClick={() => setIsOpen(o => !o)}>{title}</button>
      {isOpen && <div>{children}</div>}
    </div>
  )
}
```

→ **Vue** : `ref(false)` dans `<script setup>`.
→ **Svelte 5** : `let isOpen = $state(false)`.

**Critères pour extraire l'état dans un hook/composable dédié** (cf. philosophy §5, bascule A→B) :
- État partagé entre plusieurs composants (lifting + drilling devient pénible).
- Logique stateful réutilisée (`useDisclosure`, `useDebounce`, `usePagination`).
- Effets de bord coordonnés (focus trap, scroll lock, keyboard handlers).

```tsx
function useDisclosure(initial = false) {
  const [isOpen, setIsOpen] = useState(initial)
  return {
    isOpen,
    open: () => setIsOpen(true),
    close: () => setIsOpen(false),
    toggle: () => setIsOpen(o => !o),
  }
}
```

**INVARIANT — pas de store global pour de l'état d'UI locale**. Un state qui ne traverse qu'un sous-arbre vit dans ce sous-arbre. Le store global (Redux, Zustand, Pinia, Svelte stores partagés) sert à de l'état applicatif partagé large — pas à éviter le passage d'une prop.

**Cleanup obligatoire** : un composant qui ouvre une ressource (event listener global, timer, observer, abort controller) la libère en cleanup. Pas de listener orphelin. La forme dépend du framework (return de `useEffect`, `onUnmounted`, `$effect` cleanup).

```tsx
useEffect(() => {
  const onKey = (e: KeyboardEvent) => { /* ... */ }
  window.addEventListener('keydown', onKey)
  return () => window.removeEventListener('keydown', onKey)
}, [])
```

**Anti-pattern — composant qui dépend du store global pour fonctionner** : un atom ou une molecule ne touche **jamais** au store. Les organisms peuvent, sous réserve qu'on puisse les rendre dans un état "données fournies via props" pour le test/storybook (cf. §11).

---

## 7. Frontières et validation des props

**Frontières externes** où des données arrivent dans l'UI :
- Réponse API (fetch, GraphQL, RPC).
- Paramètres de route / query string.
- Soumission de formulaire (avant envoi au domain).
- LocalStorage / sessionStorage / cookies.
- Messages postMessage / WebSocket.
- Props venant d'un composant tiers / lib non typée.

**INVARIANT** (cf. philosophy §5) : parser à la frontière, truster en interne. Un composant qui reçoit des props d'un autre composant interne ne re-valide pas — TypeScript suffit.

**Pattern de parsing à l'entrée d'une page** :

```tsx
function ProductPage({ params }: { params: { id: string } }) {
  const { data } = useQuery({
    queryKey: ['product', params.id],
    queryFn: async () => {
      const raw = await fetch(`/api/products/${params.id}`).then(r => r.json())
      return ProductSchema.parse(raw) // ← frontière
    },
  })
  if (!data) return <Spinner />
  return <ProductView product={data} /> // ← interne, trusté
}
```

`ProductView` reçoit `product: Product` typé. Pas de re-parse. Si elle hésite à re-valider, la frontière a été ratée en amont (cf. philosophy §5).

**Formulaires — la frontière est la soumission** :

```tsx
function LoginForm({ onSubmit }: { onSubmit: (creds: Credentials) => void }) {
  const handleSubmit = (raw: unknown) => {
    const parsed = CredentialsSchema.safeParse(raw)
    if (!parsed.success) { /* afficher erreurs */ return }
    onSubmit(parsed.data) // ← typé, trusté ensuite
  }
  // ...
}
```

**Anti-pattern — props validées à chaque composant intermédiaire** : si `<ProductView>` reparse et passe à `<ProductHeader>` qui reparse à son tour, c'est une frontière fantôme. Une seule frontière, à l'entrée de la page (ou du sous-arbre stateful).

---

## 8. Variants, composition, slots — idiomes d'arbitrage

**Tension : variants vs composition**

- *Default* : variants (props énumérées) tant que les cas sont fermés et limités (intent, size, état).
- *Bascule vers composition* : quand le contenu interne d'un composant varie structurellement, ou quand le nombre de props explose pour gérer des cas combinatoires.

```tsx
✗ <Card title="..." subtitle="..." footer="..." actions={[...]} image={...} imageAlt="..." />
✓ <Card>
    <Card.Image src="..." alt="..." />
    <Card.Header>
      <Card.Title>...</Card.Title>
      <Card.Subtitle>...</Card.Subtitle>
    </Card.Header>
    <Card.Footer>...</Card.Footer>
  </Card>
```

**Compound components** (React) : exposer les sous-parties via `Card.Header`, `Card.Title`. → **Vue** : slots nommés (`<template #header>`). → **Svelte** : snippets / slots.

**Slot par défaut (children)** : pour le contenu libre. Toujours typer `React.ReactNode` (ou équivalent) — pas `string` ou `JSX.Element` qui sont trop restrictifs.

**Render prop / function-as-child** : autorisé uniquement quand le consommateur a besoin de données du composant parent pour rendre son contenu (`<List items={...}>{item => <Row item={item} />}</List>`). Pas par défaut — `children` simple suffit dans 90% des cas.

**Polymorphic component (`as` prop)** : pattern coûteux en types, à n'introduire qu'avec **plusieurs cas concrets** (`<Button as="a">`, `<Button as={Link}>`). Pas par anticipation. Si un seul cas existe (Button qui est parfois un lien), exposer `<ButtonLink>` séparé est plus lisible.

**Tension : props de style vs variants**

- *Default* : variants nommées par intention (`variant`, `size`, `tone`), implémentées par `Record<Variant, classes>` (cf. §2 et §5).
- *Exception* : un escape hatch `className` autorisé pour cas marginaux non couverts par les variants, mergé via `cn` (`clsx` + `tailwind-merge`). Pas de `style` inline sauf valeurs dynamiques calculées (position absolue dérivée, hauteur dynamique).

```tsx
type ButtonProps = {
  variant?: ButtonVariant
  className?: string // ← escape hatch
}

export function Button({ variant = 'primary', className, ...rest }: ButtonProps) {
  return <button className={cn(BASE, VARIANT[variant], className)} {...rest} />
}
```

**Anti-pattern — props de "primitive Tailwind"** (`px`, `bg`, `mt`) qui se propagent : signe que le composant n'a pas de variants et qu'on essaie de styler de l'extérieur. Refactor en variants métier.

**Tension : `Record<Variant>` vs `tailwind-variants`**

- *Default* : `Record<Variant, classes>` — typage inféré, zéro dépendance, lisible pour 1-2 axes (`variant`, `size`).
- *Bascule vers `tv`* : signal réel — variants combinatoires nécessitant `compoundVariants` (ex: `primary + disabled` → règle dérivée), besoin de `slots` pour compound components, ≥3 axes croisés (`variant × size × tone × density`). Sans signal, `tv` ajoute une dépendance pour rien.
- *Anti-pattern* : chaînes de `switch/case` ou helpers `getXxxStyle(variant, color, disabled)` cumulés. C'est la version moins lisible du `Record`. Refactor.

**Forward ref** : un atom interactif (Button, Input) forward sa ref native pour que le consommateur puisse l'adresser (focus, mesure, intégration lib). Default activé pour les atoms interactifs, optionnel pour molecules/organisms. *Note React 19* : `ref` est une prop standard, `forwardRef` n'est plus nécessaire.

---

## 9. Erreurs et fallback UI

**Distinction reprise de philosophy** :
- **Erreur attendue côté UI** : champ invalide, formulaire incomplet, droit manquant, ressource introuvable, requête échouée par réseau. → Affichée *dans* l'UI (message inline, état d'erreur du composant).
- **Erreur exceptionnelle** : crash JS, exception non gérée, état impossible. → Capturée par un **error boundary** (React/Vue), affichée comme fallback global de zone.

**Forme React — error boundary par zone** :

```tsx
<ErrorBoundary fallback={<ErrorScreen />}>
  <Suspense fallback={<Spinner />}>
    <Dashboard />
  </Suspense>
</ErrorBoundary>
```

→ **Vue 3** : `onErrorCaptured` dans un composant englobant. → **Svelte** : `<svelte:boundary>` (Svelte 5+).

**Granularité** : un error boundary à la racine de l'app *et* un par zone fonctionnelle critique (sidebar, contenu principal, modale). Pas un par composant — c'est inutilisable.

**État de chargement** : Suspense (React/Vue async setup) ou état dérivé (`isLoading`). Le composant qui consomme une donnée async expose **trois états** : loading, error, success. Pas de "blink" entre les deux.

**INVARIANT — pas de toast pour une erreur de formulaire**. Une erreur métier (champ invalide) s'affiche à l'endroit où elle se produit. Les toasts servent aux notifications transverses non bloquantes (sauvegarde réussie, conflit détecté).

**Anti-pattern — catch silencieux dans `onSubmit`** :

```
✗ try { await save() } catch { /* rien */ }
✓ try { await save() } catch (err) { setError(asUserMessage(err)) }
```

---

## 10. Organisation physique — atomic design × slicing vertical

**Le piège** : appliquer atomic design comme un slicing horizontal global (`atoms/`, `molecules/`, `organisms/` à la racine, tout mélangé) reproduit l'anti-pattern de philosophy §6 — les concepts métier éparpillés.

**Le bon mariage** : atomic design pour le **DS transverse** (ce qui n'a pas de métier), slicing vertical par concept pour **les organisms métier**.

```
src/
├── components/                    ← design system transverse (atomic)
│   ├── atoms/                     ← Button, Badge, Input, Spinner, Switch, Tooltip
│   │   └── index.ts               ← barrel optionnel
│   ├── molecules/                 ← FormField, SearchField, ImagePreview
│   ├── organisms/                 ← Header, Footer, DropZone (génériques)
│   ├── templates/                 ← AppLayout — optionnel (cf. §3)
│   ├── brand/                     ← Logo, Signature — optionnel
│   └── icons/                     ← icônes — optionnel si volume
├── domain/
│   ├── image/
│   │   ├── Image.schema.ts        ← Zod SSOT (cf. typescript §2)
│   │   ├── Image.ts               ← type + helpers (ou entity.ts selon convention projet)
│   │   ├── ImageCard.tsx          ← organism métier — vit avec son concept
│   │   ├── ImageGallery.tsx
│   │   └── useImageUpload.ts      ← hook métier
│   └── user/
│       ├── User.schema.ts
│       ├── User.ts
│       └── UserAvatar.tsx         ← organism métier (utilise components/atoms/Avatar)
├── stores/                        ← state global (Zustand) — `store/` singulier accepté
│   ├── useDrawer.ts
│   └── imageStore.ts
├── hooks/                         ← hooks transverses non liés à un concept
│   └── useTranslation.ts
├── lib/                           ← bindings techniques non-métier
│   └── tauri.ts
├── utils/                         ← helpers techniques (cn, formatters, parsers)
│   ├── index.ts                   ← export de cn et helpers transverses
│   └── format-date.ts
└── (routing du framework)         ← app/ (Next), pages/ (Nuxt), routes/ (SvelteKit), App.tsx (SPA)
```

**Critère de placement** :
- *Sans métier, réutilisable n'importe où* → `components/` (atoms, molecules, organisms génériques).
- *Avec métier, lié à un concept* → `domain/<concept>/` (organisms métier, hooks métier, schémas).
- *State global partagé* → `stores/` (Zustand). State stateful local au composant → `useState`/`ref`/`$state` dans le composant (cf. §6).
- *Hook transverse non métier* → `hooks/`. Hook métier → `domain/<concept>/`.
- *Lien à une API technique externe* (Tauri, SDK, client tiers) → `lib/`.
- *Helpers techniques* (`cn`, formatters, parsers utilitaires) → `utils/`.
- *Branche données + layout* → routing du framework (`app/`, `pages/`, `routes/`).

**Promotion** : un organism métier promu vers `components/organisms/` uniquement quand il devient générique (≥2 concepts l'utilisent à l'identique). Sinon il reste dans son slice. Cf. philosophy §6 — un composant à un seul consommateur appartient à ce consommateur.

**Templates** (si présents) : généralement transverses (`components/templates/`). S'ils deviennent métier-spécifiques (`OnboardingLayout` propre à un flow), déménagent dans le slice.

**Pages** : appartiennent au routing du framework, pas au DS. Elles consomment layouts (framework ou `templates/`) et organisms.

**Note convention domain** : la forme exacte des fichiers de concept (`Image.schema.ts` + `Image.ts` vs `schema.ts` + `entity.ts`, présence d'une `Entity` classe avec value objects, etc.) relève du **doc langage** (`typescript.md` §2) et de `docs/conventions.md` du projet. Le doc UI ne tranche pas — il situe seulement *où* le code domain vit relativement au code UI.

---

## 11. Accessibilité — règles dures

**Section spécifique au domaine UI**, sans équivalent dans les docs langage. L'accessibilité n'est pas un nice-to-have — c'est la frontière entre une UI utilisable et une UI cassée pour une partie de ses utilisateurs.

**Niveau minimal — non négociable** (cohérent avec le profil "basiques sécurité/perf toujours", philosophy §1) :

- **Sémantique HTML correcte** : `<button>` pour une action, `<a>` pour une navigation, `<form>` pour un formulaire, `<h1>`–`<h6>` hiérarchiques. Pas de `<div onClick>` sans rôle/tabindex/handler clavier.
- **Label associé à tout input** : `<label htmlFor>` + `id`, ou `aria-label`. Pas de placeholder comme seul label.
- **Focus visible** : ne jamais retirer `:focus-visible` (pas de `outline: none` sans remplacement). Tailwind : `focus-visible:ring-2 focus-visible:ring-action-primary`.
- **Contraste de texte** : tokens de couleur conçus pour respecter WCAG AA (4.5:1 texte normal, 3:1 texte large). Vérifié à l'introduction des tokens, pas après coup.
- **Ordre logique du DOM** : ordre visuel et ordre du DOM concordent (l'ordre de tab reflète l'usage). Pas de reorder CSS aggressif qui casse le tab order.
- **Navigation clavier** : tout composant interactif est accessible au clavier (Enter/Space pour activer, Esc pour fermer, flèches pour naviguer dans une liste sélectable).
- **`aria-*` quand le sémantique HTML ne suffit pas** : `aria-expanded` sur un toggle, `aria-busy` sur un loader, `role="alert"` sur un message d'erreur live, `aria-label` sur un bouton-icône.

**INVARIANT — bouton-icône sans label accessible** :
```
✗ <button><Icon name="trash" /></button>
✓ <button aria-label="Supprimer"><Icon name="trash" /></button>
```

**Composants composés (dialog, menu, listbox, combobox, tabs)** : ne pas réinventer — utiliser une lib headless qui prend en charge l'a11y (Radix, Headless UI, Ariakit, Reka UI selon framework). Le DS habille (style + tokens + variants), la lib porte la mécanique a11y.

**À discuter avec l'utilisateur** : niveau supérieur (WCAG AAA, lecteurs d'écran testés, internationalisation RTL, motion sensitivity `prefers-reduced-motion`) selon le projet. Capture dans `docs/conventions.md`.

---

## 12. Pont domain ↔ UI — rappel

Détails dans `typescript.md` §10 (et équivalents par langage). Rappels invariants côté UI :

- **INVARIANT — mutation du domain depuis l'UI interdite**. L'UI utilise `Image.toProcessing(img)` (helper du concept), jamais `img.status = 'processing'`. Le composant orchestre l'affichage et délègue au domain pour les transformations.
- **Le composant reçoit la donnée typée, retourne un event ou un callback**. Pas de "go fetch yourself" depuis un atom.
- **Hooks métier** (`useImageUpload`, `useUserSession`) vivent **dans le slice du concept**, pas dans `ui/`. Un hook qui touche au domain n'est plus une primitive UI.
- **Store global** consommé uniquement par les organisms et pages, pas par atoms/molecules. Si un atom a besoin de données, elles passent par props. Un atom branché au store global n'est plus réutilisable.

---

## 13. Smells à éviter (référence rapide)

| # | Anti-pattern | À la place |
|---|---|---|
| 1 | Valeur visuelle en dur (`bg-blue-500`, `#fff`, `16px`) dans un composant | Token sémantique (`bg-surface-primary`, `p-md`) |
| 2 | Concaténation manuelle de classes (`${a} ${b ? 'x' : 'y'}`) | `cn(...)` (`clsx` + `tailwind-merge`) |
| 3 | Atom métier (`UserAvatar` dans `ui/atoms/`) | Organism dans `domain/user/` |
| 4 | Composant qui mute le domain (`img.status = …`) | Helper du concept (`Image.toProcessing(img)`) |
| 5 | Atom branché au store global | Props uniquement pour atoms/molecules |
| 6 | Store global pour état d'UI locale (toggle ouvert) | `useState` / `ref` / `$state` local |
| 7 | Props "primitive Tailwind" qui se propagent (`px`, `bg`, `mt`) | Variants métier (`size`, `tone`) |
| 7b | Helpers `switch/case` cumulés (`getVariantStyle`, `getColorStyle`, `getDisabledStyle`) | `Record<Variant, classes>` typé (cf. §5, §8) |
| 7c | `tailwind-variants` / `cva` adoptés sans variants combinatoires ni `slots` | `Record<Variant, classes>` suffit ; `tv` sur signal réel uniquement |
| 7d | Token couleur identitaire (`cherry`) utilisé pour un statut (erreur) | Token sémantique court (`text-error`) — séparer marque et statut (§4) |
| 7e | `forwardRef` ajouté en React 19 | `ref` est une prop standard en R19 — `forwardRef` inutile |
| 8 | Polymorphic `as` prop introduite sans plusieurs cas concrets | Composant dédié (`ButtonLink`) |
| 9 | Bouton-icône sans `aria-label` | `aria-label` obligatoire |
| 10 | `<div onClick>` interactif | `<button>` ou role+tabindex+handler clavier |
| 11 | `outline: none` sur `:focus` sans remplacement | `focus-visible:ring-*` conservé |
| 12 | Placeholder comme seul label de champ | `<label htmlFor>` ou `aria-label` |
| 13 | Re-validation Zod à chaque composant intermédiaire | Une seule frontière (entrée de page/sous-arbre) |
| 14 | Toast pour une erreur de formulaire | Message inline au champ |
| 15 | Composant aux 12 props pour gérer 4 cas combinatoires | Composition (children, slots, compound) |
| 16 | Inline `style` pour valeurs statiques | Classes Tailwind ou variants |
| 17 | Event listener global sans cleanup | Cleanup obligatoire (`return () => …`) |
| 18 | CSS-in-JS runtime (styled-components, Emotion runtime) | Tailwind + variants |
| 19 | Atomic design appliqué globalement à la racine, métier mélangé | Atomic pour `ui/` transverse, slicing vertical pour métier |
| 20 | Headless réinventé pour un dialog/menu/combobox | Lib headless a11y-aware (Radix, Ariakit, Headless UI…) |

---

## 14. Renvois — anti-dilution

- Posture d'arbitrage, filtre fondamental, slicing vertical, INVARIANTS structurels → `00-philosophy.md` §4, §5, §6, §8.
- Forme du composant côté TS, pont domain↔UI détaillé, store global → `typescript.md` §2, §10.
- Choix de framework UI (Astro, Next, Nuxt, SvelteKit, Tauri front) → skills (`/bootstrap-*`), pas ce doc.
- Seuils projet (combien d'atoms avant de promouvoir, granularité d'un organism) → `docs/conventions.md` du projet, jamais ici.
- Tokens spécifiques au projet (palette, échelle d'espacement choisie) → bloc `@theme` du projet + `docs/conventions.md`, pas ce doc.
- Forme exacte des fichiers de concept domain (`Image.entity.ts` vs `entity.ts`, présence d'une classe `Entity` avec value objects) → `typescript.md` §2 + `docs/conventions.md` du projet.
- Posture tokens A (noms-marque) vs B (sémantique) du projet, conventions de variants (`Record` ou `tv`), niveaux atomic optionnels activés (`templates`, `brand`, `icons`) → `docs/conventions.md` du projet.
