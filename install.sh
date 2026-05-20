#!/usr/bin/env bash
set -euo pipefail

# code-conform installer — pose docs/ et skills/ dans le home.
# Default : copie (résilient, repo source peut bouger ou disparaître).

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_SRC="$REPO_ROOT/docs"
SKILLS_SRC="$REPO_ROOT/skills"
DOCS_DST="$HOME/.code-conform/docs"
SKILLS_DST="$HOME/.claude/skills"
SENTINEL=".installed-by-code-conform"

mode="copy"
force=0
for arg in "$@"; do
  case "$arg" in
    --link) mode="link" ;;
    --force|-f) force=1 ;;
    --uninstall) mode="uninstall" ;;
    --help|-h)
      cat <<'EOF'
code-conform installer

Usage:
  ./install.sh              Copie (default — résilient au déplacement du repo).
  ./install.sh --force      Force la copie sans backup (update propre).
  ./install.sh --link       Symlinks (dev — édits dans le repo suivis live).
  ./install.sh --uninstall  Retire ce qui a été posé par ce script.

Cibles :
  ~/.code-conform/docs/      ← docs/
  ~/.claude/skills/<name>/   ← skills/<name>/  (un lien/copie par skill)

Conflits (mode default, sans --force) :
  Les fichiers/dossiers existants à la cible sont sauvegardés en .bak.<ts>,
  sauf s'ils portent le sentinelle .installed-by-code-conform (alors écrasés).
EOF
      exit 0
      ;;
    *) echo "Arg inconnu: $arg (voir --help)" >&2; exit 1 ;;
  esac
done

[[ -d "$DOCS_SRC" ]] || { echo "✗ Manque $DOCS_SRC"; exit 1; }
[[ -d "$SKILLS_SRC" ]] || { echo "✗ Manque $SKILLS_SRC"; exit 1; }

backup() {
  local p="$1"
  local stamp
  stamp="$(date +%Y%m%d-%H%M%S)"
  mv "$p" "$p.bak.$stamp"
  echo "⚠  $p existait, sauvegardé en $p.bak.$stamp"
}

# Décide quoi faire d'un chemin cible existant :
#   - symlink → rm
#   - dossier avec sentinelle (= installé par nous) → rm -rf, propre
#   - dossier sans sentinelle + --force → rm -rf (override explicite)
#   - dossier sans sentinelle → backup
clear_target() {
  local p="$1"
  if [[ -L "$p" ]]; then
    rm "$p"
  elif [[ -d "$p" ]]; then
    if [[ -f "$p/$SENTINEL" ]] || [[ "$force" -eq 1 ]]; then
      rm -rf "$p"
    else
      backup "$p"
    fi
  elif [[ -e "$p" ]]; then
    if [[ "$force" -eq 1 ]]; then
      rm -f "$p"
    else
      backup "$p"
    fi
  fi
}

install_docs_link() {
  mkdir -p "$(dirname "$DOCS_DST")"
  clear_target "$DOCS_DST"
  ln -s "$DOCS_SRC" "$DOCS_DST"
  echo "→  link $DOCS_DST → $DOCS_SRC"
}

install_docs_copy() {
  mkdir -p "$(dirname "$DOCS_DST")"
  clear_target "$DOCS_DST"
  mkdir -p "$DOCS_DST"
  cp -R "$DOCS_SRC/." "$DOCS_DST/"
  touch "$DOCS_DST/$SENTINEL"
  echo "→  copy $DOCS_SRC/ → $DOCS_DST/"
}

install_skills() {
  local action="$1"  # link | copy
  mkdir -p "$SKILLS_DST"
  for d in "$SKILLS_SRC"/*/; do
    [[ -d "$d" ]] || continue
    local name target
    name="$(basename "${d%/}")"
    target="$SKILLS_DST/$name"
    clear_target "$target"
    if [[ "$action" == "link" ]]; then
      ln -s "${d%/}" "$target"
      echo "→  link $target"
    else
      mkdir -p "$target"
      cp -R "${d}." "$target/"
      touch "$target/$SENTINEL"
      echo "→  copy $target"
    fi
  done
}

uninstall_docs() {
  if [[ -L "$DOCS_DST" ]]; then
    rm "$DOCS_DST"
    echo "→  removed symlink $DOCS_DST"
  elif [[ -d "$DOCS_DST" ]]; then
    if [[ -f "$DOCS_DST/$SENTINEL" ]]; then
      rm -rf "$DOCS_DST"
      echo "→  removed $DOCS_DST"
    else
      echo "⚠  $DOCS_DST sans sentinelle — non géré par nous, ignoré (suppression manuelle si voulu)."
    fi
  else
    echo "   rien à faire pour $DOCS_DST"
  fi
}

uninstall_skills() {
  [[ -d "$SKILLS_DST" ]] || { echo "   pas de $SKILLS_DST"; return; }
  for d in "$SKILLS_SRC"/*/; do
    [[ -d "$d" ]] || continue
    local name target
    name="$(basename "${d%/}")"
    target="$SKILLS_DST/$name"
    if [[ -L "$target" ]]; then
      rm "$target"
      echo "→  removed $target"
    elif [[ -d "$target" ]]; then
      if [[ -f "$target/$SENTINEL" ]]; then
        rm -rf "$target"
        echo "→  removed $target"
      else
        echo "⚠  $target sans sentinelle — non géré par nous, ignoré."
      fi
    fi
  done
}

prune_orphan_skills() {
  # Skills présents dans SKILLS_DST avec notre sentinelle mais absents du repo source.
  [[ -d "$SKILLS_DST" ]] || return
  local found=0
  local source_names
  source_names=$(find "$SKILLS_SRC" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort)
  for installed in "$SKILLS_DST"/*/; do
    [[ -d "$installed" ]] || continue
    local name
    name="$(basename "${installed%/}")"
    # Si présent dans le repo source, on l'a déjà traité.
    if echo "$source_names" | grep -qx "$name"; then continue; fi
    # Sinon, vérifier sentinelle pour confirmer qu'on l'a posé.
    if [[ -f "$installed$SENTINEL" ]]; then
      rm -rf "${installed%/}"
      echo "→  pruned orphan $installed (présent dans home, absent du repo source — supprimé via sentinelle)"
      found=1
    fi
  done
  if [[ $found -eq 1 ]]; then
    echo ""
  fi
}

case "$mode" in
  copy)
    install_docs_copy
    install_skills copy
    prune_orphan_skills
    echo ""
    echo "✓ code-conform installé (copie, résilient)."
    echo "  Update : ./install.sh (re-lance, écrase nos copies via sentinelle)."
    echo "  Repo source peut désormais bouger / être supprimé sans casser l'install."
    ;;
  link)
    install_docs_link
    install_skills link
    prune_orphan_skills
    echo ""
    echo "✓ code-conform installé (symlinks, mode dev)."
    echo "  Édits dans $REPO_ROOT effectifs dès la prochaine session Claude Code."
    echo "  ⚠  Si tu déplaces / supprimes le repo, les liens cassent."
    ;;
  uninstall)
    uninstall_docs
    uninstall_skills
    echo ""
    echo "✓ Désinstallation terminée."
    ;;
esac
