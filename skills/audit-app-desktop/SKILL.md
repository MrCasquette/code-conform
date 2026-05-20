---
name: audit-app-desktop
description: Audit d'une app desktop Tauri (ou Electron) aux conventions code-conform — sécurité allowlist/CSP, IPC typé, atomic, persistance locale, distribution. Mode audit philosophy §8 — pas d'auto-modification.
---

# /audit-app-desktop

Skill **audit** : revue d'une app desktop existante. Tauri prioritaire (Electron toléré sur signal acté). **N'auto-modifie rien sans accord explicite.**

Si l'app communique avec un serveur compagnon développé en parallèle → renvoi `/audit-cloud` (audit système complet).
Si le projet est vide → `/bootstrap-app-desktop`.
Si c'est un SPA web sans `src-tauri/` → `/audit-site-vitrine` ou `/audit-saas` selon profil.

## Pré-requis — SSOT à charger

- `~/.code-conform/docs/architecture/00-philosophy.md` — mode audit (§8), filtre fondamental.
- `~/.code-conform/docs/architecture/typescript.md` — frontière, idiomes TS.
- `~/.code-conform/docs/architecture/rust.md` — côté `src-tauri/`.
- `~/.code-conform/docs/architecture/ui.md` — atomic, tokens, a11y.
- `~/.code-conform/skills/audit-design-system/SKILL.md` — grille DS réutilisable.
- `docs/conventions.md` du projet si présent.

## Étape 1 — Cartographie

Inspecter sans modifier :

- **Runtime** : `src-tauri/Cargo.toml` (Tauri version) ou `electron` dans `package.json`. Si Electron sans `docs/conventions.md` qui le justifie → écart à signaler.
- **Frontend stack** : React/Vue/Svelte, Vite version, Tailwind v4 ?
- **`tauri.conf.json`** : allowlist (qu'est-ce qui est activé ?), CSP, scopes FS, identifier.
- **Commands Rust** : `src-tauri/src/commands/` ou équivalent — combien, groupées par domaine ou en vrac.
- **Persistance** : plugin `tauri-plugin-store` / `tauri-plugin-sql` / FS direct / aucun.
- **State** : Zustand, Redux, Pinia, autre.
- **DS** : `src/components/` — appliquer grille `audit-design-system` (sous-audit).
- **Fenêtrage** : `tauri.conf.json > app.windows` — mono ou multi.
- **Updater** : `tauri-plugin-updater` présent ? Endpoint configuré ?
- **`docs/conventions.md`** : présent ? Aligné ?

Annonce la carte en 5-8 lignes.

## Étape 2 — Grille d'audit

### A — Runtime et configuration

- [ ] Tauri ≥ 2.0 (v1 = migration à proposer, encore supporté mais fin de vie).
- [ ] Electron seulement si `docs/conventions.md` documente le signal — sinon écart majeur, proposer rebootstrap Tauri ou capture du signal.
- [ ] `tauri.conf.json` : identifier en reverse-DNS unique (`com.user.app`).
- [ ] Pas de config morte (entrées plugins non utilisés).

### B — Sécurité (CRITIQUE)

- [ ] **Allowlist au minimum nécessaire** — `"all": true` = écart majeur.
- [ ] Scopes FS bornés (`$APPDATA/*` ok, `$HOME/**` à justifier).
- [ ] CSP active dans `tauri.conf.json > app.security.csp`. Pas de `unsafe-inline` ni `unsafe-eval` sauf signal acté.
- [ ] Pas de secrets dans `tauri.conf.json` (config publique).
- [ ] Si SQLite : pas de SQL concaténé côté Rust (utilisation des params).
- [ ] HTTP client (`tauri-plugin-http`) : allowlist URL si activé.

### C — IPC et frontière (philosophy §5 INVARIANT)

- [ ] Commands Rust typées (`#[tauri::command]` + types Rust clairs).
- [ ] Côté TS : soit `tauri-specta` (codegen), soit parse Zod en sortie d'`invoke`. **Pas de cast `as T` aveugle** côté front.
- [ ] Wrapper `invoke` centralisé (`src/lib/tauri.ts`) — pas d'`invoke` éparpillé sans frontière.
- [ ] Erreurs Rust remontées proprement (`Result<T, AppError>` sérialisable, pas `String` opaque).

### D — Frontend / DS (renvoi `audit-design-system`)

Appliquer la grille DS complète. Spécificités desktop :

- [ ] `templates/` typiquement présent et justifié (mono-window sans routing externe).
- [ ] Pas de `react-router` en mono-window — si présent sans signal, écart.
- [ ] Zustand pour state global (ou équivalent framework). Pas de Context React pour state non-thème.

### E — Persistance locale

- [ ] Choix cohérent avec besoin :
  - JSON pour < 1k entrées, schéma simple → `tauri-plugin-store`.
  - Relationnel / requêtes → SQLite via `tauri-plugin-sql`.
  - Fichiers user (éditeur, media) → FS direct + scope précis.
- [ ] Migrations SQLite versionnées (`src-tauri/migrations/`) si SQLite.
- [ ] Frontière Zod en sortie de lecture store (la donnée stockée peut avoir été migrée à chaud).
- [ ] Pas de duplication state runtime (Zustand) vs store persisté — clarté sur ce qui hydrate quoi.

### F — Rust (renvoi `rust.md`)

Audit allégé côté `src-tauri/` :

- [ ] Cargo workspace si multi-crates, sinon `src-tauri/` standalone OK.
- [ ] Commands groupées par domaine dans `src/commands/<area>.rs`, pas un `main.rs` géant.
- [ ] Pas d'`unwrap`/`expect` en chemin chaud (renvoi `rust.md`).
- [ ] Logs via `tracing` ou `log`, pas `println!` en prod.

### G — Distribution et updater

- [ ] Plateformes cibles déclarées (`tauri.conf.json > bundle.targets`).
- [ ] Icônes complètes par plateforme (`icons/` généré).
- [ ] Updater configuré si Q6 oui : endpoint privé/public, pubkey signature présente.
- [ ] Code signing : signaler absent si distribution publique macOS/Windows (sinon Gatekeeper / SmartScreen bloquent).

### H — Accessibilité desktop (renvoi `ui.md` §11)

- [ ] Navigation clavier complète (Tab/Shift+Tab, Enter, Escape).
- [ ] Focus visible (pas de `outline: none` non remplacé).
- [ ] Raccourcis OS-natifs si pertinent (`Cmd+W` close, `Cmd+,` settings sur macOS).
- [ ] Pas de menu/dialog réinventé — utilisation lib headless a11y (Radix, Reka, etc.).

### I — Build et DX

- [ ] `pnpm tauri dev` lance proprement.
- [ ] `pnpm tauri build` produit un binaire fonctionnel.
- [ ] `cargo check` côté `src-tauri/` passe sans warning suspect.
- [ ] `tsc --noEmit` passe.
- [ ] Biome (ou linter projet) appliqué uniformément.

### J — `docs/conventions.md`

- [ ] Présent.
- [ ] Aligné avec choix observés (persistance, IPC, fenêtrage, plateformes, updater).
- [ ] Justifie les bascules vs default code-conform si présentes (Electron, Vue/Svelte au lieu de React).

## Étape 3 — Rapport

```
# Audit app desktop — <projet>

## Carte rapide
- Tauri v<…> | Electron (signal: <…>)
- Frontend : <React 19 + Vite | …>
- Persistance : <store JSON | SQLite | FS | aucun>
- Fenêtrage : <mono | multi: N>
- Updater : <on | off>
- DS : <conforme | écarts mineurs | écarts majeurs>

## Écarts majeurs (sécurité d'abord)
1. ...

## Écarts mineurs
1. ...

## Conforme
- ...

## Suggestions hors écart
- ...
```

## Étape 4 — Correction interactive

**INVARIANT** — aucune modification sans accord explicite.

Lots typiques (sécurité prioritaire) :

1. **Réduire allowlist Tauri** au strict nécessaire — premier lot car impact direct sécurité.
2. **CSP** : retirer `unsafe-inline`/`unsafe-eval` ou capter le signal dans `conventions.md`.
3. **Frontière IPC** : introduire `src/lib/tauri.ts` wrapper, parser Zod en sortie, remplacer `as T`.
4. **DS** : chaîner `/audit-design-system` pour le détail.
5. **Migration Tauri v1 → v2** si applicable (gros lot, planifier).
6. **Persistance** : aligner choix vs besoin si mismatch (ex: JSON store qui dépasse → migrer vers SQLite).
7. **Updater + code signing** si distribution publique.
8. **`docs/conventions.md`** : créer ou compléter.

Pour chaque lot : fichiers, diff, accord, application.

## Anti-patterns du skill

- ✗ Auto-modification sans accord.
- ✗ Recommander la migration Electron→Tauri sans signal — si Electron est documenté et choisi, respecter.
- ✗ Demander de "tout typer" l'IPC manuellement sans considérer tauri-specta.
- ✗ Inventer un seuil "trop de commands" — philosophy §9, demander à l'utilisateur.
- ✗ Auditer la business logic métier au-delà des frontières IPC et DS.
- ✗ Recommander un router en mono-window "au cas où".

## Out of scope (renvoi)

- **DS isolé** → `/audit-design-system`.
- **App + serveur compagnon** → `/audit-cloud`.
- **Web SPA pure sans `src-tauri/`** → `/audit-site-vitrine` ou `/audit-saas`.
- **CI/CD release pipeline** → hors scope conventions, sujet propre.
- **Performance binaire / cold start** → hors scope, signal utilisateur requis.
